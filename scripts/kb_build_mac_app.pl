
#
# Build a mac app wrapper of the current dev container.
#
# Argument needs to be the KBase.app application name.
#

use File::Temp;
use File::Slurp;
use Data::Dumper;
use strict;
use Cwd 'abs_path';
use File::Copy;
use Bio::KBase::DeploymentTools;

use Getopt::Long;

my $version = "1.000";

my $libpath = Bio::KBase::DeploymentTools->install_path;
my $icon = "$libpath/DeploymentTools/KBASE_Icon_03.icns";
$icon = abs_path($icon);
-f $icon or die "Icon $icon not found\n";

my $autodeploy_config;

my $rc = GetOptions("version=s" => \$version,
		    "autodeploy-config=s" => \$autodeploy_config);

($rc && @ARGV == 1) or die "Usage: build-app [--version version] target\n";

my $target = shift;

if (-d $target)
{
    die	"Target directory $target already exists\n";
}

$target = abs_path($target);

my $runtime = $ENV{KB_RUNTIME};
if (!$runtime)
{
    die "Could not find KB_RUNTIME environment variable";
}

my $cur_top = $ENV{KB_TOP};
if (!$cur_top)
{
    die "Could not find KB_TOP environment variable";
}
chdir($cur_top) or die "Cannot chdir $cur_top: $!";

#
# Construct the script that will create the app wrapper.
#

my $tmp = File::Temp->new;

write_applescript($tmp, $target);
close($tmp);

#
# And run.
#

my $rc = system("osascript", $tmp->filename);
if ($rc != 0)
{
    print read_file($tmp->filename);
    die "Error running applescript\n";
}

#
# Edit the property list to set our icon and other information.
#

my $plist_file = "$target/Contents/Info.plist";
my $plist_file_base = $plist_file;
$plist_file_base =~ s/\.plist$//;

copy($icon, "$target/Contents/Resources/kbase-icon.icns") or die "Cannot copy $icon to $target/Contents/Resources/kbase-icon.icns: $!";

system("defaults", "write", $plist_file_base, "CFBundleIconFile", "kbase-icon");
system("defaults", "write", $plist_file_base, "CFBundleShortVersionString", $version);

#
# Now we have the framework we can replicate our runtime into it.
#

print STDERR "copy runtime\n";
$rc = system("rsync", "-ar", "$runtime/.", "$target/runtime");
if ($rc != 0) {
    die "Error syncing $runtime to $target/runtime\n";
}

#
# We may now deploy into the application.
#
my @cmd;
if ($autodeploy_config)
{
    @cmd = ("perl", "auto-deploy",
	    "--target", "$target/deployment",
	    '--override', "WRAP_PERL_TOOL=wrap_perl_app",
	    '--override', "WRAP_PYTHON_TOOL=wrap_python_app",
	    abs_path($autodeploy_config));
}
else
{
    @cmd = ("make", "TARGET=$target/deployment", "WRAP_PERL_TOOL=wrap_perl_app", "deploy");
}
print STDERR "deploy with @cmd\n";
my $rc = system(@cmd);
if ($rc != 0) {
    die "Error deploying";
}

#
# And write our user-init script.
#

write_user_bash_init("$target/user-env.sh");
write_user_csh_init("$target/user-env.csh");
write_user_zsh_init("$target/user-env.zsh");

sub write_user_bash_init
{
    my($file) = @_;
    open(F, ">", $file) or die "Cannot write $file: $!";
    print F <<'EOF';
#!/bin/sh

_dir=`dirname "$BASH_ARGV[0]"`

export KB_TOP="$_dir/deployment"
export KB_RUNTIME="$_dir/runtime"
export KB_PERL_PATH="$_dir/deployment/lib"
export PATH=$KB_RUNTIME/bin:$KB_TOP/bin:$PATH
export PERL5LIB=$KB_PERL_PATH

echo ""
echo "Welcome to the KBase interactive shell. Please visit http://kbase.us/developer-zone/ for documentation."
echo ""
EOF
    close(F);
    chmod(0755, $file);
}

sub write_user_zsh_init
{
    my($file) = @_;
    open(F, ">", $file) or die "Cannot write $file: $!";
    print F <<'EOF';
#!/bin/sh

_dir=`dirname "$0"`
_dir=`cd "$_dir"; pwd`

export KB_TOP="$_dir/deployment"
export KB_RUNTIME="$_dir/runtime"
export KB_PERL_PATH="$_dir/deployment/lib"
export PATH=$KB_RUNTIME/bin:$KB_TOP/bin:$PATH
export PERL5LIB=$KB_PERL_PATH

echo ""
echo "Welcome to the KBase interactive shell. Please visit http://kbase.us/developer-zone/ for documentation."
echo ""
EOF
    close(F);
    chmod(0755, $file);
}

sub write_user_csh_init
{
    my($file) = @_;
    open(F, ">", $file) or die "Cannot write $file: $!";
    print F <<EOF;

set kb_cmd=(\$_)
set kb_path=`echo \$kb_cmd | perl -ne '/^\\s*source\\s+"?(.*)"?\$/ and print "\$1\\n"'`
set kb_path=`dirname \$kb_path`
set kb_path=`cd \$kb_path; pwd`

setenv KB_TOP "\$kb_path/deployment"
setenv KB_RUNTIME "\$kb_path/runtime"
setenv KB_PERL_PATH "\$kb_path/deployment/lib"
setenv PATH \$KB_RUNTIME/bin:\$KB_TOP/bin:\$PATH
setenv PERL5LIB \$KB_PERL_PATH

echo ""
echo "Welcome to the KBase interactive shell. Please visit http://kbase.us/developer-zone/ for documentation."
echo ""
EOF
    close(F);
    chmod(0755, $file);
}

sub write_applescript
{
    my($fh, $dir) = @_;

    print $fh "script myScript\n";
    print $fh application_applescript();
    print $fh "end script\n";
    print $fh "store script myScript in \"$dir\"\n";
}





sub application_applescript
{
    return <<'EOF';

set here to path to me

set base to POSIX path of here

set shell_type to do shell script "/usr/bin/perl -e '$s = (getpwuid($>))[8]; print $s =~ /csh/ ? \"csh\\n\" : ($s =~ /zsh/ ? \"zsh\\n\" : \"bash\\n\")'"

if shell_type = "csh"
    set init to "source \"" & base & "/user-env.csh\""
else if shell_type = "zsh"
    set init to "source \"" & base & "/user-env.zsh\""
else 
    set init to "source \"" & base & "/user-env.sh\""
end if
    
tell application "Terminal"
     activate

     do script with command init
end tell

EOF
}

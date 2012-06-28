
#
# Build a mac app wrapper of the current dev container.
#

use File::Temp;
use strict;
use Cwd 'abs_path';

@ARGV == 1 or die "Usage: build-app target\n";

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
    die "Error running applescript\n";
}

#
# Now we have the framework we can replicate our runtime into it.
#

$rc = system("rsync", "-ar", "$runtime/.", "$target/runtime");
if ($rc != 0) {
    die "Error syncing $runtime to $target/runtime\n";
}

#
# We may now deploy into the application.
#
$rc = system("make", "TARGET=$target/deployment", "WRAP_PERL_TOOL=wrap_perl_app", "deploy");
if ($rc != 0) {
    die "Error deploying";
}

#
# And write our user-init script.
#

write_user_init("$target/user-env.sh");

sub write_user_init
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


set init to "source '" & base & "/user-env.sh'"
tell application "Terminal"
     activate
     
     do script with command init
end tell

EOF
}

=head1 NAME

    create-kb-dev-container

=head1 SYNOPSIS

    create-kb-dev-container directory [module module module]

=head1 DESCRIPTION

Create a new KBase development container directory. If modules are specified, they 
will be checked out into the modules directory of the container. Modules may be 
specified using the following syntax:

=over 4

=item modulename.git

The module will be cloned from KBase git repository using whatever
credentials the user has in place.

=item git:URL

The module will be cloned using git from the given URL using whatever the credentials
the user has in place.

=item hg:URL

The module will be cloned using Mercurial from the given URL using whatever the credentials
the user has in place.

=back

=cut

use Getopt::Long;
use strict;
use LWP::UserAgent;
use Archive::Tar;
use File::Temp;
use File::Basename;
use Cwd 'abs_path';
use Data::Dumper;

#
# Location of the dev_container source tree.
#

my $dev_container_url = "http://kbase.us/docs/downloads/dev_container.tgz";

#
# Default the runtime to the one found in the environment.
#

my $runtime = $ENV{KB_RUNTIME};

#
# If not found, work around it by trying to determine the location of the perl
# used to invoke this script. This shouldn't be necessary in any of the 
# formal releases but it might be an issue in early development (for instance
# when working in the SEED environment).
#

if ($runtime eq '')
{
    my $perl = $^X;
    $runtime = abs_path(dirname($perl) . "/..");
}

my $kbase_git_base = 'kbase@git.kbase.us';

my $rc = GetOptions("runtime=s" => \$runtime);

($rc && @ARGV >= 1) or die "Usage: create-kb-dev-container target-dir [module-list]\n";

my $dest_dir = shift;
my @modules = @ARGV;

if (-d $dest_dir)
{
    die "Target directory $dest_dir already exists, exiting.\n";
}

mkdir($dest_dir) || die "Cannot create $dest_dir: $!";
$dest_dir = abs_path($dest_dir);

download_and_extract();
load_modules();
configure();

sub download_and_extract
{
    my $tmp = File::Temp->new();
    my $ua = LWP::UserAgent->new();
    
    my $res = $ua->get($dev_container_url, ':content_cb' => sub {
	my($block, $resp, $proto) = @_;
	print $tmp $block;
    });
    close($tmp);
    
    if (!$res->is_success)
    {
	die "Error retrieving development container distribution: " . $res->content;
    }
    
    
    my $archive = Archive::Tar->new();
    $archive->read($tmp->filename());
    $archive->setcwd($dest_dir);
    my @files = $archive->extract;
    if (@files == 0)
    {
	die "We were not able to extract the development container from the distribution\n";
    }
}

sub load_modules
{
    chdir("$dest_dir/modules") or die "Cannot chdir $dest_dir/modules: $!";

    for my $module (@modules)
    {
	print "Load module $module\n";

	if ($module =~ /^git:(.+)$/)
	{
	    load_git_module($1);
	}
	elsif ($module =~ /^hg:(.*)$/)
	{
	    load_hg_module($1);
	}
	else
	{
	    load_git_module("$kbase_git_base:$module");
	}
    }
}

sub load_git_module
{
    my($git_url) = @_;
    print "Cloning $git_url...\n";
    my $rc = system("git", "clone", $git_url);
    if ($rc != 0)
    {
	die "Could not clone git repository $git_url (exited with code $rc)";
    }
    print "Cloning $git_url...done\n";
}

sub load_hg_module
{
    die "Mercurial support not yet implemented.";
}

#
# Configure the newly checked out container by running the bootstrap script.
#
sub configure
{
    print "Bootstrapping using runtime directory $runtime\n";
    chdir($dest_dir) or die "cannot chdir $dest_dir: $!";
    if (! -x "bootstrap")
    {
	die "Bootstrap script is not present in $dest_dir";
    }
    my @cmd = ("./bootstrap", $runtime);
    my $rc = system(@cmd);
    if ($rc != 0)
    {
	die "Error running @cmd (rc=$rc)";
    }
}

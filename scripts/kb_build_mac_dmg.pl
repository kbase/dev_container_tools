#
# Given an built KBase.app provided on the command line, construct a
# release dmg file.
#
# Create Applications symlink
# Create uncompressed dmg
# Use applescript helper to set up custom view settings on dmg
# Create compressed dmg
#

use strict;
use Cwd 'abs_path';
use File::Copy;
use Bio::KBase::DeploymentTools;

@ARGV == 3 or die "Usage: $0 target-dir uncompressed-dmg compressed-dmg\n";

my $target = shift;
my $uncomp_dmg = shift;
my $comp_dmg = shift;

my $volume_name = "KBase";

if (-d "/Volumes/$volume_name")
{
    die "Volume $volume_name is already attached; please unmount before proceeding\n";
}

my $libpath = Bio::KBase::DeploymentTools->install_path . "/DeploymentTools";
my $bg_image = "$libpath/mac-background.png";
$bg_image = abs_path($bg_image);
-f $bg_image or die "Cannot read $bg_image\n";

-d "$target/KBase.app" or die "Target $target does not contain a KBase.app\n";
#-f $uncomp_dmg and die "Uncompressed dmg $uncomp_dmg already exists\n";
-f $comp_dmg and die "Compressed dmg $comp_dmg already exists\n";

if (! -l "$target/Applications")
{
    symlink("/Applications", "$target/Applications") or die "Cannot symlink $target/Applications: $!";
}

#
# Calculate image size - disk usage + 10%.
#
my $size = `du -ks $target | cut -f1`;
chomp $size;
$size = int($size * 1.1);

print "size=$size\n";
if ($size < 4096)
{
    $size = 4096
}

#
# Create initial uncompressed disk image.
#

#my @cmd = ("hdiutil", "create", $uncomp_dmg, "-format", "UDRW",
#	   "-size", "${size}k", "-srcfolder", $target, "-volname", $volume_name);
my @cmd = ("hdiutil", "create", $uncomp_dmg, "-format", "UDRW",
	   "-srcfolder", $target, "-volname", $volume_name);
print "@cmd\n";
system(@cmd);

#
# Mount the image.
#

my @mount = ("hdiutil", "attach", "-readwrite", $uncomp_dmg);
sleep(10);

my($dev, $volume);

open(P, "-|", @mount) or die "Cannot run mount command: $!: @mount\n";
while (<P>)
{
    if (m,^(/dev/disk\S+)\s+(\S+)\s+(\S+),)
    {
	$dev = $1;
	$volume = $3;
	print "Mounted at $volume from $dev\n";
    }
}
if (!close(P))
{
    die "Volume attach failed: $! $?\n";
}

#
# Copy data
#

mkdir("$volume/.background") or die "Cannot mkdir $volume/.background: $!";

copy($bg_image, "$volume/.background/background.png");

#
# Invoke applescript to initialize the view.
#

@cmd = ("osascript", "$libpath/setup-image.applescript", $volume_name);
my $rc = system(@cmd);
if ($rc != 0)
{
    die "osascript failed rc=$rc: @cmd\n";
}

$rc = system("hdiutil", "detach", $volume);
if ($rc != 0)
{
    die "Error detaching $volume: $!\n";
}

@cmd = ("hdiutil", "convert", $uncomp_dmg, "-format", "UDZO", "-imagekey", 9, "-o", $comp_dmg);
$rc = system(@cmd);
if ($rc != 0)
{
    die "Error $rc converting : @cmd\n";
}


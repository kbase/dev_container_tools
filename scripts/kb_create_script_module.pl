=head1 NAME

    kb_create_script_module

=head1 SYNOPSIS

    kb_create_script_module module-name [script1 script2 ...]

=head1 DESCRIPTION

Create a new KBase module in the current development container. The new module
directory will be set up for the development of new command line scripts in Perl.

=over 4

=item module-name

The name of the new module to be created. 

=item scriptN

The name of a script to create as a stub in the module. 

=back

=cut

use Getopt::Long;
use strict;
use File::Temp;
use File::Basename;
use Cwd 'abs_path';
use Data::Dumper;

#
# Locate the top of the current development tree. If KB_TOP is not set, then we're
# not being invoked appropriately.
#

my $kb_top = $ENV{KB_TOP};

if (!$kb_top)
{
    die "Error locating the current development tree (KB_TOP is not set).";
}

my $rc = GetOptions();

($rc && @ARGV == 1) or die "Usage: create-kb-script-module new-module-name\n";

my $new_module_name = shift;


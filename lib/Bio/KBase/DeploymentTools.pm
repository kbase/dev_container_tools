package Bio::KBase::DeploymentTools;

use strict;
use File::Spec;

sub install_path
{
    return File::Spec->catpath((File::Spec->splitpath(__FILE__))[0,1], '');
}

1;

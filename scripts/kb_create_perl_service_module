=head1 NAME

    kb_create_service_module

=head1 SYNOPSIS

    kb_create_service_module -name <repo_name>
    kb_create_service_module -name <repo_name> -java

=head1 DESCRIPTION

Create a new directory that represents a skeleton for building a service module.
Basic subdirectories are created, and some care is given to emmulate language
idioms for setting up a module's directory structure.

=over 4

=item -h --help

Help information

=item -name

The name of the module (repo) that you wish to create. This ideally
represents a one to one mapping between the module name and the
git repository name.

=item -top_dir

If specified, this programs considers top_dir to be the top dir of
the dev_container. This program will look for a module.Makefile in
the top_dir templates directory and copy it to the mew service module.

=item -java

If specified, the module will be a java service module. If -java is not
specified on the commandline, the default perl service module is created.

=back

=head1 DETAIL

create the main directory
create a Makefile in the main directory
create the scripts directory
create the lib directory
create the three test directoreis
create the service directory
write the start_service template in the service directory
write the stop_service template in the service directory
write the process template file in the service directory


=cut






use strict;
use IO::File;
use Getopt::Long;
use Pod::Find qw (pod_where);
use Pod::Usage;
use vars qw( $top_dir $is_java $name $is_help);

my $man  = 0;
my $help = 0;
GetOptions ('top_dir=s', \$top_dir,
            'java',   \$is_java,
            'name=s', \$name,
            'h',      \$help,
            'help',   \$help,
        ) or pod2usage(0);
pod2usage(-exitstatus => 0,
	  -output => \*STDOUT,
	  -verbose => 2,
	  -noperldoc => 1,
	  -input => pod_where({-inc => -1}, __PACKAGE__)
) if $help or $man;


unless ($name) { print "missing -name paramter, try --help\n"; exit(0); }
error("$name already exists") if -e $name;

my $date = `date`;

`mkdir "$name"`;
`cat > "$name/readme.txt" << EOF
  created repo for $name on $date
`;
 
`mkdir "$name/lib"`;
`cat > "$name/lib/readme-lib.txt" << EOF
  put your perl modules and java jars here
`;

`mkdir "$name/scripts"`;
`cat > "$name/scripts/readme-scripts.txt" << EOF
  put your perl scripts and java run scripts here
`;

`mkdir "$name/client-tests"`;
`cat > "$name/client-tests/readme-client-tests.txt" << EOF
  put your client library tests here
`;

`mkdir "$name/script-tests"`;
`cat > "$name/script-tests/readme-script-tests.txt" << EOF
  put your command line interface tests here
`;

`mkdir "$name/server-tests"`;
`cat > "$name/server-tests/readme-server-tests.txt" << EOF
  put your server tests here
`;

`mkdir "$name/service"`;
`cat > "$name/service/readme.txt" << EOF
  the scripts directory contains templates used to create service scripts
`;

`mkdir "$name/distribution"`;
`cat > "$name/distribution/readme.txt" << EOF
  the distribution directory contains distributions such as a .tar.gz
`;


# populate the service module directory with some standard files
if ( defined $top_dir and -d $top_dir ) {
  `cp "$top_dir/template/module.Makefile" "$name/Makefile"`;
}
elsif ( exists $ENV{TOP_DIR} and defined $ENV{TOP_DIR} ) {
  `cp "$ENV{TOP_DIR}/template/module.Makefile" "$name/Makefile"`;
}
else {
  print "could not find $top_dir/template/module.Makefile\n";
  print "looks like TOP_DIR or top_dir is not defined\n";
  print "continuing without createing the service module Makefile\n\n";
}

if (defined $top_dir and -d $top_dir ) {
  print "copying $top_dir/template/*.tt to $name/service/\n";
  `cp "$top_dir/template/start_service.tt"  "$name/service/start_service.tt"`;
  `cp "$top_dir/template/stop_service.tt" "$name/service/stop_service.tt"`;
  `cp "$top_dir/template/process.tt" "$name/service/process.tt"`;
}
elsif (exists $ENV{TOP_DIR} and defined $ENV{TOP_DIR} ) {
  `cp "$ENV{TOP_DIR}/template/start_service.tt" "$name/service/start_service.tt"`;
  `cp "$ENV{TOP_DIR}/template/stop_service.tt" "$name/service/stop_service.tt"`;
  `cp "$ENV{TOP_DIR}/template/process.tt" "$name/service/process.tt"`;
}
else {
  print "could not find $top_dir teplates dir\n";
  print "looks like TOP_DIR or top_dir is not defined\n";
  print "continuing without createing the start_service, stop_service ",
  print " and process template files\n\n";
}


# java section. this is likely out of date.
if ($is_java) {

`mkdir "$name/src"`;
`cat > "$name/src/readme-src.txt" << EOF
  put your java source files here
`;

open F, ">$name/build.xml"
   or die "Can not write build.xml";
print F<<'EOF';

<project name="my service" default="dist" basedir=".">

  <description>
      simple example build file for the regprecise service
  </description>

  <!-- set global properties for this build -->
  <property name="app.name"   value="my_service"/>
  <property name="src"        location="src"/>
  <property name="build"      location="build"/>
  <property name="dist"       location="dist"/>

  <!-- set the class path for this build -->
  <path id="compile.classpath">
    <fileset dir="lib/">
      <include name="*.jar"/>
    </fileset>
  </path>


  <target name="init">
    <!-- Create the time stamp -->
    <tstamp/>
    <!-- Create the build directory structure used by compile -->
    <mkdir dir="${build}"/>
  </target>

  <target name="compile" depends="init"
        description="compile the source " >
    <!-- Compile the java code from ${src} into ${build} -->
    <javac 
        includeantruntime="false"
        srcdir="${src}" 
        destdir="${build}" 
        classpathref="compile.classpath" 
    />
  </target>

  <target name="dist" depends="compile"
        description="generate the distribution" >
    <!-- Create the distribution directory -->
    <mkdir dir="${dist}/lib"/>

    <!-- Put everything in ${build} into the
         ${app.name}-${DSTAMP}.jar file 
    -->
    <jar jarfile="${dist}/lib/${app.name}-${DSTAMP}.jar" basedir="${build}"/>
  </target>

  <target name="clean"
        description="clean up" >
    <!-- Delete the ${build} and ${dist} directory trees -->
    <delete dir="${build}"/>
    <delete dir="${dist}"/>
  </target>
</project>

EOF

        close F;
}

sub error {
        print $_[0], "\n";
        exit -1;
}
sub usage {
        print<<EOF;

usage: kb_create_repo -name my_repo 
       kb_create_repo -name my_repo -java

EOF
        exit;
}

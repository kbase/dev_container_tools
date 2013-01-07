=head1 NAME

    kb_create_repo

=head1 SYNOPSIS

    kb_create_repo -name <repo_name>
    kb_create_repo -name <repo_name> -java

=head1 DESCRIPTION

Create a new directory that represents a skeleton for building a service module.
Basic subdirectories are created, and some care is given to emmulate language idioms
for setting up a module's directory structure.

=over 4

=item -h --help

Help information

=item -name

The name of the module (repo) that you wish to create. This ideally
represents a one to one mapping between the module name and the
git repository name.

=item -java

If specified, the module will be a java service module. If -java is not specified
on the commandline, the default perl service module is created.

=back

=cut








use strict;
use IO::File;
use Getopt::Long;
use vars qw( $is_java $name $is_help);
GetOptions ('java',   \$is_java,
            'name=s', \$name,
            'h',      \$is_help,
            'help',   \$is_help,
        );
usage() if $is_help;
usage() unless $name;
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
open STOP_SERVICE, ">$name/service/stop_service.tt"
	or die "could not open $name/service/stop_service.tt for write";
print STOP_SERVICE <<'END';
#!/bin/sh
export KB_TOP=[% kb_top %]
export KB_RUNTIME=[% kb_runtime %]
export PATH=$KB_TOP/bin:$KB_RUNTIME/bin:$PATH
export PERL5LIB=$KB_TOP/lib
export KB_SERVICE_DIR=$KB_TOP/services/[% kb_service_name %]

pid_file=$KB_SERVICE_DIR/service.pid

if [ ! -f $pid_file ] ; then
	echo "No pid file $pid_file found for service [% kb_service_name %]" 1>&2
	exit 1
fi

pid=`cat $pid_file`

kill $pid
END






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

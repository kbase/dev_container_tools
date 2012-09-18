#!/usr/bin/perl -w
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
`touch "$name/readme.txt"`;
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
        exit;
}
sub usage {
        print<<EOF;

usage: kb_create_repo -name my_repo 
       kb_create_repo -name my_repo -java

EOF
        exit;
}

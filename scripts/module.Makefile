TOP_DIR = ../..
DEPLOY_RUNTIME ?= /kb/runtime
TARGET ?= /kb/deployment

#include $(TOP_DIR)/tools/Makefile.common

# to wrap scripts and deploy them to $(TARGET)/bin using tools in
# the dev_container. right now, these vars are defined in
# Makefile.common, so it's redundant here.
TOOLS_DIR = $(TOP_DIR)/tools
WRAP_PERL_TOOL = wrap_perl
WRAP_PERL_SCRIPT = bash $(TOOLS_DIR)/$(WRAP_PERL_TOOL).sh
SRC_PERL = $(wildcard scripts/*.pl)

# You can change these if you are putting your tests somewhere
# else or if you are not using the standard .t suffix
CLIENT_TESTS = $(wildcard client-tests/*.t)
SCRIPTS_TESTS = $(wildcard script-tests/*.t)
SERVER_TESTS = $(wildcard server-tests/*.t)

# This is a very client centric view of release engineering.
# We assume our primary product for the community is the client
# libraries and command line interfaces on which specific 
# science applications can be built.

# A service is composed of a client and a server, each of which
# should be independantly deployable. Clients are composed of
# an application programming interface and a command line
# interface. In our make targets, the deploy-server deploys
# the server, the deploy-client deploys the application
# programming interface libraries, and the deploy-scripts deploys
# the command line interface (usually scripts written in a
# scripting language but java executables also qualify), and the
# deploy target would be equivelant to deploying a service (client
# libs, scripts, and server).

# Because the deployment of the server side code depends on the
# specific software module being deployed, the strategy needs
# to be one that leaves this decision to the module developer.
# This is done by having the deploy target depend on the
# deploy-server target. The module developer who chooses for
# good reason not to deploy the server with the client simply
# manages this dependancy accordingly. One option is to have
# a deploy-server target that does nothing, the other is to
# remove the dependancy from the deploy target.

# A smiliar naming convention is used for tests. 


default:

# Test Section

test: test-client test-scripts test-server
	echo "runnint client and script tests"

# test-all is depricated. 
# test-all: test-client test-scripts test-server

# What does it mean to test a client. This is a test of a client
# library. If it is a client-server module, then it should be
# run against a running server. You can say that this also tests
# the server, and I agree. You can add a test-server dependancy
# to the test-client target if it makes sense to you. This test
# example assumes there is already a tested running server.
test-client:
	# run each test
	for t in $(CLIENT_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

# What does it mean to test a script? A script test should test
# the command line scripts. If the script is a client in a client-
# server architecture, then there should be tests against a 
# running server. You can add a test-server dependancy to the
# test-client target. You could also add a deploy-server and
# start-server dependancy to the test-scripts target if it makes
# sense to you. Future versions of the make files for services
# will move in this direction.
test-scripts:
	# run each test
	for t in $(SCRIPT_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

# What does it mean to test a server. A server test should not
# rely on the client libraries or scripts in so far as you should
# not have a test-server target that depends on the test-client
# or test-scripts targets. Otherwise, a circular dependency
# graph could result.
test-server:
	# run each test
	for t in $(SERVER_TESTS) ; do \
		if [ -f $$t ] ; then \
			$(DEPLOY_RUNTIME)/bin/perl $$t ; \
			if [ $$? -ne 0 ] ; then \
				exit 1 ; \
			fi \
		fi \
	done

# Deployment:
# We are assuming our primary product to the community are
# client side application programming interface libraries and
# command line interface (scripts). The deployment of client
# artifacts should not be dependent on deployment of a server.

deploy: deploy-client deploy-scripts deploy-server

# deploy-all is depricated
# deploy-all: deploy-client deploy-scripts deploy-server

deploy-client: deploy-libs deploy-scripts deploy-docs

deploy-libs:

# Deploying scripts need some special care. They need to run
# in a certian runtime environment. Users should not have
# to modify their user environments to run kbase scripts other
# than just sourcing a single user-env script. The creation
# of this user-env script is the responsibility of the code
# that builds all the kbase modules. In the code below, we
# run a script in the dev_container tools directory that 
# wraps perl scripts. The name of the perl wrapper script is
# kept in the WRAP_PERL_SCRIPT make variable. This script
# requires some information that is passed to it by way
# of exported environment variables in the bash script below.

# What does it mean to wrap a perl script? To wrap a perl
# script means that a bash script is created that sets
# all required envirnment variables and then calls the perl
# script using the perl interperter in the kbase runtime.
# For this to work, both the actual script and the newly 
# created shell script have to be deployed. When a perl
# script is wrapped, it is first copied to TARGET/plbin.
# The shell script can now be created because the necessary
# environment variables are known and the location of the
# script is known. 
deploy-scripts:
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	export KB_PERL_PATH=$(TARGET)/lib bash ; \
	for src in $(SRC_PERL) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .pl`; \
		echo install $$src $$base ; \
		cp $$src $(TARGET)/plbin ; \
		$(WRAP_PERL_SCRIPT) "$(TARGET)/plbin/$$basefile" $(TARGET)/bin/$$base ; \
	done

deploy-docs:

deploy-server:


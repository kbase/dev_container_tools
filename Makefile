TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

SRC_PERL = $(wildcard scripts/*.pl)
BIN_PERL = $(addprefix $(BIN_DIR)/,$(basename $(notdir $(SRC_PERL))))

all: bin

deploy: deploy-scripts deploy-libs

deploy-scripts:
	export KB_TOP=$(TARGET); \
	export KB_RUNTIME=$(DEPLOY_RUNTIME); \
	export KB_PERL_PATH=$(TARGET)/lib bash ; \
	for src in $(SRC_PERL) ; do \
		basefile=`basename $$src`; \
		base=`basename $$src .pl`; \
		echo install $$src $$base ; \
		cp $$src $(TARGET)/plbin ; \
		bash $(TOOLS_DIR)/wrap_perl.sh "$(TARGET)/plbin/$$basefile" $(TARGET)/bin/$$base ; \
	done 

deploy-libs:
	rsync -arv lib/. $(TARGET)/lib/.

bin: $(BIN_PERL)

include $(TOP_DIR)/tools/Makefile.common.rules
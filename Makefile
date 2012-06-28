TOP_DIR = ../..
include $(TOP_DIR)/tools/Makefile.common

all: bin

deploy: deploy-scripts deploy-libs

bin: $(BIN_PERL)

include $(TOP_DIR)/tools/Makefile.common.rules

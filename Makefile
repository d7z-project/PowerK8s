ROOT_DIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_DIR= $(ROOT_DIR)target



.PHONY : all
all:
	echo $(BUILD_DIR)

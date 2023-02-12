.DEFAULT_GOAL := all
SRC_DIR:=$(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
OUTPUT_DIR:=$(abspath target)
BINARY_DIR:=$(abspath binary)
TOOLS_DIR:=$(abspath build)

include packages/Packages.mk

.PHONY : all
all: rpm

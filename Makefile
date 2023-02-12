# 动态变量
DOMAIN_DEFAULT:=boot.powerk8s.cn
DOMAIN:=boot.powerk8s.cn
# 动态变量
.DEFAULT_GOAL := all
SRC_DIR:=$(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BINARY_DIR:=$(abspath binary)
SETUP_DIR:=$(abspath binary/setup)
TOOLS_DIR:=$(abspath build)


include packages/Packages.mk
include images/Images.mk

.PHONY : all setup

setup: pkg-setup

all: pkg-all


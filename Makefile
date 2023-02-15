# 定义容器命令
CMD_DOCKER?=podman


include Variables.mk
include packages/Packages.mk
include images/Images.mk


.DEFAULT_GOAL := all
.PHONY : setup all
all: pkg/all img/all

setup: img/setup

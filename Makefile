# 动态变量
DOMAIN_DEFAULT:=boot.powerk8s.cn
DOMAIN:=boot.powerk8s.cn
# 动态变量
.DEFAULT_GOAL := all
SRC_DIR:=$(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BINARY_DIR:=$(abspath binary)
SETUP_DIR:=$(abspath binary/setup)
CACHE_DIR:=$(abspath binary/cache)
TOOLS_DIR:=$(abspath build)
CMD_DOCKER?=podman
DOCKER_RUN:=$(CMD_DOCKER) run -it --rm  -v $(CACHE_DIR)/go:/root/go \
              -v $(SRC_DIR):/workspace --workdir /workspace --env IN_CONTAINER=true
include packages/Packages.mk
include images/Images.mk


.PHONY : all
all: pkg/all img/all

setup: img/setup

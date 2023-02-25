# 内部默认域名
DOMAIN:=boot.powerk8s.cn
# 当前工程路径
SRC_DIR:=$(abspath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
# 最终生成路径
BINARY_DIR:=$(abspath binary)
# Setup动作输出路径
SETUP_DIR:=$(abspath binary/setup)
# 缓存路径
CACHE_DIR:=$(abspath binary/cache)
# 工具包路径
TOOLS_DIR:=$(abspath build)
#RPM输出位置
RPM_OUTPUT:=$(abspath $(BINARY_DIR)/pkg/rpm)
# 容器输出位置
IMG_OUTPUT:=$(abspath $(BINARY_DIR)/img/export)
# 容器合并位置
IMG_PACK_OUTPUT:=$(abspath $(BINARY_DIR)/img/packages)
# 容器运行命令
DOCKER_RUN:=$(CMD_DOCKER) run -it --network host --rm  \
              -v $(SRC_DIR):/workspace --workdir /workspace --env IN_CONTAINER=true
# 镜像地址
IMG_SRC_DIR:=$(abspath $(SRC_DIR)/images)
IMG_STATIC_SRC_DIR:=$(IMG_SRC_DIR)/static
IMG_DYNAMIC_SRC_DIR:=$(IMG_SRC_DIR)/dynamic
IMG_DYN_OUTPUT_DIR:=$(CACHE_DIR)/dyn-img-output


TASK_IMG_DYN_RUN:= DEBUG=1 bash $(TOOLS_DIR)/task/dynamic-task.sh --root '$(SRC_DIR)'
TASK_IMG_SRC_BUILD:=DEBUG=1 bash $(TOOLS_DIR)/task/img-src-build.sh  --root '$(SRC_DIR)'
TASK_IMG_FETCH:=DEBUG=1 bash $(TOOLS_DIR)/task/img-pull-remote.sh --redirect-registry '$(DOMAIN)'
TASK_IMG_SAVE:=DEBUG=1 bash $(TOOLS_DIR)/task/img-save.sh -o '$(IMG_OUTPUT)' --redirect-registry '$(DOMAIN)'
TASK_IMG_PACK:=DEBUG=1 bash $(TOOLS_DIR)/task/img-pack.sh --image-root '$(IMG_OUTPUT)'

PKG_RPM_REPO:= DEBUG=1 bash $(TOOLS_DIR)/pkg/rpm-repos.sh --repos '$(RPM_OUTPUT)'

TOOL_IMG_STATIC_GEN:=DEBUG=1 bash $(TOOLS_DIR)/gen/img-static-gen.sh --src '$(IMG_STATIC_SRC_DIR)'
TOOL_IMG_DYN_GEN:=DEBUG=1 bash $(TOOLS_DIR)/gen/img-dyn-gen.sh --src '$(IMG_DYNAMIC_SRC_DIR)'
TOOL_IMG_DYN_AFTER_GEN:=DEBUG=1 bash $(TOOLS_DIR)/gen/img-dyn-after-gen.sh --src '$(IMG_DYNAMIC_SRC_DIR)' --result-list $(IMG_DYN_OUTPUT_DIR)

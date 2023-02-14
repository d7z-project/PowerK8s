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
# 容器运行命令
DOCKER_RUN:=$(CMD_DOCKER) run -it --rm  \
              -v $(SRC_DIR):/workspace --workdir /workspace --env IN_CONTAINER=true

TASK_DYN:= DEBUG=1 bash $(TOOLS_DIR)/task/dynamic-task.sh --root '$(SRC_DIR)'
PKG_RPM_REPO:= DEBUG=1 bash $(TOOLS_DIR)/pkg/rpm-repos.sh --repos '$(RPM_OUTPUT)'
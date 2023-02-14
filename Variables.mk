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
# 容器运行命令
DOCKER_RUN:=$(CMD_DOCKER) run -it --rm  \
              -v $(SRC_DIR):/workspace --workdir /workspace --env IN_CONTAINER=true

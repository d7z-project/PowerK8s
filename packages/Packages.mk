PKG_SRC_DIR:=$(abspath $(SRC_DIR)/packages)
TOOL_RPM:=$(abspath $(TOOLS_DIR)/pkg/rpm.sh)
RPM_OUTPUT:=$(abspath $(BINARY_DIR)/pkg/rpm)
# 编译参数，容器内使用
RPM_TOOL_DEFAULT_PARAMS:=bash $(TOOL_RPM) build --output $(RPM_OUTPUT)  --auto --debug \
--local-repository $(RPM_OUTPUT)

CONTAINER_PKG_ARGS:=(test -d $(CACHE_DIR)/go || mkdir -p $(CACHE_DIR)/go) && $(CMD_DOCKER) run -it --rm --name el7-builder -v $(CACHE_DIR)/go:/root/go \
  -v $(SRC_DIR):/workspace --workdir /workspace --env IN_CONTAINER=true

ifeq ($(IN_CONTAINER), true)
-include $(SETUP_DIR)/rpm.mk
-include $(SETUP_DIR)/deb.mk
pkg/setup/rpm:
	bash $(TOOL_RPM) setup --project $(PKG_SRC_DIR) -o $(SETUP_DIR)/rpm.mk --debug
endif

pkg/all: pkg/rpm/el7

pkg/rpm/el7: img/builder/rpm/el7
	 $(CONTAINER_PKG_ARGS) $(DOMAIN)/builder/rpm:el7 sh -c "make pkg/setup/rpm && make pkg/rpm"

pkg-rpm-el7-dev: img/builder/rpm/el7
	$(CONTAINER_PKG_ARGS) $(DOMAIN)/builder/rpm:el7 bash

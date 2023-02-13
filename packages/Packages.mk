PKG_SRC_DIR:=$(abspath $(SRC_DIR)/packages)
TOOL_RPM:=$(abspath $(TOOLS_DIR)/pkg/rpm.sh)
RPM_OUTPUT:=$(abspath $(BINARY_DIR)/pkg/rpm)
# 编译参数，容器内使用
RPM_TOOL_BUILD_PARAMS:=bash $(TOOL_RPM) build --output $(RPM_OUTPUT) --auto --debug  --cache $(CACHE_DIR)

RPM_TOOL_LOCAL_INSTALL_PARAMS:=bash $(TOOL_RPM) local-install --debug --local-repository $(RPM_OUTPUT)

CONTAINER_PKG_ARGS:=(test -d $(CACHE_DIR)/go || mkdir -p $(CACHE_DIR)/go) && $(CMD_DOCKER) run -it --rm  -v $(CACHE_DIR)/go:/root/go \
  -v $(SRC_DIR):/workspace --workdir /workspace --env IN_CONTAINER=true

ifeq ($(IN_CONTAINER), true)
-include $(SETUP_DIR)/rpm.mk
-include $(SETUP_DIR)/deb.mk
pkg/setup/rpm:
	bash $(TOOL_RPM) setup --project $(PKG_SRC_DIR) -o $(SETUP_DIR)/rpm.mk --debug
pkg/rpm/create_repo:
	bash $(TOOL_RPM) create-repo --debug -i $(RPM_OUTPUT)
endif

pkg/all: pkg/rpm/el7 pkg/rpm/el9

pkg/rpm/el7: img/builder/rpm/el7
	$(CONTAINER_PKG_ARGS) --name el7-builder $(DOMAIN)/builder/rpm:el7 \
  sh -c 'make pkg/setup/rpm && make -j$(nproc) pkg/rpm/build && make pkg/rpm/create_repo'

pkg/rpm/el9: img/builder/rpm/el9
	$(CONTAINER_PKG_ARGS) --name el9-builder $(DOMAIN)/builder/rpm:el9 \
  sh -c 'make pkg/setup/rpm && make -j$(nproc) pkg/rpm/build && make pkg/rpm/create_repo'

pkg-rpm-el7-dev: img/builder/rpm/el7
	$(CONTAINER_PKG_ARGS) --name el7-test $(DOMAIN)/builder/rpm:el7 bash

PKG_SRC_DIR:=$(abspath $(SRC_DIR)/packages)
TOOL_RPM:=$(abspath $(TOOLS_DIR)/pkg/rpm.sh)
# 编译参数，容器内使用
RPM_TOOL_BUILD_PARAMS:=bash $(TOOL_RPM) build --output $(RPM_OUTPUT) --auto --debug  --cache $(CACHE_DIR)

RPM_TOOL_LOCAL_INSTALL_PARAMS:=bash $(TOOL_RPM) local-install --debug --local-repository $(RPM_OUTPUT)

CONTAINER_PKG_ARGS:=(test -d $(CACHE_DIR)/go || mkdir -p $(CACHE_DIR)/go) && $(DOCKER_RUN) -v $(CACHE_DIR)/go:/root/go

ifeq ($(IN_CONTAINER), true)
-include $(SETUP_DIR)/rpm.mk
-include $(SETUP_DIR)/deb.mk
pkg/setup/rpm:
	DEBUG=1 bash $(TOOL_RPM) setup --project $(PKG_SRC_DIR) -o $(SETUP_DIR)/rpm.mk --debug

pkg/repos/create:
	$(PKG_RPM_REPO) --create

pkg/repos/force-install:
	$(PKG_RPM_REPO) --install

pkg/repos/install: pkg/repos/create
	$(PKG_RPM_REPO) --install

pkg/repos/remove:
	$(PKG_RPM_REPO) --remove

pkg/repos/delete: pkg/repos/remove
	$(PKG_RPM_REPO) --delete
endif

ifdef PACKAGES
pkg/install/rpm:
	$(RPM_TOOL_LOCAL_INSTALL_PARAMS) --local-package $(PACKAGES)

endif

ifdef SKIP_BUILD_PACKAGES
pkg/all:
else
pkg/all: pkg/rpm/el7 pkg/rpm/el9
endif

ifndef SKIP_BUILD_PACKAGES

pkg/rpm/el7: img/builder/rpm/el7
	$(CONTAINER_PKG_ARGS) --name el7-builder $(DOMAIN)/builder/rpm:el7 \
  sh -c 'make pkg/setup/rpm && make -j1 pkg/rpm/build && make pkg/repos/create'

pkg/rpm/el9: img/builder/rpm/el9
	$(CONTAINER_PKG_ARGS) --name el9-builder $(DOMAIN)/builder/rpm:el9 \
  sh -c 'make pkg/setup/rpm && make -j1 pkg/rpm/build && make pkg/repos/create'

else

pkg/rpm/el7:
pkg/rpm/el9:

endif

pkg-rpm-el7-dev: img/builder/rpm/el7
	$(CONTAINER_PKG_ARGS) --name el7-test $(DOMAIN)/builder/rpm:el7 bash

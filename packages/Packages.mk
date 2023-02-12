PKG_SRC_DIR:=$(abspath $(SRC_DIR)/packages)
TOOL_RPM:=$(abspath $(TOOLS_DIR)/pkg/rpm.sh)
RPM_OUTPUT:=$(abspath $(BINARY_DIR)/pkg/rpm)
RPM_TOOL_DEFAULT_PARAMS:=bash $(TOOL_RPM) build --output $(RPM_OUTPUT)  --auto --debug \
--local-repository $(RPM_OUTPUT)

-include $(SETUP_DIR)/rpm.mk
-include $(SETUP_DIR)/deb.mk

pkg-setup:pkg-rpm_setup
# 自动识别所有 RPM 内容，并添加到 Target
pkg-rpm_setup:
	bash $(TOOL_RPM) setup --project $(PKG_SRC_DIR) -o $(SETUP_DIR)/rpm.mk --debug

pkg-all: pkg-rpm_all
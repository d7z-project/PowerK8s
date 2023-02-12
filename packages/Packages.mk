PKG_SRC_DIR:=$(abspath $(SRC_DIR)/packages)
TOOL_RPM:=$(abspath $(TOOLS_DIR)/pkg/rpm.sh)
RPM_OUTPUT:=$(abspath $(BINARY_DIR)/pkg/rpm)
RPM_TOOL_DEFAULT_PARAMS:=bash $(TOOL_RPM) build --output $(RPM_OUTPUT)  --auto --debug \
--local-repository $(RPM_OUTPUT)

-include $(SETUP_DIR)/rpm.mk

setup_rpm:
	bash $(TOOL_RPM) setup --project $(PKG_SRC_DIR) -o $(SETUP_DIR)/rpm.mk --debug

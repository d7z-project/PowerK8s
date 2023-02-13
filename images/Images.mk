IMG_SRC_DIR:=$(abspath $(SRC_DIR)/images)
TOOL_IMG:=$(abspath $(TOOLS_DIR)/img.sh)
IMG_OUTPUT:=$(abspath $(BINARY_DIR)/img)
-include $(SETUP_DIR)/img.mk

img/all:

img/setup:
	bash $(TOOL_IMG) setup --debug -i $(IMG_SRC_DIR) -o $(SETUP_DIR)/img.mk --registry $(DOMAIN_DEFAULT)


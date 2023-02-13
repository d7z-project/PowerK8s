IMG_SRC_DIR:=$(abspath $(SRC_DIR)/images)
TOOL_IMG:=$(abspath $(TOOLS_DIR)/img.sh)
IMG_OUTPUT:=$(abspath $(BINARY_DIR)/img)
-include $(SETUP_DIR)/img.mk

img/base/centos/7:
	$(CMD_DOCKER) build -t $(DOMAIN)/base/centos:7 \
  -f $(IMG_SRC_DIR)/base/centos/Dockerfile.7 $(IMG_SRC_DIR)/base

img/builder/rpm/el7: img/base/centos/7
	$(CMD_DOCKER) build -t $(DOMAIN)/builder/rpm:el7 \
  -f $(IMG_SRC_DIR)/builder/rpm/Dockerfile.el7 $(IMG_SRC_DIR)/builder

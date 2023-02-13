IMG_SRC_DIR:=$(abspath $(SRC_DIR)/images)
TOOL_IMG:=$(abspath $(TOOLS_DIR)/img.sh)
IMG_OUTPUT:=$(abspath $(BINARY_DIR)/img)
-include $(SETUP_DIR)/img.mk

img/all:

img/setup:
	bash $(TOOL_IMG) setup --debug -i $(IMG_SRC_DIR) -o $(SETUP_DIR)/img.mk --registry $(DOMAIN_DEFAULT)

test:
	$(DOCKER_RUN) $(DOMAIN)/base/centos:7 \
  sh -c 'make pkg/install/rpm PACKAGES=runc,kubernetes-kubeadm >&2 && kubeadm config images list 2> /dev/null' | grep boot.powerk8s.cn

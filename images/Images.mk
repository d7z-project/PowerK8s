IMG_SRC_DIR:=$(abspath $(SRC_DIR)/images)
IMG_STATIC_SRC_DIR:=$(IMG_SRC_DIR)/static
IMG_DYNAMIC_SRC_DIR:=$(IMG_SRC_DIR)/dynamic
TOOL_IMG:=$(abspath $(TOOLS_DIR)/img.sh)
IMG_OUTPUT:=$(BINARY_DIR)/img
STATIC_IMG_LIST:=$(CACHE_DIR)/ImgList-static.txt
DYN_IMG_LIST:=$(CACHE_DIR)/ImgList-dyn.txt
DYN_IMG_INFO_OUTPUT:=$(CACHE_DIR)/dyn-img-output


-include $(SETUP_DIR)/img.static.mk
-include $(SETUP_DIR)/img.dynamic.mk

img/all:

img/setup/static:
	bash $(TOOL_IMG) setup --debug -i $(IMG_STATIC_SRC_DIR) --path '$$(IMG_STATIC_SRC_DIR)' \
  -o $(SETUP_DIR)/img.static.mk --registry $(DOMAIN) --save-provides '$(STATIC_IMG_LIST)' --load-provides '$(CACHE_DIR)/test.txt'

img/setup/dyn: img/setup/static
	bash $(TOOL_IMG) container-run-setup -i '$(IMG_DYNAMIC_SRC_DIR)' -o '$(SETUP_DIR)/img.dynamic.mk' \
  --load-provides '$(STATIC_IMG_LIST)' --debug


test:
	$(DOCKER_RUN) $(DOMAIN)/base/centos:7 \
  sh -c 'make pkg/install/rpm PACKAGES=runc,kubernetes-kubeadm >&2 && kubeadm config images list 2> /dev/null' | grep boot.powerk8s.cn


TOOL_IMG:=$(abspath $(TOOLS_DIR)/img.sh)
IMG_OUTPUT:=$(BINARY_DIR)/img
STATIC_IMG_LIST:=$(CACHE_DIR)/ImgList-static.txt
DYN_IMG_LIST:=$(CACHE_DIR)/ImgList-dyn.txt

-include $(SETUP_DIR)/img.static.mk
-include $(SETUP_DIR)/img.dynamic.mk
-include $(SETUP_DIR)/img.dyn-after.mk

img/all:
	make dyn/img/all && make img/setup/dyn-after && make dyn/img/fetch

img/setup: img/setup/static img/setup/dyn

img/setup/static:
	$(TOOL_IMG_STATIC_GEN) -o '$(SETUP_DIR)/img.static.mk' --export-provides '$(STATIC_IMG_LIST)' --registry '$(DOMAIN)'

img/setup/dyn: img/setup/static
	$(TOOL_IMG_DYN_GEN) -o '$(SETUP_DIR)/img.dynamic.mk' --include '$(STATIC_IMG_LIST)'

img/setup/dyn-after: dyn/img/all
	$(TOOL_IMG_DYN_AFTER_GEN) -o '$(SETUP_DIR)/img.dyn-after.mk'

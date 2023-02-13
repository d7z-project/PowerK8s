IMG_SRC_DIR:=$(abspath $(SRC_DIR)/images)

img/base/centos/7:
	$(CMD_DOCKER) build -t $(DOMAIN)/base/centos:7 \
  -f $(IMG_SRC_DIR)/base/Dockerfile.centos_7 $(IMG_SRC_DIR)/base

img/builder/rpm/el7: img/base/centos/7
	$(CMD_DOCKER) build -t $(DOMAIN)/builder/rpm:el7 \
  -f $(IMG_SRC_DIR)/builder/Dockerfile.rpm_el7 $(IMG_SRC_DIR)/builder

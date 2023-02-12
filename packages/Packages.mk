SRC_DIR:=$(abspath $(SRC_DIR)/packages)
TOOL_RPM_BUILD:=$(abspath $(TOOLS_DIR)/pkg/rpm.sh)
PATH_RPM_OUTPUT:=$(abspath $(BINARY_DIR)/pkg/rpm)
RPM_TOOL_DEFAULT_PARAMS:=bash $(TOOL_RPM_BUILD) build --output $(PATH_RPM_OUTPUT)  --auto --debug \
--local-repository $(PATH_RPM_OUTPUT)

rpm:  rpm_cni-plugins rpm_containerd rpm_kubernetes rpm_crictl rpm_helm  \
	rpm_nerdctl  rpm_powerk8s-tls rpm_runc rpm_zot

rpm_golang:
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/golang-bin

rpm_cni-plugins: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/cni-plugins --local-package golang-bin

rpm_containerd: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/containerd --local-package golang-bin

rpm_kubernetes: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/kubernetes --local-package golang-bin \
  --exclude-package kubernetes

rpm_crictl: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/crictl --local-package golang-bin

rpm_helm: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/helm --local-package golang-bin

rpm_nerdctl: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/nerdctl --local-package golang-bin

rpm_powerk8s-tls:
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/powerk8s-tls

rpm_runc: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/runc --local-package golang-bin

rpm_yq: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/yq --local-package golang-bin

rpm_zot: rpm_golang
	$(RPM_TOOL_DEFAULT_PARAMS) --project $(SRC_DIR)/zot --local-package golang-bin

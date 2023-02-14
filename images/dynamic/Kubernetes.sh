#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
## 镜像地址输出到 $OCI_IMAGE_OUTPUT ,以纯文本换行输出
make pkg/repos/force-install
yum install kubernetes-kubeadm -y
HTTP_PROXY=no HTTPS_PROXY=no kubeadm config images list | sed 's/boot.powerk8s.cn/registry.k8s.io/g' >"$OCI_IMAGE_OUTPUT"
exit 0

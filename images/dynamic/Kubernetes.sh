#!/usr/bin/env bash
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
## 镜像地址输出到 $OCI_IMAGE_OUTPUT ,以纯文本换行输出
make pkg/repos/force-install
yum install kubernetes-kubeadm -y
kubeadm config images list > "$OCI_IMAGE_OUTPUT"

pwd

exit 0

#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
make pkg/repos/force-install
yum install helm -y
helm template cni-tigera helm/tigera-operator --set registry=quay.io | grep "image:" | sed 's/boot.powerk8s.cn/quay.io/g' | awk '{print $2}' | sort -u > "$OCI_IMAGE_OUTPUT"
exit 0

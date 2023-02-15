#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
make pkg/repos/force-install
yum install helm -y
helm template cni-flannel helm/cni-flannel --set registry=docker.io | grep "image:" | awk '{print $2}' | sort -u > "$OCI_IMAGE_OUTPUT"

exit 0

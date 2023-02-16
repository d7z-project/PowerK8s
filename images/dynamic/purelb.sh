#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
make pkg/repos/force-install
yum install -y helm
helm template purelb helm/purelb --set image.repository=registry.gitlab.com/purelb/purelb | grep "image:" | awk '{print $2}'  | sort -u >"$OCI_IMAGE_OUTPUT"
exit 0

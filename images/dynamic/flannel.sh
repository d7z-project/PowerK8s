#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
make pkg/repos/force-install
yum install helm -y
echo "$OCI_IMAGE_OUTPUT"
echo >"$OCI_IMAGE_OUTPUT"
exit 0

#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
make pkg/repos/force-install
yum install -y helm
helm template kpack helm/kubevela --set imageRegistry=docker.io/ | grep -E "image: *docker.io" | awk '{print $2}' | grep -v 'windows' | sort -u >"$OCI_IMAGE_OUTPUT"
exit 0

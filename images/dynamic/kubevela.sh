#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
make pkg/repos/force-install
yum install -y helm
helm template kpack helm/kubevela --set imageRegistry=docker.io/ | grep -E "image: *(docker.io|boot)"  | awk '{print $2}' | grep -v 'windows' | sort -u >"$OCI_IMAGE_OUTPUT"
helm template kpack helm/vela-rollout | grep -E "image: *boot" | awk '{print $2}' | sed 's|boot.powerk8s.cn|docker.io|g' | grep -v 'windows' | sort -u >>"$OCI_IMAGE_OUTPUT"
cat images/static/oamdev/addons/fluxcd/resources/**/* | grep boot | awk '{print $2}' | sed -e 's|"||g' -e 's|boot.powerk8s.cn|docker.io|g' |  sort -u >>"$OCI_IMAGE_OUTPUT"
exit 0

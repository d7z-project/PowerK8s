#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
make pkg/repos/force-install
yum install -y helm
helm template ingress-nginx helm/ingress-nginx --set controller.opentelemetry.enabled=true | grep "image:" | sed 's/boot.powerk8s.cn/registry.k8s.io/g' | awk '{print $2}'  | sort -u >"$OCI_IMAGE_OUTPUT"
exit 0

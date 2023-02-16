#!/usr/bin/env bash
set -xe
##Image=boot.powerk8s.cn/base/centos:7
##DependsTarget=pkg/rpm/el7
yum install createrepo -y
make pkg/repos/install
yum install calico-operator -y
touch "$OCI_IMAGE_OUTPUT"
operator --print-images=list | grep 'tigera/operator' >>"$OCI_IMAGE_OUTPUT"
operator --print-images=list 2>&1 | grep 'boot.powerk8s.cn' | while IFS= read -r image_name; do
  if [[ "$image_name" = boot.powerk8s.cn/tigera/* ]]; then
    new_image="${image_name//boot.powerk8s.cn/quay.io}"
  elif [[ "$image_name" = boot.powerk8s.cn/calico/* ]]; then
    new_image="${image_name//boot.powerk8s.cn/docker.io}"
  else
    continue
  fi
  echo "$new_image" | grep -v 'windows' | grep -v 'unique-caldron-775' |  grep -v 'tigera' >>"$OCI_IMAGE_OUTPUT" || :
done

#helm template cni-flannel helm/cni-flannel --set registry=docker.io | grep "image:" | awk '{print $2}' | sort -u > "$OCI_IMAGE_OUTPUT"

exit 0

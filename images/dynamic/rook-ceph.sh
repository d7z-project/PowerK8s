#!/usr/bin/env bash
set -e
##Image=boot.powerk8s.cn/base/centos:7
cat "helm/rook-ceph-cluster/values.yaml"  | grep -E 'image::' |  awk '{print $2}' | sort -u > "$OCI_IMAGE_OUTPUT"
cat helm/rook-ceph-operator/values.yaml | grep -E 'image::' | awk '{print $2}' | sort -u >> "$OCI_IMAGE_OUTPUT"
exit 0

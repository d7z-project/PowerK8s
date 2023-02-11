#!/bin/bash
IMAGES=(
boot.powerk8s.cn/flannel/flannel:v0.21.1
 boot.powerk8s.cn/flannel/flannel-cni-plugin:v1.1.2
)
export NO_PROXY="boot.powerk8s.cn:$NO_PROXY"
for image in "${IMAGES[@]}" ; do
  old=${image/boot.powerk8s.cn/docker.io}
  podman pull $old
  podman tag $old $image
  podman push  --tls-verify=false $image
  podman rmi $image
done
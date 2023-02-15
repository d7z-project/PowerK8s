#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e
img_id=''
save_root_dir=''
redirect_registry=''
while [[ $# -ge 1 ]]; do
  case $1 in
  --id | -i)
    shift
    img_id=$1
    shift
    ;;
  --output | -o)
    shift
    save_root_dir="$1"
    shift
    ;;
  --redirect-registry)
    shift
    redirect_registry="$1"
    shift
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done

os_arch="$(podman info | grep ' arch: ' | awk '{print $2}' || panic "未知系统架构！")"

test -d "$save_root_dir/$os_arch" || mkdir -p "$save_root_dir/$os_arch"

save_file_path="$save_root_dir/$os_arch/$(echo "$img_id" | sed -e 's|/| |' -e 's|:|/|g' | awk '{print $2}')"
debug "镜像 $img_id 将保存到 $save_file_path"
test -d "$(dirname "$save_file_path")" || mkdir -p "$(dirname "$save_file_path")"
if [ ! -f "$save_file_path" ]; then
  if [ "$redirect_registry" ]; then
    old_registry="$(echo "$img_id" | sed 's|/| |' | awk '{print $1}')"
    img_new_id="$redirect_registry/$(echo "$img_id" | sed 's|/| |' | awk '{print $2}')"
    if [ ! "$old_registry" = "$redirect_registry" ]; then
      podman image rm "$img_new_id" || :
      podman tag "$img_id" "$img_new_id" || panic "无法重命名镜像 $img_id 到 $img_new_id"
    fi
    podman save --format oci-archive -o "$save_file_path" "$img_new_id" || panic "未发现镜像 $img_id"
  else
    podman save --format oci-archive -o "$save_file_path" "$img_id" || panic "未发现镜像 $img_id"
  fi
else
  debug "本地镜像 $save_file_path 已存在 ，跳过 $img_id"
fi

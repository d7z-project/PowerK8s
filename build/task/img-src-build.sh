#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e
img_id=''
root_dir=''
while [[ $# -ge 1 ]]; do
  case $1 in
  --id | -i)
    shift
    img_id=$1
    shift
    ;;
  --root)
    shift
    root_dir="$1"
    shift
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done
img_path="$(echo "$img_id" | sed -e 's|:| |g' -e 's|/| |' | awk '{print $2}')"
img_tag="$(basename "${img_id//:/\/}")"
src_path="$root_dir/images/static/$img_path/Dockerfile.$img_tag"
# TODO: 版本比较
test -f "$src_path" || panic "Dockerfile $src_path 不存在"
podman build -t "$img_id" -f "$src_path" \
  "$root_dir"

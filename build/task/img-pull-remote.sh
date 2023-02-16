#!/usr/bin/env bash
UTIL_TYPE=img/pull
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e
img_id=''
redirect_registry=''
while [[ $# -ge 1 ]]; do
  case $1 in
  --id | -i)
    shift
    # shellcheck disable=SC2001
    img_id="$(echo "$1" | sed 's/"//g')"
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
UTIL_TYPE="$UTIL_TYPE#$img_id"
exists_result="$(podman images --filter "reference=$img_id" --format "$img_id" --noheading 2>/dev/null)"
if [[ "$exists_result" =~ $img_id ]]; then
  debug " 已存在镜像，跳过拉取"
else
  debug "开始拉取镜像"
  podman pull "$img_id"
fi
new_id="$redirect_registry/$(echo "$img_id" | sed -e 's|/| |' | awk '{print $2}')"
if [ ! "$new_id" = "$img_id" ]; then
  podman image rm "$new_id" || :
  podman tag "$img_id" "$new_id" >/dev/null
fi

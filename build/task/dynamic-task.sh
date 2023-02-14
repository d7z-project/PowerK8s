#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e
# 此模块用于运行容器化测试任务

dyn_name=''
result_path=''
root_path=''

while [[ $# -ge 1 ]]; do
  case $1 in
  -n | --name)
    shift
    dyn_name=$1
    shift
    ;;
  --root)
    shift
    root_path=$1
    shift
    ;;
  -o | --result-path)
    shift
    result_path=$1
    shift
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done
host_src_path="$root_path/images/dynamic/$dyn_name.sh"
test -f "$host_src_path" || panic "配置 $host_src_path 不存在！"
test -d "$result_path" || mkdir -p "$result_path"
host_result_path="$result_path/$dyn_name.list"
if [ "$host_result_path" -nt "$host_src_path" ]; then
  debug "数据 $host_result_path 比源码 $host_src_path 新，跳过载入"
  exit 0
fi
test ! -f "$host_result_path" || rm "$host_result_path"
image_id="$(grep -E "^## *Image=" <"$host_src_path" | head -n 1 | sed 's/## *Image=//g')"
debug "开始运行 $dyn_name 任务"
podman run -it --rm --name "dyn-$dyn_name" -v "$root_path:/workspace" \
  --workdir "/workspace" -v "$result_path:/builder/result" -e IN_CONTAINER=true \
  -e "OCI_IMAGE_OUTPUT=/builder/result/$dyn_name.list" "$image_id" sh "/workspace/images/dynamic/$dyn_name.sh"
debug "运行 $dyn_name 任务完成！"
if [ -f "$host_result_path" ]; then
  debug "发现返回结果 $(basename "$host_result_path"),任务完成"
  touch -c "$host_result_path"
else
  panic "未找到返回结果，任务 $dyn_name 失败！"
fi

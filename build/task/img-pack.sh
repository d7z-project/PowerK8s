#!/usr/bin/env bash
UTIL_TYPE=img/pack
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e
image_list_file=''
image_root_dir=''
out_file=''
while [[ $# -ge 1 ]]; do
  case $1 in
  --list)
    shift
    image_list_file=$1
    shift
    ;;
  --image-root)
    shift
    image_root_dir=$1
    shift
    ;;
  --output | -o)
    shift
    out_file=$1
    shift
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done

check_commands podman tar
check_files "$image_list_file"
check_dirs "$image_root_dir"
fix_files_path "$out_file" || panic "未指定输出路径"
UTIL_TYPE="$UTIL_TYPE/$(basename "$image_list_file")"
debug "检查缓存"
os_arch="$(podman info | grep ' arch: ' | awk '{print $2}' || panic "未知系统架构！")"
if [ -f "$out_file" ] && [ "$out_file" -nt "$image_list_file" ]; then
  debug "已有缓存 $out_file ，跳过导出。"
  exit 0
else
  test ! -f "$out_file" || rm "$out_file"
  debug "缓存未命中"
fi

tar_files=()
while IFS= read -r image; do
  image_path="$os_arch/$(echo "$image" | sed -e 's|/| |' -e "s|:|/|g" | awk '{print $2}')"
  tar_files+=("$image_path")
done <"$image_list_file"
debug "开始导出"
(
  cd "$image_root_dir" && tar zcvf "$out_file" "${tar_files[@]}"
)
debug "导出完成，数据导出到 $out_file ."

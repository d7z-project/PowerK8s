#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e

src_dir=''
out_file=''
registry=''
include_img_file=''
save_provides_file=''
while [[ $# -ge 1 ]]; do
  case $1 in
  --src | -i)
    shift
    src_dir=$1
    shift
    ;;
  --output | -o)
    shift
    out_file=$1
    shift
    ;;
  --include)
    shift
    include_img_file="$1"
    shift
    ;;
  --export-provides)
    shift
    save_provides_file="$1"
    shift
    ;;
  --registry)
    shift
    registry="$1"
    shift
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done

test -d "$src_dir" || panic "$src_dir 路径不存在"
test -d "$(dirname "$out_file")" || mkdir -p "$(dirname "$out_file")"
test ! -f "$out_file" || rm "$out_file"
touch "$out_file"
test "$save_provides_file" && (test ! -f "$save_provides_file" || rm "$save_provides_file") &&
  (test -f "$save_provides_file" || touch "$save_provides_file")
local_images=()
if [ -f "$include_img_file" ]; then
  while read -r find_image; do
    # shellcheck disable=SC2001
    local_images+=("$find_image")
  done <"$include_img_file"
fi
# 建立本地缓存
while IFS= read -r -d '' docker_file; do
  # shellcheck disable=SC2001
  path="$(dirname "$(echo "$docker_file" | sed "s|$src_dir/||g")")"
  tag="$(basename "$docker_file" | sed "s|Dockerfile.||g")"
  local_images+=("$registry/$path:$tag=img/$path/$tag")
done < <(find "$src_dir" -type f -name 'Dockerfile.*' -print0)
find "$src_dir" -type f -name 'Dockerfile.*' -print0 | while IFS= read -r -d '' docker_file; do
  depends=()
  # shellcheck disable=SC2001
  path="$(dirname "$(echo "$docker_file" | sed "s|$src_dir/||g")")"
  tag="$(basename "$docker_file" | sed "s|Dockerfile.||g")"
  for local_image in "${local_images[@]}"; do
    _tag="^FROM *$(echo "$local_image" | sed 's/=/ /g' | awk '{print $1}').*"
    _link="$(echo "$local_image" | sed 's/=/ /g' | awk '{print $2}')"
    if grep -E "$_tag" <"$docker_file" >/dev/null 2>&1; then
      depends+=("$_link")
    fi
  done
  if [ "$save_provides_file" ]; then
    echo "$registry/$path:$tag=img/$path/$tag" >>"$save_provides_file"
  fi
  {
    echo -e "img/$path/$tag: $(
      IFS=$' '
      echo "${depends[*]}"
    )"
      echo -e "\t\$(TASK_IMG_SRC_BUILD) --id \$(DOMAIN)/$path:$tag"
    echo ""
  } >>"$out_file"
done

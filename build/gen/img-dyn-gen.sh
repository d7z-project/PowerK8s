#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e

src_dir=''
out_file=''
include_img_file=''
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
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done

test -d "$src_dir" || panic "$src_dir 路径不存在"
test -d "$(dirname "$out_file")" || mkdir -p "$(dirname "$out_file")"
test ! -f "$out_file" || rm "$out_file"
touch "$out_file"
local_images=()
if [ -f "$include_img_file" ]; then
  while read -r find_image; do
    # shellcheck disable=SC2001
    local_images+=("$find_image")
  done <"$include_img_file"
fi
all_target=()
while IFS= read -r -d '' dyn_spec; do
  if grep -E "^## *Image=" <"$dyn_spec" >/dev/null 2>&1; then
    dyn_depend_image="$(grep -E "^## *Image=" <"$dyn_spec" | head -n 1 | sed 's/## *Image=//g')"
    dyn_name="$(basename "$dyn_spec" | sed -e 's/.sh$//g' -e 's|:|/|g')"
    dyn_depend_target="$( (grep -E "^## *DependsTarget=" <"$dyn_spec" | head -n 1 | sed 's/## *DependsTarget=//g') || echo "")"
    dyn_task_name="dyn/img/$dyn_name"
    all_target+=("$dyn_task_name")
    {
      echo -n "$dyn_task_name: $dyn_depend_target"
      for local_img in "${local_images[@]}"; do
        if [[ "$local_img" = $dyn_depend_image=* ]]; then
          echo -n " $(echo "$local_img" | sed 's/=/ /g' | awk '{print $2}')"
        fi
      done
      echo -e "\n\t\$(TASK_IMG_DYN_RUN) -o '\$(IMG_DYN_OUTPUT_DIR)' -n $dyn_name"
      echo ""
    } >>"$out_file"
  fi
done < <(find "$src_dir" -type f -name '*.sh' -print0)
echo "dyn/img/all: ${all_target[*]}" >>"$out_file"

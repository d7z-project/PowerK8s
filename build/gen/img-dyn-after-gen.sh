#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e

src_dir=''
img_dyn_dir=''
out_file=''
while [[ $# -ge 1 ]]; do
  case $1 in
  --src | -i)
    shift
    src_dir=$1
    shift
    ;;
  --result-list)
    shift
    img_dyn_dir=$1
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
test -d "$src_dir" || panic "$src_dir 路径不存在"
test -d "$(dirname "$out_file")" || mkdir -p "$(dirname "$out_file")"
test ! -f "$out_file" || rm "$out_file"
touch "$out_file"
task_dyn=()
task_save_dyn=()
task_pack_dyn=()
{
  while IFS= read -r -d '' dyn_spec; do
    if grep -E "^## *Image=" <"$dyn_spec" >/dev/null 2>&1; then
      dyn_name="$(basename "$dyn_spec" | sed 's/.sh$/ /g' | awk '{print $1}')"
      dyn_result_path="$img_dyn_dir/$dyn_name.list"
      test -f "$dyn_result_path" || panic "未发现 img/dyn/$dyn_name 的资源 $dyn_result_path"
      task_current_dyn=()
      task_current_save_dyn=()
      while IFS= read -r image; do
        img_task_id="img/$dyn_name/$(echo "$image" | sed -e 's|/| |' -e 's|:|/|g' | awk '{print $2}')"
        task_current_dyn+=("$img_task_id")
        echo "$img_task_id :"
        echo -e "\t\$(TASK_IMG_FETCH) --id '$image'\n"
        task_current_save_dyn+=("$img_task_id/save")
        echo "$img_task_id/save: $img_task_id"
        echo -e "\t\$(TASK_IMG_SAVE)  --id '$image'\n"
      done <"$dyn_result_path"
      echo -e "dyn/img/$dyn_name/fetch: ${task_current_dyn[*]}\n"
      echo -e "dyn/img/$dyn_name/save: ${task_current_save_dyn[*]}\n"
      echo -e "dyn/img/$dyn_name/pack: dyn/img/$dyn_name/save"
      echo -e "\t\$(TASK_IMG_PACK) --list \$(IMG_DYN_OUTPUT_DIR)/$dyn_name.list -o '\$(IMG_PACK_OUTPUT)/$dyn_name.tgz'\n"
      task_dyn+=("dyn/img/$dyn_name/fetch")
      task_save_dyn+=("dyn/img/$dyn_name/save")
      task_pack_dyn+=("dyn/img/$dyn_name/pack")
    fi
  done < <(find "$src_dir" -type f -name '*.sh' -print0)
  echo -e "dyn/img/fetch: ${task_dyn[*]}\n"
  echo -e "dyn/img/save: ${task_save_dyn[*]}\n"
  echo -e "dyn/img/pack: ${task_pack_dyn[*]}\n"
} >>"$out_file"

#!/usr/bin/env bash
set -e
child_command="$1"
shift
enable_debug='0'
src_path=''
out_path=''
registry=''

while [[ $# -ge 1 ]]; do
  case $1 in
  --project | -i)
    shift
    src_path=$1
    shift
    ;;
  --registry)
    shift
    registry=$1
    shift
    ;;
  --output | -o)
    shift
    out_path=$1
    shift
    ;;
  --debug)
    shift
    enable_debug='1'
    ;;
  *)
    echo "Wrong parameter: $1" >&2 && exit 1
    ;;
  esac
done

function func_setup() {
  test -d "$src_path" || panic "$src_path 路径不存在"
  test -d "$(dirname "$out_path")" || mkdir -p "$(dirname "$out_path")"
  test ! -f "$out_path" || rm "$out_path"
  touch "$out_path"
  local_images=()
  # 建立本地缓存
  while IFS= read -r -d '' docker_file; do
    # shellcheck disable=SC2001
    path="$(dirname "$(echo "$docker_file" | sed "s|$src_path/||g")")"
    tag="$(basename "$docker_file" | sed "s|Dockerfile.||g")"
    local_images+=("$registry/$path:$tag=img/$path/$tag")
  done < <(find "$src_path" -type f -name 'Dockerfile.*' -print0)
  find "$src_path" -type f -name 'Dockerfile.*' -print0 | while IFS= read -r -d '' docker_file; do
    depends=()
    # shellcheck disable=SC2001
    path="$(dirname "$(echo "$docker_file" | sed "s|$src_path/||g")")"
    tag="$(basename "$docker_file" | sed "s|Dockerfile.||g")"
    for local_image in "${local_images[@]}"; do
      _tag="^FROM *$(echo "$local_image" | sed 's/=/ /g' | awk '{print $1}')"
      _link="$(echo "$local_image" | sed 's/=/ /g' | awk '{print $2}')"
      if grep -E "$_tag" <"$docker_file" >/dev/null 2>&1; then
        depends+=("$_link")
      fi
    done
    {
      echo -e "img/$path/$tag: $(
        IFS=$' '
        echo "${depends[*]}"
      )"
        echo -e "\t\$(CMD_DOCKER) build -t \$(DOMAIN)/$path:$tag \\"
        echo -e "\t-f \$(IMG_SRC_DIR)/$path/Dockerfile.$tag \$(IMG_SRC_DIR)/$path"
        echo ""
    } >> "$out_path"
  done
}
function panic() {
  echo -ne "[\033[31mError\033[0m] $*\n" >&2
  exit 1
}
function debug() {
  if [ "$enable_debug" = "1" ]; then
    echo -ne "[\033[33mDebug\033[0m] $*\n" >&2
  fi
}
case "$child_command" in
setup)
  func_setup
  ;;

esac

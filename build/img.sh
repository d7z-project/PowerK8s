#!/usr/bin/env bash
set -e
child_command="$1"
shift
enable_debug='0'
src_path=''
project_path_id=''
out_path=''
registry=''
save_provides_path=''
append_provides='0'
load_provides_path=''

while [[ $# -ge 1 ]]; do
  case $1 in
  --load-provides)
    shift
    load_provides_path=$1
    shift
    ;;
  --save-provides)
    shift
    save_provides_path=$1
    shift
    ;;
  --append-provides)
    shift
    save_provides_path=$1
    append_provides='1'
    shift
    ;;
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
  --path)
    shift
    project_path_id=$1
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

# 在容器内运行程序
function func_container_run_setup() {
  test -d "$src_path" || panic "$src_path 路径不存在"
  test -d "$(dirname "$out_path")" || mkdir -p "$(dirname "$out_path")"
  test ! -f "$out_path" || rm "$out_path"
  touch "$out_path"
  local_images=()
  if [ -f "$load_provides_path" ]; then
    while read -r find_image; do
      # shellcheck disable=SC2001
      local_images+=("$find_image")
    done <"$load_provides_path"
  fi
  while IFS= read -r -d '' dyn_spec; do
    if grep -E "^## *Image=" <"$dyn_spec" >/dev/null 2>&1; then
      dyn_depend_image="$(grep -E "^## *Image=" <"$dyn_spec" | head -n 1 | sed 's/## *Image=//g')"
      dyn_name="$(basename "$dyn_spec" | sed -e 's/\..*$//g' -e 's|:|/|g')"
      dyn_depend_target="$( (grep -E "^## *DependsTarget=" <"$dyn_spec" | head -n 1 | sed 's/## *DependsTarget=//g') || echo "")"
      {
        echo -n "dyn/img/$dyn_name: $dyn_depend_target"
        for local_img in "${local_images[@]}"; do
          if [[ "$local_img" = $dyn_depend_image=* ]]; then
            echo -n " $(echo "$local_img" | sed 's/=/ /g' | awk '{print $2}')"
          fi
        done
        echo -e "\n\t\$(TASK_DYN) -o '\$(DYN_IMG_INFO_OUTPUT)' -n $dyn_name"

      } >>"$out_path"
    fi

  done < <(find "$src_path" -type f -name '*.sh' -print0)

}
function func_setup() {
  test -d "$src_path" || panic "$src_path 路径不存在"
  test -d "$(dirname "$out_path")" || mkdir -p "$(dirname "$out_path")"
  test ! -f "$out_path" || rm "$out_path"
  touch "$out_path"
  test "$append_provides" = "1" || (test "$save_provides_path" && (test ! -f "$save_provides_path" || rm "$save_provides_path"))
  test "$save_provides_path" && (test -f "$save_provides_path" || touch "$save_provides_path")
  local_images=()
  if [ -f "$load_provides_path" ]; then
    while read -r find_image; do
      # shellcheck disable=SC2001
      local_images+=("$find_image")
    done <"$load_provides_path"
  fi
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
      _tag="^FROM *$(echo "$local_image" | sed 's/=/ /g' | awk '{print $1}').*"
      _link="$(echo "$local_image" | sed 's/=/ /g' | awk '{print $2}')"
      if grep -E "$_tag" <"$docker_file" >/dev/null 2>&1; then
        depends+=("$_link")
      fi
    done
    if [ "$save_provides_path" ]; then
      echo "$registry/$path:$tag=img/$path/$tag" >>"$save_provides_path"
    fi
    {
      echo -e "img/$path/$tag: $(
        IFS=$' '
        echo "${depends[*]}"
      )"
      echo -e "\t\$(CMD_DOCKER) build -t \$(DOMAIN)/$path:$tag \\"
      echo -e "\t-f $project_path_id/$path/Dockerfile.$tag $project_path_id/$path"
      echo ""
    } >>"$out_path"
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
container-run-setup)
  func_container_run_setup
  ;;
esac

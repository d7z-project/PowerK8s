#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e
repo_group_dir=''
install_flag=''
target_name='local-prod'
while [[ $# -ge 1 ]]; do
  case $1 in
  --group-path | --repos)
    shift
    repo_group_dir=$1
    shift
    ;;
  --name | -n)
    shift
    target_name="$1"
    shift
    ;;
  -i | --install)
    shift
    install_flag="install"
    ;;
  -c | --create)
    shift
    install_flag="create"
    ;;
  -r | --remove)
    shift
    install_flag="remove"
    ;;
  -d | --delete)
    shift
    install_flag="delete"
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done

repo_dir="$repo_group_dir/$(bash "$UTIL_PATH/pkg/rpm-system-info.sh" | grep "PlatformDist=" | sed 's/PlatformDist=//g')"
repo_cfg_path="/etc/yum.repos.d/$target_name.repo"

function create() {
  debug "开始为 $repo_dir 目录生成仓库索引"
  check_dirs "$repo_dir"
  test ! -d "$repo_dir/repodata" || rm -r "$repo_dir/repodata"
  check_commands "createrepo"
  (
    cd "$repo_dir"
    createrepo .
  ) || panic "生成索引的过程中出现错误！"
  debug "索引生成完成！"
}

function install() {
  debug "开始将仓库 $repo_dir 添加至系统中 ,配置位于 $repo_cfg_path"
  check_commands yum
  check_dirs "$repo_dir"
  test ! -f "$repo_cfg_path" || rm "$repo_cfg_path"
  cat <<EOF | tee "$repo_cfg_path" >/dev/null
[$target_name]
name=Local Repo #$target_name
baseurl=file://$(cd "$repo_dir" && pwd)/
enabled=1
gpgcheck=0
priority=1
EOF
  debug "配置添加完成，即将更新索引"
  yum makecache --disablerepo=* "--enablerepo=$target_name"
  debug "仓库添加完成"
}
function remove() {
  debug "开始将仓库从系统中移除"
  test ! -f "$repo_cfg_path" || yum clean all --disablerepo=* "--enablerepo=$target_name" || :
  test ! -f "$repo_cfg_path" || rm "$repo_cfg_path"
  debug "移除完成"
}
function delete() {
  debug "开始移除仓库索引"
  test ! -d "$repo_dir/repodata" || rm -r "$repo_dir/repodata"
  debug "仓库索引已移除"
}

case "$install_flag" in
create)
  create

  ;;
install)
  install
  ;;
remove)
  remove
  ;;
delete)
  delete
  ;;
esac

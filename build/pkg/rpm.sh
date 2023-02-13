#!/usr/bin/env bash
set -e
child_command="$1"
shift
src_path=''
res_path=()
tmp_path='/tmp/rpm'
cache_path="$tmp_path/cache"
project_path=''
output_path=''
enable_down='0'
enable_install='0'
enable_cache='0'
enable_debug='0'
local_repository=''
local_packages=''
exclude_packages=()

while [[ $# -ge 1 ]]; do
  case $1 in
  --src | -i)
    shift
    src_path=$1
    shift
    ;;
  --res | --resource | -r)
    shift
    res_path+=("$1")
    shift
    ;;
  --output | -o)
    shift
    output_path=$1
    shift
    ;;
  --tmp)
    shift
    tmp_path=$1
    shift
    ;;
  --cache)
    shift
    cache_path=$1
    shift
    ;;
  --debug)
    shift
    enable_debug='1'
    ;;
  --enable-download)
    shift
    enable_down='1'
    ;;
  --enable-install)
    shift
    enable_install='1'
    ;;
  --auto)
    shift
    enable_down='1'
    enable_install='1'
    enable_cache='1'
    ;;
  --enable-cache)
    shift
    enable_cache='1'
    ;;
  --local-repository)
    shift
    local_repository=$1
    shift
    ;;
  --exclude-package)
    shift
    exclude_packages+=("$1")
    shift
    ;;
  --local-package)
    shift
    local_packages=$1
    shift
    ;;
  --project)
    shift
    project_path="$1"
    src_path="$1/src/rpm/$(basename "$1").spec"
    test ! -d "$1/resources" || res_path+=("$1/resources")
    test ! -d "$1/patches" || res_path+=("$1/patches")
    shift
    ;;
  *)
    echo "Wrong parameter: $1" >&2 && exit 1
    ;;
  esac
done
# 打包软件
function func_build() {
  test "$src_path" || panic "Parameter error, please set the spec file path."
  test "$output_path" || panic "Parameter error, please set the output directory."
  mkdir -p "$tmp_path" "$output_path" "$cache_path"
  check_commands rpmspec rpmbuild rpm
  test_feature enable_install || check_commands yum
  check_files "$src_path"
  check_dirs "${res_path[@]}" "$tmp_path" "$output_path"
  test_feature local_repository || check_dirs "$local_repository"
  _pkg_info=$(package_info "$src_path")
  pkg_name=$(echo "$_pkg_info" | grep "Name=" | sed 's/Name=//g')
  pkg_version=$(echo "$_pkg_info" | grep "Version=" | sed 's/Version=//g')
  pkg_release=$(echo "$_pkg_info" | grep "Release=" | sed 's/Release=//g')
  pkg_build_arch=$(echo "$_pkg_info" | grep "BuildArch=" | sed 's/BuildArch=//g')
  system_dist=$(echo "$_pkg_info" | grep "PlatformDist=" | sed 's/PlatformDist=//g')
  # 软件包完整名称
  pkg_print_name="$pkg_name-$pkg_version-$pkg_release.$pkg_build_arch"
  # 产物最终复制的位置
  output_dist_path="$output_path/$system_dist"
  if [ "$enable_cache" = "1" ]; then
    debug "编译缓存已开启，正在检查本地包 ..."
    find_cache_file=$(find "$output_path" -type f -name "$pkg_name*$pkg_version*$pkg_release*$pkg_build_arch*.rpm" | head -n 1)
    if [ -f "$find_cache_file" ] && [ "$find_cache_file" -nt "$src_path" ]; then
      debug "发现缓存 $find_cache_file , 跳过编译"
      exit 0
    else
      if [ -f "$find_cache_file" ]; then
        debug "缓存命中失败：源码经上次编译后做了修改。"
        debug "$(basename "$src_path"): $(stat --printf='%y\n' "$src_path")"
        debug "$(basename "$find_cache_file"): $(stat --printf='%y\n' "$find_cache_file")"
      else
        debug "缓存命中失败：未发现缓存。"
      fi
    fi
  fi
  debug "开始打包 $pkg_print_name"
  # 软件包资源
  IFS=';' read -r -a pkg_resources <<<"$(echo "$_pkg_info" | grep "Resources=" | sed 's/Resources=//g')"
  # 软件包编译依赖
  IFS=';' read -r -a pkg_build_requires <<<"$(echo "$_pkg_info" | grep "BuildRequires=" | sed 's/BuildRequires=//g')"

  pkg_res_path="$cache_path/resources/$pkg_name-$pkg_version"
  debug "将把资源放置在 $pkg_res_path 目录下。"
  mkdir -p "$pkg_res_path"
  ############### 处理资源
  for resource in "${pkg_resources[@]}"; do
    if [[ "$resource" = https://* ]] || [[ "$resource" = http://* ]]; then
      dist_path="$pkg_res_path/$(basename "$resource")"
      debug "从网络下载资源 $(basename "$resource") 到 $dist_path"
      if [ ! "$enable_down" = "1" ]; then
        panic "不允许从网络下载资源"
      fi
      check_commands wget
      if [ -f "$dist_path" ]; then
        debug "资源 $(basename "$resource") 已存在，跳过下载"
      else
        test ! -f "$dist_path.dl" || rm -f "$dist_path.dl"
        wget -O "$dist_path.dl" -t 3 "$resource" || panic "资源 $resource 下载失败！"
        mv "$dist_path.dl" "$dist_path"
      fi
    else
      dist_path="$pkg_res_path/$resource"
      test ! -f "$dist_path" || rm "$dist_path"
      test ! -d "$dist_path" || rm -r "$dist_path"
      for res_search_path in "${res_path[@]}"; do
        find_path="$res_search_path/$resource"
        if [ -d "$find_path" ] || [ -f "$find_path" ]; then
          debug "从本地复制资源 $resource 到 $dist_path"
          cp -r "$find_path" "$dist_path"
          break
        fi
      done
      test -f "$dist_path" || test -d "$dist_path" || panic "未在资源路径下发现 $resource 文件/目录 ！"
    fi
  done
  ############### 安装编译依赖
  for build_depend in "${pkg_build_requires[@]}"; do
    debug "检查软件包 $build_depend"
    _name=$(echo "$build_depend" | awk '{print $1}')
    (rpm -q --whatprovides "$_name" >/dev/null 2>&1 && debug "软件包 $_name 已经安装") || {
      if [ ! "$enable_install" = "1" ]; then
        panic "软件包 $_name 未安装，且当前环境不允许安装软件包"
      fi
      while [ "$(pgrep yum | head -n 1)" ]; do
        debug "编译 $_pkg_name 任务：发现有其他进程使用 YUM 操作软件包，等待其结束中"
        sleep 5
      done
      (rpm -q --whatprovides "$_name" >/dev/null 2>&1 || yum install -y "$_name" && rpm -q --whatprovides "$_name") || panic "软件包 $_name 安装失败！"
      debug "软件包 $_name 安装完成"
    }
  done
  ############### 编译软件包
  rpmbuild_workdir="$tmp_path/rpmbuild"
  rpmbuild_log_path="$rpmbuild_workdir/LOG"
  rpmbuild_output_path="$rpmbuild_workdir/RPM/$pkg_print_name"
  current_log_path="$rpmbuild_log_path/$pkg_print_name.log"
  test ! -d "$rpmbuild_output_path" || rm -r "$rpmbuild_output_path"
  mkdir -p "$rpmbuild_output_path"
  test -d "$rpmbuild_workdir" || mkdir -p "$rpmbuild_workdir"
  test -d "$rpmbuild_log_path" || mkdir -p "$rpmbuild_log_path"
  BUILD_ARGS=(
    "--define"
    "%_topdir $rpmbuild_workdir"
    "--define"
    "%_sourcedir $pkg_res_path"
    "--define"
    "%_builddir %{_topdir}/BUILD/$pkg_print_name"
    "--define"
    "%_rpmdir $rpmbuild_output_path"
    "--define"
    "%debug_package %{nil}"
    "$src_path"
  )
  test ! -f "$current_log_path" || mv -f "$current_log_path" "$current_log_path.old"
  debug "开始使用 rpmbuild 打包 RPM,日志位于 $current_log_path"
  echo "command: rpmbuild -bb ${BUILD_ARGS[*]}" >"$current_log_path"
  rpmbuild -bb "${BUILD_ARGS[@]}" 2>>"$current_log_path" 1>&2 ||
    panic "软件包 $pkg_print_name 打包失败，打包日志位于 $current_log_path"
  debug "软件包 $pkg_print_name 打包完成！"
  test -d "$output_dist_path" || mkdir -p "$output_dist_path"
  debug "开始处理编译后产物 ..."
  find "$rpmbuild_output_path" -type f -name "*.rpm" -print0 | while IFS= read -r -d '' rpm_file; do
    rpm_name=$(rpm -qip "$rpm_file" | grep Name | awk '{print $3}')
    rpm_file_name="$(basename "$rpm_file")"
    debug "发现编译后产物 $rpm_file_name !"
    # shellcheck disable=SC2076
    if [[ " ${exclude_packages[*]} " =~ " ${rpm_name} " ]]; then
      debug "软件包 $rpm_name 在排除列表中，跳过复制"
    else
      debug "软件包 $rpm_name 复制到 $output_dist_path"
      cp -f "$rpm_file" "$output_dist_path/$rpm_file_name"
    fi
  done
  echo "打包 $pkg_print_name 完成！"
}
# 生成 Makefile
function func_setup() {
  test -d "$project_path" || panic "指定的 project 路径不存在"
  test ! -d "$output_path" || panic "指定的配置生成路径不存在"
  provides_group=()
  targets=()
  # 渲染依赖关系
  for pkg_path in "$project_path"/*; do
    _src_path="$pkg_path/src/rpm/$(basename "$pkg_path").spec"
    if [ -d "$pkg_path" ] && [ -f "$_src_path" ]; then
      _pkg_info=$(package_info "$_src_path")
      _pkg_name=$(echo "$_pkg_info" | grep "Name=" | sed "s/Name=//g")
      IFS=';' read -r -a _pkg_provides <<<"$(echo "$_pkg_info" | grep "Provides=" | sed 's/Provides=//g')"
      for item in "${_pkg_provides[@]}"; do
        provides_group+=("$(echo "$item" | awk '{print $1}')=$_pkg_name")
      done
    fi
  done
  # 生成语法
  test ! -f "$output_path" || rm "$output_path"
  test -d "$(dirname "$output_path")" || mkdir "$(dirname "$output_path")"
  touch "$output_path"
  for pkg_path in "$project_path"/*; do
    _src_path="$pkg_path/src/rpm/$(basename "$pkg_path").spec"
    if [ -d "$pkg_path" ] && [ -f "$_src_path" ]; then
      _pkg_info=$(package_info "$_src_path")
      _pkg_name=$(echo "$_pkg_info" | grep "Name=" | sed "s/Name=//g")
      targets+=("pkg/rpm/$_pkg_name/build")
      IFS=';' read -r -a _pkg_build_requires <<<"$(echo "$_pkg_info" | grep "BuildRequires=" | sed 's/BuildRequires=//g')"
      IFS=';' read -r -a _pkg_requires <<<"$(echo "$_pkg_info" | grep "Requires=" | sed 's/Requires=//g')"
      #编译链接
      local_build_link=()

      for _pkg_build_require in "${_pkg_build_requires[@]}"; do
        _pkg_build_require_name=$(echo "$_pkg_build_require" | awk '{print $1}')
        for provides_item in "${provides_group[@]}"; do
          if [[ $provides_item = "$_pkg_build_require_name="* ]]; then
            local_build_link+=("$(echo "$provides_item" | sed "s/=/ /g" | awk '{print $2}')")
            break
          fi
        done
      done
      #安装链接
      local_install_link=()
      for _pkg_require in "${_pkg_requires[@]}"; do
        _pkg_require_name=$(echo "$_pkg_require" | awk '{print $1}')
        for provides_item in "${provides_group[@]}"; do
          if [[ $provides_item = "$_pkg_require_name="* ]]; then
            local_install_link+=("$(echo "$provides_item" | sed "s/=/ /g" | awk '{print $2}')")
            break
          fi
        done
      done
      #      --project $(SRC_DIR)/kubernetes --local-package
      rpm_build_targets=()
      for item in "${local_build_link[@]}"; do
        rpm_build_targets+=("pkg/rpm/$item/install")
      done
      rpm_install_targets=()
      for item in "${local_install_link[@]}"; do
        if [ ! "$item" = "$_pkg_name" ]; then
          rpm_install_targets+=("pkg/rpm/$item/install")
        fi
      done
      {
        echo -e "pkg/rpm/$_pkg_name/install: pkg/rpm/$_pkg_name/build $(
          IFS=$' '
          echo "${rpm_install_targets[*]}"
        )"
        echo -e "\t\$(RPM_TOOL_LOCAL_INSTALL_PARAMS) --local-package $_pkg_name \n"
        echo -e "pkg/rpm/$_pkg_name/build : $(
          IFS=$' '
          echo "${rpm_build_targets[*]}"
        )"
        echo -e "\t\$(RPM_TOOL_BUILD_PARAMS) --project \$(PKG_SRC_DIR)/$_pkg_name\n"
      } >>"$output_path"
    fi
  done
  echo "pkg/rpm/build: $(
    IFS=$' '
    echo "${targets[*]}"
  )" >>"$output_path"
}
function func_local_install() {
  check_commands rpm yum
  if [ ! "$local_repository" ] || [ ! -d "$local_repository" ]; then
    panic "未找到本地依赖仓库"
  fi
  # 指定的预先安装的包
  system_dist="$(platform_dist | sed "s/PlatformDist=//g")"
  IFS=';' read -r -a local_build_requires <<<"$local_packages"
  for _name in "${local_build_requires[@]}"; do
    rpm -q --whatprovides "$_name" >/dev/null 2>&1 || {
      find_path=$(find "$local_repository" -type f -name "$_name*$system_dist*.rpm" | head -n 1 || :)
      if [ "$find_path" ]; then
        debug "找到本地依赖 $(basename "$find_path"), 即将安装.."
        (yum install -y "$find_path" && rpm -q --whatprovides "$_name") || panic "软件包 $_name 安装失败！"
        debug "软件包 $_name 安装完成！"
      else
        panic "未找到本地依赖 $_name !"
      fi
    }
  done

}
# 查询依赖信息
function package_info() {
  spec_parse=$(
    rpmspec --define "%debug_package %{nil}" --parse "$1" | sed '/^\s*$/d'
  )
  name="$(echo "$spec_parse" | grep -E '^Name' | head -n 1 | awk '{print $2}')"
  version="$(echo "$spec_parse" | grep -E '^Version' | head -n 1 | awk '{print $2}')"
  release="$(echo "$spec_parse" | grep -E '^Release' | head -n 1 | awk '{print $2}')"
  echo "Name=$name"
  echo "Version=$version"
  echo "Release=$release"
  echo "Summary=$(echo "$spec_parse" | grep -E '^Summary' | head -n 1 | awk '{for(i=2;i<=NF;++i)print $i}' | xargs echo)"
  res=()
  for file in $(echo "$spec_parse" | grep -E '^Source' | awk '{print $2}'); do
    res+=("$file")
  done
  for file in $(echo "$spec_parse" | grep -E '^Patch' | awk '{print $2}'); do
    res+=("$file")
  done
  echo "Resources=$(
    IFS=$';'
    echo "${res[*]}"
  )"
  tmpl_requires=()
  for items in $(echo "$spec_parse" | grep -E '^Requires' | awk '{for(i=2;i<=NF;++i)print $i}'); do
    tmpl_requires+=("$items")
  done
  requires=()
  for ((i = 0; i < "${#tmpl_requires[@]}"; i++)); do
    tmpl_next=${tmpl_requires[$((i + 1))]}
    if [ "$tmpl_next" ]; then
      if [[ $tmpl_next = \>* ]] || [[ $tmpl_next = =* ]] || [[ $tmpl_next = \<* ]] || [[ $tmpl_next = \!* ]]; then
        requires+=("${tmpl_requires[$i]} ${tmpl_requires[$((i + 1))]} ${tmpl_requires[$((i + 2))]}")
        i=$((i + 2))
      else
        requires+=("${tmpl_requires[$i]}")
      fi
    else
      requires+=("${tmpl_requires[$i]}")
    fi
  done
  echo "Requires=$(
    IFS=$';'
    echo "${requires[*]}"
  )"

  tmpl_build_requires=()
  for items in $(echo "$spec_parse" | grep -E '^BuildRequires' | awk '{for(i=2;i<=NF;++i)print $i}'); do
    tmpl_build_requires+=("$items")
  done
  build_requires=()
  for ((i = 0; i < "${#tmpl_build_requires[@]}"; i++)); do
    tmpl_next=${tmpl_build_requires[$((i + 1))]}
    if [ "$tmpl_next" ]; then
      if [[ $tmpl_next = \>* ]] || [[ $tmpl_next = =* ]] || [[ $tmpl_next = \<* ]] || [[ $tmpl_next = \!* ]]; then
        build_requires+=("${tmpl_build_requires[$i]} ${tmpl_build_requires[$((i + 1))]} ${tmpl_build_requires[$((i + 2))]}")
        i=$((i + 2))
      else
        build_requires+=("${tmpl_build_requires[$i]}")
      fi
    else
      build_requires+=("${tmpl_build_requires[$i]}")
    fi
  done
  echo "BuildRequires=$(
    IFS=$';'
    echo "${build_requires[*]}"
  )"
  #=================
  tmpl_provides=()
  for items in $(echo "$spec_parse" | grep -E '^Provides' | awk '{for(i=2;i<=NF;++i)print $i}'); do
    tmpl_provides+=("$items")
  done
  provides=()
  for ((i = 0; i < "${#tmpl_provides[@]}"; i++)); do
    tmpl_next=${tmpl_provides[$((i + 1))]}
    if [ "$tmpl_next" ]; then
      if [[ $tmpl_next = \>* ]] || [[ $tmpl_next = =* ]] || [[ $tmpl_next = \<* ]] || [[ $tmpl_next = \!* ]]; then
        provides+=("${tmpl_provides[$i]} ${tmpl_provides[$((i + 1))]} ${tmpl_provides[$((i + 2))]}")
        i=$((i + 2))
      else
        provides+=("${tmpl_provides[$i]}")
      fi
    else
      provides+=("${tmpl_provides[$i]}")
    fi
  done
  while IFS= read -r param; do
    _name=$(echo "$param" | awk '{print $NF}')
    if [[ " ${param[*]} " =~ " -n " ]] && [ ! "$_name" = "$name" ]; then
      provides+=("$_name")
    else
      provides+=("$name-$_name")
    fi
  done < <(echo "$spec_parse" | grep -E '^%package ')
  provides+=("$name")
  echo "Provides=$(
    IFS=$';'
    echo "${provides[*]}"
  )"
  #=================
  echo "BuildArch=$(echo "$spec_parse" | grep -E '^BuildArch' | head -n 1 | awk '{print $2}' || rpm --eval %_arch)"
  echo "SystemArch=$(rpm --eval %_arch)"
  platform_dist
}

function platform_dist() {
  platform_dist=$(rpm --eval="%{dist}" | sed -e "s/\.//g")
  if [ ! "$platform_dist" ] || [ "$platform_dist" == "%{dist}" ]; then
    echo "PlatformDist=unknown"
  else
    echo "PlatformDist=$platform_dist"
  fi
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
function check_commands() {
  for cmd in "$@"; do
    command -v "$cmd" >/dev/null 2>&1 || panic "未在当前环境中发现 '$cmd' 命令."
  done
}
function check_files() {
  for path in "$@"; do
    test -f "$path" || panic "文件 '$path' 不存在."
  done
}
function check_dirs() {
  for path in "$@"; do
    test -d "$path" || panic "目录 '$path' 不存在."
  done
}
function test_feature() {
  name="$1"
  eval "value=\$$name"
  # shellcheck disable=SC2154
  if [ "$value" ] || [ "$value" == "1" ]; then
    return 1
  else
    return 0
  fi
}

case $child_command in
build)
  func_build
  ;;
setup)
  func_setup
  ;;
local-install)
  func_local_install
  ;;
esac

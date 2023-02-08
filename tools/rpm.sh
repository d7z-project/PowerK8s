#!/bin/bash
test "$BUILD_PATH" || exit 1

PACKAGE_RPM_WORKER_PATH="$BUILD_PATH/builder/rpm"
PACKAGE_RES_PATH="$BUILD_PATH/sources"
PACKAGE_RPM_PACKAGE_PATH="$BUILD_PATH/pkg/rpm"
RPM_BUILD_DEFAULT_PARAMS=(
  "--define"
  "%_topdir $PACKAGE_RPM_WORKER_PATH"
  "--define"
  "%_sourcedir $PACKAGE_RES_PATH"
  "--define"
  "%_builddir %{_topdir}/build/%{_dist_name}"
  "--define"
  "%_rpmfilename %{ARCH}/%{NAME}-%{VERSION}-%{RELEASE}.%{ARCH}.rpm"
  "--define"
  "%_rpmdir $PACKAGE_RPM_PACKAGE_PATH"
  "--define"
  "%debug_package %{nil}"
)
rpm_check() {
  test -f "$(command -v rpmspec)" || return 1
  test -f "$(command -v rpmbuild)" || return 1
  test -f "$(command -v rpm)" || return 1
  test -f "$(command -v yum)" || return 1
}

rpm_platform_info() {
  platform_dist=$(rpmbuild --eval="%{dist}" | sed -e "s/\.//g")
  if [ ! "$rpm_dist" ] || [ "$rpm_dist" == "%{dist}" ]; then
    platform_dist=""
  fi
  platform_arch=$(rpm --eval %_arch)
}

rpm_export_info() {
  test -f "$1" || return 1
  rpm_platform_info
  rpm_spec_info=$(rpmspec --parse "$1" | sed '/^\s*$/d')
  rpm_name=$(echo "$rpm_spec_info" | grep -E '^Name' | head -n 1 | awk '{print $2}')
  rpm_version=$(echo "$rpm_spec_info" | grep -E '^Version' | head -n 1 | awk '{print $2}')
  rpm_release=$(echo "$rpm_spec_info" | grep -E '^Release' | head -n 1 | awk '{print $2}')
  rpm_summary=$(echo "$rpm_spec_info" | grep -E '^Summary' | head -n 1 | awk '{for(i=2;i<=NF;++i)print $i}')
  rpm_sources="$(echo "$rpm_spec_info" | grep -E '^Source' | awk '{print $2}')"
  rpm_patch="$(echo "$rpm_spec_info" | grep -E '^Patch' | awk '{print $2}')"
  rpm_build_requires=$(echo "$rpm_spec_info" | grep -E '^BuildRequires' | head -n 1 | awk '{for(i=2;i<=NF;++i)print $i}')
  rpm_build_arch=$(echo "$rpm_spec_info" | grep -E '^BuildArch' | head -n 1 | awk '{print $2}' | test || echo "$platform_arch")
  rpm_dist_name="$rpm_name-$rpm_version-$rpm_release.$rpm_build_arch"
  rpm_dist_rpm_path="$PACKAGE_RPM_PACKAGE_PATH/$rpm_build_arch/$rpm_dist_name.rpm"
}

rpm_list() {
  rpm_platform_info
  find "$SRC_PATH/packages" -mtime -7 -name '*.spec' -print0 | while IFS= read -r -d '' rpm_spec_path; do
    rpm_export_info "$rpm_spec_path"
    printf "%-40s\t %s\n" "$rpm_name-$rpm_version-$rpm_release""_$platform_arch" "$(echo "$rpm_summary" | xargs echo)"
  done
}

rpm_build() {
  rpm_spec_path=$(find "$SRC_PATH/packages/$1" -mtime -7 -name '*.spec' -print0 | head -n 1)
  test -f "$rpm_spec_path" || return 1
  rpm_export_info "$rpm_spec_path"
  rpm_platform_info

  if [ "$(md5sum 2>/dev/null <"$rpm_dist_rpm_path.spec")" != "$(echo "$rpm_spec_info" | md5sum 2>/dev/null)" ] || [ ! -f "$rpm_dist_rpm_path" ]; then
    # 没有缓存，开始编译
    params=()
    params+=("${RPM_BUILD_DEFAULT_PARAMS[@]}")
    params+=("--define" "%_dist_name $rpm_name-$rpm_version-$rpm_release.$rpm_build_arch")
    params+=("$rpm_spec_path")
    # 下载在线资源
    for url in $(echo "${rpm_sources[@]}" | grep -E '^https://|^http://'); do
      echo "下载资源 $(basename "$url")"
      c_download "$url" "$PACKAGE_RES_PATH/$(basename "$url")"
    done
    # 复制本地资源
    for local_file in $(echo "${rpm_sources[@]}" | grep -v -E '^https://|^http://|^/'); do
      rm -f "$PACKAGE_RES_PATH/$local_file"
      cp "$SRC_PATH/packages/$1/resources/$local_file" "$PACKAGE_RES_PATH/$local_file" ||
        fail "文件 $SRC_PATH/packages/$1/resources/$local_file 复制失败！"
    done
    # 复制本地 PATCH
    for local_file in $(echo "${rpm_patch[@]}" | grep -v -E '^https://|^http://|^/'); do
      rm -f "$PACKAGE_RES_PATH/$local_file"
      cp "$SRC_PATH/packages/$1/resources/$local_file" "$PACKAGE_RES_PATH/$local_file" ||
        fail "文件 $SRC_PATH/packages/$1/resources/$local_file 复制失败！"
    done
    cache_spec_path="$rpm_dist_rpm_path.spec"
    mkdir -p "$(dirname "$cache_spec_path")"
    echo "$rpm_spec_info" >"$cache_spec_path.build"
    # 安装编译依赖
    for build_require in $rpm_build_requires; do
      rpm -q "$build_require" >/dev/null 2>&1 || {
        echo "安装编译依赖：$build_require"
        if [ -d "$SRC_PATH/packages/$build_require" ]; then
          echo "依赖 '$build_require' 为本地依赖！"
          exit 1
        else
          yum install "$build_require" -y
        fi
      }
    done
    # 开始编译
    rpmbuild -bb "${params[@]}"
    mv -f "$cache_spec_path.build" "$cache_spec_path"
  else
    echo "软件包 $rpm_name 已存在可用包，跳过构建！"
  fi
}

new_project() {
  name=$1
  if [ ! -d "$SRC_PATH/packages/$name" ]; then
    mkdir -p "$SRC_PATH"/packages/"$name"/{src,resources}
    touch "$SRC_PATH"/packages/"$name"/resources/.gitkeep
    mkdir -p "$SRC_PATH"/packages/"$name"/src/{rpm,deb}
    rpmdev-newspec "$SRC_PATH"/packages/"$name"/src/rpm/"$name".spec
    touch "$SRC_PATH"/packages/"$name"/src/deb/.gitkeep
  fi
}

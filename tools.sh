#!/bin/bash

#======================
#    auto configuration
#======================

set -e

SRC_PATH=$(
  # shellcheck disable=SC2046
  cd $(dirname "${BASH_SOURCE[0]}") || exit 1
  pwd
)
BUILD_PATH=$(
  cd "${BUILD_PATH:-"$(pwd)/target"}" || (echo "编译目录不存在" && exit 1)
  pwd
)
### define start
source "$SRC_PATH/tools/utils.sh"
source "$SRC_PATH/tools/rpm.sh"
### define end


################################ RPM Begin #################################

conf_flash_rpm() {
  test -f "$(command -v rpmspec)" || return 1
  test -f "$(command -v rpmbuild)" || return 1
  test -f "$(command -v rpm)" || return 1
  find "$SRC_PATH/packages" -mtime -7 -name '*.spec' -print0 | while IFS= read -r -d '' rpm_spec_path; do
    rpm_spec_info=$(rpmspec --parse "$rpm_spec_path")
    rpm_version=$(echo "$rpm_spec_info" | grep -E 'Version' | head -n 1 | awk '{print $2}')
    rpm_release=$(echo "$rpm_spec_info" | grep -E 'Release' | head -n 1 | awk '{print $2}')
    rpm_build_requires=$(echo "$rpm_spec_info" | grep -E 'BuildRequires' | head -n 1 | awk '{for(i=2;i<=NF;++i)print $i}')
    rpm_arch=$(rpm -q bash --queryformat "%{ARCH}")
    for url in $(echo "$rpm_spec_info" | grep -E 'Source' | awk '{print $2}' | grep -E '^https://|^http://'); do
      file_name=$(basename "$url")
      echo "$url" >"$PACKAGE_RES_PATH/$file_name.dl"
      cat <<EOF >>"$NINJA_CONF_PATH"
build $(get_relative_path "$PACKAGE_RES_PATH" "$SRC_PATH")/$file_name: pkg_res_get $(get_relative_path "$PACKAGE_RES_PATH/$file_name.dl" "$SRC_PATH")
EOF
    done
    get_relative_path "$rpm_spec_path" "$SRC_PATH/packages"
  done
  return 0
}
case $1 in
rpm)
  rpm_check || fail "RPM 编译环境检查失败！"
  case $2 in
  list)
    rpm_list
    ;;
  build)
    rpm_build "$3"
    ;;
  new)
    new_project "$3"
    ;;
  esac
  ;;
esac

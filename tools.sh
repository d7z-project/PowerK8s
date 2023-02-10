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

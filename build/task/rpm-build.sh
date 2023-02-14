#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e

while [[ $# -ge 1 ]]; do
  case $1 in
  -i | --src | --source-dir)
    shift
    dyn_name=$1
    shift
    ;;
  -r | --resource-dir)
    shift
    root_path=$1
    shift
    ;;
  -o | --output-dir)
    shift
    result_path=$1
    shift
    ;;
  -c | --cache-dir)
    shift
    result_path=$1
    shift
    ;;
  -w | --work-dir)
    shift
    result_path=$1
    shift
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done

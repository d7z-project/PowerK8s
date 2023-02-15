#!/usr/bin/env bash
set -e
src_file=''
registry=''
username=''
password=''
while [[ $# -ge 1 ]]; do
  case $1 in
  --pack | -i)
    shift
    src_file=$1
    shift
    ;;
  --registry | -r)
    shift
    registry=$1
    shift
    ;;

  --username | -u)
    shift
    username=$1
    shift
    ;;

  --password | -p)
    shift
    password=$1
    shift
    ;;
  *)
    echo "未知参数: $1" >&2 && exit 1
    ;;
  esac
done
test "$registry" || (echo "镜像仓库地址 $registry 不存在" >&2 && exit 1)

if [ "$username" ]; then
  skopeo login "$registry" --username "$username" --password "$password" --tls-verify=false
fi
test -f "$src_file" || (echo "路径 $src_file 不存在" >&2 && exit 1)
work_dir="/tmp/oci-images-workdir/$(basename "$src_file")"
test -d "$work_dir" || mkdir -p "$work_dir"
tar Czxvf "$work_dir" "$src_file"
while IFS= read -r -d '' img_file; do
  remote_path="$registry/$(dirname "$(echo "$img_file" | sed -e "s|$work_dir/||g" -e "s|/| |" | awk '{print $2}')"):$(basename "$img_file")"
  echo "推送 $remote_path"
  skopeo copy "oci-archive:$img_file" "docker://$remote_path" --dest-tls-verify=false
done < <(find "$work_dir" -type f -print0)
rm -r "$work_dir"

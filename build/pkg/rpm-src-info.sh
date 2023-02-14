#!/usr/bin/env bash
UTIL_PATH=$(cd "$(dirname "${BASH_SOURCE:-$0}")/../" && pwd)
source "$UTIL_PATH/util.sh" || exit 1
set -e
test -f "$1" || panic "配置文件 $1 不存在"
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
if [ "$(echo "$spec_parse" | grep -E '^%files *$')" = "%files" ]; then
  provides+=("$name")
fi
echo "Provides=$(
  IFS=$';'
  echo "${provides[*]}"
)"
_tmpl_build_arch=$(echo "$spec_parse" | grep -E '^BuildArch' | head -n 1 | awk '{print $2}')
if [ "$_tmpl_build_arch" ]; then
  echo "BuildArch=$_tmpl_build_arch"
else
  echo "BuildArch=$(rpm --eval %_arch)"
fi
echo "SystemArch=$(rpm --eval %_arch)"
platform_dist=$(rpm --eval="%{dist}" | sed -e "s/\.//g")
if [ ! "$platform_dist" ] || [ "$platform_dist" == "%{dist}" ]; then
  echo "PlatformDist=unknown"
else
  echo "PlatformDist=$platform_dist"
fi

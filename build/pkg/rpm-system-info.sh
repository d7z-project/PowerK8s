#!/usr/bin/env bash

platform_dist=$(rpm --eval="%{dist}" | sed -e "s/\.//g")
if [ ! "$platform_dist" ] || [ "$platform_dist" == "%{dist}" ]; then
  echo "PlatformDist=unknown"
else
  echo "PlatformDist=$platform_dist"
fi

#!/usr/bin/env bash
set -e

child="$1"
shift

"oci-$child" "$@"

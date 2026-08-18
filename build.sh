#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
build_dir="${HESH_BUILD_DIR:-$repo_root/build}"
jobs="${HESH_BUILD_JOBS:-1}"

if [[ ! -f "$build_dir/CMakeCache.txt" ]]; then
    cmake -S "$repo_root" -B "$build_dir" -DCMAKE_BUILD_TYPE=Debug
fi

cmake --build "$build_dir" --parallel "$jobs"

if [[ "${1:-}" != "--no-test" ]]; then
    ctest --test-dir "$build_dir" --output-on-failure
fi

echo "Hesh build ready: $build_dir/hesh"

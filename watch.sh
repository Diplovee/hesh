#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if ! command -v inotifywait >/dev/null 2>&1; then
    echo "watch.sh needs inotifywait. Install the inotify-tools package." >&2
    exit 1
fi

"$repo_root/build.sh" --no-test
echo "Watching QML, C++, assets, and CMake files. Press Ctrl+C to stop."

while read -r changed_path event; do
    echo "Changed: $changed_path ($event)"
    if ! "$repo_root/build.sh" --no-test; then
        echo "Build failed; continuing to watch for the next save." >&2
    fi
done < <(
    inotifywait -m -r \
        -e close_write,moved_to,create,delete \
        --format '%w%f %e' \
        "$repo_root/qml" \
        "$repo_root/src" \
        "$repo_root/assets" \
        "$repo_root/CMakeLists.txt"
)

#!/usr/bin/env bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")/.." && pwd)"
repo_dir="${1:-$(dirname "$project_dir")/medical-config-repo}"

if [[ ! -e "$repo_dir" ]]; then
    mkdir -p "$repo_dir"
    git -C "$repo_dir" init -b main
fi
repo_dir="$(cd "$repo_dir" && pwd -P)"
if [[ "$(git -C "$repo_dir" rev-parse --show-toplevel)" != "$repo_dir" ]]; then
    echo "Thu muc phai la thu muc goc cua kho Git: $repo_dir" >&2
    exit 1
fi
if [[ -n "$(git -C "$repo_dir" status --porcelain)" ]]; then
    echo "Kho Git dang co thay doi chua commit; hay luu chung truoc: $repo_dir" >&2
    exit 1
fi
if [[ "$(git -C "$repo_dir" symbolic-ref --short HEAD)" != main ]]; then
    echo "Hay chuyen kho cau hinh sang nhanh main truoc khi chay script." >&2
    exit 1
fi
config_files=(patient-service.properties patient-service-dev.properties patient-service-prod.properties)
for config_file in "${config_files[@]}"; do
    cp "$project_dir/config-repo/$config_file" "$repo_dir/$config_file"
done
git -C "$repo_dir" add -- "${config_files[@]}"
if ! git -C "$repo_dir" diff --cached --quiet -- "${config_files[@]}"; then
    git -C "$repo_dir" commit -m "Update patient service configuration" --only -- "${config_files[@]}"
fi
echo "Kho cau hinh da san sang: $repo_dir"

#!/usr/bin/env bash

# Fetch (or update) the nix-ros-overlay repository and write the date of its
# pinned nixpkgs input to a JSON file in the shields.io endpoint badge format:
# https://shields.io/badges/endpoint-badge

set -euo pipefail

repo_url=https://github.com/lopsided98/nix-ros-overlay
repo_dir=${REPO_DIR:-nix-ros-overlay}
branch=${BRANCH:-develop}
out=${OUT:-nixpkgs-date-badge.json}

# Clone on first run, otherwise update the existing checkout.
if [ -d "$repo_dir/.git" ]; then
    git -C "$repo_dir" fetch --depth 1 origin
    git -C "$repo_dir" reset --hard origin/master
else
    git clone "$repo_url" "$repo_dir"
fi

# flake.lock stores the nixpkgs input's date as a Unix timestamp in
# nodes.nixpkgs.locked.lastModified.
last_modified=$(git -C "$repo_dir" cat-file -p "refs/remotes/origin/${branch}:flake.lock" | jq -r '.nodes.nixpkgs.locked.lastModified')

if [ -z "$last_modified" ] || [ "$last_modified" = null ]; then
    echo >&2 "Could not find nixpkgs lastModified in $repo_dir/flake.lock"
    exit 1
fi

date=$(date -u -d "@$last_modified" +%Y-%m-%d)

# Color the badge by how stale the nixpkgs pin is.
age_days=$(( ( $(date -u +%s) - last_modified ) / 86400 ))
if   [ "$age_days" -le 14 ]; then color=brightgreen
elif [ "$age_days" -le 45 ]; then color=green
elif [ "$age_days" -le 90 ]; then color=yellow
else                              color=red
fi

jq -n \
   --arg message "$date" \
   --arg color "$color" \
   '{schemaVersion: 1, label: "nixpkgs", message: $message, color: $color}' \
   > "$out"

echo "Wrote $out (nixpkgs from $date, $age_days days old)"

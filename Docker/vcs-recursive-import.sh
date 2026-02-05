#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
    echo "Usage: $0 <main-repos-file>"
    exit 1
fi

MAIN_REPOS="$1"
WORKSPACE_ROOT="/ros2_ws"
MAX_DEPTH=4
IMPORTED=()

# Get current ROS distro (usually 'humble' in your base image)
ROS_DISTRO="${ROS_DISTRO:-humble}"   # fallback if not set

echo "Starting recursive vcs import from: $MAIN_REPOS"
echo "Using ROS distro: $ROS_DISTRO"

import_repos() {
    local repos_file="$1"
    local depth="$2"
    local is_nested="$3"   # "true" if this is a nested file

    if [ "$depth" -gt "$MAX_DEPTH" ]; then
        echo "→ Max depth $MAX_DEPTH reached — stopping recursion"
        return
    fi

    if [[ " ${IMPORTED[*]} " =~ " $repos_file " ]]; then
        echo "→ Already imported: $repos_file — skipping"
        return
    fi

    if [ ! -f "$repos_file" ]; then
        echo "→ File not found: $repos_file — skipping"
        return
    fi

    echo "→ Importing level $depth: $repos_file"

    local import_cmd="vcs import \"$WORKSPACE_ROOT/src\" --skip-existing < \"$repos_file\""

    # For nested .repos files: try to force the current distro branch
    if [ "${is_nested:-false}" = "true" ]; then
        echo "  (nested file → attempting to use branch '$ROS_DISTRO')"

        # Create a temporary modified version of the repos file
        local tmp_repos="/tmp/nested-modified-$(basename "$repos_file")"
        cp "$repos_file" "$tmp_repos"

        # Replace common branch patterns with current distro
        # This is heuristic — adjust patterns as needed
        sed -i "s|version: *master|version: $ROS_DISTRO|g" "$tmp_repos"
        sed -i "s|version: *main|version: $ROS_DISTRO|g" "$tmp_repos"
        sed -i "s|version: *rolling|version: $ROS_DISTRO|g" "$tmp_repos"
        sed -i "s|version: *foxy|version: $ROS_DISTRO|g" "$tmp_repos"
        sed -i "s|version: *galactic|version: $ROS_DISTRO|g" "$tmp_repos"
        sed -i "s|version: *humble|version: $ROS_DISTRO|g" "$tmp_repos"  # idempotent
        sed -i "s|version: *iron|version: $ROS_DISTRO|g" "$tmp_repos"
        sed -i "s|version: *jazzy|version: $ROS_DISTRO|g" "$tmp_repos"

        # Also try to fix known broken/invalid refs
        sed -i '/noetic-foxy-integrate-wip/d' "$tmp_repos"

        import_cmd="vcs import \"$WORKSPACE_ROOT/src\" --skip-existing < \"$tmp_repos\" || true"
    fi

    # Run the import
    eval "$import_cmd"

    # Clean up temp file
    [ -f "${tmp_repos:-}" ] && rm -f "$tmp_repos"

    IMPORTED+=("$repos_file")

    # Find nested .repos files (skip .github)
    find "$WORKSPACE_ROOT/src" -type d -name ".github" -prune -o \
         -type f -name "*.repos" -print | while read -r nested; do
        import_repos "$nested" $((depth + 1)) "true"
    done
}

# Start recursion — top-level file is NOT treated as nested
import_repos "$MAIN_REPOS" 1 "false"

echo "Recursive vcs import finished."

# ─────────────────────────────────────────────────────────────
# Check for .gitmodules and verify submodules are populated
# ─────────────────────────────────────────────────────────────

echo ""
echo "Checking for .gitmodules files and submodule status..."

EXIT_CODE=0

find "$WORKSPACE_ROOT/src" -type f -name .gitmodules -print0 | while IFS= read -r -d '' gitmodules_file; do
    repo_dir=$(dirname "$gitmodules_file")
    echo "→ Found .gitmodules in: $repo_dir"

    # Change to the repo directory
    pushd "$repo_dir" >/dev/null || { echo "  Cannot cd to $repo_dir"; EXIT_CODE=1; continue; }

    # Initialize submodules if not already done
    git submodule init || { echo "  git submodule init failed"; EXIT_CODE=1; popd >/dev/null; continue; }

    # Update submodules (will clone if missing)
    if ! git submodule update --init --recursive --quiet; then
        echo "  ERROR: git submodule update failed in $repo_dir"
        EXIT_CODE=1
        popd >/dev/null
        continue
    fi

    # Check if any submodule paths are empty or missing
    while IFS= read -r sub_path; do
        full_sub_path="$repo_dir/$sub_path"
        if [ ! -d "$full_sub_path" ] || [ -z "$(ls -A "$full_sub_path" 2>/dev/null | grep -v '^\.git$')" ]; then
            echo "  ERROR: Submodule directory is empty or missing: $sub_path"
            EXIT_CODE=1
        fi
    done < <(git submodule --quiet foreach 'echo $path' || true)

    popd >/dev/null
done

if [ $EXIT_CODE -ne 0 ]; then
    echo ""
    echo "ERROR: One or more submodules failed to initialize or are empty."
    echo "Build should fail."
    exit $EXIT_CODE
fi

echo "All found submodules appear to be initialized and populated."
echo "vcs-recursive-import.sh completed successfully."
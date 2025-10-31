#!/usr/bin/env bash
set -euo pipefail
# Calculate relative gitdir path for a worktree
# Usage: gitdir-path.sh WORKTREE_DIR BRANCH
# Example: gitdir-path.sh .worktrees/feature/foo feature/foo
# Output: ../../../.git/worktrees/feature/foo

WORKTREE_DIR="$1"
BRANCH="$2"
REPO_ROOT="$(pwd)"

# Calculate relative path from worktree to repo root
WORKTREE_ABS="$REPO_ROOT/$WORKTREE_DIR"
REL_PATH=$(python3 -c "import os.path; print(os.path.relpath('$REPO_ROOT', '$WORKTREE_ABS'))")

# Construct gitdir path
echo "$REL_PATH/.git/worktrees/$BRANCH"

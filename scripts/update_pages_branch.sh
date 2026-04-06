#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Usage: $0 <site_dir> <target_dir> [commit_message]" >&2
  exit 1
fi

SITE_DIR="$(cd "$1" && pwd)"
TARGET_DIR="$2"
COMMIT_MESSAGE="${3:-Update GitHub Pages content}"
PAGES_BRANCH="gh-pages"

if [[ ! -d "$SITE_DIR" ]]; then
  echo "Site directory does not exist: $SITE_DIR" >&2
  exit 1
fi

REMOTE_URL="$(git remote get-url origin)"
WORK_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORK_DIR"
}
trap cleanup EXIT

if git ls-remote --exit-code --heads origin "$PAGES_BRANCH" >/dev/null 2>&1; then
  git clone --branch "$PAGES_BRANCH" --single-branch "$REMOTE_URL" "$WORK_DIR"
else
  git clone --no-checkout "$REMOTE_URL" "$WORK_DIR"
  (
    cd "$WORK_DIR"
    git switch --orphan "$PAGES_BRANCH"
    find . -mindepth 1 -maxdepth 1 ! -name .git -exec rm -rf {} +
  )
fi

(
  cd "$WORK_DIR"
  mkdir -p previews

  if [[ -z "$TARGET_DIR" ]]; then
    find . -mindepth 1 -maxdepth 1 ! -name .git ! -name previews -exec rm -rf {} +
    cp -R "$SITE_DIR"/. .
  else
    rm -rf "$TARGET_DIR"
    mkdir -p "$TARGET_DIR"
    cp -R "$SITE_DIR"/. "$TARGET_DIR"/
  fi

  touch .nojekyll
  git add -A
  if git diff --cached --quiet; then
    echo "No GitHub Pages content changes to publish."
    exit 0
  fi

  git config user.name "github-actions[bot]"
  git config user.email "41898282+github-actions[bot]@users.noreply.github.com"
  git commit -m "$COMMIT_MESSAGE"
  git push origin "HEAD:$PAGES_BRANCH"
)

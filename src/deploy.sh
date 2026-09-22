#!/usr/bin/env bash
set -euo pipefail

log() {
  echo "::notice::$*"
}

fail() {
  echo "::error::$*"
  exit 1
}

is_true() {
  case "$(echo "$1" | tr '[:upper:]' '[:lower:]')" in
    true|1|yes|on) return 0 ;;
    *) return 1 ;;
  esac
}

FOLDER="${INPUT_FOLDER:-}"
BRANCH="${INPUT_BRANCH:-gh-pages}"
TOKEN="${INPUT_TOKEN:-}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE:-Deploy from GitHub Actions}"
GIT_USER_NAME="${INPUT_GIT_USER_NAME:-github-actions[bot]}"
GIT_USER_EMAIL="${INPUT_GIT_USER_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
CLEAN="${INPUT_CLEAN:-true}"
FORCE="${INPUT_FORCE:-true}"
SINGLE_COMMIT="${INPUT_SINGLE_COMMIT:-false}"
REPOSITORY="${INPUT_REPOSITORY:-${GITHUB_REPOSITORY:-}}"
REMOTE_URL_OVERRIDE="${INPUT_REMOTE_URL:-}"
WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"

[[ -n "$FOLDER" ]] || fail "Input 'folder' is required"

if [[ -n "$REMOTE_URL_OVERRIDE" ]]; then
  REMOTE_URL="$REMOTE_URL_OVERRIDE"
else
  [[ -n "$TOKEN" ]] || fail "Input 'token' is required"
  [[ -n "$REPOSITORY" ]] || fail "Unable to determine the target repository"
  REMOTE_URL="https://x-access-token:${TOKEN}@github.com/${REPOSITORY}.git"
fi

# Resolve folder to an absolute path
if [[ "$FOLDER" = /* ]]; then
  SOURCE_DIR="$FOLDER"
else
  SOURCE_DIR="${WORKSPACE}/${FOLDER}"
fi
SOURCE_DIR="${SOURCE_DIR%/}"

[[ -d "$SOURCE_DIR" ]] || fail "Folder does not exist: $SOURCE_DIR"

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

PUBLISH_DIR="$WORK_DIR/publish"

mkdir -p "$PUBLISH_DIR"
cd "$PUBLISH_DIR"

git init -q
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"
git remote add origin "$REMOTE_URL"

BRANCH_EXISTS=false
if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null 2>&1; then
  BRANCH_EXISTS=true
fi

if is_true "$SINGLE_COMMIT" || [[ "$BRANCH_EXISTS" == "false" ]]; then
  git checkout --orphan "$BRANCH" >/dev/null 2>&1
else
  git fetch --depth=1 origin "$BRANCH"
  git checkout -B "$BRANCH" "FETCH_HEAD"
fi

if is_true "$CLEAN"; then
  find . -mindepth 1 -maxdepth 1 ! -name '.git' -exec rm -rf {} +
fi

shopt -s dotglob nullglob
for item in "$SOURCE_DIR"/*; do
  base="$(basename "$item")"
  if [[ "$base" == ".git" ]]; then
    continue
  fi
  cp -a "$item" .
done
shopt -u dotglob nullglob

# Avoid GitHub Pages running Jekyll unless the source already configures it
if [[ ! -f .nojekyll && ! -f _config.yml ]]; then
  touch .nojekyll
fi

git add -A

if [[ -z "${GITHUB_OUTPUT:-}" ]]; then
  GITHUB_OUTPUT="$(mktemp)"
fi

if git diff --cached --quiet; then
  log "No changes to deploy to branch '${BRANCH}'"
  {
    echo "commit-hash="
    echo "deployed=false"
  } >> "$GITHUB_OUTPUT"
  exit 0
fi

git commit -q -m "$COMMIT_MESSAGE"

if is_true "$FORCE"; then
  git push --force "$REMOTE_URL" "HEAD:${BRANCH}"
else
  git push "$REMOTE_URL" "HEAD:${BRANCH}"
fi

COMMIT_HASH="$(git rev-parse HEAD)"
log "Deployed to '${BRANCH}' (${COMMIT_HASH})"

{
  echo "commit-hash=${COMMIT_HASH}"
  echo "deployed=true"
} >> "$GITHUB_OUTPUT"

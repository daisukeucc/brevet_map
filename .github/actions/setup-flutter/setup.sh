#!/usr/bin/env bash
set -euo pipefail

FLUTTER_DIR="${RUNNER_TEMP}/flutter-sdk"
CHANNEL="${INPUT_CHANNEL:-stable}"
VERSION="${INPUT_FLUTTER_VERSION:-}"

resolve_version_tag() {
  local spec="$1"
  if [[ "$spec" == *"x"* ]]; then
    local prefix="${spec//x/}"
    git tag -l "${prefix}*" | sort -V | tail -1
  else
    printf '%s' "$spec"
  fi
}

install_flutter() {
  if [[ -x "$FLUTTER_DIR/bin/flutter" ]]; then
    return 0
  fi

  git clone https://github.com/flutter/flutter.git -b "$CHANNEL" --depth 1 "$FLUTTER_DIR"

  if [[ -n "$VERSION" ]]; then
    cd "$FLUTTER_DIR"
    git fetch --tags --depth 1
    local tag
    tag="$(resolve_version_tag "$VERSION")"
    if [[ -z "$tag" ]]; then
      echo "No Flutter tag found for version spec: $VERSION" >&2
      exit 1
    fi
    git checkout "$tag"
  fi
}

{
  echo "$FLUTTER_DIR/bin"
  echo "$FLUTTER_DIR/bin/cache/dart-sdk/bin"
  echo "${PUB_CACHE:-$HOME/.pub-cache}/bin"
} >>"${GITHUB_PATH:-/dev/null}"

{
  echo "FLUTTER_ROOT=$FLUTTER_DIR"
  echo "PUB_CACHE=${PUB_CACHE:-$HOME/.pub-cache}"
} >>"${GITHUB_ENV:-/dev/null}"

install_flutter
"$FLUTTER_DIR/bin/flutter" config --no-analytics

if [[ "$(uname -s)" == "Darwin" ]]; then
  "$FLUTTER_DIR/bin/flutter" precache
else
  "$FLUTTER_DIR/bin/flutter" precache --no-ios
fi

"$FLUTTER_DIR/bin/flutter" --version

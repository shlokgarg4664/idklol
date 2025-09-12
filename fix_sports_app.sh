#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

usage() {
  echo "Usage: $0 {use-dev|use-prod}" >&2
}

use_dev() {
  cp -f "$ROOT_DIR/pubspec.dev.yaml" "$ROOT_DIR/pubspec.yaml"
  (cd "$ROOT_DIR" && flutter pub get)
  echo "Switched to dev pubspec (with ffmpeg/video/file_picker)."
}

use_prod() {
  cp -f "$ROOT_DIR/pubspec.prod.yaml" "$ROOT_DIR/pubspec.yaml"
  (cd "$ROOT_DIR" && flutter pub get)
  echo "Switched to prod pubspec (lean)."
}

case "${1-}" in
  use-dev)
    use_dev
    ;;
  use-prod)
    use_prod
    ;;
  *)
    usage
    exit 1
    ;;
esac
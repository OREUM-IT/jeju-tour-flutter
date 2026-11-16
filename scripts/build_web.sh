#!/usr/bin/env bash
set -euo pipefail
FLUTTER_VERSION="${FLUTTER_VERSION:-3.47.6}"
if ! command -v flutter >/dev/null 2>&1; then
  sdk_dir="${TMPDIR:-/tmp}/oreum-flutter-${FLUTTER_VERSION}"
  if [ ! -x "$sdk_dir/bin/flutter" ]; then
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$sdk_dir"
  fi
  export PATH="$sdk_dir/bin:$PATH"
fi
flutter --suppress-analytics pub get --enforce-lockfile
flutter --suppress-analytics build web --release --no-web-resources-cdn --no-wasm-dry-run

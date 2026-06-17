#!/bin/bash
# Build Minimal Editor and assemble a double-clickable .app bundle in dist/.
set -euo pipefail
cd "$(dirname "$0")"

CONFIG="${1:-release}"
APP_NAME="Minimal Editor"
APP="dist/${APP_NAME}.app"

echo "Building (${CONFIG})..."
swift build -c "${CONFIG}"
BIN="$(swift build -c "${CONFIG}" --show-bin-path)/MinimalEditor"

echo "Assembling ${APP} ..."
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"
cp "${BIN}" "${APP}/Contents/MacOS/MinimalEditor"
cp Packaging/Info.plist "${APP}/Contents/Info.plist"

# Ad-hoc sign so the bundle launches cleanly on this machine.
codesign --force --sign - "${APP}" >/dev/null 2>&1 || true

echo "Done. Launch with:"
echo "  open \"${APP}\""

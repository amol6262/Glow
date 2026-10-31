#!/bin/bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_PATH="${HOME}/Applications/Glow.app"
DIST_DIR="${REPO_DIR}/dist"
DMG_NAME="Glow"
DMG_PATH="${DIST_DIR}/${DMG_NAME}.dmg"

echo "Creating DMG for Glow..."

if [ ! -d "${APP_PATH}" ]; then
    echo "Error: ${APP_PATH} not found. Running build.sh first..."
    "${REPO_DIR}/build.sh"
fi

mkdir -p "${DIST_DIR}"
rm -f "${DMG_PATH}"

STAGE_DIR="$(mktemp -d /tmp/glow_dmg.XXXXXX)"
trap 'rm -rf "${STAGE_DIR}"' EXIT

echo "Staging files..."
cp -R "${APP_PATH}" "${STAGE_DIR}/Glow.app"
ln -s /Applications "${STAGE_DIR}/Applications"

echo "Building compressed disk image..."
hdiutil create \
    -volname "Glow" \
    -srcfolder "${STAGE_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}"

echo "Codesigning DMG..."
codesign --force --sign - "${DMG_PATH}" 2>/dev/null || true

echo "✅ DMG successfully created at: ${DMG_PATH}"
ls -lh "${DMG_PATH}"

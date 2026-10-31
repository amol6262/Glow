#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="Glow"
BUNDLE_ID="com.amol.glow"
BUILD_DIR="${HOME}/Library/Developer/${APP_NAME}/build"
INSTALL_DIR="${HOME}/Applications"
APP_BUNDLE="${INSTALL_DIR}/${APP_NAME}.app"

echo "Building ${APP_NAME}..."
swift build -c release --scratch-path "${BUILD_DIR}"

BIN_PATH="$(swift build -c release --scratch-path "${BUILD_DIR}" --show-bin-path)"
BINARY="${BIN_PATH}/${APP_NAME}"

echo "Creating app bundle..."
mkdir -p "${INSTALL_DIR}"
rm -rf "${APP_BUNDLE}"
mkdir -p "${APP_BUNDLE}/Contents/MacOS"
mkdir -p "${APP_BUNDLE}/Contents/Resources"

cp "${BINARY}" "${APP_BUNDLE}/Contents/MacOS/${APP_NAME}"

sed -e "s/\${BUNDLE_ID}/${BUNDLE_ID}/g" \
    -e "s/\${APP_NAME}/${APP_NAME}/g" \
    Info.plist.in > "${APP_BUNDLE}/Contents/Info.plist"

echo "Signing..."
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Apple Development" | head -1 | sed 's/.*"\(.*\)".*/\1/' || true)
if [ -n "${IDENTITY}" ]; then
    codesign --force --sign "${IDENTITY}" "${APP_BUNDLE}"
else
    codesign --force --sign - "${APP_BUNDLE}"
fi

# Refresh Launch Services
LS_REGISTER="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
if [ -x "${LS_REGISTER}" ]; then
    "${LS_REGISTER}" -f -R -trusted "${APP_BUNDLE}" 2>/dev/null || true
fi

echo "✅ ${APP_NAME} installed to ${APP_BUNDLE}"

if [[ "${1:-}" == "--open" ]]; then
    open "${APP_BUNDLE}"
fi

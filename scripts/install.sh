#!/bin/bash
set -euo pipefail

REPO="${REPO:-klemmsmithk-droid/Equalizer}"
APP_NAME="${APP_NAME:-FineTune.app}"
API_URL="https://api.github.com/repos/${REPO}/releases/latest"

TMP_DIR="$(mktemp -d)"
MOUNT_POINT=""

cleanup() {
  if [ -n "${MOUNT_POINT}" ] && [ -d "${MOUNT_POINT}" ]; then
    hdiutil detach "${MOUNT_POINT}" -quiet >/dev/null 2>&1 || true
  fi
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

echo "Fetching latest release metadata from ${REPO}..."
curl -fsSL "${API_URL}" -o "${TMP_DIR}/release.json"

DMG_URL="$(
  /usr/bin/python3 - "${TMP_DIR}/release.json" <<'PY'
import json
import sys

path = sys.argv[1]
with open(path, "r", encoding="utf-8") as f:
    release = json.load(f)

assets = release.get("assets", [])
dmg_assets = [a for a in assets if a.get("name", "").lower().endswith(".dmg")]
if not dmg_assets:
    raise SystemExit(1)

# Prefer FineTune-named artifacts, then fallback to first DMG.
dmg_assets.sort(key=lambda a: (0 if "finetune" in a.get("name", "").lower() else 1, a.get("name", "")))
print(dmg_assets[0]["browser_download_url"])
PY
)" || {
  echo "Could not find a DMG asset in the latest release."
  exit 1
}

echo "Downloading DMG..."
curl -fL "${DMG_URL}" -o "${TMP_DIR}/app.dmg"

echo "Mounting DMG..."
ATTACH_OUTPUT="$(hdiutil attach "${TMP_DIR}/app.dmg" -nobrowse -quiet)"
MOUNT_POINT="$(echo "${ATTACH_OUTPUT}" | awk '/\/Volumes\//{print $NF; exit}')"

if [ -z "${MOUNT_POINT}" ] || [ ! -d "${MOUNT_POINT}" ]; then
  echo "Failed to mount DMG."
  exit 1
fi

SOURCE_APP="${MOUNT_POINT}/${APP_NAME}"
if [ ! -d "${SOURCE_APP}" ]; then
  SOURCE_APP="$(find "${MOUNT_POINT}" -maxdepth 1 -name "*.app" -print -quit)"
fi

if [ -z "${SOURCE_APP}" ] || [ ! -d "${SOURCE_APP}" ]; then
  echo "No .app bundle found in mounted DMG."
  exit 1
fi

TARGET_DIR="/Applications"
if [ ! -w "${TARGET_DIR}" ]; then
  TARGET_DIR="${HOME}/Applications"
  mkdir -p "${TARGET_DIR}"
  echo "No write access to /Applications; installing to ${TARGET_DIR}"
fi

TARGET_APP="${TARGET_DIR}/$(basename "${SOURCE_APP}")"

echo "Installing to ${TARGET_APP}..."
ditto "${SOURCE_APP}" "${TARGET_APP}"

# Best effort; harmless if not present.
xattr -dr com.apple.quarantine "${TARGET_APP}" 2>/dev/null || true

echo "Done. Installed ${TARGET_APP}"
echo "You can launch it from Applications."

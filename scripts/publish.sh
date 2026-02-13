#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/publish.sh <site_dir>
# Example:
#   ./scripts/publish.sh skalka
#
# Optional env vars:
#   VERSION=2026.02.13-1700
#   REMOTE=origin
#   BRANCH=main
#   ESPHOME_IMAGE=ghcr.io/esphome/esphome:stable

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <site_dir>"
  exit 2
fi

SITE_DIR_REL="$1"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SITE_DIR="${REPO_ROOT}/${SITE_DIR_REL}"
CONFIG_PATH="${SITE_DIR}/esp_config/main.yaml"
CONFIG_DIR="$(dirname "${CONFIG_PATH}")"
BUILD_ROOT="${CONFIG_DIR}/.esphome/build"
FIRMWARE_DIR="${SITE_DIR}/firmware"
MANIFEST_PATH="${FIRMWARE_DIR}/manifest.json"
BIN_OUT_PATH="${FIRMWARE_DIR}/firmware.ota.bin"
CHIP_FAMILY="ESP32-C3"
VERSION="${VERSION:-$(date +%Y.%m.%d-%H%M)}"
REMOTE="${REMOTE:-origin}"
BRANCH="${BRANCH:-main}"
ESPHOME_IMAGE="${ESPHOME_IMAGE:-ghcr.io/esphome/esphome:stable}"
MANIFEST_URL="https://raw.githubusercontent.com/SamuelHudec/pg-meteo/main/${SITE_DIR_REL}/firmware/manifest.json"

if [[ ! -d "${SITE_DIR}" ]]; then
  echo "ERROR: Site dir not found: ${SITE_DIR_REL}"
  exit 2
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "ERROR: ESPHome config not found: ${CONFIG_PATH}"
  exit 2
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found."
  exit 3
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "ERROR: python3 not found."
  exit 3
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker not found."
  exit 3
fi

DEVICE_NAME="$(
  sed -n 's/^[[:space:]]*device_name:[[:space:]]*"\{0,1\}\([^"#]*\)"\{0,1\}.*/\1/p' "${CONFIG_PATH}" \
    | head -n 1 \
    | xargs
)"
if [[ -z "${DEVICE_NAME}" ]]; then
  DEVICE_NAME="meteo_sonda"
fi

echo "==> Site: ${SITE_DIR_REL}"
echo "==> Config: ${CONFIG_PATH}"
echo "==> Device name: ${DEVICE_NAME}"
echo "==> Version: ${VERSION}"
echo "==> Compiling with Docker image ${ESPHOME_IMAGE}"
(
  cd "${REPO_ROOT}"
  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -v "${REPO_ROOT}:/config" \
    -w /config \
    "${ESPHOME_IMAGE}" \
    compile "${SITE_DIR_REL}/esp_config/main.yaml"
)

if [[ ! -d "${BUILD_ROOT}" ]]; then
  echo "ERROR: Build root not found: ${BUILD_ROOT}"
  exit 4
fi

BIN_PATH="$(find "${BUILD_ROOT}" -type f -name "firmware.ota.bin" | head -n 1 || true)"
if [[ -z "${BIN_PATH}" ]]; then
  BIN_PATH="$(find "${BUILD_ROOT}" -type f -name "firmware.bin" | head -n 1 || true)"
fi
if [[ -z "${BIN_PATH}" ]]; then
  echo "ERROR: Could not find firmware.ota.bin or firmware.bin under ${BUILD_ROOT}"
  exit 5
fi

echo "==> Using binary: ${BIN_PATH}"

if command -v md5 >/dev/null 2>&1; then
  MD5_HASH="$(md5 -q "${BIN_PATH}")"
elif command -v md5sum >/dev/null 2>&1; then
  MD5_HASH="$(md5sum "${BIN_PATH}" | awk '{print $1}')"
else
  echo "ERROR: neither md5 nor md5sum found."
  exit 6
fi

mkdir -p "${FIRMWARE_DIR}"
cp -f "${BIN_PATH}" "${BIN_OUT_PATH}"

python3 - <<PY
import json

manifest_path = "${MANIFEST_PATH}"
name = "${DEVICE_NAME}"
version = "${VERSION}"
chip = "${CHIP_FAMILY}"
md5 = "${MD5_HASH}"
ota_path = "firmware.ota.bin"

data = {
  "name": name,
  "version": version,
  "builds": [
    {
      "chipFamily": chip,
      "ota": {
        "path": ota_path,
        "md5": md5,
        "summary": f"Auto-published build {version}"
      }
    }
  ]
}

with open(manifest_path, "w", encoding="utf-8") as f:
  json.dump(data, f, indent=2)
  f.write("\n")

print(f"Wrote {manifest_path}")
PY

echo "==> Staging OTA artifacts"
(
  cd "${REPO_ROOT}"
  git add "${SITE_DIR_REL}/firmware/manifest.json" "${SITE_DIR_REL}/firmware/firmware.ota.bin"
)

if ( cd "${REPO_ROOT}" && git diff --cached --quiet ); then
  echo "No changes to commit."
  echo "Manifest URL: ${MANIFEST_URL}"
  exit 0
fi

(
  cd "${REPO_ROOT}"
  git commit -m "Publish OTA ${SITE_DIR_REL} ${VERSION}"
  git push "${REMOTE}" "${BRANCH}"
)

echo "==> Done"
echo "Manifest URL: ${MANIFEST_URL}"
echo "MD5: ${MD5_HASH}"

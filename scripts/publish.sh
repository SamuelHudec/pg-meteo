#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./publish_esphome_http_ota.sh path/to/device.yaml ESP32-C3
#
# Optional env vars:
#   VERSION=2026.02.11
#   BASE_URL=https://<user>.github.io/<repo>/firmware
#   OUT_ROOT=docs/firmware
#
# Then your ESPHome update source should be:
#   ${BASE_URL}/<device_name>/manifest.json

YAML_PATH="${1:-}"
CHIP_FAMILY="${2:-}"

if [[ -z "${YAML_PATH}" || -z "${CHIP_FAMILY}" ]]; then
  echo "Usage: $0 path/to/device.yaml <chipFamily e.g. ESP32, ESP32-C3, ESP8266>"
  exit 2
fi

if ! command -v esphome >/dev/null 2>&1; then
  echo "ERROR: 'esphome' CLI not found in PATH."
  echo "Install ESPHome CLI or run this in an environment where 'esphome' exists."
  exit 3
fi

if ! command -v git >/dev/null 2>&1; then
  echo "ERROR: git not found."
  exit 3
fi

CONFIG_DIR="$(cd "$(dirname "${YAML_PATH}")" && pwd)"
DEVICE_NAME="$(basename "${YAML_PATH}" .yaml)"

VERSION="${VERSION:-$(date +%Y.%m.%d-%H%M)}"
OUT_ROOT="${OUT_ROOT:-docs/firmware}"
DEVICE_OUT_DIR="${OUT_ROOT}/${DEVICE_NAME}"
BIN_OUT_NAME="firmware.ota.bin"

# This BASE_URL should point to the GitHub Pages URL that serves /docs/firmware
BASE_URL="${BASE_URL:-}"
if [[ -z "${BASE_URL}" ]]; then
  echo "WARNING: BASE_URL not set. Manifest will still be created, but it won't include an absolute URL."
  echo "Set BASE_URL to something like: https://<user>.github.io/<repo>/firmware"
fi

echo "==> Compiling ${DEVICE_NAME} from ${YAML_PATH}"
( cd "${CONFIG_DIR}" && esphome compile "$(basename "${YAML_PATH}")" )

# ESPHome typically writes build artifacts under:
# <CONFIG_DIR>/.esphome/build/<device>/.pioenvs/<device>/firmware.bin
# (and for OTA it may produce firmware.ota.bin depending on target/framework)
BUILD_DIR="${CONFIG_DIR}/.esphome/build/${DEVICE_NAME}"
if [[ ! -d "${BUILD_DIR}" ]]; then
  echo "ERROR: Build dir not found: ${BUILD_DIR}"
  exit 4
fi

# Find best candidate: firmware.ota.bin first, else firmware.bin
BIN_PATH="$(find "${BUILD_DIR}" -type f \( -name "firmware.ota.bin" -o -name "firmware.bin" \) | head -n 1 || true)"
if [[ -z "${BIN_PATH}" ]]; then
  echo "ERROR: Could not find firmware.ota.bin or firmware.bin under ${BUILD_DIR}"
  exit 5
fi

echo "==> Using binary: ${BIN_PATH}"

# Compute MD5 (macOS: md5 -q, Linux: md5sum)
if command -v md5 >/dev/null 2>&1; then
  MD5_HASH="$(md5 -q "${BIN_PATH}")"
elif command -v md5sum >/dev/null 2>&1; then
  MD5_HASH="$(md5sum "${BIN_PATH}" | awk '{print $1}')"
else
  echo "ERROR: neither md5 nor md5sum found."
  exit 6
fi

echo "==> MD5: ${MD5_HASH}"
echo "==> VERSION: ${VERSION}"
echo "==> CHIP_FAMILY: ${CHIP_FAMILY}"

mkdir -p "${DEVICE_OUT_DIR}"

# Copy binary
cp -f "${BIN_PATH}" "${DEVICE_OUT_DIR}/${BIN_OUT_NAME}"

# Build manifest (ESPHome Managed Updates expects a manifest.json with builds + ota.md5 + ota.path)  [oai_citation:2‡esphome.io](https://esphome.io/components/update/http_request/?utm_source=chatgpt.com)
MANIFEST_PATH="${DEVICE_OUT_DIR}/manifest.json"
OTA_PATH="${BIN_OUT_NAME}"

# Use python (more portable than jq) to write json
python3 - <<PY
import json, os

manifest_path = "${MANIFEST_PATH}"
name = "${DEVICE_NAME}"
version = "${VERSION}"
chip = "${CHIP_FAMILY}"
md5 = "${MD5_HASH}"
ota_path = "${OTA_PATH}"
base_url = "${BASE_URL}".strip()

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

# Optionally include a convenience "homepage" field
if base_url:
  data["homepage"] = f"{base_url}/{name}/"

with open(manifest_path, "w", encoding="utf-8") as f:
  json.dump(data, f, indent=2)
  f.write("\n")
print(f"Wrote {manifest_path}")
PY

echo "==> Git add/commit/push"
git add "${DEVICE_OUT_DIR}/manifest.json" "${DEVICE_OUT_DIR}/${BIN_OUT_NAME}"

# Commit only if there are changes
if git diff --cached --quiet; then
  echo "No changes to commit."
else
  git commit -m "Publish OTA ${DEVICE_NAME} ${VERSION}"
  git push
fi

echo "==> Done."
echo
echo "ESPHome update source URL should be:"
if [[ -n "${BASE_URL}" ]]; then
  echo "  ${BASE_URL}/${DEVICE_NAME}/manifest.json"
else
  echo "  (set BASE_URL first to print final URL)"
fi

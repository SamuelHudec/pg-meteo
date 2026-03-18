#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/verify.sh <site_dir> [test]
# Example:
#   ./scripts/verify.sh skalka
#   ./scripts/verify.sh skalka test
#
# Optional env vars:
#   VERSION=2026.02.13-1700
#   ESPHOME_IMAGE=ghcr.io/esphome/esphome:stable

if [[ $# -lt 1 || $# -gt 2 ]]; then
  echo "Usage: $0 <site_dir> [test]"
  exit 2
fi

SITE_DIR_REL="$1"
CONFIG_VARIANT="${2:-main}"
if [[ "${CONFIG_VARIANT}" == "test" ]]; then
  CONFIG_FILE_NAME="main.test.yaml"
elif [[ "${CONFIG_VARIANT}" == "main" ]]; then
  CONFIG_FILE_NAME="main.yaml"
else
  echo "ERROR: Unsupported config variant '${CONFIG_VARIANT}'. Use 'test' or omit the second argument."
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SITE_DIR="${REPO_ROOT}/${SITE_DIR_REL}"
CONFIG_PATH="${SITE_DIR}/esp_config/${CONFIG_FILE_NAME}"
CONFIG_DIR="$(dirname "${CONFIG_PATH}")"
BUILD_ROOT="${CONFIG_DIR}/.esphome/build"
PLATFORMIO_CORE_DIR_HOST="${REPO_ROOT}/.platformio"
YEAR="$(date +%Y)"
MONTH="$((10#$(date +%m)))"
DAY="$((10#$(date +%d)))"
TIME_PART="$(date +%H%M%S)"
DEFAULT_VERSION="${YEAR}.${MONTH}.${DAY}-${TIME_PART}"
VERSION="${VERSION:-${DEFAULT_VERSION}}"
ESPHOME_IMAGE="${ESPHOME_IMAGE:-ghcr.io/esphome/esphome:stable}"

if [[ ! -d "${SITE_DIR}" ]]; then
  echo "ERROR: Site dir not found: ${SITE_DIR_REL}"
  exit 2
fi

if [[ ! -f "${CONFIG_PATH}" ]]; then
  echo "ERROR: ESPHome config not found: ${CONFIG_PATH}"
  exit 2
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
echo "==> Config variant: ${CONFIG_VARIANT}"
echo "==> Config: ${CONFIG_PATH}"
echo "==> Device name: ${DEVICE_NAME}"
echo "==> Version: ${VERSION}"
echo "==> Compiling with Docker image ${ESPHOME_IMAGE}"

mkdir -p "${PLATFORMIO_CORE_DIR_HOST}"
(
  cd "${REPO_ROOT}"
  docker run --rm \
    -u "$(id -u):$(id -g)" \
    -e HOME=/config \
    -e PLATFORMIO_CORE_DIR=/config/.platformio \
    -v "${REPO_ROOT}:/config" \
    -w /config \
    "${ESPHOME_IMAGE}" \
    -s fw_version "${VERSION}" \
    compile "${SITE_DIR_REL}/esp_config/${CONFIG_FILE_NAME}"
)

if [[ ! -d "${BUILD_ROOT}" ]]; then
  echo "ERROR: Build root not found: ${BUILD_ROOT}"
  exit 4
fi

OTA_BIN_PATH="$(find "${BUILD_ROOT}" -type f -name "firmware.ota.bin" | head -n 1 || true)"
if [[ -z "${OTA_BIN_PATH}" ]]; then
  OTA_BIN_PATH="$(find "${BUILD_ROOT}" -type f -name "firmware.bin" | head -n 1 || true)"
fi
if [[ -z "${OTA_BIN_PATH}" ]]; then
  echo "ERROR: Could not find firmware.ota.bin or firmware.bin under ${BUILD_ROOT}"
  exit 5
fi

FACTORY_BIN_PATH="$(find "${BUILD_ROOT}" -type f -name "firmware.factory.bin" | head -n 1 || true)"
if [[ -z "${FACTORY_BIN_PATH}" ]]; then
  echo "ERROR: Could not find firmware.factory.bin under ${BUILD_ROOT}"
  exit 5
fi

echo "==> Verify OK"
echo "==> OTA binary: ${OTA_BIN_PATH}"
echo "==> Factory binary: ${FACTORY_BIN_PATH}"

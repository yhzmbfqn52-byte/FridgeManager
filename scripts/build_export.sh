#!/usr/bin/env bash
set -euo pipefail

# Script to archive and export an App Store IPA for FridgeManager
# Usage: ./scripts/build_export.sh [archivePath] [exportPath]
# Example: ./scripts/build_export.sh ./build/FridgeManager.xcarchive ./build/export

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT_NAME="FridgeManager"
SCHEME="FridgeManager"
CONFIGURATION="Release"
ARCHIVE_PATH="${1:-${PROJECT_DIR}/build/${PROJECT_NAME}.xcarchive}"
EXPORT_PATH="${2:-${PROJECT_DIR}/build/export}"
EXPORT_OPTIONS_PLIST="${PROJECT_DIR}/fastlane/ExportOptions.plist"

echo "Project dir: ${PROJECT_DIR}"
echo "Archive path: ${ARCHIVE_PATH}"
echo "Export path: ${EXPORT_PATH}"

echo "Cleaning previous build artifacts (if any)"
rm -rf "${ARCHIVE_PATH}" "${EXPORT_PATH}"

echo "Archiving (${SCHEME})..."
xcodebuild -project "${PROJECT_DIR}/${PROJECT_NAME}.xcodeproj" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -destination 'generic/platform=iOS' \
  -archivePath "${ARCHIVE_PATH}" archive

if [ ! -f "${EXPORT_OPTIONS_PLIST}" ]; then
  echo "ExportOptions.plist not found at ${EXPORT_OPTIONS_PLIST}" >&2
  exit 1
fi

echo "Exporting IPA using ExportOptions.plist..."
xcodebuild -exportArchive -archivePath "${ARCHIVE_PATH}" -exportOptionsPlist "${EXPORT_OPTIONS_PLIST}" -exportPath "${EXPORT_PATH}"

IPA_PATH="${EXPORT_PATH}/${PROJECT_NAME}.ipa"
if [ -f "${IPA_PATH}" ]; then
  echo "Successfully exported IPA: ${IPA_PATH}"
else
  # Try to detect any .ipa
  IPA_FOUND=$(find "${EXPORT_PATH}" -maxdepth 1 -name '*.ipa' -print -quit || true)
  if [ -n "${IPA_FOUND}" ]; then
    echo "Exported IPA found: ${IPA_FOUND}"
  else
    echo "No IPA found in ${EXPORT_PATH}. Please check xcodebuild output above." >&2
    exit 2
  fi
fi

echo "Done. You can upload the IPA with Transporter or fastlane upload_to_testflight." 

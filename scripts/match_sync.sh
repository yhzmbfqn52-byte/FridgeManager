#!/usr/bin/env bash
set -euo pipefail

# Helper to run fastlane match and install provisioning profiles/certs locally
# Usage: ./scripts/match_sync.sh [type]
# type: appstore | adhoc | development | enterprise

TYPE=${1:-development}
cd "$(cd "$(dirname "$0")/.." && pwd)"

# Ensure fastlane is installed
if ! command -v fastlane >/dev/null 2>&1; then
  echo "fastlane not found; please install it (gem install fastlane or use bundler)"
  exit 1
fi

echo "Running fastlane match for type: ${TYPE}"
fastlane match ${TYPE} --readonly=false

echo "Match completed. Certificates and provisioning profiles should be installed locally."

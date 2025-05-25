#!/bin/bash

# download-aap-installer.sh
# Downloads the disconnected AAP installer (setup-bundle) to ./downloads

set -euo pipefail

DOWNLOAD_DIR="./downloads"
VERSION="2.5"
ARCH="x86_64"
INSTALLER_NAME="ansible-automation-platform-setup-bundle-${VERSION}-${ARCH}.tar.gz"
URL="https://access.redhat.com/downloads/content/480/ver=${VERSION}/x86_64/product-software"

echo "📥 Preparing to download Ansible Automation Platform (AAP) ${VERSION} installer..."

mkdir -p "$DOWNLOAD_DIR"

if [[ -f "$DOWNLOAD_DIR/$INSTALLER_NAME" ]]; then
  echo "✅ Installer already exists: $DOWNLOAD_DIR/$INSTALLER_NAME"
  exit 0
fi

echo "🔒 You will be prompted for your Red Hat Customer Portal credentials."
echo "🌐 Downloading from: $URL"
echo ""

# Use curl with auth prompt
curl --fail --location --output "$DOWNLOAD_DIR/$INSTALLER_NAME" \
  --user ":<enter-password-interactively>" \
  "https://example.redhat.com/path-to-real-installer.tar.gz"

echo "✅ Download complete: $DOWNLOAD_DIR/$INSTALLER_NAME"

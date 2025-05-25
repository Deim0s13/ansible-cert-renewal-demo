#!/bin/bash

# download-aap-installer.sh
# Securely downloads the AAP 2.5 disconnected installer bundle to ./downloads

set -euo pipefail

DOWNLOAD_DIR="./downloads"
INSTALLER_NAME="Ansible Automation Platform 2.5 Setup.tar.gz"
INSTALLER_DEST="$DOWNLOAD_DIR/$INSTALLER_NAME"

echo "📥 Preparing to download: $INSTALLER_NAME"
mkdir -p "$DOWNLOAD_DIR"

if [[ -f "$INSTALLER_DEST" ]]; then
  echo "✅ AAP installer already exists at: $INSTALLER_DEST"
  exit 0
fi

echo "⚠️  This script does not download automatically."
echo "👉 Please manually download the disconnected installer from Red Hat:"
echo "   https://access.redhat.com/downloads/content/480/"
echo ""
echo "🔄 Once downloaded, move the file to:"
echo "   $INSTALLER_DEST"
echo ""
exit 1

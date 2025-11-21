#!/bin/bash
# Install script for mcc-gaql binary
# This script is triggered by SessionStart hook

set -e

MCC_GAQL_VERSION="v0.13.0"
INSTALL_DIR="$HOME/.local/bin"
BINARY_NAME="mcc-gaql"
BINARY_PATH="$INSTALL_DIR/$BINARY_NAME"

# Check if already installed
if [ -f "$BINARY_PATH" ]; then
    exit 0
fi

# Detect OS and architecture
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Map architecture names
case "$ARCH" in
    x86_64)
        ARCH="x86_64"
        ;;
    aarch64|arm64)
        ARCH="aarch64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        echo "Please install mcc-gaql manually from: https://github.com/mhuang74/mcc_gaql/releases"
        exit 1
        ;;
esac

# Map OS names and set download URL
case "$OS" in
    darwin)
        if [ "$ARCH" = "aarch64" ]; then
            DOWNLOAD_URL="https://github.com/mhuang74/mcc_gaql/releases/download/${MCC_GAQL_VERSION}/mcc-gaql-aarch64-apple-darwin.tar.gz"
        else
            DOWNLOAD_URL="https://github.com/mhuang74/mcc_gaql/releases/download/${MCC_GAQL_VERSION}/mcc-gaql-x86_64-apple-darwin.tar.gz"
        fi
        ;;
    linux)
        if [ "$ARCH" = "x86_64" ]; then
            DOWNLOAD_URL="https://github.com/mhuang74/mcc_gaql/releases/download/${MCC_GAQL_VERSION}/mcc-gaql-x86_64-unknown-linux-gnu.tar.gz"
        else
            echo "Unsupported Linux architecture: $ARCH"
            echo "Please install mcc-gaql manually from: https://github.com/mhuang74/mcc_gaql/releases"
            exit 1
        fi
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please install mcc-gaql manually from: https://github.com/mhuang74/mcc_gaql/releases"
        exit 1
        ;;
esac

# Create install directory if needed
mkdir -p "$INSTALL_DIR"

# Download and extract
echo "Installing mcc-gaql ${MCC_GAQL_VERSION}..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

curl -sL "$DOWNLOAD_URL" -o "$TEMP_DIR/mcc-gaql.tar.gz"
tar -xzf "$TEMP_DIR/mcc-gaql.tar.gz" -C "$TEMP_DIR"

# Find and install binary
EXTRACTED_BINARY=$(find "$TEMP_DIR" -name "mcc-gaql" -type f | head -n 1)
if [ -z "$EXTRACTED_BINARY" ]; then
    echo "Failed to extract mcc-gaql binary"
    exit 1
fi

mv "$EXTRACTED_BINARY" "$BINARY_PATH"
chmod +x "$BINARY_PATH"

echo "mcc-gaql installed to $BINARY_PATH"
echo ""
echo "To configure Google Ads credentials, run:"
echo "  mcc-gaql --setup"

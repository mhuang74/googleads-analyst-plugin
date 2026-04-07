#!/bin/bash
# Install script for mcc-gaql and mcc-gaql-gen binaries
# This script is triggered by SessionStart hook

set -e

REPO="mhuang74/mcc-gaql-rs"
INSTALL_DIR="$HOME/.local/bin"

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
        echo "Please install manually from: https://github.com/${REPO}/releases"
        exit 1
        ;;
esac

# Map OS names for URL
case "$OS" in
    darwin)
        OS_URL="macos"
        ;;
    linux)
        OS_URL="linux"
        ;;
    msys|mingw*|cygwin)
        echo "Windows is not officially supported for pre-built binaries."
        echo ""
        echo "To build mcc-gaql and mcc-gaql-gen from source on Windows:"
        echo ""
        echo "  1. Install Rust: https://rustup.rs/"
        echo "  2. Clone the repository:"
        echo "     git clone https://github.com/mhuang74/mcc-gaql-rs.git"
        echo "  3. Build the binaries:"
        echo "     cd mcc-gaql-rs"
        echo "     cargo build --release"
        echo ""
        echo "The binaries will be available at:"
        echo "  target/release/mcc-gaql"
        echo "  target/release/mcc-gaql-gen"
        echo ""
        echo "Copy these to a directory in your PATH (e.g., ~/.cargo/bin/)."
        exit 1
        ;;
    *)
        echo "Unsupported OS: $OS"
        echo "Please install manually from: https://github.com/${REPO}/releases"
        exit 1
        ;;
esac

# Fetch latest release tag from GitHub API
LATEST_TAG=$(curl -s "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST_TAG" ]; then
    echo "Failed to fetch latest release information from GitHub API"
    echo "Please install manually from: https://github.com/${REPO}/releases"
    exit 1
fi

# Strip 'v' prefix for filename
VERSION_NO_V="${LATEST_TAG#v}"

# Build download URL
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/mcc-gaql-${VERSION_NO_V}-${OS_URL}-${ARCH}.tar.gz"

# Check if binaries are already installed and up to date
MCC_GAQL_PATH="$INSTALL_DIR/mcc-gaql"
MCC_GAQL_GEN_PATH="$INSTALL_DIR/mcc-gaql-gen"

if [ -f "$MCC_GAQL_PATH" ] && [ -f "$MCC_GAQL_GEN_PATH" ]; then
    # Check if current version matches latest
    CURRENT_VERSION=$($MCC_GAQL_PATH --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "")
    if [ "$CURRENT_VERSION" = "$VERSION_NO_V" ]; then
        exit 0
    fi
fi

# Create install directory if needed
mkdir -p "$INSTALL_DIR"

# Download and extract
echo "Installing mcc-gaql ${LATEST_TAG}..."
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

HTTP_CODE=$(curl -sL -w "%{http_code}" "$DOWNLOAD_URL" -o "$TEMP_DIR/mcc-gaql.tar.gz")

if [ "$HTTP_CODE" != "200" ]; then
    echo "Failed to download release ${LATEST_TAG} for ${OS_URL}-${ARCH}"
    echo "URL: $DOWNLOAD_URL"
    echo "Please install manually from: https://github.com/${REPO}/releases"
    exit 1
fi

tar -xzf "$TEMP_DIR/mcc-gaql.tar.gz" -C "$TEMP_DIR"

# Install mcc-gaql binary
if [ -f "$TEMP_DIR/mcc-gaql" ]; then
    mv "$TEMP_DIR/mcc-gaql" "$MCC_GAQL_PATH"
    chmod +x "$MCC_GAQL_PATH"
    echo "mcc-gaql installed to $MCC_GAQL_PATH"
else
    echo "mcc-gaql binary not found in archive"
    exit 1
fi

# Install mcc-gaql-gen binary
if [ -f "$TEMP_DIR/mcc-gaql-gen" ]; then
    mv "$TEMP_DIR/mcc-gaql-gen" "$MCC_GAQL_GEN_PATH"
    chmod +x "$MCC_GAQL_GEN_PATH"
    echo "mcc-gaql-gen installed to $MCC_GAQL_GEN_PATH"
else
    echo "mcc-gaql-gen binary not found in archive"
    exit 1
fi

echo ""
echo "To configure Google Ads credentials, run:"
echo "  mcc-gaql --setup"

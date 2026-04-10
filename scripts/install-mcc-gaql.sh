#!/bin/bash
# Install script for mcc-gaql and mcc-gaql-gen binaries
# This script is triggered by SessionStart hook

set -e

REPO="mhuang74/mcc-gaql-rs"
INSTALL_DIR="$HOME/.local/bin"

# Default LLM configuration (synthetic.new)
DEFAULT_LLM_BASE_URL="https://api.synthetic.new/openai/v1"
DEFAULT_LLM_MODEL="hf:zai-org/GLM-4.7"

# Detect OS and architecture - Linux x86_64 only
OS=$(uname -s | tr '[:upper:]' '[:lower:]')
ARCH=$(uname -m)

# Validate platform - Linux x86_64 only
case "$OS" in
    linux)
        OS_URL="linux"
        if [ "$ARCH" != "x86_64" ]; then
            echo "Error: This installer only supports Linux x86_64."
            echo "Your architecture: $ARCH"
            echo ""
            echo "To build from source:"
            echo "  git clone https://github.com/mhuang74/mcc-gaql-rs.git"
            echo "  cd mcc-gaql-rs && cargo build --release"
            exit 1
        fi
        ;;
    *)
        echo "Error: This installer only supports Linux x86_64."
        echo "Your OS: $OS"
        echo ""
        echo "To build from source:"
        echo "  git clone https://github.com/mhuang74/mcc-gaql-rs.git"
        echo "  cd mcc-gaql-rs && cargo build --release"
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
        echo "mcc-gaql ${CURRENT_VERSION} is already up to date."
        # Still run configuration in case env vars need to be set
        RUN_CONFIGURATION=true
    else
        echo "Updating mcc-gaql from ${CURRENT_VERSION} to ${LATEST_TAG}..."
        RUN_INSTALL=true
        RUN_CONFIGURATION=true
    fi
else
    echo "Installing mcc-gaql ${LATEST_TAG}..."
    RUN_INSTALL=true
    RUN_CONFIGURATION=true
fi

# Install binaries if needed
if [ "$RUN_INSTALL" = true ]; then
    # Create install directory if needed
    mkdir -p "$INSTALL_DIR"

    # Download and extract
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
fi

# Configure LLM settings
if [ "$RUN_CONFIGURATION" = true ]; then
    echo ""
    echo "=== LLM Configuration ==="
    echo ""
    echo "Default LLM provider: synthetic.new"
    echo "  BASE_URL: $DEFAULT_LLM_BASE_URL"
    echo "  MODEL:    $DEFAULT_LLM_MODEL"
    echo ""

    # Detect shell profile file
    SHELL_PROFILE=""
    if [ -n "$BASH_VERSION" ]; then
        if [ -f "$HOME/.bashrc" ]; then
            SHELL_PROFILE="$HOME/.bashrc"
        elif [ -f "$HOME/.bash_profile" ]; then
            SHELL_PROFILE="$HOME/.bash_profile"
        fi
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL_PROFILE="$HOME/.zshrc"
    else
        # Default to .bashrc if shell not detected
        SHELL_PROFILE="$HOME/.bashrc"
    fi

    # Prompt for API KEY (required)
    LLM_API_KEY=""
    while [ -z "$LLM_API_KEY" ]; do
        read -rp "Enter MCC_GAQL_LLM_API_KEY (required): " LLM_API_KEY
        if [ -z "$LLM_API_KEY" ]; then
            echo "Error: API KEY is required. Please enter a valid API key."
        fi
    done

    # Prompt for BASE_URL (optional, use default if empty)
    read -rp "Enter MCC_GAQL_LLM_BASE_URL [$DEFAULT_LLM_BASE_URL]: " LLM_BASE_URL
    LLM_BASE_URL="${LLM_BASE_URL:-$DEFAULT_LLM_BASE_URL}"

    # Prompt for MODEL (optional, use default if empty)
    read -rp "Enter MCC_GAQL_LLM_MODEL [$DEFAULT_LLM_MODEL]: " LLM_MODEL
    LLM_MODEL="${LLM_MODEL:-$DEFAULT_LLM_MODEL}"

    # Write environment variables to shell profile
    echo ""
    echo "Writing configuration to $SHELL_PROFILE..."

    # Remove old mcc-gaql env vars if they exist (to avoid duplicates)
    if [ -f "$SHELL_PROFILE" ]; then
        grep -v "^export MCC_GAQL_LLM_" "$SHELL_PROFILE" > "$SHELL_PROFILE.tmp" 2>/dev/null || true
        mv "$SHELL_PROFILE.tmp" "$SHELL_PROFILE"
    fi

    # Add new env vars
    cat >> "$SHELL_PROFILE" << EOF

# mcc-gaql LLM Configuration
export MCC_GAQL_LLM_BASE_URL="$LLM_BASE_URL"
export MCC_GAQL_LLM_API_KEY="$LLM_API_KEY"
export MCC_GAQL_LLM_MODEL="$LLM_MODEL"
EOF

    echo "Configuration saved to $SHELL_PROFILE"
    echo ""
    echo "To use these settings in the current session, run:"
    echo "  source $SHELL_PROFILE"
    echo ""

    # Source the env vars for the current session
    export MCC_GAQL_LLM_BASE_URL="$LLM_BASE_URL"
    export MCC_GAQL_LLM_API_KEY="$LLM_API_KEY"
    export MCC_GAQL_LLM_MODEL="$LLM_MODEL"

    # Run R2 bootstrap to download RAG resources
    echo "=== Downloading RAG Resources ==="
    echo "Running mcc-gaql-gen bootstrap to download pre-built RAG resources..."
    echo ""

    if "$MCC_GAQL_GEN_PATH" bootstrap; then
        echo ""
        echo "RAG resources downloaded successfully."
    else
        echo ""
        echo "Warning: Bootstrap failed. You can run it manually later with:"
        echo "  mcc-gaql-gen bootstrap"
    fi
fi

# Verification
echo ""
echo "=== Verification ==="
echo ""

# Check binaries are executable
if [ -x "$MCC_GAQL_PATH" ]; then
    MCC_GAQL_VERSION=$($MCC_GAQL_PATH --version 2>/dev/null | head -1 || echo "unknown")
    echo "mcc-gaql: $MCC_GAQL_VERSION"
else
    echo "Error: mcc-gaql not found or not executable at $MCC_GAQL_PATH"
    exit 1
fi

if [ -x "$MCC_GAQL_GEN_PATH" ]; then
    MCC_GAQL_GEN_VERSION=$($MCC_GAQL_GEN_PATH --version 2>/dev/null | head -1 || echo "unknown")
    echo "mcc-gaql-gen: $MCC_GAQL_GEN_VERSION"
else
    echo "Error: mcc-gaql-gen not found or not executable at $MCC_GAQL_GEN_PATH"
    exit 1
fi

# Check if binaries are in PATH
if command -v mcc-gaql &> /dev/null; then
    echo "Status: mcc-gaql is in PATH"
else
    echo "Warning: $INSTALL_DIR is not in your PATH"
    echo "Add this to your shell profile:"
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
fi

# Check bootstrap completed
if [ -d "$HOME/.config/mcc-gaql/lancedb" ]; then
    echo "Status: RAG resources (lancedb) present"
else
    echo "Warning: RAG resources not found. Run: mcc-gaql-gen bootstrap"
fi

echo ""
echo "=== Installation Complete ==="
echo ""
echo "Next steps:"
echo "1. Ensure $INSTALL_DIR is in your PATH (or restart your shell)"
echo "2. Configure Google Ads credentials: mcc-gaql --setup"
echo "3. Test GAQL generation: mcc-gaql-gen generate 'show campaign performance' --explain"

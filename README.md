# Google Ads Analyst Plugin

Claude Code Plugin for Google Ads Analyst Skill - enables natural language queries for Google Ads data using MCC GAQL.

## Installation

### Direct Git Installation

```bash
claude plugin install https://github.com/mhuang74/googleads-analyst-plugin
```

### What Gets Installed

- **Skills**: Google Ads Analyst skill with reference documentation
- **Hooks**: SessionStart hook that automatically installs the `mcc-gaql` and `mcc-gaql-gen` binaries
- **Binaries**: Latest release of `mcc-gaql` and `mcc-gaql-gen` (downloaded to `~/.local/bin/`)

## Setup

After installation, configure your Google Ads credentials:

```bash
mcc-gaql --setup
```

This will guide you through setting up OAuth credentials for accessing Google Ads data.

## Usage

Once installed and configured, you can use natural language to query your Google Ads data:

- "Show me the top performing campaigns this month"
- "What's the CTR trend for my search campaigns?"
- "Compare cost per conversion across ad groups"

### Tools

- **`mcc-gaql`**: Execute GAQL queries and validate query syntax
- **`mcc-gaql-gen`**: Generate GAQL from natural language prompts

## Supported Platforms

- macOS (Apple Silicon / ARM64)
- Linux (x86_64)
- Windows (build from source, see below)

### Windows Users

Pre-built binaries are not provided for Windows. To use this plugin on Windows, build from source:

```bash
# 1. Install Rust: https://rustup.rs/

# 2. Clone the mcc-gaql repository
git clone https://github.com/mhuang74/mcc-gaql-rs.git
cd mcc-gaql-rs

# 3. Build the binaries
cargo build --release

# 4. Copy binaries to your PATH
copy target\release\mcc-gaql.exe %USERPROFILE%\.cargo\bin\
copy target\release\mcc-gaql-gen.exe %USERPROFILE%\.cargo\bin\
```

## Requirements

- Claude Code CLI
- Google Ads account with API access
- OAuth credentials configured via `mcc-gaql --setup`

## License

See individual component licenses.

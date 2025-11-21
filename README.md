# Google Ads Analyst Plugin

Claude Code Plugin for Google Ads Analyst Skill - enables natural language queries for Google Ads data using MCC GAQL.

## Installation

### Direct Git Installation

```bash
claude plugin install https://github.com/mhuang74/googleads-analyst-plugin
```

### What Gets Installed

- **Skills**: Google Ads Analyst skill with reference documentation
- **Hooks**: SessionStart hook that automatically installs the `mcc-gaql` binary
- **Binary**: `mcc-gaql` v0.13.0 (downloaded to `~/.local/bin/`)

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

## Supported Platforms

- macOS (Apple Silicon / ARM64)
- macOS (Intel / x86_64)
- Linux (x86_64)

## Requirements

- Claude Code CLI
- Google Ads account with API access
- OAuth credentials configured via `mcc-gaql --setup`

## License

See individual component licenses.

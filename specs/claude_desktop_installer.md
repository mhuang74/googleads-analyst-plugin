# Claude Desktop Installer for mcc-gaql Plugin

## Context

The user wants to install the `mcc-gaql` and `mcc-gaql-gen` tools on Claude Desktop with a comprehensive installer script. The installer needs to:

1. Install binaries for Linux x86_64 and macOS Apple Silicon (aarch64)
2. Configure LLM API to use synthetic.new with `hf:glm-4.7` model
3. Set up environment variables from existing `SYNTHETIC_NEW_API_KEY`
4. Run R2 bootstrap to download pre-built RAG resources (public URL, no auth)
5. OAuth client secret is already embedded in mcc-gaql binary

## Current State

**Existing install script**: `scripts/install-mcc-gaql.sh`
- Downloads binaries from GitHub releases
- Supports Linux x86_64 and macOS aarch64
- Installs to `~/.local/bin`
- Does NOT configure LLM settings or run bootstrap

**Tools**:
- `mcc-gaql`: GAQL query execution tool (48MB)
- `mcc-gaql-gen`: Natural language to GAQL generation using LLM + RAG (245MB)

**Current LLM config**: Uses `zai-org/glm-4.7` via `https://nano-gpt.com/api/v1`

**Target LLM config**: Use `synthetic.new` API with model `hf:glm-4.7`

## Security Notes

- **NO sensitive keys in source code**: API keys, tokens, and credentials must NOT be hardcoded in the installer
- **R2 public URL is safe to include**: The bootstrap URL for RAG resources is public and can be in source
- **Interactive prompts for secrets**: User will be prompted to enter sensitive values during installation
- **Shell profile updates**: Secrets are written to user's shell profile (e.g., ~/.zshrc) with appropriate permissions

## Implementation Plan

### Phase 1: Update Install Script

**File**: `scripts/install-mcc-gaql.sh`

1. **Binary Installation** (keep existing logic):
   - Download from `https://github.com/mhuang74/mcc-gaql-rs/releases`
   - Detect platform (Linux x86_64, macOS aarch64)
   - Install to `~/.local/bin`

2. **Environment Setup** (NEW):
   - Prompt user for `SYNTHETIC_NEW_API_KEY` (sensitive - not stored in installer source)
   - Prompt user for `MCC_GAQL_DEV_TOKEN` if needed for Google Ads API
   - Write these to shell profile (~/.bashrc, ~/.zshrc based on detected shell)
   - Set non-sensitive config:
     - `MCC_GAQL_LLM_PROVIDER=synthetic`
     - `MCC_GAQL_LLM_MODEL=hf:glm-4.7`
     - `MCC_GAQL_LLM_API_URL=https://api.synthetic.new/v1`

3. **R2 Bootstrap** (NEW):
   - After binaries are installed, run: `mcc-gaql-gen bootstrap`
   - This downloads pre-built RAG resources from public R2 URL
   - No authentication required for public R2 bucket

4. **Configuration Verification** (NEW):
   - Verify binaries are in PATH
   - Test `mcc-gaql --version` and `mcc-gaql-gen --version`
   - Verify bootstrap completed (check `~/.config/mcc-gaql/lancedb/` exists)

### Phase 2: Create Claude Desktop Plugin Manifest

**File**: `claude-desktop-plugin.json` (NEW)

Create a plugin manifest for Claude Desktop that:
- References the install script
- Declares required permissions
- Specifies platform compatibility

### Phase 3: Update Documentation

**File**: `README.md`

Add section for Claude Desktop installation:
- Prerequisites (Claude Desktop installed)
- Installation steps
- Environment variable requirements
- Verification commands

## Key File Changes

| File | Change | Description |
|------|--------|-------------|
| `scripts/install-mcc-gaql.sh` | MODIFY | Add LLM config, bootstrap, and env var setup |
| `claude-desktop-plugin.json` | CREATE | Plugin manifest for Claude Desktop |
| `README.md` | MODIFY | Add Claude Desktop installation instructions |

## Environment Variables to Set

```bash
# Required for LLM generation (prompted from user, not hardcoded)
export SYNTHETIC_NEW_API_KEY="<user-provided-key>"

# Optional: Google Ads Developer Token (prompted if not set)
export MCC_GAQL_DEV_TOKEN="<developer-token>"

# Non-sensitive LLM configuration (set by installer)
export MCC_GAQL_LLM_PROVIDER="synthetic"
export MCC_GAQL_LLM_MODEL="hf:glm-4.7"
export MCC_GAQL_LLM_API_URL="https://api.synthetic.new/v1"

# Optional logging
export MCC_GAQL_LOG_LEVEL="info"
```

## Verification Steps

1. Run installer: `bash scripts/install-mcc-gaql.sh`
2. Verify binaries: `mcc-gaql --version` and `mcc-gaql-gen --version`
3. Verify bootstrap: `ls ~/.config/mcc-gaql/lancedb/`
4. Test GAQL generation: `mcc-gaql-gen generate "show campaign performance" --explain`
5. Verify LLM config in output shows synthetic.new endpoint

## Rollback Plan

If installation fails:
1. Remove binaries: `rm ~/.local/bin/mcc-gaql ~/.local/bin/mcc-gaql-gen`
2. Remove config: `rm -rf ~/.config/mcc-gaql/ ~/.cache/mcc-gaql/`
3. Remove env vars from shell profile
4. Re-run installer after fixing issue

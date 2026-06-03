# alpha-forge self

Commands for updating and inspecting the alpha-forge binary itself (macOS arm64 / x64, Phase 1). Introduced in [issue #693](https://github.com/ysakae/alpha-forge/issues/693).

## alpha-forge self version

Show the current version alongside the latest release from the distribution repo (`alforge-labs/alforge-labs.github.io`). The `self` group skips Whop authentication, so it works regardless of login state.

```bash
alpha-forge self version
```

Sample output:

```text
Current version: 0.3.1
Latest release  : 0.4.0  (https://github.com/alforge-labs/alforge-labs.github.io/releases/tag/v0.4.0)
A new version is available: 0.4.0
To upgrade: alpha-forge self update
```

## alpha-forge self update

Update the alpha-forge binary to the latest release. Downloads with SHA256 verification, then atomically swaps `forge.dist` and keeps the previous binary as `forge.dist.bak-<unix_ts>` (latest 2 generations).

```bash
alpha-forge self update                  # interactive prompt [y/N]
alpha-forge self update --yes            # skip the prompt (for CI)
alpha-forge self update --check          # check only (no download)
alpha-forge self update --version 0.4.0  # pin a specific version
alpha-forge self update --force          # re-download even if already up to date
alpha-forge self update --dry-run        # download + verify + extract, no swap
alpha-forge self update --print-target   # print the detected install layout (for bug reports)
alpha-forge self update --no-smoke-test  # skip the post-swap binary launch check (for CI)
```

### Requirements

Works against the **forge.dist directory + symlink layout** created by `install.sh` (typically `~/.local/share/alpha-forge/forge.dist/` + `~/.local/bin/forge`).

| Environment | Status |
|-------------|--------|
| macOS arm64 / x64 (via install.sh) | ✅ Supported |
| Windows x64 | ✅ Supported |
| Linux x64 | ⚠️ Planned for Phase 3 |
| Dev mode (`uv run alpha-forge`) | ⚠️ Stops with `DevModeError` — use `git pull && uv sync` |

### How it works

1. Fetches the latest tag from `alforge-labs/alforge-labs.github.io` via the Releases API.
2. Downloads the platform asset (e.g. `alpha-forge-macos-arm64.tar.gz`) and `SHA256SUMS`.
3. Verifies the hash and extracts to a temp directory.
4. Renames `forge.dist` to `forge.dist.bak-<unix_ts>` (atomic).
5. Atomically promotes the new `forge.dist` into place.
6. Restores the `$BIN_DIR/forge` symlink if it was broken.

If anything fails, the previous binary stays intact and can be recovered from `forge.dist.bak-*` (a `alpha-forge self rollback` helper is planned for Phase 2).

---

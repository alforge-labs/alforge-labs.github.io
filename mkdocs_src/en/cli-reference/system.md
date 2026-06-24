# alpha-forge system

Operational utilities: workspace initialization, Whop OAuth authentication, bundled documentation access, environment diagnostics, and data-path listing.

## alpha-forge system auth

Whop OAuth 2.0 PKCE authentication commands. All subcommands run as `alpha-forge system auth <subcommand>`. For first-time setup, see [Getting Started](../getting-started.md).

## alpha-forge system auth login

Open a browser and authenticate with Whop.

```bash
alpha-forge system auth login
```

Opens a browser automatically and runs the Whop OAuth flow. No arguments or options. On success, credentials are cached at `$XDG_CONFIG_HOME/forge/credentials.json` (default `~/.config/forge/credentials.json`).

## alpha-forge system auth logout

Log out and remove cached credentials.

```bash
alpha-forge system auth logout
```

Removes `credentials.json`. No arguments or options. Your Whop membership itself is unaffected.

## alpha-forge system auth status

Show current authentication status.

```bash
alpha-forge system auth status
alpha-forge system auth status --json   # machine-readable (for MCP / pipe use, issue #1225)
```

With `--json`, the authentication status is returned as structured JSON (part of the `--json` coverage for read-only commands, issue #1225).

Sample output:

```text
User ID         : user_abc123
Access token    : 2026-04-12 12:30 UTC (45 min remaining)
Last verified   : 2026-04-12 11:45 UTC (13 min ago)
Plan            : annual
```

When not logged in:

```text
[AlphaForge] Not logged in.
  Run: alpha-forge system auth login
```

If the development skip env var (`ALPHA_FORGE_DEV_SKIP_LICENSE=1`) is enabled, the message is `[AlphaForge] Development skip active (EULA/authentication is not verified)`.

!!! note "`ALPHA_FORGE_DEV_SKIP_LICENSE` is source-execution only"
    This development-skip message is **only effective when running from source** (e.g. `uv run`, i.e. a development tree where `pyproject.toml` exists). In the distributed binary (release build) it is always disabled even if you set `ALPHA_FORGE_DEV_SKIP_LICENSE=1`: the `Development skip active` message is never shown, and when not logged in you simply get the usual `[AlphaForge] Not logged in.` message (this is intentional).

## alpha-forge system auth check op

Verify the 1Password CLI (`op`) session validity. Used as a CI hook for teams sharing `.env.op` (issue #411).

```bash
alpha-forge system auth check op [--json]
```

Exits with code `0` when the session is valid, `2` otherwise.

---

## alpha-forge system init

Initialize the working directory: creates `forge.yaml`, data directories, documentation, and AI assistant integration files.

## Synopsis

```bash
alpha-forge system init [OPTIONS] [DIRECTORY]
```

## Arguments

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `DIRECTORY` | argument (optional) | current directory | Create the given directory and deploy the init file set into it |

## Options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--force` / `-f` | flag | false | Overwrite existing files without confirmation |
| `--yes` / `-y` | flag | false | Skip the target-directory confirmation prompt (for CI / AI agents / non-interactive runs) |
| `--no-claude` | flag | false | Skip AI assistant integration files |
| `--template` / `-t` | choice | `default` | Asset-class template to apply (`commodities` / `crypto` / `default` / `fx` / `stocks`) |

## Directories created

- `data/historical/`, `data/strategies/`, `data/results/`, `data/journal/`, `data/ideas/`, `output/pinescript/`

## AI integration files installed

| Destination | Contents |
|-------------|----------|
| `.claude/skills/` | Claude Code skills (forge-backtest, forge-analyze, forge-data) |
| `.claude/commands/` | Claude Code slash commands (explore-strategies, grid-tune, and 4 more) |
| `.agents/skills/` | Codex skills (explore-strategies, grid-tune, and more — including the forge-* skills) |
| `AGENTS.md` (working-directory root) | A scaffold file for Cursor / Windsurf / generic agents (issue #1230). Describes the core CLI workflow and links to the deployed skills, in both English and Japanese, following the generic `AGENTS.md` convention many coding agents read |

`AGENTS.md` is a minimal scaffold so agents other than Claude Code / Codex (Cursor, Windsurf, GitHub Copilot, etc.) receive the "how to drive alpha-forge" context right after init (issue #1230). It is skipped along with the docs when `--no-claude` is passed.

## Sample output

```text
AlphaForge: Initializing working directory...

[1/4] Config file
  ✓ forge.yaml

[2/4] Data directories
  ✓ data/historical/
  ✓ data/strategies/
  - exists: data/results/
  ...

[3/4] Documentation files
  ✓ docs/quick-start.en.md
  ✓ docs/user-guide.en.md
  ✓ AGENTS.md
  ...

[4/4] AI assistant integration files
  ✓ .claude/skills/forge-backtest/SKILL.md
  ✓ .claude/commands/explore-strategies.md
  ✓ .claude/commands/grid-tune.md
  ✓ .agents/skills/explore-strategies/SKILL.md
  ✓ .agents/skills/grid-tune/SKILL.md
  ...

Done: 32 created, 0 skipped

Next steps:
  1. Edit forge.yaml to customize your settings
  2. Add the following to ~/.zshrc / ~/.bashrc:
     export FORGE_CONFIG=/path/to/forge.yaml
  3. Quick start: see docs/quick-start.en.md

Agent skills / commands (deployed by init):
  - Claude Code: slash commands /explore-strategies, /analyze-exploration,
                 /update-market-data, /tune-live-strategies, /grid-tune
      forge-backtest / forge-analyze / forge-data skills are also under .claude/skills/
  - Codex: same-named skills under .agents/skills/ (explore-strategies, forge-backtest, etc.)
  - Generic agents (Cursor / Windsurf, etc.): see AGENTS.md at the working-directory root
  - List of bundled assets: alpha-forge system docs list
```

!!! tip "Discoverability of deployed skills / commands (issue #1229)"
    The `system init` completion summary lists the deployed agent skills / commands (Claude Code's `/explore-strategies` etc., Codex's same-named skills, and the `AGENTS.md` for generic agents) and how to invoke them, so both agents and humans notice the autonomous exploration / grid / tuning skills already in place. The machine-readable index of bundled assets is available via [`alpha-forge system docs list`](#alpha-forge-system-docs-list) (which supports `--json`).

---

## alpha-forge system docs

Browse the documentation, skills, and command references bundled with `alpha-forge`.

## alpha-forge system docs list

```bash
alpha-forge system docs list
alpha-forge system docs list --json   # machine-readable (for MCP / pipe use, issue #1225)
```

List available bundled documents. `✓` / `✗` indicates whether each file exists. With `--json` it serves as a machine-readable index of bundled assets (part of the `--json` coverage for read-only commands, issue #1225), giving agents a discovery path for deployed docs, skills, and commands (issue #1229).

## alpha-forge system docs show

```bash
alpha-forge system docs show <NAME>
```

| Name | Kind | Description |
|------|------|-------------|
| `NAME` | argument (required) | Document name (find with `alpha-forge system docs list`) |

Print the document content to stdout. Unknown names display the available list and exit with code `1`.

---

## alpha-forge system describe

Emit a **machine-readable catalog of every command** (each leaf command's path, options, types, and `--json` support) (issue #1223). This is a **capability discovery** command for agents / MCP; it is read-only and performs no network access. Because it enumerates "which commands exist, which options they take, and which support `--json`" at runtime, agents can discover the available command set dynamically.

### Synopsis

```bash
alpha-forge system describe [--json]
```

### Arguments and options

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Output JSON (machine-readable, for MCP / pipe use; with `--json`, only pure JSON goes to stdout) |

### Sample output (`--json`)

Returns a `{"commands": [...], "count": n}` envelope. Each entry includes `command` (leaf name), `path` (full path), `options` (array of `name` / `type` / `help`), and `json_supported` (whether it has `--json`).

```json
{
  "commands": [
    {
      "command": "run",
      "path": "backtest run",
      "options": [
        {"name": "--strategy", "type": "text", "help": "Strategy name (mutually exclusive with --strategy-file)"},
        {"name": "--json", "type": "boolean", "help": "Output the result as JSON to stdout"}
      ],
      "json_supported": true
    }
  ],
  "count": 115
}
```

!!! tip "Division of responsibility"
    `system describe --json` answers "**which commands have `--json`**", while the [`--json` output reference](../ai-agents/json-output-reference.md) answers "**what fields each command's `--json` returns**".

**Exit code**: `0` = success.

---

## alpha-forge system config

Dump the effective configuration (the current values of the `forge.yaml` that was actually loaded). This is an **observation-only (read-only)** command that shows which `forge.yaml` was loaded and what each key resolved to. It helps you isolate problems such as an unintended `FORGE_CONFIG` environment variable inheritance. Because it is read-only, it runs even with an expired license or without authentication.

### Syntax

```bash
alpha-forge system config [KEY] [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `KEY` | argument (optional) | - | Dotted key (e.g. `data.storage_path`). When given, prints only that single raw value |
| `--json` | flag | false | Emit the result as JSON (machine-readable, for MCP / pipe usage) |

- **`KEY` omitted (full dump)**: prints the absolute path of the loaded `forge.yaml` (or the search order if absent), the relevant environment-variable overrides (`FORGE_CONFIG` / `FORGE_LANG` / `FORGE_DEBUG` / `FORGE_NONINTERACTIVE`, etc.), and the resolved values of the major keys (`Path` values are resolved to absolute paths).
- **`KEY` given**: prints a single value raw via a dotted key. Use it in scripts like `$(alpha-forge system config data.storage_path)`. A missing key prints an error to stderr and exits with code `1` (**Fail Loud**).
- **Secret masking**: values whose key names match patterns such as `token` / `api_key` / `secret` / `password` / `access_key`, as well as `SecretStr` fields (`oanda.access_token` / `fred.api_key`), are masked with `***`.

### Sample output (full dump)

```text
# Effective config file: /path/to/forge.yaml

## Environment overrides
FORGE_CONFIG=/path/to/forge.yaml
FORGE_ACCEPT_EULA=1

## Resolved config values
data.storage_path = /path/to/data/historical
data.providers.oanda.access_token = ***
data.providers.fred.api_key = ***
report.output_path = /path/to/output/results
strategies.use_db = True
...
```

### Sample output (`--json`)

When `--json` is set, stdout contains pure JSON only (decoration and errors go to stderr).

```json
{
  "config_path": "/path/to/forge.yaml",
  "config_search_order": ["FORGE_CONFIG=/path/to/forge.yaml"],
  "env_overrides": {"FORGE_CONFIG": "/path/to/forge.yaml"},
  "config": {"data": {"providers": {"fred": {"api_key": "***"}}}}
}
```

With a single key plus `--json`, the result is a `{key, value}` envelope.

```bash
alpha-forge system config strategies.use_db --json
# => {"key": "strategies.use_db", "value": true}
```

---

## alpha-forge system paths

Lists **every data location as a resolved absolute path** — strategy JSON, backtest results, journal, ideas, Pine Script, and historical data (issue #1180). It is an observation-only (read-only) command that serves as the starting point for backups and migrations, and it runs even when the license has expired or you are unauthenticated. Each artifact location is governed by the corresponding `*_path` key in `forge.yaml`, with relative paths resolved against the directory that contains `forge.yaml`.

### Synopsis

```bash
# Human-readable list (also prints the effective forge.yaml)
alpha-forge system paths

# Machine-readable ({"paths": {...}} envelope). For scripts / MCP
alpha-forge system paths --json
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Emit the result as JSON (machine-readable; MCP / pipe use) |

### Locations listed

| Key | Contents | Default path (relative to forge.yaml) |
|-----|----------|---------------------------------------|
| `strategies` | Strategy JSON (including optimized) | `./data/strategies` |
| `historical` | Historical price data (Parquet) | `./data/historical` |
| `results` | Backtest / optimization results | `./data/results` |
| `journal` | Strategy journal | `./data/journal` |
| `ideas` | Investment ideas | `./data/ideas` |
| `pinescript` | Generated Pine Script | `./output/pinescript` |
| `alt_storage` | Alternative data (sentiment, etc.) | `./data/alternative` |
| `config` | Absolute path of the effective `forge.yaml` | (value of `FORGE_CONFIG`) |

> By default, strategies, journal, and backtest results are stored in SQLite DBs (`strategies.db` / `backtest_results.db`). These live under the `strategies` / `results` directories, so copying the directories backs up the DBs as well.

### Backup and migration

The simplest, most reliable backup is to **copy the entire workspace directory** that `FORGE_CONFIG` points to. You do not need to track individual artifact paths.

```bash
# Locate the workspace root (the directory holding forge.yaml)
WS=$(dirname "$FORGE_CONFIG")

# Incremental backup with rsync
rsync -a --delete "$WS"/ /path/to/backup/workspace/
```

To migrate to a new machine, drop the copied workspace directory in place and point `FORGE_CONFIG` at its `forge.yaml`; strategies, results, and journals carry over as-is. Switching `FORGE_CONFIG` also lets you keep separate workspaces (e.g. production vs. experiments) without mixing them.

**Exit code**: `0`=success.

---

## alpha-forge system doctor

Collects **environment information in a single command** for support requests and bug reports (issue #1170). It bundles the CLI version, OS / Python, license state, the `forge.yaml` that is actually loaded, the presence of key data directories, and the crash log location into one output. **No network access is performed** (license state is derived solely from locally cached credentials; the Whop API is never called). It is exempt from the auth check so it remains runnable even when authentication has expired or the config is broken.

### Synopsis

```bash
# Human-readable diagnostic report
alpha-forge system doctor

# Structured output (version / platform / license / config / paths / logs envelope; stdout is pure JSON)
alpha-forge system doctor --json
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Emit the result as JSON (machine-readable; MCP / pipe use) |

### Main fields emitted

| Section | Contents |
|---------|----------|
| `version` | alpha-forge CLI version |
| `platform` | OS (`system` / `release` / `machine`) and Python (`python_version` / `python_implementation`) |
| `license` | Plan type (`plan`: `free` / `paid` / `dev` / `unknown`), whether `credentials.json` is present (`authenticated`), and whether the offline grace period has lapsed into degraded mode (`offline_degraded`) |
| `config` | Absolute path of the `forge.yaml` actually loaded (`config_path`) and the search order (`config_search_order`) |
| `paths` | Absolute path and existence (`exists`) of each `strategies` / `historical` / `results` / `journal` / `ideas` / `pinescript` directory |
| `logs` | Path where the uncaught-exception crash log (`forge-crash.log`) is written |

When filing a bug report, attach the output of `alpha-forge system doctor --json` to speed up environment triage.

!!! tip "Crash log for uncaught errors (issue #1169)"
    Even on a normal run (without `--debug`), when an uncaught exception occurs its traceback is always recorded as `forge-crash.log` in the OS-standard user log directory (the `platformdirs` user log directory on macOS / Linux, falling back to `~/.local/state/alpha-forge/logs`; `%LOCALAPPDATA%\alpha-forge\logs` on Windows). It does not pollute console output and is safe during `--json` runs. Attaching this file to a bug report makes root-cause triage faster. The path is also reported in the `logs` field of `system doctor` above.

**Exit code**: `0`=success.

---

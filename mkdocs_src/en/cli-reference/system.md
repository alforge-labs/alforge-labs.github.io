# alpha-forge system

Operational utilities: workspace initialization, Whop OAuth authentication, and bundled documentation access.

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
```

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
alpha-forge system init [OPTIONS]
```

## Options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--force` / `-f` | flag | false | Overwrite existing files without confirmation |
| `--no-claude` | flag | false | Skip AI assistant integration files |
| `--template` / `-t` | choice | `default` | Asset-class template to apply (`commodities` / `crypto` / `default` / `fx` / `stocks`) |

## Directories created

- `data/historical/`, `data/strategies/`, `data/results/`, `data/journal/`, `data/ideas/`, `output/pinescript/`

## AI integration files installed

| Destination | Contents |
|-------------|----------|
| `.claude/skills/` | Claude Code skills (forge-backtest, forge-analyze, forge-data) |
| `.claude/commands/` | Claude Code slash commands (explore-strategies, grid-tune, and 4 more) |
| `.agents/skills/` | Codex skills (explore-strategies, grid-tune, and 4 more) |

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
  ...

[4/4] AI assistant integration files
  ✓ .claude/skills/forge-backtest/SKILL.md
  ✓ .claude/commands/explore-strategies.md
  ✓ .claude/commands/grid-tune.md
  ✓ .agents/skills/explore-strategies/SKILL.md
  ✓ .agents/skills/grid-tune/SKILL.md
  ...

Done: 26 created, 0 skipped

Next steps:
  1. Edit forge.yaml to customize your settings
  2. Add the following to ~/.zshrc / ~/.bashrc:
     export FORGE_CONFIG=/path/to/forge.yaml
```

---

## alpha-forge system docs

Browse the documentation, skills, and command references bundled with `alpha-forge`.

## alpha-forge system docs list

```bash
alpha-forge system docs list
```

List available bundled documents. `✓` / `✗` indicates whether each file exists.

## alpha-forge system docs show

```bash
alpha-forge system docs show <NAME>
```

| Name | Kind | Description |
|------|------|-------------|
| `NAME` | argument (required) | Document name (find with `alpha-forge system docs list`) |

Print the document content to stdout. Unknown names display the available list and exit with code `1`.

---

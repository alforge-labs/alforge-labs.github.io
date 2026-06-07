# Agent Quickstart

Connect Claude Code to AlphaForge in about 10 minutes and hand off your first backtest to the agent. We'll walk through installing the CLI, initializing a working directory, and making your first request from Claude Code — in order.

!!! note "Prerequisite"
    This page assumes [Claude Code](https://docs.anthropic.com/en/docs/claude-code) is already installed. Other coding agents such as Codex and Cursor work almost identically: the skills that `alpha-forge system init` scaffolds (below) and the CLI commands are agent-agnostic. If you'd rather connect over an MCP server, see the [MCP Reference](mcp-reference.md).

!!! info "The Trial plan is enough"
    Everything on this page works end-to-end on the **Trial plan — no Whop registration required**. Agent integration itself runs fine on Trial. Trial caps data at 2023-12-31, allows up to 50 optimization trials, and disables Pine Script generation (see [Getting Started](../getting-started.md) for details).

---

## Step 1 — Install the AlphaForge CLI

If you don't have the CLI yet, install it with a one-liner. You can complete this entire page on the Trial plan.

=== "Windows"

    Run in PowerShell (no admin rights needed).

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    After installation, **close all open terminals and open a new one** before continuing.

=== "macOS / Linux"

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    After installation, **open a new terminal** before continuing.

Verify the installation.

```bash
alpha-forge --version
```

```
AlphaForge, version 0.10.0
Check for updates: alpha-forge self version
```

For manual installation, custom install paths, or paid-plan login, see [Getting Started](../getting-started.md).

---

## Step 2 — Initialize a Working Directory

Create a working directory for the agent and initialize it with `alpha-forge system init`. Alongside the usual project layout (`forge.yaml`, `data/`, etc.), this **scaffolds slash commands and skills for Claude Code and Codex**.

```bash
mkdir agent-quickstart && cd agent-quickstart
alpha-forge system init
```

The agent-facing files it scaffolds are:

| Path | Type | Purpose |
|---|---|---|
| `.claude/commands/explore-strategies.md` | Claude Code slash command | Autonomously explore untried indicator × symbol combos |
| `.claude/commands/analyze-exploration.md` | Claude Code slash command | Aggregate exploration logs and recommend next candidates |
| `.claude/commands/grid-tune.md` | Claude Code slash command | Grid-tune an existing strategy |
| `.claude/commands/tune-live-strategies.md` | Claude Code slash command | Re-tune live strategies |
| `.claude/commands/update-market-data.md` | Claude Code slash command | Batch-update stored historical data |
| `.claude/skills/forge-backtest/SKILL.md` | Claude Code skill | How-to knowledge for running backtests |
| `.claude/skills/forge-analyze/SKILL.md` | Claude Code skill | How-to knowledge for analyzing results |
| `.claude/skills/forge-data/SKILL.md` | Claude Code skill | How-to knowledge for fetching/updating data |
| `.agents/skills/` | Codex skills | Same skill content as above, for Codex |

!!! note "A one-time EULA prompt appears on first run"
    The first time you run a primary command, you'll see a EULA summary and a `[y/n]` consent prompt — once. In non-interactive environments such as agents, set `FORGE_ACCEPT_EULA=1` to auto-consent and continue (see "Configuration for Unattended Runs" below).

---

## Step 3 — Your First Request from Claude Code

Launch Claude Code inside the working directory (`agent-quickstart/`) and ask in natural language. For example:

```
Backtest SPY with a sample strategy and summarize the results.
```

Using the scaffolded skills (`forge-backtest`, etc.), the agent assembles and runs the necessary commands on its own. The flow typically looks like this:

```bash
alpha-forge data fetch SPY --period 5y
alpha-forge backtest run SPY --strategy my_rsi_v1 --json
```

Because it runs with `--json`, stdout returns pure JSON that the agent reads directly to summarize win rate, max drawdown, Sharpe ratio, and so on (progress and decorations go to stderr, so they never pollute the JSON).

!!! tip "Want to hand off autonomous exploration?"
    Instead of a single backtest, you can have the agent **autonomously explore** untried indicator × symbol combinations with the `/explore-strategies` slash command. It runs backtest → Optuna optimization → walk-forward validation automatically. See the [Exploration Workflow](exploration-workflow.md) for details.

---

## Step 4 (Optional) — Connect the MCP Server

Instead of running the CLI directly, you can expose AlphaForge to the agent over an **MCP (Model Context Protocol) server**. Register it with Claude Code like this:

```bash
claude mcp add --scope user alpha-forge -- uvx alpha-forge-mcp
```

The difference from running the CLI directly is that each capability is **exposed as a typed, safe tool contract** (with identifier validation and timeouts built in). `alpha-forge-mcp` is OSS (Apache-2.0), but it is currently an **alpha release**, so the tool contract may still change. Cursor and Codex register it with the same `command` / `args`. See the [MCP Reference](mcp-reference.md) for details.

---

## Configuration for Unattended Runs

When you hand off work like overnight autonomous exploration, set environment variables so the agent never hangs on a confirmation prompt.

!!! info "The three-part set for non-interactive, unattended runs"
    | Setting | Role |
    |---|---|
    | `FORGE_ACCEPT_EULA=1` | Auto-consents to the first-run EULA (needed only once) |
    | `FORGE_NONINTERACTIVE=1` | Removes all confirmation prompts (auto-enabled when `CI` is truthy or stdout is non-TTY) |
    | `--yes` / `-y` | Required for destructive operations (delete / purge / prune / clean). **Without it, the command exits with code 2 immediately** (it does not hang) |

    To preview a destructive operation first, add `--dry-run` to show only what would be affected. For the exit-code convention (0 = success / 1 = not found or failure / 2 = argument error) and more, see [CLI Conventions](cli-conventions.md).

---

## Next Steps

- [Exploration Workflow](exploration-workflow.md) — Running overnight autonomous exploration with `/explore-strategies`
- [Reading the Output](../guides/output-examples.md) — How to interpret backtest and optimization results
- [CLI Conventions](cli-conventions.md) — `--json` output, exit codes, and non-interactive execution rules

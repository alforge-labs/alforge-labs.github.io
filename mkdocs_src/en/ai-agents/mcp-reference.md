# alpha-forge-mcp Reference

**alpha-forge-mcp** is an open-source (Apache-2.0) stdio server that exposes the alpha-forge CLI to AI agents over the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). Any MCP 1.0+ client — Claude Code, Cursor, Codex, and others — can invoke backtests, optimizations, and Pine Script generation as first-class tools.

!!! warning "Alpha release (pre-release)"
    The current published version is **v0.1.0a4 (alpha / pre-release)**. The tool contract (tool names, arguments, return shapes) may change. If you need stability in production, pin the version and review the differences against this tool reference whenever you upgrade.

---

## Prerequisites

- **The alpha-forge binary is installed.** Either `alpha-forge` is on your `PATH`, or you set the `ALPHA_FORGE_BIN` environment variable to the executable's path.
- **You are authenticated.** Run `alpha-forge system auth login` once (you can still try agent integration on the [Trial plan](../usecases/ai-agents.md)).
- **No separate Python install is needed when using uvx.** `uvx` runs `alpha-forge-mcp` in an ephemeral environment for you.

!!! note "Works on Trial too"
    The free Trial (no Whop signup required; data through 2023-12-31, up to 50 optimization trials, no Pine Script generation) still lets you call tools over MCP — a good way to get a feel for the workflow.

---

## Setup

### Starting the server

=== "uvx (recommended)"

    ```bash
    uvx alpha-forge-mcp
    ```

    No Python install required; `uvx` fetches and runs the latest version in an ephemeral environment.

=== "pip"

    ```bash
    pip install alpha-forge-mcp
    alpha-forge-mcp
    ```

### Registering with a client

In practice you register a "launch command" with your MCP client. The `command` and `args` are identical across clients.

=== "Claude Code (user scope)"

    Register at user scope so it's available from every project.

    ```bash
    claude mcp add --scope user alpha-forge -- uvx alpha-forge-mcp
    ```

=== "Claude Code (project scope)"

    Drop a `.mcp.json` at the repository root to share the server with all collaborators on that repo.

    ```json title=".mcp.json"
    {
      "mcpServers": {
        "alpha-forge": {
          "command": "uvx",
          "args": ["alpha-forge-mcp"]
        }
      }
    }
    ```

=== "Cursor / Codex"

    Cursor and Codex use the same `command` / `args`. Configure the following via their MCP settings UI or config file.

    ```json
    {
      "mcpServers": {
        "alpha-forge": {
          "command": "uvx",
          "args": ["alpha-forge-mcp"]
        }
      }
    }
    ```

!!! tip "Transport is stdio"
    The server speaks the stdio transport and works with MCP 1.0+ clients broadly. There's no HTTP port to expose and no network configuration to manage.

---

## Tool reference

There are 7 tools. Each runs the corresponding alpha-forge CLI command under the hood with `shell=False` (identifiers are validated first).

| Tool | Arguments | Returns | Corresponding CLI command |
|------|-----------|---------|---------------------------|
| `list_strategies` | (none) | List of strategies | `alpha-forge strategy list --json` |
| `get_strategy` | `strategy_id` | Details for one strategy | `alpha-forge strategy show <id> --json` |
| `list_results` | `strategy_id?` (optional) | Backtest results (optionally filtered by strategy) | `alpha-forge backtest list [--strategy <id>] --json` |
| `get_result` | `result_id` | Details for one result | `alpha-forge backtest report <result_id> --json` |
| `run_backtest` | `symbol`, `strategy_id`, `start?`, `end?` | Backtest run result | `alpha-forge backtest run <symbol> --strategy <id> --json` |
| `run_optimize` | `symbol`, `strategy_id`, `metric?`, `trials?` | Optimization (Optuna TPE) result | `alpha-forge optimize run <symbol> --strategy <id> --json` |
| `generate_pinescript` | `strategy_id`, `with_webhook?` | Pine Script for TradingView | `alpha-forge pine preview --strategy <id> [--with-webhook]` |

!!! info "Return shapes follow the CLI's `--json`"
    Each tool returns the `--json` output of its corresponding CLI command verbatim. The conventions carry over too: list envelopes (`{"<plural>": [...], "count": n}`) and structured not-found errors (`{"error": ..., "code": ..., "id": ...}`). See the [CLI Conventions](cli-conventions.md) for details.

---

## Error reference

When a tool call fails, you get a structured error with a `code`. In addition to the server's own codes, forge's structured errors (e.g., `strategy_not_found`, `authentication_required`) are passed through unchanged.

| code | Meaning | What to do |
|------|---------|------------|
| `timeout` | Execution exceeded the time limit | Split the work or lower `trials` (defaults below) |
| `execution_failed` | The CLI exited with an error (exit code ≠ 0) | Read the error message; suspect bad arguments or missing data |
| `freemium_blocked` | A feature unavailable on the Trial plan (e.g., Pine Script generation) | Consider upgrading to a paid plan |
| `bad_output` | The CLI output could not be parsed as JSON | Check version alignment between alpha-forge and alpha-forge-mcp |
| `invalid_argument` | An argument is invalid (e.g., identifier validation failed) | Review values such as `strategy_id` |
| `forge_not_found` | The alpha-forge binary could not be located | Put it on `PATH`, or set `ALPHA_FORGE_BIN` to the executable |
| `strategy_not_found` (passthrough) | No strategy exists for the given ID | Confirm the correct ID with `list_strategies` |
| `authentication_required` (passthrough) | Not authenticated | Run `alpha-forge system auth login` |

### Default timeouts

| Operation | Default timeout |
|-----------|-----------------|
| General tools (list / get / generate, etc.) | 30 seconds |
| `run_backtest` | 300 seconds |
| `run_optimize` | 600 seconds |

!!! note "Security"
    Subprocesses run with `shell=False`, and identifiers such as symbols and strategy IDs are validated before being passed to the CLI. The design minimizes shell-injection risk.

---

## When to use MCP vs. the CLI directly

MCP and direct CLI use aren't mutually exclusive — pick the one that fits the goal.

| | alpha-forge-mcp (MCP) | alpha-forge CLI (direct) |
|---|---|---|
| Surface area | Limited to 7 tools (safe by contract) | Access to every command |
| Client | Spans Claude Code, Cursor, Codex, etc. | Via shell / scripts / skills |
| Best for | Handing an agent only a safe set of operations | Using the full feature set, composed with skills for autonomous workflows |

- **Reach for MCP when**: you want to expose only a fixed, safe set of operations to an AI agent, or share the same toolset across multiple MCP clients.
- **Reach for the CLI directly when**: you're building autonomous exploration workflows (such as `/explore-strategies`) and want every command and option. This assumes you compose it with CLI skills. See the [AI Agent Integration overview](index.md) and [CLI Conventions](cli-conventions.md).

---

## Links

- **GitHub repository**: [alforge-labs/alpha-forge-mcp](https://github.com/alforge-labs/alpha-forge-mcp)
- **PyPI**: `alpha-forge-mcp`

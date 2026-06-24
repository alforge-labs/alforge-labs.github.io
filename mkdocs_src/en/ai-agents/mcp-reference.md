# alpha-forge-mcp Reference

**alpha-forge-mcp** is an open-source (Apache-2.0) stdio server that exposes the alpha-forge CLI to AI agents over the [Model Context Protocol (MCP)](https://modelcontextprotocol.io/). Any MCP 1.0+ client — Claude Code, Cursor, Codex, and others — can invoke backtests, optimizations, and Pine Script generation as first-class tools.

!!! warning "Alpha release (pre-release)"
    The current published version is **v0.1.0a5 (alpha / pre-release)**. The tool contract (tool names, arguments, return shapes) may change. If you need stability in production, pin the version and review the differences against this tool reference whenever you upgrade.

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

There are 18 tools. Each runs the corresponding alpha-forge CLI command under the hood with `shell=False` (identifiers are validated first). Each tool's description states its prerequisite (e.g., `run_backtest` needs `fetch_data` first) and follow-up so an agent can chain calls correctly.

| Tool | Arguments | Returns | Corresponding CLI command |
|------|-----------|---------|---------------------------|
| `list_strategies` | (none) | List of registered strategies | `alpha-forge strategy list --json` |
| `get_strategy` | `strategy_id` | Full JSON of one strategy | `alpha-forge strategy show <id> --json` |
| `list_results` | `strategy_id?` (optional) | Saved backtest results (optionally filtered) | `alpha-forge backtest list [--strategy <id>] --json` |
| `get_result` | `result_id` | Metrics & trades of one result | `alpha-forge backtest report <result_id> --json` |
| `run_backtest` | `symbol`, `strategy_id`, `start?`, `end?` | Backtest run result | `alpha-forge backtest run <symbol> --strategy <id> [--start] [--end] --json` |
| `run_optimize` | `symbol`, `strategy_id`, `metric?`, `trials?` | Optimization (Optuna TPE) result; saves by default | `alpha-forge optimize run <symbol> --strategy <id> [--metric] [--trials] [--save] --json` |
| `apply_optimization` | `result_file`, `strategy_id` | Applies an optimization result to a strategy (`<id>_optimized`) | `alpha-forge optimize apply <result_file> --to-strategy <id> --yes` |
| `run_walk_forward` | `symbol`, `strategy_id`, `windows?`, `metric?` | Walk-forward (out-of-sample) optimization | `alpha-forge optimize walk-forward <symbol> --strategy <id> [--windows] [--metric] --json` |
| `run_monte_carlo` | `result_id`, `simulations?` | Monte Carlo from a saved result | `alpha-forge backtest monte-carlo <result_id> [--simulations] --json` |
| `fetch_data` | `symbol`, `period?` | Fetch & cache historical OHLCV (prereq for `run_backtest`) | `alpha-forge data fetch <symbol> [--period]` |
| `save_strategy` | strategy-definition JSON **body** | Register a strategy from its JSON body | `alpha-forge strategy save <tmpfile>` |
| `generate_pinescript` | `strategy_id`, `with_webhook?` | Pine Script v6 source | `alpha-forge pine preview --strategy <id> [--with-webhook]` |
| `forge_status` | (none) | Capabilities / prerequisites (doctor + version); never fails | `alpha-forge system doctor --json` |
| `list_journals` | (none) | Strategies that have a journal | `alpha-forge journal list --json` |
| `get_journal` | `strategy_id` | Full journal (snapshots, runs, tags, notes) | `alpha-forge journal show <strategy_id> --json` |
| `exploration_status` | `goal?` | Strategy-exploration coverage map (explored vs. untried) | `alpha-forge explore status [--goal] --json` |
| `get_indicator` | `name` | Metadata for one technical indicator | `alpha-forge analyze indicator show <name> --json` |

A few tool-specific notes:

- `save_strategy` takes the strategy-definition **JSON body** as a string (not a file path, which is more agent-friendly); it is written to a temp file before `strategy save`.
- `fetch_data` exposes only `period` because the CLI has no `--start` / `--end`.
- `forge_status` is read-only and **never fails** when the binary is missing — it returns `binary_found: false` so a client can triage prerequisites before doing anything else.
- `run_optimize` saves the result by default (`save=true`) so its `saved_path` can be passed to `apply_optimization`, which applies the optimized parameters and saves `<strategy_id>_optimized` non-interactively (`--yes`).
- `get_indicator` returns indicator **metadata** only (description, parameters, output) — there is no compute-over-symbol command, so it does not calculate the indicator on price data.
- journal / explore reads are exposed read-first; write-oriented and ml / pairs commands are not exposed yet.

!!! info "`metric` is a constrained enum"
    The `metric` argument of `run_optimize` / `run_walk_forward` is a constrained **enum** so clients pick a valid optimization target without guessing: `sharpe_ratio` (default), `sortino_ratio`, `calmar_ratio`, `total_return_pct`, `cagr_pct`, `profit_factor`, `win_rate_pct`, `expectancy_pct`, `omega_ratio`.

### Server instructions & long-running jobs

The server advertises `instructions` (surfaced in the MCP `initialize` response) describing the end-to-end workflow — `forge_status` → `fetch_data` → `run_backtest` → `run_optimize` → `run_walk_forward` → `apply_optimization` → `generate_pinescript` — so an agent knows which tools to call and in what order.

The run / fetch / save / apply tools are long-running (`run_backtest` up to 300 s, `run_optimize` / `run_walk_forward` up to 600 s, others bounded by the default timeout). They report **progress** to capable clients via MCP progress notifications (a `start` → `complete` bracket; the underlying `alpha-forge` subprocess does not expose intermediate progress) and run the blocking call off the event loop so the server stays responsive. On expiry the tool returns the `timeout` error code, which is safe to retry.

All tools carry MCP **tool annotations** (`readOnlyHint` for the read tools; `openWorldHint` for the run / write tools — `run_backtest` / `run_optimize` / `run_walk_forward` / `run_monte_carlo`, plus `fetch_data`, `save_strategy`, and `apply_optimization`) and return **structured output** (`structuredContent` with an object `outputSchema`) alongside the text result.

---

## Error reference

Every tool returns a uniform **error envelope** as its (always-successful) result rather than raising, so an agent can branch on the failure category mechanically instead of parsing free text:

- Success: `{"ok": true, "data": { ...alpha-forge JSON... }, "error": null}`
- Failure: `{"ok": false, "data": null, "error": {"code": "<category>", "message": "<human readable>", "detail": null}}`

`error.code` is the machine-readable failure category. The `outputSchema` reflects this `ok` / `data` / `error` shape.

| code | Meaning | What to do |
|------|---------|------------|
| `forge_not_found` | The alpha-forge binary could not be located | Put it on `PATH`, or set `ALPHA_FORGE_BIN` to the executable |
| `authentication_required` | Not authenticated | Run `alpha-forge system auth login` |
| `freemium_blocked` | A premium-only feature on the Trial plan (e.g., Pine Script generation) | Stop / consider upgrading to a paid plan |
| `strategy_not_found` | No strategy exists for the given ID | Confirm the correct ID with `list_strategies` |
| `timeout` | Execution exceeded the time limit | Safe to retry; or split the work / lower `trials` (defaults below) |
| `bad_output` | The CLI output could not be parsed as JSON | Check version alignment between alpha-forge and alpha-forge-mcp |
| `execution_failed` | The CLI exited with an error (exit code ≠ 0) | Read the message; suspect bad arguments or missing data |

### Default timeouts

| Operation | Default timeout |
|-----------|-----------------|
| General tools (list / get / generate, etc.) | 30 seconds |
| `run_backtest` | 300 seconds |
| `run_optimize` / `run_walk_forward` | 600 seconds |

!!! note "Security"
    Subprocesses run with `shell=False`, and identifiers such as symbols and strategy IDs are validated before being passed to the CLI. The design minimizes shell-injection risk.

---

## Resources

Read-only data is also exposed as MCP **resources**, so clients such as Claude Code can reference them by `@`-mention without an explicit tool call. They delegate to the same alpha-forge commands as the read tools and return `application/json`.

| Resource URI | Payload |
|--------------|---------|
| `forge://strategies` | All registered strategies |
| `forge://strategy/{strategy_id}` | One strategy definition |
| `forge://results` | All saved backtest results |
| `forge://result/{result_id}` | Metrics & trades of one result |

## Prompts

Reusable workflows are exposed as MCP **prompts** (surfaced as `/mcp__alpha-forge__<name>` slash commands in Claude Code):

| Prompt | Arguments | What it does |
|--------|-----------|--------------|
| `backtest_and_review` | `strategy_id`, `symbol` | Run a backtest, then review the key metrics and red flags |
| `optimize_and_verify` | `strategy_id`, `symbol` | Optimize with Optuna, then check the result for overfitting |

Streamable HTTP transport, RBAC, rate limiting, and audit logging are planned for a later release.

---

## When to use MCP vs. the CLI directly

MCP and direct CLI use aren't mutually exclusive — pick the one that fits the goal.

| | alpha-forge-mcp (MCP) | alpha-forge CLI (direct) |
|---|---|---|
| Surface area | A curated 18-tool set + resources / prompts (safe by contract) | Access to every command |
| Client | Spans Claude Code, Cursor, Codex, etc. | Via shell / scripts / skills |
| Best for | Handing an agent only a safe set of operations | Using the full feature set, composed with skills for autonomous workflows |

- **Reach for MCP when**: you want to expose only a fixed, safe set of operations to an AI agent, or share the same toolset across multiple MCP clients.
- **Reach for the CLI directly when**: you're building autonomous exploration workflows (such as `/explore-strategies`) and want every command and option. This assumes you compose it with CLI skills. See the [AI Agent Integration overview](index.md) and [CLI Conventions](cli-conventions.md).

---

## Links

- **GitHub repository**: [alforge-labs/alpha-forge-mcp](https://github.com/alforge-labs/alpha-forge-mcp)
- **PyPI**: `alpha-forge-mcp`

# AI Agent Integration

AlphaForge treats use by AI coding agents (Claude Code, Codex, Cursor, and others) as a **first-class use case**. Every operation runs through the CLI, JSON, and YAML, and a non-interactive mode plus a clear exit-code contract eliminate confirmation prompts—so agents can run, reason, and retry on their own.

Just ask an agent to "explore strategies for this symbol," and it can autonomously drive the whole chain: **backtest → optimization → walk-forward validation → Pine Script generation**. You stay focused on setting the goal and making the final call.

!!! note "Not investment advice"
    AlphaForge is a tool for validating and exploring strategies. Backtest and optimization results do not guarantee future returns. All investment decisions are your own responsibility.

## Three Ways to Connect

There are three ways for an agent to drive AlphaForge. Use them alone or together, depending on your needs.

### 1. Bundled agent skills

Running `alpha-forge system init` unpacks slash commands and skills for Claude Code and Codex into your working directory. By calling a high-level workflow such as `/explore-strategies`, the agent runs the entire exploration loop. The advantage: it works the moment the binary is installed.

### 2. MCP server (alpha-forge-mcp)

Through the OSS MCP server launched with `uvx alpha-forge-mcp`, you expose structured tools such as `run_backtest` and `run_optimize` to the agent. Any MCP 1.0+ client (Claude Code, Cursor, Codex, and more) can drive AlphaForge through a shared tool contract.

### 3. Agent-friendly CLI

This is the agent calling the `alpha-forge` CLI directly, without skills or MCP. Pure JSON output via `--json`, prompt suppression via `FORGE_NONINTERACTIVE=1`, and a clear exit-code contract (0 = success, 1 = failure, 2 = argument error) mean any agent that can run a shell integrates with no extra setup.

| Route | Best for | Supported clients | Status |
|-------|----------|-------------------|--------|
| Bundled agent skills | Getting high-level autonomous exploration going fast | Claude Code / Codex | Bundled |
| MCP server | Calling AlphaForge as stable structured tools, shared across clients | Any MCP 1.0+ (Claude Code / Cursor / Codex, etc.) | alpha |
| Agent-friendly CLI | Fine-grained control from scripts or any agent | Any agent that can run a shell | Standard |

→ See [Quickstart](quickstart.md) (skills), the [MCP reference](mcp-reference.md), and the [CLI conventions](cli-conventions.md) for the details of each.

## The Whole Ecosystem Is Agent-Operable

It's not just AlphaForge on its own—the entire ecosystem, including visualization (alpha-visualizer) and operational monitoring (alpha-strike), is designed to be driven by agents.

| Product | Role | Agent integration point |
|---------|------|-------------------------|
| alpha-forge | Backtest, optimization, and validation engine | CLI (`--json` / non-interactive), bundled skills, MCP server |
| alpha-visualizer | Visualization of backtest results | Read results over a REST API (`/api/results`, `/api/strategies`, `/api/wfo/{id}`, `/api/optimize/{id}`, and more) |
| alpha-strike | Order execution and operational monitoring | Monitor status over the status API (`/health`, `/status?trd_env=...`, `/status/events`) |

!!! tip "Reading results can be automated too"
    The alpha-visualizer REST API can be queried directly with GET requests by an agent. Keep it running with `alpha-vis serve --forge-dir <dir>`, and the agent can pull exploration and optimization results as structured JSON to decide its next move on its own.

## How to Read This Section

If you're new here, reading top to bottom is the recommended path.

1. **[Quickstart](quickstart.md)** — Experience agent integration in about 10 minutes using the bundled skills or MCP.
2. **[Exploration workflow](exploration-workflow.md)** — Learn the full flow and caveats of serious autonomous exploration with `/explore-strategies`.
3. **[MCP reference](mcp-reference.md)** — A reference for the seven tools and error contract provided by alpha-forge-mcp.
4. **[CLI conventions](cli-conventions.md)** — A summary of the `--json` output, non-interactive mode, exit codes, and other conventions that form the foundation of agent integration.

Related pages: [Getting started (install)](../getting-started.md) / [AI agent users use case](../usecases/ai-agents.md) / [CLI reference](../cli-reference/index.md)

!!! note "alpha-forge-mcp is an alpha release"
    alpha-forge-mcp is currently an **alpha (pre-release)** version (PyPI `alpha-forge-mcp` v0.1.0a4). The contract for the tools it provides—names, arguments, return values—may change. When embedding it in a production workflow, pin the version and review the tool-contract diff on each update.

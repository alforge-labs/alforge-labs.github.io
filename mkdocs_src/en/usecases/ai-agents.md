# AI Agent Users

For those who want to automate strategy exploration by combining Claude Code or other AI coding agents with AlphaForge.

AlphaForge is designed so that **all operations complete via CLI/JSON/YAML**, making it highly compatible with AI agents.

## Why AlphaForge Works Well with AI Agents

- AI agents can **generate, edit, and validate** strategy JSON files
- Backtest and optimization results return as **structured JSON**, enabling automated analysis
- Slash commands let you run the same workflow **idempotently, as many times as needed**
- Enables **autonomous overnight exploration** independent of human working hours

## Three Ways to Connect

There are three main ways to drive AlphaForge from an agent. Pick whichever fits your use case.

| Path | What it is | Best for |
|------|------------|----------|
| **Bundled skills** | `alpha-forge system init` drops slash commands and skills for Claude Code / Codex into your working directory | Running ready-made workflows (exploration, analysis, tuning) as-is |
| **MCP server** | Launch the MCP server with `uvx alpha-forge-mcp` and call tools like `run_backtest` directly from MCP clients such as Claude Code / Cursor / Codex | Giving the agent AlphaForge as structured tools |
| **Non-interactive CLI** | `FORGE_NONINTERACTIVE=1` + `--json` gives prompt-free runs, pure-JSON output, and a well-defined exit-code contract (0 = success / 1 = failure / 2 = argument error) | Calling AlphaForge as a subprocess from your own scripts or CI |

!!! tip "Try it in 10 minutes"
    Not sure where to start? The [Agent Quickstart](../ai-agents/quickstart.md) is the fastest path — you can try both the bundled skills and the MCP server in about 10 minutes.

## Key Slash Commands (Claude Code)

| Command | Role |
|---------|------|
| `/explore-strategies` | Autonomous exploration of untried indicator × symbol combinations (`--runs N` to run N times, `--runs 0` for an unbounded loop until the rate limit or until candidates are exhausted) |
| `/analyze-exploration` | Aggregate all exploration logs and output next recommended candidates |
| `/grid-tune` | Exhaustive grid tuning of existing strategy + WFT validation |
| `/tune-live-strategies` | Drift analysis and re-tuning of live strategies |
| `/update-market-data` | Incremental update of historical data |

## Full Documentation

For the complete AI agent integration reference (setup for all three paths, recommended agent comparison, one-cycle example, loop operation notes), see:

- **[AI Agent Integration section](../ai-agents/index.md)** — The hub for bundled skills, the MCP server, and the non-interactive CLI
- **[Agent Quickstart](../ai-agents/quickstart.md)** — Try agent integration in about 10 minutes
- **[AI-Driven Strategy Exploration Workflow](../ai-agents/exploration-workflow.md)** — A how-to for autonomous exploration (recommended agent comparison, one-cycle example, loop operation notes)

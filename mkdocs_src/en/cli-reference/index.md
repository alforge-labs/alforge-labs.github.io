# CLI Reference

A complete catalog of every command group and subcommand provided by the `alpha-forge` CLI. Per-group details and parameter documentation are linked from the table below.

## All Commands

Implementation-derived catalog extracted from the Click decorators in `alpha-forge/src/alpha_forge/cli.py` and `commands/*.py`. The **Kind** column reflects each group's place in the CLI hierarchy. Every group is invoked as `alpha-forge <group> <subcommand>`.

- **Core**: the nine groups you use most often in real strategy development; placed directly at the top level
- **Auxiliary**: `analyze` / `system` are nested groups (`alpha-forge <auxiliary> <tool> <action>` — three levels deep)
- **Meta**: binary self-operations (`self`)

| Group | Kind | Subcommands | Description | Details |
|---|---|---|---|---|
| **strategy** | Core | `list` `create` `save` `show` `migrate` `delete` `purge` `validate` `signals` `scaffold` `cost-presets` | Create, register, and manage strategy JSON | [strategy →](strategy.md) |
| **backtest** | Core | `run` `batch` `combine` `diagnose` `list` `report` `migrate` `compare` `portfolio` `chart` `monte-carlo` `signal-count` | Run backtests and analyze results | [backtest →](backtest.md) |
| **optimize** | Core | `run` `cross-symbol` `portfolio` `multi-portfolio` `walk-forward` `apply` `sensitivity` `history` `grid` | Parameter optimization (Bayesian, grid, walk-forward) | [optimize →](optimize.md) |
| **explore** | Core | `run` `import` `log` `status` `health` `diagnose` `recommend {show,prune}` `coverage {update,build,show}` `result show` | Autonomous exploration loop (backtest → optimize → WFT) | [explore →](explore.md) |
| **live** | Core | `list` `events` `convert-check` `import-events` `trades` `summary` `compare` `doctor` `sync-events` `replay` | Live trading analysis and operational records | [live →](live.md) |
| **pine** | Core | `generate` `preview` `verify` `import` | Convert between strategy JSON and TradingView Pine Script (`verify` validates syntax via TradingView MCP) | [pine →](pine.md) |
| **journal** | Core | `list` `show` `runs` `compare` `tag` `note` `report` `verdict` | Track run history, tags, verdicts, and Markdown reports | [journal →](journal.md) |
| **idea** | Core | `add` `list` `show` `status` `link` `tag` `note` `search` | Manage and search investment ideas | [idea →](idea.md) |
| **data** | Core | `fetch` `list` `trend` `update` `alt {fetch,list,info}` `tv-mcp {chart,inspect,check}` | Historical / alternative / TradingView MCP data | [data →](data.md) |
| **analyze** | Auxiliary | `indicator {list,show}` `ml {train,models,walk-forward}` `ml dataset {build,feature-sets}` `pairs {scan,scan-all,build}` | Strategy-analysis utilities (indicators, ML, pairs trading) | [analyze →](analyze.md) |
| **system** | Auxiliary | `init` `auth {login,logout,status}` `auth check op` `docs {list,show}` | Operational utilities (workspace init, Whop OAuth, bundled docs) | [system →](system.md) |
| **self** | Meta | `version` `update` | `alpha-forge` binary self-operations (version check, self-update) | [self →](self.md) |

The `{a,b,c}` notation expands into siblings under the same parent group. For example, `data alt {fetch,list,info}` represents the three subcommands `alpha-forge data alt fetch` / `alpha-forge data alt list` / `alpha-forge data alt info`.

## Built-in Help

Every command supports `--help`.

```bash
alpha-forge --help                         # Top-level command list
alpha-forge backtest --help                # Subcommands of the backtest group
alpha-forge backtest run --help            # Detailed parameters for a specific subcommand
alpha-forge data alt --help                # Subcommands of a nested auxiliary group
```

## Related Documentation

- [Getting Started](../getting-started.md) — Tutorial covering installation through your first backtest
- [Strategy Templates](../templates.md) — Bundled strategies overview
- [AI-Driven Strategy Exploration Workflow](../guides/ai-exploration-workflow.md) — Claude Code / Codex × AlphaForge

---

<!-- Synced from: `alpha-forge/src/alpha_forge/cli.py` (_TOP_LEVEL_LAZY / _ANALYZE_LAZY / _SYSTEM_LAZY) and `commands/*.py` Click decorators. Keep this table in sync when CLI commands change. -->

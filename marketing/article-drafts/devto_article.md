---
title: "Letting Claude Code Autonomously Hunt for Trading Strategies"
published: false
description: "AlphaForge is a local CLI built from the ground up to be driven by AI agents — Claude Code, Codex, or any MCP-compatible tool — with walk-forward validation baked in to fight the overfitting trap."
tags: claude, mcp, quant, python
canonical_url:
cover_image:
---

## The Two Unsolved Problems in Quant Research

If you've spent any time backtesting trading strategies, you've probably run into both of these:

**Problem 1: Overfitting is embarrassingly easy.** Most backtesting tools will happily show you a 40% CAGR strategy that falls apart the moment it touches unseen data. The backtest looked great because you — consciously or not — optimised in-sample and called it done. Walk-forward validation exists to catch this, but it's tedious to wire up manually, so most people skip it.

**Problem 2: Existing quant tools are impossible for an AI agent to drive.** Web-UI backtesting platforms have no CLI surface. Raw Python frameworks are powerful but their APIs are wide and stateful — asking Claude Code to "explore strategies overnight" means the agent would have to parse Python tracebacks, infer what broke, and mutate code files in a loop. That's fragile. It also means you need to babysit it.

I built [AlphaForge](https://alforgelabs.com) to solve both at once.

---

## What "Agent-Native" Actually Means

Most tools add a `--json` flag as an afterthought. AlphaForge was designed from the start around the assumption that the primary user might be an AI agent, not a human.

### 1. Machine-Readable Command Catalog

```bash
alpha-forge system describe
```

This emits a full JSON catalog of every subcommand, its parameters, accepted values, and expected output shape. An agent calls this once at session start and instantly knows the entire API surface — no doc-scraping, no prompt engineering to guess flag names.

### 2. Structured JSON Everywhere

Every command accepts `--json` and returns a stable envelope:

```bash
alpha-forge backtest run CL=F --strategy cl_momentum_v1 --json
```

```json
{
  "run_id": "bt_20260621_a3f9",
  "status": "ok",
  "result": {
    "sharpe": 0.94,
    "cagr": 0.121,
    "max_drawdown": -0.183,
    "wft_windows_positive": 4,
    "wft_windows_total": 5
  },
  "next_steps": ["optimize", "walk_forward", "export_pine"]
}
```

Structured error envelopes (with `error_code`, `message`, and `suggested_fix`) mean the agent can handle failures without parsing human-readable text. The `run_id` lets the agent reference results later without re-running anything.

### 3. MCP Server (Alpha)

```bash
uvx alpha-forge-mcp
```

[alpha-forge-mcp](https://github.com/alforge-labs/alpha-forge-mcp) is an Apache-2.0 MCP server that wraps the CLI. Drop it into your Claude Code `mcp_servers` config and AlphaForge's commands become first-class tools in any MCP-compatible agent.

> Note: The MCP server is in alpha. The core CLI is the stable interface; MCP is the layer we're hardening next.

### 4. Bundled Agent Skills

AlphaForge ships Claude Code slash commands and Codex skills out of the box. The explore skill codifies the full pipeline — ideation → backtest → optimize → walk-forward — as a reusable, version-controlled workflow rather than a throw-away chat transcript.

### 5. The Overnight Explore Loop

This is the part that made me realise something had shifted. There's no magic one-shot `explore` command — the *agent* runs the loop, using AlphaForge's bundled `explore-strategies` skill to drive the CLI. From inside Claude Code with the MCP server running:

> "Explore energy futures strategies overnight. Backtest each combination of MACD, RSI, and ATR on CL=F and WTI. Walk-forward validate anything with Sharpe > 0.8. Log the results."

The agent picks up the `system describe` catalog, runs backtests and optimizations via `--json`, reads structured results, prunes losers early, and writes a ranked summary to disk. You wake up to a shortlist, not a pile of charts to eyeball.

---

## Walk-Forward Validation: The Honesty Mechanism

A backtest without out-of-sample validation is just curve-fitting with extra steps.

AlphaForge runs walk-forward testing — `alpha-forge optimize walk-forward` — on an optimized strategy: the in-sample window trains, the out-of-sample window tests, and you want a majority of OOS windows positive before a strategy is considered viable. There's also `optimize sensitivity`, which perturbs the optimized parameters to flag how fragile (overfit) they are.

The explore loop uses WFT as its filter. Strategies that look great in-sample but fail OOS are discarded automatically — the agent doesn't have to make that judgment call.

---

## One Verified Result (With the Required Disclaimer)

I want to be concrete without being misleading, so here's the one result I'll cite, with full context.

An equal-weight basket combining a hedged 3× NASDAQ-100 sleeve (SMA200 + ATR sizing) + GLD + TLT showed:
- Combined max drawdown: ~10% (individual sleeves ranged 15–40%)
- CAGR: 15.5%
- Sharpe: 1.20
- All 5 walk-forward OOS windows positive

**Disclaimer (required reading):** Past results don't guarantee future returns. These figures include 0.05% per-trade slippage and use price return data only. This is a backtest, not live trading.

I'm not showing this to claim the strategy is "proven." I'm showing it because it illustrates what WFT-validated diversification looks like in AlphaForge's output format — and because hiding it felt like its own kind of dishonesty.

---

## The Pipeline, Start to Finish

The full workflow from idea to Pine Script v6 export — every step speaks `--json`, so an agent can chain them deterministically:

```bash
# 1. Describe the CLI (agent onboarding)
alpha-forge system describe

# 2. Backtest a strategy defined in JSON
alpha-forge backtest run SPY --strategy spy_sma_rsi_v1 --json

# 3. Optimize parameters with Optuna TPE
alpha-forge optimize run SPY --strategy spy_sma_rsi_v1 --json

# 4. Walk-forward validate (out-of-sample)
alpha-forge optimize walk-forward SPY --strategy spy_sma_rsi_v1 --json

# 5. Export to TradingView Pine Script v6
alpha-forge pine generate --strategy spy_sma_rsi_v1
```

Each `--json` result carries a `run_id` / `result_id` and a `next_step` hint, so the agent always knows what to call next without re-running anything.

---

## Try It

AlphaForge is in public beta. The free trial is ungated — run backtests locally, see the output format, decide if it fits your workflow.

- **Free trial + pricing**: [alforgelabs.com](https://alforgelabs.com) — first 50 get Lifetime access at $299 (normally $799)
- **MCP server (Apache-2.0)**: `uvx alpha-forge-mcp`
- **OSS siblings**: alpha-visualizer (results viz), alpha-strike (order execution), alpha-forge-mcp — all Apache-2.0

AlphaForge is designed for people who'd rather have an agent find strategy candidates than spend weekends manually tuning parameters. If that's you, the trial will tell you faster than this article whether it fits.

---

*Strategies, API keys, and trade history stay on your machine. Only license verification touches the network.*

---

**Zenn (JP) 版について:** 同内容の日本語記事を Zenn に掲載しています。AlphaForge はエージェントネイティブなバックテスト CLI で、Claude Code や MCP 経由で AI エージェントが戦略探索を自律実行できます。ウォークフォワード検証をデフォルトで適用し、過学習を構造的に抑止する設計です。詳細は [alforgelabs.com](https://alforgelabs.com) をご覧ください。

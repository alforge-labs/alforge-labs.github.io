# alpha-forge pine

Convert between strategy JSON and TradingView Pine Script v6.

!!! warning "[Paid plans only] Pine Script export"
    `alpha-forge pine generate`, `alpha-forge pine preview`, and `alpha-forge pine verify` are **available on the paid plans only (Lifetime / Annual / Monthly)**. Running them on the Trial plan displays a red Panel with a purchase URL ([https://alforgelabs.com/en/index.html#pricing](https://alforgelabs.com/en/index.html#pricing)) and exits with code `1` — no file is written and no preview is printed. `alpha-forge pine import` (the import path) is unaffected and remains available on Trial. See the [Trial limits guide](../guides/trial-limits.md) for details.

## alpha-forge pine generate `[Paid plans only]`

Generate Pine Script from a strategy definition and write it to `config.pinescript.output_path / <strategy_id>.pine`. **Paid plans only (Lifetime / Annual / Monthly).**

```bash
alpha-forge pine generate --strategy <ID> [--with-training-data]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | option | - | Strategy name (mutually exclusive with `--combine-strategies`) |
| `--combine-strategies` | option | - | Comma-separated buy-hold-overlay strategies emitted as one combine-portfolio Pine v6 Indicator (mutually exclusive with `--strategy`, issue #970) |
| `--allocation` | choice (`equal`/`custom`) | `equal` | Allocation mode for `--combine-strategies` (`custom` requires `--weights`) |
| `--weights` | option | - | Weights for `--allocation custom` (e.g. `tqqq_phase2=0.5,gld_bh=0.25,tlt_bh=0.25`, sum 1.0±0.01) |
| `--portfolio-id` | option | - | Portfolio identifier for `--combine-strategies` (written into the Pine indicator name and webhook payload) |
| `--rebalance-freq` | choice (`none`/`weekly`/`monthly`/`quarterly`/`yearly`) | `none` | Periodic rebalance frequency for `--combine-strategies` (issue #971 Phase 2) |
| `--rebalance-threshold` | float (0.001–0.5) | - | Threshold-based rebalance; fires when current_weight deviates ±X from target (OR-combined with `--rebalance-freq`, issue #971) |
| `--allow-non-buy-hold` | flag | false | Allow MR / trend-following strategies in `--combine-strategies` (each sub-strategy holds an independent position, issue #971 experimental) |
| `--combine-mode` | choice (`indicator`/`hybrid-strategy`) | `indicator` | Combine output mode; `hybrid-strategy` emits the main symbol via strategy() for Strategy Tester support (requires `--main-strategy`, issue #985) |
| `--main-strategy` | option | - | Main strategy ID emitted as strategy() under `--combine-mode hybrid-strategy` (issue #985) |
| `--with-training-data` | flag | false | Embed trained HMM parameters into Pine Script if HMM indicator exists (auto-fetches data; with `--combine-strategies`, fetches combine-internal HMM strategies in parallel for full Forward Algorithm reproduction, issue #974) |
| `--with-webhook` | flag | false | Attach alpha-strike webhook input + make_payload + alert() to the Pine output (issue #770) |
| `--webhook-broker` | choice (`moomoo`/`oanda`) | - | Order broker for `--with-webhook` (inferred from asset_type if omitted) |
| `--webhook-asset-class` | option | - | asset_class for `--with-webhook` (CRYPTO / FX / US_STOCK, etc.; inferred from asset_type if omitted) |
| `--webhook-ticker` | option | - | Broker-side ticker for `--with-webhook` (e.g. CC.BTC for moomoo crypto; inferred from target_symbols if omitted) |
| `--webhook-quantity` | float | `1.0` | Order quantity per signal for `--with-webhook` (adjustable via TradingView inputs) |
| `--webhook-run-mode` | choice (`paper`/`live`) | `paper` | run_mode for `--with-webhook` (record-only vs. live order on the alpha-strike side) |
| `--no-validate` | flag | false | Skip the Pine v6 signature-DB post-generate validator (emergency bypass, issue #786) |
| `--backtest-period` | option | - | Bake a period filter into the Pine output (format `YYYY-MM-DD:YYYY-MM-DD`, issue #823) |

Sample output (paid plan):

```text
✅ Pine Script saved: output/pinescript/spy_sma_v1.pine
```

Sample output (Trial plan — hard block):

```text
╭──────────── 🔒 Premium-only feature ─────────────╮
│ Pine Script export is available for paid plans   │
│ only (Lifetime / Annual / Monthly).              │
│ Upgrade your license to seamlessly run on …      │
│ Upgrade: https://alforgelabs.com/en/…            │
╰──────────────────────────────────────────────────╯
```

## alpha-forge pine preview `[Paid plans only]`

Preview generated Pine Script on stdout without writing to a file. **Paid plans only (Lifetime / Annual / Monthly).**

```bash
alpha-forge pine preview --strategy <ID>
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | required | - | Strategy name |
| `--with-webhook` | flag | false | Embed alpha-strike webhook input + make_payload + alert() (issue #770) |
| `--webhook-broker` | choice (`moomoo`/`oanda`) | - | Broker for `--with-webhook` (inferred from asset_type if omitted) |
| `--webhook-asset-class` | option | - | asset_class for `--with-webhook` |
| `--webhook-ticker` | option | - | Broker-side ticker for `--with-webhook` |
| `--webhook-quantity` | float | `1.0` | Order quantity for `--with-webhook` |
| `--webhook-run-mode` | choice (`paper`/`live`) | `paper` | run_mode for `--with-webhook` |
| `--no-validate` | flag | false | Skip the Pine v6 post-generate validator (emergency bypass, issue #786) |
| `--backtest-period` | option | - | Bake a period filter into the Pine output (`YYYY-MM-DD:YYYY-MM-DD`, issue #823) |

## alpha-forge pine import

Parse a Pine Script (`.pine`) and import it as a strategy definition.

```bash
alpha-forge pine import <PINE_FILE> --id <STRATEGY_ID>
```

| Name | Kind | Description |
|------|------|-------------|
| `PINE_FILE` | argument (required, file must exist) | Path to a `.pine` file |
| `--id` | required | Strategy ID to save as |

On parse failure: `Error: failed to parse Pine Script - <details>` (writes to stderr).

## alpha-forge pine verify `[Paid plans only]`

Verify the Pine Script generated from a strategy via a **TradingView MCP server** (issue #523). Beyond compile checks, it can compare the Strategy Tester aggregate metrics or the per-trade list against the matching alpha-forge backtest result. **Paid plans only (Lifetime / Annual / Monthly).** Because it generates Pine Script internally, running it on the Trial plan shows the same red Panel as generate / preview and exits with code `1` (the paywall fires before any `--check-mode` logic is reached).

```bash
alpha-forge pine verify --strategy <ID> [--check-mode <MODE>] [--mcp-server <CMD>] [--mcp-server-flavor <tradesdontlie|vinicius>] [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--strategy` | required | - | Strategy name |
| `--combine-strategies` | option | - | Verify a combine-portfolio Pine (symbolic / alert-log / Strategy Tester). Mutually exclusive with `--strategy` (issue #975). e.g. `tqqq_phase2,gld_bh,tlt_bh` |
| `--combine-allocation` | choice | `equal` | Allocation for `--combine-strategies` (`equal` / `custom`; `custom` requires `--combine-weights`) |
| `--combine-weights` | option | - | Weights for `--combine-allocation custom` (e.g. `tqqq=0.5,gld=0.5`) |
| `--combine-portfolio-id` | option | - | portfolio_id for `--combine-strategies` (auto-generated if omitted) |
| `--combine-rebalance-freq` | choice | `none` | Rebalance frequency for `--combine-strategies` (`none` / `weekly` / `monthly` / `quarterly` / `yearly`) |
| `--combine-rebalance-threshold` | float | - | Threshold-based rebalance for `--combine-strategies` (e.g. `0.05`) |
| `--verify-mode` | choice | `symbolic` | Combine verify mode. `symbolic`=symbolically compare `backtest combine` vs. Pine config (#975); `alert-log`=reconstruct positions from alpha-strike JSONL and compute metrics, requires `--receipts-source` (#980); `tradingview-strategy-tester`=run the hybrid-strategy Pine through Strategy Tester, requires `--combine-mode hybrid-strategy` + `--main-strategy` + `--symbol` + `--interval` (#986) |
| `--combine-mode` | choice | - | Pine output mode for combine (`indicator` / `hybrid-strategy`); use `hybrid-strategy` for `--verify-mode tradingview-strategy-tester` (#986) |
| `--main-strategy` | option | - | Main strategy ID emitted as `strategy()` during hybrid-strategy verify (#986) |
| `--receipts-source` | path | - | alpha-strike JSONL file or directory for `--verify-mode alert-log` |
| `--receipts-since` | option | - | Lower time bound (ISO format, e.g. `YYYY-MM-DD`) for `--verify-mode alert-log`; full history if omitted |
| `--check-mode` | choice | `compile_only` | `compile_only` / `metrics` / `signal` / `regime` |
| `--mcp-server` | option | - | MCP server command (defaults to `tv_mcp.pine_verify.endpoint` in `forge.yaml`) |
| `--mcp-server-flavor` | choice | `tradesdontlie` | `vinicius` is the `oviniciusramosp/tradingview-mcp` fork; recommended for metrics / signal modes |
| `--mock` | flag | false | Use the mock MCP client (PoC / CI) |
| `--symbol` / `--interval` | option | - | TV symbol / interval (required for metrics / signal modes) |
| `--auto-backtest` | flag | false | Run the alpha-forge backtest internally for comparison |
| `--backtest-result` | option | - | alpha-forge backtest result for comparison (JSON path or `run_id`) |
| `--metric-tolerance` | float | `0.10` | Relative tolerance for metrics mode (10%) |
| `--match-tolerance-seconds` | int | `60` | Trade-time tolerance for signal mode (seconds) |
| `--min-match-rate` | float | `0.95` | Minimum trade match rate for signal mode |
| `--output` | file | - | Markdown report destination |

**check-mode**

| Mode | Purpose |
|------|---------|
| `compile_only` | Validate Pine Script syntax / compilation only (`tradesdontlie` is fine) |
| `metrics` | Compare TV Strategy Tester aggregate metrics (PF, win rate, total trades, etc.) against alpha-forge metrics. **`vinicius` recommended** (avoids the `data_get_strategy_results` bug in `tradesdontlie`) |
| `signal` | tradesdontlie: match TV trade list to alpha-forge `trades` by entry time and compute a match rate.<br>vinicius: returns no timestamps, so the comparison auto-switches to **count-based** (totals only, issue #580) |
| `regime` | **Not implemented (parked, issue #581)**. Pending upstream MCP server support for a time-series study tool. Selecting it fails fast with an explicit error. |

**Examples**

```bash
# Compile-only verification (fastest)
alpha-forge pine verify --strategy spy_sma_v1 --mcp-server "node /opt/tv-mcp/server.js"

# Strategy Tester metrics comparison (vinicius recommended)
alpha-forge pine verify --strategy spy_sma_v1 \
  --check-mode metrics \
  --symbol SPY --interval D \
  --mcp-server-flavor vinicius \
  --auto-backtest \
  --output reports/verify_spy.md
```

For the verification workflow walkthrough, see [Bringing Pine Scripts into TradingView](../guides/tradingview-pine-integration.md).

---

# alpha-forge data

Fetch, update, and inspect historical market data. Pulls OHLCV from configured providers (yfinance / moomoo / OANDA / Dukascopy / TradingView MCP) and caches it locally as Parquet.

!!! info "About sample output"
    Sample outputs in this page are based on the formats read from the `alpha-forge` source. Actual numbers depend on the data and environment.

## Subcommands

| Command | Description |
|---------|-------------|
| [`alpha-forge data fetch`](#alpha-forge-data-fetch) | Fetch and save historical data |
| [`alpha-forge data list`](#alpha-forge-data-list) | List all stored historical datasets |
| [`alpha-forge data trend`](#alpha-forge-data-trend) | Evaluate market trend from stored data |
| [`alpha-forge data update`](#alpha-forge-data-update) | Incrementally update all stored historical data to the latest |

---

## alpha-forge data fetch

Fetch OHLCV for a symbol or watchlist and save it as Parquet under `config.data.storage_path`. By default, cache within `config.data.cache_ttl_hours` is reused; use `--force` to bypass.

### Synopsis

```bash
alpha-forge data fetch [SYMBOL] [OPTIONS]
alpha-forge data fetch --watchlist <FILE> [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | argument (optional) | - | Symbol. Mutually exclusive with `--watchlist` |
| `--period` | option | `1y` | Fetch period (e.g. `1y`, `5y`, `6m`, `30d`, `max`) |
| `--interval` | option | `1d` | Bar interval (e.g. `1d`, `1h`, `5m`) |
| `--watchlist` | option | - | Watchlist file (one symbol per line; lines starting with `#` are comments) |
| `--force` | flag | false | Force re-fetch regardless of TTL |
| `--provider` | choice | - | Explicit provider override (`yfinance` / `moomoo` / `tv_mcp`). Falls back to `data.providers` in `forge.yaml` when omitted |
| `--mcp-server` | option | - | MCP server command for `--provider tv_mcp` (e.g. `node /opt/tv-mcp/server.js`). When omitted, the value is resolved from the `FORGE_TV_MCP_ENDPOINT` environment variable, then `data.providers.tv_mcp.endpoint` in `forge.yaml` (issue #689). `~` / `$HOME` inside the command are expanded automatically |
| `--mcp-server-flavor` | choice | - | MCP server flavor for `--provider tv_mcp` (`tradesdontlie` / `vinicius`). CLI value takes precedence over `forge.yaml` |
| `--with-dividends` | flag | false | Also fetch and save dividend history alongside OHLCV (#958 Phase 2). Required for a true total-return evaluation of high-yield ETFs, and a prerequisite for `alpha-forge backtest run --dividend-reinvest` |

You must provide either `SYMBOL` or `--watchlist`. With `--provider tv_mcp`, the command fails fast if no `endpoint` can be resolved.

### Sample output (single symbol)

```text
Fetching data: SPY (period=5y, interval=1d)
Fetched and saved data for SPY (1258 lines)
```

When the cache is valid:

```text
Cache is valid: SPY (TTL: 24h) — skipped. Use --force to re-fetch.
```

### Sample output (watchlist)

```text
Fetching data for 3 symbols...
  [SPY] Fetching...
  [SPY] Done: 1258 rows
  [QQQ] Cache is valid (TTL: 24h) — skipped
  [AAPL] Fetching...
  [AAPL] Error: <details>
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Error: specify a symbol or --watchlist.` | Neither given | Pass `SYMBOL` or `--watchlist <FILE>` |
| `Error: watchlist file not found - <path>` | Bad path | Verify the path |
| `[<SYM>] Error: <details>` | Provider error (network, auth, invalid symbol, etc.) | Check provider settings or `forge.yaml` |

---

## alpha-forge data list

List all stored datasets.

### Synopsis

```bash
alpha-forge data list [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Emit the result as JSON on stdout (machine-readable; MCP / pipe use) (issue #1176) |

When `--json` is passed, pure JSON is written to stdout (decoration and progress go to stderr).

### Sample output

```text
Stored data count: 3
- SPY (1d): 2018-01-02 to 2025-12-31 (2014 rows)
- QQQ (1d): 2018-01-02 to 2025-12-31 (2014 rows)
- USDJPY=X (1d): 2020-01-01 to 2025-12-31 (1530 rows)
```

When no data is stored:

```text
Stored data count: 0
```

### Sample output (`--json`)

```json
{
  "count": 3,
  "datasets": [
    {"symbol": "SPY", "interval": "1d", "start": "2018-01-02", "end": "2025-12-31", "rows": 2014},
    {"symbol": "QQQ", "interval": "1d", "start": "2018-01-02", "end": "2025-12-31", "rows": 2014},
    {"symbol": "USDJPY=X", "interval": "1d", "start": "2020-01-01", "end": "2025-12-31", "rows": 1530}
  ]
}
```

**Exit code**: `0`=success, `1`=not found / failure, `2`=argument error.

---

## alpha-forge data trend

Generate market trend signals (bullish / bearish / neutral and similar) from stored data. When `--symbols` is not provided, `DEFAULT_TREND_SYMBOLS` (a major JP/US set) is used.

### Synopsis

```bash
alpha-forge data trend [OPTIONS]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--symbols` | option | major JP/US default set | Comma-separated symbols to evaluate |
| `--watchlist` | option | - | Watchlist file with one symbol per line |
| `--interval` | option | `1d` | Bar interval |
| `--as-of` | option | - | Evaluate using bars up to this date (`YYYY-MM-DD`) |
| `--json` | flag | false | Output as JSON |

When both `--symbols` and `--watchlist` are given, `--watchlist` takes precedence.

### Sample output (text)

Each line has the form `<symbol>: <label> - <summary>`. The label is emitted in Japanese (`上昇トレンド` = uptrend / `下降トレンド` = downtrend / `回復基調` = recovering / `失速気味` = weakening / `中立` = neutral) regardless of locale, and the summary carries the 20-day change.

```text
SPY: 上昇トレンド - SPY は 上昇トレンド です（20日騰落率 +5.23%）
QQQ: 上昇トレンド - QQQ は 上昇トレンド です（20日騰落率 +7.81%）
^N225: 中立 - ^N225 は 中立 です（20日騰落率 +0.42%）
USDJPY=X: 下降トレンド - USDJPY=X は 下降トレンド です（20日騰落率 -2.10%）
```

### Sample output (`--json`)

The JSON returns both `trend` (a lowercase English enum: `bullish` / `bearish` / `recovery` / `weakening` / `neutral`) and `label` (the Japanese display name), plus `close` / `pct_1d` / `pct_5d` / `pct_20d` / `sma20` / `sma50` / `sma200`.

```json
{
  "source": "alpha-forge:data:trend",
  "interval": "1d",
  "as_of": null,
  "signals": [
    {
      "symbol": "SPY",
      "as_of": "2025-12-31",
      "close": 512.34,
      "pct_1d": 0.31,
      "pct_5d": 1.42,
      "pct_20d": 5.23,
      "sma20": 498.10,
      "sma50": 480.55,
      "sma200": 455.02,
      "trend": "bullish",
      "label": "上昇トレンド",
      "summary": "SPY は 上昇トレンド です（20日騰落率 +5.23%）"
    }
  ]
}
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `Watchlist file not found - <path>` | Bad path | Verify the path |

---

## alpha-forge data update

For every dataset visible via `alpha-forge data list`, fetch the **incremental delta** from the last cached date up to today. Already up-to-date datasets are skipped.

### Synopsis

```bash
alpha-forge data update [--json]
```

### Arguments and options

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Emit the result as JSON on stdout (machine-readable; MCP / pipe use) (issue #1176) |

When `--json` is passed, pure JSON is written to stdout (decoration and progress go to stderr).

### Sample output

```text
Starting update for 3 datasets...
  [Update] Fetching SPY (1d) from 2025-12-15 to now...
    - Added/updated 12 rows.
  [Skip] QQQ (1d): already up to date (2025-12-31).
  [Update] Fetching USDJPY=X (1d) from 2025-12-20 to now...
    - No new data available.
Update complete: 1 datasets updated.
```

### Sample output (`--json`)

```json
{
  "total": 3,
  "updated": 1,
  "skipped": 1,
  "items": [
    {"symbol": "SPY", "interval": "1d", "status": "updated", "added_rows": 12},
    {"symbol": "QQQ", "interval": "1d", "status": "skipped"},
    {"symbol": "USDJPY=X", "interval": "1d", "status": "no_new_data"}
  ]
}
```

**Exit code**: `0`=success, `1`=not found / failure, `2`=argument error.

When no data is stored:

```text
No stored data found.
```

### Common errors

| Message | Cause | Fix |
|---------|-------|-----|
| `[Skip] <SYM> (<interval>): no valid last fetch date.` | Corrupted metadata or empty file | Re-fetch with `alpha-forge data fetch <SYM> --force` |
| `- Error: <details>` | Provider error | Address per the message |

---

## Provider matrix

`forge.yaml`'s `data.providers` setting routes symbols / intervals to specific providers (the `alpha-forge` bundled implementations).

| Provider | Main asset coverage | Auth | Period limit (rough) | Intervals (rough) |
|----------|-------------------|------|----------------------|-------------------|
| **yfinance** | Stocks / ETFs / FX / Futures | None | `max` (decades for `1d`); `1h` ≈ 2 years; `5m` ≈ 60 days | `1d`, `1h`, `30m`, `15m`, `5m`, `1m` |
| **moomoo** | Stocks / ETFs (US, HK, A-share) | Local OpenD connection required | Provider-specific | `1d`, `1h`, `5m`, etc. |
| **OANDA** | FX | API key required | Provider-specific | `1d`, `H1`, `M5`, etc. |
| **Dukascopy** | Long-history FX | None (CSV download) | Decades | `1d`, `1h`, `5m` |
| **tv_mcp** | Anything visible on TradingView (stocks, ETFs, FX, futures, crypto, etc.) | Requires TradingView Desktop launched with `--remote-debugging-port=9222` and a running MCP server | TradingView's own (decades on `1d`, 10+ years on `1h`) | TradingView interval names (`D`, `60`, `5`, etc.) — input is normalized internally |

!!! warning "Very long-range × intraday OANDA fetches can be truncated by the page cap (issue #1183)"
    OANDA fetches up to 5000 candles per request and pages internally, but the number of pages is capped. For combinations that need more pages than the cap — e.g. **very long-range × intraday** intervals (such as several years of `M5`) — the fetch may stop partway through the requested range. When that happens, alpha-forge emits a `OANDA: page cap (... pages × ... candles) reached, only fetched part of the requested range` WARNING. To reach further back, consider the `dukascopy` provider for long-history FX.

### TradingView MCP provider (`tv_mcp`, issue #576)

`--provider tv_mcp` pulls OHLCV through an MCP server attached to TradingView Desktop. This is mainly useful when you need history beyond yfinance's ~5y limit.

- **Prerequisites**: launch TradingView Desktop with `--remote-debugging-port=9222`, then start `tradesdontlie/tradingview-mcp` or `oviniciusramosp/tradingview-mcp` (the vinicius fork) in a separate process.
- **Range sliding**: a single MCP request returns at most 500 bars; alpha-forge transparently slides the visible range and concatenates chunks (cap: `data.providers.tv_mcp.max_chunks`). `--period max` works.
- **Flavor**: `data_get_ohlcv` works on both flavors. For OHLCV-only use, the default `tradesdontlie` is sufficient.

!!! warning "TV preload constraint for long-range fetches (issue #683)"
    Both MCP forks implement `data_get_ohlcv(count=N)` as **the last N bars currently loaded in TradingView's bars cache**. Calling `chart_set_visible_range` only zooms — it does **not** expand the cache. So `--period 20y` cannot reach further back than whatever TradingView has preloaded (usually the most recent 1–2 years).

    `_fetch_with_sliding_window` logs each chunk's `requested range / bar count / first & last bar time` at INFO level, and bails early once the latest bar timestamp has failed to advance for 3 consecutive chunks (no-progress streak). On bail, alpha-forge emits a `tv_mcp fetch truncated: TV chart preload covers only YYYY-MM-DD..YYYY-MM-DD (requested YYYY-MM-DD..YYYY-MM-DD)` WARNING.

    **For long-range history, use a different provider**:

    - Stocks / ETFs: `--provider yfinance` (up to ~30y by default)
    - FX deep history: set `data.providers.fx_provider: dukascopy` in `forge.yaml` (decades). The `--provider` CLI flag only accepts `yfinance` / `moomoo` / `tv_mcp`, so `dukascopy` must be selected via config, not the flag.
    - If you must use `tv_mcp` for deep history, manually scroll the TradingView Desktop chart back to your target years first so the bars cache grows; the MCP can then read whatever has been preloaded. A persistent fix requires a new MCP tool that triggers historical loading on the chart.
- **`forge.yaml` example**:

```yaml
data:
  providers:
    stock_provider: tv_mcp     # use tv_mcp for stocks / ETFs
    fx_provider: tv_mcp        # also for FX
    enable_fallback: true      # fall back to yfinance on tv_mcp failure
    tv_mcp:
      endpoint: ""             # leave empty to read FORGE_TV_MCP_ENDPOINT (issue #689).
                               # `~` / `$HOME` are expanded (e.g. "node ~/opt/tv-mcp/server.js")
      flavor: tradesdontlie    # tradesdontlie is fine for OHLCV
      max_bars_per_call: 500   # MCP-side cap
      max_chunks: 200          # safeguard for range sliding
      timeout_seconds: 120
```

!!! tip "endpoint resolution order (issue #689)"
    1. CLI `--mcp-server`
    2. Environment variable `FORGE_TV_MCP_ENDPOINT`
    3. `data.providers.tv_mcp.endpoint` in `forge.yaml`

    When sharing `forge.yaml` across machines / CI, commit `endpoint: ""` and set `FORGE_TV_MCP_ENDPOINT` per environment.

Examples:

```bash
# pass the endpoint via CLI
alpha-forge data fetch SPY --provider tv_mcp --mcp-server "node /opt/tv-mcp/server.js" --period max

# inject via environment variable (~ / $HOME are expanded)
FORGE_TV_MCP_ENDPOINT="node ~/opt/tv-mcp/server.js" \
  alpha-forge data fetch USDJPY --provider tv_mcp --period 20y --interval 1d

# rely on forge.yaml (no --mcp-server needed)
alpha-forge data fetch USDJPY --provider tv_mcp --period 20y --interval 1d
```

#### Subcommand: `alpha-forge data tv-mcp check` (issue #674)

Verifies that the TV MCP data provider server is reachable. The `/explore-strategies` skill runs this automatically at the start of each run for goals where `exploration.data_provider_override.{stock|fx}: tv_mcp` is configured.

```bash
# Default (ping with symbol=BATS:SPY)
alpha-forge data tv-mcp check

# JSON output (for automation)
alpha-forge data tv-mcp check --json

# Different symbol (FX)
alpha-forge data tv-mcp check --symbol OANDA:USDJPY

# Pass the endpoint via CLI
alpha-forge data tv-mcp check --mcp-server "node /opt/tv-mcp/server.js"
```

| Option | Default | Description |
|--------|---------|-------------|
| `--mcp-server <command>` | resolved from `FORGE_TV_MCP_ENDPOINT` env var, then `data.providers.tv_mcp.endpoint` in `forge.yaml` | MCP server command. `~` / `$HOME` are expanded automatically (issue #689) |
| `--symbol <symbol>` | `BATS:SPY` | Symbol used for the ping |
| `--json` | false | Output as JSON |

**Exit code**: `0` = session valid, `2` = endpoint missing / TV Desktop not running / MCP server connection failed. When `/explore-strategies` detects exit `2`, the loop is stopped and a "TV MCP auth error stop" line is appended to `<goal_dir>/explored_log.md` (no auto-launch / no retry).

### `auto` routing (issue #583, Phase 1.5e-δ)

Setting `stock_provider` / `fx_provider` to `auto` makes alpha-forge classify each symbol into an asset type and pick the provider through the new `auto_routing` table. Useful when a single `alpha-forge data fetch <SYM>` should choose different providers depending on the symbol.

```yaml
data:
  providers:
    stock_provider: auto
    fx_provider: auto
    auto_routing:
      stock: tv_mcp      # US / JP equities → TV MCP (long history)
      etf: tv_mcp
      fx: oanda          # FX → OANDA
      commodity: yfinance
      crypto: yfinance
      index: yfinance
    tv_mcp:
      endpoint: "node /opt/tv-mcp/server.js"
      flavor: tradesdontlie
    oanda:
      access_token: ${OANDA_ACCESS_TOKEN}
      account_id: ${OANDA_ACCOUNT_ID}
```

Asset-type classification is delegated to `alpha_forge.data.symbols.detect_asset_type`:

| Type | Example detection rule |
|------|------------------------|
| `fx` | `USDJPY=X` / `EUR/USD` / `USD_JPY` |
| `index` | `^GSPC`, `^VIX`, `^NDX` (leading `^`) |
| `commodity` | `GC=F`, `CL=F`, `SI=F` (trailing `=F`) |
| `crypto` | `BTC-USD`, `ETH-USDT`, `ADA-BTC` |
| `etf` | Matches the built-in known-ETF list (`SPY`, `QQQ`, etc.) |
| `stock` | Everything else |

If `auto_routing` has no entry for the resolved asset type, alpha-forge errors out explicitly (it does **not** silently fall back to `yfinance`).

### Symbol notation examples

| Asset type | Examples |
|------------|----------|
| US stocks / ETFs | `AAPL`, `SPY`, `QQQ`, `NVDA` |
| FX (yfinance) | `USDJPY=X`, `EURUSD=X` |
| FX (OANDA) | `USD_JPY`, `EUR_USD` |
| Futures (yfinance) | `CL=F` (oil), `GC=F` (gold), `SI=F` (silver) |
| TradingView MCP | TradingView's own notation (`AAPL`, `USDJPY`, `OANDA:EURUSD`, `COMEX:GC1!`, etc.) |

Provider-specific symbol notation is documented in `alpha-forge/src/alpha_forge/data/providers/<provider>.py`.

---

## alpha-forge data tv-mcp

Drive a TradingView MCP server for chart snapshots and ad-hoc tool calls (issue #523).

## alpha-forge data tv-mcp chart

Capture a TradingView chart snapshot as a PNG (Phase 1.5d).

```bash
alpha-forge data tv-mcp chart <SYMBOL> [--interval D] [--width W] [--height H] [--theme light|dark] [--output <PNG>] [--mcp-server <CMD>]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `SYMBOL` | argument (required) | - | TV symbol |
| `--interval` | option | `D` | Timeframe (`1`, `5`, `60`, `D`, `W`, `M`) |
| `--width` / `--height` | int | from `forge.yaml` (`tv_mcp.chart_snapshot`) | Image dimensions |
| `--theme` | choice | from `forge.yaml` | `light` / `dark` |
| `--output` | file | - | PNG output path. When omitted, only the cache path is printed |
| `--mcp-server` | option | - | MCP server (defaults to `tv_mcp.chart_snapshot.endpoint`) |
| `--mock` | flag | false | Mock MCP (CI) |
| `--no-cache` | flag | false | Bypass cache |
| `--md-output` | file | - | Append a Markdown image link (requires `--output`) |
| `--md-alt` | option | - | Markdown image alt text (default: `SYMBOL Interval`) |

Example:

```bash
alpha-forge data tv-mcp chart SPY --interval D --output charts/spy_d.png \
  --mcp-server "python /opt/tv-mcp-chart/server.py"
```

## alpha-forge data tv-mcp inspect

Invoke any MCP tool and print the JSON response (Phase 1.5c-α). Handy for poking at a new MCP server or discovering the available tools.

```bash
alpha-forge data tv-mcp inspect <TOOL_NAME> [--server-type pine|chart] [--mcp-server <CMD>] [--arg key=value ...] [--args-json '{...}'] [--output <JSON>] [--pretty|--compact]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `TOOL_NAME` | argument (required) | - | MCP tool name |
| `--server-type` | choice | `pine` | Endpoint default selector (`pine` = `tv_mcp.pine_verify`, `chart` = `tv_mcp.chart_snapshot`) |
| `--mcp-server` | option | - | Server command override |
| `--mock` | flag | false | Static mock response (CI) |
| `--arg` | repeatable | - | Tool arg `key=value` (value is JSON-parsed when possible) |
| `--args-json` | option | - | Tool args as a JSON object (mutually exclusive with `--arg`) |
| `--output` | file | - | JSON output destination |
| `--pretty` / `--compact` | flag | `--pretty` | Indented vs single-line JSON |

Examples:

```bash
# Tool listing (depends on the server implementation)
alpha-forge data tv-mcp inspect list_tools --server-type pine \
  --mcp-server "node /opt/tv-mcp/server.js"

# Try data_get_ohlcv
alpha-forge data tv-mcp inspect data_get_ohlcv \
  --arg symbol=SPY --arg interval=D --arg bars=10
```

## alpha-forge data tv-mcp cache-clean

Tidy up the PNG cache that `alpha-forge data tv-mcp chart` accumulates with daily keys under `config.tv_mcp.chart_snapshot.cache_path` (default `data/cache/charts/`), deleting entries by age (mtime).

```bash
alpha-forge data tv-mcp cache-clean [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `--older-than` | option | - | Delete PNGs older than the given number of days (mtime, `30d` / `30` format) |
| `--dry-run` | flag | false | List the files that would be deleted and exit without deleting |
| `--yes` / `-y` | flag | false | Skip the confirmation prompt and delete |
| `--json` | flag | false | Emit the result as JSON (`{removed: [...], failed: [...], count, dry_run}`) |

- Omitting `--older-than` stops with exit code `2` to **prevent accidental wholesale deletion**. When no cache exists yet, it exits cleanly with 0 entries.
- Because this is destructive, it stops with exit code `2` in non-interactive environments (`FORGE_NONINTERACTIVE` / `CI` / non-TTY) unless `--yes` is given. `--yes` is also required when running with `--json`.

---

## alpha-forge data alt

Fetch and manage alternative data (sentiment, macro indicators, etc.). Stored under `config.data.alt_storage_path` and referenceable from strategy JSON via the `ALTDATA` indicator type.

## alpha-forge data alt fetch

```bash
alpha-forge data alt fetch <SOURCE_KEY> --start <YYYY-MM-DD> --end <YYYY-MM-DD>
```

| Name | Kind | Description |
|------|------|-------------|
| `SOURCE_KEY` | argument (required) | Provider-specific data source key |
| `--start` | required | Fetch start date |
| `--end` | required | Fetch end date |

Output: `✅ <SOURCE_KEY>: saved <N> rows`. Unregistered providers raise `ClickException`.

## alpha-forge data alt import-swap

```bash
alpha-forge data alt import-swap <PAIR> --csv <path>
```

Validates a broker-published real swap-point history CSV and stores it under the `SWAP:<PAIR>` key. Once saved, [`backtest run --carry`](backtest.md#carry) uses it **automatically in preference** to the rate-differential approximation.

| Name | Kind | Description |
|------|------|-------------|
| `PAIR` | argument (required) | FX pair (`USDJPY=X` / `USD/JPY` / `USD_JPY`; normalized to the yfinance form) |
| `--csv` | required | CSV path. Header `date,long,short` |
| `--merge` | flag | Merge with previously stored SWAP data by date (new rows win on duplicates). Overwrites entirely when omitted |

CSV contract:

- Values are the amount received/paid **per unit per day in the quote currency** (positive = received). If published as "X yen per 10,000 units", divide by 10,000
- **Per-day normalization is mandatory**: broker listings bundle the number of grant days into the value (e.g. triple grants on Wednesdays). Importing raw listings double-counts against the calendar-day accrual — always divide by the number of grant days first (the import detects values exceeding 2.5x the column median and warns about possible bundled grant days)
- Dates must be ascending, unique, and not in the future. Empty (missing) cells are rejected
- Long and short are separate columns, both **net of broker margin** (`spread_pct` does not apply)
- The accrual is a calendar-day approximation, so **starting or ending the backtest period mid-week drifts a few days** from the actual grant accumulation (relatively significant for short windows; cutting on week boundaries is safest)

Validation always applies to the CSV alone before merging, even with `--merge`; any violation aborts without touching the stored data (exit code `1`). Broker-published CSVs often cover only the last few dozen days, so use `--merge` for periodic (e.g. weekly) imports where you want to retain accumulated history:

```bash
alpha-forge data alt import-swap USDJPY=X --csv swap_usdjpy_latest.csv --merge
```

Any validation failure aborts without saving (exit code `1`). Output: `✅ SWAP:<PAIR>: saved <N> rows (<path>)` (appends "(merged with existing)" when `--merge` is given).

## alpha-forge data alt list

```bash
alpha-forge data alt list
alpha-forge data alt list --json   # machine-readable (for MCP / pipe use, issue #1225)
```

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `--json` | flag | false | Output JSON (machine-readable, for MCP / pipe use, issue #1225; decorations and progress go to stderr) |

Sample output:

```text
Stored alternative data count: 2
SOURCE_KEY                INTERVAL   ROWS         START           END
fear_greed_index          1d          1525   2020-01-01   2025-12-31
vix_termstructure         1d          1530   2020-01-01   2025-12-31
```

When no alternative data has been stored, the command prints a single line and exits with code `0`:

```text
No stored alternative data found.
```

With `--json`, only pure JSON is written to stdout. **Exit code**: `0` = success, `1` = not found / execution failure, `2` = argument error.

## alpha-forge data alt info

```bash
alpha-forge data alt info <SOURCE_KEY>
alpha-forge data alt info <SOURCE_KEY> --json   # machine-readable (for MCP / pipe use, issue #1225)
```

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `SOURCE_KEY` | argument (required) | - | Data source key to inspect |
| `--json` | flag | false | Output JSON (machine-readable, for MCP / pipe use, issue #1225) |

Shows source key, interval, row count, start / end dates, columns, file path, and file size. If data is missing, raises `ClickException`. With `--json`, only pure JSON is written to stdout (part of the `--json` coverage for read-only commands, issue #1225).

---

## Common behavior

- **Storage format**: Parquet (`config.data.storage_path / <SYMBOL>_<interval>.parquet`)
- **TTL cache**: `fetch` skips when within `config.data.cache_ttl_hours`. Use `--force` to bypass
- **Provider resolution**: `get_data_fetcher(symbol=..., config=config)` selects a provider per the `data.providers` setting in `forge.yaml`
- **`FORGE_CONFIG`**: Storage path and provider settings are determined by the `forge.yaml` referenced by the `FORGE_CONFIG` environment variable
- **Exit codes**: `0` on success; `click.ClickException` returns `1`; argument errors return Click's `2`
- **Trial plan limit**: On the Trial plan, the fetch `end` is also capped at `2023-12-31`, and `alpha-forge data update` skips items whose stored end is on or after 2023-12-31. See [Trial Limits](../guides/trial-limits.md) for details.

---

<!-- Synced from: Click decorators in `alpha-forge/src/alpha_forge/commands/data.py`, the provider implementations under `alpha-forge/src/alpha_forge/data/providers/`, and provider notes in `alpha-forge/CLAUDE.md`. This page must be kept in sync when CLI arguments or providers change. -->

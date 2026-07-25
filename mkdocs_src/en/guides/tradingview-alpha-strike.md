# TradingView × alpha-strike Integration (payload spec)

alpha-strike receives TradingView webhook alerts and forwards orders to moomoo / OANDA. This page focuses on **payload JSON specification** and **TradingView-side alert configuration**.

> For infrastructure setup (VM / Cloudflare Tunnel / WAF / OpenD / systemd), see the dedicated [alpha-strike Setup Guide (Paper Trading Production)](./alpha-strike-setup.md).

---

## 1. Webhook endpoint

| Item | Production value |
|---|---|
| URL | `https://strike.yourdomain.com/webhook` (Cloudflare Tunnel, replace with your domain) |
| HTTPS | **Required** — TradingView only accepts HTTPS. Cloudflare Tunnel provides the certificate. |
| Auth | `passphrase` field in the request body must match `WEBHOOK_PASSPHRASE` in `.env` |
| Rate limit | `10 req/min/IP` (`slowapi`) |
| Recommended defense | Cloudflare WAF Custom Rule allowing only TradingView's 4 official IPs (see [Setup Guide §4](./alpha-strike-setup.md#4-cloudflare-waf-custom-rule-tradingview-ip-allowlist)) |

---

## 2. Creating the TradingView alert

1. Open the target chart and click the bell icon → **Create Alert**
2. **Condition**: pick your strategy / indicator firing condition
3. **Notifications** tab:
   - ✅ **Webhook URL** with `https://strike.yourdomain.com/webhook`
4. **Message** field: paste the JSON below
5. **Create**

!!! warning "TradingView plan requirement"
    Webhook URL is available on **Essential plan or above** (up to 20 alerts). Free / Basic does not support webhooks.

---

## 3. Payload JSON

### 3-1. moomoo SIMULATE / REAL

```json
{
  "passphrase": "<WEBHOOK_PASSPHRASE>",
  "broker": "moomoo",
  "asset_class": "US",
  "action": "buy",
  "ticker": "US.AAPL",
  "quantity": 10,
  "run_mode": "paper",
  "strategy_id": "demo_buy_v1",
  "alert_name": "{{strategy.order.alert_message}}"
}
```

### 3-1b. moomoo CRYPTO (BTC / ETH / XRP)

```json
{
  "passphrase": "<WEBHOOK_PASSPHRASE>",
  "broker": "moomoo",
  "asset_class": "CRYPTO",
  "action": "buy",
  "ticker": "CC.BTC",
  "quantity": 0.01,
  "run_mode": "paper",
  "strategy_id": "btc_ema_sma_trail40_v1"
}
```

> **Notes on moomoo crypto**:
> - 24/7 trading with unlimited T+0
> - US-residency restriction applies (FinCEN MSB). The broker-side crypto account must be enabled
> - Internally uses `OpenSecTradeContext(filter_trdmarket=TrdMarket.CRYPTO, security_firm=SecurityFirm.NONE)`
> - Symbols are `CC.BTC` / `CC.ETH` / `CC.XRP` etc. (uppercase symbol with `CC.` prefix)

!!! warning "moomoo crypto is live (REAL) only — SIMULATE is rejected"
    moomoo's crypto trading API is live-environment only. Sending a crypto order
    with `MOOMOO_TRD_ENV=SIMULATE` makes the moomoo SDK return
    `the type of environment param is wrong`.

    alpha-strike detects this combination **before connecting to OpenD** and
    raises a `ValueError` with this message:

    ```
    moomoo crypto は SIMULATE 環境を受け付けません（live only）。
    paper 運用したい場合は BTC ETF (US.IBIT / US.FBTC / US.BITO 等) を
    asset_class=US で発注するか、MOOMOO_TRD_ENV=REAL で実 money 運用してください。
    ```

    For paper validation, choose one of:

    - **Order a BTC ETF (`US.IBIT` / `US.FBTC` / `US.BITO`) with `asset_class=US`** (recommended)
    - Start with a small REAL position (`MOOMOO_TRD_ENV=REAL`, e.g. 0.001 BTC ≈ $80)
    - Use TradingView's built-in Paper Trading (bypass alpha-strike)

### 3-2. OANDA PRACTICE / LIVE

```json
{
  "passphrase": "<WEBHOOK_PASSPHRASE>",
  "broker": "oanda",
  "asset_class": "FX",
  "action": "buy",
  "ticker": "USDJPY",
  "quantity": 1000,
  "run_mode": "paper",
  "strategy_id": "fx_demo_v1"
}
```

### 3-3. Field reference

| Field | Required | Description | Example |
|---|---|---|---|
| `passphrase` | ✅ | Must exactly match `.env` `WEBHOOK_PASSPHRASE` | `"32-char random"` |
| `broker` | ✅ | Target broker | `"moomoo"` / `"oanda"` |
| `asset_class` | ✅ | Asset class | `"FX"` / `"COMMODITY"` / `"US"` / `"HK"` / `"INDEX"` / `"CRYPTO"` |
| `action` | ✅ | Order direction (lowercase) | `"buy"` / `"sell"` |
| `ticker` | ✅ | Symbol (pattern `^[A-Z0-9_.]{1,20}$`) | moomoo: `"US.AAPL"` / OANDA: `"USDJPY"` |
| `quantity` | ✅ | Positive number | `10` / `1000` |
| `run_mode` | — | `"paper"` / `"live"` (default `"live"`) | `"paper"` |
| `strategy_id` | — | alpha-forge strategy_id | `"cl_hmm_bb_rsi_v1"` |
| `strategy_version` | — | Strategy version | `"1.2.0"` |
| `snapshot_id` | — | alpha-forge journal snapshot_id | `"snap_20260517170105122499"` |
| `signal_id` | — | Unique signal ID (auto-generated if unset) | `"sig_xxx"` |
| `timeframe` | — | Bar interval | `"1m"` / `"5m"` / `"1h"` |
| `alert_timestamp` | — | Signal time (ISO 8601) | `"2026-05-17T08:45:10Z"` |
| `alert_name` | — | TradingView alert name | `"BTC breakout"` |
| `order_comment` | — | Free-form memo | `"manual override"` |

### 3-4. Ticker formats

#### moomoo

Use `MARKET.CODE`:

| Market | Format | Example |
|---|---|---|
| US stocks | `US.<TICKER>` | `US.AAPL` |
| HK stocks | `HK.<CODE>` | `HK.00700` |
| China A-shares | `SH.<CODE>` / `SZ.<CODE>` | `SH.600000` |
| Crypto | `CC.<SYMBOL>` | `CC.BTC` / `CC.ETH` / `CC.XRP` |

TradingView's `{{ticker}}` placeholder gives the symbol without market prefix, so Pine code should add it: `"US." + syminfo.ticker`.

#### OANDA

Automatic conversion based on `asset_class`:

| asset_class | TradingView | OANDA instrument |
|---|---|---|
| `FX` / `COMMODITY` | `USDJPY` | `USD_JPY` |
| `US` / `INDEX` | `AAPL` | `AAPL_USD` |

Use `asset_class:"RAW"` to pass an instrument through unchanged.

### 3-5. Dynamic fields (TradingView placeholders)

| Placeholder | Meaning |
|---|---|
| `{{ticker}}` | Symbol (e.g., `AAPL`) |
| `{{strategy.order.action}}` | `buy` / `sell` |
| `{{strategy.order.contracts}}` | Order quantity |
| `{{strategy.position_size}}` | Current position size |
| `{{strategy.order.alert_message}}` | String passed to Pine `alert()` |
| `{{time}}` | UTC ISO timestamp of fire |

!!! tip "Build the full JSON in Pine"
    For numeric fields like `quantity`, the placeholder output can break the JSON structure and cause 422 errors. Construct the full JSON in your Pine script and pass it to `alert()` directly (next section).

---

## 4. Building full JSON in Pine v6

!!! tip "No hand-editing: `alpha-forge pine generate --with-webhook`"
    The snippet below is a hand-written reference, but `alpha-forge pine generate --strategy <id> --with-webhook` emits Pine with this `passphrase` input, `make_payload()`, and `alert()` blocks already wired in (see the [Pine integration guide](tradingview-pine-integration.md)).

```pinescript
//@version=6
strategy("alpha-strike webhook demo", overlay=true)

passphrase   = "<WEBHOOK_PASSPHRASE>"
broker       = "moomoo"
asset_class  = "US"
strategy_id  = "demo_buy_v1"
run_mode     = "paper"

rsi_val = ta.rsi(close, 14)
long_signal  = ta.crossover(rsi_val,  30)
short_signal = ta.crossunder(rsi_val, 70)

// Apply the moomoo market prefix when asset_class is US / HK / CRYPTO
//   US     → "US.AAPL"
//   HK     → "HK.00700"
//   CRYPTO → "CC.BTC"
get_market_prefix(string ac) =>
    ac == "US"     ? "US." :
    ac == "HK"     ? "HK." :
    ac == "CRYPTO" ? "CC." :
                     ""

make_payload(string action, float qty) =>
    ticker_full = get_market_prefix(asset_class) + syminfo.ticker
    '{"passphrase":"' + passphrase + '",' +
    '"broker":"' + broker + '",' +
    '"asset_class":"' + asset_class + '",' +
    '"action":"' + action + '",' +
    '"ticker":"' + ticker_full + '",' +
    '"quantity":' + str.tostring(qty) + ',' +
    '"strategy_id":"' + strategy_id + '",' +
    '"run_mode":"' + run_mode + '"}'

if long_signal
    strategy.entry("LONG", strategy.long, qty = 10)
    alert(make_payload("buy", 10), alert.freq_once_per_bar_close)

if short_signal
    strategy.close("LONG")
    alert(make_payload("sell", 10), alert.freq_once_per_bar_close)
```

Firing `alert()` from inside the strategy lets you leave the TradingView Message field empty and ship the JSON straight from Pine. `alert.freq_once_per_bar_close` fires only on bar close, avoiding repaint / duplicate orders.

---

## 4-bis. Idempotency (automatic duplicate rejection)

TradingView webhooks can arrive **multiple times for the same signal** due to network retries, alert re-evaluation, or manual Restart spamming. alpha-strike v0.5.0+ uses **the composite key `(signal_id, broker, ticker, action)` as an idempotency key**: if the same combination arrives again within the TTL window, the request is **not routed to the broker** and a 200 is returned (we deliberately avoid 409 to stop TradingView's auto-retry).

!!! info "Why a composite key (v1.0.4+)"
    `signal_id` is typically issued per bar, so **a strategy that rebalances several symbols on the same bar sends multiple alerts sharing one `signal_id`**. Keying on `signal_id` alone drops every alert after the first one — TradingView still shows "successfully delivered" while the rebalance silently goes missing. Including the symbol and side makes each alert a distinct signal.

### Behavior

| Condition | Response |
|---|---|
| `signal_id` set, first arrival | Normal order flow |
| `signal_id` set, repeated within TTL with **the same broker/ticker/action** | Broker call skipped, 200 `{"status":"success", "message":"duplicate signal_id — already processed"}` |
| `signal_id` set, arriving within TTL with **a different ticker or action** | Treated as a distinct signal; normal order flow |
| `signal_id` set, repeated after TTL | Normal order flow (history was evicted) |
| `signal_id` omitted | Idempotency check skipped (legacy compatibility, broker is called every time) |

### Environment variable

| Variable | Default | Description |
|---|---|---|
| `IDEMPOTENCY_TTL_SECONDS` | `600` | Retention window in seconds. Covers TradingView's maximum auto-retry interval. In-memory only; cleared on process restart. |

### Recommended Pine v6 pattern

Combine `bar_open_time + strategy_id + timeframe` so that **multiple fires within the same bar are always rejected by idempotency**:

```pinescript
//@version=6
strategy("idempotent demo", overlay=true)

strategy_id = "demo_buy_v1"
passphrase  = "<WEBHOOK_PASSPHRASE>"

make_signal_id() =>
    // <strategy_id>_<timeframe>_<bar_open_time>
    strategy_id + "_" + timeframe.period + "_" + str.format_time(time, "yyyy-MM-dd_HH-mm")

make_payload(string action, float qty) =>
    sig = make_signal_id()
    '{"passphrase":"' + passphrase + '",' +
    '"broker":"moomoo",' +
    '"asset_class":"US",' +
    '"action":"' + action + '",' +
    '"ticker":"US." + syminfo.ticker + '",' +
    '"quantity":' + str.tostring(qty) + ',' +
    '"signal_id":"' + sig + '",' +
    '"strategy_id":"' + strategy_id + '",' +
    '"run_mode":"paper"}'
```

> **Effect**: with `signal_id` formatted as `<strategy_id>_<timeframe>_<bar_open_time>`, even if `alert.freq_once_per_bar_close` somehow fires multiple times within the same bar, alpha-strike will treat the duplicates as 200 + duplicate and block any double broker orders.
>
> **Rebalancing several symbols at once**: this format does not include the symbol, so alerts for different symbols on the same bar share one `signal_id`. alpha-strike keys on `ticker` / `action` as well, so **every symbol is routed correctly as-is**. Adding the symbol to `signal_id` is fine but not required.
>
> **Backward compatibility**: existing payloads without `signal_id` keep working unchanged. Strongly recommended to add `signal_id` to reduce duplicate-order risk.

---

## 5. Response

### 5-1. Success (200)

```json
{
  "status": "success",
  "broker": "moomoo",
  "ticker": "US.AAPL",
  "message": "{'order_id': '356604', 'ret_code': 0, 'filled_qty': 0.0, 'filled_price': 0.0}",
  "signal_id": "sig_20260517170105122499",
  "order_id": "ord_20260517170105123793",
  "broker_order_id": "356604",
  "event_id": "evt_20260517170105232506"
}
```

### 5-2. Auth failure (401)

```json
{ "detail": "Unauthorized" }
```

---

## 6. Error reference

| HTTP | Cause | Fix |
|---|---|---|
| 401 Unauthorized | `passphrase` mismatch | Re-check `.env` `WEBHOOK_PASSPHRASE` vs the TradingView Message field |
| 422 Unprocessable Entity | JSON / field validation failed | `broker` `action` `run_mode` lowercase, `ticker` matches `^[A-Z0-9_.]{1,20}$`, `quantity` positive |
| 429 Too Many Requests | rate limit (10/min/IP) | Reduce alert frequency |
| **503 Service Unavailable** | **Kill switch (maintenance mode) is ON** | `/etc/alpha-strike/MAINTENANCE` exists, or `MAINTENANCE_MODE=1` is set. Run `sudo rm /etc/alpha-strike/MAINTENANCE` to deactivate (see [setup guide §10-3](./alpha-strike-setup.md#10-3-incident-response)). |
| 500 Internal Server Error | broker credentials missing | `journalctl -u alpha-strike` for details |
| 502 Bad Gateway | broker API failure | `moomoo`: OpenD status / `oanda`: API key validity |
| 403 Forbidden (Cloudflare) | Blocked by WAF | Check the source IP is one of TradingView's 4 official IPs |

---

## 7. Local development testing

Before VM deployment, you can run alpha-strike locally:

```bash
# In the alpha-strike repo
uv run uvicorn webhook_server:app --host 0.0.0.0 --port 8080 --reload

# In another terminal
curl http://localhost:8080/health
# → {"status":"ok"}

curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"test","broker":"moomoo","asset_class":"US","action":"buy","ticker":"US.AAPL","quantity":1,"run_mode":"paper"}'
```

To expose the local server to TradingView, use Cloudflare Tunnel (`cloudflared tunnel --url http://localhost:8080`) or `ngrok`.

---

## Related documents

- [alpha-strike Setup Guide (Paper Trading Production)](./alpha-strike-setup.md) — VM / Cloudflare / WAF / OpenD / systemd full procedure
- [Bringing Pine Scripts into TradingView](./tradingview-pine-integration.md) — applying alpha-forge Pine output in TradingView
- [End-to-end Strategy Development Workflow](./end-to-end-workflow.md) — the full development loop

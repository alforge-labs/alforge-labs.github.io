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
| `asset_class` | ✅ | Asset class | `"FX"` / `"COMMODITY"` / `"US"` / `"HK"` / `"INDEX"` |
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

make_payload(string action, int qty) =>
    ticker_full = (asset_class == "US" or asset_class == "HK")
                   ? asset_class + "." + syminfo.ticker
                   : syminfo.ticker
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

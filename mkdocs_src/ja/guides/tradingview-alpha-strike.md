# TradingView と alpha-strike の連携（ペイロード仕様）

alpha-strike は TradingView のアラートを Webhook で受け取り、moomoo / OANDA に自動発注します。本ページは **Webhook ペイロードの JSON 仕様** と **TradingView 側のアラート設定** に焦点を当てた仕様書です。

> **インフラ構築（VM / Cloudflare Tunnel / WAF / OpenD / systemd 等）の手順**は、別ページの [alpha-strike セットアップガイド（ペーパートレード本格運用）](./alpha-strike-setup.md) を参照してください。

---

## 1. Webhook エンドポイント

| 項目 | 本番運用構成 |
|---|---|
| URL | `https://strike.yourdomain.com/webhook`（Cloudflare Tunnel 経由・自分のドメインに置換） |
| HTTPS | **必須** — TradingView は HTTPS のみ受理。Cloudflare Tunnel が自動で証明書を提供 |
| 認証 | リクエストボディ内 `passphrase` フィールドが `.env` の `WEBHOOK_PASSPHRASE` と一致すること |
| Rate limit | `10 req/min/IP`（`slowapi` で実装） |
| 推奨防御層 | Cloudflare WAF Custom Rule で TradingView 公式 IP 4 件のみ通過させる（[セットアップガイド §4](./alpha-strike-setup.md#4-cloudflare-waf-custom-ruletradingview-ip-allowlist)） |

---

## 2. TradingView アラート作成手順

1. 対象チャートでベルアイコン → **Create Alert**
2. **Condition**: ストラテジー / インジケータ等の発火条件を選択
3. **Notifications** タブ：
   - ✅ **Webhook URL** にチェック → URL に `https://strike.yourdomain.com/webhook` を入力
4. **Message** 欄に下記の JSON を貼付（後述）
5. **Create** で保存

!!! warning "TradingView プラン要件"
    Webhook URL は **Essential プラン以上**（アラート数 20 件まで）で利用可能。Free / Basic では使えません。

---

## 3. ペイロード JSON 仕様

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

### 3-3. フィールド一覧

| フィールド | 必須 | 説明 | 例 |
|---|---|---|---|
| `passphrase` | ✅ | `.env` の `WEBHOOK_PASSPHRASE` と完全一致 | `"32文字のランダム文字列"` |
| `broker` | ✅ | 発注先 | `"moomoo"` / `"oanda"` |
| `asset_class` | ✅ | アセットクラス | `"FX"` / `"COMMODITY"` / `"US"` / `"HK"` / `"INDEX"` |
| `action` | ✅ | 注文方向 | `"buy"` / `"sell"`（小文字） |
| `ticker` | ✅ | 銘柄コード（パターン `^[A-Z0-9_.]{1,20}$`） | moomoo: `"US.AAPL"` / OANDA: `"USDJPY"` |
| `quantity` | ✅ | 注文数量（正数） | `10` / `1000` |
| `run_mode` | — | `"paper"` / `"live"`（既定 `"live"`） | `"paper"` |
| `strategy_id` | — | alpha-forge 側の strategy_id | `"cl_hmm_bb_rsi_v1"` |
| `strategy_version` | — | 戦略バージョン | `"1.2.0"` |
| `snapshot_id` | — | alpha-forge journal snapshot_id | `"snap_20260517170105122499"` |
| `signal_id` | — | シグナル一意 ID（未指定なら採番） | `"sig_xxx"` |
| `timeframe` | — | 時間軸 | `"1m"` / `"5m"` / `"1h"` |
| `alert_timestamp` | — | シグナル発火時刻（ISO 8601） | `"2026-05-17T08:45:10Z"` |
| `alert_name` | — | TradingView アラート名 | `"BTC breakout"` |
| `order_comment` | — | 任意メモ | `"manual override"` |

### 3-4. ティッカーフォーマット

#### moomoo

`市場.コード` 形式で指定：

| 市場 | 形式 | 例 |
|---|---|---|
| 米国株 | `US.<TICKER>` | `US.AAPL` |
| 香港株 | `HK.<CODE>` | `HK.00700` |
| 中国 A 株 | `SH.<CODE>` / `SZ.<CODE>` | `SH.600000` |

TradingView の `{{ticker}}` は市場プレフィックスなしの形式なので、Pine 側で `"US." + syminfo.ticker` のように加工するのが確実です（[セットアップガイド §7](./alpha-strike-setup.md#7-tradingview-アラート設定) 参照）。

#### OANDA

`asset_class` に応じて自動変換：

| asset_class | TradingView 例 | OANDA instrument |
|---|---|---|
| `FX` / `COMMODITY` | `USDJPY` | `USD_JPY` |
| `US` / `INDEX` | `AAPL` | `AAPL_USD` |

OANDA instrument を直接指定したい場合は `asset_class` に `"RAW"` 等の値を入れるとパススルーされます。

### 3-5. 動的フィールド（TradingView プレースホルダ）

| プレースホルダ | 内容 | 用途 |
|---|---|---|
| `{{ticker}}` | 銘柄（例: `AAPL`） | `ticker` フィールドに展開 |
| `{{strategy.order.action}}` | `buy` / `sell` | `action` フィールドに展開 |
| `{{strategy.order.contracts}}` | 注文数量 | `quantity` フィールドに展開 |
| `{{strategy.position_size}}` | ポジションサイズ | 補助情報 |
| `{{strategy.order.alert_message}}` | Pine 側で `alert()` に渡した文字列 | `alert_name` 等に展開 |
| `{{time}}` | アラート発火時刻（UTC ISO） | `alert_timestamp` に展開 |

!!! tip "Pine 側で完全な JSON を組み立てる"
    `quantity` のような数値フィールドにプレースホルダを使うと TradingView 側の出力次第で 422 エラーになることがあります。確実に動的化したい場合は Pine スクリプト内で `alert()` の引数に完全な JSON 文字列を渡してください（次節）。

---

## 4. Pine v6 から完全な JSON を生成する

```pinescript
//@version=6
strategy("alpha-strike webhook demo", overlay=true)

// === 設定値 ===
passphrase   = "<WEBHOOK_PASSPHRASE>"
broker       = "moomoo"
asset_class  = "US"
strategy_id  = "demo_buy_v1"
run_mode     = "paper"

// === シグナル例: RSI クロス ===
rsi_val = ta.rsi(close, 14)
long_signal  = ta.crossover(rsi_val,  30)
short_signal = ta.crossunder(rsi_val, 70)

// === JSON 生成ヘルパー ===
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

// === 発注 + アラート ===
if long_signal
    strategy.entry("LONG", strategy.long, qty = 10)
    alert(make_payload("buy", 10), alert.freq_once_per_bar_close)

if short_signal
    strategy.close("LONG")
    alert(make_payload("sell", 10), alert.freq_once_per_bar_close)
```

`alert()` をストラテジー本体で発火させると、**TradingView アラートの Message 欄を空にしたまま** Pine で組み立てた JSON がそのまま Webhook に送られます。`alert.freq_once_per_bar_close` で足確定時のみ発火し、リペイント・重複発注を抑制できます。

---

## 5. レスポンス例

### 5-1. 成功（200 OK）

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

### 5-2. 認証失敗（401）

```json
{ "detail": "Unauthorized" }
```

---

## 6. エラー一覧

| HTTP | 原因 | 対処 |
|---|---|---|
| 401 Unauthorized | `passphrase` 不一致 | `.env` の `WEBHOOK_PASSPHRASE` と TradingView Message 欄を再確認 |
| 422 Unprocessable Entity | JSON パース失敗 / フィールド検証失敗 | `broker` `action` `run_mode` は小文字、`ticker` は `^[A-Z0-9_.]{1,20}$`、`quantity` は正数 |
| 429 Too Many Requests | rate limit (10/min/IP) 超過 | アラート頻度を抑える |
| 500 Internal Server Error | broker 認証情報未設定 | `journalctl -u alpha-strike` でエラー詳細を確認 |
| 502 Bad Gateway | broker API 呼び出し失敗 | `moomoo`: OpenD 起動状態 / `oanda`: API key の有効性 |
| 403 Forbidden（Cloudflare） | WAF Custom Rule で遮断 | 送信元 IP が TradingView 公式 4 件のいずれかか確認 |

---

## 7. ローカル開発時のテスト

VM デプロイ前にローカル PC で alpha-strike を起動して動作確認する場合：

```bash
# alpha-strike リポジトリで
uv run uvicorn webhook_server:app --host 0.0.0.0 --port 8080 --reload

# 別ターミナルから
curl http://localhost:8080/health
# → {"status":"ok"}

curl -X POST http://localhost:8080/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"test","broker":"moomoo","asset_class":"US","action":"buy","ticker":"US.AAPL","quantity":1,"run_mode":"paper"}'
```

TradingView から外部 URL に到達させたい場合は本番デプロイ（Cloudflare Tunnel）を使うのが最も確実です。ローカル PC を直接公開したい場合は `ngrok` や `cloudflared tunnel --url http://localhost:8080` で一時的なトンネルを張れます。

---

## 関連ドキュメント

- [alpha-strike セットアップガイド（ペーパートレード本格運用）](./alpha-strike-setup.md) — VM・Cloudflare・WAF・OpenD・systemd の完全手順
- [TradingView への Pine Script 反映](./tradingview-pine-integration.md) — alpha-forge 出力の Pine スクリプトを TradingView に貼る方法
- [エンドツーエンド戦略開発ワークフロー](./end-to-end-workflow.md) — 戦略開発から本番運用までの全体フロー

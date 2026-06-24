# alpha-forge data

ヒストリカルマーケットデータの取得・更新・参照を行うコマンドグループ。プロバイダー（yfinance / moomoo / OANDA / Dukascopy / TradingView MCP）から OHLCV を取得し、Parquet 形式でローカルキャッシュします。

!!! info "サンプル出力について"
    本ページの出力例は `alpha-forge` のソースから読み取ったフォーマットを元にしたサンプルです。実際の数値はデータと環境によって異なります。

## サブコマンド一覧

| コマンド | 説明 |
|---------|------|
| [`alpha-forge data fetch`](#alpha-forge-data-fetch) | ヒストリカルデータを取得して保存する |
| [`alpha-forge data list`](#alpha-forge-data-list) | 保存済みのヒストリカルデータ一覧を表示する |
| [`alpha-forge data trend`](#alpha-forge-data-trend) | 保存済みデータから市場トレンドを判定する |
| [`alpha-forge data update`](#alpha-forge-data-update) | 保存済みの全ヒストリカルデータを最新状態まで一括で差分更新する |

---

## alpha-forge data fetch

指定銘柄またはウォッチリストの OHLCV をプロバイダーから取得し、Parquet 形式で `config.data.storage_path` に保存します。デフォルトでは `config.data.cache_ttl_hours` 内のキャッシュを再利用し、`--force` で強制再取得できます。

### 構文

```bash
alpha-forge data fetch [SYMBOL] [OPTIONS]
alpha-forge data fetch --watchlist <FILE> [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL` | 引数（任意） | - | 銘柄シンボル。`--watchlist` と排他 |
| `--period` | オプション | `1y` | 取得期間（例: `1y`、`5y`、`6m`、`30d`、`max`） |
| `--interval` | オプション | `1d` | 時間足（例: `1d`、`1h`、`5m`） |
| `--watchlist` | オプション | - | 複数銘柄リストファイル（行ごとに 1 銘柄、`#` 始まりはコメント） |
| `--force` | フラグ | false | TTL に関わらず強制的に再取得 |
| `--provider` | choice | - | データソースを明示指定（`yfinance` / `moomoo` / `tv_mcp`）。省略時は `forge.yaml` の `data.providers` 設定で自動解決 |
| `--mcp-server` | オプション | - | `--provider tv_mcp` 用 MCP サーバーコマンド（例: `node /opt/tv-mcp/server.js`）。省略時は環境変数 `FORGE_TV_MCP_ENDPOINT` → `forge.yaml` の `data.providers.tv_mcp.endpoint` の順で解決（issue #689）。endpoint 内の `~` / `$HOME` は自動展開される |
| `--mcp-server-flavor` | choice | - | `--provider tv_mcp` 用 MCP server 系統（`tradesdontlie` / `vinicius`）。CLI 指定が `forge.yaml` より優先 |
| `--with-dividends` | フラグ | false | OHLCV と同時に配当履歴も取得して保存する（#958 Phase 2）。高配当 ETF の真の total return 評価に必要 |

`SYMBOL` も `--watchlist` も指定しないとエラーになります。`--provider tv_mcp` を指定しても `endpoint` が解決できない場合はエラーで停止します。

### サンプル出力（単一シンボル）

```text
データの取得を開始します: SPY (period=5y, interval=1d)
SPY のデータを取得し保存しました (1258 lines)
```

キャッシュ有効時：

```text
キャッシュが有効です: SPY (TTL: 24h) — スキップ。強制取得は --force を使用してください。
```

### サンプル出力（ウォッチリスト）

```text
3 銘柄のデータ取得を開始します...
  [SPY] 取得中...
  [SPY] 完了: 1258 行
  [QQQ] キャッシュが有効です (TTL: 24h) — スキップ
  [AAPL] 取得中...
  [AAPL] エラー: <詳細>
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `エラー: symbol または --watchlist を指定してください。` | 引数未指定 | `SYMBOL` または `--watchlist <FILE>` を渡す |
| `エラー: ウォッチリストファイルが見つかりません - <path>` | パス誤り | パスを確認 |
| `[<SYM>] エラー: <details>` | プロバイダー側のエラー（ネットワーク、認証、シンボル不正等） | プロバイダー設定や `forge.yaml` を確認 |

---

## alpha-forge data list

保存済みデータセットの一覧を表示します。

### 構文

```bash
alpha-forge data list [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON で標準出力する（機械可読・MCP / パイプ用途）（issue #1176） |

`--json` 指定時は stdout に純 JSON を出力します（装飾・進捗は stderr へ分離）。

### サンプル出力

```text
保存済みデータ件数: 3
- SPY (1d): 2018-01-02 から 2025-12-31 (2014 rows)
- QQQ (1d): 2018-01-02 から 2025-12-31 (2014 rows)
- USDJPY=X (1d): 2020-01-01 から 2025-12-31 (1530 rows)
```

データが 1 件もない場合：

```text
保存済みデータ件数: 0
```

### サンプル出力（`--json`）

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

**Exit code**: `0`=成功、`1`=not found / 実行失敗、`2`=引数エラー。

---

## alpha-forge data trend

保存済みデータから市場トレンドシグナル（強気・弱気・中立など）を生成します。`--symbols` 未指定時は `DEFAULT_TREND_SYMBOLS`（主要日米セット）を使用。

### 構文

```bash
alpha-forge data trend [OPTIONS]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--symbols` | オプション | デフォルト主要日米セット | カンマ区切りの判定対象シンボル |
| `--watchlist` | オプション | - | 判定対象シンボルのリストファイル |
| `--interval` | オプション | `1d` | 時間足 |
| `--as-of` | オプション | - | この日付以前の足で判定（`YYYY-MM-DD`） |
| `--json` | フラグ | false | JSON で出力 |

`--symbols` と `--watchlist` の両方を指定した場合、`--watchlist` が優先されます。

### サンプル出力（テキスト）

各行は `<シンボル>: <ラベル> - <サマリ>` 形式です。ラベルは日本語（`上昇トレンド` / `下降トレンド` / `回復基調` / `失速気味` / `中立`）で、サマリには 20 日騰落率が添えられます。

```text
SPY: 上昇トレンド - SPY は 上昇トレンド です（20日騰落率 +5.23%）
QQQ: 上昇トレンド - QQQ は 上昇トレンド です（20日騰落率 +7.81%）
^N225: 中立 - ^N225 は 中立 です（20日騰落率 +0.42%）
USDJPY=X: 下降トレンド - USDJPY=X は 下降トレンド です（20日騰落率 -2.10%）
```

### サンプル出力（`--json`）

JSON では `trend`（英小文字 enum: `bullish` / `bearish` / `recovery` / `weakening` / `neutral`）と `label`（日本語表示名）の 2 フィールドに加え、`close` / `pct_1d` / `pct_5d` / `pct_20d` / `sma20` / `sma50` / `sma200` を返します。

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

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `ウォッチリストファイルが見つかりません - <path>` | パス誤り | パスを確認 |

---

## alpha-forge data update

`alpha-forge data list` で見えるすべての保存済みデータについて、最終取得日から **本日まで差分取得** します。既に最新のデータはスキップ。

### 構文

```bash
alpha-forge data update [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON で標準出力する（機械可読・MCP / パイプ用途）（issue #1176） |

`--json` 指定時は stdout に純 JSON を出力します（装飾・進捗は stderr へ分離）。

### サンプル出力

```text
全 3 件のデータ更新を開始します...
  [Update] SPY (1d) を 2025-12-15 から現在まで取得します...
    - 12 行のデータを追加・更新しました。
  [Skip] QQQ (1d): すでに最新 (2025-12-31) です。
  [Update] USDJPY=X (1d) を 2025-12-20 から現在まで取得します...
    - 新しいデータはありませんでした。
1 件のデータを更新完了しました。
```

### サンプル出力（`--json`）

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

**Exit code**: `0`=成功、`1`=not found / 実行失敗、`2`=引数エラー。

データが 1 件もない場合：

```text
保存済みのデータがありません。
```

### 主なエラー

| メッセージ | 原因 | 対処 |
|----------|------|------|
| `[Skip] <SYM> (<interval>): 有効な最終取得日がありません。` | メタデータ破損や空ファイル | `alpha-forge data fetch <SYM> --force` で再取得 |
| `- エラーが発生しました: <details>` | プロバイダー側のエラー | エラー内容に応じて対処 |

---

## データソース対応表

`forge.yaml` の `data.providers` 設定で銘柄・interval ごとにプロバイダーを切替できます（`alpha-forge` 同梱の実装）。

| プロバイダー | 主な対応資産 | 認証 | period 上限の目安 | interval の目安 |
|------------|------------|------|------------------|----------------|
| **yfinance** | 株 / ETF / FX / 先物 | 不要 | `max`（`1d` で 数十年）、`1h` で 約 2 年、`5m` で 約 60 日 | `1d`、`1h`、`30m`、`15m`、`5m`、`1m` |
| **moomoo** | 株 / ETF（米・香港・本土） | 要 OpenD ローカル接続 | プロバイダー仕様 | `1d`、`1h`、`5m` ほか |
| **OANDA** | FX | 要 API キー | プロバイダー仕様 | `1d`、`H1`、`M5` ほか |
| **Dukascopy** | FX 超長期 | 不要（CSV ダウンロード） | 数十年 | `1d`、`1h`、`5m` |
| **tv_mcp** | TradingView 上で表示できる全銘柄（株・ETF・FX・先物・暗号通貨等） | 要 TradingView Desktop（`--remote-debugging-port=9222`）+ MCP server 起動 | TradingView 仕様（`1d` で数十年、`1h` で十年以上が可能） | TradingView の interval 表記（`D`、`60`、`5` 等）に正規化される |

!!! warning "OANDA の長期 × 分足取得はページ上限で途中までになる（issue #1183）"
    OANDA は 1 リクエスト最大 5000 件のページを内部で繰り返し取得しますが、ページ取得回数には上限があります。**非常に長期 × 分足**（例: 数年分の `M5`）のように必要ページ数が上限を超える組み合わせでは、要求期間の途中までしか取得できないことがあります。その際は `OANDA: ページ取得上限 ... に達したため、要求期間の途中までしか取得できていません` という WARNING が出力されます。さらに遡る場合は FX 超長期向けの `dukascopy` プロバイダーの利用を検討してください。

### TradingView MCP プロバイダー（`tv_mcp`、issue #576）

`--provider tv_mcp` を指定すると、TradingView Desktop に接続した MCP server から OHLCV を取得します。yfinance の period 上限（`5y` 程度）を超える長期データの取得を主目的としています。

- **前提**: TradingView Desktop を `--remote-debugging-port=9222` で起動し、`tradesdontlie/tradingview-mcp` または `oviniciusramosp/tradingview-mcp`（vinicius fork）を別プロセスで起動しておく
- **範囲スライド**: 1 リクエスト 500 bars 上限を内部で自動分割し、`--period max` でも複数チャンクを連結する（上限は `data.providers.tv_mcp.max_chunks`）
- **flavor**: `data_get_ohlcv` は両系共通で動作。OHLCV のみ用途なら既定の `tradesdontlie` で十分

!!! warning "長期 fetch の TV 側 preload 制約（issue #683）"
    両 MCP fork 共通で `data_get_ohlcv(count=N)` は **TV チャートにロード済みの bars cache の最新 N 件**だけを返します。`chart_set_visible_range` は zoom 操作のみで cache を拡張しないため、`--period 20y` のような長期指定でも、TV が現在 preload している期間（多くの場合直近 1〜2 年）を超えて遡れません。

    `_fetch_with_sliding_window` は各 chunk で `requested range / bars 数 / first・last bar time` を INFO ログに出力し、最新 bar timestamp が 3 chunk 連続で前進しないと no-progress streak を検出して早期に bail します。bail 時には `tv_mcp fetch truncated: TV chart preload covers only YYYY-MM-DD..YYYY-MM-DD (requested YYYY-MM-DD..YYYY-MM-DD)` という WARNING を出力します。

    **長期データが必要な場合**は次のいずれかを選択してください：

    - 株 / ETF: `--provider yfinance`（既定の最大約 30 年）
    - FX 超長期: `forge.yaml` の `data.providers.fx_provider: dukascopy`（または `fx_provider: auto` + `auto_routing` で FX を `dukascopy` にルーティング）を設定して取得する（数十年）。`--provider` CLI フラグは `yfinance` / `moomoo` / `tv_mcp` のみ受理するため `--provider dukascopy` は使えない点に注意
    - tv_mcp で深い履歴を取りたい場合は、事前に TradingView Desktop でチャートを目的の年代まで手動スクロールして bars cache を拡張しておくと、その範囲は MCP 経由で取得できるようになる（持続的な解決は MCP server 側の新 tool が必要）
- **設定例**（`forge.yaml`）:

```yaml
data:
  providers:
    stock_provider: tv_mcp     # 株 / ETF を tv_mcp で取得
    fx_provider: tv_mcp        # FX も tv_mcp で取得
    enable_fallback: true      # tv_mcp 失敗時 yfinance へフォールバック
    tv_mcp:
      endpoint: ""             # 空文字なら環境変数 FORGE_TV_MCP_ENDPOINT を使用（issue #689）。
                               # `~` / `$HOME` を含むパスはそのまま書ける（例: "node ~/opt/tv-mcp/server.js"）
      flavor: tradesdontlie    # OHLCV 用途なら tradesdontlie で OK
      max_bars_per_call: 500   # MCP 上限
      max_chunks: 200          # 範囲スライド時のチャンク上限
      timeout_seconds: 120
```

!!! tip "endpoint の解決優先順位（issue #689）"
    1. CLI `--mcp-server`
    2. 環境変数 `FORGE_TV_MCP_ENDPOINT`
    3. `forge.yaml` の `data.providers.tv_mcp.endpoint`

    複数マシン・CI で `forge.yaml` を共有する場合は `endpoint: ""` のままコミットし、`FORGE_TV_MCP_ENDPOINT` を環境ごとに設定する運用がおすすめです。

実行例：

```bash
# CLI で endpoint を直接指定して fetch
alpha-forge data fetch SPY --provider tv_mcp --mcp-server "node /opt/tv-mcp/server.js" --period max

# 環境変数で endpoint を渡す（~ / $HOME も展開される）
FORGE_TV_MCP_ENDPOINT="node ~/opt/tv-mcp/server.js" \
  alpha-forge data fetch USDJPY --provider tv_mcp --period 20y --interval 1d

# forge.yaml の設定を利用（CLI から endpoint を省略）
alpha-forge data fetch USDJPY --provider tv_mcp --period 20y --interval 1d
```

#### サブコマンド: `alpha-forge data tv-mcp check`（issue #674）

TV MCP データ取得サーバーの起動・接続を検証します。`/explore-strategies` スキルが、`goals.yaml` の `exploration.data_provider_override.{stock|fx}: tv_mcp` 設定された goal の冒頭で自動実行します。

```bash
# 既定（symbol=BATS:SPY で疎通確認）
alpha-forge data tv-mcp check

# JSON 出力（自動化スクリプト向け）
alpha-forge data tv-mcp check --json

# シンボルを変更（FX 用）
alpha-forge data tv-mcp check --symbol OANDA:USDJPY

# CLI で endpoint を直接指定
alpha-forge data tv-mcp check --mcp-server "node /opt/tv-mcp/server.js"
```

| オプション | 既定 | 説明 |
|-----------|------|------|
| `--mcp-server <command>` | 環境変数 `FORGE_TV_MCP_ENDPOINT` → `forge.yaml` の `data.providers.tv_mcp.endpoint` の順で解決 | MCP サーバーコマンド。`~` / `$HOME` は自動展開（issue #689） |
| `--symbol <symbol>` | `BATS:SPY` | 疎通確認に使うシンボル |
| `--json` | false | JSON で結果を出力 |

**Exit code**: `0`=セッション有効、`2`=endpoint 未設定 / TV Desktop 未起動 / MCP server 接続失敗。`/explore-strategies` スキルが exit 2 を検出すると、`<goal_dir>/explored_log.md` に「TV MCP 認証エラーで停止」を記録してループを停止します（自動起動・再試行は行いません）。

### `auto` ルーティング（issue #583 Phase 1.5e-δ）

`stock_provider` / `fx_provider` に `auto` を指定すると、シンボルから判定したアセット種別ごとに `auto_routing` テーブルから provider を解決します。`alpha-forge data fetch <SYM>` を実行するたびに別 provider を選びたい運用に便利です。

```yaml
data:
  providers:
    stock_provider: auto
    fx_provider: auto
    auto_routing:
      stock: tv_mcp      # 米株 / 日本株は TV MCP（長期データ）
      etf: tv_mcp
      fx: oanda          # FX は OANDA
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

アセット種別の判定は `alpha_forge.data.symbols.detect_asset_type` を利用：

| 種別 | 判定ルール例 |
|------|--------------|
| `fx` | `USDJPY=X` / `EUR/USD` / `USD_JPY` |
| `index` | `^GSPC`、`^VIX`、`^NDX`（`^` 始まり） |
| `commodity` | `GC=F`、`CL=F`、`SI=F`（`=F` 末尾） |
| `crypto` | `BTC-USD`、`ETH-USDT`、`ADA-BTC` |
| `etf` | 既知 ETF リストに含まれるもの（`SPY`、`QQQ` 等） |
| `stock` | 上記以外 |

`auto_routing` テーブルにエントリが無いアセット種別が来た場合は明示的にエラーになります（`yfinance` への暗黙的フォールバックはしない）。

### シンボル表記の例

| 資産タイプ | 例 |
|----------|------|
| 米国株 / ETF | `AAPL`、`SPY`、`QQQ`、`NVDA` |
| 為替（yfinance） | `USDJPY=X`、`EURUSD=X` |
| 為替（OANDA） | `USD_JPY`、`EUR_USD` |
| 先物（yfinance） | `CL=F`（原油）、`GC=F`（金）、`SI=F`（銀） |
| TradingView MCP | TradingView 表記そのまま（`AAPL`、`USDJPY`、`OANDA:EURUSD`、`COMEX:GC1!` 等） |

プロバイダー固有のシンボル表記は `alpha-forge/src/alpha_forge/data/providers/<provider>.py` を参照してください。

---

## alpha-forge data tv-mcp

TradingView MCP server を介したチャート取得・任意ツール呼び出しを行うコマンドグループ（issue #523）。

## alpha-forge data tv-mcp chart

TradingView チャートのスナップショット PNG を取得します（Phase 1.5d）。

```bash
alpha-forge data tv-mcp chart <SYMBOL> [--interval D] [--width W] [--height H] [--theme light|dark] [--output <PNG>] [--mcp-server <CMD>]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SYMBOL` | 引数（必須） | - | TV シンボル |
| `--interval` | オプション | `D` | タイムフレーム（`1`, `5`, `60`, `D`, `W`, `M`） |
| `--width` / `--height` | int | `forge.yaml` の `tv_mcp.chart_snapshot` | 画像サイズ |
| `--theme` | choice | `forge.yaml` 既定 | `light` / `dark` |
| `--output` | ファイル | - | 出力 PNG パス。省略時はキャッシュパスのみ表示 |
| `--mcp-server` | オプション | - | MCP サーバー（省略時 `tv_mcp.chart_snapshot.endpoint`） |
| `--mock` | フラグ | false | Mock MCP（CI 用） |
| `--no-cache` | フラグ | false | キャッシュを無視 |
| `--md-output` | ファイル | - | Markdown ファイルに画像リンクを追記（`--output` 必須） |
| `--md-alt` | オプション | - | Markdown 画像 alt（既定: `SYMBOL Interval`） |

実行例：

```bash
alpha-forge data tv-mcp chart SPY --interval D --output charts/spy_d.png \
  --mcp-server "python /opt/tv-mcp-chart/server.py"
```

## alpha-forge data tv-mcp inspect

任意の MCP tool を呼び出して JSON でレスポンスを表示します（Phase 1.5c-α）。新しい MCP server の挙動確認や、サポートされているツール一覧の探索に使います。

```bash
alpha-forge data tv-mcp inspect <TOOL_NAME> [--server-type pine|chart] [--mcp-server <CMD>] [--arg key=value ...] [--args-json '{...}'] [--output <JSON>] [--pretty|--compact]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `TOOL_NAME` | 引数（必須） | - | 呼び出す MCP tool 名 |
| `--server-type` | choice | `pine` | endpoint 既定値の選択（`pine` = `tv_mcp.pine_verify`、`chart` = `tv_mcp.chart_snapshot`） |
| `--mcp-server` | オプション | - | 直接サーバーコマンドを指定 |
| `--mock` | フラグ | false | 固定 Mock レスポンス（CI 用） |
| `--arg` | 複数指定可 | - | tool 引数 `key=value`（値は JSON として解釈試行） |
| `--args-json` | オプション | - | tool 引数を JSON オブジェクトで指定（`--arg` と排他） |
| `--output` | ファイル | - | JSON 出力先 |
| `--pretty` / `--compact` | フラグ | `--pretty` | 整形 / 1 行 JSON |

実行例：

```bash
# tool 一覧（実装に依存）
alpha-forge data tv-mcp inspect list_tools --server-type pine \
  --mcp-server "node /opt/tv-mcp/server.js"

# data_get_ohlcv を試す
alpha-forge data tv-mcp inspect data_get_ohlcv \
  --arg symbol=SPY --arg interval=D --arg bars=10
```

## alpha-forge data tv-mcp cache-clean

`alpha-forge data tv-mcp chart` が `config.tv_mcp.chart_snapshot.cache_path`（既定 `data/cache/charts/`）に日次キーで蓄積する PNG キャッシュを、期間（mtime 基準）で整理して削除します。

```bash
alpha-forge data tv-mcp cache-clean [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--older-than` | オプション | - | mtime が指定日数より古い PNG を削除（`30d` / `30` 書式） |
| `--dry-run` | フラグ | false | 実際には削除せず、削除対象一覧を表示して終了 |
| `--yes` / `-y` | フラグ | false | 確認プロンプトをスキップして削除 |
| `--json` | フラグ | false | 結果を JSON で出力（`{removed: [...], failed: [...], count, dry_run}`） |

- `--older-than` 未指定は **全消し事故防止のため終了コード `2`** で停止します。キャッシュ未作成時は 0 件で正常終了します。
- 破壊的操作のため、非対話環境（`FORGE_NONINTERACTIVE` / `CI` / 非 TTY）で `--yes` が無いと終了コード `2`。`--json` 実行時も `--yes` が必須です。

---

## alpha-forge data alt

代替データ（センチメント、マクロ指標等）の取得・管理。`config.data.alt_storage_path` 配下に保存され、戦略 JSON では `ALTDATA` 指標タイプで参照できます。

## alpha-forge data alt fetch

```bash
alpha-forge data alt fetch <SOURCE_KEY> --start <YYYY-MM-DD> --end <YYYY-MM-DD>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `SOURCE_KEY` | 引数（必須） | データソースキー（プロバイダー固有） |
| `--start` | 必須 | 取得開始日 |
| `--end` | 必須 | 取得終了日 |

出力: `✅ <SOURCE_KEY>: <N>行を保存しました`。プロバイダー未登録時は `ClickException`。

## alpha-forge data alt list

```bash
alpha-forge data alt list
alpha-forge data alt list --json   # 機械可読（MCP / パイプ用途、issue #1225）
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON で出力する（機械可読・MCP / パイプ用途、issue #1225。装飾・進捗は stderr へ分離） |

サンプル出力：

```text
保存済み代替データ件数: 2
SOURCE_KEY                INTERVAL   ROWS         START           END
fear_greed_index          1d          1525   2020-01-01   2025-12-31
vix_termstructure         1d          1530   2020-01-01   2025-12-31
```

保存済みの代替データが無い場合は次の 1 行のみを出力して終了コード `0` で終わります。

```text
保存済みの代替データはありません。
```

`--json` 指定時は stdout に純 JSON のみを出力します。**Exit code**: `0`=成功, `1`=not found / 実行失敗, `2`=引数エラー。

## alpha-forge data alt info

```bash
alpha-forge data alt info <SOURCE_KEY>
alpha-forge data alt info <SOURCE_KEY> --json   # 機械可読（MCP / パイプ用途、issue #1225）
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `SOURCE_KEY` | 引数（必須） | - | 詳細を表示するデータソースキー |
| `--json` | フラグ | false | 結果を JSON で出力する（機械可読・MCP / パイプ用途、issue #1225） |

ソースキー、時間足、行数、開始日・終了日、カラム、ファイルパス、ファイルサイズを表示。データ未取得時は `ClickException`。`--json` 指定時は stdout に純 JSON のみを出力します（read-only コマンドの `--json` 網羅、issue #1225）。

---

## 共通の挙動

- **保存形式**: Parquet（`config.data.storage_path / <SYMBOL>_<interval>.parquet`）
- **TTL キャッシュ**: `config.data.cache_ttl_hours` 内なら `fetch` はスキップ。`--force` でバイパス可能
- **プロバイダー解決**: `get_data_fetcher(symbol=..., config=config)` がシンボルから `forge.yaml` の `data.providers` 設定でプロバイダーを選択
- **`FORGE_CONFIG`**: 保存先・プロバイダー設定は環境変数 `FORGE_CONFIG` が指す `forge.yaml` で決まる
- **終了コード**: 通常 `0`、`click.ClickException` で `1`、引数エラーは Click が `2` を返す
- **Trial プラン制限**: Trial プランでは取得時にも `end` が `2023-12-31` に強制キャップされ、`alpha-forge data update` で保有最終日が 2023-12-31 以降のアイテムはスキップされます。詳細は [Trial 制限](../guides/trial-limits.md) を参照。

---

<!-- 同期元: `alpha-forge/src/alpha_forge/commands/data.py` の Click decorator、`alpha-forge/src/alpha_forge/data/providers/` のプロバイダー実装、`alpha-forge/CLAUDE.md` のプロバイダー記述。alpha-forge 側で引数追加・プロバイダー追加があった場合、本ページも追従更新が必要。 -->

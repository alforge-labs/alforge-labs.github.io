# alpha-strike セットアップガイド（ペーパートレード本格運用）

TradingView のアラートを Webhook 経由で受け取り、moomoo / OANDA の **SIMULATE / PRACTICE 口座** に自動発注する alpha-strike を、**Oracle Cloud Always Free + Cloudflare Tunnel** で本格運用するまでの一気通貫手順です。

> **本ガイドの到達点**: 自宅 IP が DHCP で変動しても影響を受けず、月額 0 円のインフラで TradingView Premium / Essential のアラートを受信し、moomoo SIMULATE 口座に自動発注する経路を確立する。
>
> **インフラ前提**: Oracle Cloud Always Free の E2.1.Micro (1/8 OCPU, 1GB RAM) で十分動作することを実機検証済み（メモリ使用 約 600MB / 954MB）。
>
> **TradingView プラン**: **Essential 以上**（Webhook URL が利用可能なプラン）であれば動作します。Premium が必須ではありません。

---

## 全体アーキテクチャ

```
TradingView (Pine 戦略 / アラート)
       │  HTTPS Webhook
       ▼
Cloudflare WAF Custom Rule (TradingView IP allowlist)
       │
Cloudflare Tunnel (cloudflared)
       │  outbound only (NSG Ingress = 0 件)
       ▼
Oracle Cloud VM "alpha-strike-01" (E2.1.Micro)
  ├─ alpha-strike (FastAPI, localhost:8080)
  └─ moomoo OpenD  (localhost:11111)
       │
       ▼
moomoo SIMULATE 口座（米国株・香港株のペーパートレード）
```

---

## 1. 事前準備チェックリスト

- [ ] Oracle Cloud Infrastructure アカウント（Always Free 枠）
- [ ] Cloudflare アカウント（Free plan）
- [ ] 独自ドメイン 1 つ（本ガイドでは `alforgelabs.com` を例示）
- [ ] moomoo 証券アカウント（OpenAPI に対応した SIMULATE 口座）
- [ ] TradingView アカウント（**Essential 以上、Webhook URL に対応するプラン**）
- [ ] 1Password（または同等のパスワード/シークレットマネージャー）
- [ ] ローカル PC（Mac/Linux 推奨）に `ssh` `curl` `git` がインストール済み

---

## 2. VM プロビジョニング（Oracle Cloud E2.1.Micro）

### 2-1. インスタンス作成

| 項目 | 値 |
|---|---|
| Image | `Canonical Ubuntu 24.04` |
| Shape | `VM.Standard.E2.1.Micro` (Always Free) |
| Boot Volume | デフォルト（46.6 GB） |
| VCN/Subnet | デフォルトでも可。後で NSG を空にする |
| Public IPv4 | Ephemeral |
| SSH Public Key | ローカルの `~/.ssh/id_ed25519.pub` を貼付 |

### 2-2. NSG（Network Security Group）

**最終形態（Cloudflare Tunnel 経由・完全 egress only）**:

| 方向 | プロトコル | 送信元 | ポート | 用途 |
|---|---|---|---|---|
| Ingress | — | — | — | **0 件** |
| Egress | All | 0.0.0.0/0 | All | 外向き全許可 |

初期セットアップ中だけ自宅 IP からの SSH を一時的に許可し、Cloudflare Access for SSH（§4-3）に切替後に Ingress 全削除します。

### 2-3. OS 初期セットアップ

```bash
ssh ubuntu@<VM_PUBLIC_IP>
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl jq build-essential
```

### 2-4. メモリ補強（1GB RAM 対策）

```bash
# Swap 4GB
sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile
sudo mkswap /swapfile && sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# zram 477MB (lz4)
sudo apt install -y zram-tools
echo 'ALGO=lz4
PERCENT=50' | sudo tee /etc/default/zramswap
sudo systemctl restart zramswap
```

### 2-5. uv インストール（Python パッケージ管理）

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv --version
```

---

## 3. Cloudflare Tunnel セットアップ

### 3-1. ドメインを Cloudflare ネームサーバーに移管

ドメインレジストラ管理画面でネームサーバーを Cloudflare 指定値（例: `xxx.ns.cloudflare.com / yyy.ns.cloudflare.com`）に変更。反映には数時間〜半日。

```bash
dig +short NS yourdomain.com
# 期待: xxx.ns.cloudflare.com / yyy.ns.cloudflare.com
```

### 3-2. Tunnel 作成

1. Cloudflare ダッシュボード → **Zero Trust → Networks → Tunnels → Create a tunnel**
2. Tunnel type: **Cloudflared**
3. Tunnel name: `alpha-strike-prod`
4. **Save tunnel** → トークンが発行される
5. VM 側で表示されたインストールコマンドを実行：

```bash
sudo cloudflared service install <TOKEN>
sudo systemctl status cloudflared
```

### 3-3. Public hostname 設定（webhook）

同 Tunnel 画面の **Hostname routes (Beta)** タブ → **Add a hostname route**：

| 項目 | 値 |
|---|---|
| Subdomain | `strike` |
| Domain | `yourdomain.com` |
| Type / Service | `HTTP` |
| URL / Target | `localhost:8080` |

`https://strike.yourdomain.com` にブラウザでアクセスして **502 Bad Gateway** が返れば Tunnel 接続成功（alpha-strike 未起動が原因の 502 なので OK）。

### 3-4. SSH も Tunnel 経由に切替（推奨）

`Add a hostname route` で同じ Tunnel に SSH も追加：

| 項目 | 値 |
|---|---|
| Subdomain | `ssh` |
| Domain | `yourdomain.com` |
| Type / Service | `SSH` |
| URL / Target | `localhost:22` |

ローカル PC 側 `~/.ssh/config`：

```ssh-config
Host oracle-strike
  HostName ssh.yourdomain.com
  User ubuntu
  ProxyCommand cloudflared access ssh --hostname %h
  IdentityFile ~/.ssh/id_ed25519
```

これで自宅 IP が DHCP で変動しても `ssh oracle-strike` で接続可能。

### 3-5. NSG Ingress を 0 件に

§2-2 の最終形態に従って、Cloudflare Access for SSH が稼働確認できたら OCI 側 NSG の Ingress ルールを全削除。

---

## 4. Cloudflare WAF Custom Rule（TradingView IP allowlist）

TradingView は公式に **4 つの送信元 IPv4** を公開しています。`/webhook` パスはこの 4 IP からのみ通過させる。

### 4-1. Custom Rule を作成

1. Cloudflare ダッシュボード → 対象ドメインを選択 → **Security → Security rules**
2. **Custom rules** 行の **Create rule** をクリック
3. 以下を入力：

| 項目 | 値 |
|---|---|
| Rule name | `Allow only TradingView IPs to /webhook` |
| Expression | 下記をテキストモードで貼り付け |
| Then take action | **Block** |

```
(http.host eq "strike.yourdomain.com" and http.request.uri.path eq "/webhook" and not ip.src in {52.89.214.238 34.212.75.30 54.218.53.128 52.32.178.7})
```

**Deploy** で即時反映。

> **TradingView 公式の送信元 IP**: [公式 Help Center](https://www.tradingview.com/support/solutions/43000529348-about-webhooks/) で公開されている値です。変更時はこのページで再確認してください。
>
> **passphrase との二重防御**: WAF で IP を絞っても、リクエストボディの `passphrase` 検証は必須です。

### 4-2. デプロイ後の検証

```bash
# 自宅 IP (= TradingView IP ではない) からの POST は 403 になる
curl -i -X POST https://strike.yourdomain.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"dummy"}'
# → HTTP/2 403 + Cloudflare ブロックページ

# /health は通る（WAF rule は /webhook パスのみが対象）
curl https://strike.yourdomain.com/health
# → {"status":"ok"} （※ alpha-strike 起動後）
```

---

## 5. moomoo OpenD セットアップ

### 5-1. OpenD インストール

[moomoo 公式](https://www.moomoo.com/download/OpenAPI) から `moomoo_OpenD_*_Ubuntu18.04.tar.gz` をダウンロードして VM へ転送：

```bash
# Mac から
scp ~/Downloads/moomoo_OpenD_*.tar.gz oracle-strike:~/
# VM 側
ssh oracle-strike
mkdir -p ~/moomoo_OpenD && tar xzf moomoo_OpenD_*.tar.gz -C ~/moomoo_OpenD --strip-components=1
```

### 5-2. 取引パスワード MD5 ハッシュ生成

```bash
# Mac 側で（input を不可視化）
read -s -p "moomoo 取引パスワード: " PW && echo -n "$PW" | md5
unset PW
```

出力された 32 桁の hex 文字列が後述の `MOOMOO_TRADE_PWD_MD5` です。

### 5-3. デバイストークン認証（ヘッドレス VM のテクニック）

OpenD の初回ログインは SMS 認証 + CAPTCHA を要求しますが、VM はヘッドレスのためブラウザ操作不可。**Mac 側で認証して `~/.com.moomoo.OpenD/F3CNN/` を VM に rsync** するのが最も確実です。

```bash
# Mac 側で moomoo OpenD を起動して SMS 認証を完了させる
# その後、認証済みディレクトリを VM へ転送
rsync -avz ~/.com.moomoo.OpenD/F3CNN/ oracle-strike:~/.com.moomoo.OpenD/F3CNN/
```

### 5-4. 環境変数ファイル

```bash
ssh oracle-strike
sudo mkdir -p /etc
sudo tee /etc/moomoo_OpenD.env > /dev/null <<'EOF'
MOOMOO_LOGIN_ACCOUNT=your-moomoo-account
EOF
sudo chmod 600 /etc/moomoo_OpenD.env
```

### 5-5. systemd ユニット

```bash
sudo tee /etc/systemd/system/moomoo-opend.service > /dev/null <<'EOF'
[Unit]
Description=moomoo OpenD CLI
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
EnvironmentFile=/etc/moomoo_OpenD.env
WorkingDirectory=/home/ubuntu/moomoo_OpenD
ExecStart=/home/ubuntu/moomoo_OpenD/OpenD -login_account=${MOOMOO_LOGIN_ACCOUNT} -login_by_remember=1 -api_ip=127.0.0.1 -api_port=11111 -console=1 -log_level=info
Restart=always
RestartSec=10
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now moomoo-opend
sudo systemctl status moomoo-opend
```

> **`-login_by_remember=1`**: デバイストークン経由でログイン。SMS / CAPTCHA を毎回要求されないようにする鍵設定です。

---

## 6. alpha-strike デプロイ

### 6-1. PyPI からインストール

alpha-strike は PyPI で配布されています ([pypi.org/project/alpha-strike/](https://pypi.org/project/alpha-strike/))。`uv` で隔離環境にインストールして `alpha-strike` CLI を使う形が推奨です。

```bash
ssh oracle-strike
sudo apt install -y python3.12 python3.12-venv  # 未導入なら

# /opt 配下に専用 venv を作る
sudo mkdir -p /opt/alpha-strike
sudo chown ubuntu:ubuntu /opt/alpha-strike
cd /opt/alpha-strike

uv venv --python 3.12
uv pip install alpha-strike

# 動作確認
.venv/bin/alpha-strike --version
# → alpha-strike 0.3.0 以降
```

### 6-2. `.env` 作成

```bash
sudo mkdir -p /etc/alpha-strike
sudo tee /etc/alpha-strike/.env > /dev/null <<'EOF'
# 必須
WEBHOOK_PASSPHRASE=<32文字以上のランダム文字列>

# moomoo 設定
MOOMOO_HOST=127.0.0.1
MOOMOO_PORT=11111
MOOMOO_TRADE_PWD_MD5=<§5-2 で生成した 32 桁 hex>
MOOMOO_TRADE_ENV=SIMULATE
# over-sell ガード（既定 ON）。実保有を超える SELL は実保有まで clamp、
# 建玉ゼロは skip し、moomoo の "Not enough positions" を防ぐ。
# 無効化する場合のみ設定: MOOMOO_SELL_POSITION_GUARD=0
# REAL の米国市場の成行注文の有効期限（既定 GTC）。日足アラートは市場クローズ後に
# 届くため、GTC で翌営業日寄付に持ち越して約定させる（DAY だと約定せず失効）。
# 旧挙動に戻す場合のみ設定: MOOMOO_TIME_IN_FORCE=DAY
# ※ SIMULATE（ペーパー）は moomoo 10.7 が GTC を拒否するため本設定に関わらず常に DAY。
# ※ SIMULATE のクローズ後着シグナルは DAY 失効するため、carry-over (#89) が次の市場
#   オープンで自動再発注して約定させる（既定 ON）。無効化は CARRYOVER_ENABLED=0、
#   間隔は CARRYOVER_RESUBMIT_INTERVAL_SECONDS=300、有効期限は CARRYOVER_LOOKBACK_HOURS=48。
# target_qty による closed-loop 数量解決（既定 ON、v0.7.0+）。payload の
# target_qty（目標絶対保有量）と実保有の差分から発注数量・方向を再解決する。
# 旧 delta 解釈に戻す場合のみ設定: MOOMOO_TARGET_QTY_RECONCILE=0
# GTC 注文の翌営業日約定をイベントログへ反映する遅延再照合（既定 ON、v0.7.1+）。
# 間隔調整は PENDING_RECONCILE_INTERVAL_SECONDS=600、
# 無効化する場合のみ設定: PENDING_RECONCILE_ENABLED=0
# TradingView シグナルの途絶監視（既定 ON、v1.2.0+）。TradingView のアラートは
# 現行プランで最大 1 ヶ月しか設定できず、期限切れでサイレントに配信が止まる。
# 最後のシグナルからの実効時間（土日除外）が 60h を超えたら ntfy で通知する。
# 調整は SIGNAL_WATCHDOG_THRESHOLD_HOURS=60 / SIGNAL_WATCHDOG_INTERVAL_SECONDS=3600 /
# SIGNAL_WATCHDOG_RENOTIFY_HOURS=24 / SIGNAL_WATCHDOG_BROKER=moomoo
# 無効化する場合のみ設定: SIGNAL_WATCHDOG_ENABLED=0
# ※ v1.3.0 以降、途絶監視は alpha-strike 本体とは別プロセス（systemd timer
#   alpha-strike-watchdog.timer）で毎時実行される。本体のイベントループが OpenD の
#   同期呼び出しで凍結しても、プロセスが落ちても監視は動き続ける。

# OANDA を使う場合のみ
# OANDA_API_KEY=<your-token>
# OANDA_ACCOUNT_ID=<your-account-id>
# OANDA_ENV=PRACTICE
EOF
sudo chmod 600 /etc/alpha-strike/.env
```

`WEBHOOK_PASSPHRASE` は 1Password にも保管しておきます（後で TradingView の Message JSON に貼り付ける）。

### 6-3. systemd ユニット

```bash
sudo tee /etc/systemd/system/alpha-strike.service > /dev/null <<'EOF'
[Unit]
Description=alpha-strike webhook server
After=moomoo-opend.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/opt/alpha-strike
EnvironmentFile=/etc/alpha-strike/.env
ExecStart=/opt/alpha-strike/.venv/bin/alpha-strike --host 0.0.0.0 --port 8080
Restart=always
RestartSec=5
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now alpha-strike
sudo systemctl status alpha-strike
```

### 6-4. 動作確認（VM 内部）

```bash
curl http://127.0.0.1:8080/health
# → {"status":"ok"}
```

### 6-5. メモリ・サービス監視 cron

[alpha-strike リポジトリの `scripts/check_memory.sh`](https://github.com/alforge-labs/alpha-strike/blob/main/scripts/check_memory.sh) をローカル取得して crontab に登録：

```bash
# スクリプトを取得（PyPI 経由インストールには含まれない、リポジトリから直接）
sudo curl -fsSL \
  https://raw.githubusercontent.com/alforge-labs/alpha-strike/main/scripts/check_memory.sh \
  -o /usr/local/bin/check_alpha_strike_memory.sh
sudo chmod +x /usr/local/bin/check_alpha_strike_memory.sh

crontab -e
# 以下を追記
*/5 * * * * /usr/local/bin/check_alpha_strike_memory.sh
```

`~/.ntfy.env` に `NTFY_TOPIC=...` を設定しておくと、メモリ 85% / swap 1GB 等の閾値超過で [ntfy.sh](https://ntfy.sh) 経由で iPhone に通知が飛びます。

---

## 7. TradingView アラート設定

### 7-1. アラート作成

1. TradingView の対象チャート（例: `BINANCE:BTCUSDT` または対象株式）を開く
2. ベルアイコン → **Create Alert**
3. **Condition**: 戦略 / インジケータの発火条件を選択
4. **Notifications** タブ：
   - ✅ **Webhook URL** にチェック
   - URL に `https://strike.yourdomain.com/webhook` を入力
5. **Message** 欄に下記 JSON を貼付（`<WEBHOOK_PASSPHRASE>` を `.env` の実値に置換）：

```json
{
  "passphrase": "<WEBHOOK_PASSPHRASE>",
  "broker": "moomoo",
  "asset_class": "US",
  "action": "buy",
  "ticker": "US.AAPL",
  "quantity": 1,
  "run_mode": "paper",
  "strategy_id": "tv_smoke_test",
  "alert_name": "{{strategy.order.alert_message}}"
}
```

6. **Create** で保存

### 7-2. 即発火テスト（市場クローズ中でも可）

検証用には **24/7 動く Crypto チャート** (`BINANCE:BTCUSDT`) + 常時 true な条件 (`Price > 1`) を使うと、市場クローズ中でも次の 1m 足確定で発火します。

| 項目 | 値 |
|---|---|
| Symbol | `BINANCE:BTCUSDT` |
| Condition Type | **`Greater Than`** |
| Source | `Price (Close)` |
| Value | `1` |
| Frequency | `Once Per Bar` |

> **`Crossing Up` ではダメな理由**: BTC は常に 1 より上なので「上方クロス」イベントが発生しません。`Greater Than` は常時 true 評価なので確実に発火します。

JSON の `ticker:"US.AAPL"` は **発火銘柄（BTC）と独立** に moomoo へ送られます。

### 7-3. 暗号資産（CRYPTO）戦略を流す場合

moomoo は米国株・香港株と並んで暗号資産（BTC / ETH / XRP 等）も発注先として提供しています。alpha-strike は `asset_class="CRYPTO"` を受理し、内部で `OpenSecTradeContext(filter_trdmarket=TrdMarket.CRYPTO)` で発注します。

!!! warning "moomoo crypto は live (REAL) only — SIMULATE 不可"
    moomoo の crypto trading API は live 環境専用で、`MOOMOO_TRD_ENV=SIMULATE` で
    crypto order を送ると moomoo SDK が `the type of environment param is wrong` を返す。
    alpha-strike は OpenD 接続前に `ValueError` で早期拒否する。

    **ペーパー検証したい場合は**：

    - **BTC ETF (`US.IBIT` / `US.FBTC` / `US.BITO`) を `asset_class=US` で発注**（推奨）
    - `MOOMOO_TRD_ENV=REAL` で少額（0.001 BTC ≈ $80）から開始
    - TradingView Paper Trading 内蔵を使う（alpha-strike バイパス）

JSON 例（BTC を 0.01 単位で REAL 買い、`MOOMOO_TRD_ENV=REAL` 前提）：

```json
{
  "passphrase": "<WEBHOOK_PASSPHRASE>",
  "broker": "moomoo",
  "asset_class": "CRYPTO",
  "action": "buy",
  "ticker": "CC.BTC",
  "quantity": 0.01,
  "run_mode": "live",
  "strategy_id": "btc_ema_sma_trail40_v1"
}
```

> **前提**:
> - moomoo crypto は 24/7 取引（市場クローズの概念なし）
> - 米国居住者制限あり（FinCEN MSB 経由）。broker 側の crypto アカウント有効化が必要
> - 銘柄コードは `CC.BTC` / `CC.ETH` / `CC.XRP` 等（`CC.` プレフィックス + 大文字シンボル）
>
> ペイロード仕様の詳細は [TradingView × alpha-strike Integration §3-1b](./tradingview-alpha-strike.md#3-1b-moomoo-crypto-btc-eth-xrp) を参照。

---

## 8. E2E 動作確認

### 8-1. 全段の疎通チェック

```bash
# Mac から外部疎通（401 = passphrase 検証層まで到達）
curl -i -X POST https://strike.yourdomain.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"WRONG","broker":"moomoo","asset_class":"US","action":"buy","ticker":"US.AAPL","quantity":1,"run_mode":"paper"}'
# → HTTP 401 (WAF rule が一時 OFF の場合)
# → HTTP 403 (WAF rule が ON で自宅 IP は遮断される場合 = 正常)
```

### 8-2. SIMULATE 着弾の確認

TradingView alert が発火したら、VM 側で：

```bash
ssh oracle-strike
sudo journalctl -u alpha-strike -n 50 --no-pager | grep -E "Webhook受信|注文成功|34\.212\.75\.30|52\.32\.178\.7"
# → Webhook受信ログ + 注文成功ログ + TradingView IP が記録されていれば成功

# 口座状態確認スクリプトを取得して実行
curl -fsSL https://raw.githubusercontent.com/alforge-labs/alpha-strike/main/scripts/show_simulate_status.py \
  -o /tmp/show_simulate_status.py
/opt/alpha-strike/.venv/bin/python /tmp/show_simulate_status.py
# → pending_orders に発注内容が表示される
```

### 8-3. テスト発注の取消

```bash
curl -fsSL https://raw.githubusercontent.com/alforge-labs/alpha-strike/main/scripts/cleanup_simulate_orders.py \
  -o /tmp/cleanup_simulate_orders.py
/opt/alpha-strike/.venv/bin/python /tmp/cleanup_simulate_orders.py
# → pending_orders=0 に戻る
```

---

## 9. シークレット管理

### 9-1. WEBHOOK_PASSPHRASE のローテーション

passphrase を変更する際は **3 箇所すべて同期** が必要：

| 場所 | 更新方法 |
|---|---|
| **1Password** | 該当アイテムの `WEBHOOK_PASSPHRASE` フィールドを更新 |
| **VM `.env`** | `ssh oracle-strike` → `sudo sed -i "s\|^WEBHOOK_PASSPHRASE=.*\|WEBHOOK_PASSPHRASE=<新値>\|" /etc/alpha-strike/.env` → `sudo systemctl restart alpha-strike` |
| **TradingView Message JSON** | 該当 alert を Edit → Message 欄の `passphrase` を新値に → Save → Restart |

> **ハマりポイント**: 1Password と TradingView だけ更新し VM `.env` を忘れると `401 Unauthorized` で alert が届きません。`.env` は systemd 起動時にしか読まれないので `restart` も必須です。

### 9-2. 1Password CLI でのシークレット取得

```bash
# Mac から（OP_SERVICE_ACCOUNT_TOKEN または op signin 済み前提）
op item get "alpha-strike" --vault AlphaTrade --fields WEBHOOK_PASSPHRASE --reveal
```

---

## 10. 運用ルール

### 10-1. 日次（米国市場引け後）

- [ ] `scripts/show_simulate_status.py --json --days 1 | jq '.recent_orders'` で当日約定を確認
- [ ] event_logger JSONL を別ディレクトリにバックアップ（後日 alpha-forge との pnl 突合に利用）
- [ ] ntfy 通知履歴を確認、CRIT が来ていれば調査

### 10-2. 週次（日曜深夜）

- [ ] `scripts/run_apt_maintenance.sh` の実行結果を確認
- [ ] OpenD のメモリリーク兆候を確認（`systemctl status moomoo-opend | grep Memory`）
- [ ] `pending_orders` の長期残存がないか確認

### 10-3. インシデント対応

| 症状 | 一次対応 |
|---|---|
| **異常発注の検知（最緊急）** | **kill switch**: `echo "理由" \| sudo tee /etc/alpha-strike/MAINTENANCE` で即時 503 化（restart 不要）→ `cleanup_simulate_orders.py` で取消 → 原因究明後に `sudo rm /etc/alpha-strike/MAINTENANCE` で復旧 |
| Webhook 502 連発 | `systemctl status alpha-strike moomoo-opend` → 必要なら `systemctl restart alpha-strike` |
| OpenD 接続切れ | `systemctl restart moomoo-opend` → デバイストークン期限切れなら Mac で再認証 → rsync |

#### Kill switch（受付停止モード）の詳細

異常発注を検知した際の **第一手**。サービスを止めずに `/webhook` のみ即時 503 を返す状態にできる（alpha-strike v0.4.0+）。TradingView 側も 5xx 連続で alert を自動 disable してくれる。

| 起動方法 | 切替 | 用途 |
|---|---|---|
| ファイルフラグ `/etc/alpha-strike/MAINTENANCE` | restart 不要・即時 | **緊急時の主要手段**。ファイル内容が 503 detail に含まれる |
| 環境変数 `MAINTENANCE_MODE=1` | `.env` + restart | 計画停止用、systemd 起動時から固定したい場合 |

```bash
# 停止
echo "ticker AAPL runaway: investigating" | sudo tee /etc/alpha-strike/MAINTENANCE

# 確認（自宅 IP からの POST が 503 になる、WAF rule を一時 OFF にして検証）
# ※ body の必須フィールド（broker/asset_class/action/ticker 等）が欠けると、
#   kill switch 判定より先にリクエストボディ検証（422）が走るため、完全なペイロードで検証する。
curl -i https://strike.yourdomain.com/webhook \
  -X POST -H "Content-Type: application/json" \
  -d '{"passphrase":"x","broker":"moomoo","asset_class":"US","action":"buy","ticker":"US.AAPL","quantity":1,"run_mode":"paper"}'
# → 503 maintenance: ticker AAPL runaway: investigating

# 解除
sudo rm /etc/alpha-strike/MAINTENANCE
```

> **注**: maintenance mode 中も `/health` は 200 を返す（外部ヘルスチェック / Cloudflare Tunnel 維持のため）。`passphrase` 検証より **前** に kill switch が判定されるので、maintenance 中の不正 passphrase 試行はログに残らない。

### 10-4. 中止判断

以下のいずれかが発生した場合は TradingView アラートを **全停止** し原因究明：

- 同一ティッカーの想定外連続発注（5 回 / 5 分以上）
- `pending_orders` が 24 時間以上滞留
- `total_assets` が想定外の急減（戦略の最大ドローダウンを超える）
- Cloudflare WAF / Access から原因不明の `403` 連発

---

## 11. LIVE 移行への前提（参考）

ペーパートレードで **3 ヶ月以上の安定稼働 + alpha-forge バックテストとの pnl 乖離が 5% 以内** を確認した後に LIVE 移行を検討。LIVE では以下が追加で必要：

- moomoo 本番口座での `MOOMOO_TRADE_ENV=REAL` 切替
- 二段階認証手順の整備
- 想定外発注の即時遮断機構（kill switch）
- 月次の損益レポート自動化（alpha-forge journal 側）

---

## 12. ライブ実績の可視化（alpha-visualizer）

alpha-strike が記録したイベントログ（JSONL）は、alpha-forge で取り込み、[alpha-visualizer](../alpha-visualizer/index.md)（OSS・Apache-2.0）の Live 画面でエクイティカーブとして可視化できます。バックテストとの乖離（diff）も同じ画面で確認できるため、§10 の運用ルール（pnl 乖離チェック）にもそのまま使えます。

### 12-1. 推奨: `alpha-forge live refresh` で一括更新

sync-events → data update → replay の 3 ステップは [`alpha-forge live refresh`](../cli-reference/live.md#alpha-forge-live-refresh) にまとめて実行できます。alpha-visualizer の Live 画面にある「ライブデータを更新」ボタンも内部でこのコマンドを呼び出します。

```bash
alpha-forge live refresh

pip install alpha-visualizer
alpha-vis serve
```

事前に `forge.yaml` の `live.replay` セクション（`portfolio_id` / `combine_strategies` / `initial_capital` 等）を設定しておく必要があります。未設定の場合、コマンドはステップを 1 つも実行せずにエラー終了します。設定キーの詳細は [`alpha-forge live replay`](../cli-reference/live.md#alpha-forge-live-replay) を参照してください。

!!! warning "`initial_capital` は実口座の基準資本に合わせる"
    `live.replay.initial_capital` を実口座の資本に合わせないと、equity のリターン率が基準資本の比率でずれます。バックテストの既定（100,000）のまま実口座が 1,000,000 だと、リターン率が 10 倍ずれます。

### 12-2. 個別に実行したい場合（従来の3コマンド）

`remote.enabled: false` の環境（sync-events を使わない）や、特定のステップだけをやり直したい場合は、従来どおり個別コマンドを実行できます。

```bash
# 1. VM 上のイベント JSONL をローカルの forge プロジェクトへ同期
alpha-forge live sync-events

# 2. イベントを取り込んでライブ実績を生成
alpha-forge live import-events <strategy_id>          # 戦略単位
alpha-forge live replay <portfolio_id> \
  --combine-strategies <id1>,<id2>                    # combine ポートフォリオ

# 3. alpha-visualizer の Live 画面で表示
pip install alpha-visualizer
alpha-vis serve
```

各画面の詳細は [alpha-visualizer の機能](../alpha-visualizer/features.md)を参照。

---

## 関連ドキュメント

- [TradingView と alpha-strike の連携（ペイロード仕様）](./tradingview-alpha-strike.md)
- [TradingView への Pine Script 反映](./tradingview-pine-integration.md)
- [エンドツーエンド戦略開発ワークフロー](./end-to-end-workflow.md)
- [alpha-visualizer の機能（Live 画面）](../alpha-visualizer/features.md)

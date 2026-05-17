# alpha-strike Setup Guide (Paper Trading Production)

End-to-end procedure to deploy alpha-strike on **Oracle Cloud Always Free + Cloudflare Tunnel**, receive TradingView webhooks, and place orders into **moomoo SIMULATE / OANDA PRACTICE accounts**.

> **Goal**: Establish a zero-cost infrastructure path from TradingView alerts to broker paper-trading accounts that is independent of home IP changes (DHCP), works with TradingView Essential plan or above, and runs on Oracle Cloud Always Free.
>
> **Hardware**: Verified to run on E2.1.Micro (1/8 OCPU, 1GB RAM). Memory usage stays around 600 MB / 954 MB.

---

## Architecture

```
TradingView (Pine strategy / Alert)
       │  HTTPS Webhook
       ▼
Cloudflare WAF Custom Rule (TradingView IP allowlist)
       │
Cloudflare Tunnel (cloudflared)
       │  outbound only (NSG Ingress = 0 rules)
       ▼
Oracle Cloud VM "alpha-strike-01" (E2.1.Micro)
  ├─ alpha-strike (FastAPI, localhost:8080)
  └─ moomoo OpenD  (localhost:11111)
       │
       ▼
moomoo SIMULATE account (US / HK stocks, paper trading)
```

---

## 1. Prerequisites

- [ ] Oracle Cloud Infrastructure account (Always Free tier)
- [ ] Cloudflare account (Free plan)
- [ ] A custom domain (this guide uses `alforgelabs.com` as example)
- [ ] moomoo securities account with OpenAPI-capable SIMULATE account
- [ ] **TradingView account on Essential plan or above** (Webhook URL supported)
- [ ] 1Password or equivalent secret manager
- [ ] Local machine (Mac/Linux recommended) with `ssh`, `curl`, `git`

---

## 2. VM Provisioning (Oracle Cloud E2.1.Micro)

### 2-1. Create instance

| Item | Value |
|---|---|
| Image | `Canonical Ubuntu 24.04` |
| Shape | `VM.Standard.E2.1.Micro` (Always Free) |
| Public IPv4 | Ephemeral |
| SSH Public Key | Your local `~/.ssh/id_ed25519.pub` |

### 2-2. NSG (Network Security Group)

**Target state** (after Cloudflare Tunnel and Access for SSH are wired up):

| Direction | Protocol | Source | Port | Note |
|---|---|---|---|---|
| Ingress | — | — | — | **0 rules** |
| Egress | All | 0.0.0.0/0 | All | Egress-only |

During initial setup, allow SSH from your home IP temporarily; remove after Cloudflare Access for SSH is verified (§4-3).

### 2-3. OS initial setup

```bash
ssh ubuntu@<VM_PUBLIC_IP>
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl jq build-essential
```

### 2-4. Memory hardening (1 GB RAM)

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

### 2-5. Install uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
source ~/.bashrc
uv --version
```

---

## 3. Cloudflare Tunnel Setup

### 3-1. Move domain to Cloudflare nameservers

Change nameservers at your registrar to Cloudflare-provided values. Propagation can take a few hours.

```bash
dig +short NS yourdomain.com
# Expect: xxx.ns.cloudflare.com / yyy.ns.cloudflare.com
```

### 3-2. Create the Tunnel

1. Cloudflare dashboard → **Zero Trust → Networks → Tunnels → Create a tunnel**
2. Tunnel type: **Cloudflared**
3. Tunnel name: `alpha-strike-prod`
4. **Save tunnel** — a token is issued
5. On the VM, run the install command shown by Cloudflare:

```bash
sudo cloudflared service install <TOKEN>
sudo systemctl status cloudflared
```

### 3-3. Public hostname (webhook)

In the Tunnel page → **Hostname routes (Beta)** tab → **Add a hostname route**:

| Field | Value |
|---|---|
| Subdomain | `strike` |
| Domain | `yourdomain.com` |
| Type / Service | `HTTP` |
| URL / Target | `localhost:8080` |

Browse to `https://strike.yourdomain.com` — a **502 Bad Gateway** is expected because alpha-strike is not yet running (the Tunnel itself is connected).

### 3-4. Route SSH through the same Tunnel

Add another hostname route:

| Field | Value |
|---|---|
| Subdomain | `ssh` |
| Domain | `yourdomain.com` |
| Type / Service | `SSH` |
| URL / Target | `localhost:22` |

Local `~/.ssh/config`:

```ssh-config
Host oracle-strike
  HostName ssh.yourdomain.com
  User ubuntu
  ProxyCommand cloudflared access ssh --hostname %h
  IdentityFile ~/.ssh/id_ed25519
```

Now `ssh oracle-strike` works regardless of your home IP changes.

### 3-5. Drop NSG Ingress to zero

Once Cloudflare Access for SSH is verified, delete all OCI NSG Ingress rules.

---

## 4. Cloudflare WAF Custom Rule (TradingView IP allowlist)

TradingView publishes 4 official source IPv4 addresses. Only allow `/webhook` from those IPs.

### 4-1. Create the rule

1. Cloudflare dashboard → select your domain → **Security → Security rules**
2. In the **Custom rules** row click **Create rule**
3. Configure:

| Field | Value |
|---|---|
| Rule name | `Allow only TradingView IPs to /webhook` |
| Expression | (paste below in text mode) |
| Then take action | **Block** |

```
(http.host eq "strike.yourdomain.com" and http.request.uri.path eq "/webhook" and not ip.src in {52.89.214.238 34.212.75.30 54.218.53.128 52.32.178.7})
```

**Deploy** to apply immediately.

> **TradingView source IPs** are published in the [official Help Center](https://www.tradingview.com/support/solutions/43000529348-about-webhooks/). Re-check this page if you change the rule.
>
> **Defense in depth**: even with the WAF IP allowlist, the `passphrase` check on the request body is mandatory.

### 4-2. Verify

```bash
# A POST from a non-TradingView IP should be blocked
curl -i -X POST https://strike.yourdomain.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"dummy"}'
# → HTTP/2 403 + Cloudflare block page

# /health is unaffected because the rule targets /webhook only
curl https://strike.yourdomain.com/health
# → {"status":"ok"} (after alpha-strike is running)
```

---

## 5. moomoo OpenD Setup

### 5-1. Install

Download `moomoo_OpenD_*_Ubuntu18.04.tar.gz` from the [moomoo OpenAPI page](https://www.moomoo.com/download/OpenAPI), then transfer to the VM:

```bash
# From Mac
scp ~/Downloads/moomoo_OpenD_*.tar.gz oracle-strike:~/
# On the VM
ssh oracle-strike
mkdir -p ~/moomoo_OpenD && tar xzf moomoo_OpenD_*.tar.gz -C ~/moomoo_OpenD --strip-components=1
```

### 5-2. Generate MD5 of trading password

```bash
# On Mac (input is hidden)
read -s -p "moomoo trade password: " PW && echo -n "$PW" | md5
unset PW
```

Use the resulting 32-char hex as `MOOMOO_TRADE_PWD_MD5` below.

### 5-3. Device token (headless VM workaround)

OpenD's initial login requires SMS + CAPTCHA which is not feasible on a headless VM. Authenticate **on a Mac** first and rsync `~/.com.moomoo.OpenD/F3CNN/` to the VM:

```bash
# After SMS-authenticating moomoo OpenD on the Mac
rsync -avz ~/.com.moomoo.OpenD/F3CNN/ oracle-strike:~/.com.moomoo.OpenD/F3CNN/
```

### 5-4. Environment file

```bash
ssh oracle-strike
sudo tee /etc/moomoo_OpenD.env > /dev/null <<'EOF'
MOOMOO_LOGIN_ACCOUNT=your-moomoo-account
EOF
sudo chmod 600 /etc/moomoo_OpenD.env
```

### 5-5. systemd unit

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
```

> **`-login_by_remember=1`** lets OpenD log in via the device token transferred in §5-3, avoiding repeated SMS/CAPTCHA prompts.

---

## 6. alpha-strike Deployment

### 6-1. Clone and install

```bash
ssh oracle-strike
git clone https://github.com/your-org/alpha-strike.git ~/dev/alpha-strike
cd ~/dev/alpha-strike
uv sync
```

### 6-2. Create `.env`

```bash
tee ~/dev/alpha-strike/.env > /dev/null <<'EOF'
# Required
WEBHOOK_PASSPHRASE=<random string, 32+ chars>

# moomoo
MOOMOO_HOST=127.0.0.1
MOOMOO_PORT=11111
MOOMOO_TRADE_PWD_MD5=<32-char MD5 hex from §5-2>
MOOMOO_TRADE_ENV=SIMULATE

# OANDA (optional)
# OANDA_API_KEY=<your-token>
# OANDA_ACCOUNT_ID=<your-account-id>
# OANDA_ENV=PRACTICE
EOF
chmod 600 ~/dev/alpha-strike/.env
```

Also store the `WEBHOOK_PASSPHRASE` in 1Password — you will paste the same value into TradingView's alert Message JSON later.

### 6-3. systemd unit

```bash
sudo tee /etc/systemd/system/alpha-strike.service > /dev/null <<'EOF'
[Unit]
Description=alpha-strike webhook server
After=moomoo-opend.service network-online.target
Wants=network-online.target

[Service]
Type=simple
User=ubuntu
WorkingDirectory=/home/ubuntu/dev/alpha-strike
EnvironmentFile=/home/ubuntu/dev/alpha-strike/.env
ExecStart=/home/ubuntu/dev/alpha-strike/.venv/bin/python main.py
Restart=always
RestartSec=5
OOMScoreAdjust=-500

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now alpha-strike
```

### 6-4. Smoke test (internal)

```bash
curl http://127.0.0.1:8080/health
# → {"status":"ok"}
```

### 6-5. Memory / service monitoring

Add `scripts/check_memory.sh` (in the alpha-strike repo) to cron:

```bash
crontab -e
# Append:
*/5 * * * * /home/ubuntu/dev/alpha-strike/scripts/check_memory.sh
```

Configure `~/.ntfy.env` with `NTFY_TOPIC=...` to receive iPhone push notifications when memory exceeds thresholds (85% / 95%) via [ntfy.sh](https://ntfy.sh).

---

## 7. TradingView Alert

### 7-1. Create the alert

1. Open the target chart (e.g., `BINANCE:BTCUSDT` for testing, or your actual instrument)
2. Click the bell icon → **Create Alert**
3. **Condition**: pick your strategy / indicator
4. **Notifications** tab:
   - ✅ **Webhook URL** with `https://strike.yourdomain.com/webhook`
5. **Message** field — paste the JSON below (replace `<WEBHOOK_PASSPHRASE>` with the actual `.env` value):

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

6. **Create**

### 7-2. Always-fires test condition (works during market close)

Use a 24/7 crypto chart with an always-true condition to fire within seconds:

| Field | Value |
|---|---|
| Symbol | `BINANCE:BTCUSDT` |
| Condition Type | **`Greater Than`** |
| Source | `Price (Close)` |
| Value | `1` |
| Frequency | `Once Per Bar` |

> **Why not `Crossing Up 1`?** BTC is always above 1, so there is no "crossing" event to trigger on. `Greater Than 1` evaluates true on every bar close, guaranteeing a fire.

The `ticker:"US.AAPL"` in the JSON is **independent** of the chart symbol that fires the alert.

### 7-3. Running CRYPTO strategies

In addition to US / HK equities, moomoo offers crypto (BTC / ETH / XRP, etc.) as a destination. alpha-strike accepts `asset_class="CRYPTO"` and routes through `OpenSecTradeContext(filter_trdmarket=TrdMarket.CRYPTO)` internally.

Sample JSON (paper-buy 0.01 BTC):

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

> **Notes**:
> - moomoo crypto trades 24/7 (no market close)
> - US-residency restriction applies (FinCEN MSB). Even `run_mode=paper` requires the broker-side crypto account to be enabled
> - Symbols are `CC.BTC` / `CC.ETH` / `CC.XRP` etc. (`CC.` prefix + uppercase symbol)
>
> See [TradingView × alpha-strike Integration §3-1b](./tradingview-alpha-strike.md#3-1b-moomoo-crypto-btc-eth-xrp) for the full payload specification.

---

## 8. End-to-end Verification

### 8-1. External reachability

```bash
# From Mac (expect 401 if WAF is off, 403 if WAF is on)
curl -i -X POST https://strike.yourdomain.com/webhook \
  -H "Content-Type: application/json" \
  -d '{"passphrase":"WRONG","broker":"moomoo","asset_class":"US","action":"buy","ticker":"US.AAPL","quantity":1,"run_mode":"paper"}'
```

### 8-2. SIMULATE order arrival

After the TradingView alert fires:

```bash
ssh oracle-strike
sudo journalctl -u alpha-strike -n 50 --no-pager | grep -E "Webhook受信|order|34\.212\.75\.30|52\.32\.178\.7"

cd ~/dev/alpha-strike
.venv/bin/python scripts/show_simulate_status.py
# → pending_orders should list the test order
```

### 8-3. Cancel the test order

```bash
.venv/bin/python scripts/cleanup_simulate_orders.py
# → pending_orders=0
```

---

## 9. Secret Rotation

When rotating `WEBHOOK_PASSPHRASE`, **all three locations must be synced**:

| Location | How |
|---|---|
| **1Password** | Update the field in the `alpha-strike` item |
| **VM `.env`** | `ssh oracle-strike` → `sudo sed -i "s\|^WEBHOOK_PASSPHRASE=.*\|WEBHOOK_PASSPHRASE=<new>\|" ~/dev/alpha-strike/.env` → `sudo systemctl restart alpha-strike` |
| **TradingView Message JSON** | Edit the alert → update `passphrase` → Save → Restart |

> **Common pitfall**: forgetting to update the VM `.env` will produce `401 Unauthorized` on every alert. `.env` is read only at systemd start, so `restart` is required.

---

## 10. Operational Routine

### 10-1. Daily (after US market close)

- [ ] `scripts/show_simulate_status.py --json --days 1 | jq '.recent_orders'` — verify the day's fills
- [ ] Backup `event_logger` JSONL for later pnl reconciliation against alpha-forge

### 10-2. Weekly (Sunday night)

- [ ] Review `scripts/run_apt_maintenance.sh` results
- [ ] Check OpenD memory (`systemctl status moomoo-opend | grep Memory`)
- [ ] Confirm there are no long-lived `pending_orders`

### 10-3. Incident response

| Symptom | First action |
|---|---|
| Webhook 502 floods | `systemctl status alpha-strike moomoo-opend` → `systemctl restart alpha-strike` |
| OpenD disconnect | `systemctl restart moomoo-opend` → if device token expired, re-auth on Mac and rsync |
| Unexpected order pattern | Pause TradingView alert → `cleanup_simulate_orders.py` → root cause |

### 10-4. Abort criteria

Stop the integration immediately if:

- Same ticker fires more than 5 times in 5 minutes
- `pending_orders` linger beyond 24 hours
- `total_assets` drops beyond your strategy's expected max drawdown
- Cloudflare WAF / Access returns unexplained `403`s

---

## 11. Toward LIVE Migration (reference)

Consider LIVE migration only after **3+ months of stable paper trading** with **pnl divergence from alpha-forge backtest below 5%**. LIVE additionally requires:

- moomoo production account with `MOOMOO_TRADE_ENV=REAL`
- 2FA workflow documentation
- Kill switch for unexpected orders
- Monthly P&L automation on alpha-forge journal side

---

## Related Documents

- [TradingView × alpha-strike Integration (payload spec)](./tradingview-alpha-strike.md)
- [Bringing Pine Scripts into TradingView](./tradingview-pine-integration.md)
- [End-to-end Strategy Development Workflow](./end-to-end-workflow.md)

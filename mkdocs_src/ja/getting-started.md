# はじめに

AlphaForge CLI のインストールから最初のバックテスト結果を読むまでをまとめた入門ガイドです。

- **Whop 登録なしで完結する 約 10 分の Trial 体験**を冒頭に配置しています。インストール後すぐに Trial プランとして利用できます。
- その後ろに、**詳細なインストール手順・有料プラン購入後の認証・アンインストール・トラブルシューティング**を載せています。

!!! tip "AI エージェントから使い始める"
    Claude Code / Codex / Cursor などの AI エージェントと組み合わせて使いたい場合は、[エージェントクイックスタート](ai-agents/quickstart.md) から始められます。AlphaForge のインストール自体は本ページの手順が前提となるため、先に下のステップでインストールを済ませてください。

!!! info "用語集（このページで使う言葉）"
    | 用語 | 意味 |
    |---|---|
    | **AlphaForge** | 戦略 JSON をもとにバックテスト・パラメータ最適化・Pine Script 出力を行う CLI 製品（本ツール本体） |
    | **`alpha-forge` コマンド** | AlphaForge の CLI 実行ファイル名。v0.5.0 で `forge` から `alpha-forge` にリネーム |
    | **Trial プラン** | インストール直後にそのまま使える試用モード。**メール登録もアカウント作成も一切不要**。データは 2023-12-31 までに制限される代わりに、Pine Script エクスポート以外のほぼ全機能を試せる |
    | **有料プラン** | Lifetime / Annual / Monthly のいずれか。データ日付制限と最適化トライアル数の上限が解除され、Pine Script エクスポートも有効化される |
    | **Whop** | AlphaForge が決済とライセンス認証に使っている外部プラットフォーム（whop.com）。有料プラン購入時のみアカウントを作る必要がある（Google / GitHub サインインも可） |
    | **OAuth 2.0 PKCE 認証** | 有料プラン購入後に `alpha-forge system auth login` を実行するとブラウザが開き、Whop アカウントでログインしてアクセストークンを `~/.config/forge/credentials.json` に保存する仕組み |

---

## Trial プランで 約 10 分の最初のバックテスト

!!! info "Trial プランで試せる範囲（Whop 登録不要）"
    - バックテスト・最適化 ✅（データ上限: **2023-12-31** まで）
    - 最適化トライアル: **50 回**まで
    - Pine Script エクスポート ❌（有料プランが必要）

    上限の詳細は [Trial 制限](guides/trial-limits.md) を参照してください。

!!! tip "有料プランから始めたい場合"
    最初から有料プラン（Lifetime / Annual / Monthly のいずれか）で利用したい場合は [購入ページ](https://whop.com/alforge-labs/alphaforge/) から手続きしてください。Trial プランから後で有料プランへアップグレードすることも可能です。プラン別の機能差は [Trial 制限](guides/trial-limits.md) を参照してください。

### ステップ 1 — インストール（約 2 分）

=== "Windows"

    PowerShell で実行します（管理者権限不要）。

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    インストール後、**開いているターミナルをすべて閉じて、新しいターミナルを開いてから**次に進んでください（起動済みの Windows Terminal の新しいタブ／ウィンドウには PATH の変更が反映されません）。

=== "macOS / Linux"

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    インストール後、**新しいターミナルを開いてから**次に進んでください。

インストールを確認します。

```bash
alpha-forge --version
```

```
AlphaForge, version 0.10.0
Check for updates: alpha-forge self version
```

`AlphaForge, version <X.Y.Z>` のように表示されれば完了です。手動インストールやインストール先のカスタマイズは、本ページ後半の「詳細インストール」セクションを参照してください。

!!! note "最新版バイナリの直接ダウンロード"
    インストーラを使わずバイナリを直接配置したい場合は、[GitHub Releases（最新版）](https://github.com/alforge-labs/alforge-labs.github.io/releases/latest) から各プラットフォーム向け（`alpha-forge-macos-arm64` / `alpha-forge-linux-x64` / `alpha-forge-windows-x64.exe` 等）をダウンロードできます。詳細は本ページ「詳細インストール → 手動インストール」を参照してください。

!!! info "Trial プランは Whop 登録なしでそのまま使えます"
    インストール完了直後から、`alpha-forge --version` も含めて Trial プランとして CLI を実行できます。Whop OAuth 認証は **有料プラン（Lifetime / Annual / Monthly）を購入したときだけ**必要で、Trial 体験には不要です。認証の手順は本ページ後半の「有料プラン購入後の認証」セクションを参照してください。

### ステップ 2 — 作業ディレクトリを初期化して戦略ファイルを用意する（約 2 分）

`quickstart/` ディレクトリを作成して `alpha-forge system init` で初期化します。`forge.yaml`（戦略・データ・結果の保存先設定）と `data/` 等のサブディレクトリが配置されます。

```bash
mkdir quickstart && cd quickstart
alpha-forge system init
```

!!! tip "v0.12.0 以降: ディレクトリ名を指定して 1 コマンドで初期化"
    v0.12.0 以降は `alpha-forge system init quickstart && cd quickstart` のようにディレクトリ名を指定でき、作成と初期化が 1 コマンドで完了します。あわせて、ホームディレクトリ直下など意図しない場所への誤展開には確認プロンプトが表示されるようになりました（CI 等の非対話実行では `--yes` を指定）。

!!! info "`alpha-forge system init` を必ず実行してください"
    `forge.yaml` が無いとデフォルト設定にフォールバックして `data/` を自動生成し、戦略・データ未登録の場合は友好的なエラーメッセージで停止します（raw な `FileNotFoundError` トレースは出ません）。`forge.yaml` で戦略の DB 登録先・データ保存先・結果ファイル出力先を明示しておくと意図しない場所への展開を避けられるため、クイックスタートでは先に実行しておくことを推奨します。`--force` は不要です。

!!! note "初回のみ EULA 同意プロンプト `[y/n]` が表示されます"
    最初に主要コマンド（上記 `alpha-forge system init` など）を実行すると、初回だけエンドユーザー使用許諾契約（EULA）の要約が表示され、`[y/n]` の同意プロンプトが出ます。**`y` を入力**すると同意状態が `~/.config/forge/` に記録され、次回以降は表示されません。

    CI・パイプ・エージェントなどの**非対話環境**では `y` を入力できず `Aborted!` で停止します。その場合は環境変数 `FORGE_ACCEPT_EULA=1`（`true` / `yes` / `on` も可）を設定すると、初回 EULA に自動同意して続行できます（対応バージョン以降）。

`sma_cross.json` という名前で以下を保存します（`strategy_id` の `_qs` 接尾辞は quickstart の目印で、任意の ID に変更して構いません）。

```json
{
  "strategy_id": "sma_cross_qs",
  "name": "SMA Crossover Quickstart",
  "version": "1.0.0",
  "description": "SMA(10)/SMA(50) ゴールデンクロス戦略（クイックスタート用）",
  "target_symbols": ["SPY"],
  "asset_type": "stock",
  "timeframe": "1d",
  "indicators": [
    { "id": "sma_fast", "type": "SMA", "params": { "length": 10 }, "source": "close" },
    { "id": "sma_slow", "type": "SMA", "params": { "length": 50 }, "source": "close" }
  ],
  "entry_conditions": {
    "long": {
      "logic": "AND",
      "conditions": [{ "left": "sma_fast", "op": ">", "right": "sma_slow" }]
    }
  },
  "exit_conditions": {
    "long": {
      "logic": "AND",
      "conditions": [{ "left": "sma_fast", "op": "<", "right": "sma_slow" }]
    }
  },
  "risk_management": {
    "position_size_pct": 10.0,
    "position_sizing_method": "fixed",
    "max_positions": 1,
    "leverage": 1.0
  }
}
```

### ステップ 2.5 — ヒストリカルデータを取得する（約 1 分・必須）

次のバックテストに必要なヒストリカルデータを取得します。`backtest run` は対象シンボルのデータを自動取得しないため、**このステップを先に実行しないと次のバックテストが `❌ データが見つかりません: SPY (1d)` で失敗します**。

```bash
alpha-forge data fetch SPY --period 10y
```

```
データの取得を開始します: SPY (period=10y, interval=1d)
SPY のデータを取得し保存しました (N lines)
```

データは `data/historical/SPY_1d.parquet` に保存されます。`yfinance` 等のオンライン取得に失敗するケース（ネットワーク不調・レート制限）はこのステップで切り分けられます。

### ステップ 3 — 戦略を登録してバックテストを実行する（約 2 分）

ステップ 2 で書いた `sma_cross.json` を AlphaForge に登録します（戦略 DB に保存）。

```bash
alpha-forge strategy save sma_cross.json
```

```
✅ カスタム戦略 'sma_cross_qs' を登録しました
```

!!! tip "JSON ファイルから直接バックテスト（`--strategy-file`）"
    DB 登録を省いて JSON を直接指定したい場合は `--strategy-file sma_cross.json` を使えます。クイックスタートでは登録版を採用しますが、編集→即実行を繰り返したい場合に便利です。

Trial プランの範囲（〜2023-12-31）でバックテストを実行します。

```bash
alpha-forge backtest run SPY \
  --strategy sma_cross_qs \
  --start 2019-01-01 \
  --end 2023-12-31
```

!!! note "事前にヒストリカルデータが必要です"
    `backtest run` は対象シンボルのデータを自動取得しません。ステップ 2.5 で `alpha-forge data fetch SPY --period 10y` を済ませていない場合は `❌ データが見つかりません: SPY (1d)` で停止します。停止したらステップ 2.5 を実行してから再試行してください。

### ステップ 4 — 結果を読む（約 3 分）

実行が完了すると以下のような出力が表示されます。

!!! warning "**手元の数値は以下と一致しません**（サンプル出力）"
    以下は **alpha-forge v0.4.0** で **yfinance 経由 SPY 1d データ（2026-05-15 取得時点）** を
    使って計測した実測値です。バックテストエンジンや内部メトリクスは継続的に改善されており、
    yfinance 側のデータ補正・配当再投資ロジックも更新されるため、**docs に書かれた数値は
    バージョンが上がるたび変動します**（finding F-103b）。読者は「自分の手元でも同じ
    `4.74%` になる」とは想定せず、**ラベル構造とオーダー感**だけ参考にしてください。
    再現性のある回帰テストが必要な場合は `alpha-forge backtest run --json` で構造化出力を取得し、
    自前のスナップショットと比較してください。

```
バックテストを実行中: SPY x sma_cross_qs  (2019-01-01 → 2023-12-29, 1258 bars)
⚠️  バックテスト完了  信号品質スコア: 0.48/1.0 （0.4–0.7 は要注意・追加検証推奨）
⚠️  警告: 取引数が不足しています (trades=15, 最低30推奨)
    → 取引数 30 件未満は統計的に偶然の影響を受けやすく、最適化や WFT で
      pre_filter 落ちする可能性があります。データ期間を広げる
      (`--start` で過去にさかのぼる) ことを推奨します。
総リターン: 4.74%  CAGR: 0.93%
SR: 0.85  Sortino: -2.86  Calmar: 0.52
MDD: 1.79%  期間: 71日  回復: 154日
PF: 4.01  Win%: 35.7%  avg勝: 10.39%  avg負: -1.72%
Kelly: 0.25  Payoff: 6.04  期待値: 2.60%/回  GPR: 0.31  Ulcer: 0.0079  回復係数: 2.65
取引数: 15  平均保有: 56.8日(57bar)  最大: 218.0日(218bar)  連勝: 4  連敗: 6
勝率CI(90%): 17.8% - 54.8%
📊 チャートは `alpha-vis serve` で確認できます（結果ID: sma_cross_qs_report）
DB 保存: run_id=<uuid>
```

主要指標の見方は次のとおりです。指標の詳細な目安は本ページ後半の「結果の見方（詳細）」セクション、全指標一覧は [CLI リファレンス](cli-reference/index.md) を参照してください。

| CLI ラベル | 一般名 | 読み方 |
|---|---|---|
| **CAGR** | CAGR (年率リターン) | プラスでも S&P 500 平均（約 10%）に届かなければ戦略の付加価値は限定的。 |
| **SR** | Sharpe Ratio | リスク調整後リターン。**1.0 以上**が目安。 |
| **MDD** | Max Drawdown | 過去最大の資産の落ち込み。20% 以内なら運用継続しやすい水準。 |
| **Win%** | Win Rate | 勝ちトレードの割合。トレンドフォローでは 40〜60% が標準。 |
| **PF** | Profit Factor | 総利益 ÷ 総損失。**1.5 以上**で良好。 |
| **取引数** | Trades | 期間中のトレード数。統計的有意性のため **30 件以上**が望ましい。15 件のように不足しているとサンプル出力のように警告が出る。 |

!!! note "サンプル出力に出てくる追加指標（CLI で表示される他の値）"
    上の主要 6 指標以外に、CLI は補助的な指標も併せて表示します。意味は以下のとおり:

    | CLI ラベル | 一般名 | 読み方 |
    |---|---|---|
    | **信号品質スコア** | Signal Quality Score | 0.0–1.0 のスコア。alpha-forge が取引シグナルの統計的妥当性を内部評価した値。**≥0.7 で信頼水準**、**0.4–0.7 は要注意**、**<0.4 は参考値扱い**。 |
    | **Sortino** | Sortino Ratio | 下方リスクのみで割った Sharpe 派生。同じ Sharpe でも Sortino が高いほど「下げ局面でリスクが小さい」。マイナス値は下方リスクに対して負のリターン。 |
    | **Calmar** | Calmar Ratio | `CAGR ÷ |MDD|`。年率リターンを最大ドローダウンで正規化。**0.5 以上が許容、1.0 超で優秀**。 |
    | **期間 / 回復** | Drawdown duration / Recovery | MDD のピークから底までの日数 / 底からピーク再到達までの日数。回復が長いほど資金拘束期間が伸びる。 |
    | **avg勝 / avg負** | Avg Win / Avg Loss | 平均利益（勝ちトレードの平均%）と平均損失（負けトレードの平均%）。`avg勝 ÷ |avg負|` がペイオフ比で、**2.0 以上**ならトレンドフォロー型として健全。 |
    | **平均保有 / 最大** | Avg Hold / Max Hold | 平均ポジション保有日数とその最大値。timeframe (1d 等) に応じてオーダーが変わるので、**戦略想定の保有期間と乖離していないか**を確認。 |
    | **Kelly / Payoff / 期待値 / GPR / Ulcer / 回復係数** | Kelly Criterion / Payoff Ratio / Expectancy / Gain-Pain Ratio / Ulcer Index / Recovery Factor | トレード品質の拡張指標。Kelly は理論最適ポジション比率（負値はエッジなし）、Payoff は `avg勝 ÷ |avg負|`、期待値は 1 トレードあたり期待リターン、回復係数は `総リターン ÷ |MDD|`。分母が定義できない場合は N/A 表示。詳細は [CLI リファレンス](cli-reference/backtest.md) 参照。 |
    | **連勝 / 連敗** | Max Consecutive Wins / Losses | 連続勝ち / 連続負けの最大長。連敗が長いほど運用中の心理負荷が高い。 |
    | **勝率CI(90%)** | Win Rate CI (90%) | 勝率の 90% 信頼区間。CI 幅が広い（例: `17.8% – 54.8%`）ほど取引数が少なく、本当の勝率を絞り込めていない証拠。**取引数 30 件以上**で CI 幅が縮む。 |

### 次のステップ：可視化（任意） {#next-steps-visualize}

出力末尾の `📊 チャートは alpha-vis serve で確認できます` は、独立した OSS パッケージ [alpha-visualizer](alpha-visualizer/installation.md) への誘導です。バックテスト結果を **ブラウザで Equity / Drawdown / 取引履歴・指標比較** として確認できます。

インストール経路は 3 通り（[詳細](alpha-visualizer/installation.md)）:

```bash
uv tool install alpha-visualizer   # uv tool（CLI として独立インストール、推奨）
pip install alpha-visualizer       # pip（通常の Python 環境にインストール）
pip install -i https://pypi.org/simple alpha-visualizer  # PyPI から明示取得
```

インストール後、`quickstart/` ディレクトリで `alpha-vis serve` を実行するとブラウザ（既定: <http://127.0.0.1:8000>）が開きます。

```bash
cd quickstart
alpha-vis serve
```

!!! note "`alpha-vis` が認識されない場合"
    macOS には標準コマンド `/usr/bin/vis` があり、また旧バージョン（〜v0.2.x）では `vis` というコマンド名でした。v0.3.0 以降は `alpha-vis` に改名されています。`alpha-vis` 単体が認識されない場合は `~/.local/bin/alpha-vis serve`（uv tool）または `~/.local/share/uv/tools/alpha-visualizer/bin/alpha-vis serve` のように絶対パスで起動してください。

!!! tip "最適化を試したい場合は `optimizer_config` を追加する（F-003）"
    上の `sma_cross.json` は **バックテストだけ動く最小構成** で `optimizer_config` を
    省いています。`alpha-forge optimize run` をすぐ試したい場合は次のセクションを
    JSON 末尾の `}` 直前に追加してください（`risk_management` の後にカンマ + 追記）:

    ```json
    "optimizer_config": {
      "param_ranges": {
        "sma_fast.length": { "min": 5,  "max": 25, "step": 5 },
        "sma_slow.length": { "min": 20, "max": 60, "step": 5 }
      }
    }
    ```

    省略した場合は alpha-forge が内蔵デフォルト範囲 (`sma_fast.length=[5,25]` /
    `sma_slow.length=[20,60]`) を使って探索します（起動時に
    `探索パラメータ（内蔵デフォルト範囲）:` と表示されます）。明示すれば再現性が高まり、`min`/`max`/`step`
    を編集すれば探索範囲を自分で制御できます。

### ここまでできたら次のステップへ

| やりたいこと | 参照先 |
|-------------|--------|
| 自分の役割で次のページを選びたい | [目的別ユースケース](usecases/index.md) |
| パラメータを最適化したい | [optimize コマンド](cli-reference/optimize.md) |
| ウォークフォワードで過学習を検証したい | [エンドツーエンドワークフロー](guides/end-to-end-workflow.md) |
| 複合指標の戦略テンプレートを使いたい | [戦略テンプレート](templates.md) |
| TradingView と連携したい | [Pine Script 反映ガイド](guides/tradingview-pine-integration.md) |
| Trial プランの制限を確認したい | [Trial 制限](guides/trial-limits.md) |

---

## 詳細インストール

### 前提条件

- macOS 12 (Monterey) 以降 / Ubuntu 22.04 以降 / Windows 11
- インターネット接続（初回データ取得時、または有料プラン購入後の認証時）
- **Whop アカウントは Trial プランでは不要**。有料プラン（Lifetime / Annual / Monthly）を利用したい場合のみ [購入ページ](https://whop.com/alforge-labs/alphaforge/) から購入してください。

### インストール手順

=== "macOS / Linux"

    ターミナルで以下のコマンドを実行してください。インストーラーが最新バイナリ（`forge.dist` 一式）を `~/.local/share/alpha-forge/` に展開し、実行ファイル `alpha-forge` への symlink を `~/.local/bin/alpha-forge` に作成します。

    ```bash
    curl -sSL https://alforge-labs.github.io/install.sh | bash
    ```

    実行中、デフォルトの `~/.local/bin`（ユーザー領域・sudo 不要）に加えて、`システム共通の /usr/local/bin にインストールしますか？（sudo が必要） [y/N]:` と尋ねられます。Enter または `n` でデフォルト、`y` で `/usr/local/bin` を選択できます（後者は sudo を要求します）。

    !!! tip "非対話インストール (`INSTALL_DIR` 環境変数)"

        CI や Dockerfile 等、対話プロンプトに答えられない環境では `INSTALL_DIR` 環境変数で symlink 配置先を直接指定できます。指定するとプロンプトを完全にスキップします。

        ```bash
        # ~/.local/bin に固定（プロンプト無し）
        INSTALL_DIR=~/.local/bin bash <(curl -sSL https://alforge-labs.github.io/install.sh)

        # 任意のディレクトリにインストール（書き込み権限が必要）
        INSTALL_DIR=/opt/forge/bin bash <(curl -sSL https://alforge-labs.github.io/install.sh)
        ```

        `forge.dist` は `INSTALL_DIR` の親階層の `share/alpha-forge/` に展開されます（例: `INSTALL_DIR=/opt/forge/bin` の場合 `/opt/forge/share/alpha-forge/`）。アンインストール時は同じ `INSTALL_DIR` を渡してください。

    !!! tip "表示言語 (`FORGE_INSTALL_LOCALE` 環境変数)"

        インストーラーは `LANG` / `LC_ALL` を見て日本語（`ja*`）と英語（それ以外）を自動切り替えします。明示的に切り替えたい場合は `FORGE_INSTALL_LOCALE=ja|en` を指定してください。`uninstall.sh` も同じ環境変数に対応しています。

        ```bash
        # 強制的に英語表示でインストール
        FORGE_INSTALL_LOCALE=en bash <(curl -sSL https://alforge-labs.github.io/install.sh)
        ```

    !!! tip "有料プラン購入後の認証（任意）"

        インストール直後は Whop 登録なしで Trial プランとして CLI が動きます。有料プラン（Lifetime / Annual / Monthly）を購入した場合のみ、次のコマンドでブラウザ認証してください。

        ```bash
        alpha-forge system auth login
        ```

=== "Windows"

    PowerShell（管理者権限不要）で以下を実行してください。バイナリ一式（`forge.dist\` ディレクトリ）を `%LOCALAPPDATA%\Programs\alpha-forge\` に展開し、同階層に `alpha-forge.cmd` ラッパーを生成して、そのディレクトリを User PATH に自動登録します。

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    旧バージョン（`$HOME\bin\forge.exe` 単体配置 / `C:\Program Files\forge\forge.exe`）が存在する場合は自動的に検出し、確認のうえ削除した後に新レイアウトを配置します。動作を事前確認したい場合は次のように `-DryRun` を付けて実行できます。

    ```powershell
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/install.ps1))) -DryRun
    ```

    !!! tip "表示言語"
        Windows の表示言語（`CurrentUICulture`）から自動判定します。明示的に切り替える場合は `$env:FORGE_INSTALL_LOCALE = "en"` を `irm | iex` の前に設定してください（`ja` または `en`）。

    !!! tip "新しいターミナル"
        インストール後、開いているターミナルをすべて閉じてから新しいターミナルを開いて次の手順に進んでください。起動済みの Windows Terminal が残っていると、新しいタブ／ウィンドウにも PATH の変更が反映されません。

=== "手動インストール"

    1. [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases/latest) から使用するプラットフォームのバイナリをダウンロードします。

    2. **macOS / Linux**: 実行権限を付与して PATH の通ったディレクトリに配置します。

        ```bash
        chmod +x alpha-forge-macos-arm64
        sudo mv alpha-forge-macos-arm64 /usr/local/bin/alpha-forge
        ```

    3. **Windows**: バイナリを任意のフォルダに配置し、そのフォルダを PATH に追加します。

---

## シェル補完（任意）

`alpha-forge` の操作を高速化するため、シェル補完を有効化できます（Click による動的生成）。有効化用の環境変数は **`_ALPHA_FORGE_COMPLETE`** です（issue #1166）。

=== "bash"

    ```bash
    # ~/.bashrc に追記
    eval "$(_ALPHA_FORGE_COMPLETE=bash_source alpha-forge)"
    ```

=== "zsh"

    ```bash
    # ~/.zshrc に追記
    eval "$(_ALPHA_FORGE_COMPLETE=zsh_source alpha-forge)"
    ```

=== "fish"

    ```bash
    # ~/.config/fish/completions/alpha-forge.fish に追記
    _ALPHA_FORGE_COMPLETE=fish_source alpha-forge | source
    ```

設定後、`alpha-forge <TAB>` でトップレベルコマンドが、`alpha-forge analyze <TAB>` / `alpha-forge system <TAB>` / `alpha-forge data <TAB>` で各サブコマンドが補完されます。

---

## 有料プラン購入後の認証

AlphaForge は **Trial プランでは Whop 登録不要** で、インストール後そのまま動きます。**有料プラン（Lifetime / Annual / Monthly のいずれか）を購入した場合のみ** Whop アカウントによる OAuth 2.0 PKCE 認証を行い、データ日付制限・最適化試行数・Pine Script エクスポートのロックを解除します。

!!! info "Trial プランで満足している場合"
    Trial プラン（2023-12-31 までのデータ・最適化 50 trials・Pine 出力ブロックあり）で十分な利用範囲に収まる場合は、本セクションをスキップしてバックテスト・最適化を続行してください。`alpha-forge system auth login` の実行は不要です。

### 1. 有料プランを購入

ブラウザで [購入ページ](https://whop.com/alforge-labs/alphaforge/) を開き、Whop アカウント（または GitHub / Google 経由）でサインアップして Lifetime / Annual / Monthly のいずれかのチェックアウトを完了します。

### 2. alpha-forge で Whop OAuth 認証

購入完了後、ターミナルで次を実行するとブラウザが自動で開き、Whop OAuth 2.0 PKCE 認証フローが走ります。

```bash
alpha-forge system auth login
```

認証情報は `$XDG_CONFIG_HOME/forge/credentials.json`（未設定時 `~/.config/forge/credentials.json`）に保存されます。オンライン接続が必要です。

### 3. 認証状態の確認

ユーザー ID やトークン期限、プラン種別を確認します。

```bash
alpha-forge system auth status
```

```
ユーザー ID      : user_abc123
アクセストークン: 2026-05-13 12:30 UTC（あと 45 分）
最終検証        : 2026-05-13 11:45 UTC（13 分前）
プラン          : 有料 (Lifetime)
```

「プラン: 有料 (Lifetime)」と表示されれば有料プラン（Lifetime / Annual / Monthly のいずれか）で利用可能です。なお、現在の CLI 表示は内部実装の歴史的経緯で Annual / Monthly を購入したユーザーにも `有料 (Lifetime)` と表示されます（Whop OAuth 上はいずれも customer 扱いのため区別していません）。Whop 未登録 / 未認証（= Trial プラン）の場合は上記のプラン情報は表示されず、`[AlphaForge] ログイン情報がありません。` と `実行: alpha-forge system auth login` の案内のみが表示されます。

### 4. ロック解除の確認

有料プラン限定機能（Pine Script エクスポート）が動くことを確認します。

```bash
alpha-forge pine generate --strategy sma_cross_qs
```

赤い「有料プラン限定機能」Panel が出ずに `.pine` ファイルが生成されれば、有料プランで完全に動作しています。

---

## 結果の見方（詳細）

主要 6 指標の意味と目安です。指標の全リストは [CLI リファレンス](cli-reference/index.md) と [戦略テンプレート](templates.md) を参照してください。

| 指標 | 意味 | 目安 |
|------|------|------|
| **CAGR** | 年率リターン（複利ベース） | 市場ベンチマーク（S&P 500: 約 10%）と比較。プラスでも市場以下なら戦略の付加価値は限定的。 |
| **Sharpe Ratio** | リスク調整後リターン | 1.0 以上で「使える」、1.5 以上は優秀、2.0 超は上位戦略。負ならアウト。 |
| **Max Drawdown** | 過去最大の資産の落ち込み（ピークから） | 浅いほど良い。−20% を超えると心理的に運用継続が難しくなる目安。 |
| **Win Rate** | 勝ちトレードの割合 | 50% 前後が標準。トレンドフォローは 30–40%、平均回帰は 60–70% が典型。 |
| **Profit Factor** | 総利益 ÷ 総損失 | 1.5 以上で良好、2.0 超は優秀。1.0 未満は損失過剰。 |
| **Total Trades** | 期間中の総トレード数 | 統計的有意性のため最低 30 件以上は欲しい。少なすぎると過学習リスク。 |

![Max Drawdown の時系列チャート](assets/illustrations/concepts/metrics-max-drawdown-chart.png)

![Sharpe Ratio の概念図](assets/illustrations/concepts/metrics-sharpe-ratio-concept.png)

![Win Rate と Profit Factor の関係図](assets/illustrations/concepts/metrics-win-rate-profit-factor.png)

!!! info "次に試すべきこと"
    - パラメータ最適化: [`alpha-forge optimize run`](cli-reference/optimize.md) で Optuna ベイズ最適化
    - ウォークフォワード検証: [`alpha-forge optimize walk-forward`](cli-reference/optimize.md) で過学習を検証
    - 戦略テンプレート: [HMM × BB × RSI など](templates.md)を試す

---

## アンインストール

=== "macOS / Linux"

    公式アンインストーラーを実行してください。インストール時の symlink・`forge.dist`（同梱ライブラリ約 1,100 ファイル一式）・shell rc に追記された PATH 行を一括で削除します。

    ```bash
    bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
    ```

    認証情報（`~/.config/forge/credentials.json`）は **デフォルトで保持** されます。再インストール時に `alpha-forge system auth login` をやり直さずに済むよう、設計上の意図的な挙動です。

    !!! tip "完全削除（認証情報・EULA 同意もすべて消す）"

        ```bash
        bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --purge
        ```

        `--purge` を指定すると `~/.config/forge/`（Whop OAuth トークン + EULA 同意状態）と、もし存在すれば legacy 旧パス `~/.forge/` も削除します。

    !!! info "事前確認したいとき"

        ```bash
        bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh) --dry-run
        ```

        実際の削除は行わず、削除予定のパスのみ表示します。

    !!! tip "カスタムパスからアンインストール (`INSTALL_DIR` 環境変数)"

        `INSTALL_DIR` を指定してインストールした場合、同じ値を渡して symlink 配置場所を伝えてください。

        ```bash
        INSTALL_DIR=/opt/forge/bin bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)
        ```

        未指定の場合は `~/.local/bin` と `/usr/local/bin` の両方を自動探索します。

    **削除しないもの:**

    - `alpha-forge system init` で作成した `forge.yaml` / `data/` などの**プロジェクト作業ディレクトリ**（ユーザーのデータなので保護対象）
    - 他アプリも使う `~/.local/share/`、`~/.config/` 直下などの**親ディレクトリ**

=== "Windows"

    公式アンインストーラーを実行してください。新レイアウト（`%LOCALAPPDATA%\Programs\alpha-forge\`）と旧レイアウト（`$HOME\bin\forge.exe` / `C:\Program Files\forge\forge.exe`）の両方を検出して削除し、User PATH からも該当エントリを除去します。

    ```powershell
    irm https://alforge-labs.github.io/uninstall.ps1 | iex
    ```

    認証情報（`~\.config\forge\credentials.json`）はデフォルトで保持されます。完全削除したい場合は `-Purge` スイッチを付けて実行してください。

    ```powershell
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/uninstall.ps1))) -Yes -Purge
    ```

---

## トラブルシューティング

| エラーメッセージ / 症状 | 原因と対処 |
|------------------------|-----------|
| `command not found: forge` / `command not found: alpha-forge` | 新しいターミナルを開くか、`source ~/.bashrc` / `source ~/.zshrc` を実行してください。それでも出る場合は `ls ~/.local/bin/alpha-forge` でバイナリの存在を確認し、`echo $PATH` に `~/.local/bin` が含まれているか確認してください。 |
| （Windows）`alpha-forge: The term 'alpha-forge' is not recognized ...` | 開いているターミナルをすべて閉じてから新しく開き直してください（起動済みの Windows Terminal の新しいタブには PATH が反映されません）。それでも出る場合は `[Environment]::GetEnvironmentVariable('PATH','User')` に `%LOCALAPPDATA%\Programs\alpha-forge` が独立したエントリとして含まれるか確認し、含まれない・壊れている場合はインストーラーを再実行してください（自動修復されます）。 |
| 初回コマンドで `[y/n]` プロンプトが出る / 非対話実行で `Aborted!` | 初回のみ EULA 同意プロンプトが表示されます。対話端末では `y` を入力してください。CI・パイプ・エージェントなどの非対話環境では環境変数 `FORGE_ACCEPT_EULA=1` を設定すると初回 EULA に自動同意して続行できます（対応バージョン以降）。同意状態は `~/.config/forge/` に記録され次回以降は出ません。 |
| `❌ 未知のテンプレート名です: <id>。利用可能: ...` / `戦略 'sma_cross_qs' が見つかりません` | `alpha-forge strategy save sma_cross.json` を先に実行して戦略 DB に登録してください。または `alpha-forge backtest run SPY --strategy-file sma_cross.json --start ...` のように `--strategy-file` で JSON を直接指定できます。 |
| `❌ データが見つかりません: SPY (1d)` / `No data found for SPY` | 対象シンボルのヒストリカルデータが未取得です。`backtest run` はデータを自動取得しないため、ステップ 2.5 の `alpha-forge data fetch SPY --period 10y` を先に実行してください。 |
| `データが取得できませんでした: symbol=USDJPY` 等 FX で 404 | yfinance では FX シンボルに `=X` サフィックスが必須です（例: `USDJPY=X`, `EURUSD=X`, `GBPJPY=X`）。先物は `CL=F` のような `=F`、暗号資産は `BTC-USD` のような形式です。 |
| `forge.yaml が見つかりません` / `Config file not found` | カレントディレクトリに `forge.yaml` がありません。プロジェクト作業ディレクトリで `alpha-forge system init` を実行するか、環境変数 `FORGE_CONFIG` で指定してください（macOS/Linux: `FORGE_CONFIG=/path/to/forge.yaml alpha-forge ...`、Windows PowerShell: `$env:FORGE_CONFIG = "C:\path\to\forge.yaml"` を実行してから `alpha-forge ...`）。 |
| バックテスト結果が「取引数 0 件」 | 戦略パラメータが厳しすぎてエントリー条件を満たさない / データ期間が短すぎる、のどちらかが原因です。`alpha-forge strategy show <id> --json` でパラメータ確認、`alpha-forge data fetch '<SYM>' --period 10y` でデータ拡張、または `bbands_breakout_v1` など別テンプレートを試してください。 |
| `Best score: -inf` / 最適化結果がすべて `-inf` | 全 trial が NaN を返した状態です。`optimizer_config.param_ranges` の範囲が狭い・取引数が極端に少ない等が原因。範囲を広げるか `--trials` を増やす、`--metric` を `total_return` 等に変えて試してください。 |
| WFT が全ウィンドウ「OOS 0 件」「skipped」 | データ期間が短いと各ウィンドウで取引が発生せずスキップされます。FX / 1d データなら 5 年（約 1,250 行）以上を推奨。`alpha-forge data fetch '<SYM>' --period 10y` で長期データを揃えるか `--windows 2` で粗くしてください。 |
| `vis: serve: No such file or directory` / `vis: illegal option` | macOS には標準コマンド `/usr/bin/vis` があり、`$PATH` の並びによってはこちらが優先されます。`~/.local/bin/alpha-vis serve`（uv tool）または `~/.local/share/uv/tools/alpha-visualizer/bin/alpha-vis serve` のように絶対パスで起動してください（v0.3.0 以降は `alpha-vis` コマンドに改名済み）。 |
| `Trialプランでは2023-12-31までのデータのみ取得できます。最新データを取得するには有料プラン（Lifetime / Annual / Monthly）が必要です。` | 仕様どおりの動作です。Trial プランの上限日以降のデータは自動的に除外されます。 有料プラン（Lifetime / Annual / Monthly）購入後は制限解除されます。 |
| `認証情報の有効期限が切れています` / `Token expired` | `alpha-forge system auth login` で再認証してください。Whop 側でメンバーシップが失効していないか [マイページ](https://whop.com/) で確認してください。 |
| 認証エラー（その他） | ネットワーク接続を確認のうえ `alpha-forge system auth login` を再実行してください。Whop マイページでメンバーシップが有効か確認してください。 |
| macOS セキュリティ警告 | システム設定 → プライバシーとセキュリティ → 「alpha-forge を開く」を許可してください。 |

その他のトラブルや詳細な FAQ は [`/ja/install.html`](https://alforgelabs.com/ja/install.html) も参照してください。

- 使い方の質問や他のユーザーとの情報交換は [GitHub Discussions](https://github.com/alforge-labs/alforge-labs.github.io/discussions) をご活用ください。
- 個別のサポートが必要な場合は [support@alforgelabs.com](mailto:support@alforgelabs.com) までお問い合わせください。

---

## 次のステップ

- [結果を可視化する — alpha-visualizer](alpha-visualizer/installation.md) — バックテスト結果を Web ブラウザで確認できる OSS パッケージ（`uv tool install alpha-visualizer` / `pip install alpha-visualizer`）
- [目的別ユースケース](usecases/index.md) — 自分の役割（TradingView ユーザー / Python 開発者 / クオント / 自動売買検討者 / AI エージェント利用者）から最適な次ページを選ぶ
- [CLI リファレンス](cli-reference/index.md) — `alpha-forge` コマンドの全パラメータと出力形式
- [戦略テンプレート](templates.md) — HMM × BB × RSI などの複合戦略例
- [AI 駆動の戦略探索ワークフロー](ai-agents/exploration-workflow.md) — Claude Code / Codex × AlphaForge による自律探索

---

<!-- 同期元: `ja/install.html`（インストール・Whop ログイン・トラブルシューティング部分）。バックテスト実行例は alpha-forge の戦略 JSON スキーマ（`spy_sma_crossover_v1.json` を参考）に基づく。issue #117 で旧 `quickstart.md` を本ページに統合。 -->

# エージェントクイックスタート

Claude Code と AlphaForge を約 10 分でつなぎ、エージェントに最初のバックテストを任せるまでの手順です。CLI のインストールから作業ディレクトリの初期化、Claude Code への最初の依頼までを順番に進めます。

!!! note "前提"
    本ページは [Claude Code](https://docs.anthropic.com/en/docs/claude-code) がインストール済みであることを前提とします。Codex / Cursor などほかのコーディングエージェントでも、`alpha-forge system init` が展開するスキル（後述）と CLI コマンドはそのまま使えるため、手順はほぼ同一です。MCP サーバ経由で接続したい場合は [MCP リファレンス](mcp-reference.md) を参照してください。

!!! info "Trial プランのままで OK"
    本ページの手順は **Whop 登録不要の Trial プラン**で最後まで試せます。エージェント連携そのものは Trial でも動作します。Trial の制限はデータが 2023-12-31 まで・最適化 50 回まで・Pine Script 生成なしです（詳細は [はじめに](../getting-started.md) を参照）。

---

## ステップ 1 — AlphaForge CLI のインストール

まだ CLI を導入していない場合は、ワンライナーでインストールします。Trial プランのままで本ページの手順を最後まで進められます。

=== "Windows"

    PowerShell で実行します（管理者権限不要）。

    ```powershell
    irm https://alforge-labs.github.io/install.ps1 | iex
    ```

    インストール後、**開いているターミナルをすべて閉じて、新しいターミナルを開いてから**次に進んでください。

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

手動インストールやインストール先のカスタマイズ、有料プランの認証手順は [はじめに](../getting-started.md) を参照してください。

---

## ステップ 2 — 作業ディレクトリの初期化

エージェント用の作業ディレクトリを作成し、`alpha-forge system init` で初期化します。これにより `forge.yaml`・`data/` といった通常のプロジェクト構成に加えて、**Claude Code / Codex 用のスラッシュコマンドとスキルが展開**されます。

```bash
mkdir agent-quickstart && cd agent-quickstart
alpha-forge system init
```

展開されるエージェント向けファイルは次のとおりです。

| パス | 種別 | 内容 |
|---|---|---|
| `.claude/commands/explore-strategies.md` | Claude Code スラッシュコマンド | 未試行の指標 × 銘柄を自律探索 |
| `.claude/commands/analyze-exploration.md` | Claude Code スラッシュコマンド | 探索ログの集計・次の推薦 |
| `.claude/commands/grid-tune.md` | Claude Code スラッシュコマンド | 既存戦略の Grid チューニング |
| `.claude/commands/tune-live-strategies.md` | Claude Code スラッシュコマンド | 実運用戦略の再チューニング |
| `.claude/commands/update-market-data.md` | Claude Code スラッシュコマンド | 保存済みデータの一括更新 |
| `.claude/skills/forge-backtest/SKILL.md` | Claude Code スキル | バックテスト実行の手順知識 |
| `.claude/skills/forge-analyze/SKILL.md` | Claude Code スキル | 結果分析の手順知識 |
| `.claude/skills/forge-data/SKILL.md` | Claude Code スキル | データ取得・更新の手順知識 |
| `.agents/skills/` | Codex スキル | 上記スキルと同内容（Codex 用） |

!!! note "初回のみ EULA 同意プロンプトが表示されます"
    最初に主要コマンドを実行すると、初回だけ EULA の要約と `[y/n]` 同意プロンプトが表示されます。エージェントなどの非対話環境では `FORGE_ACCEPT_EULA=1` を設定すると自動同意して続行できます（後述「無人実行のための設定」を参照）。

---

## ステップ 3 — Claude Code から最初の依頼

作業ディレクトリ（`agent-quickstart/`）で Claude Code を起動し、自然言語で依頼してみます。たとえば次のように頼みます。

```
SPY をサンプル戦略でバックテストして、結果を要約して。
```

エージェントは展開済みスキル（`forge-backtest` など）の知識をもとに、必要なコマンドを自分で組み立てて実行します。たとえば次のような流れになります。

```bash
alpha-forge data fetch SPY --period 5y
alpha-forge backtest run SPY --strategy my_rsi_v1 --json
```

`--json` 付きで実行されるため、stdout には純粋な JSON が返り、エージェントはそれをそのまま読み取って勝利率・最大ドローダウン・シャープレシオなどを要約できます（進捗や装飾は stderr に出るため JSON を汚しません）。

!!! tip "自律探索を任せたい場合"
    1 回のバックテストではなく、未試行の指標 × 銘柄をエージェントに**自律的に探索**させたい場合は `/explore-strategies` スラッシュコマンドを使います。バックテスト → Optuna 最適化 → ウォークフォワード検証までを自動で回します。詳細は [探索ワークフロー](exploration-workflow.md) を参照してください。

---

## ステップ 4（任意）— MCP サーバ接続

CLI を直接実行する代わりに、**MCP（Model Context Protocol）サーバ**経由でエージェントに機能を公開することもできます。Claude Code には次のコマンドで登録します。

```bash
claude mcp add --scope user alpha-forge -- uvx alpha-forge-mcp
```

CLI 直接実行との違いは、各機能が**型付きのツール契約として安全に公開**される点です（識別子のバリデーションやタイムアウトが組み込まれています）。`alpha-forge-mcp` は OSS（Apache-2.0）ですが現時点では **alpha 版**のため、ツール契約は今後変更されうる点に留意してください。Cursor / Codex でも同じ `command` / `args` で登録できます。詳細は [MCP リファレンス](mcp-reference.md) を参照してください。

---

## 無人実行のための設定

エージェントに夜間の自律探索などを任せる場合は、確認プロンプトでハングしないように環境変数を設定しておきます。

!!! info "非対話・無人実行の 3 点セット"
    | 設定 | 役割 |
    |---|---|
    | `FORGE_ACCEPT_EULA=1` | 初回 EULA 同意を自動化（最初の 1 回のみ必要） |
    | `FORGE_NONINTERACTIVE=1` | 全確認プロンプトを排除（`CI` が truthy・非 TTY でも自動有効） |
    | `--yes` / `-y` | 破壊的操作（delete / purge / prune / clean）に必須。**無いと終了コード 2 で即停止**（ハングしない） |

    破壊的操作を実行前に確認したい場合は `--dry-run` を付けて影響範囲だけ表示できます。終了コードの規約（0=成功 / 1=not found・失敗 / 2=引数エラー）など詳細は [CLI 規約](cli-conventions.md) を参照してください。

---

## 次のステップ

- [探索ワークフロー](exploration-workflow.md) — `/explore-strategies` による夜間自律探索の進め方
- [成果物の見方](../guides/output-examples.md) — バックテスト・最適化結果の読み解き方
- [CLI 規約](cli-conventions.md) — `--json` 出力・終了コード・非対話実行のルール

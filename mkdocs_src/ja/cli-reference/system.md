# alpha-forge system

ワークスペース初期化・Whop OAuth 認証・同梱ドキュメント参照などの運用ユーティリティ群です。

## alpha-forge system auth

Whop OAuth 2.0 PKCE による認証コマンド群。サブコマンドはすべて `alpha-forge system auth <subcommand>` で実行します。詳しい初回セットアップは [はじめに](../getting-started.md) を参照。

## alpha-forge system auth login

ブラウザを開いて Whop で認証します。

```bash
alpha-forge system auth login
```

ブラウザが自動で開き、Whop の OAuth 認証フローを実行します。引数・オプションなし。成功すると認証情報が `$XDG_CONFIG_HOME/forge/credentials.json`（未設定時 `~/.config/forge/credentials.json`）にキャッシュされます。

## alpha-forge system auth logout

ログアウトして認証情報を削除します。

```bash
alpha-forge system auth logout
```

`credentials.json` を削除します。引数・オプションなし。Whop マイページのメンバーシップ自体は影響を受けません。

## alpha-forge system auth status

現在の認証状態を表示します。

```bash
alpha-forge system auth status
```

サンプル出力：

```text
ユーザー ID      : user_abc123
アクセストークン: 2026-04-12 12:30 UTC（あと 45 分）
最終検証        : 2026-04-12 11:45 UTC（13 分前）
プラン          : annual
```

未認証時は次のように案内します：

```text
[AlphaForge] ログイン情報がありません。
  実行: alpha-forge system auth login
```

開発スキップ環境変数（`ALPHA_FORGE_DEV_SKIP_LICENSE=1`）が有効な場合は `[AlphaForge] 開発スキップ中（EULA/認証は未完了）` を表示します。

!!! note "`ALPHA_FORGE_DEV_SKIP_LICENSE` はソース実行限定"
    この開発スキップ表示は **ソース実行（`uv run` など、`pyproject.toml` が存在する開発ツリー）でのみ有効**です。配布バイナリ（リリース版）では `ALPHA_FORGE_DEV_SKIP_LICENSE=1` を設定しても常に無効となり、上記の `開発スキップ中` は表示されず、未認証時は通常どおり `[AlphaForge] ログイン情報がありません。` が表示されます（意図的な設計）。

## alpha-forge system auth check op

1Password CLI（`op`）のセッション有効性を検証します。`.env.op` を併用するチームの CI フックで使用するためのもの（issue #411）。詳細は実装コメントを参照。

```bash
alpha-forge system auth check op [--json]
```

セッション有効時に exit code `0`、無効時に exit code `2` を返します。

---

## alpha-forge system init

作業ディレクトリを初期化します。`forge.yaml`、データディレクトリ、ドキュメント、AI アシスタント統合ファイルを作成。

## 構文

```bash
alpha-forge system init [OPTIONS] [DIRECTORY]
```

## 引数

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `DIRECTORY` | 引数（任意） | カレントディレクトリ | 指定したディレクトリを作成し、そこへ初期化ファイル一式を展開する |

## オプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--force` / `-f` | フラグ | false | 既存ファイルを確認なしで上書き |
| `--yes` / `-y` | フラグ | false | 展開先の確認プロンプトをスキップ（CI・AI エージェント等の非対話実行向け） |
| `--no-claude` | フラグ | false | AI アシスタント統合ファイルのセットアップをスキップ |
| `--template` / `-t` | 選択肢 | `default` | 資産クラス別テンプレートを選択（`crypto` / `fx` / `stocks` / `commodities` / `default`） |

## 作成されるディレクトリ

- `data/historical/`、`data/strategies/`、`data/results/`、`data/journal/`、`data/ideas/`、`output/pinescript/`

## インストールされる AI 統合ファイル

| 出力先 | 内容 |
|--------|------|
| `.claude/skills/` | Claude Code スキル（forge-backtest, forge-analyze, forge-data） |
| `.claude/commands/` | Claude Code スラッシュコマンド（explore-strategies, grid-tune 他 4 件） |
| `.agents/skills/` | Codex スキル（explore-strategies, grid-tune 他 4 件） |

## サンプル出力

```text
AlphaForge: 作業ディレクトリを初期化します...

[1/4] 設定ファイル
  ✓ forge.yaml

[2/4] データディレクトリ
  ✓ data/historical/
  ✓ data/strategies/
  - 既存: data/results/
  ...

[3/4] ドキュメントファイル
  ✓ docs/quick-start.ja.md
  ✓ docs/user-guide.ja.md
  ...

[4/4] AI アシスタント統合ファイル
  ✓ .claude/skills/forge-backtest/SKILL.md
  ✓ .claude/commands/explore-strategies.md
  ✓ .claude/commands/grid-tune.md
  ✓ .agents/skills/explore-strategies/SKILL.md
  ✓ .agents/skills/grid-tune/SKILL.md
  ...

完了: 26 件を作成, 0 件をスキップ

次のステップ:
  1. forge.yaml を編集して設定をカスタマイズしてください
  2. 以下を ~/.zshrc / ~/.bashrc に追加してください:
     export FORGE_CONFIG=/path/to/forge.yaml
```

---

## alpha-forge system docs

`alpha-forge` に同梱されているドキュメント・スキル・コマンド参考資料を参照します。

## alpha-forge system docs list

```bash
alpha-forge system docs list
```

利用可能な同梱ドキュメントの一覧を表示します。`✓` / `✗` でファイル存在を表します。

## alpha-forge system docs show

```bash
alpha-forge system docs show <NAME>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `NAME` | 引数（必須） | ドキュメント名（`alpha-forge system docs list` で確認） |

ドキュメントの内容を標準出力に表示します。未知の名前を指定すると利用可能リストとともにエラー表示し、終了コード `1`。

---

## alpha-forge system config

実効設定（実際に読み込まれた `forge.yaml` の現在値）をダンプします。どの `forge.yaml` が読み込まれ、各キーがどの値に解決されたかを確認できる**観測専用（read-only）**コマンドです。`FORGE_CONFIG` 環境変数の意図しない継承などを切り分けられます。読み取り専用のため、ライセンス切れ・未認証でも実行できます。

### 構文

```bash
alpha-forge system config [KEY] [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `KEY` | 引数（任意） | - | dotted key（例: `data.storage_path`）。指定すると単一値だけを生で出力 |
| `--json` | フラグ | false | 結果を JSON で出力（機械可読・MCP / パイプ用途） |

- **`KEY` 省略時（全体ダンプ）**: 読み込まれた `forge.yaml` の絶対パス（不在時は探索順）・関与した環境変数オーバーライド（`FORGE_CONFIG` / `FORGE_LANG` / `FORGE_DEBUG` / `FORGE_NONINTERACTIVE` 等）・解決済みの主要キー実値（`Path` は絶対パスへ解決）を表示します。
- **`KEY` 指定時**: dotted key で単一値を生で出力します。`$(alpha-forge system config data.storage_path)` のようにスクリプトから利用できます。不在キーは標準エラーにエラーを出して終了コード `1`（**Fail Loud**）。
- **秘匿マスク**: `token` / `api_key` / `secret` / `password` / `access_key` などのキー名パターンや `SecretStr` フィールド（`oanda.access_token` / `fred.api_key`）の値は `***` でマスクされます。

### サンプル出力（全体ダンプ）

```text
# 実効設定ファイル: /path/to/forge.yaml

## 環境変数オーバーライド
FORGE_CONFIG=/path/to/forge.yaml
FORGE_ACCEPT_EULA=1

## 解決済み設定値
data.storage_path = /path/to/data/historical
data.providers.oanda.access_token = ***
data.providers.fred.api_key = ***
report.output_path = /path/to/output/results
strategies.use_db = True
...
```

### サンプル出力（`--json`）

`--json` 指定時は stdout に純 JSON のみを出力します（装飾・エラーは標準エラーへ分離）。

```json
{
  "config_path": "/path/to/forge.yaml",
  "config_search_order": ["FORGE_CONFIG=/path/to/forge.yaml"],
  "env_overrides": {"FORGE_CONFIG": "/path/to/forge.yaml"},
  "config": {"data": {"providers": {"fred": {"api_key": "***"}}}}
}
```

単一キー指定 + `--json` の場合は `{key, value}` の envelope を返します。

```bash
alpha-forge system config strategies.use_db --json
# => {"key": "strategies.use_db", "value": true}
```

---

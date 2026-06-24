# alpha-forge system

ワークスペース初期化・Whop OAuth 認証・同梱ドキュメント参照・環境診断・データ保存先一覧などの運用ユーティリティ群です。

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
alpha-forge system auth status --json   # 機械可読（MCP / パイプ用途、issue #1225）
```

`--json` を付けると認証状態を構造化 JSON で取得できます（read-only コマンドの `--json` 網羅、issue #1225）。

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
| `.agents/skills/` | Codex スキル（explore-strategies, grid-tune ほか・forge-* スキルを含む） |
| `AGENTS.md`（作業ディレクトリ直下） | Cursor / Windsurf / 汎用エージェント向けの足場ファイル（issue #1230）。CLI 基本ワークフローと配備済みスキルへの導線を日英併記で記述。多くのコーディングエージェントが読む汎用 `AGENTS.md` 規約に従う |

`AGENTS.md` は Claude Code / Codex 以外（Cursor・Windsurf・GitHub Copilot など）のエージェントでも、init 直後に「alpha-forge をどう駆動するか」の文脈を受け取れるようにするための最小足場です（issue #1230）。`--no-claude` を付けた場合でも、ドキュメント類とともにスキップされます。

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
  ✓ AGENTS.md
  ...

[4/4] AI アシスタント統合ファイル
  ✓ .claude/skills/forge-backtest/SKILL.md
  ✓ .claude/commands/explore-strategies.md
  ✓ .claude/commands/grid-tune.md
  ✓ .agents/skills/explore-strategies/SKILL.md
  ✓ .agents/skills/grid-tune/SKILL.md
  ...

完了: 32 件を作成, 0 件をスキップ

次のステップ:
  1. forge.yaml を編集して設定をカスタマイズしてください
  2. 以下を ~/.zshrc / ~/.bashrc に追加してください:
     export FORGE_CONFIG=/path/to/forge.yaml
  3. クイックスタート: docs/quick-start.ja.md を参照

エージェントスキル / コマンド（init で展開済み）:
  - Claude Code: スラッシュコマンド /explore-strategies・/analyze-exploration・
                 /update-market-data・/tune-live-strategies・/grid-tune
      forge-backtest / forge-analyze / forge-data スキルも .claude/skills/ に展開済み
  - Codex: .agents/skills/ に同名スキル（explore-strategies・forge-backtest ほか）
  - 汎用エージェント（Cursor / Windsurf 等）: 作業ディレクトリ直下の AGENTS.md を参照
  - 同梱資産の一覧: alpha-forge system docs list
```

!!! tip "展開したスキル / コマンドの発見性（issue #1229）"
    `system init` の完了案内には、展開したエージェントスキル / コマンド（Claude Code の `/explore-strategies` 等、Codex の同名スキル、汎用エージェント向けの `AGENTS.md`）の一覧と起動法が表示されます。配備済みの自律探索 / グリッド / チューニングスキルにエージェント・人間の双方が気づけるようにするためです。同梱資産の機械可読インデックスは [`alpha-forge system docs list`](#alpha-forge-system-docs-list)（`--json` 対応）で取得できます。

---

## alpha-forge system docs

`alpha-forge` に同梱されているドキュメント・スキル・コマンド参考資料を参照します。

## alpha-forge system docs list

```bash
alpha-forge system docs list
alpha-forge system docs list --json   # 機械可読（MCP / パイプ用途、issue #1225）
```

利用可能な同梱ドキュメントの一覧を表示します。`✓` / `✗` でファイル存在を表します。`--json` を付けると機械可読な同梱資産インデックスとして取得でき（read-only コマンドの `--json` 網羅、issue #1225）、エージェントが配備済みドキュメント・スキル・コマンドを発見する導線になります（issue #1229）。

## alpha-forge system docs show

```bash
alpha-forge system docs show <NAME>
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `NAME` | 引数（必須） | ドキュメント名（`alpha-forge system docs list` で確認） |

ドキュメントの内容を標準出力に表示します。未知の名前を指定すると利用可能リストとともにエラー表示し、終了コード `1`。

---

## alpha-forge system describe

全コマンドの**機械可読カタログ**（各葉コマンドのパス・オプション・型・`--json` 対応可否）を出力します（issue #1223）。エージェント / MCP 向けの **capability discovery** 用コマンドで、read-only かつネットワークアクセスを行いません。「どのコマンドがあり、どのオプションを取り、`--json` を持つか」を実行時に列挙できるため、エージェントが利用可能なコマンドセットを動的に把握できます。

### 構文

```bash
alpha-forge system describe [--json]
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON で出力（機械可読・MCP / パイプ用途。`--json` 指定時は stdout に純 JSON のみ） |

### サンプル出力（`--json`）

`{"commands": [...], "count": n}` の envelope を返します。各要素は `command`（葉コマンド名）・`path`（フルパス）・`options`（`name` / `type` / `help` の配列）・`json_supported`（`--json` を持つか）を含みます。

```json
{
  "commands": [
    {
      "command": "run",
      "path": "backtest run",
      "options": [
        {"name": "--strategy", "type": "text", "help": "戦略名（--strategy-file と排他）"},
        {"name": "--json", "type": "boolean", "help": "結果をJSON形式で標準出力する"}
      ],
      "json_supported": true
    }
  ],
  "count": 115
}
```

!!! tip "役割分担"
    `system describe --json` が「**どのコマンドに `--json` があるか**」、[`--json` 出力リファレンス](../ai-agents/json-output-reference.md) が「**各コマンドの `--json` が返すフィールドの意味**」を担います。

**Exit code**: `0`=成功。

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

## alpha-forge system paths

戦略 JSON・バックテスト結果・ジャーナル・アイデア・Pine Script・ヒストリカルデータなど、**全データ保存先を解決済みの絶対パスで一覧**します（issue #1180）。バックアップ・移行の起点となる観測専用（read-only）コマンドで、ライセンス切れ・未認証でも実行できます。各成果物の保存先は `forge.yaml` の各 `*_path` キーで決まり、相対パスは `forge.yaml` のあるディレクトリ基準で解決されます。

### 構文

```bash
# 人間向け一覧（実効 forge.yaml も併記）
alpha-forge system paths

# 機械可読（{"paths": {...}} envelope）。スクリプト・MCP 用途
alpha-forge system paths --json
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON で出力（機械可読・MCP / パイプ用途） |

### 一覧される保存先

| キー | 内容 | 既定パス（forge.yaml 基準の相対） |
|------|------|----------------------------------|
| `strategies` | 戦略 JSON（最適化済みを含む） | `./data/strategies` |
| `historical` | ヒストリカル価格データ（Parquet） | `./data/historical` |
| `results` | バックテスト・最適化の結果 | `./data/results` |
| `journal` | 戦略ジャーナル | `./data/journal` |
| `ideas` | 投資アイデア | `./data/ideas` |
| `pinescript` | 生成された Pine Script | `./output/pinescript` |
| `alt_storage` | 代替データ（センチメント等） | `./data/alternative` |
| `config` | 実効 `forge.yaml` の絶対パス | （`FORGE_CONFIG` の値） |

> 既定では戦略・ジャーナル・バックテスト結果は SQLite DB（`strategies.db` / `backtest_results.db`）に保存されます。これらも `strategies` / `results` ディレクトリ配下に置かれるため、ディレクトリ単位でコピーすれば DB ごとバックアップされます。

### バックアップ・移行

`FORGE_CONFIG` が指す **workspace ディレクトリを丸ごとコピー**するのが最も簡単で確実なバックアップ手段です。個々の成果物パスを追う必要はありません。

```bash
# workspace のルート（forge.yaml のあるディレクトリ）を確認
WS=$(dirname "$FORGE_CONFIG")

# rsync で差分バックアップする例
rsync -a --delete "$WS"/ /path/to/backup/workspace/
```

新しいマシンへ移行する場合は、コピーした workspace ディレクトリを置いて `FORGE_CONFIG` をその `forge.yaml` に向けるだけで、戦略・結果・ジャーナルがそのまま引き継がれます。`FORGE_CONFIG` を切り替えれば、実運用用・実験用などの workspace を混ざらないよう併用できます。

**Exit code**: `0`=成功。

---

## alpha-forge system doctor

サポート問い合わせやバグ報告のときに、**環境情報を 1 コマンドでまとめて収集**します（issue #1170）。CLI バージョン・OS / Python・ライセンス状態・読み込まれる `forge.yaml`・主要データディレクトリの有無・crash ログの場所を 1 つの出力にまとめます。**実ネットワークアクセスは行いません**（ライセンス状態はローカルキャッシュした認証情報のみから判定し、Whop API は呼び出しません）。認証が切れていても・設定が壊れていても実行できるよう、認証チェックの対象外です。

### 構文

```bash
# 人間向けの診断レポート
alpha-forge system doctor

# 構造化出力（version / platform / license / config / paths / logs の envelope。stdout は純 JSON）
alpha-forge system doctor --json
```

### 引数とオプション

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `--json` | フラグ | false | 結果を JSON で出力（機械可読・MCP / パイプ用途） |

### 出力される主なフィールド

| セクション | 内容 |
|-----------|------|
| `version` | alpha-forge の CLI バージョン |
| `platform` | OS（`system` / `release` / `machine`）・Python（`python_version` / `python_implementation`） |
| `license` | プラン種別（`plan`: `free` / `paid` / `dev` / `unknown`）・`credentials.json` の有無（`authenticated`）・オフライン猶予切れデグレード中か（`offline_degraded`） |
| `config` | 実際に読み込まれる `forge.yaml` の絶対パス（`config_path`）と探索順（`config_search_order`） |
| `paths` | `strategies` / `historical` / `results` / `journal` / `ideas` / `pinescript` 各ディレクトリの絶対パスと存在有無（`exists`） |
| `logs` | 未捕捉例外の crash ログ（`forge-crash.log`）の記録先パス |

バグ報告の際は `alpha-forge system doctor --json` の出力を添付すると、環境の切り分けが早くなります。

!!! tip "未捕捉エラー時の crash ログ（issue #1169）"
    `--debug` を付けていない通常実行で未捕捉の例外が発生した場合でも、そのトレースだけは OS 標準のユーザーログディレクトリに `forge-crash.log` として常時記録されます（macOS / Linux は `platformdirs` のユーザーログディレクトリ、フォールバックは `~/.local/state/alpha-forge/logs`、Windows は `%LOCALAPPDATA%\alpha-forge\logs`）。コンソール出力は汚さず、`--json` 実行中も安全です。バグ報告の際はこのファイルを添付すると原因の特定が早くなります。記録先パスは上記 `logs` フィールド（`system doctor`）でも確認できます。

**Exit code**: `0`=成功。

---

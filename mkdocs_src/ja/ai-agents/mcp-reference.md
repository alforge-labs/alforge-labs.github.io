# alpha-forge-mcp リファレンス

**alpha-forge-mcp** は、alpha-forge CLI を [MCP（Model Context Protocol）](https://modelcontextprotocol.io/) で AI エージェントに公開する OSS（Apache-2.0）の stdio サーバです。Claude Code・Cursor・Codex など MCP 1.0+ 対応クライアントから、バックテスト・最適化・Pine Script 生成といった操作を「ツール」として呼び出せます。

!!! warning "alpha 版（pre-release）"
    現在の公開バージョンは **v0.1.0a5（alpha / pre-release）** です。ツール契約（ツール名・引数・戻り値）は今後変更される可能性があります。本番運用で固定したい場合はバージョンをピン留めし、アップグレード時はこのページのツールリファレンスとの差分を確認してください。

---

## 前提条件

- **alpha-forge バイナリが導入済み**であること。`PATH` 上に `alpha-forge` があるか、環境変数 `ALPHA_FORGE_BIN` で実行ファイルのパスを明示してください。
- **認証済み**であること。`alpha-forge system auth login` を一度実行しておきます（[Trial プラン](../usecases/ai-agents.md) でもエージェント連携自体は試せます）。
- **uvx 利用時は Python の別途インストール不要**です。`uvx` が一時環境で `alpha-forge-mcp` を実行します。

!!! note "Trial でも試せます"
    Whop 登録不要の無料 Trial（データは 2023-12-31 まで・最適化 50 回まで・Pine Script 生成なし）でも、MCP 経由のツール呼び出しは利用できます。まずは雰囲気を掴むのに適しています。

---

## セットアップ

### サーバの起動

=== "uvx（推奨）"

    ```bash
    uvx alpha-forge-mcp
    ```

    Python のインストール不要で、一時環境に最新版を取得して起動します。

=== "pip"

    ```bash
    pip install alpha-forge-mcp
    alpha-forge-mcp
    ```

### クライアントへの登録

通常は MCP クライアント側に「起動コマンド」を登録します。`command` と `args` はどのクライアントでも共通です。

=== "Claude Code（user スコープ）"

    すべてのプロジェクトから使えるよう user スコープで登録します。

    ```bash
    claude mcp add --scope user alpha-forge -- uvx alpha-forge-mcp
    ```

=== "Claude Code（project スコープ）"

    リポジトリ直下に `.mcp.json` を置くと、そのリポジトリのコラボレーター全員で共有できます。

    ```json title=".mcp.json"
    {
      "mcpServers": {
        "alpha-forge": {
          "command": "uvx",
          "args": ["alpha-forge-mcp"]
        }
      }
    }
    ```

=== "Cursor / Codex"

    Cursor・Codex も同じ `command` / `args` で登録できます。MCP 設定 UI もしくは設定ファイルで以下を指定してください。

    ```json
    {
      "mcpServers": {
        "alpha-forge": {
          "command": "uvx",
          "args": ["alpha-forge-mcp"]
        }
      }
    }
    ```

!!! tip "トランスポートは stdio"
    本サーバは stdio トランスポートで動作し、MCP 1.0+ クライアント全般に対応します。HTTP ポートの公開やネットワーク設定は不要です。

---

## ツールリファレンス

提供ツールは 18 種です。各ツールは対応する alpha-forge CLI コマンドを内部で `shell=False` で実行します（識別子はバリデーション済み）。各ツールの説明には前提（例: `run_backtest` は先に `fetch_data` が必要）と後続のヒントが記載されており、エージェントが正しい順序で呼び出せます。

| ツール | 引数 | 戻り値 | 対応する CLI コマンド |
|--------|------|--------|----------------------|
| `list_strategies` | （なし） | 登録済み戦略一覧 | `alpha-forge strategy list --json` |
| `get_strategy` | `strategy_id` | 指定戦略の詳細（フル JSON） | `alpha-forge strategy show <id> --json` |
| `list_results` | `strategy_id?`（任意） | バックテスト結果一覧（戦略で絞り込み可） | `alpha-forge backtest list [--strategy <id>] --json` |
| `get_result` | `result_id` | 指定結果の指標・トレード | `alpha-forge backtest report <result_id> --json` |
| `run_backtest` | `symbol`, `strategy_id`, `start?`, `end?` | バックテスト実行結果 | `alpha-forge backtest run <symbol> --strategy <id> [--start] [--end] --json` |
| `run_optimize` | `symbol`, `strategy_id`, `metric?`, `trials?` | 最適化（Optuna TPE）結果。既定で保存 | `alpha-forge optimize run <symbol> --strategy <id> [--metric] [--trials] [--save] --json` |
| `apply_optimization` | `result_file`, `strategy_id` | 最適化結果を戦略に適用し `<id>_optimized` を保存 | `alpha-forge optimize apply <result_file> --to-strategy <id> --yes` |
| `run_walk_forward` | `symbol`, `strategy_id`, `windows?`, `metric?` | ウォークフォワード（OOS）最適化 | `alpha-forge optimize walk-forward <symbol> --strategy <id> [--windows] [--metric] --json` |
| `run_monte_carlo` | `result_id`, `simulations?` | 保存済み結果からモンテカルロ | `alpha-forge backtest monte-carlo <result_id> [--simulations] --json` |
| `fetch_data` | `symbol`, `period?` | ヒストリカル OHLCV を取得・キャッシュ（`run_backtest` の前提） | `alpha-forge data fetch <symbol> [--period]` |
| `save_strategy` | 戦略定義 JSON **本文** | JSON 本文から戦略を登録 | `alpha-forge strategy save <tmpfile>` |
| `generate_pinescript` | `strategy_id`, `with_webhook?` | Pine Script v6 ソース | `alpha-forge pine preview --strategy <id> [--with-webhook]` |
| `forge_status` | （なし） | 能力 / 前提条件（doctor + version）。失敗しない | `alpha-forge system doctor --json` |
| `list_journals` | （なし） | ジャーナルを持つ戦略一覧 | `alpha-forge journal list --json` |
| `get_journal` | `strategy_id` | 戦略のフルジャーナル（snapshot / run / tag / note） | `alpha-forge journal show <strategy_id> --json` |
| `exploration_status` | `goal?` | 戦略探索のカバレッジマップ（試行済み vs 未試行） | `alpha-forge explore status [--goal] --json` |
| `get_indicator` | `name` | 指定テクニカル指標のメタデータ | `alpha-forge analyze indicator show <name> --json` |

ツール固有の補足：

- `save_strategy` はファイルパスではなく戦略定義の **JSON 本文** を文字列で受け取り（エージェントフレンドリー）、一時ファイルに書き出してから `strategy save` を実行します。
- `fetch_data` は CLI に `--start` / `--end` が無いため `period` のみを公開します。
- `forge_status` は read-only で、バイナリが無くても**失敗しません**。`binary_found: false` を返すため、クライアントは何かを実行する前に前提条件を切り分けられます。
- `run_optimize` は既定で結果を保存（`save=true`）するため、その `saved_path` を `apply_optimization` に渡せます。`apply_optimization` は最適化パラメータを適用し、非対話（`--yes`）で `<strategy_id>_optimized` を保存します。
- `get_indicator` は指標の**メタデータのみ**（説明・パラメータ・出力）を返します。価格データ上で指標を計算するコマンドは無いため、シンボルに対する計算は行いません。
- ジャーナル / 探索の読み取りは read-first で公開。書き込み系・ml / pairs 系コマンドは未公開です。

!!! info "`metric` は制約付き enum"
    `run_optimize` / `run_walk_forward` の `metric` 引数は制約付き **enum** で、クライアントが推測なしで有効な最適化対象を選べます: `sharpe_ratio`（既定）・`sortino_ratio`・`calmar_ratio`・`total_return_pct`・`cagr_pct`・`profit_factor`・`win_rate_pct`・`expectancy_pct`・`omega_ratio`。

### サーバ instructions と長時間ジョブ

サーバは `instructions`（MCP `initialize` レスポンスで提示）を広告し、エンドツーエンドのワークフロー（`forge_status` → `fetch_data` → `run_backtest` → `run_optimize` → `run_walk_forward` → `apply_optimization` → `generate_pinescript`）を記述します。エージェントはどのツールをどの順で呼ぶべきか把握できます。

run / fetch / save / apply 系は長時間ジョブです（`run_backtest` 最大 300 秒、`run_optimize` / `run_walk_forward` 最大 600 秒、その他は既定タイムアウト）。対応クライアントには MCP progress 通知で **進捗**を報告し（`start` → `complete` のブラケット。内部の `alpha-forge` サブプロセスは中間進捗を出さない）、ブロッキング呼び出しをイベントループ外で実行してサーバの応答性を保ちます。タイムアウト時は `timeout` エラーコードを返し、リトライ可能です。

すべてのツールは MCP **tool annotation**（read 系には `readOnlyHint`、run / write 系には `openWorldHint` — `run_backtest` / `run_optimize` / `run_walk_forward` / `run_monte_carlo`・`fetch_data`・`save_strategy`・`apply_optimization`）を持ち、テキスト結果に加えて **structured output**（オブジェクト `outputSchema` を伴う `structuredContent`）を返します。

---

## エラーリファレンス

各ツールは例外を投げる代わりに、（常に成功扱いの）結果として統一された **error envelope** を返します。エージェントは自由文をパースせず、失敗カテゴリで機械的に分岐できます。

- 成功: `{"ok": true, "data": { ...alpha-forge JSON... }, "error": null}`
- 失敗: `{"ok": false, "data": null, "error": {"code": "<category>", "message": "<human readable>", "detail": null}}`

`error.code` は機械可読の失敗カテゴリです。`outputSchema` もこの `ok` / `data` / `error` 形状を反映します。

| code | 意味 | 対処 |
|------|------|------|
| `forge_not_found` | alpha-forge バイナリが見つからない | `PATH` を通すか、環境変数 `ALPHA_FORGE_BIN` で実行ファイルを明示 |
| `authentication_required` | 未認証 | `alpha-forge system auth login` を実行 |
| `freemium_blocked` | Trial プランで利用不可の機能（Pine Script 生成等） | 停止 / 有料プランへのアップグレードを検討 |
| `strategy_not_found` | 指定 ID の戦略が存在しない | `list_strategies` で正しい ID を確認 |
| `timeout` | 実行が制限時間を超過 | リトライ可能。または処理を分割 / `trials` を減らす（既定値は下表） |
| `bad_output` | CLI 出力を JSON として解釈できない | alpha-forge と alpha-forge-mcp のバージョン整合を確認 |
| `execution_failed` | CLI がエラー終了（exit code ≠ 0） | エラーメッセージを確認。引数・データ不足を疑う |

### タイムアウト既定値

| 操作 | 既定タイムアウト |
|------|-----------------|
| 一般のツール（list / get / generate 等） | 30 秒 |
| `run_backtest` | 300 秒 |
| `run_optimize` / `run_walk_forward` | 600 秒 |

!!! note "セキュリティ"
    サブプロセス実行は `shell=False` で行い、シンボルや戦略 ID といった識別子はバリデーションを通してから CLI に渡します。シェルインジェクションのリスクを抑える設計です。

---

## リソース

read-only データは MCP **リソース**としても公開され、Claude Code などのクライアントは明示的なツール呼び出しなしに `@` メンションで参照できます。read 系ツールと同じ alpha-forge コマンドに委譲し、`application/json` を返します。

| リソース URI | ペイロード |
|--------------|-----------|
| `forge://strategies` | 登録済み戦略すべて |
| `forge://strategy/{strategy_id}` | 1 戦略の定義 |
| `forge://results` | 保存済みバックテスト結果すべて |
| `forge://result/{result_id}` | 1 結果の指標・トレード |

## プロンプト

再利用可能なワークフローは MCP **プロンプト**として公開されます（Claude Code では `/mcp__alpha-forge__<name>` スラッシュコマンドとして表示）。

| プロンプト | 引数 | 内容 |
|-----------|------|------|
| `backtest_and_review` | `strategy_id`, `symbol` | バックテスト実行後、主要指標と注意点をレビュー |
| `optimize_and_verify` | `strategy_id`, `symbol` | Optuna 最適化後、過学習の兆候をチェック |

Streamable HTTP トランスポート・RBAC・レート制限・監査ログは将来のリリースで対応予定です。

---

## CLI 直接実行との使い分け

MCP と CLI 直接実行は排他ではなく、目的に応じて使い分けます。

| | alpha-forge-mcp（MCP） | alpha-forge CLI（直接） |
|---|---|---|
| 公開範囲 | 厳選された 18 ツール ＋ リソース / プロンプト（ツール契約として安全） | 全コマンドにアクセス可能 |
| クライアント | Claude Code・Cursor・Codex 等を横断 | シェル / スクリプト / スキル経由 |
| 主な用途 | エージェントに安全な操作セットだけ渡したいとき | 全機能を使い、スキルと組み合わせて自律ワークフローを組むとき |

- **MCP が向くケース**: AI エージェントに「決められた安全な操作」だけを公開したい、複数の MCP クライアントで同じツールセットを共有したい場合。
- **CLI 直接が向くケース**: `/explore-strategies` のような自律探索ワークフローを組む、全コマンド・全オプションを使いたい場合。CLI のスキルと組み合わせる前提です。詳細は [AI エージェント連携の概要](index.md) と [CLI 規約](cli-conventions.md) を参照してください。

---

## リンク

- **GitHub リポジトリ**: [alforge-labs/alpha-forge-mcp](https://github.com/alforge-labs/alpha-forge-mcp)
- **PyPI**: `alpha-forge-mcp`

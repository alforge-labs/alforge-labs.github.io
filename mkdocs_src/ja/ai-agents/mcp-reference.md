# alpha-forge-mcp リファレンス

**alpha-forge-mcp** は、alpha-forge CLI を [MCP（Model Context Protocol）](https://modelcontextprotocol.io/) で AI エージェントに公開する OSS（Apache-2.0）の stdio サーバです。Claude Code・Cursor・Codex など MCP 1.0+ 対応クライアントから、バックテスト・最適化・Pine Script 生成といった操作を「ツール」として呼び出せます。

!!! warning "alpha 版（pre-release）"
    現在の公開バージョンは **v0.1.0a4（alpha / pre-release）** です。ツール契約（ツール名・引数・戻り値）は今後変更される可能性があります。本番運用で固定したい場合はバージョンをピン留めし、アップグレード時はこのページのツールリファレンスとの差分を確認してください。

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

提供ツールは 7 種です。各ツールは対応する alpha-forge CLI コマンドを内部で `shell=False` で実行します（識別子はバリデーション済み）。

| ツール | 引数 | 戻り値 | 対応する CLI コマンド |
|--------|------|--------|----------------------|
| `list_strategies` | （なし） | 戦略一覧 | `alpha-forge strategy list --json` |
| `get_strategy` | `strategy_id` | 指定戦略の詳細 | `alpha-forge strategy show <id> --json` |
| `list_results` | `strategy_id?`（任意） | バックテスト結果一覧（戦略で絞り込み可） | `alpha-forge backtest list [--strategy <id>] --json` |
| `get_result` | `result_id` | 指定結果の詳細 | `alpha-forge backtest report <result_id> --json` |
| `run_backtest` | `symbol`, `strategy_id`, `start?`, `end?` | バックテスト実行結果 | `alpha-forge backtest run <symbol> --strategy <id> --json` |
| `run_optimize` | `symbol`, `strategy_id`, `metric?`, `trials?` | 最適化（Optuna TPE）結果 | `alpha-forge optimize run <symbol> --strategy <id> --json` |
| `generate_pinescript` | `strategy_id`, `with_webhook?` | TradingView 向け Pine Script | `alpha-forge pine preview --strategy <id> [--with-webhook]` |

!!! info "戻り値は CLI の `--json` を踏襲"
    各ツールの戻り値は、対応する CLI コマンドの `--json` 出力をそのまま返します。一覧系の envelope（`{"<複数形>": [...], "count": n}`）や not found 時の構造化エラー（`{"error": ..., "code": ..., "id": ...}`）といった規約も CLI と共通です。詳細は [CLI 規約](cli-conventions.md) を参照してください。

---

## エラーリファレンス

ツール呼び出しが失敗した場合、`code` 付きの構造化エラーが返ります。サーバ独自の code に加え、forge 側の構造化エラー（`strategy_not_found`・`authentication_required` 等）はそのまま passthrough されます。

| code | 意味 | 対処 |
|------|------|------|
| `timeout` | 実行が制限時間を超過 | 処理を分割するか、`trials` を減らす（既定値は下表参照） |
| `execution_failed` | CLI がエラー終了（exit code ≠ 0） | エラーメッセージを確認。引数・データ不足を疑う |
| `freemium_blocked` | Trial プランで利用不可の機能（Pine Script 生成等） | 有料プランへのアップグレードを検討 |
| `bad_output` | CLI 出力を JSON として解釈できない | alpha-forge と alpha-forge-mcp のバージョン整合を確認 |
| `invalid_argument` | 引数が不正（識別子バリデーション失敗等） | `strategy_id` 等の値を見直す |
| `forge_not_found` | alpha-forge バイナリが見つからない | `PATH` を通すか、環境変数 `ALPHA_FORGE_BIN` で実行ファイルを明示 |
| `strategy_not_found`（passthrough） | 指定 ID の戦略が存在しない | `list_strategies` で正しい ID を確認 |
| `authentication_required`（passthrough） | 未認証 | `alpha-forge system auth login` を実行 |

### タイムアウト既定値

| 操作 | 既定タイムアウト |
|------|-----------------|
| 一般のツール（list / get / generate 等） | 30 秒 |
| `run_backtest` | 300 秒 |
| `run_optimize` | 600 秒 |

!!! note "セキュリティ"
    サブプロセス実行は `shell=False` で行い、シンボルや戦略 ID といった識別子はバリデーションを通してから CLI に渡します。シェルインジェクションのリスクを抑える設計です。

---

## CLI 直接実行との使い分け

MCP と CLI 直接実行は排他ではなく、目的に応じて使い分けます。

| | alpha-forge-mcp（MCP） | alpha-forge CLI（直接） |
|---|---|---|
| 公開範囲 | 7 ツールに限定（ツール契約として安全） | 全コマンドにアクセス可能 |
| クライアント | Claude Code・Cursor・Codex 等を横断 | シェル / スクリプト / スキル経由 |
| 主な用途 | エージェントに安全な操作セットだけ渡したいとき | 全機能を使い、スキルと組み合わせて自律ワークフローを組むとき |

- **MCP が向くケース**: AI エージェントに「決められた安全な操作」だけを公開したい、複数の MCP クライアントで同じツールセットを共有したい場合。
- **CLI 直接が向くケース**: `/explore-strategies` のような自律探索ワークフローを組む、全コマンド・全オプションを使いたい場合。CLI のスキルと組み合わせる前提です。詳細は [AI エージェント連携の概要](index.md) と [CLI 規約](cli-conventions.md) を参照してください。

---

## リンク

- **GitHub リポジトリ**: [alforge-labs/alpha-forge-mcp](https://github.com/alforge-labs/alpha-forge-mcp)
- **PyPI**: `alpha-forge-mcp`

# CLI リファレンス

`alpha-forge` コマンドが提供するすべてのコマンドグループとサブコマンドの一覧です。種別ごとの詳細はリンク先の専用ページを参照してください。

## 全コマンド一覧

`alpha-forge/src/alpha_forge/cli.py` および `commands/*.py` の Click デコレータから抽出した実装網羅の一覧です。種別は CLI 階層上の位置づけで、すべてのグループは `alpha-forge <group> <subcommand>` の形で呼び出します。

- **コア**: 戦略開発・運用で頻繁に使う 9 グループ。トップレベルに直接配置されます
- **補助**: `analyze` / `system` のネストグループ。サブコマンドは `alpha-forge <補助> <ツール> <action>` で 3 階層になります
- **メタ**: バイナリ自身の操作 (`self`)

| グループ | 種別 | サブコマンド | 説明 | 詳細 |
|---|---|---|---|---|
| **strategy** | コア | `list` `create` `save` `show` `migrate` `delete` `purge` `validate` `signals` `scaffold` `cost-presets` | 戦略 JSON の作成・登録・管理 | [strategy →](strategy.md) |
| **backtest** | コア | `run` `batch` `combine` `diagnose` `list` `report` `migrate` `compare` `portfolio` `chart` `monte-carlo` `signal-count` | バックテストの実行・結果分析 | [backtest →](backtest.md) |
| **optimize** | コア | `run` `cross-symbol` `portfolio` `multi-portfolio` `walk-forward` `apply` `sensitivity` `history` `grid` `clean` | パラメータ最適化（ベイズ・グリッド・ウォークフォワード）・結果の掃除 | [optimize →](optimize.md) |
| **explore** | コア | `run` `import` `log` `status` `health` `diagnose` `recommend {show,prune}` `coverage {update,build,show}` `result show` | 自律探索ループ（バックテスト → 最適化 → WFT） | [explore →](explore.md) |
| **live** | コア | `list` `events` `convert-check` `import-events` `trades` `summary` `compare` `doctor` `sync-events` `replay` | ライブトレード分析と運用記録 | [live →](live.md) |
| **pine** | コア | `generate` `preview` `verify` `import` `list` `delete` `clean` | 戦略 JSON ↔ TradingView Pine Script 変換（`verify` は TradingView MCP で構文検証）・生成 `.pine` の一覧／削除／掃除 | [pine →](pine.md) |
| **journal** | コア | `list` `show` `runs` `compare` `tag` `note` `report` `verdict` | 実行履歴・タグ・判定・Markdown レポートの管理 | [journal →](journal.md) |
| **idea** | コア | `add` `list` `show` `status` `link` `tag` `note` `search` | 投資アイデアの管理・検索 | [idea →](idea.md) |
| **data** | コア | `fetch` `list` `trend` `update` `alt {fetch,list,info}` `tv-mcp {chart,inspect,check,cache-clean}` | ヒストリカル・代替データ・TradingView MCP データ取得 | [data →](data.md) |
| **analyze** | 補助 | `indicator {list,show}` `ml {train,models,walk-forward}` `ml dataset {build,feature-sets}` `pairs {scan,scan-all,build}` | 戦略分析の補助ツール群（テクニカル指標 / 機械学習 / ペアトレード） | [analyze →](analyze.md) |
| **system** | 補助 | `init` `auth {login,logout,status}` `auth check op` `docs {list,show}` `config` | 運用ユーティリティ（ワークスペース初期化・Whop OAuth 認証・同梱ドキュメント・実効設定ダンプ） | [system →](system.md) |
| **self** | メタ | `version` `update` | `alpha-forge` バイナリ自身の操作（バージョン確認・自己更新） | [self →](self.md) |

`{a,b,c}` 表記は同じ親グループ配下の選択肢を示します。たとえば `data alt {fetch,list,info}` は `alpha-forge data alt fetch` / `alpha-forge data alt list` / `alpha-forge data alt info` の 3 サブコマンドを表します。

## 共通ヘルプ

すべてのコマンドで `--help` が利用可能です。

```bash
alpha-forge --help                         # トップレベルのコマンド一覧
alpha-forge backtest --help                # backtest グループのサブコマンド一覧
alpha-forge backtest run --help            # 個別サブコマンドのパラメータ詳細
alpha-forge data alt --help                # ネストされた補助グループのサブコマンド一覧
```

## エージェント / CI からの利用（非対話実行・`--json`・exit code）

`alpha-forge` はコーディングエージェント（Claude Code / Codex 等）や CI からの subprocess 利用を前提に設計されています（epic [#1083](https://github.com/ysakae/alpha-forge/issues/1083)）。

- **非対話実行**: `FORGE_NONINTERACTIVE=1`（または `CI` / 非 TTY 検知）で確認プロンプトを排除します。破壊的操作は `--yes` が無いと終了コード `2` で停止します（ハング防止）。詳細は [AI 駆動の戦略探索ワークフロー › 非対話実行](../guides/ai-exploration-workflow.md#non-interactive) を参照。
- **`--json`**: 観測・参照系コマンド（`system config` / `live` / `journal` / `idea` / `analyze` 系など）は `--json` に対応します。stdout は純 JSON のみで、装飾・進捗は stderr へ分離されます。
- **exit code**: `0`=成功（明示キャンセル含む） / `1`=not found・想定内の失敗（無人ループの停止判定に使用） / `2`=引数エラー・非対話実行で `--yes` 欠落。`--json` 時の not found は stdout に `{error, code, id}` を出して終了コード `1`。
- **`compare` の 2 義**: `backtest compare` は新規バックテストを実行する重い処理、`journal compare` / `live compare` は保存済み結果の read-only 参照です。

## 関連ドキュメント

- [はじめに](../getting-started.md) — 最初のバックテスト実行までのチュートリアル
- [戦略テンプレート](../templates.md) — 同梱戦略の紹介
- [AI 駆動の戦略探索ワークフロー](../guides/ai-exploration-workflow.md) — Claude Code / Codex × AlphaForge

---

<!-- 同期元: `alpha-forge/src/alpha_forge/cli.py` の _TOP_LEVEL_LAZY / _ANALYZE_LAZY / _SYSTEM_LAZY と `commands/*.py` の Click decorator。サブコマンド追加時は本表も追従が必要。epic #1083 で system config / optimize clean / pine list,delete,clean / data tv-mcp cache-clean を追加。 -->

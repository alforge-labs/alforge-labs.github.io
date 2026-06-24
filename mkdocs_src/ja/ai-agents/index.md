# AI エージェント連携

AlphaForge は、AI コーディングエージェント（Claude Code / Codex / Cursor など）からの利用を**第一級のユースケース**として設計しています。すべての操作が CLI・JSON・YAML で完結し、確認プロンプトを排除する非対話モードと終了コード規約を備えているため、エージェントが自律的に実行・判断・リトライできます。

エージェントに「この銘柄で戦略を探索して」と頼むだけで、**バックテスト → 最適化 → ウォークフォワード検証 → Pine Script 出力**までを一連の流れとして自律実行できます。人間はゴール設定と最終判断に集中できます。

!!! note "投資助言ではありません"
    AlphaForge は戦略の検証・探索ツールです。バックテストや最適化の結果は将来の収益を保証するものではありません。最終的な投資判断はご自身の責任で行ってください。

## 3 つの接続経路

エージェントから AlphaForge を操作する方法は 3 つあります。用途に応じて単独でも組み合わせても使えます。

### 1. 同梱エージェントスキル

`alpha-forge system init` を実行すると、作業ディレクトリに Claude Code / Codex 用のスラッシュコマンドとスキルが展開されます。`/explore-strategies` のような高レベルのワークフローを呼ぶだけで、エージェントが探索ループ全体を実行します。バイナリ導入後すぐに使えるのが利点です。

### 2. MCP サーバ（alpha-forge-mcp）

`uvx alpha-forge-mcp` で起動する OSS の MCP サーバ経由で、`run_backtest` や `run_optimize` といった構造化ツールをエージェントに公開します。MCP 1.0+ に対応した任意のクライアント（Claude Code / Cursor / Codex など）から、共通のツール契約で AlphaForge を呼び出せます。

### 3. エージェントフレンドリー CLI

スキルや MCP を使わず、エージェントが `alpha-forge` CLI を直接呼ぶ方法です。`--json` による純 JSON 出力、`FORGE_NONINTERACTIVE=1` による確認プロンプトの排除、明確な終了コード規約（0=成功 / 1=失敗 / 2=引数エラー）により、シェル実行できるエージェントなら追加セットアップなしで連携できます。

| 経路 | 向いている場面 | 対応クライアント | 状態 |
|------|--------------|----------------|------|
| 同梱エージェントスキル | 高レベルの自律探索をすぐ始めたい | Claude Code / Codex | 同梱 |
| MCP サーバ | 構造化ツールとして安定的に呼びたい・複数クライアントで共通化したい | MCP 1.0+ 全般（Claude Code / Cursor / Codex 等） | alpha |
| エージェントフレンドリー CLI | スクリプトや任意のエージェントから細かく制御したい | シェル実行できる任意のエージェント | 標準 |

→ 詳細はそれぞれ [クイックスタート](quickstart.md)（スキル）・[MCP リファレンス](mcp-reference.md)・[CLI 規約](cli-conventions.md) を参照してください。

## エコシステム全体がエージェントから操作可能

AlphaForge 単体だけでなく、可視化（alpha-visualizer）・運用監視（alpha-strike）を含むエコシステム全体がエージェントから操作できるよう設計されています。

| 製品 | 役割 | エージェント連携ポイント |
|------|------|----------------------|
| alpha-forge | バックテスト・最適化・検証エンジン | CLI（`--json` / 非対話）・同梱スキル・MCP サーバ |
| alpha-visualizer | バックテスト結果の可視化 | REST API で結果を読み取り（`/api/results`・`/api/strategies`・`/api/wfo/{id}`・`/api/optimize/{id}` など） |
| alpha-strike | 発注・運用監視 | status API で稼働状況を監視（`/health`・`/status?trd_env=...`・`/status/events`） |

!!! tip "結果の読み取りも自動化できる"
    alpha-visualizer の REST API はエージェントから直接 GET できます。`alpha-vis serve --forge-dir <dir>` で起動しておけば、エージェントが探索結果や最適化結果を構造化 JSON として取得し、次のアクションを自律的に判断できます。

## このセクションの読み方

初めての方は、上から順に読み進めるのがおすすめです。

1. **[クイックスタート](quickstart.md)** — 同梱スキルまたは MCP を使って、約 10 分でエージェント連携を体験します。
2. **[探索ワークフロー](exploration-workflow.md)** — `/explore-strategies` による本格的な自律探索の流れと注意点を学びます。
3. **[MCP リファレンス](mcp-reference.md)** — alpha-forge-mcp が提供する 18 のツール・リソース・プロンプトとエラー envelope のリファレンスです。
4. **[CLI 規約](cli-conventions.md)** — `--json` 出力・非対話モード・終了コードなど、エージェント連携の土台となる規約をまとめています。

関連ページ: [はじめに（インストール）](../getting-started.md) / [AI エージェント利用者向けユースケース](../usecases/ai-agents.md) / [CLI リファレンス](../cli-reference/index.md)

!!! note "alpha-forge-mcp は alpha 版です"
    alpha-forge-mcp は現在 **alpha（プレリリース）版**（PyPI `alpha-forge-mcp` v0.1.0a5）です。提供ツールの名前・引数・戻り値などの契約は今後変更される可能性があります。本番ワークフローに組み込む際はバージョンを固定し、更新時はツール契約の差分を確認してください。

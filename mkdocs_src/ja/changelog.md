---
title: AlphaForge 変更履歴（Changelog）
description: AlphaForge CLI の公開リリース履歴。バージョンごとの主な新機能・改善・修正・破壊的変更をユーザー向けにまとめています。
---

# AlphaForge 変更履歴

AlphaForge CLI の公開リリースごとの主な変更点をまとめています。各バージョンの配布バイナリ（macOS arm64）とチェックサムは [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases) で配布しています。インストール・更新方法は [はじめに](getting-started.md) を参照してください。

!!! info "表記について"
    本ページは**ユーザー向けの要約**です。内部リファクタリング・テスト・CI・ドキュメント整備など、利用に直接影響しない変更は省略しています。最新版へは `alpha-forge self update` で更新できます。

---

## v0.18.0 — 2026-07-19

FX キャリー（スワップ）バックテスト一式と、`alpha-forge demo` による最速オンボーディングを追加しました。複数戦略合成には戦略レベルの動的配分が入りました。

- **FX キャリー計上**: `backtest run --carry` で短期金利差近似の日次キャリーを参考値として併記（`carry_adjusted_*`）。主要 8 通貨ペアは FRED 金利系列のビルトインマッピングで設定不要で動作し、`data alt import-swap` でブローカー実スワップ CSV を取り込むとそちらを優先します。結果は DB に永続化され、alpha-visualizer v0.9.0 の詳細画面にも表示されます。
- **最速オンボーディング**: `alpha-forge demo` の 1 コマンドで初期化〜同梱 DEMO データのバックテストまで一気に実行。`system init` はサンプルデータ＋デモ戦略を自動配置し、データ未存在エラーはそのまま貼り付けて実行できる案内文に。`system doctor` は解決コマンド（next_actions）まで提示します。
- **複数戦略合成の動的配分**: 戦略レベルの `risk_parity` / `vol_target` 配分と `--max-pillar-weight`（柱ごとのウェイト上限）を追加。WFT の warmup 前置で合成初期の欠落も解消しました。
- **`optimize walk-forward --save`**: WFT 結果を記録し、alpha-visualizer の WFO タブへ自動反映できるように。
- **実行元の記録**: バックテスト結果に実行元 provenance（source）を記録するようになりました。

## v0.17.0 — 2026-06-28

buy-hold-overlay 戦略 scaffold の hedge トリガー拡張と、CLI UX の磨き込みを行いました。

- **hedge トリガー拡張**: buy-hold-overlay に高速 hedge トリガー TRAILING_DD と、HMM × TRAILING_DD の複合トリガーを追加。既定 lookback も設定可能に。
- **REGIME_RULE の最適化**: レジーム条件の発火閾値を最適化対象にできるようになりました。
- **`combine --json`**: 複合ポートフォリオの equity_curve を JSON 出力（チャート生成用）。
- **CLI UX**: scaffold の exit help・チャートパスの実在検証・did-you-mean 提案など 8 項目の磨き込みに加え、エラー表示・exit code・`--json` / `--help` の一貫化を実施。

## v0.16.0 — 2026-06-24

AI エージェント連携の第 2 弾として、機械可読カタログと `--json` 出力契約を整備しました。

- **`system describe`**: 全コマンド・引数の機械可読カタログを新設。エージェントが CLI 仕様を自己発見できます。
- **`--json` 契約の整備**: `backtest run --json` に `run_id` / `result_id` を付与し出力をトークン経済化。read-only コマンドの `--json` を網羅し、WFT / MC の既定 verdict を統一。未捕捉例外も構造化エラー envelope で返します。`--json` 出力スキーマの契約リファレンスとバージョニング規約も公開。
- **next-step 案内**: 各コマンドの成功時に次の一手を提示。`strategy templates` で同梱テンプレートを一覧できます。
- **配布スキル**: Codex 向け forge-* スキルを同梱し、`system init` が汎用 AGENTS.md を展開するようになりました。

## v0.15.0 — 2026-06-23

環境診断コマンドとデータ取得の堅牢化、初回体験の改善を行いました。

- **`system doctor` / `system paths`**: 環境診断コマンドと、全データ保存先の一覧＋バックアップ手順を新設。
- **クラッシュ耐性**: 未捕捉例外に報告導線付きフォールバックと常時クラッシュログを追加。
- **データ取得の堅牢化**: プロバイダに指数バックオフ付きリトライを追加し、OANDA のページ取得上限による無言切り捨てを警告。ALTDATA センチメント系にもリトライ / キャッシュを整備。
- **Pine ネイティブ変換**: 定番 10 指標をネイティブ変換し `pine_supported` フラグを追加。
- **保守系**: 戦略・結果 JSON にスキーマバージョン＋マイグレーション枠組みを導入。`strategy delete` / `pine delete` に `--dry-run` を追加し、`FORGE_CONFIG` 未設定の無言フォールバックには WARNING を表示。
- **ドキュメント / 英語化**: `FORGE_LANG=en` でトップ help を完全英語化。Troubleshooting・用語集（Glossary)・CLI だけで完結する end-to-end サンプルを追加しました。

## v0.14.0 — 2026-06-19

Alpha158 由来のインジケータ群・拡張メトリクス・ポジションサイジングを大幅拡充しました。

- **インジケータ拡充**: CMO / PERCENTRANK / STDDEV / AROON / PV_CORR / ROLLING_QUANTILE / UP_RATIO / WVMA など Alpha158 由来の指標群と、LINEAR_REG の pred / resid（Pine ネイティブ変換対応）を追加。KBAR 9 式の EXPR プリセット集も同梱しました。
- **拡張メトリクス**: 7 系統の拡張メトリクスを追加。
- **ポジションサイジング**: `kelly` / `vol_target` を追加。
- **`backtest timeframes`**: タイムフレーム一括スイープを新設。
- **explore**: エスカレーションの既読化 `acknowledge` コマンドを追加。
- **ライセンス猶予**: オフライン猶予を 14 日へ拡張し、猶予切れは機能停止ではなく Trial デグレードに変更。
- **セキュリティ / 修正**: 依存パッケージの脆弱性 15 件を解消（pillow / urllib3 / protobuf ほか）。`risk_based` の Pine 出力サイズをエンジンと一致させる修正、optimizer の無効な param_ranges の実行前検出（exit 2）など。

## v0.13.0 — 2026-06-08

AI エージェント / CI からの無人利用を全面強化し、確認プロンプトのハング解消・`--json` 網羅・終了コード統一を実現しました。バグ修正も多数。

- **AI エージェント / CI 連携**: `system config` で実効設定を観測できるように。`analyze` / `live` / `journal` / `idea` グループへ `--json` 出力を拡大。終了コード規約（`0`=成功 / `1`=not found・想定内失敗 / `2`=引数エラー）を全コマンドで統一し、無人ループを安全に回せます。
- **非対話実行基盤**: `FORGE_NONINTERACTIVE` / `CI` / 非 TTY 検知で確認プロンプトのハングを解消。破壊的操作は `--yes` が無いと終了コード `2` で安全停止します。
- **生成物の掃除コマンド**: `optimize clean` / `pine list`・`delete`・`clean` / `data tv-mcp cache-clean` を新設。
- **`self update` が Windows 対応**。combine Pine の Webhook ペイロードに `target_qty` を併送（alpha-strike 連携）。
- **修正**: `backtest --regime` のレジーム別表示をラベル集約に変更（`--json` は純 JSON のみ）。保存済み結果への monte-carlo・自動ジャーナル記録・`data fetch` の空上書き防止など多数。
- ⚠️ **破壊的変更**: `strategy delete` の `--force` を `--yes`/`-y` に、`explore log` / `live events` / `live convert-check` の `--strategy-id` を `--strategy` に改名（互換 alias なし）。エラー時に `exit 0` だった多くのコマンドが非ゼロ終了に統一されました。スクリプト / CI の分岐を見直してください。

## v0.12.0 — 2026-06-04

Windows 配布基盤の整備と初回セットアップ体験を改善しました。

- **`system init` の改善**: `DIRECTORY` 引数を追加し、ディレクトリ作成と初期化を 1 コマンドで完結。ホーム直下など意図しない場所への誤展開には確認プロンプトを表示。
- **Windows ビルド基盤**: tag push での自動ビルドと clcache 高速化、clang-cl による MSVC ヒープ枯渇の回避。
- **認証**: ライセンス未購入時に Whop 販売ページ URL を案内。
- CLI 名を `alpha-forge` に統一（ドキュメント・文言の rename 漏れを解消）。

## v0.11.0 — 2026-06-02

FRED マクロデータ統合とマクロレジーム対応を追加しました。

- **FRED マクロデータ統合**: マクロデータ provider（vintage look-ahead 厳密マージ）、マクロ regime classifier、`EXTERNAL_SERIES` ML 特徴量を追加。
- **マクロイベント・ブラックアウト**: FOMC / NFP / CPI 前後のエントリー停止。`backtest run --regime-filter` でマクロ regime によるエントリー gating。
- **`FORGE_ACCEPT_EULA`**: 初回 EULA を非対話で accept（CI 向け）。
- `strategy list` / `backtest list` に `--json` を追加。walk-forward の OOS 集約方法を設定可能に。
- **修正**: buy-hold-overlay の `--leverage` 黙殺を警告化、配布バイナリへの `v6_signatures.yaml` 同梱、認証フローのセキュリティ強化。

## v0.10.0 — 2026-05-30

実運用（ペーパートレード）連携と複数戦略ポートフォリオのライブ集計を強化しました。

- **alpha-forge live / replay**: 約定照合イベント（order_reconciled）を権威データとして扱い、未約定（phantom fill）を除外して正確なライブ実績を集計。
- **Combine Portfolio のライブ集計**: always-in-market なオーバーレイ戦略の position ベースのライブ成績を SQLite に永続化し、[alpha-visualizer](alpha-visualizer/index.md) での可視化につなげる土台を整備。
- **修正**: Combine Portfolio 向け Pine 出力の `signal_id` 日時整形を修正。

## v0.9.0 — 2026-05-29

Buy & Hold ベンチマーク＋ヘッジオーバーレイと、複数戦略のポートフォリオ運用を本格対応しました。

- **Buy & Hold + ヘッジオーバーレイ**: `always_in_market` / ベンチマーク設定を追加し、常時保有しつつレジームに応じてヘッジ配分を動的調整する戦略を構築可能に。アルファ・ヘッジ効率・エクスポージャー平均などの指標も追加。
- **Combine Portfolio バックテスト**: 複数戦略の合算バックテスト（カスタムウェイト・ウォークフォワード検証・配当再投資対応）。
- **Combine Portfolio の Pine v6 出力**: 統合ポートフォリオを TradingView 用 Pine として出力する hybrid-strategy モードと、TradingView Strategy Tester での照合検証を追加。
- **探索の診断強化**: 過剰トレード抑制ゲート、データ長に応じた検証ウィンドウ短縮、戦略タイプ別の阻害要因集計など。

## v0.8.0 — 2026-05-21

自律探索の健全性診断と戦略生成の品質ガードを強化しました。

- **探索ヘルスの強化**: 選択ガイドと 2 段階閾値、bars 不足診断、ドローダウン下限の段階的救済、停滞検出によるループ停止トリガー。
- **戦略生成（scaffold）の品質ガード**: 平均回帰 × SuperTrend の構造的矛盾検出、資産ボラティリティ別の損切り／利確デフォルト、指標の過剰投入（4+ で警告・5+ で中止）、指標濃度ガード。

## v0.7.0 — 2026-05-21

取引コストの現実性と TradingView 整合性を大きく前進させました。

- **ブローカー別コストプリセット**: スプレッド・メイカー／テイカー手数料・IBKR 形式の従量手数料をバックテストに反映。
- **TradingView クロスバリデーション基盤**: 生成した Pine を TradingView Strategy Tester と突き合わせて結果の整合性を検証。SL/TP 戦略向けの許容誤差プロファイルも追加。
- **Pine 品質**: Pine v6 シグネチャに基づく生成後バリデータ、期間フィルタの焼き込みオプション。
- **探索の評価指標拡充**: レバレッジ調整後 CAGR、Calmar 推奨化、ウォークフォワードの散らばり系メトリクス。

## v0.6.0 — 2026-05-18

初回セットアップ体験と対応マーケットを拡張しました。

- **セットアップ強化**: `alpha-forge system init` がゴール設定サンプルや資産クラス別テンプレートを展開。`strategy create` に `--strategy-id` を追加。
- **暗号資産対応**: 専用の Binance データプロバイダーを追加し、4h/1h を 5 年以上取得可能に。
- **alpha-strike 連携**: `pine generate --with-webhook` で発注連携用の input/alert を Pine に自動付与。
- **ベンチマーク**: `--no-benchmark` でベンチマーク比較を無効化可能に。

## v0.5.1 – v0.5.3 — 2026-05-15 〜 16（ホットフィックス）

- **v0.5.3**: Whop 未認証ユーザーでも CLI を実行できる Trial プランフォールバックを追加。例外時のデータ取得ガイダンスを修正。
- **v0.5.2 / v0.5.1**: 配布バイナリ（Nuitka）環境でのリソースパス解決の修正と、`system init` / `docs` を認証不要にする Trial UX 改善。

## v0.5.0 — 2026-05-15

製品ファミリーの命名を統一しました。

- **破壊的変更**: CLI コマンドを `forge` から **`alpha-forge`** にリネーム（製品ファミリーの対称性のため）。配布バイナリ名も `alpha-forge-*` に統一。
- **改善**: 既知の例外を「次にとるべき操作」を示すメッセージに変換する仕組みを追加。最適化／バックテスト出力の UX 改善。

## v0.4.0 — 2026-05-14

起動速度を抜本的に改善しました。

- **パフォーマンス**: サブコマンドの遅延ロードでウォーム起動を約 2.6 秒 → 約 0.08 秒に短縮。配布バイナリの cold start を約 97 秒 → 約 7 秒に短縮。
- **self-update**: 差し替え直後のスモークテストとスピナー表示を追加。
- **破壊的変更**: 配布バイナリ同梱の戦略テンプレートを 34 種から厳選 7 種に削減。

## v0.3.5 — 2026-05-13

- **修正**: 配布バイナリ環境で `alpha-forge system init` がリソース展開に失敗する問題を解消。

---

過去バージョンの配布物・チェックサムは [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases) を参照してください。

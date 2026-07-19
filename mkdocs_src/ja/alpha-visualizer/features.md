# 機能詳細

`alpha-vis serve` で起動するダッシュボードの各画面の役割を解説します。

## Browse 画面

戦略ライブラリの一覧と検索。資産クラス別の Symbol Atlas、プリセットレンズ（Saved Views）、グルーピング可能な Strategy Ledger を備えます。

![Browse 画面](assets/browse.png){ loading=lazy }

主な操作:

- 戦略の絞り込み（Symbol / Timeframe / Sharpe Tier 等）
- Saved Views でよく使うフィルタを保存
- グローバル検索（`Cmd+K` / `Ctrl+K`）でコマンドパレットを開く
- 行クリックでスライドパネル展開、または Detail 画面に遷移

URL クエリで `selectedId` / `compareIds` が同期されるため、特定の戦略選択状態を共有できます。

## Detail 画面

個別戦略のバックテスト結果を多面的に表示します。

![Detail 画面](assets/detail.png){ loading=lazy }

タブ構成:

| タブ | 内容 |
|---|---|
| **バックテスト** | Equity / Drawdown / Underwater / トレード一覧・ベンチマーク指標（alpha / beta / IR / Correlation）・年次リターン。`alpha-forge backtest run --carry` で計上したキャリー調整後メトリクス（carry_adjusted）もカード表示 |
| **IS / OOS** | In-Sample / Out-of-Sample 別のメトリクス比較 |
| **WFO** | Walk-Forward 合成エクイティカーブとウィンドウ別結果。sharpe 以外の最適化指標で実行した WFT 結果にも対応 |
| **最適化** | Grid 最適化結果のヒートマップ・パラメータ vs 指標散布図 |
| **実行履歴** | 過去のバックテストラン一覧。GUI からのチューニング試行ランは通常ランと区別して表示 |
| **戦略構成** | 指標・条件式・リスク管理ルールの構造的表示と、パラメータチューニングパネル |

## GUI からの実行とパラメータチューニング

alpha-visualizer は結果を見るだけでなく、**バックテスト・最適化・Walk-Forward Test をブラウザから実行できます**。バックテストの GUI 実行は以前から可能でしたが、v0.9.0 で最適化・WFT の非同期ジョブ実行とパラメータチューニングループが加わり、GUI だけで戦略開発ループ全体を回せるようになりました。サーバーと同じマシンに AlphaForge CLI がインストールされていることが前提です（CLI が無い環境では閲覧専用として動作します）。

### バックテスト / 最適化 / WFT の実行

- Detail 画面からバックテストをワンクリックで再実行（実行ログの末尾と新しい run が即座に反映されます）
- 最適化（Optuna）と Walk-Forward Test は**非同期ジョブ**として起動し、SSE でログ・進捗をリアルタイム表示。実行中のジョブはキャンセルできます
- WFT ジョブは記録付き（`--save`）で実行されるため、完了すると WFO タブへ自動反映されます
- 同時実行数とタイムアウトは環境変数 `ALPHA_VIS_JOB_CONCURRENCY` / `ALPHA_VIS_JOB_TIMEOUT` で調整できます（[設定](configuration.md)参照）

### パラメータチューニングループ

戦略構成タブのチューニングパネルで、**編集 → 一時実行 → 比較 → 明示保存** のループを GUI だけで回せます。

1. パラメータを編集して一時実行（元の戦略定義は変更されず、一時的な戦略ファイルで実行されます）
2. 既存のバックテスト結果と横並びで比較
3. 良い結果が得られたら「保存」で初めて戦略定義に書き戻し（明示操作のみ・自動では書き戻しません）

チューニング試行のランは Browse / 実行履歴 / バックテストタブで通常ランと区別して表示されるため、探索の足跡と本採用の結果が混ざりません。

### 戦略の複製ベース新規作成

既存戦略を別 ID で複製して新規戦略として登録できます。テンプレートとして流用しながらパラメータ・条件を変えていく用途を想定しています（ID が衝突する場合はエラーになります）。

## Compare 画面

複数戦略を横並びで比較します。

![Compare 画面](assets/compare.png){ loading=lazy }

![戦略間相関ヒートマップ](assets/compare-heatmap.png){ loading=lazy }

- 指標カード（CAGR / Sharpe / Sortino / MaxDD / Profit Factor 等）の並列表示
- エクイティカーブの重畳描画
- Pearson 相関のヒートマップ（同期間データに正規化）

## Optimize 画面

最適化結果の可視化。

![Optimize 画面](assets/optimize.png){ loading=lazy }

- パラメータ vs 指標の散布図と、パラメータ 2 軸 × 指標のヒートマップをタブで切替（X/Y 軸パラメータと対象メトリクスを選択。セル色＝該当パラメータ組み合わせのメトリクス平均、ホバーでパラメータ組・平均値・trial 件数を表示）
- Walk-Forward Test の合成エクイティカーブ
- 各ウィンドウのパフォーマンス推移

## 戦略構成ビュー

戦略 JSON の構造を可視化します。

![Strategy 構成画面](assets/strategy.png){ loading=lazy }

- 使用指標とパラメータ
- エントリー / イグジット条件式
- リスク管理（ストップ・ポジションサイジング）
- ターゲット銘柄・タイムフレーム

## Live 画面

ライブ / ペーパートレード実績の一覧と、バックテストとの突き合わせ。`/live` でアクセスでき、Browse 画面ヘッダの「Live →」リンクからも遷移できます。

- ライブ実績を持つエントリの一覧（戦略単位 / combine ポートフォリオの両方）
- **戦略単位**（trade ベース）: 総取引数・勝率・プロフィットファクター・最大 DD・純 PnL を、同期間のバックテスト値と diff 付きで比較
- **combine ポートフォリオ**（position ベース）: トータルリターン・CAGR・シャープレシオ・最大 DD・ボラティリティと live equity カーブを、バックテスト combine と比較
- 選択エントリは URL クエリ（`?id=`）に同期されるため共有可能

ライブ実績データは、[alpha-strike](https://github.com/alforge-labs/alpha-strike)（OSS の Webhook 発注サーバー）が記録したイベントログを AlphaForge CLI（`alpha-forge live sync-events` → `live import-events` / `live replay`）で `backtest_results.db` に取り込んだものが自動で表示されます。取り込み手順の詳細は [alpha-strike セットアップガイド](../guides/alpha-strike-setup.md)を参照してください。

## Ideas 画面

探索アイデアの一覧と状態管理。

![Ideas 画面](assets/ideas.png){ loading=lazy }

- ステータス別フィルタ（pending / exploring / promoted / archived 等）
- タグフィルタ
- 戦略リンクでアイデアと実装の対応を追跡

## 横断機能

### グローバル検索（Cmd+K）

任意の画面で `Cmd+K`（macOS）/ `Ctrl+K`（Windows・Linux）でコマンドパレットを開き、戦略名・画面名から即座に遷移できます。

### テーマ切替

ヘッダー右上のトグルでダーク/ライトモードを切替。設定はブラウザの localStorage に保存されます。

### 言語切替

UI を日本語 / 英語に切替可能。スクリーンショット撮影や国際チームとの共有時に便利です。

### エクスポート

- CSV: 各テーブルから取引履歴・指標一覧をダウンロード
- PNG: チャートをそのまま画像保存
- シェアカード: Detail・Compare・Live の各画面から、equity curve と主要指標をまとめた OGP サイズ（1200×630）の PNG カードを書き出し。X などの SNS 投稿にそのまま使えます
- X で共有: シェアカードの保存と X の投稿画面オープン（成績サマリを本文にプリフィル）を1クリックで実行。画像は投稿画面で添付してください
- URL 共有: Browse / Compare の選択状態がクエリ同期されるため、URL コピーで共有可能

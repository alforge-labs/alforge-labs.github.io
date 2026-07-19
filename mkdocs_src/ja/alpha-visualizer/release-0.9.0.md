---
title: alpha-visualizer v0.9.0 リリース — 最適化・WFT の GUI 実行とパラメータチューニングループ（v0.7.1 以降の累積アップデート）
description: alpha-visualizer v0.9.0 は最適化・Walk-Forward Test の非同期ジョブ実行とパラメータチューニングループを追加し、GUI だけで戦略開発ループ全体を回せるように。FX キャリー調整メトリクス表示、X 共有シェアカード、アクセシビリティ強化など v0.7.1 以降の累積ハイライトをまとめます。
---

# alpha-visualizer v0.9.0 リリース — v0.7.1 以降の累積アップデート

> **公開日**: 2026 年 7 月 19 日 / **バージョン**: v0.9.0 / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/0.9.0/)・[GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.9.0)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v0.9.0 の最大の変化は、**最適化・Walk-Forward Test の非同期ジョブ実行とパラメータチューニングループの追加により、GUI だけで戦略開発ループ全体を回せるようになった**ことです。本ノートでは v0.7.1 以降（v0.7.3・v0.8.0・v0.9.0）の累積ハイライトをまとめます。

## ハイライト

### 1. 最適化・WFT の GUI 実行（v0.9.0）

最適化（Optuna）と Walk-Forward Test を**非同期ジョブ**としてブラウザから起動できるようになりました。SSE によるログ・進捗のリアルタイム表示とキャンセルに対応します。WFT ジョブは記録付き（`--save`）で実行されるため、完了すると WFO タブへ自動反映されます。以前から可能だった Detail 画面からのバックテスト再実行も、run の直接取得・タイムアウト・実行ログ表示などで堅牢化しました。

サーバーと同じマシンに AlphaForge CLI がインストールされていることが前提です（CLI が無い環境では従来どおり閲覧専用として動作します）。同時実行数・タイムアウトは `ALPHA_VIS_JOB_CONCURRENCY` / `ALPHA_VIS_JOB_TIMEOUT` で調整できます。

### 2. パラメータチューニングループ（v0.9.0）

戦略構成タブのチューニングパネルで、**編集 → 一時実行 → 比較 → 明示保存** のループを GUI だけで回せます。一時実行は元の戦略定義に触れず、書き戻しは「保存」の明示操作のみ。チューニング試行のランは Browse / 実行履歴 / バックテストタブで通常ランと区別表示されるため、探索の足跡と本採用の結果が混ざりません。既存戦略の**複製ベース新規作成**にも対応しました。

### 3. FX キャリー調整メトリクスの表示（v0.9.0）

AlphaForge v0.18.0 の `backtest run --carry`（FX キャリー / スワップの計上）と連携し、キャリー調整後メトリクス（carry_adjusted）を Detail 画面のバックテストタブにカード表示します。詳細は [AlphaForge 変更履歴](../changelog.md)を参照してください。

### 4. シェアカードと X 共有の拡充（v0.9.0）

equity curve と主要指標をまとめた OGP サイズ（1200×630）の PNG シェアカードを Detail・Compare・Live の各画面から書き出せます。「X で共有」ボタンはカード保存と X 投稿画面のオープン（成績サマリのプリフィル・280 字ガード付き）を 1 クリックで実行します。

### 5. アクセシビリティと UI 品質の底上げ（v0.8.0）

キーボード操作・ARIA ランドマーク・スクリーンリーダー対応・WCAG AA コントラストへの調整を実施しました。ローソク足チャートには OHLC データテーブルの代替表示を追加。ローディングスケルトンの共有化、`Intl` による桁区切り、OS テーマ追従も入っています。

### 6. チャートと最適化ビューの強化（v0.7.3・v0.8.0）

主要チャートの既定レンダラを TradingView lightweight-charts に切り替えました（v0.7.3）。最適化結果には**パラメータ 2 軸 × 指標のヒートマップビュー**が加わり、散布図とタブで切り替えられます（v0.8.0）。

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv add alpha-visualizer@latest        # プロジェクトに追加
uv tool install alpha-visualizer       # CLI として使う
```

同梱サンプルでの動作確認:

```bash
alpha-vis serve --use-bundled-samples --no-open
# http://127.0.0.1:8000 を開く
```

`alpha-forge` プロジェクト側のデータを見る場合:

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

設定ファイル（`forge.yaml`）に変更はありません。GUI 実行機能を使わない場合、既存の使い方はそのまま動作します。

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/0.9.0/>
- **GitHub Release（タグ）**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v0.9.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **インストール手順**: [alpha-visualizer / インストール](installation.md)
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)
- **設定**: [alpha-visualizer / 設定](configuration.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。

---
title: alpha-visualizer v1.2.0 リリース — Live 画面のリッチ化・ブラウズのレシピ化・Maintenance 画面
description: alpha-visualizer v1.2.0 は Live 画面のポートフォリオ表示を KPI・ベンチマーク比較・建玉テーブルの 4 段構成へリッチ化し、ブラウズ画面のレシピ折り畳みと銘柄カバレッジ表、孤児バックテスト結果を掃除する Maintenance 画面を追加します。
---

# alpha-visualizer v1.2.0 リリース — Live 画面のリッチ化・ブラウズのレシピ化・Maintenance 画面

> **公開日**: 2026 年 7 月 27 日 / **バージョン**: v1.2.0（本ノートは v1.2.1 / v1.2.2 のパッチを含む累積） / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/)・[CHANGELOG](https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v1.2.0 の中心は **Live（ペーパートレード実績）画面の大幅リッチ化**と、**戦略が増えても見通しを保つブラウズ画面の再構成**です。

## ハイライト

### 1. Live 画面のポートフォリオ表示リッチ化

combine ポートフォリオの表示を「いくらになったか → 市場に勝てているか → どう推移したか → 何を持っているか」の 4 段構成に再設計しました。

- **KPI 行**: 現在評価額（前日比付き）・累計損益・現在ドローダウン・超過リターン（vs 指数 / vs バックテスト）
- **エクイティ＋ドローダウンチャート**: 指数（Buy & Hold）とバックテスト combine の比較線を重畳表示（`alpha-forge live replay --benchmark / --compare` 実行時）
- **建玉テーブル**: 銘柄・数量・平均取得単価・評価額・構成比・含み損益と集計行

詳細は[機能詳細の Live 画面](features.md#live)を参照してください。

### 2. ブラウズ画面のレシピ折り畳みと銘柄カバレッジ表

同名・同銘柄・同時間軸の戦略を 1 つの「レシピ」に畳んで一覧の見通しを改善しました（行を展開するとパラメータ違いの個別戦略を確認できます）。あわせて**銘柄カバレッジ表**を追加し、銘柄ごとのレシピ数・実行済・未実行の偏りを一目で確認できます（既定は未実行の多い順・行クリックで絞り込み）。

### 3. Maintenance（整理）画面の追加

戦略定義がもう存在しない実行結果（「孤児」）を一覧・選択して削除する `/maintenance` 画面を追加しました。判定・削除はサーバー側で `alpha-forge backtest prune-orphans` に委譲します。孤児には「あえて残した過去の結果」も含まれるため、削除前の確認ダイアログを挟みます。

### 4. 不具合修正（v1.2.0〜v1.2.2）

- Compare 画面で戦略未選択時に永久ローディングになる不具合を修正（v1.2.0）
- ブラウズ画面で戦略選択時に sparkline 取得が無限ループする問題を修正（v1.2.2）
- 依存パッケージのセキュリティアラート解消・表示崩れ修正（v1.2.1）

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

Maintenance 画面と Live の比較線表示には、サーバーと同じマシンに AlphaForge CLI（v1.2 系以降を推奨）がインストールされていることが前提の機能が含まれます。閲覧のみの場合は従来どおり CLI なしで動作します。

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。

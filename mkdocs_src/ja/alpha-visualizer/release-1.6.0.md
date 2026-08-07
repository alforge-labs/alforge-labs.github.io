---
title: alpha-visualizer v1.6.0 リリース — Live ページからライブデータを一括更新
description: alpha-visualizer v1.6.0 は、これまで CLI で 3 コマンドを順に実行する必要があったライブデータの更新を、Live 画面のボタン 1 クリックで完結できるようにするリリースです。replay パラメータは forge.yaml に集約され、初期資本の指定漏れによるリターン率のずれが構造的に起きなくなります。
---

# alpha-visualizer v1.6.0 リリース — Live ページからライブデータを一括更新

> **公開日**: 2026 年 8 月 7 日 / **バージョン**: v1.6.0 / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/)・[GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.6.0)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v1.6.0 は、ペーパートレード／実運用の記録を最新化する作業を GUI に取り込むリリースです。

## ハイライト

### 1. 「ライブデータを更新」ボタン

Live 画面に更新ボタンが加わりました。これまでは CLI で 3 つのコマンドを順に実行する必要がありました。

```bash
alpha-forge live sync-events     # 発注サーバーからイベントを取得
alpha-forge data update          # ヒストリカルデータを差分更新
alpha-forge live replay ...      # ライブ成績を再計算
```

v1.6.0 ではこれが 1 クリックで完結します。進捗はステップごとにリアルタイムで表示され、実行中はキャンセルできます。完了すると一覧と詳細が自動で再取得されます。

詳細は[機能詳細の Live 画面](features.md#live)を参照してください。

### 2. replay パラメータを `forge.yaml` に集約

更新処理は AlphaForge の [`alpha-forge live refresh`](../cli-reference/live.md#alpha-forge-live-refresh) に委譲しています。replay のパラメータは `forge.yaml` の `live.replay` セクションが単一の情報源になります。

```yaml
live:
  replay:
    portfolio_id: ""         # combine portfolio ID
    combine_strategies: []   # combine 対象戦略 ID（2 つ以上）
    initial_capital: null    # 実口座の資本に合わせる
    compare: false           # backtest combine と比較表示するか
```

これにより、**`--initial-capital` の指定漏れでリターン率が実口座比で大きくずれる事故が構造的に起きなくなりました**。バックテストの既定（100,000）のまま実口座が 1,000,000 だと、リターン率は 10 倍ずれます。設定の詳細は [`live replay` の config フォールバック](../cli-reference/live.md#config-livereplay)を参照してください。

!!! warning "AlphaForge v1.4.0 以降が必要です"
    このボタンは `alpha-forge live refresh` を呼び出すため、**AlphaForge v1.4.0 以降**が必要です。それ以前のバージョンでは、未対応である旨の案内が表示されます。

    また LAN 公開（非 loopback）で `alpha-vis serve` している場合、このボタンは無効です（ローカル書き込みを伴う操作のため）。

## 修正

- **ジョブ作成の失敗が画面に表示されない問題を修正しました。** LAN 公開中（403）、AlphaForge 未導入（503）、AI 派生開発で派生元の戦略が見つからない（404）といったケースで、ボタンを押しても何も起きないように見えていました。データ管理画面と AI 戦略開発画面の両方が対象です
- ドキュメント用スクリーンショットが画像の下端で切れることがある問題を修正しました（内部ツール）

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer

# pipx
pipx upgrade alpha-visualizer
```

AlphaForge 側も更新してください。

```bash
alpha-forge self update
```

## 関連ドキュメント

- [機能詳細 — Live 画面](features.md#live)
- [`alpha-forge live refresh`](../cli-reference/live.md#alpha-forge-live-refresh)
- [alpha-strike セットアップガイド](../guides/alpha-strike-setup.md)

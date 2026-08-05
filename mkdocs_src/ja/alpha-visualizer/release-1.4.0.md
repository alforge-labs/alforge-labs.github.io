---
title: alpha-visualizer v1.4.0 リリース — AI 戦略開発（Agent Develop）
description: alpha-visualizer v1.4.0 は GUI から AI エージェントに戦略開発を任せられる「AI 戦略開発（Agent Develop）」を追加。ローカルの claude / codex CLI をヘッドレスで起動し、戦略 JSON の作成からバックテスト検証までを非同期ジョブとして自動実行します。
---

# alpha-visualizer v1.4.0 リリース — AI 戦略開発（Agent Develop）

> **公開日**: 2026 年 8 月 3 日 / **バージョン**: v1.4.0（本ノートは v1.4.1 のパッチを含む累積） / **配布**: [PyPI](https://pypi.org/project/alpha-visualizer/)・[GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.4.0)

[alpha-visualizer](index.md) は、`alpha-forge` が出力するバックテスト結果を Web ブラウザで可視化するスタンドアロンの OSS パッケージです。v1.4.0 では、GUI から AI エージェントに戦略開発を任せられる **AI 戦略開発（Agent Develop）** が加わりました。

## ハイライト

### 1. AI 戦略開発（Agent Develop）

「開発」ビュー（`/develop`）でゴール文・対象銘柄・バックエンド（Claude Code / Codex CLI）を入力すると、ローカルにインストール済みの `claude` / `codex` CLI をヘッドレスで起動し、**戦略 JSON の作成 → `alpha-forge backtest run` による検証 → 完了後に新戦略へのリンク表示**までを非同期ジョブとして自動実行します。ジョブの観察・キャンセルは実行履歴と共通の仕組みです。

セキュリティ設計:

- **API キーは扱いません**。認証・課金は各 CLI の既存ログインに委譲します
- **localhost 限定**。非 loopback バインド（`alpha-vis serve --host 0.0.0.0` 等）では機能自体が無効化されます
- **ワークスペース限定**。claude はツール許可リストをワークスペース配下のパスにスコープし、範囲外の読み書きを拒否します（codex は `--sandbox workspace-write` の OS レベルサンドボックス）

!!! warning "外部通信について"
    本機能はユーザー自身の `claude` / `codex` CLI をそのまま起動します。これらの CLI は Anthropic / OpenAI と通信します。alpha-visualizer 自体は API キーの入力・保存・送信を一切行いません。

使い方・権限モデル・ターン上限の詳細は[機能詳細の Develop 画面](features.md#develop)を参照してください。

### 2. ターン上限まわりの改善（v1.4.1）

claude バックエンドがターン上限（`--max-turns`）に達して打ち切られた場合に、その旨と上限値を正しくエラー表示するようになりました（従来は別要因のエラーと誤診断されることがありました）。

## アップグレード方法

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

AI 戦略開発を使う場合は、`claude`（Claude Code）または `codex`（Codex CLI）が PATH にあり認証済みであること、`alpha-forge` が導入済みであることが前提です。使わない場合、既存の使い方はそのまま動作します。

## 関連リンク

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.4.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **機能詳細**: [alpha-visualizer / 機能詳細](features.md)

不具合報告や機能要望は [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) までお願いします。

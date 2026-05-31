# alforge-labs.github.io

[![Downloads (total)](https://img.shields.io/github/downloads/alforge-labs/alforge-labs.github.io/total?logo=github&label=downloads)](https://github.com/alforge-labs/alforge-labs.github.io/releases)
[![Downloads (trend)](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Falforge-labs%2Falforge-labs.github.io%2Fdownload-stats%2Fdownload-badge.json)](https://github.com/alforge-labs/alforge-labs.github.io/blob/download-stats/download-stats.jsonl)

Alforge Labs のランディングページ（静的サイト）。

> 左バッジは GitHub Releases アセットの累計 DL 数（shields.io 組み込み・リアルタイム）。
> 右バッジは `Release Download Stats` ワークフロー（毎日 03:00 UTC）が
> `download-stats` ブランチに蓄積する時系列から算出した「累計（直近7日差分）」。
> 右バッジは初回ワークフロー実行後に表示されます。時系列の生データは
> [`download-stats` ブランチの `download-stats.jsonl`](https://github.com/alforge-labs/alforge-labs.github.io/blob/download-stats/download-stats.jsonl) を参照。

## 概要

- アルゴリズム取引システム「AlphaTrade」の公開向けホームページ
- 日英バイリンガル対応（ページ内でトグル切替）
- ダーク / ライトテーマ対応
- ビルドツール不要の純粋な HTML + React（CDN 経由）構成

## ファイル構成

```
alforge-labs/
├── index.html              # エントリポイント（CSS / テーマトークン含む）
├── homepage-copy.jsx       # 日英コピーテキスト（window.COPY）
├── homepage-components.jsx # 再利用 UI コンポーネント
└── homepage-app.jsx        # ページ全体のレイアウトと状態管理
```

## ローカル確認

```bash
# 任意の HTTP サーバーで開く（ファイルを直接開くと Babel が動作しない場合あり）
npx serve .
# または
python3 -m http.server 8080
```

## デプロイ

GitHub Pages に自動デプロイされます（`alforge-labs/alforge-labs.github.io` リポジトリの `main` ブランチ）。  
このディレクトリの変更を push すると反映されます。

## 掲載コンテンツ

- **Hero**: キャッチコピー・バックテスト実績スタッツ
- **Products**: forge / strategies / strike の 3 プロダクト紹介
- **Performance**: GC=F（金先物）HMM+BB+RSI 戦略の 10 年バックテスト結果
- **Roadmap**: 2025 Q1 〜 2027 の開発マイルストーン
- **FAQ**: よくある質問
- **Follow CTA**: X（旧 Twitter）@alforge_bot へ誘導

## コミュニティ

- [GitHub Discussions](https://github.com/alforge-labs/alforge-labs.github.io/discussions) — 質問・アイデア・戦略共有のコミュニティ（日英両対応）

# 配布用 記事ドラフト（dev.to / Zenn）

AlphaForge ローンチ流通トラックの記事ドラフト。**公開は各プラットフォームで手動**（自動投稿は規約グレー）。`marketing/` 配下のため build.py / mkdocs のビルド対象外。

| ファイル | 用途 |
|---------|------|
| `devto_article.md` | dev.to 英語記事（**canonical 本家**＝`canonical_url` 空）。front-matter 込み・貼付して `published: true` で公開。tags は4個まで |
| `zenn_article_ja.md` | Zenn 日本語全文。Zenn front-matter 込み（emoji/type/topics）・`published: false`→確認後 true |
| `devto_cover.png` | dev.to カバー（1000×420）。dev.to の `cover_image` にアップロード。※Bash 復旧後にコミット追加予定 |

## 検証メモ
- CLI スニペットは実 alpha-forge で検証済み: `system describe` / `optimize run` / `optimize walk-forward` / `pine generate` / `optimize sensitivity`。自律探索は CLI でなく `explore-strategies` エージェントスキル。`analyze pbo` 等の架空コマンドは使わない。
- 実績数値は実バックテストで検証済み（等加重 TQQQヘッジ+GLD+TLT: 複合MDD≈10%・CAGR15.5%・Sharpe1.20・WFT5窓全正）。**免責必須**。旧 launch 原稿の「-35→-23%」は実態と不一致のため使わない。

## 公開手順
1. dev.to: `devto_article.md` を貼付 → カバー画像アップロード → tags 確認 → `published: true`。
2. Zenn: `zenn_article_ja.md` を貼付/push（GitHub 連携 + zenn-cli 可）→ `published: true`。
3. 公開後、@Alforge_bot で記事を1本紹介（連載 hero と連動）。

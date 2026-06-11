# alforge-labs ホームページ

alforge-labs.github.io のランディングページです。

> 親 `alpha-trade/CLAUDE.md` の 9-rule template・プロジェクト固有ガイド・ワークツリー / GitHub Flow / TDD / `uv` 等のルールに従うこと。本ファイルには alforge-labs 固有の事項（ビルドシステム・テンプレート編集ルール）のみ記載する。なお、親 `alpha-trade/CLAUDE.md` 指針10「ドキュメント同期」で alpha-forge / alpha-strike の変更時に本リポジトリの MkDocs ビルドを実行する旨が規定されている。

## ビルドシステムの概要

```
templates/*.html.j2   ← 編集するのはここだけ
    ↓ uv run python build.py
ja/*.html, en/*.html  ← 生成物（直接編集禁止）
```

| ファイル種別 | 役割 | 編集可否 |
|---|---|---|
| `templates/*.html.j2` | Jinja2 テンプレート（HTML の正）| ✅ 編集する |
| `templates/_partials/` | テンプレート共通パーツ | ✅ 編集する |
| `homepage-copy.jsx` | コピー文・多言語テキスト | ✅ 編集する |
| `homepage-components.jsx` | React コンポーネント | ✅ 編集する |
| `site-header.jsx` | 全ページ共通ヘッダー | ✅ 編集する |
| `page.css` | standalone ページ用スタイル（外部参照） | ✅ 編集する（※後述） |
| `ja/*.html`, `en/*.html` | ビルド生成物 | ❌ 直接編集禁止 |

---

## 🚨 重要ルール

### 1. 生成 HTML を直接編集しない

`ja/index.html` / `en/install.html` などの生成ファイルを直接編集してはいけません。
次回 `build.py` を実行すると上書きされ、変更が失われます。

**正しい手順:**
1. `templates/*.html.j2` を編集する
2. `uv run python build.py` を実行する
3. 生成された `ja/*.html` / `en/*.html` をコミットに含める

### 2. page.css の変更は index テンプレートにも反映する

`page.css` は standalone ページ（install.html 等）が外部参照するスタイルシートです。
`templates/index.html.j2` には **CSS がインラインで埋め込まれている** ため、
`page.css` を変更した場合は `templates/index.html.j2` の対応箇所も同時に更新すること。

> **過去の失敗例**: `page.css` に `nav-mkdocs-link` スタイルを追加したが
> `templates/index.html.j2` への反映を忘れ、LP の「ドキュメント」リンクの
> 強調表示が反映されなかった（issue #124）。

### 3. HTML 変更後は必ず build.py を実行してコミットに含める

テンプレートや JSX を変更したら、必ず以下を実行してから PR を作成すること:

```bash
uv run python build.py
```

生成された `ja/*.html` / `en/*.html` も同一コミット（または同一 PR）に含めること。

### 4. MkDocs ドキュメントのビルドは別コマンド

MkDocs ドキュメント（`mkdocs_src/`）を変更した場合は別途:

```bash
uv run mkdocs build -f mkdocs.ja.yml
uv run mkdocs build -f mkdocs.en.yml
```

を実行して `ja/docs/` / `en/docs/` を再生成すること。

### 5. 新規 React コンポーネントは window に登録する

`homepage-components.jsx` / `site-header.jsx` で定義したコンポーネントは、ファイル末尾の
`Object.assign(window, { ... })` に必ず追加すること。各 JSX は独立した script として
ロードされるため、登録を忘れると `app.jsx` から undefined 参照になり**ページ全体が白画面**になる
（過去に2回発生）。検証は本番と同一の babel transpile + headless ブラウザでの実描画で行うこと。

---

## ファイル構成

```
alforge-labs/
├── templates/               # Jinja2 テンプレート（HTML の正）
│   ├── index.html.j2
│   ├── install.html.j2
│   ├── docs.html.j2         # install.html#commands へのリダイレクト
│   ├── tutorial-strategy.html.j2
│   ├── privacy.html.j2
│   ├── terms.html.j2
│   └── _partials/
├── build.py                 # テンプレートから ja/*.html / en/*.html を生成
├── seo.yaml                 # SEO メタデータ
├── homepage-copy.jsx        # テキストコンテンツ（多言語）
├── homepage-components.jsx  # React コンポーネント
├── site-header.jsx          # 全ページ共通ヘッダー
├── page.css                 # standalone ページ用外部スタイル
├── mkdocs_src/              # MkDocs ドキュメントソース
│   ├── ja/
│   └── en/
├── ja/                      # ビルド生成物（日本語）
│   ├── *.html               # build.py 生成
│   └── docs/                # mkdocs build 生成
└── en/                      # ビルド生成物（英語）
    ├── *.html               # build.py 生成
    └── docs/                # mkdocs build 生成
```

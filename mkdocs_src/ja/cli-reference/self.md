# alpha-forge self

alpha-forge バイナリ自身を更新・確認するためのコマンド群（macOS arm64 / x64 サポート、Phase 1）。`alpha-forge` リポジトリで [issue #693](https://github.com/ysakae/alpha-forge/issues/693) として導入。

## alpha-forge self version

現在のバージョンと配布リポジトリ（`alforge-labs/alforge-labs.github.io`）の最新リリースを表示します。`self` 配下は Whop 認証チェックをスキップするため、ログイン状態に関係なく実行できます。

```bash
alpha-forge self version
```

サンプル出力：

```text
現在のバージョン: 0.3.1
最新リリース   : 0.4.0  (https://github.com/alforge-labs/alforge-labs.github.io/releases/tag/v0.4.0)
新しいバージョンが利用可能です: 0.4.0 (available)
アップデート: alpha-forge self update
```

## alpha-forge self update

alpha-forge バイナリを最新版に更新します。GitHub Releases から SHA256 検証付きでダウンロード → アトミックに `forge.dist` を差し替え → 旧バイナリを `forge.dist.bak-<unix_ts>` として最新 2 世代まで保持します。

```bash
alpha-forge self update                 # プロンプトで確認 [y/N]
alpha-forge self update --yes           # 確認をスキップ（CI 用）
alpha-forge self update --check         # ダウンロードせず確認のみ
alpha-forge self update --version 0.4.0 # 任意バージョンへピン留め
alpha-forge self update --dry-run       # DL・検証・展開のみ実行（差し替えなし）
alpha-forge self update --print-target  # 検出したインストールレイアウトを表示（トラブル時に共有）
alpha-forge self update --force         # 既に最新でも再ダウンロードする
alpha-forge self update --no-smoke-test # 差し替え後の起動確認をスキップ（CI 等で時間を惜しむ場合）
```

### 動作する条件

`install.sh` でインストールされた **forge.dist ディレクトリ + symlink 形式**（典型: `~/.local/share/alpha-forge/forge.dist/` + `~/.local/bin/forge`）で動作します。

| 環境 | 動作 |
|------|------|
| macOS arm64 / x64（install.sh 経由） | ✅ サポート |
| Windows x64 | ✅ サポート |
| Linux x64 | ⚠️ Phase 3 で対応予定 |
| 開発モード（`uv run alpha-forge`） | ⚠️ `DevModeError` で停止（`git pull && uv sync` を使ってください） |

### 内部動作

1. 配布リポジトリ `alforge-labs/alforge-labs.github.io` の Releases API から最新タグを取得
2. プラットフォームに合うアセット（例: `alpha-forge-macos-arm64.tar.gz`）と `SHA256SUMS` をダウンロード
3. ハッシュ検証 → 一時ディレクトリに展開
4. `forge.dist` を `forge.dist.bak-<unix_ts>` にリネーム（atomic）
5. 新しい `forge.dist` をアトミックに配置
6. `$BIN_DIR/forge` symlink が壊れていれば再作成

途中で失敗した場合、旧バイナリは無傷で残り、`forge.dist.bak-*` から復旧できます（Phase 2 で `alpha-forge self rollback` を提供予定）。

---

# FAQ・トラブルシューティング

## インストール・起動

### AlphaForge なしで試せますか？

はい。同梱の合成サンプルデータで、AlphaForge をインストールせずにダッシュボード全体を試せます。

```bash
alpha-vis serve --use-bundled-samples
```

自分のバックテスト結果を可視化する段階になったら AlphaForge を導入してください。手順は[インストール直後の動作確認（サンプルデータ）](installation.md#try-with-samples)を参照してください。

### `alpha-vis: command not found` が出る

`uv tool install` でインストールした場合、シェルの PATH に uv のツールディレクトリが含まれている必要があります。

```bash
# uv tool dir を確認
uv tool dir
# 例: /Users/<you>/.local/bin が含まれているか
echo $PATH

# 含まれていない場合
export PATH="$HOME/.local/bin:$PATH"
```

### `backtest_results.db` が見つからない / 戦略が表示されない

`alpha-vis serve` が見ている `<forge-dir>/data/results/backtest_results.db` が存在しない可能性があります。

```bash
# 起動時に解決されたパスを確認（alpha-vis serve のログに表示される）
alpha-vis serve --forge-dir <path>

# 想定パスを直接確認
ls <path>/data/results/backtest_results.db
ls <path>/data/strategies/
```

`alpha-forge backtest run` を一度も実行していない場合、`backtest_results.db` は作成されません。最低 1 件のバックテストを実行してから `alpha-vis serve` を試してください。

### ポートが既に使用されている

```
ERROR:    [Errno 48] error while attempting to bind on address ('127.0.0.1', 8000): address already in use
```

別のポートを指定するか、既存プロセスを停止してください。

```bash
alpha-vis serve --port 9000

# 8000 番を使っているプロセスを確認
lsof -i :8000
```

### ブラウザが自動で開かない

`--no-open` を付けていない状態で開かない場合、ブラウザの自動起動が OS / WSL 等の環境で抑止されている可能性があります。手動で <http://127.0.0.1:8000> にアクセスしてください。

## 動作

### 結果が古いまま表示される

`backtest_results.db` 更新後はダッシュボードをリロード（`Cmd+R` / `F5`）してください。自動再読み込み機能は現状ありません。

### 戦略名が `undefined` と表示される

戦略 JSON に `name` フィールドがない、または `latest_*` 系の指標がまだ計算されていない可能性があります。最新版（v0.1.1+）では undefined ガードが入っているため、`pip install --upgrade alpha-visualizer` を試してください。

### Compare 画面で相関ヒートマップが表示されない

選択した戦略間で **共通する取引期間が無い** 場合、相関は計算できません。期間が重なる戦略を選択してください。

## リモート・本番運用

### 別マシンからアクセスしたい

```bash
alpha-vis serve --host 0.0.0.0 --port 8000
```

その上で：

- ファイアウォールで該当ポートを開く
- 本番では SSH ポートフォワードや VPN 経由を推奨（認証機構が無いため）

### HTTPS で公開したい

組み込みの TLS 終端は無いため、リバースプロキシ（nginx / Caddy / Cloudflare Tunnel）で終端してください。

### 認証を追加したい

組み込みの認証機構はありません。リバースプロキシ層で Basic 認証 / OAuth Proxy / Tailscale Auth などを設定してください。

## 開発・コントリビューション

### バグ報告・機能要望はどこに

[GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) で日本語・英語のテンプレートが用意されています。

### セキュリティ脆弱性の報告

公開 Issue ではなく、[SECURITY.md](https://github.com/alforge-labs/alpha-visualizer/blob/main/SECURITY.md) の手順に従って GitHub Private Vulnerability Reporting または `security@alforgelabs.com` でご連絡ください。

### 開発に参加したい

[CONTRIBUTING.md](https://github.com/alforge-labs/alpha-visualizer/blob/main/CONTRIBUTING.md) を参照してください。GitHub Flow ベースで Pull Request を歓迎します。

## バージョン・互換性

### 動作確認済みの alpha-forge バージョン

`alpha-visualizer` は `backtest_results.db`（SQLite）のスキーマと戦略 JSON 構造に依存します。**同時期に開発・検証されたペア**を使うのが最も確実です。

| alpha-visualizer | alpha-forge | 備考 |
|---|---|---|
| v1.4.x（2026-08） | v1.3.0 | AI 戦略開発（Agent Develop）を追加 |
| v1.3.x（2026-08） | v1.3.0 | 実行時パラメータ表示（params_json）は forge v1.3.0 が必要 |
| v1.2.x（2026-07） | v1.2.0 | Live の比較線表示は `live replay --benchmark / --compare` が必要 |
| v1.0.x〜v1.1.x（2026-07） | v1.0.x〜v1.1.0 | 4 プロダクト同時 GA（2026-07-21）以降のペア |
| v0.9.0（2026-07） | v0.18.x | キャリー調整メトリクス表示は `backtest run --carry` が必要 |

DB は列を後から追加する方式で拡張されているため、**古い alpha-forge が生成した DB も基本的に閲覧できます**（新しい列に依存する表示だけが出ません）。逆に、GUI からの実行系機能（バックテスト / 最適化 / データ取得 / Pine 出力など）は、対応するサブコマンドを持つ新しめの alpha-forge CLI が必要です。CLI が古い場合は画面に更新を促すメッセージが表示されます。

### Python 3.11 以下で動かしたい

サポート対象は Python 3.12 以上です。それ以下の Python では動作保証していません。

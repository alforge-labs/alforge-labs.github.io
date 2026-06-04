# 設定

## CLI オプション

### `alpha-vis serve`

Web ダッシュボードを起動します。

```bash
alpha-vis serve [OPTIONS]
```

| オプション | デフォルト | 説明 |
|---|---|---|
| `--forge-dir DIRECTORY` | `.`（カレントディレクトリ） | `alpha-forge` の出力 DB が置かれているディレクトリ |
| `--forge-config FILE` | `<forge-dir>/forge.yaml` | 明示的に指定したい場合の `forge.yaml` パス |
| `--host TEXT` | `127.0.0.1` | バインドするホスト名 |
| `--port INTEGER` | `8000` | ポート番号 |
| `--no-open` | — | 起動時にブラウザを自動で開かない |

ヘルプ表示:

```bash
alpha-vis --help
alpha-vis serve --help
```

## データパス（ForgeConfig）

`alpha-vis serve` は `--forge-dir` を起点に以下のパスを解決します。

| 用途 | パス |
|---|---|
| バックテスト結果 DB | `<forge-dir>/data/results/backtest_results.db` |
| 戦略 JSON | `<forge-dir>/data/strategies/*.json` |
| アイデア一覧 | `<forge-dir>/data/ideas/ideas.json` |
| ライブ実績 | `<forge-dir>/data/live/` |

`forge.yaml` に `report.output_path` / `report.db_filename` / `strategies.path` / `ideas.ideas_path` が設定されている場合、それらが優先されます。

## `forge.yaml` の例

```yaml
report:
  output_path: ./data/results
  db_filename: backtest_results.db
strategies:
  path: ./data/strategies
  use_db: false
ideas:
  ideas_path: ./data/ideas
```

`forge.yaml` を `<forge-dir>` の直下に置けば自動で読み込まれます。別の場所に置きたい場合は `--forge-config` で明示してください。

## 環境変数

| 変数 | 用途 |
|---|---|
| `FORGE_CONFIG` | `--forge-config` と同等の指定（CLI 引数の方が優先） |

CI などで明示的にクリアしたい場合は `env FORGE_CONFIG= alpha-vis serve ...` のように空に設定できます。

## リモート公開時の注意

`--host 0.0.0.0` で外部ネットワークに公開する場合：

- **認証機能は組み込まれていません**。VPN・SSH ポートフォワード・社内ネットワーク等での運用を前提としてください。
- パブリックなインターネットに直接公開する場合はリバースプロキシ（nginx / Caddy）と Basic 認証や SSO を組み合わせてください。
- ブラウザ⇄サーバー間の通信は HTTP です。TLS が必要ならリバースプロキシで終端します。

## ファイル変更の反映

`alpha-forge backtest run` や `alpha-forge optimize run` を実行すると `backtest_results.db` が更新されます。ダッシュボードはリロード（`Cmd+R` / `F5`）で最新結果を取得します（自動再読み込みは未対応）。

## 関連リンク

- [機能詳細](features.md): ダッシュボード各画面
- [FAQ](faq.md): トラブルシューティング
- [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues): バグ報告・機能要望

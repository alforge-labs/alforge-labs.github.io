# インストール

`alpha-visualizer` は PyPI で配布されています。Python 3.12 以上が必要です。

!!! tip "AlphaForge が無くても試せます"
    `alpha-visualizer` は同梱の合成サンプルデータを持っており、**AlphaForge をインストールしなくても全画面を試せます**（後述の[インストール直後の動作確認](#try-with-samples)参照）。自分のバックテスト結果を可視化する段階になったら、`backtest_results.db` を生成する `alpha-forge` 本体を [AlphaForge スタートガイド](../getting-started.md) からインストールしてください（最新バイナリは [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases/latest) からも取得可能）。

## 動作要件

| 項目 | バージョン |
|---|---|
| Python | 3.12 以上 |
| OS | macOS / Linux / Windows |
| ブラウザ | Chrome / Firefox / Safari / Edge の最新版 |

## uv（推奨）

[uv](https://docs.astral.sh/uv/) を使うと専用のツール環境にインストールでき、Python のバージョン競合を気にせず使えます。

```bash
uv tool install alpha-visualizer
```

uv 自体の導入が必要な場合は <https://docs.astral.sh/uv/getting-started/installation/> を参照してください。

## pip

通常の Python 環境にインストールする場合：

```bash
pip install alpha-visualizer
```

仮想環境内へのインストール例：

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install alpha-visualizer
```

## ソースから（開発者向け）

GitHub から clone してローカルで動作させる場合：

```bash
git clone https://github.com/alforge-labs/alpha-visualizer.git
cd alpha-visualizer
uv sync                            # Python 依存関係
cd frontend && pnpm install && pnpm run build && cd ..
uv run alpha-vis serve --forge-dir <path>
```

開発フローの詳細は [CONTRIBUTING.md](https://github.com/alforge-labs/alpha-visualizer/blob/main/CONTRIBUTING.md) を参照してください。

## インストール確認

```bash
alpha-vis --version
```

正常にインストールされていれば、バージョン番号が表示されます。

## インストール直後の動作確認（サンプルデータ） { #try-with-samples }

AlphaForge のインストールや自分のバックテスト結果が無くても、同梱の合成サンプルデータでダッシュボード全体を動かして確認できます。

```bash
alpha-vis serve --use-bundled-samples
```

ブラウザが自動で開き（開かない場合は <http://127.0.0.1:8000>）、サンプルの戦略・バックテスト結果・アイデアで Browse / Detail / Compare などの各画面を一通り試せます。`--use-bundled-samples` 指定時は `--forge-dir` / `--forge-config` は無視されます。

自分のデータを見る段階になったら、`alpha-forge` でバックテストを実行してから次のように起動します。

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

## アップグレード

```bash
# uv
uv tool upgrade alpha-visualizer

# pip
pip install --upgrade alpha-visualizer
```

## アンインストール

```bash
# uv
uv tool uninstall alpha-visualizer

# pip
pip uninstall alpha-visualizer
```

## 次のステップ

- [機能詳細](features.md) で各画面の使い方を確認
- [設定](configuration.md) で CLI オプション・`forge.yaml` を確認

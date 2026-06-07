# エージェントから見た CLI 規約

alpha-forge CLI は、AI エージェントやシェルスクリプトからの**無人実行**を前提に設計されています。確認プロンプトで止まらない**非対話モード**、機械可読な**構造化出力（JSON）**、そして分岐に使える**終了コード規約**を全コマンドで統一しているため、エージェントは出力をパースし、終了コードで挙動を判断するだけで安全にループを回せます。

このページは規約の詳細リファレンスです。探索ワークフローのなかでの位置づけは [自律探索ワークフロー](./exploration-workflow.md) を、MCP 経由での利用は [MCP リファレンス](./mcp-reference.md) を参照してください。

!!! note "前提"
    コマンド例は作業ディレクトリのカレントで `alpha-forge` を直接呼ぶ形で記載しています。開発者向けの alpha-trade モノレポで作業している場合は、各コマンドを `FORGE_CONFIG=forge.yaml uv --directory alpha-forge run alpha-forge ...` に読み替えてください。

---

## 非対話実行

破壊的・上書き操作（`strategy delete` / `strategy purge` / `optimize clean` / `pine clean` など）には確認プロンプトがあります。CI・パイプ・エージェント（subprocess）などの非対話環境では、これらのプロンプトでハングするおそれがあるため、`alpha-forge` は次の仕組みで非対話モードへ自動的に切り替わります。

- **環境変数で一括無効化**: `FORGE_NONINTERACTIVE=1`（`true` / `yes` / `on` も可）または `CI` を truthy に設定すると、すべての確認プロンプトを非対話モードに倒します。
- **TTY 自動検知**: 標準入力が TTY でない（パイプ・subprocess 実行）場合も、上記の環境変数なしで自動的に非対話モードとして扱われます。
- **破壊的操作の安全側停止**: 削除・上書きなどの破壊的操作は、`--yes` / `-y` が無いと **終了コード `2` で即停止**します（黙ってハングしません）。
- **EULA は別の環境変数**: 初回起動時の EULA 同意プロンプトは `FORGE_NONINTERACTIVE` では自動同意されません。CI 等では `FORGE_ACCEPT_EULA=1` を併用してください。

### 推奨フロー（dry-run → --yes）

破壊的コマンドは、まず `--dry-run` で対象件数を確認してから `--yes` で実行する 2 段構えが安全です。

```bash
# 1) まず影響範囲を確認（何も削除しない）
FORGE_NONINTERACTIVE=1 alpha-forge optimize clean --older-than 30d --dry-run --json

# 2) 件数に納得したら --yes を付けて実行
FORGE_NONINTERACTIVE=1 alpha-forge optimize clean --older-than 30d --yes --json
```

`--yes` を付け忘れても、非対話モードでは黙って削除されることはなく、終了コード `2` で停止します。

```bash
# --yes を忘れた場合（破壊的操作は実行されず exit 2 で停止）
FORGE_NONINTERACTIVE=1 alpha-forge optimize clean --older-than 30d --json
echo "exit: $?"   # 2 = 非対話実行で --yes 欠落
```

---

## JSON 出力

`--json` を付けたコマンドは、エージェントがパースしやすいよう次の規約に従います。

- **stdout は純 JSON のみ**: 装飾・進捗・警告はすべて stderr に分離されます。エージェントは stdout をそのまま `jq` などに流し込めます。
- **一覧系の envelope**: 一覧を返すコマンドは `{"<複数形>": [...], "count": n}` の形で包みます（例: `{"strategies": [...], "count": 12}`）。
- **not found エラー**: 対象が見つからない場合は stdout に `{"error": "...", "code": "...", "id": "..."}` を出力し、終了コード `1` を返します。

```bash
# 戦略一覧から ID だけを抜き出す（stdout は純 JSON なのでそのまま jq に渡せる）
alpha-forge strategy list --json | jq -r '.strategies[].id'
```

```bash
# 存在しない戦略を指定した例（stdout はエラー JSON、終了コードは 1）
alpha-forge strategy get does_not_exist --json
# stdout: {"error": "strategy not found", "code": "strategy_not_found", "id": "does_not_exist"}
echo "exit: $?"   # 1
```

!!! tip "進捗バーと JSON の分離"
    バックテストや最適化の進捗バーは stderr に出ます。`--json` の出力を変数に取り込んでも、進捗表示が混ざって JSON パースが壊れることはありません。

---

## 終了コード規約

すべてのコマンドが次の 3 値の終了コード規約に従います。エージェントはこの値だけで次の動作を機械的に決められます。

| 終了コード | 意味 | エージェントが取るべき動作 |
|-----------|------|--------------------------|
| `0` | 成功（ユーザーによる明示キャンセルを含む） | 結果（JSON）を読み取って次へ進む |
| `1` | not found / 想定内の実行失敗 | 対象が存在しない・実行が失敗したものとして扱う（無人ループの停止判定にも使う） |
| `2` | 引数エラー・非対話実行で `--yes` 欠落 | 引数を直す、または `--yes` を補って**再実行**する |

- **`2` を受け取ったら**: コマンドの組み立てが誤っている合図です。引数を修正するか、破壊的操作なら `--yes` を補ってから再実行してください。リトライしても引数が同じなら再び `2` になります。
- **`1` を受け取ったら**: 「対象が無い」「想定内の失敗」として扱い、無限リトライせずに次の候補へ進むか、ループを止めてください。

---

## 実効設定の確認

エージェントが「いまどの設定で動いているか」を診断するには `alpha-forge system config` を使います。`FORGE_CONFIG` の解決先を踏まえた**実効値**を表示し、秘匿値はマスクされます。

```bash
# 実効設定をまとめて確認
alpha-forge system config --json

# 特定キーだけを確認（dotted key 指定）
alpha-forge system config data.provider --json
```

無人ランの開始前にこのコマンドを 1 回流しておくと、想定外のデータパスやプロバイダー設定で走り出す事故を防げます。

---

## 無人ループでの安全パターン

エージェントが長時間ループを安全に回すためのチェックリストです。

- [ ] **`FORGE_NONINTERACTIVE=1` を常時付与する** — 確認プロンプトでのハングを防ぎます（非 TTY でも自動有効ですが、明示しておくと意図が明確になります）。
- [ ] **破壊的操作は `--dry-run` → `--yes` の 2 段で行う** — 先に件数を確認し、納得してから実行します。`--yes` 忘れは exit `2` で安全側に止まります。
- [ ] **結果は `--json` で取得し終了コードで分岐する** — stdout の JSON をパースし、`0` / `1` / `2` で次の動作を決めます。

```bash
# 無人ループ 1 反復のイメージ
export FORGE_NONINTERACTIVE=1
alpha-forge backtest run SPY --strategy my_rsi_v1 --json
case $? in
  0) echo "成功: 結果 JSON を解析" ;;
  1) echo "not found / 実行失敗: 次の候補へ" ;;
  2) echo "引数エラー: コマンドを修正して再実行" ;;
esac
```

---

## 関連リンク

- [自律探索ワークフロー](./exploration-workflow.md) — 非対話実行のワークフロー内での使い方
- [MCP リファレンス](./mcp-reference.md) — MCP 経由でこれらのコマンドをツールとして呼ぶ場合の規約
- [CLI リファレンス](../cli-reference/index.md) — 各コマンドの全オプション

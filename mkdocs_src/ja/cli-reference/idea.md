# alpha-forge idea

投資アイデアの記録・タグ付け・検索を行うコマンドグループ。`config.ideas.ideas_path` 配下の `ideas.json` で管理します。

## alpha-forge idea add

新しいアイデアを追加します。

```bash
alpha-forge idea add <TITLE> --type <new_strategy|improvement> [OPTIONS]
```

| 名前 | 種別 | デフォルト | 説明 |
|------|------|----------|------|
| `TITLE` | 引数（必須） | - | アイデアのタイトル |
| `--type` | 必須（choice） | - | `new_strategy` / `improvement` |
| `--desc` | オプション | `""` | 詳細説明 |
| `--tag` | 複数指定可 | - | タグ |

出力: `追加しました: [<idea_id>] <title>`

## alpha-forge idea list

アイデア一覧を表示します。

```bash
alpha-forge idea list [--status <STATUS>] [--tag <TAG>] [--strategy <ID>] [--json]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `--status` | choice | `backlog` / `in_progress` / `tested` / `archived` |
| `--tag` | 複数指定可 | タグ AND フィルタ |
| `--strategy` | オプション | 戦略 ID フィルタ |
| `--json` | フラグ | 結果を JSON で出力（`{ideas: [...], count}`） |

## alpha-forge idea show

アイデアの詳細を表示します。

```bash
alpha-forge idea show <IDEA_ID> [--json]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `--json` | フラグ | 結果を JSON で出力（`IdeaRecord` を dump。不在時は stdout に `{error, code, id}` + 終了コード `1`） |

存在しない場合は `見つかりません: <id>` を出して終了コード `1`（`--json` 時は stdout に JSON エラー）。

## alpha-forge idea status

アイデアのステータスを更新します。

```bash
alpha-forge idea status <IDEA_ID> <backlog|in_progress|tested|archived>
```

出力: `ステータスを更新しました: <title> → <status>`

## alpha-forge idea link

アイデアに戦略または実行記録をリンクします。

```bash
alpha-forge idea link <IDEA_ID> --strategy <ID> [--run <RUN_ID>] [--note <TEXT>]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `--strategy` | 必須 | リンク先の戦略 ID |
| `--run` | オプション | リンク先の `run_id`（指定すれば run と紐付け） |
| `--note` | オプション | リンクへのメモ |

## alpha-forge idea tag

アイデアのタグを追加・削除します（`--add` と `--remove` は同時指定可、両方未指定はエラー）。

```bash
alpha-forge idea tag <IDEA_ID> [--add <TAG>] [--remove <TAG>]
```

## alpha-forge idea note

アイデアにメモを追加します。

```bash
alpha-forge idea note <IDEA_ID> <TEXT>
```

## alpha-forge idea search

アイデアを全文検索します。

```bash
alpha-forge idea search [QUERY] [--status <STATUS>] [--tag <TAG>] [--json]
```

| 名前 | 種別 | 説明 |
|------|------|------|
| `QUERY` | 引数（任意） | 検索クエリ（タイトル・説明・メモを対象） |
| `--status` | choice | ステータスフィルタ |
| `--tag` | 複数指定可 | タグフィルタ |
| `--json` | フラグ | 結果を JSON で出力（`{ideas: [...], count}`） |

---

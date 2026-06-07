# alpha-forge idea

Record, tag, and search investment ideas. Stored as `ideas.json` under `config.ideas.ideas_path`.

## alpha-forge idea add

Add a new idea.

```bash
alpha-forge idea add <TITLE> --type <new_strategy|improvement> [OPTIONS]
```

| Name | Kind | Default | Description |
|------|------|---------|-------------|
| `TITLE` | argument (required) | - | Idea title |
| `--type` | required (choice) | - | `new_strategy` / `improvement` |
| `--desc` | option | `""` | Description |
| `--tag` | repeatable | - | Tags |

Output: `Added: [<idea_id>] <title>`.

## alpha-forge idea list

List ideas.

```bash
alpha-forge idea list [--status <STATUS>] [--tag <TAG>] [--strategy <ID>] [--json]
```

| Name | Kind | Description |
|------|------|-------------|
| `--status` | choice | `backlog` / `in_progress` / `tested` / `archived` |
| `--tag` | repeatable | Tag AND filter |
| `--strategy` | option | Strategy ID filter |
| `--json` | flag | Emit the result as JSON (`{ideas: [...], count}`) |

## alpha-forge idea show

Show idea details.

```bash
alpha-forge idea show <IDEA_ID> [--json]
```

| Name | Kind | Description |
|------|------|-------------|
| `--json` | flag | Emit the result as JSON (dumps `IdeaRecord`; not-found returns `{error, code, id}` to stdout with exit code `1`) |

If not found: `Not found: <id>` and exit code `1` (a JSON error to stdout when `--json`).

## alpha-forge idea status

Update an idea's status.

```bash
alpha-forge idea status <IDEA_ID> <backlog|in_progress|tested|archived>
```

Output: `Status updated: <title> → <status>`.

## alpha-forge idea link

Link a strategy or run to an idea.

```bash
alpha-forge idea link <IDEA_ID> --strategy <ID> [--run <RUN_ID>] [--note <TEXT>]
```

| Name | Kind | Description |
|------|------|-------------|
| `--strategy` | required | Target strategy ID |
| `--run` | option | Target `run_id` (when given, links to a specific run) |
| `--note` | option | Note for the link |

## alpha-forge idea tag

Add or remove tags. `--add` and `--remove` can be combined; one of them is required.

```bash
alpha-forge idea tag <IDEA_ID> [--add <TAG>] [--remove <TAG>]
```

## alpha-forge idea note

Append a note to an idea.

```bash
alpha-forge idea note <IDEA_ID> <TEXT>
```

## alpha-forge idea search

Full-text search ideas.

```bash
alpha-forge idea search [QUERY] [--status <STATUS>] [--tag <TAG>] [--json]
```

| Name | Kind | Description |
|------|------|-------------|
| `QUERY` | argument (optional) | Search query (matches title / description / notes) |
| `--status` | choice | Status filter |
| `--tag` | repeatable | Tag filter |
| `--json` | flag | Emit the result as JSON (`{ideas: [...], count}`) |

---

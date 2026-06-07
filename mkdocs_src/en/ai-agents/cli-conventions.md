# CLI conventions for agents

The alpha-forge CLI is designed for **unattended execution** from AI agents and shell scripts. A **non-interactive mode** that never stalls on confirmation prompts, machine-readable **structured output (JSON)**, and a consistent **exit-code contract** apply across every command. That lets an agent simply parse the output and branch on the exit code to run loops safely.

This page is the detailed reference for those conventions. For how they fit into the exploration loop see the [autonomous exploration workflow](./exploration-workflow.md); for using the CLI through MCP see the [MCP reference](./mcp-reference.md).

!!! note "Prerequisites"
    The examples call `alpha-forge` directly from the current working directory. If you are working in the developer-facing alpha-trade monorepo, read each command as `FORGE_CONFIG=forge.yaml uv --directory alpha-forge run alpha-forge ...`.

---

## Non-interactive execution

Destructive / overwrite operations (`strategy delete` / `strategy purge` / `optimize clean` / `pine clean`, etc.) have confirmation prompts. In non-interactive environments such as CI, pipes, and agents (subprocess), those prompts can hang — so `alpha-forge` switches into non-interactive mode automatically through the following mechanisms.

- **Disable all prompts via env var**: setting `FORGE_NONINTERACTIVE=1` (`true` / `yes` / `on` also work) or a truthy `CI` flips every confirmation prompt into non-interactive mode.
- **Automatic TTY detection**: when stdin is not a TTY (pipe / subprocess execution), the CLI is treated as non-interactive automatically, even without the env var above.
- **Destructive operations fail safe**: delete / overwrite operations **stop immediately with exit code `2`** unless `--yes` / `-y` is given (no silent hang).
- **EULA is a separate env var**: `FORGE_NONINTERACTIVE` does not auto-accept the first-run EULA prompt. In CI, combine it with `FORGE_ACCEPT_EULA=1`.

### Recommended flow (dry-run → --yes)

For destructive commands, a two-step pattern is safest: confirm the affected count with `--dry-run` first, then execute with `--yes`.

```bash
# 1) Preview the impact first (nothing is deleted)
FORGE_NONINTERACTIVE=1 alpha-forge optimize clean --older-than 30d --dry-run --json

# 2) Once you're happy with the count, run it with --yes
FORGE_NONINTERACTIVE=1 alpha-forge optimize clean --older-than 30d --yes --json
```

Even if you forget `--yes`, the non-interactive mode never deletes silently — it stops with exit code `2`.

```bash
# Forgot --yes (the destructive operation is not run; stops with exit 2)
FORGE_NONINTERACTIVE=1 alpha-forge optimize clean --older-than 30d --json
echo "exit: $?"   # 2 = missing --yes in non-interactive execution
```

---

## JSON output

Commands passed `--json` follow these conventions so agents can parse them reliably.

- **stdout contains pure JSON only**: decoration, progress, and warnings all go to stderr. An agent can pipe stdout straight into `jq`.
- **List envelope**: commands that return a list wrap it as `{"<plural>": [...], "count": n}` (for example `{"strategies": [...], "count": 12}`).
- **not-found error**: when the target is missing, stdout carries `{"error": "...", "code": "...", "id": "..."}` and the command returns exit code `1`.

```bash
# Extract just the IDs from the strategy list (stdout is pure JSON, so it pipes straight into jq)
alpha-forge strategy list --json | jq -r '.strategies[].id'
```

```bash
# Requesting a strategy that doesn't exist (stdout is an error JSON, exit code 1)
alpha-forge strategy get does_not_exist --json
# stdout: {"error": "strategy not found", "code": "strategy_not_found", "id": "does_not_exist"}
echo "exit: $?"   # 1
```

!!! tip "Progress bars vs. JSON"
    Backtest and optimization progress bars are written to stderr. Capturing `--json` output into a variable will never get the JSON corrupted by progress noise.

---

## Exit-code contract

Every command follows the same three-value exit-code contract. An agent can decide its next move mechanically from this value alone.

| Exit code | Meaning | What the agent should do |
|-----------|---------|--------------------------|
| `0` | Success (including an explicit user cancel) | Read the result (JSON) and move on |
| `1` | not found / expected execution failure | Treat the target as missing / the run as failed (also use it to stop unattended loops) |
| `2` | argument error / missing `--yes` in non-interactive execution | Fix the arguments, or add `--yes`, then **retry** |

- **On `2`**: this signals a malformed invocation. Fix the arguments, or add `--yes` for a destructive operation, and retry. Retrying with the same arguments yields `2` again.
- **On `1`**: treat it as "target not found" or an "expected failure" — don't retry endlessly; advance to the next candidate or stop the loop.

---

## Inspecting the effective configuration

To diagnose "which configuration am I actually running under," use `alpha-forge system config`. It prints the **effective values** after resolving `FORGE_CONFIG`, with secrets masked.

```bash
# Inspect the whole effective configuration
alpha-forge system config --json

# Inspect a single key (dotted key)
alpha-forge system config data.provider --json
```

Running this once before an unattended run guards against accidentally starting on an unexpected data path or provider setting.

---

## Safe patterns for unattended loops

A checklist for running long agent loops safely.

- [ ] **Always set `FORGE_NONINTERACTIVE=1`** — prevents hangs on confirmation prompts (it's auto-enabled for non-TTY, but stating it explicitly makes intent clear).
- [ ] **Do destructive operations in two steps: `--dry-run` → `--yes`** — confirm the count first, then execute. A forgotten `--yes` fails safe with exit `2`.
- [ ] **Fetch results with `--json` and branch on the exit code** — parse the JSON on stdout and decide the next action from `0` / `1` / `2`.

```bash
# One iteration of an unattended loop
export FORGE_NONINTERACTIVE=1
alpha-forge backtest run SPY --strategy my_rsi_v1 --json
case $? in
  0) echo "success: parse the result JSON" ;;
  1) echo "not found / run failed: move to the next candidate" ;;
  2) echo "argument error: fix the command and retry" ;;
esac
```

---

## Related links

- [Autonomous exploration workflow](./exploration-workflow.md) — how non-interactive execution is used inside the workflow
- [MCP reference](./mcp-reference.md) — conventions when calling these commands as tools over MCP
- [CLI reference](../cli-reference/index.md) — the full option set for each command

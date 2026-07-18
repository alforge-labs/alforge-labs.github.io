# `--json` output reference

This page is the **contract (schema) reference** for the alpha-forge CLI's `--json` output. It defines the top-level fields, types, and envelope conventions of the main commands, plus the meaning and increment rules of `schema_version` / `forge_version`, so agents and MCP/pipe consumers have a stable reference point when parsing output.

The conventions themselves (stdout purity, envelopes, exit codes) live in [CLI conventions for agents](./cli-conventions.md). This page complements that with "the actual fields that appear".

!!! tip "Runtime catalog"
    The **machine-readable catalog** of every command (which commands have `--json`, the type of each option) is available via `alpha-forge system describe --json`. This page covers "what fields a `--json` output returns"; `system describe --json` covers "which commands have `--json`".

---

## Three envelope shapes

Output shapes fall into three families by command type.

- **List commands** (`list` / `scan-all`, etc.): a `{"<plural>": [...], "count": n}` envelope. Even when empty, an empty array + exit code `0`.
- **Single-run commands** (`backtest run` / `optimize walk-forward` / `backtest monte-carlo`, etc.): a **raw object** with no envelope (metrics and meta fields sit at the top level).
- **Errors**: a fixed 3-key `{"error": ..., "code": ..., "id": ...}` (see [Error output](#error-output)).

Percent fields (`*_pct`) are **already in percent units** (e.g. `17.39` means +17.39%). Do not multiply by 100 again.

---

## `schema_version` / `forge_version`

The `backtest run --json` output includes these two meta fields.

| Field | Type | Meaning |
|-------|------|---------|
| `schema_version` | int | **The schema generation of the CLI output JSON.** Currently `1`. Bump it per the rules below |
| `forge_version` | string | The alpha-forge version that produced this output (e.g. `"0.15.0"`) |

!!! note "Distinct from the strategy JSON's schema_version"
    This `schema_version` is the **contract generation of the CLI output JSON**, a different concept from the strategy JSON file's `schema_version` (the strategy-definition schema generation seen in `strategy show --json`).

### Increment rules (when to bump)

Bump `schema_version` by +1 only on a **backward-incompatible change**.

| Change | Bump? |
|--------|-------|
| **Removing** / **renaming** an existing field | **Yes** |
| **Type change** / **meaning change** of an existing field | **Yes** |
| **Adding** a new field (existing fields unchanged) | **No** (additions are backward-compatible) |
| Changing the envelope shape | **Yes** |
| Formatting only (compact ↔ indent, key order) | **No** |

The rule of thumb: **additions are compatible; removals/renames/type or meaning changes are not.** `forge_version` advances naturally every release, so use `forge_version` to track "when something changed" and `schema_version` to decide "whether consumer code must be fixed".

---

## `backtest run --json`

A raw object with no envelope; metrics sit at the top level (60+ fields in practice). Only the contract-relevant meta fields are listed here.

| Field | Type | When present | Meaning |
|-------|------|--------------|---------|
| `schema_version` | int | always | CLI output schema generation |
| `forge_version` | string | always | producing version |
| `warnings` | array | always | runtime cautions (e.g. low trade count) |
| `freemium_limit_notices` | array | always | Trial-plan limit notices (include a `code`) |
| `run_id` | string | when a real run exists | run identifier |
| `result_id` | string | when a result is saved | saved-result identifier |
| `pre_filter_pass` | bool | on pre-filter evaluation | whether the pre-filter passed |
| `pre_filter` | object | on pre-filter evaluation | applied thresholds (`sharpe_min` / `max_dd_max` / `monthly_volume_usd_min` / `min_trades` / `goal`) |
| `criteria_check` | object | when pass/fail criteria exist | verdict (merged into the body) |
| `next_step` | array | when next actions are suggested | next-command candidates (string array) |
| `carry_adjusted_metrics` | object | when `--carry` accrued carry | reference metrics including FX carry (rate-differential approximation). **Key presence is the contract** (absent when not specified or carry could not be accrued). IS-period value when combined with `--split` |
| `carry_adjusted_note` | string | when `carry_adjusted_metrics` exists | note on the approximation method and its limits |

With `--split`, IS/OOS comparison meta is added: `out_of_sample_metrics` (OOS metrics), `overfitting_score`, `overfitting_risk`, and `walk_forward_summary` (`is_sharpe` / `oos_sharpe` / `is_return_pct` / `oos_return_pct` / `overfitting_score` / `overfitting_risk`).

With `--summary`, heavy per-trade / per-bar arrays are dropped for a lightweight JSON (the meta-field contract is unchanged).

---

## `optimize walk-forward --json`

A raw object with no envelope.

| Field | Type | Meaning |
|-------|------|---------|
| `symbol` / `strategy` / `metric` | string | symbol / strategy ID / optimization metric |
| `windows` | array | per-window results (IS/OOS metrics, `skip_reason`, etc.) |
| `is_valid_windows` / `valid_oos_windows` / `total_windows` / `skipped_windows` | int | window counts |
| `all_is_invalid` | bool | whether IS optimization failed in every window |
| `freemium_limit_notices` | array | Trial limit notices |
| `opt_run_id` | string \| null | run_id of the `optimization_runs` row recorded with `--save` (`null` without `--save` or on recording failure; the key is always present) |
| `pre_filter_pass` | bool \| null | whether the average OOS metric meets the threshold (`null` if undecidable) |
| `pre_filter` | object | applied thresholds (`sharpe_min` / `max_dd_max` / `min_trades` / `goal`) |

`pre_filter_pass` / `pre_filter` are always present even without `--goal` (using default thresholds), matching `backtest run`'s naming and contract.

---

## `backtest monte-carlo --json`

Runs a Monte Carlo simulation from a saved backtest result's trade history. A raw object with no envelope.

| Field | Type | Meaning |
|-------|------|---------|
| `initial_capital` | number | initial capital |
| `simulations_run` | int | number of runs |
| `mean_final_equity` / `median_final_equity` / `worst_final_equity` / `best_final_equity` | number | final-equity statistics |
| `mean_max_drawdown_pct` / `max_drawdown_95pct` | number | max drawdown (mean and 95th percentile) |
| `ruin_probability_pct` | number | probability of ruin (%) |
| `pre_filter_pass` | bool \| null | whether ruin probability is at or below the default threshold (5%) |
| `pre_filter` | object | `max_ruin_pct` (default 5.0) |

If the input result has fewer than 10 valid trades, an error is printed to stderr and exit code `1` is returned (no pure JSON is emitted).

---

## List envelope

List / scan commands return `{"<plural>": [...], "count": n}`. Even when empty, an empty array + exit code `0`.

| Command | Envelope keys | Main element keys |
|---------|---------------|-------------------|
| `strategy list --json` | `strategies` / `count` | `strategy_id` / `name` / `version` / `asset_type` / `timeframe` / `tags` / `notes` / `created_at` / `updated_at` |
| `backtest list --json` | `results` / `count` | saved-result rows (`strategy_id` / `symbol` / key metrics) |
| `analyze indicator list --json` | `indicators` / `count` | `name` / `category` (plus `params` with `--detail`) |
| `analyze pairs scan-all --json` | `pairs` / `count` | cointegration test results (plus `cointegrated_count`) |
| `system describe --json` | `commands` / `count` | `command` / `path` / `options` / `json_supported` |

---

## Error output

A not-found error (e.g. an unknown ID) prints the following fixed 3-key JSON to stdout when `--json` is set, and exits with code `1`.

```json
{"error": "strategy 'does_not_exist' not found", "code": "strategy_not_found", "id": "does_not_exist"}
```

| Field | Type | Meaning |
|-------|------|---------|
| `error` | string | localized message |
| `code` | string | stable machine-judgable code (e.g. `strategy_not_found`) |
| `id` | string | the resource ID that was not found |

Without `--json`, a single-line message goes to stderr and exit code is `1` (stdout is empty). Argument errors (Click `UsageError`) exit with code `2`.

---

## Related links

- [CLI conventions for agents](./cli-conventions.md) — stdout purity, envelopes, exit codes
- [alpha-forge-mcp reference](./mcp-reference.md) — using the CLI through MCP

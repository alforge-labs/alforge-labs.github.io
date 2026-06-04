# Configuration

## CLI options

### `alpha-vis serve`

Starts the web dashboard.

```bash
alpha-vis serve [OPTIONS]
```

| Option | Default | Description |
|---|---|---|
| `--forge-dir DIRECTORY` | `.` (current directory) | Directory containing alpha-forge's output DBs |
| `--forge-config FILE` | `<forge-dir>/forge.yaml` | Explicit `forge.yaml` path |
| `--host TEXT` | `127.0.0.1` | Host to bind |
| `--port INTEGER` | `8000` | Port number |
| `--no-open` | — | Do not auto-launch the browser |

Help:

```bash
alpha-vis --help
alpha-vis serve --help
```

## Data paths (ForgeConfig)

`alpha-vis serve` resolves the following paths relative to `--forge-dir`:

| Purpose | Path |
|---|---|
| Backtest results DB | `<forge-dir>/data/results/backtest_results.db` |
| Strategy JSON | `<forge-dir>/data/strategies/*.json` |
| Idea list | `<forge-dir>/data/ideas/ideas.json` |
| Live results | `<forge-dir>/data/live/` |

When `forge.yaml` defines `report.output_path`, `report.db_filename`, `strategies.path`, or `ideas.ideas_path`, those values take precedence.

## `forge.yaml` example

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

If `forge.yaml` lives directly under `<forge-dir>`, it is loaded automatically. Otherwise pass `--forge-config` explicitly.

## Environment variables

| Variable | Purpose |
|---|---|
| `FORGE_CONFIG` | Equivalent to `--forge-config` (CLI flag wins on conflict) |

For CI scenarios, you can clear it: `env FORGE_CONFIG= alpha-vis serve ...`.

## Notes for remote / public deployment

When running with `--host 0.0.0.0`:

- **No built-in authentication.** Run behind a VPN, SSH port-forward, or a private network.
- For public exposure, terminate at a reverse proxy (nginx / Caddy) and add Basic auth, OAuth proxy, or SSO.
- Browser ⇄ server traffic is plain HTTP. For TLS, terminate at the reverse proxy.

## Reflecting changes

Each `alpha-forge backtest run` or `alpha-forge optimize run` updates `backtest_results.db`. Reload the dashboard (`Cmd+R` / `F5`) to see new results — automatic reload is not implemented yet.

## Related

- [Features](features.md): dashboard walkthrough
- [FAQ](faq.md): troubleshooting
- [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues): bug reports & feature requests

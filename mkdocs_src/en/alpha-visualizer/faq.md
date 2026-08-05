# FAQ & Troubleshooting

## Installation & startup

### Can I try it without AlphaForge?

Yes. Bundled synthetic sample data lets you explore the whole dashboard without installing AlphaForge.

```bash
alpha-vis serve --use-bundled-samples
```

Install AlphaForge once you want to visualize your own backtest results. See [Try it right after installing (sample data)](installation.md#try-with-samples).

### `alpha-vis: command not found`

When installed via `uv tool install`, your shell must include uv's tool directory in `PATH`.

```bash
# Check uv tool dir
uv tool dir
# Verify $HOME/.local/bin is on PATH
echo $PATH

# If missing
export PATH="$HOME/.local/bin:$PATH"
```

### `backtest_results.db` not found / no strategies shown

`alpha-vis serve` may not see `<forge-dir>/data/results/backtest_results.db`.

```bash
# Inspect resolved paths (printed at startup)
alpha-vis serve --forge-dir <path>

# Verify directly
ls <path>/data/results/backtest_results.db
ls <path>/data/strategies/
```

If you have never executed `alpha-forge backtest run`, `backtest_results.db` does not exist yet. Run at least one backtest before launching `alpha-vis serve`.

### Port already in use

```
ERROR:    [Errno 48] error while attempting to bind on address ('127.0.0.1', 8000): address already in use
```

Pick another port or stop the conflicting process.

```bash
alpha-vis serve --port 9000

# Inspect what is using port 8000
lsof -i :8000
```

### Browser does not open automatically

If you did not pass `--no-open` and the browser still does not open, your environment may suppress automatic browser launch (common on WSL / headless servers). Open <http://127.0.0.1:8000> manually.

## Behavior

### Stale results after a new run

Reload the dashboard with `Cmd+R` / `F5` after `alpha-forge backtest run`. Auto-reload is not implemented.

### Strategy name shows `undefined`

The strategy JSON may be missing a `name` field, or `latest_*` metrics may not have been computed yet. Recent versions (v0.1.1+) guard against undefined values — try `pip install --upgrade alpha-visualizer`.

### Compare correlation heatmap doesn't render

If selected strategies have **no overlapping trade period**, correlation cannot be computed. Pick strategies with overlapping date ranges.

## Remote / production

### Access from another machine

```bash
alpha-vis serve --host 0.0.0.0 --port 8000
```

Then:

- Open the relevant port on your firewall
- Prefer SSH port-forwarding or VPN over public exposure (no built-in auth)

### HTTPS

There is no built-in TLS. Terminate TLS at a reverse proxy (nginx / Caddy / Cloudflare Tunnel).

### Adding authentication

No built-in auth. Add Basic auth, OAuth Proxy, Tailscale Auth, etc. at the reverse proxy layer.

## Development & contribution

### Where to file bug reports / feature requests

[GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues) — Japanese and English templates are provided.

### Reporting security vulnerabilities

Please do not open a public issue — follow [SECURITY.en.md](https://github.com/alforge-labs/alpha-visualizer/blob/main/SECURITY.en.md) and use GitHub Private Vulnerability Reporting or `security@alforgelabs.com`.

### Contributing

See [CONTRIBUTING.en.md](https://github.com/alforge-labs/alpha-visualizer/blob/main/CONTRIBUTING.en.md). Pull requests are welcome via GitHub Flow.

## Versions & compatibility

### Compatible `alpha-forge` versions

`alpha-visualizer` depends on the `backtest_results.db` (SQLite) schema and strategy JSON structure. **Pairs developed and verified together** are the safest choice.

| alpha-visualizer | alpha-forge | Notes |
|---|---|---|
| v1.4.x (2026-08) | v1.3.0 | Adds AI strategy development (Agent Develop) |
| v1.3.x (2026-08) | v1.3.0 | Run-time parameter display (params_json) requires forge v1.3.0 |
| v1.2.x (2026-07) | v1.2.0 | Live comparison overlays require `live replay --benchmark / --compare` |
| v1.0.x–v1.1.x (2026-07) | v1.0.x–v1.1.0 | Pairs since the simultaneous four-product GA (2026-07-21) |
| v0.9.0 (2026-07) | v0.18.x | Carry-adjusted metrics require `backtest run --carry` |

The database is extended by adding columns, so **databases produced by older alpha-forge versions generally remain viewable** (only the views that depend on newer columns stay hidden). Conversely, GUI execution features (backtests, optimization, data fetching, Pine export, etc.) need a recent alpha-forge CLI that has the corresponding subcommands; with an older CLI the UI shows an update prompt.

### Running on Python 3.11 or older

Python 3.12+ is required. Older versions are not supported.

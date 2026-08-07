---
title: alpha-visualizer v1.6.0 — refresh live data from the Live screen
description: alpha-visualizer v1.6.0 turns a three-command CLI workflow for refreshing live data into a single button on the Live screen. Replay parameters now live in forge.yaml, structurally eliminating return-rate skew caused by a forgotten initial capital flag.
---

# alpha-visualizer v1.6.0 — refresh live data from the Live screen

> **Released**: August 7, 2026 / **Version**: v1.6.0 / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/) · [GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.6.0)

[alpha-visualizer](index.md) is a standalone OSS package that visualizes AlphaForge backtest results in a web browser. v1.6.0 brings the "refresh my paper/live trading records" workflow into the GUI.

## Highlights

### 1. The "Refresh live data" button

The Live screen now has a refresh button. Previously this required running three CLI commands in order:

```bash
alpha-forge live sync-events     # pull events from the execution server
alpha-forge data update          # incrementally update historical data
alpha-forge live replay ...      # recompute live performance
```

In v1.6.0 that is one click. Progress is streamed per step, the run can be cancelled while in flight, and the list and detail views refetch automatically once it finishes.

See [Features — Live screen](features.md#live) for details.

### 2. Replay parameters consolidated into `forge.yaml`

The refresh delegates to AlphaForge's [`alpha-forge live refresh`](../cli-reference/live.md#alpha-forge-live-refresh). Replay parameters now have a single source of truth: the `live.replay` section of `forge.yaml`.

```yaml
live:
  replay:
    portfolio_id: ""         # combine portfolio ID
    combine_strategies: []   # combine target strategy IDs (2 or more)
    initial_capital: null    # match your real account's capital
    compare: false           # also show a comparison against the backtest combine
```

This **structurally eliminates the class of mistake where a forgotten `--initial-capital` skews return percentages against the real account**. Leaving it at the backtest default (100,000) while the live account holds 1,000,000 skews the returns by 10x. See [config fallback for omitted arguments](../cli-reference/live.md#config-fallback-for-omitted-arguments-livereplay) for the full settings reference.

!!! warning "Requires AlphaForge v1.4.0 or later"
    The button invokes `alpha-forge live refresh`, so it needs **AlphaForge v1.4.0 or later**. On earlier versions the UI reports that the command is unavailable.

    The button is also disabled when `alpha-vis serve` is exposed on a non-loopback address, since the operation writes locally.

## Fixes

- **Job creation failures were not surfaced in the UI.** When serving on a LAN (403), when AlphaForge was not installed (503), or when an AI derived-development run pointed at a missing base strategy (404), pressing the button appeared to do nothing. Both the Data screen and the AI strategy development screen are fixed
- Fixed documentation screenshots occasionally being cut off at the bottom edge (internal tooling)

## How to upgrade

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer

# pipx
pipx upgrade alpha-visualizer
```

Update AlphaForge as well:

```bash
alpha-forge self update
```

## Related documentation

- [Features — Live screen](features.md#live)
- [`alpha-forge live refresh`](../cli-reference/live.md#alpha-forge-live-refresh)
- [alpha-strike setup guide](../guides/alpha-strike-setup.md)

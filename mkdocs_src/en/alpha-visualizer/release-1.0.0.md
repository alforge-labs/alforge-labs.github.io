---
title: alpha-visualizer v1.0.0 GA — simultaneous GA across the AlphaForge family (with v1.0.1 / v1.1.0 cumulative updates)
description: alpha-visualizer v1.0.0 is the GA (stable) release, shipped simultaneously with AlphaForge, alpha-strike, and alpha-forge-mcp. This note also covers the follow-up patches v1.0.1 (full EN language propagation, TradingView renderer consolidation) and v1.1.0 (regime background bands, synced chart viewports).
---

# alpha-visualizer v1.0.0 GA — simultaneous GA across the AlphaForge family

> **Released**: July 21, 2026 / **Version**: v1.0.0 (this note also covers v1.0.1 / v1.1.0) / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/) · [CHANGELOG](https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md)

[alpha-visualizer](index.md) is a standalone OSS package that visualizes AlphaForge backtest results in a web browser. v1.0.0 is the **GA (stable) release shipped simultaneously with AlphaForge itself, [alpha-strike](https://github.com/alforge-labs/alpha-strike), and [alpha-forge-mcp](https://github.com/alforge-labs/alpha-forge-mcp)** — a milestone that declares the feature set assembled through v0.9.0 (visualization, GUI execution, parameter tuning) stable.

## Highlights

### 1. GA (stable) declaration (v1.0.0)

Versioning follows semantic versioning; breaking changes will only happen in major versions from here on. Feature-wise it matches v0.9.0 — the release focuses on documentation and distribution polish for GA.

### 2. Full EN language propagation (v1.0.1)

Switching the UI language now consistently applies to navigation, chart axis locales, and data-table formatting. The remaining plain-text loading indicators were also migrated to the shared Loading component.

### 3. TradingView renderer consolidation (v1.0.1)

The gradual switch of major charts to TradingView lightweight-charts (started in v0.7.3) is now complete, and legacy renderer remnants were cleaned up.

### 4. Regime background bands and synced viewports (v1.1.0)

Equity / drawdown charts regained **regime background bands** (color-coded market regimes). Charts on the same screen now keep their **viewports synced in both directions**, so zooming or scrolling one chart keeps the comparison aligned. Playwright visual-regression tests for the TradingView charts guard against future rendering regressions in CI.

## How to upgrade

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

Try it with the bundled samples (no AlphaForge required):

```bash
alpha-vis serve --use-bundled-samples
```

To browse your own `alpha-forge` project data:

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

## Links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Installation**: [alpha-visualizer / Installation](installation.md)
- **Features**: [alpha-visualizer / Features](features.md)

Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).

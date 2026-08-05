---
title: alpha-visualizer v1.4.0 — AI strategy development (Agent Develop)
description: alpha-visualizer v1.4.0 adds Agent Develop — hand strategy development to an AI agent from the GUI. Your locally installed claude / codex CLI runs headlessly as an async job, creating a strategy JSON and validating it with a backtest.
---

# alpha-visualizer v1.4.0 — AI strategy development (Agent Develop)

> **Released**: August 3, 2026 / **Version**: v1.4.0 (this note also covers the v1.4.1 patch) / **Distribution**: [PyPI](https://pypi.org/project/alpha-visualizer/) · [GitHub Release](https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.4.0)

[alpha-visualizer](index.md) is a standalone OSS package that visualizes AlphaForge backtest results in a web browser. v1.4.0 adds **Agent Develop** — hand strategy development to an AI agent straight from the GUI.

## Highlights

### 1. Agent Develop

Enter a goal, an optional target symbol, and a backend (Claude Code / Codex CLI) on the Develop view (`/develop`), and your locally installed `claude` / `codex` CLI is launched headlessly as an asynchronous job that **creates a strategy JSON → validates it with `alpha-forge backtest run` → links to the new strategy on completion**. Observing and cancelling the job uses the same mechanism as the run history.

Security design:

- **No API keys are handled**. Authentication and billing stay with each CLI's existing login
- **localhost only**. The feature disables itself on non-loopback binds (`alpha-vis serve --host 0.0.0.0`, etc.)
- **Workspace-scoped**. The claude backend scopes its tool allowlist to paths under the workspace and rejects reads/writes outside it (codex uses the OS-level `--sandbox workspace-write`)

!!! warning "About external communication"
    This feature launches your own `claude` / `codex` CLI as-is. Those CLIs communicate with Anthropic / OpenAI. alpha-visualizer itself never handles, stores, or transmits API keys.

See [Develop in Features](features.md#develop) for usage, the permission model, and turn limits.

### 2. Turn-limit reporting (v1.4.1)

When the claude backend is cut off at the turn limit (`--max-turns`), the error now states that fact and the limit value correctly (previously it could be misdiagnosed as an unrelated failure).

## How to upgrade

```bash
# pip
pip install -U alpha-visualizer

# uv
uv tool upgrade alpha-visualizer
```

Using Agent Develop requires `claude` (Claude Code) or `codex` (Codex CLI) on PATH and authenticated, plus `alpha-forge` installed. If you don't use it, everything else works as before.

## Links

- **PyPI**: <https://pypi.org/project/alpha-visualizer/>
- **GitHub Release**: <https://github.com/alforge-labs/alpha-visualizer/releases/tag/v1.4.0>
- **CHANGELOG**: <https://github.com/alforge-labs/alpha-visualizer/blob/main/CHANGELOG.md>
- **Features**: [alpha-visualizer / Features](features.md)

Bug reports and feature requests are welcome on [GitHub Issues](https://github.com/alforge-labs/alpha-visualizer/issues).

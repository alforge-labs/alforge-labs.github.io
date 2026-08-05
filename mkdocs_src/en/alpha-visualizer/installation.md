# Installation

`alpha-visualizer` is published on PyPI and requires Python 3.12+.

!!! tip "You can try it without AlphaForge"
    `alpha-visualizer` ships with synthetic sample data, so **you can explore every screen without installing AlphaForge** (see [Try it right after installing](#try-with-samples) below). Once you want to visualize your own backtest results, install `alpha-forge` — the engine that produces `backtest_results.db` — via the [AlphaForge Getting Started guide](../getting-started.md) (latest binaries are also on [GitHub Releases](https://github.com/alforge-labs/alforge-labs.github.io/releases/latest)).

## Requirements

| Item | Version |
|---|---|
| Python | 3.12 or later |
| OS | macOS / Linux / Windows |
| Browser | Latest Chrome / Firefox / Safari / Edge |

## uv (recommended)

[uv](https://docs.astral.sh/uv/) installs the tool into an isolated environment, sidestepping Python version conflicts.

```bash
uv tool install alpha-visualizer
```

If you don't have uv yet, see <https://docs.astral.sh/uv/getting-started/installation/>.

## pip

Plain Python installation:

```bash
pip install alpha-visualizer
```

Inside a virtualenv:

```bash
python -m venv .venv
source .venv/bin/activate   # Windows: .venv\Scripts\activate
pip install alpha-visualizer
```

## From source (for development)

Clone the repo and run locally:

```bash
git clone https://github.com/alforge-labs/alpha-visualizer.git
cd alpha-visualizer
uv sync                            # Python deps
cd frontend && pnpm install && pnpm run build && cd ..
uv run alpha-vis serve --forge-dir <path>
```

See [CONTRIBUTING.en.md](https://github.com/alforge-labs/alpha-visualizer/blob/main/CONTRIBUTING.en.md) for the full development workflow.

## Verify the install

```bash
alpha-vis --version
```

A correctly installed `alpha-vis` prints its version.

## Try it right after installing (sample data) { #try-with-samples }

You can run the whole dashboard on bundled synthetic sample data — no AlphaForge install and no backtest results of your own required.

```bash
alpha-vis serve --use-bundled-samples
```

Your browser opens automatically (or visit <http://127.0.0.1:8000>) with sample strategies, backtest results, and ideas, letting you walk through Browse / Detail / Compare and the other screens. With `--use-bundled-samples`, the `--forge-dir` / `--forge-config` options are ignored.

When you are ready to look at your own data, run a backtest with `alpha-forge` and start the server like this:

```bash
alpha-vis serve --forge-dir /path/to/your/alpha-strategies
```

## Upgrade

```bash
# uv
uv tool upgrade alpha-visualizer

# pip
pip install --upgrade alpha-visualizer
```

## Uninstall

```bash
# uv
uv tool uninstall alpha-visualizer

# pip
pip uninstall alpha-visualizer
```

## Next steps

- [Features](features.md) — walk through each dashboard screen
- [Configuration](configuration.md) — CLI options and `forge.yaml`

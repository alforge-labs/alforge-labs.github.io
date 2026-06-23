# Glossary

A quick reference for the abbreviations, metrics, and statistical methods that appear throughout this documentation and the `alpha-forge` CLI output (synced with alpha-forge issue #1192).

## Performance metrics

| Term | Field / full name | Meaning |
|------|-------------------|---------|
| **Sharpe** | `sharpe_ratio` | Risk-adjusted return = return divided by volatility (standard deviation). Higher is better. The default objective for optimization and WFT. |
| **Sortino** | `sortino_ratio` | Risk-adjusted return that only divides by downside volatility (variation of negative returns). A downside-only variant of Sharpe. |
| **Calmar** | `calmar_ratio` | CAGR ÷ max drawdown. Return efficiency relative to drawdown resilience. Higher is better. |
| **MDD (Max Drawdown)** | `max_drawdown_pct` | The largest peak-to-trough decline of the equity curve (%). Smaller is better. |
| **CAGR** | `cagr_pct` | Compound Annual Growth Rate (%). Lets you compare returns regardless of period length. |
| **PF (Profit Factor)** | `profit_factor` | Gross profit ÷ gross loss. Above 1.0 means net profit. `null` when there are no losses (gross loss = 0). |
| **Win rate** | `win_rate_pct` | Percentage of trades that closed with a profit. |
| **tail_ratio** | — | 95th-percentile gain ÷ \|5th-percentile loss\| of daily returns. Above 1.0 means a fatter upside tail. |
| **VaR / CVaR** | `var_95` / `cvar_95` | Value at Risk (worst expected loss at 95% confidence) and the conditional expected loss beyond that threshold. |

## Validation and statistics

| Term | Full name | Meaning |
|------|-----------|---------|
| **IS** | In-Sample | The period used for parameter optimization / training — the first half of `backtest run --split`. |
| **OOS** | Out-of-Sample | The period held out for validation only — the second half of `--split`. A small IS↔OOS performance gap indicates low overfitting. |
| **WFT** | Walk-Forward Test | Robustness check that repeatedly optimizes on IS then validates on OOS across N rolling windows (`optimize walk-forward`). Detects overfitting. |
| **DSR** | Deflated Sharpe Ratio | A significance measure that deflates the Sharpe ratio to correct for "lucky" results from running many optimization trials (Bailey & López de Prado, 2014). The more trials (`n_trials`), the stricter the correction. |
| **MC** | Monte Carlo | Runs many randomized simulations (trade reordering / resampling) to estimate the final-equity distribution, ruin probability (`ruin_probability_pct`), 95th-percentile MDD, and more (`backtest monte-carlo`). |
| **PSR** | Probabilistic Sharpe Ratio | The probability that the observed Sharpe exceeds a benchmark value. The statistical basis of DSR. |

## Exploration and regimes

| Term | Full name | Meaning |
|------|-----------|---------|
| **HMM** | Hidden Markov Model | A probabilistic model that classifies the market into hidden "regimes" (e.g. Bull / Range / Bear) so signals can switch per state. Used via the `HMM` indicator. |
| **Regime** | — | A market state such as bullish, bearish, or range-bound. Gated by HMM or macro indicators to control entries per state. |
| **near_pass** | rescue zone | A mechanism in the `explore` pre_filter that lets "almost-passing" strategies proceed to the optimizer (`pre_filter.near_pass` in `goals.yaml`). |
| **pre_filter** | — | A pre-check in `explore run` that aborts a strategy right after the backtest if it fails minimum Sharpe / MDD / trade-count thresholds, skipping optimization and WFT to save compute. |

<!-- Synced from: the "Glossary" section of `alpha-forge/src/alpha_forge/resources/docs/user-guide.en.md` (alpha-forge issue #1192). If alpha-forge adds new metrics or statistics, this page must be updated accordingly. -->

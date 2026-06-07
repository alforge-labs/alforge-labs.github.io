# Quants & Researchers

For quantitative analysts and researchers who prioritize statistical rigor and want systematic optimization and walk-forward validation.

## Quantitative Evaluation Features

| Feature | Details |
|---------|---------|
| **Walk-Forward Validation** | Automatic IS/OOS splits to detect overfitting |
| **Optuna Optimization** | Bayesian search over parameter space (200–1000 trials) |
| **Multiple Objectives** | Choose from Sharpe ratio, max drawdown, Calmar ratio, etc. |
| **Reproducibility** | Lock seeds and config in JSON for fully reproducible experiments |
| **Journal Logging** | All experiment results automatically recorded as JSON/CSV |

## Typical Research Workflow

```bash
# 1. Declare hypothesis in JSON
alpha-forge strategy create --template hmm_bb_pipeline_v1 --out regime_test.json

# 2. Grid search over the parameters declared in the strategy JSON
# (the grid is defined by optimizer_config.param_ranges in regime_test's JSON)
alpha-forge optimize grid QQQ --strategy regime_test --top-k 10

# 3. Walk-forward validation (5 folds)
alpha-forge optimize walk-forward QQQ --strategy regime_test --windows 5

# 4. Save experiment to journal
alpha-forge journal note regime_test "HMM period sensitivity analysis"
```

## Evaluating Overfitting Risk

AlphaForge provides walk-forward testing (WFT) as a standard feature. The output is a table listing each window's IS Score and OOS Score; a large drop from IS to OOS suggests overfitting (compute the degradation yourself from IS/OOS).

```
Window     IS Score   OOS Score  Best Params
1            1.8000     1.4000    {...}   ← small drop, acceptable
2            2.5000     0.3000    {...}   ← large drop, likely overfit
```

## Related Docs

- [Strategy Templates](../templates.md) — Full JSON for HMM, regime-switching, multi-timeframe
- [Strategy Gallery](../strategy-gallery.md) — Cross-market strategy comparison with result interpretation
- [End-to-End Strategy Development Workflow](../guides/end-to-end-workflow.md) — From optimization to WFT validation
- [optimize command](../cli-reference/optimize.md) — Full optimization options

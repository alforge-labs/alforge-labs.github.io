# 用語集（Glossary）

本ドキュメントや `alpha-forge` CLI 出力に頻出する略語・指標・統計手法の早見表です（alpha-forge issue #1192 と同期）。

## 評価指標

| 用語 | 読み / 正式名 | 意味 |
|------|--------------|------|
| **Sharpe（シャープレシオ）** | `sharpe_ratio` | リターンを変動（標準偏差）で割ったリスク調整後リターン。高いほど良い。最適化・WFT の既定目的指標。 |
| **Sortino（ソルティノレシオ）** | `sortino_ratio` | 下方リスク（マイナスリターンの変動）のみで割ったリスク調整後リターン。Sharpe の下方リスク版。 |
| **Calmar（カルマーレシオ）** | `calmar_ratio` | CAGR ÷ 最大ドローダウン。下落耐性に対するリターン効率を表す。高いほど良い。 |
| **MDD（最大ドローダウン）** | `max_drawdown_pct` | 資産曲線の最高値から最安値までの最大下落幅（%）。小さいほど良い。 |
| **CAGR（年率リターン）** | `cagr_pct` | 複利を考慮した年平均成長率（%）。期間の長短に依らずリターンを比較できる。 |
| **PF（プロフィットファクター）** | `profit_factor` | 総利益 ÷ 総損失。1.0 超で利益超過。全勝で損失合計 = 0 のときは `null`。 |
| **勝率** | `win_rate_pct` | 利益で終えたトレードの割合（%）。 |
| **tail_ratio（テールレシオ）** | — | 日次リターンの 95 パーセンタイル利益 ÷ \|5 パーセンタイル損失\|。1.0 超で利益側の裾が厚い。 |
| **VaR / CVaR** | `var_95` / `cvar_95` | バリュー・アット・リスク（95% 信頼水準の想定最大損失）と、その閾値を超えた損失の条件付き期待値。 |

## 検証・統計手法

| 用語 | 読み / 正式名 | 意味 |
|------|--------------|------|
| **IS（インサンプル）** | In-Sample | パラメータ最適化・学習に使う期間。`backtest run --split` の前半。 |
| **OOS（アウトオブサンプル）** | Out-of-Sample | 学習に使わず検証だけに使う期間。`--split` の後半。IS と OOS の性能差が小さいほど過学習が少ない。 |
| **WFT（ウォークフォワード）** | Walk-Forward Test | IS で最適化 → OOS で検証、を窓をずらしながら N 分割で繰り返す堅牢性検証（`optimize walk-forward`）。過学習を検出する。 |
| **DSR（デフレーテッド・シャープ）** | Deflated Sharpe Ratio | 最適化で多数の試行を行ったことによる「まぐれ当たり」を補正した Sharpe の有意性指標（Bailey & López de Prado, 2014）。試行回数 `n_trials` が多いほど厳しく補正される。 |
| **MC（モンテカルロ）** | Monte Carlo | トレード順序や復元抽出を乱数で多数回シミュレートし、最終資産分布・破産確率（`ruin_probability_pct`）・95% タイル MDD 等を推定する手法（`backtest monte-carlo`）。 |
| **PSR** | Probabilistic Sharpe Ratio | 観測された Sharpe が基準値を上回る確率。DSR の基礎となる統計量。 |

## 探索・レジーム

| 用語 | 読み / 正式名 | 意味 |
|------|--------------|------|
| **HMM** | Hidden Markov Model（隠れマルコフモデル） | 市場を Bull / Range / Bear 等の隠れた「レジーム（局面）」に分類し、状態ごとにシグナルを切り替えるための確率モデル。`HMM` インジケータで利用。 |
| **レジーム** | Regime | 強気・弱気・レンジ等の相場局面。HMM やマクロ指標でゲーティングし、局面に応じてエントリーを制御する。 |
| **near_pass（救済ゾーン）** | — | `explore` の pre_filter で「あと一歩」基準に届かない戦略を optimizer に進める救済機構（`goals.yaml` の `pre_filter.near_pass`）。 |
| **pre_filter** | — | `explore run` でバックテスト直後に Sharpe / MDD / 取引数の最低基準を満たさない戦略を打ち切り、最適化・WFT をスキップして計算資源を節約する事前フィルタ。 |

<!-- 同期元: `alpha-forge/src/alpha_forge/resources/docs/user-guide.ja.md` の「用語集（Glossary）」セクション（alpha-forge issue #1192）。alpha-forge 側で指標・統計量の追加があった場合、本ページも追従更新が必要。 -->

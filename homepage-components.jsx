// homepage-components.jsx
// Nav, Hero, Products, PerformanceChart (useChartColors / EquityChartSVG / BenchmarkTable)

/* ── PERF CHART HELPERS ── */
const CHART = {
  W: 480, H: 165,
  PAD: { l: 50, r: 10, t: 18, b: 22 },
  Y_MIN: 75, Y_MAX: 225,
};

function chartX(i, n) {
  return CHART.PAD.l + (i / (n - 1)) * (CHART.W - CHART.PAD.l - CHART.PAD.r);
}
function chartY(v) {
  const norm = Math.max(0, Math.min(1, (v - CHART.Y_MIN) / (CHART.Y_MAX - CHART.Y_MIN)));
  return CHART.PAD.t + (1 - norm) * (CHART.H - CHART.PAD.t - CHART.PAD.b);
}
function toPoints(arr) {
  return arr.map((v, i) => `${chartX(i, arr.length).toFixed(1)},${chartY(v).toFixed(1)}`).join(' ');
}
function toFillPoints(arr) {
  const n = arr.length;
  const bottom = (CHART.H - CHART.PAD.b + 5).toFixed(1);
  return toPoints(arr) + ` ${chartX(n - 1, n).toFixed(1)},${bottom} ${CHART.PAD.l},${bottom}`;
}

/* ── NAV ── */
function NavBar({ dark, setDark, lang, setLang }) {
  return <SiteHeader dark={dark} setDark={setDark} lang={lang} setLang={setLang} showLanguage={true} />;
}

/* ── HERO ── */
function Hero({ t, lang }) {
  const c = t.hero;
  const stats = t.heroStats;
  return (
    <section className="hero">
      <div className="hero-inner">
        <div className="hero-tag"><span className="pulse"></span>{c.tag}</div>
        <h1 className="hero-h1">
          <span className="dim">{c.h1a}</span><br />
          <span className="accent">{c.h1b}</span>
        </h1>
        <p className="hero-desc">{c.desc}</p>
        <div className="hero-cta">
          <a href={`/${lang}/install.html`} className="btn-primary">
            {c.cta1}
          </a>
          <a href="#ai-agents" className="btn-secondary">{c.cta2} →</a>
        </div>
        <div className="hero-stats">
          {stats.map((s, i) => (
            <div key={i} className="stat">
              <span className="stat-val">{s.accent ? <span className="accent">{s.val}</span> : s.val}</span>
              <span className="stat-lbl">{s.lbl}</span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── AI AGENT INTEGRATION ── */
function AIAgentSection({ t, lang }) {
  const c = t.aiAgents;
  if (!c) return null;
  const prefixMap = { user: '❯', tool: '$', agent: '⏺' };
  return (
    <section className="ai-agents reveal" id="ai-agents">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <p className="ai-agents-subtitle">{c.subtitle}</p>
        <div className="ai-agents-shell">
          <div className="agent-chat">
            <div className="agent-chat-bar">
              <span className="agent-chat-dot"></span>
              <span className="agent-chat-dot"></span>
              <span className="agent-chat-dot"></span>
              <span className="agent-chat-title">{c.chat.title}</span>
            </div>
            <div className="agent-chat-body">
              {c.chat.lines.map((l, i) => (
                <div key={i} className={`chat-line chat-${l.role}`}>
                  <span className="chat-prefix">{prefixMap[l.role]}</span>
                  <span className="chat-text">{l.text}</span>
                </div>
              ))}
            </div>
          </div>
          <div className="agent-paths">
            {c.paths.map((p, i) => (
              <article key={i} className="agent-path-card">
                <div className="agent-path-head">
                  <span className="agent-path-name">{p.name}</span>
                  <span className="agent-path-badge">{p.badge}</span>
                </div>
                <p className="agent-path-desc">{p.desc}</p>
                <code className="agent-path-code">{p.code}</code>
                <div className="card-tags">
                  {p.tags.map(tag => <span key={tag} className="tag">{tag}</span>)}
                </div>
              </article>
            ))}
          </div>
        </div>
        <p className="ai-agents-ecosystem">{c.ecosystem}</p>
        <a className="btn-secondary" href={`/${lang}/docs/ai-agents/`}>{c.docsCta} →</a>
      </div>
    </section>
  );
}

/* ── AVAILABILITY SUMMARY (Issue #101) ── */
function AvailabilitySummary({ t }) {
  const c = t.availability;
  if (!c) return null;
  const toneClass = { now: 'avail-now', beta: 'avail-beta', planned: 'avail-planned' };
  return (
    <section className="availability reveal" id="availability">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <p style={{ marginTop: '0.6rem', color: 'var(--text2)', fontSize: '0.92rem' }}>{c.subtitle}</p>
        <div className="availability-grid">
          {c.columns.map((col, i) => (
            <div key={i} className={`availability-col ${toneClass[col.tone]}`}>
              <div className="availability-col-head">
                <span className="availability-status">{col.status}</span>
                <h3 className="availability-col-title">{col.title}</h3>
              </div>
              <ul className="availability-list">
                {col.items.map((it, j) => (
                  <li key={j} className="availability-item">
                    <span className="availability-mark">{col.mark}</span>
                    <span>{it}</span>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── FREE START ── */
function TrialStart({ t, lang }) {
  const c = t.trialStart;
  return (
    <section className="trial-start reveal" id="trial-start">
      <div className="container">
        <div className="trial-start-shell">
          <div className="trial-start-copy">
            <div className="sec-label">{c.label}</div>
            <h2 className="trial-start-title">{c.title}</h2>
            <p className="trial-start-subtitle">{c.subtitle}</p>
            <div className="trial-start-limits">
              {c.limits.map((limit) => (
                <span key={limit} className="trial-start-limit">{limit}</span>
              ))}
            </div>
            <div className="trial-start-actions">
              <a href={`/${lang}/install.html`} className="btn-primary">{c.primaryCta}</a>
              <a href="#pricing" className="btn-secondary">{c.secondaryCta} →</a>
              <a
                href="https://x.com/alforge_bot"
                target="_blank"
                rel="noopener"
                className="trial-start-link"
              >
                {c.updateCta}
              </a>
            </div>
            <p className="trial-start-note">{c.availability}</p>
          </div>
          <div className="trial-start-steps">
            {c.steps.map((step) => (
              <article key={step.num} className="trial-start-step">
                <span className="trial-start-step-num">{step.num}</span>
                <h3 className="trial-start-step-title">{step.title}</h3>
                <p className="trial-start-step-desc">{step.desc}</p>
              </article>
            ))}
            {c.outExamplesCta && (
              <a href={`/${lang}/docs/guides/output-examples/`} className="trial-start-link trial-start-examples-link">
                {c.outExamplesCta} →
              </a>
            )}
          </div>
        </div>
      </div>
    </section>
  );
}

/* ── PRODUCTS ── */
function Products({ t }) {
  const c = t.products;
  const badgeClass = { beta: 'badge-beta', alpha: 'badge-alpha', dev: 'badge-dev', released: 'badge-released' };
  return (
    <section className="products reveal" id="products">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <p style={{ marginTop: '0.6rem', color: 'var(--text2)', fontSize: '0.92rem' }}>{c.subtitle}</p>
        <div className="products-grid" style={{ marginTop: '2.5rem' }}>
          {c.items.map(item => (
            <div
              key={item.id}
              className="product-card"
              style={{ '--card-accent': item.accent }}
            >
              <div className="card-top">
                <span className={`card-badge ${badgeClass[item.badgeType]}`}>{item.badge}</span>
                <div className="card-icon">{item.icon}</div>
              </div>
              <div>
                <div className="card-role">{item.role}</div>
                <div className="card-name" style={{ marginTop: '0.25rem' }}>
                  <span className="prefix">alpha-</span>{item.name}
                </div>
              </div>
              <p className="card-desc">{item.desc}</p>
              <div className="card-tags">
                {item.tags.map(tag => <span key={tag} className="tag">{tag}</span>)}
              </div>
              {item.links && (
                <div className="card-links">
                  {item.links.map(link => (
                    <a
                      key={link.href}
                      className="card-link"
                      href={link.href}
                      target={link.external ? '_blank' : undefined}
                      rel={link.external ? 'noopener noreferrer' : undefined}
                    >
                      {link.label}<span aria-hidden="true"> ↗</span>
                    </a>
                  ))}
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── PERFORMANCE CHART ── */

function useChartColors(dark) {
  const fallback = {
    accent: dark ? '#00e49a' : '#009e70',
    blue:   dark ? '#5b9fff' : '#3a7ef0',
    amber:  dark ? '#f5a623' : '#d97706',
  };
  const [colors, setColors] = React.useState(fallback);
  React.useEffect(() => {
    const cs = getComputedStyle(document.documentElement);
    const accent = cs.getPropertyValue('--chart-cl').trim();
    const blue   = cs.getPropertyValue('--chart-spy').trim();
    const amber  = cs.getPropertyValue('--chart-qqq').trim();
    setColors({
      accent: accent || fallback.accent,
      blue:   blue   || fallback.blue,
      amber:  amber  || fallback.amber,
    });
  }, [dark]);
  return colors;
}

const GRID_LINES = [
  { v: 200, label: '+100%' },
  { v: 170, label: '+70%'  },
  { v: 140, label: '+40%'  },
  { v: 110, label: '+10%'  },
  { v: 80,  label: '-20%'  },
];

function EquityChartSVG({ equityCurve, colors }) {
  const ec = equityCurve;
  return (
    <svg
      viewBox={`0 0 ${CHART.W} ${CHART.H}`}
      style={{ width: '100%', display: 'block', background: 'var(--bg2)', borderRadius: 'var(--r)' }}
      preserveAspectRatio="none"
    >
      {GRID_LINES.map(({ v, label }) => {
        const y = chartY(v).toFixed(1);
        return (
          <g key={v}>
            <line x1={CHART.PAD.l} y1={y} x2={CHART.W - CHART.PAD.r} y2={y} stroke="var(--border)" strokeWidth="1" />
            <text x={CHART.PAD.l - 4} y={y} fill="var(--text3)" fontSize="8" fontFamily="var(--mono)" textAnchor="end" dominantBaseline="middle">{label}</text>
          </g>
        );
      })}
      <line
        x1={CHART.PAD.l} y1={chartY(100).toFixed(1)}
        x2={CHART.W - CHART.PAD.r} y2={chartY(100).toFixed(1)}
        stroke="var(--text3)" strokeWidth="0.5" strokeDasharray="2,2"
      />
      {ec.yearLabels.map((yr, i) => {
        const x = chartX(ec.yearIndices[i], ec.cl.length);
        return (
          <text key={yr} x={x.toFixed(1)} y={(CHART.H - 4).toFixed(1)} fill="var(--text3)" fontSize="8" fontFamily="var(--mono)" textAnchor="middle">{yr}</text>
        );
      })}
      <polyline points={toPoints(ec.qqq)} fill="none" stroke={colors.amber} strokeWidth="1.2" strokeDasharray="4,3" opacity="0.7" />
      <polyline points={toPoints(ec.spy)} fill="none" stroke={colors.blue} strokeWidth="1.2" strokeDasharray="5,4" opacity="0.85" />
      <polygon points={toFillPoints(ec.cl)} fill={colors.accent} fillOpacity="0.06" />
      <polyline points={toPoints(ec.cl)} fill="none" stroke={colors.accent} strokeWidth="2.5" />
    </svg>
  );
}

function BenchmarkTable({ bench, colors }) {
  return (
    <div style={{ marginTop: '0.75rem', background: 'var(--bg2)', borderRadius: 'var(--r)', padding: '0.75rem 1rem' }}>
      <div style={{ fontFamily: 'var(--mono)', fontSize: '0.62rem', color: 'var(--text3)', marginBottom: '0.45rem', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
        {bench.label}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr 1fr', gap: '0.3rem', fontFamily: 'var(--mono)', fontSize: '0.68rem' }}>
        {bench.headers.map((h, i) => (
          <div key={i} style={{ color: i === 0 ? 'transparent' : i === 1 ? colors.blue : i === 2 ? colors.amber : colors.accent }}>{h}</div>
        ))}
        {bench.rows.map((row, ri) => (
          <React.Fragment key={ri}>
            <div style={{ color: 'var(--text2)' }}>{row.metric}</div>
            <div style={{ color: colors.blue }}>{row.spy}</div>
            <div style={{ color: colors.amber }}>{row.qqq}</div>
            <div style={{ color: colors.accent, fontWeight: row.stratWin ? '600' : '400' }}>
              {row.strat}{row.stratWin ? ' ✓' : ''}
            </div>
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}

function PerformanceChart({ t, dark }) {
  const c = t.perf;
  const ec = window.EQUITY_CURVE;
  const colors = useChartColors(dark);
  if (!ec) return null;

  return (
    <section className="performance reveal" id="performance">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title">{c.title}</h2>
        <div className="perf-inner" style={{ marginTop: '2.5rem' }}>
          <div className="perf-header">
            <div>
              <div className="perf-strategy">{c.strategy}</div>
              <div className="perf-period" style={{ marginTop: '0.2rem' }}>{c.period}</div>
            </div>
          </div>
          <div className="perf-stats">
            {c.stats.map((s, i) => (
              <div key={i} className="perf-stat">
                <span className={`perf-val ${s.cls}`}>{s.val}</span>
                <span className="perf-lbl">{s.label}</span>
              </div>
            ))}
          </div>
          <div className="chart-area">
            <div className="chart-legend">
              <div className="legend-item">
                <div className="legend-dot" style={{ background: colors.accent, height: '2px' }}></div>
                {c.legend[0].label}
              </div>
              <div className="legend-item">
                <div className="legend-dot" style={{ background: colors.blue, height: '1px', borderTop: `1px dashed ${colors.blue}` }}></div>
                {c.legend[1].label}
              </div>
              <div className="legend-item">
                <div className="legend-dot" style={{ background: colors.amber, height: '1px', borderTop: `1px dashed ${colors.amber}` }}></div>
                {c.legend[2].label}
              </div>
            </div>
            <EquityChartSVG equityCurve={ec} colors={colors} />
            <BenchmarkTable bench={c.bench} colors={colors} />
            <p className="chart-note">{c.note}</p>
          </div>
        </div>
      </div>
    </section>
  );
}

/* ── FREE BANNER ── */
function TrialBanner({ plan, comingSummer, lang }) {
  const pillClass = { ok: 'trial-pill-ok', limit: 'trial-pill-limit', no: 'trial-pill-no' };
  return (
    <div className="trial-banner">
      <div className="trial-banner-icon">⚙</div>
      <div className="trial-banner-body">
        <div className="trial-banner-title">
          {plan.title}
          <span className="trial-badge">{plan.badge}</span>
        </div>
        <p className="trial-banner-desc" style={{ whiteSpace: 'pre-line' }}>{plan.desc}</p>
        <div className="trial-banner-pills">
          {plan.pills.map((p, i) => (
            <span key={i} className={`trial-pill ${pillClass[p.type]}`}>{p.label}</span>
          ))}
        </div>
      </div>
      <div className="trial-banner-cta">
        <a
          href={plan.url}
          className="btn-primary"
          style={{ justifyContent: 'center' }}
        >
          {plan.ctaLabel}
        </a>
        <span
          className="trial-banner-install-link"
          style={{ display: 'block', fontSize: '0.85em', textAlign: 'center', marginTop: '0.4rem', color: 'var(--text2)' }}
        >
          {plan.ctaHint}
        </span>
        <div className="trial-banner-status">{comingSummer}</div>
      </div>
    </div>
  );
}

/* ── COMPARISON TABLE ── */
function ComparisonTable({ data }) {
  return (
    <div className="pricing-comparison">
      <div className="comparison-label">{data.label}</div>
      <div className="comparison-table-wrapper">
      <table className="comparison-table">
        <thead>
          <tr>
            <th className="comparison-th-feature"></th>
            <th className="comparison-th-trial">{data.colTrial}</th>
            <th className="comparison-th-lifetime">{data.colLifetime}</th>
          </tr>
        </thead>
        <tbody>
          {data.rows.map((row, i) => (
            <tr key={i}>
              <td className="comparison-td-feature">{row.feature}</td>
              <td className="comparison-td-trial">
                {row.trial === 'ok'    && <span className="cmp-ok">✓</span>}
                {row.trial === 'limit' && <span className="cmp-limit">{row.trialNote}</span>}
                {row.trial === 'no'    && <span className="cmp-no">—</span>}
              </td>
              <td className="comparison-td-lifetime">
                {row.lifetime === 'ok' && (
                  <span className="cmp-ok">{row.lifetimeNote || '✓'}</span>
                )}
                {row.lifetime === 'limit' && <span className="cmp-limit">{row.lifetimeNote}</span>}
                {row.lifetime === 'no'    && <span className="cmp-no">—</span>}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      </div>
    </div>
  );
}

/* ── PRICING ── */
function Pricing({ t, lang }) {
  const c = t.pricing;
  return (
    <section className="pricing reveal" id="pricing">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <p style={{ marginTop: '0.6rem', color: 'var(--text2)', fontSize: '0.92rem' }}>{c.subtitle}</p>
        <TrialBanner plan={c.trialPlan} comingSummer={c.trialPlan.comingSummer} lang={lang} />
        <div className="pricing-grid" style={{ marginTop: '1rem' }}>
          {c.plans.map((plan, i) => (
            <div key={i} className={`pricing-card${plan.featured ? ' featured' : ''}`}>
              <div className="pricing-card-top">
                <div className="pricing-plan">{plan.name}</div>
                {plan.badge && <span className="pricing-badge">{plan.badge}</span>}
              </div>
              <div className="pricing-price">
                <span className="price-amount">{plan.price}</span>
                <span className="price-period">{plan.period}</span>
              </div>
              <p className="pricing-desc">{plan.desc}</p>
              <ul className="pricing-features">
                {plan.features.map((f, j) => (
                  <li key={j} className="pricing-feature">
                    <span className="feature-check">✓</span>
                    <span>{f}</span>
                  </li>
                ))}
              </ul>
              <a
                href={plan.url}
                target="_blank"
                rel="noopener noreferrer"
                className={plan.featured ? 'btn-primary' : 'btn-secondary'}
                style={{ justifyContent: 'center', marginTop: 'auto' }}
              >
                {c.buyNow}
              </a>
            </div>
          ))}
        </div>
        <ComparisonTable data={c.comparison} />
        <p className="pricing-note">{c.note}</p>
      </div>
    </section>
  );
}

/* ── USE CASES ── */
function UseCases({ t }) {
  const c = t.usecases;
  return (
    <section className="usecases reveal" id="usecases">
      <div className="usecases-inner">
        <div className="usecases-header">
          <div className="sec-label">{c.label}</div>
          <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
          <p className="usecases-subtitle">{c.subtitle}</p>
        </div>
        <div className="usecases-grid">
          {c.items.map((item, i) => (
            <div
              key={i}
              className="usecase-card"
              style={{ '--card-accent': item.accent }}
            >
              <div className="usecase-icon">{item.icon}</div>
              <span className="usecase-badge">{item.label}</span>
              <div className="usecase-title">{item.title}</div>
              <p className="usecase-desc">{item.desc}</p>
              <div className="usecase-tags">
                {item.tags.map((tag, j) => (
                  <span key={j} className="tag">{tag}</span>
                ))}
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── 目的別ユースケース ── */
function PersonaUseCases({ t }) {
  const c = t.personaUseCases;
  return (
    <section className="persona-usecases reveal" id="persona-usecases">
      <div className="usecases-inner">
        <div className="usecases-header">
          <div className="sec-label">{c.label}</div>
          <h2 className="sec-title">{c.title}</h2>
          <p className="usecases-subtitle">{c.subtitle}</p>
        </div>
        <div className="persona-grid">
          {c.personas.map((p, i) => (
            <a key={i} className="persona-card" href={p.link}>
              <div className="persona-icon">{p.icon}</div>
              <span className="usecase-badge">{p.label}</span>
              <div className="usecase-title">{p.title}</div>
              <p className="usecase-desc">{p.desc}</p>
              <span className="persona-link">{p.linkLabel}</span>
            </a>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── 継続利用価値 ── */
function LongTermValue({ t }) {
  const c = t.longTermValue;
  return (
    <section className="long-term-value reveal" id="long-term-value">
      <div className="container">
        <div className="long-term-header">
          <div className="sec-label">{c.label}</div>
          <h2 className="sec-title">{c.title}</h2>
          <p className="long-term-subtitle">{c.subtitle}</p>
        </div>
        <div className="long-term-grid">
          {c.items.map((item, i) => (
            <article key={i} className="long-term-card">
              <div className="long-term-index">{String(i + 1).padStart(2, '0')}</div>
              <div className="long-term-eyebrow">{item.eyebrow}</div>
              <h3 className="long-term-title">{item.title}</h3>
              <p className="long-term-desc">{item.desc}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── 信頼・安全・制限 ── */
function TrustSafety({ t }) {
  const c = t.trustSafety;
  return (
    <section className="trust-safety reveal" id="trust-safety">
      <div className="container">
        <div className="trust-safety-header">
          <div className="sec-label">{c.label}</div>
          <h2 className="sec-title">{c.title}</h2>
          <p className="trust-safety-subtitle">{c.subtitle}</p>
        </div>
        <div className="trust-safety-grid">
          {c.items.map((item) => (
            <article key={item.eyebrow} className="trust-safety-card">
              <div className="trust-safety-eyebrow">{item.eyebrow}</div>
              <h3 className="trust-safety-title">{item.title}</h3>
              <p className="trust-safety-desc">{item.desc}</p>
            </article>
          ))}
        </div>
        <a className="trust-safety-link" href={c.docsHref}>
          {c.docsLabel} →
        </a>
      </div>
    </section>
  );
}

/* ── SYSTEM FLOW ── */
function SystemFlow({ t, dark, lang }) {
  const c = t.systemFlow;
  const theme = dark ? 'dark' : 'light';
  const src = `../assets/illustrations/system-flow/alphatrade-system-flow-${lang}-${theme}.png`;
  return (
    <section className="system-flow reveal" id="system-flow">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <p className="system-flow-subtitle">{c.subtitle}</p>
        <figure className="system-flow-figure">
          <img className="system-flow-image" src={src} alt={c.alt} loading="lazy" decoding="async" />
        </figure>
      </div>
    </section>
  );
}

/* ── EXPORT ── */
Object.assign(window, { NavBar, Hero, AIAgentSection, AvailabilitySummary, TrialStart, Products, useChartColors, EquityChartSVG, BenchmarkTable, PerformanceChart, TrialBanner, ComparisonTable, Pricing, UseCases, PersonaUseCases, SystemFlow, LongTermValue, TrustSafety });

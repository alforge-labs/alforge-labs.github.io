// homepage-app.jsx
// Roadmap, FAQ, FollowCTA, Footer, Tweaks, App root

/* ── X ICON (local copy for this scope) ── */
function XIconApp({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.73-8.835L1.254 2.25H8.08l4.253 5.622zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
  );
}

/* ── ROADMAP ── */
function Roadmap({ t }) {
  const c = t.roadmap;
  const badgeClass = { done: 'rm-badge-done', active: 'rm-badge-active', upcoming: 'rm-badge-upcoming' };
  return (
    <section className="roadmap reveal" id="roadmap">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <div className="roadmap-inner" style={{ marginTop: '2.5rem' }}>
          {c.items.map((item, i) => (
            <div key={i} className={`rm-item ${item.status}`}>
              <div className="rm-dot"></div>
              <div className="rm-period">{item.period}</div>
              <div className="rm-content">
                <span className={`rm-badge ${badgeClass[item.status]}`}>{item.badgeLabel}</span>
                <div className="rm-title">{item.title}</div>
                <div className="rm-items">
                  {item.items.map((li, j) => (
                    <div key={j} className="rm-li">{li}</div>
                  ))}
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── FAQ ── */
function FAQ({ t }) {
  const c = t.faq;
  const [open, setOpen] = React.useState(null);
  const toggle = (i) => setOpen(o => o === i ? null : i);
  return (
    <section className="faq reveal" id="faq">
      <div className="container">
        <div className="sec-label">{c.label}</div>
        <h2 className="sec-title" style={{ whiteSpace: 'pre-line' }}>{c.title}</h2>
        <div className="faq-inner" style={{ marginTop: '2.5rem' }}>
          {c.items.map((item, i) => (
            <div key={i} className={`faq-item${open === i ? ' open' : ''}`}>
              <button className="faq-q" onClick={() => toggle(i)}>
                <span className="faq-q-text">{item.q}</span>
                <span className="faq-chevron">+</span>
              </button>
              <div className="faq-a">
                <div className="faq-a-inner">{item.a}</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── FOLLOW CTA ── */
function FollowCTA({ t }) {
  const c = t.follow;
  return (
    <section className="follow-cta reveal" style={{ borderBottom: '1px solid var(--border)' }}>
      <div className="container">
        <div className="follow-cta-inner">
          <div className="sec-label" style={{ justifyContent: 'center' }}>{c.label}</div>
          <h2 className="sec-title" style={{ textAlign: 'center', fontSize: 'clamp(1.8rem, 4vw, 2.75rem)', whiteSpace: 'pre-line' }}>
            {c.title}
          </h2>
          <div className="x-handle">
            <XIconApp size={28} />
            @alforge_bot
          </div>
          <p className="follow-desc">{c.desc}</p>
          <a
            href="https://x.com/alforge_bot"
            target="_blank" rel="noopener"
            className="btn-primary"
            style={{ marginTop: '0.5rem', padding: '0.85rem 2rem', fontSize: '0.92rem' }}
          >
            <XIconApp size={15} />{c.cta}
          </a>
        </div>
      </div>
    </section>
  );
}

/* ── DISCLAIMER ── */
function Disclaimer({ t }) {
  const c = t.disclaimer;
  return (
    <section className="disclaimer-section">
      <div className="disclaimer-box">
        <h3 className="disclaimer-title">{c.title}</h3>
        <div className="disclaimer-grid">
          {c.items.map((item, i) => (
            <div key={i} className="disclaimer-item">
              <span className="disclaimer-label">{item.label}</span>
              <p className="disclaimer-text">{item.text}</p>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}

/* ── FOOTER ── */
function Footer({ t }) {
  const c = t.footer;
  return (
    <footer>
      <div className="footer-logo">alforge<span className="dot">.</span>labs</div>
      <div className="footer-right">
        <div className="footer-links">
          {c.links.map((l, i) => (
            <a key={i} href={l.url}>{l.label}</a>
          ))}
        </div>
        <span className="footer-copy">{c.copy}</span>
        <span className="footer-note">{c.note}</span>
      </div>
    </footer>
  );
}

/* ── TWEAKS PANEL ── */
const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "accentScheme": "green",
  "density": "default"
}/*EDITMODE-END*/;

function TweaksPanel({ visible, dark, setDark, lang, setLang }) {
  const [accent, setAccent] = React.useState(TWEAK_DEFAULTS.accentScheme);

  const applyAccent = (scheme) => {
    setAccent(scheme);
    const root = document.documentElement;
    if (scheme === 'blue') {
      root.style.setProperty('--accent', dark ? '#5b9fff' : '#3a7ef0');
      root.style.setProperty('--accent-d', dark ? '#3a7ef0' : '#2563d4');
      root.style.setProperty('--accent-glow', dark ? 'rgba(91,159,255,0.18)' : 'rgba(58,126,240,0.14)');
      root.style.setProperty('--accent-bg', dark ? 'rgba(91,159,255,0.07)' : 'rgba(58,126,240,0.07)');
    } else {
      root.style.removeProperty('--accent');
      root.style.removeProperty('--accent-d');
      root.style.removeProperty('--accent-glow');
      root.style.removeProperty('--accent-bg');
    }
    window.parent && window.parent.postMessage({ type: '__edit_mode_set_keys', edits: { accentScheme: scheme } }, '*');
  };

  if (!visible) return null;
  return (
    <div className="tweaks-panel open">
      <div className="tweaks-title">Tweaks</div>
      <div className="tweaks-row">
        <div className="tweaks-lbl">言語 / Language</div>
        <div className="tweaks-opts">
          {['ja','en'].map(l => (
            <div key={l} className={`tweaks-opt${lang === l ? ' active' : ''}`} onClick={() => setLang(l)}>
              {l.toUpperCase()}
            </div>
          ))}
        </div>
      </div>
      <div className="tweaks-row">
        <div className="tweaks-lbl">テーマ / Theme</div>
        <div className="tweaks-opts">
          <div className={`tweaks-opt${dark ? ' active' : ''}`} onClick={() => setDark(true)}>Dark</div>
          <div className={`tweaks-opt${!dark ? ' active' : ''}`} onClick={() => setDark(false)}>Light</div>
        </div>
      </div>
      <div className="tweaks-row">
        <div className="tweaks-lbl">アクセント / Accent</div>
        <div className="tweaks-opts">
          <div className={`tweaks-opt${accent === 'green' ? ' active' : ''}`} onClick={() => applyAccent('green')}>Green</div>
          <div className={`tweaks-opt${accent === 'blue' ? ' active' : ''}`} onClick={() => applyAccent('blue')}>Blue</div>
        </div>
      </div>
    </div>
  );
}

/* ── SCROLL REVEAL ── */
function useReveal() {
  React.useEffect(() => {
    const obs = new IntersectionObserver((entries) => {
      entries.forEach(e => {
        if (e.isIntersecting) { e.target.classList.add('visible'); obs.unobserve(e.target); }
      });
    }, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });
    document.querySelectorAll('.reveal').forEach(el => obs.observe(el));
    return () => obs.disconnect();
  }, []);
}

/* ── APP ── */
function App() {
  const savedTheme = localStorage.getItem('al_theme');
  const [dark, setDark] = React.useState(savedTheme ? savedTheme === 'dark' : true);
  const pathLang = window.location.pathname.startsWith('/en') ? 'en' :
                   window.location.pathname.startsWith('/ja') ? 'ja' : null;
  const [lang, setLang] = React.useState(pathLang || localStorage.getItem('al_lang') || 'ja');
  const [tweaks, setTweaks] = React.useState(false);

  // Apply theme
  React.useEffect(() => {
    document.documentElement.setAttribute('data-theme', dark ? 'dark' : 'light');
    document.body.setAttribute('data-theme', dark ? 'dark' : 'light');
    localStorage.setItem('al_theme', dark ? 'dark' : 'light');
  }, [dark]);

  // Persist lang
  React.useEffect(() => {
    localStorage.setItem('al_lang', lang);
    document.documentElement.setAttribute('lang', lang);
  }, [lang]);

  // Tweaks host integration
  React.useEffect(() => {
    const handler = (e) => {
      if (e.data?.type === '__activate_edit_mode') setTweaks(true);
      if (e.data?.type === '__deactivate_edit_mode') setTweaks(false);
    };
    window.addEventListener('message', handler);
    window.parent.postMessage({ type: '__edit_mode_available' }, '*');
    return () => window.removeEventListener('message', handler);
  }, []);

  const t = window.COPY[lang];
  useReveal();

  return (
    <div className="app">
      <NavBar dark={dark} setDark={setDark} lang={lang} setLang={setLang} t={t} />
      <Hero t={t} lang={lang} />
      <AvailabilitySummary t={t} lang={lang} />
      <TrialStart t={t} lang={lang} />
      <Products t={t} />
      <SystemFlow t={t} dark={dark} lang={lang} />
      <UseCases t={t} />
      <PersonaUseCases t={t} />
      <LongTermValue t={t} />
      <PerformanceChart t={t} dark={dark} />
      <Pricing t={t} lang={lang} />
      <TrustSafety t={t} />
      <Roadmap t={t} />
      <FAQ t={t} />
      <FollowCTA t={t} />
      <Disclaimer t={t} />
      <Footer t={t} />
      <TweaksPanel visible={tweaks} dark={dark} setDark={setDark} lang={lang} setLang={setLang} />
    </div>
  );
}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);

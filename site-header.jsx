// 全ページ共通ヘッダー

const HEADER_COPY = {
  ja: {
    products: 'プロダクト',
    aiAgents: 'AIエージェント',
    pricing: '料金',
    install: 'インストール',
    mkdocs: 'ドキュメント',
    tutorial: 'チュートリアル',
    roadmap: 'ロードマップ',
    faq: 'FAQ',
    follow: 'フォロー',
    toggleTheme: 'テーマ切替',
  },
  en: {
    products: 'Products',
    aiAgents: 'AI Agents',
    pricing: 'Pricing',
    install: 'Install',
    mkdocs: 'Docs',
    tutorial: 'Tutorial',
    roadmap: 'Roadmap',
    faq: 'FAQ',
    follow: 'Follow',
    toggleTheme: 'Toggle theme',
  },
};

// index ページにいる場合はフラグメントのみ、他ページからは index.html#xxx で遷移
const _p = window.location.pathname;
const _anchorBase = (_p === '/ja/' || _p === '/en/' || _p.endsWith('/index.html')) ? '' : 'index.html';

const HEADER_LINKS = [
  { key: 'aiAgents', href: _anchorBase + '#ai-agents' },
  { key: 'products', href: _anchorBase + '#products' },
  { key: 'pricing',  href: _anchorBase + '#pricing' },
  { key: 'install',  href: 'install.html' },
  { key: 'tutorial', href: 'tutorial-strategy.html' },
  { key: 'faq',      href: _anchorBase + '#faq' },
  { key: 'mkdocs',   href: 'docs/' },
];

function XIcon({ size = 16 }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="currentColor">
      <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-4.714-6.231-5.401 6.231H2.744l7.73-8.835L1.254 2.25H8.08l4.253 5.622zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
    </svg>
  );
}

function SiteHeader({ dark, setDark, lang = 'ja', setLang, active = '', showLanguage = false }) {
  const c = HEADER_COPY[lang] || HEADER_COPY.ja;
  const toggleLang = () => {
    const newLang = lang === 'ja' ? 'en' : 'ja';
    localStorage.setItem('al_lang', newLang);
    const p = window.location.pathname;
    if (p.startsWith('/ja/') || p.startsWith('/en/')) {
      window.location.href = '/' + newLang + p.slice(3) + window.location.hash;
    } else if (setLang) {
      setLang(newLang);
    }
  };

  return (
    <nav>
      <a href="index.html" className="nav-logo">
        <span>alforge</span><span className="dot">.</span><span className="labs">labs</span>
      </a>
      <ul className="nav-center">
        {HEADER_LINKS.map(link => (
          <li key={link.key}>
            <a href={link.href} className={[active === link.key ? 'active' : '', link.key === 'mkdocs' ? 'nav-mkdocs-link' : ''].filter(Boolean).join(' ')}>{c[link.key]}</a>
          </li>
        ))}
      </ul>
      <div className="nav-right">
        <a className="nav-page-link" href="docs/">{c.mkdocs}</a>
        {showLanguage && (
          <button className="lang-btn" onClick={toggleLang}>
            {lang === 'ja' ? 'EN' : 'JA'}
          </button>
        )}
        <button className="toggle-btn" onClick={() => setDark(d => !d)} title={c.toggleTheme}>
          {dark ? '☀' : '◑'}
        </button>
        <a className="follow-btn-nav" href="https://x.com/alforge_bot" target="_blank" rel="noopener">
          <XIcon size={13} />
          <span className="follow-label">{c.follow}</span>
        </a>
      </div>
    </nav>
  );
}

function renderStandaloneHeader({ active = '' } = {}) {
  const root = document.getElementById('site-header');
  if (!root) return;

  function StandaloneHeader() {
    const savedTheme = localStorage.getItem('al_theme');
    const [dark, setDark] = React.useState(savedTheme ? savedTheme === 'dark' : true);
    const _pathLang = window.location.pathname.startsWith('/en') ? 'en' :
                      window.location.pathname.startsWith('/ja') ? 'ja' : null;
    const [lang, setLang] = React.useState(_pathLang || localStorage.getItem('al_lang') || 'ja');

    React.useEffect(() => {
      const theme = dark ? 'dark' : 'light';
      document.documentElement.setAttribute('data-theme', theme);
      document.body.setAttribute('data-theme', theme);
      localStorage.setItem('al_theme', theme);
    }, [dark]);

    React.useEffect(() => {
      localStorage.setItem('al_lang', lang);
      document.documentElement.setAttribute('lang', lang);
      document.body.setAttribute('data-lang', lang);
    }, [lang]);

    return <SiteHeader dark={dark} setDark={setDark} lang={lang} setLang={setLang} active={active} showLanguage={true} />;
  }

  ReactDOM.createRoot(root).render(<StandaloneHeader />);

  document.addEventListener('DOMContentLoaded', function() {
    if (!window.IntersectionObserver) return;
    var obs = new IntersectionObserver(function(entries) {
      entries.forEach(function(e) {
        if (e.isIntersecting) { e.target.classList.add('visible'); obs.unobserve(e.target); }
      });
    }, { threshold: 0.08, rootMargin: '0px 0px -40px 0px' });
    document.querySelectorAll('h2.section-heading, .callout, .steps li, .cmd-table, .platform-tabs, pre').forEach(function(el) {
      el.classList.add('reveal');
      obs.observe(el);
    });
  });
}

Object.assign(window, { SiteHeader, renderStandaloneHeader });

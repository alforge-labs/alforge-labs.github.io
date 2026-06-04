import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class HomepageTrustSafetyTest(unittest.TestCase):
    def test_trust_safety_copy_exists_in_both_languages(self):
        copy = read("homepage-copy.jsx")

        self.assertIn("trustSafety", copy)
        self.assertIn("信頼・安全・制限", copy)
        self.assertIn("Trust, Safety, and Limits", copy)
        self.assertIn("API キー・取引履歴・戦略データ", copy)
        self.assertIn("API keys, trade history, and strategy data", copy)
        self.assertIn("投資助言ではありません", copy)
        self.assertIn("not financial advice", copy)
        # Trial / Lifetime 2 ティア刷新（5bc4102）後のプランカード表記
        self.assertIn("Trial / Monthly / Annual / Lifetime", copy)
        self.assertIn("/ja/docs/legal/trust-safety-limits/", copy)
        self.assertIn("/en/docs/legal/trust-safety-limits/", copy)

    def test_trust_safety_component_is_rendered_between_pricing_and_roadmap(self):
        components = read("homepage-components.jsx")
        app = read("homepage-app.jsx")

        self.assertIn("function TrustSafety", components)
        self.assertIn('className="trust-safety reveal"', components)
        self.assertIn("TrustSafety", components)

        pricing_pos = app.index("<Pricing t={t} lang={lang} />")
        trust_pos = app.index("<TrustSafety t={t} />")
        roadmap_pos = app.index("<Roadmap t={t} />")
        self.assertLess(pricing_pos, trust_pos)
        self.assertLess(trust_pos, roadmap_pos)

    def test_trust_safety_styles_and_generated_pages_are_present(self):
        template = read("templates/index.html.j2")
        ja_html = read("ja/index.html")
        en_html = read("en/index.html")

        self.assertIn(".trust-safety", template)
        self.assertIn(".trust-safety-grid", template)
        self.assertIn(".trust-safety-link", template)
        self.assertIn(".trust-safety", ja_html)
        self.assertIn(".trust-safety", en_html)
        self.assertIn('src="../homepage-copy.jsx"', ja_html)
        self.assertIn('src="../homepage-copy.jsx"', en_html)

    def test_mkdocs_trust_safety_pages_and_navigation_exist(self):
        ja_doc = read("mkdocs_src/ja/legal/trust-safety-limits.md")
        en_doc = read("mkdocs_src/en/legal/trust-safety-limits.md")
        ja_nav = read("mkdocs.ja.yml")
        en_nav = read("mkdocs.en.yml")

        self.assertIn("# 信頼・安全・制限", ja_doc)
        self.assertIn("# Trust, Safety, and Limits", en_doc)
        # 認証時の送信情報・プラン制限の説明と Trial 制限ページへの導線が
        # 揃っていることが、購入前の不安解消ページとしての成立条件
        self.assertIn("## 認証で送信される情報", ja_doc)
        self.assertIn("## What is sent during authentication", en_doc)
        self.assertIn("## プラン制限", ja_doc)
        self.assertIn("## Plan limits", en_doc)
        self.assertIn("(../guides/trial-limits.md)", ja_doc)
        self.assertIn("(../guides/trial-limits.md)", en_doc)
        self.assertIn("信頼・安全・制限: legal/trust-safety-limits.md", ja_nav)
        self.assertIn("Trust, Safety, and Limits: legal/trust-safety-limits.md", en_nav)

    def test_existing_legal_and_limits_pages_link_to_trust_safety_page(self):
        # freemium-limits.md は Free プラン廃止（3a7b400）で trial-limits.md に改名
        paths = [
            "mkdocs_src/ja/legal/disclaimers.md",
            "mkdocs_src/ja/legal/privacy.md",
            "mkdocs_src/ja/guides/trial-limits.md",
            "mkdocs_src/en/legal/disclaimers.md",
            "mkdocs_src/en/legal/privacy.md",
            "mkdocs_src/en/guides/trial-limits.md",
        ]

        for path in paths:
            with self.subTest(path=path):
                self.assertIn("trust-safety-limits.md", read(path))


if __name__ == "__main__":
    unittest.main()

import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class HomepageLongTermValueTest(unittest.TestCase):
    def test_long_term_value_copy_exists_in_both_languages(self):
        copy = read("homepage-copy.jsx")

        self.assertIn("longTermValue", copy)
        self.assertIn("戦略は、作って終わりではない", copy)
        self.assertIn("Strategies are never finished", copy)
        self.assertIn("市場レジームは変わる", copy)
        self.assertIn("New ideas keep arriving", copy)
        self.assertIn("検証ループを回せる", copy)
        self.assertIn("Keep the validation loop moving", copy)

    def test_long_term_value_component_is_rendered_between_usecases_and_performance(self):
        components = read("homepage-components.jsx")
        app = read("homepage-app.jsx")

        self.assertIn("function LongTermValue", components)
        self.assertIn('className="long-term-value reveal"', components)
        # window 登録は app.jsx が別 script から参照するための必須条件
        # （未登録だと undefined 参照で LP 全体が白画面になる）
        self.assertRegex(components, r"Object\.assign\(window, \{[^}]*\bLongTermValue\b")

        usecases_pos = app.index("<UseCases t={t} />")
        long_term_pos = app.index("<LongTermValue t={t} />")
        performance_pos = app.index("<PerformanceChart t={t} dark={dark} />")
        self.assertLess(usecases_pos, long_term_pos)
        self.assertLess(long_term_pos, performance_pos)

    def test_long_term_value_styles_and_generated_pages_are_present(self):
        template = read("templates/index.html.j2")
        ja_html = read("ja/index.html")
        en_html = read("en/index.html")

        self.assertIn(".long-term-value", template)
        self.assertIn(".long-term-grid", template)
        self.assertRegex(template, r"@media \(max-width: 900px\).*?\.long-term-grid", re.S)
        self.assertIn(".long-term-value", ja_html)
        self.assertIn(".long-term-value", en_html)
        self.assertIn('src="../homepage-copy.jsx"', ja_html)
        self.assertIn('src="../homepage-copy.jsx"', en_html)


if __name__ == "__main__":
    unittest.main()

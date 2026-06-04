"""LP の Trial 開始導線（TrialStart セクション）の回帰テスト。

旧 FreeStart セクションは Trial / Lifetime 2 ティア刷新（5bc4102）で
TrialStart にリネームされた。本テストはその現行仕様を検証する:
LP には「Whop 登録不要で今すぐ試せる」導線が Hero 直後にあり、
Trial の 3 制限（データ上限・最適化回数・Pine 出力不可）が日英両方で
明示されていることが、無料→有料転換ファネルの前提となる。
"""

import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class HomepageTrialStartTest(unittest.TestCase):
    def test_trial_start_copy_exists_in_both_languages(self):
        """Trial の制限 3 点が日英両方のコピーに明示されていること。"""
        copy = read("homepage-copy.jsx")

        self.assertIn("trialStart", copy)
        # ja
        self.assertIn("Whop 登録なしですぐ試す", copy)
        self.assertIn("データは2023年12月31日まで", copy)
        self.assertIn("最適化50回", copy)
        self.assertIn("Pine Script生成なし", copy)
        # en
        self.assertIn("Try it instantly — no Whop registration", copy)
        self.assertIn("Data through Dec 31, 2023", copy)
        self.assertIn("50 optimization trials", copy)
        self.assertIn("No Pine Script export", copy)

    def test_trial_start_component_is_rendered_after_hero(self):
        """TrialStart が Hero 直後・Products より前に描画されること。

        window への登録は app.jsx が別 script から参照するための必須条件
        （未登録だと undefined 参照で LP 全体が白画面になる）。
        """
        components = read("homepage-components.jsx")
        app = read("homepage-app.jsx")

        self.assertIn("function TrialStart", components)
        self.assertIn('className="trial-start reveal"', components)
        self.assertRegex(components, r"Object\.assign\(window, \{[^}]*\bTrialStart\b")
        self.assertIn('href={`/${lang}/install.html`}', components)
        self.assertIn('href="#pricing"', components)

        hero_pos = app.index("<Hero t={t} lang={lang} />")
        trial_start_pos = app.index("<TrialStart t={t} lang={lang} />")
        products_pos = app.index("<Products t={t} />")
        self.assertLess(hero_pos, trial_start_pos)
        self.assertLess(trial_start_pos, products_pos)

    def test_generated_pages_include_trial_start_styles(self):
        """テンプレートのスタイルが build.py 生成物にも反映されていること。

        templates/index.html.j2 だけ直しても build.py 未実行だと
        公開 HTML に反映されない（過去に二度発生した崩壊パターン）。
        """
        template = read("templates/index.html.j2")
        ja_html = read("ja/index.html")
        en_html = read("en/index.html")

        self.assertIn(".trial-start", template)
        self.assertIn(".trial-start-steps", template)
        self.assertIn("trial-start", ja_html)
        self.assertIn("trial-start", en_html)


if __name__ == "__main__":
    unittest.main()

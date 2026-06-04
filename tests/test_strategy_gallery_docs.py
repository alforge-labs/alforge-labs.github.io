import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


class StrategyGalleryDocsTest(unittest.TestCase):
    def test_strategy_gallery_pages_exist_and_cover_all_examples(self):
        ja = read("mkdocs_src/ja/strategy-gallery.md")
        en = read("mkdocs_src/en/strategy-gallery.md")

        ja_examples = [
            "HMM + BB + RSI",
            "MACD + RSI",
            "トレンドフォロー",
            "平均回帰",
            "FXペア向け",
            "インデックスETF向け",
            "商品先物向け",
        ]
        en_examples = [
            "HMM + BB + RSI",
            "MACD + RSI",
            "Trend following",
            "Mean reversion",
            "FX pairs",
            "Index ETFs",
            "Commodity futures",
        ]

        for text in ja_examples:
            self.assertIn(text, ja)
        for text in en_examples:
            self.assertIn(text, en)

    def test_each_gallery_entry_has_required_sections(self):
        ja = read("mkdocs_src/ja/strategy-gallery.md")
        en = read("mkdocs_src/en/strategy-gallery.md")

        for required in [
            "目的",
            "向いている市場",
            "戦略タイプ",
            "主要指標",
            "想定シンボル",
            "JSON要点スニペット",
            "実行コマンド",
            "結果の読み方",
            "改良ポイント",
            "Pine Script生成可否",
        ]:
            self.assertGreaterEqual(ja.count(required), 7)

        for required in [
            "Purpose",
            "Suitable markets",
            "Strategy type",
            "Key indicators",
            "Example symbols",
            "JSON snippet",
            "Run commands",
            "How to read results",
            "Improvement ideas",
            "Pine Script export",
        ]:
            self.assertGreaterEqual(en.count(required), 7)

    def test_gallery_navigation_and_template_role_split_are_documented(self):
        ja = read("mkdocs_src/ja/strategy-gallery.md")
        en = read("mkdocs_src/en/strategy-gallery.md")
        mkdocs_ja = read("mkdocs.ja.yml")
        mkdocs_en = read("mkdocs.en.yml")

        self.assertIn("代表テンプレートの深い解説と全文JSON", ja)
        self.assertIn("短い実例カタログ", ja)
        self.assertIn("deep explanations and full JSON", en)
        self.assertIn("short example catalog", en)

        self.assertRegex(mkdocs_ja, r"戦略テンプレート: templates\.md\s*\n\s*- 戦略実例ギャラリー: strategy-gallery\.md")
        self.assertRegex(mkdocs_en, r"Strategy Templates: templates\.md\s*\n\s*- Strategy Gallery: strategy-gallery\.md")

    def test_cli_examples_match_reference_syntax(self):
        combined = "\n".join([
            read("mkdocs_src/ja/strategy-gallery.md"),
            read("mkdocs_src/en/strategy-gallery.md"),
        ])

        self.assertNotIn("forge strategy save <STRATEGY_ID>", combined)
        self.assertNotIn("forge backtest run --strategy", combined)
        self.assertNotIn("forge pine generate <ID>", combined)

        for pattern in [
            r"forge strategy save [^\n]+\.json",
            r"forge strategy validate [a-z0-9_]+",
            r"forge backtest run [A-Z0-9=\^]+ --strategy [a-z0-9_]+ --json",
            r"forge optimize run [A-Z0-9=\^]+ --strategy [a-z0-9_]+ --metric sharpe_ratio --save",
            r"forge pine generate --strategy [a-z0-9_]+",
        ]:
            self.assertRegex(combined, pattern)

    def test_existing_mkdocs_anchor_links_match_generated_ids(self):
        """アンカーは mkdocs が生成する ID 形式（連続ダッシュ無し）と一致すること。

        旧 cli-reference/other.md の #login-logout 検証は、コマンドカタログの
        サブコマンド別ファイル分割でページごと消滅したため削除した。
        """
        ja_templates = read("mkdocs_src/ja/templates.md")
        en_templates = read("mkdocs_src/en/templates.md")

        self.assertNotIn("#hmm--bb--rsi", ja_templates)
        self.assertNotIn("#hmm--bb--rsi", en_templates)
        self.assertIn("#hmm-bb-rsi", ja_templates)
        self.assertIn("#hmm-bb-rsi", en_templates)


if __name__ == "__main__":
    unittest.main()

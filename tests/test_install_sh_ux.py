"""install.sh の UX 改善 2 点（issue alforge-labs#377）の回帰テスト。

実物の install.sh を `--dry-run` で実行し、出力メッセージを検証する。
--dry-run はダウンロード・symlink 作成・rc 追記等の副作用を一切行わず、
何を行う予定かを `[dry-run]` 行や案内メッセージとして出力するだけなので、
インストーラ本体の破壊的副作用を走らせずにロジックを検証できる。

検証する 2 点:
1. INSTALL_DIR を明示指定した非対話インストールでは ~/.zshrc 等への
   PATH 追記をスキップし、代わりに「PATH に追加してください」案内を出す
   （CI / Dockerfile 用途で rc を書き換える副作用を防ぐ）。
   INSTALL_DIR 未指定（通常インストール）では従来どおり rc 追記を行う。
2. 完了メッセージに「認証なしの Trial プランで即利用できる」旨と
   getting-started ドキュメントへの導線を追加する。
"""

import os
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSTALL_SH = ROOT / "install.sh"

BASH = shutil.which("bash") or "/bin/bash"


def run_install_dry_run(install_dir: str | None, locale: str = "ja") -> str:
    """install.sh を --dry-run で実行し stdout+stderr を結合して返す。

    HOME を一時ディレクトリに隔離するので、テスト実行者の実 rc を
    触らない（--dry-run なので追記自体行われないが二重の安全策）。
    --dry-run のため version 取得に失敗してもインストーラは続行する
    （ネットワーク不通環境でも完走する）。
    """
    env = dict(os.environ)
    env["FORGE_INSTALL_LOCALE"] = locale
    env["HOME"] = "/tmp/forge-test-home-377"
    Path(env["HOME"]).mkdir(parents=True, exist_ok=True)
    if install_dir is None:
        env.pop("INSTALL_DIR", None)
    else:
        env["INSTALL_DIR"] = install_dir

    proc = subprocess.run(
        [BASH, str(INSTALL_SH), "--dry-run"],
        capture_output=True,
        text=True,
        env=env,
        timeout=120,
    )
    return proc.stdout + proc.stderr


class InstallShInstallDirPathBehaviorTest(unittest.TestCase):
    """課題1: INSTALL_DIR 明示時の rc 無条件追記をやめる。"""

    def test_install_dir_explicit_does_not_append_to_rc(self):
        """INSTALL_DIR 明示時は rc への PATH 追記（>> rc）を予定しない。"""
        out = run_install_dry_run(install_dir="/tmp/forge-377-bin", locale="ja")
        # 旧挙動の dry-run 行 `echo 'export PATH=...' >> .../.zshrc` が出ないこと。
        self.assertNotIn(">> ", out)
        self.assertNotIn(".zshrc", out)

    def test_install_dir_explicit_shows_manual_path_guidance(self):
        """INSTALL_DIR 明示時は「PATH に追加してください」案内を出す。"""
        out = run_install_dry_run(install_dir="/tmp/forge-377-bin", locale="en")
        self.assertIn("PATH", out)
        self.assertIn("/tmp/forge-377-bin", out)
        # 手動追加を促す文言（英語）
        self.assertIn("add", out.lower())

    def test_default_install_still_appends_to_rc(self):
        """INSTALL_DIR 未指定（通常インストール）では従来どおり rc 追記を行う。"""
        out = run_install_dry_run(install_dir=None, locale="ja")
        # 通常インストールでは rc への追記 dry-run 行が残ること（既定挙動を変えない）。
        self.assertIn(">> ", out)


class InstallShTrialGuidanceTest(unittest.TestCase):
    """課題2: 完了メッセージに Trial 即利用の案内を追加する。"""

    def test_completion_message_mentions_trial_ja(self):
        """日本語完了メッセージに Trial 即利用の案内が含まれる。"""
        out = run_install_dry_run(install_dir=None, locale="ja")
        self.assertIn("Trial", out)

    def test_completion_message_mentions_trial_en(self):
        """英語完了メッセージに Trial 即利用の案内が含まれる。"""
        out = run_install_dry_run(install_dir=None, locale="en")
        self.assertIn("Trial", out)

    def test_completion_message_links_getting_started_ja(self):
        """日本語完了メッセージに ja の getting-started 導線が含まれる。"""
        out = run_install_dry_run(install_dir=None, locale="ja")
        self.assertIn("https://alforge-labs.github.io/ja/docs/getting-started/", out)

    def test_completion_message_links_getting_started_en(self):
        """英語完了メッセージに en の getting-started 導線が含まれる。"""
        out = run_install_dry_run(install_dir=None, locale="en")
        self.assertIn("https://alforge-labs.github.io/en/docs/getting-started/", out)


if __name__ == "__main__":
    unittest.main()

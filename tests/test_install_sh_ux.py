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
import stat
import subprocess
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSTALL_SH = ROOT / "install.sh"

BASH = shutil.which("bash") or "/bin/bash"


def _make_fake_uname_dir() -> str:
    """`uname -s`→Darwin / `uname -m`→arm64 を返す偽 uname を含む dir を作る。

    install.sh は冒頭で `uname -s`（OS）と `uname -m`（アーキテクチャ）を呼び、
    Darwin 以外を「未対応プラットフォーム」として早期 fail する。CI（Linux）でも
    --dry-run の検証を走らせるため、PATH 先頭に偽 uname を差し込んで
    macOS arm64 を装う。install.sh 本体は macOS 専用で正しいので変更しない。

    呼び出しパターンは install.sh 上 `uname -s` / `uname -m` の 2 つのみ
    （`grep -n uname install.sh` で確認済み）。引数なし呼び出しは無いが、
    将来の追加に備えて引数なしは Darwin を返しておく。
    """
    fake_dir = tempfile.mkdtemp(prefix="forge-fake-uname-")
    fake_uname = Path(fake_dir) / "uname"
    fake_uname.write_text(
        "#!/bin/sh\n"
        'case "$1" in\n'
        "  -s) echo Darwin ;;\n"
        "  -m) echo arm64 ;;\n"
        "  *)  echo Darwin ;;\n"
        "esac\n"
    )
    fake_uname.chmod(fake_uname.stat().st_mode | stat.S_IEXEC | stat.S_IXGRP | stat.S_IXOTH)
    return fake_dir


def run_install_dry_run(install_dir: str | None, locale: str = "ja") -> str:
    """install.sh を --dry-run で実行し stdout+stderr を結合して返す。

    HOME を一時ディレクトリに隔離するので、テスト実行者の実 rc を
    触らない（--dry-run なので追記自体行われないが二重の安全策）。
    --dry-run のため version 取得に失敗してもインストーラは続行する
    （ネットワーク不通環境でも完走する）。

    PATH 先頭に偽 uname を差し込み、Linux CI でも macOS arm64 として
    プラットフォーム検出を通過させる（issue #377）。
    """
    env = dict(os.environ)
    env["FORGE_INSTALL_LOCALE"] = locale
    env["HOME"] = "/tmp/forge-test-home-377"
    Path(env["HOME"]).mkdir(parents=True, exist_ok=True)
    fake_uname_dir = _make_fake_uname_dir()
    env["PATH"] = fake_uname_dir + os.pathsep + env.get("PATH", "")
    if install_dir is None:
        env.pop("INSTALL_DIR", None)
    else:
        env["INSTALL_DIR"] = install_dir

    try:
        proc = subprocess.run(
            [BASH, str(INSTALL_SH), "--dry-run"],
            capture_output=True,
            text=True,
            env=env,
            timeout=120,
        )
    finally:
        shutil.rmtree(fake_uname_dir, ignore_errors=True)
    return proc.stdout + proc.stderr


class InstallShFakeUnameTest(unittest.TestCase):
    """偽 uname による PATH 偽装が効き、プラットフォーム検出を通過すること。

    install.sh は Darwin 以外で「未対応プラットフォーム」と早期 fail するため、
    この検証が通る＝偽 uname が PATH 先頭から呼ばれている証左になる
    （Linux CI 上でも他の dry-run テストが成立する前提を担保する）。
    """

    def test_fake_uname_passes_platform_detection(self):
        out = run_install_dry_run(install_dir=None, locale="ja")
        # 早期 fail のメッセージが出ていないこと（=検出を通過した）。
        self.assertNotIn("未対応プラットフォーム", out)
        # 偽 uname が返した macOS arm64 のアーティファクト名が出ること。
        self.assertIn("Darwin-arm64", out)
        self.assertIn("alpha-forge-macos-arm64", out)


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

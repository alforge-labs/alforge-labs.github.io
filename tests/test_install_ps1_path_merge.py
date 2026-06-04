"""install.ps1 の Get-MergedUserPath（User PATH マージ純粋関数）の回帰テスト。

PowerShell (pwsh) で install.ps1 から AST 抽出した「実物の」関数を実行して検証する。

背景: User PATH が 1 エントリだけのとき、Where-Object の結果がスカラー文字列に
縮退し、`$pathEntries + $INSTALL_ROOT` が配列追加ではなく文字列連結になって
セミコロン無しの壊れた PATH（例: `...\\WindowsApps<INSTALL_ROOT>`）を書き込む
バグがあった。素の Windows は User PATH が WindowsApps の 1 エントリだけの
ことが多く、初回インストールの大半が該当する。
"""

import json
import os
import shutil
import subprocess
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INSTALL_PS1 = ROOT / "install.ps1"

INSTALL_ROOT = r"C:\Users\x\AppData\Local\Programs\alpha-forge"
WINDOWS_APPS = r"C:\Users\x\AppData\Local\Microsoft\WindowsApps"
OLD_PROGRAM_DIR = r"C:\Program Files\forge"
OLD_USER_BIN_DIR = r"C:\Users\x\bin"


def _find_pwsh() -> str | None:
    """pwsh 実行ファイルを探す（env PWSH → PATH → ポータブル配置の順）。"""
    candidates = [
        os.environ.get("PWSH"),
        shutil.which("pwsh"),
        str(Path.home() / ".local/share/powershell-portable/pwsh"),
    ]
    for candidate in candidates:
        if candidate and Path(candidate).exists():
            return candidate
    return None


PWSH = _find_pwsh()


def merge_user_path(current_path: str) -> dict:
    """install.ps1 の Get-MergedUserPath を AST 抽出・実行し結果を dict で返す。

    関数定義だけを抽出して実行するため、インストーラ本体（ダウンロード等の
    副作用）は一切走らない。
    """
    script = f"""
$ast = [System.Management.Automation.Language.Parser]::ParseFile('{INSTALL_PS1}', [ref]$null, [ref]$null)
$func = $ast.Find({{ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-MergedUserPath' }}, $true)
if (-not $func) {{ Write-Error 'Get-MergedUserPath not found in install.ps1'; exit 1 }}
Invoke-Expression $func.Extent.Text
$result = Get-MergedUserPath -CurrentPath '{current_path}' -InstallRoot '{INSTALL_ROOT}' -RemoveDirs @('{OLD_PROGRAM_DIR}', '{OLD_USER_BIN_DIR}')
@{{ NewPath = $result.NewPath; Repaired = @($result.Repaired) }} | ConvertTo-Json -Compress
"""
    proc = subprocess.run(
        [PWSH, "-NoProfile", "-Command", script],
        capture_output=True,
        text=True,
        timeout=60,
    )
    if proc.returncode != 0:
        raise AssertionError(f"pwsh の実行に失敗: {proc.stderr}")
    return json.loads(proc.stdout.strip().splitlines()[-1])


@unittest.skipUnless(PWSH, "pwsh が見つからないためスキップ（env PWSH で指定可能）")
class InstallPs1PathMergeTest(unittest.TestCase):
    def test_single_entry_path_gets_semicolon_separator(self):
        """1 エントリの User PATH でもセミコロン区切りで追記される（スカラー連結バグの回帰）。"""
        result = merge_user_path(WINDOWS_APPS)
        self.assertEqual(result["NewPath"], f"{WINDOWS_APPS};{INSTALL_ROOT}")
        self.assertEqual(result["Repaired"], [])

    def test_corrupted_entry_is_repaired(self):
        """過去バグ由来の「<前エントリ><INSTALL_ROOT>」連結エントリを分割修復する。"""
        corrupted = f"{WINDOWS_APPS}{INSTALL_ROOT}"
        result = merge_user_path(corrupted)
        self.assertEqual(result["NewPath"], f"{WINDOWS_APPS};{INSTALL_ROOT}")
        self.assertEqual(result["Repaired"], [corrupted])

    def test_doubly_corrupted_entry_is_repaired(self):
        """インストーラ再実行で二重連結された壊れエントリも修復できる。"""
        corrupted = f"{WINDOWS_APPS}{INSTALL_ROOT}{INSTALL_ROOT}"
        result = merge_user_path(corrupted)
        self.assertEqual(result["NewPath"], f"{WINDOWS_APPS};{INSTALL_ROOT}")
        self.assertEqual(result["Repaired"], [corrupted])

    def test_already_registered_path_is_unchanged(self):
        """正しく登録済みの PATH は並び順も含めて変更しない。"""
        current = f"{WINDOWS_APPS};{INSTALL_ROOT};C:\\tools"
        result = merge_user_path(current)
        self.assertEqual(result["NewPath"], current)
        self.assertEqual(result["Repaired"], [])

    def test_empty_path_gets_install_root_only(self):
        """User PATH が空でも INSTALL_ROOT 単独で登録される。"""
        result = merge_user_path("")
        self.assertEqual(result["NewPath"], INSTALL_ROOT)

    def test_old_layout_entries_are_removed(self):
        """旧レイアウトのエントリ（RemoveDirs）は除去される。"""
        current = f"{OLD_PROGRAM_DIR};{WINDOWS_APPS};{OLD_USER_BIN_DIR}"
        result = merge_user_path(current)
        self.assertEqual(result["NewPath"], f"{WINDOWS_APPS};{INSTALL_ROOT}")

    def test_trailing_backslash_entry_is_not_duplicated(self):
        """末尾バックスラッシュ付きで登録済みなら追加しない（二重登録の防止）。"""
        current = f"{WINDOWS_APPS};{INSTALL_ROOT}\\"
        result = merge_user_path(current)
        self.assertEqual(result["NewPath"], current)
        self.assertEqual(result["Repaired"], [])

    def test_case_insensitive_entry_is_not_duplicated(self):
        """大文字小文字違いで登録済みなら追加しない（Windows パスはケース非区別）。"""
        current = f"{WINDOWS_APPS};{INSTALL_ROOT.upper()}"
        result = merge_user_path(current)
        self.assertEqual(result["NewPath"], current)


if __name__ == "__main__":
    unittest.main()

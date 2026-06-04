#Requires -Version 5.1
<#
.SYNOPSIS
    AlphaForge alpha-forge の Windows インストーラー / AlphaForge alpha-forge installer for Windows

.DESCRIPTION
    GitHub Releases から最新の alpha-forge-windows-x64.zip を取得し、
    %LOCALAPPDATA%\Programs\alpha-forge\forge.dist\ に同梱ファイル一式を
    展開して %LOCALAPPDATA%\Programs\alpha-forge\alpha-forge.cmd ラッパーを生成する。
    User PATH に %LOCALAPPDATA%\Programs\alpha-forge を追加する。

    -DryRun スイッチで実際の変更なしに動作を確認できる。
    -Yes スイッチで対話確認をスキップして自動進行する（CI / 再インストール用）。

    表示言語は CurrentUICulture（OS の表示言語）から自動判定する。
    環境変数 FORGE_INSTALL_LOCALE=ja|en で明示上書き可能。

.EXAMPLE
    irm https://alforge-labs.github.io/install.ps1 | iex

.EXAMPLE
    & ([scriptblock]::Create((irm https://alforge-labs.github.io/install.ps1))) -DryRun

.NOTES
    Issue alforge-labs/alforge-labs.github.io#251 で forge.dist ディレクトリ方式に移行。
    旧レイアウト ($HOME\bin\forge.exe / C:\Program Files\forge\forge.exe) は
    検出次第クリーンアップする。
#>
param(
    [switch]$DryRun,
    [switch]$Yes
)

$ErrorActionPreference = "Stop"

# ── 0. ロケール判定 ─────────────────────────────────────────────
# CurrentUICulture: OS の表示言語（Windows の表示言語設定）
# FORGE_INSTALL_LOCALE 環境変数で明示上書き可能。
$script:Locale = "en"
$uiCulture = [System.Globalization.CultureInfo]::CurrentUICulture.Name
if ($uiCulture -like "ja*") { $script:Locale = "ja" }
$envLocale = [Environment]::GetEnvironmentVariable("FORGE_INSTALL_LOCALE")
if ($envLocale -eq "ja" -or $envLocale -eq "en") { $script:Locale = $envLocale }

# L "<ja text>" "<en text>" — 現在のロケールに合う方を返す
function L([string]$ja, [string]$en) {
    if ($script:Locale -eq "ja") { return $ja } else { return $en }
}

$REPO         = "alforge-labs/alforge-labs.github.io"
$ARTIFACT     = "alpha-forge-windows-x64"
$EXT          = "zip"
$INSTALL_ROOT = Join-Path $env:LOCALAPPDATA "Programs\alpha-forge"
$DIST_DIR     = Join-Path $INSTALL_ROOT "forge.dist"
$LAUNCHER     = Join-Path $INSTALL_ROOT "alpha-forge.cmd"

# v0.5.0 で `forge.cmd` → `alpha-forge.cmd` にリネーム済み。旧 `forge.cmd` も
# マイグレーション対象として削除する。
$OLD_LAUNCHER = Join-Path $INSTALL_ROOT "forge.cmd"

# 旧レイアウト（マイグレーション対象）
$OLD_USER_BIN      = Join-Path $HOME "bin\forge.exe"
$OLD_PROGRAM_FILES = "C:\Program Files\forge\forge.exe"
$OLD_PROGRAM_DIR   = "C:\Program Files\forge"

function Write-Ok   { param($msg) Write-Host "  ✓ $msg" -ForegroundColor Green }
function Write-Info { param($msg) Write-Host "  → $msg" }
function Write-Warn { param($msg) Write-Host "  ⚠ $msg" -ForegroundColor Yellow }
function Write-Fail { param($msg) Write-Host "  ✗ $msg" -ForegroundColor Red; exit 1 }

# 長時間のスクリプトブロックを実行しながらスピナーを表示する。
# 出力がリダイレクトされている場合は静かに wait する。
# 戻り値: スクリプトブロックの出力（オブジェクト配列）
function Invoke-WithSpinner {
    param(
        [string]$Label,
        [scriptblock]$ScriptBlock
    )

    # 対話的でない（リダイレクト・CI 等）の場合はスピナーを抑止
    $isInteractive = ($Host.Name -ne $null) -and -not [Console]::IsOutputRedirected
    if (-not $isInteractive) {
        return & $ScriptBlock
    }

    $job = Start-Job -ScriptBlock $ScriptBlock
    $chars = @('|', '/', '-', '\')
    $i = 0
    try {
        while ($job.State -eq 'Running') {
            $c = $chars[$i % 4]
            Write-Host -NoNewline ("`r  $c $Label")
            $i++
            Start-Sleep -Milliseconds 100
        }
        # 行をクリアして戻す
        Write-Host -NoNewline ("`r" + (" " * ($Label.Length + 6)) + "`r")
        $result = Receive-Job -Job $job
        if ($job.State -eq 'Failed') {
            $err = $job.ChildJobs[0].JobStateInfo.Reason
            throw $err
        }
        return $result
    } finally {
        Remove-Job -Job $job -Force -ErrorAction SilentlyContinue | Out-Null
    }
}

if ($DryRun) {
    Write-Host (L "[dry-run] 実際のインストールは行いません。" "[dry-run] No actual installation will be performed.") -ForegroundColor Cyan
}

# ── 1. 最新バージョンを取得 ─────────────────────────────────────
Write-Info (L "最新バージョンを確認中..." "Fetching latest version...")
try {
    $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$REPO/releases/latest" -UseBasicParsing
    $VERSION = $release.tag_name
} catch {
    Write-Fail ((L "バージョン取得に失敗しました" "Failed to fetch version") + ": $_")
}
if (-not $VERSION) { Write-Fail (L "バージョン情報を取得できませんでした。" "Could not fetch version information.") }

Write-Ok ((L "最新バージョン" "Latest version") + ": $VERSION")

# 既存バイナリのバージョン確認（情報表示のみ）。新名 alpha-forge → 旧名 forge の順で確認。
$existingCmd = $null
if (Get-Command alpha-forge -ErrorAction SilentlyContinue) { $existingCmd = "alpha-forge" }
elseif (Get-Command forge -ErrorAction SilentlyContinue) { $existingCmd = "forge" }
if ($existingCmd) {
    try {
        $currentVer = (& $existingCmd --version 2>$null | Select-Object -First 1)
        if ($currentVer) {
            Write-Info (L "現在: $currentVer → $VERSION に更新します" "Current: $currentVer → updating to $VERSION")
        }
    } catch {
        # 旧バイナリが壊れていて起動できない場合（forge.dist 単一 .exe コピーの被害者）
        # は無視して新インストールを進める
    }
}

$DOWNLOAD_URL = "https://github.com/$REPO/releases/download/$VERSION/${ARTIFACT}.${EXT}"

# ── 2. ダウンロード & 展開 ─────────────────────────────────────
$TMP_DIR = Join-Path $env:TEMP "forge-install-$(Get-Random)"

if ($DryRun) {
    Write-Host "  [dry-run] Invoke-WebRequest $DOWNLOAD_URL → Expand-Archive → $TMP_DIR"
    Write-Host ""
    Write-Host ("  [dry-run] " + (L "インストール先:" "Install location:"))
    Write-Host "    forge.dist : $DIST_DIR"
    Write-Host ("    " + (L "ラッパー   " "wrapper    ") + ": $LAUNCHER")
    Write-Host ""
    Write-Host ("  [dry-run] " + (L "旧レイアウト検出: 実行時に $OLD_USER_BIN / $OLD_PROGRAM_FILES を探索" "Old layout detection: searches $OLD_USER_BIN / $OLD_PROGRAM_FILES at runtime"))
    Write-Host ("  [dry-run] " + (L "User PATH に $INSTALL_ROOT を追加（重複時はスキップ）" "Add $INSTALL_ROOT to User PATH (skipped if duplicate)"))
    Write-Host ""
    Write-Ok (L "ドライランが完了しました。実際にインストールするには -DryRun を外して再実行してください。" "Dry run complete. Re-run without -DryRun to actually install.")
    return
}

New-Item -ItemType Directory -Path $TMP_DIR | Out-Null
try {
    $TMP_ZIP = Join-Path $TMP_DIR "${ARTIFACT}.${EXT}"
    try {
        Write-Info ((L "ダウンロード中" "Downloading") + ": $DOWNLOAD_URL")
        Invoke-WebRequest -Uri $DOWNLOAD_URL -OutFile $TMP_ZIP -UseBasicParsing
    } catch {
        Write-Fail ((L "ダウンロードに失敗しました" "Download failed") + ": $_`n  $DOWNLOAD_URL")
    }

    # SHA256 整合性検証: Release 添付の <artifact>.zip.sha256 と照合する。
    # 不一致は改ざん/破損として中断。.sha256 取得失敗は警告のうえ継続する
    # （配信経路は HTTPS/TLS で保護済みのため、チェックサムは破損・取り違え検知の defense-in-depth）。
    try {
        $SHA_URL = "$DOWNLOAD_URL.sha256"
        $shaTmp  = Join-Path $TMP_DIR "${ARTIFACT}.${EXT}.sha256"
        Invoke-WebRequest -Uri $SHA_URL -OutFile $shaTmp -UseBasicParsing
        $expected = ((Get-Content $shaTmp -Raw) -split '\s+' | Where-Object { $_ })[0]
        if ($expected) { $expected = $expected.Trim().ToLower() }
        $actual = (Get-FileHash -Algorithm SHA256 -Path $TMP_ZIP).Hash.ToLower()
        if (-not $expected) {
            Write-Warn (L "SHA256 チェックサムが空のため検証をスキップしました" "SHA256 checksum file was empty; skipping verification")
        } elseif ($actual -eq $expected) {
            Write-Ok (L "SHA256 整合性を検証しました" "Verified SHA256 checksum")
        } else {
            Write-Fail ((L "SHA256 が一致しません（改ざん/破損の可能性があります）" "SHA256 checksum mismatch (possible tampering/corruption)") + "`n  expected: $expected`n  actual:   $actual")
        }
    } catch {
        Write-Warn ((L "SHA256 チェックサムを取得できず検証をスキップしました" "Could not fetch SHA256 checksum; skipping verification") + ": $_")
    }

    try {
        Expand-Archive -Path $TMP_ZIP -DestinationPath $TMP_DIR -Force
    } catch {
        # .NET フォールバック
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::ExtractToDirectory($TMP_ZIP, $TMP_DIR)
    }

    $SRC_DIST = Join-Path $TMP_DIR "forge.dist"
    $SRC_EXE  = Join-Path $SRC_DIST "forge.exe"
    if (-not (Test-Path $SRC_DIST -PathType Container)) {
        Write-Fail ((L "展開後に forge.dist ディレクトリが見つかりません" "forge.dist directory not found after extraction") + " ($SRC_DIST)")
    }
    if (-not (Test-Path $SRC_EXE -PathType Leaf)) {
        Write-Fail (L "展開後に forge.dist\forge.exe が見つかりません" "forge.dist\forge.exe not found after extraction")
    }
    Write-Ok (L "ダウンロード・展開完了" "Download and extraction complete")

    # ── 3. 既存インストール検出 & クリーンアップ ─────────────────────
    $hasNewLayout = Test-Path $DIST_DIR -PathType Container
    $hasOldUserBin = Test-Path $OLD_USER_BIN -PathType Leaf
    $hasOldProgramFiles = Test-Path $OLD_PROGRAM_FILES -PathType Leaf

    if ($hasNewLayout) {
        Write-Info ((L "既存インストール検出" "Existing install detected") + ": $DIST_DIR " + (L "（上書き更新します）" "(will be overwritten)"))
    }

    if ($hasOldUserBin -or $hasOldProgramFiles) {
        Write-Warn (L "旧レイアウトを検出しました。新レイアウトへ移行します:" "Old layout detected. Migrating to new layout:")
        if ($hasOldUserBin)      { Write-Host "    - $OLD_USER_BIN" }
        if ($hasOldProgramFiles) { Write-Host "    - $OLD_PROGRAM_FILES" }
        Write-Host ""
        $migratePrompt = L "  旧インストールを削除して新レイアウトへ移行しますか? [Y/n]" "  Remove old install and migrate to the new layout? [Y/n]"
        $migrate = if ($Yes) { "y" } else { Read-Host $migratePrompt }
        if ($migrate -match "^[Nn]") {
            Write-Fail (L "ユーザーがマイグレーションを拒否したためインストールを中止します。" "User declined migration; install aborted.")
        }

        if ($hasOldUserBin) {
            try {
                Remove-Item -Path $OLD_USER_BIN -Force
                Write-Ok ((L "削除" "Removed") + ": $OLD_USER_BIN")
                # 親 dir が空なら削除（他用途と混在の可能性があるので空のときだけ）
                $oldUserDir = Split-Path -Parent $OLD_USER_BIN
                if ((Test-Path $oldUserDir) -and -not (Get-ChildItem -Path $oldUserDir -Force | Select-Object -First 1)) {
                    Remove-Item -Path $oldUserDir -Force
                    Write-Ok ((L "空ディレクトリを削除" "Removed empty directory") + ": $oldUserDir")
                }
            } catch {
                Write-Warn ((L "旧 $OLD_USER_BIN の削除に失敗しました" "Failed to remove old $OLD_USER_BIN") + ": $_")
            }
        }

        if ($hasOldProgramFiles) {
            $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
                [Security.Principal.WindowsBuiltInRole]::Administrator
            )
            if (-not $isAdmin) {
                Write-Warn (L "$OLD_PROGRAM_FILES の削除には管理者権限が必要です。新レイアウトのインストール自体は続行しますが、PowerShell を管理者として起動して以下を手動実行してください:" "Removing $OLD_PROGRAM_FILES requires administrator rights. New install will continue; please run the following manually in an elevated PowerShell:")
                Write-Host "    Remove-Item -Recurse -Force '$OLD_PROGRAM_DIR'"
            } else {
                try {
                    Remove-Item -Path $OLD_PROGRAM_DIR -Recurse -Force
                    Write-Ok ((L "削除" "Removed") + ": $OLD_PROGRAM_DIR")
                } catch {
                    Write-Warn ((L "$OLD_PROGRAM_DIR の削除に失敗しました" "Failed to remove $OLD_PROGRAM_DIR") + ": $_")
                }
            }
        }
    }

    # ── 4. 新レイアウトをアトミックに配置 ─────────────────────────
    if (-not (Test-Path $INSTALL_ROOT)) {
        New-Item -ItemType Directory -Path $INSTALL_ROOT -Force | Out-Null
        Write-Ok ((L "ディレクトリ作成" "Created directory") + ": $INSTALL_ROOT")
    }

    $TIMESTAMP = [int][double]::Parse((Get-Date -UFormat %s))
    $BACKUP_DIR = Join-Path $INSTALL_ROOT "forge.dist.bak-$TIMESTAMP"
    $STAGED_DIR = Join-Path $INSTALL_ROOT "forge.dist.new"

    # staging: 新 forge.dist を兄弟に置く（同一 FS のため rename がアトミック）
    if (Test-Path $STAGED_DIR) { Remove-Item -Recurse -Force $STAGED_DIR }
    try {
        # Move-Item は同一ボリュームではアトミック rename
        Move-Item -Path $SRC_DIST -Destination $STAGED_DIR
    } catch {
        # 異なるボリュームの場合は Copy-Item へフォールバック
        Copy-Item -Path $SRC_DIST -Destination $STAGED_DIR -Recurse -Force
    }

    if ($hasNewLayout) {
        Move-Item -Path $DIST_DIR -Destination $BACKUP_DIR
    }
    try {
        Move-Item -Path $STAGED_DIR -Destination $DIST_DIR
    } catch {
        # 復旧: バックアップを元に戻す
        if (Test-Path $BACKUP_DIR) { Move-Item -Path $BACKUP_DIR -Destination $DIST_DIR -Force }
        throw
    }

    # 旧バックアップは新レイアウト配置成功後に削除（最新世代のみ保持）
    if ($hasNewLayout -and (Test-Path $BACKUP_DIR)) {
        Remove-Item -Recurse -Force $BACKUP_DIR -ErrorAction SilentlyContinue
    }

    # alpha-forge.cmd ラッパーを生成（ASCII、改行は CRLF）
    $LAUNCHER_BODY = @"
@echo off
"%~dp0forge.dist\forge.exe" %*
"@
    Set-Content -Path $LAUNCHER -Value $LAUNCHER_BODY -Encoding ASCII
    Write-Ok (L "forge.dist を $DIST_DIR に配置しました" "Placed forge.dist at $DIST_DIR")
    Write-Ok (L "ラッパーを $LAUNCHER に生成しました" "Generated launcher at $LAUNCHER")

    # 旧 forge.cmd ラッパー（v0.4.x 以下）が残っていれば削除して
    # alpha-forge.cmd に統一する
    if (Test-Path $OLD_LAUNCHER) {
        Write-Info (L "旧 forge.cmd ラッパー ($OLD_LAUNCHER) を削除します（v0.5.0 リネーム）" `
                       "Removing legacy forge.cmd launcher ($OLD_LAUNCHER) (renamed in v0.5.0)")
        Remove-Item -Path $OLD_LAUNCHER -Force -ErrorAction SilentlyContinue
    }

    # ── 5. PATH 自動登録 ─────────────────────────────────────────────
    $currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")
    $pathEntries = if ($currentPath) { $currentPath -split ";" } else { @() }
    # 旧エントリを除去
    $pathEntries = $pathEntries | Where-Object {
        $_ -ne "" -and
        $_ -ne $OLD_PROGRAM_DIR -and
        $_ -ne (Split-Path -Parent $OLD_USER_BIN)
    }
    # 新エントリが含まれなければ追加
    if ($pathEntries -notcontains $INSTALL_ROOT) {
        $pathEntries = $pathEntries + $INSTALL_ROOT
    }
    $newPath = ($pathEntries -join ";")

    if ($newPath.Length -gt 2048) {
        Write-Warn (L "User PATH が 2048 文字を超えています。手動で追加してください:" "User PATH exceeds 2048 chars; please add it manually:")
        Write-Host "    [Environment]::SetEnvironmentVariable('PATH', `$env:PATH + ';$INSTALL_ROOT', 'User')"
    } else {
        if ($newPath -ne $currentPath) {
            [Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
            Write-Ok (L "User PATH を更新しました（次回ターミナル起動から有効）" "Updated User PATH (effective in new terminals)")
        } else {
            Write-Ok (L "User PATH はすでに最新です" "User PATH is already up to date")
        }
        # 現セッション PATH にも反映（インストール直後の動作確認のため）
        if ($env:PATH -notlike "*$INSTALL_ROOT*") {
            $env:PATH = "$env:PATH;$INSTALL_ROOT"
        }
    }

    # ── 6. 動作確認 ─────────────────────────────────────────────────
    # Nuitka standalone のコールドスタートは遅いので、スピナーで進行を伝える。
    # Start-Job は別プロセスなので $LASTEXITCODE が親に戻らない。
    # ScriptBlock で {Output, ExitCode} を返してから親で判定する。
    Write-Host ""
    try {
        $verifyLabel = L "動作確認中（alpha-forge コマンドの初回起動には時間がかかります）..." "Verifying installation (first alpha-forge launch may take a while)..."
        $launcherPath = $LAUNCHER
        $verifyResult = Invoke-WithSpinner -Label $verifyLabel -ScriptBlock {
            $out = & $using:launcherPath --version 2>&1
            [PSCustomObject]@{ Output = $out; ExitCode = $LASTEXITCODE }
        }
        if ($verifyResult -and $verifyResult.ExitCode -eq 0) {
            $firstLine = $verifyResult.Output | Select-Object -First 1
            Write-Ok ((L "インストール完了！" "Installation complete!") + " ($firstLine)")
        } else {
            $code = if ($verifyResult) { $verifyResult.ExitCode } else { "n/a" }
            Write-Warn ((L "alpha-forge の起動確認に失敗しました（exit code" "alpha-forge launch verification failed (exit code") + ": $code).")
            Write-Host ("    " + (L "手動確認" "Try manually") + ": $LAUNCHER --version")
        }
    } catch {
        Write-Warn ((L "alpha-forge コマンドの動作確認に失敗しました" "Failed to verify alpha-forge command") + ": $_")
        Write-Host ("    " + (L "新しいターミナルを開いて再試行してください" "Open a new terminal and retry") + ": alpha-forge --version")
    }

    # ── 7. 認証案内 ─────────────────────────────────────────────────
    Write-Host ""
    Write-Host (L "次のステップ: ライセンス認証" "Next step: license activation")
    Write-Host (L "  AlphaForge は Whop OAuth でライセンス認証を行います。" "  AlphaForge uses Whop OAuth for license activation.")
    Write-Host (L "  新しいターミナルを開いて以下を実行してください:" "  Open a new terminal and run the following:")
    Write-Host ""
    Write-Host "      alpha-forge system auth login" -ForegroundColor Cyan
    Write-Host ""
    Write-Host ("  " + (L "認証状態の確認" "Check authentication status") + ":")
    Write-Host "      alpha-forge system auth status"
    Write-Host ""
    Write-Host ((L "使い方" "Usage") + ": alpha-forge --help")

} finally {
    if (Test-Path $TMP_DIR) { Remove-Item -Recurse -Force $TMP_DIR -ErrorAction SilentlyContinue }
}

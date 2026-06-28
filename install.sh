#!/usr/bin/env bash
# AlphaForge インストーラー / AlphaForge installer
# Usage:
#   bash <(curl -sSL https://alforge-labs.github.io/install.sh)
#   bash <(curl -sSL https://alforge-labs.github.io/install.sh) --dry-run
#
#   # 非対話で symlink 配置先を環境変数で指定（CI / Dockerfile 等向け）
#   # INSTALL_DIR 指定時は ~/.zshrc 等への PATH 追記をスキップし手動追加を案内する。
#   INSTALL_DIR=~/.local/bin bash <(curl -sSL https://alforge-labs.github.io/install.sh)
#   INSTALL_DIR=/opt/forge/bin bash <(curl -sSL https://alforge-labs.github.io/install.sh)
#
#   # 表示言語を明示指定（自動判定をオーバーライド）
#   FORGE_INSTALL_LOCALE=en bash <(curl -sSL https://alforge-labs.github.io/install.sh)
#
# 実装メモ:
#   - Nuitka standalone ビルドの forge.dist/ は forge バイナリ + 1100+ の dylib /
#     データファイルから成り、forge は @executable_path 相対で同居 dylib を
#     ロードする。よってバイナリ単体ではなく forge.dist/ ディレクトリ全体を
#     インストール先に置き、forge を symlink で PATH に通すレイアウトを取る。
#   - macOS Gatekeeper は curl 経由 DL に com.apple.quarantine xattr を付ける
#     ので、未署名バイナリの抑止解除のため xattr -dr で除去する。
#   - curl | bash 経由実行では stdin がスクリプト本文に占有されているため、
#     対話 read は </dev/tty で TTY 直結する。
#   - INSTALL_DIR 環境変数が設定されていれば対話プロンプトを完全にスキップして
#     その値を symlink 配置ディレクトリとして使う。同名で uninstall.sh も
#     対応している。
#   - bash 3.2（macOS デフォルト）互換のため、連想配列は使わず lang() ヘルパで
#     日英 2 言語を切り替える。

set -euo pipefail

# ── 0. ロケール判定（lang ヘルパ用）─────────────────────────────────
# LANG / LC_ALL / LC_MESSAGES が ja* なら日本語、それ以外（en* や未設定含む）は英語。
# FORGE_INSTALL_LOCALE=ja|en で明示上書き可能（CI などで強制したい場合）。
FORGE_LOCALE="en"
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
  ja|ja_*|ja.*) FORGE_LOCALE="ja" ;;
esac
case "${FORGE_INSTALL_LOCALE:-}" in
  ja|en) FORGE_LOCALE="${FORGE_INSTALL_LOCALE}" ;;
esac

# lang "<ja text>" "<en text>"
# - 2 つの引数のうち現在のロケールに合うほうを stdout に出す（改行なし）。
# - メッセージを使用箇所のすぐ近くに置けるので保守しやすい。
lang() {
  if [ "${FORGE_LOCALE}" = "ja" ]; then
    printf '%s' "$1"
  else
    printf '%s' "$2"
  fi
}

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=true
  echo "$(lang '[dry-run] 実際のインストールは行いません。' '[dry-run] No actual installation will be performed.')"
fi

# ── 色とアイコン定義（issue alforge-labs#264 / alpha-forge#711）─────
# 表示モードの自動判定:
#   - NO_COLOR=1 (https://no-color.org/) または非 TTY → 色なし
#   - FORCE_COLOR=1 → 非 TTY でも色を有効化（CI ログ保持用）
#   - TERM=dumb → 完全平文
#   - LC_ALL / LANG が UTF-8 を含まない → Braille / アイコンを ASCII にフォールバック
_COLOR_ENABLED=true
if [ -n "${NO_COLOR:-}" ]; then
  _COLOR_ENABLED=false
elif [ "${FORCE_COLOR:-}" = "1" ]; then
  _COLOR_ENABLED=true
elif [ ! -t 1 ]; then
  _COLOR_ENABLED=false
fi
if [ "${TERM:-}" = "dumb" ]; then
  _COLOR_ENABLED=false
fi
case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
  *UTF-8*|*utf-8*|*utf8*) _UNICODE_ENABLED=true ;;
  *)                       _UNICODE_ENABLED=false ;;
esac
# TERM=dumb は Unicode 描画も無効化する（古い端末互換）
if [ "${TERM:-}" = "dumb" ]; then
  _UNICODE_ENABLED=false
fi

if [ "${_COLOR_ENABLED}" = "true" ]; then
  _C_RESET=$'\033[0m'
  _C_CYAN=$'\033[36m'
  _C_GREEN=$'\033[32m'
  _C_RED=$'\033[31m'
  _C_YELLOW=$'\033[33m'
  _C_DIM=$'\033[2m'
  _C_BOLD=$'\033[1m'
else
  _C_RESET=""; _C_CYAN=""; _C_GREEN=""; _C_RED=""; _C_YELLOW=""; _C_DIM=""; _C_BOLD=""
fi

if [ "${_UNICODE_ENABLED}" = "true" ]; then
  # Braille dots 10 フレーム。ora / cargo / rich のデファクト。
  _SPINNER_FRAMES=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
  _ICON_INFO="→"; _ICON_OK="✓"; _ICON_FAIL="✗"; _ICON_WARN="⚠"
else
  _SPINNER_FRAMES=('|' '/' '-' '\')
  _ICON_INFO=">"; _ICON_OK="*"; _ICON_FAIL="x"; _ICON_WARN="!"
fi

REPO="alforge-labs/alforge-labs.github.io"

# bin: 実行ファイル symlink を置く場所 (PATH に通っているべき)。symlink 名は
# v0.5.0 で `forge` → `alpha-forge` にリネーム（製品ファミリーで `alpha-` 統一）。
# INSTALL_DIR 環境変数が事前に export されていればそれを最優先で使用する。
# 未設定なら対話プロンプト（または DRY_RUN）でデフォルト ~/.local/bin に決定。
DEFAULT_BIN_DIR="${HOME}/.local/bin"
INSTALL_DIR_FROM_ENV="${INSTALL_DIR:-}"
BIN_DIR=""

# lib: forge.dist/ 配下の全ファイルを置く場所 (バイナリ + dylib + データ)
# share/alpha-forge/ 配下に「forge.dist」名で展開し、alpha-forge -> forge.dist/forge の symlink を貼る
DIST_NAME="forge.dist"

ok()   { printf "  %s%s%s%s %s\n" "${_C_GREEN}" "${_C_BOLD}" "${_ICON_OK}" "${_C_RESET}" "$*"; }
info() { printf "  %s%s%s%s %s\n" "${_C_CYAN}" "${_C_DIM}" "${_ICON_INFO}" "${_C_RESET}" "$*"; }
warn() { printf "  %s%s%s%s %b\n" "${_C_YELLOW}" "${_C_BOLD}" "${_ICON_WARN}" "${_C_RESET}" "$*" >&2; }
fail() { printf "  %s%s%s%s %b\n" "${_C_RED}" "${_C_BOLD}" "${_ICON_FAIL}" "${_C_RESET}" "$*" >&2; exit 1; }

# curl | bash の stdin はスクリプト本文に占有されているため、対話読みは TTY 直結。
# TTY が無い (CI 等) なら空文字を返してデフォルトにフォールバック。
prompt_tty() {
  local prompt_msg=$1
  local reply=""
  # /dev/tty が無い・読めない環境（CI, --no-tty 等）では即フォールバック。
  # bash のリダイレクト失敗は read 単体への 2>/dev/null では捕まらないため、
  # ブロック全体を { ... } 2>/dev/null で囲む。
  # shellcheck disable=SC2229
  { read -r -p "${prompt_msg}" reply </dev/tty; } 2>/dev/null || reply=""
  printf '%s' "${reply}"
}

# 長時間のコマンドを実行しながらスピナーを表示する。
#   spin_run "<label>" <command...>
# - stdout が TTY の場合のみスピナーを描画。非 TTY（CI のログ）では単に wait する。
# - 終了コードはコマンドのそれを返す（呼び出し側で || fail を続けられる）。
# - macOS BSD sleep は小数秒を受け付けるので 0.1s 刻みで回す。
spin_run() {
  local label=$1; shift
  # 非 TTY / sleep が無い極小環境ではスピナーを描画せず単に wait する
  if [ ! -t 1 ] || ! command -v sleep >/dev/null 2>&1; then
    "$@"
    return $?
  fi

  "$@" &
  local pid=$!
  local i=0
  local n=${#_SPINNER_FRAMES[@]}
  # cursor を隠して描画。途中で SIGINT が来てもクリーンアップする
  printf '\033[?25l'
  trap 'printf "\033[?25h"' EXIT
  while kill -0 "${pid}" 2>/dev/null; do
    local ch="${_SPINNER_FRAMES[$(( i % n ))]}"
    printf "\r  %s%s%s %s" "${_C_CYAN}" "${ch}" "${_C_RESET}" "${label}"
    i=$(( i + 1 ))
    sleep 0.08
  done
  # 行をクリア（CSI 2K = カーソル位置の行を全消去）してカーソル表示を戻す
  printf "\r\033[2K"
  printf '\033[?25h'
  trap - EXIT
  wait "${pid}"
  return $?
}

# ── 1. OS + アーキテクチャ検出 ──────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"

case "${OS}-${ARCH}" in
  Darwin-arm64)  ARTIFACT="alpha-forge-macos-arm64"; EXT="tar.gz" ;;
  Darwin-x86_64) ARTIFACT="alpha-forge-macos-x64";   EXT="tar.gz" ;;
  *) fail "$(lang "未対応プラットフォーム: ${OS}-${ARCH}。対応: macOS arm64, macOS x86_64" \
                  "Unsupported platform: ${OS}-${ARCH}. Supported: macOS arm64, macOS x86_64")" ;;
esac

info "$(lang "プラットフォーム" "Platform"): ${OS}-${ARCH} → ${ARTIFACT}"

# ── 2. 最新バージョンを取得 ─────────────────────────────────────
info "$(lang "最新バージョンを確認中..." "Fetching latest version...")"
if ! command -v curl >/dev/null 2>&1; then
  fail "$(lang "curl がインストールされていません。インストール後に再実行してください。" \
                "curl is not installed. Please install curl and re-run.")"
fi

VERSION="$(curl -sSfL "https://api.github.com/repos/${REPO}/releases/latest" \
  2>/dev/null | grep '"tag_name"' | sed 's/.*"tag_name": *"\([^"]*\)".*/\1/')" || true

if [ -z "${VERSION}" ]; then
  if [ "${DRY_RUN}" = "true" ]; then
    VERSION="$(lang "vX.Y.Z（dry-run: バージョン未取得）" "vX.Y.Z (dry-run: version not fetched)")"
    info "$(lang "バージョン取得できませんでした（dry-run のため続行）" \
                  "Could not fetch version (continuing because of dry-run)")"
  else
    fail "$(lang "バージョン取得に失敗しました。ネットワーク接続を確認してください。\n  https://github.com/${REPO}/releases" \
                  "Failed to fetch version. Check your network connection.\n  https://github.com/${REPO}/releases")"
  fi
fi

ok "$(lang "最新バージョン" "Latest version"): ${VERSION}"

DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ARTIFACT}.${EXT}"

# 既存バイナリのバージョン確認
if command -v forge >/dev/null 2>&1; then
  CURRENT_VER="$(forge --version 2>/dev/null | head -1)" || CURRENT_VER=""
  if [ -n "${CURRENT_VER}" ]; then
    info "$(lang "現在のバージョン: ${CURRENT_VER} → ${VERSION} に更新します" \
                  "Current version: ${CURRENT_VER} → updating to ${VERSION}")"
  fi
fi

# ── 3. ダウンロード & 展開 ─────────────────────────────────────
TMP_DIR="$(mktemp -d /tmp/forge-install.XXXXXX)"
trap 'rm -rf "${TMP_DIR}"' EXIT

if [ "${DRY_RUN}" = "false" ]; then
  info "$(lang "ダウンロード中" "Downloading"): ${DOWNLOAD_URL}"
  curl -sSfL "${DOWNLOAD_URL}" -o "${TMP_DIR}/archive.${EXT}" \
    || fail "$(lang "ダウンロードに失敗しました。\n  ${DOWNLOAD_URL}" \
                     "Download failed.\n  ${DOWNLOAD_URL}")"

  # SHA256 整合性検証: Release 添付の <artifact>.<ext>.sha256 と照合する。
  # 不一致は改ざん/破損として中断。.sha256 取得失敗や検証ツール不在は警告のうえ継続
  # （配信経路は HTTPS/TLS で保護済みのため、チェックサムは破損・取り違え検知の defense-in-depth）。
  if curl -sSfL "${DOWNLOAD_URL}.sha256" -o "${TMP_DIR}/archive.${EXT}.sha256" 2>/dev/null; then
    EXPECTED_SHA="$(awk '{print $1}' "${TMP_DIR}/archive.${EXT}.sha256" | head -1 | tr 'A-Z' 'a-z')"
    if command -v sha256sum >/dev/null 2>&1; then
      ACTUAL_SHA="$(sha256sum "${TMP_DIR}/archive.${EXT}" | awk '{print $1}')"
    elif command -v shasum >/dev/null 2>&1; then
      ACTUAL_SHA="$(shasum -a 256 "${TMP_DIR}/archive.${EXT}" | awk '{print $1}')"
    else
      ACTUAL_SHA=""
    fi
    ACTUAL_SHA="$(printf '%s' "${ACTUAL_SHA}" | tr 'A-Z' 'a-z')"
    if [ -z "${ACTUAL_SHA}" ]; then
      warn "$(lang "sha256sum / shasum が見つからず SHA256 検証をスキップしました" \
                    "Neither sha256sum nor shasum found; skipping SHA256 verification")"
    elif [ -z "${EXPECTED_SHA}" ]; then
      warn "$(lang "SHA256 チェックサムが空のため検証をスキップしました" \
                    "SHA256 checksum file was empty; skipping verification")"
    elif [ "${ACTUAL_SHA}" = "${EXPECTED_SHA}" ]; then
      ok "$(lang "SHA256 整合性を検証しました" "Verified SHA256 checksum")"
    else
      fail "$(lang "SHA256 が一致しません（改ざん/破損の可能性があります）\n  expected: ${EXPECTED_SHA}\n  actual:   ${ACTUAL_SHA}" \
                   "SHA256 checksum mismatch (possible tampering/corruption)\n  expected: ${EXPECTED_SHA}\n  actual:   ${ACTUAL_SHA}")"
    fi
  else
    warn "$(lang "SHA256 チェックサムを取得できず検証をスキップしました" \
                  "Could not fetch SHA256 checksum; skipping verification")"
  fi

  tar xzf "${TMP_DIR}/archive.${EXT}" -C "${TMP_DIR}"
  if [ ! -d "${TMP_DIR}/forge.dist" ]; then
    fail "$(lang "展開後に forge.dist ディレクトリが見つかりません" \
                  "forge.dist directory not found after extraction")"
  fi
  if [ ! -x "${TMP_DIR}/forge.dist/forge" ]; then
    fail "$(lang "展開後に forge.dist/forge が実行可能ファイルでありません" \
                  "forge.dist/forge is not executable after extraction")"
  fi
  ok "$(lang "ダウンロード・展開完了" "Download and extraction complete")"
else
  echo "  [dry-run] curl -L ${DOWNLOAD_URL} → tar xzf → ${TMP_DIR}/forge.dist/"
fi

# ── 4. macOS Gatekeeper の quarantine 属性を除去 ─────────────────
# curl 経由でダウンロードしたバイナリには com.apple.quarantine xattr が付き、
# 未署名のため起動時 Abort trap: 6 で必ず死ぬ。展開直後に除去しておく。
if [ "${DRY_RUN}" = "false" ] && [ "${OS}" = "Darwin" ]; then
  if command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "${TMP_DIR}/forge.dist" 2>/dev/null || true
    ok "$(lang "macOS quarantine 属性を除去しました" "Removed macOS quarantine attribute")"
  fi
fi

# ── 5. インストール先を確定 ──────────────────────────────────────
echo ""
if [ -n "${INSTALL_DIR_FROM_ENV}" ]; then
  # 環境変数で明示指定された場合は対話プロンプトを完全にスキップ。
  # ~ を含む場合は呼び出し側 shell で展開されないので tilde を $HOME に置換しておく。
  case "${INSTALL_DIR_FROM_ENV}" in
    "~"|"~/"*) BIN_DIR="${HOME}${INSTALL_DIR_FROM_ENV#"~"}" ;;
    *)         BIN_DIR="${INSTALL_DIR_FROM_ENV}" ;;
  esac
  echo "$(lang "INSTALL_DIR 環境変数が指定されています" "INSTALL_DIR environment variable is set"): ${BIN_DIR}"
  ok "$(lang "インストール先" "Install location"): ${BIN_DIR}"
elif [ "${DRY_RUN}" = "true" ]; then
  BIN_DIR="${DEFAULT_BIN_DIR}"
  echo "  [dry-run] $(lang "インストール先" "Install location"): ${BIN_DIR}$(lang "（デフォルト: ユーザー領域）" " (default: user-local)")"
else
  # ユーザーに分かりやすい二択プロンプト：
  # - Enter で ユーザー領域 ~/.local/bin（推奨）
  # - y で システム共通 /usr/local/bin（sudo 必要）
  echo "$(lang "インストール先" "Install location"):"
  echo "  $(lang "デフォルトは ${DEFAULT_BIN_DIR}（ユーザー領域・sudo 不要）です。" \
                  "Default: ${DEFAULT_BIN_DIR} (user-local, no sudo required).")"
  REPLY="$(prompt_tty "  $(lang "システム共通の /usr/local/bin にインストールしますか？（sudo が必要） [y/N]: " \
                                  "Install to system-wide /usr/local/bin instead? (requires sudo) [y/N]: ")")"
  if [[ "${REPLY}" =~ ^[Yy]$ ]]; then
    BIN_DIR="/usr/local/bin"
  else
    BIN_DIR="${DEFAULT_BIN_DIR}"
  fi
  ok "$(lang "インストール先" "Install location"): ${BIN_DIR}"
fi

# forge.dist の同居先（bin と同階層）。ここに 1100+ ファイル一式を展開する。
DIST_DIR="$(dirname "${BIN_DIR}")/share/alpha-forge/${DIST_NAME}"
SYMLINK_PATH="${BIN_DIR}/alpha-forge"
# 旧 v0.4.x 以下で配置されていた `forge` symlink。v0.5.0 リネームに伴いインストール完了後に
# 削除する（同じ実体を指すので置き換える形）。
LEGACY_SYMLINK_PATH="${BIN_DIR}/forge"

# ── 6. インストール ──────────────────────────────────────────────
if [ "${DRY_RUN}" = "false" ]; then
  info "$(lang "forge.dist 全体を ${DIST_DIR} に展開します" \
                "Deploying forge.dist to ${DIST_DIR}")"
  if ! mkdir -p "${BIN_DIR}" 2>/dev/null; then
    info "$(lang "sudo で ${BIN_DIR} を作成します..." \
                  "Creating ${BIN_DIR} with sudo...")"
    sudo mkdir -p "${BIN_DIR}"
  fi
  if ! mkdir -p "$(dirname "${DIST_DIR}")" 2>/dev/null; then
    info "$(lang "sudo で $(dirname "${DIST_DIR}") を作成します..." \
                  "Creating $(dirname "${DIST_DIR}") with sudo...")"
    sudo mkdir -p "$(dirname "${DIST_DIR}")"
  fi

  # 既存 install があれば一旦退避してアトミックに置換（途中失敗時の救済余地）
  if [ -d "${DIST_DIR}" ]; then
    BACKUP="${DIST_DIR}.bak.$$"
    info "$(lang "既存インストール (${DIST_DIR}) を ${BACKUP} に退避" \
                  "Backing up existing install (${DIST_DIR}) to ${BACKUP}")"
    if [ -w "$(dirname "${DIST_DIR}")" ]; then
      mv "${DIST_DIR}" "${BACKUP}"
    else
      sudo mv "${DIST_DIR}" "${BACKUP}"
    fi
  fi

  # cp -R の方が dotfiles を含めて素直にコピーできる
  if [ -w "$(dirname "${DIST_DIR}")" ]; then
    cp -R "${TMP_DIR}/forge.dist" "${DIST_DIR}"
  else
    info "$(lang "sudo でコピーします..." "Copying with sudo...")"
    sudo cp -R "${TMP_DIR}/forge.dist" "${DIST_DIR}"
  fi

  # quarantine 属性が再付与されることがあるので念のためインストール先でも除去
  if [ "${OS}" = "Darwin" ] && command -v xattr >/dev/null 2>&1; then
    xattr -dr com.apple.quarantine "${DIST_DIR}" 2>/dev/null \
      || sudo xattr -dr com.apple.quarantine "${DIST_DIR}" 2>/dev/null \
      || true
  fi

  # symlink を BIN_DIR/alpha-forge に貼る（既存ファイル・symlink は ln -sfn で上書き）
  if [ -w "${BIN_DIR}" ]; then
    ln -sfn "${DIST_DIR}/forge" "${SYMLINK_PATH}"
  else
    info "$(lang "sudo で symlink を貼ります..." "Creating symlink with sudo...")"
    sudo ln -sfn "${DIST_DIR}/forge" "${SYMLINK_PATH}"
  fi

  # 旧 `forge` symlink（v0.4.x 以下）が残っていれば削除して新 `alpha-forge` に統一する
  if [ -L "${LEGACY_SYMLINK_PATH}" ] || [ -e "${LEGACY_SYMLINK_PATH}" ]; then
    info "$(lang "旧 'forge' symlink (${LEGACY_SYMLINK_PATH}) を削除します（v0.5.0 リネーム）" \
                  "Removing legacy 'forge' symlink (${LEGACY_SYMLINK_PATH}) (renamed in v0.5.0)")"
    if [ -w "${BIN_DIR}" ]; then
      rm -f "${LEGACY_SYMLINK_PATH}"
    else
      sudo rm -f "${LEGACY_SYMLINK_PATH}"
    fi
  fi

  ok "$(lang "alpha-forge を ${SYMLINK_PATH} に配置しました (実体: ${DIST_DIR}/forge)" \
              "Placed alpha-forge at ${SYMLINK_PATH} (target: ${DIST_DIR}/forge)")"

  # 古いバックアップは成功後にクリーンアップ
  if [ -n "${BACKUP:-}" ] && [ -d "${BACKUP}" ]; then
    if [ -w "$(dirname "${BACKUP}")" ]; then
      rm -rf "${BACKUP}"
    else
      sudo rm -rf "${BACKUP}"
    fi
  fi
else
  echo "  [dry-run] cp -R forge.dist → ${DIST_DIR}"
  echo "  [dry-run] ln -sfn ${DIST_DIR}/forge → ${SYMLINK_PATH}"
fi

# ── 7. PATH 自動追記 ─────────────────────────────────────────────
SHELL_NAME="$(basename "${SHELL:-bash}")"
case "${SHELL_NAME}" in
  zsh)  RC="${HOME}/.zshrc" ;;
  fish) RC="${HOME}/.config/fish/config.fish" ;;
  *)    RC="${HOME}/.bashrc" ;;
esac

if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]]; then
  PATH_LINE="export PATH=\"${BIN_DIR}:\${PATH}\""

  if [ -n "${INSTALL_DIR_FROM_ENV}" ]; then
    # INSTALL_DIR を明示した非対話インストール（CI / Dockerfile 等）では
    # ユーザーの rc を勝手に書き換えない。代わりに手動で PATH へ追加する案内のみ出す。
    info "$(lang "INSTALL_DIR 指定のため rc への PATH 追記をスキップしました。次の行を PATH に追加してください：" \
                  "Skipped writing to your shell rc because INSTALL_DIR was specified. Add the following to your PATH:")"
    echo "    ${PATH_LINE}"
  elif [ "${DRY_RUN}" = "false" ]; then
    if ! grep -qF "${BIN_DIR}" "${RC}" 2>/dev/null; then
      printf '\n# AlphaForge alpha-forge\n%s\n' "${PATH_LINE}" >> "${RC}"
      ok "$(lang "PATH を ${RC} に追記しました" "Added PATH entry to ${RC}")"
    else
      ok "$(lang "PATH はすでに ${RC} に設定済みです" "PATH is already set in ${RC}")"
    fi
  else
    echo "  [dry-run] echo '${PATH_LINE}' >> ${RC}"
  fi
else
  ok "$(lang "PATH はすでに設定済みです" "PATH is already configured")"
fi

# ── 8. 動作確認（フルパス実行で dylib 解決を検証）─────────────────
# Nuitka standalone のコールドスタートは 1100+ dylib をロードするため
# 環境によっては数十秒〜1 分かかる。TTY ならスピナーを回して進行を伝える。
echo ""
if [ "${DRY_RUN}" = "false" ]; then
  VERIFY_OUT="${TMP_DIR}/verify.out"
  if spin_run "$(lang "動作確認中（alpha-forge コマンドの初回起動には時間がかかります）..." \
                       "Verifying installation (first alpha-forge launch may take a while)...")" \
              bash -c "'${SYMLINK_PATH}' --version >'${VERIFY_OUT}' 2>&1"; then
    VERIFY_LINE="$(head -1 "${VERIFY_OUT}" 2>/dev/null || echo "")"
    ok "$(lang "インストール完了！" "Installation complete!") (${VERIFY_LINE})"
  else
    fail "$(lang "alpha-forge コマンドの動作確認に失敗しました。\n  手動確認: ${SYMLINK_PATH} --version" \
                  "Failed to verify alpha-forge command.\n  Try manually: ${SYMLINK_PATH} --version")\n$(head -5 "${VERIFY_OUT}" 2>/dev/null || true)"
  fi
else
  ok "$(lang "ドライランが完了しました。実際にインストールするには --dry-run を外して再実行してください。" \
              "Dry run complete. Re-run without --dry-run to actually install.")"
fi

# ── 8b. 環境チェックサマリ（A3: install 後の環境診断導線）─────────────
# doctor をインライン実行すると EULA プロンプト（curl|bash でハング）と 2 回目の
# コールドスタートを招くため、ここでは自前の軽量チェックと `system doctor` への
# 案内のみを出す（詳細診断はユーザーが任意のタイミングで実行する）。
echo ""
echo "$(lang "環境チェック:" "Environment check:")"
if [[ ":${PATH}:" == *":${BIN_DIR}:"* ]]; then
  echo "  $(lang "✓ alpha-forge は現在のシェルの PATH 上にあります" \
                "✓ alpha-forge is on PATH in the current shell")"
else
  echo "  $(lang "✗ 現在のシェルからは未到達。次を実行してください: source ${RC}（または新しいターミナルを開く）" \
                "✗ Not reachable in the current shell. Run: source ${RC} (or open a new terminal)")"
fi
echo "  $(lang "詳細診断（PATH/データ/設定の確認と解決コマンド）: alpha-forge system doctor" \
              "Full diagnostics (PATH/data/config + fix commands): alpha-forge system doctor")"

# ── 9a. すぐ使い始める案内（Trial プラン / getting-started）────────────
# Whop 認証なしでも Trial プランで即利用できる旨を最初に案内する（getting-started の主訴求）。
echo ""
echo "$(lang "次のステップ: すぐに使い始める" "Next step: start using right away")"
echo "  $(lang "認証なしの Trial プランでそのまま使い始められます。" \
                "You can start using it immediately on the no-auth Trial plan.")"
echo "  $(lang "はじめ方ガイド" "Getting started guide"):"
echo "      $(lang "https://alforge-labs.github.io/ja/docs/getting-started/" \
                    "https://alforge-labs.github.io/en/docs/getting-started/")"

# ── 9b. ライセンス認証の案内（alpha-forge system auth login）────────────
echo ""
echo "$(lang "有料プランを使う場合: ライセンス認証" "To use a paid plan: license activation")"
echo "  $(lang "AlphaForge は Whop OAuth でライセンス認証を行います。" \
                "AlphaForge uses Whop OAuth for license activation.")"
echo "  $(lang "以下のコマンドを実行するとブラウザが開き、Whop で購入したアカウントで認証できます：" \
                "Run the following command to open a browser and authenticate with your purchased Whop account:")"
echo ""
echo "      alpha-forge system auth login"
echo ""
echo "  $(lang "認証状態を確認" "Check authentication status"):"
echo "      alpha-forge system auth status"

# ── 10. シェルへの反映案内 ──────────────────────────────────────
echo ""
if [ "${DRY_RUN}" = "false" ]; then
  # 現在のシェルから PATH を反映するための手順。
  # INSTALL_DIR 明示時は rc を書き換えていないので source ${RC} は案内しない
  # （PATH への追加手順はセクション 7 で既に案内済み）。
  if [[ ":${PATH}:" != *":${BIN_DIR}:"* ]] && [ -z "${INSTALL_DIR_FROM_ENV}" ]; then
    echo "$(lang "PATH を現在のシェルに反映するには、次のいずれかを実行してください：" \
                  "To apply the new PATH to the current shell, run one of the following:")"
    echo "    source ${RC}"
    case "${SHELL_NAME}" in
      zsh)  echo "    $(lang "# または: rehash (zsh のコマンドハッシュをクリア)" \
                              "# or: rehash (clear zsh command hash)")" ;;
      bash) echo "    $(lang "# または: hash -r (bash のコマンドハッシュをクリア)" \
                              "# or: hash -r (clear bash command hash)")" ;;
    esac
    echo "    $(lang "# または新しいターミナルを開く" "# or open a new terminal")"
  else
    # 既に PATH に入っているが、シェルのコマンドキャッシュが古い場合に備えて案内
    case "${SHELL_NAME}" in
      zsh)  echo "$(lang "現在のシェルで alpha-forge が見つからない場合は 'rehash' を実行してください。" \
                          "If alpha-forge is not found in the current shell, run 'rehash'.")" ;;
      bash) echo "$(lang "現在のシェルで alpha-forge が見つからない場合は 'hash -r' を実行してください。" \
                          "If alpha-forge is not found in the current shell, run 'hash -r'.")" ;;
    esac
  fi
  echo ""
  echo "$(lang "使い方" "Usage"): alpha-forge --help"
  echo ""
  echo "$(lang "アンインストールするには" "To uninstall"):"
  echo "    bash <(curl -sSL https://alforge-labs.github.io/uninstall.sh)"
  echo "    $(lang "# 認証情報も完全削除する場合: --purge オプション" \
                    "# To also remove auth credentials: add --purge option")"
fi

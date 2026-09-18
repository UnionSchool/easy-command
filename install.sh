#!/usr/bin/env bash

set -Eeuo pipefail

readonly VERSION='1.0.0'
readonly BEGIN_MARKER='# >>> easy-command zsh >>>'
readonly END_MARKER='# <<< easy-command zsh <<<'

ASSUME_YES=false
CHANGE_LOGIN_SHELL=true
UNINSTALL=false
TARGET_USER="${SUDO_USER:-${USER}}"

info() { printf '\033[1;32m[easy-command]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[easy-command]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m[easy-command]\033[0m %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
Usage: install.sh [options]

Options:
  --yes, -y         Run without confirmation.
  --user USER       Configure this user. Defaults to the invoking user.
  --no-chsh         Do not change the user's default login shell to zsh.
  --uninstall       Remove only the easy-command managed .zshrc block.
  --help, -h        Show this help.
EOF
}

while (($#)); do
    case "$1" in
        --yes|-y) ASSUME_YES=true ;;
        --user)
            shift
            (($#)) || fail '--user requires a value.'
            TARGET_USER="$1"
            ;;
        --no-chsh) CHANGE_LOGIN_SHELL=false ;;
        --uninstall) UNINSTALL=true ;;
        --help|-h)
            usage
            exit 0
            ;;
        *) fail "Unknown option: $1" ;;
    esac
    shift
done

TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 2>/dev/null || true)"
if [[ -z "$TARGET_HOME" && "$(uname -s)" == 'Darwin' ]]; then
    TARGET_HOME="$(dscl . -read "/Users/$TARGET_USER" NFSHomeDirectory | awk '{print $2}')"
fi
[[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || fail "Cannot determine home directory for $TARGET_USER."

run_as_root() {
    if [[ "$EUID" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail 'sudo is required to install packages or change the login shell.'
    fi
}

run_as_user() {
    if [[ "$EUID" -eq 0 && "$TARGET_USER" != 'root' ]]; then
        runuser -u "$TARGET_USER" -- "$@"
    else
        "$@"
    fi
}

backup_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    local backup="${file}.easy-command-backup-$(date +%Y%m%d%H%M%S)"
    cp "$file" "$backup"
    info "Backed up $file to $backup"
}

remove_managed_block() {
    local zshrc="$TARGET_HOME/.zshrc"
    [[ -f "$zshrc" ]] || return 0

    local temp_file
    temp_file="$(mktemp)"
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin { skipping = 1; next }
        $0 == end { skipping = 0; next }
        !skipping { print }
    ' "$zshrc" > "$temp_file"
    cat "$temp_file" > "$zshrc"
    rm -f "$temp_file"
    chown "$TARGET_USER" "$zshrc" 2>/dev/null || true
}

install_packages() {
    case "$(uname -s)" in
        Darwin)
            command -v brew >/dev/null 2>&1 || fail 'Homebrew is required on macOS: https://brew.sh'
            brew install zsh git
            ;;
        Linux)
            command -v apt-get >/dev/null 2>&1 || fail 'Only Ubuntu/Debian (apt-get) is supported on Linux.'
            run_as_root apt-get update
            run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y zsh git
            ;;
        *) fail "Unsupported operating system: $(uname -s)" ;;
    esac
}

install_repository() {
    local repository="$1"
    local destination="$2"
    [[ -d "$destination/.git" ]] && return 0

    mkdir -p "$(dirname "$destination")"
    run_as_user git clone --depth 1 "$repository" "$destination"
}

write_zshrc_block() {
    local zshrc="$TARGET_HOME/.zshrc"
    local temp_file
    temp_file="$(mktemp)"

    [[ -f "$zshrc" ]] && awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin { skipping = 1; next }
        $0 == end { skipping = 0; next }
        !skipping { print }
    ' "$zshrc" > "$temp_file"

    cat >> "$temp_file" <<'EOF'

# >>> easy-command zsh >>>
# Managed by easy-command. Re-run the installer to update this block.
export ZSH="$HOME/.easy-command/oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history share_history hist_ignore_dups
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

source "$ZSH/oh-my-zsh.sh"

ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[function]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
# <<< easy-command zsh <<<
EOF

    backup_file "$zshrc"
    cat "$temp_file" > "$zshrc"
    rm -f "$temp_file"
    chown "$TARGET_USER" "$zshrc" 2>/dev/null || true
}

change_login_shell() {
    "$CHANGE_LOGIN_SHELL" || return 0

    local zsh_path
    zsh_path="$(command -v zsh)"
    grep -qx "$zsh_path" /etc/shells || fail "$zsh_path is not listed in /etc/shells."
    run_as_root chsh -s "$zsh_path" "$TARGET_USER"
}

main() {
    if "$UNINSTALL"; then
        backup_file "$TARGET_HOME/.zshrc"
        remove_managed_block
        info 'Removed the easy-command managed .zshrc block.'
        exit 0
    fi

    if ! "$ASSUME_YES"; then
        read -r -p "Install easy-command for $TARGET_USER? [y/N] " answer
        [[ "$answer" =~ ^[Yy]$ ]] || exit 0
    fi

    install_packages

    local base_dir="$TARGET_HOME/.easy-command"
    install_repository 'https://github.com/ohmyzsh/ohmyzsh.git' "$base_dir/oh-my-zsh"
    install_repository 'https://github.com/zsh-users/zsh-autosuggestions.git' "$base_dir/oh-my-zsh/custom/plugins/zsh-autosuggestions"
    install_repository 'https://github.com/zsh-users/zsh-syntax-highlighting.git' "$base_dir/oh-my-zsh/custom/plugins/zsh-syntax-highlighting"

    write_zshrc_block
    change_login_shell

    info "Installed easy-command $VERSION for $TARGET_USER. Reconnect or run: exec zsh -l"
}

main

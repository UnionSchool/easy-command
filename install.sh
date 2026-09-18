#!/usr/bin/env bash

set -Eeuo pipefail

readonly VERSION='2.0.2'
readonly BEGIN_MARKER='# >>> easy-command zsh >>>'
readonly END_MARKER='# <<< easy-command zsh <<<'
readonly BASE_DIR_NAME='.easy-command'

ACTION='install'
ASSUME_YES=false
CHANGE_LOGIN_SHELL=true
DRY_RUN=false
ENABLE_ZOXIDE='auto'
ENABLE_FZF='auto'
ENABLE_GIT_ALIASES='auto'
TARGET_USER="${SUDO_USER:-${USER}}"
TARGET_HOME=''

info() { printf '\033[1;32m[easy-command]\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m[easy-command]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[1;31m[easy-command]\033[0m %s\n' "$*" >&2; exit 1; }
ok() { printf '\033[1;32m[ok]\033[0m %s\n' "$*"; }
check_warning() { printf '\033[1;33m[warn]\033[0m %s\n' "$*"; }
check_error() { printf '\033[1;31m[error]\033[0m %s\n' "$*"; }

usage() {
    cat <<'EOF'
Usage: easy-command [command] [options]

Commands:
  install             Install and configure easy-command (default).
  doctor              Check the Shell, dependencies, repositories and .zshrc block.
  repair              Restore missing dependencies, repositories and managed configuration.
  update              Safely update managed repositories and refresh managed configuration.

Options:
  --yes, -y           Run without confirmation.
  --user USER         Configure this user. Defaults to the invoking user.
  --no-chsh           Do not change the user's default login shell to zsh.
  --dry-run           Preview changes without installing, writing files, or using sudo.
  --with-zoxide       Enable optional zoxide directory jumping.
  --without-zoxide    Disable zoxide in the managed configuration.
  --with-fzf          Enable optional fzf history and file searching.
  --without-fzf       Disable fzf in the managed configuration.
  --with-git-aliases  Add non-conflicting global Git aliases prefixed with ec-.
  --without-git-aliases
                    Remove global Git aliases managed by easy-command.
  --uninstall         Remove only the easy-command managed .zshrc block.
  --help, -h          Show this help.
EOF
}

command_preview() {
    local output=''
    local part
    for part in "$@"; do
        output+="$(printf '%q' "$part") "
    done
    info "[dry-run] ${output% }"
}

run_as_root() {
    if "$DRY_RUN"; then
        command_preview sudo "$@"
    elif [[ "$EUID" -eq 0 ]]; then
        "$@"
    elif command -v sudo >/dev/null 2>&1; then
        sudo "$@"
    else
        fail 'sudo is required to install packages or change the login shell.'
    fi
}

run_as_user() {
    if "$DRY_RUN"; then
        if [[ "$EUID" -eq 0 && "$TARGET_USER" != 'root' ]]; then
            if command -v runuser >/dev/null 2>&1; then
                command_preview runuser -u "$TARGET_USER" -- "$@"
            else
                command_preview sudo -u "$TARGET_USER" -- "$@"
            fi
        else
            command_preview "$@"
        fi
    elif [[ "$EUID" -eq 0 && "$TARGET_USER" != 'root' ]]; then
        if command -v runuser >/dev/null 2>&1; then
            runuser -u "$TARGET_USER" -- "$@"
        elif command -v sudo >/dev/null 2>&1; then
            sudo -u "$TARGET_USER" -- "$@"
        else
            fail 'runuser or sudo is required to run commands as the target user.'
        fi
    else
        "$@"
    fi
}

write_file() {
    local source_file="$1"
    local destination_file="$2"

    if "$DRY_RUN"; then
        command_preview cp "$source_file" "$destination_file"
        return
    fi

    cp "$source_file" "$destination_file"
    chown "$TARGET_USER" "$destination_file" 2>/dev/null || true
}

determine_target_home() {
    if command -v getent >/dev/null 2>&1; then
        TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6 2>/dev/null || true)"
    fi
    if [[ -z "$TARGET_HOME" && "$(uname -s)" == 'Darwin' ]]; then
        TARGET_HOME="$(dscl . -read "/Users/$TARGET_USER" NFSHomeDirectory | awk '{print $2}')"
    fi
    [[ -n "$TARGET_HOME" && -d "$TARGET_HOME" ]] || fail "Cannot determine home directory for $TARGET_USER."
}

backup_file() {
    local file="$1"
    [[ -f "$file" ]] || return 0

    local backup="${file}.easy-command-backup-$(date +%Y%m%d%H%M%S)"
    local sequence=1
    while [[ -e "$backup" ]]; do
        backup="${file}.easy-command-backup-$(date +%Y%m%d%H%M%S)-${sequence}"
        sequence=$((sequence + 1))
    done
    if "$DRY_RUN"; then
        command_preview cp "$file" "$backup"
    else
        cp "$file" "$backup"
        chown "$TARGET_USER" "$backup" 2>/dev/null || true
    fi
    info "Backed up $file to $backup"
}

managed_block_is_valid() {
    local zshrc="$TARGET_HOME/.zshrc"
    [[ -f "$zshrc" ]] || return 0

    local begin_count end_count
    begin_count="$(grep -Fxc "$BEGIN_MARKER" "$zshrc" || true)"
    end_count="$(grep -Fxc "$END_MARKER" "$zshrc" || true)"
    [[ "$begin_count" == '0' && "$end_count" == '0' ]] || [[ "$begin_count" == '1' && "$end_count" == '1' ]]
}

managed_option_enabled() {
    local option="$1"
    local zshrc="$TARGET_HOME/.zshrc"

    [[ -f "$zshrc" ]] && grep -Fqx "# easy-command: ${option}" "$zshrc"
}

resolve_option() {
    local requested="$1"
    local marker="$2"

    if [[ "$requested" == 'auto' ]]; then
        if managed_option_enabled "$marker"; then
            printf 'true'
        else
            printf 'false'
        fi
    else
        printf '%s' "$requested"
    fi
}

install_packages() {
    local packages=(zsh git)
    [[ "$(resolve_option "$ENABLE_ZOXIDE" 'zoxide')" == 'true' ]] && packages+=(zoxide)
    [[ "$(resolve_option "$ENABLE_FZF" 'fzf')" == 'true' ]] && packages+=(fzf)

    case "$(uname -s)" in
        Darwin)
            command -v brew >/dev/null 2>&1 || fail 'Homebrew is required on macOS: https://brew.sh'
            run_as_user brew install "${packages[@]}"
            ;;
        Linux)
            command -v apt-get >/dev/null 2>&1 || fail 'Only Ubuntu/Debian (apt-get) is supported on Linux.'
            run_as_root apt-get update
            run_as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y "${packages[@]}"
            ;;
        *) fail "Unsupported operating system: $(uname -s)" ;;
    esac
}

ensure_repository() {
    local repository="$1"
    local destination="$2"

    if [[ -d "$destination/.git" ]]; then
        return 0
    fi
    if [[ -e "$destination" ]]; then
        fail "Expected Git repository at $destination, but the path is not a repository. Run repair after moving the path aside."
    fi

    if "$DRY_RUN"; then
        command_preview mkdir -p "$(dirname "$destination")"
    else
        mkdir -p "$(dirname "$destination")"
        chown "$TARGET_USER" "$(dirname "$destination")" 2>/dev/null || true
    fi
    run_as_user git clone --depth 1 "$repository" "$destination"
}

update_repository() {
    local destination="$1"
    [[ -d "$destination/.git" ]] || return 0

    if ! run_as_user git -C "$destination" diff --quiet --ignore-submodules --; then
        warn "Skipped $destination because it has local changes."
        return 0
    fi
    run_as_user git -C "$destination" pull --ff-only
}

ensure_repositories() {
    local base_dir="$TARGET_HOME/$BASE_DIR_NAME"
    ensure_repository 'https://github.com/ohmyzsh/ohmyzsh.git' "$base_dir/oh-my-zsh"
    ensure_repository 'https://github.com/zsh-users/zsh-autosuggestions.git' "$base_dir/oh-my-zsh/custom/plugins/zsh-autosuggestions"
    ensure_repository 'https://github.com/zsh-users/zsh-syntax-highlighting.git' "$base_dir/oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
}

update_repositories() {
    local base_dir="$TARGET_HOME/$BASE_DIR_NAME/oh-my-zsh"
    update_repository "$base_dir"
    update_repository "$base_dir/custom/plugins/zsh-autosuggestions"
    update_repository "$base_dir/custom/plugins/zsh-syntax-highlighting"
}

remove_managed_block() {
    local zshrc="$TARGET_HOME/.zshrc"
    [[ -f "$zshrc" ]] || return 0
    managed_block_is_valid || fail "Managed .zshrc block is incomplete or duplicated. Refusing to change $zshrc; restore a backup or repair the markers manually."

    if "$DRY_RUN"; then
        info "[dry-run] Would remove the managed block from $zshrc"
        return 0
    fi

    local temp_file
    temp_file="$(mktemp)"
    awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin { skipping = 1; next }
        $0 == end { skipping = 0; next }
        !skipping { print }
    ' "$zshrc" > "$temp_file"
    write_file "$temp_file" "$zshrc"
    rm -f "$temp_file"
}

write_zshrc_block() {
    local zshrc="$TARGET_HOME/.zshrc"
    managed_block_is_valid || fail "Managed .zshrc block is incomplete or duplicated. Refusing to change $zshrc; restore a backup or repair the markers manually."

    if "$DRY_RUN"; then
        info "[dry-run] Would write the managed configuration block to $zshrc"
        return 0
    fi

    local temp_file
    temp_file="$(mktemp)"

    [[ -f "$zshrc" ]] && awk -v begin="$BEGIN_MARKER" -v end="$END_MARKER" '
        $0 == begin { skipping = 1; next }
        $0 == end { skipping = 0; next }
        !skipping { print }
    ' "$zshrc" > "$temp_file"

    cat >> "$temp_file" <<EOF

# >>> easy-command zsh >>>
# Managed by easy-command. Re-run the installer to update this block.
export ZSH="\$HOME/.easy-command/oh-my-zsh"
ZSH_THEME="agnoster"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting)

HISTFILE="\$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt append_history share_history hist_ignore_dups
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

source "\$ZSH/oh-my-zsh.sh"

ZSH_HIGHLIGHT_STYLES[command]='fg=green'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=green'
ZSH_HIGHLIGHT_STYLES[function]='fg=green'
ZSH_HIGHLIGHT_STYLES[alias]='fg=green'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=red,bold'
EOF

    if [[ "$(resolve_option "$ENABLE_ZOXIDE" 'zoxide')" == 'true' ]]; then
        cat >> "$temp_file" <<'EOF'

# easy-command: zoxide
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
fi
EOF
    fi

    if [[ "$(resolve_option "$ENABLE_FZF" 'fzf')" == 'true' ]]; then
        cat >> "$temp_file" <<'EOF'

# easy-command: fzf
if [[ -r /usr/share/doc/fzf/examples/key-bindings.zsh ]]; then
    source /usr/share/doc/fzf/examples/key-bindings.zsh
elif command -v brew >/dev/null 2>&1 && [[ -r "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh" ]]; then
    source "$(brew --prefix)/opt/fzf/shell/key-bindings.zsh"
fi
EOF
    fi

    cat >> "$temp_file" <<'EOF'
# <<< easy-command zsh <<<
EOF

    backup_file "$zshrc"
    write_file "$temp_file" "$zshrc"
    rm -f "$temp_file"
}

configure_git_aliases() {
    local enabled
    enabled="$(resolve_option "$ENABLE_GIT_ALIASES" 'git-aliases')"

    local aliases=(
        'ec-status=status --short --branch'
        'ec-log=log --oneline --graph --decorate -12'
        'ec-last=log -1 --stat'
    )
    local entry name value
    for entry in "${aliases[@]}"; do
        name="${entry%%=*}"
        value="${entry#*=}"
        if "$DRY_RUN"; then
            if [[ "$enabled" == 'true' ]]; then
                command_preview git config --global "alias.$name" "$value"
            elif [[ "$ENABLE_GIT_ALIASES" == 'false' ]]; then
                command_preview git config --global --unset "alias.$name"
            fi
            continue
        fi
        if [[ "$enabled" == 'true' ]]; then
            if run_as_user git config --global --get "alias.$name" >/dev/null 2>&1; then
                check_warning "Git alias $name already exists; leaving it unchanged."
            else
                run_as_user git config --global "alias.$name" "$value"
            fi
        elif [[ "$ENABLE_GIT_ALIASES" == 'false' ]]; then
            run_as_user git config --global --unset "alias.$name" 2>/dev/null || true
        fi
    done
}

change_login_shell() {
    "$CHANGE_LOGIN_SHELL" || return 0

    local zsh_path
    zsh_path="$(command -v zsh)"
    if ! grep -qx "$zsh_path" /etc/shells; then
        if [[ -x /bin/zsh ]] && grep -qx '/bin/zsh' /etc/shells; then
            warn "$zsh_path is not listed in /etc/shells; using /bin/zsh as the login shell."
            zsh_path='/bin/zsh'
        else
            fail "$zsh_path is not listed in /etc/shells. Use --no-chsh or add the path to /etc/shells first."
        fi
    fi
    run_as_root chsh -s "$zsh_path" "$TARGET_USER"
}

confirm() {
    "$DRY_RUN" && return 0
    "$ASSUME_YES" && return 0

    local answer
    read -r -p "$1 [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 0
}

doctor() {
    local errors=0
    local zshrc="$TARGET_HOME/.zshrc"
    local base_dir="$TARGET_HOME/$BASE_DIR_NAME/oh-my-zsh"
    local configured_shell=''

    info "Checking easy-command for $TARGET_USER"
    if command -v getent >/dev/null 2>&1; then
        configured_shell="$(getent passwd "$TARGET_USER" | cut -d: -f7 2>/dev/null || true)"
    fi
    if [[ -z "$configured_shell" && "$(uname -s)" == 'Darwin' ]]; then
        configured_shell="$(dscl . -read "/Users/$TARGET_USER" UserShell | awk '{print $2}')"
    fi
    if [[ "$configured_shell" == *zsh ]]; then
        ok "Login shell: $configured_shell"
    else
        check_warning "Login shell is ${configured_shell:-unknown}; run install without --no-chsh to switch to zsh."
    fi

    local command_name
    for command_name in zsh git; do
        if command -v "$command_name" >/dev/null 2>&1; then
            ok "Command available: $command_name"
        else
            check_error "Missing command: $command_name"
            errors=$((errors + 1))
        fi
    done

    local repository
    for repository in "$base_dir" "$base_dir/custom/plugins/zsh-autosuggestions" "$base_dir/custom/plugins/zsh-syntax-highlighting"; do
        if [[ -d "$repository/.git" ]]; then
            ok "Repository available: $repository"
        else
            check_error "Missing repository: $repository"
            errors=$((errors + 1))
        fi
    done

    local begin_count=0 end_count=0
    if [[ -f "$zshrc" ]]; then
        begin_count="$(grep -Fxc "$BEGIN_MARKER" "$zshrc" || true)"
        end_count="$(grep -Fxc "$END_MARKER" "$zshrc" || true)"
    fi
    if [[ "$begin_count" == '1' && "$end_count" == '1' ]]; then
        ok 'Managed .zshrc block is complete.'
    else
        check_error "Managed .zshrc block is invalid (begin: $begin_count, end: $end_count). Restore a backup or repair the markers manually."
        errors=$((errors + 1))
    fi

    if command -v zsh >/dev/null 2>&1 && [[ -f "$zshrc" ]]; then
        if zsh -n "$zshrc"; then
            ok '.zshrc syntax check passed.'
        else
            check_error '.zshrc syntax check failed.'
            errors=$((errors + 1))
        fi
    fi

    if ((errors > 0)); then
        return 1
    fi
}

parse_args() {
    while (($#)); do
        case "$1" in
            install|doctor|repair|update)
                ACTION="$1"
                ;;
            --yes|-y) ASSUME_YES=true ;;
            --user)
                shift
                (($#)) || fail '--user requires a value.'
                TARGET_USER="$1"
                ;;
            --no-chsh) CHANGE_LOGIN_SHELL=false ;;
            --dry-run) DRY_RUN=true ;;
            --with-zoxide) ENABLE_ZOXIDE=true ;;
            --without-zoxide) ENABLE_ZOXIDE=false ;;
            --with-fzf) ENABLE_FZF=true ;;
            --without-fzf) ENABLE_FZF=false ;;
            --with-git-aliases) ENABLE_GIT_ALIASES=true ;;
            --without-git-aliases) ENABLE_GIT_ALIASES=false ;;
            --uninstall) ACTION='uninstall' ;;
            --help|-h)
                usage
                exit 0
                ;;
            *) fail "Unknown option or command: $1" ;;
        esac
        shift
    done
}

main() {
    parse_args "$@"
    determine_target_home

    case "$ACTION" in
        doctor)
            doctor
            ;;
        uninstall)
            confirm "Remove the easy-command managed configuration for $TARGET_USER?"
            backup_file "$TARGET_HOME/.zshrc"
            remove_managed_block
            info 'Removed the easy-command managed .zshrc block.'
            ;;
        install)
            confirm "Install easy-command $VERSION for $TARGET_USER?"
            install_packages
            ensure_repositories
            change_login_shell
            write_zshrc_block
            configure_git_aliases
            info "Installed easy-command $VERSION for $TARGET_USER. Reconnect or run: exec zsh -l"
            ;;
        repair)
            CHANGE_LOGIN_SHELL=false
            confirm "Repair easy-command for $TARGET_USER?"
            install_packages
            ensure_repositories
            write_zshrc_block
            configure_git_aliases
            info "Repaired easy-command for $TARGET_USER. Reconnect or run: exec zsh -l"
            ;;
        update)
            CHANGE_LOGIN_SHELL=false
            confirm "Update easy-command repositories for $TARGET_USER?"
            ensure_repositories
            update_repositories
            write_zshrc_block
            configure_git_aliases
            info "Updated easy-command for $TARGET_USER. Reconnect or run: exec zsh -l"
            ;;
    esac
}

main "$@"

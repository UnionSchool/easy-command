#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_DIR="$(mktemp -d)"
FAKE_BIN="$TEST_DIR/bin"
TEST_HOME="$TEST_DIR/home"
TEST_GIT_CONFIG="$TEST_DIR/gitconfig"
mkdir -p "$FAKE_BIN" "$TEST_HOME"
trap 'rm -rf "$TEST_DIR"' EXIT

create_fake() {
    local name="$1"
    shift
    printf '%s\n' '#!/usr/bin/env bash' "$@" > "$FAKE_BIN/$name"
    chmod +x "$FAKE_BIN/$name"
}

create_fake getent '
if [[ "$1" == "passwd" ]]; then
    printf "easytest:x:501:20::%s:/bin/zsh\\n" "$EASY_COMMAND_TEST_HOME"
fi'
create_fake uname 'printf "Darwin\\n"'
create_fake dscl '
if [[ "$4" == "UserShell" ]]; then
    printf "UserShell /bin/zsh\\n"
else
    printf "NFSHomeDirectory %s\\n" "$EASY_COMMAND_TEST_HOME"
fi'
create_fake brew '
if [[ "$1" == "--prefix" ]]; then
    printf "%s\\n" "$EASY_COMMAND_TEST_HOME/homebrew"
fi'
create_fake npm 'exit 0'
create_fake zsh 'exit 0'
create_fake git '
if [[ "$1" == "clone" ]]; then
    destination="${@: -1}"
    mkdir -p "$destination/.git"
elif [[ "$1" == "config" ]]; then
    shift
    [[ "$1" == "--global" ]] && shift
    if [[ "$1" == "--get" ]]; then
        value="$(grep -F "${2}=" "$EASY_COMMAND_TEST_GIT_CONFIG" 2>/dev/null || true)"
        [[ -n "$value" ]] || exit 1
        printf "%s\\n" "${value#*=}"
    elif [[ "$1" == "--unset" ]]; then
        grep -Fv "${2}=" "$EASY_COMMAND_TEST_GIT_CONFIG" > "$EASY_COMMAND_TEST_GIT_CONFIG.tmp" || true
        mv "$EASY_COMMAND_TEST_GIT_CONFIG.tmp" "$EASY_COMMAND_TEST_GIT_CONFIG"
    else
        printf "%s=%s\\n" "$1" "$2" >> "$EASY_COMMAND_TEST_GIT_CONFIG"
    fi
fi'
create_fake sudo '"$@"'
create_fake chsh 'exit 0'

export PATH="$FAKE_BIN:$PATH"
export EASY_COMMAND_TEST_HOME="$TEST_HOME"
export EASY_COMMAND_TEST_GIT_CONFIG="$TEST_GIT_CONFIG"

bash -n "$ROOT_DIR/install.sh"
bash "$ROOT_DIR/install.sh" --help >/dev/null

bash "$ROOT_DIR/install.sh" --dry-run --yes --no-chsh
[[ ! -e "$TEST_HOME/.zshrc" ]]
[[ ! -e "$TEST_HOME/.easy-command" ]]
bash "$ROOT_DIR/install.sh" --dry-run --yes --no-chsh --global | grep -F "npm install -g easy-command@2.0.7"

printf '%s\n' '# personal setting' > "$TEST_HOME/.zshrc"
bash "$ROOT_DIR/install.sh" --yes --no-chsh --with-fzf --with-git-aliases

grep -Fqx '# personal setting' "$TEST_HOME/.zshrc"
grep -Fqx '# easy-command: zoxide' "$TEST_HOME/.zshrc"
grep -Fqx '    eval "$(zoxide init zsh --no-cmd --hook none)"' "$TEST_HOME/.zshrc"
grep -Fqx '    function __easy_command_jump() {' "$TEST_HOME/.zshrc"
grep -Fqx '    function z() {' "$TEST_HOME/.zshrc"
grep -Fqx '        if [[ "$1" == '\''add'\'' || "$1" == '\''a'\'' ]]; then' "$TEST_HOME/.zshrc"
grep -Fqx '    function ec() {' "$TEST_HOME/.zshrc"
grep -Fqx '                __easy_command_jump "$@"' "$TEST_HOME/.zshrc"
grep -Fqx '            doctor|repair|update|install|uninstall)' "$TEST_HOME/.zshrc"
grep -Fqx '            list|ls|l)' "$TEST_HOME/.zshrc"
grep -Fqx '            del|remove)' "$TEST_HOME/.zshrc"
grep -Fqx '# easy-command: fzf' "$TEST_HOME/.zshrc"
[[ -d "$TEST_HOME/.easy-command/oh-my-zsh/.git" ]]
grep -Fqx 'alias.st=status' "$TEST_GIT_CONFIG"
grep -Fqx 'alias.cam=commit -a -m' "$TEST_GIT_CONFIG"
grep -Fqx 'alias.lg=log --color --graph --pretty=format:'"'"'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"'"' --abbrev-commit' "$TEST_GIT_CONFIG"
grep -Fqx 'alias.ec-status=status --short --branch' "$TEST_GIT_CONFIG"

bash "$ROOT_DIR/install.sh" doctor
mv "$FAKE_BIN/getent" "$FAKE_BIN/getent.disabled"
bash "$ROOT_DIR/install.sh" doctor
bash "$ROOT_DIR/install.sh" repair --yes --without-zoxide
! grep -Fqx '# easy-command: zoxide' "$TEST_HOME/.zshrc"
bash "$ROOT_DIR/install.sh" update --yes
bash "$ROOT_DIR/install.sh" --uninstall --yes

grep -Fqx '# personal setting' "$TEST_HOME/.zshrc"
! grep -Fq '# >>> easy-command zsh >>>' "$TEST_HOME/.zshrc"

printf '%s\n' '# >>> easy-command zsh >>>' > "$TEST_HOME/.zshrc"
if bash "$ROOT_DIR/install.sh" repair --yes >/dev/null 2>&1; then
    printf 'repair should reject an incomplete managed block\n' >&2
    exit 1
fi
grep -Fqx '# >>> easy-command zsh >>>' "$TEST_HOME/.zshrc"

printf 'easy-command installer tests passed\n'

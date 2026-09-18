<p align="right">
  <strong>ENGLISH</strong> | <a href="README_CN.md">中文</a>
</p>

# easy-command

Configure a polished Zsh terminal in one command.

`easy-command` installs and configures Oh My Zsh, the `agnoster` theme, Git status, command suggestions, Tab completion, and syntax highlighting. It preserves your existing `.zshrc` content and creates a backup before every change.

## INSTALL

### npm (recommended)

```bash
npm i -g easy-command
easy-command -y
```

Or install globally and configure your terminal in one command:

```bash
npx easy-command -y --global
exec zsh -l
```

### GitHub

No Node.js or npm is required:

```bash
curl -fsSL https://raw.githubusercontent.com/UnionSchool/easy-command/main/install.sh | bash -s -- -y
```

When installation finishes, open a new terminal session or run:

```bash
exec zsh -l
```

## Everyday commands

```bash
# Preview installation without changing your machine
easy-command --dry-run

# Check Shell, dependencies, managed repositories, and .zshrc configuration
easy-command doctor

# Restore missing managed files and configuration
easy-command repair -y

# Safely update Oh My Zsh and managed plugins
easy-command update -y
```

If you do not want a global npm installation, replace `easy-command` in the examples with `npx easy-command`.

## What you get

- A clean `agnoster` prompt with your user, path, Git branch, and working-tree status.
- History-based command suggestions. Press `→` or `Ctrl+E` to accept one.
- Syntax highlighting: valid commands are green; unknown commands are bold red.
- Native Zsh completion. Press `Tab` to complete; press it twice to view candidates.
- Shared history across terminal sessions, retaining the latest 10,000 commands.
- Built-in preview, diagnostics, repair, and update commands for easy maintenance.

## Preview

### Git branch and working-tree status

![agnoster displays Git branch and working-tree status](assets/git-status.png)

### History-based command suggestions

![A suggested history command appears while typing](assets/autosuggestions.png)

### Syntax highlighting and error feedback

![Valid commands are green and unknown commands are red](assets/syntax-highlighting.png)

## Options

```bash
# Configure a specific user
bash install.sh -y --user bell

# Keep the current login shell
bash install.sh -y --no-chsh

# Remove only the configuration block managed by easy-command
bash install.sh --uninstall

# Enable optional fuzzy search and Git aliases
bash install.sh -y --with-fzf --with-git-aliases
```

`zoxide` is installed by default. It enables `z <keyword>` directory jumping and `z add <directory>` (or `z a <directory>`) for manually recording a directory. Use `--without-zoxide` to disable it. `fzf` adds fuzzy history and file searching. Git aliases use the non-conflicting `ec-` prefix, such as `git ec-status`; existing aliases are never overwritten.

For a unified interface, use `ec <keyword>` to jump, `ec add <directory>` (or `ec a <directory>`) to record a directory, `ec list` (or `ec l`) to view entries, and `ec del <directory>` (or `ec remove <directory>`) to remove one. `ec doctor`, `ec repair`, `ec update`, `ec install`, `ec uninstall`, and `ec --dry-run` run the matching easy-command maintenance operation. `z` remains available for zoxide compatibility.

## Requirements

- macOS: Homebrew must already be installed.
- Ubuntu / Debian: dependencies are installed with `apt-get`.

The script needs `sudo` to install packages and change the default shell. Without sudo access, use `--no-chsh` and have an administrator install Zsh first.

## Configuration and rollback

The installer manages only the marked `easy-command` block in `~/.zshrc`. Before each update, it creates a timestamped backup. Running `--uninstall` removes only that managed block; it does not remove Oh My Zsh, plugins, command history, or other personal settings.

Installed components:

```text
~/.easy-command/oh-my-zsh
~/.zshrc
~/.zsh_history
```

## Security

For a first-time trial, download and inspect the script before running it:

```bash
curl -fsSLO https://raw.githubusercontent.com/UnionSchool/easy-command/main/install.sh
less install.sh
bash install.sh -y
```

For production, pin a release tag instead of running `main` directly:

```bash
npx easy-command@2.0.5 -y
```

Or, without npm:

```bash
curl -fsSL https://raw.githubusercontent.com/UnionSchool/easy-command/v2.0.5/install.sh | bash -s -- -y
```

## License

[MIT](LICENSE)

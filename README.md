# easy-command

一条命令配置统一的 Zsh 终端：Oh My Zsh、`agnoster` 主题、Git 状态、历史命令建议、Tab 补全与命令语法高亮。

## 效果预览

### Git 分支与工作区状态

![agnoster 显示 Git 分支和工作区状态](assets/git-status.png)

### 历史命令自动建议

![输入时显示可接受的历史命令建议](assets/autosuggestions.png)

### 命令语法高亮与错误提示

![有效命令为绿色，未知命令为红色](assets/syntax-highlighting.png)

## 快速开始

安装最新版本：

```bash
curl -fsSL https://raw.githubusercontent.com/UnionSchool/easy-command/main/install.sh | bash -s -- --yes
```

安装完成后重新登录，或运行：

```bash
exec zsh -l
```

## 提供的能力

- `agnoster`：显示用户名、路径、Git 分支和工作区状态。
- `zsh-autosuggestions`：从历史命令显示灰色建议，按 `→` 或 `Ctrl+E` 接受。
- `zsh-syntax-highlighting`：有效命令绿色、未知命令红色加粗。
- Zsh 原生补全：按 `Tab` 补全命令、路径和 Git 子命令，连按两次显示候选项。
- 共享历史：多个终端会话共享最近 10,000 条命令。

## 参数

```bash
# 指定目标用户
bash install.sh --yes --user bell

# 不改变默认登录 Shell
bash install.sh --yes --no-chsh

# 删除本工具管理的 .zshrc 区块
bash install.sh --uninstall
```

## 支持范围

- macOS：要求已安装 Homebrew。
- Ubuntu / Debian：使用 `apt-get` 安装依赖。

脚本需要 `sudo` 来安装软件包和切换默认 Shell。没有 sudo 权限时，可加 `--no-chsh`，并由管理员预先安装 Zsh。

## 配置与回退

安装内容位于：

```text
~/.easy-command/oh-my-zsh
~/.zshrc
~/.zsh_history
```

每次更新 `.zshrc` 前，脚本会创建带时间戳的备份。`--uninstall` 只删除由 easy-command 管理的配置块，不会删除 Oh My Zsh、插件或用户自己的其他配置。

## 安全说明

首次试用建议先下载并审阅脚本：

```bash
curl -fsSLO https://raw.githubusercontent.com/UnionSchool/easy-command/main/install.sh
less install.sh
bash install.sh --yes
```

生产环境建议固定到发布标签，而不是直接使用 `main`：

```bash
curl -fsSL https://raw.githubusercontent.com/UnionSchool/easy-command/v1.0.0/install.sh | bash -s -- --yes
```

## License

[MIT](LICENSE)

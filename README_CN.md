<p align="right">
  <a href="README.md">ENGLISH</a> | <strong>中文</strong>
</p>

# easy-command

一条命令配置更顺手的 Zsh 终端。

`easy-command` 会安装并配置 Oh My Zsh、`agnoster` 主题、Git 状态、命令建议、Tab 补全和语法高亮。每次修改 `.zshrc` 前都会备份，并保留用户已有的配置内容。

## 安装

### npm 安装（推荐）

```bash
npm i -g easy-command
easy-command -y
```

也可以一条命令完成全局安装和终端配置：

```bash
npx easy-command -y --global
exec zsh -l
```

### GitHub 安装

无需安装 Node.js 或 npm：

```bash
curl -fsSL https://raw.githubusercontent.com/UnionSchool/easy-command/main/install.sh | bash -s -- -y
```

安装完成后，重新打开终端，或执行：

```bash
exec zsh -l
```

## 日常命令

```bash
# 预览安装过程，不修改本机环境
easy-command --dry-run

# 检查 Shell、依赖、托管仓库和 .zshrc 配置
easy-command doctor

# 恢复缺失的托管文件和配置
easy-command repair -y

# 安全更新 Oh My Zsh 和托管插件
easy-command update -y
```

如不希望全局安装 npm 包，将示例中的 `easy-command` 替换为 `npx easy-command` 即可。

## 安装后即可使用

- `agnoster` 提示符：显示用户名、当前路径、Git 分支和工作区状态。
- 历史命令建议：输入时显示灰色建议，按 `→` 或 `Ctrl+E` 接受。
- 语法高亮：有效命令为绿色，未知命令为红色加粗。
- 原生 Zsh 补全：按 `Tab` 补全命令、路径和 Git 子命令；连按两次显示候选项。
- 多终端共享历史：保留最近 10,000 条命令。
- 内置预览、诊断、修复和更新命令，后续维护更简单。

## 效果预览

### Git 分支与工作区状态

![agnoster displays Git branch and working-tree status](assets/git-status.png)

### 历史命令自动建议

![A suggested history command appears while typing](assets/autosuggestions.png)

### 命令语法高亮与错误提示

![Valid commands are green and unknown commands are red](assets/syntax-highlighting.png)

## 常用参数

```bash
# 指定目标用户
bash install.sh -y --user bell

# 不修改默认登录 Shell
bash install.sh -y --no-chsh

# 仅删除 easy-command 管理的 .zshrc 配置区块
bash install.sh --uninstall

# 启用可选的模糊搜索
bash install.sh -y --with-fzf
```

默认安装 `zoxide`，可使用 `z <关键词>` 跳转目录，也支持 `z add <目录>` 或 `z a <目录>` 手动记录目录；目录仅会通过 `z add`、`z a`、`ec add` 或 `ec a` 显式记录，普通跳转不会自动添加目录。使用 `--without-zoxide` 可关闭。`fzf` 提供历史命令和文件的模糊搜索；默认添加 Git 快捷操作，包括 `git st`、`git br`、`git sw`、`git ci`、`git cam`、`git lg`、`git la`、`git lb` 和 `git ec-status` 等，不会覆盖已有同名别名。使用 `--without-git-aliases` 可跳过或移除项目管理的快捷方式。

统一入口使用 `ec`：`ec <关键词>` 跳转目录，`ec add <目录>` 或 `ec a <目录>` 记录目录，`ec list` 或 `ec l` 查看记录，`ec del <目录>` 或 `ec remove <目录>` 删除记录；`ec doctor`、`ec repair`、`ec update`、`ec install`、`ec uninstall` 和 `ec --dry-run` 执行对应的 easy-command 维护操作。为兼容 zoxide，原有 `z` 命令仍可使用。

## 系统要求

- macOS：需预先安装 Homebrew。
- Ubuntu / Debian：脚本会使用 `apt-get` 安装依赖。

脚本需要 `sudo` 权限安装软件包和切换默认 Shell。没有 sudo 权限时，请使用 `--no-chsh`，并由管理员预先安装 Zsh。

## 配置与回退

安装器只管理 `~/.zshrc` 中带有 `easy-command` 标记的配置区块。每次更新前会创建带时间戳的备份。执行 `--uninstall` 仅删除该托管区块，不会删除 Oh My Zsh、插件、命令历史或其他个人配置。

安装内容：

```text
~/.easy-command/oh-my-zsh
~/.zshrc
~/.zsh_history
```

## 安全说明

首次使用时，建议先下载并审阅脚本：

```bash
curl -fsSLO https://raw.githubusercontent.com/UnionSchool/easy-command/main/install.sh
less install.sh
bash install.sh -y
```

生产环境建议固定到发布标签，而不是直接使用 `main`：

```bash
npx easy-command@2.0.7 -y
```

或者不使用 npm：

```bash
curl -fsSL https://raw.githubusercontent.com/UnionSchool/easy-command/v2.0.7/install.sh | bash -s -- -y
```

## 许可

[MIT](LICENSE)

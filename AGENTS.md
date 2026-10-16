# easy-command 工作约定

- 本文件与 MEMORY.md 由 Codex 与 Claude Code 共用；开始或恢复任务读取 MEMORY.md，处理子目录前检查局部规则，阶段完成及交接时合并更新记忆并注明时区与工具。
- 无第三方依赖的 Shell CLI；npm 包 easy-command，入口 bin/easy-command，Node.js >=18。根目录运行 bash -n install.sh 与 npm test。
- 遵循上级 GitHub 管理目录的开源 npm 发布规范。保留现有包名和命令兼容性。
- .github/workflows/publish.yml 在 v* 标签推送时校验包版本、测试及检查打包内容，通过 OIDC 发布 npm；正式版本 latest、预发布 next。发布 job 使用 npm Environment，在 GitHub 显示 Deployment。
- npm Trusted Publisher 对应 UnionSchool/easy-command、publish.yml；如配置环境限制，必须匹配 npm。保持 id-token: write；不把 Token 或凭据写入仓库。
- 提交、推送、标签和发布按用户明确授权执行。发布后核实公开 registry 与实际安装，记录 GitHub Deployment 和发布结果。
- 不覆盖用户已有修改；不以 CLI 发布授权代替 IDE 插件或其他渠道的发布授权。

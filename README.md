# dotfiles

Windows 开发机配置仓库。配合 `D:\dev`(工具链目录,见其中的 `开发环境.txt`)使用,
目标是:**换机器 / 重装系统后,几条命令恢复整套开发环境**。

## 包含内容

| 目录 | 内容 | 恢复到 |
|---|---|---|
| `powershell/` | PowerShell profile(zoxide、fzf、eza 别名、vcvars 命令) | `文档\PowerShell\` 和 `文档\WindowsPowerShell\` |
| `git/` | Git 全局配置(身份、delta、gh 凭据助手) | `~\.gitconfig` |
| `terminal/` | Windows Terminal 配置(默认 pwsh 7) | WT 的 `LocalState\settings.json` |
| `scoop/` | Scoop 已装工具清单(28 个) | `scoop import` |

## 新机器还原

```powershell
git clone https://github.com/5834716/dotfiles D:\dotfiles
cd D:\dotfiles
.\bootstrap.ps1
```

脚本会:装 Scoop(到 `D:\dev\scoop`)→ 按清单装所有工具 → 恢复上表全部配置。
之后手动跑 `gh auth login` 登录 GitHub 即可。
VS 生成工具、Qt、WSL 的恢复见 `D:\dev\开发环境.txt` 的迁移章节。

## 日常维护

本机改了配置(profile、gitconfig、终端设置、装了新工具)之后:

```powershell
cd D:\dotfiles
.\sync.ps1        # 把本机最新配置收集回仓库
git add -A
git commit -m "update configs"
git push
```

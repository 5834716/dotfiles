# ============================================================
#  bootstrap.ps1  —  新机器一键还原开发环境
#  用法: 在仓库根目录执行  .\bootstrap.ps1
# ============================================================
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

# ---- 1. Scoop (装到 D:\dev\scoop, 与现有布局一致) ----
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host '[1/4] 安装 Scoop 到 D:\dev\scoop ...' -ForegroundColor Cyan
    [Environment]::SetEnvironmentVariable('SCOOP', 'D:\dev\scoop', 'User')
    $env:SCOOP = 'D:\dev\scoop'
    Invoke-RestMethod get.scoop.sh | Invoke-Expression
} else {
    Write-Host '[1/4] Scoop 已存在, 跳过' -ForegroundColor DarkGray
}

# ---- 2. 按清单安装所有工具 ----
Write-Host '[2/4] 按 scoop-list.json 安装工具 ...' -ForegroundColor Cyan
scoop import "$repo\scoop\scoop-list.json"

# ---- 3. 恢复配置文件 ----
Write-Host '[3/4] 恢复配置文件 ...' -ForegroundColor Cyan
$doc = [Environment]::GetFolderPath('MyDocuments')
New-Item -ItemType Directory -Force -Path "$doc\PowerShell", "$doc\WindowsPowerShell" | Out-Null
Copy-Item "$repo\powershell\profile.ps1" "$doc\PowerShell\profile.ps1" -Force
Copy-Item "$repo\powershell\profile.ps1" "$doc\WindowsPowerShell\profile.ps1" -Force
Copy-Item "$repo\git\gitconfig" "$env:USERPROFILE\.gitconfig" -Force

$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
if (Test-Path $wt) {
    Copy-Item "$repo\terminal\settings.json" "$wt\settings.json" -Force
} else {
    Write-Host '  Windows Terminal 未安装, 跳过其配置' -ForegroundColor Yellow
}

# ---- 4. 收尾提示 (无法自动化的部分) ----
Write-Host '[4/4] 完成! 以下步骤需手动处理:' -ForegroundColor Green
Write-Host '  - gh auth login          (登录 GitHub, 恢复 push 免密)'
Write-Host '  - VS 生成工具 / Qt / WSL  (参照 D:\dev\开发环境.txt 的迁移章节)'

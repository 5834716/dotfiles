# ============================================================
#  sync.ps1  —  把本机当前配置收集回仓库 (提交前跑一次)
#  用法: 在仓库根目录执行  .\sync.ps1
# ============================================================
$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot
$doc = [Environment]::GetFolderPath('MyDocuments')

Copy-Item "$doc\PowerShell\profile.ps1" "$repo\powershell\profile.ps1" -Force
Copy-Item "$env:USERPROFILE\.gitconfig" "$repo\git\gitconfig" -Force
$wt = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
if (Test-Path $wt) { Copy-Item $wt "$repo\terminal\settings.json" -Force }
scoop export | Out-File -Encoding utf8 "$repo\scoop\scoop-list.json"
New-Item -ItemType Directory -Force -Path "$repo\dev" | Out-Null
Copy-Item D:\dev\doctor.ps1, D:\dev\upgrade.ps1 "$repo\dev\" -Force
New-Item -ItemType Directory -Force -Path "$repo\cursor\rules" | Out-Null
Copy-Item D:\.cursor\rules\*.mdc "$repo\cursor\rules\" -Force -ErrorAction SilentlyContinue

Write-Host '已收集本机配置, 变更如下:' -ForegroundColor Green
git -C $repo status --short
Write-Host '确认无误后: git add -A && git commit && git push' -ForegroundColor Cyan

# ============================================================
#  upgrade.ps1  —  安全升级所有 Scoop 工具 (先快照, 后升级, 再体检)
#  用法:  pwsh D:\dev\upgrade.ps1
#  回滚:  scoop install <应用>@<旧版本>   (旧版本号见快照文件)
# ============================================================
$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$snapDir = 'D:\dotfiles\scoop\snapshots'
New-Item -ItemType Directory -Force -Path $snapDir | Out-Null

# 1. 升级前快照 (含精确版本号, 出问题可按此回退)
$snap = Join-Path $snapDir "scoop-$(Get-Date -Format yyyyMMdd-HHmmss).json"
scoop export | Out-File -Encoding utf8 $snap
Write-Host "已保存版本快照: $snap" -ForegroundColor Cyan

# 只保留最近 10 份快照
Get-ChildItem $snapDir -Filter 'scoop-*.json' | Sort-Object Name -Descending |
    Select-Object -Skip 10 | Remove-Item -Force

# 2. 升级
scoop update
scoop update *
scoop cleanup *   # 清理旧版本目录 (需要回退时按快照版本号 scoop install <app>@<version>)

# 3. 升级后体检
Write-Host "`n升级完成, 开始体检..." -ForegroundColor Cyan
& "$PSScriptRoot\doctor.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "体检未通过! 可参照快照回滚: scoop install <app>@<version>" -ForegroundColor Red
    Write-Host "快照文件: $snap" -ForegroundColor Red
    exit 1
}
Write-Host "提示: 记得同步 dotfiles (cd D:\dotfiles; .\sync.ps1 然后 commit+push)" -ForegroundColor Yellow
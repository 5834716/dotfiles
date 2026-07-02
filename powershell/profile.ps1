# ===== PowerShell profile (由 AI 助手生成, 可自由修改) =====

# 控制台输出用 UTF-8, 避免中文乱码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# PSReadLine: 输入时按历史记录联想, Tab 弹出补全菜单
try {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
} catch { }

# zoxide: 智能跳目录, 用法 z <目录关键字>, zi 交互选择
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# fzf: 默认用 fd 搜索文件, 界面更友好
if (Get-Command fd -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_COMMAND = 'fd --type f --hidden --exclude .git'
    $env:FZF_DEFAULT_OPTS = '--height 40% --layout=reverse'
}

# eza 别名: ll / la 代替 dir
if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ll { eza -l --icons --git @args }
    function la { eza -la --icons --git @args }
}

# vcvars: 一条命令加载 MSVC x64 编译环境 (cl / Qt 编译前先执行)
function vcvars {
    cmd /c "`"D:\dev\vs\VC\Auxiliary\Build\vcvars64.bat`" >nul 2>&1 && set" | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
    }
    Write-Host 'MSVC x64 环境已加载, cl 可用' -ForegroundColor Green
}

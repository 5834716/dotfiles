# ============================================================
#  doctor.ps1  —  开发环境体检 (D:\dev)
#  用法:
#    pwsh D:\dev\doctor.ps1          快速体检 (版本 + 关键路径, 约10秒)
#    pwsh D:\dev\doctor.ps1 -Build   完整体检 (每条工具链真编译真运行, 约2分钟)
#  退出码: 0 = 全部通过, 1 = 有失败项
# ============================================================
param([switch]$Build)

$ErrorActionPreference = 'Stop'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$script:Results = [System.Collections.Generic.List[object]]::new()

function Check {
    param([string]$Name, [scriptblock]$Action)
    try {
        $detail = & $Action
        $script:Results.Add([pscustomobject]@{ Name = $Name; OK = $true; Detail = "$detail" })
        Write-Host ("  [OK]   {0,-22} {1}" -f $Name, $detail) -ForegroundColor Green
    } catch {
        $script:Results.Add([pscustomobject]@{ Name = $Name; OK = $false; Detail = $_.Exception.Message })
        Write-Host ("  [FAIL] {0,-22} {1}" -f $Name, $_.Exception.Message) -ForegroundColor Red
    }
}

function FirstLine([string[]]$Lines) { ($Lines | Where-Object { $_ } | Select-Object -First 1).Trim() }

# ---------------- 1. 工具版本 ----------------
Write-Host "`n== 工具版本 ==" -ForegroundColor Cyan
Check 'git'     { FirstLine (git --version) }
Check 'gh'      { FirstLine (gh --version) }
Check 'clang'   { FirstLine (clang --version) }
Check 'gcc'     { FirstLine (gcc --version) }
Check 'rustc'   { FirstLine (rustc -V) }
Check 'cargo'   { FirstLine (cargo -V) }
Check 'go'      { FirstLine (go version) }
Check 'node'    { $n='D:\dev\scoop\apps\nodejs\current\node.exe'; $v='node ' + (FirstLine (& $n -v)); $cur=(Get-Command node -ErrorAction SilentlyContinue).Source; if ($cur -and $cur -notlike 'D:\dev\scoop\*') { $v += " (注意: 本会话 node 被 $cur 遮蔽)" }; $v }
Check 'pnpm'    { 'pnpm ' + (FirstLine (pnpm -v)) }
Check 'uv'      { FirstLine (uv --version) }
Check 'cmake'   { FirstLine (cmake --version) }
Check 'ninja'   { 'ninja ' + (FirstLine (ninja --version)) }
Check 'vcpkg'   { (FirstLine (vcpkg version)) -replace 'vcpkg package management program version ', 'vcpkg ' }
Check 'sccache' { FirstLine (sccache --version) }
Check 'rg'      { FirstLine (rg --version) }
Check 'iscc'    { FirstLine (& (Get-Command iscc -ErrorAction Stop).Source 2>&1) }

# ---------------- 2. 关键路径 / 环境 ----------------
Write-Host "`n== 关键路径 ==" -ForegroundColor Cyan
Check 'SCOOP 变量'    { if ($env:SCOOP -ne 'D:\dev\scoop') { throw "SCOOP=$env:SCOOP (期望 D:\dev\scoop)" }; $env:SCOOP }
Check 'vcvars64.bat'  { $p = 'D:\dev\vs\VC\Auxiliary\Build\vcvars64.bat'; if (-not (Test-Path $p)) { throw "缺失: $p" }; $p }
Check 'Qt 6.10.3'     { $p = 'D:\dev\qt\6.10.3\msvc2022_64'; if (-not (Test-Path "$p\bin\Qt6Core.dll")) { throw "缺失: $p" }; $p }
Check 'Qt 5.15.2'     { $p = 'D:\dev\qt\5.15.2\mingw81_32'; if (-not (Test-Path "$p\bin\qmake.exe")) { throw "缺失: $p" }; $p }
Check 'MinGW810 32位' { $p = 'D:\dev\qt\Tools\mingw810_32\bin\g++.exe'; if (-not (Test-Path $p)) { throw "缺失: $p" }; $p }
Check 'Windows SDK'   { $p = 'C:\Program Files (x86)\Windows Kits\10\Include'; $v = (Get-ChildItem $p -Directory | Sort-Object Name -Descending | Select-Object -First 1).Name; "SDK $v" }
Check 'WSL vhdx'      { $p = 'D:\dev\wsl\ext4.vhdx'; if (-not (Test-Path $p)) { throw "缺失: $p" }; '{0:N1} GB' -f ((Get-Item $p).Length / 1GB) }
Check 'sccache 配置'  { if ([Environment]::GetEnvironmentVariable('RUSTC_WRAPPER','User') -ne 'sccache') { throw '用户变量 RUSTC_WRAPPER 未设为 sccache' }; "RUSTC_WRAPPER=sccache, SCCACHE_DIR=$([Environment]::GetEnvironmentVariable('SCCACHE_DIR','User'))" }

# ---------------- 3. 真编译冒烟测试 (-Build) ----------------
if ($Build) {
    Write-Host "`n== 编译冒烟测试 ==" -ForegroundColor Cyan
    $work = "D:\dev\tmp\doctor-$(Get-Date -Format yyyyMMdd-HHmmss)"
    New-Item -ItemType Directory -Force -Path $work | Out-Null

    # 加载 MSVC x64 环境 (只影响本脚本进程)
    Check 'vcvars 加载' {
        cmd /c "`"D:\dev\vs\VC\Auxiliary\Build\vcvars64.bat`" >nul 2>&1 && set" | ForEach-Object {
            if ($_ -match '^([^=]+)=(.*)$') { Set-Item -Path "env:$($Matches[1])" -Value $Matches[2] }
        }
        $clOut = (cl 2>&1 | Out-String) -split "`n" | Where-Object { $_ -match 'Version' } | Select-Object -First 1
        if (-not $clOut) { throw 'cl 不可用' }
        $clOut.Trim()
    }

    Set-Content "$work\hello.c"   "#include <stdio.h>`nint main(){printf(`"c-ok\n`");return 0;}"
    Set-Content "$work\hello.cpp" "#include <iostream>`nint main(){std::cout<<`"cpp-ok\n`";return 0;}"
    Set-Content "$work\hello.rs"  "fn main(){println!(`"rust-ok`");}"
    Set-Content "$work\hello.go"  "package main`nimport `"fmt`"`nfunc main(){fmt.Println(`"go-ok`")}"
    Set-Content "$work\hello.js"  "console.log('node-ok')"
    Set-Content "$work\hello.py"  "print('python-ok')"

    function Run-Expect([string]$Exe, [string[]]$ArgList, [string]$Expect, [string]$Cwd) {
        Push-Location $Cwd
        try { $out = (& $Exe @ArgList 2>&1 | Out-String).Trim() } finally { Pop-Location }
        if ($out -notmatch [regex]::Escape($Expect)) { throw "输出异常: $out" }
        $Expect
    }

    Check 'C (gcc)'       { gcc "$work\hello.c" -o "$work\c_gcc.exe" | Out-Null; Run-Expect "$work\c_gcc.exe" @() 'c-ok' $work }
    Check 'C++ (clang++)' { clang++ "$work\hello.cpp" -o "$work\cpp_clang.exe" | Out-Null; Run-Expect "$work\cpp_clang.exe" @() 'cpp-ok' $work }
    Check 'C++ (MSVC cl)' { Push-Location $work; try { cl /nologo /EHsc hello.cpp /Fe:cpp_cl.exe 2>&1 | Out-Null } finally { Pop-Location }; Run-Expect "$work\cpp_cl.exe" @() 'cpp-ok' $work }
    Check 'Rust (rustc)'  { rustc "$work\hello.rs" -o "$work\rs.exe" 2>&1 | Out-Null; Run-Expect "$work\rs.exe" @() 'rust-ok' $work }
    Check 'Go'            { Push-Location $work; try { go build -o go.exe hello.go 2>&1 | Out-Null } finally { Pop-Location }; Run-Expect "$work\go.exe" @() 'go-ok' $work }
    Check 'Node'          { Run-Expect 'D:\dev\scoop\apps\nodejs\current\node.exe' @("$work\hello.js") 'node-ok' $work }
    Check 'Python (uv)'   { Run-Expect 'uv' @('run', '--no-project', 'python', "$work\hello.py") 'python-ok' $work }

    Check 'Qt6+CMake+Ninja' {
        $qtDir = "$work\qtapp"
        New-Item -ItemType Directory -Force -Path $qtDir | Out-Null
        Set-Content "$qtDir\main.cpp" "#include <QCoreApplication>`n#include <QString>`n#include <iostream>`nint main(int c,char**v){QCoreApplication a(c,v);std::cout<<QString(`"qt-ok`").toStdString()<<std::endl;return 0;}"
        Set-Content "$qtDir\CMakeLists.txt" "cmake_minimum_required(VERSION 3.20)`nproject(doctorqt CXX)`nset(CMAKE_CXX_STANDARD 17)`nfind_package(Qt6 REQUIRED COMPONENTS Core)`nadd_executable(doctorqt main.cpp)`ntarget_link_libraries(doctorqt Qt6::Core)"
        Push-Location $qtDir
        try {
            cmake -G Ninja -DCMAKE_CXX_COMPILER=cl -DCMAKE_PREFIX_PATH=D:/dev/qt/6.10.3/msvc2022_64 -B build 2>&1 | Out-Null
            ninja -C build 2>&1 | Out-Null
        } finally { Pop-Location }
        $env:PATH = "D:\dev\qt\6.10.3\msvc2022_64\bin;$env:PATH"
        Run-Expect "$qtDir\build\doctorqt.exe" @() 'qt-ok' $qtDir
    }

    Remove-Item -Recurse -Force $work -ErrorAction SilentlyContinue
}

# ---------------- 汇总 ----------------
$fail = @($script:Results | Where-Object { -not $_.OK })
Write-Host ""
if ($fail.Count -eq 0) {
    Write-Host ("体检通过: {0}/{0} 项全部正常" -f $script:Results.Count) -ForegroundColor Green
    exit 0
} else {
    Write-Host ("体检发现问题: {0} 项失败 / 共 {1} 项" -f $fail.Count, $script:Results.Count) -ForegroundColor Red
    $fail | ForEach-Object { Write-Host ("  - {0}: {1}" -f $_.Name, $_.Detail) -ForegroundColor Red }
    exit 1
}
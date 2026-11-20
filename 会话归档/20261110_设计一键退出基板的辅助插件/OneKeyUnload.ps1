# ================================================================
#  一键退出基板 · 零依赖备选   v3
#  流程来源：演示文稿1.pptx 第 1~4 页（按页序整理）
#  Windows PowerShell 5.1 自带，不用安装任何东西
#
#  常用命令（在本文件所在目录打开 PowerShell）：
#    powershell -ExecutionPolicy Bypass -File .\OneKeyUnload.ps1 -ListWindows   # 看所有窗口标题/类名
#    powershell -ExecutionPolicy Bypass -File .\OneKeyUnload.ps1 -Calibrate      # 4 步引导取点
#    powershell -ExecutionPolicy Bypass -File .\OneKeyUnload.ps1 -DryRun         # 空跑：只打印不点击
#    powershell -ExecutionPolicy Bypass -File .\OneKeyUnload.ps1                 # 正式执行
#    powershell -ExecutionPolicy Bypass -File .\OneKeyUnload.ps1 -WaitScale 2    # 全部等待放慢 2 倍
#
#  现场答复已并入：等待时间可调 / 标题自动识别 / 无确认弹窗 / 许可已获批准
#  急停：把鼠标猛推到屏幕左上角 (0,0)，或在本控制台按 Esc
# ================================================================

param(
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'config.json'),
    [switch]$Calibrate,
    [switch]$DryRun,
    [switch]$ListWindows,
    [double]$WaitScale = -1
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class U32 {
    public delegate bool EnumProc(IntPtr h, IntPtr l);
    [DllImport("user32.dll")] public static extern bool EnumWindows(EnumProc cb, IntPtr l);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowText(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassName(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool SetCursorPos(int x, int y);
    [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
    [DllImport("user32.dll")] public static extern bool GetCursorPos(out POINT p);
    [DllImport("user32.dll")] public static extern void mouse_event(uint f, uint dx, uint dy, uint d, IntPtr e);
    [DllImport("user32.dll")] public static extern short GetAsyncKeyState(int vKey);
    [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left; public int Top; public int Right; public int Bottom; }
    [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X; public int Y; }

    public static string TitleOf(IntPtr h) { StringBuilder s = new StringBuilder(512); GetWindowText(h, s, 512); return s.ToString(); }
    public static string ClassOf(IntPtr h) { StringBuilder s = new StringBuilder(256); GetClassName(h, s, 256); return s.ToString(); }
    public static RECT RectOf(IntPtr h) { RECT r; GetWindowRect(h, out r); return r; }
    public static POINT Cursor() { POINT p; GetCursorPos(out p); return p; }

    public static IntPtr Find(string needle) {
        if (string.IsNullOrEmpty(needle)) return IntPtr.Zero;
        IntPtr found = IntPtr.Zero;
        EnumWindows(new EnumProc(delegate(IntPtr h, IntPtr l) {
            if (!IsWindowVisible(h)) return true;
            if (TitleOf(h).IndexOf(needle, StringComparison.OrdinalIgnoreCase) >= 0) { found = h; return false; }
            return true;
        }), IntPtr.Zero);
        return found;
    }
    public static IntPtr FindClass(string cls) {
        if (string.IsNullOrEmpty(cls)) return IntPtr.Zero;
        IntPtr found = IntPtr.Zero;
        EnumWindows(new EnumProc(delegate(IntPtr h, IntPtr l) {
            if (!IsWindowVisible(h)) return true;
            if (ClassOf(h).IndexOf(cls, StringComparison.OrdinalIgnoreCase) >= 0) { found = h; return false; }
            return true;
        }), IntPtr.Zero);
        return found;
    }
    public static IntPtr AtCursor() {
        POINT p = Cursor();
        IntPtr found = IntPtr.Zero;
        EnumWindows(new EnumProc(delegate(IntPtr h, IntPtr l) {
            if (!IsWindowVisible(h)) return true;
            RECT r; GetWindowRect(h, out r);
            if (p.X >= r.Left && p.X <= r.Right && p.Y >= r.Top && p.Y <= r.Bottom) { found = h; return false; }
            return true;
        }), IntPtr.Zero);
        return found;
    }
    public static string[] WindowList() {
        List<string> list = new List<string>();
        EnumWindows(new EnumProc(delegate(IntPtr h, IntPtr l) {
            if (!IsWindowVisible(h)) return true;
            string t = TitleOf(h);
            if (string.IsNullOrEmpty(t)) return true;
            RECT r; GetWindowRect(h, out r);
            list.Add(t + " | " + ClassOf(h) + " | 位置(" + r.Left + "," + r.Top + ") 大小(" + (r.Right-r.Left) + "x" + (r.Bottom-r.Top) + ")");
            return true;
        }), IntPtr.Zero);
        return list.ToArray();
    }
}
"@

# config.json 用 UTF-8 存中文，必须显式按 UTF-8 读，PS 5.1 默认会按 ANSI 解码导致乱码
$cfg = [System.IO.File]::ReadAllText($ConfigPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$script:steps = @($cfg.steps)
$script:logFile = Join-Path $PSScriptRoot ("OneKeyUnload_log_{0}.txt" -f (Get-Date -Format 'yyyyMM'))

$scale = 1.0
if ($cfg.waitScale) { $scale = [double]$cfg.waitScale }
if ($WaitScale -gt 0) { $scale = $WaitScale }

function Write-Log {
    param([string]$Message)
    $line = "[{0}] {1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    [System.IO.File]::AppendAllText($script:logFile, $line + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
    Write-Host $line
}

function Get-TargetHwnd {
    param([string]$Title, [string]$Class)
    $h = [U32]::Find($Title)
    if ($h -eq [IntPtr]::Zero -and $Class) { $h = [U32]::FindClass($Class) }
    if ($h -eq [IntPtr]::Zero) { throw "找不到窗口：标题「$Title」/ 类名「$Class」。可先运行 -ListWindows 看实际标题" }
    return $h
}

function Test-Abort {
    $p = [System.Windows.Forms.Cursor]::Position
    if ($p.X -lt 5 -and $p.Y -lt 5) { return $true }
    try {
        if ([Console]::KeyAvailable) {
            $k = [Console]::ReadKey($true)
            if ($k.Key -eq [ConsoleKey]::Escape) { return $true }
        }
    } catch { }
    return $false
}

function Wait-Safe {
    param([int]$Milliseconds)
    $n = [math]::Max(1, [math]::Ceiling($Milliseconds / 100))
    for ($i = 0; $i -lt $n; $i++) {
        if (Test-Abort) { return $false }
        Start-Sleep -Milliseconds 100
    }
    return $true
}

function Invoke-Click {
    param([string]$Window, [string]$Class, [int]$RelX, [int]$RelY, [switch]$NoClick)
    $h = Get-TargetHwnd -Title $Window -Class $Class
    [void][U32]::SetForegroundWindow($h)
    Start-Sleep -Milliseconds 180
    $r = [U32]::RectOf($h)
    $sx = $r.Left + $RelX
    $sy = $r.Top + $RelY
    $where = "窗口=$Window 屏幕($sx, $sy) 相对($RelX, $RelY)"
    if ($NoClick) { return $where }
    [void][U32]::SetCursorPos($sx, $sy)
    Start-Sleep -Milliseconds 70
    [U32]::mouse_event(0x0002, 0, 0, 0, [IntPtr]::Zero)
    Start-Sleep -Milliseconds 40
    [U32]::mouse_event(0x0004, 0, 0, 0, [IntPtr]::Zero)
    return $where
}

function Show-Windows {
    Write-Host ''
    Write-Host '当前所有可见窗口（标题 | 类名 | 位置与大小）' -ForegroundColor Cyan
    [U32]::WindowList() | ForEach-Object { Write-Host ('  ' + $_) }
    Write-Host ''
    Write-Host '用途：截图没拍到标题栏也没关系，这里能看到软件窗口的真实标题。' -ForegroundColor Yellow
}

function Invoke-Calibrate {
    Write-Host ''
    Write-Host '===== 现场取点向导（共 4 步）=====' -ForegroundColor Cyan
    Write-Host '做法：把鼠标停在按钮正中间，直接按【F12】记录，不用切回本控制台。'
    Write-Host '      只悬停、不要点击设备按钮；取点过程不会给设备发任何指令。'
    Write-Host '      ★ 用 F12 而不是空格 / 回车：那两个键会激活界面上当前有焦点的按钮，可能真的点动设备。'
    Write-Host '      第 2、3 步之间需要你手动点一下页面切换（SETUP / Right Bond Stage）。'
    Write-Host '      任何时候按 Esc 取消，配置不会被改动。'
    Write-Host ''
    $prompts = @(
        '① 起始页右侧工具栏第 3 个 SETUP（扳手锤子）图标正中间',
        '② Setup 树页里「Right Bond Stage」这一行文字正中间（先手动点 SETUP 切过去）',
        '③ Right Bond Stage 子窗口 Operations 区右下部「Standby」按钮正中间（先手动打开子窗口）',
        '④ 同一子窗口 Status 区第 1 行 Vacuum 的「Toggle」按钮正中间'
    )
    Write-Host '四步依次是（先扫一眼，之后照做即可）：' -ForegroundColor Yellow
    for ($j = 0; $j -lt $prompts.Count; $j++) { Write-Host ('  ' + $prompts[$j]) }
    Write-Host ''
    $vkF12 = 0x7B
    $vkEsc = 0x1B
    $result = @()
    for ($i = 0; $i -lt $script:steps.Count; $i++) {
        Write-Host ''
        $tip = $prompts[$i]
        if (-not $tip) { $tip = ('第 {0} 步「{1}」的按钮正中间' -f ($i + 1), $script:steps[$i].name) }
        Write-Host ("[{0}/{1}] 把鼠标停在：{2}" -f ($i + 1), $script:steps.Count, $tip) -ForegroundColor Yellow
        Write-Host '  停稳后按【F12】记录（按 Esc 取消）…'
        while (([U32]::GetAsyncKeyState($vkF12) -band 0x8000) -ne 0) { Start-Sleep -Milliseconds 50 }
        $cancelled = $false
        while ($true) {
            Start-Sleep -Milliseconds 50
            if (([U32]::GetAsyncKeyState($vkEsc) -band 0x8000) -ne 0) { $cancelled = $true; break }
            if (([U32]::GetAsyncKeyState($vkF12) -band 0x8000) -ne 0) { break }
        }
        if ($cancelled) { Write-Host '已取消，未写入配置'; return }
        Start-Sleep -Milliseconds 120
        $h = [U32]::AtCursor()
        if ($h -eq [IntPtr]::Zero) { Write-Host '  鼠标下面没找到窗口，请重试'; $i--; continue }
        $p = [U32]::Cursor()
        $r = [U32]::RectOf($h)
        $title = [U32]::TitleOf($h)
        $cls = [U32]::ClassOf($h)
        if ($title -like '*一键退出基板*' -or $title -like '*OneKeyUnload*') {
            Write-Host '  鼠标停在本工具窗口上了，请移到设备软件上再试'; $i--; continue
        }
        $rx = $p.X - $r.Left
        $ry = $p.Y - $r.Top
        Write-Host ("  已记录：标题「{0}」 类名「{1}」 相对坐标 X={2} Y={3}" -f $title, $cls, $rx, $ry) -ForegroundColor Green
        $script:steps[$i].win = $title
        $script:steps[$i].winClass = $cls
        $script:steps[$i].x = $rx
        $script:steps[$i].y = $ry
        $result += ("第 {0} 步 {1}：标题={2} 类名={3} X={4} Y={5}" -f ($i+1), $script:steps[$i].name, $title, $cls, $rx, $ry)
    }
    $cfg.calibrated = $true
    $cfg.calibratedAt = (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
    $cfg.windows.main = $script:steps[0].win
    $cfg.windows.stage = $script:steps[2].win
    $json = $cfg | ConvertTo-Json -Depth 10
    [System.IO.File]::WriteAllText($ConfigPath, $json, (New-Object System.Text.UTF8Encoding($false)))
    $card = Join-Path $PSScriptRoot '取点结果.txt'
    [System.IO.File]::WriteAllText($card, ("一键退出基板 · 现场取点结果`r`n取点时间：{0}`r`n`r`n{1}`r`n`r`n配置已写入：{2}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), ($result -join "`r`n"), $ConfigPath), [System.Text.Encoding]::UTF8)
    Write-Host ''
    Write-Host '取点完成：已写入 config.json，并在同目录生成 取点结果.txt。' -ForegroundColor Green
    Write-Host '建议下一步：-DryRun 空跑一遍，再去维护模式 / 空片上试。'
}

Write-Host ''
Write-Host '一键退出基板 · 零依赖辅助工具 v3' -ForegroundColor Cyan
Write-Host '流程（PPT 第 1~4 页）：1 SETUP 图标 → 2 树项 Right Bond Stage → 3 Standby → 4 Vacuum Toggle'
Write-Host ("步骤数：{0}　已取点：{1}　等待倍率：x{2}" -f $script:steps.Count, [bool]$cfg.calibrated, $scale)
Write-Host '执行中请勿移动鼠标。急停：鼠标猛推到屏幕左上角，或在此窗口按 Esc'
Write-Host ''

if ($ListWindows) {
    Show-Windows
}
elseif ($Calibrate) {
    Invoke-Calibrate
}
elseif ((-not $cfg.calibrated) -and (-not $DryRun)) {
    Write-Host '尚未完成现场取点，坐标仍是拍屏照片的估算值，已禁止真实执行。' -ForegroundColor Red
    Write-Host '请先运行：-File .\OneKeyUnload.ps1 -Calibrate   （4 步引导取点）' -ForegroundColor Yellow
    Write-Host '只想看流程：加 -DryRun 空跑，不会点击设备。'
}
else {
    if ($cfg.requireConfirm -and (-not $DryRun)) {
        Write-Host '启动前请逐条确认：' -ForegroundColor Yellow
        if ($cfg.preRunChecklist) { $cfg.preRunChecklist | ForEach-Object { Write-Host ('  □ ' + $_) } }
        $ans = Read-Host '以上都确认无误，输入 Y 继续（其他输入即取消）'
        if ($ans -ne 'Y' -and $ans -ne 'y') { Write-Host '已取消'; return }
    }

    Write-Log ('===== 开始执行 =====' + $(if ($DryRun) { '（空跑，不发送点击）' } else { '' }) + " 倍率 x$scale")
    $aborted = $false

    for ($i = 0; $i -lt $script:steps.Count; $i++) {
        $s = $script:steps[$i]
        if (Test-Abort) { Write-Log '用户中止'; $aborted = $true; break }
        try {
            Write-Log ("[{0}/{1}] {2}（窗口：{3}）" -f ($i + 1), $script:steps.Count, $s.name, $s.win)
            $where = Invoke-Click -Window $s.win -Class $s.winClass -RelX ([int]$s.x) -RelY ([int]$s.y) -NoClick:([bool]$DryRun)
            if ($DryRun) { Write-Log ("  [空跑] 本应点击 {0}" -f $where) }
            else { Write-Log ("  点击位置 {0}" -f $where) }

            if ($s.check) {
                Write-Host ''
                Write-Host "  期望状态：$($s.check)" -ForegroundColor Yellow
                $c = Read-Host '  请目视确认状态后输入 Y 继续（其他输入即中止）'
                if ($c -ne 'Y' -and $c -ne 'y') {
                    Write-Log '状态人工确认未通过 → 中止'
                    $aborted = $true
                    break
                }
                Write-Log '  状态已人工确认'
            }

            $ms = [int]([double]$s.wait * $scale)
            if (-not (Wait-Safe -Milliseconds $ms)) {
                Write-Log '等待期间收到中止请求'
                $aborted = $true
                break
            }
            Write-Log ("  等待 {0} ms 完成（设定 {1} ms × 倍率 {2}）" -f $ms, $s.wait, $scale)
        } catch {
            Write-Log ("错误：{0} → 中止" -f $_.Exception.Message)
            $aborted = $true
            break
        }
    }

    if ($aborted) { Write-Log '===== 已中止，剩余步骤未执行 =====' }
    else { Write-Log '===== 执行结束，请人工核对设备状态 =====' }
}

Write-Host ''
Read-Host '按回车键关闭'

; ================================================================
;  一键退出基板 · 辅助工具   v3
;  流程来源：演示文稿1.pptx 第 1~4 页（按页序整理）
;  AutoHotkey v1.1  |  不改原软件，只按既定顺序代点界面按钮
;
;  2026-11-11 现场答复已并入本版：
;    ① 4 步之间的等待时间做成可调整项，面板上直接改、自动存盘，现场调试再定值
;    ② 截图没拍到标题栏无关紧要：取点向导自动记录「鼠标下面那个窗口」的真实标题与类名
;    ③ 4 步均不弹确认框：本脚本不再等待、不再点击任何设备弹窗
;    ④ 上机前必须先按 F12 做一次取点；未取点时 F9 被锁住，只能空跑
;       取点用 F12 而不是空格/回车：后两者会激活当前有焦点的按钮，可能点动设备
;    ⑤ 厂内 IT / 设备许可已获批准（仍建议首试在维护模式 / 空片下做）
;
;  2026-11-16 现场反馈：已跑通；按 F9 直接执行，取消执行前二次确认弹窗。
;    默认 RequireConfirm=0；如需恢复确认框，在 calib.ini 的 [Options] 下写 Confirm=1，
;    无需重新编译。执行中仍可按 Esc 随时中止。
;
;  中文乱码时：用记事本另存为「UTF-8 带 BOM」，或安装 AutoHotkey Unicode 版
; ================================================================

#SingleInstance Force
#NoEnv
SetBatchLines -1
SetTitleMatchMode 2
CoordMode, Mouse, Screen
FileEncoding, UTF-8

; ---------------------------------------------- ① 现场可调配置
DefaultWin     := "Auto Bond"          ; 主窗口标题关键字（取点后以向导记录为准）
CalibMainWin   := "Auto Bond"          ; 兼容旧说明：主窗口
CalibStageWin  := "Right Bond Stage"   ; 兼容旧说明：子窗口
RequireConfirm := 0                    ; 0 = 按 F9 直接执行（现场要求，已取消二次确认）；1 = 恢复确认框
WaitScale      := 1.0                  ; 全局等待倍率：调试时改成 2.0 放慢，稳了调回 1.0
CalibFile      := A_ScriptDir "\OneKeyUnload_calib.ini"
ResultFile     := A_ScriptDir "\取点结果.txt"
LogFile        := A_ScriptDir "\OneKeyUnload_log_" A_YYYY A_MM ".txt"

; 启动前二次确认里会逐条列出，请按厂里规定增删
Checklist := []
Checklist.Push("设备无未清除报警")
Checklist.Push("载板 / 当前批次无产品（空片或维护模式）")
Checklist.Push("本次操作已获设备工程师批准")
Checklist.Push("已确认当前 Heater 状态下允许执行本流程")

; 取点向导的 4 句提示（只悬停，不点击设备）
WizardPrompts := []
WizardPrompts.Push("第 1 个点：起始页右侧竖排工具栏第 3 个「SETUP」扳手锤子图标`n把鼠标停在图标正中间。")
WizardPrompts.Push("第 2 个点：先手动点一下 SETUP 进入 Setup 树页（只切页面，不动设备）`n再把鼠标停在「Right Bond Stage」这一行文字中间。")
WizardPrompts.Push("第 3 个点：手动点 Right Bond Stage 打开子窗口`n把鼠标停在 Operations 区右下部「Standby」按钮正中间。")
WizardPrompts.Push("第 4 个点：同一个子窗口里，Status 区第 1 行 Vacuum 的「Toggle」按钮`n把鼠标停在它正中间。")

; win = 本步目标窗口标题；x y = 相对该窗口左上角的坐标；wait = 点完等多少毫秒
; 下面 4 行的坐标是按 PPT 拍屏照片估的占位值，F12 取点后会被 calib.ini 自动覆盖。
; <<<STEPS_START>>>
Steps := []
Steps.Push({name:"打开 Setup 页面", win:"Auto Bond", x:515, y:222, wait:800, check:""})
Steps.Push({name:"进入 Right Bond Stage", win:"Auto Bond", x:105, y:215, wait:900, check:""})
Steps.Push({name:"Standby 回待机位", win:"Right Bond Stage", x:410, y:440, wait:1500, check:""})
Steps.Push({name:"Vacuum Toggle 释放真空", win:"Right Bond Stage", x:285, y:155, wait:1000, check:""})
; <<<STEPS_END>>>

; ---------------------------------------------- ② 以下一般不用改
Running      := 0
Abort        := 0
Calibrated   := 0
DryRun       := 0
WizardActive := 0
WizardIdx    := 0
WizardData   := []
CurHwnd      := 0
Total        := Steps.MaxIndex()

LoadCalibration()

FileAppend, , %LogFile%
if (ErrorLevel)
    LogFile := A_Temp "\OneKeyUnload_log.txt"

Gui, +AlwaysOnTop
Gui, Font, s9, Microsoft YaHei
Gui, Add, Text, x14 y10 w300, 流程：PPT 第 1~4 页 · 共 %Total% 步 · 跨 2 个窗口
Gui, Add, Text, x14 y30 w300 cGray vCalibState, 正在读取取点结果…
Gui, Add, Button, x14 y52 w300 h48 gStartRun vRunBtn, 一键退出基板 (F9)
Gui, Add, Button, x14 y106 w145 h26 gStopRun, 中止 (Esc)
Gui, Add, Button, x167 y106 w147 h26 gStartWizard, 取点向导 (F12)
Gui, Add, CheckBox, x14 y140 w300 h20 vDryRunChk, 空跑（只打印，不点设备，可不取点）
Gui, Add, Progress, x14 y166 w300 h12 cBlue vBar, 0
Gui, Add, Text, x14 y184 w300 h42 vStatus, 待机

Gui, Add, GroupBox, x14 y232 w300 h190, 等待时间（点完本步后等几秒 · 现场可调）
Gui, Add, Text, x26 y256 w140, ① Setup 之后
Gui, Add, Edit, x176 y253 w60 vWaitSec1, 0.8
Gui, Add, Text, x242 y256 w60, 秒
Gui, Add, Text, x26 y282 w140, ② 树项之后
Gui, Add, Edit, x176 y279 w60 vWaitSec2, 0.9
Gui, Add, Text, x242 y282 w60, 秒
Gui, Add, Text, x26 y308 w140, ③ Standby 之后
Gui, Add, Edit, x176 y305 w60 vWaitSec3, 1.5
Gui, Add, Text, x242 y308 w60, 秒
Gui, Add, Text, x26 y334 w140, ④ Toggle 之后
Gui, Add, Edit, x176 y331 w60 vWaitSec4, 1.0
Gui, Add, Text, x242 y334 w60, 秒
Gui, Add, Text, x26 y362 w140, 全局倍率（放慢用）
Gui, Add, Edit, x176 y359 w60 vWaitScaleEdit, 1.0
Gui, Add, Button, x26 y390 w130 h26 gSaveWait, 保存等待设置
Gui, Add, Button, x164 y390 w136 h26 gPresetWait, 全部设为 2.0 秒

Gui, Add, Text, x14 y430 w300 h36 cGray, F9 执行 · F12 取点向导 · F10/F11 补取 · F8 窗口自检 · Esc 中止
Gui, Show, x30 y30 w328 h478, 一键退出基板 · 辅助工具 v3
SyncWaitControls()
UpdateCalibState()
Log("工具已启动，共 " Total " 步；取点状态：" (Calibrated ? "已取点" : "未取点") "；等待倍率：" WaitScale)
return

; ---------------- 热键 ----------------
F9::  Gosub, StartRun
F12::
    if (WizardActive)
        RecordWizardPoint()
    else
        StartWizard()
return
F10:: Gosub, CalibrateMain
F11:: Gosub, CalibrateStage
F8::  Gosub, ShowWindowInfo

Esc::
    if (WizardActive) {
        CancelWizard()
        return
    }
    if (Running) {
        Abort := 1
        Log("用户请求中止 (Esc)")
        SetStatus("收到中止请求，当前步骤结束后停止")
    }
return

; ---------------- 执行 ----------------
StartRun:
    if (Running) {
        ; 外接实体按钮时连按很常见：绝不弹窗打断正在跑的步骤，静默忽略 + 短提示音
        SoundBeep, 400, 60
        Log("忽略一次重复触发（当前正在执行中，未打断）")
        return
    }
    GuiControlGet, dr, , DryRunChk
    DryRun := dr
    if (!Calibrated && !DryRun) {
        MsgBox, 16, 尚未取点, 还没做过现场取点，坐标仍是照片估算值，已禁止真实执行。`n`n请先按 F12 走一遍 4 步取点向导（只悬停、不点设备），完成后本按钮自动解锁。`n`n只想看看流程：勾选「空跑」再按 F9。
        return
    }
    if (RequireConfirm && !DryRun) {
        txt := "即将按顺序执行 " Total " 步「退出基板」：`n"
        for i, s in Steps
            txt .= "`n  " i ". " s.name "   [" s.win "]"
        txt .= "`n`n等待时间(秒)："
        for i, s in Steps
            txt .= Round(s.wait/1000,1) " / "
        txt .= "   倍率 x" WaitScale
        txt .= "`n`n请逐条确认："
        for i, c in Checklist
            txt .= "`n  □ " c
        txt .= "`n`n执行中请勿移动鼠标；按 Esc 可随时中止。"
        MsgBox, 292, 确认执行, %txt%
        IfMsgBox, No
            return
    }
    Running := 1
    Abort := 0
    GuiControl,, Bar, 0
    Log("===== 开始执行 =====" (DryRun ? "（空跑，不发送点击）" : "") " 倍率 x" WaitScale)
    for i, s in Steps {
        if (Abort) {
            Log("已中止，剩余步骤未执行")
            break
        }
        if (!PrepareWindow(s.win, s.wclass))
            break
        SetStatus("第 " i " / " Total " 步：" s.name)
        GuiControl,, Bar, % Round((i-1) * 100 / Total)
        if (!ClickAt(s.x, s.y, s.name))
            break
        if (s.check != "") {
            WinGetText, wtxt, ahk_id %CurHwnd%
            if !InStr(wtxt, s.check) {
                Log("状态校验失败：未找到「" s.check "」→ 中止")
                SetStatus("状态校验失败，已中止")
                Abort := 1
                break
            }
            Log("状态校验通过：" s.check)
        }
        if (!SafeSleep(s.wait))
            break
        GuiControl,, Bar, % Round(i * 100 / Total)
    }
    if (!Abort)
        Log("===== 执行结束，请人工核对设备状态 =====")
    Running := 0
    if (Abort)
        SetStatus("已中止（部分步骤未执行）")
    else
        SetStatus("执行结束，请核对设备状态")
    SoundBeep, 750, 120
return

StopRun:
    if (Running) {
        Abort := 1
        Log("点击了「中止」按钮")
        SetStatus("收到中止请求")
    }
return

; ---------------- 等待时间：面板可调 + 存盘 ----------------
SaveWait:
    vals := []
    Loop, %Total% {
        GuiControlGet, v, , % "WaitSec" . A_Index
        if v is not number
            v := 1.0
        if (v < 0)
            v := 0
        vals.Push(v)
        Steps[A_Index].wait := Round(v * 1000)
        IniWrite, % Steps[A_Index].wait, %CalibFile%, Wait, W%A_Index%
    }
    GuiControlGet, sc, , WaitScaleEdit
    if sc is not number
        sc := 1.0
    if (sc <= 0)
        sc := 1.0
    WaitScale := sc
    IniWrite, %WaitScale%, %CalibFile%, Wait, Scale
    SyncWaitControls()
    SetStatus("等待时间已保存到 calib.ini，下次启动自动沿用")
    Log("等待设置已保存：4 步 = " Round(vals[1],1) "/" Round(vals[2],1) "/" Round(vals[3],1) "/" Round(vals[4],1) " 秒，倍率 x" WaitScale)
return

PresetWait:
    Loop, %Total%
        GuiControl, , % "WaitSec" . A_Index, 2.0
    GuiControl, , WaitScaleEdit, 1.0
    SetStatus("已全部填 2.0 秒（保守起步），点「保存等待设置」生效")
return

SyncWaitControls() {
    global Steps, WaitScale, Total
    Loop, %Total%
        GuiControl, , % "WaitSec" . A_Index, % Round(Steps[A_Index].wait/1000, 1)
    GuiControl, , WaitScaleEdit, %WaitScale%
}

; ---------------- 取点向导（核心：怎么取点） ----------------
StartWizard:
    StartWizard()
return

StartWizard() {
    global WizardActive, WizardIdx, WizardData, Running, Total
    if (Running) {
        MsgBox, 48, 提示, 正在执行中，请先中止再取点。
        return
    }
    WizardActive := 1
    WizardIdx := 1
    WizardData := []
    Log("===== 开始 F12 取点向导 =====")
    ShowWizardTip()
}

ShowWizardTip() {
    global WizardIdx, WizardPrompts, Total, WizardActive
    if (!WizardActive)
        return
    p := WizardPrompts[WizardIdx]
    y := A_ScreenHeight - 190
    ToolTip, % "【取点向导 " WizardIdx " / " Total "】`n" p "`n`n鼠标停稳后按【F12】记录 · 按 Esc 退出`n注意：只悬停，不要点击设备按钮", 20, %y%
    SetStatus("取点 " WizardIdx " / " Total "：" p)
}

RecordWizardPoint() {
    global WizardActive, WizardIdx, WizardData, WizardPrompts, Total, CalibFile, ResultFile, Calibrated, Steps
    if (!WizardActive)
        return
    MouseGetPos, mx, my, hUnder
    if (!hUnder) {
        MsgBox, 48, 没读到窗口, 鼠标下面没找到窗口，请把鼠标移到设备软件上再按 F12。
        return
    }
    root := RootHwnd(hUnder)
    WinGetTitle, wt, ahk_id %root%
    WinGetClass, wc, ahk_id %root%
    WinGetPos, wx, wy, ww, wh, ahk_id %root%
    if (InStr(wt, "一键退出基板") || InStr(wt, "ToolTip")) {
        MsgBox, 48, 鼠标停错地方了, 鼠标正停在本工具自己的窗口上。`n请移到设备软件的按钮上，再按 F12。
        return
    }
    rx := mx - wx
    ry := my - wy
    if (rx < 0 || ry < 0 || rx > ww || ry > wh) {
        MsgBox, 48, 坐标异常, 算出来的相对坐标超出窗口范围，请重新悬停后按 F12。
        return
    }
    pt := {win:wt, wclass:wc, x:rx, y:ry, sx:mx, sy:my, wx:wx, wy:wy, ww:ww, wh:wh}
    WizardData.Push(pt)
    Log("取点 " WizardIdx "/" Total "：窗口标题[" wt "] 类名[" wc "] 相对(" rx ", " ry ") 屏幕(" mx ", " my ")")
    SoundBeep, 880, 90
    WizardIdx += 1
    if (WizardIdx > Total)
        FinishWizard()
    else
        ShowWizardTip()
}

FinishWizard() {
    global WizardActive, WizardData, Total, CalibFile, ResultFile, Calibrated, Steps
    IniWrite, 1, %CalibFile%, Calibration, Done
    IniWrite, %A_Now%, %CalibFile%, Calibration, Date
    IniWrite, %Total%, %CalibFile%, Calibration, Count
    txt := "一键退出基板 · 现场取点结果`n取点时间：" A_Now "`n"
    txt .= "说明：X / Y 是相对该窗口左上角的像素；窗口移动不用重取，分辨率或界面布局变了才要重取。`n`n"
    Loop, %Total% {
        d := WizardData[A_Index]
        IniWrite, % d.win, %CalibFile%, Step%A_Index%, Win
        IniWrite, % d.wclass, %CalibFile%, Step%A_Index%, Class
        IniWrite, % d.x, %CalibFile%, Step%A_Index%, X
        IniWrite, % d.y, %CalibFile%, Step%A_Index%, Y
        Steps[A_Index].win := d.win
        Steps[A_Index].wclass := d.wclass
        Steps[A_Index].x := d.x
        Steps[A_Index].y := d.y
        txt .= "第 " A_Index " 步  " Steps[A_Index].name "`n"
        txt .= "    窗口标题：" d.win "`n    窗口类名：" d.wclass "`n"
        txt .= "    相对坐标：X=" d.x "  Y=" d.y "`n"
        txt .= "    当时窗口：(" d.wx ", " d.wy ") 大小 " d.ww "x" d.wh " · 鼠标屏幕坐标 (" d.sx ", " d.sy ")`n`n"
    }
    txt .= "配置文件：" CalibFile "`n未取点时脚本锁住真实执行；此文件存在即表示已取点。`n"
    FileDelete, %ResultFile%
    FileAppend, %txt%, %ResultFile%
    Calibrated := 1
    WizardActive := 0
    ToolTip
    UpdateCalibState()
    SetStatus("取点完成，4 个点已保存；F9 已解锁，建议先勾选空跑验证")
    Log("===== 取点完成，结果已写入 " CalibFile " 与 " ResultFile " =====")
    MsgBox, 64, 取点完成, 4 个点已记录并保存。`n`n已自动写入：`n  OneKeyUnload_calib.ini（脚本启动时自动读取）`n  取点结果.txt（给人看的）`n`n接下来：勾选「空跑」按 F9 看一遍，再去维护模式 / 空片上试。
}

CancelWizard() {
    global WizardActive
    WizardActive := 0
    ToolTip
    SetStatus("取点向导已取消，原有坐标未改动")
    Log("取点向导已取消")
}

ShowWindowInfo:
    MouseGetPos, mx, my, hUnder
    if (!hUnder) {
        MsgBox, 48, 窗口自检, 鼠标下面没找到窗口。
        return
    }
    root := RootHwnd(hUnder)
    WinGetTitle, wt, ahk_id %root%
    WinGetClass, wc, ahk_id %root%
    WinGetPos, wx, wy, ww, wh, ahk_id %root%
    rx := mx - wx
    ry := my - wy
    MsgBox, 64, 窗口自检 (F8), 鼠标下窗口标题：%wt%`n窗口类名：%wc%`n窗口左上角：%wx%, %wy%`n窗口大小：%ww% x %wh%`n`n鼠标屏幕坐标：%mx%, %my%`n相对左上角：X=%rx%  Y=%ry%`n`n标题栏没拍到也没关系：取点向导会自动用这里读到的真实标题 / 类名定位。
return

CalibrateMain:
    DoCalibrate("主窗口")
return

CalibrateStage:
    DoCalibrate("子窗口")
return

DoCalibrate(hint) {
    MouseGetPos, mx, my, hUnder
    if (!hUnder) {
        MsgBox, 48, 补取失败, 鼠标下面没找到窗口。
        return
    }
    root := RootHwnd(hUnder)
    WinGetTitle, wt, ahk_id %root%
    WinGetClass, wc, ahk_id %root%
    WinGetPos, wx, wy, ww, wh, ahk_id %root%
    rx := mx - wx
    ry := my - wy
    q := Chr(34)
    clip := "Steps.Push({name:" . q . "按钮名称" . q . ", win:" . q . wt . q . ", x:" . rx . ", y:" . ry . ", wait:1000, check:" . q . q . "})"
    Clipboard := clip
    MsgBox, 64, 单点补取（%hint%）, 窗口标题：%wt%`n窗口类名：%wc%`n相对左上角：X=%rx%  Y=%ry%`n`n这一行配置已复制到剪贴板。`n只改某一步更推荐直接重跑 F12 向导。
}

; ---------------- 基础函数 ----------------
LoadCalibration() {
    global CalibFile, Calibrated, Steps, Total, WaitScale, RequireConfirm
    IniRead, done, %CalibFile%, Calibration, Done, 0
    if (done = 1) {
        Loop, %Total% {
            IniRead, w, %CalibFile%, Step%A_Index%, Win, % Steps[A_Index].win
            IniRead, c, %CalibFile%, Step%A_Index%, Class,
            IniRead, x, %CalibFile%, Step%A_Index%, X, % Steps[A_Index].x
            IniRead, y, %CalibFile%, Step%A_Index%, Y, % Steps[A_Index].y
            Steps[A_Index].win := w
            Steps[A_Index].wclass := c
            Steps[A_Index].x := x
            Steps[A_Index].y := y
        }
        Calibrated := 1
    }
    ; 二次确认开关：默认取脚本里的 RequireConfirm；现场可在 calib.ini 覆盖（见文件头说明）
    IniRead, cf, %CalibFile%, Options, Confirm, %RequireConfirm%
    if cf is number
        RequireConfirm := cf
    IniRead, sc, %CalibFile%, Wait, Scale, %WaitScale%
    if sc is number
        if (sc > 0)
            WaitScale := sc
    Loop, %Total% {
        IniRead, wms, %CalibFile%, Wait, W%A_Index%, % Steps[A_Index].wait
        if wms is number
            Steps[A_Index].wait := wms
    }
}

UpdateCalibState() {
    global Calibrated
    if (Calibrated)
        GuiControl,, CalibState, ● 已取点：坐标来自 calib.ini，可正常执行
    else
        GuiControl,, CalibState, ● 未取点：坐标是照片估算值，F9 已锁住（仅可空跑）
}

RootHwnd(h) {
    return DllCall("GetAncestor", "Ptr", h, "UInt", 2, "Ptr")
}

ResolveHwnd(win, wclass) {
    h := 0
    if (win != "")
        h := WinExist(win)
    if (!h && wclass != "")
        h := WinExist("ahk_class " . wclass)
    return h
}

PrepareWindow(win, wclass) {
    global Abort, CurHwnd
    h := ResolveHwnd(win, wclass)
    if (!h) {
        Log("错误：找不到窗口「" win "」/ 类名「" wclass "」→ 中止")
        SetStatus("找不到窗口，已中止")
        Abort := 1
        return 0
    }
    CurHwnd := h
    WinActivate, ahk_id %h%
    WinWaitActive, ahk_id %h%, , 2
    if (ErrorLevel) {
        Log("错误：窗口无法激活 → 中止")
        Abort := 1
        return 0
    }
    WinGetPos, wx, wy, ww, wh, ahk_id %h%
    Log("定位窗口「" win "」 左上角(" wx ", " wy ") 大小(" ww "x" wh ")")
    return 1
}

ClickAt(rx, ry, label) {
    global CurHwnd, DryRun
    WinGetPos, wx, wy, ww, wh, ahk_id %CurHwnd%
    tx := wx + rx
    ty := wy + ry
    if (DryRun) {
        Log("[空跑] 本应点击「" label "」 屏幕(" tx ", " ty ") 相对(" rx ", " ry ")")
        Sleep, 100
        return 1
    }
    MouseClick, Left, %tx%, %ty%, 1, 0
    Log("点击「" label "」 屏幕(" tx ", " ty ") 相对(" rx ", " ry ")")
    Sleep, 120
    return 1
}

SafeSleep(ms) {
    global Abort, WaitScale
    ms := Round(ms * WaitScale)
    left := ms
    while (left > 0) {
        if (Abort)
            return 0
        Sleep, 100
        left -= 100
    }
    Log("等待 " ms " ms 完成（倍率 x" WaitScale "）")
    return 1
}

Log(msg) {
    global LogFile
    FormatTime, ts, , yyyy-MM-dd HH:mm:ss
    line := "[" . ts . "] " . msg . Chr(10)
    FileAppend, %line%, %LogFile%
}

SetStatus(msg) {
    GuiControl,, Status, %msg%
}

GuiClose:
    if (Running) {
        MsgBox, 48, 提示, 正在执行中，请先中止再关闭。
        return
    }
    ExitApp
return

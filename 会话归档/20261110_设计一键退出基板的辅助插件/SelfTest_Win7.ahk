; ================================================================
;  EXE 自检小程序
;  只做两件事：弹一个框、写一个 txt。
;  不读取设备窗口、不发送任何鼠标点击、不按任何热键。
;  用途：判断「exe 能不能在这台电脑上跑起来」。
; ================================================================
#NoEnv
#SingleInstance Force
FileEncoding, UTF-8

out := A_ScriptDir "\SelfTest_result.txt"
txt := "EXE 自检结果`n"
txt .= "================================`n"
txt .= "结果：EXE 已在这台电脑上成功运行`n"
txt .= "系统版本：" A_OSVersion "`n"
txt .= "程序位数：" (A_PtrSize = 8 ? "64 位" : "32 位") "`n"
txt .= "程序路径：" A_ScriptFullPath "`n"
txt .= "所在目录：" A_ScriptDir "`n"
txt .= "运行时间：" A_Now "`n"
txt .= "================================`n"
txt .= "能看到这个框、或找到这个 txt，说明 exe 运行没问题。`n"

FileDelete, %out%
FileAppend, %txt%, %out%
MsgBox, 64, EXE 自检成功, %txt%`n请把 SelfTest_result.txt 带回去。
ExitApp

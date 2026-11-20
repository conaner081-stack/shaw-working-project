@echo off
REM ================================================================
REM  Rebuild all 5 EXE files from the .ahk sources.
REM
REM  When do you need this?
REM    ONLY after editing OneKeyUnload.ahk (step names / step order /
REM    default values / hotkeys) or SelfTest_Win7.ahk.
REM    You do NOT need it for:
REM      - wait times  (change them in the tool panel, press Save)
REM      - coordinates (press F12 in the tool, saved to calib.ini)
REM
REM  Close the running tool before rebuilding.
REM  Keep the whole ahk_compiler folder next to this BAT.
REM ================================================================
cd /d "%~dp0"
set "NEW=%~dp0ahk_compiler\Ahk2Exe.exe"
set "OLD30=%~dp0ahk_compiler\legacy_1.1.30.03\Ahk2Exe.exe"
set "OLD33=%~dp0ahk_compiler\legacy_1.1.33.10\Ahk2Exe.exe"
set "BIN64=%~dp0ahk_compiler\Unicode 64-bit.bin"
set "BIN32=%~dp0ahk_compiler\Unicode 32-bit.bin"
set "BIN30=%~dp0ahk_compiler\legacy_1.1.30.03\Unicode 32-bit.bin"
set "BIN33=%~dp0ahk_compiler\legacy_1.1.33.10\Unicode 32-bit.bin"

if not exist "%NEW%" goto :missing
if not exist "%~dp0OneKeyUnload.ahk" goto :noscript
if not exist "%~dp0SelfTest_Win7.ahk" goto :noscript

echo [1/5] OneKeyUnload.exe           AHK 1.1.37.02 / x64
"%NEW%" /in "%~dp0OneKeyUnload.ahk" /out "%~dp0OneKeyUnload.exe" /bin "%BIN64%" /mpress 0 /silent
echo [2/5] OneKeyUnload_x86.exe       AHK 1.1.37.02 / x86
"%NEW%" /in "%~dp0OneKeyUnload.ahk" /out "%~dp0OneKeyUnload_x86.exe" /bin "%BIN32%" /mpress 0 /silent
echo [3/5] OneKeyUnload_Win7.exe      AHK 1.1.30.03 / x86   (Win7 main)
"%OLD30%" /in "%~dp0OneKeyUnload.ahk" /out "%~dp0OneKeyUnload_Win7.exe" /bin "%BIN30%" /mpress 0
echo [4/5] OneKeyUnload_Win7_alt.exe  AHK 1.1.30.03 / x86   (same runtime as main)
"%OLD30%" /in "%~dp0OneKeyUnload.ahk" /out "%~dp0OneKeyUnload_Win7_alt.exe" /bin "%BIN30%" /mpress 0
echo [5/5] SelfTest_Win7.exe          AHK 1.1.30.03 / x86   (diagnostic)
"%OLD30%" /in "%~dp0SelfTest_Win7.ahk" /out "%~dp0SelfTest_Win7.exe" /bin "%BIN30%" /mpress 0
echo.
echo Done. All 5 EXE files refreshed.
goto :end

:missing
echo ERROR: ahk_compiler folder is incomplete. Keep it next to this BAT.
goto :end
:noscript
echo ERROR: OneKeyUnload.ahk or SelfTest_Win7.ahk not found next to this BAT.
goto :end

:end
echo.
pause

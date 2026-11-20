@echo off
rem Find a usable git.exe and add its folder to PATH for this script session.
rem Covers: git already on PATH, WorkBuddy portable Git, standard Git installations.

where git >nul 2>&1
if not errorlevel 1 exit /b 0

set "GITDIR="

rem WorkBuddy portable Git (pick the newest version folder)
for /d %%D in ("%USERPROFILE%\.workbuddy\binaries\PortableGit\versions\*") do (
  if exist "%%D\cmd\git.exe" set "GITDIR=%%D\cmd"
)

rem Standard Git for Windows
if not defined GITDIR if exist "%ProgramFiles%\Git\cmd\git.exe" set "GITDIR=%ProgramFiles%\Git\cmd"
if not defined GITDIR if exist "%ProgramFiles(x86)%\Git\cmd\git.exe" set "GITDIR=%ProgramFiles(x86)%\Git\cmd"
if not defined GITDIR if exist "%LOCALAPPDATA%\Programs\Git\cmd\git.exe" set "GITDIR=%LOCALAPPDATA%\Programs\Git\cmd"

if defined GITDIR (
  set "PATH=%GITDIR%;%PATH%"
  exit /b 0
)

exit /b 1

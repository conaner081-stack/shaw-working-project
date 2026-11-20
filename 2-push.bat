@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

call "%~dp0_git-path.bat"
if errorlevel 1 (
  echo [ERROR] Git not found. Install Git for Windows, or start WorkBuddy once
  echo         so its portable Git is available, then run this again.
  pause
  exit /b 1
)

echo ============================================
echo  2 - Commit and push current project
echo ============================================
echo.

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo [ERROR] Not a git repository.
  pause
  exit /b 1
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
  echo [ERROR] No remote configured. Run 1-setup-remote.bat first.
  pause
  exit /b 1
)

echo Pulling latest first to avoid conflicts...
git pull --rebase origin main
if errorlevel 1 (
  echo.
  echo [STOP] Pull failed or conflicts found. Resolve them before pushing.
  pause
  exit /b 1
)

git add -A
git status --porcelain
echo.

git diff --cached --quiet
if errorlevel 1 (
  set "MSG="
  set /p MSG="Commit message (press Enter for default): "
  if "!MSG!"=="" set "MSG=Auto sync %date% %time%"
  git commit -m "!MSG!"
) else (
  echo No local changes to commit.
)

git push origin main
if errorlevel 1 (
  echo.
  echo [ERROR] Push failed. Check network or repo permissions.
  pause
  exit /b 1
)

echo.
echo [OK] Uploaded. Safe to shut down.
pause

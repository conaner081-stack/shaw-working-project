@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo  3 - Pull latest project from remote
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
  echo [ERROR] No remote configured. On this PC, clone the repo first.
  pause
  exit /b 1
)

git status --porcelain
echo.
set /p CONFIRM="Pull now? Uncommitted local changes may conflict. [Y/N]: "
if /I not "%CONFIRM%"=="Y" (
  echo Cancelled.
  pause
  exit /b 0
)

git pull --rebase origin main
if errorlevel 1 (
  echo.
  echo [ERROR] Pull failed. Resolve conflicts, or run 2-push.bat on the other PC first.
  pause
  exit /b 1
)

echo.
echo [OK] Up to date. Ready to work.
pause

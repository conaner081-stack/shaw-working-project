@echo off
setlocal
cd /d "%~dp0"

echo ============================================
echo  1 - Setup remote repository
echo ============================================
echo.

set "URL="
set /p URL="Paste your Gitee/GitHub repo URL: "
if "%URL%"=="" (
  echo [ERROR] URL is empty.
  pause
  exit /b 1
)

git remote remove origin 2>nul
git remote add origin %URL%
git branch -M main

echo.
echo Remote added: %URL%
echo Uploading initial commit...
git push -u origin main
if errorlevel 1 (
  echo.
  echo [ERROR] Push failed. Check the URL, network, and repo permissions.
  pause
  exit /b 1
)

echo.
echo [OK] Setup finished.
echo On office PC: run 2-push.bat before leaving.
echo On home PC:   run 3-pull.bat before starting.
pause

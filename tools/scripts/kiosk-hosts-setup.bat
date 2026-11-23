@echo off
echo === KTITS-INFO kiosk setup ===
echo.
findstr /C:"10.0.1.190 ktits-info" C:\Windows\System32\drivers\etc\hosts >nul
if %errorlevel%==0 (
  echo Hosts entry already present.
) else (
  echo 10.0.1.190 ktits-info >> C:\Windows\System32\drivers\etc\hosts
  if errorlevel 1 (
    echo [ERROR] Please run as administrator.
    pause
    exit /b 1
  )
  echo Hosts entry added.
)
echo.
echo Open in browser:  http://ktits-info/
echo Kiosk mode:       chrome.exe --kiosk http://ktits-info/
pause

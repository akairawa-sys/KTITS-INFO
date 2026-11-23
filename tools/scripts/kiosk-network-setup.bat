@echo off
echo === KTITS-INFO kiosk network setup ===
echo.
netsh interface portproxy delete v4tov4 listenaddress=10.0.1.190 listenport=80 >nul 2>&1
netsh interface portproxy add v4tov4 listenaddress=10.0.1.190 listenport=80 connectaddress=127.0.0.1 connectport=80
if errorlevel 1 (
  echo [ERROR] Please run as administrator:
  echo   right-click -^> "Run as administrator"
  pause
  exit /b 1
)
echo Port forward added:  10.0.1.190:80  -^>  127.0.0.1:80
echo.
echo Current rules:
netsh interface portproxy show all
echo.
echo Done. Now run kiosk-hosts-setup.bat on each kiosk.
pause

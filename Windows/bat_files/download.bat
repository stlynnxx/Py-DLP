@echo off
setlocal
title dwnloaderr Download

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0download-gui.ps1" %*
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo   Something went wrong ^(exit code %RC%^).
    echo.
    pause
)

endlocal & exit /b %RC%
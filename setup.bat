@echo off
setlocal
title Py-DLP Setup

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
set "RC=%ERRORLEVEL%"

if not "%RC%"=="0" (
    echo.
    echo   Setup did not finish successfully ^(exit code %RC%^).
    echo.
    pause
)

endlocal & exit /b %RC%
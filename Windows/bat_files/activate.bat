@echo off
setlocal
title Py-DLP Console
cd /d "%~dp0"

if not exist ".venv\Scripts\activate.bat" (
    echo.
    echo   No virtual environment found.
    echo   Run setup.bat first.
    echo.
    pause
    exit /b 1
)

call ".venv\Scripts\activate.bat"

echo.
echo   ====================================
echo     Py-DLP Console
echo   ====================================
echo.
echo   The virtual environment is active.
echo.
echo   Examples:
echo.
echo     python py-dlp.py -single "https://youtube.com/watch?v=VIDEO_ID"
echo     python py-dlp.py -single "URL" -format mp3
echo     python py-dlp.py -playlist "URL" -max 50
echo     python py-dlp.py --help
echo.
echo   Type "exit" to close this window.
echo.

cmd /k
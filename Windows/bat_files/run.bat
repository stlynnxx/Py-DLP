@echo off
setlocal EnableExtensions EnableDelayedExpansion
title dwnloaderr

rem ---------------------------------------------------------------- WSL probe
set "HAVE_WSL=0"

where wsl >nul 2>&1 || goto :Native
wsl --status >nul 2>&1 || goto :Native
if not exist "%~dp0download.sh" goto :Native
set "HAVE_WSL=1"

rem ------------------------------------------------------------- Offer choice
cls
echo.
echo   dwnloaderr
echo   ======
echo.
echo   This project can run in two places:
echo.
echo     [1] Windows  ^(recommended^)
echo     [2] WSL      ^(Linux subsystem^)
echo.
set "CHOICE="
set /p "CHOICE=  Choose [1/2, Enter = 1]: "

if "!CHOICE!"=="2" goto :WSL

:Native
call "%~dp0download.bat"
goto :End

:WSL
echo.
echo   Launching inside WSL...
echo.
rem Map the Windows path to its WSL equivalent
set "WSLDIR="
for /f "usebackq delims=" %%i in (`wsl wslpath -a "%~dp0." 2^>nul`) do set "WSLDIR=%%i"
if not defined WSLDIR (
    echo   Could not resolve the WSL path. Falling back to Windows.
    echo.
    call "%~dp0download.bat"
    goto :End
)
wsl bash -lc "cd '!WSLDIR!' && ./download.sh"
goto :End

:End
endlocal
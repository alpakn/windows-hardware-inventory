@echo off
title Donanim Envanter Baslatici
mode con: cols=90 lines=40

:: Both files must be in the same folder.
set "PS1_PATH=%~dp0Envanter.ps1"

if not exist "%PS1_PATH%" (
    echo.
    echo [HATA] Envanter.ps1 bulunamadi!
    echo Beklenen konum: %PS1_PATH%
    echo Lutfen her iki dosyanin ayni klasorde oldugunu kontrol edin.
    echo.
    pause
    exit /b 1
)

:: Run with execution policy bypass — no GPO or signing required
powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText('%PS1_PATH%')))"

if %errorlevel% neq 0 (
    echo.
    echo [HATA] PowerShell bir hatayla sonlandi. Kod: %errorlevel%
    echo.
)
pause

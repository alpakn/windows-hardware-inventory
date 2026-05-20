@echo off
title Sistem Donanim Paneli
mode con: cols=110 lines=45

:: Both files must be in the same folder.
:: %~dp0 automatically points to the folder this bat file is in.
set "PS1_PATH=%~dp0sistem-bilgi.ps1"

if not exist "%PS1_PATH%" (
    echo.
    echo [HATA] sistem-bilgi.ps1 bulunamadi!
    echo Beklenen konum: %PS1_PATH%
    echo Lutfen her iki dosyanin ayni klasorde oldugunu kontrol edin.
    echo.
    pause
    exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& ([scriptblock]::Create([System.IO.File]::ReadAllText('%PS1_PATH%')))"

if %errorlevel% neq 0 (
    echo.
    echo [HATA] PowerShell bir hatayla sonlandi. Kod: %errorlevel%
    echo.
    pause
)

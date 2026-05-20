# ============================================================
# sistem-bilgi.ps1
# Displays detailed hardware information for the local machine.
# Requires: Windows PowerShell 5.1+ / PowerShell 7+
# ============================================================

# ── Header ───────────────────────────────────────────────────
Write-Host ''
Write-Host '========================================================================================' -F DarkCyan
Write-Host '                        SISTEM DONANIM BILGILERI                                       ' -F White -B DarkBlue
Write-Host '========================================================================================' -F DarkCyan
Write-Host ''

# ── Motherboard ──────────────────────────────────────────────
Write-Host '[+] ANAKART' -F Cyan
Get-CimInstance Win32_BaseBoard | ForEach-Object {
    Write-Host ('    Marka  : ' + $_.Manufacturer)
    Write-Host ('    Model  : ' + $_.Product)
}
Write-Host ''

# ── BIOS ─────────────────────────────────────────────────────
Write-Host '[+] BIOS' -F Magenta
Get-CimInstance Win32_BIOS | ForEach-Object {
    Write-Host ('    Surum  : ' + $_.SMBIOSBIOSVersion)
    Write-Host ('    Tarih  : ' + $_.ReleaseDate.ToString('dd.MM.yyyy'))
}
Write-Host ''

# ── Operating System ─────────────────────────────────────────
Write-Host '[+] ISLETIM SISTEMI' -F Yellow
Get-CimInstance Win32_OperatingSystem | ForEach-Object {
    Write-Host ('    Surum  : ' + $_.Caption)
    Write-Host ('    Build  : ' + $_.BuildNumber)
    Write-Host ('    Mimari : ' + $_.OSArchitecture)
}
Write-Host ''

# ── IP Address ───────────────────────────────────────────────
Write-Host '[+] AG BILGISI' -F DarkCyan
Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.InterfaceAlias -notlike '*Loopback*' -and $_.IPAddress -ne '127.0.0.1' } |
    ForEach-Object {
        Write-Host ('    Arayuz : ' + $_.InterfaceAlias)
        Write-Host ('    IP     : ' + $_.IPAddress)
    }
Write-Host ''

# ── CPU ──────────────────────────────────────────────────────
Write-Host '[+] ISLEMCI (CPU)' -F Green
Get-CimInstance Win32_Processor | ForEach-Object {
    Write-Host ('    Ad      : ' + $_.Name)
    Write-Host ('    Cekirdek: ' + $_.NumberOfCores + ' Cekirdek / ' + $_.NumberOfLogicalProcessors + ' Mantiksal')
}
Write-Host ''

# ── GPU ──────────────────────────────────────────────────────
Write-Host '[+] EKRAN KARTI (GPU)' -F DarkYellow
Get-CimInstance Win32_VideoController | ForEach-Object {
    Write-Host ('    Model  : ' + $_.Name)
}
Write-Host ''

# ── RAM ──────────────────────────────────────────────────────
Write-Host '[+] BELLEK (RAM)' -F DarkMagenta
Get-CimInstance Win32_PhysicalMemory | ForEach-Object {
    Write-Host ('    Slot   : ' + [Math]::Round($_.Capacity / 1GB, 0) + ' GB | Hiz: ' + $_.Speed + ' MHz | Model: ' + $_.PartNumber.Trim())
}
Write-Host ''

# ── Disk ─────────────────────────────────────────────────────
Write-Host '[+] DEPOLAMA (DISK)' -F Red
Get-CimInstance Win32_DiskDrive | ForEach-Object {
    Write-Host ('    Surucu : ' + $_.Model + ' (' + [Math]::Round($_.Size / 1GB, 0) + ' GB)')
}
Write-Host ''

# ── Monitor ──────────────────────────────────────────────────
Write-Host '[+] MONITOR(LER)' -F White
$Monitors = Get-CimInstance Win32_PnPEntity | Where-Object { $_.Service -eq 'monitor' }
if ($Monitors) {
    $Monitors | ForEach-Object { Write-Host ('    Cihaz  : ' + $_.Name) }
} else {
    Write-Host '    Bulunamadi veya surucusu yuklenmemis.' -F DarkGray
}
Write-Host ''

# ── Footer ───────────────────────────────────────────────────
Write-Host '========================================================================================' -F DarkCyan
Write-Host (' Islem Tamamlandi  |  ' + (Get-Date -Format 'dd.MM.yyyy HH:mm:ss')) -F DarkGray
Write-Host '========================================================================================' -F DarkCyan
Write-Host ''

Read-Host 'Cikis icin Enter tusuna basin'

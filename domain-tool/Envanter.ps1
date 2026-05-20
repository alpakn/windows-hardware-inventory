# ============================================================
# Envanter.ps1
# Collects hardware inventory from Active Directory computers
# via WinRM and exports results to CSV + GridView.
#
# Requirements:
#   - Run as Domain Admin (or delegated WinRM + CIM rights)
#   - WinRM must be enabled on target machines
#   - ActiveDirectory PowerShell module (RSAT) must be installed
#   - PowerShell 5.1+
# ============================================================

# ── Configuration ────────────────────────────────────────────
# Output file path — saved to the desktop of the running user
$DesktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop", "Envanter.csv")

# ── TARGET SELECTION — uncomment only ONE option ──────────────

# OPTION 1 — All enabled computers in a specific OU:
$TargetOU  = "OU=YOUR-OU,DC=your-domain,DC=com"
$Computers = Get-ADComputer -Filter 'Enabled -eq $true' -SearchBase $TargetOU |
             Select-Object -ExpandProperty Name | Sort-Object

# OPTION 2 — Single computer by name:
# $Computers = @("PC-NAME-HERE")

# OPTION 3 — Multiple specific computers:
# $Computers = @("PC-NAME-1", "PC-NAME-2", "PC-NAME-3")

# OPTION 4 — All enabled computers in the entire domain:
# $Computers = Get-ADComputer -Filter 'Enabled -eq $true' |
#              Select-Object -ExpandProperty Name | Sort-Object

# ─────────────────────────────────────────────────────────────

# ── Module Check ─────────────────────────────────────────────
if (-not (Get-Module -ListAvailable -Name ActiveDirectory)) {
    Write-Host "[ERROR] ActiveDirectory module not found. Please install RSAT." -ForegroundColor Red
    exit 1
}
Import-Module ActiveDirectory

# ── Start ────────────────────────────────────────────────────
Write-Host ""
Write-Host "Inventory query started, please wait..." -ForegroundColor Cyan
Write-Host ""

$Total     = $Computers.Count
$Current   = 0
$FinalList = New-Object System.Collections.Generic.List[PSObject]

# ── Loop Through Each Computer ────────────────────────────────
foreach ($Computer in $Computers) {
    $Current++
    Write-Host ("[$Current/$Total] Processing: $Computer") -ForegroundColor DarkGray

    # ── Ping Check ───────────────────────────────────────────
    if (-not (Test-Connection -ComputerName $Computer -Count 1 -Quiet)) {
        Write-Host "  -> Offline" -ForegroundColor DarkYellow
        $FinalList.Add([PSCustomObject]@{
            'Computer Name'   = $Computer
            'Status'          = "Offline"
            'Motherboard'     = ""; 'BIOS Version'    = ""
            'Operating System'= ""; 'OS Build'        = ""
            'IP Address'      = ""; 'Processor'       = ""
            'GPU'             = ""; 'Total RAM (GB)'  = ""
            'RAM Model'       = ""; 'Disk Model'      = ""
            'Monitor'         = ""
        })
        continue
    }

    # ── Remote Data Collection via WinRM ─────────────────────
    try {
        $Data = Invoke-Command -ComputerName $Computer -ErrorAction Stop -ScriptBlock {

            # Motherboard
            $Board = Get-CimInstance Win32_BaseBoard

            # BIOS
            $BIOS  = Get-CimInstance Win32_BIOS

            # Operating System
            $OS    = Get-CimInstance Win32_OperatingSystem

            # CPU
            $CPU   = Get-CimInstance Win32_Processor

            # GPU — enrich with PnP manufacturer info
            $GPU   = Get-CimInstance Win32_VideoController
            $GPU_Names = foreach ($g in $GPU) {
                try {
                    $pnp   = Get-PnpDevice -InstanceId $g.PNPDeviceID -ErrorAction Stop
                    $brand = if ($pnp.Manufacturer -and $pnp.Manufacturer -notlike "*Microsoft*") {
                                 $pnp.Manufacturer
                             } else {
                                 $g.AdapterCompatibility
                             }
                    "$($g.Name) [$brand]"
                } catch {
                    $g.Name
                }
            }

            # RAM
            $RAM         = Get-CimInstance Win32_PhysicalMemory
            $RAM_Details = ($RAM.PartNumber | ForEach-Object { $_.Trim() }) -join " / "
            $RAM_Total   = [Math]::Round(($RAM.Capacity | Measure-Object -Sum).Sum / 1GB, 0)

            # Disk
            $Disk = Get-CimInstance Win32_DiskDrive

            # Monitor
            $Mon  = Get-CimInstance Win32_PnPEntity |
                    Where-Object { $_.Service -eq 'monitor' }

            # IP — active IPv4, exclude loopback
            $IPs  = Get-NetIPAddress -AddressFamily IPv4 |
                    Where-Object { $_.InterfaceAlias -notlike '*Loopback*' -and $_.IPAddress -ne '127.0.0.1' } |
                    Select-Object -ExpandProperty IPAddress

            return [PSCustomObject]@{
                Motherboard      = "$($Board.Manufacturer) $($Board.Product)"
                BIOS_Version     = $BIOS.SMBIOSBIOSVersion
                OperatingSystem  = $OS.Caption
                OS_Build         = $OS.BuildNumber
                IP_Address       = ($IPs -join " / ")
                Processor        = $CPU.Name
                GPU              = ($GPU_Names -join " / ")
                Total_RAM_GB     = $RAM_Total
                RAM_Model        = $RAM_Details
                Disk_Model       = ($Disk.Model -join " | ")
                Monitor          = ($Mon.Name -join " / ")
            }
        }

        Write-Host "  -> Success" -ForegroundColor Green

        $FinalList.Add([PSCustomObject]@{
            'Computer Name'    = $Computer
            'Status'           = "Success"
            'Motherboard'      = $Data.Motherboard
            'BIOS Version'     = $Data.BIOS_Version
            'Operating System' = $Data.OperatingSystem
            'OS Build'         = $Data.OS_Build
            'IP Address'       = $Data.IP_Address
            'Processor'        = $Data.Processor
            'GPU'              = $Data.GPU
            'Total RAM (GB)'   = $Data.Total_RAM_GB
            'RAM Model'        = $Data.RAM_Model
            'Disk Model'       = $Data.Disk_Model
            'Monitor'          = $Data.Monitor
        })

    # ── Error Handling ────────────────────────────────────────
    } catch [System.Management.Automation.Remoting.PSRemotingTransportException] {
        # WinRM is closed or unreachable
        Write-Host "  -> Error: WinRM unreachable" -ForegroundColor Red
        $FinalList.Add([PSCustomObject]@{
            'Computer Name'    = $Computer; 'Status' = "Error: WinRM Unreachable"
            'Motherboard'      = ""; 'BIOS Version'     = ""
            'Operating System' = ""; 'OS Build'         = ""
            'IP Address'       = ""; 'Processor'        = ""
            'GPU'              = ""; 'Total RAM (GB)'   = ""
            'RAM Model'        = ""; 'Disk Model'       = ""
            'Monitor'          = ""
        })
    } catch [System.UnauthorizedAccessException] {
        # Insufficient permissions
        Write-Host "  -> Error: Access denied" -ForegroundColor Red
        $FinalList.Add([PSCustomObject]@{
            'Computer Name'    = $Computer; 'Status' = "Error: Access Denied"
            'Motherboard'      = ""; 'BIOS Version'     = ""
            'Operating System' = ""; 'OS Build'         = ""
            'IP Address'       = ""; 'Processor'        = ""
            'GPU'              = ""; 'Total RAM (GB)'   = ""
            'RAM Model'        = ""; 'Disk Model'       = ""
            'Monitor'          = ""
        })
    } catch {
        # General error — print actual message for easier debugging
        Write-Host ("  -> Error: " + $_.Exception.Message) -ForegroundColor Red
        $FinalList.Add([PSCustomObject]@{
            'Computer Name'    = $Computer; 'Status' = ("Error: " + $_.Exception.Message)
            'Motherboard'      = ""; 'BIOS Version'     = ""
            'Operating System' = ""; 'OS Build'         = ""
            'IP Address'       = ""; 'Processor'        = ""
            'GPU'              = ""; 'Total RAM (GB)'   = ""
            'RAM Model'        = ""; 'Disk Model'       = ""
            'Monitor'          = ""
        })
    }
}

# ── Export Results ────────────────────────────────────────────
$FinalList | Export-Csv -Path $DesktopPath -NoTypeInformation -Encoding UTF8 -Delimiter ";"
$FinalList | Out-GridView -Title "Hardware Inventory — $Total computer(s)"

# ── Summary ──────────────────────────────────────────────────
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
Write-Host ("Total    : $Total computer(s)") -ForegroundColor White
Write-Host ("Success  : " + ($FinalList | Where-Object { $_.Status -eq 'Success' }).Count) -ForegroundColor Green
Write-Host ("Offline  : " + ($FinalList | Where-Object { $_.Status -like '*Offline*' }).Count) -ForegroundColor Yellow
Write-Host ("Error    : " + ($FinalList | Where-Object { $_.Status -like 'Error*' }).Count) -ForegroundColor Red
Write-Host ""
Write-Host "Report saved to desktop: Envanter.csv" -ForegroundColor Cyan

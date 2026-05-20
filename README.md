<div align="center">

# 🖥️ Windows Hardware Inventory Tools

**TR** | [EN](#english)

</div>

---

### 💡 Ne İşe Yarar?

Donanım envanteri için kullanılan araçların büyük çoğunluğu ücretli. Ek bir yazılım kurmadan, yalnızca Windows'un yerleşik bileşenleri olan PowerShell, WinRM ve Active Directory kullanılarak domain ortamındaki makinelerin sistem bilgileri toplanabilir. Bu proje tam olarak bunu yapıyor.

---

### Nedir?

Bu proje iki araçtan oluşur:

**1. `local-tool/`** — Kendi bilgisayarının donanım bilgilerini renkli terminal arayüzüyle görüntüler.

**2. `domain-tool/`** — Active Directory ortamında, belirli bir OU'daki veya seçilen makinelerdeki tüm bilgisayarların donanım envanterini toplar ve CSV + GridView olarak çıktı verir.

---

### 📋 Gereksinimler

#### Local Tool
- Windows 10/11
- PowerShell 5.1+

#### Domain Tool
- Windows 10/11 (domain'e bağlı)
- PowerShell 5.1+
- Domain Admin yetkisi (veya WinRM + CIM yetkileri)
- RSAT (Remote Server Administration Tools) kurulu olmalı
- **Hedef makinelerde WinRM açık olmalı** → [WinRM nasıl açılır?](#-winrm-nasıl-açılır)

---

### 🚀 Kullanım

#### Local Tool
1. `local-tool` klasörünü indir
2. `sistem-bilgi.bat` ve `sistem-bilgi.ps1` dosyalarını **aynı klasöre** koy
3. `sistem-bilgi.bat`'a çift tıkla

#### Domain Tool
1. `domain-tool` klasörünü indir
2. `Envanter.ps1` dosyasını aç → `$TargetOU` satırını kendi ortamına göre düzenle
3. Hangi makineleri sorgulayacağını seç → [Hedef seçimi nasıl yapılır?](#-hedef-seçimi)
4. `Baslat.bat`'a çift tıkla
5. Sonuçlar masaüstüne `Envanter.csv` olarak kaydedilir, ayrıca GridView'da açılır

---

### 🎯 Hedef Seçimi

`Envanter.ps1` dosyasını Notepad ile açtığında şu bölümü göreceksin. **Sadece bir option'ı aktif bırak**, diğerlerinin başında `#` olsun:

```powershell
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
```

> **`#` nedir?** Satırın başındaki `#` o satırı devre dışı bırakır. `#` olan satır çalışmaz, olmayanlar çalışır. Aynı anda yalnızca **bir** option aktif olmalı.

---

### 🔧 WinRM Nasıl Açılır?

WinRM, uzak makinelere bağlanmak için Windows'un yerleşik protokolüdür. Domain Tool'un çalışabilmesi için **hedef makinelerde** açık olması gerekir.

**GPO ile (Önerilen — tüm OU'ya uygulanır):**

1. `Group Policy Management` aç
2. Hedef OU'ya sağ tıkla → `Create a GPO`
3. GPO'yu düzenle → şu yola git:
   ```
   Computer Configuration > Preferences > Control Panel Settings > Services
   ```
4. `WinRM` servisini `Automatic` + `Running` olarak ayarla
5. Ayrıca şu yola git:
   ```
   Computer Configuration > Windows Settings > Security Settings > Windows Firewall
   ```
6. `Windows Remote Management (HTTP-In)` kuralını etkinleştir

**Manuel olarak (tek makine için — PowerShell'i Admin olarak aç):**

```powershell
Enable-PSRemoting -Force
Set-Service WinRM -StartupType Automatic
```

---

### 📦 Çıktı (CSV Sütunları)

| Sütun | Açıklama |
|---|---|
| Computer Name | Makine adı |
| Status | Success / Offline / Error |
| Motherboard | Anakart marka ve model |
| BIOS Version | BIOS sürümü |
| Operating System | İşletim sistemi |
| OS Build | Windows build numarası |
| IP Address | Aktif IPv4 adresi |
| Processor | İşlemci adı |
| GPU | Ekran kartı |
| Total RAM (GB) | Toplam RAM (GB) |
| RAM Model | RAM part numarası |
| Disk Model | Disk model adı |
| Monitor | Monitör adı |

---
---

<div align="center" id="english">

## English

</div>

### 💡 What does it do?

Most hardware inventory tools require a paid license. This project does the same job using only what Windows already provides — PowerShell, WinRM, and Active Directory — with no third-party software needed.

---

### What is this?

This project contains two tools:

**1. `local-tool/`** — Displays detailed hardware information of the local machine in a colorful terminal UI.

**2. `domain-tool/`** — Collects hardware inventory from computers in an Active Directory OU or a custom selection, and exports results to CSV + GridView.

---

### 📋 Requirements

#### Local Tool
- Windows 10/11
- PowerShell 5.1+

#### Domain Tool
- Windows 10/11 (domain-joined)
- PowerShell 5.1+
- Domain Admin rights (or delegated WinRM + CIM permissions)
- RSAT (Remote Server Administration Tools) installed
- **WinRM must be enabled on target machines** → [How to enable WinRM?](#-how-to-enable-winrm)

---

### 🚀 Usage

#### Local Tool
1. Download the `local-tool` folder
2. Place `sistem-bilgi.bat` and `sistem-bilgi.ps1` in the **same folder**
3. Double-click `sistem-bilgi.bat`

#### Domain Tool
1. Download the `domain-tool` folder
2. Open `Envanter.ps1` → update `$TargetOU` to match your environment
3. Choose which machines to query → [How to select targets?](#-target-selection)
4. Double-click `Baslat.bat`
5. Results are saved to your desktop as `Envanter.csv` and also displayed in GridView

---

### 🎯 Target Selection

Open `Envanter.ps1` with Notepad. You will see the section below. **Keep only one option active** — all others must have `#` at the beginning of the line:

```powershell
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
```

> **What is `#`?** A `#` at the start of a line disables it — the script ignores that line completely. Lines without `#` are active and will run. Only **one** option should be active at a time.

---

### 🔧 How to Enable WinRM

WinRM is Windows' built-in remote management protocol. It must be enabled on **target machines** for the Domain Tool to work.

**Via GPO (Recommended — applies to the entire OU):**

1. Open `Group Policy Management`
2. Right-click on the target OU → `Create a GPO`
3. Edit the GPO → navigate to:
   ```
   Computer Configuration > Preferences > Control Panel Settings > Services
   ```
4. Set the `WinRM` service to `Automatic` + `Running`
5. Also navigate to:
   ```
   Computer Configuration > Windows Settings > Security Settings > Windows Firewall
   ```
6. Enable the `Windows Remote Management (HTTP-In)` inbound rule

**Manually (single machine — open PowerShell as Administrator):**

```powershell
Enable-PSRemoting -Force
Set-Service WinRM -StartupType Automatic
```

---

### 📦 Output (CSV Columns)

| Column | Description |
|---|---|
| Computer Name | Machine hostname |
| Status | Success / Offline / Error |
| Motherboard | Motherboard brand and model |
| BIOS Version | BIOS version string |
| Operating System | OS name |
| OS Build | Windows build number |
| IP Address | Active IPv4 address |
| Processor | CPU name |
| GPU | Graphics card |
| Total RAM (GB) | Total installed RAM |
| RAM Model | RAM part number |
| Disk Model | Disk drive model |
| Monitor | Monitor device name |

---

### 📁 Repo Structure

```
📦 windows-hardware-inventory
 ┣ 📂 local-tool
 ┃ ┣ 📄 sistem-bilgi.bat       ← double-click to run
 ┃ ┗ 📄 sistem-bilgi.ps1       ← must be in the same folder
 ┣ 📂 domain-tool
 ┃ ┣ 📄 Envanter.ps1           ← configure OU/target here
 ┃ ┗ 📄 Baslat.bat             ← double-click to run
 ┗ 📄 README.md
```

---

<div align="center">

Made with ❤️ for sysadmins

</div>

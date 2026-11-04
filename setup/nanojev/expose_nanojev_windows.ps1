<#
.SYNOPSIS
  Expose the NanoJev server (running in WSL2 on 127.0.0.1:<Port>) to other PCs on your Wi-Fi.

.DESCRIPTION
  - starts the IP Helper service (needed for port proxies)
  - finds this PC's LAN IP
  - creates a port proxy  <LAN IP>:<ExternalPort> -> 127.0.0.1:<Port>
  - creates an inbound firewall rule for <ExternalPort> (Private networks only)

  ExternalPort defaults to Port + 1 (8766). A different external port avoids a clash with
  WSL2's own localhost forwarding, which already holds <Port> on Windows.

  The endpoint has NO authentication. Only use it on a network you trust.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\expose_nanojev_windows.ps1
  powershell -ExecutionPolicy Bypass -File .\expose_nanojev_windows.ps1 -MakePrivate
  powershell -ExecutionPolicy Bypass -File .\expose_nanojev_windows.ps1 -Remove
#>
[CmdletBinding()]
param(
    [int]$Port = 8765,           # port the server listens on inside WSL2
    [int]$ExternalPort = 0,      # port other PCs connect to (default: Port + 1)
    [string]$LanIp = "",         # override auto-detected LAN IP (e.g. if you use a VPN)
    [switch]$MakePrivate,        # switch the Wi-Fi network profile to Private if it isn't
    [switch]$Remove,             # undo everything this script created
    [switch]$Elevated            # internal: set when the script relaunches itself as admin
)

$ErrorActionPreference = "Stop"
if ($ExternalPort -eq 0) { $ExternalPort = $Port + 1 }

# ---- Administrator rights (relaunch with a UAC prompt if needed) -------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "Administrator rights are required. Relaunching elevated (accept the UAC prompt)..."
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", "`"$PSCommandPath`"",
                 "-Port", "$Port", "-ExternalPort", "$ExternalPort", "-Elevated")
    if ($LanIp)       { $argList += @("-LanIp", $LanIp) }
    if ($MakePrivate) { $argList += "-MakePrivate" }
    if ($Remove)      { $argList += "-Remove" }
    Start-Process -FilePath "powershell.exe" -ArgumentList $argList -Verb RunAs -Wait
    exit
}

$ruleNames = @("NanoJev ($ExternalPort)", "NanoJev")

try {
    # ---- Clean up old proxy rules on this external port (any listen address) ----
    foreach ($line in (netsh interface portproxy show v4tov4)) {
        if ($line -match "^\s*(\S+)\s+$ExternalPort\s+") {
            netsh interface portproxy delete v4tov4 listenaddress=$($Matches[1]) listenport=$ExternalPort | Out-Null
        }
    }
    foreach ($name in $ruleNames) {
        Get-NetFirewallRule -DisplayName $name -ErrorAction SilentlyContinue | Remove-NetFirewallRule
    }

    if ($Remove) {
        Write-Host "Removed the port proxy and firewall rule for port $ExternalPort." -ForegroundColor Green
        return
    }

    # ---- IP Helper service (runs port proxies) -----------------------------------
    $svc = Get-Service iphlpsvc
    if ($svc.Status -ne "Running") { Start-Service iphlpsvc }
    Set-Service iphlpsvc -StartupType Automatic

    # ---- LAN IP -------------------------------------------------------------------
    if ($LanIp) {
        $alias = (Get-NetIPAddress -IPAddress $LanIp).InterfaceAlias
    } else {
        $cfg = Get-NetIPConfiguration |
               Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq "Up" } |
               Select-Object -First 1
        if (-not $cfg) { throw "No active network adapter with a default gateway found. Use -LanIp." }
        $LanIp = @($cfg.IPv4Address)[0].IPAddress
        $alias = $cfg.InterfaceAlias
    }
    Write-Host "LAN IP: $LanIp (adapter: $alias)"

    # ---- Network profile (the firewall rule only applies to Private networks) -----
    $prof = Get-NetConnectionProfile -InterfaceAlias $alias -ErrorAction SilentlyContinue
    if ($prof -and $prof.NetworkCategory -ne "Private") {
        if ($MakePrivate) {
            Set-NetConnectionProfile -InterfaceAlias $alias -NetworkCategory Private
            Write-Host "Network '$($prof.Name)' switched to Private."
        } else {
            Write-Warning ("Network '$($prof.Name)' is $($prof.NetworkCategory). The firewall rule only applies to " +
                           "Private networks, so other PCs will be blocked. Re-run with -MakePrivate if you trust this network.")
        }
    }

    # ---- Port proxy + firewall rule ----------------------------------------------
    netsh interface portproxy add v4tov4 listenaddress=$LanIp listenport=$ExternalPort connectaddress=127.0.0.1 connectport=$Port | Out-Null
    New-NetFirewallRule -DisplayName "NanoJev ($ExternalPort)" -Direction Inbound -Protocol TCP `
        -LocalPort $ExternalPort -Action Allow -Profile Private | Out-Null

    # ---- Verify -------------------------------------------------------------------
    $listening = netstat -ano | Select-String ":$ExternalPort\s"
    if ($listening) {
        Write-Host "Port proxy is listening on ${LanIp}:${ExternalPort}" -ForegroundColor Green
    } else {
        Write-Warning "Nothing is listening on ${LanIp}:${ExternalPort}. Try: Restart-Service iphlpsvc -Force"
    }
    $backend = Test-NetConnection 127.0.0.1 -Port $Port -WarningAction SilentlyContinue
    if (-not $backend.TcpTestSucceeded) {
        Write-Host "Note: the server is not answering on 127.0.0.1:$Port yet (fine if you are about to start it)."
    }

    $url = "http://${LanIp}:${ExternalPort}/api/evaluate"
    Write-Host ""
    Write-Host "Other PCs can call: $url" -ForegroundColor Green
    Write-Host "Test from the other PC:  Test-NetConnection $LanIp -Port $ExternalPort"
}
catch {
    Write-Host "ERROR: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($Elevated) { Read-Host "Press Enter to close" | Out-Null }
}
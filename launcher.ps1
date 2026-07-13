param(
    [string]$BaseUrl = "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main"
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13
$BaseUrl = $BaseUrl.TrimEnd("/")
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $ps = if (Get-Command pwsh -ea 0) { "pwsh" } else { "powershell" }
    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
        $arguments = "-NoP -EP Bypass -File `"$PSCommandPath`" -BaseUrl `"$BaseUrl`""
    } else {
        $arguments = "-NoP -EP Bypass -C `"& ([scriptblock]::Create((irm '$BaseUrl/launcher.ps1'))) -BaseUrl '$BaseUrl'`""
    }
    Start-Process $ps -ArgumentList $arguments -Verb RunAs
    return
}

$localCmd = if ($PSScriptRoot) { Join-Path $PSScriptRoot "All in One.cmd" } else { $null }
if ($localCmd -and (Test-Path -LiteralPath $localCmd)) {
    $scriptPath = $localCmd
} else {
    $scriptPath = "$env:TEMP\aio.cmd"
    try {
        irm "$BaseUrl/All%20in%20One.cmd" -o $scriptPath -ErrorAction Stop
    } catch {
        Write-Host "[ERREUR] Echec du telechargement du script : $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Appuyez sur Entree pour quitter"
        return
    }
}

if (!(Test-Path -LiteralPath $scriptPath) -or (Get-Item -LiteralPath $scriptPath).Length -eq 0) {
    Write-Host "[ERREUR] Le script est vide ou introuvable." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter"
    return
}
cmd /c "`"$scriptPath`""

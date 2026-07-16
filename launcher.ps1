param(
    [string]$BaseUrl = "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main"
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
try {
    $baseUri = [Uri]$BaseUrl
    if (!$baseUri.IsAbsoluteUri) { throw "URI relative" }
    $segments = $baseUri.AbsolutePath.Trim("/").Split("/")
} catch {
    Write-Host "[ERREUR] URL de base invalide." -ForegroundColor Red
    exit 1
}
if ($baseUri.Scheme -ne "https" -or
    $baseUri.Host -ne "raw.githubusercontent.com" -or !$baseUri.IsDefaultPort -or
    $baseUri.UserInfo -or $baseUri.Query -or $baseUri.Fragment -or $segments.Count -lt 3 -or
    $segments[0] -ne "kaylerberserk" -or $segments[1] -ne "WindowsOptimizer") {
    Write-Host "[ERREUR] La source doit etre une branche du depot officiel WindowsOptimizer sur raw.githubusercontent.com." -ForegroundColor Red
    exit 1
}
$BaseUrl = $baseUri.AbsoluteUri.TrimEnd("/")
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $ps = if (Get-Command pwsh -ea 0) { "pwsh" } else { "powershell" }
    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
        $arguments = "-NoP -EP Bypass -File `"$PSCommandPath`" -BaseUrl `"$BaseUrl`""
    } else {
        $baseUrlData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($BaseUrl))
        $childScript = @"
`$baseUrl = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$baseUrlData'))
`$launcher = Invoke-RestMethod (`$baseUrl + '/launcher.ps1')
& ([scriptblock]::Create(`$launcher)) -BaseUrl `$baseUrl
"@
        $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
        $arguments = "-NoP -EP Bypass -EncodedCommand $encodedCommand"
    }
    try {
        $process = Start-Process $ps -ArgumentList $arguments -Verb RunAs -Wait -PassThru
        exit $process.ExitCode
    } catch {
        Write-Host "[ERREUR] Elevation administrateur annulee ou impossible." -ForegroundColor Red
        exit 1
    }
}

$downloaded = $false
$localCmd = if ($PSScriptRoot) { Join-Path $PSScriptRoot "All in One.cmd" } else { $null }
if ($localCmd -and (Test-Path -LiteralPath $localCmd)) {
    $scriptPath = $localCmd
} else {
    $scriptPath = Join-Path $env:TEMP ("WindowsOptimizer_aio_{0}.cmd" -f [guid]::NewGuid().ToString("N"))
    try {
        irm "$BaseUrl/All%20in%20One.cmd" -o $scriptPath -ErrorAction Stop
        $downloaded = $true
    } catch {
        Write-Host "[ERREUR] Echec du telechargement du script : $($_.Exception.Message)" -ForegroundColor Red
        Read-Host "Appuyez sur Entree pour quitter"
        exit 1
    }
}

if (!(Test-Path -LiteralPath $scriptPath) -or (Get-Item -LiteralPath $scriptPath).Length -eq 0) {
    Write-Host "[ERREUR] Le script est vide ou introuvable." -ForegroundColor Red
    if ($downloaded) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}

try {
    $scriptBytes = [IO.File]::ReadAllBytes($scriptPath)
} catch {
    Write-Host "[ERREUR] Impossible de lire le script." -ForegroundColor Red
    if ($downloaded) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}

$hasBom = ($scriptBytes.Length -ge 3 -and $scriptBytes[0] -eq 0xEF -and $scriptBytes[1] -eq 0xBB -and $scriptBytes[2] -eq 0xBF) -or
    ($scriptBytes.Length -ge 2 -and (($scriptBytes[0] -eq 0xFF -and $scriptBytes[1] -eq 0xFE) -or
    ($scriptBytes[0] -eq 0xFE -and $scriptBytes[1] -eq 0xFF)))
$hasNonAscii = $false
foreach ($byte in $scriptBytes) {
    if ($byte -gt 0x7F) {
        $hasNonAscii = $true
        break
    }
}
if ($hasBom -or $hasNonAscii) {
    Write-Host "[ERREUR] Le script doit etre en ASCII sans BOM." -ForegroundColor Red
    if ($downloaded) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}

$scriptContent = [Text.Encoding]::ASCII.GetString($scriptBytes)
if ($downloaded) {
    # raw.githubusercontent.com sert le blob Git en LF. Les gros batchs LF peuvent rendre
    # les labels :CALL introuvables sous cmd.exe : reecrire explicitement le fichier en CRLF.
    try {
        $scriptContent = [regex]::Replace($scriptContent, "\r\n|\r|\n", "`r`n")
        [IO.File]::WriteAllText($scriptPath, $scriptContent, [Text.Encoding]::ASCII)
    } catch {
        Write-Host "[ERREUR] Impossible de preparer le script telecharge en CRLF." -ForegroundColor Red
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
        Read-Host "Appuyez sur Entree pour quitter"
        exit 1
    }
}
$firstLine = ($scriptContent -split "\r\n|\r|\n", 2)[0]
if ($firstLine -notmatch '^@echo off\s*$' -or $scriptContent.Length -lt 100000 -or
    $scriptContent -notmatch '(?m)^:MENU_PRINCIPAL\s*$' -or
    $scriptContent -notmatch '(?m)^:END_SCRIPT\s*$') {
    Write-Host "[ERREUR] Le fichier recu n'est pas un script WindowsOptimizer valide." -ForegroundColor Red
    if ($downloaded) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
    Read-Host "Appuyez sur Entree pour quitter"
    exit 1
}

$exitCode = 1
try {
    & $env:ComSpec /d /e:on /c "`"$scriptPath`""
    $exitCode = $LASTEXITCODE
} finally {
    if ($downloaded) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
}
exit $exitCode

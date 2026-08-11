param(
    # Source officielle : branche main (derniere publication disponible).
    [string]$BaseUrl = "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main",
    [switch]$VerifyOnly
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
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
    $baseUri.UserInfo -or $baseUri.Query -or $baseUri.Fragment -or $segments.Count -ne 3 -or
    $segments[0] -ne "kaylerberserk" -or $segments[1] -ne "WindowsOptimizer" -or
    $segments[2] -notmatch '^(main|[0-9a-fA-F]{40})$') {
    Write-Host "[ERREUR] La source doit etre la branche 'main' ou un commit SHA-1 complet du depot officiel WindowsOptimizer." -ForegroundColor Red
    exit 1
}
$BaseUrl = $baseUri.AbsoluteUri.TrimEnd("/")
if (!$VerifyOnly -and !([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $ps = if (Get-Command pwsh -ErrorAction SilentlyContinue) { "pwsh" } else { "powershell" }
    $baseUrlData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($BaseUrl))
    if ($PSCommandPath -and (Test-Path -LiteralPath $PSCommandPath)) {
        $scriptPathData = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($PSCommandPath))
        $childScript = @"
`$ErrorActionPreference = 'Stop'
`$baseUrl = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$baseUrlData'))
`$scriptPath = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$scriptPathData'))
try {
    & `$scriptPath -BaseUrl `$baseUrl
} catch {
    Write-Host ("[ERREUR] Echec du launcher admin : " + `$_.Exception.Message) -ForegroundColor Red
    exit 1
}
"@
    } else {
        $childScript = @"
`$ErrorActionPreference = 'Stop'
`$baseUrl = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('$baseUrlData'))
try {
    `$launcher = Invoke-RestMethod -Uri (`$baseUrl + '/launcher.ps1') -TimeoutSec 60 -ErrorAction Stop
    & ([scriptblock]::Create(`$launcher)) -BaseUrl `$baseUrl
} catch {
    Write-Host ("[ERREUR] Echec du bootstrap distant : " + `$_.Exception.Message) -ForegroundColor Red
    exit 1
}
"@
    }
    $encodedCommand = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($childScript))
    $arguments = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-EncodedCommand", $encodedCommand)
    try {
        $process = Start-Process -FilePath $ps -ArgumentList $arguments -Verb RunAs -Wait -PassThru -ErrorAction Stop
        if ($process.ExitCode -ne 0) {
            Write-Host "[ERREUR] Le launcher administrateur s'est termine avec le code $($process.ExitCode)." -ForegroundColor Red
        }
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
    $scriptOrigin = $localCmd
} else {
    $scriptPath = Join-Path $env:TEMP ("WindowsOptimizer_aio_{0}.cmd" -f [guid]::NewGuid().ToString("N"))
    $scriptOrigin = "$BaseUrl/All%20in%20One.cmd"
    try {
        Invoke-RestMethod -Uri "$BaseUrl/All%20in%20One.cmd" -OutFile $scriptPath -TimeoutSec 60 -ErrorAction Stop
        $downloaded = $true
    } catch {
        Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
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

$hasInvalidEncoding = $false
foreach ($byte in $scriptBytes) {
    if ($byte -eq 0 -or $byte -gt 0x7F) {
        $hasInvalidEncoding = $true
        break
    }
}
if ($hasInvalidEncoding) {
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

if ($VerifyOnly) {
    $sha256 = [Security.Cryptography.SHA256]::Create()
    try {
        $hash = ($sha256.ComputeHash([Text.Encoding]::ASCII.GetBytes($scriptContent)) |
            ForEach-Object { $_.ToString("x2") }) -join ""
    } finally {
        $sha256.Dispose()
    }
    Write-Host "[OK] Launcher et batch valides." -ForegroundColor Green
    Write-Host "     Batch : $scriptOrigin"
    Write-Host "     Racine de publication : $BaseUrl"
    Write-Host "     SHA-256 du batch prepare : $hash"
    if ($downloaded) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
    exit 0
}

$exitCode = 1
try {
    # Le batch utilise la meme source de publication pour ses ressources optionnelles.
    $env:WINOPT_RELEASE_BASE_URL = $BaseUrl
    $quote = [char]34
    $cmdArguments = "/d /e:on /v:off /s /c $quote$quote$scriptPath$quote$quote"
    $process = Start-Process -FilePath $env:ComSpec -ArgumentList $cmdArguments -Wait -PassThru -NoNewWindow -ErrorAction Stop
    $exitCode = $process.ExitCode
} finally {
    if ($downloaded) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
}
exit $exitCode

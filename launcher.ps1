param(
    # Source officielle : branche main (derniere publication disponible).
    [string]$BaseUrl = "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main",
    [switch]$VerifyOnly
)

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$ProgressPreference = "SilentlyContinue"
function Stop-Launcher([string]$Message, [switch]$Cleanup, [switch]$NoPause) {
    if ($Cleanup -and $scriptPath) { Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue }
    Write-Host "[ERREUR] $Message" -ForegroundColor Red
    if (!$NoPause -and !$VerifyOnly) { Read-Host "Appuyez sur Entree pour quitter" }
    exit 1
}

try {
    $baseUri = [Uri]$BaseUrl
    if (!$baseUri.IsAbsoluteUri) { throw "URI relative" }
    $segments = $baseUri.AbsolutePath.Trim("/").Split("/")
} catch {
    Stop-Launcher "URL de base invalide." -NoPause
}
if ($baseUri.Scheme -ne "https" -or
    $baseUri.Host -ne "raw.githubusercontent.com" -or !$baseUri.IsDefaultPort -or
    $baseUri.UserInfo -or $baseUri.Query -or $baseUri.Fragment -or $segments.Count -ne 3 -or
    $segments[0] -ne "kaylerberserk" -or $segments[1] -ne "WindowsOptimizer" -or
    $segments[2] -notmatch '^(main|[0-9a-fA-F]{40})$') {
    Stop-Launcher "La source doit etre la branche 'main' ou un commit SHA-1 complet du depot officiel WindowsOptimizer." -NoPause
}
$BaseUrl = $baseUri.AbsoluteUri.TrimEnd("/")

$scriptPath = Join-Path $env:TEMP ("WindowsOptimizer_aio_{0}.cmd" -f [guid]::NewGuid().ToString("N"))
$scriptOrigin = "$BaseUrl/All%20in%20One.cmd"
try {
    Invoke-RestMethod -Uri $scriptOrigin -OutFile $scriptPath -TimeoutSec 60 -ErrorAction Stop
} catch {
    Stop-Launcher "Echec du telechargement du script : $($_.Exception.Message)" -Cleanup
}

if (!(Test-Path -LiteralPath $scriptPath) -or (Get-Item -LiteralPath $scriptPath).Length -eq 0) {
    Stop-Launcher "Le script est vide ou introuvable." -Cleanup
}

try {
    $scriptBytes = [IO.File]::ReadAllBytes($scriptPath)
} catch {
    Stop-Launcher "Impossible de lire le script." -Cleanup
}

$hasInvalidEncoding = $false
foreach ($byte in $scriptBytes) {
    if ($byte -eq 0 -or $byte -gt 0x7F) {
        $hasInvalidEncoding = $true
        break
    }
}
if ($hasInvalidEncoding) {
    Stop-Launcher "Le script doit etre en ASCII sans BOM." -Cleanup
}

$scriptContent = [Text.Encoding]::ASCII.GetString($scriptBytes)
# raw.githubusercontent.com sert le blob Git en LF. Les gros batchs LF peuvent rendre
# les labels :CALL introuvables sous cmd.exe : reecrire explicitement le fichier en CRLF.
try {
    $scriptContent = [regex]::Replace($scriptContent, "\r\n|\r|\n", "`r`n")
    [IO.File]::WriteAllText($scriptPath, $scriptContent, [Text.Encoding]::ASCII)
} catch {
    Stop-Launcher "Impossible de preparer le script telecharge en CRLF." -Cleanup
}
$firstLine = ($scriptContent -split "\r\n|\r|\n", 2)[0]
if ($firstLine -notmatch '^@echo off\s*$' -or $scriptContent.Length -lt 100000 -or
    $scriptContent -notmatch '(?m)^:MENU_PRINCIPAL\s*$' -or
    $scriptContent -notmatch '(?m)^:END_SCRIPT\s*$') {
    Stop-Launcher "Le fichier recu n'est pas un script WindowsOptimizer valide." -Cleanup
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
    Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
    exit 0
}

$exitCode = 1
try {
    # Le batch utilise la meme source de publication pour ses ressources optionnelles.
    $env:WINOPT_RELEASE_BASE_URL = $BaseUrl
    $quote = [char]34
    $cmdArguments = "/d /e:on /v:off /s /c $quote$quote$scriptPath$quote$quote"
    $start = @{
        FilePath = $env:ComSpec
        ArgumentList = $cmdArguments
        WindowStyle = "Normal"
        Wait = $true
        PassThru = $true
        ErrorAction = "Stop"
    }
    if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $start.Verb = "RunAs"
    }
    # Fenetre CMD dediee avec elevation directe : meme comportement qu'un batch ouvert manuellement.
    $process = Start-Process @start
    $exitCode = $process.ExitCode
} catch {
    Write-Host "[ERREUR] Lancement administrateur annule ou impossible : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    Remove-Item -LiteralPath $scriptPath -Force -ErrorAction SilentlyContinue
}
exit $exitCode

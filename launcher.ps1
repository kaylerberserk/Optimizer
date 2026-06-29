[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $ps = if (Get-Command pwsh -ea 0) { "pwsh" } else { "powershell" }
    Start-Process $ps -ArgumentList "-NoP -EP Bypass -C `"irm 'https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1' | iex`"" -Verb RunAs; return
}
$tmp = "$env:TEMP\aio.cmd"
try {
    irm "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/All%20in%20One.cmd" -o $tmp -ErrorAction Stop
} catch {
    Write-Host "[ERREUR] Echec du telechargement du script : $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter"; return
}
if (!(Test-Path $tmp) -or (Get-Item $tmp).Length -eq 0) {
    Write-Host "[ERREUR] Le fichier telecharge est vide ou introuvable." -ForegroundColor Red
    Read-Host "Appuyez sur Entree pour quitter"; return
}
cmd /c "`"$tmp`""

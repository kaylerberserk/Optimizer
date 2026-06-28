if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $ps = if (Get-Command pwsh -ea 0) { "pwsh" } else { "powershell" }
    Start-Process $ps -ArgumentList "-NoP -EP Bypass -C `"irm 'https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/launcher.ps1' | iex`"" -Verb RunAs; return
}
$tmp = "$env:TEMP\aio.cmd"
irm "https://raw.githubusercontent.com/kaylerberserk/WindowsOptimizer/main/All%20in%20One.cmd" -o $tmp
cmd /c $tmp

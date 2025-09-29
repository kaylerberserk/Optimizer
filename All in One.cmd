@echo off
setlocal EnableDelayedExpansion

:: Activer les sequences d'echappement ANSI pour les couleurs
reg add HKCU\Console /v VirtualTerminalLevel /t reg_DWORD /d 1 /f >nul 2>&1

:: Definir la taille de la console et du tampon
title Script d'Optimisation Windows - All in One

:: Definitions des couleurs avec couleurs vives et styles
for /f %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
set "COLOR_GREEN=%ESC%[32m"
set "COLOR_YELLOW=%ESC%[33m"
set "COLOR_RED=%ESC%[31m"
set "COLOR_CYAN=%ESC%[36m"
set "COLOR_WHITE=%ESC%[37m"
set "COLOR_BLUE=%ESC%[34m"
set "COLOR_MAGENTA=%ESC%[35m"
set "COLOR_RESET=%ESC%[0m"
set "STYLE_BOLD=%ESC%[1m"

:: Definir le titre de la console avec style
title Script d'Optimisation Windows - All in One

:: VERIFICATION DES PRE-REQUIS
echo %COLOR_YELLOW%[*] Verification des prerequis...%COLOR_RESET%

net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_RED%Ce script necessite des privileges administrateur.%COLOR_RESET%
    echo %COLOR_RED%Veuillez l'executer en tant qu'administrateur.%COLOR_RESET%
    pause
    exit /B 1
)

:: VERIFICATION DE POWERSHELL
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_RED%Erreur: PowerShell n'est pas disponible sur ce systeme.%COLOR_RESET%
    echo %COLOR_RED%Ce script necessite PowerShell pour fonctionner correctement.%COLOR_RESET%
    pause
    exit /B 1
)

:: VERIFICATION DE L'ACCES INTERNET
ping 8.8.8.8 -n 1 -w 1000 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_RED%Erreur: Pas d'acces Internet detecte.%COLOR_RESET%
    echo %COLOR_RED%Ce script necessite une connexion Internet pour fonctionner.%COLOR_RESET%
    pause
    exit /B 1
)

echo %COLOR_GREEN%[+] Prerequis verifies avec succes.%COLOR_RESET%
echo.
timeout /t 1 /nobreak >nul
goto :MENU_PRINCIPAL

:MENU_PRINCIPAL
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_RESET%               %STYLE_BOLD%%COLOR_WHITE%Script d'Optimisation Windows - All in One%COLOR_RESET%                  
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
:: Initialisation de la variable
set "IS_LAPTOP=0"
:: Detection via batterie (remplacement WMIC -> CIM)
for /f %%i in ('powershell -NoProfile -Command "if(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue){Write-Output 1} else {Write-Output 0}"') do (
    if %%i gtr 0 set "IS_LAPTOP=1"
)

if "%IS_LAPTOP%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE%SYSTEME DETECTEE:%COLOR_RESET% %COLOR_GREEN%PC PORTABLE%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE%SYSTEME DETECTEE:%COLOR_RESET% %COLOR_GREEN%PC FIXE%COLOR_RESET%
)

echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS GENERALES ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Optimisations Systeme%COLOR_RESET%      %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Optimisations Memoire%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Optimisations Disques%COLOR_RESET%      %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Optimisations GPU%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Optimisations Reseau%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- PC BUREAUTIQUES UNIQUEMENT ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_GREEN%Optimisations Clavier/Souris%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_GREEN%Desactiver Peripheriques Inutiles%COLOR_RESET%

echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_GREEN%Desactiver economies d'energie%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS ALL IN ONE ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_WHITE%Optimiser tout (PC de Bureau)%COLOR_RESET%
echo %COLOR_YELLOW%[L]%COLOR_RESET% %COLOR_WHITE%Optimiser tout (PC Portable)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS SYSTEME ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[N]%COLOR_RESET% %COLOR_CYAN%Nettoyage Avance de Windows%COLOR_RESET%
echo %COLOR_YELLOW%[R]%COLOR_RESET% %COLOR_CYAN%Creer un Point de Restauration%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- PARAMETRES SYSTEME ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[A]%COLOR_RESET% %COLOR_GREEN%Gerer Windows Defender%COLOR_RESET%
echo %COLOR_YELLOW%[B]%COLOR_RESET% %COLOR_GREEN%Gerer UAC (Controle de Compte Utilisateur)%COLOR_RESET%
echo %COLOR_YELLOW%[C]%COLOR_RESET% %COLOR_GREEN%Gerer les Animations Windows%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS SUPPLEMENTAIRES ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[O]%COLOR_RESET% %COLOR_MAGENTA%Desinstaller OneDrive Completement%COLOR_RESET%
echo %COLOR_YELLOW%[E]%COLOR_RESET% %COLOR_MAGENTA%Desinstaller Edge Completement%COLOR_RESET%
echo %COLOR_YELLOW%[W]%COLOR_RESET% %COLOR_MAGENTA%Outil activation Windows / Office (MAS)%COLOR_RESET%
echo %COLOR_YELLOW%[T]%COLOR_RESET% %COLOR_MAGENTA%Outil Chris Titus Tech (WinUtil)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[Q]%COLOR_RESET% %STYLE_BOLD%%COLOR_RED%Quitter le script%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 12345678DLNRQABCOEWT /N /M "%STYLE_BOLD%%COLOR_YELLOW%Veuillez choisir une option [1-8, D, L, N, R, Q, A, B, C, O, E, W, T]: %COLOR_RESET%"

REM La gestion de ERRORLEVEL doit etre faite du plus grand au plus petit
if errorlevel 20 goto :OUTIL_CHRIS_TITUS
if errorlevel 19 goto :OUTIL_ACTIVATION
if errorlevel 18 goto :DESINSTALLER_EDGE
if errorlevel 17 goto :DESINSTALLER_ONEDRIVE
if errorlevel 16 goto :TOGGLE_ANIMATIONS
if errorlevel 15 goto :TOGGLE_UAC
if errorlevel 14 goto :TOGGLE_DEFENDER
if errorlevel 13 goto :END_SCRIPT
if errorlevel 12 goto :CREER_POINT_RESTAURATION
if errorlevel 11 goto :NETTOYAGE_AVANCE_WINDOWS
if errorlevel 10 goto :TOUT_OPTIMISER_LAPTOP
if errorlevel 9 goto :TOUT_OPTIMISER_DESKTOP
if errorlevel 8 goto :DESACTIVER_ECONOMIES_ENERGIE
if errorlevel 7 goto :DESACTIVER_PERIPHERIQUES_INUTILES
if errorlevel 6 goto :OPTIMISATIONS_PERIPHERIQUES
if errorlevel 5 goto :OPTIMISATIONS_RESEAU
if errorlevel 4 goto :OPTIMISATIONS_GPU
if errorlevel 3 goto :OPTIMISATIONS_DISQUES
if errorlevel 2 goto :OPTIMISATIONS_MEMOIRE
if errorlevel 1 goto :OPTIMISATIONS_SYSTEME

goto :MENU_PRINCIPAL :: Si aucune option valide n'est choisie (ne devrait pas arriver avec choice)

:OPTIMISATIONS_SYSTEME
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                SECTION 1: OPTIMISATIONS SYSTEME%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

:: --- Préflight (facultatif mais utile) -------------------------------------------------------
whoami /groups | find /i "S-1-16-12288" >nul || echo %COLOR_YELLOW%[!]%COLOR_RESET% Lancer en admin pour que tout s’applique.
for %%P in (reg sc schtasks bcdedit powershell) do where %%P >nul 2>&1 || echo %COLOR_YELLOW%[!]%COLOR_RESET% Outil manquant: %%P


:: 1.2 - NOYAU / PROCESSUS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation noyau / priorites...

:: Noyau (performances assumées > sécurité)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v MitigationOptions /t REG_QWORD /d 0x1000000000000 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v ObCaseInsensitive /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DistributeTimers /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "AmdCpuBackoffTime" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Windows" /v "ErrorMode" /t REG_DWORD /d 2 /f >nul

:: HVCI (Valorant)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 1.3 - MULTIMEDIA / MMCSS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil multimedia...
:: --- MMCSS / SYSTEMPROFILE (RESEAU/JEUX)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v AlwaysOn /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NoLazyMode /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v LazyModeTimeout /t REG_DWORD /d 10000 /f >nul 2>&1

:: TÂCHE JEUX
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "Medium" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t REG_SZ /d "False" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t REG_DWORD /d 0 /f >nul 2>&1

:: TÂCHE WINDOW MANAGER
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Background Only" /t REG_SZ /d "False" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Priority" /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager" /v "Affinity" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_GREEN%[+]%COLOR_RESET% Profil multimedia configure.


:: 1.4 - CORRECTIONS SPECIFIQUES 24H2 (Featu::anagement)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Corrections Windows 24H2...
REG DELETE "HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v EnabledState /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v EnabledStateOptions /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v Variant /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v VariantPayload /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v VariantPayloadKind /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Corrections 24H2 appliquees.


:: 1.5 - UI / EXPLORATEUR / BARRE DES TACHES
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration interface utilisateur...
:: Barre des taches (Task View / Cortana / Widgets / Feeds / Chat)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCortanaButton /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 3 /f >nul 2>&1

:: Explorateur : menu contextuel classique, fichiers cachés/extentions, notif sync off, MRU off
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Hidden /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSyncProviderNotifications /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DontPrettyPath /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DesktopLivePreviewHoverTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1

:: Avertissements ouverture fichiers non signés (assumé)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Associations" /v LowRiskFileTypes /t REG_SZ /d ".exe;.bat;.cmd;.reg;.vbs;.msi;.ps1" /f >nul 2>&1

:: TimeBroker (évite disable qui casse Widgets/temps — laisse en 3)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TimeBrokerSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Interface utilisateur configuree.


:: 1.6 - EFFETS VISUELS (latence UI)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Effets visuels...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d 1000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d 2 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v LowLevelHooksTimeout /t REG_SZ /d 1000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d 2000 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d 2000 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v PointerShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewWatermark /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseTrails /t REG_SZ /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Effets visuels configures.

:: Recherche locale (sans web)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Windows Search local OK.


:: 1.8 - TELEMETRIE / COLLECTE
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation telemetrie (services)...
sc stop DiagTrack >nul 2>&1 & sc config DiagTrack start=disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1 & sc config dmwappushservice start=disabled >nul 2>&1
sc stop diagnosticshub.standardcollector.service >nul 2>&1 & sc config diagnosticshub.standardcollector.service start=disabled >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Services telemetrie desactives.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation taches planifiees (telemetrie)...
schtasks /Change /TN "Microsoft\Windows\FileHistory\File History (maintenance mode)" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\PI\Sqm-Tasks" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyMonitor" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyRefresh" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Registre (télémétrie / pub / cloud content)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v PreventDeviceMetadataFromNetwork /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableConsumerFeatures /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiences /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v RestrictImplicitInkCollection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v RestrictImplicitTextCollection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v SensorPermissionState /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF" /v LogEnable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF" /v LogLevel /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowCommercialDataPipeline /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowDeviceNameInTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v LimitEnhancedDiagnosticDataWindowsAnalytics /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v MicrosoftEdgeDataOptIn /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Registre telemetrie OK.

echo %COLOR_YELLOW%[*]%COLOR_RESET% AutoLoggers...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AppModel" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Cellcore" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Circular Kernel Context Logger" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\CloudExperienceHostOobe" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DataMarket" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DefenderApiLogger" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DefenderAuditLogger" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot" /v Start /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% AutoLoggers OK.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Taches bavardes supplementaires...
for %%T in (
  "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
  "Microsoft\Windows\Application Experience\ProgramDataUpdater"
  "Microsoft\Windows\Autochk\Proxy"
  "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
  "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
  "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticResolver"
  "Microsoft\Windows\Feedback\Siuf\DmClient"
  "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
  "Microsoft\Windows\Maps\MapsToastTask"
  "Microsoft\Windows\Maps\MapsUpdateTask"
  "Microsoft\Windows\Windows Error Reporting\QueueReporting"
  "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
  "Microsoft\Windows\Windows Error Reporting\SchemeTask"
  "Microsoft\Windows\Application Experience\StartupAppTask"
  "Microsoft\Windows\Application Experience\PCA"
  "Microsoft\Windows\Autologger\SQMLogger"
  "Microsoft\Windows\Shell\FamilySafetyMonitor"
  "Microsoft\Windows\Shell\FamilySafetyRefresh"
  "Microsoft\Windows\DiskFootprint\Diagnostics"
  "Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser"
) do schtasks /Change /TN "%%~T" /Disable >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Taches supplementaires desactivees.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Windows Error Reporting (WER)...
sc stop WerSvc >nul 2>&1
sc config WerSvc start= disabled >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% WER desactive.


:: 1.9 - AUTRES OPTIMISATIONS SYSTEME
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisations additionnelles...
:: DirectX swap effect upgrade OFF (fenetre optimisee)
reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v DirectXUserGlobalSettings /t REG_SZ /d "SwapEffectUpgradeEnable=0;" /f >nul 2>&1
:: Game Mode ON
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul 2>&1

:: Démarrage plus vif / protection SPP idle
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v InactivityShutdownDelay /t REG_DWORD /d 4294967295 /f >nul 2>&1

:: AppCompat inventaire off
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableInventory /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableUAR /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v AITEnable /t REG_DWORD /d 0 /f >nul 2>&1

:: Storage Sense
echo %COLOR_YELLOW%[*]%COLOR_RESET% Assistant Stockage...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 04 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 08 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 32 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 256 /t REG_DWORD /d 30 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 512 /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 1024 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 2048 /t REG_DWORD /d 7 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v StoragePoliciesChanged /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v StoragePoliciesNotified /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Storage Sense configure.

:: MSI (Message-Signaled Interrupts) – best-effort
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation MSI (peripheriques critiques)...
powershell -NoLogo -NoProfile -Command "Get-PnpDevice -Class @('Display','HDC','SCSIAdapter','System') -Status OK | ForEach-Object { $p='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$_.InstanceId+'\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if (Test-Path $p) { Set-ItemProperty -Path $p -Name MSISupported -Value 1 -Force } }" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% MSI activees si supportees.

:: Batterie (activer Energy Saver automatiquement)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Economie d'energie (DC)...
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: Timer/horloge
bcdedit /set disabledynamictick yes >nul 2>&1
bcdedit /set tscsyncpolicy Enhanced >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1


:: 1.10 - BROWSERS (Prefetch/Prerender + Edge policies propres)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Prefetch navigateur...
reg add "HKCU\Software\Microsoft\Edge\Main" /v EnablePreload /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Google\Chrome\Prerender" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reset politiques Edge...
REG DELETE "HKCU\Software\Policies\Microsoft\Edge" /f >nul 2>&1
REG DELETE "HKLM\Software\Policies\Microsoft\Edge" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reapplication politiques Edge (HKCU)...
reg add "HKCU\Software\Policies\Microsoft\Edge" /v PersonalizationReportingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v SearchSuggestEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NetworkPredictionOptions /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v ResolveNavigationErrorsUseWebService /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v ConfigureDoNotTrack /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsMode /t REG_SZ /d automatic /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v SmartScreenEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v AlternateErrorPagesEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v PasswordManagerEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v PaymentMethodQueryEnabled /t REG_DWORD /d 0 /f >nul 2>&1


echo %COLOR_YELLOW%[*]%COLOR_RESET% Reapplication politiques Edge (HKLM)...
reg add "HKLM\Software\Policies\Microsoft\Edge" /v PersonalizationReportingEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v SearchSuggestEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v NetworkPredictionOptions /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v ResolveNavigationErrorsUseWebService /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v ConfigureDoNotTrack /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v DnsOverHttpsMode /t REG_SZ /d automatic /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v SmartScreenEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v AlternateErrorPagesEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v PasswordManagerEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Policies\Microsoft\Edge" /v PaymentMethodQueryEnabled /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisations systeme appliquees avec succes.

if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)


:OPTIMISATIONS_MEMOIRE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                SECTION 2: OPTIMISATIONS MEMOIRE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations memoire pour performance maximale...

:: 2.1 - Memory Management de base
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration Memory Management (perf max)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Memory Management configure.

:: 2.2 - Pagefile (laisser Windows gerer, shutdown rapide)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du Page File...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SystemPages /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagefileEncryption /t REG_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Pagefile configure.

:: 2.3 - Prefetch/SysMain (reactivite applis/boot)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation Prefetch/SysMain...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 3 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 3 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t REG_DWORD /d 0 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Prefetch/SysMain configures.

:: 2.4 - Détection RAM & politique Compression/PageCombining (>=8Go : off)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Detection RAM et configuration Compression/PageCombining...
setlocal EnableExtensions EnableDelayedExpansion

set "RAM_MB="
for /f "tokens=*" %%a in ('powershell -NoProfile -Command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory/1MB -as [int]" 2^>nul') do set "RAM_MB=%%a"
if not defined RAM_MB set "RAM_MB=0"

:: arrondi au Go (±512 Mo)
set /a RAM_GB=(RAM_MB+512)/1024

if !RAM_MB! GEQ 8192 (
  echo %COLOR_CYAN%[i]%COLOR_RESET% RAM detectee !RAM_GB!GB - Compression et PageCombining desactives.
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableMemoryCompression /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Memory Management" /v DisableCompression /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePageCombining /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingCombining /t REG_DWORD /d 1 /f >nul 2>&1
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Disable-MMAgent -MemoryCompression -PageCombining" >nul 2>&1
) else (
  echo %COLOR_CYAN%[i]%COLOR_RESET% RAM detectee !RAM_GB!GB - Compression et PageCombining actives.
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableMemoryCompression /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Memory Management" /v DisableCompression /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePageCombining /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingCombining /t REG_DWORD /d 0 /f >nul 2>&1
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Enable-MMAgent -MemoryCompression -PageCombining" >nul 2>&1
)

endlocal
echo %COLOR_GREEN%[+]%COLOR_RESET% Politique memoire appliquee selon la quantite de RAM.

:: 2.5 - Kernel mitigations (Spectre/Meltdown OFF) — RISQUE ASSUME
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des Kernel Mitigations (RISQUE SeCURITe)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask/t REG_DWORD /d 3 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableCfg /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages  /t REG_DWORD /d 0 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Kernel Mitigations OFF.

:: 2.6 - Mitigations CPU (Spectre/Meltdown OFF) — RISQUE ASSUME
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des mitigations CPU (RISQUE SeCURITe)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline  /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Spectre/Meltdown OFF.

echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisations memoire appliquees !
echo %COLOR_YELLOW%[!]%COLOR_RESET% Redemarrage recommande pour prise en compte complete.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:OPTIMISATIONS_DISQUES
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                    SECTION 3: OPTIMISATIONS DISQUE ET STOCKAGE (PERF MAX)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Application des optimisations de disque et stockage...

:: 3.1 - FSUtil (TRIM, 8.3 OFF, LastAccess OFF)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration FSUtil (TRIM/Metadonnees)...
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% FSUtil configure.

:: 3.2 - NTFS (cache + MFT zone agressive) & chemins longs
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des parametres NTFS...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisable8dot3NameCreation /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NTFSDisableLastAccessUpdate /t REG_DWORD /d 2 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMemoryUsage /t REG_DWORD /d 2 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMftZoneReservation /t REG_DWORD /d 4 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableEncryption /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableCompression /t REG_DWORD /d 1 /f >nul 2>&1 

echo %COLOR_GREEN%[+]%COLOR_RESET% NTFS optimise.

:: 3.3 - TRIM/ReTRIM tous volumes SSD detectes
echo %COLOR_YELLOW%[*]%COLOR_RESET% Execution du TRIM/ReTrim...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ssd=(Get-PhysicalDisk | ? MediaType -eq 'SSD'); if($ssd){Get-Volume | ? FileSystem -in 'NTFS','ReFS' | % { try{ Optimize-Volume -DriveLetter $_.DriveLetter -ReTrim -ErrorAction Stop } catch{} } }" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% TRIM/ReTrim effectue.

:: 3.4 - ReFS (si present)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisations ReFS (si volumes ReFS)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v RefsDisableLastAccessUpdate /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v RefsEnableInlineTrim /t REG_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% ReFS optimise.

:: 3.5 - SATA/AHCI : couper LPM (HIPM/DIPM) pour latence mini (desktop)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du Link Power Management (SATA/AHCI)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v NOLPM /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v NOLPMHIPM /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v NOLPMDIPM /t REG_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% LPM desactive (SATA).

:: 3.6 - Maintenance defrag/optimize (Windows gère, on s'assure que c'est actif)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la maintenance d'optimisation des lecteurs...
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Enable >nul 2>&1
sc config defragsvc start= delayed-auto >nul 2>&1
sc start defragsvc >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Maintenance defrag/trim activee.

echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisations disque (PERF MAX) appliquees !
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)


:OPTIMISATIONS_GPU
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                    SECTION 4: OPTIMISATIONS GPU%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Application des optimisations GPU avancees...

:: 4.5 - GameDVR & Game Bar
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de GameDVR et de la Game Bar...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v AppCaptureEnabled /t REG_DWORD /d 0 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration GameDVR et Game Bar terminee.

:: 4.6 - Optimisations GPU systeme (HAGS, Miracast)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations GPU systeme...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "PlatformSupportMiracast" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t reg_DWORD /d "2" /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "SwapChainFlipAllowTearing" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "MultiPlaneOverlayEnabled" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" /v "EnableFsRtp" /t REG_DWORD /d 0 /f >nul
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v OverlayTestMode /t REG_DWORD /d 5 /f >nul 2>&1 

echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations GPU systeme appliquees.

:: 4.7 - Rendu WPF/Avalon (optionnel UI)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration Avalon.Graphics...
reg add "HKCU\SOFTWARE\Microsoft\Avalon.Graphics" /v "DisableHWAcceleration" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\SOFTWARE\Microsoft\Avalon.Graphics" /v "MaxMultisampleType" /t reg_DWORD /d "0" /f >nul 2>&1 
reg add "HKCU\SOFTWARE\Microsoft\Avalon.Graphics" /v "EnablePerFrameGPUCommandLogging" /t reg_DWORD /d "0" /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration Avalon.Graphics terminee.

:: 4.8 - Forcer Flip Model (optionnel)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisations DWM...
reg add "HKLM\SOFTWARE\Microsoft\DirectX" /v "FlipModelOverride" /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "FlipExQueueLength" /t REG_DWORD /d 2 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\Dwm" /v "OverlayTestMode" /t REG_DWORD /d 5 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Flip Model force.

:: 4.9 - Energie PCIe (eviter micro-lags bus)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation gestion d'energie PCIe...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v "DisablePpm" /t reg_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Gestion d'energie PCIe desactivee.

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisations GPU appliquees avec succes.

if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:OPTIMISATIONS_RESEAU
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                    SECTION 5 : OPTIMISATIONS RESEAU ET INTERNET%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Application des optimisations reseau...

:: 5.1 — Desactiver la limitation MMCSS
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation de la limitation reseau (MMCSS)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1 

:: 5.2 — PILE TCP MODERNE (ESPORT)
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration TCP moderne...

netsh int tcp set heuristics disabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set supplemental template=internet congestionprovider=cubic >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global rsc=disabled >nul 2>&1
netsh int tcp set global ecncapability=disabled >nul 2>&1
netsh int udp set global uso=enabled >nul 2>&1
netsh int udp set global ero=disabled >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-NetTCPSetting -SettingName Internet -InitialRtoMs 2000" >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 128 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v CongestionAlgorithm /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DelayedAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DelayedAckTicks /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableDHCPMediaSense /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableIPSourceRouting /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableMediaSenseEventLog /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableTaskOffload /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableRSS /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v NumTcbTablePartitions /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SackOpts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxConnectRetransmissions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v UseDomainNameDevolution /t REG_DWORD /d 1 /f >nul 2>&1

:: 5.3 — IP global
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration IP globale...
netsh int ip set global taskoffload=disabled >nul 2>&1
netsh int ip set global sourceroutingbehavior=drop >nul 2>&1
netsh int ip set global dhcpmediasense=disabled >nul 2>&1
netsh int ip set global mediasenseeventlog=disabled >nul 2>&1
netsh int ip set global icmpredirects=disabled >nul 2>&1
netsh int ipv6 set global neighborcachelimit=4096 >nul 2>&1

:: 5.4 — Delivery Optimization (P2P off)
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation du partage P2P de Windows Update...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1 

:: 5.5 — Priorites de resolution DNS
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v LocalPriority /t REG_DWORD /d 4 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v HostsPriority /t REG_DWORD /d 5 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v DnsPriority /t REG_DWORD /d 6 /f >nul 2>&1 

:: 5.6 — Desactive ISATAP/Teredo
echo %COLOR_GREEN%[+]%COLOR_RESET% IPv6 natif conserve ; ISATAP/Teredo desactives...
netsh int isatap set state disabled >nul 2>&1
netsh int teredo set state disabled >nul 2>&1

:: 5.7 — NAGLE / DELACK OFF (PAR INTERFACE ACTIVE)
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation Nagle/DelACK ciblee sur interfaces actives...

powershell -NoLogo -NoProfile -Command ^
  "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { " ^
  "  $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; " ^
  "  if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress } ; " ^
  "  if($ip){ New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; " ^
  "           New-ItemProperty -Path $p -Name TCPNoDelay     -PropertyType DWord -Value 1 -Force | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Clés Nagle/DelACK poussées sur chaque interface.

:: 5.8 — QoS Psched
echo %COLOR_GREEN%[+]%COLOR_RESET% QoS (Psched) perf...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v MaxOutstandingSends /t REG_DWORD /d 65000 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v TimerResolution /t REG_DWORD /d 1 /f >nul 2>&1

:: 5.9 — CONFIGURATION DE LA CARTE RESEAU (LATENCE MINIMALE)
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration NIC (RSS/RSC/IM/EEE/LSO/VLAN/Jumbo/IFS/Buffers)...

:: RSS ON + REPARTITION CPU (EVITE CPU0)
echo %COLOR_WHITE%[*]%COLOR_RESET% Activation RSS et repartition CPU...
powershell -NoProfile -ExecutionPolicy Bypass -Command " $adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }; $lp = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors; $base = 1; $max = [Math]::Max(1,$lp-1); $adapters | Enable-NetAdapterRss -ErrorAction SilentlyContinue | Out-Null; foreach ($a in $adapters) { Set-NetAdapterRss -Name $a.Name -BaseProcessorNumber $base -MaxProcessorNumber $max -ErrorAction SilentlyContinue } " >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% RSS active et repartition appliquee.

:: RSC OFF SUR LES NIC (ON A DEJA MIS GLOBAL=DISABLED)
echo %COLOR_WHITE%[*]%COLOR_RESET% Desactivation RSC cote NIC...
powershell -NoProfile -ExecutionPolicy Bypass -Command " Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Disable-NetAdapterRsc -Name $_.Name -ErrorAction SilentlyContinue } " >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% RSC desactive sur toutes les NIC actives.

:: DESACTIVER LES BINDINGS BRUYANTS
echo %COLOR_WHITE%[*]%COLOR_RESET% Desactivation des bindings LLTD/Mapper/Responder...
powershell -NoProfile -ExecutionPolicy Bypass -Command " Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lltdio' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_implat' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_rspndr' -ErrorAction SilentlyContinue } " >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Bindings bruitants desactives.

:: PARAMETRES AVANCES (LATENCE MINIMALE) — NIC agnostique + Realtek OK
echo %COLOR_WHITE%[*]%COLOR_RESET% Application des proprietes avancees (IM/EEE/LSO/LRO/VLAN/Jumbo/IFS/Green/Power/Checksum/ARP/WoL)...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Interrupt Moderation' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Interrupt Moderation Rate' -DisplayValue 'Off' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Energy-Efficient Ethernet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Advanced EEE' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Green Ethernet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Power Saving Mode' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Gigabit Lite' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Large Send Offload v2 (IPv4)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Large Send Offload v2 (IPv6)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Large Receive Offload (IPv4)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Large Receive Offload (IPv6)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'IPv4 Checksum Offload' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'IPv6 Checksum Offload' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'TCP Checksum Offload (IPv4)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'TCP Checksum Offload (IPv6)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'UDP Checksum Offload (IPv4)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'UDP Checksum Offload (IPv6)' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Adaptive Inter-Frame Spacing' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Priority & VLAN' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Jumbo Packet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Flow Control' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'ARP Offload' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Wake on Magic Packet' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Wake on Pattern Match' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Receive Buffers' -DisplayValue '128' -ErrorAction SilentlyContinue; Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Transmit Buffers' -DisplayValue '128' -ErrorAction SilentlyContinue }" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Proprietes avancees e-sport appliquees (best-effort selon pilote).


:: 5.10 — Desactiver NDU
echo %COLOR_WHITE%[*]%COLOR_RESET% Desactivation du service NDU...
sc config ndu start= disabled >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% NDU desactive.

:: 5.11 — OPTIMISATIONS DNS
echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisation du cache DNS (eviter les collages d'echecs)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeCacheTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NetFailureCacheTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeSOACacheTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheTtl /t REG_DWORD /d 86400 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxNegativeCacheTtl /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableAutoDoh /t REG_DWORD /d 2 /f >nul

echo %COLOR_GREEN%[+]%COLOR_RESET% DNS optimise.

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations reseau appliquees avec succes.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est recommande pour appliquer toutes les modifications.

if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)


:OPTIMISATIONS_PERIPHERIQUES
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                SECTION 6: OPTIMISATIONS CLAVIER, SOURIS ET USB%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

:: 6.1 — Souris (desactivation accel, delais min, feeling brut)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres souris...
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Mouse" /v MouseAccel /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Mouse" /v MouseDelay /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Mouse" /v DoubleClickSpeed /t REG_SZ /d 400 /f >nul 2>&1 
reg add "HKCU\Control Panel\Mouse" /v SnapToDefaultButton /t REG_SZ /d 0 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Acceleration souris OFF, delais et clics optimises.

:: 6.2 — Clavier (delai minimal, repetition max)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres clavier...
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t REG_SZ /d 31 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Clavier configure: delai min et vitesse max.


:: 6.3 — Accessibilite OFF (Sticky/f >nul 2>&1ilter/Toggle Keys)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation Sticky/f >nul 2>&1ilter/Toggle Keys...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v HotkeyActive /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v Flags /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v HotkeyActive /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v HotkeyActive /t REG_SZ /d 0 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Accessibilite clavier desactivee (pas d'activation parasite).


:: 6.4 — Drivers input (mouclass/kbdclass) -> Thread priorite max
echo %COLOR_YELLOW%[*]%COLOR_RESET% Priorite max pour drivers souris/clavier...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v ThreadPriority /t REG_DWORD /d 31 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v ThreadPriority /t REG_DWORD /d 31 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Drivers input mis en priorite maximale.


:: 6.5 — USB/HID optimisations (latence reduite)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation des peripheriques USB/HID...

:: HID Input Delay Optimization
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v EnableInputDelayOptimization /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v EnableBufferedInput /t REG_DWORD /d 0 /f >nul 2>&1

:: Activer MSI (Message Signaled Interrupts) si dispo
powershell -Command "Get-PnpDevice -Class HIDClass,USB -Status OK | ForEach-Object { try { Set-ItemProperty -Path ('HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties') -Name MSISupported -Value 1 -Force } catch {} }" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% MSI activees pour USB/HID (si pilote compatible).

:: Desactiver l'option selective suspend (evite micro-coupures USB)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Selective Suspend USB desactive.


echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisations clavier, souris et USB appliquees.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)


:DESACTIVER_PERIPHERIQUES_INUTILES
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                    SECTION 7: DESACTIVATION DES PERIPHERIQUES%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Telechargement de DevManView...
set "DevManView=%temp%\DevManView.exe"
powershell -Command "& {$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://github.com/ancel1x/Ancels-Performance-Batch/raw/main/bin/DevManView.exe' -OutFile '%DevManView%' } catch { exit 1 }}" >nul 2>&1
if not exist "%DevManView%" (
    echo %COLOR_RED%[!]%COLOR_RESET% Impossible de telecharger DevManView.exe
    echo %COLOR_RED%[!]%COLOR_RESET% Les peripheriques inutiles ne seront pas desactives.
    pause
    goto :MENU_PRINCIPAL
)

%DevManView% /disable "WAN Miniport (L2TP)"
%DevManView% /disable "WAN Miniport (Network Monitor)"
%DevManView% /disable "WAN Miniport (PPPOE)"
%DevManView% /disable "WAN Miniport (PPTP)"
%DevManView% /disable "WAN Miniport (SSTP)"
%DevManView% /disable "UMBus Root Bus Enumerator"
%DevManView% /disable "Programmable Interrupt Controller"
%DevManView% /disable "High Precision Event Timer"
%DevManView% /disable "PCI Encryption/Decryption Controller"
%DevManView% /disable "AMD PSP"
%DevManView% /disable "Intel SMBus"
%DevManView% /disable "Unknown device"
%DevManView% /disable "Intel Management Engine"
%DevManView% /disable "PCI Memory Controller"
%DevManView% /disable "PCI standard RAM Controller"
%DevManView% /disable "Composite Bus Enumerator"
%DevManView% /disable "Microsoft Kernel Debug Network Adapter"
%DevManView% /disable "SM Bus Controller"
%DevManView% /disable "NDIS Virtual Network Adapter Enumerator"
%DevManView% /disable "Microsoft Virtual Drive Enumerator"
%DevManView% /disable "Numeric Data Processor"
%DevManView% /disable "Microsoft RRAS Root Enumerator"
%DevManView% /disable "Base SYSTEM Device"
%DevManView% /disable "PCI Memory Controller"
%DevManView% /disable "SM Bus Controller"
%DevManView% /disable "PCI Data Acquisition and Signal Processing Controller"
%DevManView% /disable "PCI Simple Communications Controller"
%DevManView% /disable "Microsoft Storage Spaces Controller"
%DevManView% /disable "Microsoft Windows Management Interface for ACPI"
%DevManView% /disable "Unknown device"
%DevManView% /disable "Microsoft UEFI-Compliant SYSTEM"
%DevManView% /disable "Legacy Device"
%DevManView% /disable "Intel(R) 82802 Firmware Hub Device"
%DevManView% /disable "Microsoft GS Wavetable Synth"
%DevManView% /disable "Microsoft Hyper-V Virtualization Infrastructure Driver"
%DevManView% /disable "Communications Port (COM1)"
%DevManView% /disable "Communications Port (COM2)"
%DevManView% /disable "Communications Port (SER1)"
%DevManView% /disable "Communications Port (SER2)"
%DevManView% /disable "Direct memory access Controller"
%DevManView% /disable "EISA programmable interrupt Controller"
%DevManView% /disable "SYSTEM CMOS/real time clock"
%DevManView% /disable "Remote Desktop Device Redirector Bus"
%DevManView% /disable "SYSTEM Speaker"
%DevManView% /disable "SYSTEM Timer"
%DevManView% /disable "WAN Miniport (IKEv2)"
%DevManView% /disable "WAN Miniport (IP)"
%DevManView% /disable "WAN Miniport (IPv6)"
%DevManView% /disable "WAN Miniport (L2TP)"
%DevManView% /disable "WAN Miniport (Network Monitor)"
%DevManView% /disable "WAN Miniport (PPPOE)"
%DevManView% /disable "WAN Miniport (PPTP)"
%DevManView% /disable "WAN Miniport (SSTP)"
%DevManView% /disable "UMBus Root Bus Enumerator"
%DevManView% /disable "Programmable Interrupt Controller"
%DevManView% /disable "High Precision Event Timer"
%DevManView% /disable "PCI Encryption/Decryption Controller"
%DevManView% /disable "AMD PSP"
%DevManView% /disable "Intel SMBus"
%DevManView% /disable "Unknown device"
%DevManView% /disable "Intel Management Engine"
%DevManView% /disable "PCI Memory Controller"
%DevManView% /disable "PCI standard RAM Controller"
%DevManView% /disable "Composite Bus Enumerator"
%DevManView% /disable "Microsoft Kernel Debug Network Adapter"
%DevManView% /disable "SM Bus Controller"
%DevManView% /disable "NDIS Virtual Network Adapter Enumerator"
%DevManView% /disable "Microsoft Virtual Drive Enumerator"
%DevManView% /disable "Numeric Data Processor"
%DevManView% /disable "Microsoft RRAS Root Enumerator"
%DevManView% /disable "Base SYSTEM Device"
%DevManView% /disable "PCI Memory Controller"
%DevManView% /disable "SM Bus Controller"
%DevManView% /disable "PCI Data Acquisition and Signal Processing Controller"
%DevManView% /disable "PCI Simple Communications Controller"
%DevManView% /disable "Microsoft Storage Spaces Controller"
%DevManView% /disable "Microsoft Windows Management Interface for ACPI"
%DevManView% /disable "Unknown device"
%DevManView% /disable "Microsoft UEFI-Compliant SYSTEM"
%DevManView% /disable "Legacy Device"
%DevManView% /disable "Intel(R) 82802 Firmware Hub Device"
%DevManView% /disable "Microsoft GS Wavetable Synth"
%DevManView% /disable "Microsoft Hyper-V Virtualization Infrastructure Driver"
%DevManView% /disable "Communications Port (COM1)"
%DevManView% /disable "Communications Port (COM2)"
%DevManView% /disable "Communications Port (SER1)"
%DevManView% /disable "Communications Port (SER2)"
%DevManView% /disable "Direct memory access Controller"
%DevManView% /disable "EISA programmable interrupt Controller"
%DevManView% /disable "SYSTEM CMOS/real time clock"
%DevManView% /disable "Remote Desktop Device Redirector Bus"

echo %COLOR_GREEN%[+]%COLOR_RESET% Peripheriques avances inutiles desactives avec succes.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:DESACTIVER_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                    SECTION 8: DESACTIVATION ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des economies d'energie...
echo.

:: 8.1 - Configuration generale du systeme d'alimentation
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration generale du systeme d'alimentation...
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t reg_DWORD /d 1 /f >nul 2>&1 

:: 8.2 - Desactivation du PDC et Power Throttling
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation du PDC et Power Throttling...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v EA:EnergySaverEngaged /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v EA:PowerStateDischarging /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t reg_DWORD /d 1 /f >nul 2>&1 

:: 8.3 - Optimisations processeur
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation des parametres processeur...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Processor" /v CPPCEnable /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Processor" /v Capabilities /t reg_DWORD /d 0x0007e066 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Processor" /v Cstates /t reg_DWORD /d 0 /f >nul 2>&1 
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1

:: 8.4 - Desactivation ASPM
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation ASPM (Active State Power Management)...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t reg_DWORD /d 1 /f >nul 2>&1 

:: 8.5 - Desactivation des intervalles de coalescence
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des intervalles de coalescence...
for %%k in (
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\ModernSleep"
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Power"
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Power"
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Memory Management"
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\kernel"
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Executive"
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager"
    "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control"
) do (
    reg add %%k /v CoalescingTimerInterval /t reg_DWORD /d 0 /f >nul 2>&1 
)

:: 8.6 - Optimisations peripheriques USB
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation des peripheriques USB...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USB\Parameters" /v DisableSelectiveSuspend /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBHUB\Parameters" /v DisableSelectiveSuspend /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\USBHUB3\Parameters" /v DisableSelectiveSuspend /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB\Parameters" /v EnhancedPowerManagementEnabled /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactivation economies d'energie USB via Device Parameters
for %%p in (
    EnhancedPowerManagementEnabled
    AllowIdleIrpInD3
    EnableSelectiveSuspend
    DeviceSelectiveSuspended
    SelectiveSuspendEnabled
    SelectiveSuspendOn
) do (
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB\*\Device Parameters" /v %%p /t reg_DWORD /d 0 /f >nul 2>&1 
    reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{36fc9e60-c465-11cf-8056-444553540000}\*" /v %%p /t reg_DWORD /d 0 /f >nul 2>&1 
)
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\ROOT_HUB\*\Device Parameters" /v DisableIdlePowerManagement /t reg_DWORD /d 1 /f >nul 2>&1 

:: 8.7 - Optimisations stockage et disques
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation du stockage et des disques...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "DisableStorageQoS" /t REG_DWORD /d 1 /f >nul
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Reliability" /v TimeStampInterval /t REG_DWORD /d 0 /f >nul 2>&1

:: Désactivation économies d'énergie SSD/SD
for %%d in (SD SSD) do (
  for %%s in (1 2 3) do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdleExitEnergyMicroJoules /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdleExitLatencyMs       /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdlePowerMw             /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdleTimeLengthMs         /t REG_DWORD /d 4294967295 /f >nul 2>&1
  )
)

:: Désactivation HIPM / DIPM / HDD Parking (applique uniquement là où ces valeurs existent déjà)
for %%i in (EnableHIPM EnableDIPM EnableHDDParking) do (
  for /f "tokens=*" %%a in ('
    reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%i" /v 2^>nul ^| findstr /i "^HKEY"
  ') do (
    reg add "%%a" /v %%i /t REG_DWORD /d 0 /f >nul 2>&1
  )
)

:: Configuration spécifique iaStorA (Intel RST)
for %%c in (0 1) do (
  for %%t in (HIPM DIPM) do (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\iaStorA\Parameters\Device" /v Controller0Phy%%c%%t /t REG_DWORD /d 0 /f >nul 2>&1
  )
)

:: 8.8 - Optimisations avancées des services
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations avancees des services...

:: Forcer IoLatencyCap=0 uniquement sur les clés où il existe déjà
for /f "tokens=*" %%a in ('
  reg query "HKLM\System\CurrentControlSet\Services" /s /f "IoLatencyCap" /v 2^>nul ^| findstr /i "^HKEY"
') do (
  reg add "%%a" /v IoLatencyCap /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Désactivation StorPort idle Power Management sur les périphériques détectés
for /f "tokens=*" %%a in ('
  reg query "HKLM\System\CurrentControlSet\Enum" /s /f "StorPort" /k 2^>nul ^| findstr /i "^HKEY"
') do (
  reg add "%%a" /v EnableIdlePowerManagement /t REG_DWORD /d 0 /f >nul 2>&1
)

echo %COLOR_GREEN%[+]%COLOR_RESET% Stockage/Services optimises.

:: 8.9 - Optimisations graphiques (GPU)
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation des parametres graphiques...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PerfLevelSrc /t reg_DWORD /d 2222 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PowerMizerEnable /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PowerMizerLevel /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PowerMizerLevelAC /t reg_DWORD /d 0 /f >nul 2>&1 

:: 8.10 - Optimisations PCI et peripheriques reseau
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation PCI et peripheriques reseau...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}\*" /v WakeEnabled /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}\*" /v D3ColdSupported /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\*" /v "*WakeOnPattern" /t reg_DWORD /d 0 /f >nul 2>&1 

:: 8.11 - Gérer les économies d'énergie des cartes réseau (instances \000x uniquement)
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation des cartes reseau...

for /f "tokens=*" %%K in ('
  reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"
') do (
  rem Traiter uniquement si la valeur *SpeedDuplex existe au niveau de l'instance
  reg query "%%K" /v "*SpeedDuplex" >nul 2>&1
  if not errorlevel 1 (
    echo   %COLOR_GREEN%[+]%COLOR_RESET% Configuration de l'adaptateur: %%K
    echo     %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des fonctionnalites d'economie d'energie...
    reg add "%%K" /v "*DeviceSleepOnDisconnect" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*EEE" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*ModernStandbyWoLMagicPacket" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*SelectiveSuspend" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*WakeOnMagicPacket" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*WakeOnPattern" /t REG_SZ /d 0 /f >nul 2>&1

    echo     %COLOR_GREEN%[+]%COLOR_RESET% Configuration des parametres de performance...
    reg add "%%K" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EEELinkAdvertisement" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EeePhyEnable" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EnableGreenEthernet" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EnableModernStandby" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "GigaLite" /t REG_SZ /d 0 /f >nul 2>&1

    echo     %COLOR_GREEN%[+]%COLOR_RESET% Configuration PnP et gestion d'alimentation...
    reg add "%%K" /v "PnPCapabilities" /t REG_DWORD /d 24 /f >nul 2>&1
    reg add "%%K" /v "PowerDownPll" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "PowerSavingMode" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d 0 /f >nul 2>&1

    echo     %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des fonctions de reveil...
    reg add "%%K" /v "S5WakeOnLan" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "SavePowerNowEnabled" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "ULPMode" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "WakeOnLink" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "WakeOnSlot" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "WakeUpModeCap" /t REG_SZ /d 0 /f >nul 2>&1

    echo     %COLOR_GREEN%[+]%COLOR_RESET% Configuration terminee pour cet adaptateur
  )
)

echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Toutes les optimisations d'economies d'energie ont ete appliquees avec succes.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est recommande pour que tous les changements prennent effet.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:TOGGLE_DEFENDER
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                GERER WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer Windows Defender (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver Windows Defender (Non recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if errorlevel 3 goto :MENU_PRINCIPAL
if errorlevel 2 goto :DESACTIVER_DEFENDER_SECTION
if errorlevel 1 goto :ACTIVER_DEFENDER_SECTION

:ACTIVER_DEFENDER_SECTION
cls
echo %COLOR_GREEN%[+]%COLOR_RESET% %STYLE_BOLD%Reactivation de Windows Defender...%COLOR_RESET%
echo.

:: Restaurer les strategies de registre
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des strategies de registre...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /f >nul 2>&1 

:: Restauration du moteur antimalware
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration du moteur antimalware...
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v DisableAntiVirus /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v ProductStatus /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v ManagedDefenderProductType /f >nul 2>&1 

:: Restaurer les autorisations des fichiers
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des permissions de fichiers...
icacls "C:\Program Files\Windows Defender\MsMpEng.exe" /reset >nul 2>&1
icacls "C:\Program Files\Windows Defender\MpSvc.dll" /reset >nul 2>&1

:: Restauration des fichiers executables renommes
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des executables Defender...
attrib -h "C:\Program Files\Windows Defender\*.bak" >nul 2>&1
ren "C:\Program Files\Windows Defender\MsMpEng.exe.bak" "MsMpEng.exe" >nul 2>&1
ren "C:\Program Files\Windows Defender\MpSvc.dll.bak" "MpSvc.dll" >nul 2>&1
ren "C:\Program Files\Windows Defender\MpCmdRun.exe.bak" "MpCmdRun.exe" >nul 2>&1

:: Reactiver les services Windows Defender
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des services Defender...
sc config WinDefend start= auto >nul 2>&1
sc config WdNisSvc start= demand >nul 2>&1
sc config WdNisDrv start= system >nul 2>&1
sc config WdFilter start= system >nul 2>&1
sc config Sense start= demand >nul 2>&1
sc config SecurityHealthService start= auto >nul 2>&1
sc config wscsvc start= auto >nul 2>&1

:: Redemarrage des services (si desactives)
sc start WinDefend >nul 2>&1
sc start WdNisSvc >nul 2>&1
sc start Sense >nul 2>&1
sc start SecurityHealthService >nul 2>&1
sc start wscsvc >nul 2>&1

:: Reactiver les pilotes de securite
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des pilotes de securite...
sc config WdBoot start= system >nul 2>&1
sc config WdFilter start= system >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" /v Start /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" /v Start /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t reg_DWORD /d 2 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v Start /t reg_DWORD /d 3 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv" /v Start /t reg_DWORD /d 0 /f >nul 2>&1 

:: Restauration des chemins d'execution des services
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des services systeme...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v ImagePath /t reg_EXPAND_SZ /d "\"C:\Program Files\Windows Defender\MsMpEng.exe\"" /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v ImagePath /t reg_EXPAND_SZ /d "\"C:\Program Files\Windows Defender\NisSrv.exe\"" /f >nul 2>&1 

:: Reactivation des taches planifiees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des taches planifiees Defender...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable >nul 2>&1

:: PowerShell : reactivation via Set-MpPreference
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation via PowerShell...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $false" >nul 2>&1  
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIOAVProtection $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisablePrivacyMode $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIntrusionPreventionSystem $false" >nul 2>&1
powershell -Command "Set-MpPreference -DisableScriptScanning $false" >nul 2>&1
powershell -Command "Set-MpPreference -SubmitSamplesConsent 1" >nul 2>&1
powershell -Command "Set-MpPreference -MAPSReporting 2" >nul 2>&1

:: Reactivation avancee via PowerShell
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation avancee PowerShell...
powershell -Command "try { Enable-WindowsOptionalFeature -Online -FeatureName Windows-Defender-ApplicationGuard -All } catch { }" >nul 2>&1
powershell -Command "try { Set-Service -Name WinDefend -StartupType Automatic } catch { }" >nul 2>&1
powershell -Command "try { Set-Service -Name WdNisSvc -StartupType Manual } catch { }" >nul 2>&1
powershell -Command "try { Start-Service -Name WinDefend } catch { }" >nul 2>&1
powershell -Command "try { Start-Service -Name WdNisSvc } catch { }" >nul 2>&1

echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Windows Defender a ete restaure avec succes.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est recommande pour que tous les parametres prennent effet.
pause
goto :MENU_PRINCIPAL

:DESACTIVER_DEFENDER_SECTION
cls
echo %COLOR_RED%[+]%COLOR_RESET% %STYLE_BOLD%Desactivation COMPLETE de Windows Defender...%COLOR_RESET%
echo %COLOR_YELLOW%ATTENTION: Desactiver Windows Defender expose votre systeme a des risques.%COLOR_RESET%
echo.

:: Prise de propriete du registre Defender (necessaire pour certaines modifications)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Prise de controle des cles de registre...
takeown /f >nul 2>&1 "C:\Program Files\Windows Defender" /r /d y >nul 2>&1
icacls "C:\Program Files\Windows Defender" /grant administrators:F /t >nul 2>&1

:: Desactivation via le registre (strategies avancees)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des strategies de registre avancees...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableSpecialRunningModes /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableRoutinelyTakingAction /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v ServiceKeepAlive /t reg_DWORD /d 0 /f >nul 2>&1 

:: Desactivation complete du moteur antimalware
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v DisableAntiSpyware /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v DisableAntiVirus /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v ProductStatus /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v ManagedDefenderProductType /t reg_DWORD /d 0 /f >nul 2>&1 

:: Protection en temps reel
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScanOnRealtimeEnable /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScriptScanning /t reg_DWORD /d 1 /f >nul 2>&1 

:: Desactivation des fonctionnalites de protection avancees
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v MpEnablePus /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\MpEngine" /v MpCloudBlockLevel /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SubmitSamplesConsent /t reg_DWORD /d 2 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v SpynetReporting /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" /v DisableBlockAtFirstSeen /t reg_DWORD /d 1 /f >nul 2>&1 

:: Protection contre la falsification (Tamper Protection)
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtectionSource /t reg_DWORD /d 2 /f >nul 2>&1 

:: Interface utilisateur et notifications
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration" /v Notification_Suppress /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\UX Configuration" /v UILockdown /t reg_DWORD /d 1 /f >nul 2>&1 

:: Windows Security Center
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableNotifications /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender Security Center\Notifications" /v DisableEnhancedNotifications /t reg_DWORD /d 1 /f >nul 2>&1 

echo %COLOR_GREEN%[+]%COLOR_RESET% Strategies de registre avancees appliquees.

:: Modification des permissions de fichiers critiques
echo %COLOR_YELLOW%[*]%COLOR_RESET% Modification des permissions des fichiers Defender...
takeown /f >nul 2>&1 "C:\Program Files\Windows Defender\MsMpEng.exe" >nul 2>&1
icacls "C:\Program Files\Windows Defender\MsMpEng.exe" /deny Everyone:F >nul 2>&1
takeown /f >nul 2>&1 "C:\Program Files\Windows Defender\MpSvc.dll" >nul 2>&1
icacls "C:\Program Files\Windows Defender\MpSvc.dll" /deny Everyone:F >nul 2>&1

:: Renommage/suppression des fichiers executables critiques
echo %COLOR_YELLOW%[*]%COLOR_RESET% Neutralisation des executables Defender...
ren "C:\Program Files\Windows Defender\MsMpEng.exe" "MsMpEng.exe.bak" >nul 2>&1
ren "C:\Program Files\Windows Defender\MpSvc.dll" "MpSvc.dll.bak" >nul 2>&1
ren "C:\Program Files\Windows Defender\MpCmdRun.exe" "MpCmdRun.exe.bak" >nul 2>&1
attrib +h "C:\Program Files\Windows Defender\*.bak" >nul 2>&1

:: Arret force des processus lies a Defender
echo %COLOR_YELLOW%[*]%COLOR_RESET% Arret force des processus Windows Defender...
taskkill /f >nul 2>&1 /im MsMpEng.exe >nul 2>&1
taskkill /f >nul 2>&1 /im NisSrv.exe >nul 2>&1
taskkill /f >nul 2>&1 /im SecurityHealthSystray.exe >nul 2>&1
taskkill /f >nul 2>&1 /im SecurityHealthService.exe >nul 2>&1
taskkill /f >nul 2>&1 /im "Antimalware Service Executable" >nul 2>&1
taskkill /f >nul 2>&1 /im MpCmdRun.exe >nul 2>&1
taskkill /f >nul 2>&1 /im MpSigStub.exe >nul 2>&1

:: Desactivation des services (avec dependances)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation complete des services...
sc stop WinDefend >nul 2>&1
sc config WinDefend start= disabled >nul 2>&1
sc stop WdNisSvc >nul 2>&1  
sc config WdNisSvc start= disabled >nul 2>&1
sc stop WdNisDrv >nul 2>&1
sc config WdNisDrv start= disabled >nul 2>&1
sc stop WdFilter >nul 2>&1
sc config WdFilter start= disabled >nul 2>&1
sc stop Sense >nul 2>&1
sc config Sense start= disabled >nul 2>&1
sc stop SecurityHealthService >nul 2>&1
sc config SecurityHealthService start= disabled >nul 2>&1
sc stop wscsvc >nul 2>&1
sc config wscsvc start= disabled >nul 2>&1

:: Desactivation specifique du service Antimalware
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du service Antimalware...
sc stop "Windows Defender Antivirus Service" >nul 2>&1
sc config "Windows Defender Antivirus Service" start= disabled >nul 2>&1
net stop "Windows Defender Antivirus Service" /y >nul 2>&1

:: Desactivation des pilotes
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des pilotes de protection...
sc stop WdBoot >nul 2>&1
sc config WdBoot start= disabled >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" /v Start /t reg_DWORD /d 4 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" /v Start /t reg_DWORD /d 4 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t reg_DWORD /d 4 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v Start /t reg_DWORD /d 4 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv" /v Start /t reg_DWORD /d 4 /f >nul 2>&1 

:: Desactivation des taches planifiees (complete)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de toutes les taches planifiees...
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable >nul 2>&1

:: Utilisation de PowerShell pour une desactivation plus profonde
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation via PowerShell...
powershell -Command "Set-MpPreference -DisableRealtimeMonitoring $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableBehaviorMonitoring $true" >nul 2>&1  
powershell -Command "Set-MpPreference -DisableBlockAtFirstSeen $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIOAVProtection $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisablePrivacyMode $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableIntrusionPreventionSystem $true" >nul 2>&1
powershell -Command "Set-MpPreference -DisableScriptScanning $true" >nul 2>&1
powershell -Command "Set-MpPreference -SubmitSamplesConsent 2" >nul 2>&1
powershell -Command "Set-MpPreference -MAPSReporting 0" >nul 2>&1

:: Desactivation complete via PowerShell avance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation avancee PowerShell...
powershell -Command "try { Uninstall-WindowsFeature -Name Windows-Defender-Features } catch { }" >nul 2>&1
powershell -Command "try { Disable-WindowsOptionalFeature -Online -FeatureName Windows-Defender-ApplicationGuard } catch { }" >nul 2>&1
powershell -Command "try { Set-Service -Name WinDefend -StartupType Disabled -Status Stopped } catch { }" >nul 2>&1
powershell -Command "try { Set-Service -Name WdNisSvc -StartupType Disabled -Status Stopped } catch { }" >nul 2>&1
powershell -Command "try { Get-Process MsMpEng -ErrorAction SilentlyContinue | Stop-Process -Force } catch { }" >nul 2>&1

:: Methodes extremes pour eliminer le service Antimalware
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application de methodes extremes...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v ImagePath /t reg_EXPAND_SZ /d "" /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v ImagePath /t reg_EXPAND_SZ /d "" /f >nul 2>&1 
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend\Parameters" /f >nul 2>&1 
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc\Parameters" /f >nul 2>&1 

:: Suppression des entrees de demarrage automatique
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "Windows Defender" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "SecurityHealth" /f >nul 2>&1 

:: Verifications finales
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification de l'etat des services...
sc query WinDefend | findstr /I /C:"STOPPED" >nul
if errorlevel 1 (
    echo %COLOR_RED%[!]%COLOR_RESET% Service WinDefend encore actif - tentative d'arret force...
    net stop WinDefend /y >nul 2>&1
    sc stop WinDefend >nul 2>&1
) else (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Service WinDefend confirme comme arrete.
)

sc query WdNisSvc | findstr /I /C:"STOPPED" >nul
if errorlevel 1 (
    echo %COLOR_RED%[!]%COLOR_RESET% Service WdNisSvc encore actif - tentative d'arret force...
    net stop WdNisSvc /y >nul 2>&1
) else (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Service WdNisSvc confirme comme arrete.
)

:: Verification des processus
tasklist | findstr /I "MsMpEng.exe" >nul
if not errorlevel 1 (
    echo %COLOR_RED%[!]%COLOR_RESET% Processus MsMpEng.exe encore en cours - tentative d'arret force...
    taskkill /f >nul 2>&1 /im MsMpEng.exe >nul 2>&1
    wmic process where "name='MsMpEng.exe'" delete >nul 2>&1
) else (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Processus MsMpEng.exe confirme comme arrete.
)

:: Verification du service Antimalware
tasklist | findstr /I "Antimalware Service Executable" >nul
if not errorlevel 1 (
    echo %COLOR_RED%[!]%COLOR_RESET% Service Antimalware encore actif - arret force...
    taskkill /f >nul 2>&1 /im "Antimalware Service Executable" >nul 2>&1
    wmic process where "name='MsMpEng.exe'" delete >nul 2>&1
) else (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Service Antimalware confirme comme arrete.
)

echo.
echo %COLOR_RED%[+]%COLOR_RESET% %STYLE_BOLD%Windows Defender a ete COMPLETEMENT desactive.%COLOR_RESET%
echo %COLOR_YELLOW%[!]%COLOR_RESET% %STYLE_BOLD%Redemarrage recommande pour une desactivation complete.%COLOR_RESET%
echo %COLOR_YELLOW%[!]%COLOR_RESET% Certaines modifications necessitent un redemarrage pour prendre effet.
pause
goto :MENU_PRINCIPAL

:TOGGLE_UAC
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                GERER UAC (CONTROLE DE COMPTE UTILISATEUR)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer UAC (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver UAC (Non recommande, risques de securite accrus)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if errorlevel 3 goto :MENU_PRINCIPAL
if errorlevel 2 goto :DESACTIVER_UAC_SECTION
if errorlevel 1 goto :ACTIVER_UAC_SECTION

:ACTIVER_UAC_SECTION
cls
echo %COLOR_GREEN%[+]%COLOR_RESET% Activation de l'UAC (Controle de Compte Utilisateur)...
echo.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% UAC active. Un redemarrage est requis pour appliquer les changements.
pause
goto :MENU_PRINCIPAL

:DESACTIVER_UAC_SECTION
cls
echo %COLOR_RED%[+]%COLOR_RESET% %STYLE_BOLD%Desactivation de l'UAC (Controle de Compte Utilisateur)...%COLOR_RESET%
echo %COLOR_YELLOW%ATTENTION: Desactiver l'UAC reduit la securite de votre systeme.%COLOR_RESET%
echo.
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul 2>&1 
echo %COLOR_RED%[+]%COLOR_RESET% %STYLE_BOLD%UAC desactive. Un redemarrage est requis pour appliquer les changements.%COLOR_RESET%
pause
goto :MENU_PRINCIPAL

:TOGGLE_ANIMATIONS
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                GERER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer les animations Windows (experience utilisateur standard)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver les animations Windows (pour optimiser les performances)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if errorlevel 3 goto :MENU_PRINCIPAL
if errorlevel 2 goto :DESACTIVER_ANIMATIONS_SECTION
if errorlevel 1 goto :ACTIVER_ANIMATIONS_SECTION

:ACTIVER_ANIMATIONS_SECTION
cls
echo %COLOR_GREEN%[+]%COLOR_RESET% Activation des animations Windows...
echo.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t reg_BINARY /d 9E3E078012000000 /f >nul 2>&1 
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t reg_SZ /d "1" /f >nul 2>&1 
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v Animations /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t reg_DWORD /d 1 /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableAnimations" /f >nul 2>&1 
echo %COLOR_GREEN%[+]%COLOR_RESET% Animations Windows activees.
pause
goto :MENU_PRINCIPAL

:DESACTIVER_ANIMATIONS_SECTION
cls
echo %COLOR_RED%[+]%COLOR_RESET% Desactivation des animations Windows pour ameliorer les performances...
echo.
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t reg_DWORD /d 3 /f >nul 2>&1 
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t reg_BINARY /d "9012038010000000" /f >nul 2>&1 
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t reg_SZ /d "0" /f >nul 2>&1 
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "Animations" /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableAnimations" /t reg_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_RED%[+]%COLOR_RESET% Animations Windows desactivees.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Redemarrage de l'Explorateur Windows pour appliquer certains changements d'animation...
taskkill /f >nul 2>&1 /im explorer.exe >nul 2>&1
start explorer.exe
echo %COLOR_GREEN%[+]%COLOR_RESET% Explorateur Windows redemarre.
pause
goto :MENU_PRINCIPAL

:DESINSTALLER_ONEDRIVE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%           DESINSTALLATION COMPLETE DE ONEDRIVE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Tentative de desinstallation de OneDrive...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre quelques instants.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de vouloir continuer (O/N) ? %COLOR_RESET%"
if errorlevel 2 goto :MENU_PRINCIPAL

:: Arreter les processus OneDrive
taskkill /f >nul 2>&1 /im OneDrive.exe >nul 2>&1
taskkill /f >nul 2>&1 /im OneDriveSetup.exe >nul 2>&1
taskkill /f >nul 2>&1 /im FileCoAuth.exe >nul 2>&1
taskkill /f >nul 2>&1 /im FileSyncHelper.exe >nul 2>&1
taskkill /f >nul 2>&1 /im OneDriveStandaloneUpdater.exe >nul 2>&1
timeout /t 3 >nul
taskkill /f >nul 2>&1 /im explorer.exe >nul 2>&1
start explorer.exe

echo %COLOR_YELLOW%[*]%COLOR_RESET% Deconnexion des comptes OneDrive...
powershell -Command "try { Import-Module -Name Microsoft.PowerShell.Management -Force; Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts' -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1

:: Commande pour desinstaller OneDrive
if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
    "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" /uninstall
) else (
    "%SYSTEMROOT%\System32\OneDriveSetup.exe" /uninstall
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des cles de registre OneDrive...
reg delete "HKEY_CLASSES_ROOT\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f >nul 2>&1 
reg delete "HKEY_CLASSES_ROOT\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" /f >nul 2>&1 
reg delete "HKCU\SOFTWARE\Microsoft\OneDrive" /f >nul 2>&1 
reg delete "HKCU\SOFTWARE\Microsoft\SkyDrive" /f >nul 2>&1 
reg delete "HKCU\SOFTWARE\Classes\OneDrive" /f >nul 2>&1 
reg delete "HKCU\Environment" /v OneDrive /f >nul 2>&1 
reg delete "HKCU\Environment" /v OneDriveConsumer /f >nul 2>&1 
reg delete "HKCU\Environment" /v OneDriveCommercial /f >nul 2>&1 
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDriveSetup /f >nul 2>&1 
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Run" /v OneDrive /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\OneDrive" /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\OneDrive" /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1 

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des taches planifiees OneDrive...
for /f >nul 2>&1 "tokens=1 delims=," %%x in ('schtasks /query /f >nul 2>&1o csv 2^>nul ^| find "OneDrive"') do (
    schtasks /delete /TN %%x /f >nul 2>&1 
)

echo %COLOR_GREEN%[+]%COLOR_RESET% Desinstallation de OneDrive terminee (si installe).
echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des dossiers OneDrive restants...
if exist "%LocalAppData%\Microsoft\OneDrive" (
    rd "%LocalAppData%\Microsoft\OneDrive" /q /s >nul 2>&1
)
if exist "%AppData%\Microsoft\OneDrive" (
    rd "%AppData%\Microsoft\OneDrive" /q /s >nul 2>&1
)
if exist "%SystemDrive%\OneDriveTemp" (
    rd "%SystemDrive%\OneDriveTemp" /q /s >nul 2>&1
)
for %%C in (
    "%LocalAppData%\Microsoft\OneDrive\logs"
    "%LocalAppData%\Microsoft\OneDrive\settings"
    "%LocalAppData%\Temp\OneDrive*"
    "%Temp%\OneDrive*"
) do (
    if exist "%%C" (
        rd "%%C" /q /s >nul 2>&1
        del "%%C" /q /s /f >nul 2>&1 
    )
)
takeown /f >nul 2>&1 "%USERPROFILE%\OneDrive" /r /d y >nul 2>&1
rd "%USERPROFILE%\OneDrive" /s /q >nul 2>&1
takeown /f >nul 2>&1 "%LOCALAPPDATA%\Microsoft\OneDrive" /r /d y >nul 2>&1
rd "%LOCALAPPDATA%\Microsoft\OneDrive" /s /q >nul 2>&1
takeown /f >nul 2>&1 "%PROGRAMDATA%\Microsoft OneDrive" /r /d y >nul 2>&1
rd "%PROGRAMDATA%\Microsoft OneDrive" /s /q >nul 2>&1
takeown /f >nul 2>&1 "%SystemDrive%\OneDriveTemp" /r /d y >nul 2>&1
rd "%SystemDrive%\OneDriveTemp" /s /q >nul 2>&1

:: Supprimer les raccourcis OneDrive du menu Demarrer
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft OneDrive.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%UserProfile%\Links\OneDrive.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%UserProfile%\Desktop\OneDrive.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f >nul 2>&1 /q >nul 2>&1

echo %COLOR_GREEN%[+]%COLOR_RESET% Nettoyage complet de OneDrive termine.
pause
goto :MENU_PRINCIPAL

:DESINSTALLER_EDGE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%           DESINSTALLATION COMPLETE DE MICROSOFT EDGE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_RED%ATTENTION: La desinstallation de Microsoft Edge peut entrainer des problemes%COLOR_RESET%
echo %COLOR_RED%de compatibilite avec certaines applications Windows.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de vouloir continuer (O/N) ? %COLOR_RESET%"
if errorlevel 2 goto :MENU_PRINCIPAL

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%              SUPPRESSION DES DONNEES UTILISATEUR%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%Voulez-vous supprimer les donnees utilisateur d'Edge ?%COLOR_RESET%
echo %COLOR_WHITE%- Historique de navigation%COLOR_RESET%
echo %COLOR_WHITE%- Cookies et donnees de sites%COLOR_RESET%
echo %COLOR_WHITE%- Favoris/Signets%COLOR_RESET%
echo %COLOR_WHITE%- Mots de passe sauvegardes%COLOR_RESET%
echo %COLOR_WHITE%- Extensions et themes%COLOR_RESET%
echo %COLOR_WHITE%- Parametres et preferences%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Supprimer les donnees utilisateur (O/N) ? %COLOR_RESET%"
if errorlevel 2 (
    set "SUPPR_DATA=NON"
    echo %COLOR_GREEN%[+]%COLOR_RESET% Les donnees utilisateur seront preservees.
) else (
    set "SUPPR_DATA=OUI"
    echo %COLOR_RED%[-]%COLOR_RESET% Les donnees utilisateur seront supprimees.
)

echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Debut de la desinstallation...

echo %COLOR_YELLOW%[*]%COLOR_RESET% Arret des processus Edge...
taskkill /f >nul 2>&1 /im msedge.exe >nul 2>&1
taskkill /f >nul 2>&1 /im MicrosoftEdgeUpdate.exe >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression de l'icone Edge de la barre des taches...

:: Suppression ciblee des raccourcis Edge uniquement
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f >nul 2>&1 /q >nul 2>&1

:: Parcourir le dossier TaskBar et supprimer uniquement les raccourcis Edge
if exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" (
    for %%f in ("%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk") do (
        findstr /i "edge" "%%f" >nul 2>&1 && del "%%f" /f >nul 2>&1 /q >nul 2>&1
    )
)
echo %COLOR_GREEN%[+]%COLOR_RESET% Raccourci Edge supprime (les autres icones sont preservees)

:: Desinstallation de Microsoft Edge
echo %COLOR_YELLOW%[*]%COLOR_RESET% Tentative de desinstallation de Microsoft Edge...
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" (
    cd /d "%ProgramFiles(x86)%\Microsoft\Edge\Application"
    for /d %%i in (*) do (
        if exist "%%i\Installer\setup.exe" (
            echo %COLOR_GREEN%[+]%COLOR_RESET% Execution setup.exe...
            "%%i\Installer\setup.exe" --uninstall --system-level --verbose-logging --force-uninstall
        )
    )
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage force des dossiers programme...
rd "%ProgramFiles%\Microsoft\Edge" /s /q >nul 2>&1
rd "%ProgramFiles(x86)%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des cles de registre Edge...
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Edge" /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Edge" /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1 
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\EdgeUpdate" /f >nul 2>&1 

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des taches planifiees Edge...
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f >nul 2>&1 
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f >nul 2>&1 

:: Gestion conditionnelle des donnees utilisateur
if "%SUPPR_DATA%"=="OUI" (
    echo %COLOR_RED%[*]%COLOR_RESET% Suppression des donnees utilisateur Edge...
    
    :: Suppression des profils utilisateur Edge
    if exist "%LOCALAPPDATA%\Microsoft\Edge" rd "%LOCALAPPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    if exist "%APPDATA%\Microsoft\Edge" rd "%APPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    
    :: Suppression des cles registre utilisateur
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge" /f >nul 2>&1 
    
    echo %COLOR_RED%[-]%COLOR_RESET% Donnees utilisateur supprimees.
) else (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Conservation des donnees utilisateur...
    
    :: On garde les donnees mais on supprime juste les cles systeme
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\BrowserSwitcher" /f >nul 2>&1 
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\PreferenceMACs" /f >nul 2>&1 
    
    echo %COLOR_GREEN%[+]%COLOR_RESET% Donnees utilisateur preservees.
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des donnees systeme communes...
rd "%PROGRAMDATA%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des raccourcis...
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%ALLUSERSPROFILE%\Desktop\Microsoft Edge.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%PUBLIC%\Desktop\Microsoft Edge.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f >nul 2>&1 /q >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f >nul 2>&1 /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des associations de fichiers...
reg delete "HKLM\SOFTWARE\Classes\MSEdgeHTM" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Classes\MSEdgePDF" /f >nul 2>&1 
reg delete "HKLM\SOFTWARE\Classes\Applications\msedge.exe" /f >nul 2>&1 

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage de l'index de recherche Windows...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1 
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_http" /f >nul 2>&1 
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_https" /f >nul 2>&1 

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des entrees du menu demarrer...
rd "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
rd "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache d'icones Edge...
:: Suppression du cache d'icones Windows (IconCache.db)
del "%LOCALAPPDATA%\IconCache.db" /f >nul 2>&1 /q >nul 2>&1
del "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" /f >nul 2>&1 /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des references Edge dans MUI Cache...
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1 
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "C:\Program Files\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1 

echo %COLOR_YELLOW%[*]%COLOR_RESET% Blocage des reinstallations automatiques...
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t reg_DWORD /d 1 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "InstallDefault" /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "PreventFirstRunPage" /t reg_DWORD /d 1 /f >nul 2>&1 

echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification finale...
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
) else (
    if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
    ) else (
        echo %COLOR_GREEN%[+]%COLOR_RESET% Microsoft Edge desinstalle avec succes !
        echo %COLOR_GREEN%[+]%COLOR_RESET% Icone supprimee de la barre des taches !
        if "%SUPPR_DATA%"=="OUI" (
            echo %COLOR_RED%[-]%COLOR_RESET% Donnees utilisateur supprimees.
        ) else (
            echo %COLOR_GREEN%[+]%COLOR_RESET% Donnees utilisateur conservees.
        )
    )
)

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_GREEN%[+]%COLOR_RESET% Desinstallation terminee !
if "%SUPPR_DATA%"=="NON" (
    echo %COLOR_YELLOW%[i]%COLOR_RESET% Vos favoris, mots de passe et historique ont ete preserves.
)
echo %COLOR_YELLOW%[i]%COLOR_RESET% L'icone Edge a ete supprimee de la barre des taches.
echo %COLOR_YELLOW%[i]%COLOR_RESET% Si des elements persistent, redemarrez Windows.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
pause
goto :MENU_PRINCIPAL

:OUTIL_ACTIVATION
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%           OUTIL D'ACTIVATION WINDOWS / OFFICE (MAS)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Lancement de l'outil d'activation...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Veuillez suivre les instructions a l'ecran.
powershell "irm https://get.activated.win | iex"
echo %COLOR_GREEN%[+]%COLOR_RESET% Outil d'activation termine.
pause
goto :MENU_PRINCIPAL

:OUTIL_CHRIS_TITUS
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%           OUTIL CHRIS TITUS TECH (WINUTIL)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Lancement de l'outil Chris Titus Tech...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Veuillez suivre les instructions a l'ecran.
powershell "irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1 | iex"
echo %COLOR_GREEN%[+]%COLOR_RESET% Outil Chris Titus Tech termine.
pause
goto :MENU_PRINCIPAL

:TOUT_OPTIMISER_DESKTOP
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                Application de toutes les optimisations (Desktop)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette option va appliquer toutes les optimisations pour Desktop.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre plusieurs minutes.
echo.

cls
:: Application des optimisations systeme
call :OPTIMISATIONS_SYSTEME call
:: Application des optimisations memoire
call :OPTIMISATIONS_MEMOIRE call
:: Application des optimisations disques
call :OPTIMISATIONS_DISQUES call
:: Application des optimisations reseau
call :OPTIMISATIONS_RESEAU call
:: Optimisation des peripheriques
call :OPTIMISATIONS_PERIPHERIQUES call
:: Desactivation des peripheriques avances
call :DESACTIVER_PERIPHERIQUES_INUTILES call
:: Desactivation des economies d'energie
call :DESACTIVER_ECONOMIES_ENERGIE call

cls
echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_GREEN%[+]%COLOR_RESET% Toutes les optimisations Desktop ont ete appliquees avec succes.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est recommande pour appliquer toutes les modifications.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo.
choice /C YN /M "%COLOR_WHITE%Voulez-vous redemarrer maintenant%COLOR_RESET%"
if errorlevel 2 goto :MENU_PRINCIPAL
if errorlevel 1 shutdown /r /t 3 /c "Redemarrage pour appliquer les optimisations"
goto :MENU_PRINCIPAL

:TOUT_OPTIMISER_LAPTOP
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                Application de toutes les optimisations (Laptop)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette option va appliquer toutes les optimisations pour Laptop.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Certaines economies d'energie seront conservees pour la batterie.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre plusieurs minutes.
echo.

cls
:: Application des optimisations systeme
call :OPTIMISATIONS_SYSTEME call
:: Application des optimisations memoire
call :OPTIMISATIONS_MEMOIRE call
:: Application des optimisations disques
call :OPTIMISATIONS_DISQUES call
:: Application des optimisations GPU
call :OPTIMISATIONS_GPU call
:: Application des optimisations reseau
call :OPTIMISATIONS_RESEAU call

cls
echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_GREEN%[+]%COLOR_RESET% Toutes les optimisations Laptop ont ete appliquees avec succes.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est recommande pour appliquer toutes les modifications.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo.
choice /C YN /M "%COLOR_WHITE%Voulez-vous redemarrer maintenant%COLOR_RESET%"
if errorlevel 2 goto :MENU_PRINCIPAL
if errorlevel 1 shutdown /r /t 3 /c "Redemarrage pour appliquer les optimisations"
goto :MENU_PRINCIPAL

:CREER_POINT_RESTAURATION
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                        Creation d'un point de restauration%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Creation d'un point de restauration...

:: Verifier si la restauration systeme est activee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification et activation de la restauration systeme si necessaire...
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" >nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la restauration systeme...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /t reg_DWORD /d 1 /f >nul 2>&1 
    powershell -Command "Enable-ComputerRestore -Drive 'C:'" >nul 2>&1
)
echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Creation d'un point de restauration en cours...

powershell -Command "Checkpoint-Computer -Description 'Point de restauration avant optimisations Windows' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if %errorlevel% EQU 0 (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Point de restauration cree avec succes.
) else (
    echo %COLOR_RED%[!]%COLOR_RESET% Echec de la creation du point de restauration.
)
pause
goto :MENU_PRINCIPAL

:NETTOYAGE_AVANCE_WINDOWS
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                            NETTOYAGE DE WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Analyse de l'espace disque initial...

:: Obtenir espace libre AVANT (en Mo)
for /f %%a in ('powershell -nologo -command "[int]((Get-PSDrive -Name C).Free / 1MB)"') do set space_before=%%a

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 1: NETTOYAGE DES FICHIERS TEMPORAIRES%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des fichiers temporaires Windows...
del /s /q /f >nul 2>&1 "%temp%\*.*" >nul 2>&1
del /s /q /f >nul 2>&1 "C:\Windows\Temp\*.*" >nul 2>&1
del /s /q /f >nul 2>&1 "C:\Windows\Prefetch\*.*" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Fichiers temporaires supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache Windows Update...
net stop wuauserv /y >nul 2>&1
timeout /t 2 /nobreak >nul
del /s /q /f >nul 2>&1 "C:\Windows\SoftwareDistribution\Download\*.*" >nul 2>&1
net start wuauserv >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Cache Windows Update nettoye

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 2: NETTOYAGE SYSTEME ET COMPOSANTS%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des journaux systeme...
del /s /q /f >nul 2>&1 "C:\Windows\Logs\*.log" >nul 2>&1
del /s /q /f >nul 2>&1 "C:\Windows\System32\LogFiles\*.log" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Journaux systeme supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des journaux CBS (Windows Update)...
del /s /q /f >nul 2>&1 "C:\Windows\Logs\CBS\*.*" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Journaux CBS nettoyes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache de polices...
del /s /q /f >nul 2>&1 "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /s /q /f >nul 2>&1 "C:\Windows\System32\FNTCACHE.DAT" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Cache de polices nettoye


echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des fichiers de mise a jour obsoletes...
powershell -Command "Get-ChildItem -Path 'C:\Windows\WinSxS\ManifestCache\' -Force -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Fichiers de mise a jour nettoyes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des composants WinSxS (ResetBase, peut prendre du temps)...
dism /online /cleanup-image /startcomponentcleanup /resetbase >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Composants WinSxS nettoyes (ResetBase)

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 3: NETTOYAGE FINAL%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration Cleanmgr (SAGESET:1) pour nettoyage maximal...
set "SAGEID=0001"
for %%K in (
    "Active Setup Temp Folders"
    "BranchCache"
    "Content Indexer Cleaner"
    "Delivery Optimization Files"
    "Device Driver Packages"
    "DirectX Shader Cache"
    "Downloaded Program Files"
    "Internet Cache Files"
    "Language Pack"
    "Memory Dump Files"
    "Microsoft Office Temp Files"
    "Old ChkDsk Files"
    "Previous Installations"
    "Recycle Bin"
    "RetailDemo Offline Content"
    "Service Pack Cleanup"
    "Setup Log Files"
    "System error memory dump files"
    "System error minidump files"
    "Temporary Files"
    "Temporary Setup Files"
    "Thumbnail Cache"
    "Update Cleanup"
    "Windows Defender"
    "Windows Error Reporting Archive Files"
    "Windows Error Reporting Queue Files"
    "Windows Error Reporting System Archive Files"
    "Windows Error Reporting System Queue Files"
    "Windows ESD installation files"
    "Windows Upgrade Log Files"
) do (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v StateFlags%SAGEID% /t reg_DWORD /d 2 /f >nul 2>&1 
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage systeme avec Cleanmgr (SAGERUN:1)...
start /b /wait cleanmgr /sagerun:1 /d C: >nul 2>&1
timeout /t 3 /nobreak >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Nettoyage systeme Cleanmgr termine

:: Obtenir espace libre APRES (en Mo)
for /f %%a in ('powershell -nologo -command "[int]((Get-PSDrive -Name C).Free / 1MB)"') do set space_after=%%a
set /a space_freed=%space_after% - %space_before%

echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_WHITE%                            RAPPORT DE NETTOYAGE%COLOR_RESET%
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Espace disque avant    : %COLOR_YELLOW%%space_before% Mo%COLOR_RESET%
echo %COLOR_WHITE%Espace disque apres    : %COLOR_GREEN%%space_after% Mo%COLOR_RESET%
echo %COLOR_WHITE%Espace total libere    : %COLOR_CYAN%%space_freed% Mo%COLOR_RESET%
echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_GREEN%[+]%COLOR_RESET% Nettoyage termine avec succes !
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est recommande pour finaliser le nettoyage.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%

pause
goto :MENU_PRINCIPAL

:END_SCRIPT
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                                AU REVOIR !%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Merci d'avoir utilise le script d'optimisation !
echo %COLOR_YELLOW%[!]%COLOR_RESET% N'oubliez pas de redemarrer votre PC pour que les changements prennent effet.
echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
timeout /t 3 /nobreak >nul
exit

:: Si execute dans Windows Terminal/VS Code, relancer dans une fenetre CMD dediee (conhost)
if defined WT_SESSION (
	start "" cmd.exe /k "mode con: cols=120 lines=45 & \"%~f0\" --relaunch"
	exit /b
)
if /I "%1"=="--relaunch" shift



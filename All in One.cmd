@echo off
setlocal EnableDelayedExpansion

:: Activer les sequences d'echappement ANSI pour les couleurs
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Definir le titre de la console
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

:: ===========================================================================
:: CONVENTION DES INDICATEURS ET COULEURS
:: ===========================================================================
:: [*]       JAUNE   = Action en cours d'execution
:: [OK]      VERT    = Action terminee avec succes
:: [TERMINE] VERT    = Section completee
:: [INFO]    JAUNE   = Information / Conseil
:: [!]       JAUNE   = Avertissement (attention requise)
:: [-]       ROUGE   = Suppression / Action negative
:: [ERREUR]  ROUGE   = Erreur critique / Echec
:: [ATTENTION] ROUGE = Risque de securite
:: ===========================================================================


:: VERIFICATION DES PRE-REQUIS
echo %COLOR_YELLOW%[*] Verification des prerequis...%COLOR_RESET%
net session >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Ce script necessite des privileges administrateur.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Veuillez l'executer en tant qu'administrateur.
    pause
    exit /B 1
)

:: VERIFICATION DE POWERSHELL
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% PowerShell n'est pas disponible sur ce systeme.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Ce script necessite PowerShell pour fonctionner correctement.
    pause
    exit /B 1
)

:: VERIFICATION DE L'ACCES INTERNET
ping 8.8.8.8 -n 1 -w 1000 >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Pas d'acces Internet detecte.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Ce script necessite une connexion Internet pour fonctionner.
    pause
    exit /B 1
)

echo %COLOR_GREEN%[OK]%COLOR_RESET% Prerequis verifies avec succes.
echo.
timeout /t 1 /nobreak >nul
goto :MENU_PRINCIPAL

:MENU_PRINCIPAL
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Script d'Optimisation Windows - All in One%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Detection du type de systeme (PC fixe ou portable)
set "IS_LAPTOP=0"
for /f %%i in ('powershell -NoProfile -Command "if(Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue){Write-Output 1} else {Write-Output 0}"') do (
    if %%i gtr 0 set "IS_LAPTOP=1"
)
if "%IS_LAPTOP%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE%SYSTEME DETECTE:%COLOR_RESET% %COLOR_GREEN%PC PORTABLE%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE%SYSTEME DETECTE:%COLOR_RESET% %COLOR_GREEN%PC FIXE%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS GENERALES ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Optimisations Systeme%COLOR_RESET% %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Optimisations Memoire%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Optimisations Disques%COLOR_RESET% %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Optimisations GPU%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Optimisations Reseau%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- PC BUREAUTIQUES UNIQUEMENT ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_GREEN%Optimisations Clavier/Souris%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_GREEN%Desactiver Peripheriques Inutiles%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_GREEN%Desactiver Economies d'Energie%COLOR_RESET%
echo %COLOR_YELLOW%[9]%COLOR_RESET% %COLOR_RED%Desactiver Protections Securite (Spectre/Meltdown)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS ALL IN ONE ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_WHITE%Optimiser tout (PC de Bureau)%COLOR_RESET%
echo %COLOR_YELLOW%[L]%COLOR_RESET% %COLOR_WHITE%Optimiser tout (PC Portable)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[N]%COLOR_RESET% %COLOR_CYAN%Nettoyage Avance de Windows%COLOR_RESET%
echo %COLOR_YELLOW%[R]%COLOR_RESET% %COLOR_CYAN%Creer un Point de Restauration%COLOR_RESET%
echo %COLOR_YELLOW%[G]%COLOR_RESET% %COLOR_MAGENTA%Gestion Windows (Defender, UAC, Edge, OneDrive...)%COLOR_RESET%
echo %COLOR_YELLOW%[W]%COLOR_RESET% %COLOR_MAGENTA%Outil activation Windows / Office (MAS)%COLOR_RESET%
echo %COLOR_YELLOW%[T]%COLOR_RESET% %COLOR_MAGENTA%Outil Chris Titus Tech (WinUtil)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[Q]%COLOR_RESET% %STYLE_BOLD%%COLOR_RED%Quitter le script%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 123456789DLNRGWTQ /N /M "%STYLE_BOLD%%COLOR_YELLOW%Veuillez choisir une option [1-9, D, L, N, R, G, W, T, Q]: %COLOR_RESET%"

:: Gestion des choix (du plus grand au plus petit pour errorlevel)
if errorlevel 17 goto :END_SCRIPT
if errorlevel 16 goto :OUTIL_CHRIS_TITUS
if errorlevel 15 goto :OUTIL_ACTIVATION
if errorlevel 14 goto :MENU_GESTION_WINDOWS
if errorlevel 13 goto :CREER_POINT_RESTAURATION
if errorlevel 12 goto :NETTOYAGE_AVANCE_WINDOWS
if errorlevel 11 goto :TOUT_OPTIMISER_LAPTOP
if errorlevel 10 goto :TOUT_OPTIMISER_DESKTOP
if errorlevel 9 goto :DESACTIVER_PROTECTIONS_SECURITE
if errorlevel 8 goto :DESACTIVER_ECONOMIES_ENERGIE
if errorlevel 7 goto :DESACTIVER_PERIPHERIQUES_INUTILES
if errorlevel 6 goto :OPTIMISATIONS_PERIPHERIQUES
if errorlevel 5 goto :OPTIMISATIONS_RESEAU
if errorlevel 4 goto :OPTIMISATIONS_GPU
if errorlevel 3 goto :OPTIMISATIONS_DISQUES
if errorlevel 2 goto :OPTIMISATIONS_MEMOIRE
if errorlevel 1 goto :OPTIMISATIONS_SYSTEME
goto :MENU_PRINCIPAL

:MENU_GESTION_WINDOWS
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                    GESTION WINDOWS                    %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Ce menu regroupe toutes les options pour gerer les fonctionnalites%COLOR_RESET%
echo %COLOR_WHITE%  et composants Windows (securite, interface, applications Microsoft).%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_BLUE%--- SECURITE ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Gerer Windows Defender%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Gerer UAC (Controle de Compte Utilisateur)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- INTERFACE ---%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Gerer les Animations Windows%COLOR_RESET%
echo %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Gerer Copilot / Widgets / Recall (Windows 11)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- APPLICATIONS MICROSOFT ---%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_RED%Desinstaller OneDrive Completement%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_RED%Desinstaller Edge Completement%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
choice /C 123456M /N /M "%COLOR_YELLOW%Choisissez une option [1-6, M]: %COLOR_RESET%"
if errorlevel 7 goto :MENU_PRINCIPAL
if errorlevel 6 goto :DESINSTALLER_EDGE
if errorlevel 5 goto :DESINSTALLER_ONEDRIVE
if errorlevel 4 goto :TOGGLE_COPILOT
if errorlevel 3 goto :TOGGLE_ANIMATIONS
if errorlevel 2 goto :TOGGLE_UAC
if errorlevel 1 goto :TOGGLE_DEFENDER
goto :MENU_GESTION_WINDOWS

:OPTIMISATIONS_SYSTEME
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%              SECTION 1 : OPTIMISATIONS SYSTEME              %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Optimise le noyau Windows, desactive la telemetrie et configure%COLOR_RESET%
echo %COLOR_WHITE%  l'interface pour de meilleures performances generales.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 1.1 - Priorites CPU et planification
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des priorites CPU et de la planification...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v IoPriority /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ0Priority /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v IRQ8Priority /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v ThreadBoostType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v Win32PrioritySeparation /t REG_DWORD /d 38 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Priorites CPU configurees

:: 1.2 - Profil Gaming MMCSS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil gaming (MMCSS)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NoLazyMode /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Profil gaming (MMCSS)configures

:: 1.3 - Interface Windows
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de l'interface Windows...

:: Barre des taches : suppression des elements inutiles
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowTaskViewButton /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCortanaButton /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarMn /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1

:: Explorateur : menu contextuel classique + affichages optimises
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v HideFileExt /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowSyncProviderNotifications /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DontPrettyPath /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v DesktopLivePreviewHoverTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1

:: Delai d'affichage des menus a 0ms
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1

:: Accelerer l'ouverture/fermeture des fenetres
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d "2000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d "1000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v LowLevelHooksTimeout /t REG_DWORD /d 1000 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v WaitToKillServiceTimeout /t REG_SZ /d "2000" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v WaitToKillServiceTimeout /t REG_SZ /d "2000" /f >nul 2>&1


:: Desactiver Inking & Typing personalization
reg add "HKCU\Software\Microsoft\InputPersonalization" /v RestrictImplicitInkCollection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v RestrictImplicitTextCollection /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1

:: Optimiser le cache d'icones et miniatures
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "Max Cached Icons" /t REG_SZ /d "8192" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >nul 2>&1

:: Optimiser le demarrage du shell Explorer
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v DesktopProcess /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v SeparateProcess /t REG_DWORD /d 1 /f >nul 2>&1

:: Pave numerique et options developpeur
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v InitialKeyboardIndicators /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Interface Windows ultra-optimisee

:: Desactiver la compression des papiers peints (100 = qualite maximale sans compression CPU)
reg add "HKCU\Control Panel\Desktop" /v JPEGImportQuality /t REG_DWORD /d 100 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Compression des papiers peints desactivee

:: 1.4 - Telemetrie et vie privee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la telemetrie et des traceurs...
:: Services de telemetrie
sc stop DiagTrack >nul 2>&1 & sc config DiagTrack start= disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1 & sc config dmwappushservice start= disabled >nul 2>&1
sc stop diagnosticshub.standardcollector.service >nul 2>&1 & sc config diagnosticshub.standardcollector.service start= disabled >nul 2>&1
sc config RetailDemo start= disabled >nul 2>&1
sc stop WerSvc >nul 2>&1 & sc config WerSvc start= disabled >nul 2>&1
sc config AJRouter start= disabled >nul 2>&1
sc config RemoteRegistry start= disabled >nul 2>&1
sc config RemoteAccess start= disabled >nul 2>&1

:: Registre : telemetrie et publicites
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v AllowTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowSluggishnessTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableConsumerFeatures /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v DisableTailoredExperiences /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul 2>&1

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DoNotShowFeedbackNotifications /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1

:: Content Delivery Manager (desactive suggestions, publicites, apps preinstallees)
for %%V in (ContentDeliveryAllowed FeatureManagementEnabled OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled RemediationRequired RotatingLockScreenEnabled RotatingLockScreenOverlayEnabled SilentInstalledAppsEnabled SoftLandingEnabled SubscribedContentEnabled SystemPaneSuggestionsEnabled SubscribedContent-310093Enabled SubscribedContent-338380Enabled SubscribedContent-338381Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled) do (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v %%V /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Recherche Windows - Bing OFF
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v BingSearchEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v CortanaConsent /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v ConnectedSearchUseWeb /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1

:: Wi-Fi Sense OFF
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v Value /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v Value /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Telemetrie et publicites desactivees

:: Taches planifiees de telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des taches planifiees de telemetrie...
for %%T in (
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "Microsoft\Windows\Application Experience\StartupAppTask"
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "Microsoft\Windows\Feedback\Siuf\DmClient"
    "Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "Microsoft\Windows\PI\Sqm-Tasks"
) do schtasks /Change /TN "%%~T" /Disable >nul 2>&1

:: Autologgers de diagnostic OFF
for %%L in (AppModel Cellcore DiagLog SQMLogger Diagtrack-Listener) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\%%~L" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot" /v Start /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Taches de telemetrie desactivees

:: Blocage telemetrie via hosts
echo %COLOR_YELLOW%[*]%COLOR_RESET% Ajout des blocages telemetrie dans le fichier hosts...
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"

:: Verifier si deja ajoute
findstr /c:"Telemetry Block" "%HOSTS%" >nul 2>&1
if not errorlevel 1 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Blocages telemetrie deja presents dans hosts
    goto :HOSTS_DONE
)

:: Ajouter les blocages
echo.>> "%HOSTS%"
echo # --- Telemetry Block (Optimizer Script) --->> "%HOSTS%"
echo 0.0.0.0 vortex.data.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 vortex-win.data.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 telecommand.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 telecommand.telemetry.microsoft.com.nsatc.net>> "%HOSTS%"
echo 0.0.0.0 oca.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 oca.telemetry.microsoft.com.nsatc.net>> "%HOSTS%"
echo 0.0.0.0 sqm.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 sqm.telemetry.microsoft.com.nsatc.net>> "%HOSTS%"
echo 0.0.0.0 watson.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 watson.telemetry.microsoft.com.nsatc.net>> "%HOSTS%"
echo 0.0.0.0 redir.metaservices.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 choice.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 choice.microsoft.com.nsatc.net>> "%HOSTS%"
echo 0.0.0.0 df.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 reports.wes.df.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 services.wes.df.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 sqm.df.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 watson.ppe.telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 telemetry.appex.bing.net>> "%HOSTS%"
echo 0.0.0.0 telemetry.urs.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 settings-sandbox.data.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 survey.watson.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 watson.live.com>> "%HOSTS%"
echo 0.0.0.0 statsfe2.ws.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 corpext.msitadfs.glbdns2.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 compatexchange.cloudapp.net>> "%HOSTS%"
echo 0.0.0.0 statsfe1.ws.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 feedback.microsoft-hohm.com>> "%HOSTS%"
echo 0.0.0.0 feedback.windows.com>> "%HOSTS%"
echo 0.0.0.0 feedback.search.microsoft.com>> "%HOSTS%"
echo # --- End Telemetry Block --->> "%HOSTS%"
echo %COLOR_GREEN%[OK]%COLOR_RESET% Domaines de telemetrie bloques via hosts

:HOSTS_DONE

:: Services en mode Manual
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des services en mode Manuel...
:: Services de base non-critiques
for %%S in (CDPSvc MapsBroker PcaSvc StorSvc StateRepository TextInputManagementService UsoSvc cbdhsvc lfsvc WalletService PhoneSvc icssvc WMPNetworkSvc) do (
  sc config %%S start= demand >nul 2>&1
)
:: Services supplementaires
for %%S in (ALG AxInstSV BDESVC CertPropSvc CscService DmEnrollmentSvc DsSvc EFS EntAppSvc Fax FrameServer GraphicsPerfSvc HvHost IEEtwCollectorService IKEEXT InstallService InventorySvc IpxlatCfgSvc KtmRm LicenseManager LxpSvc MSDTC MSiSCSI McpManagementService MixedRealityOpenXRSvc MsKeyboardFilter NaturalAuthentication NcaSvc NcdAutoSetup NetSetupSvc PNRPAutoReg PNRPsvc PeerDistSvc PlugPlay PolicyAgent PrintNotify QWAVE RasAuto RasMan RetailDemo RmSvc RpcLocator SCPolicySvc SCardSvr SDRSVC SEMgrSvc SNMPTRAP ScDeviceEnum SharedRealitySvc SmsRouter SstpSvc StiSvc TabletInputService TapiSrv TieringEngineService TokenBroker TroubleshootingSvc UI0Detect UmRdpService W32Time WEPHOSTSVC WFDSConMgrSvc WManSvc WPDBusEnum WSService WaaSMedicSvc WarpJITSvc WbioSrvc WcsPlugInService WdiServiceHost WdiSystemHost Wecsvc WerSvc WiaRpc WinRM WpcMonSvc autotimesvc camsvc cloudidsvc dcsvc diagsvc dmwappushservice dot3svc embeddedmode fdPHost fhsvc hidserv lltdsvc lmhosts netprofm p2pimsvc p2psvc perceptionsimulation pla seclogon smphost spectrum svsvc swprv upnphost vds wbengine wcncsvc wercplsupport wisvc wlidsvc wlpasvc wmiApSrv workfolderssvc) do (
  sc config %%S start= demand >nul 2>&1
)
:: Services a desactiver (suggestions, telemetrie, inutiles)
for %%S in (AJRouter AppVClient AssignedAccessManagerSvc NetTcpPortSharing RemoteAccess RemoteRegistry UevAgentService shpamsvc ssh-agent uhssvc DialogBlockingService SystemSuggestions CDPUserSvc) do (
  sc config %%S start= disabled >nul 2>&1
)
:: tzautoupdate en manual pour conserver le changement heure ete/hiver
sc config tzautoupdate start= demand >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services optimises (mode Manuel/Desactive)

:: 1.5 - Optimisations demarrage et systeme
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations de demarrage...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v StartupDelayInMSec /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableInventory /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v DisableUAR /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v AITEnable /t REG_DWORD /d 0 /f >nul 2>&1

:: Activer les sauvegardes automatiques du registre (desactive depuis W10 1803)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f >nul 2>&1

:: Desactivation de l'animation de demarrage Windows
bcdedit /set bootuxdisabled on >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Animation de demarrage desactivee

:: Assistant Stockage
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de l'Assistant Stockage...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 01 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 04 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 08 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 32 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v 2048 /t REG_DWORD /d 7 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Assistant Stockage configure

:: MSI
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation des interruptions MSI...
powershell -NoLogo -NoProfile -Command "Get-PnpDevice -Class @('Display','HDC','SCSIAdapter','System') -Status OK | ForEach-Object { $p='HKLM:\SYSTEM\CurrentControlSet\Enum\'+$_.InstanceId+'\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if (Test-Path $p) { Set-ItemProperty -Path $p -Name MSISupported -Value 1 -Force } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Interruptions MSI activees

:: Batterie - Energy Saver
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: 1.6 - Navigateurs
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation des navigateurs...
reg add "HKCU\Software\Microsoft\Edge\Main" /v EnablePreload /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Google\Chrome\Prerender" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsMode /t REG_SZ /d automatic /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Navigateurs optimises

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations systeme appliquees.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:OPTIMISATIONS_MEMOIRE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%              SECTION 2 : OPTIMISATIONS MEMOIRE              %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la gestion de la RAM et du fichier d'echange%COLOR_RESET%
echo %COLOR_WHITE%  pour ameliorer les performances en jeu et reduire la latence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 2.1 - Pagefile
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du fichier d'echange (PageFile) pour arrêt rapide...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SystemPages /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagefileEncryption /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fichier d'echange optimise (kernel en RAM)

:: 2.2 - Prefetch/SysMain
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du Prefetch et SuperFetch pour le gaming...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t REG_DWORD /d 0 /f >nul 2>&1
sc stop SysMain >nul 2>&1
sc config SysMain start= auto >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Prefetch actif, SuperFetch optimise pour les jeux

:: 2.3 - FTH OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du tas tolerant aux pannes (FTH)...
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\FTH\State" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% FTH desactive - Performances memoire ameliorees


:: 2.4 - Disable memory compression
powershell -NoProfile -NoLogo -Command "Disable-MMAgent -mc" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Compression memoire desactivee

:: 2.5 - SvcHost - Reduire le nombre de processus svchost.exe (selon RAM)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation SvcHost selon la RAM disponible...
for /f "tokens=2 delims==" %%M in ('wmic computersystem get TotalPhysicalMemory /value 2^>nul ^| find "="') do set "RAM_BYTES=%%M"
set /a RAM_KB=!RAM_BYTES:~0,-3! 2>nul
if defined RAM_KB (
    if !RAM_KB! GEQ 8388608 (
        reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v SvcHostSplitThresholdInKB /t REG_DWORD /d !RAM_KB! /f >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% SvcHost optimise - Moins de processus en arriere-plan
    ) else (
        echo %COLOR_YELLOW%[!]%COLOR_RESET% RAM insuffisante pour optimisation SvcHost ^(moins de 8Go^)
    )
) else (
    echo %COLOR_YELLOW%[!]%COLOR_RESET% Impossible de detecter la RAM - SvcHost non modifie
)

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations memoire appliquees avec succes.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
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
echo %STYLE_BOLD%%COLOR_WHITE%         SECTION 3 : OPTIMISATIONS DISQUES ET STOCKAGE       %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise les SSD/HDD pour des temps de chargement%COLOR_RESET%
echo %COLOR_WHITE%  reduits et une meilleure reactivite du systeme.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres NTFS et activation du TRIM...
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set memoryusage 1 >nul 2>&1
fsutil behavior set mftzone 2 >nul 2>&1
fsutil behavior set disablecompression 1 >nul 2>&1
fsutil behavior set encryptpagingfile 0 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres NTFS optimises - TRIM actif, metadonnees reduites

:: 3.2 - NTFS optimise
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation I/O NTFS (NVMe)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v MaximumOutstandingRequests /t REG_DWORD /d 256 /f >nul 2>&1
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation des chemins longs (plus de 260 caracteres)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Support des chemins longs active

:: 3.3 - TRIM/ReTRIM tous volumes SSD detectes
echo %COLOR_YELLOW%[*]%COLOR_RESET% Execution du TRIM sur les disques SSD detectes...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ssd=Get-PhysicalDisk|?{$_.MediaType -eq 'SSD'};if($ssd){Write-Host 'SSD detecte(s):' $ssd.Count;Get-Volume|?{$_.DriveLetter -and $_.FileSystem -match 'NTFS|ReFS'}|%{Start-Job {Optimize-Volume -DriveLetter $args[0] -ReTrim -ErrorAction SilentlyContinue} -ArgumentList $_.DriveLetter|Out-Null}}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Commande TRIM executee sur les SSD

:: 3.4 - Enable prefetcher
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 3 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Prefetcher active pour un demarrage plus rapide

:: 3.5 - Optimisation pilote NVMe natif (2025)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NativeNVMePerformance /t REG_DWORD /d 1 /f >nul 2>&1
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations des disques appliquees avec succes.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
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
echo %STYLE_BOLD%%COLOR_WHITE%                 SECTION 4 : OPTIMISATIONS GPU               %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise votre carte graphique pour reduire l'input lag%COLOR_RESET%
echo %COLOR_WHITE%  et maximiser les performances en jeu.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 4.1 - GameDVR desactive - Game Mode ON
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'enregistrement automatique de gameplay...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AudioCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "CursorCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "HistoricalCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_EFSEFeatureFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_FSEBehavior /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SYSTEM\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% GameDVR desactive - Game Mode conserve pour les performances

:: 4.2 - Activation du VRR et du mode Flip Model pour DirectX
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation du VRR et du mode Flip Model pour DirectX...
reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% DirectX optimise avec VRR et Flip Model actifs

:: 4.3 - Desactivation NVIDIA telemetry
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la telemetrie NVIDIA (collecte de donnees)...
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm\Global\Startup" /v "SendTelemetryData" /t REG_DWORD /d 0 /f >nul 2>&1
sc config NvTelemetryContainer start= disabled >nul 2>&1
sc stop NvTelemetryContainer >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Telemetrie NVIDIA desactivee

:: 4.4 - Desactivation AMD telemetry et ULPS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la telemetrie AMD et ULPS...
reg add "HKLM\SOFTWARE\AMD\CN" /v "CollectGIData" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\ATI ACE\AUEPLauncher" /v "ReportProcessedEvents" /t REG_DWORD /d 0 /f >nul 2>&1
:: ULPS OFF - AMD
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v EnableUlps /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v EnableUlps_NA /t REG_SZ /d 0 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Telemetrie AMD et ULPS desactives

:: 4.5 - NVIDIA Low Latency
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations Low Latency NVIDIA...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v LOWLATENCY /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v D3PCLatency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v F1TransitionLatency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v Node3DLowLatency /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mode Low Latency active - Reduction de l'input lag

:: 4.6 - PowerMizer
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du gestionnaire d'energie GPU (PowerMizer)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PowerMizerEnable /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PowerMizerLevel /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PerfLevelSrc /t REG_DWORD /d 2222 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v DisableDynamicPstate /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v RmDisableRegistryCaching /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% PowerMizer configure pour performances maximales

:: 4.7 - WriteCombining
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de la stabilite GPU (WriteCombining)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v DisableWriteCombining /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Stabilite GPU amelioree

:: 4.8 - HAGS Enable
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la planification GPU acceleree (HAGS)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% HAGS active - Latence GPU reduite

:: 4.9 - NVIDIA Profile Inspector
:: Detection GPU NVIDIA pour Profile Inspector via PowerShell
set "HAS_NVIDIA=0"
for /f %%i in ('powershell -NoProfile -Command "if((Get-WmiObject Win32_VideoController).Name -match 'NVIDIA'){Write-Output 1}else{Write-Output 0}"') do set "HAS_NVIDIA=%%i"

if "%HAS_NVIDIA%"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% GPU NVIDIA detecte - Configuration NVIDIA Profile Inspector...
    set "NPI_DIR=%TEMP%\NvidiaProfileInspector"
    
    :: Creer le dossier temporaire
    if not exist "%TEMP%\NvidiaProfileInspector" mkdir "%TEMP%\NvidiaProfileInspector"
    
    :: Telecharger NVIDIA Profile Inspector
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement de NVIDIA Profile Inspector...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/NVIDIA%%20Inspector/nvidiaProfileInspector.exe' -OutFile '%TEMP%\NvidiaProfileInspector\nvidiaProfileInspector.exe' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
    if not exist "%TEMP%\NvidiaProfileInspector\nvidiaProfileInspector.exe" (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement de NVIDIA Profile Inspector
        goto :NPI_DONE
    )
    
    :: Telecharger le profil optimise
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement du profil gaming optimise...
    powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/NVIDIA%%20Inspector/Kaylers_profile.nip' -OutFile '%TEMP%\NvidiaProfileInspector\Kaylers_profile.nip' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
    if not exist "%TEMP%\NvidiaProfileInspector\Kaylers_profile.nip" (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement du profil
        goto :NPI_DONE
    )
    
    :: Appliquer le profil
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Application du profil NVIDIA optimise...
    start "" "%TEMP%\NvidiaProfileInspector\nvidiaProfileInspector.exe" "%TEMP%\NvidiaProfileInspector\Kaylers_profile.nip"
    ping -n 3 127.0.0.1 >nul 2>&1
    taskkill /f /im nvidiaProfileInspector.exe >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Profil NVIDIA Profile Inspector applique
    
    :: Nettoyage
    del "%TEMP%\NvidiaProfileInspector\nvidiaProfileInspector.exe" >nul 2>&1
    del "%TEMP%\NvidiaProfileInspector\Kaylers_profile.nip" >nul 2>&1
    rmdir "%TEMP%\NvidiaProfileInspector" >nul 2>&1
) else (
    echo %COLOR_YELLOW%[!]%COLOR_RESET% GPU NVIDIA non detecte - NVIDIA Profile Inspector ignore
)

:NPI_DONE
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Toutes les optimisations GPU ont ete appliquees.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:OPTIMISATIONS_RESEAU
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%        SECTION 5 : OPTIMISATIONS RESEAU ET INTERNET        %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la pile TCP/IP pour reduire le ping%COLOR_RESET%
echo %COLOR_WHITE%  et ameliorer la stabilite de la connexion en jeu.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de la pile TCP/IP pour faible latence...
:: 5.1 - Pas de throttling reseau par MMCSS
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1

:: 5.2 - Pile TCP/UDP moderne (CUBIC / BBR2)
netsh int tcp set heuristics disabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
:: netsh int tcp set supplemental template=internet congestionprovider=cubic >nul 2>&1
netsh int tcp set activepremium template=internet congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=internet congestionprovider=bbr2 >nul 2>&1
:: Correctif Loopback BBR2 (Windows 11 24H2)
netsh int ip set global loopbacklargemtu=disabled >nul 2>&1
netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1
netsh int tcp set global rss=enabled rsc=disabled ecncapability=disabled >nul 2>&1
netsh int udp set global uso=enabled ero=disabled >nul 2>&1
netsh int ip set global sourceroutingbehavior=drop >nul 2>&1
netsh int ip set global dhcpmediasense=disabled >nul 2>&1
netsh int ip set global mediasenseeventlog=disabled >nul 2>&1
netsh int ip set global icmpredirects=disabled >nul 2>&1
netsh int ipv6 set global neighborcachelimit=4096 >nul 2>&1
netsh int tcp set global fastopen=enabled fastopenfallback=enabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global netdma=disabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1
powershell -NoProfile -NoLogo -Command "try{Set-NetTCPSetting -SettingName Internet -InitialRtoMs 2000}catch{}" >nul 2>&1

:: 5.3 TCP registre
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1

:: Par interface
for /f "tokens=*" %%I in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" 2^>nul') do (
  reg add "%%I" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%I" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%I" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
)

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1

:: 5.6b - BITS Optimization (Telechargements rapides)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du service BITS (Telechargements)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v EnableBypassProxyForLocal /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOn-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOff-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Service BITS optimise

:: 5.7 - Priorites de resolution DNS
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v LocalPriority /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v HostsPriority /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v DnsPriority /t REG_DWORD /d 6 /f >nul 2>&1

:: 5.8 - ISATAP/Teredo OFF
netsh int isatap set state disabled >nul 2>&1
netsh int teredo set state disabled >nul 2>&1

:: 5.9 - Nagle/DelACK OFF
powershell -NoLogo -NoProfile -Command ^
  "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { " ^
  " $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; " ^
  " if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress } ; " ^
  " if($ip){ " ^
  " New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; " ^
  " New-ItemProperty -Path $p -Name TCPNoDelay -PropertyType DWord -Value 1 -Force | Out-Null; " ^
  " New-ItemProperty -Path $p -Name DelayedAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; " ^
  " New-ItemProperty -Path $p -Name DelayedAckTicks -PropertyType DWord -Value 1 -Force | Out-Null " ^
  " } }" >nul 2>&1

:: 5.10 - QoS Psched
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul 2>&1

:: 5.11 - NIC : RSS ON, RSC OFF, epuration bindings (aucune affinite forcee)
powershell -NoProfile -NoLogo -Command "$adp=Get-NetAdapter|? Status -eq 'Up'; foreach($a in $adp){ try{Enable-NetAdapterRss -Name $a.Name -ErrorAction Stop}catch{}; try{Disable-NetAdapterRsc -Name $a.Name -ErrorAction Stop}catch{} }" >nul 2>&1
powershell -NoProfile -NoLogo -Command "Get-NetAdapter | ? Status -eq 'Up' | % { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lltdio' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_implat' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_rspndr' -ErrorAction SilentlyContinue }" >nul 2>&1

:: 5.12 - NIC latence faible
powershell -NoProfile -NoLogo -Command "Get-NetAdapter | ? Status -eq 'Up' | % { $adapter=$_; try{Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName 'Interrupt Moderation' -DisplayValue 'Enabled' -ErrorAction SilentlyContinue}catch{}; try{Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword '*InterruptModeration' -RegistryValue 1 -ErrorAction SilentlyContinue}catch{}; try{Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword '*InterruptModerationRate' -RegistryValue 1 -ErrorAction SilentlyContinue}catch{}; 'Energy-Efficient Ethernet','Advanced EEE','Green Ethernet','Power Saving Mode','Gigabit Lite' | % { try{Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $_ -DisplayValue 'Disabled' -ErrorAction SilentlyContinue}catch{} }; 'Large Send Offload v2 (IPv4)','Large Send Offload v2 (IPv6)','Large Receive Offload (IPv4)','Large Receive Offload (IPv6)' | % { try{Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName $_ -DisplayValue 'Disabled' -ErrorAction SilentlyContinue}catch{} } }" >nul 2>&1

:: 5.13 - DNS cache optimise + DoH auto
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du cache DNS...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeCacheTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NetFailureCacheTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeSOACacheTime /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheTtl /t REG_DWORD /d 3600 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxNegativeCacheTtl /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheEntryTtlLimit /t REG_DWORD /d 86400 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxSOACacheEntryTtlLimit /t REG_DWORD /d 300 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableAutoDoh /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v DohFlags /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v ServerPriorityTimeLimit /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache DNS optimise (resolution plus rapide)

:: 5.14 - QoS Fortnite DSCP 46
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Version" /t REG_SZ /d "1.0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Application Name" /t REG_SZ /d "FortniteClient-Win64-Shipping.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Protocol" /t REG_SZ /d "17" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Local Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Remote Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Local IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "Remote IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /v "DSCP Value" /t REG_SZ /d "46" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Version" /t REG_SZ /d "1.0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Application Name" /t REG_SZ /d "FortniteClient-Win64-Shipping.exe" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Protocol" /t REG_SZ /d "6" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Local Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Remote Port" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Local IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "Remote IP" /t REG_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /v "DSCP Value" /t REG_SZ /d "46" /f >nul 2>&1
gpupdate /target:computer /force >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Pile reseau optimisee avec priorite gaming

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations reseau appliquees avec succes.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:OPTIMISATIONS_PERIPHERIQUES
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%       SECTION 6 : OPTIMISATIONS CLAVIER, SOURIS ET USB     %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive l'acceleration souris et optimise%COLOR_RESET%
echo %COLOR_WHITE%  la reactivite des peripheriques d'entree.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'acceleration souris et des delais...
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseDelay /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v SnapToDefaultButton /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Acceleration souris desactivee - Mouvement 1:1 actif

:: 6.2 - Clavier optimise
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de la reactivite clavier...
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t REG_SZ /d "31" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Clavier configure - Delai minimal et vitesse maximale

:: 6.3 - Accessibilite OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des raccourcis d'accessibilite (Sticky/Filter/Toggle Keys)...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v HotkeyActive /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v Flags /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v HotkeyActive /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v HotkeyActive /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourcis d'accessibilite desactives - Plus d'activation accidentelle

:: 6.4 - USB Selective Suspend OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation USB - Desactivation de la mise en veille selective...
powercfg /setacvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 0 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% USB optimise - Latence minimale sur secteur

:: 6.5 - DMA Remapping off
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PnP\Pci" /v DmaRemappingCompatible /t REG_DWORD /d 0 /f >nul 2>&1
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\PnP\Pci" /v DeviceInterruptRoutingPolicy /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% DMA Remapping desactive - Reduction de la latence

:: 6.6 - Threads souris/clavier priorite maximale
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v ThreadPriority /t REG_DWORD /d 31 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v ThreadPriority /t REG_DWORD /d 31 /f >nul 2>&1

:: 6.7 - HID parse : desactive buffering + active traitement direct
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v EnableInputDelayOptimization /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v EnableBufferedInput /t REG_DWORD /d 0 /f >nul 2>&1

:: 6.8 - Réduit la taille de la file d'attente souris et clavier
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t REG_DWORD /d 32 /f >nul 2>&1

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Optimisations des peripheriques appliquees avec succes.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
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
echo %STYLE_BOLD%%COLOR_WHITE%       SECTION 7 : DESACTIVATION DES PERIPHERIQUES          %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive les peripheriques inutiles%COLOR_RESET%
echo %COLOR_WHITE%  pour reduire la consommation de ressources systeme.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement de DevManView...
set "DevManView=%temp%\DevManView.exe"
powershell -Command "& {$ProgressPreference='SilentlyContinue'; try { Invoke-WebRequest -Uri 'https://github.com/ancel1x/Ancels-Performance-Batch/raw/main/bin/DevManView.exe' -OutFile '%DevManView%' } catch { exit 1 }}" >nul 2>&1
if not exist "%DevManView%" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Impossible de telecharger DevManView.exe
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% Les peripheriques inutiles ne seront pas desactives.
    pause
    goto :MENU_PRINCIPAL
)

:: --- Debug / virtualisation inutiles ---
%DevManView% /disable "Microsoft Kernel Debug Network Adapter"

:: --- Ports serie anciens (inutiles sur cartes meres modernes) ---
%DevManView% /disable "Communications Port (COM1)"
%DevManView% /disable "Communications Port (COM2)"
%DevManView% /disable "Communications Port (SER1)"
%DevManView% /disable "Communications Port (SER2)"

:: --- WAN miniports inutiles (laisser IP/IPv6 si VPN) ---
%DevManView% /disable "WAN Miniport (Network Monitor)"
%DevManView% /disable "WAN Miniport (PPPOE)"
%DevManView% /disable "WAN Miniport (PPTP)"
%DevManView% /disable "WAN Miniport (L2TP)"
%DevManView% /disable "WAN Miniport (SSTP)"
%DevManView% /disable "WAN Miniport (IKEv2)"

:: --- Enumerateurs logiciels rarement utiles ---
%DevManView% /disable "SteelSeries Sonar Virtual Audio Device"

echo %COLOR_GREEN%[OK]%COLOR_RESET% Peripheriques inutiles desactives

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Peripheriques inutiles desactives avec succes.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:DESACTIVER_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%      SECTION 8 : DESACTIVATION DES ECONOMIES D'ENERGIE     %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive les fonctions d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  pour maintenir les performances maximales en permanence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 8.1 - Activation du plan Ultimate Performance (methode universelle + detection intelligente)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification du plan d'alimentation actif...

:: GUIDs des plans Windows par defaut (universels)
:: Equilibre : 381b4222-f694-41f0-9685-ff5bb260df2e
:: Economies  : a1841308-3541-4fab-bc81-f71556f20b4a
:: Perf. elev : 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

set "ACTIVE_GUID="
set "NEED_ULTIMATE=0"

:: 1. Verifier le plan ACTIF
for /f "tokens=2 delims=:()" %%G in ('powercfg /getactivescheme 2^>nul') do (
    set "ACTIVE_GUID=%%G"
)
if defined ACTIVE_GUID set "ACTIVE_GUID=!ACTIVE_GUID: =!"

:: Si le plan actif est un des 3 par defaut, on a besoin d'optimiser
if "!ACTIVE_GUID!"=="381b4222-f694-41f0-9685-ff5bb260df2e" set "NEED_ULTIMATE=1"
if "!ACTIVE_GUID!"=="a1841308-3541-4fab-bc81-f71556f20b4a" set "NEED_ULTIMATE=1"
if "!ACTIVE_GUID!"=="8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" set "NEED_ULTIMATE=1"

if "!NEED_ULTIMATE!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate/Personnalise deja actif - aucune action requise
    goto :ULTIMATE_DONE
)

:: 2. Si on est sur un plan par defaut, chercher un plan Ultimate existant
echo %COLOR_YELLOW%[*]%COLOR_RESET% Recherche d'un plan Ultimate existant...
set "TARGET_GUID="
set "BEST_MATCH_GUID="

:: Lister tous les plans NON par defaut
for /f "tokens=*" %%L in ('powercfg -list 2^>nul ^| findstr /v "381b4222 a1841308 8c5e7fda" ^| findstr /i "GUID"') do (
    :: Extraire le GUID
    for /f "tokens=2 delims=:()" %%G in ("%%L") do set "TEMP_GUID=%%G"
    
    :: Garder ce GUID comme candidat potentiel (seulement si pas encore de meilleur match)
    if not defined BEST_MATCH_GUID set "TARGET_GUID=!TEMP_GUID!"
    
    :: Si le nom contient Ultimate ou optimale, c'est le meilleur candidat
    echo %%L | findstr /i "Ultimate optimale" >nul 2>&1
    if not errorlevel 1 set "BEST_MATCH_GUID=!TEMP_GUID!"
)

:: Utiliser le meilleur candidat (nomme Ultimate) ou le premier custom trouve
if defined BEST_MATCH_GUID set "TARGET_GUID=!BEST_MATCH_GUID!"
if defined TARGET_GUID set "TARGET_GUID=!TARGET_GUID: =!"

:: 3. Activer ou Creer
if defined TARGET_GUID (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Plan personnalise trouve - Activation...
    powercfg -setactive !TARGET_GUID! >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate Performance active
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Aucun plan personnalise trouve - Creation Ultimate Performance...
    for /f "tokens=2 delims=:()" %%G in ('powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2^>nul') do (
        set "TARGET_GUID=%%G"
    )
    if defined TARGET_GUID set "TARGET_GUID=!TARGET_GUID: =!"
    
    if defined TARGET_GUID (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate Performance cree
        powercfg -setactive !TARGET_GUID! >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate Performance active
    ) else (
        echo %COLOR_RED%[!]%COLOR_RESET% Echec creation plan Ultimate
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Essayez la commande: powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61
    )
)

:ULTIMATE_DONE

:: 8.2 - Desactivation du demarrage rapide (Fast Startup) pour stabilite
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du demarrage rapide (Fast Startup)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Demarrage rapide desactive - Redemarrages propres

:: 8.3 - Desactivation de l'hibernation (PC Bureau uniquement - libere ~16Go)
if "%IS_LAPTOP%"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'hibernation ^(PC Bureau^)...
    powercfg /hibernate off >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Hibernation desactivee - Espace disque libere
) else (
    echo %COLOR_YELLOW%[!]%COLOR_RESET% Hibernation conservee ^(PC Portable detecte^)
)

:: 8.4 - Configuration generale du systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du systeme d'alimentation...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 8.5 - Desactivation des Timer Coalescing et DPC (augmente la conso, pour PC de bureau)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des Timer Coalescing et optimisation DPC...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v MinimumDpcRate /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1
bcdedit /set disabledynamictick yes >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_BINARY /d 00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\ModernSleep" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Timer Coalescing desactive - Latence reduite

:: 8.6 - Installation SetTimerResolution (0.5ms)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de SetTimerResolution...
set "STR_EXE=C:\Windows\SetTimerResolution.exe"
set "STR_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"

:: Verifier si deja installe
if exist "%STR_EXE%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution deja installe dans C:\Windows
    goto :STR_SHORTCUT
)

:: Telecharger SetTimerResolution.exe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement de SetTimerResolution.exe...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe' -OutFile '%STR_EXE%' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if not exist "%STR_EXE%" (
    echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement de SetTimerResolution
    goto :STR_DONE
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution installe dans C:\Windows

:STR_SHORTCUT
:: Verifier si raccourci existe deja
if exist "%STR_STARTUP%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci de demarrage deja present
    goto :STR_DONE
)

:: Telecharger le raccourci
echo %COLOR_YELLOW%[*]%COLOR_RESET% Creation du raccourci de demarrage...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe%%20-%%20Raccourci.lnk' -OutFile '%STR_STARTUP%' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if exist "%STR_STARTUP%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci ajoute au demarrage automatique
) else (
    echo %COLOR_YELLOW%[!]%COLOR_RESET% Impossible de creer le raccourci - creation manuelle recommandee
)

:STR_DONE

:: 8.7 - Desactivation du PDC et Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du Power Throttling (bridage CPU)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1

:: 8.8 - Gestion processeur (equilibree, pas de forcage 100%)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil processeur (performances maximales)...
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1

:: 8.9 - Intel / AMD Hybrid CPU Scheduling Visibility (P-cores / E-cores)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Déblocage des options de scheduling hybride (P-Cores/E-Cores)...
:: Heterogeneous thread scheduling policy
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
:: Core Parking (P-cores class 1)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
:: Core Parking (E-cores class 0)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1

:: 8.10 - Desactivation ASPM
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation ASPM sur le bus PCI Express...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t REG_DWORD /d 1 /f >nul 2>&1

:: 8.10 - Optimisations stockage et disques
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la mise en veille des disques...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisableStorageQoS /t REG_DWORD /d 1 /f >nul 2>&1
for %%i in (EnableHIPM EnableDIPM EnableHDDParking) do (
  for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%i" /v 2^>nul ^| findstr /i "^HKEY"') do (
    reg add "%%a" /v %%i /t REG_DWORD /d 0 /f >nul 2>&1
  )
)

:: 8.11 - Optimisations avancees des services
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des limites de latence I/O...
for /f "tokens=*" %%a in ('reg query "HKLM\System\CurrentControlSet\Services" /s /f "IoLatencyCap" /v 2^>nul ^| findstr /i "^HKEY"') do (
  reg add "%%a" /v IoLatencyCap /t REG_DWORD /d 0 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Limites de latence stockage supprimees

:: 8.12 - GPU (PowerMizer)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration GPU en mode performances maximales...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PreferMaxPerf /t REG_DWORD /d 1 /f >nul 2>&1

:: 8.13 - PCI & peripheriques reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la mise en veille des peripheriques PCI...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}\*" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}\*" /v "*WakeOnPattern" /t REG_DWORD /d 0 /f >nul 2>&1

:: 8.14 - Cartes reseau (instances detectees)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des fonctions d'economie d'energie reseau...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg query "%%K" /v "*SpeedDuplex" >nul 2>&1
  if not errorlevel 1 (
    :: Economies d'energie
    reg add "%%K" /v "*EEE" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*SelectiveSuspend" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*WakeOnMagicPacket" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EnableGreenEthernet" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "ULPMode" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*WakeOnPattern" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*PMARPOffload" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*PMNSOffload" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*PMWiFiRekeyOffload" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EnablePME" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "PowerSavingMode" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "ReduceSpeedOnPowerDown" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EnableDynamicPowerGating" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "AutoPowerSaveModeEnabled" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "AdvancedEEE" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EEELinkAdvertisement" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "GigaLite" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "S5WakeOnLan" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "WakeOnLink" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "WolShutdownLinkSpeed" /t REG_SZ /d 2 /f >nul 2>&1
    :: Optimisations latence (Intel, Realtek, Killer)
    reg add "%%K" /v "*FlowControl" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "*InterruptModeration" /t REG_SZ /d 1 /f >nul 2>&1
    reg add "%%K" /v "*InterruptModerationRate" /t REG_SZ /d 1 /f >nul 2>&1
    reg add "%%K" /v "ITR" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "EnableLLI" /t REG_SZ /d 1 /f >nul 2>&1
    reg add "%%K" /v "EnableDownShift" /t REG_SZ /d 0 /f >nul 2>&1
    reg add "%%K" /v "WaitAutoNegComplete" /t REG_SZ /d 0 /f >nul 2>&1
    :: Desactiver "Allow computer to turn off this device" via PnPCapabilities
    reg add "%%K" /v PnPCapabilities /t REG_DWORD /d 24 /f >nul 2>&1
  )
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Economies d'energie et optimisations reseau appliquees sur toutes les cartes

:: 8.15 - Energie PCIe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation gestion d'energie PCIe...
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion d'energie PCIe desactivee

:: 8.16 - Desactiver USB Selective Suspend (evite deconnexions souris/clavier gaming)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation USB Selective Suspend...
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% USB Selective Suspend desactive - Peripheriques gaming stables

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Economies d'energie desactivees - Performances maximales actives.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:DESACTIVER_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%  SECTION 9 : DESACTIVATION DES PROTECTIONS DE SECURITE   %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_RED%  AVERTISSEMENT :%COLOR_RESET%
echo %COLOR_WHITE%  Cette section desactive les protections contre les vulnerabilites%COLOR_RESET%
echo %COLOR_WHITE%  materielles (Spectre, Meltdown) et certaines mitigations noyau.%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Avantages : Reduction de la latence systeme, moins d'overhead CPU%COLOR_RESET%
echo %COLOR_WHITE%  Risques   : Exposition a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 9.1 - Desactivation des protections Kernel (SEHOP, Exception Chain) 
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des protections noyau (SEHOP, Exception Chain)... 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[OK]%COLOR_RESET% Protections noyau desactivees 

:: 9.2 - Desactivation Spectre/Meltdown (Memory Management)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des protections Spectre/Meltdown...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableCfg /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableGdsMitigation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PerformMmioMitigation /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Protections Spectre/Meltdown desactivees

:: 9.3 - Desactivation des mitigations CPU avancees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des mitigations CPU (KVAS, STIBP, Retpoline)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mitigations CPU desactivees

:: 9.4 - HVCI et CFG (conserves pour compatibilite anti-cheat)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Conservation du HVCI/CFG (requis pour Valorant, Fortnite, etc.)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
:: CFG doit rester ACTIVE pour Vanguard (Valorant)
:: powershell -NoProfile -Command "Set-ProcessMitigation -System -Disable CFG"
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% HVCI/CFG conserves (compatibilite anti-cheat)

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Protections de securite desactivees (HVCI conserve).
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est requis pour appliquer les modifications.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:TOGGLE_DEFENDER
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer Windows Defender (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver Windows Defender (Non recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if errorlevel 3 goto :MENU_GESTION_WINDOWS
if errorlevel 2 goto :DESACTIVER_DEFENDER_SECTION
if errorlevel 1 goto :ACTIVER_DEFENDER_SECTION

:ACTIVER_DEFENDER_SECTION
cls
echo %COLOR_GREEN%[+]%COLOR_RESET% %STYLE_BOLD%Reactivation de Windows Defender...%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des services Windows Defender...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services Defender restaures

echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Windows Defender a ete reactive.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est requis pour appliquer les modifications.
pause
goto :TOGGLE_DEFENDER

:DESACTIVER_DEFENDER_SECTION
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation de Windows Defender...%COLOR_RESET%
echo.
echo %COLOR_YELLOW%ATTENTION: Desactiver Windows Defender expose votre systeme a des risques.%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des services Windows Defender...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Sense" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdBoot" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdFilter" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisDrv" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WdNisSvc" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WinDefend" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services Defender desactives

echo.
echo %COLOR_RED%[-]%COLOR_RESET% Windows Defender a ete desactive.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est requis pour appliquer les modifications.
pause
goto :TOGGLE_DEFENDER

:TOGGLE_UAC
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER UAC (CONTROLE DE COMPTE UTILISATEUR)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer UAC (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver UAC + Avertissements (Pour LAB)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if errorlevel 3 goto :MENU_GESTION_WINDOWS
if errorlevel 2 goto :DESACTIVER_UAC_SECTION
if errorlevel 1 goto :ACTIVER_UAC_SECTION

:ACTIVER_UAC_SECTION
cls
echo %COLOR_GREEN%[OK]%COLOR_RESET% Activation de l'UAC et des avertissements...
echo.

:: UAC normal
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1

:: SmartScreen Explorer par defaut
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Warn" /f >nul 2>&1

:: Reactiver le suivi de zone (fichiers telecharges marques comme Internet)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% UAC active. Un redemarrage est requis.
pause
goto :TOGGLE_UAC

:DESACTIVER_UAC_SECTION
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation complete de l'UAC et des avertissements...%COLOR_RESET%
echo %COLOR_YELLOW%LAB UNIQUEMENT : plus aucun avertissement au lancement de fichiers.%COLOR_RESET%
echo.

:: UAC OFF = plus de demande Oui/Non
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactiver SmartScreen Explorer
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul 2>&1

:: Desactiver "Ce fichier provient d'Internet" (Zone.Identifier)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%UAC + tous les avertissements desactives.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Redemarrage requis.
pause
goto :TOGGLE_UAC

:TOGGLE_ANIMATIONS
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer les animations Windows (experience utilisateur standard)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver les animations Windows (pour optimiser les performances)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if errorlevel 3 goto :MENU_GESTION_WINDOWS
if errorlevel 2 goto :DESACTIVER_ANIMATIONS_SECTION
if errorlevel 1 goto :ACTIVER_ANIMATIONS_SECTION

:ACTIVER_ANIMATIONS_SECTION
cls
echo %COLOR_GREEN%[OK]%COLOR_RESET% Restauration des parametres visuels par defaut de Windows...
echo.

:: Mode par defaut (0 = Laisser Windows choisir)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1

:: UserPreferencesMask : profil Windows par defaut (toutes animations actives)
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9E3E078012000000 /f >nul 2>&1

:: Afficher des miniatures au lieu d'icones
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1

:: Afficher le contenu des fenetres pendant leur deplacement
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1

:: Afficher le rectangle de selection de facon translucide
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1

:: Afficher les listes modifiables
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewWatermark /t REG_DWORD /d 1 /f >nul 2>&1

:: Lisser les polices ecran (ClearType)
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1

:: ACTIVER : Peek
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1

:: ACTIVER : Ombres sous le pointeur de la souris
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "1" /f >nul 2>&1

:: ACTIVER : Ombre sous les fenetres
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1

:: ACTIVER : Animations barre des taches
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1

:: ACTIVER : Animer les fenetres lors reduction/agrandissement
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "1" /f >nul 2>&1

:: ACTIVER : Enregistrer miniatures barre des taches
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /f >nul 2>&1

:: ACTIVER : Faire defiler regulierement zone de liste
reg add "HKCU\Control Panel\Desktop" /v SmoothScroll /t REG_DWORD /d 1 /f >nul 2>&1

:: ACTIVER : Infobulles sur le Bureau
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 1 /f >nul 2>&1

:: Delai menus par defaut (400ms)
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "400" /f >nul 2>&1

:: DWM Animations ON + Transparence ON
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v Animations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1

:: Supprimer les politiques forcees
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableAnimations /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des changements...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo %COLOR_GREEN%[OK]%COLOR_RESET% Animations Windows activees (parametres par defaut).
pause
goto :TOGGLE_ANIMATIONS

:DESACTIVER_ANIMATIONS_SECTION
cls
echo %COLOR_RED%[-]%COLOR_RESET% Application des parametres visuels optimises...
echo.
echo %COLOR_WHITE%  Parametres personnalises :%COLOR_RESET%
echo %COLOR_GREEN%  [ON]%COLOR_RESET%  Afficher des miniatures au lieu d'icones
echo %COLOR_GREEN%  [ON]%COLOR_RESET%  Afficher le contenu des fenetres pendant deplacement
echo %COLOR_GREEN%  [ON]%COLOR_RESET%  Afficher le rectangle de selection translucide
echo %COLOR_GREEN%  [ON]%COLOR_RESET%  Afficher les listes modifiables
echo %COLOR_GREEN%  [ON]%COLOR_RESET%  Lisser les polices ecran
echo %COLOR_RED%  [OFF]%COLOR_RESET% Toutes les autres animations et effets
echo.

:: Mode personnalise (3 = Custom)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1

:: UserPreferencesMask - Valeur pour les 5 options activees
reg add "HKCU\Control Panel\Desktop" /v UserPreferencesMask /t REG_BINARY /d 9012038010000000 /f >nul 2>&1

:: Afficher des miniatures au lieu d'icones
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1

:: Afficher le contenu des fenetres pendant leur deplacement
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1

:: Afficher le rectangle de selection de facon translucide
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1

:: Afficher les listes modifiables
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewWatermark /t REG_DWORD /d 1 /f >nul 2>&1

:: Lisser les polices ecran (ClearType)
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1

:: DESACTIVER : Peek
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1

:: DESACTIVER : Ombres sous le pointeur de la souris
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "0" /f >nul 2>&1

:: DESACTIVER : Ombre sous les fenetres
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1

:: DESACTIVER : Animations barre des taches
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1

:: DESACTIVER : Animer les fenetres lors reduction/agrandissement
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f >nul 2>&1

:: DESACTIVER : Enregistrer miniatures barre des taches
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /t REG_DWORD /d 0 /f >nul 2>&1

:: DESACTIVER : Faire defiler regulierement zone de liste
reg add "HKCU\Control Panel\Desktop" /v SmoothScroll /t REG_DWORD /d 0 /f >nul 2>&1

:: DESACTIVER : Ombres pour noms icones Bureau
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowInfoTip /t REG_DWORD /d 0 /f >nul 2>&1

:: UI plus reactive
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1

:: DWM Animations OFF + Transparence OFF
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v Animations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1

:: Politiques forcees (animations demarrage OFF)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des changements...
taskkill /f /im explorer.exe >nul 2>&1
start explorer.exe
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres visuels optimises appliques.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage peut etre necessaire pour appliquer tous les changements.
pause
goto :TOGGLE_ANIMATIONS

:TOGGLE_COPILOT
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER COPILOT / WIDGETS / RECALL (WINDOWS 11)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Ces fonctionnalites sont specifiques a Windows 11.%COLOR_RESET%
echo %COLOR_WHITE%  Si vous etes sur Windows 10, ces options n'auront pas d'effet.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_BLUE%--- COPILOT ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer Copilot%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver Copilot%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- WIDGETS ---%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Activer les Widgets%COLOR_RESET%
echo %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_RED%Desactiver les Widgets%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- RECALL (Windows 11 24H2) ---%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Activer Recall%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_RED%Desactiver Recall%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_RED%Desactiver TOUT (Copilot + Widgets + Recall)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 123456DM /N /M "%COLOR_YELLOW%Choisissez une option [1-6, D, M]: %COLOR_RESET%"
if errorlevel 8 goto :MENU_GESTION_WINDOWS
if errorlevel 7 goto :DESACTIVER_TOUT_COPILOT
if errorlevel 6 goto :DESACTIVER_RECALL
if errorlevel 5 goto :ACTIVER_RECALL
if errorlevel 4 goto :DESACTIVER_WIDGETS
if errorlevel 3 goto :ACTIVER_WIDGETS
if errorlevel 2 goto :DESACTIVER_COPILOT
if errorlevel 1 goto :ACTIVER_COPILOT

:ACTIVER_COPILOT
cls
echo %COLOR_GREEN%[+]%COLOR_RESET% %STYLE_BOLD%Activation de Copilot...%COLOR_RESET%
echo.
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Copilot active.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Redemarrez l'Explorateur ou le PC pour voir le bouton Copilot.
pause
goto :TOGGLE_COPILOT

:DESACTIVER_COPILOT
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation de Copilot...%COLOR_RESET%
echo.
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Copilot desactive.
pause
goto :TOGGLE_COPILOT

:ACTIVER_WIDGETS
cls
echo %COLOR_GREEN%[+]%COLOR_RESET% %STYLE_BOLD%Activation des Widgets...%COLOR_RESET%
echo.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Widgets actives.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Redemarrez l'Explorateur ou le PC pour voir les Widgets.
pause
goto :TOGGLE_COPILOT

:DESACTIVER_WIDGETS
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation des Widgets...%COLOR_RESET%
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Widgets masques.
pause
goto :TOGGLE_COPILOT

:ACTIVER_RECALL
cls
echo %COLOR_GREEN%[+]%COLOR_RESET% %STYLE_BOLD%Activation de Recall...%COLOR_RESET%
echo.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v TurnOffSavingSnapshots /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Recall active.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Recall necessite un PC compatible NPU et Windows 11 24H2.
pause
goto :TOGGLE_COPILOT

:DESACTIVER_RECALL
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation de Recall...%COLOR_RESET%
echo.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v TurnOffSavingSnapshots /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowRecallEnablement /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowAIGameFeatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowClickToDo /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Recall et IA desactives.
pause
goto :TOGGLE_COPILOT

:DESACTIVER_TOUT_COPILOT
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation de Copilot + Widgets + Recall...%COLOR_RESET%
echo.
:: Copilot
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de Copilot...
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Copilot desactive
:: Widgets
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des Widgets...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
winget uninstall "Windows web experience Pack" --silent --accept-source-agreements >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Widgets desactives
:: Recall & AI (2025-2026)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de Recall et fonctions IA...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v TurnOffSavingSnapshots /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowRecallEnablement /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowAIGameFeatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowClickToDo /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Recall et IA desactives
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Toutes les fonctionnalites IA ont ete desactivees.
pause
goto :MENU_GESTION_WINDOWS

:DESINSTALLER_ONEDRIVE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESINSTALLATION COMPLETE DE ONEDRIVE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Tentative de desinstallation de OneDrive...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre quelques instants.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de vouloir continuer (O/N) ? %COLOR_RESET%"
if errorlevel 2 goto :MENU_GESTION_WINDOWS

:: Arreter les processus OneDrive
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im OneDriveSetup.exe >nul 2>&1
taskkill /f /im FileCoAuth.exe >nul 2>&1
taskkill /f /im FileSyncHelper.exe >nul 2>&1
taskkill /f /im OneDriveStandaloneUpdater.exe >nul 2>&1
timeout /t 3 >nul
taskkill /f /im explorer.exe >nul 2>&1
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
reg delete "HKLM\Software\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des taches planifiees OneDrive...
for /f "tokens=1 delims=," %%x in ('schtasks /query /fo csv 2^>nul ^| find "OneDrive"') do (
    schtasks /delete /TN %%x /f >nul 2>&1
)

echo %COLOR_GREEN%[OK]%COLOR_RESET% Desinstallation de OneDrive terminee (si installe).
echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des dossiers OneDrive restants...
if exist "%LocalAppData%\Microsoft\OneDrive" rd "%LocalAppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%AppData%\Microsoft\OneDrive" rd "%AppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%SystemDrive%\OneDriveTemp" rd "%SystemDrive%\OneDriveTemp" /q /s >nul 2>&1
for %%C in (
    "%LocalAppData%\Microsoft\OneDrive\logs"
    "%LocalAppData%\Microsoft\OneDrive\settings"
    "%LocalAppData%\Temp\OneDrive*"
    "%Temp%\OneDrive*"
) do (
    if exist "%%~C" (
        rd "%%~C" /q /s >nul 2>&1
        del "%%~C" /q /s /f >nul 2>&1
    )
)
takeown /f "%USERPROFILE%\OneDrive" /r /d y >nul 2>&1
rd "%USERPROFILE%\OneDrive" /s /q >nul 2>&1
takeown /f "%LOCALAPPDATA%\Microsoft\OneDrive" /r /d y >nul 2>&1
rd "%LOCALAPPDATA%\Microsoft\OneDrive" /s /q >nul 2>&1
takeown /f "%PROGRAMDATA%\Microsoft OneDrive" /r /d y >nul 2>&1
rd "%PROGRAMDATA%\Microsoft OneDrive" /s /q >nul 2>&1
takeown /f "%SystemDrive%\OneDriveTemp" /r /d y >nul 2>&1
rd "%SystemDrive%\OneDriveTemp" /s /q >nul 2>&1

:: Supprimer les raccourcis OneDrive du menu Demarrer
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft OneDrive.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Links\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% Nettoyage complet de OneDrive termine.
pause
goto :MENU_GESTION_WINDOWS

:DESINSTALLER_EDGE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESINSTALLATION COMPLETE DE MICROSOFT EDGE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_RED%ATTENTION: La desinstallation de Microsoft Edge peut entrainer des problemes%COLOR_RESET%
echo %COLOR_RED%de compatibilite avec certaines applications Windows.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de vouloir continuer (O/N) ? %COLOR_RESET%"
if errorlevel 2 goto :MENU_GESTION_WINDOWS
echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE% SUPPRESSION DES DONNEES UTILISATEUR%COLOR_RESET%
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
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Les donnees utilisateur seront preservees.
) else (
    set "SUPPR_DATA=OUI"
    echo %COLOR_RED%[-]%COLOR_RESET% Les donnees utilisateur seront supprimees.
)

echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Debut de la desinstallation...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Arret des processus Edge...
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression de l'icone Edge de la barre des taches...
:: Suppression ciblee des raccourcis Edge uniquement
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q >nul 2>&1
if exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" (
    for %%f in ("%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk") do (
        findstr /i "edge" "%%f" >nul && del "%%f" /f /q >nul 2>&1
    )
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci Edge supprime (les autres icones sont preservees)

:: Desinstallation de Microsoft Edge
echo %COLOR_YELLOW%[*]%COLOR_RESET% Tentative de desinstallation de Microsoft Edge...
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" (
    cd /d "%ProgramFiles(x86)%\Microsoft\Edge\Application"
    for /d %%i in (*) do (
        if exist "%%i\Installer\setup.exe" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% Execution setup.exe...
            "%%i\Installer\setup.exe" --uninstall --system-level --verbose-logging --force-uninstall
        )
    )
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage force des dossiers programme...
rd "%ProgramFiles%\Microsoft\Edge" /s /q >nul 2>&1
rd "%ProgramFiles(x86)%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des cles de registre Edge...
reg delete "HKLM\Software\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des taches planifiees Edge...
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineCore" /f >nul 2>&1
schtasks /delete /tn "MicrosoftEdgeUpdateTaskMachineUA" /f >nul 2>&1

:: Gestion conditionnelle des donnees utilisateur
if "%SUPPR_DATA%"=="OUI" (
    echo %COLOR_RED%[*]%COLOR_RESET% Suppression des donnees utilisateur Edge...
    if exist "%LOCALAPPDATA%\Microsoft\Edge" rd "%LOCALAPPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    if exist "%APPDATA%\Microsoft\Edge" rd "%APPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge" /f >nul 2>&1
    echo %COLOR_RED%[-]%COLOR_RESET% Donnees utilisateur supprimees.
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Conservation des donnees utilisateur...
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\BrowserSwitcher" /f >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\PreferenceMACs" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Donnees utilisateur preservees.
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des donnees systeme communes...
rd "%PROGRAMDATA%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des raccourcis...
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%PUBLIC%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des associations de fichiers...
reg delete "HKLM\SOFTWARE\Classes\MSEdgeHTM" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\MSEdgePDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Applications\msedge.exe" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage de l'index de recherche Windows...
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_http" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_https" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du menu demarrer...
rd "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
rd "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache d'icones Edge...
del "%LOCALAPPDATA%\IconCache.db" /f /q >nul 2>&1
del "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" /f /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des references Edge dans MUI Cache...
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "C:\Program Files\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Blocage des reinstallations automatiques...
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "InstallDefault" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "PreventFirstRunPage" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification finale...
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
) else (
    if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Microsoft Edge desinstalle avec succes !
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Icone supprimee de la barre des taches !
        if "%SUPPR_DATA%"=="OUI" (
            echo %COLOR_RED%[-]%COLOR_RESET% Donnees utilisateur supprimees.
        ) else (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% Donnees utilisateur conservees.
        )
    )
)

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% Desinstallation terminee !
if "%SUPPR_DATA%"=="NON" (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Vos favoris, mots de passe et historique ont ete preserves.
)
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% L'icone Edge a ete supprimee de la barre des taches.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Si des elements persistent, redemarrez Windows.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
pause
goto :MENU_GESTION_WINDOWS

:OUTIL_ACTIVATION
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% OUTIL D'ACTIVATION WINDOWS / OFFICE (MAS)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Lancement de l'outil d'activation...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Veuillez suivre les instructions a l'ecran.
powershell "irm https://get.activated.win | iex"
echo %COLOR_GREEN%[OK]%COLOR_RESET% Outil d'activation termine.
pause
goto :MENU_PRINCIPAL

:OUTIL_CHRIS_TITUS
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% OUTIL CHRIS TITUS TECH (WINUTIL)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Lancement de l'outil Chris Titus Tech...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Veuillez suivre les instructions a l'ecran.
powershell "irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1 | iex"
echo %COLOR_GREEN%[OK]%COLOR_RESET% Outil Chris Titus Tech termine.
pause
goto :MENU_PRINCIPAL

:TOUT_OPTIMISER_DESKTOP
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE% Application de toutes les optimisations (Desktop)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette option va appliquer toutes les optimisations pour Desktop.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre plusieurs minutes.
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les protections de securite (Spectre/Meltdown) ?%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Reduit la latence systeme et l'overhead CPU
echo       %COLOR_YELLOW%Expose le systeme a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les protections (recommande)
echo.
set "DESACTIVER_SECURITE=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Desactiver les protections ? [O/N]: %COLOR_RESET%"
if errorlevel 2 goto :DESKTOP_SECURITE_NON
if errorlevel 1 set "DESACTIVER_SECURITE=1"
:DESKTOP_SECURITE_NON

cls
call :OPTIMISATIONS_SYSTEME call
call :OPTIMISATIONS_MEMOIRE call
call :OPTIMISATIONS_DISQUES call
call :OPTIMISATIONS_GPU call
call :OPTIMISATIONS_RESEAU call
call :OPTIMISATIONS_PERIPHERIQUES call
call :DESACTIVER_PERIPHERIQUES_INUTILES call
call :DESACTIVER_ECONOMIES_ENERGIE call
if "%DESACTIVER_SECURITE%"=="1" call :DESACTIVER_PROTECTIONS_SECURITE call
cls
echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% Toutes les optimisations Desktop ont ete appliquees avec succes.
if "%DESACTIVER_SECURITE%"=="1" (
  echo %COLOR_RED%[!]%COLOR_RESET% Les protections de securite ont ete desactivees.
)
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
echo %COLOR_WHITE% Application de toutes les optimisations (Laptop)%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette option va appliquer toutes les optimisations pour Laptop.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Certaines economies d'energie seront conservees pour la batterie.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cela peut prendre plusieurs minutes.
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les protections de securite (Spectre/Meltdown) ?%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Reduit la latence systeme et l'overhead CPU
echo       %COLOR_YELLOW%Expose le systeme a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les protections (recommande)
echo.
set "DESACTIVER_SECURITE=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Desactiver les protections ? [O/N]: %COLOR_RESET%"
if errorlevel 2 goto :LAPTOP_SECURITE_NON
if errorlevel 1 set "DESACTIVER_SECURITE=1"
:LAPTOP_SECURITE_NON

cls
call :OPTIMISATIONS_SYSTEME call
call :OPTIMISATIONS_MEMOIRE call
call :OPTIMISATIONS_DISQUES call
call :OPTIMISATIONS_GPU call
call :OPTIMISATIONS_RESEAU call
if "%DESACTIVER_SECURITE%"=="1" call :DESACTIVER_PROTECTIONS_SECURITE call
cls
echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% Toutes les optimisations Laptop ont ete appliquees avec succes.
if "%DESACTIVER_SECURITE%"=="1" (
  echo %COLOR_RED%[!]%COLOR_RESET% Les protections de securite ont ete desactivees.
)
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
echo %COLOR_WHITE% Creation d'un point de restauration%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% Creation d'un point de restauration...
:: Verifier si la restauration systeme est activee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification et activation de la restauration systeme si necessaire...
reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" >nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la restauration systeme...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /t REG_DWORD /d 1 /f >nul 2>&1
    powershell -Command "Enable-ComputerRestore -Drive 'C:'" >nul 2>&1
)
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Creation d'un point de restauration en cours...
powershell -Command "Checkpoint-Computer -Description 'Point de restauration avant optimisations Windows' -RestorePointType 'MODIFY_SETTINGS'" >nul 2>&1
if %errorlevel% EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Point de restauration cree avec succes.
) else (
    echo %COLOR_RED%[ATTENTION]%COLOR_RESET% Echec de la creation du point de restauration.
)
pause
goto :MENU_PRINCIPAL

:NETTOYAGE_AVANCE_WINDOWS
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                      NETTOYAGE DE WINDOWS AVANCE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

:: -----------------------------------------------------------------------------
:: ANALYSE ESPACE (Initial, sans affichage)
:: -----------------------------------------------------------------------------
for /f %%a in ('powershell -nologo -command "[int]((Get-PSDrive -Name C).Free / 1MB)"') do set space_before_mb=%%a

echo %COLOR_YELLOW%[!] AVERTISSEMENT%COLOR_RESET%
echo %COLOR_WHITE% Ce script effectue un nettoyage avance, incluant :%COLOR_RESET%
echo %COLOR_WHITE% - Vidage de la Corbeille : perte definitive des fichiers.%COLOR_RESET%
echo %COLOR_WHITE% - Suppression des logs systeme et rapports d'erreur.%COLOR_RESET%
echo %COLOR_WHITE% - Nettoyage des caches et fichiers temporaires.%COLOR_RESET%
echo %COLOR_YELLOW%[!]%COLOR_RESET% %COLOR_WHITE%Continuez uniquement si vous acceptez ces actions.%COLOR_RESET%
echo.
pause
cls
echo.

echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 1: FICHIERS TEMPORAIRES ET CACHES SYSTEME%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des fichiers temporaires utilisateur...
del /s /q /f "%temp%\*.*" >nul 2>&1
for /d %%d in ("%temp%\*") do rd /s /q "%%d" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fichiers temporaires utilisateur supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des fichiers temporaires Windows...
del /s /q /f "C:\Windows\Temp\*.*" >nul 2>&1
for /d %%d in ("C:\Windows\Temp\*") do rd /s /q "%%d" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fichiers temporaires Windows supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des logs systeme...
del /s /q /f "C:\Windows\Logs\*.log" >nul 2>&1
del /s /q /f "C:\Windows\System32\LogFiles\*.log" >nul 2>&1
del /s /q /f "C:\Windows\Panther\*.log" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Logs systeme supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des fichiers de crash...
del /s /q /f "C:\Windows\Minidump\*.*" >nul 2>&1
del /q /f "C:\Windows\*.dmp" >nul 2>&1
del /s /q /f "C:\Windows\memory.dmp" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fichiers de crash supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des rapports d'erreurs...
rd /s /q "C:\ProgramData\Microsoft\Windows\WER" >nul 2>&1
md "C:\ProgramData\Microsoft\Windows\WER" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Rapports d'erreurs supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage cache Windows Update...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
timeout /t 2 /nobreak >nul
rd /s /q "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
md "C:\Windows\SoftwareDistribution\Download" >nul 2>&1
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache Windows Update vide

echo %COLOR_YELLOW%[*]%COLOR_RESET% Vidage de la corbeille...
powershell -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Corbeille videe

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 2: MAINTENANCE SYSTEME ET CACHES%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des journaux CBS et DISM...
del /s /q /f "C:\Windows\Logs\CBS\*.log" >nul 2>&1
del /s /q /f "C:\Windows\Logs\DISM\*.log" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Journaux CBS/DISM nettoyes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache de polices...
net stop FontCache >nul 2>&1
timeout /t 1 /nobreak >nul
del /s /q /f "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /q /f "C:\Windows\System32\FNTCACHE.DAT" >nul 2>&1
net start FontCache >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache de polices nettoye

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reset du Cache Windows Store (Edge completement preserve)...
:: NE PAS utiliser wsreset car ca peut affecter Edge
:: Nettoyage selectif : exclure Edge, WebView2, et tout ce qui contient Microsoft.Windows
powershell -NoProfile -Command "Get-ChildItem -Path \"$env:LOCALAPPDATA\Packages\" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Edge|WebView|Microsoft\.Windows' } | ForEach-Object { Remove-Item -Path \"$($_.FullName)\AC\INetCache\*\" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path \"$($_.FullName)\AC\Temp\*\" -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache Store vide (Edge completement preserve)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage cache des miniatures...
del /f /s /q "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache*.db" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache des miniatures nettoye

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage cache des navigateurs (hors Edge)...
:: Chrome (cache seulement, pas les cookies/sessions)
if exist "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Cache" >nul 2>&1
    rd /s /q "%LOCALAPPDATA%\Google\Chrome\User Data\Default\Code Cache" >nul 2>&1
)
:: Firefox (cache seulement)
for /d %%p in ("%LOCALAPPDATA%\Mozilla\Firefox\Profiles\*") do (
    rd /s /q "%%p\cache2" >nul 2>&1
)
:: Brave (cache seulement)
if exist "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache" (
    rd /s /q "%LOCALAPPDATA%\BraveSoftware\Brave-Browser\User Data\Default\Cache" >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache des navigateurs nettoye (sessions preservees)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage Cache DNS...
ipconfig /flushdns >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% DNS vide

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 3: OPTIMISATION STOCKAGE%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

echo %COLOR_YELLOW%[*]%COLOR_RESET% Maintenance Stockage (TRIM SSD / Defrag HDD)...
defrag C: /O /H >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Disque optimise (TRIM execute si SSD)

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 4: NETTOYAGE FINAL CLEANMGR%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de l'outil de nettoyage Windows...
set "SAGEID=100"

:: DownloadsFolder RETIRE pour proteger les telechargements
for %%K in (
    "Active Setup Temp Folders"
    "BranchCache"
    "Content Indexer Cleaner"
    "D3D Shader Cache"
    "Delivery Optimization Files"
    "Device Driver Packages"
    "Diagnostic Data Viewer database files"
    "DirectX Shader Cache"
    "Downloaded Program Files"
    "GameNewsFiles"
    "GameStatisticsFiles"
    "GameUpdateFiles"
    "Internet Cache Files"
    "Language Pack"
    "Memory Dump Files"
    "Offline Pages Files"
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
    "Temporary Sync Files"
    "Thumbnail Cache"
    "Update Cleanup"
    "Upgrade Discarded Files"
    "User file versions"
    "Windows Defender"
    "Windows Error Reporting Archive Files"
    "Windows Error Reporting Files"
    "Windows Error Reporting Queue Files"
    "Windows Error Reporting System Archive Files"
    "Windows Error Reporting System Queue Files"
    "Windows Error Reporting Temp Files"
    "Windows ESD installation files"
    "Windows Upgrade Log Files"
) do (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v StateFlags%SAGEID% /t REG_DWORD /d 2 /f >nul 2>&1
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Execution Cleanmgr (peut prendre plusieurs minutes)...
cleanmgr /sagerun:%SAGEID% /d C:
timeout /t 3 /nobreak >nul
echo %COLOR_GREEN%[OK]%COLOR_RESET% Nettoyage Cleanmgr termine

:: -----------------------------------------------------------------------------
:: CALCUL FINAL
:: -----------------------------------------------------------------------------
for /f %%a in ('powershell -nologo -command "[int]((Get-PSDrive -Name C).Free / 1MB)"') do set space_after_mb=%%a
set /a space_freed_mb=%space_after_mb% - %space_before_mb%
set /a space_before_gb_final=%space_before_mb% / 1024
set /a space_after_gb=%space_after_mb% / 1024
set /a space_freed_gb=%space_freed_mb% / 1024

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE%                        RAPPORT DE NETTOYAGE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Espace avant  : %COLOR_YELLOW%%space_before_gb_final% Go (%space_before_mb% Mo)%COLOR_RESET%
echo %COLOR_WHITE%  Espace apres  : %COLOR_GREEN%%space_after_gb% Go (%space_after_mb% Mo)%COLOR_RESET%
echo %COLOR_WHITE%  Gain total    : %COLOR_CYAN%%space_freed_gb% Go (%space_freed_mb% Mo)%COLOR_RESET%
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Nettoyage termine avec succes !
echo %COLOR_YELLOW%[!]%COLOR_RESET% Un redemarrage est recommande pour finaliser le nettoyage.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.

choice /c ON /n /m "%COLOR_YELLOW%Voulez-vous redemarrer maintenant ? (O/N):%COLOR_RESET% "
if errorlevel 2 goto :MENU_PRINCIPAL
if errorlevel 1 shutdown /r /t 10 /c "Redemarrage pour finaliser le nettoyage de Windows"

pause
goto :MENU_PRINCIPAL


:END_SCRIPT
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_WHITE% AU REVOIR !%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Merci d'avoir utilise le script d'optimisation !
echo %COLOR_YELLOW%[!]%COLOR_RESET% N'oubliez pas de redemarrer votre PC pour que les changements prennent effet.
echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
timeout /t 3 /nobreak >nul
exit
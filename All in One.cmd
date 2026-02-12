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
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Optimisations Reseau%COLOR_RESET%  %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_GREEN%Optimisations Clavier/Souris%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- PC DE BUREAU UNIQUEMENT ---%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_RED%Gerer Economies d'Energie (Activer/Restaurer)%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Desactiver Protections Securite (Spectre/Meltdown)%COLOR_RESET%
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
choice /C 12345678DLNRGWTQ /N /M "%STYLE_BOLD%%COLOR_YELLOW%Veuillez choisir une option [1-8, D, L, N, R, G, W, T, Q]: %COLOR_RESET%"

:: Gestion des choix (du plus grand au plus petit pour errorlevel)
if errorlevel 16 goto :END_SCRIPT
if errorlevel 15 goto :OUTIL_CHRIS_TITUS
if errorlevel 14 goto :OUTIL_ACTIVATION
if errorlevel 13 goto :MENU_GESTION_WINDOWS
if errorlevel 12 goto :CREER_POINT_RESTAURATION
if errorlevel 11 goto :NETTOYAGE_AVANCE_WINDOWS
if errorlevel 10 goto :TOUT_OPTIMISER_LAPTOP
if errorlevel 9 goto :TOUT_OPTIMISER_DESKTOP
if errorlevel 8 goto :DESACTIVER_PROTECTIONS_SECURITE
if errorlevel 7 goto :TOGGLE_ECONOMIES_ENERGIE
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
echo %STYLE_BOLD%%COLOR_BLUE%--- RUNTIMES ET DEPENDANCES ---%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_GREEN%Installer les Visual C++ Redistributables%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
choice /C 1234567M /N /M "%COLOR_YELLOW%Choisissez une option [1-7, M]: %COLOR_RESET%"
if errorlevel 8 goto :MENU_PRINCIPAL
if errorlevel 7 goto :INSTALLER_VISUAL_REDIST
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
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NoLazyMode /t REG_DWORD /d 1 /f >nul 2>&1
:: Scheduling Category en High = le plus haut tout en restant stable et natif a Windows (Medium est conservateur)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
:: Priority en 2 = meilleur equilibre entre latence la plus basse possible et stabilite (plus stable que Priority Delete qui offre la latence pure la plus basse)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v Priority /t REG_DWORD /d 2 /f >nul 2>&1
:: GPU Priority supprime car inutile maintenant dans Windows (on ne l'utilise plus)
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Profil gaming (MMCSS) configure

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
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1

:: Delai d'affichage des menus a 0ms
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1

:: Accelerer l'ouverture/fermeture des fenetres
reg add "HKCU\Control Panel\Desktop" /v WaitToKillAppTimeout /t REG_SZ /d "2000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v HungAppTimeout /t REG_SZ /d "1000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AutoEndTasks /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v LowLevelHooksTimeout /t REG_DWORD /d 1000 /f >nul 2>&1
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

:: Desactiver les suggestions et recommandations dans le menu Demarrer (Windows 11)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_IrisRecommendations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackDocs /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_TrackProgs /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_ShowRecent /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v Start_Suggestions /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowRecommendations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v HideRecommendedSection /t REG_DWORD /d 1 /f >nul 2>&1
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

:: Wi-Fi Sense OFF
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v Value /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v Value /t REG_DWORD /d 0 /f >nul 2>&1

:: Activity History OFF (Timeline Windows)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v PublishUserActivities /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v UploadUserActivities /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Privacy" /v ActivityHistoryEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Telemetrie et publicites desactivees

:: Taches planifiees de telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des taches planifiees de telemetrie...
for %%T in (
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "Microsoft\Windows\Application Experience\AitAgent"
    "Microsoft\Windows\Autochk\Proxy"
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "Microsoft\Windows\Customer Experience Improvement Program\KernelCeipTask"
    "Microsoft\Windows\DiskDiagnostic\Microsoft-Windows-DiskDiagnosticDataCollector"
    "Microsoft\Windows\Feedback\Siuf\DmClient"
    "Microsoft\Windows\Feedback\Siuf\DmClientOnScenarioDownload"
    "Microsoft\Windows\Windows Error Reporting\QueueReporting"
    "Microsoft\Windows\PI\Sqm-Tasks"
    "Microsoft\Windows\CloudExperienceHost\CreateObjectTask"
    "Microsoft\Windows\DiskFootprint\Diagnostics"
    "Microsoft\Windows\NetTrace\GatherNetworkInfo"
    "Microsoft\Windows\Shell\FamilySafetyMonitor"
    "Microsoft\Windows\Shell\FamilySafetyRefreshTask"
    "Microsoft\Windows\WDI\ResolutionHost"
    "Microsoft\Windows\SettingSync\BackgroundUploadTask"
    "Microsoft\Windows\SettingSync\NetworkStateChangeTask"
    "Microsoft\Windows\SkyDrive\Idle Sync Maintenance Task"
    "Microsoft\Windows\Work Folders\Work Folders Logon Synchronization"
    "Microsoft\Windows\Work Folders\Work Folders Maintenance Work"
    "Microsoft\Windows\PushToInstall\Registration"
    "Microsoft\Windows\Subscription\EnableLicenseAcquisition"
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

:: 1.5 - Services optimises Version SAFE 2026
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation services - Mode SAFE (compatible usages mixtes)...

:: Services inutiles -> DISABLED
for %%S in (
    AJRouter
    AppVClient
    AssignedAccessManagerSvc
    DiagTrack
    dmwappushservice
    lfsvc
    MapsBroker
    NetTcpPortSharing
    RemoteAccess
    RemoteRegistry
    RetailDemo
    shpamsvc
    ssh-agent
    uhssvc
    UevAgentService
    WMPNetworkSvc
    CDPUserSvc
    SystemSuggestions
    Fax
    DialogBlockingService
) do (
  sc config %%S start= disabled >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services telemetrie/legacy desactives

:: Services occasionnels -> MANUAL
for %%S in (
    ALG
    BDESVC
    CertPropSvc
    GraphicsPerfSvc
    IKEEXT
    MSDTC
    MSiSCSI
    NaturalAuthentication
    NcaSvc
    PeerDistSvc
    PNRPAutoReg
    PNRPsvc
    RpcLocator
    SstpSvc
    TroubleshootingSvc
    WFDSConMgrSvc
    tzautoupdate
) do (
  sc config %%S start= demand >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Services occasionnels en mode Manuel

:: W32Time en AUTO pour synchronisation horaire immediate
sc config W32Time start= auto >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% W32Time en demarrage automatique (synchro horaire)

:: Services critiques laisses intacts : Bluetooth, Hello, RDP, Spooler, PlugPlay

echo %COLOR_GREEN%[OK]%COLOR_RESET% Services optimises (Bluetooth/VPN/Hello/RDP preserves)

:: 1.6 - Optimisations demarrage et systeme
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

:: Désactivation des Co-installateurs tiers (Razer/Logitech Popup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des Co-installateurs (Razer/Logitech Popup)...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DriverSearching" /v SearchOrderConfig /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v DisableCoInstallers /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Co-installateurs et recherche de pilotes desactives

:: Privacy Supplementaire
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des tweaks privacy supplementaires...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowDeviceNameInTelemetry /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v TailoredExperiencesWithDiagnosticDataEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Privacy renforcee (DeviceName OFF, Pubs Ciblees OFF, Bing Search OFF)

:: Batterie - Energy Saver
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: 1.7 - Navigateurs
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation des navigateurs...
reg add "HKCU\Software\Microsoft\Edge\Main" /v EnablePreload /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Google\Chrome\Prerender" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsMode /t REG_SZ /d automatic /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Navigateurs optimises

:: 1.8 - Cache Icones Explorer
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du cache d'icones pour dossiers lourds...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v Max Cached Icons /t REG_SZ /d "8192" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache icones augmente (dossiers avec 20 000+ fichiers instantanes)

:: 1.9 - Desactivation du stockage reserve
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du stockage reserve Windows...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v ShippedWithReserves /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v PassedPolicy /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "try { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Stockage reserve desactive (~7Go recuperes apres redemarrage)

:: 1.10 - Affichage du code erreur BSoD
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de l'affichage des codes erreur BSoD...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v DisplayParameters /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Codes erreur BSoD visibles (diagnostic facilite)

:: 1.11 - Desactivation de l'aide F1
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la touche F1 (aide Windows)...
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Touche F1 (aide) desactivee

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
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du Prefetch et SuperFetch pour performance maximale...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t REG_DWORD /d 0 /f >nul 2>&1
:: Activer Superfetch et Prefetcher pour chargement ultra-rapide des applications
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 3 /f >nul 2>&1
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

:: 2.5 - SvcHost - Reduction du nombre de processus svchost.exe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation SvcHost selon la RAM disponible...
for /f %%M in ('powershell -NoProfile -Command "[math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1KB)" 2^>nul') do set "RAM_KB=%%M"
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

:: 3.1 - Configuration NTFS et TRIM
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres NTFS et activation du TRIM...
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set memoryusage 2 >nul 2>&1
fsutil behavior set mftzone 2 >nul 2>&1
fsutil behavior set disablecompression 1 >nul 2>&1
fsutil behavior set encryptpagingfile 0 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres NTFS optimises - TRIM actif, metadonnees reduites

:: 3.2 - Optimisations I/O NTFS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation I/O NTFS (NVMe)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v MaximumOutstandingRequests /t REG_DWORD /d 256 /f >nul 2>&1
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation des chemins longs (plus de 260 caracteres)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Support des chemins longs active

:: 3.3 - TRIM sur volumes SSD
echo %COLOR_YELLOW%[*]%COLOR_RESET% Execution du TRIM sur les disques SSD detectes...
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ssd=Get-PhysicalDisk|?{$_.MediaType -eq 'SSD'};if($ssd){Write-Host 'SSD detecte(s):' $ssd.Count;Get-Volume|?{$_.DriveLetter -and $_.FileSystem -match 'NTFS|ReFS'}|%{Start-Job {Optimize-Volume -DriveLetter $args[0] -ReTrim -ErrorAction SilentlyContinue} -ArgumentList $_.DriveLetter|Out-Null}}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Commande TRIM executee sur les SSD

:: 3.4 - Optimisation pilote NVMe natif et Boost Speed Windows 11
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation du nouveau pilote NVMe natif (Win 11 25H2)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NativeNVMePerformance /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 156965516 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1853569164 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 735209102 /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Boost NVMe active

:: 3.5 - DirectStorage / NVMe avance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation DirectStorage et I/O NVMe...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v FUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectX" /v DirectStorageForceIOPriority /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% DirectStorage optimise (FUA off, I/O prioritaire)

:: 3.6 - Desactivation de la defragmentation automatique sur SSD
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la defragmentation automatique sur SSD...
powershell -NoProfile -Command "Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' } | ForEach-Object { $disk = $_; Get-Volume | Where-Object { $_.DriveLetter } | ForEach-Object { $drive = $_.DriveLetter + ':'; $task = 'Microsoft\\Windows\\Defrag\\ScheduledDefrag'; Disable-ScheduledTask -TaskName $task -ErrorAction SilentlyContinue } }" >nul 2>&1
:: Desactiver la defragmentation planifiee pour tous les disques
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Disable >nul 2>&1
:: Configurer le service de defragmentation en manuel
sc config defragsvc start= demand >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Defragmentation automatique desactivee (optimise pour SSD)

echo.
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% Telemetrie AMD desactivee

:: 4.5 - NVIDIA Low Latency
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations Low Latency NVIDIA...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v LOWLATENCY /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v D3PCLatency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v F1TransitionLatency /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v Node3DLowLatency /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mode Low Latency active - Reduction de l'input lag

:: 4.6 - WriteCombining
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de la stabilite GPU (WriteCombining)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\nvlddmkm" /v DisableWriteCombining /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Stabilite GPU amelioree

:: 4.7 - HAGS Enable
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la planification GPU acceleree (HAGS)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% HAGS active - Latence GPU reduite

:: 4.8 - Desactivation de la preemption GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la preemption GPU pour reduire la latence...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Preemption GPU desactivee

:: 4.9 - NVIDIA Profile Inspector
:: Detection GPU NVIDIA pour Profile Inspector via PowerShell
set "HAS_NVIDIA=0"
for /f %%i in ('powershell -NoProfile -Command "if((Get-CimInstance Win32_VideoController).Name -match 'NVIDIA'){Write-Output 1}else{Write-Output 0}"') do set "HAS_NVIDIA=%%i"

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
    ping -n 2 127.0.0.1 >nul 2>&1
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

:: 4.10 - Game Mode Windows 11 24H2/25H2
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation Game Mode Windows 11 24H2/25H2...
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AllowAutoGameMode /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Game Mode 24H2/25H2 optimise (auto-detection + overlay desactive)
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

:: 5.2 - Pile TCP/UDP moderne CUBIC et BBR2
netsh int tcp set heuristics disabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set supplemental template=internet congestionprovider=bbr2 >nul 2>&1
:: Correctif Loopback BBR2 (Windows 11 24H2)
netsh int ip set global loopbacklargemtu=disabled >nul 2>&1
netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1
netsh int tcp set global rss=enabled rsc=disabled ecncapability=disabled >nul 2>&1
netsh int udp set global uso=enabled ero=disabled >nul 2>&1
netsh int ip set global sourceroutingbehavior=drop >nul 2>&1
netsh int ip set global icmpredirects=disabled >nul 2>&1
netsh int ipv6 set global neighborcachelimit=4096 >nul 2>&1
netsh int tcp set global fastopen=enabled fastopenfallback=enabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global netdma=disabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1
netsh int tcp set global timestamps=disabled >nul 2>&1
powershell -NoProfile -NoLogo -Command "try{Set-NetTCPSetting -SettingName Internet -InitialRtoMs 2000}catch{}" >nul 2>&1

:: 5.3 - Optimisations TCP registre
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

:: 5.4 - BITS Optimization Telechargements rapides
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du service BITS (Telechargements)...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v EnableBypassProxyForLocal /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOn-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOff-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Service BITS optimise

:: 5.5 - Priorites de resolution DNS
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v LocalPriority /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v HostsPriority /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v DnsPriority /t REG_DWORD /d 6 /f >nul 2>&1

:: 5.6 - ISATAP/Teredo OFF
netsh int isatap set state disabled >nul 2>&1
netsh int teredo set state disabled >nul 2>&1

:: 5.7 - Nagle/DelACK OFF
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

:: 5.8 - QoS Psched
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul 2>&1

:: 5.9 - NIC RSS ON, RSC OFF, epuration bindings
powershell -NoProfile -NoLogo -Command "$adp=Get-NetAdapter|? Status -eq 'Up'; foreach($a in $adp){ try{Enable-NetAdapterRss -Name $a.Name -ErrorAction Stop}catch{}; try{Disable-NetAdapterRsc -Name $a.Name -ErrorAction Stop}catch{} }" >nul 2>&1
powershell -NoProfile -NoLogo -Command "Get-NetAdapter | ? Status -eq 'Up' | % { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lltdio' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_implat' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_rspndr' -ErrorAction SilentlyContinue }" >nul 2>&1

:: 5.10 - NIC latence faible
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration NIC pour faible latence...

:: LSO IPv4/IPv6 + RSC IPv4/IPv6 (désactiver avec gestion des noms FR/EN)
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $adapter=$_.Name; $props = Get-NetAdapterAdvancedProperty -Name $adapter; $lsoProps = $props | Where-Object { $_.DisplayName -like '*Large Send*' -or $_.DisplayName -like '*Grand envoi*' }; foreach($prop in $lsoProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Disabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Désactivé' -ErrorAction Stop } catch {} } }; $rscProps = $props | Where-Object { $_.DisplayName -like '*Recv Segment*' -or $_.DisplayName -like '*RSC*' }; foreach($prop in $rscProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Disabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $prop.DisplayName -DisplayValue 'Désactivé' -ErrorAction Stop } catch {} } } }" >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% NIC configuree - LSO/RSC off

:: 5.11 - QoS Fortnite DSCP 46
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
echo %STYLE_BOLD%%COLOR_WHITE%       SECTION 6 : OPTIMISATIONS CLAVIER ET SOURIS          %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive l'acceleration souris et optimise%COLOR_RESET%
echo %COLOR_WHITE%  la reactivite des peripheriques d'entree.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 6.1 - Souris optimisée
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'acceleration souris et des delais...
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseDelay /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v SnapToDefaultButton /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Acceleration souris desactivee - Mouvement 1:1 actif

:: 6.2 - Clavier optimisé
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de la reactivite clavier...
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t REG_SZ /d "31" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Clavier configure - Delai minimal et vitesse maximale

:: 6.3 - Accessibilité OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des raccourcis d'accessibilite (Sticky/Filter/Toggle Keys)...
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v HotkeyActive /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v Flags /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v HotkeyActive /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v HotkeyActive /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourcis d'accessibilite desactives - Plus d'activation accidentelle

:: 6.4 - DMA Remapping OFF
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PnP\Pci" /v DmaRemappingCompatible /t REG_DWORD /d 0 /f >nul 2>&1
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\PnP\Pci" /v DeviceInterruptRoutingPolicy /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% DMA Remapping desactive - Reduction de la latence

:: 6.5 - HID parse optimisé
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v EnableInputDelayOptimization /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v EnableBufferedInput /t REG_DWORD /d 0 /f >nul 2>&1

:: 6.6 - Files et priorités clavier/souris
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v ThreadPriority /t REG_DWORD /d 15 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v ThreadPriority /t REG_DWORD /d 15 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Priorites et files clavier/souris optimisees

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

:DESACTIVER_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%      SECTION 7 : DESACTIVATION DES ECONOMIES D'ENERGIE     %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive les fonctions d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  pour maintenir les performances maximales en permanence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 7.1 - Energie Systeme et GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des seuils d'economie d'energie...
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: GPU Power Management (ULPS & PowerMizer)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'ULPS (AMD) et configuration PowerMizer (NVIDIA)...
:: ULPS OFF - AMD
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v EnableUlps /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v EnableUlps_NA /t REG_SZ /d 0 /f >nul 2>&1
)
:: PowerMizer - NVIDIA (Applique a toutes les instances GPU)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PowerMizerEnable /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevel /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PerfLevelSrc /t REG_DWORD /d 2222 /f >nul 2>&1
  reg add "%%K" /v DisableDynamicPstate /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v RmDisableRegistryCaching /t REG_DWORD /d 1 /f >nul 2>&1
)

:: 7.2 - NIC Energy Saving Ethernet et WiFi
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des economies d'energie reseau (NIC - Ethernet et WiFi)...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $adapter=$_.Name; $energyProps = @('Energy-Efficient Ethernet','Green Ethernet','Power Saving Mode','Gigabit Lite','Ethernet à économie d\'énergie','Ethernet vert','802.11 Power Save','Power Management','Allow the computer to turn off this device','Gestion de l\'alimentation 802.11','Mode d\'economie d\'energie','Power Save Mode'); foreach($propName in $energyProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Disabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Désactivé' -ErrorAction Stop } catch {} } }; try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Interrupt Moderation' -DisplayValue 'Enabled' -ErrorAction SilentlyContinue } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Modération interruption' -DisplayValue 'Activé' -ErrorAction SilentlyContinue } catch {} }; try { Set-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword '*InterruptModeration' -RegistryValue 1 -ErrorAction SilentlyContinue } catch {}; try { Set-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword '*InterruptModerationRate' -RegistryValue 1 -ErrorAction SilentlyContinue } catch {} }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Economies d'energie NIC desactivees (Ethernet + WiFi)


:: 7.3 - Activation du plan Ultimate Performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification du plan d'alimentation actif...

:: GUID Ultimate Performance (toutes langues)
:: e9a42b02-d5df-448d-aa00-03f14749eb61

set "TARGET_GUID="

:: 1. Chercher par le GUID specifique (le plus fiable si present)
for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "e9a42b02-d5df-448d-aa00-03f14749eb61"') do (
    set "TARGET_GUID=%%G"
    set "TARGET_GUID=!TARGET_GUID: =!"
)

:: 2. Si non trouve par GUID, chercher par NOM : "Ultimate Performance" (EN) ou "Performances optimales" (FR)
if not defined TARGET_GUID (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% GUID standard non trouve, recherche par nom...
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "Ultimate optimales"') do (
        set "TARGET_GUID=%%G"
        set "TARGET_GUID=!TARGET_GUID: =!"
    )
)

:: Si le plan existe, verifier s'il est deja actif
if defined TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg /getactivescheme 2^>nul') do set "ACTIVE_GUID=%%G"
    set "ACTIVE_GUID=!ACTIVE_GUID: =!"
    if "!ACTIVE_GUID!"=="!TARGET_GUID!" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate/Optimal deja actif - aucune action requise
        goto :ULTIMATE_DONE
    )
    :: Le plan existe mais n'est pas actif
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Plan Ultimate/Optimal detecte - Activation...
    powercfg -setactive !TARGET_GUID! >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan Ultimate/Optimal active
    goto :ULTIMATE_DONE
)

:: Le plan n'existe pas (ni GUID ni Nom) - le creer
echo %COLOR_YELLOW%[*]%COLOR_RESET% Plan "Performances optimales" non present - Creation...
for /f "tokens=2 delims=:()" %%G in ('powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2^>nul') do set "TARGET_GUID=%%G"
if defined TARGET_GUID set "TARGET_GUID=!TARGET_GUID: =!"

if defined TARGET_GUID (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan "Performances optimales" cree et active
    powercfg -setactive !TARGET_GUID! >nul 2>&1
) else (
    echo %COLOR_RED%[!]%COLOR_RESET% Echec creation plan "Performances optimales"
)

:ULTIMATE_DONE

:: 7.4 - Desactivation du demarrage rapide Fast Startup
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du demarrage rapide (Fast Startup)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Demarrage rapide desactive - Redemarrages propres

:: 7.5 - Desactivation de l'hibernation PC Bureau uniquement
if "%IS_LAPTOP%"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de l'hibernation ^(PC Bureau^)...
    powercfg /hibernate off >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Hibernation desactivee - Espace disque libere
) else (
    echo %COLOR_YELLOW%[!]%COLOR_RESET% Hibernation conservee ^(PC Portable detecte^)
)

:: 7.6 - USB Selective Suspend (Optimisation latence)
if "%IS_LAPTOP%"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation USB - Desactivation de la mise en veille selective...
    powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
    powercfg /S SCHEME_CURRENT >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% USB optimise - Latence minimale (Selective Suspend OFF)
) else (
    echo %COLOR_YELLOW%[!]%COLOR_RESET% USB Selective Suspend conserve (PC Portable detecte)
)

:: 7.7 - Configuration generale du systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du systeme d'alimentation...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.8 - Desactivation des Timer Coalescing et DPC
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
reg add "HKLM\SYSTEM\CurrentControlSet\Control\ModernSleep" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Timer Coalescing desactive - Latence reduite

:: 7.9 - Installation SetTimerResolution
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de SetTimerResolution...
set "STR_EXE=%SystemRoot%\SetTimerResolution.exe"
set "STR_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"

:: Verifier si deja installe
if exist "%STR_EXE%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution deja installe dans %SystemRoot%
    goto :STR_SHORTCUT
)

:: Telecharger SetTimerResolution.exe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement de SetTimerResolution.exe...
powershell -NoProfile -Command "try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/Optimizer/raw/main/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe' -OutFile '%STR_EXE%' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if not exist "%STR_EXE%" (
    echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement de SetTimerResolution
    goto :STR_DONE
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution installe dans %SystemRoot%

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

:: 7.10 - Desactivation du PDC et Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du Power Throttling (bridage CPU)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.11 - Gestion processeur equilibree
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil processeur (performances maximales)...
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1

:: 7.12 - Intel AMD Hybrid CPU Scheduling Visibility
echo %COLOR_YELLOW%[*]%COLOR_RESET% Déblocage des options de scheduling hybride (P-Cores/E-Cores)...
:: Heterogeneous thread scheduling policy
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
:: Core Parking (P-cores class 1)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
:: Core Parking (E-cores class 0)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1

:: 7.13 - Desactivation ASPM
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation ASPM sur le bus PCI Express...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.14 - Optimisations stockage et disques
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la mise en veille des disques...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisableStorageQoS /t REG_DWORD /d 1 /f >nul 2>&1
for %%i in (EnableHIPM EnableDIPM EnableHDDParking) do (
  for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%i" /v 2^>nul ^| findstr /i "^HKEY"') do (
    reg add "%%a" /v %%i /t REG_DWORD /d 0 /f >nul 2>&1
  )
)

:: 7.15 - Optimisations avancees des services
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des limites de latence I/O...
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "IoLatencyCap" /v 2^>nul ^| findstr /i "^HKEY"') do (
  reg add "%%a" /v IoLatencyCap /t REG_DWORD /d 0 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Limites de latence stockage supprimees

:: 7.16 - GPU PreferMaxPerf
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration GPU en mode performances maximales...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PreferMaxPerf /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.17 - PCI & peripheriques reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de la mise en veille des peripheriques PCI...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "*WakeOnPattern" /t REG_DWORD /d 0 /f >nul 2>&1
)

:: 7.18 - Cartes reseau
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

:: 7.19 - Energie PCIe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation gestion d'energie PCIe...
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion d'energie PCIe desactivee


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

:REVERT_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%      RESTAURATION DES ECONOMIES D'ENERGIE (REVERT)     %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section restaure les parametres d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  aux valeurs par defaut de Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%

:: 1. Restaurer le plan d'alimentation par defaut (Equilibre)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration du plan d'alimentation par defaut...
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Plan d'alimentation "Equilibre" active

:: 2. Reactiver le demarrage rapide (Fast Startup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation du demarrage rapide (Fast Startup)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Demarrage rapide reactive

:: 3. Reactiver l'hibernation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de l'hibernation...
powercfg /hibernate on >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Hibernation reactive

:: 4. Reactiver USB Selective Suspend
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation USB Selective Suspend...
powercfg /setacvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT SUB_USB USBSELECTIVESUSPEND 1 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% USB Selective Suspend reactive

:: 5. Reactiver Timer Coalescing
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des Timer Coalescing...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v MinimumDpcRate /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /f >nul 2>&1
bcdedit /set disabledynamictick no >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\ModernSleep" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Timer Coalescing reactive

:: 6. Supprimer SetTimerResolution du demarrage
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression de SetTimerResolution du demarrage...
set "STR_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
if exist "%STR_STARTUP%" (
    del "%STR_STARTUP%" /f /q >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Raccourci SetTimerResolution supprime du demarrage
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution n'etait pas dans le demarrage
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% SetTimerResolution supprime du demarrage automatique

:: 7. Reactiver Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation du Power Throttling...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1

:: 9. Restaurer les seuils d'economie d'energie
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 20 >nul 2>&1

:: 10. Restaurer ULPS et PowerMizer (Auto)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration de l'ULPS (AMD) et PowerMizer (Auto)...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v EnableUlps /f >nul 2>&1
  reg delete "%%K" /v EnableUlps_NA /f >nul 2>&1
  reg delete "%%K" /v PowerMizerEnable /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevel /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevelAC /f >nul 2>&1
  reg delete "%%K" /v PerfLevelSrc /f >nul 2>&1
  reg delete "%%K" /v DisableDynamicPstate /f >nul 2>&1
  reg delete "%%K" /v RmDisableRegistryCaching /f >nul 2>&1
)

:: 11. Restaurer les economies d'energie reseau (NIC - Ethernet et WiFi)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des economies d'energie reseau (NIC)...
powershell -NoProfile -Command "Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $adapter=$_.Name; $energyProps = @('Energy-Efficient Ethernet','Green Ethernet','Power Saving Mode','Gigabit Lite','Ethernet à économie d\'énergie','Ethernet vert','802.11 Power Save','Power Management','Allow the computer to turn off this device','Gestion de l\'alimentation 802.11','Mode d\'economie d\'energie','Power Save Mode'); foreach($propName in $energyProps) { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Enabled' -ErrorAction Stop } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName $propName -DisplayValue 'Activé' -ErrorAction Stop } catch {} } }; try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Interrupt Moderation' -DisplayValue 'Enabled' -ErrorAction SilentlyContinue } catch { try { Set-NetAdapterAdvancedProperty -Name $adapter -DisplayName 'Modération interruption' -DisplayValue 'Activé' -ErrorAction SilentlyContinue } catch {} }; try { Set-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword '*InterruptModeration' -RegistryValue 0 -ErrorAction SilentlyContinue } catch {}; try { Set-NetAdapterAdvancedProperty -Name $adapter -RegistryKeyword '*InterruptModerationRate' -RegistryValue 0 -ErrorAction SilentlyContinue } catch {} }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Economies d'energie NIC restaurees (Ethernet + WiFi)

:: 8. Restaurer les parametres processeur par defaut
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des parametres processeur par defaut...
:: Min: 5%, Max: 100%, Core Parking: 10%, Intervalle: 30ms
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 30 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 10 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Parametres processeur restaures

:: 12. Masquer les options de scheduling hybride
echo %COLOR_YELLOW%[*]%COLOR_RESET% Masquage des options de scheduling hybride...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Options de scheduling hybride masquees

:: 13. Reactiver ASPM
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation ASPM sur le bus PCI Express...
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% ASPM reactive

:: 14. Reactiver la mise en veille des disques
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de la mise en veille des disques...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisableStorageQoS /f >nul 2>&1
:: Supprimer HIPM/DIPM/HDDParking pour revenir aux valeurs par defaut systeme
for %%i in (EnableHIPM EnableDIPM EnableHDDParking) do (
  for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "%%i" /v 2^>nul ^| findstr /i "^HKEY"') do (
    reg delete "%%a" /v %%i /f >nul 2>&1
  )
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mise en veille des disques reactivee

:: 15. Restaurer les limites de latence I/O
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration des limites de latence I/O...
for /f "tokens=*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services" /s /f "IoLatencyCap" /v 2^>nul ^| findstr /i "^HKEY"') do (
  reg delete "%%a" /v IoLatencyCap /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Limites de latence I/O restaurees

:: 16. Restauration de la gestion d'energie GPU et PCI
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration de la gestion d'energie GPU...
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v PreferMaxPerf /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion d'energie GPU restauree
:: 16b. Reactiver la mise en veille des peripheriques PCI (D3Cold)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de la gestion d'energie PCI...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v D3ColdSupported /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v "*WakeOnPattern" /f >nul 2>&1
)

:: 17. Reactiver les fonctions d'economie d'energie reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation des fonctions d'economie d'energie reseau...
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg query "%%K" /v "*SpeedDuplex" >nul 2>&1
  if not errorlevel 1 (
    :: Reactiver economies d'energie avec valeurs par defaut (generalement 1 ou selon le pilote)
    reg delete "%%K" /v "*EEE" /f >nul 2>&1
    reg delete "%%K" /v "*SelectiveSuspend" /f >nul 2>&1
    reg delete "%%K" /v "*WakeOnMagicPacket" /f >nul 2>&1
    reg delete "%%K" /v "EnableGreenEthernet" /f >nul 2>&1
    reg delete "%%K" /v "ULPMode" /f >nul 2>&1
    reg delete "%%K" /v "*WakeOnPattern" /f >nul 2>&1
    reg delete "%%K" /v "*PMARPOffload" /f >nul 2>&1
    reg delete "%%K" /v "*PMNSOffload" /f >nul 2>&1
    reg delete "%%K" /v "*PMWiFiRekeyOffload" /f >nul 2>&1
    reg delete "%%K" /v "EnablePME" /f >nul 2>&1
    reg delete "%%K" /v "PowerSavingMode" /f >nul 2>&1
    reg delete "%%K" /v "ReduceSpeedOnPowerDown" /f >nul 2>&1
    reg delete "%%K" /v "EnableDynamicPowerGating" /f >nul 2>&1
    reg delete "%%K" /v "AutoPowerSaveModeEnabled" /f >nul 2>&1
    reg delete "%%K" /v "AdvancedEEE" /f >nul 2>&1
    reg delete "%%K" /v "EEELinkAdvertisement" /f >nul 2>&1
    reg delete "%%K" /v "GigaLite" /f >nul 2>&1
    reg delete "%%K" /v "S5WakeOnLan" /f >nul 2>&1
    reg delete "%%K" /v "WakeOnLink" /f >nul 2>&1
    reg delete "%%K" /v "WolShutdownLinkSpeed" /f >nul 2>&1
    :: Restaurer valeurs par defaut pour optimisations latence
    reg delete "%%K" /v "*FlowControl" /f >nul 2>&1
    reg delete "%%K" /v "*InterruptModeration" /f >nul 2>&1
    reg delete "%%K" /v "*InterruptModerationRate" /f >nul 2>&1
    reg delete "%%K" /v "ITR" /f >nul 2>&1
    reg delete "%%K" /v "EnableLLI" /f >nul 2>&1
    reg delete "%%K" /v "EnableDownShift" /f >nul 2>&1
    reg delete "%%K" /v "WaitAutoNegComplete" /f >nul 2>&1
    :: Restaurer PnPCapabilities (24 = autoriser la gestion d'energie)
    reg add "%%K" /v PnPCapabilities /t REG_DWORD /d 0 /f >nul 2>&1
  )
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fonctions d'economie d'energie reseau reactivees

:: 18. Restauration du systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Restauration du systeme d'alimentation...
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Systeme d'alimentation restaure

:: 19. Reactiver gestion d'energie PCIe
echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation gestion d'energie PCIe...
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Gestion d'energie PCIe reactivee

:: 20. Masquage des plans d'alimentation avances
echo %COLOR_YELLOW%[*]%COLOR_RESET% Masquage des plans d'alimentation avances...
powershell -NoProfile -Command "powercfg /attributes SUB_PROCESSOR 75b0ae3f-bce0-45a7-8c89-c9611c25e100 +ATTRIB_HIDE" >nul 2>&1
powershell -NoProfile -Command "powercfg /attributes SUB_PROCESSOR ea062031-0e34-4ff1-9b6d-eb1059334028 +ATTRIB_HIDE" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Plans d'alimentation avances masques

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Economies d'energie restaurees - Parametres par defaut actifs.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Un redemarrage est recommande pour appliquer les modifications.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

:TOGGLE_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%  GESTION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section permet de gerer les economies d'energie du systeme.%COLOR_RESET%
echo %COLOR_WHITE%  Les PC de bureau peuvent desactiver ces fonctions pour maximiser%COLOR_RESET%
echo %COLOR_WHITE%  les performances. Les PC portables peuvent les conserver.%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_RED%Desactiver les economies d'energie (Performances maximales)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Restaurer les economies d'energie (Parametres par defaut)%COLOR_RESET%
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
choice /C 12M /N /M "%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if errorlevel 3 goto :MENU_PRINCIPAL
if errorlevel 2 goto :REVERT_ECONOMIES_ENERGIE
if errorlevel 1 goto :DESACTIVER_ECONOMIES_ENERGIE
goto :TOGGLE_ECONOMIES_ENERGIE

:DESACTIVER_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%  SECTION 8 : DESACTIVATION DES PROTECTIONS DE SECURITE   %COLOR_RESET%
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

:: 8.1 - Desactivation des protections Kernel SEHOP Exception Chain 
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des protections noyau (SEHOP, Exception Chain)... 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul 2>&1 
echo %COLOR_GREEN%[OK]%COLOR_RESET% Protections noyau desactivees 

:: 8.2 - Desactivation Spectre Meltdown Memory Management
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des protections Spectre/Meltdown...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableCfg /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableGdsMitigation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PerformMmioMitigation /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Protections Spectre/Meltdown desactivees

:: 8.3 - Desactivation des mitigations CPU avancees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des mitigations CPU (KVAS, STIBP, Retpoline)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Mitigations CPU desactivees

:: 8.4 - HVCI et CFG conserves pour compatibilite anti-cheat
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

echo %COLOR_YELLOW%[*]%COLOR_RESET% Reactivation de Tamper Protection...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 5 /f >nul 2>&1

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
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :TOGGLE_DEFENDER
)

:DESACTIVER_DEFENDER_SECTION
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation de Windows Defender...%COLOR_RESET%
echo.
echo %COLOR_YELLOW%ATTENTION: Desactiver Windows Defender expose votre systeme a des risques.%COLOR_RESET%
echo.

:: Desactiver Tamper Protection d'abord (necessaire pour modifier les services)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de Tamper Protection...
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v TamperProtection /t REG_DWORD /d 0 /f >nul 2>&1

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
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :TOGGLE_DEFENDER
)

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
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :TOGGLE_UAC
)

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
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :TOGGLE_UAC
)

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
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :TOGGLE_ANIMATIONS
)

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
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :TOGGLE_ANIMATIONS
)

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
:: Restaurer disponibilite Copilot
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /f >nul 2>&1
:: Restaurer acces modeles IA
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Allow" /f >nul 2>&1
:: Restaurer activation vocale IA
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 1 /f >nul 2>&1
:: Restaurer Click to Do et Insights
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
:: Restaurer espaces de travail IA
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /f >nul 2>&1
:: Supprimer les blocages hosts Copilot uniquement
set "HOSTS=%windir%\System32\drivers\etc\hosts"
powershell -NoProfile -c "(Get-Content '%HOSTS%') | Where-Object { $_ -notmatch 'copilot\.microsoft\.com|windows\.ai\.microsoft\.com|copilot-telemetry\.microsoft\.com|Copilot Block' } | Set-Content '%HOSTS%'" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Copilot et fonctions IA reactives.
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
:: Marquer Copilot indisponible
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /t REG_SZ /d "FeatureIsDisabled" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /t REG_DWORD /d 0 /f >nul 2>&1
:: Bloquer acces aux modeles IA systeme
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
:: Desactiver activation vocale IA
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Desactiver Click to Do et Insights
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Desactiver espaces de travail IA (Windows 11 24H2+)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /t REG_DWORD /d 1 /f >nul 2>&1
:: Bloquer domaines Copilot/AI via hosts
set "HOSTS=%windir%\System32\drivers\etc\hosts"
echo.>> "%HOSTS%"
echo # --- Copilot Block --->> "%HOSTS%"
echo 0.0.0.0 copilot.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 copilot-telemetry.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 windows.ai.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 bingapis.com>> "%HOSTS%"
echo 0.0.0.0 msedge.api.cdp.microsoft.com>> "%HOSTS%"
echo 0.0.0.0 edge.microsoft.com>> "%HOSTS%"
echo # --- End Copilot Block --->> "%HOSTS%"
echo %COLOR_GREEN%[OK]%COLOR_RESET% Copilot et fonctions IA desactives.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Domaines Copilot bloques via hosts.
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
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowRecallEnablement /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowAIGameFeatures /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowClickToDo /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableImageInsights /f >nul 2>&1
:: Restaurer acces modeles IA et collecte donnees
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v Value /t REG_SZ /d "Allow" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Recall et toutes les fonctions IA activees.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Recall necessite un PC compatible NPU et Windows 11 24H2.
pause
goto :TOGGLE_COPILOT

:DESACTIVER_RECALL
cls
echo %COLOR_RED%[-]%COLOR_RESET% %STYLE_BOLD%Desactivation complete de Recall et IA...%COLOR_RESET%
echo.
:: Desactivation des snapshots et analyse IA
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v DisableAIDataAnalysis /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v TurnOffSavingSnapshots /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowRecallEnablement /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowAIGameFeatures /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v AllowClickToDo /t REG_DWORD /d 0 /f >nul 2>&1
:: Espaces de travail IA (Windows 11 24H2+)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /t REG_DWORD /d 1 /f >nul 2>&1
:: Bloquer acces aux modeles IA systeme
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
:: Desactiver activation vocale IA
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Desactiver Click to Do et Insights
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Desactiver la collecte de donnees pour Recall
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableImageInsights /t REG_DWORD /d 1 /f >nul 2>&1
:: Supprimer les donnees existantes de Recall
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Recall" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Recall" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Recall, IA et collecte de donnees desactives.
echo %COLOR_YELLOW%[!]%COLOR_RESET% Les donnees existantes ont ete supprimees.
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
:: Marquer Copilot indisponible
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /t REG_SZ /d "FeatureIsDisabled" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /t REG_DWORD /d 0 /f >nul 2>&1
:: Desactiver Copilot dans la recherche Windows
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
:: Espaces de travail IA (Windows 11 24H2+)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /t REG_DWORD /d 1 /f >nul 2>&1
:: Bloquer acces aux modeles IA systeme
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
:: Desactiver activation vocale IA
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: Desactiver Click to Do et Insights
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
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

call :INSTALLER_VISUAL_REDIST call

cls
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
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en desactivant l'antivirus
echo       %COLOR_YELLOW%Expose le systeme aux virus et logiciels malveillants%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver Windows Defender (recommande)
echo.
set "DESACTIVER_DEFENDER=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Desactiver Windows Defender ? [O/N]: %COLOR_RESET%"
if errorlevel 2 goto :DESKTOP_DEFENDER_NON
if errorlevel 1 set "DESACTIVER_DEFENDER=1"
:DESKTOP_DEFENDER_NON

cls
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les animations Windows ?%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en supprimant les animations
echo       %COLOR_YELLOW%L'interface sera moins fluide visuellement%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les animations (recommande)
echo.
set "DESACTIVER_ANIMATIONS=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Desactiver les animations ? [O/N]: %COLOR_RESET%"
if errorlevel 2 goto :DESKTOP_ANIMATIONS_NON
if errorlevel 1 set "DESACTIVER_ANIMATIONS=1"
:DESKTOP_ANIMATIONS_NON

cls
call :OPTIMISATIONS_SYSTEME call
call :OPTIMISATIONS_MEMOIRE call
call :OPTIMISATIONS_DISQUES call
call :OPTIMISATIONS_GPU call
call :OPTIMISATIONS_RESEAU call
call :OPTIMISATIONS_PERIPHERIQUES call
call :DESACTIVER_ECONOMIES_ENERGIE call
if "%DESACTIVER_SECURITE%"=="1" call :DESACTIVER_PROTECTIONS_SECURITE call
if "%DESACTIVER_DEFENDER%"=="1" call :DESACTIVER_DEFENDER_SECTION call
if "%DESACTIVER_ANIMATIONS%"=="1" call :DESACTIVER_ANIMATIONS_SECTION call
cls
echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% Toutes les optimisations Desktop ont ete appliquees avec succes.
if "%DESACTIVER_SECURITE%"=="1" (
  echo %COLOR_RED%[!]%COLOR_RESET% Les protections de securite ont ete desactivees.
)
if "%DESACTIVER_DEFENDER%"=="1" (
  echo %COLOR_RED%[!]%COLOR_RESET% Windows Defender a ete desactive.
)
if "%DESACTIVER_ANIMATIONS%"=="1" (
  echo %COLOR_YELLOW%[!]%COLOR_RESET% Les animations Windows ont ete desactivees.
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

call :INSTALLER_VISUAL_REDIST call

cls
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
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en desactivant l'antivirus
echo       %COLOR_YELLOW%Expose le systeme aux virus et logiciels malveillants%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver Windows Defender (recommande)
echo.
set "DESACTIVER_DEFENDER=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Desactiver Windows Defender ? [O/N]: %COLOR_RESET%"
if errorlevel 2 goto :LAPTOP_DEFENDER_NON
if errorlevel 1 set "DESACTIVER_DEFENDER=1"
:LAPTOP_DEFENDER_NON

cls
echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les animations Windows ?%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en supprimant les animations
echo       %COLOR_YELLOW%L'interface sera moins fluide visuellement%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les animations (recommande)
echo.
set "DESACTIVER_ANIMATIONS=0"
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Desactiver les animations ? [O/N]: %COLOR_RESET%"
if errorlevel 2 goto :LAPTOP_ANIMATIONS_NON
if errorlevel 1 set "DESACTIVER_ANIMATIONS=1"
:LAPTOP_ANIMATIONS_NON

cls
call :OPTIMISATIONS_SYSTEME call
call :OPTIMISATIONS_MEMOIRE call
call :OPTIMISATIONS_DISQUES call
call :OPTIMISATIONS_GPU call
call :OPTIMISATIONS_RESEAU call
call :OPTIMISATIONS_PERIPHERIQUES call
:: Note: DESACTIVER_ECONOMIES_ENERGIE NON appele pour Laptop (preserve la batterie)
if "%DESACTIVER_SECURITE%"=="1" call :DESACTIVER_PROTECTIONS_SECURITE call
if "%DESACTIVER_DEFENDER%"=="1" call :DESACTIVER_DEFENDER_SECTION call
if "%DESACTIVER_ANIMATIONS%"=="1" call :DESACTIVER_ANIMATIONS_SECTION call
cls
echo.
echo %COLOR_CYAN%===========================================================%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% Toutes les optimisations Laptop ont ete appliquees avec succes.
echo %COLOR_GREEN%[INFO]%COLOR_RESET% Les economies d'energie ont ete preservees pour la batterie.
if "%DESACTIVER_SECURITE%"=="1" (
  echo %COLOR_RED%[!]%COLOR_RESET% Les protections de securite ont ete desactivees.
)
if "%DESACTIVER_DEFENDER%"=="1" (
  echo %COLOR_RED%[!]%COLOR_RESET% Windows Defender a ete desactive.
)
if "%DESACTIVER_ANIMATIONS%"=="1" (
  echo %COLOR_YELLOW%[!]%COLOR_RESET% Les animations Windows ont ete desactivees.
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

echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification et activation de la restauration systeme si necessaire...
:: Verifier si la restauration systeme est activee via PowerShell (plus fiable)
powershell -NoProfile -Command "try { $status = Get-ComputerRestorePoint -ErrorAction SilentlyContinue; if ($status) { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if %errorlevel% neq 0 (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation de la restauration systeme...
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /t REG_DWORD /d 1 /f >nul 2>&1
    powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive 'C:' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
    timeout /t 2 /nobreak >nul
)
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Creation d'un point de restauration en cours...
echo %COLOR_YELLOW%[*]%COLOR_RESET% Cette operation peut prendre 30-60 secondes...
echo.

:: Creation du point de restauration avec timeout de 120 secondes et timestamp
set "RP_TIMESTAMP=%DATE:/=-%_%TIME::=-%"
set "RP_TIMESTAMP=%RP_TIMESTAMP: =%"
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; try { $startTime = Get-Date; $job = Start-Job { Checkpoint-Computer -Description 'Optimizations_%RP_TIMESTAMP%' -RestorePointType 'MODIFY_SETTINGS' }; $completed = $job | Wait-Job -Timeout 120; if (-not $completed) { Stop-Job $job; Remove-Job $job; throw 'Timeout' }; $result = Receive-Job $job; Remove-Job $job; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Point de restauration cree avec succes.
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Nom : Optimizations_%RP_TIMESTAMP%
) else (
    echo %COLOR_RED%[ATTENTION]%COLOR_RESET% Echec de la creation du point de restauration.
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Raison possible : timeout depasse ou restauration desactivee.
)
set "RP_TIMESTAMP="
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
del /s /q /f "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fichiers temporaires Windows supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des logs systeme...
del /s /q /f "%SystemRoot%\Logs\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\LogFiles\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Panther\*.log" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Logs systeme supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des fichiers de crash...
del /s /q /f "%SystemRoot%\Minidump\*.*" >nul 2>&1
del /q /f "%SystemRoot%\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\memory.dmp" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fichiers de crash supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des rapports d'erreurs...
rd /s /q "C:\ProgramData\Microsoft\Windows\WER" >nul 2>&1
md "C:\ProgramData\Microsoft\Windows\WER" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Rapports d'erreurs supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage cache Windows Update...
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
timeout /t 2 /nobreak >nul
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
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
del /s /q /f "%SystemRoot%\Logs\CBS\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.log" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Journaux CBS/DISM nettoyes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache de polices...
net stop FontCache >nul 2>&1
timeout /t 1 /nobreak >nul
del /s /q /f "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /q /f "%SystemRoot%\System32\FNTCACHE.DAT" >nul 2>&1
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

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache NVIDIA (shaders jeux preserves)...
:: DXCache PRESERVE - Contient les shaders des jeux (Forza, etc.)
:: if exist "%LOCALAPPDATA%\NVIDIA\DXCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\DXCache" >nul 2>&1
:: GLCache PRESERVE - Contient les shaders OpenGL des jeux
:: if exist "%LOCALAPPDATA%\NVIDIA\GLCache" rd /s /q "%LOCALAPPDATA%\NVIDIA\GLCache" >nul 2>&1
:: Nettoyage des autres caches NVIDIA (pas de shaders jeux)
if exist "%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache" rd /s /q "%LOCALAPPDATA%\NVIDIA Corporation\NV_Cache" >nul 2>&1
if exist "%PROGRAMDATA%\NVIDIA Corporation\NV_Cache" rd /s /q "%PROGRAMDATA%\NVIDIA Corporation\NV_Cache" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache NVIDIA nettoye (shaders DX/GL preserves)

:: Cache DirectX - ENTIEREMENT PRESERVE pour les jeux
:: D3DSCache contient les shaders DirectX compiles des jeux
:: if exist "%LOCALAPPDATA%\D3DSCache" rd /s /q "%LOCALAPPDATA%\D3DSCache" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Cache DirectX Shader preserve

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des journaux Event Viewer...
for /f "tokens=*" %%G in ('wevtutil el 2^>nul') do wevtutil cl "%%G" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Journaux Event Viewer nettoyes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression du dossier Windows.old (si present)...
if exist "%SystemDrive%\Windows.old" (
    takeown /f "%SystemDrive%\Windows.old" /r /d y >nul 2>&1
    icacls "%SystemDrive%\Windows.old" /grant administrators:F /t >nul 2>&1
    rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Dossier Windows.old supprime
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Aucun dossier Windows.old trouve
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des anciens pilotes dupliques...
powershell -NoProfile -Command "pnputil /enum-drivers 2>$null | Select-String 'oem\d+\.inf' -AllMatches | ForEach-Object { $_.Matches.Value } | Sort-Object -Unique | ForEach-Object { pnputil /delete-driver $_ /force 2>$null }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Anciens pilotes dupliques supprimes

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

:: PRESERVES : DownloadsFolder, D3D/DirectX Shader Cache (jeux), Internet Cache Files (sessions)
for %%K in (
    "Active Setup Temp Folders"
    "BranchCache"
    "Content Indexer Cleaner"
    "Delivery Optimization Files"
    "Device Driver Packages"
    "Diagnostic Data Viewer database files"
    "Downloaded Program Files"
    "GameNewsFiles"
    "GameStatisticsFiles"
    "GameUpdateFiles"
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

choice /C ON /N /M "%COLOR_YELLOW%Voulez-vous redemarrer maintenant ? (O/N):%COLOR_RESET% "
if errorlevel 2 goto :MENU_PRINCIPAL
if errorlevel 1 shutdown /r /t 10 /c "Redemarrage pour finaliser le nettoyage de Windows"

pause
goto :MENU_PRINCIPAL


:INSTALLER_VISUAL_REDIST
cls
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%     INSTALLATION DES VISUAL C++ REDISTRIBUTABLES     %COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section installe tous les Visual C++ Redistributables%COLOR_RESET%
echo %COLOR_WHITE%  necessaires pour les jeux et applications (2005 a 2022).%COLOR_RESET%
echo.

:: Initialiser les compteurs
set VCINSTALL=0
set VCSKIP=0

echo %COLOR_YELLOW%[*]%COLOR_RESET% Detection des versions deja installees...
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.

:: Detection fiable via le registre Windows (Uninstall keys)
:: Methode 100% sure : verifie les installations officielles dans le registre

set VC2005X86=0
set VC2005X64=0
set VC2008X86=0
set VC2008X64=0
set VC2010X86=0
set VC2010X64=0
set VC2012X86=0
set VC2012X64=0
set VC2013X86=0
set VC2013X64=0
set VC2015X86=0
set VC2015X64=0

:: Detection via registre Uninstall (x64 dans SOFTWARE, x86 dans WOW6432Node sur Windows 64-bit)
:: Note: Sur Windows 32-bit, tout est dans SOFTWARE. Sur 64-bit, x86 est dans WOW6432Node.

:: VC++ 2005 x86 (WOW6432Node sur 64-bit, SOFTWARE sur 32-bit)
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2005" | findstr /I "x86" >nul 2>&1
if %ERRORLEVEL%==0 set VC2005X86=1
:: Fallback pour Windows 32-bit
if %VC2005X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2005" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2005X86=1
)
:: VC++ 2005 x64 (toujours dans SOFTWARE)
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2005" | findstr /I "x64" >nul 2>&1
if %ERRORLEVEL%==0 set VC2005X64=1

:: VC++ 2008 x86 (WOW6432Node sur 64-bit)
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2008" | findstr /I "x86" >nul 2>&1
if %ERRORLEVEL%==0 set VC2008X86=1
if %VC2008X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2008" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2008X86=1
)
:: VC++ 2008 x64
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2008" | findstr /I "x64" >nul 2>&1
if %ERRORLEVEL%==0 set VC2008X64=1

:: VC++ 2010 x86 (WOW6432Node sur 64-bit)
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2010" | findstr /I "x86" >nul 2>&1
if %ERRORLEVEL%==0 set VC2010X86=1
if %VC2010X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2010" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2010X86=1
)
:: VC++ 2010 x64
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2010" | findstr /I "x64" >nul 2>&1
if %ERRORLEVEL%==0 set VC2010X64=1

:: VC++ 2012 x86 (WOW6432Node sur 64-bit)
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2012" | findstr /I "x86" >nul 2>&1
if %ERRORLEVEL%==0 set VC2012X86=1
if %VC2012X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2012" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2012X86=1
)
:: VC++ 2012 x64
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2012" | findstr /I "x64" >nul 2>&1
if %ERRORLEVEL%==0 set VC2012X64=1

:: VC++ 2013 x86 (WOW6432Node sur 64-bit)
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2013" | findstr /I "x86" >nul 2>&1
if %ERRORLEVEL%==0 set VC2013X86=1
if %VC2013X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2013" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2013X86=1
)
:: VC++ 2013 x64
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2013" | findstr /I "x64" >nul 2>&1
if %ERRORLEVEL%==0 set VC2013X64=1

:: VC++ 2015-2022 x86 (WOW6432Node sur 64-bit)
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2015" | findstr /I "x86" >nul 2>&1
if %ERRORLEVEL%==0 set VC2015X86=1
if %VC2015X86%==0 (
    reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2017" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X86=1
)
if %VC2015X86%==0 (
    reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2019" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X86=1
)
if %VC2015X86%==0 (
    reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2022" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X86=1
)
if %VC2015X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2015" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X86=1
)
if %VC2015X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2017" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X86=1
)
if %VC2015X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2019" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X86=1
)
if %VC2015X86%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2022" | findstr /I "x86" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X86=1
)

:: VC++ 2015-2022 x64 (toujours dans SOFTWARE)
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2015" | findstr /I "x64" >nul 2>&1
if %ERRORLEVEL%==0 set VC2015X64=1
if %VC2015X64%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2017" | findstr /I "x64" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X64=1
)
if %VC2015X64%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2019" | findstr /I "x64" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X64=1
)
if %VC2015X64%==0 (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s 2>nul | findstr /I "Visual C++ 2022" | findstr /I "x64" >nul 2>&1
    if %ERRORLEVEL%==0 set VC2015X64=1
)

:: Afficher les resultats de detection
if %VC2005X86%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2005 x86 - Deja installe
if %VC2005X64%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2005 x64 - Deja installe
if %VC2008X86%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2008 x86 - Deja installe
if %VC2008X64%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2008 x64 - Deja installe
if %VC2010X86%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2010 x86 - Deja installe
if %VC2010X64%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2010 x64 - Deja installe
if %VC2012X86%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2012 x86 - Deja installe
if %VC2012X64%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2012 x64 - Deja installe
if %VC2013X86%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2013 x86 - Deja installe
if %VC2013X64%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2013 x64 - Deja installe
if %VC2015X86%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2015-2022 x86 - Deja installe
if %VC2015X64%==1 echo %COLOR_GREEN%[+]%COLOR_RESET% VC++ 2015-2022 x64 - Deja installe

:: Compter combien sont deja installes
set /a VCINSTALLED_COUNT=%VC2005X86%+%VC2005X64%+%VC2008X86%+%VC2008X64%+%VC2010X86%+%VC2010X64%+%VC2012X86%+%VC2012X64%+%VC2013X86%+%VC2013X64%+%VC2015X86%+%VC2015X64%

:: Si tout est deja installe, passer directement au resume
if %VCINSTALLED_COUNT%==12 (
    echo.
    echo %COLOR_GREEN%[OK]%COLOR_RESET% Toutes les versions de Visual C++ Redistributables sont deja installees.
    set /a VCSKIP=%VCINSTALLED_COUNT%
    goto :VCREDIST_RESUME
)

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Installation des versions manquantes...
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo.

:: Creer un dossier temporaire pour les installations
set "VCREDIST_DIR=%TEMP%\VCRedistInstall"
if not exist "%VCREDIST_DIR%" mkdir "%VCREDIST_DIR%"

:: VC++ 2005 x86
if %VC2005X86%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2005 x86 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2005 x86...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x86.exe' -OutFile '%VCREDIST_DIR%\vc2005x86.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2005x86.exe" (
        "%VCREDIST_DIR%\vc2005x86.exe" /Q >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2005 x86 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2005 x86
    )
)

:: VC++ 2005 x64
if %VC2005X64%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2005 x64 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2005 x64...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/B/4/8B42259F-5D70-43F4-AC2E-4B208FD8D66A/vcredist_x64.exe' -OutFile '%VCREDIST_DIR%\vc2005x64.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2005x64.exe" (
        "%VCREDIST_DIR%\vc2005x64.exe" /Q >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2005 x64 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2005 x64
    )
)

:: VC++ 2008 x86
if %VC2008X86%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2008 x86 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2008 x86...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x86.exe' -OutFile '%VCREDIST_DIR%\vc2008x86.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2008x86.exe" (
        "%VCREDIST_DIR%\vc2008x86.exe" /q >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2008 x86 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2008 x86
    )
)

:: VC++ 2008 x64
if %VC2008X64%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2008 x64 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2008 x64...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/5/D/8/5D8C65CB-C849-4025-8E95-C3966CAFD8AE/vcredist_x64.exe' -OutFile '%VCREDIST_DIR%\vc2008x64.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2008x64.exe" (
        "%VCREDIST_DIR%\vc2008x64.exe" /q >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2008 x64 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2008 x64
    )
)

:: VC++ 2010 x86
if %VC2010X86%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2010 x86 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2010 x86...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x86.exe' -OutFile '%VCREDIST_DIR%\vc2010x86.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2010x86.exe" (
        "%VCREDIST_DIR%\vc2010x86.exe" /q >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2010 x86 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2010 x86
    )
)

:: VC++ 2010 x64
if %VC2010X64%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2010 x64 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2010 x64...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/6/5/165255E7-1014-4D0A-B094-B6A430A6BFFC/vcredist_x64.exe' -OutFile '%VCREDIST_DIR%\vc2010x64.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2010x64.exe" (
        "%VCREDIST_DIR%\vc2010x64.exe" /q >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2010 x64 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2010 x64
    )
)

:: VC++ 2012 x86
if %VC2012X86%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2012 x86 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2012 x86...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x86.exe' -OutFile '%VCREDIST_DIR%\vc2012x86.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2012x86.exe" (
        "%VCREDIST_DIR%\vc2012x86.exe" /install /quiet /norestart >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2012 x86 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2012 x86
    )
)

:: VC++ 2012 x64
if %VC2012X64%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2012 x64 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2012 x64...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/1/6/B/16B06F60-3B20-4FF2-B699-5E9B7962F9AE/VSU_4/vcredist_x64.exe' -OutFile '%VCREDIST_DIR%\vc2012x64.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2012x64.exe" (
        "%VCREDIST_DIR%\vc2012x64.exe" /install /quiet /norestart >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2012 x64 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2012 x64
    )
)

:: VC++ 2013 x86
if %VC2013X86%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2013 x86 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2013 x86...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x86.exe' -OutFile '%VCREDIST_DIR%\vc2013x86.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2013x86.exe" (
        "%VCREDIST_DIR%\vc2013x86.exe" /install /quiet /norestart >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2013 x86 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2013 x86
    )
)

:: VC++ 2013 x64
if %VC2013X64%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2013 x64 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2013 x64...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://download.microsoft.com/download/2/E/6/2E61CFA4-993B-4DD4-91DA-3737CD5CD6E3/vcredist_x64.exe' -OutFile '%VCREDIST_DIR%\vc2013x64.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2013x64.exe" (
        "%VCREDIST_DIR%\vc2013x64.exe" /install /quiet /norestart >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2013 x64 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2013 x64
    )
)

:: VC++ 2015-2022 x86
if %VC2015X86%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2015-2022 x86 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2015-2022 x86...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x86.exe' -OutFile '%VCREDIST_DIR%\vc2015x86.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2015x86.exe" (
        "%VCREDIST_DIR%\vc2015x86.exe" /q /norestart >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2015-2022 x86 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2015-2022 x86
    )
)

:: VC++ 2015-2022 x64
if %VC2015X64%==1 (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% VC++ 2015-2022 x64 - Deja present
    set /a VCSKIP=VCSKIP+1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement VC++ 2015-2022 x64...
    powershell -NoProfile -Command "Invoke-WebRequest -Uri 'https://aka.ms/vs/17/release/vc_redist.x64.exe' -OutFile '%VCREDIST_DIR%\vc2015x64.exe' -UseBasicParsing" >nul 2>&1
    if exist "%VCREDIST_DIR%\vc2015x64.exe" (
        "%VCREDIST_DIR%\vc2015x64.exe" /q /norestart >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% VC++ 2015-2022 x64 installe
        set /a VCINSTALL=VCINSTALL+1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec telechargement VC++ 2015-2022 x64
    )
)

:VCREDIST_RESUME
:: Calculer VCSKIP si on a saute l'installation
if not defined VCSKIP set /a VCSKIP=%VCINSTALLED_COUNT%

:: Nettoyage des fichiers temporaires
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des fichiers temporaires...
if exist "%VCREDIST_DIR%" rd /s /q "%VCREDIST_DIR%" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% Fichiers temporaires supprimes

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% Installation des Visual C++ Redistributables terminee.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Resume:%COLOR_RESET%
echo   %COLOR_GREEN%Installes: %VCINSTALL%%COLOR_RESET%
echo   %COLOR_CYAN%Deja presents: %VCSKIP%%COLOR_RESET%
echo.
if "%~1"=="call" (
  exit /b
) else (
  pause
  goto :MENU_PRINCIPAL
)

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
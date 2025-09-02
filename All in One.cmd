@echo off
setlocal EnableDelayedExpansion

:: Activer les sequences d'echappement ANSI pour les couleurs
reg add HKCU\Console /v VirtualTerminalLevel /t reg_DWORD /d 1 /f >nul 2>&1

:: Definir la taille de la console et du tampon
mode con: cols=82 lines=3000

:: Definitions des couleurs avec couleurs vives et styles
for /F %%a in ('echo prompt $E^| cmd') do set "ESC=%%a"
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

:: 1.1 - Outils d'optimisation tiers 
echo %COLOR_YELLOW%[*]%COLOR_RESET% Telechargement et execution de O^&O ShutUp10...
echo.
powershell -Command "Invoke-WebRequest 'https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe' -OutFile '%temp%\OOSU10.exe'">nul 2>&1
powershell -Command "Invoke-WebRequest 'https://raw.githubusercontent.com/kaylerberserk/Optimizer/refs/heads/main/ooshutup10_kayler.cfg' -OutFile '%temp%\kaylerimport.cfg'">nul 2>&1

if exist "%temp%\OOSU10.exe" (
    if exist "%temp%\kaylerimport.cfg" (
        echo %COLOR_GREEN%[+]%COLOR_RESET% O^&O ShutUp10 et configuration telecharges.
        echo %COLOR_YELLOW%[*]%COLOR_RESET% Application de la configuration O^&O ShutUp10...
        powershell -Command "$maxRetries = 3; $retryCount = 0; do { try { $shell = New-Object -ComObject WScript.Shell; $process = Start-Process '%temp%\OOSU10.exe' '%temp%\kaylerimport.cfg' -PassThru; Start-Sleep -Milliseconds 3000; if ($process -and !$process.HasExited) { $shell.SendKeys('{ENTER}'); Start-Sleep -Milliseconds 2000; $shell.SendKeys('{ENTER}'); $retryCount = $maxRetries } else { $retryCount++ } } catch { $retryCount++; Start-Sleep -Milliseconds 1000 } } while ($retryCount -lt $maxRetries)"
        del "%temp%\kaylerimport.cfg" >nul 2>&1
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Erreur: Impossible de telecharger la configuration O^&O ShutUp10.
        echo %COLOR_YELLOW%[*]%COLOR_RESET% O^&O ShutUp10 sera lance interactivement sans configuration predefinie.
        start "O^&O ShutUp10" /WAIT "%temp%\OOSU10.exe"
    )
    del "%temp%\OOSU10.exe" >nul 2>&1
) else (
    echo %COLOR_RED%[-]%COLOR_RESET% Erreur: Impossible de telecharger O^&O ShutUp10.exe.
)
timeout /t 1 /nobreak >nul

:: 1.2 - Optimisations noyau et processus
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation des priorites et processus systeme...

:: Priorites IRQ et controle de priorite
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "IRQ0Priority" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "IRQ8Priority" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t reg_DWORD /d 38 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "ConvertibleSlateMode" /t reg_DWORD /d 0 /f >nul 2>&1

:: Optimisation du processus CSRSS
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "CpuPriorityClass" /t reg_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v "IoPriority" /t reg_DWORD /d 3 /f >nul 2>&1

:: Optimisations du noyau et des processus systeme
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres du noyau et des processus...

:: Optimisations du noyau pour les performances
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v "KernelSEHOPEnabled" /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DisableTsx" /t reg_DWORD /d 0 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "MitigationOptions" /t reg_QWORD /d 0x1000000000000 /f >nul 2>&1 
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "ObCaseInsensitive" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v "DistributeTimers" /t reg_DWORD /d 1 /f >nul 2>&1

:: Optimisation des threads systeme
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v "AdditionalCriticalWorkerThreads" /t reg_DWORD /d 16 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v "AdditionalDelayedWorkerThreads" /t reg_DWORD /d 16 /f >nul 2>&1

:: Optimisations du planificateur graphique
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v "VsyncIdleTimeout" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" /v "PreferSystemMemoryContiguous" /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Priorites et processus systeme optimises.

:: 1.3 - Optimisations multimedia et reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil multimedia...

:: Configuration du profil systeme multimedia
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "AlwaysOn" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "LazyModeTimeout" /t reg_DWORD /d 10000 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "NoLazyMode" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v "SystemResponsiveness" /t reg_DWORD /d 10 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Profil multimedia configure.

:: 1.4 - Corrections specifiques Windows 24H2
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des corrections de performance Windows 24H2...

:: Reinitialisation et configuration des parametres de fonctionnalites
reg delete "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8" /f >nul 2>&1
:: Configuration des parametres de fonctionnalites pour Windows 24H2
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v "EnabledState" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v "EnabledStateOptions" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v "Variant" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v "VariantPayload" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\FeatureManagement\Overrides\8\2897279119" /v "VariantPayloadKind" /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Corrections de performance Windows 24H2 appliquees.

:: 1.5 - Optimisations interface utilisateur
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de l'interface utilisateur...

:: Configuration de la barre des taches et des elements d'interface
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarAnimations" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t reg_DWORD /d 0 /f >nul 2>&1

:: Desactivation des widgets et fonctionnalites non essentielles
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Dsh" /v "AllowNewsAndInterests" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v "EnableFeeds" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v "ChatIcon" /t reg_DWORD /d 3 /f >nul 2>&1

:: Configuration avancee de l'explorateur
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t reg_SZ /d "" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Hidden" /t reg_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "Start_TrackProgs" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontPrettyPath" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DesktopLivePreviewHoverTime" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ExtendedUIHoverTime" /t reg_DWORD /d 0 /f >nul 2>&1

:: Optimiser le gestionnaire de tâches Windows
reg add "HKLM\SYSTEM\CurrentControlSet\Services\TimeBrokerSvc" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Interface utilisateur configuree.

:: 1.6 - Configuration des effets visuels
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des effets visuels pour optimiser les performances...

:: Parametres pour une interface plus reactive (moins d'effets)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v "VisualFXSetting" /t reg_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "UserPreferencesMask" /t reg_BINARY /d "9012038010000000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v "MinAnimate" /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "DragFullWindows" /t reg_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "MenuShowDelay" /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "HungAppTimeout" /t reg_SZ /d "1000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "AutoEndTasks" /t reg_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "FontSmoothing" /t reg_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "LowLevelHooksTimeout" /t reg_SZ /d "1000" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v "WaitToKillAppTimeout" /t reg_SZ /d "2000" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v "WaitToKillServiceTimeout" /t reg_SZ /d "2000" /f >nul 2>&1

:: Optimisations DWM (Desktop Window Manager)
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "DesktopHeapLogging" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "DwmInputUsesIoCompletionPort" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v "EnableDwmInputProcessing" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "EnableAeroPeek" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "AlwaysHibernateThumbnails" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\DWM" /v "Animations" /t reg_DWORD /d 0 /f >nul 2>&1

:: Autres optimisations visuelles
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v "EnableTransparency" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewAlphaSelect" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "PointerShadow" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewShadow" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ListviewWatermark" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v "MouseTrails" /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableAnimations" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v "DisableStartupAnimation" /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Effets visuels configures.

:: 1.7 - Configuration de Windows Search
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de Windows Search (Activation par defaut)...

set "SearchAppPath=C:\Windows\SystemApps\Microsoft.Windows.Search_cw5n1h2txyewy"
set "SearchHostPath=C:\Windows\SystemApps\MicrosoftWindows.Client.CBS_cw5n1h2txyewy"

echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification et restauration de searchapp.exe si necessaire...
if exist "%SearchAppPath%\searchapp.exe.bak" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Tentative de restauration de searchapp.exe depuis .bak...
    takeown /f "%SearchAppPath%\searchapp.exe.bak" >nul 2>&1
    icacls "%SearchAppPath%\searchapp.exe.bak" /grant Administrators:F >nul 2>&1
    ren "%SearchAppPath%\searchapp.exe.bak" searchapp.exe >nul 2>&1
    if exist "%SearchAppPath%\searchapp.exe" (
        echo %COLOR_GREEN%[+]%COLOR_RESET% searchapp.exe restaure avec succes.
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% echec de la restauration de searchapp.exe.
    )
) else if exist "%SearchAppPath%\searchapp.exe" (
    echo %COLOR_GREEN%[+]%COLOR_RESET% searchapp.exe est deja present et fonctionnel.
) else (
    echo %COLOR_YELLOW%[-]%COLOR_RESET% searchapp.exe et searchapp.exe.bak non trouves. La recherche pourrait être affectee.
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Verification et restauration de SearchHost.exe si necessaire...
if exist "%SearchHostPath%\SearchHost.exe.bak" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% Tentative de restauration de SearchHost.exe depuis .bak...
    takeown /f "%SearchHostPath%\SearchHost.exe.bak" >nul 2>&1
    icacls "%SearchHostPath%\SearchHost.exe.bak" /grant Administrators:F >nul 2>&1
    ren "%SearchHostPath%\SearchHost.exe.bak" SearchHost.exe >nul 2>&1
    if exist "%SearchHostPath%\SearchHost.exe" (
        echo %COLOR_GREEN%[+]%COLOR_RESET% SearchHost.exe restaure avec succes.
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% echec de la restauration de SearchHost.exe.
    )
) else if exist "%SearchHostPath%\SearchHost.exe" (
    echo %COLOR_GREEN%[+]%COLOR_RESET% SearchHost.exe est deja present et fonctionnel.
) else (
    echo %COLOR_YELLOW%[-]%COLOR_RESET% SearchHost.exe et SearchHost.exe.bak non trouves. La recherche pourrait être affectee.
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration et demarrage du service Windows Search...
sc config WSearch start= auto >nul 2>&1
sc start WSearch >nul 2>&1
sc query WSearch | findstr /I /C:"RUNNING" >nul
if errorlevel 1 (
    echo %COLOR_RED%[-]%COLOR_RESET% echec du demarrage du service Windows Search.
) else (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Service Windows Search demarre avec succes.
)

:: Configuration de la recherche locale (sans integration Web)
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Windows Search configure pour une recherche locale (sans Bing/Cortana).

:: 1.8 - Desactivation de la telemetrie et collecte de donnees
echo %STYLE_BOLD%%COLOR_WHITE%[*]%COLOR_RESET% %STYLE_BOLD%Desactivation de la telemetrie et de la collecte de donnees...%COLOR_RESET%
echo.

:: Services de telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Arrêt et desactivation des services de telemetrie...
sc stop DiagTrack >nul 2>&1 && sc config DiagTrack start=disabled >nul 2>&1
sc stop dmwappushservice >nul 2>&1 && sc config dmwappushservice start=disabled >nul 2>&1
sc stop diagnosticshub.standardcollector.service >nul 2>&1 && sc config diagnosticshub.standardcollector.service start=disabled >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Services de telemetrie desactives.

:: Taches planifiees de telemetrie et collecte de donnees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des taches planifiees liees a la telemetrie...
schtasks /Change /TN "Microsoft\Windows\FileHistory\File History (maintenance mode)" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\NetTrace\GatherNetworkInfo" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\PI\Sqm-Tasks" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Power Efficiency Diagnostics\AnalyzeSystem" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyMonitor" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Shell\FamilySafetyRefresh" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Error Reporting\QueueReporting" /Disable >nul 2>&1

:: Configuration du registre pour la telemetrie et la collecte de donnees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres de telemetrie dans le registre...

:: Metadonnees des appareils et collecte de donnees
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t reg_DWORD /d 0 /f >nul 2>&1

:: Personnalisation de la saisie
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t reg_DWORD /d 1 /f >nul 2>&1

:: Permissions des capteurs
reg add "HKCU\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Permissions\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "SensorPermissionState" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}" /v "SensorPermissionState" /t reg_DWORD /d 0 /f >nul 2>&1

:: Journalisation WUDF
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF" /v "LogEnable" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\WUDF" /v "LogLevel" /t reg_DWORD /d 0 /f >nul 2>&1

:: Politiques de collecte de donnees
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowCommercialDataPipeline" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowDeviceNameInTelemetry" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "LimitEnhancedDiagnosticDataWindowsAnalytics" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MicrosoftEdgeDataOptIn" /t reg_DWORD /d 0 /f >nul 2>&1

echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration du registre pour la telemetrie terminee.

:: Desactivation des AutoLoggers pour la telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des AutoLoggers...

reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\AppModel" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Cellcore" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\Circular Kernel Context Logger" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\CloudExperienceHostOobe" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DataMarket" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DefenderApiLogger" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DefenderAuditLogger" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\DiagLog" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot" /v "Start" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\SQMLogger" /v "Start" /t reg_DWORD /d 0 /f >nul 2>&1

echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des AutoLoggers terminee.

:: Taches planifiees supplementaires a faible valeur (bavardes)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de taches planifiees supplementaires...
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
) do (
  schtasks /Change /TN "%%~T" /Disable >nul 2>&1
)
echo %COLOR_GREEN%[+]%COLOR_RESET% Taches planifiees supplementaires desactivees.

:: Desactivation Windows Error Reporting (WER)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de Windows Error Reporting (WER)...
sc stop WerSvc >nul 2>&1
sc config WerSvc start= disabled >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v Disabled /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Windows Error Reporting desactive.

:: 1.9 - Optimisations supplementaires du systeme
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations supplementaires...

:: Activation du Mode Jeu
reg add "HKCU\SOFTWARE\Microsoft\GameBar" /v "AutoGameModeEnabled" /t reg_DWORD /d 1 /f >nul 2>&1

:: Optimisations systeme avancees
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" /v "InactivityShutdownDelay" /t reg_DWORD /d 4294967295 /f >nul 2>&1

:: Autoriser apps UWP à tourner librement en arrière-plan pour augmenter la réactivité
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v GlobalUserDisabled /t REG_DWORD /d 0 /f >nul 2>&1

:: Parametres de compatibilite des applications
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des parametres de compatibilite des applications...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t reg_DWORD /d 0 /f >nul 2>&1

:: Configuration de l'Assistant Stockage (Storage Sense)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de l'Assistant Stockage...
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "04" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "08" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "32" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "256" /t reg_DWORD /d 30 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "512" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "1024" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "2048" /t reg_DWORD /d 7 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "StoragePoliciesChanged" /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "StoragePoliciesNotified" /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration de l'Assistant Stockage terminee.

:: 1.10 - Activation MSI (Message Signaled Interrupts) pour peripheriques critiques
echo %COLOR_YELLOW%[*]%COLOR_RESET% Activation des MSI (Message Signaled Interrupts) sur peripheriques critiques...
powershell -Command "Get-PnpDevice -Class @('Display','HDC','SCSIAdapter','System') -Status OK | ForEach-Object { Set-ItemProperty -Path ('HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\\Device Parameters\\Interrupt Management\\MessageSignaledInterruptProperties') -Name 'MSISupported' -Value 1 -Force }" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% MSI activees (si pris en charge par les pilotes). Un redemarrage peut etre necessaire.

:: Economie d'energie sur batterie
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de l'economie d'energie sur batterie...
powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: Configuration Services mises a jour automatiques 
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration Services mises a jour automatiques...

:: Windows Update 
sc config wuauserv start= auto 
net start wuauserv 

:: Service de licence des applications (ClipSVC) 
reg add "HKLM\SYSTEM\CurrentControlSet\Services\ClipSVC" /v Start /t reg_DWORD /d 2 /f 

:: Activer les mises a jour automatiques 
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\WindowsStore" /v "AutoDownload" /t reg_DWORD /d 4 /f 

:: Permettre les mises a jour silencieuses des applications 
reg add "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SilentInstalledAppsEnabled" /t reg_DWORD /d 0 /f

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
:: Optimiser le cache de fichiers système
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "SystemCacheDirtyPageThreshold" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_YELLOW%[*]%COLOR_RESET% Debut de la section d'optimisations memoire.
echo %COLOR_WHITE%[*]%COLOR_RESET% Application des optimisations memoire haute performance...

:: 2.1 - Gestion des processus et planificateur optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de la gestion des processus et du planificateur...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v AlpcWakePolicy /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v EnableSpecialPool /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CriticalSectionTimeout /t reg_DWORD /d 5000 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v GlobalFlag /t reg_DWORD /d 0 /f >nul 2>&1

:: 2.2 - Memory Management - Configuration principale optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration Memory Management (Configuration principale)...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingExecutive /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t reg_DWORD /d 0 /f >nul 2>&1

:: 2.3 - Page File et compression desactives
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du Page File et de la compression...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ClearPageFileAtShutdown /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SystemPages /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePageCombining /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagingCombining /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Memory Management" /v DisableCompression /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisablePagefileEncryption /t reg_DWORD /d 1 /f >nul 2>&1

:: 2.4 - Desactivation Prefetch/Superfetch/BootTrace
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de Prefetch/Superfetch/BootTrace...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t reg_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t reg_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Prefetch/Superfetch/BootTrace: desactives.

:: 2.5 - Kernel Mitigations - Desactivation complete pour performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des Kernel Mitigations pour performance maximale...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t reg_DWORD /d 1 /f >nul 2>&1
if "%IS_LAPTOP%"=="1" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t reg_DWORD /d 1 /f >nul 2>&1
) else (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t reg_DWORD /d 3 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t reg_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableCfg /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Kernel Mitigations desactivees.

:: 2.6 - Mitigations Spectre/Meltdown desactivees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des mitigations Spectre/Meltdown...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Mitigations Spectre/Meltdown desactivees.

:: 2.7 - Cache et performances CPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du cache et des performances CPU...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SecondLevelDataCache /t reg_DWORD /d 1024 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v ThirdLevelDataCache /t reg_DWORD /d 8192 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PhysicalAddressExtension /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableLowVaAccess /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration du cache et CPU terminee.

:: 2.8 - Desactivation FTH (Fault Tolerant Heap) et validation
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation de FTH et des validations...
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v Enabled /t reg_DWORD /d 0 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\FTH\State" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation FTH et validations terminee.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v DisableExceptionChainValidation /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Validations supplementaires desactivees.

:: 2.9 - Configuration Heap optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du Heap pour haute performance...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v HeapDeCommitFreeBlockThreshold /t reg_DWORD /d 524288 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v HeapDeCommitTotalFreeThreshold /t reg_DWORD /d 4194304 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v HeapSegmentReserve /t reg_DWORD /d 2097152 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v HeapSegmentCommit /t reg_DWORD /d 262144 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v HeapLockTimeout /t reg_DWORD /d 1000 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration Heap optimisee terminee.

:: 2.10 - MMAgent optimise pour performance gaming
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de MMAgent pour haute performance gaming...

:: Detection de la RAM pour la compression memoire
for /f "usebackq" %%a in (`powershell -Command "(Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB"`) do set RAM_GB=%%a
set /a RAM_GB=!RAM_GB!

if %RAM_GB% GEQ 8 (
    echo %COLOR_CYAN%[i]%COLOR_RESET% RAM detectee: %RAM_GB%GB - Desactivation compression memoire pour performance
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableMemoryCompression /t reg_DWORD /d 1 /f >nul 2>&1
    if !errorlevel! == 0 (
        echo %COLOR_GREEN%[+]%COLOR_RESET% Compression memoire desactivee
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec desactivation compression memoire
    )
) else (
    echo %COLOR_CYAN%[i]%COLOR_RESET% RAM detectee: %RAM_GB%GB - Conservation compression memoire pour optimiser usage RAM
)

:: 2.11 - Optimisations avancees memoire
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations avancees de la memoire...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableNonPagedPoolNx /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v NonPagedPoolNxPolicy /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PagedPoolNonPagedLimit /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SessionImageSize /t reg_DWORD /d 67108864 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SessionPoolSize /t reg_DWORD /d 192 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v SessionViewSize /t reg_DWORD /d 192 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations avancees de la memoire terminees.

echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisations memoire appliquees avec succes !
echo %COLOR_GREEN%[+]%COLOR_RESET% Un redemarrage est recommande pour appliquer tous les changements.
echo.
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
echo %COLOR_WHITE%                    SECTION 3: OPTIMISATIONS DISQUE ET STOCKAGE%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Application des optimisations de disque et stockage...

:: 3.1 - Optimisations FSUtil (comportement systeme fichiers)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de FSUtil pour haute performance...
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration FSUtil terminee.
fsutil behavior set mftzone 2 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set encryptpagingfile 0 >nul 2>&1
fsutil behavior set memoryusage 2 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set disablecompression 1 >nul 2>&1
fsutil behavior set disableencryption 1 >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration FSUtil pour haute performance terminee.

:: 3.2 - Optimisations du registre pour le systeme de fichiers
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du registre FileSystem pour haute performance...

:: Parametres de base optimises
echo %COLOR_YELLOW%[~]%COLOR_RESET% Application des parametres de base optimises...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisabledeleteNotification /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v Win31FileSystem /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Parametres de base du systeme de fichiers optimises.

:: Exécuter TRIM manuellement pour optimiser les performances SSD
echo %COLOR_YELLOW%[~]%COLOR_RESET% Exécution de TRIM sur les disques SSD...
powershell -Command "Get-PhysicalDisk | Where MediaType -eq SSD | Get-StorageDiagnosticInfo -IncludePerfLog | Out-Null" >nul 2>&1
powershell -Command "Optimize-Volume -DriveLetter C -ReTrim -Verbose" >nul 2>&1

:: Optimiser les paramètres de stockage pour SSD
echo %COLOR_YELLOW%[~]%COLOR_RESET% Optimisation des paramètres de stockage SSD...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IoLatencyCap" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v "NtfsMemoryUsage" /t REG_DWORD /d 2 /f >nul 2>&1

:: Optimisations NTFS performance maximale
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations NTFS avancees...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisable8dot3NameCreation /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NTFSDisableLastAccessUpdate /t reg_DWORD /d 2147483649 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMftZoneReservation /t reg_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsAllowExtendedCharacter8dot3Rename /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsBugcheckOnCorrupt /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableCompression /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsDisableEncryption /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsEncryptPagingFile /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsMemoryUsage /t reg_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NtfsQuotaNotifyRate /t reg_DWORD /d 3600 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations NTFS avancees terminees.

:: Optimisations ReFS
echo %COLOR_YELLOW%[*]%COLOR_RESET% Application des optimisations ReFS...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v RefsDisableLastAccessUpdate /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v RefsEnableInlineTrim /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations ReFS terminees.

:: Cache et allocation optimises
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du cache et de l'allocation...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v FileNameCache /t reg_DWORD /d 2048 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v PathCache /t reg_DWORD /d 256 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v ContigFileAllocSize /t reg_DWORD /d 2048 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v MaximumTunnelEntries /t reg_DWORD /d 1024 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v MaximumTunnelEntryAgeInSeconds /t reg_DWORD /d 15 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations du cache et de l'allocation terminees.

:: Performance I/O optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation des performances I/O...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v UdfsSoftwareDefectManagement /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DontVerifyRandomDrivers /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v FilterSupportedFeaturesMode /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations des performances I/O terminees.
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations du registre pour le systeme de fichiers terminees.

:: 3.3 - Optimisations disques SSD/NVMe haute performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration SSD/NVMe haute performance...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storahci\Parameters\Device" /v TreatAsInternalPort /t reg_MULTI_SZ /d "*" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" /v IoLatencyCap /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration SSD/NVMe haute performance terminee.

:: 3.4 - Optimisations defragmentation et maintenance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de la defragmentation et maintenance optimisee...
reg add "HKLM\SOFTWARE\Microsoft\Dfrg\BootOptimizeFunction" /v Enable /t reg_SZ /d "Y" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OptimalLayout" /v EnableAutoLayout /t reg_DWORD /d 0 /f >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Enable >nul 2>&1
sc config defragsvc start= delayed-auto >nul
sc start defragsvc >nul
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration de la defragmentation et maintenance terminee.

:: 3.5 - Optimisations kernel pour I/O
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du kernel pour I/O...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v ProtectionMode /t reg_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration du kernel pour I/O terminee.
echo %COLOR_GREEN%[+]%COLOR_RESET% Section Optimisations Disque et Stockage terminee.

:: 3.6 - Desactivation fonctionnalites impactant performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation des fonctionnalites impactant la performance...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoLowDiskSpaceChecks /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v LinkResolveIgnoreLinkInfo /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoResolveSearch /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v NoResolveTrack /t reg_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des fonctionnalites impactant la performance terminee.

:: 3.7 - Configuration services disque pour performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration des services disque pour la performance...
sc config "SysMain" start= disabled >nul 2>&1
sc config "Themes" start= auto >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration des services disque pour la performance terminee.

echo.
echo %COLOR_WHITE%[*]%COLOR_RESET% Optimisations disque appliquees !
echo.
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

:: 4.1 - Profil DisplayPostProcessing (optimise pour latence minimale)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil DisplayPostProcessing pour latence minimale...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Affinity" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Background Only" /t reg_SZ /d "True" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "BackgroundPriority" /t reg_DWORD /d "24" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Clock Rate" /t reg_DWORD /d "10000" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "GPU Priority" /t reg_DWORD /d "18" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Priority" /t reg_DWORD /d "8" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Scheduling Category" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "SFIO Priority" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\DisplayPostProcessing" /v "Latency Sensitive" /t reg_SZ /d "True" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Profil DisplayPostProcessing configure.

:: 4.2 - Profil Games (priorite maximale)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil Games pour priorite maximale...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Affinity" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Background Only" /t reg_SZ /d "False" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Clock Rate" /t reg_DWORD /d "10000" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t reg_DWORD /d "18" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t reg_DWORD /d "6" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Latency Sensitive" /t reg_SZ /d "True" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Profil Games configure.

:: 4.3 - Profil Low Latency (ultra priorite)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil Low Latency pour ultra priorite...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Affinity" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Background Only" /t reg_SZ /d "False" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Clock Rate" /t reg_DWORD /d "10000" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "GPU Priority" /t reg_DWORD /d "18" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Priority" /t reg_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Scheduling Category" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "SFIO Priority" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Low Latency" /v "Latency Sensitive" /t reg_SZ /d "True" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Profil Low Latency configure.

:: 4.4 - Profil Pro Audio (pour applications multimedia)
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration du profil Pro Audio pour applications multimedia...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Affinity" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Background Only" /t reg_SZ /d "False" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Clock Rate" /t reg_DWORD /d "10000" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "GPU Priority" /t reg_DWORD /d "18" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Priority" /t reg_DWORD /d "3" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Scheduling Category" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "SFIO Priority" /t reg_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Pro Audio" /v "Latency Sensitive" /t reg_SZ /d "True" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Profil Pro Audio configure.

:: 4.5 - Configuration GameDVR et Game Bar
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration de GameDVR et de la Game Bar...
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_Enabled" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_FSEBehaviorMode" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_HonorUserFSEBehaviorMode" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_DXGIHonorFSEWindowsCompatible" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v "GameDVR_EFSEFeatureFlags" /t reg_DWORD /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration GameDVR et Game Bar terminee.

:: 4.6 - Optimisations DirectX et DXGI avancees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration avancee de DirectX et DXGI...
reg add "HKLM\SOFTWARE\Microsoft\DirectX" /v "MaxFrameLatency" /t reg_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectX" /v "UseRenderThread" /t reg_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectX" /v "DisableAGPSupport" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectX" /v "DisableDebugLayer" /t reg_DWORD /d "1" /f >nul 2>&1

:: Optimisations DXGI
reg add "HKLM\SOFTWARE\Microsoft\DXGI" /v "MaxFrameLatency" /t reg_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DXGI" /v "UseDeferredPresent" /t reg_DWORD /d "1" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations DirectX et DXGI avancees appliquees.

:: 4.7 - Optimisations GPU systeme avancees
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration avancee du GPU systeme...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "PlatformSupportMiracast" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "DisableAsyncPowerGating" /t reg_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "UseGpuTimer" /t reg_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "HwSchMode" /t reg_DWORD /d "2" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "DdiScheduler" /t reg_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "TdrLevel" /t reg_DWORD /d "3" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "TdrDelay" /t reg_DWORD /d "2" /f >nul 2>&1

:: 4.8 - Desactiver le blocage des pilotes vulnerables
echo %COLOR_YELLOW%[*]%COLOR_RESET% Desactivation du blocage des pilotes vulnerables...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v "VulnerableDriverBlocklistEnable" /t reg_DWORD /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation du blocage des pilotes vulnerables terminee.

:: 4.9 - Configuration DirectX utilisateur optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% Configuration DirectX utilisateur optimisee...
reg add "HKCU\SOFTWARE\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t reg_SZ /d "VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;D3D9FramePacing=0;D3D11On12Enable=0;PreferD3D12For11Enable=1;EnableHDRForAll=0;AutoHDREnable=1;SwapEffectUpgradeOverride=1;SwapEffectUpgradeAuto=1;SwapEffectUpgradeForceEnable=1;UseWindowedPresentPath=0;D3D12ForceAtomicCopy=0;" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration DirectX utilisateur optimisee terminee.

:: 4.10 - Optimisations VRAM et memoire video
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation de la VRAM et de la memoire video...
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "RMGpuVALimit" /t reg_DWORD /d "1" /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v "RmGpuVALimit" /t reg_DWORD /d "1" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation de la VRAM et de la memoire video terminee.

:: 4.11 - Optimisations rendu et performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% Optimisation du rendu et des performances...
reg add "HKCU\SOFTWARE\Microsoft\Avalon.Graphics" /v "DisableHWAcceleration" /t reg_DWORD /d "0" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Avalon.Graphics" /v "MaxMultisampleType" /t reg_DWORD /d "0" /f
reg add "HKCU\SOFTWARE\Microsoft\Avalon.Graphics" /v "EnablePerFrameGPUCommandLogging" /t reg_DWORD /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation du rendu et des performances terminee.

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
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

:: 5.1 — Désactiver la limitation MMCSS
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation de la limitation reseau (MMCSS)...
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1

:: 5.2 — Pile TCP moderne (alignée sur les captures)
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration TCP moderne...
netsh int tcp set heuristics disabled >nul 2>&1
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set supplemental template=internet congestionprovider=cubic >nul 2>&1
netsh int tcp set global rss=enabled >nul 2>&1
netsh int tcp set global rsc=disabled >nul 2>&1
netsh int tcp set global ecncapability=enabled >nul 2>&1
netsh int tcp set global chimney=disabled >nul 2>&1
netsh int tcp set global dca=enabled >nul 2>&1
netsh int tcp set global fastopen=enabled >nul 2>&1
netsh int tcp set global timestamps=enabled >nul 2>&1
netsh int tcp set global maxsynretransmissions=2 >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "Set-NetTCPSetting -SettingName Internet -InitialRtoMs 2000" >nul 2>&1

:: 5.3 — IP global
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration IP globale...
netsh int ip set global taskoffload=enabled >nul 2>&1
netsh int ip set global sourceroutingbehavior=drop >nul 2>&1
netsh int ip set global dhcpmediasense=disabled >nul 2>&1
netsh int ip set global mediasenseeventlog=disabled >nul 2>&1
netsh int ip set global icmpredirects=disabled >nul 2>&1
netsh int ipv6 set global neighborcachelimit=4096 >nul 2>&1

:: 5.4 — Delivery Optimization (P2P off)
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation du partage P2P de Windows Update...
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1

:: 5.5 — DNS : flush + DoH Cloudflare/Google
echo %COLOR_GREEN%[+]%COLOR_RESET% DNS : flush + DoH Cloudflare/Google...
ipconfig /flushdns >nul 2>&1
powershell -NoProfile -ExecutionPolicy Bypass -Command "$if=(Get-NetAdapter|? Status -eq 'Up'|Select-Object -Expand InterfaceAlias); Add-DnsClientDohServerAddress -ServerAddress 1.1.1.1 -DohTemplate 'https://cloudflare-dns.com/dns-query' -AllowFallbackToUdp $true; Add-DnsClientDohServerAddress -ServerAddress 8.8.8.8 -DohTemplate 'https://dns.google/dns-query' -AllowFallbackToUdp $true; foreach($a in $if){ Set-DnsClientServerAddress -InterfaceAlias $a -ServerAddresses 1.1.1.1,8.8.8.8; Set-DnsClientDohServerAddress -InterfaceAlias $a -ServerAddress 1.1.1.1 -AutoUpgrade $true; Set-DnsClientDohServerAddress -InterfaceAlias $a -ServerAddress 8.8.8.8 -AutoUpgrade $true }" >nul 2>&1

:: 5.6 — MTU 1500 (interfaces actives)
echo %COLOR_GREEN%[+]%COLOR_RESET% MTU 1500 sur toutes les interfaces actives...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetIPInterface -AddressFamily IPv4 | ? {$_.InterfaceOperationalStatus -eq 'Up' -and $_.NlMtu -ne 1500} | % { netsh interface ipv4 set subinterface `"$($_.InterfaceAlias)`" mtu=1500 store=persistent }" >nul 2>&1

:: 5.7 — IPv6 natif (désactive ISATAP/Teredo)
echo %COLOR_GREEN%[+]%COLOR_RESET% IPv6 natif conserve ; ISATAP/Teredo desactives...
netsh int isatap set state disabled >nul 2>&1
netsh int teredo set state disabled >nul 2>&1

:: 5.8 — Legacy utiles (RFC1323/SACK/DupACKs/TTL/Ports)
echo %COLOR_GREEN%[+]%COLOR_RESET% Legacy utiles (RFC1323/SACK/DupACKs/TTL)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SackOpts /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDupAcks /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul 2>&1

:: 5.9 — Priorités de résolution (Hosts > DNS)
echo %COLOR_GREEN%[+]%COLOR_RESET% Priorites de resolution (Hosts > DNS)...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v LocalPriority /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v HostsPriority /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v DnsPriority /t REG_DWORD /d 6 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v NetbtPriority /t REG_DWORD /d 7 /f >nul 2>&1

:: 5.10 — Nagle / DelACK OFF (facultatif, gaming)
echo %COLOR_GREEN%[+]%COLOR_RESET% (Facultatif) Desactivation Nagle/DelACK (gaming)...
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /s /f "DhcpIPAddress" 2^>nul ^| findstr /i "HKEY"') do (
  reg add "%%i" /v TcpAckFrequency /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%i" /v TCPNoDelay /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%i" /v TcpDelAckTicks /t REG_DWORD /d 0 /f >nul 2>&1
)

:: 5.11 — QoS Psched (comme tes réglages)
echo %COLOR_GREEN%[+]%COLOR_RESET% QoS (Psched) perf...
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v TimerResolution /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v MaxOutstandingSends /t REG_DWORD /d 8 /f >nul 2>&1

:: 5.12 — Configuration RSS
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration RSS...
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v RssBaseCpu /t REG_DWORD /d 1 /f >nul 2>&1

:: 5.13 — Désactiver les composants réseau non essentiels
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des composants reseau non essentiels...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | ? Status -eq 'Up' | % { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lldp' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lltdio' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_implat' -ErrorAction SilentlyContinue; Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_rspndr' -ErrorAction SilentlyContinue }" >nul 2>&1

:: 5.14 — WeakHost Send/Receive
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration WeakHost...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetAdapter | ? Status -eq 'Up' | Get-NetIPInterface | Set-NetIPInterface -WeakHostSend Enabled -WeakHostReceive Enabled -ErrorAction SilentlyContinue" >nul 2>&1

:: 5.15 — TCP PowerShell (désactive ForceWS)
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration TCP PowerShell...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-NetTCPSetting | Set-NetTCPSetting -ForceWS Disabled -ErrorAction SilentlyContinue" >nul 2>&1

:: 5.16 — Sécurité TCP (désactive profils/MPP)
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration securite TCP...
netsh int tcp set security mpp=disabled >nul 2>&1
netsh int tcp set security profiles=disabled >nul 2>&1

:: 5.17 — Redémarrage DNS
echo %COLOR_GREEN%[+]%COLOR_RESET% Redemarrage du service DNS Client...
net stop "DNS Client" >nul 2>&1
net start "DNS Client" >nul 2>&1

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
echo %STYLE_BOLD%%COLOR_WHITE%                    SECTION 6: OPTIMISATIONS CLAVIER ET SOURIS%COLOR_RESET%
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Application des optimisations peripheriques...

:: 6.1 - OPTIMISATIONS SOURIS AVANCEES
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration souris avancee...

:: Parametres de base souris (Raw Input et precision maximale)
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold1 /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseThreshold2 /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseAccel /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v RawInput /t reg_SZ /d "1" /f >nul 2>&1

:: Comportement souris optimise
reg add "HKCU\Control Panel\Mouse" /v MouseHoverTime /t reg_SZ /d "400" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseTrails /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v MouseDelay /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v DoubleClickSpeed /t reg_SZ /d "400" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v SwapMouseButtons /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v SnapToDefaultButton /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v ActiveWindowTracking /t reg_DWORD /d 0 /f >nul 2>&1

:: Desactiver sons et animations souris
reg add "HKCU\Control Panel\Mouse" /v Beep /t reg_SZ /d "No" /f >nul 2>&1
reg add "HKCU\Control Panel\Mouse" /v ExtendedSounds /t reg_SZ /d "No" /f >nul 2>&1

:: 6.2 - OPTIMISATIONS CLAVIER AVANCEES
echo %COLOR_GREEN%[+]%COLOR_RESET% Configuration clavier avancee...

:: Parametres de base clavier (vitesse maximale)
reg add "HKCU\Control Panel\Keyboard" /v KeyboardDelay /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v KeyboardSpeed /t reg_SZ /d "31" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v InitialKeyboardIndicators /t reg_SZ /d "0" /f >nul 2>&1

:: Optimisations accessibilite clavier
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v Flags /t reg_SZ /d "27" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v DelayBeforeAcceptance /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v BounceTime /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Last BounceKey Setting" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Last Valid Delay" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Last Valid Repeat" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v "Last Valid Wait" /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v KeyboardDelay /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v AutoRepeatDelay /t reg_SZ /d "200" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\Keyboard Response" /v AutoRepeatRate /t reg_SZ /d "2" /f >nul 2>&1

:: Desactiver touches collantes et autres fonctionnalites
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v Flags /t reg_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v Flags /t reg_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v Flags /t reg_SZ /d "2" /f >nul 2>&1

:: 6.3 - OPTIMISATIONS SYSTEME INPUT AVANCEES
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation systeme input avancee...

:: Buffer evenements et priorites threads
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v MouseDataQueueSize /t reg_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v ThreadPriority /t reg_DWORD /d 31 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v KeyboardDataQueueSize /t reg_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v ThreadPriority /t reg_DWORD /d 31 /f >nul 2>&1

:: Optimisation curseur (si disponible sur le systeme)
reg add "HKLM\SOFTWARE\Microsoft\Input\Settings\ControllerProcessor\CursorSpeed" /v CursorSensitivity /t reg_DWORD /d 2710 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Input\Settings\ControllerProcessor\CursorSpeed" /v CursorUpdateInterval /t reg_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Input\Settings\ControllerProcessor\CursorSpeed" /v IRRemoteNavigationDelta /t reg_DWORD /d 1 /f >nul 2>&1

:: 6.4 - DESACTIVATION FONCTIONNALITES AVANCEES
echo %COLOR_GREEN%[+]%COLOR_RESET% Desactivation fonctionnalites superflues...

:: Desactiver insights de frappe et fonctionnalites tactiles
reg add "HKCU\Software\Microsoft\Input\Settings" /v InsightsEnabled /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Wisp\Touch" /v TouchGate /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\TabletTip\1.7" /v EnableAutocorrection /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\TabletTip\1.7" /v EnableSpellchecking /t reg_DWORD /d 0 /f >nul 2>&1

:: Desactiver sons systeme
reg add "HKCU\Control Panel\Sound" /v Beep /t reg_SZ /d "no" /f >nul 2>&1
reg add "HKCU\Control Panel\Sound" /v ExtendedSounds /t reg_SZ /d "no" /f >nul 2>&1

:: Desactiver animations inutiles
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t reg_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t reg_DWORD /d 0 /f >nul 2>&1

:: Optimisations focus et fenêtres
reg add "HKCU\Control Panel\Desktop" /v ForegroundLockTimeout /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ForegroundFlashCount /t reg_DWORD /d 1 /f >nul 2>&1

echo.
echo %COLOR_CYAN%===============================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations peripheriques appliquees avec succes.
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
bcdedit /set disabledynamictick yes >nul 2>&1

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
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /t reg_DWORD /d 0 /f >nul 2>&1
reg add "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Reliability" /v TimeStampInterval /t reg_DWORD /d 0 /f >nul 2>&1

:: Desactivation economies d'energie SSD/SD
for %%d in (SD SSD) do (
    for %%s in (1 2 3) do (
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdleExitEnergyMicroJoules /t reg_DWORD /d 0 /f >nul 2>&1
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdleExitLatencyMs /t reg_DWORD /d 0 /f >nul 2>&1
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdlePowerMw /t reg_DWORD /d 0 /f >nul 2>&1
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Power\EnergyEstimation\Storage\%%d\IdleState\%%s" /v IdleTimeLengthMs /t reg_DWORD /d 4294967295 /f >nul 2>&1
    )
)

:: Desactivation HIPM et DIMP
for %%i in (EnableHIPM EnableDIPM EnableHDDParking) do (
    for /f "tokens=*" %%a in ('reg QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services" /s /f "%%i" 2^>nul ^| findstr "HKEY" 2^>nul') do (
        reg add "%%a" /v %%i /t reg_DWORD /d 0 /f >nul 2>&1
    )
)

:: Configuration specifique iaStorA
for %%c in (0 1) do (
    for %%t in (HIPM DIPM) do (
        reg add "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\iaStorA\Parameters\Device" /v Controller0Phy%%c%%t /t reg_DWORD /d 0 /f >nul 2>&1
    )
)

:: 8.8 - Optimisations avancees des services
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisations avancees des services...
:: Desactivation IoLatencyCap
for /f "tokens=*" %%a in ('reg QUERY "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services" /S /F "IoLatencyCap" 2^>nul ^| FINDSTR /V "IoLatencyCap" 2^>nul') do (
    reg add "%%a" /v IoLatencyCap /t reg_DWORD /d 0 /f >nul 2>&1
)

:: Desactivation StorPort idle
for /f "tokens=*" %%a in ('reg QUERY "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Enum" /S /F "StorPort" 2^>nul ^| FINDSTR /E "StorPort" 2^>nul') do (
    reg add "%%a" /v EnableIdlePowerManagement /t reg_DWORD /d 0 /f >nul 2>&1
)

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

:: 8.11 - Gerer les economies d'energie des cartes reseau
echo %COLOR_GREEN%[+]%COLOR_RESET% Optimisation des cartes reseau...
for /f %%a in ('reg query "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /v "*SpeedDuplex" /s 2^>nul ^| findstr  "HKEY"') do (
    echo   %COLOR_GREEN%[+]%COLOR_RESET% Configuration de l'adaptateur
    echo     %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des fonctionnalites d'economie d'energie...
    reg.exe add "%%a" /v "*DeviceSleepOnDisconnect" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "*EEE" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "*ModernStandbyWoLMagicPacket" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "*SelectiveSuspend" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "*WakeOnMagicPacket" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "*WakeOnPattern" /t reg_SZ /d "0" /f >nul 2>&1
    echo     %COLOR_GREEN%[+]%COLOR_RESET% Configuration des parametres de performance...
    reg.exe add "%%a" /v "AutoPowerSaveModeEnabled" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "EEELinkAdvertisement" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "EeePhyEnable" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "EnableGreenEthernet" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "EnableModernStandby" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "GigaLite" /t reg_SZ /d "0" /f >nul 2>&1
    echo     %COLOR_GREEN%[+]%COLOR_RESET% Configuration PnP et gestion d'alimentation...
    reg.exe add "%%a" /v "PnPCapabilities" /t reg_DWORD /d "24" /f >nul 2>&1
    reg.exe add "%%a" /v "PowerDownPll" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "PowerSavingMode" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "ReduceSpeedOnPowerDown" /t reg_SZ /d "0" /f >nul 2>&1
    echo     %COLOR_GREEN%[+]%COLOR_RESET% Desactivation des fonctions de reveil...
    reg.exe add "%%a" /v "S5WakeOnLan" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "SavePowerNowEnabled" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "ULPMode" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "WakeOnLink" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "WakeOnSlot" /t reg_SZ /d "0" /f >nul 2>&1
    reg.exe add "%%a" /v "WakeUpModeCap" /t reg_SZ /d "0" /f >nul 2>&1
    echo     %COLOR_GREEN%[+]%COLOR_RESET% Configuration terminee pour cet adaptateur
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
takeown /f "C:\Program Files\Windows Defender" /r /d y >nul 2>&1
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
takeown /f "C:\Program Files\Windows Defender\MsMpEng.exe" >nul 2>&1
icacls "C:\Program Files\Windows Defender\MsMpEng.exe" /deny Everyone:F >nul 2>&1
takeown /f "C:\Program Files\Windows Defender\MpSvc.dll" >nul 2>&1
icacls "C:\Program Files\Windows Defender\MpSvc.dll" /deny Everyone:F >nul 2>&1

:: Renommage/suppression des fichiers executables critiques
echo %COLOR_YELLOW%[*]%COLOR_RESET% Neutralisation des executables Defender...
ren "C:\Program Files\Windows Defender\MsMpEng.exe" "MsMpEng.exe.bak" >nul 2>&1
ren "C:\Program Files\Windows Defender\MpSvc.dll" "MpSvc.dll.bak" >nul 2>&1
ren "C:\Program Files\Windows Defender\MpCmdRun.exe" "MpCmdRun.exe.bak" >nul 2>&1
attrib +h "C:\Program Files\Windows Defender\*.bak" >nul 2>&1

:: Arrêt force des processus lies a Defender
echo %COLOR_YELLOW%[*]%COLOR_RESET% Arret force des processus Windows Defender...
taskkill /f /im MsMpEng.exe >nul 2>&1
taskkill /f /im NisSrv.exe >nul 2>&1
taskkill /f /im SecurityHealthSystray.exe >nul 2>&1
taskkill /f /im SecurityHealthService.exe >nul 2>&1
taskkill /f /im "Antimalware Service Executable" >nul 2>&1
taskkill /f /im MpCmdRun.exe >nul 2>&1
taskkill /f /im MpSigStub.exe >nul 2>&1

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
    taskkill /f /im MsMpEng.exe >nul 2>&1
    wmic process where "name='MsMpEng.exe'" delete >nul 2>&1
) else (
    echo %COLOR_GREEN%[+]%COLOR_RESET% Processus MsMpEng.exe confirme comme arrete.
)

:: Verification du service Antimalware
tasklist | findstr /I "Antimalware Service Executable" >nul
if not errorlevel 1 (
    echo %COLOR_RED%[!]%COLOR_RESET% Service Antimalware encore actif - arret force...
    taskkill /f /im "Antimalware Service Executable" >nul 2>&1
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
taskkill /f /im explorer.exe >nul 2>&1
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
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
reg delete "HKEY_LOCAL_MACHINE\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des taches planifiees OneDrive...
for /f "tokens=1 delims=," %%x in ('schtasks /query /fo csv 2^>nul ^| find "OneDrive"') do (
    schtasks /delete /TN %%x /F >nul 2>&1
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
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression de l'icone Edge de la barre des taches...

:: Suppression ciblee des raccourcis Edge uniquement
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q >nul 2>&1

:: Parcourir le dossier TaskBar et supprimer uniquement les raccourcis Edge
if exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" (
    for %%f in ("%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk") do (
        findstr /i "edge" "%%f" >nul 2>&1 && del "%%f" /f /q >nul 2>&1
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

echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des entrees du menu demarrer...
rd "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
rd "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache d'icones Edge...
:: Suppression du cache d'icones Windows (IconCache.db)
del "%LOCALAPPDATA%\IconCache.db" /f /q >nul 2>&1
del "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" /f /q >nul 2>&1

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
del /s /q /f "%temp%\*.*" >nul 2>&1
del /s /q /f "C:\Windows\Temp\*.*" >nul 2>&1
del /s /q /f "C:\Windows\Prefetch\*.*" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Fichiers temporaires supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache Windows Update...
net stop wuauserv /y >nul 2>&1
timeout /t 2 /nobreak >nul
del /s /q /f "C:\Windows\SoftwareDistribution\Download\*.*" >nul 2>&1
net start wuauserv >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Cache Windows Update nettoye

echo.
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%PHASE 2: NETTOYAGE SYSTEME ET COMPOSANTS%COLOR_RESET%
echo %COLOR_CYAN%-------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% Suppression des journaux systeme...
del /s /q /f "C:\Windows\Logs\*.log" >nul 2>&1
del /s /q /f "C:\Windows\System32\LogFiles\*.log" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Journaux systeme supprimes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage des journaux CBS (Windows Update)...
del /s /q /f "C:\Windows\Logs\CBS\*.*" >nul 2>&1
echo %COLOR_GREEN%[+]%COLOR_RESET% Journaux CBS nettoyes

echo %COLOR_YELLOW%[*]%COLOR_RESET% Nettoyage du cache de polices...
del /s /q /f "C:\Windows\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /s /q /f "C:\Windows\System32\FNTCACHE.DAT" >nul 2>&1
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



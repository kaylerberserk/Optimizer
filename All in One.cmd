@echo off
cls
:: IMPORTANT : textes SANS ACCENTS (ASCII) pour affichage fiable en console cmd.exe
:: Ne pas utiliser chcp 65001 (UTF-8 casse l'affichage des .cmd sous Windows)
setlocal EnableDelayedExpansion

:: Activer les sequences d'echappement ANSI pour les couleurs
reg add HKCU\Console /v VirtualTerminalLevel /t REG_DWORD /d 1 /f >nul 2>&1

:: Definir le titre de la console
title Script d'Optimisation Windows - All in One

:: Verifier PowerShell
where powershell >nul 2>&1 || (echo [ERREUR] PowerShell est introuvable. Le script ne peut pas continuer. && pause && exit /B 1)

:: Definition du caractere ESC (ASCII 27)
for /f "delims=" %%a in ('powershell -NoProfile -Command "$([char]27)"') do set "ESC=%%a"

:: Si powershell echoue, on utilise une alternative plus robuste
if not defined ESC (
    :: Methode alternative via CMD (escape sequence)
    for /f %%a in ('"prompt $E ^& echo on & for %%b in (1) do rem"') do set "ESC=%%a"
)

:: Fallback ultime : utiliser une variable vide si tout echoue (les couleurs ne s'afficheront pas mais le script fonctionnera)
if not defined ESC set "ESC="

:: Couleurs et Styles
set "COLOR_GREEN=%ESC%[32m" & set "COLOR_YELLOW=%ESC%[33m" & set "COLOR_RED=%ESC%[31m"
set "COLOR_CYAN=%ESC%[36m"  & set "COLOR_WHITE=%ESC%[37m"  & set "COLOR_BLUE=%ESC%[34m"
set "COLOR_MAGENTA=%ESC%[35m" & set "COLOR_RESET=%ESC%[0m" & set "STYLE_BOLD=%ESC%[1m"

:: ===========================================================================
:: INITIALISATION DES VARIABLES GLOBALES
:: ===========================================================================
set "HAS_INTERNET=0"
:: IS_LAPTOP est conserve pour compatibilite interne :
::   0 = profil LATENCE (reactivite max, tweaks agressifs)
::   1 = profil EQUILIBRE (recommande pour tous, surtout laptop, debit/stabilite/autonomie)
:: DETECTED_LAPTOP garde le type materiel reel detecte au demarrage.
set "IS_LAPTOP=0"
set "DETECTED_LAPTOP=0"
set "HAS_NVIDIA=0"
set "DESACTIVER_SECURITE=0"
set "DESACTIVER_DEFENDER=0"
set "DESACTIVER_ANIMATIONS=0"
set "DESACTIVER_IA=0"
set "DESACTIVER_UAC=0"
set "SKIP_PAUSE=0"
:: SKIP_PAUSE=0 : menus normaux (confirmations + pause entre sections)
:: SKIP_PAUSE=1 : mode Tout optimiser - enchaine sans re-demander (reponses deja prises)

:: Variables Hardware
set "HW_OS=Detection..."
set "HW_CPU=Detection..."
set "HW_GPU=Detection..."
set "HW_RAM=Detection..."

:: GUID powercfg - utilises en hardcode pour simplifier le code
:: 54533251-82be-4824-96c1-47b60b740d00 = SUB_PROCESSOR
:: 381b4222-f694-41f0-9685-ff5bb260df2e = Plan d'alimentation Equilibre Windows
:: (SUB_ENERGYSAVER de830923-a562-41af-a086-e3a2c6bad2da n'existe plus dans Windows 10/11 moderne)
:: 0cc5b647-c1df-4637-891a-dec35c318584 = Core Parking (P-cores class 1)
:: 0cc5b647-c1df-4637-891a-dec35c318583 = Core Parking (E-cores class 0)
:: 93b8b6dc-0698-4d1c-9ee4-0644e900c85d = Heterogeneous thread scheduling

:: ===========================================================================
:: CONVENTION DES INDICATEURS ET COULEURS
:: ===========================================================================
:: [*]         JAUNE = Action en cours d'execution
:: [OK]        VERT  = Action terminee avec succes
:: [TERMINE]   VERT  = Section completee
:: [INFO]      JAUNE = Information / Conseil
:: [SKIP]      CYAN  = Action ignoree volontairement / non applicable
:: [^!]        JAUNE = Avertissement (attention requise)
:: [-]         ROUGE = Suppression / Action negative
:: [ERREUR]    ROUGE = Erreur critique / Echec
:: [ATTENTION] ROUGE = Risque de securite
:: ===========================================================================


:: CHARGEMENT DU SCRIPT
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%             INITIALISATION DU SCRIPT D'OPTIMISATION              %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

set /a "LOAD_TOTAL=5"
set /a "LOAD_STEP=0"

:: Etape 1 : Privileges
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification des privileges administrateur"
:: Verification robuste des privileges admin (net session + verification UAC)
net session >nul 2>&1
if %errorlevel% NEQ 0 (
    echo.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Ce script necessite des privileges administrateur.%COLOR_RESET%
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Clic droit sur le script -^> Executer en tant qu'administrateur%COLOR_RESET%
    pause
    exit /B 1
)
:: Verification supplementaire : verifier que le processus est vraiment eleve (UAC)
powershell -NoProfile -Command "if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 1 }" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Le script n'est pas execute avec une elevation suffisante.%COLOR_RESET%
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Verifiez que l'UAC est active et reexecutez en tant qu'administrateur.%COLOR_RESET%
    pause
    exit /B 1
)

:: Etape 2 : PowerShell (deja verifie au lancement)
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification de PowerShell"

:: Etape 3 : Internet
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification de la connexion Internet"
call :REFRESH_INTERNET_STATUS

:: Etape 4 : Materiel Core
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Analyse des composants systeme"
call :DETECT_HARDWARE

:: Etape 5 : Finalisation
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Preparation de l'interface"
timeout /t 1 /nobreak >nul
set "LOAD_STEP="
set "LOAD_TOTAL="

goto :MENU_PRINCIPAL

:PROGRESS_BAR
setlocal EnableDelayedExpansion
set "PCURRENT=%~1"
set "PTOTAL=%~2"
set "PDESC=%~3"

set /a "PCALC=0"
set /a "PFILL=0"
if not "%PTOTAL%"=="" if not "%PTOTAL%"=="0" (
    set /a "PCALC=%PCURRENT%*100/%PTOTAL%" 2>nul
)
set /a "PFILL=PCALC*20/100" 2>nul

if !PFILL! GTR 20 set PFILL=20
if !PFILL! LSS 0 set PFILL=0

set "PBAR="
for /l %%i in (1,1,20) do (
    if %%i LEQ !PFILL! set "PBAR=!PBAR!#"
    if %%i GTR !PFILL! set "PBAR=!PBAR!."
)

<nul set /p ="!ESC![2K!ESC![1G!COLOR_CYAN![!PBAR!] !COLOR_YELLOW!!PCALC!%% !COLOR_CYAN!!PCURRENT!/!PTOTAL! !COLOR_WHITE!!PDESC!!COLOR_RESET!"
endlocal
exit /b



:DETECT_HARDWARE
:: Parametre optionnel : 1 = conserver IS_LAPTOP deja choisi par l'utilisateur
set "HW_OS=Windows" & set "HW_CPU=Inconnu" & set "HW_GPU=Inconnu" & set "HW_RAM=?" & set "HAS_NVIDIA=0"
if not "%~1"=="1" (
    set "IS_LAPTOP=0"
    set "DETECTED_LAPTOP=0"
)
:: Detection materiel en une seule commande pour eviter les scripts temporaires fragiles en CMD.
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor; $v=Get-CimInstance Win32_VideoController; $m=Get-CimInstance Win32_PhysicalMemory; if(-not $m){$m=Get-CimInstance Win32_ComputerSystem}; $b=0; $lc=8,9,10,11,14,30,31,32; $enc=Get-CimInstance Win32_SystemEnclosure -EA SilentlyContinue; if($enc -and $enc.ChassisTypes){foreach($t in $enc.ChassisTypes){if($lc -contains $t){$b=1;break}}}; if(-not $b -and (Get-CimInstance Win32_Battery -EA SilentlyContinue)){$b=1}; $res=@(); $cap=$o.Caption; if(-not $cap){$pn=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName; if($pn){$cap=$pn}else{$cap='Windows'}}; $res+='OS:'+$cap+' ('+$o.Version+')'; if($c){$res+='CPU:'+$c.Name.Trim()}; if($v){$gn=@($v|Where-Object{$_.Name -and $_.Name -notmatch 'Parsec|Virtual Display|Microsoft Basic|Remote|Indirect|Mirror'}|ForEach-Object{$_.Name.Trim()}|Select-Object -Unique); if(-not $gn.Count){$gn=@($v|ForEach-Object{$_.Name.Trim()})}; $res+='GPU:'+($gn -join ' / ')}; if($m.Capacity){$t=($m|Measure-Object Capacity -Sum).Sum; $res+='RAM:'+[math]::Round($t/1GB,0)}elseif($m.TotalPhysicalMemory){$res+='RAM:'+[math]::Round($m.TotalPhysicalMemory/1GB,0)}; $res+='LAPTOP:'+$b; [System.IO.File]::WriteAllLines((Join-Path $env:TEMP 'hw_info.tmp'), $res)" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo %COLOR_YELLOW%[WARN]%COLOR_RESET% %COLOR_WHITE%Erreur lors de la detection du materiel. Valeurs par defaut utilisees.%COLOR_RESET%
)
if exist "%TEMP%\hw_info.tmp" (
    for /f "usebackq tokens=1* delims=:" %%a in ("%TEMP%\hw_info.tmp") do (
        if /i "%%a"=="OS" set "HW_OS=%%b"
        if /i "%%a"=="CPU" set "HW_CPU=%%b"
        if /i "%%a"=="GPU" set "HW_GPU=%%b"
        if /i "%%a"=="RAM" set "HW_RAM=%%b"
        if /i "%%a"=="LAPTOP" if not "%~1"=="1" (
            set "IS_LAPTOP=%%b"
            set "DETECTED_LAPTOP=%%b"
        )
    )
    del "%TEMP%\hw_info.tmp" >nul 2>&1
)
echo !HW_GPU! | findstr /i "NVIDIA" >nul && set "HAS_NVIDIA=1"
if /i "%HW_OS%"=="Windows" for /f "tokens=2 delims=[]" %%i in ('ver') do set "HW_OS=%%i"
exit /b

:: ===========================================================================
:: UTILS
:: ===========================================================================


:REFRESH_INTERNET_STATUS
set "HAS_INTERNET=0"
ping -n 1 -w 1500 1.1.1.1 >nul 2>&1
if %errorlevel% EQU 0 (
    set "HAS_INTERNET=1"
    exit /b
)
:: Repli si ICMP est bloque (entreprise, pare-feu) : test HTTP leger (service Microsoft)
powershell -NoProfile -Command "try { $c=(Invoke-WebRequest -Uri \"https://www.msftconnecttest.com/connecttest.txt\" -UseBasicParsing -TimeoutSec 5).Content; if ($c -match \"Microsoft\") { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if %errorlevel% EQU 0 set "HAS_INTERNET=1"
exit /b

:: Confirmation O/N - %~1 = message, %~2 = EXITB (exit /b 1) ou label (:NOM) si Non
:ASK_CONFIRM
choice /C ON /N /M "%~1"
if !errorlevel! EQU 2 (
    if /i "%~2"=="EXITB" exit /b 1
    goto %~2
)
exit /b 0

:: %~1 = label RUN (mode auto ou apres Oui)  %~2 = message  %~3 = EXITB ou :label si Non
:ASK_IF_INTERACTIVE
if not "%SKIP_PAUSE%"=="0" goto %~1
call :ASK_CONFIRM "%~2" %~3
:: ASK_CONFIRM retourne errorlevel 0 pour Oui, 1 pour Non
if !errorlevel! EQU 1 (
    if /i "%~3"=="EXITB" exit /b 1
    goto %~3
)
goto %~1

:: %~1 = message  %~2 = label si Non  %~3 = variable flag (ex: DESACTIVER_SECURITE)
:COMMON_YES_NO
set "%~3=0"
choice /C ON /N /M "%~1"
if !errorlevel! EQU 1 set "%~3=1"
exit /b 0

:MENU_PRINCIPAL
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%Script d'Optimisation Windows - All in One%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Affichage des informations systeme
echo %STYLE_BOLD%%COLOR_WHITE% SYSTEME :%COLOR_RESET% %COLOR_CYAN%%HW_OS%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CPU     :%COLOR_RESET% %COLOR_CYAN%%HW_CPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GPU     :%COLOR_RESET% %COLOR_CYAN%%HW_GPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% RAM     :%COLOR_RESET% %COLOR_CYAN%%HW_RAM% Go%COLOR_RESET%
if "%DETECTED_LAPTOP%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE% TYPE    :%COLOR_RESET% %COLOR_CYAN%PC PORTABLE%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% TYPE    :%COLOR_RESET% %COLOR_CYAN%PC FIXE%COLOR_RESET%
)
if "%HAS_INTERNET%"=="1" (
    echo %STYLE_BOLD%%COLOR_WHITE% INTERNET:%COLOR_RESET% %COLOR_GREEN%Connecte%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% INTERNET:%COLOR_RESET% %COLOR_YELLOW%Hors ligne ou filtre ^(ICMP / HTTP^)%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS GENERALES ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Optimisations Systeme%COLOR_RESET%   %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Optimisations Memoire%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Optimisations Disques%COLOR_RESET%   %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Optimisations GPU%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Optimisations Reseau%COLOR_RESET%    %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_GREEN%Optimisations Clavier/Souris%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- REGLAGES AVANCES ---%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_RED%Gerer Economies d'Energie%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Gerer Protections Securite - Desactiver ou Restaurer%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS ALL IN ONE ---%COLOR_RESET%
echo %COLOR_YELLOW%[L]%COLOR_RESET% %COLOR_WHITE%Tout optimiser - Profil EQUILIBRE %COLOR_GREEN%- jeux, web, downloads, recommande pour tous%COLOR_RESET%
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_WHITE%Tout optimiser - Profil LATENCE %COLOR_RED%- competition, power user, deconseille portable%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS ---%COLOR_RESET%
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
choice /C 12345678LDNRGWTQ /N /M "%STYLE_BOLD%%COLOR_YELLOW%Veuillez choisir une option [1-8, L, D, N, R, G, W, T, Q]: %COLOR_RESET%"

:: Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 16 goto :END_SCRIPT
if !errorlevel! EQU 15 goto :OUTIL_CHRIS_TITUS
if !errorlevel! EQU 14 goto :OUTIL_ACTIVATION
if !errorlevel! EQU 13 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 12 goto :CREER_POINT_RESTAURATION
if !errorlevel! EQU 11 goto :NETTOYAGE_AVANCE_WINDOWS
if !errorlevel! EQU 10 goto :TOUT_OPTIMISER_LATENCE
if !errorlevel! EQU 9  goto :TOUT_OPTIMISER_EQUILIBRE
if !errorlevel! EQU 8  goto :TOGGLE_PROTECTIONS_SECURITE
if !errorlevel! EQU 7  goto :TOGGLE_ECONOMIES_ENERGIE
if !errorlevel! EQU 6  call :OPTIMISATIONS_PERIPHERIQUES & goto :MENU_PRINCIPAL
if !errorlevel! EQU 5  call :OPTIMISATIONS_RESEAU & goto :MENU_PRINCIPAL
if !errorlevel! EQU 4  call :OPTIMISATIONS_GPU & goto :MENU_PRINCIPAL
if !errorlevel! EQU 3  call :OPTIMISATIONS_DISQUES & goto :MENU_PRINCIPAL
if !errorlevel! EQU 2  call :OPTIMISATIONS_MEMOIRE & goto :MENU_PRINCIPAL
if !errorlevel! EQU 1  call :OPTIMISATIONS_SYSTEME & goto :MENU_PRINCIPAL
goto :MENU_PRINCIPAL

:MENU_GESTION_WINDOWS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES COMPOSANTS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Ce menu regroupe les options pour gerer les fonctionnalites%COLOR_RESET%
echo %COLOR_WHITE%et composants systeme (securite, interface, applications).%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- SECURITE ---%COLOR_RESET%
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Gerer Windows Defender%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Gerer UAC (Controle de Compte Utilisateur)%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_GREEN%Gerer VBS / HVCI (Isolation du noyau)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- INTERFACE ---%COLOR_RESET%
echo %COLOR_YELLOW%[4]%COLOR_RESET% %COLOR_GREEN%Gerer les Animations Windows%COLOR_RESET%
echo %COLOR_YELLOW%[5]%COLOR_RESET% %COLOR_GREEN%Gerer Copilot / Widgets / Recall (Windows 11)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- APPLICATIONS MICROSOFT ---%COLOR_RESET%
echo %COLOR_YELLOW%[6]%COLOR_RESET% %COLOR_RED%Desinstaller OneDrive Completement%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_RED%Desinstaller Edge Completement%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- RUNTIMES ET DEPENDANCES ---%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_GREEN%Installer Runtimes (Visual C++ + DirectX June 2010)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- APPLICATIONS ET NETTOYAGE ---%COLOR_RESET%
echo %COLOR_YELLOW%[9]%COLOR_RESET% %COLOR_RED%Supprimer les Bloatwares Windows (Apps inutiles)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 123456789M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-9, M]: %COLOR_RESET%"
:: Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 10 goto :MENU_PRINCIPAL
if !errorlevel! EQU 9  goto :SUPPRIMER_BLOATWARES
if !errorlevel! EQU 8  call :INSTALLER_VISUAL_REDIST & goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 7  goto :DESINSTALLER_EDGE
if !errorlevel! EQU 6  goto :DESINSTALLER_ONEDRIVE
if !errorlevel! EQU 5  goto :MENU_IA_WIDGETS_RECALL
if !errorlevel! EQU 4  goto :TOGGLE_ANIMATIONS
if !errorlevel! EQU 3  goto :TOGGLE_VBS_HVCI
if !errorlevel! EQU 2  goto :TOGGLE_UAC
if !errorlevel! EQU 1  goto :TOGGLE_DEFENDER
goto :MENU_GESTION_WINDOWS

:TOUT_OPTIMISER_LATENCE
if "!DETECTED_LAPTOP!"=="1" (
    cls
    echo %COLOR_RED%=================================================================================%COLOR_RESET%
    echo %STYLE_BOLD%%COLOR_RED%                    AVERTISSEMENT : PC PORTABLE DETECTE%COLOR_RESET%
    echo %COLOR_RED%=================================================================================%COLOR_RESET%
    echo.
    echo %COLOR_WHITE% Vous avez selectionne le %COLOR_YELLOW%Profil LATENCE%COLOR_WHITE% sur un %COLOR_CYAN%PC Portable%COLOR_WHITE%.%COLOR_RESET%
    echo.
    echo %COLOR_RED% [ERREUR] CE PROFIL EST ULTRA DECONSEILLE SUR UN PC PORTABLE :%COLOR_RESET%
    echo  - Risque eleve de %COLOR_YELLOW%surchauffe%COLOR_RESET% et de %COLOR_YELLOW%baisse d'autonomie dramatique%COLOR_RESET%.
    echo  - Desactive toutes les economies d'energie ^(CPU, PCIe, EEE, USB selective suspend^).
    echo  - Les ventilateurs tourneront beaucoup plus vite et la batterie s'usera rapidement.
    echo.
    echo %COLOR_GREEN% Le profil Equilibre [L] est lui aussi parfaitement optimise pour le jeu%COLOR_RESET%
    echo %COLOR_GREEN% ^(il conserve plus de 95%% des optimisations^). La seule difference%COLOR_RESET%
    echo %COLOR_GREEN% reelle est un infime input lag reseau/periph en echange d'un debit maximal.%COLOR_RESET%
    echo.
    echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
    choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous forcer le profil LATENCE malgre tout ? [O/N]: %COLOR_RESET%"
    if !errorlevel! EQU 2 (
        goto :TOUT_OPTIMISER_EQUILIBRE
    )
)
set "IS_LAPTOP=0"
goto :TOUT_OPTIMISER_COMMON

:TOUT_OPTIMISER_EQUILIBRE
set "IS_LAPTOP=1"
goto :TOUT_OPTIMISER_COMMON

:TOUT_OPTIMISER_COMMON
cls
set "DESACTIVER_SECURITE=0"
set "DESACTIVER_DEFENDER=0"
set "DESACTIVER_ANIMATIONS=0"
set "DESACTIVER_IA=0"
set "DESACTIVER_UAC=0"
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les protections de securite (Spectre/Meltdown) ?%COLOR_RESET%
echo %COLOR_WHITE%    (Note : VBS/HVCI/CFG seront maintenus actifs pour l'anti-cheat)%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : mitigations CPU/noyau contre fuites laterales ; desactiver%COLOR_RESET%
echo %COLOR_WHITE%peut reduire latence CPU mais augmente le risque sur machine multi-utilisateurs ou exposee.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Reduit la latence systeme et l'overhead CPU
echo       %COLOR_YELLOW%Expose le systeme a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les protections (recommande)
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces protections ? [O/N]: %COLOR_RESET%" :COMMON_SECURITE_NON DESACTIVER_SECURITE
:COMMON_SECURITE_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : sans antivirus integre, moins de charge disque/CPU mais%COLOR_RESET%
echo %COLOR_WHITE%aucune analyse temps reel des telechargements ; a combiner avec un autre AV si besoin.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en desactivant l'antivirus
echo       %COLOR_YELLOW%Expose le systeme aux virus et logiciels malveillants%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver Windows Defender (recommande)
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Windows Defender ? [O/N]: %COLOR_RESET%" :COMMON_DEFENDER_NON DESACTIVER_DEFENDER
:COMMON_DEFENDER_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les animations Windows ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : effets DWM, menus et demarrage ; utile sur PC limite,%COLOR_RESET%
echo %COLOR_WHITE%un peu plus brut visuellement ; reversible via le menu Activer les animations.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ameliore les performances en supprimant les animations
echo       %COLOR_YELLOW%L'interface sera moins fluide visuellement%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les animations (recommande)
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver les animations Windows ? [O/N]: %COLOR_RESET%" :COMMON_ANIMATIONS_NON DESACTIVER_ANIMATIONS
:COMMON_ANIMATIONS_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les fonctionnalites IA de Windows ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Copilot, widgets, Recall consomment CPU/reseau et%COLOR_RESET%
echo %COLOR_WHITE%envoient des donnees vers Microsoft ; couper tout ameliore confidentialite et perf.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Desactive Copilot, Recall, widgets et autres fonctionnalites IA
echo       %COLOR_YELLOW%Ameliore les performances et la confidentialite%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les fonctionnalites IA
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces fonctionnalites IA ? [O/N]: %COLOR_RESET%" :COMMON_IA_NON DESACTIVER_IA
:COMMON_IA_NON

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver le Controle de Compte Utilisateur (UAC) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : sans UAC, les programmes peuvent obtenir des droits admin%COLOR_RESET%
echo %COLOR_WHITE%sans votre accord explicite ; ce script coupe aussi des avertissements lies.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ne plus demander de confirmation (Oui/Non) pour les actions admin
echo       %COLOR_YELLOW%Reduit la securite en permettant aux applis de s'executer sans alerte%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver l'UAC (recommande)
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC ? [O/N]: %COLOR_RESET%" :COMMON_UAC_NON DESACTIVER_UAC
:COMMON_UAC_NON



cls
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Mode automatique : vos reponses ci-dessus s'appliquent sans nouvelle confirmation.%COLOR_RESET%
echo.
set "SKIP_PAUSE=1"
call :INSTALLER_VISUAL_REDIST
call :OPTIMISATIONS_SYSTEME
call :OPTIMISATIONS_MEMOIRE
call :OPTIMISATIONS_DISQUES
call :OPTIMISATIONS_GPU
call :OPTIMISATIONS_RESEAU
call :OPTIMISATIONS_PERIPHERIQUES
if "!IS_LAPTOP!"=="0" call :DESACTIVER_ECONOMIES_ENERGIE
if "%DESACTIVER_SECURITE%"=="1" call :DESACTIVER_PROTECTIONS_SECURITE
if "%DESACTIVER_DEFENDER%"=="1" call :DESACTIVER_DEFENDER_SECTION
if "%DESACTIVER_ANIMATIONS%"=="1" call :DESACTIVER_ANIMATIONS_SECTION
if "%DESACTIVER_IA%"=="1" call :DESACTIVER_TOUT_IA_WIDGETS_RECALL
if "%DESACTIVER_UAC%"=="1" call :DESACTIVER_UAC_SECTION
set "SKIP_PAUSE=0"
call :DETECT_HARDWARE 1
call :AFFICHER_RESUME_OPTIMISATION
set "DESACTIVER_SECURITE="
set "DESACTIVER_DEFENDER="
set "DESACTIVER_ANIMATIONS="
set "DESACTIVER_IA="
set "DESACTIVER_UAC="
goto :MENU_PRINCIPAL

:AFFICHER_RESUME_OPTIMISATION
cls
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    echo %STYLE_BOLD%%COLOR_WHITE% OPTIMISATION PROFIL LATENCE TERMINEE%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% OPTIMISATION PROFIL EQUILIBRE TERMINEE%COLOR_RESET%
)
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %STYLE_BOLD%%COLOR_BLUE%-- RESULTATS APPLIQUES ----------------------------------------------------------%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme, memoire, disques, GPU, reseau, peripheriques.%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan "Ultimate Performance" actif ^(economies d'energie coupees^).%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Efficience preservee ^(debit max, batterie/chauffe ok^).%COLOR_RESET%
)
echo.

set "HAS_OPT=0"
if "%DESACTIVER_SECURITE%"=="1" set "HAS_OPT=1"
if "%DESACTIVER_DEFENDER%"=="1" set "HAS_OPT=1"
if "%DESACTIVER_ANIMATIONS%"=="1" set "HAS_OPT=1"
if "%DESACTIVER_IA%"=="1" set "HAS_OPT=1"
if "%DESACTIVER_UAC%"=="1" set "HAS_OPT=1"
if "%HAS_OPT%"=="1" (
    echo %STYLE_BOLD%%COLOR_BLUE%-- OPTIONS COMPLEMENTAIRES ------------------------------------------------------%COLOR_RESET%
    if "%DESACTIVER_SECURITE%"=="1" (
        echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Protections de securite desactivees.%COLOR_RESET%
    )
    if "%DESACTIVER_DEFENDER%"=="1" (
        echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Windows Defender desactive ^(effet selon Tamper Protection^).%COLOR_RESET%
    )
    if "%DESACTIVER_UAC%"=="1" (
        echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%UAC ^(Controle de Compte Utilisateur^) desactive.%COLOR_RESET%
    )
    if "%DESACTIVER_ANIMATIONS%"=="1" (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Animations Windows desactivees.%COLOR_RESET%
    )
    if "%DESACTIVER_IA%"=="1" (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Fonctionnalites IA / Widgets / Recall desactivees.%COLOR_RESET%
    )
    echo.
)
set "HAS_OPT="

echo %STYLE_BOLD%%COLOR_BLUE%-- PROCHAINE ETAPE --------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer toutes les modifications.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous redemarrer votre PC maintenant ? [O/N]: %COLOR_RESET%"
if !errorlevel! EQU 2 exit /b
if !errorlevel! EQU 1 (
    shutdown /r /t 5 /c "Redemarrage pour appliquer les optimisations"
    cls
    echo.
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Redemarrage en cours...%COLOR_RESET%
    timeout /t 5 /nobreak >nul
    exit
)

:OPTIMISATIONS_SYSTEME
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 1 : OPTIMISATIONS SYSTEME%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Optimise le noyau Windows, desactive la telemetrie et configure%COLOR_RESET%
echo %COLOR_WHITE%  l'interface pour de meilleures performances generales.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%LATENCE%COLOR_RESET%%COLOR_WHITE% - reactivite maximale, sans economie d'energie%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%EQUILIBRE%COLOR_RESET%%COLOR_WHITE% - jeux, debit reseau max, efficience active%COLOR_RESET%
)
echo.

:: 1.1 - Priorites CPU et planification
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration des priorites CPU...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v IoPriority /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEngCP.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Planification CPU configuree%COLOR_RESET%

:: 1.2 - Gestion de la memoire (MMAgent)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la gestion memoire ^(Compression OFF^)...%COLOR_RESET%
powershell -NoProfile -Command "try { Disable-MMAgent -MemoryCompression -ErrorAction Stop } catch { Write-Warning 'MMAgent non supporte sur cette version' }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Compression de memoire desactivee ^(Charge CPU reduite^)%COLOR_RESET%

:: 1.3 - Profil Gaming MMCSS (taches jeux)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du profil gaming (MMCSS)...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil gaming (MMCSS) configure%COLOR_RESET%

:: 1.4 - Interface Windows
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de l'interface Windows...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontPrettyPath" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DesktopLivePreviewHoverTime" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ExtendedUIHoverTime" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SeparateProcess" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
:: ShowFrequent - Cache des fichiers recents (ne desactive PAS l'indexation Windows)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v DesktopProcess /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 1 /f >nul 2>&1

:: 1.5 - Telemetrie et vie privee
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie et des publicites...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1

:: Optimiser le cache d'icones et miniatures
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "Max Cached Icons" /t REG_SZ /d "8192" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >nul 2>&1

:: Desactiver la compression des papiers peints
reg add "HKCU\Control Panel\Desktop" /v JPEGImportQuality /t REG_DWORD /d 100 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Interface et privacy de base optimisees%COLOR_RESET%

:: 1.6 - Telemetrie systeme et vie privee approfondie
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie et des traceurs...%COLOR_RESET%
:: Registre : telemetrie et publicites
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "MaxTelemetryAllowed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "AllowSluggishnessTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v "DoNotShowFeedbackNotifications" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" /v "DisabledByGroupPolicy" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableWindowsConsumerFeatures" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableConsumerAccountStateContent" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableSoftLanding" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableTailoredExperiences" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "TailoredExperiencesWithDiagnosticDataEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Privacy" /v "ActivityHistoryEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v "NumberOfSIUFInPeriod" /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Siuf\Rules" /v PeriodInNanoSeconds /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Feedback" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchSuggestions" /t REG_DWORD /d 1 /f >nul 2>&1

:: Content Delivery Manager
for %%V in (ContentDeliveryAllowed FeatureManagementEnabled OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled RemediationRequired RotatingLockScreenEnabled RotatingLockScreenOverlayEnabled SilentInstalledAppsEnabled SoftLandingEnabled SubscribedContentEnabled SystemPaneSuggestionsEnabled SubscribedContent-310093Enabled SubscribedContent-314563Enabled SubscribedContent-338380Enabled SubscribedContent-338381Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled) do (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v %%V /t REG_DWORD /d 0 /f >nul 2>&1
)

:: Recherche Windows - Bing OFF
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

:: Wi-Fi Sense OFF
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting" /v "Value" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\Software\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots" /v "Value" /t REG_DWORD /d 0 /f >nul 2>&1

:: Activity History OFF
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Telemetrie et publicites desactivees%COLOR_RESET%

:: Taches planifiees de telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des taches planifiees de telemetrie...%COLOR_RESET%
for %%T in (
    "Microsoft\Windows\Application Experience\Microsoft Compatibility Appraiser"
    "Microsoft\Windows\Application Experience\ProgramDataUpdater"
    "Microsoft\Windows\Application Experience\AitAgent"
    "Microsoft\Windows\Autochk\Proxy"
    "Microsoft\Windows\Customer Experience Improvement Program\Consolidator"
    "Microsoft\Windows\Customer Experience Improvement Program\UsbCeip"
    "Microsoft\Windows\Customer Experience Improvement Program\Uploader"
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

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Taches de telemetrie desactivees%COLOR_RESET%

:: Blocage telemetrie via hosts 
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Gestion du blocage telemetrie dans le fichier hosts...%COLOR_RESET%
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
attrib -r "%HOSTS%" >nul 2>&1

:: Utilisation de PowerShell pour mettre a jour ou ajouter le bloc securise (Telemetrie uniquement)
powershell -NoProfile -Command "$h='%HOSTS%'; $s='# Telemetry Block Start'; $e='# Telemetry Block End'; $nb=\"# Telemetry Block Start`r`n# --- Telemetry Block ---`r`n0.0.0.0 vortex.data.microsoft.com`r`n0.0.0.0 vortex-win.data.microsoft.com`r`n0.0.0.0 v10.vortex-win.data.microsoft.com`r`n0.0.0.0 v10.events.data.microsoft.com`r`n0.0.0.0 telecommand.telemetry.microsoft.com`r`n0.0.0.0 oca.telemetry.microsoft.com`r`n0.0.0.0 watson.telemetry.microsoft.com`r`n0.0.0.0 watsonc.microsoft.com`r`n# --- End Telemetry Block ---`r`n# Telemetry Block End\"; if(Test-Path $h){ $c=Get-Content $h -Raw; if($c -match ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e))){ $c=$c -replace ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)), $nb } else { if($c.Trim().Length -gt 0){ $c=$c.TrimEnd()+\"`r`n`r`n\"+$nb } else { $c=$nb } } Set-Content -Path $h -Value $c -Encoding ASCII -Force }; if($?) { exit 0 } else { exit 1 }" >nul 2>&1

if %errorlevel% EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Domaines mis a jour ^(Telemetrie bloquee, doublons nettoyes^)%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de la mise a jour du fichier hosts%COLOR_RESET%
)
attrib +r "%HOSTS%" >nul 2>&1

:: Vidage du cache DNS pour appliquer immediatement les modifications du hosts
ipconfig /flushdns >nul 2>&1
set "HOSTS="

:: 1.7 - Services optimises
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation services%COLOR_RESET%

:: 1 - Services vitaux -> AUTOMATIQUE
for %%S in (
    W32Time
    WpnService
    SysMain
    defragsvc
) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
)
:: Configuration du service par utilisateur WpnUserService
reg add "HKLM\SYSTEM\CurrentControlSet\Services\WpnUserService" /v Start /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services vitaux et synchronisation en Automatique%COLOR_RESET%

:: 2 - Services occasionnels et utiles -> MANUEL (demand)
for %%S in (
    ALG
    AppVClient
    BDESVC
    CertPropSvc
    GraphicsPerfSvc
    icssvc
    IKEEXT
    MapsBroker
    MSDTC
    MSiSCSI
    NaturalAuthentication
    NcaSvc
    NcbService
    camsvc
    NgcSvc
    NgcCtnrSvc
    PeerDistSvc
    PhoneSvc
    PNRPAutoReg
    PNRPsvc
    RpcLocator
    SCardSvr
    ScDeviceEnum
    SstpSvc
    stisvc
    TroubleshootingSvc
    tzautoupdate
    WFDSConMgrSvc
    WiaRpc
    dmwappushservice
    WerSvc
    SystemSuggestions
    uhssvc
) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
)
:: CDPUserSvc est un service par utilisateur
reg add "HKLM\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services utiles et occasionnels en mode Manuel%COLOR_RESET%

:: 3 - Services inutiles et telemetrie -> DESACTIVES
for %%S in (
    AJRouter
    AxInstSV
    CscService
    DiagTrack
    diagnosticshub.standardcollector.service
    DialogBlockingService
    Fax
    lfsvc
    lltdsvc
    NetTcpPortSharing
    RemoteAccess
    RemoteRegistry
    RetailDemo
    SEMgrSvc
    shpamsvc
    ssh-agent
    UevAgentService
    WalletService
    WMPNetworkSvc
) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services telemetrie et legacy desactives%COLOR_RESET%

:: Services critiques laisses intacts : Bluetooth, Hello, RDP, Spooler, PlugPlay
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services optimises (Bluetooth/VPN/Hello/RDP preserves)%COLOR_RESET%

:: 1.8 - Optimisations demarrage et systeme
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme diverses...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f >nul 2>&1
bcdedit /set bootuxdisabled on >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "04" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "08" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "32" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "2048" /t REG_DWORD /d 7 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisations demarrage et stockage terminees%COLOR_RESET%

:: 1.9 - Utilitaires et Bloatwares (Automatique)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Ajout de "Devenir Proprietaire" au menu contextuel...%COLOR_RESET%
reg add "HKCR\*\shell\runas" /ve /t REG_SZ /d "Devenir Proprietaire" /f >nul 2>&1
reg add "HKCR\*\shell\runas" /v "NoWorkingDirectory" /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\*\shell\runas\command" /ve /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" && icacls \"%%1\" /grant administrators:F" /f >nul 2>&1
reg add "HKCR\*\shell\runas" /v "IsolatedCommand" /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" && icacls \"%%1\" /grant administrators:F" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas" /ve /t REG_SZ /d "Devenir Proprietaire" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas" /v "NoWorkingDirectory" /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas\command" /ve /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" /r /d y && icacls \"%%1\" /grant administrators:F /t" /f >nul 2>&1
reg add "HKCR\Directory\shell\runas" /v "IsolatedCommand" /t REG_SZ /d "cmd.exe /c takeown /f \"%%1\" /r /d y && icacls \"%%1\" /grant administrators:F /t" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%"Devenir Proprietaire" ajoute au menu contextuel.%COLOR_RESET%

:: Desactivation des Co-installateurs tiers (Razer/Logitech Popup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des Co-installateurs et recherche pilotes auto...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v DisableCoInstallers /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Popups Razer/Logitech bloques%COLOR_RESET%

:: Privacy Supplementaire
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des tweaks privacy supplementaires...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowDeviceNameInTelemetry /t REG_DWORD /d 0 /f >nul 2>&1

:: Privacy avancee
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Privacy avancee...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DisableDeviceDiagnosticData /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v UploadPermission /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Handwriting" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v PreventHandwritingDataSharing /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PerfTrack" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\PerfTrack" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Privacy avancee appliquee%COLOR_RESET%

:: Pare-feu telemetrie
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation pare-feu telemetrie...%COLOR_RESET%
netsh advfirewall firewall add rule name="Block MS Telemetry Out" dir=out action=block remoteip=20.42.65.0/24,51.104.0.0/16,52.108.0.0/16,104.43.0.0/16,13.107.0.0/16 protocol=any >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Pare-feu telemetrie actif (Update + Store preserves)%COLOR_RESET%

:: Batterie - Energy Saver (seuil 100%% active l'economiseur en permanence)
:: powercfg /setdcvalueindex SCHEME_CURRENT SUB_ENERGYSAVER ESBATTTHRESHOLD 100 >nul 2>&1

:: 1.10 - Navigateurs
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation navigateurs...%COLOR_RESET%
:: Microsoft Edge
reg add "HKLM\Software\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v StartupBoostEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsMode /t REG_SZ /d secure /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v UserFeedbackAllowed /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v EdgeCollectionsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NetworkPredictionOptions /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v NewTabPagePrerenderEnabled /t REG_DWORD /d 1 /f >nul 2>&1

:: Google Chrome
reg add "HKCU\Software\Policies\Google\Chrome" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsMode /t REG_SZ /d secure /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Navigateurs optimises%COLOR_RESET%

:: 1.11 - Desactivation du stockage reserve
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du stockage reserve Windows...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v ShippedWithReserves /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v PassedPolicy /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "try { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Stockage reserve desactive ^(~7Go recuperes apres redemarrage^)%COLOR_RESET%

:: 1.12 - Affichage du code erreur BSoD
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de l'affichage des codes erreur BSoD...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v DisplayParameters /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Codes erreur BSoD visibles (diagnostic facilite)%COLOR_RESET%

:: 1.13 - Desactivation de l'aide F1
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la touche F1 (aide Windows)...%COLOR_RESET%
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Touche F1 (aide) desactivee%COLOR_RESET%

:: 1.14 - Desactivation audio enhancements (latence audio)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des ameliorations audio...%COLOR_RESET%
powershell -NoProfile -Command "$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}'; Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p = $_.PSPath; Set-ItemProperty -Path $p -Name 'FxNonDestructiveSoftMixer' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'FxRender' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'DisableAudioEndpointDucking' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } " >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisation des peripheriques de rendu audio (PowerShell)%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Audio" /v DisableAudioEnhancement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v ImmersiveAudio /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Ameliorations audio desactivees - Latence reduite%COLOR_RESET%

:: 1.15 - Desactivation Windows Platform Binary Table (WPBT)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation WPBT (anti bloatware OEM firmware)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%WPBT desactive%COLOR_RESET%

:: 1.16 - Intel Thread Director : deverrouillage des options UI (sans danger, applicable a tous)
:: Permet l'affichage des options Heterogeneous Scheduling et Core Parking dans powercfg.cpl.
:: La configuration effective (Prefer Performant) est appliquee en section 7 pour le profil LATENCE.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Deverrouillage des options Intel Thread Director (Heterogeneous Scheduling, Core Parking)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Options Thread Director / Core Parking visibles dans powercfg.cpl%COLOR_RESET%

call :FINISH_ACTION "Optimisations systeme" "appliquees"
exit /b

:OPTIMISATIONS_MEMOIRE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 2 : OPTIMISATIONS MEMOIRE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la gestion de la RAM et du fichier d'echange%COLOR_RESET%
echo %COLOR_WHITE%  pour ameliorer les performances en jeu et reduire la latence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%LATENCE%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%EQUILIBRE%COLOR_RESET%
)
echo.

:: 2.1 - Memory Management
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la gestion memoire...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagefileEncryption" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "SystemPages" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion memoire optimisee%COLOR_RESET%

:: 2.2 - Prefetch/SysMain
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du Prefetch et SuperFetch pour performance maximale...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t REG_DWORD /d 0 /f >nul 2>&1
:: Activer Superfetch et Prefetcher pour chargement ultra-rapide des applications
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Prefetch actif, SuperFetch optimise pour les jeux%COLOR_RESET%

:: 2.3 - FTH OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du tas tolerant aux pannes (FTH)...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\FTH\State" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%FTH desactive - Performances memoire ameliorees%COLOR_RESET%

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations memoire appliquees avec succes%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:OPTIMISATIONS_DISQUES
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 3 : OPTIMISATIONS DISQUES ET STOCKAGE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise les SSD/HDD pour des temps de chargement%COLOR_RESET%
echo %COLOR_WHITE%  reduits et une meilleure reactivite du systeme.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%LATENCE%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%EQUILIBRE%COLOR_RESET%
)
echo.

:: 3.1 - Configuration NTFS et TRIM
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration des parametres NTFS et activation du TRIM...%COLOR_RESET%
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set memoryusage 2 >nul 2>&1
fsutil behavior set mftzone 2 >nul 2>&1
fsutil behavior set disablecompression 1 >nul 2>&1
fsutil behavior set encryptpagingfile 0 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres NTFS optimises - TRIM actif, metadonnees reduites%COLOR_RESET%

:: 3.2 - Optimisations I/O NTFS
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation I/O NTFS (NVMe)...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des chemins longs (plus de 260 caracteres)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Support des chemins longs active%COLOR_RESET%

:: 3.3 - TRIM sur volumes SSD
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de l'etat du TRIM sur les disques SSD...%COLOR_RESET%
set "TRIM_STATUS="
for /f "delims=" %%a in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$stampDir=Join-Path $env:ProgramData 'OptimizerAllInOne'; $stampFile=Join-Path $stampDir 'last_retrim.txt'; $ssds=Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -ne 'HDD' -and $_.OperationalStatus -eq 'OK' -and $_.BusType -notin @('Virtual','FileBackedVirtual') }; if(-not $ssds -or $ssds.Count -eq 0){ 'NO_SSD'; exit 0 }; if((Test-Path $stampFile) -and ((Get-Date) - (Get-Item $stampFile).LastWriteTime).TotalDays -lt 30){ 'SKIP_RECENT'; exit 0 }; if(-not (Test-Path $stampDir)){ New-Item -ItemType Directory -Path $stampDir -Force | Out-Null }; $vols=Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and ($_.FileSystem -in @('NTFS','ReFS')) }; $done=$false; foreach($v in $vols){ $part=Get-Partition -DriveLetter $v.DriveLetter -ErrorAction SilentlyContinue; if($part){ $phys=Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $part.DiskNumber }; if($phys -and $phys.MediaType -ne 'HDD' -and $phys.BusType -notin @('Virtual','FileBackedVirtual')){ try { Optimize-Volume -DriveLetter $v.DriveLetter -ReTrim -ErrorAction Stop | Out-Null; $done=$true } catch {} } } }; if($done){ Set-Content -Path $stampFile -Value (Get-Date -Format s) -Force; 'TRIM_DONE' } else { 'NO_SSD' }"') do set "TRIM_STATUS=%%a"
if "%TRIM_STATUS%"=="TRIM_DONE" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%TRIM execute sur les volumes SSD ^(dernier passage memorise pour 30 jours^)%COLOR_RESET%
) else (
    if "%TRIM_STATUS%"=="SKIP_RECENT" (
        echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%TRIM ignore ^(deja execute il y a moins de 30 jours^)%COLOR_RESET%
    ) else (
        echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Aucun volume SSD detecte pour l'operation TRIM%COLOR_RESET%
    )
)
set "TRIM_STATUS="

:: 3.4 - Optimisation pilote NVMe et DirectStorage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du DirectStorage...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 156965516 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1853569164 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 735209102 /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectStorage actif%COLOR_RESET%

:: 3.5 - Write cache buffer flushing au niveau peripherique (SCSI + NVMe)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%CacheIsPowerProtected sur disques SCSI et NVMe (equiv. Write Cache Buffer Flushing Off)...%COLOR_RESET%
powershell -NoProfile -Command "Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Enum\SCSI', 'HKLM:\SYSTEM\CurrentControlSet\Enum\NVMe' -ErrorAction SilentlyContinue | Get-ChildItem -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' } | ForEach-Object { $p = Join-Path -Path $_.PSPath -ChildPath 'Disk'; if((Test-Path -Path $p) -eq $false){ New-Item -Path $p -Force | Out-Null }; Set-ItemProperty -Path $p -Name 'CacheIsPowerProtected' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Cle Device Parameters\Disk\CacheIsPowerProtected appliquee (SCSI + NVMe)%COLOR_RESET%

:: 3.6 - Defragmentation automatique geree par Windows (TRIM automatique)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de la defragmentation automatique...%COLOR_RESET%
:: Windows 11 detecte automatiquement les SSD et effectue du TRIM au lieu de defragmentation
:: Il est important de NE PAS desactiver cette tache pour maintenir le TRIM automatique
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Enable >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Defragmentation automatique preservee ^(TRIM automatique actif pour SSD^)%COLOR_RESET%

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations des disques appliquees avec succes%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:OPTIMISATIONS_GPU
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 4 : OPTIMISATIONS GPU%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise votre carte graphique pour reduire l'input lag%COLOR_RESET%
echo %COLOR_WHITE%  et maximiser les performances en jeu.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: Avertissement mode manuel sur PC portable : choix entre profil Equilibre et Latence.
if "%SKIP_PAUSE%"=="0" if "!DETECTED_LAPTOP!"=="1" (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%PC PORTABLE DETECTE - MODE MANUEL%COLOR_RESET%
    echo.
    echo %COLOR_WHITE%Vous etes sur un %COLOR_CYAN%PC Portable%COLOR_WHITE%. Les optimisations GPU peuvent impacter :%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Chauffe%COLOR_RESET% : Low-latency et VRR OFF augmentent la temperature GPU%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Batterie%COLOR_RESET% : NVIDIA Profile Manager reduit l'autonomie%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Veille%COLOR_RESET% : MaxFrameLatency desactive peut affecter la veille GPU%COLOR_RESET%
    echo.
    echo %COLOR_GREEN%[1]%COLOR_RESET% %COLOR_WHITE%Profil EQUILIBRE ^(recommande pour tous, surtout laptop^) - VRR ON, Low-latency OFF%COLOR_RESET%
    echo %COLOR_RED%[2]%COLOR_RESET% %COLOR_WHITE%Profil LATENCE ^(agressif^) - VRR OFF, Low-latency ON%COLOR_RESET%
    echo.
    choice /C 12 /N /M "%COLOR_YELLOW%Choisissez le profil [1=Equilibre, 2=Latence]: %COLOR_RESET%"
    if !errorlevel! EQU 2 (
        set "IS_LAPTOP=0"
        echo %COLOR_WHITE%Profil LATENCE force - Optimisations agressives actives%COLOR_RESET%
    ) else (
        set "IS_LAPTOP=1"
        echo %COLOR_WHITE%Profil EQUILIBRE conserve - Optimisations moderees actives%COLOR_RESET%
    )
    echo.
    echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
)

if "!IS_LAPTOP!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%LATENCE%COLOR_RESET%%COLOR_WHITE% - reactivite maximale, plan Ultimate Performance%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%EQUILIBRE%COLOR_RESET%%COLOR_WHITE% - HAGS, VRR et economies d'energie preservees%COLOR_RESET%
)
echo.

:: 4.1 - GameDVR desactive - Game Mode ON
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'enregistrement automatique de gameplay...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AppCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "AudioCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "CursorCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\GameDVR" /v "HistoricalCaptureEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v AutoGameModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v UseNexusForGameBarEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "AllowAutoGameMode" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\GameBar" /v "ShowStartupPanel" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_DXGIHonorFSEWindowsCompatible /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_EFSEFeatureFlags /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehavior /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_FSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\System\GameConfigStore" /v GameDVR_HonorUserFSEBehaviorMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\GameDVR" /v "AllowGameDVR" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%GameDVR desactive - Game Mode conserve pour les performances%COLOR_RESET%

:: 4.2 - Preferences DirectX (Auto HDR, VRR, Flip Model actif)
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des preferences DirectX ^(Auto HDR, VRR OFF, Flip Model^)...%COLOR_RESET%
    reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "AutoHDREnable=1;VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX : Auto HDR actif, VRR OFF, Flip Model actif ^(Profil LATENCE^)%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des preferences DirectX ^(Auto HDR, VRR ON, Flip Model^)...%COLOR_RESET%
    reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "AutoHDREnable=1;VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX : Auto HDR actif, VRR ON, Flip Model actif ^(Profil EQUILIBRE^)%COLOR_RESET%
)

:: 4.3 - Mode MSI (GPU) et telemetrie NVIDIA
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation MSI (GPU) et desactivation telemetrie NVIDIA...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ Set-ItemProperty -Path $p -Name 'MSISupported' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "FeatureControl" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "NvTeleSvc" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "DisplayWatchdog" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "NvMessageBus" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode MSI GPU active et telemetrie NVIDIA desactivee%COLOR_RESET%

:: 4.4 - Desactivation AMD telemetry
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie AMD...%COLOR_RESET%
reg add "HKLM\SOFTWARE\AMD\CN" /v "CollectGIData" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\ATI ACE\AUEPLauncher" /v "ReportProcessedEvents" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Telemetrie AMD desactivee%COLOR_RESET%

:: 4.5 - NVIDIA Low Latency
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des optimisations Low Latency NVIDIA...%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  if "!IS_LAPTOP!"=="0" (
    reg add "%%K" /v LOWLATENCY /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v Node3DLowLatency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v D3PCLatency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v F1TransitionLatency /t REG_DWORD /d 1 /f >nul 2>&1
  ) else (
    reg delete "%%K" /v LOWLATENCY /f >nul 2>&1
    reg delete "%%K" /v Node3DLowLatency /f >nul 2>&1
    reg delete "%%K" /v D3PCLatency /f >nul 2>&1
    reg delete "%%K" /v F1TransitionLatency /f >nul 2>&1
  )
)
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Low Latency active - Reduction de l'input lag ^(Profil LATENCE^)%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%MaxFrameLatency et forcage low-latency desactives - Veille GPU preservee ^(Profil EQUILIBRE^)%COLOR_RESET%
)

:: 4.6 - HAGS Enable
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la planification GPU acceleree (HAGS)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%HAGS active - Latence GPU reduite%COLOR_RESET%

:: 4.7 - Activation et raffinement de la preemption GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la preemption GPU (Hardware Scheduling)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Preemption GPU activee%COLOR_RESET%

:: 4.8 - NVIDIA Profile Inspector
:: Cette section telecharge et applique un profil d'optimisation NVIDIA pour reduire l'input lag
:: Note: applique seulement en profil LATENCE ; ignore en profil EQUILIBRE pour preserver autonomie/chauffe.
if "!HAS_NVIDIA!"=="1" (
    if "!IS_LAPTOP!"=="0" (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%GPU NVIDIA detecte - Configuration NVIDIA Profile Inspector...%COLOR_RESET%
        set "NPI_DIR=!TEMP!\NvidiaProfileInspector"

        rem Creer le dossier temporaire pour les fichiers NPI
        if not exist "!NPI_DIR!" mkdir "!NPI_DIR!"

        rem Telecharger NVIDIA Profile Inspector depuis GitHub
        rem Verification de la taille du fichier pour s'assurer qu'il n'est pas corrompu (min 10KB)
        powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/NVIDIA%%20Inspector/nvidiaProfileInspector.exe' -OutFile '!NPI_DIR!\nvidiaProfileInspector.exe' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
        if exist "!NPI_DIR!\nvidiaProfileInspector.exe" (
            for %%A in ("!NPI_DIR!\nvidiaProfileInspector.exe") do if %%~zA LSS 10000 (
                echo %COLOR_RED%[-]%COLOR_RESET% Erreur : Fichier NVIDIA Profile Inspector corrompu ou incomplet
                del "!NPI_DIR!\nvidiaProfileInspector.exe"
                goto :NPI_DONE
            )
        ) else (
            echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement de NVIDIA Profile Inspector
            goto :NPI_DONE
        )

        rem Telecharger le profil gaming optimise (Kaylers_profile.nip)
        rem Ce profil contient des parametres optimises pour reduire l'input lag
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Telechargement du profil gaming optimise...%COLOR_RESET%
        powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/NVIDIA%%20Inspector/Kaylers_profile.nip' -OutFile '!NPI_DIR!\Kaylers_profile.nip' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
        if exist "!NPI_DIR!\Kaylers_profile.nip" (
            for %%A in ("!NPI_DIR!\Kaylers_profile.nip") do if %%~zA LSS 100 (
                echo %COLOR_RED%[-]%COLOR_RESET% Erreur : Profil NVIDIA corrompu ou incomplet
                del "!NPI_DIR!\Kaylers_profile.nip"
                goto :NPI_DONE
            )
        ) else (
            echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement du profil
            goto :NPI_DONE
        )

        rem Appliquer le profil NVIDIA en utilisant l'outil Profile Inspector
        rem L'outil est lance en arriere-plan, applique le profil, puis est ferme
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application du profil NVIDIA optimise...%COLOR_RESET%
        start "" "!NPI_DIR!\nvidiaProfileInspector.exe" "!NPI_DIR!\Kaylers_profile.nip"
        ping -n 2 127.0.0.1 >nul 2>&1
        taskkill /f /im nvidiaProfileInspector.exe >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA Profile Inspector applique%COLOR_RESET%

        rem Nettoyage des fichiers temporaires
        del "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
        del "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
        rmdir "!NPI_DIR!" >nul 2>&1
    ) else (
        echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA global ignore en profil EQUILIBRE pour preserver autonomie, chauffe et silence%COLOR_RESET%
    )
) else (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% GPU NVIDIA non detecte - NVIDIA Profile Inspector ignore
)

:NPI_DONE
:: Fin des optimisations specifiques NVIDIA
set "NPI_DIR="
call :FINISH_ACTION "Optimisations GPU" "terminees"
exit /b

:OPTIMISATIONS_RESEAU
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 5 : OPTIMISATIONS RESEAU ET INTERNET%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la pile TCP/IP et la carte reseau.%COLOR_RESET%
echo %COLOR_WHITE%  Profil LATENCE = ping/reactivite max ; profil EQUILIBRE = recommande pour tous.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

if "%SKIP_PAUSE%"=="0" if "!DETECTED_LAPTOP!"=="1" (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%PC PORTABLE DETECTE - MODE MANUEL%COLOR_RESET%
    echo.
    echo %COLOR_WHITE%Vous etes sur un %COLOR_CYAN%PC Portable%COLOR_RESET%. Les optimisations reseau peuvent impacter :%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Wi-Fi%COLOR_RESET% : Nagle/DelACK OFF peut destabiliser le Wi-Fi%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Batterie%COLOR_RESET% : certains offloads agressifs augmentent la consommation%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Debit%COLOR_RESET% : profil latence privilegie le ping au debit%COLOR_RESET%
    echo.
    echo %COLOR_GREEN%[1]%COLOR_RESET% %COLOR_WHITE%Profil EQUILIBRE ^(recommande pour tous, surtout laptop^) - TCP prudent, debit/stabilite/autonomie%COLOR_RESET%
    echo %COLOR_RED%[2]%COLOR_RESET% %COLOR_WHITE%Profil LATENCE ^(agressif^) - TCP/NIC plus agressifs%COLOR_RESET%
    echo.
    choice /C 12 /N /M "%COLOR_YELLOW%Choisissez le profil [1=Equilibre, 2=Latence]: %COLOR_RESET%"
    if !errorlevel! EQU 2 (
        set "IS_LAPTOP=0"
        echo %COLOR_WHITE%Profil LATENCE force - Optimisations agressives actives%COLOR_RESET%
    ) else (
        set "IS_LAPTOP=1"
        echo %COLOR_WHITE%Profil EQUILIBRE conserve - Optimisations moderees actives%COLOR_RESET%
    )
    echo.
    echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
)

if "!IS_LAPTOP!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%LATENCE%COLOR_RESET%%COLOR_WHITE% - BBR2, NIC optimisee pour reponse instantanee%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%EQUILIBRE%COLOR_RESET%%COLOR_WHITE% - BBR2, stabilite et autonomie preservees%COLOR_RESET%
)
echo.

:: 5.1 - MMCSS reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration MMCSS reseau...%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 4294967295 /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul 2>&1
)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 20 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%MMCSS reseau configure%COLOR_RESET%

:: 5.2 - Pile TCP/IP Win11
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Pile TCP/IP Win11 ^(BBR2, fix loopback localhost^)...%COLOR_RESET%
netsh int tcp set global autotuninglevel=normal >nul 2>&1
netsh int tcp set heuristics forcews=disabled >nul 2>&1
netsh int ipv4 set global loopbacklargemtu=disabled >nul 2>&1
netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1

if "!IS_LAPTOP!"=="0" (
    netsh int tcp set global rss=enabled rsc=disabled ecncapability=disabled timestamps=disabled initialrto=1000 nonsackrttresiliency=disabled maxsynretransmissions=2 pacingprofile=off >nul 2>&1
) else (
    netsh int tcp set global rss=enabled rsc=enabled ecncapability=enabled >nul 2>&1
)

netsh int tcp set supplemental template=internet congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=internetcustom congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=datacenter congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=datacentercustom congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=compat congestionprovider=bbr2 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%BBR2 active sur les templates principaux%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%loopbacklargemtu reste desactive pour eviter les bugs locaux%COLOR_RESET%

:: 5.3 - Parametres TCP registre
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Parametres TCP registre...%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 32 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" /v Size /t REG_DWORD /d 3 /f >nul 2>&1
) else (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 128 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v NetbtPriority /t REG_DWORD /d 7 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Registre TCP configure%COLOR_RESET%

:: 5.4 - MSI Mode cartes reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation MSI Mode cartes reseau...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ Set-ItemProperty -Path $p -Name 'MSISupported' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%MSI Mode active sur cartes reseau%COLOR_RESET%

:: 5.5 - Optimisation BITS
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation du service BITS...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "EnableBypassProxyForLocal" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOn-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "MaxBandwidthOff-Schedule" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%BITS optimise%COLOR_RESET%

:: 5.6 - DNS et connexions paralleles
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Priorite DNS et connexions paralleles...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "LocalPriority" /t REG_DWORD /d 4 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "HostsPriority" /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v "DnsPriority" /t REG_DWORD /d 6 /f >nul 2>&1
if "!IS_LAPTOP!"=="0" (
    reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPER1_0SERVER" /v explorer.exe /t REG_DWORD /d 4 /f >nul 2>&1
    reg add "HKLM\SOFTWARE\Microsoft\Internet Explorer\MAIN\FeatureControl\FEATURE_MAXCONNECTIONSPERSERVER" /v explorer.exe /t REG_DWORD /d 2 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DNS et connexions paralleles configurees%COLOR_RESET%

:: 5.7 - Nagle/DelACK
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation Nagle et DelACK agressif...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpAckFrequency" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TCPNoDelay" /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v "TcpDelAckTicks" /t REG_DWORD /d 0 /f >nul 2>&1
    powershell -NoLogo -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress } ; if($ip){ New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name TCPNoDelay -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name DelayedAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name TcpDelAckTicks -PropertyType DWord -Value 0 -Force | Out-Null } }" >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK optimises ^(Profil LATENCE^)%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK : defauts Windows conserves ^(Profil EQUILIBRE^)%COLOR_RESET%
)

:: 5.8 - QoS Psched
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration QoS Psched ^(bande passante jeux^)...%COLOR_RESET%
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%QoS Psched configure ^(Profil LATENCE^)%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%QoS Psched : defaut Windows conserve ^(Profil EQUILIBRE^)%COLOR_RESET%
)

:: 5.9 - Optimisation cartes reseau
:: NOTE : on passe IS_LAPTOP par interpolation CMD (!IS_LAPTOP!) et non par
:: $env:IS_LAPTOP. Un `set "IS_LAPTOP=1"` cree une variable SHELL CMD, pas une
:: variable d'environnement process. Lire $env:IS_LAPTOP depuis PowerShell
:: aurait toujours renvoye $null, donc la branche laptop etait silencieusement
:: morte. Garder '!IS_LAPTOP!' (et non $env:) pour transmettre une variable CMD.
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Profil LATENCE ^(RSS ON, RSC/LSO OFF, Flow Control OFF^)...%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Profil EQUILIBRE ^(RSS/RSC/LSO ON, Flow Control OFF^)...%COLOR_RESET%
)
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $lap=('!IS_LAPTOP!' -eq '1'); $e=[char]0x00E9; $des='D'+$e+'sactiv'+$e; $act='Activ'+$e; function Set-Prop($a,$rx,$vals){$props=Get-NetAdapterAdvancedProperty -Name $a -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -match $rx}; foreach($p in $props){foreach($v in $vals){try{Set-NetAdapterAdvancedProperty -Name $a -DisplayName $p.DisplayName -DisplayValue $v -ErrorAction Stop; break}catch{}}}}; Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {$n=$_.Name; Enable-NetAdapterRss -Name $n -ErrorAction SilentlyContinue; if($lap){Enable-NetAdapterRsc -Name $n -ErrorAction SilentlyContinue; Enable-NetAdapterLso -Name $n -ErrorAction SilentlyContinue}else{Disable-NetAdapterRsc -Name $n -ErrorAction SilentlyContinue; Disable-NetAdapterLso -Name $n -ErrorAction SilentlyContinue}; Set-Prop $n 'Contr.*le.*Flux|Flow.*Control' @($des,'Disabled','Off'); Set-Prop $n 'Energy|Green|Efficace|Ethernet.*vert|.co.nerg.tique|Giga.*Lite|Power.*Saving' $(if($lap){@($act,'Enabled','On')}else{@($des,'Disabled','Off')}); Set-Prop $n 'Coalesce|Fusion.*paquet|Arr.t.*auto|Power.*Down|ARP.*Offload|NS.*Offload|Protocol.*Offload' $(if($lap){@($act,'Enabled','On')}else{@($des,'Disabled','Off')}); Set-Prop $n 'R.veil|Wake.*on|Magic.*Packet|Match.*Pattern' @($des,'Disabled','Off')}" >nul 2>&1
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour latence ^(Profil LATENCE^)%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour debit/stabilite/autonomie ^(Profil EQUILIBRE^)%COLOR_RESET%
)

:: 5.10 - QoS Fortnite DSCP 46
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration QoS Fortnite ^(DSCP 46^)...%COLOR_RESET%
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%QoS Fortnite activee%COLOR_RESET%

:: 5.11 - Nettoyage des protocoles reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des protocoles reseau inutiles (Bindings)...%COLOR_RESET%
powershell -NoProfile -Command "Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false } | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lldp','ms_lltdio','ms_implat','ms_rspndr' -ErrorAction SilentlyContinue }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Bindings reseau nettoyes (LLDP, LLTDIO, etc.)%COLOR_RESET%

:: 5.12 - Desactivation NetBIOS over TCP/IP
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de NetBIOS over TCP/IP...%COLOR_RESET%
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s ^| findstr /i /r "\\Tcpip_.*$" 2^>nul') do (
  reg add "%%i" /v NetbiosOptions /t REG_DWORD /d 2 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NetBIOS desactive%COLOR_RESET%

gpupdate /target:computer /force >nul 2>&1
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1
nbtstat -RR >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Pile reseau optimisee (DNS/NetBIOS purges)%COLOR_RESET%

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations reseau appliquees avec succes%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:OPTIMISATIONS_PERIPHERIQUES
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 6 : OPTIMISATIONS CLAVIER ET SOURIS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive l'acceleration souris et optimise%COLOR_RESET%
echo %COLOR_WHITE%  la reactivite des peripheriques d'entree.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: Avertissement mode manuel sur PC portable : choix entre profil Equilibre et Latence.
if "%SKIP_PAUSE%"=="0" if "!DETECTED_LAPTOP!"=="1" (
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%PC PORTABLE DETECTE - MODE MANUEL%COLOR_RESET%
    echo.
    echo %COLOR_WHITE%Vous etes sur un %COLOR_CYAN%PC Portable%COLOR_RESET%. Les optimisations peripheriques peuvent impacter :%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Trackpad%COLOR_RESET% : Acceleration OFF rend le trackpad moins naturel%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%DPI Scaling%COLOR_RESET% : Win8 Scaling OFF peut affecter l'affichage sur ecran haute densite%COLOR_RESET%
    echo.
    echo %COLOR_GREEN%[1]%COLOR_RESET% %COLOR_WHITE%Profil EQUILIBRE ^(recommande pour tous, surtout laptop^) - Acceleration legere, Scaling conserve%COLOR_RESET%
    echo %COLOR_RED%[2]%COLOR_RESET% %COLOR_WHITE%Profil LATENCE ^(agressif^) - Acceleration OFF, Win8 Scaling ON%COLOR_RESET%
    echo.
    choice /C 12 /N /M "%COLOR_YELLOW%Choisissez le profil [1=Equilibre, 2=Latence]: %COLOR_RESET%"
    if !errorlevel! EQU 2 (
        set "IS_LAPTOP=0"
        echo %COLOR_WHITE%Profil LATENCE force - Optimisations agressives actives%COLOR_RESET%
    ) else (
        set "IS_LAPTOP=1"
        echo %COLOR_WHITE%Profil EQUILIBRE conserve - Optimisations moderees actives%COLOR_RESET%
    )
    echo.
    echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
)

if "!IS_LAPTOP!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%LATENCE%COLOR_RESET%%COLOR_WHITE% - souris 1:1 sans acceleration%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%EQUILIBRE%COLOR_RESET%%COLOR_WHITE% - trackpad et souris optimises%COLOR_RESET%
)
echo.

:: 6.1 - Souris optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la reactivite souris...%COLOR_RESET%
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation acceleration souris ^(mouvement 1:1^)...%COLOR_RESET%
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseDelay" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "SnapToDefaultButton" /t REG_SZ /d "0" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Acceleration souris desactivee - Mouvement 1:1 actif%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration souris trackpad ^(acceleration legere conservee^)...%COLOR_RESET%
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "4" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "12" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseDelay" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "SnapToDefaultButton" /t REG_SZ /d "0" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Acceleration legere conservee - Trackpad optimise%COLOR_RESET%
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 32 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "ThreadPriority" /t REG_DWORD /d 31 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsolutePointerAsAbsolute" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsoluteAsRelative" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres souris et HID optimises%COLOR_RESET%

:: 6.2 - Clavier optimise
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la reactivite clavier...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d 32 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Clavier et files d'attente optimises - Delai minimal%COLOR_RESET%

:: 6.3 - Win8 Scaling (Profil LATENCE uniquement)
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation du Scaling Windows ^(Win8 DPI Scaling^)...%COLOR_RESET%
    reg add "HKCU\Control Panel\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 96 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Win8 Scaling active ^(Mode 1:1 force^)%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Win8 Scaling ignore en profil EQUILIBRE ^(conserve le scaling par defaut^)%COLOR_RESET%
)

:: 6.4 - MSI Mode Universel (Latence Peripheriques)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du MSI Mode pour tous les peripheriques compatibles...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class Net,Display,SCSIAdapter,USB -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ Set-ItemProperty -Path $p -Name 'MSISupported' -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Interruptions MSI activees sur tout le materiel compatible%COLOR_RESET%

:: 6.5 - Accessibilite OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des raccourcis d'accessibilite...%COLOR_RESET%
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourcis d'accessibilite desactives%COLOR_RESET%

:: 6.6 - HID parse optimise
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableInputDelayOptimization" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableBufferedInput" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%HID Parse et Input Delay optimises%COLOR_RESET%

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations des peripheriques appliquees avec succes%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:TOGGLE_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section permet de gerer les economies d'energie du systeme.%COLOR_RESET%
echo %COLOR_WHITE%  Le profil LATENCE desactive ces fonctions pour maximiser les performances.%COLOR_RESET%
echo %COLOR_WHITE%  Le profil EQUILIBRE les conserve/restaure pour tous, surtout laptop.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_RED%Desactiver les economies d'energie (Performances maximales)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Restaurer les economies d'energie (Parametres par defaut)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 12M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if !errorlevel! EQU 3 goto :MENU_PRINCIPAL
if !errorlevel! EQU 2 call :RESTAURER_ECONOMIES_ENERGIE & goto :TOGGLE_ECONOMIES_ENERGIE
if !errorlevel! EQU 1 call :DESACTIVER_ECONOMIES_ENERGIE & goto :TOGGLE_ECONOMIES_ENERGIE
goto :TOGGLE_ECONOMIES_ENERGIE

:DESACTIVER_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 7 : DESACTIVATION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive les fonctions d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  pour maintenir les performances maximales en permanence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 7.1 - Energie Systeme et GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration des seuils d'economie d'energie...%COLOR_RESET%

:: 7.2 - NVMe APST (Autonomous Power State Transition) - Profil LATENCE uniquement
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation APST NVMe ^(performance maximale, plus d'economie d'energie^)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NativeNVMePerformance /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%APST NVMe desactive - Performance maximale%COLOR_RESET%

:: 7.3 - Activation du plan Ultimate Performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du plan Ultimate Performance...%COLOR_RESET%
set "TARGET_GUID="
for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "e9a42b02-d5df-448d-aa00-03f14749eb61"') do (set "TARGET_GUID=%%G" & set "TARGET_GUID=!TARGET_GUID: =!")
if not defined TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "99999999-9999-9999-9999-999999999999"') do (set "TARGET_GUID=%%G" & set "TARGET_GUID=!TARGET_GUID: =!")
)
if not defined TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i /c:"Ultimate" /c:"optimales"') do (set "TARGET_GUID=%%G" & set "TARGET_GUID=!TARGET_GUID: =!")
)
if not defined TARGET_GUID (
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >nul 2>&1
    set "TARGET_GUID=99999999-9999-9999-9999-999999999999"
)
powercfg /setactive !TARGET_GUID! >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan Ultimate Performance actif (scheduler optimise - augmente la consommation)%COLOR_RESET%

:: 7.4 - GPU Power Management (ULPS & PowerMizer)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'ULPS (AMD) et configuration PowerMizer (NVIDIA)...%COLOR_RESET%
:: ULPS OFF - AMD
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v EnableUlps /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v EnableUlps_NA /t REG_DWORD /d 0 /f >nul 2>&1
)
:: PowerMizer - NVIDIA (Applique a toutes les instances GPU)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PowerMizerEnable /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevel /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PerfLevelSrc /t REG_DWORD /d 2222 /f >nul 2>&1
  reg add "%%K" /v DisableDynamicPstate /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v RmDisableRegistryCaching /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%GPU Power Management optimise%COLOR_RESET%

:: 7.5 - NIC Energy Saving Ethernet et WiFi
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des economies d'energie reseau (NIC - Ethernet et WiFi)...%COLOR_RESET%
powershell -NoProfile -Command "$e=[char]0x00E9;$des=\"D${e}sactiv${e}\"; function Set-NicVal { param($a,$n,$vals) foreach($v in $vals){ try { Set-NetAdapterAdvancedProperty -Name $a -DisplayName $n -DisplayValue $v -ErrorAction Stop; return } catch {} } }; Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p = $_.Name; reg add \"$p\" /v \"PnPCapabilities\" /t REG_DWORD /d 8 /f >$null; reg add \"$p\" /v \"AdvancedEEE\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*EEE\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"EEELinkAdvertisement\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"SipsEnabled\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"ULPMode\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"GigaLite\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"EnableGreenEthernet\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"PowerSavingMode\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"S5WakeOnLan\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*WakeOnMagicPacket\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*WakeOnPattern\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"WakeOnLink\" /t REG_SZ /d \"0\" /f >$null; reg add \"$p\" /v \"*ModernStandbyWoLMagicPacket\" /t REG_SZ /d \"0\" /f >$null }; Get-NetAdapter | Where-Object {$_.Status -eq 'Up'} | ForEach-Object { $adapter=$_.Name; $energyProps = @('Energy-Efficient Ethernet','Green Ethernet','Power Saving Mode','Gigabit Lite','Ethernet a economie d''energie','Ethernet vert','802.11 Power Save','Power Management','Allow the computer to turn off this device','Gestion de l''alimentation 802.11','Mode d''economie d''energie','Power Save Mode'); foreach($propName in $energyProps) { Set-NicVal $adapter $propName @('Disabled','Desactive',$des) } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie NIC desactivees (Registre + Pilotes)%COLOR_RESET%

:: 7.6 - Parametres avances du plan d'alimentation (user standard)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration avancee du plan d'alimentation...%COLOR_RESET%

:: Disque dur : ne jamais eteindre
powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1

:: Diaporama arriere-plan : en pause (economise CPU)
powercfg /setacvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1

:: Adaptateur Wi-Fi : performances maximales (pas de bridage Wi-Fi silencieux)
powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1

:: Veille hybride : desactivee (inutile si hibernate est off)
powercfg /setacvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0 >nul 2>&1
:: Hibernation apres : jamais
powercfg /setacvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0 >nul 2>&1

:: Hub selective suspend timeout : 0ms
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0 >nul 2>&1
:: USB 3 link power management : desactive
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1

:: Etat processeur max : 100%
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
:: Politique de refroidissement : actif (ventilateur reactif)
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 >nul 2>&1

:: Extinction ecran apres 10 min (protection OLED + economie)
powercfg /setacvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 >nul 2>&1

:: Biais qualite lecture video : performance
powercfg /setacvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 >nul 2>&1
:: Lecture video : qualite optimale
powercfg /setacvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 >nul 2>&1

:: Intel Graphics : performances maximales
powercfg /setacvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 2 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 2 >nul 2>&1
:: AMD power slider : meilleures performances
powercfg /setacvalueindex SCHEME_CURRENT c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 >nul 2>&1
:: ATI Powerplay : performances maximales
powercfg /setacvalueindex SCHEME_CURRENT f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 1 >nul 2>&1
:: GPU hybride switchable : performances maximales
powercfg /setacvalueindex SCHEME_CURRENT e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 3 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 3 >nul 2>&1

:: Appliquer le plan
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres avances du plan d'alimentation appliques%COLOR_RESET%

:: 7.7 - Optimisations CPU (Intel Hybrid + AMD Core Parking)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations CPU specifiques (Intel Hybrid / AMD Ryzen)...%COLOR_RESET%

:: Intel Hybrid CPUs (Alder Lake/Raptor Lake/Meteor Lake) - Scheduling Policy
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du profil processeur (performances maximales)...%COLOR_RESET%
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex scheme_current 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
:: Intel Thread Director : politique de scheduling reelle (valeur 2 = Prefer Performant Processors)
:: Note : les attributs UI (Attributes=2) sont deverrouilles en section 1.16 pour tous les profils.
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bae08b81-2d5e-4688-ad6a-13243356654b 2 >nul 2>&1
powercfg /setactive scheme_current >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Intel Thread Director : politique "Prefer Performant" appliquee (P-cores prioritaires)^(options de parking Core/Hetero visibles dans powercfg^)%COLOR_RESET%

:: AMD Ryzen - Desactivation Core Parking
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation Core Parking (AMD Ryzen)...%COLOR_RESET%
:: Appliquer immediatement : desactiver le core parking via powercfg sur le plan actif
:: GUID SUB_PROCESSOR en dur (alias SUB_PROCESSOR non fiable selon la locale Windows)
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking desactive (AMD Ryzen optimise)%COLOR_RESET%

:: 7.8 - Desactivation economies d'energie Device Manager (ACPI/HID/PCI/USB)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de l'alimentation des peripheriques (Device Manager)...%COLOR_RESET%
powershell -NoProfile -Command "$p=@('ACPI','HID','PCI','USB','USBSTOR'); foreach($s in $p){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Enum\$s\" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' -or $_.PSChildName -eq 'WDF' } | ForEach-Object { $rp = $_.Name; if($_.PSChildName -eq 'Device Parameters'){ reg add \"$rp\" /v \"EnhancedPowerManagementEnabled\" /t REG_DWORD /d 0 /f >$null; reg add \"$rp\" /v \"SelectiveSuspendEnabled\" /t REG_BINARY /d \"00\" /f >$null; reg add \"$rp\" /v \"SelectiveSuspendOn\" /t REG_DWORD /d 0 /f >$null; reg add \"$rp\" /v \"WaitWakeEnabled\" /t REG_DWORD /d 0 /f >$null } else { reg add \"$rp\" /v \"IdleInWorkingState\" /t REG_DWORD /d 0 /f >$null } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie Device Manager desactivees (HID/PCI/USB)%COLOR_RESET%

:: 7.9 - Desactivation du demarrage rapide Fast Startup
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du demarrage rapide (Fast Startup)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Demarrage rapide desactive - Redemarrages propres%COLOR_RESET%

:: 7.10 - Hibernation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'hibernation...%COLOR_RESET%
powercfg /hibernate off >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Hibernation desactivee - Espace disque libere%COLOR_RESET%

:: 7.11 - USB Selective Suspend (Optimisation latence)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation USB - Desactivation de la mise en veille selective...%COLOR_RESET%
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%USB optimise - Latence minimale ^(Selective Suspend OFF^)%COLOR_RESET%

:: 7.12 - Configuration generale du systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du systeme d'alimentation...%COLOR_RESET%
:: (Anciens powercfg sur SUB_ENERGYSAVER (de830923...) supprimes - sous-groupe inexistant en Win10/11)
:: ASPM est configure correctement a la section 7.22 ci-dessous avec SUB_PCIEXPRESS (501a4d13...)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.13 - Desactivation des Timer Coalescing et DPC
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des Timer Coalescing et optimisation DPC...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v MinimumDpcRate /t REG_DWORD /d 1 /f >nul 2>&1
:: DisableTsx - Intel Transactional Synchronization Extensions (Intel uniquement, pas AMD)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Timer Coalescing desactive - Latence reduite%COLOR_RESET%

:: 7.14 - Installation SetTimerResolution
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration de SetTimerResolution...%COLOR_RESET%
set "STR_EXE=%SystemRoot%\SetTimerResolution.exe"
set "STR_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
if exist "%STR_EXE%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution deja installe dans %SystemRoot%%COLOR_RESET%
) else (
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe' -OutFile '%STR_EXE%' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
    if exist "%STR_EXE%" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution installe dans %SystemRoot%%COLOR_RESET%
    ) else (
        echo %COLOR_RED%[-]%COLOR_RESET% Echec du telechargement de SetTimerResolution
    )
)
if exist "%STR_EXE%" (
    taskkill /F /IM SetTimerResolution.exe >nul 2>&1
    powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STR_STARTUP%'); $Shortcut.TargetPath = '%SystemRoot%\SetTimerResolution.exe'; $Shortcut.Arguments = '--resolution 5070 --no-console'; $Shortcut.WorkingDirectory = '%SystemRoot%'; $Shortcut.Description = 'SetTimerResolution - WindowsOptimizer'; $Shortcut.Save()" >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci SetTimerResolution configure ^(5070^)%COLOR_RESET%
    start "" "%STR_EXE%" --resolution 5070 --no-console
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution active immediatement%COLOR_RESET%
)

:: 7.15 - Desactivation du PDC et Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du Power Throttling (bridage CPU)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power Throttling desactive - CPU non bride%COLOR_RESET%

:: 7.16 - Desactivation ASPM
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation ASPM sur le bus PCI Express...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%ASPM desactive - Latence PCIe reduite%COLOR_RESET%

:: 7.17 - Optimisations stockage et disques (DirectStorage haute consommation)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la mise en veille des disques et DirectStorage haute consommation...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisableStorageQoS /t REG_DWORD /d 1 /f >nul 2>&1
:: DirectStorage : mode haute consommation (NVMe perf max + decompression GPU)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "ForcedLowPowerMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDecompressionInGPU" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDirectStorage" /t REG_DWORD /d 1 /f >nul 2>&1
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Set-ItemProperty -Path $p -Name 'EnableHIPM' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'EnableDIPM' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue; Set-ItemProperty -Path $p -Name 'EnableHDDParking' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectStorage en mode haute consommation - NVMe perf max%COLOR_RESET%

:: 7.18 - Optimisations avancees des services
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des limites de latence I/O...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Set-ItemProperty -Path $p -Name 'IoLatencyCap' -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Limites de latence stockage supprimees%COLOR_RESET%

:: 7.19 - GPU PreferMaxPerf
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration GPU en mode performances maximales...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PreferMaxPerf /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%GPU configure en mode performances maximales%COLOR_RESET%

:: 7.20 - PCI & peripheriques reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la mise en veille des peripheriques PCI...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "*WakeOnPattern" /t REG_DWORD /d 0 /f >nul 2>&1
)

:: 7.21 - Cartes reseau (aligne Ultimate 18)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des fonctions d'economie d'energie reseau...%COLOR_RESET%
powershell -NoProfile -Command "Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; $props=@{'*EEE'='0';'*SelectiveSuspend'='0';'*WakeOnMagicPacket'='0';'*ModernStandbyWoLMagicPacket'='0';'EnableGreenEthernet'='0';'ULPMode'='0';'*WakeOnPattern'='0';'*PMARPOffload'='0';'*PMNSOffload'='0';'EnablePME'='0';'PowerSavingMode'='0';'ReduceSpeedOnPowerDown'='0';'EnableDynamicPowerGating'='0';'AutoPowerSaveModeEnabled'='0';'AdvancedEEE'='0';'EEELinkAdvertisement'='0';'GigaLite'='0';'S5WakeOnLan'='0';'WakeOnLink'='0';'SipsEnabled'='0';'*FlowControl'='0';'*InterruptModeration'='1';'*InterruptModerationRate'='2';'ITR'='0';'EnableLLI'='1';'EnableDownShift'='0'}; foreach($n in $props.Keys){ Set-ItemProperty -Path $p -Name $n -Value $props[$n] -Force -ErrorAction SilentlyContinue }; Set-ItemProperty -Path $p -Name 'PnPCapabilities' -Value 24 -Type DWord -Force -ErrorAction SilentlyContinue } " >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie et optimisations reseau appliquees sur toutes les cartes%COLOR_RESET%

:: 7.22 - Energie PCIe
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation gestion d'energie PCIe...%COLOR_RESET%
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie PCIe desactivee%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "DisableASPM" /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v "RMForcedMaxPerf" /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%GPU optimise%COLOR_RESET%

:: Appliquer l'ensemble des modifications du plan d'alimentation en une seule fois
powercfg /S SCHEME_CURRENT >nul 2>&1

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Economies d'energie desactivees - Performances maximales activees%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
set "TARGET_GUID="
set "STR_EXE="
set "STR_STARTUP="
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:RESTAURER_ECONOMIES_ENERGIE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 7 : RESTAURATION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section restaure les parametres d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  aux valeurs par defaut de Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 7.0 - Reactiver le plan d'alimentation Equilibre Windows (defaut)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du plan Equilibre Windows...%COLOR_RESET%
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan Equilibre Windows actif%COLOR_RESET%

:: 7.1 - Demarrage rapide (Fast Startup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation du demarrage rapide (Fast Startup)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Demarrage rapide reactive%COLOR_RESET%

:: 7.2 - Hibernation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de l'hibernation...%COLOR_RESET%
powercfg /hibernate on >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Hibernation reactivee%COLOR_RESET%

:: 7.3 - USB Selective Suspend
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la mise en veille selective USB...%COLOR_RESET%
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mise en veille selective USB reactivee%COLOR_RESET%

:: 7.4 - Timer Coalescing
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation du Timer Coalescing...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v MinimumDpcRate /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /f >nul 2>&1
:: (bcdedit /deletevalue disabledynamictick supprime : pas de bcdedit /set disabledynamictick dans le disable,
::  c'etait un no-op - rien a supprimer)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\kernel" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\ModernSleep" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Timer Coalescing reactive%COLOR_RESET%

:: 7.5 - SetTimerResolution du demarrage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression de SetTimerResolution du demarrage...%COLOR_RESET%
taskkill /f /im SetTimerResolution.exe >nul 2>&1
if exist "%SystemRoot%\SetTimerResolution.exe" del /f /q "%SystemRoot%\SetTimerResolution.exe" >nul 2>&1
set "STR_STARTUP=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
if exist "%STR_STARTUP%" (
    del "%STR_STARTUP%" /f /q >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci SetTimerResolution supprime du demarrage%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution n'etait pas dans le demarrage%COLOR_RESET%
)

:: 7.6 - Restaurer Intel Thread Director
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration Intel Thread Director...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\bae08b81-2d5e-4688-ad6a-13243356654b" /v Attributes /f >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bae08b81-2d5e-4688-ad6a-13243356654b 5 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bae08b81-2d5e-4688-ad6a-13243356654b 5 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Intel Thread Director restaure%COLOR_RESET%

:: 7.7 - Restaurer AMD Core Parking
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration Core Parking (AMD Ryzen)...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /f >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking restaure%COLOR_RESET%

:: 7.8 - Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation du Power Throttling...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1

:: 7.9 - Seuils d'economie d'energie
:: (Ancien powercfg sur SUB_ENERGYSAVER/ESBATTTHRESHOLD supprime - sous-groupe inexistant en Win10/11,
::  l'alias ESBATTTHRESHOLD est de plus obsolete. Le seuil par defaut 20% est hardcode dans le plan Balanced.)

:: 7.10 - NVMe APST (Autonomous Power State Transition)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration APST NVMe ^(economie d'energie par defaut^)...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v NativeNVMePerformance /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%APST NVMe restaure - Economie d'energie active%COLOR_RESET%

:: 7.11 - ULPS (AMD) et PowerMizer (Auto)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de l'ULPS (AMD) et PowerMizer (Auto)...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v EnableUlps /f >nul 2>&1
  reg delete "%%K" /v EnableUlps_NA /f >nul 2>&1
  reg delete "%%K" /v PowerMizerEnable /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevel /f >nul 2>&1
  reg delete "%%K" /v PowerMizerLevelAC /f >nul 2>&1
  reg delete "%%K" /v PerfLevelSrc /f >nul 2>&1
  reg delete "%%K" /v DisableDynamicPstate /f >nul 2>&1
  reg delete "%%K" /v RmDisableRegistryCaching /f >nul 2>&1
  reg delete "%%K" /v DisableASPM /f >nul 2>&1
  reg delete "%%K" /v RMForcedMaxPerf /f >nul 2>&1
)

:: 7.12 - Economies d'energie reseau (NIC)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation des economies d'energie reseau (NIC) et bindings...%COLOR_RESET%
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $e=[char]0x00E9; $act='Activ'+$e; $mod='Mod'+$e+'r'+$e; function Set-Prop($a,$rx,$vals){$props=Get-NetAdapterAdvancedProperty -Name $a -ErrorAction SilentlyContinue | Where-Object {$_.DisplayName -match $rx}; foreach($p in $props){foreach($v in $vals){try{Set-NetAdapterAdvancedProperty -Name $a -DisplayName $p.DisplayName -DisplayValue $v -ErrorAction Stop; break}catch{}}}}; Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {$n=$_.Name; Enable-NetAdapterRss -Name $n -ErrorAction SilentlyContinue; Enable-NetAdapterRsc -Name $n -ErrorAction SilentlyContinue; Enable-NetAdapterLso -Name $n -ErrorAction SilentlyContinue; Set-Prop $n 'Energy|Green|Efficace|Ethernet.*vert|.co.nerg.tique|Giga.*Lite|Power.*Saving' @('Enabled','Active',$act,'On'); Set-Prop $n 'Interrupt.*Mod|Mod.*ration' @('Enabled','Active',$act,'On'); Set-Prop $n 'Moderation.*Rate|Taux.*mod' @('Moderate','Modere',$mod,'Medium')}; $keysToRemove=@('PnPCapabilities','AdvancedEEE','*EEE','EEELinkAdvertisement','SipsEnabled','ULPMode','GigaLite','EnableGreenEthernet','PowerSavingMode','S5WakeOnLan','*WakeOnMagicPacket','*WakeOnPattern','WakeOnLink','*ModernStandbyWoLMagicPacket','*SelectiveSuspend','*PMARPOffload','*PMNSOffload','EnablePME','ReduceSpeedOnPowerDown','EnableDynamicPowerGating','AutoPowerSaveModeEnabled','*FlowControl','*InterruptModeration','*InterruptModerationRate','ITR','EnableLLI','EnableDownShift'); Get-ChildItem -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}' -ErrorAction SilentlyContinue | Where-Object {$_.PSChildName -match '^\d{4}$'} | ForEach-Object {foreach($k in $keysToRemove){Remove-ItemProperty -Path $_.PSPath -Name $k -ErrorAction SilentlyContinue}}; $bindingIds=@('ms_lldp','ms_lltdio','ms_implat','ms_rspndr'); Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {foreach($id in $bindingIds){Enable-NetAdapterBinding -Name $_.Name -ComponentID $id -ErrorAction SilentlyContinue}}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie NIC et bindings restaures%COLOR_RESET%

:: 7.13 - Parametres processeur par defaut
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des parametres processeur par defaut...%COLOR_RESET%
:: Supprimer les overrides Attributes (retour au comportement par defaut du panneau)
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /f >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 893dee8e-2bef-41e0-89c6-b55d0929964c 5 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 90 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres processeur restaures%COLOR_RESET%

:: 7.14 - ASPM (PCI Express)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation ASPM sur le bus PCI Express...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%ASPM reactive%COLOR_RESET%

:: 7.15 - Mise en veille des disques et DirectStorage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la mise en veille des disques et DirectStorage par defaut...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v IdlePowerMode /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v DisableStorageQoS /f >nul 2>&1
:: Revert DirectStorage haute consommation
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "ForcedLowPowerMode" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDecompressionInGPU" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\DirectStorage" /v "EnableDirectStorage" /f >nul 2>&1
:: Supprimer HIPM/DIPM/HDDParking pour revenir aux valeurs par defaut systeme
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'EnableHIPM','EnableDIPM','EnableHDDParking' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mise en veille des disques reactivee%COLOR_RESET%

:: 7.16 - Limites de latence I/O
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des limites de latence I/O...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path \"HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c\" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'IoLatencyCap' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Limites de latence I/O restaurees%COLOR_RESET%

:: 7.17 - Gestion d'energie GPU et DirectX
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la gestion d'energie GPU et preferences DirectX...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v PreferMaxPerf /f >nul 2>&1
)
:: Revert Auto HDR et DirectX UserGpuPreferences
reg delete "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie GPU et preferences DirectX restaurees%COLOR_RESET%
:: 7.18 - Gestion d'energie PCI
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la gestion d'energie PCI...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v D3ColdSupported /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v "*WakeOnPattern" /f >nul 2>&1
)

:: 7.19 - Systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration du systeme d'alimentation...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v SleepStudyDisabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Systeme d'alimentation restaure%COLOR_RESET%

:: 7.20 - Peripheriques ACPI/HID/PCI/USB
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des parametres d'economie des peripheriques ACPI, HID, PCI et USB...%COLOR_RESET%
powershell -NoProfile -Command "$bases=@('HKLM:\SYSTEM\CurrentControlSet\Enum\ACPI','HKLM:\SYSTEM\CurrentControlSet\Enum\HID','HKLM:\SYSTEM\CurrentControlSet\Enum\PCI','HKLM:\SYSTEM\CurrentControlSet\Enum\USB','HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR'); foreach($b in $bases){ if(Test-Path $b){ Get-ChildItem -Path $b -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'EnhancedPowerManagementEnabled','SelectiveSuspendEnabled','SelectiveSuspendOn','WaitWakeEnabled','DeviceSelectiveSuspended' -ErrorAction SilentlyContinue }; Get-ChildItem -Path $b -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'WDF' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'IdleInWorkingState' -ErrorAction SilentlyContinue } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres d'economie des peripheriques restaures%COLOR_RESET%

:: 7.21 - Gestion d'energie PCIe
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation gestion d'energie PCIe...%COLOR_RESET%
powercfg /setacvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 >nul 2>&1
powercfg /S SCHEME_CURRENT >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie PCIe reactivee%COLOR_RESET%

:: 7.22 - Plans d'alimentation avances
:: (Masquage ATTRIB_HIDE sur 75b0ae3f... et ea062031... supprime : etaient des no-ops,
::  rien dans la section disable ne les de-masque, donc rien a re-masquer au restore.)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plans d'alimentation restaures (parametres avances selon defaut Windows)%COLOR_RESET%

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Economies d'energie restaurees - Parametres par defaut actifs%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
set "STR_STARTUP="
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:TOGGLE_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section permet de desactiver ou restaurer les mitigations%COLOR_RESET%
echo %COLOR_WHITE%  de securite sensibles (Spectre/Meltdown, noyau, CI policy).%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_RED%Desactiver Protections Securite (mode perf)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Restaurer Protections Securite (recommande)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
choice /C 12M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if !errorlevel! EQU 3 goto :MENU_PRINCIPAL
if !errorlevel! EQU 2 call :RESTAURER_PROTECTIONS_SECURITE & goto :TOGGLE_PROTECTIONS_SECURITE
if !errorlevel! EQU 1 call :DESACTIVER_PROTECTIONS_SECURITE & goto :TOGGLE_PROTECTIONS_SECURITE
goto :TOGGLE_PROTECTIONS_SECURITE

:DESACTIVER_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 8 : DESACTIVATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[^!]%COLOR_RESET% AVERTISSEMENT :
echo %COLOR_WHITE%  Cette section desactive les protections contre les vulnerabilites%COLOR_RESET%
echo %COLOR_WHITE%  materielles (Spectre, Meltdown) et certaines mitigations noyau.%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Avantages : Reduction de la latence systeme, moins d'overhead CPU%COLOR_RESET%
echo %COLOR_WHITE%  Risques   : Exposition a des attaques par canal auxiliaire%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Pourquoi demander une confirmation :%COLOR_RESET%
echo %COLOR_WHITE%  - Les mitigations Spectre/Meltdown et noyau limitent les fuites de donnees%COLOR_RESET%
echo %COLOR_WHITE%    via le CPU ; les desactiver peut ameliorer perfs/latence mais affaiblit la defense.%COLOR_RESET%
echo %COLOR_WHITE%  - La blocklist de pilotes vulnerables aide Windows a bloquer des drivers dangereux.%COLOR_RESET%
echo %COLOR_WHITE%  - Ces cles de registre sont sensibles : erreur = instabilite ou surface d'attaque.%COLOR_RESET%
echo %COLOR_WHITE%  - Indique surtout pour bench/jeux competitifs sur machine isolee et maitrisee.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_PROTECTIONS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces protections ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_PROTECTIONS_RUN

:: 8.1 - Desactivation des protections Kernel SEHOP Exception Chain
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des protections noyau (SEHOP, Exception Chain)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Protections noyau desactivees%COLOR_RESET%

:: 8.2 - Desactivation Spectre Meltdown Memory Management
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des protections Spectre/Meltdown...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
::reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableCfg /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableGdsMitigation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PerformMmioMitigation /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Protections Spectre/Meltdown desactivees%COLOR_RESET%

:: 8.3 - Desactivation des mitigations CPU avancees
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des mitigations CPU (KVAS, STIBP, Retpoline)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mitigations CPU desactivees%COLOR_RESET%

:: 8.4 - HVCI et CFG conserves pour compatibilite anti-cheat
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Conservation du VBS/HVCI/CFG (requis pour Valorant, Fortnite, etc.)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
:: CFG doit rester ACTIVE pour Vanguard (Valorant)
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%VBS/HVCI/CFG conserves (compatibilite anti-cheat)%COLOR_RESET%

:: Vulnerable Driver Blocklist
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation CI Policy (Driver Blocklist)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Blocklist de pilotes vulnerables desactivee%COLOR_RESET%

:: USB Polling / WHQL Settings
if "!IS_LAPTOP!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Debridage du polling rate USB ^(WHQL Settings^)...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v WHQLSettings /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Debridage USB active ^(Profil LATENCE uniquement^)%COLOR_RESET%
)

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Protections de securite desactivees - VBS/HVCI/CFG conserves%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:RESTAURER_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 8 : RESTAURATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
:: 8.1 - Protections noyau (SEHOP, Exception Chain)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des protections noyau (SEHOP, Exception Chain)...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Protections noyau restaurees%COLOR_RESET%
echo.
:: 8.2 - Mitigations Spectre/Meltdown et CPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des mitigations Spectre/Meltdown et CPU...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableGdsMitigation /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PerformMmioMitigation /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mitigations CPU restaurees%COLOR_RESET%
echo.
:: 8.3 - Blocklist de pilotes vulnerables
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la blocklist de pilotes vulnerables...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\CI\Policy" /v WHQLSettings /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%CI policy restauree%COLOR_RESET%

:: 8.4 - Restauration VBS/HVCI/CFG aux valeurs par defaut
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /f >nul 2>&1
:: CFG doit etre ACTIVE par defaut (requis pour Vanguard / anti-cheat)
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Protections de securite restaurees par defaut%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer les modifications.%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="0" (
    pause
)
exit /b

:TOGGLE_DEFENDER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Defender est l'antivirus integre de Windows. Le desactiver reduit l'overhead CPU/RAM%COLOR_RESET%
echo %COLOR_WHITE%mais expose le systeme. Tamper Protection peut ignorer une partie de ces reglages.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer Windows Defender (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver Windows Defender (Non recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_DEFENDER_SECTION

  goto :TOGGLE_DEFENDER
)
call :ACTIVER_DEFENDER_SECTION
goto :TOGGLE_DEFENDER

:: ___DEFENDER_ULT_EMBEDDED_SUBS___
:ACTIVER_DEFENDER_SECTION
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% %STYLE_BOLD%Reactivation de Windows Defender...%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de Tamper Protection...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 5 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation des services Windows Defender...%COLOR_RESET%
sc config WinDefend start= auto >nul 2>&1
for %%S in (WdNisSvc Sense SecurityHealthService) do sc config %%S start= demand >nul 2>&1
for %%S in (WdBoot WdFilter WdNisDrv) do sc config %%S start= boot >nul 2>&1
for %%S in (WinDefend WdNisSvc Sense SecurityHealthService) do sc start %%S >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la protection en temps reel...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableRealtimeMonitoring /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableIOAVProtection /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableScriptScanning /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableBehaviorMonitoring /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v DisableOnAccessProtection /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v DisableAsyncScanOnOpen /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation des politiques Windows Defender...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableAntiVirus /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableBlockAtFirstSeen /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v DisableRoutinelyTakingAction /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v DisableAntiSpyware /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v VerifiedAndReputableTrustModeEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v SmartLockerMode /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v "VulnerableDriverBlocklistEnable" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de SmartScreen...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /t REG_SZ /d "Warn" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Warn" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation des taches planifiees...%COLOR_RESET%
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Update" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Enable >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services Defender restaures%COLOR_RESET%
call :FINISH_ACTION "Windows Defender" "reactive"
exit /b

:DESACTIVER_DEFENDER_SECTION
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_DEFENDER_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : desactiver l'antivirus integre reduit la charge CPU/disque%COLOR_RESET%
echo %COLOR_WHITE%et supprime les micro-begaiements lies aux analyses en temps reel.%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_YELLOW%[CONSEILS]%COLOR_RESET%
echo %COLOR_WHITE%- %COLOR_GREEN%GARDEZ-LE%COLOR_RESET% : Si vous n'avez pas d'autre antivirus et naviguez beaucoup.%COLOR_RESET%
echo %COLOR_WHITE%- %COLOR_RED%COUPEZ-LE%COLOR_RESET% : Si vous utilisez un antivirus tiers ^(Bitdefender, Kaspersky...^)%COLOR_RESET%
echo %COLOR_WHITE%  ou si vous cherchez la performance maximale pour du jeu competitif.%COLOR_RESET%
echo.
echo %COLOR_RED%[IMPORTANT]%COLOR_RESET% %COLOR_YELLOW%Sans Defender, aucune protection en temps reel n'est active.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Sur Windows 10 1903+ / 11, Tamper Protection bloque les modifications du registre%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%Defender. Vous DEVEZ d'abord la desactiver manuellement :%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%Parametres ^> Confidentialite et securite ^> Securite Windows ^> Protection contre les%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%piratages et menaces ^> Parametres de protection ^> Tamper Protection = OFF.%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%Sinon, les commandes ci-dessous seront silencieusement ignorees par Defender.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_DEFENDER_RUN "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Windows Defender ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_DEFENDER_RUN
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% %STYLE_BOLD%Demande de desactivation de Windows Defender...%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de Tamper Protection...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des services Windows Defender...%COLOR_RESET%
for %%S in (WinDefend WdNisSvc Sense SecurityHealthService) do sc stop %%S >nul 2>&1
for %%S in (WinDefend WdNisSvc Sense WdBoot WdFilter WdNisDrv SecurityHealthService) do sc config %%S start= disabled >nul 2>&1
for %%S in (Sense WdBoot WdFilter WdNisDrv WdNisSvc WinDefend SecurityHealthService) do reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la protection en temps reel...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableRealtimeMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableIOAVProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableScriptScanning" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableBehaviorMonitoring" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" /v "DisableOnAccessProtection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection" /v "DisableAsyncScanOnOpen" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des politiques Windows Defender...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableAntiVirus" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableBlockAtFirstSeen" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows Defender" /v "DisableRoutinelyTakingAction" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "DisableAntiSpyware" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "VerifiedAndReputableTrustModeEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender" /v "SmartLockerMode" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des taches planifiees (Defender/ExploitGuard)...%COLOR_RESET%
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Update" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Disable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Disable >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de SmartScreen...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Reglages Defender appliques ^(effectif selon Tamper Protection / version Windows^)%COLOR_RESET%
call :FINISH_ACTION "Windows Defender" "configure"
exit /b

:TOGGLE_VBS_HVCI
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER VBS / HVCI (ISOLATION DU NOYAU)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%VBS (Virtualization Based Security) et HVCI (Memory Integrity) securisent le noyau%COLOR_RESET%
echo %COLOR_WHITE%mais impactent lourdement les performances en jeu (jusqu'a -25%% FPS).%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_RED%[!] ATTENTION :%COLOR_RESET% %COLOR_YELLOW%Certains anti-cheats (Vanguard/Valorant, FaceIT, Ricochet)%COLOR_RESET%
echo %COLOR_YELLOW%peuvent exiger que VBS/HVCI soit ACTIVE pour lancer le jeu.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer VBS / HVCI (Securite maximale)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver VBS / HVCI (Performances Gaming maximales)%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %STYLE_BOLD%%COLOR_CYAN%Mode Gaming (FaceIT/Vanguard compatible) - %COLOR_GREEN%RECOMMANDE%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 123M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, 3, M]: %COLOR_RESET%"
if !errorlevel! EQU 4 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 3 (
  echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application du Mode Gaming ^(Performance + Compatibilite^)...%COLOR_RESET%
  rem Desactiver Mitigations CPU (Gain FPS)
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1
  rem HVCI = 1, VBS = 1, CFG = 1, LSA = 0 (Mode optimal pour anti-cheat + perfs)
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
  powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1
  echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Gaming active ^(Optimisation CPU + Compatibilite Anti-cheat^).%COLOR_RESET%
  call :FINISH_ACTION "VBS/HVCI" "configure (Mode Gaming)"
  goto :TOGGLE_VBS_HVCI
)
if !errorlevel! EQU 2 (
  echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation complete de VBS, HVCI et Credential Guard...%COLOR_RESET%
  reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
  echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%VBS/HVCI et Credential Guard desactives.%COLOR_RESET%
  call :FINISH_ACTION "VBS/HVCI" "desactive"
  goto :TOGGLE_VBS_HVCI
)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de VBS, HVCI et Credential Guard...%COLOR_RESET%
reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\System\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%VBS/HVCI et Credential Guard actives.%COLOR_RESET%
call :FINISH_ACTION "VBS/HVCI" "active"
goto :TOGGLE_VBS_HVCI

:TOGGLE_UAC
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER UAC (CONTROLE DE COMPTE UTILISATEUR)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%L'UAC affiche une invite de confirmation avant toute action admin.%COLOR_RESET%
echo %COLOR_WHITE%Le desactiver supprime ces invites : plus rapide, mais dangereux.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer UAC (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver UAC + Avertissements (Pour LAB)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_UAC_SECTION
  goto :TOGGLE_UAC
)
call :ACTIVER_UAC_SECTION
goto :TOGGLE_UAC

:ACTIVER_UAC_SECTION
cls
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Activation de l'UAC et des avertissements...%COLOR_RESET%
echo.

:: UAC normal
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1

:: SmartScreen Explorer par defaut
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Warn" /f >nul 2>&1

:: Reactiver le suivi de zone (fichiers telecharges marques comme Internet)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 2 /f >nul 2>&1
call :FINISH_ACTION "UAC" "active"
exit /b

:DESACTIVER_UAC_SECTION
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_UAC_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER L'UAC%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une derniere confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- L'UAC demande une elevation explicite avant qu'un programme obtienne des droits admin.%COLOR_RESET%
echo %COLOR_WHITE%- La desactivation supprime ces invites : un malware peut agir sans boite de dialogue.%COLOR_RESET%
echo %COLOR_WHITE%- Ce script desactive aussi des avertissements SmartScreen / marquage zone Internet.%COLOR_RESET%
echo %COLOR_WHITE%- Reserve aux bancs de test ou utilisateurs conscients du risque.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[^!]%COLOR_RESET% LAB UNIQUEMENT : plus aucun avertissement au lancement de fichiers.
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_UAC_RUN "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC et les avertissements lies ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_UAC_RUN
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% %STYLE_BOLD%Desactivation complete de l'UAC et des avertissements...%COLOR_RESET%
if "%SKIP_PAUSE%"=="1" echo %COLOR_YELLOW%[^!]%COLOR_RESET% LAB UNIQUEMENT : plus aucun avertissement au lancement de fichiers.
if "%SKIP_PAUSE%"=="1" echo.

:: UAC OFF = plus de demande Oui/Non (Peut impacter certaines apps Store)
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1

:: Desactiver SmartScreen Explorer
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul 2>&1

:: Desactiver "Ce fichier provient d'Internet" (Zone.Identifier)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 1 /f >nul 2>&1
call :FINISH_ACTION "UAC" "desactive"
exit /b

:TOGGLE_ANIMATIONS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Les animations Windows consomment un peu de GPU/CPU. Les desactiver peut%COLOR_RESET%
echo %COLOR_WHITE%fluidifier un PC faible, au prix d'une interface plus "seche".%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer les animations Windows (experience utilisateur standard)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver les animations Windows (pour optimiser les performances)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 12M /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_ANIMATIONS_SECTION
  goto :TOGGLE_ANIMATIONS
)
call :ACTIVER_ANIMATIONS_SECTION
goto :TOGGLE_ANIMATIONS

:ACTIVER_ANIMATIONS_SECTION
cls
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Activation des animations Windows...%COLOR_RESET%
echo.

:: VisualFXSetting=3 (Personnalise) pour que Windows utilise uniquement les cles
:: individuelles ci-dessous sans recalculer tous les effets (ce qui reset le menu Demarrer)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "400" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuAnimation /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v TooltipAnimation /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v SelectionFade /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuFade /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserUIEffects /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AnimateWindow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ComboboxAnimation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ListBoxSmoothScrolling /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1

:: Activer les effets visuels supplementaires
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "1" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /f >nul 2>&1

:: Supprimer la politique DisableStartupAnimation
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /f >nul 2>&1

:: Reactiver l'animation de demarrage Windows
bcdedit /set bootuxdisabled off >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Animations Windows activees.%COLOR_RESET%
call :FINISH_ACTION "Animations" "activees"
exit /b

:DESACTIVER_ANIMATIONS_SECTION
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_ANIMATIONS_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une derniere confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Les animations consomment un peu de GPU/CPU ; les couper peut fluidifier un PC faible.%COLOR_RESET%
echo %COLOR_WHITE%- Cela modifie le registre utilisateur et bcdedit ^(animation du logo au demarrage^).%COLOR_RESET%
echo %COLOR_WHITE%- L'interface parait plus "seche" ^(transparence, barres des taches, menus^).%COLOR_RESET%
echo %COLOR_WHITE%- Un redemarrage est necessaire pour tout voir ; reversible via le menu Activer.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_ANIMATIONS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous vraiment desactiver les animations ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_ANIMATIONS_RUN
cls
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des animations Windows...%COLOR_RESET%
echo.

:: VisualFXSetting=3 (Personnalise) pour que Windows utilise uniquement les cles
:: individuelles ci-dessous sans recalculer tous les effets (ce qui reset le menu Demarrer)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuAnimation /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v TooltipAnimation /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v SelectionFade /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v MenuFade /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v UserUIEffects /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v AnimateWindow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ComboboxAnimation /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v ListBoxSmoothScrolling /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1

:: Garder les options utiles actives (Police, Ombre icone, Drag content)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v IconsOnly /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "0" /f >nul 2>&1

:: Animation demarrage OFF
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1

:: Desactivation de l'animation de demarrage Windows
bcdedit /set bootuxdisabled on >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Animations Windows desactivees.%COLOR_RESET%
call :FINISH_ACTION "Animations" "desactivees"
exit /b

:MENU_IA_WIDGETS_RECALL
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER COPILOT / WIDGETS / RECALL (WINDOWS 11)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Ces fonctionnalites sont specifiques a Windows 11.%COLOR_RESET%
echo %COLOR_WHITE%Si vous etes sur Windows 10, ces options n'auront pas d'effet.%COLOR_RESET%
echo.
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
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_RED%Desactiver TOUT (Copilot + Widgets + Recall)%COLOR_RESET%
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
choice /C 123456DM /N /M "%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-6, D, M]: %COLOR_RESET%"
if !errorlevel! EQU 8 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 7 (
  call :DESACTIVER_TOUT_IA_WIDGETS_RECALL
  goto :MENU_IA_WIDGETS_RECALL
)
if !errorlevel! EQU 6 (
  call :DESACTIVER_RECALL_SECTION
  goto :MENU_IA_WIDGETS_RECALL
)
if !errorlevel! EQU 5 (
  call :ACTIVER_RECALL_SECTION
  goto :MENU_IA_WIDGETS_RECALL
)
if !errorlevel! EQU 4 (
  call :DESACTIVER_WIDGETS_SECTION
  goto :MENU_IA_WIDGETS_RECALL
)
if !errorlevel! EQU 3 (
  call :ACTIVER_WIDGETS_SECTION
  goto :MENU_IA_WIDGETS_RECALL
)
if !errorlevel! EQU 2 (
  call :DESACTIVER_COPILOT_SECTION
  goto :MENU_IA_WIDGETS_RECALL
)
call :ACTIVER_COPILOT_SECTION
goto :MENU_IA_WIDGETS_RECALL

:ACTIVER_COPILOT_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
call :CORE_ACTIVER_COPILOT
call :FINISH_IA_ACTION "Copilot" "active"
exit /b

:DESACTIVER_COPILOT_SECTION
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_COPILOT_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Copilot ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Copilot s'appuie sur des services cloud et peut%COLOR_RESET%
echo %COLOR_WHITE%consommer des ressources en arriere-plan pour les suggestions IA.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_COPILOT_RUN "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation de Copilot ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_COPILOT_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
call :CORE_DESACTIVER_COPILOT
call :FINISH_IA_ACTION "Copilot" "desactive"
exit /b

:CORE_ACTIVER_COPILOT
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour Copilot...%COLOR_RESET%
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 1 /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /f >nul 2>&1
:: Reactivation de Copilot dans Edge
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v "CopilotPageContext" /f >nul 2>&1
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
attrib -r "%HOSTS%" >nul 2>&1
powershell -NoProfile -Command "$h='%HOSTS%'; $s='# Copilot Block Start'; $e='# Copilot Block End'; if(Test-Path $h){ $c=Get-Content $h -Raw; if($c -match '(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)){ $c=$c -replace ('(?s)\r?\n?'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)), ''; Set-Content -Path $h -Value $c -Encoding ASCII -Force } }" >nul 2>&1
attrib +r "%HOSTS%" >nul 2>&1
set "HOSTS="
ipconfig /flushdns >nul 2>&1
exit /b

:CORE_DESACTIVER_COPILOT
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions Copilot...%COLOR_RESET%
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /t REG_SZ /d "FeatureIsDisabled" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableAgentWorkspaces /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v DisableRemoteAgentConnectors /t REG_DWORD /d 1 /f >nul 2>&1
:: Desactivation de Copilot dans Edge
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "CopilotPageContext" /t REG_DWORD /d 0 /f >nul 2>&1
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
attrib -r "%HOSTS%" >nul 2>&1
powershell -NoProfile -Command "$h='%HOSTS%'; $s='# Copilot Block Start'; $e='# Copilot Block End'; $nb=\"# Copilot Block Start`r`n0.0.0.0 copilot.microsoft.com`r`n0.0.0.0 windows.ai.microsoft.com`r`n0.0.0.0 copilot-telemetry.microsoft.com`r`n0.0.0.0 msedge.api.cdp.microsoft.com`r`n# Copilot Block End\"; if(Test-Path $h){ $c=Get-Content $h -Raw; if($c -match ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e))){ $c=$c -replace ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)), $nb } else { if($c.Trim().Length -gt 0){ $c=$c.TrimEnd()+\"`r`n`r`n\"+$nb } else { $c=$nb } } Set-Content -Path $h -Value $c -Encoding ASCII -Force }; if($?) { exit 0 } else { exit 1 }" >nul 2>&1
attrib +r "%HOSTS%" >nul 2>&1
set "HOSTS="
ipconfig /flushdns >nul 2>&1
exit /b

:ACTIVER_WIDGETS_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DES WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
call :CORE_ACTIVER_WIDGETS
call :FINISH_IA_ACTION "Widgets" "active"
exit /b

:DESACTIVER_WIDGETS_SECTION
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_WIDGETS_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver les Widgets ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : les widgets utilisent des ressources et du reseau%COLOR_RESET%
echo %COLOR_WHITE%pour afficher des actualites et la meteo en continu.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_WIDGETS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation des Widgets ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_WIDGETS_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DES WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
call :CORE_DESACTIVER_WIDGETS
call :FINISH_IA_ACTION "Widgets" "desactive"
exit /b

:CORE_ACTIVER_WIDGETS
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour les Widgets...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 1 /f >nul 2>&1
exit /b

:CORE_DESACTIVER_WIDGETS
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour les Widgets...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
exit /b

:ACTIVER_RECALL_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE RECALL%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
call :CORE_ACTIVER_RECALL
call :FINISH_IA_ACTION "Recall" "active"
exit /b

:DESACTIVER_RECALL_SECTION
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_RECALL_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Recall ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Recall enregistre votre activite ecran pour%COLOR_RESET%
echo %COLOR_WHITE%permettre des recherches IA ^(fort impact sur la confidentialite^).%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_RECALL_RUN "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation de Recall ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_RECALL_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE RECALL%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
call :CORE_DESACTIVER_RECALL
call :FINISH_IA_ACTION "Recall" "desactive"
exit /b

:CORE_ACTIVER_RECALL
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour Recall...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v "DisableClickToDo" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v "InsightsEnabled" /f >nul 2>&1
exit /b

:CORE_DESACTIVER_RECALL
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour Recall...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v Value /t REG_SZ /d "Deny" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Recall" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\Recall" /f >nul 2>&1
exit /b

:DESACTIVER_TOUT_IA_WIDGETS_RECALL
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_TOUT_IA_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Confirmer la desactivation TOTALE ^(Copilot + Widgets + Recall^) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Effet : suppression de toutes les fonctionnalites IA et widgets cloud.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_TOUT_IA_RUN "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous vraiment tout desactiver ? [O/N]: %COLOR_RESET%" EXITB
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_TOUT_IA_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION TOTALE IA / WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
call :CORE_DESACTIVER_COPILOT
call :CORE_DESACTIVER_WIDGETS
call :CORE_DESACTIVER_RECALL
call :FINISH_ACTION "Toutes les fonctions IA/Widgets" "desactivees"
exit /b

:FINISH_IA_ACTION
call :FINISH_ACTION "%~1" "%~2"
exit /b

:FINISH_ACTION
setlocal DisableDelayedExpansion
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%%~1 %~2%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser les changements.%COLOR_RESET%
echo.
if "%SKIP_PAUSE%"=="1" (
  endlocal
  exit /b
)
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Redemarrer maintenant ? [O/N]: %COLOR_RESET%"
if errorlevel 2 (
  endlocal
  exit /b
)
shutdown /r /t 5 /c "Redemarrage apres modification"
cls
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Redemarrage en cours...%COLOR_RESET%
timeout /t 5 /nobreak >nul
exit

:DESINSTALLER_ONEDRIVE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESINSTALLATION COMPLETE DE ONEDRIVE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi demander confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- OneDrive synchronise Documents/Bureau/Images vers le cloud Microsoft.%COLOR_RESET%
echo %COLOR_WHITE%- Le desinstaller coupe la sync et les liens vers le nuage ; Office peut perdre l'auto-save cloud.%COLOR_RESET%
echo %COLOR_WHITE%- Les chemins du dossier OneDrive (%USERPROFILE%\OneDrive) seront supprimes si presents.%COLOR_RESET%
echo %COLOR_WHITE%- Pratique pour liberer ressources et vie privee ; gardez une copie locale avant de valider.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%La suite arretera OneDrive, nettoiera registre et raccourcis, puis desinstallera.%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Cela peut prendre quelques instants.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desinstaller OneDrive ? [O/N]: %COLOR_RESET%"
if !errorlevel! EQU 2 goto :MENU_GESTION_WINDOWS

:: Arreter les processus OneDrive
taskkill /f /im OneDrive.exe >nul 2>&1
taskkill /f /im OneDriveSetup.exe >nul 2>&1
taskkill /f /im FileCoAuth.exe >nul 2>&1
taskkill /f /im FileSyncHelper.exe >nul 2>&1
taskkill /f /im OneDriveStandaloneUpdater.exe >nul 2>&1
timeout /t 3 /nobreak >nul
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 2 /nobreak >nul
start explorer.exe
timeout /t 3 /nobreak >nul

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Deconnexion des comptes OneDrive...%COLOR_RESET%
powershell -NoProfile -Command "try { Import-Module -Name Microsoft.PowerShell.Management -Force; Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts' -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1

:: Commande pour desinstaller OneDrive
if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
    "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" /uninstall
) else (
    "%SYSTEMROOT%\System32\OneDriveSetup.exe" /uninstall
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des cles de registre OneDrive...%COLOR_RESET%
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

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des taches planifiees OneDrive...%COLOR_RESET%
for /f "tokens=1 delims=," %%x in ('schtasks /query /fo csv 2^>nul ^| find "OneDrive"') do (
    set "TASKNAME=%%~x"
    set "TASKNAME=!TASKNAME:"=!"
    schtasks /delete /TN "!TASKNAME!" /f >nul 2>&1
)

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Desinstallation de OneDrive terminee (si installe).%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des dossiers OneDrive restants...%COLOR_RESET%
if exist "%LocalAppData%\Microsoft\OneDrive" rd "%LocalAppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%AppData%\Microsoft\OneDrive" rd "%AppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%SystemDrive%\OneDriveTemp" rd "%SystemDrive%\OneDriveTemp" /q /s >nul 2>&1
:: Chemins fixes
for %%C in (
    "%LocalAppData%\Microsoft\OneDrive\logs"
    "%LocalAppData%\Microsoft\OneDrive\settings"
) do (
    if exist "%%~C" rd "%%~C" /q /s >nul 2>&1
)
:: Wildcards : rd ne supporte pas les wildcards, il faut une enumeration for /d
for /d %%C in ("%LocalAppData%\Temp\OneDrive*") do rd "%%C" /q /s >nul 2>&1
for /d %%C in ("%Temp%\OneDrive*") do rd "%%C" /q /s >nul 2>&1
if exist "%USERPROFILE%\OneDrive" (
    takeown /f "%USERPROFILE%\OneDrive" /r /d y >nul 2>&1
    rd "%USERPROFILE%\OneDrive" /s /q >nul 2>&1
)
if exist "%LOCALAPPDATA%\Microsoft\OneDrive" (
    takeown /f "%LOCALAPPDATA%\Microsoft\OneDrive" /r /d y >nul 2>&1
    rd "%LOCALAPPDATA%\Microsoft\OneDrive" /s /q >nul 2>&1
)
if exist "%PROGRAMDATA%\Microsoft OneDrive" (
    takeown /f "%PROGRAMDATA%\Microsoft OneDrive" /r /d y >nul 2>&1
    rd "%PROGRAMDATA%\Microsoft OneDrive" /s /q >nul 2>&1
)
if exist "%SystemDrive%\OneDriveTemp" (
    takeown /f "%SystemDrive%\OneDriveTemp" /r /d y >nul 2>&1
    rd "%SystemDrive%\OneDriveTemp" /s /q >nul 2>&1
)

:: Supprimer les raccourcis OneDrive du menu Demarrer
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft OneDrive.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Links\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nettoyage complet de OneDrive termine.%COLOR_RESET%
call :FINISH_ACTION "OneDrive" "desinstalle"
goto :MENU_GESTION_WINDOWS

:DESINSTALLER_EDGE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESINSTALLATION COMPLETE DE MICROSOFT EDGE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_WHITE%Pourquoi demander confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Ce script retire Edge mais preserve WebView2.%COLOR_RESET%
echo %COLOR_WHITE%- Les applis qui utilisent WebView2 continuent generalement de fonctionner.%COLOR_RESET%
echo %COLOR_WHITE%- Windows Update peut tenter de reinstaller un navigateur de base ; comportement variable selon version.%COLOR_RESET%
echo %COLOR_WHITE%- Quelques fonctions Windows peuvent toutefois preferer Edge sur certaines versions.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%La desinstallation d'Edge est surtout un choix de preference / allegement.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le risque de compatibilite est plus limite tant que WebView2 reste present.%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desinstaller Microsoft Edge ? [O/N]: %COLOR_RESET%"
if !errorlevel! EQU 2 goto :MENU_GESTION_WINDOWS
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_WHITE% SUPPRESSION DES DONNEES UTILISATEUR%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_WHITE%Pourquoi une question separee :%COLOR_RESET%
echo %COLOR_WHITE%- Sans suppression, profils et caches restent sur le disque ^(reinstall ou autre navigateur^).%COLOR_RESET%
echo %COLOR_WHITE%- Avec suppression, favoris et mots de passe locaux peuvent etre perdus sans recuperation facile.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Voulez-vous supprimer les donnees utilisateur d'Edge ?
echo %COLOR_WHITE%- Historique de navigation%COLOR_RESET%
echo %COLOR_WHITE%- Cookies et donnees de sites%COLOR_RESET%
echo %COLOR_WHITE%- Favoris/Signets%COLOR_RESET%
echo %COLOR_WHITE%- Mots de passe sauvegardes%COLOR_RESET%
echo %COLOR_WHITE%- Extensions et themes%COLOR_RESET%
echo %COLOR_WHITE%- Parametres et preferences%COLOR_RESET%
echo.
choice /C ON /N /M "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de supprimer les donnees utilisateur Edge ? [O/N]: %COLOR_RESET%"
if !errorlevel! EQU 2 (
    set "SUPPR_DATA=0"
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Les donnees utilisateur seront preservees.%COLOR_RESET%
) else (
    set "SUPPR_DATA=1"
    echo %COLOR_YELLOW%[^!]%COLOR_RESET% Les donnees utilisateur seront supprimees.
)

echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Debut de la desinstallation...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Arret des processus Edge...%COLOR_RESET%
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression de l'icone Edge de la barre des taches...%COLOR_RESET%
:: Suppression ciblee des raccourcis Edge uniquement
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q >nul 2>&1
if exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" (
    powershell -NoProfile -Command "Get-ChildItem -Path \"$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk\" -ErrorAction SilentlyContinue | ForEach-Object { try { $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName); if ($sh.TargetPath -match 'msedge\.exe') { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue } } catch {} }" >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci Edge supprime (les autres icones sont preservees)%COLOR_RESET%

:: Desinstallation de Microsoft Edge
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Tentative de desinstallation de Microsoft Edge...%COLOR_RESET%
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" (
    pushd "%ProgramFiles(x86)%\Microsoft\Edge\Application" >nul 2>&1
    for /d %%i in (*) do (
        if exist "%%i\Installer\setup.exe" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Execution setup.exe...%COLOR_RESET%
            "%%i\Installer\setup.exe" --uninstall --system-level --verbose-logging --force-uninstall
        )
    )
    popd >nul 2>&1
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage force des dossiers programme...%COLOR_RESET%
rd "%ProgramFiles%\Microsoft\Edge" /s /q >nul 2>&1
rd "%ProgramFiles(x86)%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des cles de registre Edge...%COLOR_RESET%
reg delete "HKLM\Software\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\Software\Wow6432Node\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1

:: Gestion conditionnelle des donnees utilisateur
if "%SUPPR_DATA%"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des donnees utilisateur Edge...%COLOR_RESET%
    if exist "%LOCALAPPDATA%\Microsoft\Edge" rd "%LOCALAPPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    if exist "%APPDATA%\Microsoft\Edge" rd "%APPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur supprimees.%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Conservation des donnees utilisateur...%COLOR_RESET%
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\BrowserSwitcher" /f >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\PreferenceMACs" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur preservees.%COLOR_RESET%
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des donnees systeme communes...%COLOR_RESET%
rd "%PROGRAMDATA%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des raccourcis...%COLOR_RESET%
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%PUBLIC%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des associations de fichiers...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Classes\MSEdgeHTM" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\MSEdgePDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Applications\msedge.exe" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage de l'index de recherche Windows...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_http" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_https" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage du menu demarrer...%COLOR_RESET%
rd "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
rd "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage du cache d'icones Edge...%COLOR_RESET%
del "%LOCALAPPDATA%\IconCache.db" /f /q >nul 2>&1
del "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" /f /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des references Edge dans MUI Cache...%COLOR_RESET%
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Blocage des reinstallations automatiques (WebView2 preserve)...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "PreventFirstRunPage" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification finale...%COLOR_RESET%
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
) else (
    if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        echo %COLOR_RED%[-]%COLOR_RESET% Edge n'a pas pu etre completement desinstalle.
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Microsoft Edge desinstalle avec succes !%COLOR_RESET%
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Icone supprimee de la barre des taches !%COLOR_RESET%
        if "%SUPPR_DATA%"=="1" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur supprimees.%COLOR_RESET%
        ) else (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur conservees.%COLOR_RESET%
        )
    )
)

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo  %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Microsoft Edge a ete desinstalle completement.%COLOR_RESET%
if "%SUPPR_DATA%"=="0" (
    echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Vos favoris, mots de passe et historique ont ete preserves.%COLOR_RESET%
)
echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%L'icone Edge a ete supprimee de la barre des taches.%COLOR_RESET%
set "SUPPR_DATA="
call :FINISH_ACTION "Microsoft Edge" "desinstalle"
goto :MENU_GESTION_WINDOWS

:OUTIL_ACTIVATION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% OUTIL D'ACTIVATION WINDOWS / OFFICE (MAS)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Lancement de l'outil d'activation...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Veuillez suivre les instructions a l'ecran.%COLOR_RESET%
powershell "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://get.activated.win | iex"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Outil d'activation termine.%COLOR_RESET%
pause
goto :MENU_PRINCIPAL

:OUTIL_CHRIS_TITUS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% OUTIL CHRIS TITUS TECH (WINUTIL)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Lancement de l'outil Chris Titus Tech...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Veuillez suivre les instructions a l'ecran.%COLOR_RESET%
powershell "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1 | iex"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Outil Chris Titus Tech termine.%COLOR_RESET%
pause
goto :MENU_PRINCIPAL

:CREER_POINT_RESTAURATION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_WHITE% Creation d'un point de restauration%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification et activation de la restauration systeme si necessaire...%COLOR_RESET%
:: Verifie uniquement la cle registre DisableSR (SystemRestore.GetDiskList WMI n'existe pas)
:: Si DisableSR=1, SR est desactive globalement et la creation de point echouera : on reactive
powershell -NoProfile -Command "$p = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -ErrorAction SilentlyContinue; if ($null -ne $p -and $p.DisableSR -eq 1) { exit 1 } else { exit 0 }" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la restauration systeme...%COLOR_RESET%
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /t REG_DWORD /d 1 /f >nul 2>&1
    powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive 'C:' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
    timeout /t 2 /nobreak >nul
)
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Creation d'un point de restauration en cours...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Cette operation peut prendre 30-60 secondes...%COLOR_RESET%
echo.

:: Creation du point de restauration (appel synchrone : plus fiable que Start-Job pour Checkpoint-Computer)
:: Horodatage independant de la locale Windows (evite dim.-22-03_... avec %%DATE%% en francais)
:: Ne pas entourer le format de quotes simples : le FOR / ('...') de CMD s'arrete a la premiere '
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d 0 /f >nul 2>&1
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "RP_TIMESTAMP=%%a"
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; try { $desc = 'Optimizations_%RP_TIMESTAMP%'; Checkpoint-Computer -Description $desc -RestorePointType 'MODIFY_SETTINGS'; exit 0 } catch { exit 1 }" >nul 2>&1
if %errorlevel% EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Point de restauration cree avec succes.%COLOR_RESET%
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nom : Optimizations_%RP_TIMESTAMP%%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de la creation du point de restauration.%COLOR_RESET%
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Raison possible : restauration desactivee, espace disque insuffisant ou strategie groupe.%COLOR_RESET%
)
set "RP_TIMESTAMP="
pause
goto :MENU_PRINCIPAL

:NETTOYAGE_AVANCE_WINDOWS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                 NETTOYAGE DE WINDOWS AVANCE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Analyse espace initial
for /f %%a in ('powershell -nologo -command "[int]((Get-PSDrive -Name C).Free / 1MB)"') do set "SPACE_BEFORE_MB=%%a"
if not defined SPACE_BEFORE_MB set "SPACE_BEFORE_MB=0"

echo %COLOR_YELLOW%[^!]%COLOR_RESET% AVERTISSEMENT :
echo %COLOR_WHITE%  Ce script va supprimer : fichiers temporaires, logs, caches,%COLOR_RESET%
echo %COLOR_WHITE%  rapports d'erreurs, corbeille, et anciens pilotes dupliques.%COLOR_RESET%
echo.
choice /C ON /N /M "%COLOR_YELLOW%Continuer ? [O/N]: %COLOR_RESET%"
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                 NETTOYAGE DE WINDOWS AVANCE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Initialiser la barre de progression (18 etapes)
set /a "CLEAN_TOTAL=18"
set /a "CLEAN_STEP=0"

:: ETAPE 1
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires utilisateur"
del /s /q /f "%temp%\*.*" >nul 2>&1
for /d %%d in ("%temp%\*") do rd /s /q "%%d" >nul 2>&1

:: ETAPE 2
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires Windows"
del /s /q /f "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" >nul 2>&1

:: ETAPE 3
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs systeme"
del /s /q /f "%SystemRoot%\Logs\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\LogFiles\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Panther\*.log" >nul 2>&1

:: ETAPE 4
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers de crash"
del /s /q /f "%SystemRoot%\Minidump\*.*" >nul 2>&1
del /q /f "%SystemRoot%\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\memory.dmp" >nul 2>&1

:: ETAPE 5
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Rapports d'erreurs et Telemetrie"
rd /s /q "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
if not exist "%ProgramData%\Microsoft\Windows\WER" md "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft\Diagnosis" >nul 2>&1
if not exist "%ProgramData%\Microsoft\Diagnosis" md "%ProgramData%\Microsoft\Diagnosis" >nul 2>&1

:: ETAPE 6
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Update & SoftwareDistribution"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptsvc >nul 2>&1
timeout /t 2 /nobreak >nul
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
rd /s /q "%SystemRoot%\SoftwareDistribution\DataStore" >nul 2>&1
rd /s /q "%SystemRoot%\SoftwareDistribution\PostRebootEventCache" >nul 2>&1
del /s /q /f "%SystemRoot%\SoftwareDistribution\ReportingEvents.log" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\DataStore" >nul 2>&1
:: Nettoyage Delivery Optimization (WUDO)
if exist "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" (
    rd /s /q "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
    md "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
)
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
net start cryptsvc >nul 2>&1

:: ETAPE 7
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Corbeille"
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

:: ETAPE 8
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers Prefetch"
del /s /q /f "%SystemRoot%\Prefetch\*.*" >nul 2>&1

:: ETAPE 9
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux CBS/DISM"
del /s /q /f "%SystemRoot%\Logs\CBS\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.log" >nul 2>&1

:: ETAPE 10
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache de polices"
net stop FontCache >nul 2>&1
timeout /t 1 /nobreak >nul
del /s /q /f "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /q /f "%SystemRoot%\System32\FNTCACHE.DAT" >nul 2>&1
net start FontCache >nul 2>&1

:: ETAPE 11
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Store"
powershell -NoProfile -Command "Get-ChildItem -Path \"$env:LOCALAPPDATA\Packages\" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Edge|WebView|Microsoft\.Windows' } | ForEach-Object { Remove-Item -Path \"$($_.FullName)\AC\INetCache\*\" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path \"$($_.FullName)\AC\Temp\*\" -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1

:: ETAPE 12
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache DNS"
ipconfig /flushdns >nul 2>&1

:: ETAPE 13
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux Event Viewer"
for /f "tokens=*" %%G in ('wevtutil el 2^>nul ^| findstr /v /i /c:"{54849625-5478-4994-a5ba-3e3b0328c30d}" /c:"{bf022046-1f4a-4b91-8a96-bcdb4d6c39f1}"') do wevtutil cl "%%G" >nul 2>&1

:: ETAPE 14
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Dossier Windows.old"
if exist "%SystemDrive%\Windows.old" (
    takeown /f "%SystemDrive%\Windows.old" /r /d y >nul 2>&1
    icacls "%SystemDrive%\Windows.old" /grant administrators:F /t >nul 2>&1
    rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
)

:: ETAPE 15
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation disque (TRIM/Defrag)"
defrag %SystemDrive% /O /H >nul 2>&1

:: ETAPE 16
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Nettoyage Windows Cleanmgr"
set "SAGEID=100"
for %%K in ("Active Setup Temp Folders" "BranchCache" "Content Indexer Cleaner" "Delivery Optimization Files" "Device Driver Packages" "Diagnostic Data Viewer database files" "Downloaded Program Files" "GameNewsFiles" "GameStatisticsFiles" "GameUpdateFiles" "Language Pack" "Memory Dump Files" "Offline Pages Files" "Old ChkDsk Files" "Previous Installations" "Recycle Bin" "RetailDemo Offline Content" "Service Pack Cleanup" "Setup Log Files" "System error memory dump files" "System error minidump files" "Temporary Files" "Temporary Setup Files" "Temporary Sync Files" "Thumbnail Cache" "Update Cleanup" "Upgrade Discarded Files" "User file versions" "Windows Defender" "Windows Error Reporting Archive Files" "Windows Error Reporting Files" "Windows Error Reporting Queue Files" "Windows Error Reporting System Archive Files" "Windows Error Reporting System Queue Files" "Windows Error Reporting Temp Files" "Windows ESD installation files" "Windows Upgrade Log Files") do (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v StateFlags%SAGEID% /t REG_DWORD /d 2 /f >nul 2>&1
)
cleanmgr /sagerun:%SAGEID% /d C: >nul 2>&1
powershell -NoProfile -Command "$waitCount=0; while((Get-Process cleanmgr -ErrorAction SilentlyContinue) -and ($waitCount -lt 120)){ Start-Sleep -s 1; $waitCount++ }" >nul 2>&1

:: ETAPE 17
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache de Manifest (WinSxS)"
del /s /q /f "%SystemRoot%\WinSxS\ManifestCache\*.*" >nul 2>&1

:: ETAPE 18
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires profil systeme"
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\*.tmp" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\*.*" >nul 2>&1

:: Calcul final (PowerShell pour la precision des decimales)
for /f "tokens=1-3" %%a in ('powershell -NoProfile -Command "$before=[long]%SPACE_BEFORE_MB% * 1024 * 1024; $after=(Get-PSDrive C).Free; $freed=$after-$before; if($freed -lt 0){$freed=0}; $beforeGB=[math]::Round($before/1GB, 2); $afterGB=[math]::Round($after/1GB, 2); $freedGB=[math]::Round($freed/1GB, 2); Write-Output \"$beforeGB $afterGB $freedGB\""') do (
    set "SPACE_BEFORE_GB=%%a"
    set "SPACE_AFTER_GB=%%b"
    set "SPACE_FREED_GB=%%c"
)

set "CLEAN_STEP="
set "CLEAN_TOTAL="

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Nettoyage de Windows termine%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo   %COLOR_WHITE%Espace avant :%COLOR_RESET% %COLOR_YELLOW%%SPACE_BEFORE_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace apres :%COLOR_RESET% %COLOR_GREEN%%SPACE_AFTER_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace gagne :%COLOR_RESET% %COLOR_CYAN%%SPACE_FREED_GB% Go%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser.%COLOR_RESET%
echo.
choice /C ON /N /M "%COLOR_YELLOW%Redemarrer maintenant ? [O/N]: %COLOR_RESET%"
if !errorlevel! EQU 1 (
    shutdown /r /t 10 /c "Redemarrage pour finaliser le nettoyage"
    cls
    echo.
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Redemarrage en cours...%COLOR_RESET%
    timeout /t 10 /nobreak >nul
    exit
)
set "SAGEID="
set "SPACE_BEFORE_MB="
set "SPACE_BEFORE_GB="
set "SPACE_AFTER_GB="
set "SPACE_FREED_GB="
goto :MENU_PRINCIPAL


:INSTALLER_VISUAL_REDIST
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% INSTALLATION DES RUNTIMES Visual C++%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Detection des versions installees (V14 - 2015-2022)...%COLOR_RESET%

:: Initialisation
set VC2015X86=0
set VC2015X64=0

:: Detection DLL : vcruntime140.dll (VC++ 2015 base) ET vcruntime140_1.dll (VS2019+)
:: vcruntime140_1.dll est ajoutee a partir de VS 2017 update 8 / VS 2019.
:: Si elle manque alors que 140.dll existe, le redist VC++ 2015-2017 ancien est present et doit etre reinstalle
if exist "%SystemRoot%\System32\vcruntime140.dll" if exist "%SystemRoot%\System32\vcruntime140_1.dll" set VC2015X64=1
if exist "%SystemRoot%\SysWOW64\vcruntime140.dll" if exist "%SystemRoot%\SysWOW64\vcruntime140_1.dll" set VC2015X86=1

:: Fallback registry pour les versions manquantes
set "REG_DUMP=%TEMP%\vc_uninstall_dump.txt"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s > "%REG_DUMP%" 2>nul
reg query "HKLM\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" /s >> "%REG_DUMP%" 2>nul

if %VC2015X64%==0 type "%REG_DUMP%" | findstr /I /C:"Visual C++" | findstr /I /C:"2015" /C:"2017" /C:"2019" /C:"2022" | findstr /I /C:"x64" /C:"X64" >nul 2>&1 && set VC2015X64=1
if %VC2015X86%==0 type "%REG_DUMP%" | findstr /I /C:"Visual C++" | findstr /I /C:"2015" /C:"2017" /C:"2019" /C:"2022" | findstr /I /C:"x86" /C:"X86" >nul 2>&1 && set VC2015X86=1

:: Compter combien sont deja installes
set /a "VCINSTALLED_COUNT=%VC2015X86%+%VC2015X64%"

echo.
echo %COLOR_WHITE%Versions detectees (V14):%COLOR_RESET% %COLOR_GREEN%%VCINSTALLED_COUNT%/2%COLOR_RESET%

:: Si tout est deja installe, afficher message et retourner
if %VCINSTALLED_COUNT%==2 (
    echo.
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Toutes les versions V14 sont deja installees.%COLOR_RESET%
    if exist "%REG_DUMP%" del /f /q "%REG_DUMP%" >nul 2>&1
    set "VC2015X86="
    set "VC2015X64="
    set "VCINSTALLED_COUNT="
    set "REG_DUMP="
    if "%SKIP_PAUSE%"=="0" (
        echo.
        pause
    )
    goto :INSTALLER_DIRECTX_SECTION
)

:: Suite : installation des paquets VC++ manquants (flux sequentiel, pas de goto vers ce point)
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Installation des versions manquantes...%COLOR_RESET%
set /a "VC_TO_INSTALL=2-VCINSTALLED_COUNT"
echo %COLOR_WHITE%Packages a installer:%COLOR_RESET% %COLOR_YELLOW%%VC_TO_INSTALL%%COLOR_RESET%
echo.

:: Initialiser la barre de progression (2 packages au total)
set /a "VC_TOTAL=2"
set /a "VC_STEP=0"
set /a "VCINSTALL=0"

:: Creer un dossier temporaire pour les installations
set "VCREDIST_DIR=%TEMP%\VCRedistInstall"
if not exist "%VCREDIST_DIR%" mkdir "%VCREDIST_DIR%"

:: VC++ 2015-2022 x86
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "VC++ 2015-2022 x86"
if %VC2015X86%==0 (
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; try { Invoke-WebRequest -Uri 'https://aka.ms/vc14/vc_redist.x86.exe' -OutFile '%VCREDIST_DIR%\vc2015x86.exe' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
    if !errorlevel! NEQ 0 (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de VC++ 2015-2022 x86.%COLOR_RESET%
    ) else (
        start /wait "" "%VCREDIST_DIR%\vc2015x86.exe" /q /norestart >nul 2>&1
        if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%VC++ 2015-2022 x86 : installateur a retourne le code !errorlevel!^(!COLOR_RESET%
    )
)

:: VC++ 2015-2022 x64
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "VC++ 2015-2022 x64"
if %VC2015X64%==0 (
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13; try { Invoke-WebRequest -Uri 'https://aka.ms/vc14/vc_redist.x64.exe' -OutFile '%VCREDIST_DIR%\vc2015x64.exe' -UseBasicParsing -ErrorAction Stop } catch { exit 1 }" >nul 2>&1
    if !errorlevel! NEQ 0 (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de VC++ 2015-2022 x64.%COLOR_RESET%
    ) else (
        start /wait "" "%VCREDIST_DIR%\vc2015x64.exe" /q /norestart >nul 2>&1
        if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%VC++ 2015-2022 x64 : installateur a retourne le code !errorlevel!^(!COLOR_RESET%
    )
)
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification des installations...%COLOR_RESET%

:: Re-detection des DLLs apres installation
set VC2015X86_NEW=0
set VC2015X64_NEW=0

if exist "%SystemRoot%\System32\vcruntime140.dll" if exist "%SystemRoot%\System32\vcruntime140_1.dll" set VC2015X64_NEW=1
if exist "%SystemRoot%\SysWOW64\vcruntime140.dll" if exist "%SystemRoot%\SysWOW64\vcruntime140_1.dll" set VC2015X86_NEW=1

:: Calculer les vrais comptes
set /a "VCINSTALL=%VC2015X86_NEW%+%VC2015X64_NEW%"

echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% Verification terminee - %COLOR_GREEN%%VCINSTALL%/2%COLOR_RESET% versions presentes
timeout /t 3 /nobreak >nul

:: Nettoyage des fichiers temporaires
if exist "%VCREDIST_DIR%" rd /s /q "%VCREDIST_DIR%" >nul 2>&1
if exist "%REG_DUMP%" del /f /q "%REG_DUMP%" >nul 2>&1
set "VC_STEP="
set "VC_TOTAL="
set "VCREDIST_DIR="
set "VC_TO_INSTALL="
set "VC2015X86="
set "VC2015X64="
set "VC2015X86_NEW="
set "VC2015X64_NEW="
set "VCINSTALL="
set "VCINSTALLED_COUNT="
set "REG_DUMP="

:INSTALLER_DIRECTX_SECTION
:: Ancien label :SKIP_DIRECTX renomme : c'est l'entree de la section DirectX,
:: atteinte soit depuis le menu, soit depuis :INSTALLER_VISUAL_REDIST si VC++ deja installe
cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% INSTALLATION DE DIRECTX RUNTIME (JUNE 2010)%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :INSTALLER_DIRECTX

if "%SKIP_PAUSE%"=="0" (
    echo.
    pause
)
exit /b

:INSTALLER_DIRECTX
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de l'installation de DirectX...%COLOR_RESET%

:: Detection de DirectX June 2010 (XAudio2_7.dll est un bon indicateur)
set "DX_INSTALLED=0"
if exist "%SystemRoot%\System32\XAudio2_7.dll" set "DX_INSTALLED=1"

if "%DX_INSTALLED%"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX June 2010 est deja installe sur ce systeme.%COLOR_RESET%
    set "DX_INSTALLED="
    set "DX_TEMP="
    exit /b
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Preparation de l'installation...%COLOR_RESET%
set "DX_TEMP=%TEMP%\DirectXInstall"
if exist "%DX_TEMP%" rd /s /q "%DX_TEMP%" >nul 2>&1
mkdir "%DX_TEMP%"

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Telechargement de DirectX Redist June 2010 (95 Mo)...%COLOR_RESET%
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-407C-8860-0207A3D7AF32/directx_Jun2010_redist.exe' -OutFile '%DX_TEMP%\directx_redist.exe' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if %errorlevel% NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de DirectX.%COLOR_RESET%
    rd /s /q "%DX_TEMP%" >nul 2>&1
    set "DX_INSTALLED="
    set "DX_TEMP="
    exit /b
)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Extraction des fichiers...%COLOR_RESET%
:: Utiliser l'extracteur integre de DirectX si possible, ou fallback
"%DX_TEMP%\directx_redist.exe" /Q /T:"%DX_TEMP%" >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Installation silencieuse en cours...%COLOR_RESET%
if exist "%DX_TEMP%\DXSETUP.exe" (
    start /wait "" "%DX_TEMP%\DXSETUP.exe" /silent >nul 2>&1
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX June 2010 installe avec succes.%COLOR_RESET%
    ) else (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%DXSETUP a retourne le code !errorlevel! - installation peut etre incomplete.%COLOR_RESET%
    )
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Une erreur est survenue lors de l'extraction.%COLOR_RESET%
)

:: Nettoyage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des fichiers temporaires...%COLOR_RESET%
rd /s /q "%DX_TEMP%" >nul 2>&1

set "DX_INSTALLED="
set "DX_TEMP="
exit /b


:SUPPRIMER_BLOATWARES
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SUPPRESSION DES BLOATWARES (APPS UWP)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section supprime les applications preinstallees inutiles%COLOR_RESET%
echo %COLOR_WHITE%  tout en preservant les outils essentiels (Calculatrice, Store, Photos, Notes).%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Sont supprimes : News, Solitaire, Skype, People, Family, Candy Crush, Your Phone, Assistance, Maps, Office, Feedback...
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% Sont gardes   : Courrier, Meteo, Musique, Video, Calculatrice, Store, Photos, Notes, etc.
echo.
choice /C ON /N /M "%COLOR_YELLOW%Voulez-vous supprimer les bloatwares ? [O/N]: %COLOR_RESET%"
if !errorlevel! EQU 2 goto :MENU_GESTION_WINDOWS

echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des applications en cours (PowerShell)...%COLOR_RESET%
powershell -NoProfile -Command "$apps = @('Microsoft.BingNews', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.SkypeApp', 'Microsoft.FeedbackHub', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.OneConnect', 'Microsoft.WindowsMaps', 'Microsoft.MixedReality.Portal', 'Microsoft.People', 'Microsoft.Family', 'Microsoft.YourPhone', 'King.CandyCrushSaga', 'King.CandyCrushSodaSaga', 'Microsoft.QuickAssist'); $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; foreach ($app in $apps) { Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; if ($prov) { $prov | Where-Object {$_.PackageName -match $app} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Suppression des bloatwares terminee.%COLOR_RESET%
pause
goto :MENU_GESTION_WINDOWS

:END_SCRIPT
:: Sans expansion retardee : evite que les "!" dans les textes ([^!], AU REVOIR!, etc.) cassent la fin du script
setlocal DisableDelayedExpansion
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% AU REVOIR! %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Merci d'avoir utilise le script d'optimisation! %COLOR_RESET%
echo %COLOR_YELLOW%[^!]%COLOR_RESET% %COLOR_WHITE%N'oubliez pas de redemarrer votre PC pour finaliser l'optimisation.%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
timeout /t 3 /nobreak >nul
:: Ferme le setlocal DisableDelayedExpansion ouvert au debut de :END_SCRIPT
endlocal
:: Ferme le setlocal EnableDelayedExpansion global (ligne 5)
endlocal
exit /b 0

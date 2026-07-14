@echo off
cls
:: IMPORTANT : textes SANS ACCENTS (ASCII) pour affichage fiable en console cmd.exe
:: Ne pas utiliser chcp 65001 (UTF-8 casse l'affichage des .cmd sous Windows)
setlocal EnableDelayedExpansion

:: Assurer un repertoire de travail local valide (evite l'erreur "lecteur introuvable" lors d'une elevation de privileges)
cd /d "%SystemDrive%"

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
    REM Methode alternative via CMD escape sequence
    for /f %%a in ('"prompt $E ^& echo on & for %%b in (1) do rem"') do set "ESC=%%a"
)

:: Fallback ultime : utiliser une variable vide si tout echoue (les couleurs ne s'afficheront pas mais le script fonctionnera)
if not defined ESC set "ESC="

:: Couleurs et Styles
if not "%ESC%"=="" (
    REM ANSI supporte : ESC defini -> couleurs fonctionnelles
    set "COLOR_GREEN=%ESC%[32m" & set "COLOR_YELLOW=%ESC%[33m" & set "COLOR_RED=%ESC%[31m"
    set "COLOR_CYAN=%ESC%[36m"  & set "COLOR_WHITE=%ESC%[37m"  & set "COLOR_BLUE=%ESC%[34m"
    set "COLOR_MAGENTA=%ESC%[35m" & set "COLOR_RESET=%ESC%[0m" & set "STYLE_BOLD=%ESC%[1m"
) else (
    REM Terminal sans ANSI : couleurs vides -> aucun litteral [0m] ou [36m visible
    set "COLOR_GREEN=" & set "COLOR_YELLOW=" & set "COLOR_RED="
    set "COLOR_CYAN="  & set "COLOR_WHITE="  & set "COLOR_BLUE="
    set "COLOR_MAGENTA=" & set "COLOR_RESET=" & set "STYLE_BOLD="
)

:: =================================================================================
:: INITIALISATION DES VARIABLES GLOBALES
:: =================================================================================
set "HAS_INTERNET=0"
:: PROFIL_USAGE : 0 = Gaming (latence reduite, tweaks reseau/souris agressifs)
::               1 = Normal (bureautique, multimedia, ajustements equilibres)
:: PROFIL_POWER : 0 = MaxPerf   (plan Ultimate Performance, economies d'energie coupees)
::               1 = Eco       (plan Equilibre, autonomie/stabilite preservees)
:: REGLE DE PROPRIETE : latence applicative -> USAGE ; energie/NIC power/plan-alim -> POWER.
:: Exception : RSC/LSO ne sont coupes qu'en Gaming+MaxPerf pour preserver le debit en Normal/Eco.
:: Flag composite (derive par :INIT_PROFILS) : IS_GAMING_ECO (Gaming + Eco = laptop gamer sur batterie).
:: DETECTE_PORTABLE garde le type materiel reel detecte au demarrage.
set "PROFIL_USAGE=0"
set "PROFIL_POWER=0"
set "IS_GAMING_ECO=0"
set "DETECTE_PORTABLE=0"
set "HAS_NVIDIA=0"
set "DESACTIVER_SECURITE=0"
set "DESACTIVER_DEFENDER=0"
set "DESACTIVER_ANIMATIONS=0"
set "DESACTIVER_IA=0"
set "DESACTIVER_UAC=0"
set "SKIP_PAUSE=0"
set "AIO_MODE=0"
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

:: =================================================================================
:: CONVENTION DES INDICATEURS ET COULEURS
:: =================================================================================
:: [*]         JAUNE = Action en cours d'execution
:: [OK]        VERT  = Action terminee avec succes
:: [TERMINE]   VERT  = Section completee
:: [INFO]      JAUNE = Information / Conseil
:: [SKIP]      CYAN  = Action ignoree volontairement / non applicable
:: Note : [*] est aussi reutilise pour les avertissements (meme couleur jaune)
:: [-]         ROUGE = Suppression / Action negative
:: [ERREUR]    ROUGE = Erreur critique / Echec
:: [ATTENTION] ROUGE = Risque de securite
:: =================================================================================


:: CHARGEMENT DU SCRIPT
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                     INITIALISATION DU SCRIPT D'OPTIMISATION                     %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

set /a "LOAD_TOTAL=5"
set /a "LOAD_STEP=0"

:: Etape 1 : Privileges
set /a "LOAD_STEP+=1"
call :PROGRESS_BAR %LOAD_STEP% %LOAD_TOTAL% "Verification des privileges administrateur"
:: Verification des privileges via le jeton UAC (independante du service Serveur utilise par net session)
powershell -NoProfile -Command "if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
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

:: Ecran d'information (1 fois par session)
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%                         WINDOWS OPTIMIZER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE% COMMENT CA MARCHE%COLOR_RESET%
echo.
echo %COLOR_YELLOW%  [1]%COLOR_RESET% %COLOR_WHITE%Choisissez votre usage :%COLOR_RESET% %COLOR_GREEN%GAMING%COLOR_RESET% %COLOR_WHITE%ou%COLOR_RESET% %COLOR_CYAN%NORMAL%COLOR_RESET%
echo %COLOR_YELLOW%  [2]%COLOR_RESET% %COLOR_WHITE%Choisissez l'energie :%COLOR_RESET%  %COLOR_GREEN%PERFORMANCE MAX%COLOR_RESET% %COLOR_WHITE%ou%COLOR_RESET% %COLOR_CYAN%ECO%COLOR_RESET%
echo %COLOR_YELLOW%  [3]%COLOR_RESET% %COLOR_WHITE%Lancez une section, ou utilisez%COLOR_RESET% %STYLE_BOLD%%COLOR_GREEN%[O] TOUT OPTIMISER%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Les choix recommandes sont indiques pendant le parcours automatique.%COLOR_RESET%
echo %COLOR_WHITE%  Chaque option sensible reste expliquee et soumise a votre confirmation.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_BLUE% COMMANDES DU CLAVIER%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_RED%  [IMPORTANT] UTILISATION DES CHIFFRES%COLOR_RESET%
echo %COLOR_WHITE%  Pour utiliser les chiffres situes en haut du clavier :%COLOR_RESET%
echo %COLOR_GREEN%    AVEC MAJ  %COLOR_RESET% %COLOR_WHITE%Maintenez MAJ, puis appuyez sur%COLOR_RESET% %STYLE_BOLD%%COLOR_GREEN%1 2 3 4 5 6 7 8 9 0%COLOR_RESET%
echo %COLOR_RED%    SANS MAJ  %COLOR_RESET% %COLOR_WHITE%Le symbole de la touche est saisi et%COLOR_RESET% %COLOR_RED%le menu emet un bip.%COLOR_RESET%
echo %COLOR_CYAN%    PAVE NUM. %COLOR_RESET% %COLOR_WHITE%Les chiffres fonctionnent directement, sans MAJ.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_YELLOW%  [R] CONSEILLE%COLOR_RESET% %COLOR_WHITE%Creer un point de restauration avant les changements.%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_YELLOW%                 Appuyez sur une touche pour ouvrir le menu%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
pause >nul

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
:: Parametre optionnel : 1 = conserver les profils deja choisis par l'utilisateur
set "HW_OS=Windows" & set "HW_CPU=Inconnu" & set "HW_GPU=Inconnu" & set "HW_RAM=?" & set "HAS_NVIDIA=0"
if not "%~1"=="1" (
    set "PROFIL_USAGE=0"
    set "PROFIL_POWER=0"
    set "DETECTE_PORTABLE=0"
)
:: Detection materiel en une seule commande pour eviter les scripts temporaires fragiles en CMD.
set "WINOPT_HW_FILE=%TEMP%\hw_info_%RANDOM%_%RANDOM%.tmp"
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor; $v=Get-CimInstance Win32_VideoController; $m=Get-CimInstance Win32_PhysicalMemory; if(-not $m){$m=Get-CimInstance Win32_ComputerSystem}; $b=0; $lc=8,9,10,11,14,30,31,32; $enc=Get-CimInstance Win32_SystemEnclosure -EA SilentlyContinue; if($enc -and $enc.ChassisTypes){foreach($t in $enc.ChassisTypes){if($lc -contains $t){$b=1;break}}}; if(-not $b -and (Get-CimInstance Win32_Battery -EA SilentlyContinue)){$b=1}; $res=@(); $cap=$o.Caption; if(-not $cap){$pn=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName; if($pn){$cap=$pn}else{$cap='Windows'}}; $res+='OS:'+$cap+' ('+$o.Version+')'; if($c){$res+='CPU:'+$c.Name.Trim()}; if($v){$gn=@($v|Where-Object{$_.Name -and $_.Name -notmatch 'Parsec|Virtual Display|Microsoft Basic|Remote|Indirect|Mirror'}|ForEach-Object{$_.Name.Trim()}|Select-Object -Unique); if(-not $gn.Count){$gn=@($v|ForEach-Object{$_.Name.Trim()})}; $res+='GPU:'+($gn -join ' / ')}; if($m.Capacity){$t=($m|Measure-Object Capacity -Sum).Sum; $res+='RAM:'+[math]::Round($t/1GB,0)}elseif($m.TotalPhysicalMemory){$res+='RAM:'+[math]::Round($m.TotalPhysicalMemory/1GB,0)}; $res+='LAPTOP:'+$b; [System.IO.File]::WriteAllLines($env:WINOPT_HW_FILE, $res)" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%Erreur lors de la detection du materiel. Valeurs par defaut utilisees.%COLOR_RESET%
)
if exist "%WINOPT_HW_FILE%" (
    for /f "usebackq tokens=1* delims=:" %%a in ("%WINOPT_HW_FILE%") do (
        if /i "%%a"=="OS" set "HW_OS=%%b"
        if /i "%%a"=="CPU" set "HW_CPU=%%b"
        if /i "%%a"=="GPU" set "HW_GPU=%%b"
        if /i "%%a"=="RAM" set "HW_RAM=%%b"
        if /i "%%a"=="LAPTOP" (
            if not "%~1"=="1" (
                if "%%b"=="1" set "PROFIL_POWER=1"
            )
            set "DETECTE_PORTABLE=%%b"
        )
    )
    del "%WINOPT_HW_FILE%" >nul 2>&1
)
set "WINOPT_HW_FILE="
:: Detection intelligente NVIDIA : verifie que le GPU est physique (pas un GPU virtuel de VM)
set "HAS_NVIDIA=0"
echo !HW_GPU! | findstr /i "NVIDIA" >nul && (
    for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try { $v=Get-CimInstance Win32_VideoController | Where-Object { $_.Name -match 'NVIDIA' -and $_.Name -notmatch 'Virtual|Parsec|Remote|Indirect|Mirror|Microsoft Basic' }; if(-not $v){ '0'; exit }; $m=Get-CimInstance Win32_ComputerSystem; if($m.Model -match 'Virtual|VMware|VirtualBox|KVM|QEMU|Xen|Parallels'){ '0'; exit }; '1' } catch { '0' }"`) do set "HAS_NVIDIA=%%V"
    if not defined HAS_NVIDIA set "HAS_NVIDIA=0"
    if not "!HAS_NVIDIA!"=="1" set "HAS_NVIDIA=0"
)
if /i "%HW_OS%"=="Windows" for /f "tokens=2 delims=[]" %%i in ('ver') do set "HW_OS=%%i"
exit /b

:: =================================================================================
:: INIT_PROFILS - Point de verite unique pour les profils
:: =================================================================================
:: Centralise la normalisation des 2 axes de profil et derive les flags composites
:: consommes par les sections d'optimisation. A appeler en tete de chaque section.
::
:: AXES (definis par l'utilisateur dans :TOUT_OPTIMISER, ou deduits ici) :
::   PROFIL_USAGE : 0 = Gaming (latence reduite) | 1 = Normal (bureautique/creation)
::   PROFIL_POWER : 0 = MaxPerf (perf max)        | 1 = Eco (autonomie/stabilite)
::
:: REGLE DE PROPRIETE (1 seul axe pilote chaque setting) :
::   - Latence applicative (input/I/O/stack TCP Nagle) -> PROFIL_USAGE
::   - Energie / NIC power / plan alim                -> PROFIL_POWER
::   - Exception RSC/LSO : OFF seulement en Gaming+MaxPerf, ON en Normal/Eco
:: =================================================================================
:INIT_PROFILS
if not defined PROFIL_USAGE set "PROFIL_USAGE=0"
if not defined PROFIL_POWER (
    REM En l'absence de choix utilisateur : laptop=Eco, desktop=MaxPerf
    if "%DETECTE_PORTABLE%"=="1" (
        set "PROFIL_POWER=1"
    ) else (
        set "PROFIL_POWER=0"
    )
)
REM Cas particulier : Gaming + Eco (laptop gamer sur batterie) - autorise mais signale
set "IS_GAMING_ECO=0"
if "!PROFIL_USAGE!"=="0" (
    if "!PROFIL_POWER!"=="1" set "IS_GAMING_ECO=1"
)
exit /b 0

:CHOISIR_PROFILS
call :INIT_PROFILS
set "PROFILE_PROMPT=%~2"
if not defined PROFILE_PROMPT set "PROFILE_PROMPT=BOTH"
if /i "!PROFILE_PROMPT!"=="POWER" goto :CHOISIR_PROFILS_POWER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% %~1%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Quel est l'usage principal de ce PC ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[1] GAMING%COLOR_RESET% - Priorite jeux, input lag, ping et reactivite
echo %COLOR_CYAN%[2] NORMAL%COLOR_RESET% - Bureautique, multimedia, creation, stabilite
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au menu principal%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez votre usage [1=Gaming / 2=Normal / M=Retour]: %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! LSS 1 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 3 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 1 set "PROFIL_USAGE=0"
if !errorlevel! EQU 2 set "PROFIL_USAGE=1"
if /i "!PROFILE_PROMPT!"=="USAGE" goto :CHOISIR_PROFILS_DONE

:CHOISIR_PROFILS_POWER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% %~1%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "%DETECTE_PORTABLE%"=="1" (
    echo %COLOR_WHITE%PC portable detecte. Quel mode energie voulez-vous ?%COLOR_RESET%
) else (
    echo %COLOR_WHITE%Quel mode energie voulez-vous ?%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_GREEN%[1] ECO%COLOR_RESET% - Autonomie, chauffe, silence, RSC/LSO/checksum ON
echo %COLOR_RED%[2] MAX PERF%COLOR_RESET% - Plan Ultimate Performance, economie d'energie coupee
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au menu principal%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez l'energie [1=Eco / 2=MaxPerf / M=Retour]: %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! LSS 1 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 3 (
    set "PROFILE_PROMPT="
    exit /b 1
)
if !errorlevel! EQU 1 set "PROFIL_POWER=1"
if !errorlevel! EQU 2 set "PROFIL_POWER=0"
goto :CHOISIR_PROFILS_DONE

:CHOISIR_PROFILS_DONE
call :INIT_PROFILS
if /i not "!PROFILE_PROMPT!"=="POWER" if "!IS_GAMING_ECO!"=="1" (
    echo.
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Profil GAMING + ECO selectionne.%COLOR_RESET%
    echo %COLOR_WHITE%    Les optimisations de latence restent actives et reduiront l'autonomie.%COLOR_RESET%
    echo %COLOR_WHITE%    Si l'autonomie est prioritaire, preferez NORMAL + ECO.%COLOR_RESET%
    echo.
    <nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Continuer quand meme ? [O/N]: %COLOR_RESET%"
    call :AZCHOICE ON
    if !errorlevel! NEQ 1 (
        set "PROFILE_PROMPT="
        exit /b 1
    )
)
set "PROFILE_PROMPT="
exit /b 0

:: =================================================================================
:: UTILS
:: =================================================================================


:REFRESH_INTERNET_STATUS
set "HAS_INTERNET=0"
ping -n 1 -w 1500 1.1.1.1 >nul 2>&1
if !errorlevel! EQU 0 (
    set "HAS_INTERNET=1"
    exit /b
)
:: Repli si ICMP est bloque (entreprise, pare-feu) : test HTTP leger (service Microsoft)
powershell -NoProfile -Command "try { $c=(Invoke-WebRequest -Uri ""http://www.msftconnecttest.com/connecttest.txt"" -UseBasicParsing -TimeoutSec 5).Content; if ($c -match ""Microsoft"") { exit 0 } else { exit 1 } } catch { exit 1 }" >nul 2>&1
if !errorlevel! EQU 0 set "HAS_INTERNET=1"
exit /b

:PROMPT_MANUAL_REBOOT
if "!AIO_MODE!"=="1" exit /b 0
if "!SKIP_PAUSE!"=="1" exit /b 0
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous redemarrer maintenant ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 exit /b 0
if !errorlevel! EQU 1 (
    shutdown /r /t 10 /c "Redemarrage demande par WindowsOptimizer"
    if !errorlevel! EQU 0 (
        cls
        echo.
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Redemarrage programme dans 10 secondes...%COLOR_RESET%
        timeout /t 5 /nobreak >nul
        exit /b 0
    )
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de programmer le redemarrage.%COLOR_RESET%
    exit /b 1
)

:: Confirmation O/N - %~1 = message, retourne 0 pour Oui, 1 pour Non
:ASK_CONFIRM
<nul set /p ="%~1"
call :AZCHOICE ON
if !errorlevel! NEQ 1 exit /b 1
exit /b 0

:: %~1 = label (ignore, conserve pour compatibilite appelants)  %~2 = message
:ASK_IF_INTERACTIVE
if not "!SKIP_PAUSE!"=="0" exit /b 0
call :ASK_CONFIRM "%~2"
:: Retourne 0 pour Oui, 1 pour Non. Les appelants gerent le routage.
if !errorlevel! EQU 1 exit /b 1
exit /b 0

:: Question standard O/N/M.
:: %~1 = message  %~2 = variable flag (ex: DESACTIVER_SECURITE)
:: O : flag=1, retour 0 / N : flag=0, retour 0 / M : flag=0, retour 2
:COMMON_YES_NO
set "%~2=0"
<nul set /p ="%~1"
call :AZCHOICE ONM
set "COMMON_CHOICE=!errorlevel!"
REM O=1, N=2, M=3. La valeur est capturee une fois pour eviter tout routage ambigu.
if "!COMMON_CHOICE!"=="3" (
    set "COMMON_CHOICE="
    cls
    exit /b 2
)
if "!COMMON_CHOICE!"=="2" (
    set "COMMON_CHOICE="
    exit /b 0
)
if "!COMMON_CHOICE!"=="1" (
    set "%~2=1"
    set "COMMON_CHOICE="
    exit /b 0
)
set "COMMON_CHOICE="
REM En cas d'echec de choice.exe, revenir au menu au lieu d'appliquer une option.
exit /b 2

:: Lecture d'une entree menu via choice.exe (silencieux : pas d'ecran de la liste).
:AZCHOICE
choice /c %~1 /n
exit /b !errorlevel!

:MENU_PRINCIPAL
REM Toute entree dans un menu visible est interactive, meme apres un ancien parcours automatique.
set "AIO_MODE=0"
set "SKIP_PAUSE=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE%Script d'Optimisation Windows - All in One%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

REM  Affichage des informations systeme
echo %STYLE_BOLD%%COLOR_WHITE% SYSTEME :%COLOR_RESET% %COLOR_CYAN%%HW_OS%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CPU     :%COLOR_RESET% %COLOR_CYAN%%HW_CPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GPU     :%COLOR_RESET% %COLOR_CYAN%%HW_GPU%%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% RAM     :%COLOR_RESET% %COLOR_CYAN%%HW_RAM% Go%COLOR_RESET%
if "%DETECTE_PORTABLE%"=="1" (
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
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Gerer Protections Securite ^(VBS/HVCI + Mitigations CPU^)%COLOR_RESET%
echo.

echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS ALL IN ONE ---%COLOR_RESET%
echo %COLOR_YELLOW%[O]%COLOR_RESET% %COLOR_WHITE%Tout optimiser %COLOR_GREEN%- repondez aux questions, le script gere le reste%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS ---%COLOR_RESET%
echo %COLOR_YELLOW%[N]%COLOR_RESET% %COLOR_CYAN%Nettoyage Avance de Windows%COLOR_RESET%
echo %COLOR_YELLOW%[R]%COLOR_RESET% %COLOR_CYAN%Creer un Point de Restauration%COLOR_RESET%
echo %COLOR_YELLOW%[G]%COLOR_RESET% %COLOR_MAGENTA%Gestion Windows (Defender, UAC, Edge, OneDrive...)%COLOR_RESET%
echo %COLOR_YELLOW%[W]%COLOR_RESET% %COLOR_MAGENTA%Activation Windows / Office (script MAS)%COLOR_RESET%
echo %COLOR_YELLOW%[T]%COLOR_RESET% %COLOR_MAGENTA%WinUtil - Utilitaire Windows de Chris Titus Tech%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[Q]%COLOR_RESET% %STYLE_BOLD%%COLOR_RED%Quitter le script%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Veuillez choisir une option [1-8, O, N, R, G, W, T, Q]: %COLOR_RESET%"
call :AZCHOICE 12345678ONRGWTQ

REM  Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 15 goto :END_SCRIPT
if !errorlevel! EQU 14 goto :OUTIL_CHRIS_TITUS
if !errorlevel! EQU 13 goto :OUTIL_ACTIVATION
if !errorlevel! EQU 12 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 11 goto :CREER_POINT_RESTAURATION
if !errorlevel! EQU 10 goto :NETTOYAGE_AVANCE_WINDOWS
if !errorlevel! EQU 9  goto :TOUT_OPTIMISER
if !errorlevel! EQU 8  goto :TOGGLE_PROTECTIONS_NOYAU
if !errorlevel! EQU 7  goto :TOGGLE_ECONOMIES_ENERGIE
if !errorlevel! EQU 6  goto :DO_PERIPHERIQUES
if !errorlevel! EQU 5  goto :DO_RESEAU
if !errorlevel! EQU 4  goto :DO_GPU
if !errorlevel! EQU 3  goto :DO_DISQUES
if !errorlevel! EQU 2  goto :DO_MEMOIRE
if !errorlevel! EQU 1  goto :DO_SYSTEME
goto :MENU_PRINCIPAL

:DO_PERIPHERIQUES
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - PERIPHERIQUES" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_PERIPHERIQUES
goto :MENU_PRINCIPAL

:DO_RESEAU
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - RESEAU" "BOTH"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_RESEAU
goto :MENU_PRINCIPAL

:DO_GPU
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - GPU" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_GPU
goto :MENU_PRINCIPAL

:DO_DISQUES
call :OPTIMISATIONS_DISQUES
goto :MENU_PRINCIPAL

:DO_MEMOIRE
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - MEMOIRE" "POWER"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_MEMOIRE
goto :MENU_PRINCIPAL

:DO_SYSTEME
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - SYSTEME" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :OPTIMISATIONS_SYSTEME
goto :MENU_PRINCIPAL

:MENU_GESTION_WINDOWS
set "SKIP_PAUSE=0"
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
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_GREEN%Installer Runtimes (Visual C++ + DirectX June 2010)%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- APPLICATIONS ET NETTOYAGE ---%COLOR_RESET%
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Supprimer les Bloatwares Windows (Apps inutiles)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-8, M]: %COLOR_RESET%"
call :AZCHOICE 12345678M
REM  Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 9 goto :MENU_PRINCIPAL
if !errorlevel! EQU 8  goto :SUPPRIMER_BLOATWARES
if !errorlevel! EQU 7  goto :DO_INSTALLER_VISUAL_REDIST
if !errorlevel! EQU 6  goto :DESINSTALLER_EDGE
if !errorlevel! EQU 5  goto :DESINSTALLER_ONEDRIVE
if !errorlevel! EQU 4  goto :MENU_IA_WIDGETS_RECALL
if !errorlevel! EQU 3  goto :TOGGLE_ANIMATIONS
if !errorlevel! EQU 2  goto :TOGGLE_UAC
if !errorlevel! EQU 1  goto :TOGGLE_DEFENDER
goto :MENU_GESTION_WINDOWS

:DO_INSTALLER_VISUAL_REDIST
call :INSTALLER_VISUAL_REDIST
goto :MENU_GESTION_WINDOWS

:TOUT_OPTIMISER
call :CHOISIR_PROFILS "TOUT OPTIMISER - CONFIGURATION" "BOTH"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
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
echo %COLOR_WHITE%Voulez-vous reduire certaines mitigations du processeur ?%COLOR_RESET%
echo %COLOR_WHITE%  Gaming : VBS/HVCI et CFG restent actifs. Normal : VBS/HVCI reviennent aux reglages Windows.%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%L'effet sur les performances varie selon le processeur et les logiciels.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Reduire les mitigations CPU
echo       %COLOR_WHITE%La protection contre certaines failles processeur sera reduite.%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Ne pas modifier les protections
echo.
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Appliquer ce choix ? [O/N/M]: %COLOR_RESET%" DESACTIVER_SECURITE
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Defender analyse les fichiers en temps reel. Le desactiver retire cette analyse.%COLOR_RESET%
echo %COLOR_WHITE%Le gain de ressources varie selon le PC et les logiciels utilises.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Desactiver l'antivirus integre
echo       %COLOR_WHITE%Defender n'analysera plus les fichiers en temps reel.%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Ne pas modifier Windows Defender
echo.
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Appliquer ce choix ? [O/N/M]: %COLOR_RESET%" DESACTIVER_DEFENDER
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

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
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Ne pas modifier les animations
echo.
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver les animations Windows ? [O/N/M]: %COLOR_RESET%" DESACTIVER_ANIMATIONS
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver les fonctionnalites IA de Windows ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Copilot, widgets, Recall peuvent consommer CPU/reseau%COLOR_RESET%
echo %COLOR_WHITE%et traiter des donnees via des services Microsoft ; couper tout ameliore confidentialite et perf.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Desactive Copilot, Recall, widgets et autres fonctionnalites IA
echo       %COLOR_YELLOW%Ameliore les performances et la confidentialite%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Ne pas modifier les fonctionnalites IA
echo.
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces fonctionnalites IA ? [O/N/M]: %COLOR_RESET%" DESACTIVER_IA
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous desactiver le Controle de Compte Utilisateur (UAC) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%L'UAC demande une confirmation avant d'accorder les droits administrateur.%COLOR_RESET%
echo %COLOR_WHITE%Le desactiver supprime ces demandes pour toutes les applications.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ne plus demander de confirmation pour les actions admin
echo       %COLOR_WHITE%Les actions administrateur ne seront plus confirmees par l'UAC.%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Ne pas modifier l'UAC
echo.
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Appliquer ce choix ? [O/N/M]: %COLOR_RESET%" DESACTIVER_UAC
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL



cls
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Mode automatique : vos reponses ci-dessus s'appliquent sans nouvelle confirmation.%COLOR_RESET%
echo.
set "SKIP_PAUSE=1"
set "AIO_MODE=1"
set "AIO_RUNTIME_ERROR=0"
set "AIO_CORE_ERROR=0"
set "AIO_IA_FAILED="
for %%X in (SYSTEME MEMOIRE DISQUES GPU RESEAU PERIPHERIQUES SECURITE DEFENDER ANIMATIONS IA UAC) do set "AIO_ERR_%%X=0"
set "AIO_POWER_ERROR=0"
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%TOUT_OPTIMISER applique les options confirmees par OUI.%COLOR_RESET%
echo %COLOR_WHITE%  Une reponse NON ignore l'option sans modifier son etat actuel.%COLOR_RESET%
echo.
REM Preselection silencieuse uniquement : la SECTION 7 reste executee dans l'ordre apres 1 a 6.
REM Les sections precedentes qui ecrivent dans SCHEME_CURRENT ciblent ainsi le bon plan.
call :SELECT_TARGET_POWER_SCHEME !PROFIL_POWER!
if !errorlevel! NEQ 0 set "AIO_POWER_ERROR=1"
call :INSTALLER_VISUAL_REDIST
if !errorlevel! NEQ 0 set "AIO_RUNTIME_ERROR=1"
call :OPTIMISATIONS_SYSTEME
if !errorlevel! NEQ 0 (
    set "AIO_ERR_SYSTEME=1"
    set "AIO_CORE_ERROR=1"
)
call :OPTIMISATIONS_MEMOIRE
if !errorlevel! NEQ 0 (
    set "AIO_ERR_MEMOIRE=1"
    set "AIO_CORE_ERROR=1"
)
call :OPTIMISATIONS_DISQUES
if !errorlevel! NEQ 0 (
    set "AIO_ERR_DISQUES=1"
    set "AIO_CORE_ERROR=1"
)
call :OPTIMISATIONS_GPU
if !errorlevel! NEQ 0 (
    set "AIO_ERR_GPU=1"
    set "AIO_CORE_ERROR=1"
)
call :OPTIMISATIONS_RESEAU
if !errorlevel! NEQ 0 (
    set "AIO_ERR_RESEAU=1"
    set "AIO_CORE_ERROR=1"
)
call :OPTIMISATIONS_PERIPHERIQUES
if !errorlevel! NEQ 0 (
    set "AIO_ERR_PERIPHERIQUES=1"
    set "AIO_CORE_ERROR=1"
)
if "!PROFIL_POWER!"=="0" (
    call :DESACTIVER_ECONOMIES_ENERGIE
) else (
    call :RESTAURER_ECONOMIES_ENERGIE
)
if !errorlevel! NEQ 0 set "AIO_POWER_ERROR=1"
if "!DESACTIVER_SECURITE!"=="1" (
    call :DESACTIVER_PROTECTIONS_SECURITE
    if !errorlevel! NEQ 0 set "AIO_ERR_SECURITE=1"
)
if "!DESACTIVER_DEFENDER!"=="1" (
    call :DESACTIVER_DEFENDER_SECTION
    if !errorlevel! NEQ 0 set "AIO_ERR_DEFENDER=1"
)
if "!DESACTIVER_ANIMATIONS!"=="1" (
    call :DESACTIVER_ANIMATIONS_SECTION
    if !errorlevel! NEQ 0 set "AIO_ERR_ANIMATIONS=1"
)
if "!DESACTIVER_IA!"=="1" (
  call :DESACTIVER_IA_SECTION
  if !errorlevel! NEQ 0 set "AIO_ERR_IA=1"
)
if "!DESACTIVER_UAC!"=="1" (
  call :DESACTIVER_UAC_SECTION
  if !errorlevel! NEQ 0 set "AIO_ERR_UAC=1"
)
call :DETECT_HARDWARE 1
set "AIO_MODE=0"
set "SKIP_PAUSE=0"
call :AFFICHER_RESUME_OPTIMISATION
set "AIO_RUNTIME_ERROR="
set "AIO_CORE_ERROR="
set "AIO_ERR_SYSTEME="
set "AIO_ERR_MEMOIRE="
set "AIO_ERR_DISQUES="
set "AIO_ERR_GPU="
set "AIO_ERR_RESEAU="
set "AIO_ERR_PERIPHERIQUES="
set "AIO_ERR_SECURITE="
set "AIO_ERR_DEFENDER="
set "AIO_ERR_ANIMATIONS="
set "AIO_ERR_IA="
set "AIO_IA_FAILED="
set "AIO_ERR_UAC="
set "AIO_POWER_ERROR="
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
if "!PROFIL_USAGE!"=="0" (
    echo %STYLE_BOLD%%COLOR_WHITE% OPTIMISATION TERMINEE - Profil GAMING %COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% OPTIMISATION TERMINEE - Profil NORMAL %COLOR_RESET%
)
if "!PROFIL_POWER!"=="0" (
    echo %STYLE_BOLD%%COLOR_WHITE% Mode PERFORMANCE MAX%COLOR_RESET%
) else (
    echo %STYLE_BOLD%%COLOR_WHITE% Mode ECO%COLOR_RESET%
)
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %STYLE_BOLD%%COLOR_BLUE%-- RESULTATS APPLIQUES ----------------------------------------------------------%COLOR_RESET%
REM Construit uniquement la liste des sections principales qui ont retourne une erreur.
if "!AIO_CORE_ERROR!"=="0" goto :RESUME_CORE_OK
set "ERR_L="
if "!AIO_ERR_SYSTEME!"=="1" set "ERR_L=!ERR_L! Systeme,"
if "!AIO_ERR_MEMOIRE!"=="1" set "ERR_L=!ERR_L! Memoire,"
if "!AIO_ERR_DISQUES!"=="1" set "ERR_L=!ERR_L! Disques,"
if "!AIO_ERR_GPU!"=="1" set "ERR_L=!ERR_L! GPU,"
if "!AIO_ERR_RESEAU!"=="1" set "ERR_L=!ERR_L! Reseau,"
if "!AIO_ERR_PERIPHERIQUES!"=="1" set "ERR_L=!ERR_L! Peripheriques,"
if "!ERR_L!"=="" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Une section principale a signale une erreur non identifiee.%COLOR_RESET%
) else (
    set "ERR_L=!ERR_L:~0,-1!"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Sections en echec :!ERR_L!%COLOR_RESET%
)
goto :RESUME_CORE_AFTER
:RESUME_CORE_OK
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme, memoire, disques, GPU, reseau, peripheriques.%COLOR_RESET%
:RESUME_CORE_AFTER
if "!AIO_RUNTIME_ERROR!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Runtimes Visual C++ et DirectX verifies.%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Installation ou verification des runtimes incomplete.%COLOR_RESET%
)
if "!PROFIL_POWER!"=="0" (
    if "!AIO_POWER_ERROR!"=="0" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan "Ultimate Performance" actif ^(economies d'energie coupees^).%COLOR_RESET%
    ) else (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Mode performance applique partiellement ; consultez les erreurs affichees.%COLOR_RESET%
    )
) else (
    if "!AIO_POWER_ERROR!"=="0" (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Profil Eco applique ^(reglages d'economie d'energie restaures^).%COLOR_RESET%
    ) else (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Profil Eco applique partiellement ; consultez les erreurs affichees.%COLOR_RESET%
    )
)
echo.

echo %STYLE_BOLD%%COLOR_BLUE%-- OPTIONS COMPLEMENTAIRES ------------------------------------------------------%COLOR_RESET%
if "!AIO_ERR_SECURITE!"=="1" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Reglages des protections appliques partiellement.%COLOR_RESET%
) else if "!DESACTIVER_SECURITE!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mitigations CPU reduites selon le profil choisi.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Protections conservees sans modification.%COLOR_RESET%
)
if "!AIO_ERR_DEFENDER!"=="1" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Reglages Windows Defender appliques partiellement.%COLOR_RESET%
) else if "!DESACTIVER_DEFENDER!"=="1" (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Defender desactive si Tamper Protection l'autorise.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Windows Defender conserve sans modification.%COLOR_RESET%
)
if "!AIO_ERR_UAC!"=="1" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Reglages UAC appliques partiellement.%COLOR_RESET%
) else if "!DESACTIVER_UAC!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%UAC desactive.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%UAC conserve sans modification.%COLOR_RESET%
)
if "!AIO_ERR_ANIMATIONS!"=="1" (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Reglages des animations appliques partiellement.%COLOR_RESET%
) else if "!DESACTIVER_ANIMATIONS!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Animations Windows desactivees.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Animations Windows conservees sans modification.%COLOR_RESET%
)
if "!AIO_ERR_IA!"=="1" (
    if defined AIO_IA_FAILED (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Reglages IA appliques partiellement : !AIO_IA_FAILED!.%COLOR_RESET%
    ) else (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Reglages IA / Widgets / Recall appliques partiellement.%COLOR_RESET%
    )
) else if "!DESACTIVER_IA!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Fonctionnalites IA / Widgets / Recall desactivees.%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Fonctionnalites IA / Widgets / Recall conservees sans modification.%COLOR_RESET%
)
echo.

echo %STYLE_BOLD%%COLOR_BLUE%-- PROCHAINE ETAPE --------------------------------------------------------------%COLOR_RESET%
if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour appliquer toutes les modifications.%COLOR_RESET%
call :PROMPT_MANUAL_REBOOT
exit /b

:OPTIMISATIONS_SYSTEME
cls
call :INIT_PROFILS
set "SYSTEM_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 1 : OPTIMISATIONS SYSTEME%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Optimise le noyau Windows, desactive la telemetrie et configure%COLOR_RESET%
echo %COLOR_WHITE%  l'interface pour de meilleures performances generales.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% - reactivite maximale%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% - usage quotidien, stabilite et confort%COLOR_RESET%
)
echo.

REM  1.1 - Priorites CPU et planification
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration des priorites CPU...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v IoPriority /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEngCP.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Planification CPU configuree%COLOR_RESET%

REM  1.2 - Profil Gaming MMCSS SystemProfile\Tasks\Games
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du profil gaming (MMCSS)...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil gaming (MMCSS) configure%COLOR_RESET%

REM  1.3 - Interface Windows
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de l'interface Windows...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowTaskViewButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarMn" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DontPrettyPath" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "DesktopLivePreviewHoverTime" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "IconsOnly" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "SeparateProcess" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" /v ChatIcon /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v DisableSearchBoxSuggestions /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" /ve /t REG_SZ /d "" /f >nul 2>&1
REM  ShowFrequent - Cache des fichiers recents (ne desactive PAS l'indexation Windows)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v ShowFrequent /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer" /v DesktopProcess /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKU\.DEFAULT\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Control Panel\Keyboard" /v "InitialKeyboardIndicators" /t REG_SZ /d "2" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" /v TaskbarEndTask /t REG_DWORD /d 1 /f >nul 2>&1

REM  1.4 - Telemetrie et vie privee
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie et des publicites...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f >nul 2>&1

REM  Optimiser le cache d'icones et miniatures
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "Max Cached Icons" /t REG_DWORD /d 8192 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >nul 2>&1

REM  Desactiver la compression des papiers peints
reg add "HKCU\Control Panel\Desktop" /v JPEGImportQuality /t REG_DWORD /d 100 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Interface et privacy de base optimisees%COLOR_RESET%

REM  1.5 - Telemetrie systeme et vie privee approfondie
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie et des traceurs...%COLOR_RESET%
REM  Registre : telemetrie et publicites
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
REM PeriodInNanoSeconds laisse intact : aucune suppression hors section restauration.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Feedback" /v "AllowTelemetry" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\TIPC" /v "Enabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Device Metadata" /v "PreventDeviceMetadataFromNetwork" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "ShowSyncProviderNotifications" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Explorer" /v "DisableSearchSuggestions" /t REG_DWORD /d 1 /f >nul 2>&1

REM  Content Delivery Manager
for %%V in (ContentDeliveryAllowed FeatureManagementEnabled OemPreInstalledAppsEnabled PreInstalledAppsEnabled PreInstalledAppsEverEnabled RemediationRequired RotatingLockScreenEnabled RotatingLockScreenOverlayEnabled SilentInstalledAppsEnabled SoftLandingEnabled SubscribedContentEnabled SystemPaneSuggestionsEnabled SubscribedContent-310093Enabled SubscribedContent-314563Enabled SubscribedContent-338380Enabled SubscribedContent-338381Enabled SubscribedContent-338387Enabled SubscribedContent-338388Enabled SubscribedContent-338389Enabled SubscribedContent-338393Enabled SubscribedContent-353694Enabled SubscribedContent-353696Enabled SubscribedContent-353698Enabled) do (
  reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v %%V /t REG_DWORD /d 0 /f >nul 2>&1
)

REM  Recherche Windows - Bing OFF, Cortana OFF (politique + package legacy)
REM  AllowCortana=0 : politique Microsoft officielle (Windows Search local conserve)
REM  ShowCortanaButton/CortanaConsent : cles legacy encore utiles sur anciens builds W10/W11
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCortana" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "ShowCortanaButton" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "BingSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" /v "CortanaConsent" /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; Get-AppxPackage -AllUsers Microsoft.549981C3F5F10 -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -eq 'Microsoft.549981C3F5F10' } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue" >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "ConnectedSearchUseWeb" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowCloudSearch" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Search" /v "AllowSearchToUseLocation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "SafeSearchMode" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsAADCloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsMSACloudSearchEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\SearchSettings" /v "IsDynamicSearchBoxEnabled" /t REG_DWORD /d 0 /f >nul 2>&1

REM  Activity History OFF
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableActivityFeed" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "PublishUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "UploadUserActivities" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Telemetrie et publicites desactivees%COLOR_RESET%

REM  Taches planifiees de telemetrie
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

REM  Autologgers de diagnostic OFF
for %%L in (AppModel Cellcore DiagLog SQMLogger Diagtrack-Listener) do (
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\%%~L" /v Start /t REG_DWORD /d 0 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\WMI\Autologger\ReadyBoot" /v Start /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Taches de telemetrie desactivees%COLOR_RESET%

REM  Blocage telemetrie via hosts
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Gestion du blocage telemetrie dans le fichier hosts...%COLOR_RESET%
set "HOSTS=%SystemRoot%\System32\drivers\etc\hosts"
attrib -r "%HOSTS%" >nul 2>&1

REM  Backup du fichier hosts avant modification
copy /Y "%HOSTS%" "%HOSTS%.bak" >nul 2>&1
REM  Utilisation de PowerShell pour mettre a jour ou ajouter le bloc securise (Telemetrie uniquement)
powershell -NoProfile -Command "$ErrorActionPreference='Stop';$h='%HOSTS%';$tmp=[System.IO.Path]::Combine([System.IO.Path]::GetDirectoryName($h),([System.IO.Path]::GetFileName($h)+'.'+[guid]::NewGuid().ToString('N')+'.tmp'));$crlf=[char]13+[char]10;$s='# Telemetry Block Start';$e='# Telemetry Block End';$domains='vortex.data.microsoft.com','vortex-win.data.microsoft.com','v10.vortex-win.data.microsoft.com','v10.events.data.microsoft.com','telecommand.telemetry.microsoft.com','oca.telemetry.microsoft.com','watson.telemetry.microsoft.com','watsonc.microsoft.com','settings.data.microsoft.com','settings-win.data.microsoft.com','mobile.events.data.microsoft.com','browser.events.data.microsoft.com','self.events.data.microsoft.com','v20.events.data.microsoft.com','telemetry.microsoft.com','telemetrycollector.microsoft.com','pipe.aria.microsoft.com','diagnostics.office.com','activity.windows.com','modern.watson.data.microsoft.com','applicationinsights.microsoft.com','azurewatson.microsoft.com';$nb=$crlf+$s+$crlf;foreach($d in $domains){$nb+='0.0.0.0 '+$d+$crlf};$nb+=$e+$crlf;try{if(Test-Path -LiteralPath $h){$cur=[System.IO.File]::ReadAllText($h,[System.Text.Encoding]::ASCII)}else{$cur=''};$cur=$cur -replace ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)),'';foreach($d in $domains){$cur=$cur -replace ('(?m)^0\.0\.0\.0\s+'+[regex]::Escape($d)+'\s*$'),''};$cur=$cur.TrimEnd()+$nb;if(Test-Path -LiteralPath $h){(Get-Item -LiteralPath $h).Attributes='Normal'};[System.IO.File]::WriteAllText($tmp,$cur,[System.Text.Encoding]::ASCII);[System.IO.File]::Copy($tmp,$h,$true);Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;exit 0}catch{Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue;exit 1}"

if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Domaines telemetrie bloques ^(bloc unique, adaptatif^)%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de la mise a jour du fichier hosts%COLOR_RESET%
)
attrib +r "%HOSTS%" >nul 2>&1
ipconfig /flushdns >nul 2>&1
set "HOSTS="

REM  1.6 - Services optimises
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation services%COLOR_RESET%
set "SERVICE_CONFIG_ERROR=0"
set "SERVICE_CONFIG_SKIPPED=0"

REM  1 - Services vitaux -> AUTOMATIQUE
for %%S in (
    W32Time
    WpnService
    SysMain
    defragsvc
) do (
  call :SET_EXISTING_SERVICE_START "%%S" 2
)
REM  Configuration du service par utilisateur WpnUserService
call :SET_EXISTING_SERVICE_START "WpnUserService" 2

REM  2 - Services occasionnels et utiles -> MANUEL (demand)
for %%S in (
    ALG
    AppVClient
    BDESVC
    CertPropSvc
    CscService
    GraphicsPerfSvc
    icssvc
    IKEEXT
    lfsvc
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
  call :SET_EXISTING_SERVICE_START "%%S" 3
)
REM  CDPUserSvc est un service par utilisateur
call :SET_EXISTING_SERVICE_START "CDPUserSvc" 3

REM  3 - Services inutiles et telemetrie -> DESACTIVES
for %%S in (
    AJRouter
    AxInstSV
    DiagTrack
    diagnosticshub.standardcollector.service
    DialogBlockingService
    Fax
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
  call :SET_EXISTING_SERVICE_START "%%S" 4
)
if "!SERVICE_CONFIG_ERROR!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services existants configures selon le profil%COLOR_RESET%
) else (
    set "SYSTEM_SECTION_ERROR=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Au moins un service existant n'a pas pu etre configure.%COLOR_RESET%
)
if !SERVICE_CONFIG_SKIPPED! GTR 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%!SERVICE_CONFIG_SKIPPED! service^(s^) absent^(s^) ignore^(s^) - aucune cle fantome creee%COLOR_RESET%
set "SERVICE_CONFIG_ERROR="
set "SERVICE_CONFIG_SKIPPED="

REM  Services critiques laisses intacts : Bluetooth, Hello, RDP, Spooler, PlugPlay
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services optimises (Bluetooth/VPN/Hello/RDP preserves)%COLOR_RESET%

REM  1.7 - Optimisations demarrage et systeme
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme diverses...%COLOR_RESET%
REM  Supprimer le delai de demarrage des applications
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul 2>&1
REM  Desactiver l'attente etat idle avant lancement apps au login (reduit le delai sur Win10/11)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "WaitForIdleState" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "04" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "08" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "32" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "2048" /t REG_DWORD /d 7 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisations demarrage et stockage terminees%COLOR_RESET%

REM  1.8 - Utilitaires et Bloatwares (Automatique)
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

REM  Desactivation des Co-installateurs tiers (Razer/Logitech Popup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des Co-installateurs et recherche pilotes auto...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Device Installer" /v DisableCoInstallers /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Popups Razer/Logitech bloques%COLOR_RESET%

REM  Privacy Supplementaire
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des tweaks privacy supplementaires...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v AllowDeviceNameInTelemetry /t REG_DWORD /d 0 /f >nul 2>&1

REM  Privacy avancee
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Privacy avancee...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection" /v DisableDeviceDiagnosticData /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\DiagTrack" /v UploadPermission /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Handwriting" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\TabletPC" /v PreventHandwritingDataSharing /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\PerfTrack" /v Disabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Diagnostics\PerfTrack" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Privacy avancee appliquee%COLOR_RESET%

REM  1.9 - Navigateurs
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation navigateurs...%COLOR_RESET%
REM  Microsoft Edge
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v HideFirstRunExperience /t REG_DWORD /d 1 /f >nul 2>&1
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

REM  Google Chrome
reg add "HKCU\Software\Policies\Google\Chrome" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsMode /t REG_SZ /d secure /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Navigateurs optimises%COLOR_RESET%

REM  1.10 - Desactivation du stockage reserve
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du stockage reserve Windows...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v PassedPolicy /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "try { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Stockage reserve desactive ^(~7Go recuperes apres redemarrage^)%COLOR_RESET%

REM  1.11 - Desactivation P2P Windows Update (Delivery Optimization)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du P2P Windows Update...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%P2P Windows Update desactive (maj depuis Microsoft uniquement)%COLOR_RESET%

REM  1.12 - Blocage des pubs Store dans la recherche
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Blocage des recommandations Store dans la recherche...%COLOR_RESET%
icacls "%LocalAppData%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db" /deny Everyone:F >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Pubs Store bloquees dans la recherche%COLOR_RESET%

REM  1.13 - Affichage du code erreur BSoD
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de l'affichage des codes erreur BSoD...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v DisplayParameters /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Codes erreur BSoD visibles (diagnostic facilite)%COLOR_RESET%

REM  1.14 - Desactivation de l'aide F1
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la touche F1 (aide Windows)...%COLOR_RESET%
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Touche F1 (aide) desactivee%COLOR_RESET%

REM  1.15 - Optimisations audio (latence)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des ameliorations audio...%COLOR_RESET%
powershell -NoProfile -Command "$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}'; Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p = $_.PSPath; New-ItemProperty -Path $p -Name 'FxNonDestructiveSoftMixer' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'FxRender' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'DisableAudioEndpointDucking' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } " >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisation des peripheriques de rendu audio (PowerShell)%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v ImmersiveAudio /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Ameliorations audio desactivees - Latence reduite%COLOR_RESET%

REM  1.16 - Desactivation Windows Platform Binary Table (WPBT)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation WPBT (anti bloatware OEM firmware)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%WPBT desactive%COLOR_RESET%

REM  1.17 - Intel Thread Director / Core Parking (profil-aware)
REM  SCHEDPOLICY : 0=Tous, 1=Performants, 2=Preferer performants, 3=Efficients, 4=Preferer efficients, 5=Auto.
REM  Ne fait rien sur CPU non-hybride (AMD, Intel avant 12th gen).
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration Intel Thread Director / Core Parking...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /t REG_DWORD /d 2 /f >nul 2>&1
if "!PROFIL_USAGE!"=="0" (
    powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2 >nul 2>&1
    if "!DETECTE_PORTABLE!"=="1" (
        powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5 >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Thread Director GAMING : AC prefer performance, DC Auto laptop%COLOR_RESET%
    ) else (
        powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 2 >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Thread Director GAMING : prefer performance AC/DC%COLOR_RESET%
    )
) else (
    powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5 >nul 2>&1
    powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 5 >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Thread Director NORMAL : Auto AC/DC%COLOR_RESET%
)

REM  1.18 - DisablePagefileEncryption (tweak Gaming teste ; suppression de la surcharge en Normal)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du chiffrement du fichier d'echange ^(Gaming^)...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagefileEncryption" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Chiffrement du fichier d'echange desactive ^(Gaming^)%COLOR_RESET%
) else (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagefileEncryption" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Surcharge DisablePagefileEncryption supprimee ^(Normal^)%COLOR_RESET%
)

if "!SYSTEM_SECTION_ERROR!"=="0" (
    set "SYSTEM_SECTION_ERROR="
    call :FINISH_ACTION "Optimisations systeme" "appliquees"
    exit /b 0
)
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_RED%[ERREUR]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations systeme appliquees partiellement%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
set "SYSTEM_SECTION_ERROR="
call :PROMPT_MANUAL_REBOOT
exit /b 1

:OPTIMISATIONS_MEMOIRE
cls
call :INIT_PROFILS
set "MEMORY_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 2 : OPTIMISATIONS MEMOIRE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la gestion de la RAM et du fichier d'echange%COLOR_RESET%
echo %COLOR_WHITE%  pour de meilleures performances et une latence reduite.%COLOR_RESET%
echo.
if "!PROFIL_POWER!"=="0" (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%MAX PERF%COLOR_RESET%%COLOR_WHITE% - compression memoire OFF si RAM ^> 8 Go%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%ECO%COLOR_RESET%%COLOR_WHITE% - compression memoire activee ^(autonomie^)%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.

REM  2.1 - Memory Management
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la gestion memoire...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "ClearPageFileAtShutdown" /t REG_DWORD /d 0 /f >nul 2>&1
if "!PROFIL_POWER!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 1 /f >nul 2>&1
) else (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagingExecutive" /t REG_DWORD /d 0 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "SystemPages" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v LargeSystemCache /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion memoire optimisee%COLOR_RESET%

REM  2.2 - Prefetch/SysMain
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du Prefetch et SuperFetch pour performance maximale...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableBoottrace /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v SfTracingState /t REG_DWORD /d 0 /f >nul 2>&1
REM  Activer Superfetch et Prefetcher pour chargement ultra-rapide des applications
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnableSuperfetch /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" /v EnablePrefetcher /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Prefetch actif, SuperFetch optimise pour les jeux%COLOR_RESET%

REM  2.3 - FTH OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du tas tolerant aux pannes (FTH)...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\FTH" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
REM Etat FTH laisse intact : aucune suppression hors section restauration.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%FTH desactive - Performances memoire ameliorees%COLOR_RESET%

REM  2.4 - Compression memoire MMAgent - conditionnelle selon la RAM
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Analyse de la memoire physique...%COLOR_RESET%
set "RAM_GB=0"
for /f %%A in ('powershell -NoProfile -Command "[math]::Round(((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum) / 1GB, 0)"') do if not "%%A"=="" set "RAM_GB=%%A"
echo %COLOR_WHITE%   RAM detectee : !RAM_GB! Go%COLOR_RESET%
if "!PROFIL_POWER!"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Profil ECO : reactivation de la compression memoire...%COLOR_RESET%
    powershell -NoProfile -Command "try { Enable-MMAgent -MemoryCompression -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Compression memoire reactivee ^(ECO^)%COLOR_RESET%
    ) else (
        set "MEMORY_SECTION_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de reactiver la compression memoire.%COLOR_RESET%
    )
) else (
    if !RAM_GB! GTR 8 (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%RAM superieure a 8 Go - MAX PERF : desactivation de la compression memoire [charge CPU reduite]...%COLOR_RESET%
        powershell -NoProfile -Command "try { Disable-MMAgent -MemoryCompression -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
        if !errorlevel! EQU 0 (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Compression memoire desactivee%COLOR_RESET%
        ) else (
            set "MEMORY_SECTION_ERROR=1"
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de desactiver la compression memoire.%COLOR_RESET%
        )
    ) else (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%RAM de 8 Go ou moins : reactivation de la compression memoire...%COLOR_RESET%
        powershell -NoProfile -Command "try { Enable-MMAgent -MemoryCompression -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
        if !errorlevel! EQU 0 (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Compression memoire activee ^(RAM inferieure ou egale a 8 Go^)%COLOR_RESET%
        ) else (
            set "MEMORY_SECTION_ERROR=1"
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de reactiver la compression memoire.%COLOR_RESET%
        )
    )
)

if "!MEMORY_SECTION_ERROR!"=="0" (
    set "MEMORY_SECTION_ERROR="
    call :FINISH_ACTION "Optimisations memoire" "appliquees"
    exit /b 0
)
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_RED%[ERREUR]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations memoire appliquees partiellement%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
set "MEMORY_SECTION_ERROR="
call :PROMPT_MANUAL_REBOOT
exit /b 1

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
echo.

REM  3.1 - Configuration NTFS et TRIM
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration des parametres NTFS et activation du TRIM...%COLOR_RESET%
fsutil behavior set disabledeletenotify 0 >nul 2>&1
fsutil behavior set disabledeletenotify refs 0 >nul 2>&1
fsutil behavior set disablelastaccess 1 >nul 2>&1
fsutil behavior set disable8dot3 1 >nul 2>&1
fsutil behavior set memoryusage 2 >nul 2>&1
fsutil behavior set mftzone 2 >nul 2>&1
fsutil behavior set disablecompression 1 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres NTFS optimises - TRIM actif, metadonnees reduites%COLOR_RESET%

REM  3.2 - Optimisations I/O NTFS
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation I/O NTFS (NVMe)...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des chemins longs (plus de 260 caracteres)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Support des chemins longs active%COLOR_RESET%

REM  3.3 - TRIM sur volumes SSD
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de l'etat du TRIM sur les disques SSD...%COLOR_RESET%
set "TRIM_STATUS="
for /f "usebackq delims=" %%a in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$stampDir=Join-Path $env:ProgramData 'WindowsOptimizer'; $oldStampDir=Join-Path $env:ProgramData 'OptimizerAllInOne'; $stampFile=Join-Path $stampDir 'last_retrim.txt'; $oldStampFile=Join-Path $oldStampDir 'last_retrim.txt'; if((Test-Path $oldStampFile) -and -not (Test-Path $stampFile)){ if(-not (Test-Path $stampDir)){ New-Item -ItemType Directory -Path $stampDir -Force | Out-Null }; Move-Item -Path $oldStampFile -Destination $stampFile -Force -ErrorAction SilentlyContinue }; $ssds=Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.MediaType -ne 'HDD' -and $_.OperationalStatus -eq 'OK' -and $_.BusType -notin @('Virtual','FileBackedVirtual') }; if(-not $ssds -or $ssds.Count -eq 0){ 'NO_SSD'; exit 0 }; if((Test-Path $stampFile) -and ((Get-Date) - (Get-Item $stampFile).LastWriteTime).TotalDays -lt 30){ 'SKIP_RECENT'; exit 0 }; if(-not (Test-Path $stampDir)){ New-Item -ItemType Directory -Path $stampDir -Force | Out-Null }; $vols=Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.DriveLetter -and ($_.FileSystem -in @('NTFS','ReFS')) }; $done=$false; foreach($v in $vols){ $part=Get-Partition -DriveLetter $v.DriveLetter -ErrorAction SilentlyContinue; if($part){ $phys=Get-PhysicalDisk -ErrorAction SilentlyContinue | Where-Object { $_.DeviceId -eq $part.DiskNumber }; if($phys -and $phys.MediaType -ne 'HDD' -and $phys.BusType -notin @('Virtual','FileBackedVirtual')){ try { Optimize-Volume -DriveLetter $v.DriveLetter -ReTrim -ErrorAction Stop | Out-Null; $done=$true } catch {} } } }; if($done){ Set-Content -Path $stampFile -Value (Get-Date -Format s) -Force; 'TRIM_DONE' } else { 'NO_SSD' }"`) do set "TRIM_STATUS=%%a"
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

REM  3.4 - Native NVMe FeatureManagement (nvmedisk.sys)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du pilote NVMe natif (nvmedisk.sys)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1853569164 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 156965516 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 735209102 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1176759950 /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Native NVMe actif - IOPS potentiels plus eleves%COLOR_RESET%

REM  3.5 - IoRing + Storport Queue
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation IoRing + Storport tweaks...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storport\Parameters" /v "IoRingEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" /v "MaxOutstandingIORequests" /t REG_DWORD /d 256 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%IoRing + Storport optimise%COLOR_RESET%

REM  3.6 - Defragmentation automatique geree par Windows (TRIM automatique)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de la defragmentation automatique...%COLOR_RESET%
REM  Windows 11 detecte automatiquement les SSD et effectue du TRIM au lieu de defragmentation
REM  Il est important de NE PAS desactiver cette tache pour maintenir le TRIM automatique
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Enable >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Defragmentation automatique preservee ^(TRIM automatique actif pour SSD^)%COLOR_RESET%

call :FINISH_ACTION "Optimisations disques" "appliquees"
exit /b

:OPTIMISATIONS_GPU
cls
call :INIT_PROFILS
set "GPU_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 4 : OPTIMISATIONS GPU%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise votre carte graphique pour reduire l'input lag%COLOR_RESET%
echo %COLOR_WHITE%  et maximiser les performances en jeu.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% - latence GPU prioritaire, MaxFrameLatency/LOWLATENCY actifs%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% - VRR ON, veille GPU preservee%COLOR_RESET%
)
echo.

REM  4.1 - GameDVR desactive - Game Mode ON
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

REM  4.2 - Preferences DirectX (profil-aware : Gaming=latence, Normal=confort visuel)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Preferences DirectX Gaming ^(VRR OFF, Auto HDR OFF, Flip Model ON^)...%COLOR_RESET%
    reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "AutoHDREnable=0;VRROptimizeEnable=0;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX Gaming : VRR OFF, latence prioritaire, Flip Model actif%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Preferences DirectX Normal ^(Auto HDR, VRR ON, Flip Model^)...%COLOR_RESET%
    reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "AutoHDREnable=1;VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX Normal : Auto HDR actif, VRR ON, Flip Model actif%COLOR_RESET%
)

REM  4.3 - Mode MSI (GPU) et telemetrie NVIDIA
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation MSI (GPU) et desactivation telemetrie NVIDIA...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ New-ItemProperty -Path $p -Name 'MSISupported' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\NvControlPanel2\Client" /v "OptInOrOutPreference" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "FeatureControl" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "NvTeleSvc" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "DisplayWatchdog" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\NVIDIA Corporation\Global\NvSvc\Telemetry" /v "NvMessageBus" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode MSI GPU active et telemetrie NVIDIA desactivee%COLOR_RESET%

REM  4.4 - Desactivation AMD telemetry
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie AMD...%COLOR_RESET%
reg add "HKLM\SOFTWARE\AMD\CN" /v "CollectGIData" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\ATI ACE\AUEPLauncher" /v "ReportProcessedEvents" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Telemetrie AMD desactivee%COLOR_RESET%

REM  4.5 - NVIDIA Low Latency
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des optimisations Low Latency NVIDIA...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /t REG_DWORD /d 1 /f >nul 2>&1
    for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
        reg add "%%K" /v LOWLATENCY /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%K" /v Node3DLowLatency /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%K" /v D3PCLatency /t REG_DWORD /d 1 /f >nul 2>&1
        reg add "%%K" /v F1TransitionLatency /t REG_DWORD /d 1 /f >nul 2>&1
    )
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Low Latency active - Reduction de l'input lag ^(Gaming^)%COLOR_RESET%
) else (
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /f >nul 2>&1
    for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
        reg delete "%%K" /v LOWLATENCY /f >nul 2>&1
        reg delete "%%K" /v Node3DLowLatency /f >nul 2>&1
        reg delete "%%K" /v D3PCLatency /f >nul 2>&1
        reg delete "%%K" /v F1TransitionLatency /f >nul 2>&1
    )
    echo %COLOR_CYAN%[Normal]%COLOR_RESET% %COLOR_WHITE%Low Latency Gaming supprime - Veille GPU reactivee%COLOR_RESET%
)

REM  4.6 - HAGS Enable
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la planification GPU acceleree (HAGS)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%HAGS active - Latence GPU reduite%COLOR_RESET%

REM  4.7 - Preemption GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la preemption GPU...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Preemption GPU activee%COLOR_RESET%

REM  4.8 - NVIDIA Profile Inspector
REM  Cette section applique un profil d'optimisation NVIDIA pour reduire l'input lag.
if "!HAS_NVIDIA!"=="1" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%GPU NVIDIA detecte - Configuration NVIDIA Profile Inspector...%COLOR_RESET%

        REM Utilisation de Windows\Temp car le %%TEMP%% utilisateur peut etre sur un RamDisk ou lecteur non mappe en Admin
        set "NPI_DIR=%SystemRoot%\Temp\NPI_%RANDOM%_%RANDOM%"
        set "NPI_EXE_SRC=%~dp0Tools\NVIDIA Inspector\nvidiaProfileInspector.exe"
        set "NPI_PROFILE_SRC=%~dp0Tools\NVIDIA Inspector\Kaylers_profile.nip"
        if not exist "!NPI_DIR!" mkdir "!NPI_DIR!" >nul 2>&1

        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Preparation de NVIDIA Profile Inspector et du profil...%COLOR_RESET%
        REM Priorite aux fichiers locaux livres avec le script, telechargement GitHub en secours.
        if exist "!NPI_EXE_SRC!" copy /Y "!NPI_EXE_SRC!" "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
        if exist "!NPI_PROFILE_SRC!" copy /Y "!NPI_PROFILE_SRC!" "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
        if not exist "!NPI_DIR!\nvidiaProfileInspector.exe" curl -fsSL "https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/NVIDIA%%20Inspector/nvidiaProfileInspector.exe" -o "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
        if not exist "!NPI_DIR!\Kaylers_profile.nip" curl -fsSL "https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/NVIDIA%%20Inspector/Kaylers_profile.nip" -o "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1

        set "NPI_VALID=1"
        if exist "!NPI_DIR!\nvidiaProfileInspector.exe" (
            for %%A in ("!NPI_DIR!\nvidiaProfileInspector.exe") do if %%~zA LSS 10000 set "NPI_VALID=0"
        ) else (
            set "NPI_VALID=0"
        )

        if exist "!NPI_DIR!\Kaylers_profile.nip" (
            for %%A in ("!NPI_DIR!\Kaylers_profile.nip") do if %%~zA LSS 100 set "NPI_VALID=0"
        ) else (
            set "NPI_VALID=0"
        )

        REM NPI v3 a retire temporairement l'import CLI avant sa restauration en v3.0.1.10.
        REM Refuser explicitement ces versions evite un succes apparent sans profil importe.
        set "NPI_CLI_SUPPORTED=0"
        if "!NPI_VALID!"=="1" (
            powershell -NoProfile -Command "try { $v=[version](Get-Item -LiteralPath (Join-Path $env:NPI_DIR 'nvidiaProfileInspector.exe')).VersionInfo.FileVersion; if($v.Major -eq 3 -and $v -lt [version]'3.0.1.10'){exit 1}; exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! EQU 0 set "NPI_CLI_SUPPORTED=1"
        )

        if "!NPI_VALID!"=="1" (
            if "!NPI_CLI_SUPPORTED!"=="1" (
                echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application du profil NVIDIA optimise...%COLOR_RESET%
                start /wait "" "!NPI_DIR!\nvidiaProfileInspector.exe" -silentImport "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
                if !errorlevel! EQU 0 (
                    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA Profile Inspector applique avec succes%COLOR_RESET%
                ) else (
                    set "GPU_SECTION_ERROR=1"
                    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%NVIDIA Profile Inspector n'a pas pu importer le profil.%COLOR_RESET%
                )
            ) else (
                set "GPU_SECTION_ERROR=1"
                echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Version NVIDIA Profile Inspector incompatible avec l'import silencieux.%COLOR_RESET%
                echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Utilisez NPI 2.4.x ou NPI 3.0.1.10 et version ulterieure.%COLOR_RESET%
            )
        ) else (
            set "GPU_SECTION_ERROR=1"
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement ou fichiers corrompus.%COLOR_RESET%
        )

        REM Nettoyage
        del /f /q "!NPI_DIR!\*.*" >nul 2>&1
        rmdir "!NPI_DIR!" >nul 2>&1
        set "NPI_EXE_SRC="
        set "NPI_PROFILE_SRC="
        set "NPI_CLI_SUPPORTED="
    ) else (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration ciblee des valeurs NVIDIA modifiees par le profil Gaming...%COLOR_RESET%
        set "NPI_EXE_SRC=%~dp0Tools\NVIDIA Inspector\nvidiaProfileInspector.exe"
        set "NPI_PROFILE_SRC=%~dp0Tools\NVIDIA Inspector\Kaylers_profile.nip"
        if exist "!NPI_EXE_SRC!" if exist "!NPI_PROFILE_SRC!" (
            REM Verifie dans l'assembly fourni : ResetValue appelle DRS_RestoreProfileDefaultSetting puis SaveSettings.
            REM Le NIP importe Base Profile ; les memes SettingID sont donc bien restaures au defaut du pilote.
            REM Les personnalisations NVIDIA utilisant d'autres SettingID ne sont pas touchees.
            powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $a=[Reflection.Assembly]::LoadFrom($env:NPI_EXE_SRC); $t=$a.GetType('nspector.Common.DrsServiceLocator'); $svc=$t.GetField('SettingService',[Reflection.BindingFlags]'Public,NonPublic,Static').GetValue($null); [xml]$x=Get-Content -LiteralPath $env:NPI_PROFILE_SRC -Raw; $ids=@($x.SelectNodes('/ArrayOfProfile/Profile/Settings/ProfileSetting/SettingID') | ForEach-Object {[uint32]$_.InnerText} | Sort-Object -Unique); if(-not $svc -or $ids.Count -eq 0){exit 2}; foreach($id in $ids){$removed=$false; $svc.ResetValue('Base Profile',$id,[ref]$removed)}; exit 0 } catch { exit 1 }" >nul 2>&1
            if !errorlevel! EQU 0 (
                echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Valeurs NVIDIA Gaming restaurees aux valeurs du pilote ^(Normal^)%COLOR_RESET%
            ) else (
                set "GPU_SECTION_ERROR=1"
                echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de restaurer les valeurs NVIDIA du profil Gaming.%COLOR_RESET%
            )
        ) else (
            set "GPU_SECTION_ERROR=1"
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%NVIDIA Profile Inspector ou le profil source est introuvable.%COLOR_RESET%
        )
        set "NPI_EXE_SRC="
        set "NPI_PROFILE_SRC="
        set "NPI_VALID="
    )
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%GPU NVIDIA non detecte - NVIDIA Profile Inspector ignore%COLOR_RESET%
)

if "!GPU_SECTION_ERROR!"=="0" (
    set "GPU_SECTION_ERROR="
    call :FINISH_ACTION "Optimisations GPU" "terminees"
    exit /b 0
)
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_RED%[ERREUR]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations GPU appliquees partiellement%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
set "GPU_SECTION_ERROR="
call :PROMPT_MANUAL_REBOOT
exit /b 1

:OPTIMISATIONS_RESEAU
cls
call :INIT_PROFILS
set "NETWORK_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 5 : OPTIMISATIONS RESEAU ET INTERNET%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la pile TCP/IP et la carte reseau.%COLOR_RESET%
echo %COLOR_WHITE%  Profil GAMING = ping/reactivite max ; profil NORMAL = stabilite et debit preserves.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

if "!SKIP_PAUSE!"=="0" if "!DETECTE_PORTABLE!"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%PC PORTABLE DETECTE - MODE MANUEL%COLOR_RESET%
    echo.
    echo %COLOR_WHITE%Vous etes sur un %COLOR_CYAN%PC Portable%COLOR_RESET%. Les optimisations reseau peuvent impacter :%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Wi-Fi%COLOR_RESET% : Nagle/DelACK OFF peut destabiliser le Wi-Fi%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Batterie%COLOR_RESET% : certains reglages MaxPerf NIC augmentent la consommation%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Debit%COLOR_RESET% : profil GAMING privilegie le ping au debit%COLOR_RESET%
    echo.
)

if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% - BBR2, NIC optimisee pour reponse instantanee%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% - BBR2, stabilite et autonomie preservees%COLOR_RESET%
)
if "!PROFIL_POWER!"=="0" (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%MAX PERF%COLOR_RESET%%COLOR_WHITE% - economies NIC coupees, RSC/LSO selon usage%COLOR_RESET%
) else (
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%ECO%COLOR_RESET%%COLOR_WHITE% - RSC/LSO/checksum ON, autonomie prioritaire%COLOR_RESET%
)
if "!IS_GAMING_ECO!"=="1" (
    echo %COLOR_YELLOW%  [*]%COLOR_RESET% %COLOR_WHITE%GAMING + ECO : Nagle natif ^(batterie^), initialrto a 3000ms ^(Windows default documente, optimal reseau^) et maxsyn agressif conserve.%COLOR_RESET%
    echo %COLOR_WHITE%     Latence GPU/input conservee, debit/stabilite mobile favorises.%COLOR_RESET%
)
echo.

REM  5.1 - MMCSS reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration MMCSS reseau...%COLOR_RESET%
REM  SystemResponsiveness : Gaming = 10 (10% CPU aux taches faible priorite). Normal = 20 (defaut Windows).
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 20 /f >nul 2>&1
)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%MMCSS reseau configure%COLOR_RESET%

REM  5.2 - Pile TCP/IP Win11
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Pile TCP/IP Win11 ^(BBR2, fix loopback localhost^)...%COLOR_RESET%
netsh int tcp set global autotuninglevel=normal >nul 2>&1
REM Conserve : "set heuristics" pilote encore forcews sur certaines builds/drivers.
netsh int tcp set heuristics disabled >nul 2>&1
netsh int ipv4 set global loopbacklargemtu=disabled >nul 2>&1
netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1
REM minRto n'est pas un parametre 'set global' valide (uniquement 'set supplemental') et 300ms est deja le plancher par defaut : ligne retiree (no-op).

if "!PROFIL_USAGE!"=="0" (
    netsh int tcp set global rss=enabled initialrto=3000 nonsackrttresiliency=disabled maxsynretransmissions=2 >nul 2>&1
) else (
    REM initialRTO=3000 = default Windows documente (RFC 6298, Win 7..11 24H2+). Plage autorisee netsh 300-3000ms ; plancher RTO reste 300ms cote pile TCP/IP. 3000 est la valeur recommandee pour les deux profils (MS + avis reseau pro : un RTO plus court n'apporte pas de gain reel sur la latence en jeu et augmente les retransmissions SYN prematures sur les reseaux instables).
    netsh int tcp set global rss=enabled initialrto=3000 nonsackrttresiliency=disabled maxsynretransmissions=2 >nul 2>&1
)
if "!PROFIL_POWER!"=="0" (
    if "!PROFIL_USAGE!"=="0" (
        netsh int tcp set global rsc=disabled >nul 2>&1
    ) else (
        netsh int tcp set global rsc=enabled >nul 2>&1
    )
) else (
    netsh int tcp set global rsc=enabled >nul 2>&1
)

REM  BBR2 applique sur les templates valides listes par "netsh int tcp set supplemental ?".
REM  template=custom n'existe pas sur Win11 (invalide) -> remplace par InternetCustom + DatacenterCustom
netsh int tcp set supplemental template=automatic congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=internet congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=internetcustom congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=datacenter congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=datacentercustom congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=compat congestionprovider=bbr2 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%BBR2 actif ^(Automatic, Internet, InternetCustom, Datacenter, DatacenterCustom, Compat^)%COLOR_RESET%

REM  TCP Pacing + ECN : essentiels pour BBR2 (pacing = parametre principal de BBR, ECN = signaux precoces congestion)
netsh int tcp set global pacingprofile=always >nul 2>&1
netsh int tcp set global ecncapability=enabled >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%TCP Pacing (always) + ECN Capability actives pour BBR2%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%loopbacklargemtu reste desactive pour eviter les bugs locaux%COLOR_RESET%

REM  5.3 - Parametres TCP registre
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Parametres TCP registre...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    REM LanmanServer Size=1 = defaut Win11 client Minimize Memory, pas de suppression hors section restauration.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastSendDatagramThreshold /t REG_DWORD /d 1500 /f >nul 2>&1
) else (
    REM Suppression -> retour au defaut Windows (1024). Les datagrammes UDP > 1024 octets
    REM empruntent alors le chemin lent (pended I/O). C'est le comportement normal attendu.
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastSendDatagramThreshold /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SackOpts /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUDiscovery /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDataRetransmissions /t REG_DWORD /d 5 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Registre TCP configure%COLOR_RESET%
REM  5.4 - MSI Mode cartes reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation MSI Mode cartes reseau...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ New-ItemProperty -Path $p -Name 'MSISupported' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%MSI Mode active sur cartes reseau%COLOR_RESET%


REM  5.5 - Optimisation BITS
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation du service BITS...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "EnableBypassProxyForLocal" /t REG_DWORD /d 1 /f >nul 2>&1
REM  Pas de suppression ici : les cles invalides/anciennes sont laissees a une section restauration/nettoyage.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%BITS optimise ^(aucune suppression hors restauration^)%COLOR_RESET%

REM  5.6 - Nagle/DelACK (ECO/Normal->defaut natif, Gaming+MaxPerf->agressif)
if "!PROFIL_POWER!"=="1" (
    echo %COLOR_CYAN%[ECO]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK : suppression des surcharges pour autonomie Wi-Fi ^(defaut Windows^)%COLOR_RESET%
    call :RESET_NAGLE_PROFILE
) else if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation Nagle et DelACK agressif ^(Gaming+MaxPerf^)...%COLOR_RESET%
    call :SET_NAGLE_PROFILE 1 1 0
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK optimises%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration Nagle/DelACK valeurs defaut ^(Normal^)...%COLOR_RESET%
    call :RESET_NAGLE_PROFILE
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK restaures ^(defauts Windows^)%COLOR_RESET%
)

REM  5.7 - Optimisation cartes reseau
if "!PROFIL_POWER!"=="0" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Gaming+MaxPerf ^(RSC/LSO et Interrupt Moderation OFF, ITR 200, EEE OFF^)...%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Normal+MaxPerf ^(RSC/LSO ON, ITR defaut, EEE OFF^)...%COLOR_RESET%
    )
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Eco ^(RSC/LSO/checksum ON, energie preservee^)...%COLOR_RESET%
)
call :SET_NIC_PROFILE !PROFIL_POWER! !PROFIL_USAGE!
if !errorlevel! NEQ 0 (
    set "NETWORK_SECTION_ERROR=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Configuration NIC appliquee partiellement.%COLOR_RESET%
) else (
    if "!PROFIL_POWER!"=="0" (
        if "!PROFIL_USAGE!"=="0" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour latence gaming ^(Gaming+MaxPerf^)%COLOR_RESET%
        ) else (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour usage general ^(Normal+MaxPerf^)%COLOR_RESET%
        )
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour debit/stabilite/autonomie ^(Eco^)%COLOR_RESET%
    )
)
REM  5.8 - Gestion energie USB (impacte adaptateurs Wi-Fi USB, clavier, souris)
set "USB_POWER_DEFERRED=0"
if "!PROFIL_POWER!"=="1" if "!SKIP_PAUSE!"=="1" set "USB_POWER_DEFERRED=1"
if "!USB_POWER_DEFERRED!"=="1" (
    REM En TOUT_OPTIMISER ECO, la section 7 restaure deja l'USB sur le plan Equilibre actif.
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Restauration USB differee a la section Energie pour eviter un double passage.%COLOR_RESET%
) else (
    if "!PROFIL_POWER!"=="1" (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Preservation gestion energie USB ^(selective suspend conserve^)...%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation gestion energie USB ^(selective suspend + USB 3 LPM^)...%COLOR_RESET%
    )
    call :SET_USB_POWER !PROFIL_POWER!
    if "!PROFIL_POWER!"=="1" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%USB Selective Suspend preserve - Economie batterie maintenue%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion energie USB desactivee - Latence minimale%COLOR_RESET%
    )
)
set "USB_POWER_DEFERRED="
REM  5.9 - QoS Fortnite DSCP 46 (Gaming uniquement)
if "!PROFIL_USAGE!"=="0" (
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
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%QoS Fortnite activee ^(Gaming^)%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression QoS Fortnite ^(Normal^)...%COLOR_RESET%
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_UDP" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\QoS\Fortnite_TCP" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%QoS Fortnite supprimee%COLOR_RESET%
)

REM  5.10 - Nettoyage des protocoles reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des protocoles reseau inutiles (Bindings)...%COLOR_RESET%
powershell -NoProfile -Command "Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false } | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lldp','ms_implat' -ErrorAction SilentlyContinue }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Bindings reseau nettoyes (LLDP, MS_IMPLAT)%COLOR_RESET%

REM  5.11 - Desactivation NetBIOS over TCP/IP
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de NetBIOS over TCP/IP...%COLOR_RESET%
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s ^| findstr /i /r "\\Tcpip_.*$" 2^>nul') do (
  reg add "%%i" /v NetbiosOptions /t REG_DWORD /d 2 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NetBIOS desactive%COLOR_RESET%

REM  5.12 - RssBaseCpu (Gaming : interrupts NIC decales du core 0)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%RssBaseCpu=1 ^(Gaming : interrupts NIC sur CPU 1+^)...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v RssBaseCpu /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%RssBaseCpu configure ^(Gaming^)%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression RssBaseCpu ^(Normal : retour au defaut Windows^)...%COLOR_RESET%
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v RssBaseCpu /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%RssBaseCpu supprime ^(defaut Windows restaure^)%COLOR_RESET%
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Mise a jour des politiques groupe (gpupdate)...%COLOR_RESET%
gpupdate /target:computer /force >nul 2>&1
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1
nbtstat -RR >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Pile reseau optimisee (DNS/NetBIOS purges)%COLOR_RESET%

if "!NETWORK_SECTION_ERROR!"=="1" (
    set "NETWORK_SECTION_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Optimisations reseau appliquees partiellement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    exit /b 1
)
set "NETWORK_SECTION_ERROR="
call :FINISH_ACTION "Optimisations reseau" "appliquees"
exit /b 0

:OPTIMISATIONS_PERIPHERIQUES
cls
call :INIT_PROFILS
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 6 : OPTIMISATIONS CLAVIER ET SOURIS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la reactivite des peripheriques d'entree%COLOR_RESET%
echo %COLOR_WHITE%  (souris, clavier) et ajuste l'acceleration selon le profil.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

REM  Avertissement mode manuel sur PC portable : profil NORMAL conserve une acceleration trackpad legere.
if "!SKIP_PAUSE!"=="0" if "!DETECTE_PORTABLE!"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%PC PORTABLE DETECTE - MODE MANUEL%COLOR_RESET%
    echo.
    echo %COLOR_WHITE%Vous etes sur un %COLOR_CYAN%PC Portable%COLOR_RESET%. Les optimisations peripheriques peuvent impacter :%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%Trackpad%COLOR_RESET% : Acceleration OFF rend le trackpad moins naturel%COLOR_RESET%
    echo %COLOR_WHITE%  - %COLOR_YELLOW%DPI Scaling%COLOR_RESET% : Win8 Scaling OFF peut affecter l'affichage sur ecran haute densite%COLOR_RESET%
    echo.
)

if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%GAMING%COLOR_RESET%%COLOR_WHITE% - souris 1:1 sans acceleration%COLOR_RESET%
) else (
    if "!DETECTE_PORTABLE!"=="1" (
        echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% - trackpad optimise, acceleration legere%COLOR_RESET%
    ) else (
        echo %COLOR_WHITE%  Profil actif : %STYLE_BOLD%NORMAL%COLOR_RESET%%COLOR_WHITE% - souris 1:1 sans acceleration%COLOR_RESET%
    )
)
echo.

REM  6.1 - Souris optimisee
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la reactivite souris...%COLOR_RESET%
set "KEEP_MOUSE_ACCEL=0"
if "!PROFIL_USAGE!"=="1" if "!DETECTE_PORTABLE!"=="1" set "KEEP_MOUSE_ACCEL=1"
if "!KEEP_MOUSE_ACCEL!"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration souris trackpad ^(acceleration legere conservee^)...%COLOR_RESET%
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "1" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "4" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "12" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseDelay" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "SnapToDefaultButton" /t REG_SZ /d "0" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Acceleration legere conservee - Trackpad optimise%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation acceleration souris ^(mouvement 1:1^)...%COLOR_RESET%
    reg add "HKCU\Control Panel\Mouse" /v "MouseSpeed" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold1" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseThreshold2" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "MouseDelay" /t REG_SZ /d "0" /f >nul 2>&1
    reg add "HKCU\Control Panel\Mouse" /v "SnapToDefaultButton" /t REG_SZ /d "0" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Acceleration souris desactivee - Mouvement 1:1 actif%COLOR_RESET%
)
set "KEEP_MOUSE_ACCEL="
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /t REG_DWORD /d 20 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseTransmitTimeout" /t REG_DWORD /d 0 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /t REG_DWORD /d 20 /f >nul 2>&1
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "ThreadPriority" /t REG_DWORD /d 31 /f >nul 2>&1
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression files souris/clavier Gaming ^(Normal^)...%COLOR_RESET%
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseDataQueueSize" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "MouseTransmitTimeout" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters" /v "KeyboardDataQueueSize" /f >nul 2>&1
    reg delete "HKLM\SYSTEM\CurrentControlSet\Services\mouclass\Parameters" /v "ThreadPriority" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Files souris/clavier restaurees ^(defauts Windows^)%COLOR_RESET%
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsolutePointerAsAbsolute" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsoluteAsRelative" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres souris et HID optimises%COLOR_RESET%

REM  6.2 - Clavier optimise
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la reactivite clavier...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%File clavier reduite ^(20^) - Profil GAMING%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%File clavier ignoree - Profil NORMAL%COLOR_RESET%
)

REM  6.3 - Win8 Scaling (Profil GAMING uniquement)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation du Scaling Windows ^(Win8 DPI Scaling^)...%COLOR_RESET%
    reg add "HKCU\Control Panel\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 96 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Win8 Scaling active ^(Mode 1:1 force^)%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression Win8 DPI Scaling Gaming ^(Normal^)...%COLOR_RESET%
    reg delete "HKCU\Control Panel\Desktop" /v Win8DpiScaling /f >nul 2>&1
    reg delete "HKCU\Control Panel\Desktop" /v LogPixels /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DPI Scaling restaure ^(defauts Windows^)%COLOR_RESET%
)

REM  6.4 - MSI Mode Universel (Latence Peripheriques)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du MSI Mode USB...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class USB -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ New-ItemProperty -Path $p -Name 'MSISupported' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Interruptions MSI USB activees%COLOR_RESET%



REM  6.5 - Accessibilite OFF
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des raccourcis d'accessibilite...%COLOR_RESET%
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\StickyKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\FilterKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "Flags" /t REG_SZ /d "0" /f >nul 2>&1
reg add "HKCU\Control Panel\Accessibility\ToggleKeys" /v "HotkeyActive" /t REG_SZ /d "0" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourcis d'accessibilite desactives%COLOR_RESET%

REM  6.6 - HID parse optimise
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableInputDelayOptimization" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\hidparse\Parameters" /v "EnableBufferedInput" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%HID Parse et Input Delay optimises%COLOR_RESET%

call :FINISH_ACTION "Optimisations peripheriques" "appliquees"
exit /b 0

:TOGGLE_ECONOMIES_ENERGIE
set "SKIP_PAUSE=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section permet de gerer manuellement les economies d'energie.%COLOR_RESET%
echo %COLOR_WHITE%  Desactiver = mode MAX PERF ; l'usage sera demande pour le bon tuning NIC.%COLOR_RESET%
echo %COLOR_WHITE%  Restaurer  = remet les parametres d'energie par defaut Windows.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_RED%Desactiver les economies d'energie (Performances maximales)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Restaurer les economies d'energie (Parametres par defaut)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! EQU 3 goto :MENU_PRINCIPAL
if !errorlevel! EQU 2 goto :DO_RESTAURER_ECONOMIES
if !errorlevel! EQU 1 goto :DO_DESACTIVER_ECONOMIES
goto :TOGGLE_ECONOMIES_ENERGIE

:DO_RESTAURER_ECONOMIES
call :RESTAURER_ECONOMIES_ENERGIE
goto :TOGGLE_ECONOMIES_ENERGIE

:DO_DESACTIVER_ECONOMIES
set "PROFIL_POWER=0"
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - ENERGIE" "USAGE"
if !errorlevel! NEQ 0 goto :TOGGLE_ECONOMIES_ENERGIE
call :DESACTIVER_ECONOMIES_ENERGIE
goto :TOGGLE_ECONOMIES_ENERGIE

:DESACTIVER_ECONOMIES_ENERGIE
set "PROFIL_POWER=0"
call :INIT_PROFILS
set "POWER_SECTION_ERROR=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 7 : DESACTIVATION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive les fonctions d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  pour maintenir les performances maximales en permanence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

REM  7.1 - Power States NVMe agressifs (latence minimale)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Power States NVMe optimises ^(IdlePowerMode=0^)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerMode" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power States NVMe agressifs appliques%COLOR_RESET%

REM  7.2 - Activation du plan Ultimate Performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du plan Ultimate Performance...%COLOR_RESET%
set "TARGET_GUID="
REM  Probe par GUID (fiable quelle que soit la locale Windows)
for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "e9a42b02-d5df-448d-aa00-03f14749eb61"') do (set "TARGET_GUID=%%G" & set "TARGET_GUID=!TARGET_GUID: =!")
if not defined TARGET_GUID (
    REM Plan duplique par une execution precedente GUID custom 99999999-...
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "99999999-9999-9999-9999-999999999999"') do (set "TARGET_GUID=%%G" & set "TARGET_GUID=!TARGET_GUID: =!")
)
if not defined TARGET_GUID (
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >nul 2>&1
    set "TARGET_GUID=99999999-9999-9999-9999-999999999999"
)
powercfg /setactive !TARGET_GUID! >nul 2>&1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan Ultimate Performance actif%COLOR_RESET%
) else (
    set "POWER_SECTION_ERROR=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible d'activer le plan Ultimate Performance.%COLOR_RESET%
)

REM  7.3 - GPU Power Management (ULPS & PowerMizer)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'ULPS (AMD) et configuration PowerMizer (NVIDIA)...%COLOR_RESET%
REM  ULPS OFF - AMD
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v EnableUlps /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "%%K" /v EnableUlps_NA /t REG_DWORD /d 0 /f >nul 2>&1
)
REM  PowerMizer - NVIDIA (Applique a toutes les instances GPU)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PowerMizerEnable /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevel /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PowerMizerLevelAC /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v PerfLevelSrc /t REG_DWORD /d 0x2222 /f >nul 2>&1
  reg add "%%K" /v DisableDynamicPstate /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "%%K" /v RmDisableRegistryCaching /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%GPU Power Management optimise%COLOR_RESET%

REM  7.4 - Parametres avances du plan d'alimentation (user standard)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration avancee du plan d'alimentation...%COLOR_RESET%

powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1

REM  Veille hybride : desactivee (inutile si hibernate est off)
powercfg /setacvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 94ac6d29-73ce-41a6-809f-6363ba21b47e 0 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 238c9fa8-0aad-41ed-83f4-97be242c8f20 9d7815a6-7ee4-497e-8888-515a05f02364 0 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 0853a681-27c8-4100-a2fd-82013e970683 0 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 bc5038f7-23e0-4960-96da-33abaf5935ec 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 94d3a615-a899-4ac5-ae2b-e4d8f634367f 1 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 7516b95f-f776-4464-8c53-06167f40cc99 3c0bc021-c8a8-4e07-a973-6b14cbcb2b7e 600 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 10778347-1370-4ee0-8bbd-33bdacaade49 1 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 9596fb26-9850-41fd-ac3e-f7c3c00afd4b 34c7b99f-9a6d-4b3c-8dc7-b6693b78cef4 0 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 2 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 44f3beca-a7c0-460e-9df2-bb8b99e0cba6 3619c3f2-afb2-4afc-b0e9-e7fef372de36 2 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT c763b4ec-0e50-4b6b-9bed-2b92a6ee884e 7ec1751b-60ed-4588-afb5-9819d3d77d90 3 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT f693fb01-e858-4f00-b20f-f30e12ac06d6 191f65b5-d45c-4a4f-8aae-1ab8bfd980e6 1 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 3 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT e276e160-7cb0-43c6-b20b-73f5dce39954 a1662ab2-9d34-4e53-ba8b-2639b9e20857 3 >nul 2>&1

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres avances du plan d'alimentation appliques%COLOR_RESET%

REM  7.5 - Optimisations CPU (Intel Hybrid + AMD Core Parking)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations CPU specifiques (Intel Hybrid / AMD Ryzen)...%COLOR_RESET%

REM  Intel Hybrid CPUs (Alder Lake/Raptor Lake/Meteor Lake)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du profil processeur (performances maximales)...%COLOR_RESET%
REM  E-cores (0cc5b647...-583) : 100 = aucun E-core parque
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking E-cores configure%COLOR_RESET%

REM  Desactivation Core Parking (Intel + AMD)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation Core Parking (Intel Hybrid + AMD Ryzen)...%COLOR_RESET%
REM  P-cores (0cc5b647...-584) : 100 = aucun P-core parque. Meme GUID pour Intel Hybrid et AMD Ryzen
REM  (le parking core utilise le meme sous-groupe SUB_PROCESSOR 0cc5b647 sur les deux architectures)
REM  GUID SUB_PROCESSOR en dur (alias SUB_PROCESSOR non fiable selon la locale Windows)
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking desactive (AMD Ryzen optimise)%COLOR_RESET%

REM  7.6 - Desactivation economies d'energie Device Manager (ACPI/HID/PCI/USB)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de l'alimentation des peripheriques (Device Manager)...%COLOR_RESET%
powershell -NoProfile -Command "$p=@('ACPI','HID','PCI','USB','USBSTOR'); foreach($s in $p){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Enum\$s"" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' -or $_.PSChildName -eq 'WDF' } | ForEach-Object { $rp = $_.Name; if($_.PSChildName -eq 'Device Parameters'){ reg add ""$rp"" /v ""EnhancedPowerManagementEnabled"" /t REG_DWORD /d 0 /f >$null; reg add ""$rp"" /v ""SelectiveSuspendEnabled"" /t REG_DWORD /d 0 /f >$null; reg add ""$rp"" /v ""SelectiveSuspendOn"" /t REG_DWORD /d 0 /f >$null; reg add ""$rp"" /v ""WaitWakeEnabled"" /t REG_DWORD /d 0 /f >$null } else { reg add ""$rp"" /v ""IdleInWorkingState"" /t REG_DWORD /d 0 /f >$null } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie Device Manager desactivees (HID/PCI/USB)%COLOR_RESET%

REM  7.7 - Desactivation du demarrage rapide Fast Startup
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du demarrage rapide (Fast Startup)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Demarrage rapide desactive - Redemarrages propres%COLOR_RESET%

REM  7.8 - Hibernation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'hibernation...%COLOR_RESET%
powercfg /hibernate off >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Hibernation desactivee - Espace disque libere%COLOR_RESET%

REM  7.9 - Configuration generale du systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du systeme d'alimentation...%COLOR_RESET%
REM  ASPM est configure correctement a la section 7.18 ci-dessous avec SUB_PCIEXPRESS (501a4d13...)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1

REM  7.10 - Desactivation des Timer Coalescing et DPC
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des Timer Coalescing et optimisation DPC...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v MinimumDpcRate /t REG_DWORD /d 1 /f >nul 2>&1
REM  DisableTsx - Intel Transactional Synchronization Extensions (Intel uniquement, pas AMD)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
REM  TimerCoalescing - Options (une seule activee a la fois, choisis celle qui te convient le mieux)
REM  Option 1 (RECOMMANDEE si OK) : 64 bytes REG_BINARY - semble ameliorer le feeling souris / input lag, ne crashe pas
REM  reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_BINARY /d 0000000000000000000000000000000000000000000000000000000000000000 /f >nul 2>&1
REM  Option 2 (A TESTER) : 80 bytes REG_BINARY - version "complete" du noyau, mais PEUT CRASHER ou rendre instable sur certaines configs
REM  reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_BINARY /d 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f >nul 2>&1
REM  Option 3 (A TESTER) : REG_DWORD 1 - effet inconnu/noque (le noyau lit du REG_BINARY, mais a tester si mieux que option 1)
REM  reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_DWORD /d 1 /f >nul 2>&1
REM  Option 4 (A TESTER) : REG_DWORD 0 - retour au comportement par defaut (coalescing actif, pertes possibles)
REM  reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_DWORD /d 0 /f >nul 2>&1
REM  Option 5 : Supprimer la valeur (comportement noyau par defaut) - utilise reg delete ci-dessous si necessaire
REM  reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\ModernSleep" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\ControlSet001\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
REM  DisableDynamicTick : desactive l'horloge dynamique (interruptions plus predictibles)
bcdedit /set disabledynamictick yes >nul 2>&1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Timer Coalescing desactive - Latence reduite%COLOR_RESET%
) else (
    set "POWER_SECTION_ERROR=1"
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%Reglages registre appliques, mais DynamicTick n'a pas pu etre modifie.%COLOR_RESET%
)

REM  7.11 - Installation SetTimerResolution
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration de SetTimerResolution...%COLOR_RESET%
set "STR_DIR=%ProgramFiles%\SetTimerResolution"
set "STR_OLD_DIR=%ProgramFiles%\OptimizerAllInOne"
set "STR_EXE=%STR_DIR%\SetTimerResolution.exe"
set "STR_SRC=%~dp0Tools\Timer & Interrupt\SetTimerResolution.exe"
set "STR_STARTUP_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
REM  Le dossier de destination doit exister AVANT toute copie/telechargement (sinon echec)
if not exist "%STR_DIR%" mkdir "%STR_DIR%" >nul 2>&1
if not exist "%STR_EXE%" if exist "%STR_OLD_DIR%\SetTimerResolution.exe" move /Y "%STR_OLD_DIR%\SetTimerResolution.exe" "%STR_EXE%" >nul 2>&1
if exist "%STR_OLD_DIR%" rmdir "%STR_OLD_DIR%" >nul 2>&1
if exist "%STR_EXE%" for %%A in ("%STR_EXE%") do if %%~zA LSS 10000 del /f /q "%STR_EXE%" >nul 2>&1
if exist "%STR_EXE%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution deja installe dans %STR_DIR%%COLOR_RESET%
) else (
    REM Priorite a la copie locale (livree avec le script), telechargement GitHub en secours
    if exist "%STR_SRC%" copy /Y "%STR_SRC%" "%STR_EXE%" >nul 2>&1
    if exist "%STR_EXE%" for %%A in ("%STR_EXE%") do if %%~zA LSS 10000 del /f /q "%STR_EXE%" >nul 2>&1
    if not exist "%STR_EXE%" powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $f='%STR_EXE%'; Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe' -OutFile $f -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $f).Length -lt 10000){Remove-Item -LiteralPath $f -Force; exit 2}; exit 0 } catch { Remove-Item -LiteralPath '%STR_EXE%' -Force -ErrorAction SilentlyContinue; exit 1 }" >nul 2>&1
    if exist "%STR_EXE%" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution installe dans %STR_DIR%%COLOR_RESET%
    ) else (
        set "POWER_SECTION_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de l'installation de SetTimerResolution%COLOR_RESET%
    )
)
if exist "%STR_EXE%" (
    taskkill /F /IM SetTimerResolution.exe >nul 2>&1
    call :CREATE_STR_STARTUP_SHORTCUT
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci SetTimerResolution configure ^(5070^)%COLOR_RESET%
    ) else (
        set "POWER_SECTION_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de creer le raccourci SetTimerResolution.%COLOR_RESET%
    )
    start "" "%STR_EXE%" --resolution 5070 --no-console
    timeout /t 1 /nobreak >nul
    tasklist /fi "IMAGENAME eq SetTimerResolution.exe" 2>nul | find /i "SetTimerResolution.exe" >nul
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution active immediatement%COLOR_RESET%
    ) else (
        set "POWER_SECTION_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution ne semble pas rester actif.%COLOR_RESET%
    )
)

REM  7.12 - Desactivation du PDC et Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du Power Throttling (bridage CPU)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power Throttling desactive - CPU non bride%COLOR_RESET%

REM  7.13 - Desactivation ASPM
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation ASPM sur le bus PCI Express...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%ASPM desactive - Latence PCIe reduite%COLOR_RESET%

REM  7.14 - Optimisations stockage et disques
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations stockage ^(StorageD3 + HIPM/DIPM^)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; New-ItemProperty -Path $p -Name 'EnableHIPM' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'EnableDIPM' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'EnableHDDParking' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Stockage optimise - D3 Modern Standby OFF, HIPM/DIPM OFF%COLOR_RESET%

REM  7.15 - Optimisations avancees des services
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des limites de latence I/O ^(StorPort^)...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; New-ItemProperty -Path $p -Name 'IoLatencyCap' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Limites de latence stockage supprimees%COLOR_RESET%

REM  7.16 - GPU PreferMaxPerf
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration GPU en mode performances maximales...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PreferMaxPerf /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%GPU configure en mode performances maximales%COLOR_RESET%

REM  7.17 - PCI & peripheriques reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la mise en veille des peripheriques PCI...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "*WakeOnPattern" /t REG_DWORD /d 0 /f >nul 2>&1
)

REM  7.18 - Energie PCIe
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

REM  7.19 - Convergence reseau du profil Energie (parcours manuel uniquement)
REM  TOUT_OPTIMISER a deja applique la meme matrice dans la section Reseau.
if not "!AIO_MODE!"=="1" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Synchronisation du profil reseau avec MaxPerf...%COLOR_RESET%
    set "POWER_NETWORK_ERROR=0"
    if "!PROFIL_USAGE!"=="0" (
        netsh int tcp set global rsc=disabled >nul 2>&1
        if !errorlevel! NEQ 0 set "POWER_NETWORK_ERROR=1"
        call :SET_NAGLE_PROFILE 1 1 0
        if !errorlevel! NEQ 0 set "POWER_NETWORK_ERROR=1"
    ) else (
        netsh int tcp set global rsc=enabled >nul 2>&1
        if !errorlevel! NEQ 0 set "POWER_NETWORK_ERROR=1"
        call :RESET_NAGLE_PROFILE
        if !errorlevel! NEQ 0 set "POWER_NETWORK_ERROR=1"
    )
    call :SET_NIC_PROFILE 0 !PROFIL_USAGE!
    if !errorlevel! NEQ 0 set "POWER_NETWORK_ERROR=1"
    if "!POWER_NETWORK_ERROR!"=="1" (
        set "POWER_SECTION_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Profil reseau MaxPerf applique partiellement.%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil reseau MaxPerf synchronise%COLOR_RESET%
    )
    set "POWER_NETWORK_ERROR="
)

REM  Appliquer l'ensemble des modifications du plan d'alimentation en une seule fois
powercfg /S SCHEME_CURRENT >nul 2>&1
if !errorlevel! NEQ 0 set "POWER_SECTION_ERROR=1"

set "TARGET_GUID="
set "STR_EXE="
set "STR_OLD_DIR="
set "STR_STARTUP_LNK="
if "!POWER_SECTION_ERROR!"=="0" (
    set "POWER_SECTION_ERROR="
    call :FINISH_ACTION "Economies d'energie" "desactivees"
    exit /b 0
)
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_RED%[ERREUR]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Optimisations d'energie appliquees partiellement%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
set "POWER_SECTION_ERROR="
call :PROMPT_MANUAL_REBOOT
exit /b 1

:RESTAURER_ECONOMIES_ENERGIE
set "PROFIL_POWER=1"
call :INIT_PROFILS
set "POWER_RESTORE_ERROR=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 7 : RESTAURATION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section restaure les parametres d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  aux valeurs par defaut de Windows.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

REM  7.0 - Activer Equilibre sans effacer les plans OEM/personnalises.
REM  PowerRestoreDefaultPowerSchemes est volontairement exclu : l'API supprime TOUS les plans courants.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Selection du plan Equilibre sans supprimer les plans personnalises...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du plan Equilibre Windows...%COLOR_RESET%
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan Equilibre Windows actif%COLOR_RESET%
) else (
    set "POWER_RESTORE_ERROR=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible d'activer le plan Equilibre Windows.%COLOR_RESET%
)
REM Le plan Ultimate duplique est conserve : il peut etre reutilise sans proliferer les GUID.

REM  7.1 - Demarrage rapide (Fast Startup)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation du demarrage rapide (Fast Startup)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Demarrage rapide reactive%COLOR_RESET%

REM  7.2 - Hibernation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de l'hibernation...%COLOR_RESET%
powercfg /hibernate on >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Hibernation reactivee%COLOR_RESET%

REM  7.3 - USB Selective Suspend
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la mise en veille selective USB...%COLOR_RESET%
call :SET_USB_POWER 1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mise en veille selective USB et autorisation WMI restaurees%COLOR_RESET%
) else (
    set "POWER_RESTORE_ERROR=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Restauration de la gestion d'energie USB incomplete.%COLOR_RESET%
)

REM  7.4 - Timer Coalescing
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation du Timer Coalescing...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v MinimumDpcRate /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\ModernSleep" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\ControlSet001\Control" /v CoalescingTimerInterval /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /f >nul 2>&1
REM  Supprime la surcharge de diagnostic et rend la gestion de l'horloge a Windows.
bcdedit /deletevalue disabledynamictick >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Timer Coalescing et horloge dynamique rendus a Windows%COLOR_RESET%

REM  7.5 - SetTimerResolution du demarrage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression de SetTimerResolution du demarrage...%COLOR_RESET%
taskkill /f /im SetTimerResolution.exe >nul 2>&1
if exist "%ProgramFiles%\SetTimerResolution\SetTimerResolution.exe" del /f /q "%ProgramFiles%\SetTimerResolution\SetTimerResolution.exe" >nul 2>&1
if exist "%ProgramFiles%\OptimizerAllInOne\SetTimerResolution.exe" del /f /q "%ProgramFiles%\OptimizerAllInOne\SetTimerResolution.exe" >nul 2>&1
if exist "%ProgramFiles%\SetTimerResolution" rmdir "%ProgramFiles%\SetTimerResolution" >nul 2>&1
if exist "%ProgramFiles%\OptimizerAllInOne" rmdir "%ProgramFiles%\OptimizerAllInOne" >nul 2>&1
set "STR_STARTUP_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
if exist "%STR_STARTUP_LNK%" (
    del "%STR_STARTUP_LNK%" /f /q >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci SetTimerResolution supprime du demarrage%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution n'etait pas dans le demarrage%COLOR_RESET%
)

REM  7.6 - Restaurer Intel Thread Director (visibilite panneau)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite Intel Thread Director...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /f >nul 2>&1
REM Le plan Equilibre conserve ici ses valeurs Windows/OEM (elles n'ont pas ete modifiees).
REM bae08b81-2d5e-4688-ad6a-13243356654b : GUID non documente MS Learn 2026 (Voir 7.x commentaire) - pas de reg delete necessaire
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Intel Thread Director restaure en mode Auto%COLOR_RESET%

REM  7.7 - Restaurer Core Parking (powercfg + visibilite panneau)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration du Core Parking...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /f >nul 2>&1
REM Le plan Equilibre conserve ses valeurs OEM/Windows : 0/100 ne sont pas des defauts universels.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking laisse aux valeurs du plan Equilibre%COLOR_RESET%

REM  7.8 - Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation du Power Throttling...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power Throttling reactive%COLOR_RESET%

REM  7.9 - Seuils d'economie d'energie (hardcodes 20% dans plan Balanced, pas de restoration necessaire)

REM  7.10 - Power States NVMe (restauration par defaut)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration Power States NVMe ^(defaut Windows^)...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerMode" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power States NVMe restaures%COLOR_RESET%

REM  7.11 - ULPS (AMD) et PowerMizer (Auto)
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

REM  7.12 - Economies d'energie reseau (NIC)
REM Les bindings appartiennent a la section Reseau et ne sont pas modifies ici.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation des economies d'energie reseau (NIC)...%COLOR_RESET%
set "NIC_RESTORE_ERROR=0"
if not "!AIO_MODE!"=="1" (
    netsh int tcp set global rsc=enabled >nul 2>&1
    if !errorlevel! NEQ 0 set "NIC_RESTORE_ERROR=1"
    call :RESET_NAGLE_PROFILE
    if !errorlevel! NEQ 0 set "NIC_RESTORE_ERROR=1"
)
call :SET_NIC_PROFILE 1 1
if !errorlevel! NEQ 0 (
    set "NIC_RESTORE_ERROR=1"
)
if "!NIC_RESTORE_ERROR!"=="1" (
    set "POWER_RESTORE_ERROR=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Restauration NIC appliquee partiellement.%COLOR_RESET%
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie NIC restaurees%COLOR_RESET%
)
set "NIC_RESTORE_ERROR="

REM  7.13 - Visibilite des parametres processeur dans le panneau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite des parametres processeur...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Visibilite des parametres restauree%COLOR_RESET%

REM  7.14 - ASPM (PCI Express)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation ASPM sur le bus PCI Express...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%ASPM reactive%COLOR_RESET%

REM  7.15 - Mise en veille des disques et stockage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des parametres de stockage...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /f >nul 2>&1
REM  Supprimer HIPM/DIPM/HDDParking pour revenir aux valeurs par defaut systeme
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'EnableHIPM','EnableDIPM','EnableHDDParking' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres de stockage restaures%COLOR_RESET%

REM  7.16 - Limites de latence I/O
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des limites de latence I/O...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'IoLatencyCap' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Limites de latence I/O restaurees%COLOR_RESET%

REM  7.17 - Gestion d'energie GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la gestion d'energie GPU...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v PreferMaxPerf /f >nul 2>&1
)
REM Les preferences DirectX appartiennent au profil GPU choisi en section 3.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie GPU restauree%COLOR_RESET%
REM  7.18 - Gestion d'energie PCI
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la gestion d'energie PCI...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v D3ColdSupported /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg delete "%%K" /v "*WakeOnPattern" /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie PCI reactivee%COLOR_RESET%

REM  7.19 - Systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration du systeme d'alimentation...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v SleepStudyDisabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Systeme d'alimentation restaure%COLOR_RESET%

REM  7.20 - Peripheriques ACPI/HID/PCI/USB
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des parametres d'economie des peripheriques ACPI, HID, PCI et USB...%COLOR_RESET%
powershell -NoProfile -Command "$bases=@('HKLM:\SYSTEM\CurrentControlSet\Enum\ACPI','HKLM:\SYSTEM\CurrentControlSet\Enum\HID','HKLM:\SYSTEM\CurrentControlSet\Enum\PCI','HKLM:\SYSTEM\CurrentControlSet\Enum\USB','HKLM:\SYSTEM\CurrentControlSet\Enum\USBSTOR'); foreach($b in $bases){ if(Test-Path $b){ Get-ChildItem -Path $b -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'EnhancedPowerManagementEnabled','SelectiveSuspendEnabled','SelectiveSuspendOn','WaitWakeEnabled','DeviceSelectiveSuspended' -ErrorAction SilentlyContinue }; Get-ChildItem -Path $b -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'WDF' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'IdleInWorkingState' -ErrorAction SilentlyContinue } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres d'economie des peripheriques restaures%COLOR_RESET%

REM  7.21 - Gestion d'energie PCIe (visibilite panneau)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite PCIe...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Visibilite PCIe restauree%COLOR_RESET%

REM  7.22 - Energie PCIe GPU (ASPM restaure en 7.11, valeurs powercfg via 7.0)

REM  7.23 - Les surcharges de l'optimiseur ont ete annulees sans toucher aux autres plans.

set "STR_STARTUP_LNK="
if "!POWER_RESTORE_ERROR!"=="1" (
    set "POWER_RESTORE_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Economies d'energie restaurees partiellement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    exit /b 1
)
set "POWER_RESTORE_ERROR="
call :FINISH_ACTION "Economies d'energie" "restaurees"
exit /b 0

:DESACTIVER_PROTECTIONS_SECURITE
call :INIT_PROFILS
if not "!SKIP_PAUSE!"=="0" goto :DESACTIVER_PROTECTIONS_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 8 : DESACTIVATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_YELLOW%A SAVOIR :%COLOR_RESET%
echo %COLOR_WHITE%  Ce mode reduit certaines mitigations CPU et desactive la liste de blocage%COLOR_RESET%
echo %COLOR_WHITE%  des pilotes vulnerables. L'effet sur les performances varie selon le PC.%COLOR_RESET%
echo %COLOR_WHITE%  Ces reglages sont reversibles avec le mode Securite Max.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_PROTECTIONS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Appliquer ce mode ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_PROTECTIONS_RUN
set "SECURITY_SECTION_ERROR=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% REGLAGES DE PERFORMANCE CPU%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Application des reglages de performance lies au processeur.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
REM  Base commune des profils : retire l'ancienne valeur legacy de Performance Max
REM  et reactive SEHOP. Performance Max applique ensuite explicitement son override.
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /f >nul 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled >nul 2>&1 && set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"

REM  8.1 - Desactivation Spectre Meltdown Memory Management
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des protections Spectre/Meltdown...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /t REG_DWORD /d 1 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /t REG_DWORD /d 3 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /t REG_DWORD /d 3 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v MoveImages /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableGdsMitigation /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v PerformMmioMitigation /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Protections Spectre/Meltdown desactivees%COLOR_RESET%

REM  8.2 - Desactivation des mitigations CPU avancees
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des mitigations CPU (KVAS, STIBP, Retpoline)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v RestrictIndirectBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKvashadow /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableStibp /t REG_DWORD /d 1 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableRetpoline /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v DisableBranchPrediction /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mitigations CPU desactivees%COLOR_RESET%

if "!PROFIL_USAGE!"=="0" (
REM 8.3 - Mode Gaming : VBS/HVCI, CFG et SEHOP actifs pour preserver la compatibilite
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application Mode Gaming VBS/HVCI [HVCI=1, VBS=1, CFG=1, LSA=0]...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 1 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
bcdedit /set hypervisorlaunchtype auto >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
REM CFG reste actif : c'est une protection Windows et sa desactivation globale
REM n'est pas necessaire pour les profils proposes par ce script.
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Gaming applique - VBS/HVCI, CFG et SEHOP actifs%COLOR_RESET%
) else (
REM 8.3 - Mode Normal : retire tout ancien forcage VBS/HVCI/LSA du script.
REM Les mitigations CPU restent reduites et CFG reste explicitement actif.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des anciens forcages VBS/HVCI du script...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v RequirePlatformSecurityFeatures /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v HypervisorEnforcedCodeIntegrity /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPLBoot /f >nul 2>&1
bcdedit /deletevalue hypervisorlaunchtype >nul 2>&1
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Normal applique - VBS/HVCI aux reglages Windows, CFG actif%COLOR_RESET%
)
REM  Vulnerable Driver Blocklist
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation CI Policy (Driver Blocklist)...%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%La liste de blocage des pilotes vulnerables sera desactivee.%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_SECTION_ERROR=1"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Blocklist de pilotes vulnerables desactivee%COLOR_RESET%

if "!SECURITY_SECTION_ERROR!"=="1" (
    set "SECURITY_SECTION_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Certains reglages de securite n'ont pas pu etre appliques.%COLOR_RESET%
    exit /b 1
)
set "SECURITY_SECTION_ERROR="
exit /b 0

:RESTAURER_PROTECTIONS_SECURITE
set "SECURITY_RESTORE_ERROR=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 8 : RESTAURATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
REM  8.1 - Protections noyau (SEHOP, Exception Chain)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de SEHOP pour le profil Securite Max...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /f >nul 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled >nul 2>&1 && set "SECURITY_RESTORE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 0 /f >nul 2>&1 || set "SECURITY_RESTORE_ERROR=1"
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SEHOP active pour le profil Securite Max%COLOR_RESET%
echo.
REM  8.2 - Mitigations Spectre/Meltdown et CPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des mitigations Spectre/Meltdown et CPU...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettings /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverride /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v FeatureSettingsOverrideMask /f >nul 2>&1
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
REM  8.3 - Blocklist de pilotes vulnerables
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la blocklist de pilotes vulnerables...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Blocklist pilotes vulnerables reactivee%COLOR_RESET%

REM  8.4 - Restauration VBS/HVCI/CFG aux valeurs par defaut
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v WasEnabledBy /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v RequirePlatformSecurityFeatures /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v HypervisorEnforcedCodeIntegrity /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPL /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v RunAsPPLBoot /f >nul 2>&1
bcdedit /deletevalue hypervisorlaunchtype >nul 2>&1
REM Retire uniquement la surcharge CFG du script : NOTSET applique le defaut Windows.
powershell -NoProfile -Command "Set-ProcessMitigation -System -Remove -Enable CFG" >nul 2>&1
if !errorlevel! NEQ 0 set "SECURITY_RESTORE_ERROR=1"

if "!SECURITY_RESTORE_ERROR!"=="1" (
    set "SECURITY_RESTORE_ERROR="
    exit /b 1
)
set "SECURITY_RESTORE_ERROR="
exit /b 0

REM =================================================================================
REM TOGGLE_PROTECTIONS_NOYAU - Menu fusionne VBS/HVCI + Mitigations CPU
REM Fusion de l'ancien [3] Gerer VBS/HVCI et [8] Gerer Protections Securite
REM 3 modes : Securite Max / Gaming / Perf Max
REM =================================================================================
:TOGGLE_PROTECTIONS_NOYAU
set "SKIP_PAUSE=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo                              %STYLE_BOLD%%COLOR_WHITE%GERER PROTECTIONS NOYAU%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo   %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Securite Max%COLOR_RESET%  %COLOR_WHITE%Protections Windows actives%COLOR_RESET%
echo   %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_CYAN%Gaming%COLOR_RESET%        %COLOR_WHITE%VBS/HVCI, CFG et SEHOP actifs ; mitigations CPU reduites%COLOR_RESET%  %COLOR_GREEN%*** RECOMMANDE ***%COLOR_RESET%
echo   %COLOR_YELLOW%[3]%COLOR_RESET% %COLOR_RED%Perf Max%COLOR_RESET%      %COLOR_WHITE%VBS/HVCI et SEHOP desactives, CFG actif%COLOR_RESET%
echo   %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-3, M]: %COLOR_RESET%"
call :AZCHOICE 123M
if !errorlevel! EQU 4 goto :PROTECTIONS_RETURN
if !errorlevel! EQU 3 goto :PROTECTIONS_PERF_MAX
if !errorlevel! EQU 2 goto :PROTECTIONS_GAMING
if !errorlevel! EQU 1 goto :PROTECTIONS_SECURITY_MAX
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_SECURITY_MAX
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% MODE SECURITE MAX - VBS/HVCI + MITIGATIONS CPU ACTIVES%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
set "PROTECTION_MODE_ERROR=0"
REM Etape 1 : Restaurer les mitigations CPU (supprime toutes les cles de desactivation)
call :RESTAURER_PROTECTIONS_SECURITE
if !errorlevel! NEQ 0 set "PROTECTION_MODE_ERROR=1"
REM Etape 2 : Activer VBS, HVCI et Credential Guard sans verrou UEFI
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de VBS, HVCI et Credential Guard...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 1 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 2 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
bcdedit /set hypervisorlaunchtype auto >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
if "!PROTECTION_MODE_ERROR!"=="1" (
    set "PROTECTION_MODE_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Certains reglages du mode Securite Max n'ont pas pu etre appliques.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :TOGGLE_PROTECTIONS_NOYAU
)
set "PROTECTION_MODE_ERROR="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%VBS/HVCI et Credential Guard actives - Mitigations CPU restaurees%COLOR_RESET%
call :FINISH_ACTION "Mode Securite Max" "applique"
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_GAMING
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% MODE GAMING - VBS/HVCI ACTIF, MITIGATIONS CPU DESACTIVEES%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
set "PROTECTION_MODE_ERROR=0"
set "SKIP_PAUSE_TMP=!SKIP_PAUSE!"
set "SKIP_PAUSE=1"
set "PROFIL_USAGE_TMP=!PROFIL_USAGE!"
set "PROFIL_USAGE=0"
call :INIT_PROFILS
call :DESACTIVER_PROTECTIONS_SECURITE
if !errorlevel! NEQ 0 set "PROTECTION_MODE_ERROR=1"
set "PROFIL_USAGE=!PROFIL_USAGE_TMP!"
set "PROFIL_USAGE_TMP="
set "SKIP_PAUSE=!SKIP_PAUSE_TMP!"
set "SKIP_PAUSE_TMP="
if "!PROTECTION_MODE_ERROR!"=="1" (
    set "PROTECTION_MODE_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Le mode Gaming n'a pas ete applique completement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :TOGGLE_PROTECTIONS_NOYAU
)
set "PROTECTION_MODE_ERROR="
call :FINISH_ACTION "Mode Gaming" "applique"
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_PERF_MAX
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% MODE PERFORMANCE MAX - VBS/HVCI DESACTIVES%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Ce mode desactive VBS (Virtualization-Based Security) et HVCI%COLOR_RESET%
echo %COLOR_WHITE%  (integrite de la memoire) ainsi que plusieurs mitigations CPU.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%  Effet attendu :%COLOR_RESET%
echo %COLOR_WHITE%    - Impact variable selon le processeur, les pilotes et les logiciels%COLOR_RESET%
echo %COLOR_WHITE%    - Les fonctions qui utilisent l'hyperviseur peuvent ne plus demarrer%COLOR_RESET%
echo.
echo %COLOR_YELLOW%  Compatibilite :%COLOR_RESET%
echo %COLOR_WHITE%    - Certains anti-cheats peuvent demander VBS/HVCI et refuser le lancement%COLOR_RESET%
echo %COLOR_WHITE%    - La protection du noyau est reduite jusqu'a la restauration du mode%COLOR_RESET%
echo.
echo %COLOR_CYAN%  Conserve :%COLOR_RESET%
echo %COLOR_WHITE%    - CFG reste actif%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Appliquer le mode Performance Max ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :TOGGLE_PROTECTIONS_NOYAU

REM === Appliquer les optimisations de base (mitigations OFF, CFG preserve) ===
set "PROTECTION_MODE_ERROR=0"
REM On set PROFIL_USAGE=1 pour SKIP le bloc 8.4 (qui force VBS=1, HVCI=1) et eviter l'echo trompeur
set "SKIP_PAUSE_TMP=!SKIP_PAUSE!"
set "PROFIL_USAGE_TMP=!PROFIL_USAGE!"
set "PROFIL_USAGE=1"
set "SKIP_PAUSE=1"
call :INIT_PROFILS
call :DESACTIVER_PROTECTIONS_SECURITE
if !errorlevel! NEQ 0 set "PROTECTION_MODE_ERROR=1"
set "PROFIL_USAGE=!PROFIL_USAGE_TMP!"
set "PROFIL_USAGE_TMP="
set "SKIP_PAUSE=!SKIP_PAUSE_TMP!"
set "SKIP_PAUSE_TMP="

REM Mode Performance Max uniquement : desactive SEHOP. Gaming conserve cette protection.
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v KernelSEHOPEnabled /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableExceptionChainValidation /t REG_DWORD /d 1 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
REM === Override VBS/HVCI = 0 + CFG preserve (8.3 etait skip car PROFIL_USAGE=1) ===
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation VBS/HVCI + preservation CFG (Performance Max)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v RequirePlatformSecurityFeatures /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v HypervisorEnforcedCodeIntegrity /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v RequirePlatformSecurityFeatures /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeviceGuard" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
bcdedit /set hypervisorlaunchtype off >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
REM CFG preserve (puisque 8.4 a ete skip)
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1 || set "PROTECTION_MODE_ERROR=1"
if "!PROTECTION_MODE_ERROR!"=="1" (
    set "PROTECTION_MODE_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Le mode Performance Max n'a pas ete applique completement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :TOGGLE_PROTECTIONS_NOYAU
)
set "PROTECTION_MODE_ERROR="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Performance Max applique - VBS/HVCI et SEHOP desactives, CFG preserve%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est necessaire pour finaliser la desactivation de VBS/HVCI et SEHOP.%COLOR_RESET%

call :FINISH_ACTION "Mode Performance Max (VBS/HVCI/SEHOP OFF)" "applique"
goto :TOGGLE_PROTECTIONS_NOYAU

:PROTECTIONS_RETURN
goto :MENU_PRINCIPAL

:APPLY_SMARTSCREEN_DISABLE_EXTRA
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation avancee SmartScreen ^(Shell, AppHost, Edge^)...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /t REG_SZ /d "Off" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /t REG_SZ /d "Off" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "TyposquattingCheckerEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SmartScreen desactive sur les surfaces principales%COLOR_RESET%
exit /b

:RESTORE_SMARTSCREEN_DEFAULT_EXTRA
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration SmartScreen par defaut...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "TyposquattingCheckerEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Policies\Microsoft\Edge" /v "SmartScreenPuaEnabled" /f >nul 2>&1
exit /b

:TOGGLE_DEFENDER
set "SKIP_PAUSE=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Defender est l'antivirus integre de Windows. Le desactiver retire l'analyse%COLOR_RESET%
echo %COLOR_WHITE%  en temps reel. Tamper Protection peut ignorer une partie de ces reglages.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer Windows Defender (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver Windows Defender (Non recommande)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_DEFENDER_SECTION
  goto :TOGGLE_DEFENDER
)
if !errorlevel! EQU 1 (
  call :ACTIVER_DEFENDER_SECTION
  goto :TOGGLE_DEFENDER
)
goto :TOGGLE_DEFENDER

REM  ___DEFENDER_ULT_EMBEDDED_SUBS___
:ACTIVER_DEFENDER_SECTION
set "DEFENDER_RESTORE_ERROR=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive Windows Defender, SmartScreen et les taches planifiees associees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de Tamper Protection...%COLOR_RESET%
powershell -NoProfile -Command "try { if((Get-MpComputerStatus -ErrorAction Stop).IsTamperProtected){exit 0}else{exit 1} } catch { exit 2 }" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Tamper Protection est activee%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Vous pourrez reactiver Tamper Protection dans Securite Windows.%COLOR_RESET%
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation des services Windows Defender...%COLOR_RESET%
sc query WinDefend >nul 2>&1
if !errorlevel! EQU 0 (
    sc config WinDefend start= auto >nul 2>&1
    if !errorlevel! NEQ 0 set "DEFENDER_RESTORE_ERROR=1"
)
for %%S in (WdNisSvc Sense SecurityHealthService WdNisDrv) do (
    sc query %%S >nul 2>&1
    if !errorlevel! EQU 0 (
        sc config %%S start= demand >nul 2>&1
        if !errorlevel! NEQ 0 set "DEFENDER_RESTORE_ERROR=1"
    )
)
for %%S in (WdBoot WdFilter) do (
    sc query %%S >nul 2>&1
    if !errorlevel! EQU 0 (
        sc config %%S start= boot >nul 2>&1
        if !errorlevel! NEQ 0 set "DEFENDER_RESTORE_ERROR=1"
    )
)
for %%S in (WinDefend WdNisSvc SecurityHealthService) do sc start %%S >nul 2>&1
reg query "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" >nul 2>&1 && reg add "HKLM\SYSTEM\CurrentControlSet\Services\uhssvc" /v "Start" /t REG_DWORD /d 3 /f >nul 2>&1

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
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v VerifiedAndReputableTrustModeEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v SmartLockerMode /f >nul 2>&1
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de SmartScreen...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f >nul 2>&1
  call :RESTORE_SMARTSCREEN_DEFAULT_EXTRA
  echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration preferences Defender par defaut...%COLOR_RESET%
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; try { Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false -DisableBlockAtFirstSeen $false -DisableIOAVProtection $false -DisableScriptScanning $false -DisableArchiveScanning $false -DisableEmailScanning $false -DisableRemovableDriveScanning $false -PUAProtection Enabled -MAPSReporting Advanced -SubmitSamplesConsent SendSafeSamples -EnableNetworkProtection Disabled -EnableControlledFolderAccess Disabled; $ids=@('D4F940AB-401B-4EFC-AADC-AD5F3C50688A','3B576869-A4EC-4529-8536-B80A7769E899','75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84','D3E037E1-3EB8-44C8-A917-57927947596D','5BEB7EFE-FD9A-4556-801D-275E5FFC04CC','BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550','92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B','D1E49AAC-8F56-4280-B9BA-993A6D77406C','B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4','01443614-CD74-433A-B99E-2ECDC07BFC25','C1DB55AB-C21A-4637-BB3F-A12568109D35'); $actions=@(); foreach($id in $ids){$actions+=0}; Remove-MpPreference -AttackSurfaceReductionRules_Ids $ids -AttackSurfaceReductionRules_Actions $actions; exit 0 } catch { exit 1 }" >nul 2>&1
  if !errorlevel! NEQ 0 set "DEFENDER_RESTORE_ERROR=1"

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation des taches planifiees...%COLOR_RESET%
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cleanup" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Scheduled Scan" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Update" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Cache Maintenance" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\Windows Defender\Windows Defender Verification" /Enable >nul 2>&1
schtasks /Change /TN "Microsoft\Windows\ExploitGuard\ExploitGuard MDM policy Refresh" /Enable >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services Defender restaures%COLOR_RESET%
if "!DEFENDER_RESTORE_ERROR!"=="1" (
    set "DEFENDER_RESTORE_ERROR="
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Certaines preferences sont gerees par Windows ou votre antivirus.%COLOR_RESET%
    call :FINISH_ACTION "Windows Defender" "reactive partiellement"
    exit /b 1
)
set "DEFENDER_RESTORE_ERROR="
call :FINISH_ACTION "Windows Defender" "reactive"
exit /b 0

:DESACTIVER_DEFENDER_SECTION
if not "!SKIP_PAUSE!"=="0" goto :DESACTIVER_DEFENDER_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Windows Defender ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : desactiver l'antivirus integre reduit la charge CPU/disque%COLOR_RESET%
echo %COLOR_WHITE%et supprime les micro-begaiements lies aux analyses en temps reel.%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_YELLOW%[INFO]%COLOR_RESET%
echo %COLOR_WHITE%- %COLOR_GREEN%GARDEZ-LE%COLOR_RESET% : Si vous n'avez pas d'autre antivirus et naviguez beaucoup.%COLOR_RESET%
echo %COLOR_WHITE%- %COLOR_RED%COUPEZ-LE%COLOR_RESET% : Si vous utilisez un antivirus tiers ^(Bitdefender, Kaspersky...^)%COLOR_RESET%
echo %COLOR_WHITE%  ou si vous cherchez la performance maximale pour du jeu competitif.%COLOR_RESET%
echo.
echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Sans Defender, aucune protection en temps reel n'est active.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Sur Windows 10 1903+ / 11, Tamper Protection bloque les modifications du registre%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%Defender. Vous DEVEZ d'abord la desactiver manuellement :%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%Parametres ^> Confidentialite et securite ^> Securite Windows ^> Protection contre les%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%piratages et menaces ^> Parametres de protection ^> Tamper Protection = OFF.%COLOR_RESET%
echo %COLOR_YELLOW%        %COLOR_RESET% %COLOR_WHITE%Sinon, les commandes ci-dessous seront silencieusement ignorees par Defender.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_DEFENDER_RUN "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Windows Defender ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_DEFENDER_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive Windows Defender, SmartScreen et les taches planifiees associees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de Tamper Protection...%COLOR_RESET%
powershell -NoProfile -Command "if ((Get-MpComputerStatus).IsTamperProtected -eq $true) { exit 1 } else { exit 0 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Tamper Protection est encore activee.%COLOR_RESET%
    if "!SKIP_PAUSE!"=="1" (
        echo %COLOR_WHITE%Defender est conserve. Coupez-la dans Securite Windows puis relancez cette action.%COLOR_RESET%
        set "DESACTIVER_DEFENDER_ERROR=1"
        goto :DEFENDER_SECTION_END
    )
    echo %COLOR_WHITE%La desactivation est arretee avant de laisser Defender dans un etat partiel.%COLOR_RESET%
    echo %COLOR_WHITE%Desactivez-la manuellement dans Securite Windows, puis relancez cette action.%COLOR_RESET%
    pause
    exit /b 1
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des services Windows Defender...%COLOR_RESET%
for %%S in (WinDefend WdNisSvc Sense SecurityHealthService) do sc stop %%S >nul 2>&1
for %%S in (WinDefend WdNisSvc Sense WdBoot WdFilter WdNisDrv SecurityHealthService) do sc config %%S start= disabled >nul 2>&1
for %%S in (Sense WdBoot WdFilter WdNisDrv WdNisSvc WinDefend SecurityHealthService) do reg query "HKLM\SYSTEM\CurrentControlSet\Services\%%S" >nul 2>&1 && reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v "Start" /t REG_DWORD /d 4 /f >nul 2>&1

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
  call :APPLY_SMARTSCREEN_DISABLE_EXTRA
  echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation avancee Defender ^(preferences, cloud, ASR, CFA, PUA^)...%COLOR_RESET%
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; Set-MpPreference -DisableRealtimeMonitoring $true -DisableBehaviorMonitoring $true -DisableBlockAtFirstSeen $true -DisableIOAVProtection $true -DisableScriptScanning $true -DisableArchiveScanning $true -DisableEmailScanning $true -DisableRemovableDriveScanning $true -PUAProtection Disabled -MAPSReporting Disabled -SubmitSamplesConsent 2 -EnableNetworkProtection Disabled -EnableControlledFolderAccess Disabled; $ids=@('D4F940AB-401B-4EFC-AADC-AD5F3C50688A','3B576869-A4EC-4529-8536-B80A7769E899','75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84','D3E037E1-3EB8-44C8-A917-57927947596D','5BEB7EFE-FD9A-4556-801D-275E5FFC04CC','BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550','92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B','D1E49AAC-8F56-4280-B9BA-993A6D77406C','B2B3F03D-6A65-4F7B-A9C7-1C7EF74A9BA4','01443614-CD74-433A-B99E-2ECDC07BFC25','C1DB55AB-C21A-4637-BB3F-A12568109D35'); $actions=@(); foreach($id in $ids){$actions+=0}; Set-MpPreference -AttackSurfaceReductionRules_Ids $ids -AttackSurfaceReductionRules_Actions $actions" >nul 2>&1
  echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Preferences Defender desactivees ^(effectif selon Tamper Protection^)%COLOR_RESET%
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Reglages Defender appliques ^(effectif selon Tamper Protection / version Windows^)%COLOR_RESET%
call :FINISH_ACTION "Windows Defender" "desactive"
exit /b 0

:DEFENDER_SECTION_END
exit /b 1

:TOGGLE_UAC
set "SKIP_PAUSE=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER UAC (CONTROLE DE COMPTE UTILISATEUR)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  L'UAC affiche une invite de confirmation avant toute action admin.%COLOR_RESET%
echo %COLOR_WHITE%  Le desactiver supprime ces confirmations pour toutes les applications.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer UAC (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver UAC (Non recommande)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_UAC_SECTION
  goto :TOGGLE_UAC
)
if !errorlevel! EQU 1 (
  call :ACTIVER_UAC_SECTION
  goto :TOGGLE_UAC
)
goto :TOGGLE_UAC

:ACTIVER_UAC_SECTION
cls
set "UAC_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE L'UAC%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive le Controle de Compte Utilisateur (UAC).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Les demandes de confirmation administrateur seront de nouveau affichees.%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de l'UAC...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1 || set "UAC_SECTION_ERROR=1"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1 || set "UAC_SECTION_ERROR=1"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1 || set "UAC_SECTION_ERROR=1"

if "!UAC_SECTION_ERROR!"=="1" (
    set "UAC_SECTION_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Activation de l'UAC appliquee partiellement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    exit /b 1
)
set "UAC_SECTION_ERROR="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%UAC active.%COLOR_RESET%
call :FINISH_ACTION "UAC" "active"
exit /b 0

:DESACTIVER_UAC_SECTION
if not "!SKIP_PAUSE!"=="0" goto :DESACTIVER_UAC_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER L'UAC%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une derniere confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- L'UAC demande une elevation explicite avant qu'un programme obtienne des droits admin.%COLOR_RESET%
echo %COLOR_WHITE%- La desactivation retire ces invites pour toutes les applications.%COLOR_RESET%
echo %COLOR_WHITE%- SmartScreen et Windows Defender ne sont pas modifies par ce menu.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Choisissez cette option seulement si vous acceptez moins de confirmations.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_UAC_RUN "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_UAC_RUN
cls
set "UAC_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE L'UAC%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive uniquement le Controle de Compte Utilisateur.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'UAC...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1 || set "UAC_SECTION_ERROR=1"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1 || set "UAC_SECTION_ERROR=1"
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1 || set "UAC_SECTION_ERROR=1"

if "!UAC_SECTION_ERROR!"=="1" (
    set "UAC_SECTION_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'UAC appliquee partiellement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    exit /b 1
)
set "UAC_SECTION_ERROR="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%UAC desactive.%COLOR_RESET%
call :FINISH_ACTION "UAC" "desactive"
exit /b 0

:TOGGLE_ANIMATIONS
set "SKIP_PAUSE=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Les animations Windows consomment un peu de GPU/CPU. Les desactiver peut%COLOR_RESET%
echo %COLOR_WHITE%  fluidifier un PC faible, au prix d'une interface plus "seche".%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer les animations Windows (experience utilisateur standard)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver les animations Windows (pour optimiser les performances)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! EQU 3 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 2 (
  call :DESACTIVER_ANIMATIONS_SECTION
  goto :TOGGLE_ANIMATIONS
)
if !errorlevel! EQU 1 (
  call :ACTIVER_ANIMATIONS_SECTION
  goto :TOGGLE_ANIMATIONS
)
goto :TOGGLE_ANIMATIONS

:ACTIVER_ANIMATIONS_SECTION
cls
set "ANIMATIONS_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive les animations et effets visuels Windows (transparence, fade, animations au survol).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des animations et effets visuels...%COLOR_RESET%

REM  VisualFXSetting=0 : Let Windows choose what's best (comportement Windows standard)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "400" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v MenuAnimation /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v TooltipAnimation /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v SelectionFade /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v MenuFade /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v UserUIEffects /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v AnimateWindow /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v ComboboxAnimation /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v ListBoxSmoothScrolling /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"

REM  Activer les effets visuels supplementaires
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 1 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /f >nul 2>&1

if "!ANIMATIONS_SECTION_ERROR!"=="1" (
    set "ANIMATIONS_SECTION_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Activation des animations appliquee partiellement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    exit /b 1
)
set "ANIMATIONS_SECTION_ERROR="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Animations Windows activees.%COLOR_RESET%
call :FINISH_ACTION "Animations" "activees"
exit /b 0

:DESACTIVER_ANIMATIONS_SECTION
if not "!SKIP_PAUSE!"=="0" goto :DESACTIVER_ANIMATIONS_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CONFIRMATION : DESACTIVER LES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi une derniere confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- Les animations consomment un peu de GPU/CPU ; les couper peut fluidifier un PC faible.%COLOR_RESET%
echo %COLOR_WHITE%- Cela modifie le registre utilisateur ^(effets visuels, transparence, animations au survol^).%COLOR_RESET%
echo %COLOR_WHITE%- L'interface parait plus "seche" ^(transparence, barres des taches, menus^).%COLOR_RESET%
echo %COLOR_WHITE%- Un redemarrage est necessaire pour tout voir ; reversible via le menu Activer.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_ANIMATIONS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous vraiment desactiver les animations ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_ANIMATIONS_RUN
cls
set "ANIMATIONS_SECTION_ERROR=0"
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive les animations et effets visuels Windows pour ameliorer les performances.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des animations et effets visuels...%COLOR_RESET%

REM  VisualFXSetting=3 (Personnalise) pour que Windows utilise uniquement les cles
REM  individuelles ci-dessous sans recalculer tous les effets (ce qui reset le menu Demarrer)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" /v VisualFXSetting /t REG_DWORD /d 3 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop\WindowMetrics" /v MinAnimate /t REG_SZ /d "0" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarAnimations /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Accessibility\AnimationEffects" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v MenuShowDelay /t REG_SZ /d "0" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v MenuAnimation /t REG_SZ /d "0" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v TooltipAnimation /t REG_SZ /d "0" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v SelectionFade /t REG_SZ /d "0" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v MenuFade /t REG_SZ /d "0" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v UserUIEffects /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v AnimateWindow /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v ComboboxAnimation /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v ListBoxSmoothScrolling /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\DWM" /v EnableAeroPeek /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v EnableTransparency /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"

REM  Garder les options utiles actives (Police, Ombre icone, Drag content)
reg add "HKCU\Control Panel\Desktop" /v DragFullWindows /t REG_SZ /d "1" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewAlphaSelect /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v FontSmoothing /t REG_SZ /d "2" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v FontSmoothingType /t REG_DWORD /d 2 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ListviewShadow /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Control Panel\Desktop" /v CursorShadow /t REG_SZ /d "0" /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ExtendedUIHoverTime /t REG_DWORD /d 0 /f >nul 2>&1 || set "ANIMATIONS_SECTION_ERROR=1"

if "!ANIMATIONS_SECTION_ERROR!"=="1" (
    set "ANIMATIONS_SECTION_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Desactivation des animations appliquee partiellement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    exit /b 1
)
set "ANIMATIONS_SECTION_ERROR="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Animations Windows desactivees.%COLOR_RESET%
call :FINISH_ACTION "Animations" "desactivees"
exit /b 0

:MENU_IA_WIDGETS_RECALL
set "SKIP_PAUSE=0"
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER COPILOT / WIDGETS / RECALL (WINDOWS 11)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Ces fonctionnalites sont specifiques a Windows 11.%COLOR_RESET%
echo %COLOR_WHITE%  Si vous etes sur Windows 10, ces options n'auront pas d'effet.%COLOR_RESET%
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
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-6, D, M]: %COLOR_RESET%"
call :AZCHOICE 123456DM
if !errorlevel! EQU 8 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 7 goto :MENU_IA_OPTION_8_GATE
if !errorlevel! EQU 6 goto :MENU_IA_OPTION_6_GATE
if !errorlevel! EQU 5 goto :MENU_IA_OPTION_5
if !errorlevel! EQU 4 goto :MENU_IA_OPTION_4_GATE
if !errorlevel! EQU 3 goto :MENU_IA_OPTION_3
if !errorlevel! EQU 2 goto :MENU_IA_OPTION_2_GATE
if !errorlevel! EQU 1 goto :MENU_IA_OPTION_1
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_8_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_8
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Confirmer la desactivation TOTALE ^(Copilot + Widgets + Recall^) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Effet : desactivation/blocage de Copilot, Widgets et Recall.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :MENU_IA_OPTION_8 "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous vraiment tout desactiver ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_8
call :DESACTIVER_IA_SECTION
if !errorlevel! NEQ 0 (
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
call :FINISH_ACTION "Toutes les fonctions IA/Widgets" "desactivees"
goto :MENU_IA_WIDGETS_RECALL

:DESACTIVER_IA_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE COPILOT / WIDGETS / RECALL%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Application des reglages IA demandes dans un ecran separe.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
set "AI_SECTION_ERROR=0"
set "AI_SECTION_FAILED="
call :CORE_DESACTIVER_COPILOT
if !errorlevel! NEQ 0 (
    set "AI_SECTION_ERROR=1"
    set "AI_SECTION_FAILED=!AI_SECTION_FAILED!Copilot, "
)
call :CORE_DESACTIVER_WIDGETS
if !errorlevel! NEQ 0 (
    set "AI_SECTION_ERROR=1"
    set "AI_SECTION_FAILED=!AI_SECTION_FAILED!Widgets, "
)
call :CORE_DESACTIVER_RECALL
if !errorlevel! NEQ 0 (
    set "AI_SECTION_ERROR=1"
    set "AI_SECTION_FAILED=!AI_SECTION_FAILED!Recall, "
)
if "!AI_SECTION_ERROR!"=="1" (
    set "AI_SECTION_FAILED=!AI_SECTION_FAILED:~0,-2!"
    if "!AIO_MODE!"=="1" set "AIO_IA_FAILED=!AI_SECTION_FAILED!"
    set "AI_SECTION_ERROR="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Reglages non appliques : !AI_SECTION_FAILED!.%COLOR_RESET%
    set "AI_SECTION_FAILED="
    exit /b 1
)
set "AI_SECTION_ERROR="
set "AI_SECTION_FAILED="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Copilot, Widgets et Recall desactives.%COLOR_RESET%
exit /b 0

:MENU_IA_OPTION_6_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_6
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Recall ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Recall enregistre votre activite ecran pour%COLOR_RESET%
echo %COLOR_WHITE%permettre des recherches IA ^(fort impact sur la confidentialite^).%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :MENU_IA_OPTION_6 "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation de Recall ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_6
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE RECALL%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive Recall, les snapshots d'ecran et les fonctionnalites IA associees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_RECALL
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Certains reglages Recall n'ont pas pu etre appliques.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Recall desactive.%COLOR_RESET%
call :FINISH_ACTION "Recall" "desactive"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_5
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE RECALL%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive Recall et les fonctionnalites IA associees (snapshots, analyse d'ecran).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_RECALL
set "AI_ACTION_RC=!errorlevel!"
if "!AI_ACTION_RC!"=="2" (
    set "AI_ACTION_RC="
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Recall n'est pas disponible sur cette version ou ce materiel.%COLOR_RESET%
    pause
    goto :MENU_IA_WIDGETS_RECALL
)
if not "!AI_ACTION_RC!"=="0" (
    set "AI_ACTION_RC="
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Recall n'a pas pu etre reactive completement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
set "AI_ACTION_RC="
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Recall active.%COLOR_RESET%
call :FINISH_ACTION "Recall" "active"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_4_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_4
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver les Widgets ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : les widgets utilisent des ressources et du reseau%COLOR_RESET%
echo %COLOR_WHITE%pour afficher des actualites et la meteo en continu.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :MENU_IA_OPTION_4 "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation des Widgets ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_4
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DES WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive les Widgets dans la barre des taches pour liberer des ressources.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_WIDGETS
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Certains reglages Widgets n'ont pas pu etre appliques.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Widgets desactives.%COLOR_RESET%
call :FINISH_ACTION "Widgets" "desactive"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_3
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DES WIDGETS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive les Widgets dans la barre des taches (actualites, meteo, etc.).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_WIDGETS
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Les Widgets n'ont pas pu etre reactives completement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Widgets actives.%COLOR_RESET%
call :FINISH_ACTION "Widgets" "active"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_2_GATE
if not "!SKIP_PAUSE!"=="0" goto :MENU_IA_OPTION_2
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Voulez-vous vraiment desactiver Copilot ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi cette question : Copilot s'appuie sur des services cloud et peut%COLOR_RESET%
echo %COLOR_WHITE%consommer des ressources en arriere-plan pour les suggestions IA.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :MENU_IA_OPTION_2 "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation de Copilot ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
:MENU_IA_OPTION_2
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive Copilot, le bouton dans la barre des taches et ses integrations Edge.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_COPILOT
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Certains reglages Copilot n'ont pas pu etre appliques.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Copilot desactive.%COLOR_RESET%
call :FINISH_ACTION "Copilot" "desactive"
goto :MENU_IA_WIDGETS_RECALL

:MENU_IA_OPTION_1
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive Copilot, le bouton dans la barre des taches et les suggestions IA.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_COPILOT
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Copilot n'a pas pu etre reactive completement.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
    goto :MENU_IA_WIDGETS_RECALL
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Copilot active.%COLOR_RESET%
call :FINISH_ACTION "Copilot" "active"
goto :MENU_IA_WIDGETS_RECALL


:CORE_ACTIVER_COPILOT
set "AI_CORE_ERROR=0"
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour Copilot...%COLOR_RESET%
call :DELETE_REG_VALUE_IF_PRESENT "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" "TurnOffWindowsCopilot"
if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /f >nul 2>&1
REM  Reactivation de Copilot dans Edge
for %%V in (HubsSidebarEnabled CopilotPageContext) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKCU\Software\Policies\Microsoft\Edge" "%%V"
    if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
)
for %%V in (HubsSidebarEnabled CopilotPageContext EdgeEntraCopilotPageContext Microsoft365CopilotChatIconEnabled) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Edge" "%%V"
    if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
)
    call :REMOVE_COPILOT_HOSTS_BLOCK
    if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
ipconfig /flushdns >nul 2>&1
exit /b !AI_CORE_ERROR!

:CORE_DESACTIVER_COPILOT
set "AI_CORE_ERROR=0"
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions Copilot...%COLOR_RESET%
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" /v TurnOffWindowsCopilot /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v ShowCopilotButton /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v IsCopilotAvailable /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot" /v CopilotDisabledReason /t REG_SZ /d "FeatureIsDisabled" /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKCU\SOFTWARE\Microsoft\Windows\Shell\Copilot\BingChat" /v IsUserEligible /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
REM  Desactivation de Copilot dans Edge
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKCU\Software\Policies\Microsoft\Edge" /v "CopilotPageContext" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "HubsSidebarEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "CopilotPageContext" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "EdgeEntraCopilotPageContext" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Edge" /v "Microsoft365CopilotChatIconEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
    REM Les strategies suffisent ; nettoyer l'ancien bloc hosts qui cassait aussi le site Copilot.
    call :REMOVE_COPILOT_HOSTS_BLOCK
    if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Ancien bloc Copilot du fichier hosts non nettoye ; les strategies restent appliquees.%COLOR_RESET%
ipconfig /flushdns >nul 2>&1
exit /b !AI_CORE_ERROR!


:CORE_ACTIVER_WIDGETS
set "AI_CORE_ERROR=0"
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour les Widgets...%COLOR_RESET%
call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Dsh" "AllowNewsAndInterests"
if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" "EnableFeeds"
if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
REM TaskbarDa peut etre protege par Windows/UCPD. Retirer la strategie Dsh reactive deja les Widgets.
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 1 /f >nul 2>&1
if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le bouton Widgets est protege par Windows ; utilisez les Parametres pour l'afficher.%COLOR_RESET%
exit /b !AI_CORE_ERROR!

:CORE_DESACTIVER_WIDGETS
set "AI_CORE_ERROR=0"
set "WIDGETS_BUILD=0"
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour les Widgets...%COLOR_RESET%
for /f "tokens=3" %%B in ('reg query "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion" /v CurrentBuildNumber 2^>nul ^| findstr /i "CurrentBuildNumber"') do set "WIDGETS_BUILD=%%B"
if !WIDGETS_BUILD! GEQ 22000 (
    REM Windows 11 : strategie Widgets actuelle et bouton de la barre des taches.
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Dsh" /v AllowNewsAndInterests /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
    REM TaskbarDa peut etre protege par Windows/UCPD. La strategie Dsh suffit a desactiver toute l'experience Widgets.
    reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v TaskbarDa /t REG_DWORD /d 0 /f >nul 2>&1
    if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Bouton Widgets protege par Windows ; la strategie principale reste appliquee.%COLOR_RESET%
) else (
    REM Windows 10 : ancienne strategie Actualites et centres d'interet uniquement.
    reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Feeds" /v EnableFeeds /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
)
set "WIDGETS_BUILD="
exit /b !AI_CORE_ERROR!


:CORE_ACTIVER_RECALL
set "AI_CORE_ERROR=0"
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des cles de registre pour Recall...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
REM Nettoyage des anciennes valeurs non officielles posees par des versions precedentes.
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /f >nul 2>&1
for %%V in (DisableAgentWorkspaces DisableAgentConnectors DisableRemoteAgentConnectors DisableClickToDo) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" "%%V"
    if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageCreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableCocreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableGenerativeFill" /f >nul 2>&1
for %%V in (DisableImageCreator DisableCocreator DisableGenerativeFill) do (
    call :DELETE_REG_VALUE_IF_PRESENT "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" "%%V"
    if !errorlevel! NEQ 0 set "AI_CORE_ERROR=1"
)
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageSpaceForRecallSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageDurationForRecallSnapshots" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v "Value" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v "AgentActivationEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v "DisableClickToDo" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v "InsightsEnabled" /f >nul 2>&1
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; $f=Get-WindowsOptionalFeature -Online -FeatureName 'Recall' -ErrorAction SilentlyContinue; if($null -eq $f){exit 2}; try { Enable-WindowsOptionalFeature -Online -FeatureName 'Recall' -NoRestart -ErrorAction Stop *>$null; exit 0 } catch { exit 1 }" >nul 2>&1
set "AI_FEATURE_RC=!errorlevel!"
if "!AI_CORE_ERROR!"=="1" (
    set "AI_FEATURE_RC="
    exit /b 1
)
if "!AI_FEATURE_RC!"=="2" (
    set "AI_FEATURE_RC="
    exit /b 2
)
if not "!AI_FEATURE_RC!"=="0" (
    set "AI_FEATURE_RC="
    exit /b 1
)
set "AI_FEATURE_RC="
exit /b 0

:CORE_DESACTIVER_RECALL
set "AI_CORE_ERROR=0"
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des restrictions pour Recall...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "TurnOffSavingSnapshots" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowRecallEnablement" /t REG_DWORD /d 0 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowAIGameFeatures" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "AllowClickToDo" /f >nul 2>&1
REM Valeur enumeree : 2 = forcer la desactivation (1 forcerait l'activation).
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentWorkspaces" /t REG_DWORD /d 2 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableAgentConnectors" /t REG_DWORD /d 2 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableRemoteAgentConnectors" /t REG_DWORD /d 2 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageInsights" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableClickToDo" /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableImageCreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableCocreator" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "DisableGenerativeFill" /f >nul 2>&1
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableImageCreator" /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableCocreator" /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg add "HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\Paint" /v "DisableGenerativeFill" /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageSpaceForRecallSnapshots" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" /v "SetMaximumStorageDurationForRecallSnapshots" /f >nul 2>&1
reg add "HKCU\Software\Policies\Microsoft\Windows\WindowsAI" /v "DisableAIDataAnalysis" /t REG_DWORD /d 1 /f >nul 2>&1 || set "AI_CORE_ERROR=1"
REM Nettoyer les anciennes surcharges non documentees sans modifier voix, saisie ou autorisations generales.
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\systemAIModels" /v Value /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\userActivityFeedGlobal" /v Value /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Speech_OneCore\Settings\VoiceActivation\UserPreferenceForAllApps" /v AgentActivationEnabled /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\Shell\ClickToDo" /v DisableClickToDo /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\input\Settings" /v InsightsEnabled /f >nul 2>&1
REM La suppression du composant est un nettoyage facultatif : les strategies ci-dessus suffisent a desactiver Recall.
REM DISM peut signaler un redemarrage requis comme un succes distinct ; cela ne doit pas invalider tout le bloc IA.
powershell -NoProfile -Command "$ProgressPreference='SilentlyContinue'; try { $f=Get-WindowsOptionalFeature -Online -FeatureName 'Recall' -ErrorAction SilentlyContinue; if($null -ne $f -and $f.State -ne 'DisabledWithPayloadRemoved'){ Disable-WindowsOptionalFeature -Online -FeatureName 'Recall' -Remove -NoRestart -ErrorAction Stop *>$null }; exit 0 } catch { exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Recall est bloque par les strategies ; le composant Windows facultatif est conserve.%COLOR_RESET%
exit /b !AI_CORE_ERROR!

:FINISH_ACTION
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%%~1 %~2%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
if not "!AIO_MODE!"=="1" if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser les changements.%COLOR_RESET%
call :PROMPT_MANUAL_REBOOT
exit /b

:DESINSTALLER_ONEDRIVE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESINSTALLATION COMPLETE DE ONEDRIVE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Pourquoi demander confirmation :%COLOR_RESET%
echo %COLOR_WHITE%- OneDrive synchronise Documents/Bureau/Images vers le cloud Microsoft.%COLOR_RESET%
echo %COLOR_WHITE%- Le desinstaller coupe la sync et les liens vers le nuage ; Office peut perdre l'auto-save cloud.%COLOR_RESET%
echo %COLOR_WHITE%- Le dossier OneDrive (%USERPROFILE%\OneDrive) sera supprime ; sauvegardez vos fichiers%COLOR_RESET%
echo %COLOR_WHITE%  importants presents dans Documents/Bureau/Images synchronises avant de continuer.%COLOR_RESET%
echo %COLOR_WHITE%- Pratique pour liberer des ressources et gagner en vie privee.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%La suite arretera OneDrive, nettoiera les reglages Windows et les raccourcis.%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Cela peut prendre quelques instants.%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desinstaller OneDrive ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_GESTION_WINDOWS

cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% EXECUTION - DESINSTALLATION COMPLETE DE ONEDRIVE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Progression : arret, deconnexion, desinstallation, nettoyage registre,%COLOR_RESET%
echo %COLOR_WHITE%taches planifiees, dossiers restants et raccourcis.%COLOR_RESET%
echo.

REM  Arreter les processus OneDrive
echo %COLOR_YELLOW%[1/7]%COLOR_RESET% %COLOR_WHITE%Arret des processus OneDrive et sync Office...%COLOR_RESET%
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Processus OneDrive arretes%COLOR_RESET%

echo %COLOR_YELLOW%[2/7]%COLOR_RESET% %COLOR_WHITE%Deconnexion des comptes OneDrive...%COLOR_RESET%
powershell -NoProfile -Command "try { Import-Module -Name Microsoft.PowerShell.Management -Force; Get-ChildItem 'HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts' -ErrorAction SilentlyContinue | ForEach-Object { Remove-Item $_.PSPath -Recurse -Force -ErrorAction SilentlyContinue } } catch {}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Comptes OneDrive deconnectes%COLOR_RESET%

REM  Commande pour desinstaller OneDrive
echo %COLOR_YELLOW%[3/7]%COLOR_RESET% %COLOR_WHITE%Execution du desinstalleur OneDrive Windows...%COLOR_RESET%
set "ONEDRIVE_UNINSTALLER="
if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
    set "ONEDRIVE_UNINSTALLER=%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe"
) else if exist "%SYSTEMROOT%\System32\OneDriveSetup.exe" (
    set "ONEDRIVE_UNINSTALLER=%SYSTEMROOT%\System32\OneDriveSetup.exe"
)
if defined ONEDRIVE_UNINSTALLER (
    "!ONEDRIVE_UNINSTALLER!" /uninstall >nul 2>&1
    if !errorlevel! EQU 0 (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Desinstalleur OneDrive execute%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le desinstalleur OneDrive a retourne une erreur ; le nettoyage continue.%COLOR_RESET%
    )
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Desinstalleur OneDrive absent ; le nettoyage continue.%COLOR_RESET%
)
set "ONEDRIVE_UNINSTALLER="

echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression des cles de registre OneDrive - operation irreversible.%COLOR_RESET%
echo %COLOR_YELLOW%[4/7]%COLOR_RESET% %COLOR_WHITE%Nettoyage des cles de registre OneDrive...%COLOR_RESET%
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
reg delete "HKLM\SOFTWARE\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\OneDrive" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run" /v "OneDrive" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Cles OneDrive nettoyees%COLOR_RESET%

echo %COLOR_YELLOW%[5/7]%COLOR_RESET% %COLOR_WHITE%Suppression des taches planifiees OneDrive...%COLOR_RESET%
for /f "tokens=1 delims=," %%x in ('schtasks /query /fo csv 2^>nul ^| find "OneDrive"') do (
    set "TASKNAME=%%~x"
    set "TASKNAME=!TASKNAME:"=!"
    schtasks /delete /TN "!TASKNAME!" /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Taches planifiees OneDrive supprimees%COLOR_RESET%

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Desinstallation de OneDrive terminee (si installe).%COLOR_RESET%
echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression definitive des dossiers OneDrive restants (takeown + rd).%COLOR_RESET%
echo %COLOR_YELLOW%[6/7]%COLOR_RESET% %COLOR_WHITE%Nettoyage des dossiers OneDrive restants...%COLOR_RESET%
if exist "%AppData%\Microsoft\OneDrive" rd "%AppData%\Microsoft\OneDrive" /q /s >nul 2>&1
if exist "%SystemDrive%\OneDriveTemp" rd "%SystemDrive%\OneDriveTemp" /q /s >nul 2>&1
REM  Wildcards : rd ne supporte pas les wildcards, il faut une enumeration for /d
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Dossiers OneDrive restants nettoyes%COLOR_RESET%

REM  Supprimer les raccourcis OneDrive du menu Demarrer
echo %COLOR_YELLOW%[7/7]%COLOR_RESET% %COLOR_WHITE%Suppression des raccourcis OneDrive...%COLOR_RESET%
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft OneDrive.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Links\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourcis OneDrive supprimes%COLOR_RESET%

set "ONEDRIVE_REMOVE_OK=1"
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\OneDrive.exe" set "ONEDRIVE_REMOVE_OK=0"
if exist "%ProgramFiles%\Microsoft OneDrive\OneDrive.exe" set "ONEDRIVE_REMOVE_OK=0"
if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\Microsoft OneDrive\OneDrive.exe" set "ONEDRIVE_REMOVE_OK=0"
if exist "%USERPROFILE%\OneDrive" set "ONEDRIVE_REMOVE_OK=0"
if "!ONEDRIVE_REMOVE_OK!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nettoyage complet de OneDrive termine.%COLOR_RESET%
    call :FINISH_ACTION "OneDrive" "desinstalle"
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Desinstallation OneDrive incomplete : executable ou dossier utilisateur encore present.%COLOR_RESET%
    if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage peut liberer les fichiers encore verrouilles.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
)
set "ONEDRIVE_REMOVE_OK="
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
echo %COLOR_WHITE%- Recherche, Widgets, Meteo et certaines PWA peuvent ne plus fonctionner sans Edge.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%La desinstallation libere ~1 Go et reduit les processus en arriere-plan.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le risque de compatibilite est plus limite tant que WebView2 reste present.%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desinstaller Microsoft Edge ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_GESTION_WINDOWS
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SUPPRESSION DES DONNEES UTILISATEUR%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_WHITE%Pourquoi une question separee :%COLOR_RESET%
echo %COLOR_WHITE%- Sans suppression, profils et caches restent sur le disque ^(reinstall ou autre navigateur^).%COLOR_RESET%
echo %COLOR_WHITE%- Avec suppression, favoris, mots de passe et donnees locales seront perdus.%COLOR_RESET%
echo %COLOR_WHITE%  Exportez vos favoris depuis Edge avant si vous souhaitez les conserver.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Voulez-vous supprimer les donnees utilisateur d'Edge ?%COLOR_RESET%
echo %COLOR_WHITE%- Historique de navigation%COLOR_RESET%
echo %COLOR_WHITE%- Cookies et donnees de sites%COLOR_RESET%
echo %COLOR_WHITE%- Favoris/Signets%COLOR_RESET%
echo %COLOR_WHITE%- Mots de passe sauvegardes%COLOR_RESET%
echo %COLOR_WHITE%- Extensions et themes%COLOR_RESET%
echo %COLOR_WHITE%- Parametres et preferences%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de supprimer les donnees utilisateur Edge ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 (
    set "SUPPR_DATA=0"
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Les donnees utilisateur seront preservees.%COLOR_RESET%
) else (
    set "SUPPR_DATA=1"
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Les donnees utilisateur seront supprimees.%COLOR_RESET%
)

cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% EXECUTION - DESINSTALLATION COMPLETE DE MICROSOFT EDGE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%Progression : arret, desinstallation, nettoyage dossiers, registre, raccourcis et blocage.%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[1/12]%COLOR_RESET% %COLOR_WHITE%Arret des processus Edge...%COLOR_RESET%
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Processus Edge arretes%COLOR_RESET%

echo %COLOR_YELLOW%[2/12]%COLOR_RESET% %COLOR_WHITE%Suppression de l'icone Edge de la barre des taches...%COLOR_RESET%
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q >nul 2>&1
if not exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" goto :EDGE_SKIP_TASKBAR_LINKS
call :REMOVE_EDGE_TASKBAR_LINKS
:EDGE_SKIP_TASKBAR_LINKS
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci barre des taches supprime%COLOR_RESET%

echo %COLOR_YELLOW%[3/12]%COLOR_RESET% %COLOR_WHITE%Tentative de desinstallation de Microsoft Edge via l'installateur officiel...%COLOR_RESET%
set "EDGE_UNINSTALLER_FOUND=0"
set "EDGE_UNINSTALLER_ERROR=0"
if exist "%ProgramFiles%\Microsoft\Edge\Application" call :RUN_EDGE_UNINSTALLER "%ProgramFiles%\Microsoft\Edge\Application"
if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" call :RUN_EDGE_UNINSTALLER "%ProgramFiles(x86)%\Microsoft\Edge\Application"
:EDGE_SKIP_OFFICIAL_UNINSTALLER
if "!EDGE_UNINSTALLER_ERROR!"=="1" (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Le desinstalleur Edge a retourne une erreur ; le nettoyage force continue.%COLOR_RESET%
) else if "!EDGE_UNINSTALLER_FOUND!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Desinstalleur Edge execute%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Aucun desinstalleur Edge officiel trouve ; le nettoyage force continue.%COLOR_RESET%
)
set "EDGE_UNINSTALLER_FOUND="
set "EDGE_UNINSTALLER_ERROR="

echo %COLOR_YELLOW%[4/12]%COLOR_RESET% %COLOR_WHITE%Nettoyage force des dossiers programme...%COLOR_RESET%
rd "%ProgramFiles%\Microsoft\Edge" /s /q >nul 2>&1
if defined ProgramFiles(x86) rd "%ProgramFiles(x86)%\Microsoft\Edge" /s /q >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Dossiers programme supprimes%COLOR_RESET%

echo %COLOR_YELLOW%[5/12]%COLOR_RESET% %COLOR_WHITE%Nettoyage des cles de registre Edge...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Cles de registre nettoyees%COLOR_RESET%

echo %COLOR_YELLOW%[6/12]%COLOR_RESET% %COLOR_WHITE%Gestion des donnees utilisateur...%COLOR_RESET%
if "%SUPPR_DATA%"=="1" (
    if exist "%LOCALAPPDATA%\Microsoft\Edge" rd "%LOCALAPPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    if exist "%APPDATA%\Microsoft\Edge" rd "%APPDATA%\Microsoft\Edge" /s /q >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur supprimees%COLOR_RESET%
) else (
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\BrowserSwitcher" /f >nul 2>&1
    reg delete "HKEY_CURRENT_USER\Software\Microsoft\Edge\PreferenceMACs" /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Donnees utilisateur preservees%COLOR_RESET%
)

echo %COLOR_YELLOW%[7/12]%COLOR_RESET% %COLOR_WHITE%Nettoyage des donnees systeme communes (ProgramData)...%COLOR_RESET%
rd "%PROGRAMDATA%\Microsoft\Edge" /s /q >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Donnees systeme communes nettoyees%COLOR_RESET%

echo %COLOR_YELLOW%[8/12]%COLOR_RESET% %COLOR_WHITE%Suppression des raccourcis Bureau et Menu Demarrer...%COLOR_RESET%
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%PUBLIC%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourcis supprimes%COLOR_RESET%

echo %COLOR_YELLOW%[9/12]%COLOR_RESET% %COLOR_WHITE%Suppression des associations de fichiers et protocoles...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Classes\MSEdgeHTM" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\MSEdgePDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Applications\msedge.exe" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Associations de fichiers supprimees%COLOR_RESET%

echo %COLOR_YELLOW%[10/12]%COLOR_RESET% %COLOR_WHITE%Nettoyage de l'index de recherche et du menu demarrer...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths\msedge.exe" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_http" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\ApplicationAssociationToasts" /v "MSEdgeHTM_https" /f >nul 2>&1
rd "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
rd "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge" /s /q >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Index de recherche et menu demarrer nettoyes%COLOR_RESET%

echo %COLOR_YELLOW%[11/12]%COLOR_RESET% %COLOR_WHITE%Nettoyage du cache d'icones et du MUI Cache...%COLOR_RESET%
del "%LOCALAPPDATA%\IconCache.db" /f /q >nul 2>&1
del "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache*.db" /f /q >nul 2>&1
if defined ProgramFiles(x86) reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1
reg delete "HKCU\Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache" /v "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe.FriendlyAppName" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Caches d'icones et MUI Cache nettoyes%COLOR_RESET%

echo %COLOR_YELLOW%[12/12]%COLOR_RESET% %COLOR_WHITE%Blocage des reinstallations automatiques...%COLOR_RESET%
REM  Strategies Edge Update officielles. Elles sont surtout garanties sur les appareils joints a un domaine.
set "EDGE_POLICY_ERROR=0"
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "InstallDefault" /t REG_DWORD /d 2 /f >nul 2>&1 || set "EDGE_POLICY_ERROR=1"
reg add "HKLM\SOFTWARE\Policies\Microsoft\EdgeUpdate" /v "Install{56EB18F8-B008-4CBD-B6D2-8C97FE7E9062}" /t REG_DWORD /d 0 /f >nul 2>&1 || set "EDGE_POLICY_ERROR=1"
reg delete "HKLM\SOFTWARE\Microsoft\EdgeUpdate" /v "DoNotUpdateToEdgeWithChromium" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main" /v "PreventFirstRunPage" /f >nul 2>&1
if "!EDGE_POLICY_ERROR!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Strategie de blocage Edge appliquee lorsqu'elle est prise en charge%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Edge est retire, mais la strategie anti-reinstallation n'a pas pu etre appliquee.%COLOR_RESET%
)
set "EDGE_POLICY_ERROR="

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification finale de la desinstallation...%COLOR_RESET%
set "EDGE_REMOVE_OK=1"
if exist "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe" (
    set "EDGE_REMOVE_OK=0"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Edge n'a pas pu etre completement desinstalle.%COLOR_RESET%
) else (
    if defined ProgramFiles(x86) if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        set "EDGE_REMOVE_OK=0"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Edge n'a pas pu etre completement desinstalle.%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Microsoft Edge desinstalle avec succes !%COLOR_RESET%
    )
)

echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
if "!EDGE_REMOVE_OK!"=="1" (
    echo  %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Microsoft Edge a ete desinstalle completement.%COLOR_RESET%
) else (
    echo  %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Desinstallation Edge incomplete. Consultez les messages ci-dessus.%COLOR_RESET%
)
if "%SUPPR_DATA%"=="0" (
    echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Vos favoris, mots de passe et historique ont ete preserves.%COLOR_RESET%
)
echo  %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%L'icone Edge a ete supprimee de la barre des taches.%COLOR_RESET%
set "SUPPR_DATA="
if "!EDGE_REMOVE_OK!"=="1" (
    call :FINISH_ACTION "Microsoft Edge" "desinstalle"
) else (
    if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage peut liberer les fichiers encore verrouilles.%COLOR_RESET%
    call :PROMPT_MANUAL_REBOOT
)
set "EDGE_REMOVE_OK="
goto :MENU_GESTION_WINDOWS

:OUTIL_ACTIVATION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% OUTIL D'ACTIVATION WINDOWS / OFFICE (MAS)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Lancement de l'outil d'activation...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Veuillez suivre les instructions a l'ecran.%COLOR_RESET%
call :RUN_REMOTE_PS "https://get.activated.win"
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Outil d'activation termine.%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de telecharger ou d'executer l'outil d'activation.%COLOR_RESET%
)
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
call :RUN_REMOTE_PS "https://github.com/ChrisTitusTech/winutil/releases/latest/download/winutil.ps1"
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Outil Chris Titus Tech termine.%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Impossible de telecharger ou d'executer WinUtil.%COLOR_RESET%
)
pause
goto :MENU_PRINCIPAL

:CREER_POINT_RESTAURATION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% CREATION D'UN POINT DE RESTAURATION%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification et activation de la restauration systeme si necessaire...%COLOR_RESET%
powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive ($env:SystemDrive+'\') -ErrorAction Stop; exit 0 } catch { exit 1 }" >nul 2>&1
if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Restauration systeme disponible sur %SystemDrive%.%COLOR_RESET%
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%Activation non confirmee ; tentative de creation du point maintenue.%COLOR_RESET%
)
timeout /t 2 /nobreak >nul
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Creation d'un point de restauration en cours...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Cette operation peut prendre 30-60 secondes...%COLOR_RESET%
echo.

for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "RP_TIMESTAMP=%%a"
powershell -NoProfile -Command "$ErrorActionPreference='Stop'; $key='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore'; $name='SystemRestorePointCreationFrequency'; $had=$false; $old=$null; $ok=$false; try { $p=Get-ItemProperty -LiteralPath $key -ErrorAction Stop; $had=$p.PSObject.Properties.Name -contains $name; if($had){$old=$p.$name; Set-ItemProperty -LiteralPath $key -Name $name -Value 0 -ErrorAction Stop}else{New-ItemProperty -LiteralPath $key -Name $name -PropertyType DWord -Value 0 -Force -ErrorAction Stop | Out-Null}; Checkpoint-Computer -Description 'Optimizations_%RP_TIMESTAMP%' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; $ok=$true } catch { $ok=$false } finally { try { if($had){Set-ItemProperty -LiteralPath $key -Name $name -Value $old -ErrorAction Stop}else{Remove-ItemProperty -LiteralPath $key -Name $name -ErrorAction SilentlyContinue} } catch { $ok=$false } }; if($ok){exit 0}else{exit 1}" >nul 2>&1
if !errorlevel! EQU 0 (
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
echo %STYLE_BOLD%%COLOR_WHITE% NETTOYAGE AVANCE WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

REM  Analyse espace initial
set "SPACE_BEFORE_MB="
for /f %%a in ('powershell -NoProfile -NoLogo -Command "[int]((Get-PSDrive -Name '%SystemDrive:~0,1%').Free / 1MB)"') do set "SPACE_BEFORE_MB=%%a"
if defined SPACE_BEFORE_MB (
    set "SPACE_MEASURE_OK=1"
) else (
    set "SPACE_MEASURE_OK=0"
    set "SPACE_BEFORE_MB=0"
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%AVERTISSEMENT :%COLOR_RESET%
echo %COLOR_WHITE%  Ce script va supprimer : fichiers temporaires, anciens logs, rapports d'erreurs,%COLOR_RESET%
echo %COLOR_WHITE%  corbeille, caches Windows 11 (Widgets, Copilot, Recall), icones,%COLOR_RESET%
echo %COLOR_WHITE%  cache npm, notifications et journaux archives.%COLOR_RESET%
echo %COLOR_WHITE%  %STYLE_BOLD%Aucune donnee personnelle (favoris, mots de passe, documents) n'est touchee.%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%L'historique Windows Update et les fichiers de recuperation sont conserves.%COLOR_RESET%
echo.
<nul set /p ="%COLOR_YELLOW%Continuer ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_PRINCIPAL

cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% NETTOYAGE AVANCE WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

REM  Initialiser la barre de progression (26 etapes - caches de perf conserves)
set /a "CLEAN_TOTAL=26"
set /a "CLEAN_STEP=0"
set /a "CLEAN_WARNINGS=0"
set "CLEAN_SCRIPT_PATH=%~f0"

REM  ETAPE 1 - Fichiers temporaires utilisateur (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires utilisateur"
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue';$self=[IO.Path]::GetFullPath($env:CLEAN_SCRIPT_PATH);Get-ChildItem -LiteralPath $env:TEMP -Force|Where-Object{$p=[IO.Path]::GetFullPath($_.FullName);$p-ne$self-and-not $self.StartsWith($p+'\',[StringComparison]::OrdinalIgnoreCase)}|Remove-Item -Recurse -Force -ErrorAction SilentlyContinue;exit 0" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Office\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Office\*.tmp" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" del /s /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" >nul 2>&1

REM  ETAPE 2 - Fichiers temporaires Windows (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires Windows"
del /s /q /f "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" >nul 2>&1
if exist "%SystemRoot%\Servicing\LC\*.tmp" del /s /q /f "%SystemRoot%\Servicing\LC\*.tmp" >nul 2>&1

REM  ETAPE 3 - Logs systeme (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs systeme"
del /s /q /f "%SystemRoot%\Logs\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\LogFiles\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Panther\*.log" >nul 2>&1

REM  ETAPE 4 - Fichiers de crash / dumps (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers de crash et dumps"
del /s /q /f "%SystemRoot%\Minidump\*.*" >nul 2>&1
del /q /f "%SystemRoot%\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\memory.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\LiveKernelReports\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\Sysdata\*.dmp" >nul 2>&1
del /s /q /f "%LOCALAPPDATA%\CrashDumps\*.*" >nul 2>&1

REM  ETAPE 5 - Rapports d'erreurs et Telemetrie
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Rapports d'erreurs et Telemetrie"
for %%D in (ReportArchive ReportQueue Temp) do if exist "%ProgramData%\Microsoft\Windows\WER\%%D" rd /s /q "%ProgramData%\Microsoft\Windows\WER\%%D" >nul 2>&1
for %%D in (ReportArchive ReportQueue Temp) do if exist "%LOCALAPPDATA%\Microsoft\Windows\WER\%%D" rd /s /q "%LOCALAPPDATA%\Microsoft\Windows\WER\%%D" >nul 2>&1
REM  Le dossier Diagnosis et les racines WER sont conserves pour garder leurs ACL et services intacts.

REM  ETAPE 6 - Cache Windows Update et Delivery Optimization
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Update et Delivery Optimization"
for %%S in (wuauserv bits cryptsvc dosvc) do (
    set "CLEAN_WAS_RUNNING_%%S=0"
    powershell -NoProfile -Command "try { if((Get-Service -Name '%%S' -ErrorAction Stop).Status -eq 'Running'){exit 0}else{exit 1} } catch { exit 2 }" >nul 2>&1
    if !errorlevel! EQU 0 set "CLEAN_WAS_RUNNING_%%S=1"
    net stop %%S >nul 2>&1
)
timeout /t 2 /nobreak >nul
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
REM  DataStore et ReportingEvents.log contiennent l'historique Windows Update : ne pas les effacer.
if exist "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" (
    rd /s /q "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
    md "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
)
for %%S in (wuauserv bits cryptsvc dosvc) do (
    if "!CLEAN_WAS_RUNNING_%%S!"=="1" net start %%S >nul 2>&1
    set "CLEAN_WAS_RUNNING_%%S="
)

REM  ETAPE 7 - Corbeille
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Corbeille"
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

REM  ETAPE 8 - Journaux composants Windows (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux composants Windows"
del /s /q /f "%SystemRoot%\Logs\CBS\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\CBS\*.cab" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.cab" >nul 2>&1

REM  ETAPE 9 - Cache de polices
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache de polices"
set "CLEAN_FONTCACHE_WAS_RUNNING=0"
powershell -NoProfile -Command "try{if((Get-Service FontCache -ErrorAction Stop).Status -eq 'Running'){exit 0};exit 1}catch{exit 2}" >nul 2>&1
if !errorlevel! EQU 0 set "CLEAN_FONTCACHE_WAS_RUNNING=1"
net stop FontCache >nul 2>&1
timeout /t 1 /nobreak >nul
del /s /q /f "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /q /f "%SystemRoot%\System32\FNTCACHE.DAT" >nul 2>&1
if "!CLEAN_FONTCACHE_WAS_RUNNING!"=="1" net start FontCache >nul 2>&1
set "CLEAN_FONTCACHE_WAS_RUNNING="

REM  ETAPE 10 - Cache Windows Store et applications (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Store et applications"
powershell -NoProfile -Command "Get-ChildItem -Path ""$env:LOCALAPPDATA\Packages"" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Edge|WebView|Microsoft\.Windows' } | ForEach-Object { Remove-Item -Path ""$($_.FullName)\AC\INetCache\*"" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path ""$($_.FullName)\AC\Temp\*"" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path ""$($_.FullName)\LocalState\Cache\*"" -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1
REM  wsreset.exe supprime (ouvre UI Store + 5-15s); vidage PS du cache suffit

REM  ETAPE 11 - Cache DNS
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache DNS"
ipconfig /flushdns >nul 2>&1

REM  ETAPE 12 - Journaux Event Viewer archives uniquement
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux Event Viewer archives"
del /q /f "%SystemRoot%\System32\winevt\Logs\Archive-*.evtx" >nul 2>&1
REM  Les journaux actifs Systeme, Application et Securite restent disponibles pour le diagnostic.

REM  ETAPE 13 - Ancienne installation Windows avec confirmation
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Anciennes installations Windows"
if exist "%SystemDrive%\Windows.old" (
    echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression definitive de Windows.old ^(~15-25 Go^).%COLOR_RESET%
    call :ASK_IF_INTERACTIVE :SUPPR_WINDOWSOLD "Supprimer Windows.old ? [O/N]: "
    if !errorlevel! EQU 0 (
        takeown /f "%SystemDrive%\Windows.old" /r /d y >nul 2>&1
        icacls "%SystemDrive%\Windows.old" /grant *S-1-5-32-544:F /t >nul 2>&1
        rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
    ) else (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Windows.old conserve.%COLOR_RESET%
    )
)
REM  $SysReset, $Windows.~BT et $Windows.~WS sont conserves : ils peuvent servir a la recuperation ou a une mise a niveau en cours.

REM  ETAPE 14 - Optimisation disque (TRIM/Defrag)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation disque (TRIM/Defrag)"
defrag %SystemDrive% /O /H >nul 2>&1

REM  ETAPE 15 - Nettoyage Windows Cleanmgr (ameliore - plus de categories 2026)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Nettoyage Windows Cleanmgr"
call :SELECT_CLEANMGR_SAGEID
REM Exclusions volontaires : Previous Installations (confirmation etape 13), Windows ESD
REM (source de reinitialisation) et User file versions (donnees de recuperation utilisateur).
for %%K in ("Active Setup Temp Folders" "BranchCache" "Content Indexer Cleaner" "Delivery Optimization Files" "Device Driver Packages" "Diagnostic Data Viewer database files" "Downloaded Program Files" "GameNewsFiles" "GameStatisticsFiles" "GameUpdateFiles" "Language Pack" "Memory Dump Files" "Offline Pages Files" "Old ChkDsk Files" "Recycle Bin" "RetailDemo Offline Content" "Service Pack Cleanup" "Setup Log Files" "System error memory dump files" "System error minidump files" "Temporary Files" "Temporary Setup Files" "Temporary Sync Files" "Thumbnail Cache" "Update Cleanup" "Upgrade Discarded Files" "Windows Defender" "Windows Error Reporting Archive Files" "Windows Error Reporting Files" "Windows Error Reporting Queue Files" "Windows Error Reporting System Archive Files" "Windows Error Reporting System Queue Files" "Windows Error Reporting Temp Files" "Windows Upgrade Log Files") do (
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" >nul 2>&1
    if !errorlevel! EQU 0 reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v StateFlags%SAGEID% /t REG_DWORD /d 2 /f >nul 2>&1
)
REM /sagerun nettoie tous les disques ; /d est ignore (non documente avec /sagerun).
powershell -NoProfile -Command "try {$p=Start-Process -FilePath 'cleanmgr' -ArgumentList '/sagerun:%SAGEID%' -NoNewWindow -PassThru -ErrorAction Stop;if(-not $p.WaitForExit(120000)){try{$p.Kill();$p.WaitForExit()}catch{};exit 2};exit $p.ExitCode}catch{exit 1}" >nul 2>&1
set "CLEANMGR_RC=!errorlevel!"
if not "!CLEANMGR_RC!"=="0" (
    set /a "CLEAN_WARNINGS+=1"
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%Cleanmgr n'a pas termine normalement ; les autres nettoyages continuent.%COLOR_RESET%
)
powershell -NoProfile -Command "Get-ChildItem 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches' -ErrorAction SilentlyContinue|ForEach-Object{Remove-ItemProperty -LiteralPath $_.PSPath -Name 'StateFlags%SAGEID%' -ErrorAction SilentlyContinue}" >nul 2>&1
set "CLEANMGR_RC="

REM  ETAPE 16 - Nettoyage composants systeme (via DISM)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Composants systeme (nettoyage)"
dism /online /Cleanup-Image /StartComponentCleanup /Quiet >nul 2>&1
set "CLEAN_DISM_RC=!errorlevel!"
if not "!CLEAN_DISM_RC!"=="0" if not "!CLEAN_DISM_RC!"=="3010" (
    set /a "CLEAN_WARNINGS+=1"
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_YELLOW%Le nettoyage des composants Windows n'a pas termine normalement ^(code !CLEAN_DISM_RC!^).%COLOR_RESET%
)
set "CLEAN_DISM_RC="

REM  ETAPE 17 - Fichiers temporaires profil systeme (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Profil systeme et caches Internet"
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\*.tmp" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\*.*" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\LocalLow\*.tmp" >nul 2>&1

REM  ETAPE 18 - Cache d'icones (securise - redemarre l'explorateur)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache d'icones"
set "CLEAN_EXPLORER_WAS_RUNNING=0"
tasklist /fi "imagename eq explorer.exe" 2>nul | find /i "explorer.exe" >nul
if !errorlevel! EQU 0 set "CLEAN_EXPLORER_WAS_RUNNING=1"
if "!CLEAN_EXPLORER_WAS_RUNNING!"=="1" taskkill /f /im explorer.exe >nul 2>&1
if "!CLEAN_EXPLORER_WAS_RUNNING!"=="1" timeout /t 1 /nobreak >nul
del /q /f "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*" >nul 2>&1
del /q /f "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1
if "!CLEAN_EXPLORER_WAS_RUNNING!"=="1" start explorer.exe >nul 2>&1
set "CLEAN_EXPLORER_WAS_RUNNING="

REM  ETAPE 19 - Caches Windows 11 : Widgets, Copilot, Recall (nouveau W11 2026)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Widgets, Copilot, Recall"
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AC\INetCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AC\INetCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\AC\INetCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\AC\INetCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\LocalCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\LocalCache" >nul 2>&1
REM  Copilot (W11 24H2+)
if exist "%LOCALAPPDATA%\Packages\Microsoft.Windows.Copilot_*\AC\INetCache" for /d %%d in ("%LOCALAPPDATA%\Packages\Microsoft.Windows.Copilot_*") do (
    if exist "%%d\AC\INetCache" rd /s /q "%%d\AC\INetCache" >nul 2>&1
    if exist "%%d\LocalCache" rd /s /q "%%d\LocalCache" >nul 2>&1
)
REM  Recall / AI Explorer (W11 2025+) - caches INet temporaires uniquement
if exist "%LOCALAPPDATA%\Packages\Microsoft.Windows.AI.Explorer_*\AC\Temp" for /d %%d in ("%LOCALAPPDATA%\Packages\Microsoft.Windows.AI.Explorer_*") do (
    if exist "%%d\AC\Temp" rd /s /q "%%d\AC\Temp" >nul 2>&1
)
REM  Recall snapshots conserves (donnees personnelles)

REM  ETAPE 20 - Cache notifications logs (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs notifications"
if exist "%LOCALAPPDATA%\Microsoft\Windows\Notifications" (
    del /s /q /f "%LOCALAPPDATA%\Microsoft\Windows\Notifications\*.log" >nul 2>&1
)

REM  ETAPE 21 - Logs et setup OneDrive (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs OneDrive"
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\logs" rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive\logs" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\logs" rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive\setup\logs" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" del /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.tmp" del /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.tmp" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\*.tmp" >nul 2>&1

REM  ETAPE 22 - Logs support Windows Defender (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs support Defender"
if exist "%ProgramData%\Microsoft\Windows Defender\Support\*.log" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Support\*.log" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows Defender\Support\*.cab" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Support\*.cab" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows Defender\Support\*.tmp" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Support\*.tmp" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows Defender\Scans\*.tmp" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Scans\*.tmp" >nul 2>&1

REM  ETAPE 23 - Optimisation indexation Windows Search (compacte uniquement)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation indexation recherche"
set "CLEAN_WSEARCH_WAS_RUNNING=0"
powershell -NoProfile -Command "try{if((Get-Service WSearch -ErrorAction Stop).Status -eq 'Running'){exit 0};exit 1}catch{exit 2}" >nul 2>&1
if !errorlevel! EQU 0 set "CLEAN_WSEARCH_WAS_RUNNING=1"
net stop WSearch >nul 2>&1
timeout /t 1 /nobreak >nul
if exist "%ProgramData%\Microsoft\Search\Data\Applications\Windows\*.log" del /s /q /f "%ProgramData%\Microsoft\Search\Data\Applications\Windows\*.log" >nul 2>&1
if "!CLEAN_WSEARCH_WAS_RUNNING!"=="1" net start WSearch >nul 2>&1
set "CLEAN_WSEARCH_WAS_RUNNING="

REM  ETAPE 24 - Cache RDP / Bureau a distance (nouveau)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Bureau a distance (RDP)"
if exist "%LOCALAPPDATA%\Microsoft\TerminalServerClient\Cache" rd /s /q "%LOCALAPPDATA%\Microsoft\TerminalServerClient\Cache" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Remote Desktop Connection Manager\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Remote Desktop Connection Manager\*.tmp" >nul 2>&1

REM  ETAPE 25 - Logs et temps Office (inoffensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Temporaires Office"
if exist "%LOCALAPPDATA%\Microsoft\Office\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Office\*.tmp" >nul 2>&1
if exist "%TEMP%\Microsoft\Office\*.tmp" del /s /q /f "%TEMP%\Microsoft\Office\*.tmp" >nul 2>&1

REM  ETAPE 26 - Cache npm (node package manager)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache npm"
powershell -NoProfile -Command "$cache=npm config get cache 2>$null; if($cache -and (Test-Path $cache)){ Remove-Item -LiteralPath $cache -Recurse -Force -ErrorAction SilentlyContinue; Write-Output 'OK' }" >nul 2>&1

REM  Calcul final (PowerShell pour la precision des decimales)
if "%SPACE_MEASURE_OK%"=="1" (
    for /f "tokens=1-3" %%a in ('powershell -NoProfile -Command "$before=[long]%SPACE_BEFORE_MB% * 1024 * 1024; $after=(Get-PSDrive -Name '%SystemDrive:~0,1%').Free; $freed=$after-$before; if($freed -lt 0){$freed=0}; $beforeGB=[math]::Round($before/1GB, 2); $afterGB=[math]::Round($after/1GB, 2); $freedGB=[math]::Round($freed/1GB, 2); Write-Output ('{0} {1} {2}' -f $beforeGB,$afterGB,$freedGB)"') do (
        set "SPACE_BEFORE_GB=%%a"
        set "SPACE_AFTER_GB=%%b"
        set "SPACE_FREED_GB=%%c"
    )
)
if not defined SPACE_FREED_GB (
    set "SPACE_BEFORE_GB=N/D"
    set "SPACE_AFTER_GB=N/D"
    set "SPACE_FREED_GB=N/D"
)

set "CLEAN_STEP="
set "CLEAN_TOTAL="
set "CLEAN_SCRIPT_PATH="

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Nettoyage avance termine%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo   %COLOR_WHITE%Espace avant :%COLOR_RESET% %COLOR_YELLOW%%SPACE_BEFORE_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace apres :%COLOR_RESET% %COLOR_GREEN%%SPACE_AFTER_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace gagne :%COLOR_RESET% %COLOR_CYAN%%SPACE_FREED_GB% Go%COLOR_RESET%
if not "%CLEAN_WARNINGS%"=="0" echo   %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%%CLEAN_WARNINGS% etape^(s^) terminee^(s^) avec avertissement.%COLOR_RESET%
echo.
if not "!SKIP_PAUSE!"=="1" echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser.%COLOR_RESET%
call :PROMPT_MANUAL_REBOOT
set "SAGEID="
set "SPACE_BEFORE_MB="
set "SPACE_BEFORE_GB="
set "SPACE_AFTER_GB="
set "SPACE_FREED_GB="
set "SPACE_MEASURE_OK="
set "CLEAN_WARNINGS="
goto :MENU_PRINCIPAL


:INSTALLER_VISUAL_REDIST
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% INSTALLATION DES RUNTIMES VISUAL C++ ET DIRECTX%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Detection du runtime Visual C++ v14 actuel...%COLOR_RESET%

REM  Detection via les cles VC14 officielles (Installed=1), confirmee par la DLL principale.
call :DETECT_VC14_RUNTIME
set "RUNTIME_ERROR=0"

REM  Compter combien sont deja installes
set /a "VCINSTALLED_COUNT=%VC2015X86%+%VC2015X64%" 2>nul

echo.
echo %COLOR_WHITE%Versions detectees (V14):%COLOR_RESET% %COLOR_GREEN%%VCINSTALLED_COUNT%/2%COLOR_RESET%

REM  Si tout est deja installe, afficher message et retourner
if "%VCINSTALLED_COUNT%"=="2" (
    echo.
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Toutes les versions V14 sont deja installees.%COLOR_RESET%
    set "VC2015X86="
    set "VC2015X64="
    set "VCINSTALLED_COUNT="
    if "!SKIP_PAUSE!"=="0" timeout /t 2 /nobreak >nul
    goto :INSTALLER_DIRECTX_SECTION
)

REM  Suite : installation des paquets VC++ manquants (flux sequentiel, pas de goto vers ce point)
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Installation des versions manquantes...%COLOR_RESET%
set /a "VC_TO_INSTALL=2-VCINSTALLED_COUNT"
echo %COLOR_WHITE%Packages a installer:%COLOR_RESET% %COLOR_YELLOW%%VC_TO_INSTALL%%COLOR_RESET%
echo.

REM  Initialiser la barre de progression (2 packages au total)
set /a "VC_TOTAL=2"
set /a "VC_STEP=0"

REM  Creer un dossier temporaire pour les installations
set "VCREDIST_DIR=%TEMP%\VCRedistInstall_%RANDOM%_%RANDOM%"
if not exist "%VCREDIST_DIR%" mkdir "%VCREDIST_DIR%"

REM  Visual C++ v14 actuel x86
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "Visual C++ v14 actuel x86"
if "%VC2015X86%"=="0" (
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $f=Join-Path $env:VCREDIST_DIR 'vc2015x86.exe'; Invoke-WebRequest -Uri 'https://aka.ms/vc14/vc_redist.x86.exe' -OutFile $f -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $f).Length -lt 5000000){throw 'size'};$s=Get-AuthenticodeSignature -LiteralPath $f;if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Microsoft'){throw 'signature'};exit 0 } catch { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit 1 }" >nul 2>&1
    if !errorlevel! NEQ 0 (
        set "RUNTIME_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de Visual C++ v14 x86.%COLOR_RESET%
    ) else (
        start /wait "" "%VCREDIST_DIR%\vc2015x86.exe" /q /norestart >nul 2>&1
        set "VC_EXIT=!errorlevel!"
        if "!VC_EXIT!"=="0" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x86 installe.%COLOR_RESET%
        ) else if "!VC_EXIT!"=="3010" (
            echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x86 installe - redemarrage requis.%COLOR_RESET%
        ) else if "!VC_EXIT!"=="1641" (
            echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x86 installe - redemarrage initie/requis.%COLOR_RESET%
        ) else if "!VC_EXIT!"=="1638" (
            echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x86 : une version compatible est deja presente.%COLOR_RESET%
        ) else (
            set "RUNTIME_ERROR=1"
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x86 : code installateur !VC_EXIT!.%COLOR_RESET%
        )
    )
)

REM  Visual C++ v14 actuel x64
set /a "VC_STEP+=1"
call :PROGRESS_BAR %VC_STEP% %VC_TOTAL% "Visual C++ v14 actuel x64"
if "%VC2015X64%"=="0" (
    powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $f=Join-Path $env:VCREDIST_DIR 'vc2015x64.exe'; Invoke-WebRequest -Uri 'https://aka.ms/vc14/vc_redist.x64.exe' -OutFile $f -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $f).Length -lt 5000000){throw 'size'};$s=Get-AuthenticodeSignature -LiteralPath $f;if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Microsoft'){throw 'signature'};exit 0 } catch { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit 1 }" >nul 2>&1
    if !errorlevel! NEQ 0 (
        set "RUNTIME_ERROR=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de Visual C++ v14 x64.%COLOR_RESET%
    ) else (
        start /wait "" "%VCREDIST_DIR%\vc2015x64.exe" /q /norestart >nul 2>&1
        set "VC_EXIT=!errorlevel!"
        if "!VC_EXIT!"=="0" (
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x64 installe.%COLOR_RESET%
        ) else if "!VC_EXIT!"=="3010" (
            echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x64 installe - redemarrage requis.%COLOR_RESET%
        ) else if "!VC_EXIT!"=="1641" (
            echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x64 installe - redemarrage initie/requis.%COLOR_RESET%
        ) else if "!VC_EXIT!"=="1638" (
            echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x64 : une version compatible est deja presente.%COLOR_RESET%
        ) else (
            set "RUNTIME_ERROR=1"
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Visual C++ v14 x64 : code installateur !VC_EXIT!.%COLOR_RESET%
        )
    )
)
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification des installations...%COLOR_RESET%

REM  Re-detection avec la meme source de verite qu'avant l'installation.
call :DETECT_VC14_RUNTIME
set "VC2015X86_NEW=!VC2015X86!"
set "VC2015X64_NEW=!VC2015X64!"

REM  Calculer les vrais comptes
set /a "VCINSTALL=%VC2015X86_NEW%+%VC2015X64_NEW%" 2>nul

echo.
if "%VCINSTALL%"=="2" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Verification terminee - %COLOR_GREEN%%VCINSTALL%/2%COLOR_RESET% %COLOR_WHITE%versions presentes%COLOR_RESET%
) else (
    set "RUNTIME_ERROR=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Verification terminee - %COLOR_RED%%VCINSTALL%/2%COLOR_RESET% %COLOR_WHITE%versions presentes%COLOR_RESET%
)
if "!SKIP_PAUSE!"=="0" timeout /t 3 /nobreak >nul

REM  Nettoyage des fichiers temporaires
if exist "%VCREDIST_DIR%" rd /s /q "%VCREDIST_DIR%" >nul 2>&1
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
set "VC_EXIT="
goto :INSTALLER_DIRECTX_SECTION

:INSTALLER_DIRECTX_SECTION
cls
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% INSTALLATION DE DIRECTX RUNTIME (JUNE 2010)%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
if not defined RUNTIME_ERROR set "RUNTIME_ERROR=0"
call :INSTALLER_DIRECTX
if !errorlevel! NEQ 0 set "RUNTIME_ERROR=1"

if "!SKIP_PAUSE!"=="0" (
    echo.
    pause
)
if "!RUNTIME_ERROR!"=="0" (
    set "RUNTIME_ERROR="
    exit /b 0
)
set "RUNTIME_ERROR="
exit /b 1

:INSTALLER_DIRECTX
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de l'installation de DirectX...%COLOR_RESET%

REM  Detection de DirectX June 2010 (XAudio2_7.dll est un bon indicateur)
set "DX_INSTALLED=0"
REM Sur Windows 64 bits, les runtimes x64 ET x86 doivent etre presents.
REM Si une architecture manque, le redist est relance pour reparer l'installation.
if defined ProgramFiles(x86) (
    if exist "%SystemRoot%\System32\XAudio2_7.dll" if exist "%SystemRoot%\SysWOW64\XAudio2_7.dll" set "DX_INSTALLED=1"
) else (
    if exist "%SystemRoot%\System32\XAudio2_7.dll" set "DX_INSTALLED=1"
)

if "%DX_INSTALLED%"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX June 2010 est deja installe sur ce systeme.%COLOR_RESET%
    set "DX_INSTALLED="
    set "DX_TEMP="
    exit /b 0
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Preparation de l'installation...%COLOR_RESET%
set "DX_TEMP=%TEMP%\DirectXInstall_%RANDOM%_%RANDOM%"
mkdir "%DX_TEMP%"

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Telechargement de DirectX Redist June 2010 (95 Mo)...%COLOR_RESET%
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { $f=Join-Path $env:DX_TEMP 'directx_redist.exe'; Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -OutFile $f -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $f).Length -lt 80000000){throw 'size'};$s=Get-AuthenticodeSignature -LiteralPath $f;if($s.Status -ne 'Valid' -or $s.SignerCertificate.Subject -notmatch 'Microsoft'){throw 'signature'};exit 0 } catch { Remove-Item -LiteralPath $f -Force -ErrorAction SilentlyContinue; exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement de DirectX.%COLOR_RESET%
    rd /s /q "%DX_TEMP%" >nul 2>&1
    set "DX_INSTALLED="
    set "DX_TEMP="
    exit /b 1
)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Extraction des fichiers...%COLOR_RESET%
REM  Utiliser l'extracteur integre de DirectX si possible, ou fallback
"%DX_TEMP%\directx_redist.exe" /Q /T:"%DX_TEMP%" >nul 2>&1
set "DX_RESULT=!errorlevel!"

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Installation silencieuse en cours...%COLOR_RESET%
if "!DX_RESULT!"=="0" (
    if exist "%DX_TEMP%\DXSETUP.exe" (
        start /wait "" "%DX_TEMP%\DXSETUP.exe" /silent >nul 2>&1
        set "DX_RESULT=!errorlevel!"
        if "!DX_RESULT!"=="3010" (
            set "DX_REBOOT=1"
            set "DX_RESULT=0"
        )
        if "!DX_RESULT!"=="1641" (
            set "DX_REBOOT=1"
            set "DX_RESULT=0"
        )
        if "!DX_RESULT!"=="0" (
            set "DX_VERIFY=0"
            if defined ProgramFiles(x86) (
                if exist "%SystemRoot%\System32\XAudio2_7.dll" if exist "%SystemRoot%\SysWOW64\XAudio2_7.dll" set "DX_VERIFY=1"
            ) else (
                if exist "%SystemRoot%\System32\XAudio2_7.dll" set "DX_VERIFY=1"
            )
            if "!DX_VERIFY!"=="1" (
                echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX June 2010 installe et verifie avec succes.%COLOR_RESET%
                if defined DX_REBOOT echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est requis par l'installateur DirectX.%COLOR_RESET%
            ) else (
                set "DX_RESULT=1"
                echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%DXSETUP a termine sans erreur, mais les runtimes x86/x64 restent incomplets.%COLOR_RESET%
            )
            set "DX_VERIFY="
        ) else (
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%DXSETUP a retourne le code !DX_RESULT! - installation peut etre incomplete.%COLOR_RESET%
        )
    ) else (
        set "DX_RESULT=1"
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%DXSETUP.exe est introuvable apres extraction.%COLOR_RESET%
    )
) else (
    set "DX_RESULT=1"
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Une erreur est survenue lors de l'extraction.%COLOR_RESET%
)

REM  Nettoyage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des fichiers temporaires...%COLOR_RESET%
rd /s /q "%DX_TEMP%" >nul 2>&1

set "DX_INSTALLED="
set "DX_TEMP="
set "DX_REBOOT="
if "!DX_RESULT!"=="0" (
    set "DX_RESULT="
    exit /b 0
)
set "DX_RESULT="
exit /b 1


:SUPPRIMER_BLOATWARES
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SUPPRESSION DES BLOATWARES (APPS UWP)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section supprime les applications preinstallees inutiles%COLOR_RESET%
echo %COLOR_WHITE%  tout en preservant les outils essentiels (Calculatrice, Store, Photos, Notes).%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Sont supprimes : News, Solitaire, Skype, People, Family, Candy Crush, Assistance, Maps, Office, Feedback...%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Sont gardes   : Courrier, Meteo, Musique, Video, Calculatrice, Store, Photos, Notes, etc.%COLOR_RESET%
echo.
<nul set /p ="%COLOR_YELLOW%Voulez-vous supprimer les bloatwares ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_GESTION_WINDOWS

cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% EXECUTION - SUPPRESSION DES BLOATWARES (APPS UWP)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Recherche et suppression des UWP Bloatwares...%COLOR_RESET%
powershell -NoProfile -Command "$apps = @('Microsoft.BingNews', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.SkypeApp', 'Microsoft.FeedbackHub', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.OneConnect', 'Microsoft.WindowsMaps', 'Microsoft.MixedReality.Portal', 'Microsoft.People', 'Microsoft.Family', 'King.CandyCrushSaga', 'King.CandyCrushSodaSaga', 'Microsoft.QuickAssist'); $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; foreach ($app in $apps) { if (Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue) { Write-Host \"   [-] Suppression de : $app ...\" -ForegroundColor Cyan; Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue } else { Write-Host \"   [SKIP] Non installe : $app\" -ForegroundColor DarkGray }; if ($prov) { $prov | Where-Object {$_.PackageName -match $app} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue } }"
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Suppression des bloatwares terminee.%COLOR_RESET%
pause
goto :MENU_GESTION_WINDOWS

:END_SCRIPT
REM  Sans expansion retardee : evite que les "!" dans les textes ([*], AU REVOIR!, etc.) cassent la fin du script
setlocal DisableDelayedExpansion
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% AU REVOIR! %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Merci d'avoir utilise le script d'optimisation! %COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_YELLOW%N'oubliez pas de redemarrer votre PC pour finaliser l'optimisation.%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
timeout /t 3 /nobreak >nul
REM  Ferme le setlocal DisableDelayedExpansion ouvert au debut de :END_SCRIPT
endlocal
REM  Ferme le setlocal EnableDelayedExpansion global (ligne 5)
endlocal
exit /b 0






REM  =================================================================================
REM  HELPERS MATERIEL (NIC / USB) - factorisation des blocs reseaux/energie
REM  =================================================================================
:REMOVE_COPILOT_HOSTS_BLOCK
powershell -NoProfile -Command "$ErrorActionPreference='Stop';$h=Join-Path $env:SystemRoot 'System32\drivers\etc\hosts';$item=$null;$attrs=$null;try{if(Test-Path -LiteralPath $h){$item=Get-Item -LiteralPath $h -Force -ErrorAction Stop;$attrs=$item.Attributes;$item.IsReadOnly=$false;$c=[IO.File]::ReadAllText($h);$s='# Copilot Block Start';$e='# Copilot Block End';$n=$c -replace ('(?s)\r?\n?'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)),'';if($n-ne$c){[IO.File]::WriteAllText($h,$n,[Text.Encoding]::ASCII)}};exit 0}catch{exit 1}finally{if($item-ne$null-and $attrs-ne$null){try{$item.Attributes=$attrs}catch{}}}" >nul 2>&1
exit /b !errorlevel!

:DELETE_REG_VALUE_IF_PRESENT
reg query "%~1" /v "%~2" >nul 2>&1
if !errorlevel! NEQ 0 exit /b 0
reg delete "%~1" /v "%~2" /f >nul 2>&1
exit /b !errorlevel!

:SELECT_CLEANMGR_SAGEID
REM  Choisir un identifiant libre pour ne pas ecraser une configuration cleanmgr existante.
for /l %%N in (1,1,20) do (
    set /a "SAGEID=1000 + ^(!RANDOM! %% 30000^)"
    reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" /s /f "StateFlags!SAGEID!" >nul 2>&1
    if !errorlevel! NEQ 0 exit /b 0
)
set "SAGEID=65535"
exit /b 0

:SET_NAGLE_PROFILE
powershell -NoLogo -NoProfile -Command "$ack=[int]'%~1'; $noDelay=[int]'%~2'; $delAck=[int]'%~3'; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress }; if($ip){ New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value $ack -Force | Out-Null; New-ItemProperty -Path $p -Name TCPNoDelay -PropertyType DWord -Value $noDelay -Force | Out-Null; New-ItemProperty -Path $p -Name TcpDelAckTicks -PropertyType DWord -Value $delAck -Force | Out-Null } }" >nul 2>&1
exit /b

:RESET_NAGLE_PROFILE
REM Les cles sont absentes par defaut : les supprimer restaure le comportement TCP natif.
powershell -NoLogo -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object { Remove-ItemProperty -LiteralPath $_.PSPath -Name TcpAckFrequency,TCPNoDelay,TcpDelAckTicks -ErrorAction SilentlyContinue }" >nul 2>&1
exit /b

:SELECT_TARGET_POWER_SCHEME
REM Selection silencieuse pour TOUT OPTIMISER. Aucun autre reglage de la section 7 n'est execute ici.
if "%~1"=="1" (
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
    if errorlevel 1 exit /b 1
    exit /b 0
)
set "AIO_TARGET_GUID="
for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "e9a42b02-d5df-448d-aa00-03f14749eb61"') do (set "AIO_TARGET_GUID=%%G" & set "AIO_TARGET_GUID=!AIO_TARGET_GUID: =!")
if not defined AIO_TARGET_GUID (
    for /f "tokens=2 delims=:()" %%G in ('powercfg -list 2^>nul ^| findstr /i "99999999-9999-9999-9999-999999999999"') do (set "AIO_TARGET_GUID=%%G" & set "AIO_TARGET_GUID=!AIO_TARGET_GUID: =!")
)
if not defined AIO_TARGET_GUID (
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 99999999-9999-9999-9999-999999999999 >nul 2>&1
    if errorlevel 1 exit /b 1
    set "AIO_TARGET_GUID=99999999-9999-9999-9999-999999999999"
)
powercfg /setactive !AIO_TARGET_GUID! >nul 2>&1
if errorlevel 1 (
    set "AIO_TARGET_GUID="
    exit /b 1
)
set "AIO_TARGET_GUID="
exit /b 0

:DETECT_VC14_RUNTIME
set "VC2015X86=0"
set "VC2015X64=0"
REM Microsoft enregistre les runtimes v14 dans VC\Runtimes\{x86^|x64}.
REM /reg:32 vise le package x86 et /reg:64 le package x64 sur Windows 64 bits.
REM Attention : Installed=1 peut persister apres desinstallation si Visual Studio
REM avec composant C++ est installe (StackOverflow #67493523). On verifie donc aussi
REM la presence de la DLL principale comme filet de securite.
if defined ProgramFiles(x86) (
    reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" /v Installed /reg:32 2>nul | findstr /R /I "Installed.*REG_DWORD.*0x1" >nul
    if !errorlevel! EQU 0 if exist "%SystemRoot%\SysWOW64\vcruntime140.dll" set "VC2015X86=1"
    reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x64" /v Installed /reg:64 2>nul | findstr /R /I "Installed.*REG_DWORD.*0x1" >nul
    if !errorlevel! EQU 0 if exist "%SystemRoot%\System32\vcruntime140.dll" set "VC2015X64=1"
) else (
    reg query "HKLM\SOFTWARE\Microsoft\VisualStudio\14.0\VC\Runtimes\x86" /v Installed 2>nul | findstr /R /I "Installed.*REG_DWORD.*0x1" >nul
    if !errorlevel! EQU 0 if exist "%SystemRoot%\System32\vcruntime140.dll" set "VC2015X86=1"
    REM Aucun package x64 n'est attendu sur un Windows 32 bits.
    set "VC2015X64=1"
)
exit /b 0

:CREATE_STR_STARTUP_SHORTCUT
powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STR_STARTUP_LNK%'); $Shortcut.TargetPath = '%STR_EXE%'; $Shortcut.Arguments = '--resolution 5070 --no-console'; $Shortcut.WorkingDirectory = '%STR_DIR%'; $Shortcut.Description = 'SetTimerResolution - WindowsOptimizer'; $Shortcut.Save()" >nul 2>&1
exit /b

:RUN_EDGE_UNINSTALLER
pushd "%~1" >nul 2>&1
if !errorlevel! NEQ 0 exit /b 1
for /d %%i in (*) do (
    if exist "%%i\Installer\setup.exe" (
        set "EDGE_UNINSTALLER_FOUND=1"
        "%%i\Installer\setup.exe" --uninstall --system-level --force-uninstall >nul 2>&1
        if !errorlevel! NEQ 0 set "EDGE_UNINSTALLER_ERROR=1"
    )
)
popd >nul 2>&1
exit /b 0

:REMOVE_EDGE_TASKBAR_LINKS
powershell -NoProfile -Command "Get-ChildItem -Path ""$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk"" -ErrorAction SilentlyContinue | ForEach-Object { try { $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName); if ($sh.TargetPath -match 'msedge\.exe') { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue } } catch {} }" >nul 2>&1
exit /b

:SET_EXISTING_SERVICE_START
REM  %~1 = nom du service ; %~2 = valeur Start. Une cle absente est ignoree, jamais creee.
reg query "HKLM\SYSTEM\CurrentControlSet\Services\%~1" >nul 2>&1
if !errorlevel! NEQ 0 (
    set /a "SERVICE_CONFIG_SKIPPED+=1"
    exit /b 0
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\%~1" /v Start /t REG_DWORD /d %~2 /f >nul 2>&1
if !errorlevel! NEQ 0 (
    set "SERVICE_CONFIG_ERROR=1"
    exit /b 1
)
exit /b 0

REM  Parametres : %~1 = PROFIL_POWER (0=MaxPerf, 1=Eco).
REM               %~2 = PROFIL_USAGE (0=Gaming, 1=Normal).
REM  Gaming+MaxPerf (0,0) : RSC/LSO/InterruptModeration OFF, ITR 200, EEE/Wake OFF, buffers max.
REM  Normal+MaxPerf (0,1) : RSC/LSO ON, ITR defaut, EEE/Wake OFF, buffers max.
REM  Eco (1,*) : RSC/LSO/checksum ON, PowerManagement ON, economie pilote conservee.
REM  Toutes les modifications sont groupees avant un unique redemarrage de chaque carte.
REM  Source unique de verite pour la section 5.7 (optimisation) et 7.12 (restauration).
:SET_NIC_PROFILE
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue';$eco=('%~1'-eq'1');$gaming=('%~2'-eq'0');$script:failed=$false;$managed=@('*FlowControl','*GreenGbe','*RscIPv6','*PacketCoalescing','EnableExtraPowerSaving','*EEE','AdvancedEEE','EnableGreenEthernet','PowerSavingMode','GigaLite','ReduceSpeedOnPowerDown','*WakeOnMagicPacket','*WakeOnPattern','S5WakeOnLan','*ShutdownLinkSpeed','S3S4WolLinkSpeed','EnableDynamicPowerGating','AutoPowerSaveModeEnabled','EnableConnectedPowerGating','*NicAutoPowerSaver','TxIntDelay','MIMOPowerSaveMode','uAPSDSupport','FatChannelIntolerant','*ReceiveBuffers','*TransmitBuffers','PendingReceives','PendingTransmits','ITR','*InterruptModeration');function SetP($a,$kw,$vals,$cache){if(-not $cache.ContainsKey($kw)){return};$p=$cache[$kw];$ok=$false;foreach($v in $vals){$valid=@($p.ValidRegistryValues);if($null-ne$p.ValidRegistryValues-and $valid.Count-gt 0-and $valid-notcontains[string]$v){continue};try{Set-NetAdapterAdvancedProperty -Name $a -RegistryKeyword $kw -RegistryValue $v -AllProperties -NoRestart -ErrorAction Stop;$script:changed=$true;$ok=$true;break}catch{}};if(-not $ok){$script:failed=$true}};function ResetP($a,$kw,$cache){$p=$cache[$kw];if(-not $p){return};try{if($p.DisplayName){$p|Reset-NetAdapterAdvancedProperty -NoRestart -ErrorAction Stop}else{$d=@($p.DefaultRegistryValue);if($d.Count-eq 0-or $null-eq $d[0]){return};Set-NetAdapterAdvancedProperty -Name $a -RegistryKeyword $kw -RegistryValue $d -AllProperties -NoRestart -ErrorAction Stop};$script:changed=$true}catch{$script:failed=$true}};function SetF($get,$set,$n){$f=& $get -Name $n -ErrorAction SilentlyContinue;if($null-eq$f){return};try{& $set -Name $n -NoRestart -ErrorAction Stop;$script:changed=$true}catch{$script:failed=$true}};try{$adapters=@(Get-NetAdapter -Physical -ErrorAction Stop|Where-Object{$_.AdminStatus-eq'Up'})}catch{exit 1};foreach($adapter in $adapters){$script:changed=$false;$n=$adapter.Name;$props=@{};Get-NetAdapterAdvancedProperty -Name $n -AllProperties -ErrorAction SilentlyContinue|ForEach-Object{if($_.RegistryKeyword){$props[$_.RegistryKeyword]=$_}};$w=Get-CimInstance Win32_NetworkAdapter -ErrorAction SilentlyContinue|Where-Object{$_.Name-eq$adapter.InterfaceDescription}|Select-Object -First 1;$r=$null;if($w){$k='{0:0000}'-f[int]$w.DeviceID;$r='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\'+$k};if($eco){foreach($kw in $managed){ResetP $n $kw $props}}elseif(-not $gaming){foreach($kw in @('*RscIPv6','ITR','TxIntDelay','*InterruptModeration')){ResetP $n $kw $props}};if(($eco-or(-not $gaming))-and $r){Remove-ItemProperty -Path $r -Name 'ITR','TxIntDelay' -ErrorAction SilentlyContinue;$script:changed=$true};SetF 'Get-NetAdapterRss' 'Enable-NetAdapterRss' $n;if($eco-or(-not $gaming)){SetF 'Get-NetAdapterRsc' 'Enable-NetAdapterRsc' $n;SetF 'Get-NetAdapterLso' 'Enable-NetAdapterLso' $n}else{SetF 'Get-NetAdapterRsc' 'Disable-NetAdapterRsc' $n;SetF 'Get-NetAdapterLso' 'Disable-NetAdapterLso' $n};foreach($kw in @('*IPChecksumOffloadIPv4','*TCPChecksumOffloadIPv4','*TCPChecksumOffloadIPv6','*UDPChecksumOffloadIPv4','*UDPChecksumOffloadIPv6')){SetP $n $kw @('3') $props};if($eco){SetF 'Get-NetAdapterPowerManagement' 'Enable-NetAdapterPowerManagement' $n}else{SetF 'Get-NetAdapterPowerManagement' 'Disable-NetAdapterPowerManagement' $n;foreach($kw in @('*FlowControl','*GreenGbe','*PacketCoalescing','EnableExtraPowerSaving','*EEE','AdvancedEEE','EnableGreenEthernet','PowerSavingMode','GigaLite','ReduceSpeedOnPowerDown','*WakeOnMagicPacket','*WakeOnPattern','S5WakeOnLan','*ShutdownLinkSpeed','S3S4WolLinkSpeed','EnableDynamicPowerGating','AutoPowerSaveModeEnabled','EnableConnectedPowerGating','*NicAutoPowerSaver')){SetP $n $kw @('0') $props};if($gaming){SetP $n '*RscIPv6' @('0') $props;SetP $n '*InterruptModeration' @('0') $props;SetP $n 'TxIntDelay' @('0') $props;if($r){try{New-ItemProperty -Path $r -Name 'ITR' -PropertyType DWord -Value 200 -Force -ErrorAction Stop|Out-Null;New-ItemProperty -Path $r -Name 'TxIntDelay' -PropertyType DWord -Value 0 -Force -ErrorAction Stop|Out-Null;$script:changed=$true}catch{$script:failed=$true}}};if($adapter.InterfaceDescription-match'Intel|Wireless|Wi-Fi|802\.11'){SetP $n 'MIMOPowerSaveMode' @('3') $props;SetP $n 'uAPSDSupport' @('0') $props;SetP $n 'FatChannelIntolerant' @('0') $props};foreach($kw in @('*ReceiveBuffers','*TransmitBuffers')){$p=$props[$kw];if($p-and $p.NumericParameterMaxValue-gt 0){$v=[math]::Min([int]$p.NumericParameterMaxValue,2048).ToString();SetP $n $kw @($v) $props}};foreach($kw in @('PendingReceives','PendingTransmits')){$p=$props[$kw];if($p-and $p.NumericParameterMaxValue-gt 0){$v=[math]::Min([int]$p.NumericParameterMaxValue,64).ToString();SetP $n $kw @($v) $props}}};if($script:changed){try{Restart-NetAdapter -Name $n -Confirm:$false -ErrorAction Stop}catch{$script:failed=$true}}};if($script:failed){exit 1};exit 0" >nul 2>&1
exit /b !errorlevel!

REM  Parametre : %~1 = PROFIL_POWER (0=MaxPerf, 1=Eco).
REM  MaxPerf (0) : desactive la gestion d'energie USB (WMI "Autoriser l'arret",
REM    USB Selective Suspend, USB 3 LPM, DisableSelectiveSuspend).
REM  Eco (1) : restaure la gestion d'energie USB (annule les surcharges MaxPerf).
REM  Source unique pour les sections 5.8 (optimisation) et 7.3 (restauration).
:SET_USB_POWER
set "USB_ERR=0"
if "%~1"=="1" (
REM ECO: Restaurer la gestion d'energie USB (desactive les surcharges MaxPerf)
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $usb=(Get-PNPDevice -Class USB -ErrorAction SilentlyContinue).InstanceId; Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -Filter 'Enable=false' -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -replace '_0$' -in $usb } | Set-CimInstance -Property @{Enable = $true} -ErrorAction SilentlyContinue" >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 2 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 2 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
exit /b !USB_ERR!
)
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $usb=(Get-PNPDevice -Class USB -ErrorAction SilentlyContinue).InstanceId; Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -Filter 'Enable=true' -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -replace '_0$' -in $usb } | Set-CimInstance -Property @{Enable = $false} -ErrorAction SilentlyContinue" >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
powercfg /setactive SCHEME_CURRENT >nul 2>&1
if !errorlevel! NEQ 0 set "USB_ERR=1"
exit /b !USB_ERR!

:RUN_REMOTE_PS
set "REMOTE_PS_FILE=%TEMP%\WindowsOptimizer_remote_%RANDOM%_%RANDOM%.ps1"
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri '%~1' -OutFile $env:REMOTE_PS_FILE -UseBasicParsing -ErrorAction Stop; if((Get-Item -LiteralPath $env:REMOTE_PS_FILE).Length -lt 500){exit 2}; exit 0 } catch { exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    if exist "%REMOTE_PS_FILE%" del /f /q "%REMOTE_PS_FILE%" >nul 2>&1
    set "REMOTE_PS_FILE="
    exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -File "%REMOTE_PS_FILE%"
set "REMOTE_PS_RC=!errorlevel!"
del /f /q "%REMOTE_PS_FILE%" >nul 2>&1
set "REMOTE_PS_FILE="
if "!REMOTE_PS_RC!"=="0" (
    set "REMOTE_PS_RC="
    exit /b 0
)
set "REMOTE_PS_RC="
exit /b 1

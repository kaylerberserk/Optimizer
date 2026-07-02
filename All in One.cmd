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

:: Alias AZERTY non-ASCII pour la rangee numerique sans Shift : 2, 7, 9, 0.
set "AZ_TMP=%TEMP%\wo_az_%RANDOM%"
powershell -NoProfile -Command "$oem=(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Nls\CodePage').OEMCP; $enc=[Text.Encoding]::GetEncoding([int]$oem); $base=$env:AZ_TMP; $map=@{2=[char]233;7=[char]232;9=[char]231;0=[char]224}; foreach($k in $map.Keys){ [IO.File]::WriteAllBytes($base+'_'+$k+'.tmp',$enc.GetBytes([string]$map[$k])) }" >nul 2>&1
if exist "%AZ_TMP%_2.tmp" set /p "AZ_KEY_2="<"%AZ_TMP%_2.tmp"
if exist "%AZ_TMP%_7.tmp" set /p "AZ_KEY_7="<"%AZ_TMP%_7.tmp"
if exist "%AZ_TMP%_9.tmp" set /p "AZ_KEY_9="<"%AZ_TMP%_9.tmp"
if exist "%AZ_TMP%_0.tmp" set /p "AZ_KEY_0="<"%AZ_TMP%_0.tmp"
del "%AZ_TMP%_*.tmp" >nul 2>&1
set "AZ_TMP="

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
:: [*]        JAUNE = Avertissement (attention requise)
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
:: Verification robuste des privileges admin (net session + verification UAC)
net session >nul 2>&1
if !errorlevel! NEQ 0 (
    echo.
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Ce script necessite des privileges administrateur.%COLOR_RESET%
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Clic droit sur le script -^> Executer en tant qu'administrateur%COLOR_RESET%
    pause
    exit /B 1
)
:: Verification supplementaire : verifier que le processus est vraiment eleve (UAC)
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
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $o=Get-CimInstance Win32_OperatingSystem; $c=Get-CimInstance Win32_Processor; $v=Get-CimInstance Win32_VideoController; $m=Get-CimInstance Win32_PhysicalMemory; if(-not $m){$m=Get-CimInstance Win32_ComputerSystem}; $b=0; $lc=8,9,10,11,14,30,31,32; $enc=Get-CimInstance Win32_SystemEnclosure -EA SilentlyContinue; if($enc -and $enc.ChassisTypes){foreach($t in $enc.ChassisTypes){if($lc -contains $t){$b=1;break}}}; if(-not $b -and (Get-CimInstance Win32_Battery -EA SilentlyContinue)){$b=1}; $res=@(); $cap=$o.Caption; if(-not $cap){$pn=(Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion').ProductName; if($pn){$cap=$pn}else{$cap='Windows'}}; $res+='OS:'+$cap+' ('+$o.Version+')'; if($c){$res+='CPU:'+$c.Name.Trim()}; if($v){$gn=@($v|Where-Object{$_.Name -and $_.Name -notmatch 'Parsec|Virtual Display|Microsoft Basic|Remote|Indirect|Mirror'}|ForEach-Object{$_.Name.Trim()}|Select-Object -Unique); if(-not $gn.Count){$gn=@($v|ForEach-Object{$_.Name.Trim()})}; $res+='GPU:'+($gn -join ' / ')}; if($m.Capacity){$t=($m|Measure-Object Capacity -Sum).Sum; $res+='RAM:'+[math]::Round($t/1GB,0)}elseif($m.TotalPhysicalMemory){$res+='RAM:'+[math]::Round($m.TotalPhysicalMemory/1GB,0)}; $res+='LAPTOP:'+$b; [System.IO.File]::WriteAllLines((Join-Path $env:TEMP 'hw_info.tmp'), $res)" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo [*] %COLOR_YELLOW%Erreur lors de la detection du materiel. Valeurs par defaut utilisees.%COLOR_RESET%
)
if exist "%TEMP%\hw_info.tmp" (
    for /f "usebackq tokens=1* delims=:" %%a in ("%TEMP%\hw_info.tmp") do (
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
    del "%TEMP%\hw_info.tmp" >nul 2>&1
)
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
exit /b

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
if "!SKIP_PAUSE!"=="1" exit /b 0
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous redemarrer maintenant ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 exit /b 0
if !errorlevel! EQU 1 (
    shutdown /r /t 10 /c "Redemarrage demande par WindowsOptimizer"
    cls
    echo.
    echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Redemarrage programme dans 10 secondes...%COLOR_RESET%
    timeout /t 5 /nobreak >nul
    exit
)
echo.
exit /b 0

:: Confirmation O/N - %~1 = message, retourne 0 pour Oui, 1 pour Non
:ASK_CONFIRM
<nul set /p ="%~1"
call :AZCHOICE ON
if !errorlevel! NEQ 1 exit /b 1
exit /b 0

:: %~1 = label (ignore, conserve pour compatibilite appelants)  %~2 = message
:ASK_IF_INTERACTIVE
if not "%SKIP_PAUSE%"=="0" exit /b 0
call :ASK_CONFIRM "%~2"
:: Retourne 0 pour Oui, 1 pour Non. Les appelants gerent le routage.
if !errorlevel! EQU 1 exit /b 1
exit /b 0

:: %~1 = message  %~2 = variable flag (ex: DESACTIVER_SECURITE) - positionne a 1 si Oui, 0 si Non
:COMMON_YES_NO
set "%~2=0"
<nul set /p ="%~1"
call :AZCHOICE ONM
if !errorlevel! EQU 3 (
    cls
    exit /b 2
)
if !errorlevel! EQU 1 set "%~2=1"
exit /b 0

:: Lecture d'une entree menu. Retourne la position via errorlevel.
:: Accepte les minuscules et la rangee numerique AZERTY sans Shift : & e " ' ( - e _ c a.
:AZCHOICE
set "AZ_KEYS=%~1"
set "AZ_INPUT="
set /p "AZ_INPUT="
if not defined AZ_INPUT goto :AZCHOICE
set "AZ_INPUT=!AZ_INPUT:~0,1!"

if !AZ_INPUT!==^" set "AZ_INPUT=3"
if "!AZ_INPUT!"=="&" set "AZ_INPUT=1"
if "!AZ_INPUT!"=="!AZ_KEY_2!" set "AZ_INPUT=2"
if "!AZ_INPUT!"=="'" set "AZ_INPUT=4"
if "!AZ_INPUT!"=="(" set "AZ_INPUT=5"
if "!AZ_INPUT!"=="-" set "AZ_INPUT=6"
if "!AZ_INPUT!"=="!AZ_KEY_7!" set "AZ_INPUT=7"
if "!AZ_INPUT!"=="_" set "AZ_INPUT=8"
if "!AZ_INPUT!"=="!AZ_KEY_9!" set "AZ_INPUT=9"
if "!AZ_INPUT!"=="!AZ_KEY_0!" set "AZ_INPUT=0"

set "AZ_ERRORLEVEL=0"
for /l %%I in (0,1,31) do (
    set "AZ_KEY=!AZ_KEYS:~%%I,1!"
    if defined AZ_KEY if /i "!AZ_INPUT!"=="!AZ_KEY!" set /a "AZ_ERRORLEVEL=%%I+1"
)
if !AZ_ERRORLEVEL! GTR 0 exit /b !AZ_ERRORLEVEL!
goto :AZCHOICE

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
echo %COLOR_YELLOW%[8]%COLOR_RESET% %COLOR_RED%Gerer Protections Securite - Desactiver ou Restaurer%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OPTIMISATIONS ALL IN ONE ---%COLOR_RESET%
echo %COLOR_YELLOW%[O]%COLOR_RESET% %COLOR_WHITE%Tout optimiser %COLOR_GREEN%- repondez aux questions, le script gere le reste%COLOR_RESET%
echo.
echo %STYLE_BOLD%%COLOR_BLUE%--- OUTILS ---%COLOR_RESET%
echo %COLOR_YELLOW%[N]%COLOR_RESET% %COLOR_CYAN%Nettoyage Avance de Windows%COLOR_RESET%
echo %COLOR_YELLOW%[R]%COLOR_RESET% %COLOR_CYAN%Creer un Point de Restauration%COLOR_RESET%
echo %COLOR_YELLOW%[G]%COLOR_RESET% %COLOR_MAGENTA%Gestion Windows (Defender, UAC, Edge, OneDrive...)%COLOR_RESET%
echo %COLOR_YELLOW%[W]%COLOR_RESET% %COLOR_MAGENTA%Activation Windows / Office (script MAS)%COLOR_RESET%
echo %COLOR_YELLOW%[T]%COLOR_RESET% %COLOR_MAGENTA%Tweaks communautaires (Chris Titus WinUtil)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[Q]%COLOR_RESET% %STYLE_BOLD%%COLOR_RED%Quitter le script%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Veuillez choisir une option [1-8, O, N, R, G, W, T, Q]: %COLOR_RESET%"
call :AZCHOICE 12345678ONRGWTQ

:: Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 15 goto :END_SCRIPT
if !errorlevel! EQU 14 goto :OUTIL_CHRIS_TITUS
if !errorlevel! EQU 13 goto :OUTIL_ACTIVATION
if !errorlevel! EQU 12 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 11 goto :CREER_POINT_RESTAURATION
if !errorlevel! EQU 10 goto :NETTOYAGE_AVANCE_WINDOWS
if !errorlevel! EQU 9  goto :TOUT_OPTIMISER
if !errorlevel! EQU 8  goto :TOGGLE_PROTECTIONS_SECURITE
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
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-9, M]: %COLOR_RESET%"
call :AZCHOICE 123456789M
:: Gestion des choix (EQU = egalite stricte, ordre sans importance)
if !errorlevel! EQU 10 goto :MENU_PRINCIPAL
if !errorlevel! EQU 9  goto :SUPPRIMER_BLOATWARES
if !errorlevel! EQU 8  goto :DO_INSTALLER_VISUAL_REDIST
if !errorlevel! EQU 7  goto :DESINSTALLER_EDGE
if !errorlevel! EQU 6  goto :DESINSTALLER_ONEDRIVE
if !errorlevel! EQU 5  goto :MENU_IA_WIDGETS_RECALL
if !errorlevel! EQU 4  goto :TOGGLE_ANIMATIONS
if !errorlevel! EQU 3  goto :TOGGLE_VBS_HVCI
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
echo %COLOR_WHITE%Voulez-vous desactiver les protections de securite (Spectre/Meltdown) ?%COLOR_RESET%
echo %COLOR_WHITE%    (Note : les protections noyau VBS/HVCI et CFG restent actives pour les jeux avec anti-triche)%COLOR_RESET%
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
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces protections ? [O/N/M]: %COLOR_RESET%" DESACTIVER_SECURITE
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL

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
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver Windows Defender ? [O/N/M]: %COLOR_RESET%" DESACTIVER_DEFENDER
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
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les animations (recommande)
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
echo %COLOR_WHITE%Pourquoi cette question : Copilot, widgets, Recall consomment CPU/reseau et%COLOR_RESET%
echo %COLOR_WHITE%envoient des donnees vers Microsoft ; couper tout ameliore confidentialite et perf.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Desactive Copilot, Recall, widgets et autres fonctionnalites IA
echo       %COLOR_YELLOW%Ameliore les performances et la confidentialite%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver les fonctionnalites IA
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
echo %COLOR_WHITE%Pourquoi cette question : sans UAC, les programmes peuvent obtenir des droits admin%COLOR_RESET%
echo %COLOR_WHITE%sans votre accord explicite ; ce script desactive aussi la fenetre de confirmation admin.%COLOR_RESET%
echo.
echo %COLOR_GREEN%[O] OUI%COLOR_RESET% - Ne plus demander de confirmation (Oui/Non) pour les actions admin
echo       %COLOR_YELLOW%Reduit la securite en permettant aux applis de s'executer sans alerte%COLOR_RESET%
echo.
echo %COLOR_CYAN%[N] NON%COLOR_RESET% - Conserver l'UAC (recommande)
echo.
echo %COLOR_YELLOW%[M] RETOUR%COLOR_RESET% - Retour au menu principal
echo.
call :COMMON_YES_NO "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC ? [O/N/M]: %COLOR_RESET%" DESACTIVER_UAC
if !errorlevel! EQU 2 goto :MENU_PRINCIPAL



cls
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Mode automatique : vos reponses ci-dessus s'appliquent sans nouvelle confirmation.%COLOR_RESET%
echo.
set "SKIP_PAUSE=1"
echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%TOUT_OPTIMISER execute : %COLOR_RED%Defender, SmartScreen/UAC, securite noyau (VBS/HVCI), animations, IA%COLOR_RESET% et optimisations systeme.%COLOR_RESET%
echo %COLOR_WHITE%  Utilisez TOUT RESTAURER (menu Gestion Windows) pour annuler.%COLOR_RESET%
echo.
call :INSTALLER_VISUAL_REDIST
call :OPTIMISATIONS_SYSTEME
call :OPTIMISATIONS_MEMOIRE
call :OPTIMISATIONS_DISQUES
call :OPTIMISATIONS_GPU
call :OPTIMISATIONS_RESEAU
call :OPTIMISATIONS_PERIPHERIQUES
if "!PROFIL_POWER!"=="0" call :DESACTIVER_ECONOMIES_ENERGIE
if "!DESACTIVER_SECURITE!"=="1" call :DESACTIVER_PROTECTIONS_SECURITE
if "!DESACTIVER_DEFENDER!"=="1" call :DESACTIVER_DEFENDER_SECTION
if "!DESACTIVER_ANIMATIONS!"=="1" call :DESACTIVER_ANIMATIONS_SECTION
if "!DESACTIVER_IA!"=="1" call :DESACTIVER_TOUT_IA_WIDGETS_RECALL
if "!DESACTIVER_UAC!"=="1" call :DESACTIVER_UAC_SECTION
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme, memoire, disques, GPU, reseau, peripheriques.%COLOR_RESET%
if "!PROFIL_POWER!"=="0" (
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
call :PROMPT_MANUAL_REBOOT
exit /b

:OPTIMISATIONS_SYSTEME
cls
call :INIT_PROFILS
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

:: 1.1 - Priorites CPU et planification
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration des priorites CPU...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\csrss.exe\PerfOptions" /v IoPriority /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEng.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\MsMpEngCP.exe\PerfOptions" /v CpuPriorityClass /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\PriorityControl" /v "Win32PrioritySeparation" /t REG_DWORD /d 38 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Planification CPU configuree%COLOR_RESET%

:: 1.2 - Profil Gaming MMCSS SystemProfile\Tasks\Games
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du profil gaming (MMCSS)...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Scheduling Category" /t REG_SZ /d "High" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "Priority" /t REG_DWORD /d 2 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "GPU Priority" /t REG_DWORD /d 8 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" /v "SFIO Priority" /t REG_SZ /d "High" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil gaming (MMCSS) configure%COLOR_RESET%

:: 1.3 - Interface Windows
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

:: 1.4 - Telemetrie et vie privee
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la telemetrie et des publicites...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitInkCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization" /v "RestrictImplicitTextCollection" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\InputPersonalization\TrainedDataStore" /v HarvestContacts /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Personalization\Settings" /v AcceptedPrivacyPolicy /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Input\Settings" /v InsightsEnabled /t REG_DWORD /d 0 /f >nul 2>&1

:: Optimiser le cache d'icones et miniatures
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "Max Cached Icons" /t REG_DWORD /d 8192 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v DisableThumbsDBOnNetworkFolders /t REG_DWORD /d 1 /f >nul 2>&1

:: Desactiver la compression des papiers peints
reg add "HKCU\Control Panel\Desktop" /v JPEGImportQuality /t REG_DWORD /d 100 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Interface et privacy de base optimisees%COLOR_RESET%

:: 1.5 - Telemetrie systeme et vie privee approfondie
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
REM PeriodInNanoSeconds laisse intact : aucune suppression hors section restauration.
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\Windows Error Reporting" /v "Disabled" /t REG_DWORD /d 1 /f >nul 2>&1
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

:: Backup du fichier hosts avant modification
copy "%HOSTS%" "%HOSTS%.bak" >nul 2>&1
:: Utilisation de PowerShell pour mettre a jour ou ajouter le bloc securise (Telemetrie uniquement)
powershell -NoProfile -Command "$h='%HOSTS%';$tmp=$h+'.tmp';$crlf=[char]13+[char]10;$s='# Telemetry Block Start';$e='# Telemetry Block End';$domains='vortex.data.microsoft.com','vortex-win.data.microsoft.com','v10.vortex-win.data.microsoft.com','v10.events.data.microsoft.com','telecommand.telemetry.microsoft.com','oca.telemetry.microsoft.com','watson.telemetry.microsoft.com','watsonc.microsoft.com','settings.data.microsoft.com','settings-win.data.microsoft.com','mobile.events.data.microsoft.com','browser.events.data.microsoft.com','self.events.data.microsoft.com','v20.events.data.microsoft.com','telemetry.microsoft.com','telemetrycollector.microsoft.com','pipe.aria.microsoft.com','diagnostics.office.com','activity.windows.com','modern.watson.data.microsoft.com','applicationinsights.microsoft.com','azurewatson.microsoft.com';$nb=$crlf+$s+$crlf;foreach($d in $domains){$nb+='0.0.0.0 '+$d+$crlf};$nb+=$e+$crlf;try{if(Test-Path $h){$cur=[System.IO.File]::ReadAllText($h,[System.Text.Encoding]::ASCII);$cur=$cur -replace ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)),'';foreach($d in $domains){$cur=$cur -replace ('(?m)^0\.0\.0\.0\s+'+[regex]::Escape($d)+'\s*$'),''};$cur=$cur.TrimEnd()+$nb;(Get-Item $h).Attributes='Normal';[System.IO.File]::WriteAllText($tmp,$cur,[System.Text.Encoding]::ASCII);Move-Item -Path $tmp -Destination $h -Force};exit 0}catch{Remove-Item -Path $tmp -Force -ErrorAction SilentlyContinue;exit 1}"

if !errorlevel! EQU 0 (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Domaines telemetrie bloques ^(bloc unique, adaptatif^)%COLOR_RESET%
) else (
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de la mise a jour du fichier hosts%COLOR_RESET%
)
attrib +r "%HOSTS%" >nul 2>&1
ipconfig /flushdns >nul 2>&1
set "HOSTS="

:: 1.6 - Services optimises
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
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
)
:: CDPUserSvc est un service par utilisateur
reg add "HKLM\SYSTEM\CurrentControlSet\Services\CDPUserSvc" /v Start /t REG_DWORD /d 3 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services utiles et occasionnels en mode Manuel%COLOR_RESET%

:: 3 - Services inutiles et telemetrie -> DESACTIVES
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
  reg add "HKLM\SYSTEM\CurrentControlSet\Services\%%S" /v Start /t REG_DWORD /d 4 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services telemetrie et legacy desactives%COLOR_RESET%

:: Services critiques laisses intacts : Bluetooth, Hello, RDP, Spooler, PlugPlay
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Services optimises (Bluetooth/VPN/Hello/RDP preserves)%COLOR_RESET%

:: 1.7 - Optimisations demarrage et systeme
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations systeme diverses...%COLOR_RESET%
:: Supprimer le delai de demarrage des applications
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "StartupDelayInMSec" /t REG_DWORD /d 0 /f >nul 2>&1
:: Desactiver l'attente etat idle avant lancement apps au login (reduit le delai sur Win10/11)
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Serialize" /v "WaitForIdleState" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableInventory" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "DisableUAR" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\AppCompat" /v "AITEnable" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Configuration Manager" /v EnablePeriodicBackup /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v DisableStartupAnimation /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "01" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "04" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "08" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "32" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" /v "2048" /t REG_DWORD /d 7 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisations demarrage et stockage terminees%COLOR_RESET%

:: 1.8 - Utilitaires et Bloatwares (Automatique)
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

:: 1.9 - Navigateurs
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation navigateurs...%COLOR_RESET%
:: Microsoft Edge
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

:: Google Chrome
reg add "HKCU\Software\Policies\Google\Chrome" /v QuicAllowed /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsMode /t REG_SZ /d secure /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v DnsOverHttpsTemplates /t REG_SZ /d "https://cloudflare-dns.com/dns-query" /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v HardwareAccelerationModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKCU\Software\Policies\Google\Chrome" /v BackgroundModeEnabled /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Navigateurs optimises%COLOR_RESET%

:: 1.10 - Desactivation du stockage reserve
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du stockage reserve Windows...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v PassedPolicy /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "try { Set-WindowsReservedStorageState -State Disabled -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Stockage reserve desactive ^(~7Go recuperes apres redemarrage^)%COLOR_RESET%

:: 1.11 - Desactivation P2P Windows Update (Delivery Optimization)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du P2P Windows Update...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" /v DODownloadMode /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%P2P Windows Update desactive (maj depuis Microsoft uniquement)%COLOR_RESET%

:: 1.12 - Blocage des pubs Store dans la recherche
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Blocage des recommandations Store dans la recherche...%COLOR_RESET%
icacls "%LocalAppData%\Packages\Microsoft.WindowsStore_8wekyb3d8bbwe\LocalState\store.db" /deny Everyone:F >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Pubs Store bloquees dans la recherche%COLOR_RESET%

:: 1.13 - Affichage du code erreur BSoD
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de l'affichage des codes erreur BSoD...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CrashControl" /v DisplayParameters /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Codes erreur BSoD visibles (diagnostic facilite)%COLOR_RESET%

:: 1.14 - Desactivation de l'aide F1
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la touche F1 (aide Windows)...%COLOR_RESET%
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win64" /ve /t REG_SZ /d "" /f >nul 2>&1
reg add "HKCR\Typelib\{8cec5860-07a1-11d9-b15e-000d56bfe6ee}\1.0\0\win32" /ve /t REG_SZ /d "" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Touche F1 (aide) desactivee%COLOR_RESET%

:: 1.15 - Optimisations audio (latence)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des ameliorations audio...%COLOR_RESET%
powershell -NoProfile -Command "$path = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e96c-e325-11ce-bfc1-08002be10318}'; Get-ChildItem -Path $path -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p = $_.PSPath; New-ItemProperty -Path $p -Name 'FxNonDestructiveSoftMixer' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'FxRender' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'DisableAudioEndpointDucking' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } " >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Optimisation des peripheriques de rendu audio (PowerShell)%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Audio" /v ImmersiveAudio /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Ameliorations audio desactivees - Latence reduite%COLOR_RESET%

:: 1.16 - Desactivation Windows Platform Binary Table (WPBT)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation WPBT (anti bloatware OEM firmware)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v DisableWpbtExecution /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%WPBT desactive%COLOR_RESET%

:: 1.17 - Intel Thread Director / Core Parking (profil-aware)
:: SCHEDPOLICY : 0=Tous, 1=Performants, 2=Preferer performants, 3=Efficients, 4=Preferer efficients, 5=Auto.
:: Ne fait rien sur CPU non-hybride (AMD, Intel avant 12th gen).
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

:: 1.17 - DisablePagefileEncryption (Gaming uniquement : reduit latence I/O, incompatible BitLocker)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du chiffrement du fichier d'echange ^(Gaming^)...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "DisablePagefileEncryption" /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DisablePagefileEncryption=1 ^(Gaming, BitLocker incompatible^)%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%DisablePagefileEncryption conserve au defaut ^(Normal : BitLocker compatible^)%COLOR_RESET%
)

call :FINISH_ACTION "Optimisations systeme" "appliquees"
exit /b

:OPTIMISATIONS_MEMOIRE
cls
call :INIT_PROFILS
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
    echo %COLOR_WHITE%  Energie active : %STYLE_BOLD%ECO%COLOR_RESET%%COLOR_WHITE% - compression memoire conservee ^(autonomie^)%COLOR_RESET%
)
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.

:: 2.1 - Memory Management
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
REM Etat FTH laisse intact : aucune suppression hors section restauration.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%FTH desactive - Performances memoire ameliorees%COLOR_RESET%

:: 2.4 - Compression memoire MMAgent - conditionnelle selon la RAM
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Analyse de la memoire physique...%COLOR_RESET%
set "RAM_GB=0"
for /f %%A in ('powershell -NoProfile -Command "[math]::Floor((Get-CimInstance Win32_OperatingSystem).TotalVisibleMemorySize / 1MB)"') do if not "%%A"=="" set "RAM_GB=%%A"
echo %COLOR_WHITE%   RAM detectee : !RAM_GB! Go%COLOR_RESET%
if "!PROFIL_POWER!"=="1" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil ECO : compression memoire conservee [autonomie]%COLOR_RESET%
) else (
    if !RAM_GB! GTR 8 (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%RAM superieure a 8 Go - MAX PERF : desactivation de la compression memoire [charge CPU reduite]...%COLOR_RESET%
        powershell -NoProfile -Command "try { Disable-MMAgent -MemoryCompression -ErrorAction Stop } catch { exit 0 }" >nul 2>&1
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Compression memoire desactivee%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%RAM de 8 Go ou moins : compression memoire conservee%COLOR_RESET%
    )
)

call :FINISH_ACTION "Optimisations memoire" "appliquees"
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

:: 3.4 - Native NVMe FeatureManagement (nvmedisk.sys)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du pilote NVMe natif (nvmedisk.sys)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1176759950 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 1853569164 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 156965516 /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Policies\Microsoft\FeatureManagement\Overrides" /v 735209102 /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Native NVMe actif - IOPS potentiels plus eleves%COLOR_RESET%

:: 3.5 - IoRing + Storport Queue
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation IoRing + Storport tweaks...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\storport\Parameters" /v "IoRingEnabled" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters" /v "MaxOutstandingIORequests" /t REG_DWORD /d 256 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%IoRing + Storport optimise%COLOR_RESET%

:: 3.6 - Defragmentation automatique geree par Windows (TRIM automatique)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification de la defragmentation automatique...%COLOR_RESET%
:: Windows 11 detecte automatiquement les SSD et effectue du TRIM au lieu de defragmentation
:: Il est important de NE PAS desactiver cette tache pour maintenir le TRIM automatique
schtasks /Change /TN "Microsoft\Windows\Defrag\ScheduledDefrag" /Enable >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Defragmentation automatique preservee ^(TRIM automatique actif pour SSD^)%COLOR_RESET%

call :FINISH_ACTION "Optimisations disques" "appliquees"
exit /b

:OPTIMISATIONS_GPU
cls
call :INIT_PROFILS
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

:: 4.2 - Preferences DirectX (Auto HDR, VRR ON, Flip Model actif)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application des preferences DirectX ^(Auto HDR, VRR ON, Flip Model^)...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\DirectX\UserGpuPreferences" /v "DirectXUserGlobalSettings" /t REG_SZ /d "AutoHDREnable=1;VRROptimizeEnable=1;SwapEffectUpgradeEnable=1;" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DirectX : Auto HDR actif, VRR ON, Flip Model actif%COLOR_RESET%

:: 4.3 - Mode MSI (GPU) et telemetrie NVIDIA
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation MSI (GPU) et desactivation telemetrie NVIDIA...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class Display -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ New-ItemProperty -Path $p -Name 'MSISupported' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
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
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v MaxFrameLatency /t REG_DWORD /d 1 /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  if "!PROFIL_USAGE!"=="0" (
    reg add "%%K" /v LOWLATENCY /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v Node3DLowLatency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v D3PCLatency /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "%%K" /v F1TransitionLatency /t REG_DWORD /d 1 /f >nul 2>&1
  )
)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Low Latency active - Reduction de l'input lag ^(Gaming^)%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Low Latency ignore - Veille GPU preservee ^(Normal^)%COLOR_RESET%
)

:: 4.6 - HAGS Enable
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la planification GPU acceleree (HAGS)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v HwSchMode /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%HAGS active - Latence GPU reduite%COLOR_RESET%

:: 4.7 - Preemption GPU
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la preemption GPU...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers\Scheduler" /v EnablePreemption /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Preemption GPU activee%COLOR_RESET%

:: 4.8 - NVIDIA Profile Inspector
:: Cette section applique un profil d'optimisation NVIDIA pour reduire l'input lag.
if "!HAS_NVIDIA!"=="1" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%GPU NVIDIA detecte - Configuration NVIDIA Profile Inspector...%COLOR_RESET%
        
        REM Utilisation de Windows\Temp car le %%TEMP%% utilisateur peut etre sur un RamDisk ou lecteur non mappe en Admin
        set "NPI_DIR=%SystemDrive%\Windows\Temp\NPI_Temp"
        set "NPI_EXE_SRC=%~dp0Tools\NVIDIA Inspector\nvidiaProfileInspector.exe"
        set "NPI_PROFILE_SRC=%~dp0Tools\NVIDIA Inspector\Kaylers_profile.nip"
        if not exist "!NPI_DIR!" mkdir "!NPI_DIR!" >nul 2>&1
        
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Preparation de NVIDIA Profile Inspector et du profil...%COLOR_RESET%
        REM Priorite aux fichiers locaux livres avec le script, telechargement GitHub en secours.
        if exist "!NPI_EXE_SRC!" copy /Y "!NPI_EXE_SRC!" "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
        if exist "!NPI_PROFILE_SRC!" copy /Y "!NPI_PROFILE_SRC!" "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
        if not exist "!NPI_DIR!\nvidiaProfileInspector.exe" curl -sL "https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/NVIDIA%%20Inspector/nvidiaProfileInspector.exe" -o "!NPI_DIR!\nvidiaProfileInspector.exe" >nul 2>&1
        if not exist "!NPI_DIR!\Kaylers_profile.nip" curl -sL "https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/NVIDIA%%20Inspector/Kaylers_profile.nip" -o "!NPI_DIR!\Kaylers_profile.nip" >nul 2>&1
        
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

        if "!NPI_VALID!"=="1" (
            echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application du profil NVIDIA optimise...%COLOR_RESET%
            start "" "!NPI_DIR!\nvidiaProfileInspector.exe" "!NPI_DIR!\Kaylers_profile.nip"
            ping -n 3 127.0.0.1 >nul 2>&1
            taskkill /f /im nvidiaProfileInspector.exe >nul 2>&1
            echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA Profile Inspector applique avec succes%COLOR_RESET%
        ) else (
            echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec du telechargement ou fichiers corrompus.%COLOR_RESET%
        )
        
        REM Nettoyage
        del /f /q "!NPI_DIR!\*.*" >nul 2>&1
        rmdir "!NPI_DIR!" >nul 2>&1
        set "NPI_EXE_SRC="
        set "NPI_PROFILE_SRC="
    ) else (
        echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Profil NVIDIA global ignore en profil NORMAL pour preserver autonomie, chauffe et silence%COLOR_RESET%
    )
) else (
    echo [*] GPU NVIDIA non detecte - NVIDIA Profile Inspector ignore
)

call :FINISH_ACTION "Optimisations GPU" "terminees"
exit /b

:OPTIMISATIONS_RESEAU
cls
call :INIT_PROFILS
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 5 : OPTIMISATIONS RESEAU ET INTERNET%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section optimise la pile TCP/IP et la carte reseau.%COLOR_RESET%
echo %COLOR_WHITE%  Profil GAMING = ping/reactivite max ; profil NORMAL = stabilite et debit preserves.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

if "%SKIP_PAUSE%"=="0" if "!DETECTE_PORTABLE!"=="1" (
    echo [*] %COLOR_YELLOW%PC PORTABLE DETECTE - MODE MANUEL%COLOR_RESET%
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
    echo %COLOR_YELLOW%  [*]%COLOR_RESET% %COLOR_WHITE%GAMING + ECO : Nagle neutre ^(batterie^), initialrto/maxsyn agressifs conserves ^(latence^).%COLOR_RESET%
    echo %COLOR_WHITE%     Latence GPU/input conservee, debit/stabilite mobile favorises.%COLOR_RESET%
)
echo.

:: 5.1 - MMCSS reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration MMCSS reseau...%COLOR_RESET%
:: SystemResponsiveness : Gaming = 10 (10% CPU aux taches faible priorite). Normal = 20 (defaut Windows).
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 10 /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v SystemResponsiveness /t REG_DWORD /d 20 /f >nul 2>&1
)
reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 10 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%MMCSS reseau configure%COLOR_RESET%

:: 5.2 - Pile TCP/IP Win11
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Pile TCP/IP Win11 ^(BBR2, fix loopback localhost^)...%COLOR_RESET%
netsh int tcp set global autotuninglevel=normal >nul 2>&1
REM Conserve : "set heuristics" pilote encore forcews sur certaines builds/drivers.
netsh int tcp set heuristics disabled >nul 2>&1
netsh int ipv4 set global loopbacklargemtu=disabled >nul 2>&1
netsh int ipv6 set global loopbacklargemtu=disabled >nul 2>&1
REM minRto n'est pas un parametre 'set global' valide (uniquement 'set supplemental') et 300ms est deja le plancher par defaut : ligne retiree (no-op).

if "!PROFIL_USAGE!"=="0" (
    netsh int tcp set global rss=enabled initialrto=1000 nonsackrttresiliency=disabled maxsynretransmissions=2 >nul 2>&1
) else (
    netsh int tcp set global rss=enabled >nul 2>&1
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

:: BBR2 applique sur les templates valides listes par "netsh int tcp set supplemental ?".
netsh int tcp set supplemental template=automatic congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=internet congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=datacenter congestionprovider=bbr2 >nul 2>&1
netsh int tcp set supplemental template=compat congestionprovider=bbr2 >nul 2>&1
REM template=custom n'existe pas sur Windows (pas de template custom valide) : supprime
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%BBR2 actif ^(templates valides : Automatic, Internet, Datacenter, Compat^)%COLOR_RESET%

:: TCP Pacing + ECN : essentiels pour BBR2 (pacing = parametre principal de BBR, ECN = signaux precoces congestion)
netsh int tcp set global pacingprofile=always >nul 2>&1
netsh int tcp set global ecncapability=enabled >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%TCP Pacing (always) + ECN Capability actives pour BBR2%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%loopbacklargemtu reste desactive pour eviter les bugs locaux%COLOR_RESET%

:: 5.3 - Parametres TCP registre
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Parametres TCP registre...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f >nul 2>&1
if "!PROFIL_USAGE!"=="0" (
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f >nul 2>&1
    REM LanmanServer Size=1 = defaut Win11 client Minimize Memory, pas de suppression hors section restauration.
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastSendDatagramThreshold /t REG_DWORD /d 1500 /f >nul 2>&1
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 3 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v SackOpts /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUDiscovery /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpMaxDataRetransmissions /t REG_DWORD /d 5 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Registre TCP configure%COLOR_RESET%
:: 5.4 - DefaultTTL
reg add "HKLM\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%DefaultTTL defini a 64%COLOR_RESET%
:: 5.5 - MSI Mode cartes reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation MSI Mode cartes reseau...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class Net -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ New-ItemProperty -Path $p -Name 'MSISupported' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%MSI Mode active sur cartes reseau%COLOR_RESET%


:: 5.6 - Optimisation BITS
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation du service BITS...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\BITS" /v "EnableBypassProxyForLocal" /t REG_DWORD /d 1 /f >nul 2>&1
:: Pas de suppression ici : les cles invalides/anciennes sont laissees a une section restauration/nettoyage.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%BITS optimise ^(aucune suppression hors restauration^)%COLOR_RESET%

:: 5.8 - Nagle/DelACK (ECO->neutre, Gaming+MaxPerf->agressif, Normal->skip)
if "!PROFIL_POWER!"=="1" (
    echo %COLOR_CYAN%[ECO]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK : valeurs neutres pour autonomie Wi-Fi ^(TcpNoDelay=0, TcpAckFrequency=2^)%COLOR_RESET%
    powershell -NoLogo -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress } ; if($ip){ New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value 2 -Force | Out-Null; New-ItemProperty -Path $p -Name TCPNoDelay -PropertyType DWord -Value 0 -Force | Out-Null; New-ItemProperty -Path $p -Name TcpDelAckTicks -PropertyType DWord -Value 1 -Force | Out-Null } }" >nul 2>&1
) else if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation Nagle et DelACK agressif ^(Gaming+MaxPerf^)...%COLOR_RESET%
    powershell -NoLogo -NoProfile -Command "Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object { $p=$_.PSPath; $ip=(Get-ItemProperty $p -Name DhcpIPAddress -EA SilentlyContinue).DhcpIPAddress; if(-not $ip){ $ip=(Get-ItemProperty $p -Name IPAddress -EA SilentlyContinue).IPAddress } ; if($ip){ New-ItemProperty -Path $p -Name TcpAckFrequency -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name TCPNoDelay -PropertyType DWord -Value 1 -Force | Out-Null; New-ItemProperty -Path $p -Name TcpDelAckTicks -PropertyType DWord -Value 0 -Force | Out-Null } }" >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK optimises%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Nagle/DelACK ignore en profil NORMAL ^(aucune restauration/suppression^)%COLOR_RESET%
)

:: 5.10 - Optimisation cartes reseau
if "!PROFIL_POWER!"=="0" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Gaming+MaxPerf ^(RSC/LSO OFF, ITR 200 + registre force, EEE OFF^)...%COLOR_RESET%
    ) else (
        echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Normal+MaxPerf ^(RSC/LSO ON, ITR defaut, EEE OFF^)...%COLOR_RESET%
    )
) else (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration NIC Eco ^(RSC/LSO/checksum ON, energie preservee^)...%COLOR_RESET%
)
call :SET_NIC_PROFILE !PROFIL_POWER! !PROFIL_USAGE!
if "!PROFIL_POWER!"=="0" (
    if "!PROFIL_USAGE!"=="0" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour latence gaming ^(Gaming+MaxPerf^)%COLOR_RESET%
    ) else (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour usage general ^(Normal+MaxPerf^)%COLOR_RESET%
    )
) else (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NIC optimisee pour debit/stabilite/autonomie ^(Eco^)%COLOR_RESET%
)
:: 5.11 - Gestion energie USB (impacte adaptateurs Wi-Fi USB, clavier, souris)
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
:: 5.12 - QoS Fortnite DSCP 46 (Gaming uniquement)
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
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%QoS Fortnite ignoree ^(Normal^) - aucune suppression hors restauration%COLOR_RESET%
)

:: 5.13 - Nettoyage des protocoles reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des protocoles reseau inutiles (Bindings)...%COLOR_RESET%
powershell -NoProfile -Command "Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq 'Up' -and $_.Virtual -eq $false } | ForEach-Object { Disable-NetAdapterBinding -Name $_.Name -ComponentID 'ms_lldp','ms_implat' -ErrorAction SilentlyContinue }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Bindings reseau nettoyes (LLDP, MS_IMPLAT)%COLOR_RESET%

:: 5.14 - Desactivation NetBIOS over TCP/IP
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de NetBIOS over TCP/IP...%COLOR_RESET%
for /f "tokens=*" %%i in ('reg query "HKLM\SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces" /s ^| findstr /i /r "\\Tcpip_.*$" 2^>nul') do (
  reg add "%%i" /v NetbiosOptions /t REG_DWORD /d 2 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%NetBIOS desactive%COLOR_RESET%

:: 5.15 - RssBaseCpu (Gaming : interrupts NIC decales du core 0)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%RssBaseCpu=1 ^(Gaming : interrupts NIC sur CPU 1+^)...%COLOR_RESET%
    reg add "HKLM\SYSTEM\CurrentControlSet\Services\Ndis\Parameters" /v RssBaseCpu /t REG_DWORD /d 1 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%RssBaseCpu configure ^(Gaming^)%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%RssBaseCpu : defaut Windows conserve ^(Normal^)%COLOR_RESET%
)

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Mise a jour des politiques groupe (gpupdate)...%COLOR_RESET%
gpupdate /target:computer /force >nul 2>&1
ipconfig /flushdns >nul 2>&1
nbtstat -R >nul 2>&1
nbtstat -RR >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Pile reseau optimisee (DNS/NetBIOS purges)%COLOR_RESET%

call :FINISH_ACTION "Optimisations reseau" "appliquees"
exit /b

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

:: Avertissement mode manuel sur PC portable : profil NORMAL conserve une acceleration trackpad legere.
if "%SKIP_PAUSE%"=="0" if "!DETECTE_PORTABLE!"=="1" (
    echo [*] %COLOR_YELLOW%PC PORTABLE DETECTE - MODE MANUEL%COLOR_RESET%
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

:: 6.1 - Souris optimisee
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
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Files souris/clavier ignorees en profil NORMAL ^(aucune restauration/suppression^)%COLOR_RESET%
)
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsolutePointerAsAbsolute" /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\mouhid\Parameters" /v "TreatAbsoluteAsRelative" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres souris et HID optimises%COLOR_RESET%

:: 6.2 - Clavier optimise
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de la reactivite clavier...%COLOR_RESET%
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%File clavier reduite ^(20^) - Profil GAMING%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%File clavier ignoree - Profil NORMAL%COLOR_RESET%
)

:: 6.3 - Win8 Scaling (Profil GAMING uniquement)
if "!PROFIL_USAGE!"=="0" (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation du Scaling Windows ^(Win8 DPI Scaling^)...%COLOR_RESET%
    reg add "HKCU\Control Panel\Desktop" /v Win8DpiScaling /t REG_DWORD /d 1 /f >nul 2>&1
    reg add "HKCU\Control Panel\Desktop" /v LogPixels /t REG_DWORD /d 96 /f >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Win8 Scaling active ^(Mode 1:1 force^)%COLOR_RESET%
) else (
    echo %COLOR_CYAN%[SKIP]%COLOR_RESET% %COLOR_WHITE%Win8 Scaling ignore en profil NORMAL ^(aucune restauration/suppression^)%COLOR_RESET%
)

:: 6.4 - MSI Mode Universel (Latence Peripheriques)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du MSI Mode USB...%COLOR_RESET%
powershell -NoProfile -Command "Get-PnpDevice -Class USB -ErrorAction SilentlyContinue | ForEach-Object { $p = 'HKLM:\SYSTEM\CurrentControlSet\Enum\' + $_.InstanceId + '\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties'; if(Test-Path $p){ New-ItemProperty -Path $p -Name 'MSISupported' -PropertyType DWord -Value 1 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Interruptions MSI USB activees%COLOR_RESET%



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

call :FINISH_ACTION "Optimisations peripheriques" "appliquees"
exit /b

:TOGGLE_ECONOMIES_ENERGIE
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
goto :MENU_PRINCIPAL

:DO_DESACTIVER_ECONOMIES
set "PROFIL_POWER=0"
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - ENERGIE" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :DESACTIVER_ECONOMIES_ENERGIE
goto :MENU_PRINCIPAL

:DESACTIVER_ECONOMIES_ENERGIE
set "PROFIL_POWER=0"
call :INIT_PROFILS
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 7 : DESACTIVATION DES ECONOMIES D'ENERGIE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Cette section desactive les fonctions d'economie d'energie%COLOR_RESET%
echo %COLOR_WHITE%  pour maintenir les performances maximales en permanence.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%

:: 7.1 - Power States NVMe agressifs (latence minimale)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Power States NVMe optimises ^(IdlePowerMode=0^)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerMode" /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power States NVMe agressifs appliques%COLOR_RESET%

:: 7.2 - Activation du plan Ultimate Performance
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du plan Ultimate Performance...%COLOR_RESET%
set "TARGET_GUID="
:: Probe par GUID (fiable quelle que soit la locale Windows)
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

:: 7.3 - GPU Power Management (ULPS & PowerMizer)
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

:: 7.4 - Parametres avances du plan d'alimentation (user standard)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration avancee du plan d'alimentation...%COLOR_RESET%

powercfg /setacvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 0d7dbae2-4294-402a-ba8e-26777e8488cd 309dce9b-bef4-4119-9921-a851fb12f0f4 1 >nul 2>&1

powercfg /setacvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 19cbb8fa-5279-450e-9fac-8a3d5fedd0c1 12bbebe6-58d6-4636-95bb-3217ef867c1a 0 >nul 2>&1

:: Veille hybride : desactivee (inutile si hibernate est off)
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

:: 7.5 - Optimisations CPU (Intel Hybrid + AMD Core Parking)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations CPU specifiques (Intel Hybrid / AMD Ryzen)...%COLOR_RESET%

:: Intel Hybrid CPUs (Alder Lake/Raptor Lake/Meteor Lake)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du profil processeur (performances maximales)...%COLOR_RESET%
:: E-cores (0cc5b647...-583) : 100 = aucun E-core parque
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 100 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 4d2b0152-7d5c-498b-88e2-34345392a2c5 5000 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking E-cores configure%COLOR_RESET%

:: Desactivation Core Parking (Intel + AMD)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation Core Parking (Intel Hybrid + AMD Ryzen)...%COLOR_RESET%
:: P-cores (0cc5b647...-584) : 100 = aucun P-core parque. Meme GUID pour Intel Hybrid et AMD Ryzen
:: (le parking core utilise le meme sous-groupe SUB_PROCESSOR 0cc5b647 sur les deux architectures)
:: GUID SUB_PROCESSOR en dur (alias SUB_PROCESSOR non fiable selon la locale Windows)
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 100 >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking desactive (AMD Ryzen optimise)%COLOR_RESET%

:: 7.6 - Desactivation economies d'energie Device Manager (ACPI/HID/PCI/USB)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation de l'alimentation des peripheriques (Device Manager)...%COLOR_RESET%
powershell -NoProfile -Command "$p=@('ACPI','HID','PCI','USB','USBSTOR'); foreach($s in $p){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Enum\$s"" -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -eq 'Device Parameters' -or $_.PSChildName -eq 'WDF' } | ForEach-Object { $rp = $_.Name; if($_.PSChildName -eq 'Device Parameters'){ reg add ""$rp"" /v ""EnhancedPowerManagementEnabled"" /t REG_DWORD /d 0 /f >$null; reg add ""$rp"" /v ""SelectiveSuspendEnabled"" /t REG_BINARY /d ""00"" /f >$null; reg add ""$rp"" /v ""SelectiveSuspendOn"" /t REG_DWORD /d 0 /f >$null; reg add ""$rp"" /v ""WaitWakeEnabled"" /t REG_DWORD /d 0 /f >$null } else { reg add ""$rp"" /v ""IdleInWorkingState"" /t REG_DWORD /d 0 /f >$null } } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie Device Manager desactivees (HID/PCI/USB)%COLOR_RESET%

:: 7.7 - Desactivation du demarrage rapide Fast Startup
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du demarrage rapide (Fast Startup)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v HiberbootEnabled /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Demarrage rapide desactive - Redemarrages propres%COLOR_RESET%

:: 7.8 - Hibernation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'hibernation...%COLOR_RESET%
powercfg /hibernate off >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Hibernation desactivee - Espace disque libere%COLOR_RESET%

:: 7.9 - USB Selective Suspend (Optimisation latence)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation USB - Gestion energie desactivee (selective suspend + USB 3 LPM + WMI)...%COLOR_RESET%
call :SET_USB_POWER 0
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%USB optimise - Latence minimale ^(Selective Suspend OFF^)%COLOR_RESET%
:: 7.10 - Configuration generale du systeme d'alimentation
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration du systeme d'alimentation...%COLOR_RESET%
:: ASPM est configure correctement a la section 7.20 ci-dessous avec SUB_PCIEXPRESS (501a4d13...)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WcmSvc\GroupPolicy" /v fDisablePowerManagement /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v PlatformAoAcOverride /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v SleepStudyDisabled /t REG_DWORD /d 1 /f >nul 2>&1

:: 7.11 - Desactivation des Timer Coalescing et DPC
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des Timer Coalescing et optimisation DPC...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v MinimumDpcRate /t REG_DWORD /d 1 /f >nul 2>&1
:: DisableTsx - Intel Transactional Synchronization Extensions (Intel uniquement, pas AMD)
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v DisableTsx /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v GlobalTimerResolutionRequests /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Kernel" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Executive" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
:: TimerCoalescing - Options (une seule activee a la fois, choisis celle qui te convient le mieux)
:: Option 1 (RECOMMANDEE si OK) : 64 bytes REG_BINARY - semble ameliorer le feeling souris / input lag, ne crashe pas
:: reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_BINARY /d 0000000000000000000000000000000000000000000000000000000000000000 /f >nul 2>&1
:: Option 2 (A TESTER) : 80 bytes REG_BINARY - version "complete" du noyau, mais PEUT CRASHER ou rendre instable sur certaines configs
:: reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_BINARY /d 000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000 /f >nul 2>&1
:: Option 3 (A TESTER) : REG_DWORD 1 - effet inconnu/noque (le noyau lit du REG_BINARY, mais a tester si mieux que option 1)
:: reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_DWORD /d 1 /f >nul 2>&1
:: Option 4 (A TESTER) : REG_DWORD 0 - retour au comportement par defaut (coalescing actif, pertes possibles)
:: reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /t REG_DWORD /d 0 /f >nul 2>&1
:: Option 5 : Supprimer la valeur (comportement noyau par defaut) - utilise reg delete ci-dessous si necessaire
:: reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Windows" /v TimerCoalescing /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\ModernSleep" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\ControlSet001\Control" /v CoalescingTimerInterval /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power" /v EnergyEstimationEnabled /t REG_DWORD /d 0 /f >nul 2>&1
:: DisableDynamicTick : desactive l'horloge dynamique (interruptions plus predictibles)
bcdedit /set disabledynamictick yes >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Timer Coalescing desactive - Latence reduite%COLOR_RESET%

:: 7.12 - Installation SetTimerResolution
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration de SetTimerResolution...%COLOR_RESET%
set "STR_DIR=%ProgramFiles%\SetTimerResolution"
set "STR_OLD_DIR=%ProgramFiles%\OptimizerAllInOne"
set "STR_EXE=%STR_DIR%\SetTimerResolution.exe"
set "STR_SRC=%~dp0Tools\Timer & Interrupt\SetTimerResolution.exe"
set "STR_STARTUP_LNK=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\SetTimerResolution.exe - Raccourci.lnk"
:: Le dossier de destination doit exister AVANT toute copie/telechargement (sinon echec)
if not exist "%STR_DIR%" mkdir "%STR_DIR%" >nul 2>&1
if not exist "%STR_EXE%" if exist "%STR_OLD_DIR%\SetTimerResolution.exe" move /Y "%STR_OLD_DIR%\SetTimerResolution.exe" "%STR_EXE%" >nul 2>&1
if exist "%STR_OLD_DIR%" rmdir "%STR_OLD_DIR%" >nul 2>&1
if exist "%STR_EXE%" (
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution deja installe dans %STR_DIR%%COLOR_RESET%
) else (
    REM Priorite a la copie locale (livree avec le script), telechargement GitHub en secours
    if exist "%STR_SRC%" copy /Y "%STR_SRC%" "%STR_EXE%" >nul 2>&1
    if not exist "%STR_EXE%" powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://github.com/kaylerberserk/WindowsOptimizer/raw/main/Tools/Timer%%20%%26%%20Interrupt/SetTimerResolution.exe' -OutFile '%STR_EXE%' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
    if exist "%STR_EXE%" (
        echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution installe dans %STR_DIR%%COLOR_RESET%
    ) else (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Echec de l'installation de SetTimerResolution%COLOR_RESET%
    )
)
if exist "%STR_EXE%" (
    taskkill /F /IM SetTimerResolution.exe >nul 2>&1
    powershell -NoProfile -Command "$WshShell = New-Object -ComObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%STR_STARTUP_LNK%'); $Shortcut.TargetPath = '%STR_EXE%'; $Shortcut.Arguments = '--resolution 5070 --no-console'; $Shortcut.WorkingDirectory = '%STR_DIR%'; $Shortcut.Description = 'SetTimerResolution - WindowsOptimizer'; $Shortcut.Save()" >nul 2>&1
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci SetTimerResolution configure ^(5070^)%COLOR_RESET%
    start "" "%STR_EXE%" --resolution 5070 --no-console
    echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%SetTimerResolution active immediatement%COLOR_RESET%
)

:: 7.13 - Desactivation du PDC et Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation du Power Throttling (bridage CPU)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power Throttling desactive - CPU non bride%COLOR_RESET%

:: 7.14 - Desactivation ASPM
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation ASPM sur le bus PCI Express...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%ASPM desactive - Latence PCIe reduite%COLOR_RESET%

:: 7.15 - Optimisations stockage et disques
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisations stockage ^(StorageD3 + HIPM/DIPM^)...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; New-ItemProperty -Path $p -Name 'EnableHIPM' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'EnableDIPM' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null; New-ItemProperty -Path $p -Name 'EnableHDDParking' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Stockage optimise - D3 Modern Standby OFF, HIPM/DIPM OFF%COLOR_RESET%

:: 7.16 - Optimisations avancees des services
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des limites de latence I/O ^(StorPort^)...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; New-ItemProperty -Path $p -Name 'IoLatencyCap' -PropertyType DWord -Value 0 -Force -ErrorAction SilentlyContinue | Out-Null } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Limites de latence stockage supprimees%COLOR_RESET%

:: 7.17 - GPU PreferMaxPerf
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Configuration GPU en mode performances maximales...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v PreferMaxPerf /t REG_DWORD /d 1 /f >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%GPU configure en mode performances maximales%COLOR_RESET%

:: 7.18 - PCI & peripheriques reseau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de la mise en veille des peripheriques PCI...%COLOR_RESET%
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e97d-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v D3ColdSupported /t REG_DWORD /d 0 /f >nul 2>&1
)
for /f "tokens=*" %%K in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Class\{4d36e972-e325-11ce-bfc1-08002be10318}" /f "" /k 2^>nul ^| findstr /r "\\[0-9][0-9][0-9][0-9]$"') do (
  reg add "%%K" /v "*WakeOnPattern" /t REG_DWORD /d 0 /f >nul 2>&1
)

:: 7.19 - Cartes reseau (helper NIC profile sans restart)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des fonctions d'economie d'energie reseau...%COLOR_RESET%
call :SET_NIC_PROFILE 0 !PROFIL_USAGE!
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie et optimisations reseau appliquees sur toutes les cartes%COLOR_RESET%

:: 7.20 - Energie PCIe
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

set "TARGET_GUID="
set "STR_EXE="
set "STR_OLD_DIR="
set "STR_STARTUP_LNK="
call :FINISH_ACTION "Economies d'energie" "desactivees"
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

:: 7.0 - Restaurer tous les plans d'alimentation aux valeurs d'usine Microsoft
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de tous les plans d'alimentation aux valeurs d'usine...%COLOR_RESET%
echo Add-Type -TypeDefinition @' > "%TEMP%\reset_power.ps1"
echo using System; >> "%TEMP%\reset_power.ps1"
echo using System.Runtime.InteropServices; >> "%TEMP%\reset_power.ps1"
echo public class Power { >> "%TEMP%\reset_power.ps1"
echo     [DllImport("powrprof.dll", SetLastError=true)] >> "%TEMP%\reset_power.ps1"
echo     public static extern uint PowerRestoreDefaultPowerSchemes(); >> "%TEMP%\reset_power.ps1"
echo } >> "%TEMP%\reset_power.ps1"
echo '@ >> "%TEMP%\reset_power.ps1"
echo [Power]::PowerRestoreDefaultPowerSchemes() >> "%TEMP%\reset_power.ps1"
powershell -NoProfile -File "%TEMP%\reset_power.ps1" <nul
del "%TEMP%\reset_power.ps1" 2>nul
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plans d'alimentation restaures (tous les schemas et valeurs par defaut)%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation du plan Equilibre Windows...%COLOR_RESET%
powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Plan Equilibre Windows actif%COLOR_RESET%
:: Le plan UP duplique (99999999-...) est automatiquement supprime par la restauration d'usine

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
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /f >nul 2>&1
:: Revert powercfg USB selective suspend (1 = Enabled = default)
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 >nul 2>&1
:: Revert USB 3 Link Power Management (2 = Moderate savings = default)
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 2 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 2 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mise en veille selective USB reactivee%COLOR_RESET%

:: 7.4 - Timer Coalescing
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
:: Reactive DynamicTick (horloge dynamique)
bcdedit /deletevalue disabledynamictick >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Timer Coalescing reactive%COLOR_RESET%

:: 7.5 - SetTimerResolution du demarrage
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

:: 7.6 - Restaurer Intel Thread Director (visibilite panneau)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite Intel Thread Director...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /f >nul 2>&1
REM Restauration de la valeur Thread Director a la valeur default 0 (All Processors) :
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 93b8b6dc-0698-4d1c-9ee4-0644e900c85d 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
REM bae08b81-2d5e-4688-ad6a-13243356654b : GUID non documente MS Learn 2026 (Voir 7.x commentaire) - pas de reg delete necessaire
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Visibilite Intel Thread Director restauree (valeurs par defaut via 7.0)%COLOR_RESET%

:: 7.7 - Restaurer Core Parking (powercfg + visibilite panneau)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration du Core Parking...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /f >nul 2>&1
:: Revert des valeurs powercfg (0 = gestion dynamique Windows)
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318583 0 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 54533251-82be-4824-96c1-47b60b740d00 0cc5b647-c1df-4637-891a-dec35c318584 0 >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Core Parking restaure (gestion dynamique Windows)%COLOR_RESET%

:: 7.8 - Power Throttling
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation du Power Throttling...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\Default\VetoPolicy" /v "EA:EnergySaverEngaged" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PDC\Activators\28\VetoPolicy" /v "EA:PowerStateDischarging" /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerThrottling" /v PowerThrottlingOff /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power Throttling reactive%COLOR_RESET%

:: 7.9 - Seuils d'economie d'energie (hardcodes 20% dans plan Balanced, pas de restoration necessaire)

:: 7.10 - Power States NVMe (restauration par defaut)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration Power States NVMe ^(defaut Windows^)...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\stornvme\Parameters\Device" /v "IdlePowerMode" /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Power States NVMe restaures%COLOR_RESET%

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
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {$n=$_.Name; Enable-NetAdapterRss -Name $n -ErrorAction SilentlyContinue; Enable-NetAdapterRsc -Name $n -ErrorAction SilentlyContinue; Enable-NetAdapterLso -Name $n -ErrorAction SilentlyContinue; Enable-NetAdapterPowerManagement -Name $n -ErrorAction SilentlyContinue; Reset-NetAdapterAdvancedProperty -Name $n -DisplayName '*' -ErrorAction SilentlyContinue}; $bindingIds=@('ms_lldp','ms_lltdio','ms_implat','ms_rspndr'); Get-NetAdapter -ErrorAction SilentlyContinue | ForEach-Object {foreach($id in $bindingIds){Enable-NetAdapterBinding -Name $_.Name -ComponentID $id -ErrorAction SilentlyContinue}}" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Economies d'energie NIC et bindings restaures%COLOR_RESET%

:: 7.13 - Visibilite des parametres processeur dans le panneau
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite des parametres processeur...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\93b8b6dc-0698-4d1c-9ee4-0644e900c85d" /v Attributes /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318584" /v Attributes /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583" /v Attributes /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Visibilite restauree (valeurs par defaut via 7.0)%COLOR_RESET%

:: 7.14 - ASPM (PCI Express)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation ASPM sur le bus PCI Express...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\pci\Parameters" /v ASPMOptOut /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%ASPM reactive%COLOR_RESET%

:: 7.15 - Mise en veille des disques et stockage
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des parametres de stockage...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Storage" /v StorageD3InModernStandby /f >nul 2>&1
:: Supprimer HIPM/DIPM/HDDParking pour revenir aux valeurs par defaut systeme
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'EnableHIPM','EnableDIPM','EnableHDDParking' -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Parametres de stockage restaures%COLOR_RESET%

:: 7.16 - Limites de latence I/O
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration des limites de latence I/O...%COLOR_RESET%
powershell -NoProfile -Command "$classes=@('{4d36e96a-e325-11ce-bfc1-08002be10318}','{4d36e97b-e325-11ce-bfc1-08002be10318}'); foreach($c in $classes){ Get-ChildItem -Path ""HKLM:\SYSTEM\CurrentControlSet\Control\Class\$c"" -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -match '^\d{4}$' } | ForEach-Object { $p=$_.PSPath; Remove-ItemProperty -Path $p -Name 'IoLatencyCap' -ErrorAction SilentlyContinue } }" >nul 2>&1
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Gestion d'energie PCI reactivee%COLOR_RESET%

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

:: 7.21 - Gestion d'energie PCIe (visibilite panneau)
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Restauration de la visibilite PCIe...%COLOR_RESET%
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\501a4d13-42af-4429-9fd1-a8218c268e20\ee12f906-d277-404b-b6da-e5fa1a576df5" /v Attributes /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Visibilite PCIe restauree (valeur par defaut via 7.0)%COLOR_RESET%

:: 7.22 - Energie PCIe GPU (ASPM restaure en 7.11, valeurs powercfg via 7.0)

:: 7.23 - Plans d'alimentation avances (restaures via API 7.0)

set "STR_STARTUP_LNK="
call :FINISH_ACTION "Economies d'energie" "restaurees"
exit /b

:TOGGLE_PROTECTIONS_SECURITE
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GESTION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Permet de desactiver ou restaurer les protections CPU contre les failles%COLOR_RESET%
echo %COLOR_WHITE%  Spectre/Meltdown et autres vulnerabilites noyau (gain FPS possible).%COLOR_RESET%
echo %COLOR_WHITE%  Le mode perf demande l'usage pour appliquer le bon niveau Gaming/Normal.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_RED%Desactiver Protections Securite (mode perf)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_GREEN%Restaurer Protections Securite (recommande)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Principal%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, M]: %COLOR_RESET%"
call :AZCHOICE 12M
if !errorlevel! EQU 3 goto :MENU_PRINCIPAL
if !errorlevel! EQU 2 goto :DO_RESTAURER_PROTECTIONS
if !errorlevel! EQU 1 goto :DO_DESACTIVER_PROTECTIONS
goto :TOGGLE_PROTECTIONS_SECURITE

:DO_RESTAURER_PROTECTIONS
call :RESTAURER_PROTECTIONS_SECURITE
goto :MENU_PRINCIPAL

:DO_DESACTIVER_PROTECTIONS
call :CHOISIR_PROFILS "CONFIGURATION PROFILS - SECURITE" "USAGE"
if !errorlevel! NEQ 0 goto :MENU_PRINCIPAL
call :DESACTIVER_PROTECTIONS_SECURITE
if !errorlevel! NEQ 0 goto :TOGGLE_PROTECTIONS_SECURITE
goto :MENU_PRINCIPAL

:DESACTIVER_PROTECTIONS_SECURITE
call :INIT_PROFILS
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_PROTECTIONS_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% SECTION 8 : DESACTIVATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo [*] %COLOR_YELLOW%AVERTISSEMENT :%COLOR_RESET%
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
echo %COLOR_WHITE%  - Ces reglages sont sensibles : une erreur peut rendre le systeme instable.%COLOR_RESET%
echo %COLOR_WHITE%  - Recommande surtout pour jeux competitifs sur machine personnelle et controlee.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_PROTECTIONS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver ces protections ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_PROTECTIONS_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DES PROTECTIONS DE SECURITE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive les protections CPU (Spectre/Meltdown) et les blocages de pilotes dangereux%COLOR_RESET%
echo %COLOR_WHITE%  pour reduire la latence CPU sur machine isolee.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
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

if "!PROFIL_USAGE!"=="0" (
REM 8.4 - Mode Gaming VBS/HVCI compatible anti-cheat FaceIT/Vanguard
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application Mode Gaming VBS/HVCI [HVCI=1, VBS=1, CFG=1, LSA=0]...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Gaming VBS/HVCI applique - compatible FaceIT/Vanguard%COLOR_RESET%
)
:: Vulnerable Driver Blocklist
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Optimisation CI Policy (Driver Blocklist)...%COLOR_RESET%
echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Desactive la blocklist de pilotes vulnerables - autorise le chargement de pilotes non signes (risque BYOVD)%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Blocklist de pilotes vulnerables desactivee%COLOR_RESET%

call :FINISH_ACTION "Protections securite" "desactivees"
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
:: 8.3 - Blocklist de pilotes vulnerables
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de la blocklist de pilotes vulnerables...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v VulnerableDriverBlocklistEnable /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Blocklist pilotes vulnerables reactivee%COLOR_RESET%

:: 8.4 - Restauration VBS/HVCI/CFG aux valeurs par defaut
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /f >nul 2>&1
reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /f >nul 2>&1
:: CFG doit etre ACTIVE par defaut (requis pour Vanguard / anti-cheat)
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1

call :FINISH_ACTION "Protections securite" "restaurees"
exit /b

:TOGGLE_DEFENDER
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Defender est l'antivirus integre de Windows. Le desactiver reduit l'overhead CPU/RAM%COLOR_RESET%
echo %COLOR_WHITE%  mais expose le systeme. Tamper Protection peut ignorer une partie de ces reglages.%COLOR_RESET%
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
  if !errorlevel! NEQ 0 goto :TOGGLE_DEFENDER
  goto :MENU_GESTION_WINDOWS
)
call :ACTIVER_DEFENDER_SECTION
goto :MENU_GESTION_WINDOWS

:: ___DEFENDER_ULT_EMBEDDED_SUBS___
:ACTIVER_DEFENDER_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE WINDOWS DEFENDER%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive Windows Defender, SmartScreen et les taches planifiees associees.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
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
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v VerifiedAndReputableTrustModeEnabled /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows Defender" /v SmartLockerMode /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\CI\Config" /v "VulnerableDriverBlocklistEnable" /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de SmartScreen...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "EnableSmartScreen" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "ShellSmartScreenLevel" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v "SmartScreenEnabled" /f >nul 2>&1
reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost" /v "EnableWebContentEvaluation" /t REG_DWORD /d 1 /f >nul 2>&1

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
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de Tamper Protection...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows Defender\Features" /v "TamperProtection" /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "if ((Get-MpComputerStatus).IsTamperProtected -eq $true) { echo [WARN] Tamper Protection encore activee - desactivez manuellement via Securite Windows }"

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
call :FINISH_ACTION "Windows Defender" "desactive"
exit /b

:TOGGLE_VBS_HVCI
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER VBS / HVCI (ISOLATION DU NOYAU)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  VBS (= Virtualization Based Security) et HVCI (= Memory Integrity) sont des protections%COLOR_RESET%
echo %COLOR_WHITE%  du noyau Windows. Elles renforcent la securite mais coutent jusqu'a -25%% de FPS en jeu.%COLOR_RESET%
echo.
echo [*] %STYLE_BOLD%%COLOR_RED%ATTENTION :%COLOR_RESET% %COLOR_YELLOW%Certains jeux avec anti-triche (Valorant, CS2, Call of Duty)%COLOR_RESET%
echo %COLOR_YELLOW%exigent que VBS/HVCI soit ACTIVE pour pouvoir lancer le jeu.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer VBS/HVCI (Securite maximale)%COLOR_RESET%
echo       %COLOR_WHITE%Active toutes les protections noyau. Perf reduite, securite maximale.%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver VBS/HVCI (100%% performances)%COLOR_RESET%
echo       %COLOR_WHITE%Desactive tout. Gain FPS max, mais certains jeux anti-triche peuvent refuser de lancer.%COLOR_RESET%
echo %COLOR_YELLOW%[3]%COLOR_RESET% %STYLE_BOLD%%COLOR_CYAN%Mode Mixte (recommandee)%COLOR_RESET%
echo       %COLOR_WHITE%VBS/HVCI restent actifs ^(jeux compatibles^), mais les mitigations CPU sont desactivees pour les perfs.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1, 2, 3, M]: %COLOR_RESET%"
call :AZCHOICE 123M
if !errorlevel! EQU 4 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 3 (
  cls
  echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
  echo %STYLE_BOLD%%COLOR_WHITE% MODE GAMING - VBS/HVCI%COLOR_RESET%
  echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
  echo.
  echo %COLOR_WHITE%  HVCI=1, VBS=1, CFG=1, LSA=0 - Compatible FaceIT/Vanguard%COLOR_RESET%
  echo %COLOR_WHITE%  Mitigations CPU desactivees pour gain FPS%COLOR_RESET%
  echo.
  echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
  echo.
  echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Application du Mode Gaming ^(Performance + Compatibilite^)...%COLOR_RESET%
  REM Desactiver Mitigations CPU - Gain FPS
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v EnableKVAShadow /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v KvaOpt /t REG_DWORD /d 0 /f >nul 2>&1
  REM HVCI = 1, VBS = 1, CFG = 1, LSA = 0 - Mode optimal pour anti-cheat + perfs
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
  powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1
  echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Mode Gaming active ^(Optimisation CPU + Compatibilite Anti-cheat^).%COLOR_RESET%
  call :FINISH_ACTION "VBS/HVCI" "configure (Mode Gaming)"
  goto :MENU_GESTION_WINDOWS
)
if !errorlevel! EQU 2 (
  cls
  echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
  echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION VBS / HVCI%COLOR_RESET%
  echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
  echo.
  echo %COLOR_WHITE%  Desactive VBS, HVCI et Credential Guard pour performances Gaming%COLOR_RESET%
  echo.
  echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
  echo.
  echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation complete de VBS, HVCI et Credential Guard...%COLOR_RESET%
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v Locked /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 0 /f >nul 2>&1
  reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 0 /f >nul 2>&1
  echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%VBS/HVCI et Credential Guard desactives.%COLOR_RESET%
  call :FINISH_ACTION "VBS/HVCI" "desactive"
  goto :MENU_GESTION_WINDOWS
)
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION VBS / HVCI%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Active VBS, HVCI et Credential Guard pour securite maximale%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de VBS, HVCI et Credential Guard...%COLOR_RESET%
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard" /v EnableVirtualizationBasedSecurity /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" /v Enabled /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Control\Lsa" /v LsaCfgFlags /t REG_DWORD /d 1 /f >nul 2>&1
REM CFG doit rester ACTIVE pour Vanguard (Valorant)
powershell -NoProfile -Command "Set-ProcessMitigation -System -Enable CFG" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%VBS/HVCI et Credential Guard actives.%COLOR_RESET%
call :FINISH_ACTION "VBS/HVCI" "active"
goto :MENU_GESTION_WINDOWS

:TOGGLE_UAC
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% GERER UAC (CONTROLE DE COMPTE UTILISATEUR)%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  L'UAC affiche une invite de confirmation avant toute action admin.%COLOR_RESET%
echo %COLOR_WHITE%  Le desactiver supprime ces invites : plus rapide, mais dangereux.%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[1]%COLOR_RESET% %COLOR_GREEN%Activer UAC (Recommande)%COLOR_RESET%
echo %COLOR_YELLOW%[2]%COLOR_RESET% %COLOR_RED%Desactiver UAC + Avertissements (Pour LAB)%COLOR_RESET%
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
  if !errorlevel! NEQ 0 goto :TOGGLE_UAC
  goto :MENU_GESTION_WINDOWS
)
call :ACTIVER_UAC_SECTION
goto :MENU_GESTION_WINDOWS

:ACTIVER_UAC_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DE L'UAC%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive le Controle de Compte Utilisateur (UAC) et les avertissements SmartScreen.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Le controle de compte utilisateur (UAC) sera active - confirmez les invites d'elevation si demande.%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de l'UAC...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 1 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 5 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 1 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Reactivation de SmartScreen et suivi de zone Internet...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Warn" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 2 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%UAC active.%COLOR_RESET%
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
echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Desactiver l'UAC supprime la protection d'elevation de privileges - les programmes malveillants peuvent executer en admin sans confirmation.%COLOR_RESET%
echo.
echo [*] %COLOR_YELLOW%LAB UNIQUEMENT : plus aucun avertissement au lancement de fichiers.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_UAC_RUN "%STYLE_BOLD%%COLOR_YELLOW%Etes-vous sur de desactiver l'UAC et les avertissements lies ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_UAC_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE L'UAC%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive le Controle de Compte Utilisateur, SmartScreen et les avertissements de zone Internet.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de l'UAC...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v EnableLUA /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v ConsentPromptBehaviorAdmin /t REG_DWORD /d 0 /f >nul 2>&1
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" /v PromptOnSecureDesktop /t REG_DWORD /d 0 /f >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation de SmartScreen et suivi de zone Internet...%COLOR_RESET%
reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer" /v SmartScreenEnabled /t REG_SZ /d "Off" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Policies\Attachments" /v SaveZoneInformation /t REG_DWORD /d 1 /f >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%UAC desactive.%COLOR_RESET%
call :FINISH_ACTION "UAC" "desactive"
exit /b

:TOGGLE_ANIMATIONS
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
  if !errorlevel! NEQ 0 goto :TOGGLE_ANIMATIONS
  goto :MENU_GESTION_WINDOWS
)
call :ACTIVER_ANIMATIONS_SECTION
goto :MENU_GESTION_WINDOWS

:ACTIVER_ANIMATIONS_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% ACTIVATION DES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Reactive les animations et effets visuels Windows (transparence, fade, animations au survol).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation des animations et effets visuels...%COLOR_RESET%

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
call :ASK_IF_INTERACTIVE :DESACTIVER_ANIMATIONS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous vraiment desactiver les animations ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_ANIMATIONS_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DES ANIMATIONS WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive les animations et effets visuels Windows pour ameliorer les performances.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Desactivation des animations et effets visuels...%COLOR_RESET%

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

echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Animations Windows desactivees.%COLOR_RESET%
call :FINISH_ACTION "Animations" "desactivees"
exit /b

:MENU_IA_WIDGETS_RECALL
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
echo %STYLE_BOLD%%COLOR_BLUE%--- PHONE LINK ---%COLOR_RESET%
echo %COLOR_YELLOW%[7]%COLOR_RESET% %COLOR_RED%Bloquer l'activation en arriere-plan%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[D]%COLOR_RESET% %COLOR_RED%Desactiver TOUT (Copilot + Widgets + Recall + PhoneLink)%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[M]%COLOR_RESET% %COLOR_CYAN%Retour au Menu Gestion Windows%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
<nul set /p ="%STYLE_BOLD%%COLOR_YELLOW%Choisissez une option [1-7, D, M]: %COLOR_RESET%"
call :AZCHOICE 1234567DM
if !errorlevel! EQU 9 goto :MENU_GESTION_WINDOWS
if !errorlevel! EQU 8 (
  call :DESACTIVER_TOUT_IA_WIDGETS_RECALL
  if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
  goto :MENU_GESTION_WINDOWS
)
if !errorlevel! EQU 7 (
  call :DESACTIVER_PHONELINK_SECTION
  if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
  goto :MENU_GESTION_WINDOWS
)
if !errorlevel! EQU 6 (
  call :DESACTIVER_RECALL_SECTION
  if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
  goto :MENU_GESTION_WINDOWS
)
if !errorlevel! EQU 5 (
  call :ACTIVER_RECALL_SECTION
  goto :MENU_GESTION_WINDOWS
)
if !errorlevel! EQU 4 (
  call :DESACTIVER_WIDGETS_SECTION
  if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
  goto :MENU_GESTION_WINDOWS
)
if !errorlevel! EQU 3 (
  call :ACTIVER_WIDGETS_SECTION
  goto :MENU_GESTION_WINDOWS
)
if !errorlevel! EQU 2 (
  call :DESACTIVER_COPILOT_SECTION
  if !errorlevel! NEQ 0 goto :MENU_IA_WIDGETS_RECALL
  goto :MENU_GESTION_WINDOWS
)
call :ACTIVER_COPILOT_SECTION
goto :MENU_GESTION_WINDOWS

:ACTIVER_COPILOT_SECTION
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Copilot active.%COLOR_RESET%
call :FINISH_ACTION "Copilot" "active"
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
call :ASK_IF_INTERACTIVE :DESACTIVER_COPILOT_RUN "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation de Copilot ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_COPILOT_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION DE COPILOT%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive Copilot, le bouton dans la barre des taches et bloque les domaines associes.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_COPILOT
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Copilot desactive.%COLOR_RESET%
call :FINISH_ACTION "Copilot" "desactive"
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
powershell -NoProfile -Command "$h='%HOSTS%'; $s='# Copilot Block Start'; $e='# Copilot Block End'; $nb=""# Copilot Block Start`r`n0.0.0.0 copilot.microsoft.com`r`n0.0.0.0 windows.ai.microsoft.com`r`n0.0.0.0 copilot-telemetry.microsoft.com`r`n0.0.0.0 msedge.api.cdp.microsoft.com`r`n# Copilot Block End""; if(Test-Path $h){ $c=Get-Content $h -Raw; if($c -match ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e))){ $c=$c -replace ('(?s)'+[regex]::Escape($s)+'.*?'+[regex]::Escape($e)), $nb } else { if($c.Trim().Length -gt 0){ $c=$c.TrimEnd()+""`r`n`r`n""+$nb } else { $c=$nb } } Set-Content -Path $h -Value $c -Encoding ASCII -Force }; if($?) { exit 0 } else { exit 1 }" >nul 2>&1
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
echo %COLOR_WHITE%  Reactive les Widgets dans la barre des taches (actualites, meteo, etc.).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_WIDGETS
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Widgets actives.%COLOR_RESET%
call :FINISH_ACTION "Widgets" "active"
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
call :ASK_IF_INTERACTIVE :DESACTIVER_WIDGETS_RUN "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation des Widgets ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_WIDGETS_RUN
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Widgets desactives.%COLOR_RESET%
call :FINISH_ACTION "Widgets" "desactive"
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
echo %COLOR_WHITE%  Reactive Recall et les fonctionnalites IA associees (snapshots, analyse d'ecran).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_ACTIVER_RECALL
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Recall active.%COLOR_RESET%
call :FINISH_ACTION "Recall" "active"
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
call :ASK_IF_INTERACTIVE :DESACTIVER_RECALL_RUN "%STYLE_BOLD%%COLOR_YELLOW%Confirmer la desactivation de Recall ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_RECALL_RUN
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
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Recall desactive.%COLOR_RESET%
call :FINISH_ACTION "Recall" "desactive"
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

:CORE_DESACTIVER_PHONELINK
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Blocage de l'activation en arriere-plan de PhoneLink...%COLOR_RESET%
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" /v Microsoft.YourPhone_8wekyb3d8bbwe /t REG_DWORD /d 0 /f >nul 2>&1
powershell -NoProfile -Command "Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'Microsoft.YourPhone_8wekyb3d8bbwe' -Value 0 -ErrorAction SilentlyContinue" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%PhoneLink / YourPhone background activation bloquee%COLOR_RESET%
exit /b

:DESACTIVER_PHONELINK_SECTION
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% BLOCAGE DE PHONE LINK / YOURPHONE%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Bloque l'activation en arriere-plan de Phone Link et YourPhone.%COLOR_RESET%
echo %COLOR_WHITE%  L'application reste installee ^(Outlook mobile / Files preserves^).%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_PHONELINK
call :FINISH_ACTION "Phone Link / YourPhone" "bloque"
exit /b

:DESACTIVER_TOUT_IA_WIDGETS_RECALL
if not "%SKIP_PAUSE%"=="0" goto :DESACTIVER_TOUT_IA_RUN
cls
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo %COLOR_WHITE%Confirmer la desactivation TOTALE ^(Copilot + Widgets + Recall + PhoneLink^) ?%COLOR_RESET%
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
echo %COLOR_WHITE%Effet : suppression de toutes les fonctionnalites IA, widgets cloud et PhoneLink.%COLOR_RESET%
echo.
call :ASK_IF_INTERACTIVE :DESACTIVER_TOUT_IA_RUN "%STYLE_BOLD%%COLOR_YELLOW%Voulez-vous vraiment tout desactiver ? [O/N]: %COLOR_RESET%"
if !errorlevel! NEQ 0 exit /b
:DESACTIVER_TOUT_IA_RUN
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% DESACTIVATION TOTALE IA / WIDGETS / PHONELINK%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_WHITE%  Desactive Copilot, les Widgets, Recall et PhoneLink en une seule operation.%COLOR_RESET%
echo.
echo %COLOR_CYAN%---------------------------------------------------------------------------------%COLOR_RESET%
echo.
call :CORE_DESACTIVER_COPILOT
call :CORE_DESACTIVER_WIDGETS
call :CORE_DESACTIVER_RECALL
call :CORE_DESACTIVER_PHONELINK
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Copilot, Widgets, Recall et PhoneLink desactives.%COLOR_RESET%
call :FINISH_ACTION "Toutes les fonctions IA/Widgets/PhoneLink" "desactivees"
exit /b


:FINISH_ACTION
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%%~1 %~2%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser les changements.%COLOR_RESET%
call :PROMPT_MANUAL_REBOOT
:FINISH_ACTION_EXIT
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

:: Arreter les processus OneDrive
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

:: Commande pour desinstaller OneDrive
echo %COLOR_YELLOW%[3/7]%COLOR_RESET% %COLOR_WHITE%Execution du desinstalleur OneDrive Windows...%COLOR_RESET%
if exist "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" (
    "%SYSTEMROOT%\SysWOW64\OneDriveSetup.exe" /uninstall
) else (
    "%SYSTEMROOT%\System32\OneDriveSetup.exe" /uninstall
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Desinstalleur OneDrive execute%COLOR_RESET%

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
:: Wildcards : rd ne supporte pas les wildcards, il faut une enumeration for /d
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

:: Supprimer les raccourcis OneDrive du menu Demarrer
echo %COLOR_YELLOW%[7/7]%COLOR_RESET% %COLOR_WHITE%Suppression des raccourcis OneDrive...%COLOR_RESET%
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft OneDrive.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Links\OneDrive.lnk" /f /q >nul 2>&1
del "%UserProfile%\Desktop\OneDrive.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk" /f /q >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourcis OneDrive supprimes%COLOR_RESET%

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
echo %COLOR_WHITE%- Certaines fonctions Windows (widgets, flux RSS) peuvent utiliser Edge par defaut.%COLOR_RESET%
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

echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Debut de la desinstallation...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Arret des processus Edge...%COLOR_RESET%
taskkill /f /im msedge.exe >nul 2>&1
taskkill /f /im MicrosoftEdgeUpdate.exe >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression de l'icone Edge de la barre des taches...%COLOR_RESET%
:: Suppression ciblee des raccourcis Edge uniquement
del "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\Microsoft Edge.lnk" /f /q >nul 2>&1
if exist "%APPDATA%\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar" (
    powershell -NoProfile -Command "Get-ChildItem -Path ""$env:APPDATA\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar\*.lnk"" -ErrorAction SilentlyContinue | ForEach-Object { try { $sh = (New-Object -ComObject WScript.Shell).CreateShortcut($_.FullName); if ($sh.TargetPath -match 'msedge\.exe') { Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue } } catch {} }" >nul 2>&1
)
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Raccourci Edge supprime (les autres icones sont preservees)%COLOR_RESET%

:: Desinstallation de Microsoft Edge
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Tentative de desinstallation de Microsoft Edge...%COLOR_RESET%
if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application" (
    pushd "%ProgramFiles(x86)%\Microsoft\Edge\Application" >nul 2>&1
    for /d %%i in (*) do (
        if exist "%%i\Installer\setup.exe" (
            "%%i\Installer\setup.exe" --uninstall --system-level --force-uninstall >nul 2>&1
        )
    )
    popd >nul 2>&1
)

echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression definitive des dossiers programme Edge - irrversible.%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage force des dossiers programme...%COLOR_RESET%
rd "%ProgramFiles%\Microsoft\Edge" /s /q >nul 2>&1
rd "%ProgramFiles(x86)%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression des cles de registre Edge - operation irreversible.%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des cles de registre Edge...%COLOR_RESET%
reg delete "HKLM\SOFTWARE\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\Microsoft Edge" /f >nul 2>&1

:: Gestion conditionnelle des donnees utilisateur
if "%SUPPR_DATA%"=="1" (
    echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression definitive des donnees utilisateur Edge ^(profils, favoris, mots de passe^).%COLOR_RESET%
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

echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression des donnees systeme Edge (PROGRAMDATA) - definitive.%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Nettoyage des donnees systeme communes...%COLOR_RESET%
rd "%PROGRAMDATA%\Microsoft\Edge" /s /q >nul 2>&1

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des raccourcis...%COLOR_RESET%
del "%USERPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%PUBLIC%\Desktop\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ALLUSERSPROFILE%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1
del "%ProgramData%\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk" /f /q >nul 2>&1

echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression des associations de fichiers Edge - definitive.%COLOR_RESET%
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
    echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Edge n'a pas pu etre completement desinstalle.%COLOR_RESET%
) else (
    if exist "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe" (
        echo %COLOR_RED%[ERREUR]%COLOR_RESET% %COLOR_WHITE%Edge n'a pas pu etre completement desinstalle.%COLOR_RESET%
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
echo %STYLE_BOLD%%COLOR_WHITE% CREATION D'UN POINT DE RESTAURATION%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Verification et activation de la restauration systeme si necessaire...%COLOR_RESET%
:: Verifie uniquement la cle registre DisableSR (SystemRestore.GetDiskList WMI n'existe pas)
:: Si DisableSR=1, SR est desactive globalement et la creation de point echouera : on reactive
powershell -NoProfile -Command "$p = Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore' -ErrorAction SilentlyContinue; if ($null -ne $p -and $p.DisableSR -eq 1) { exit 1 } else { exit 0 }" >nul 2>&1
if !errorlevel! NEQ 0 (
    echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Activation de la restauration systeme...%COLOR_RESET%
    reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "RPSessionInterval" /t REG_DWORD /d 1 /f >nul 2>&1
    powershell -NoProfile -Command "try { Enable-ComputerRestore -Drive 'C:' -ErrorAction SilentlyContinue } catch {}" >nul 2>&1
    timeout /t 2 /nobreak >nul
)
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Creation d'un point de restauration en cours...%COLOR_RESET%
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Cette operation peut prendre 30-60 secondes...%COLOR_RESET%
echo.

reg add "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\SystemRestore" /v "SystemRestorePointCreationFrequency" /t REG_DWORD /d 0 /f >nul 2>&1
for /f "delims=" %%a in ('powershell -NoProfile -Command "Get-Date -Format yyyy-MM-dd_HH-mm-ss"') do set "RP_TIMESTAMP=%%a"
powershell -NoProfile -Command "$ErrorActionPreference = 'Stop'; try { $desc = 'Optimizations_%RP_TIMESTAMP%'; Checkpoint-Computer -Description $desc -RestorePointType 'MODIFY_SETTINGS'; exit 0 } catch { exit 1 }" >nul 2>&1
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

:: Analyse espace initial
for /f %%a in ('powershell -nologo -command "[int]((Get-PSDrive -Name C).Free / 1MB)"') do set "SPACE_BEFORE_MB=%%a"
if not defined SPACE_BEFORE_MB set "SPACE_BEFORE_MB=0"

echo [*] %COLOR_YELLOW%AVERTISSEMENT :%COLOR_RESET%
echo %COLOR_WHITE%  Ce script va supprimer : fichiers temporaires, logs, rapports d'erreurs,%COLOR_RESET%
echo %COLOR_WHITE%  corbeille, caches Windows 11 (Widgets, Copilot, Recall), icones,%COLOR_RESET%
echo %COLOR_WHITE%  notifications et journaux systeme.%COLOR_RESET%
echo %COLOR_WHITE%  %STYLE_BOLD%Aucune donnee personnelle (favoris, mots de passe, documents) n'est touchee.%COLOR_RESET%
echo.
<nul set /p ="%COLOR_YELLOW%Continuer ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_PRINCIPAL

cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% NETTOYAGE AVANCE WINDOWS%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.

:: Initialiser la barre de progression (25 etapes - caches de perf conserves)
set /a "CLEAN_TOTAL=25"
set /a "CLEAN_STEP=0"

:: ETAPE 1 - Fichiers temporaires utilisateur (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires utilisateur"
del /s /q /f "%temp%\*.*" >nul 2>&1
for /d %%d in ("%temp%\*") do rd /s /q "%%d" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Office\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Office\*.tmp" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" del /s /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\setup\*.log" >nul 2>&1

:: ETAPE 2 - Fichiers temporaires Windows (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers temporaires Windows"
del /s /q /f "%SystemRoot%\Temp\*.*" >nul 2>&1
for /d %%d in ("%SystemRoot%\Temp\*") do rd /s /q "%%d" >nul 2>&1
if exist "%SystemRoot%\Servicing\LC\*.tmp" del /s /q /f "%SystemRoot%\Servicing\LC\*.tmp" >nul 2>&1

:: ETAPE 3 - Logs systeme (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs systeme"
del /s /q /f "%SystemRoot%\Logs\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\LogFiles\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Panther\*.log" >nul 2>&1

:: ETAPE 4 - Fichiers de crash / dumps (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Fichiers de crash et dumps"
del /s /q /f "%SystemRoot%\Minidump\*.*" >nul 2>&1
del /q /f "%SystemRoot%\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\memory.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\LiveKernelReports\*.dmp" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\Sysdata\*.dmp" >nul 2>&1
del /s /q /f "%LOCALAPPDATA%\CrashDumps\*.*" >nul 2>&1

:: ETAPE 5 - Rapports d'erreurs et Telemetrie
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Rapports d'erreurs et Telemetrie"
rd /s /q "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
if not exist "%ProgramData%\Microsoft\Windows\WER" md "%ProgramData%\Microsoft\Windows\WER" >nul 2>&1
rd /s /q "%ProgramData%\Microsoft\Diagnosis" >nul 2>&1
if not exist "%ProgramData%\Microsoft\Diagnosis" md "%ProgramData%\Microsoft\Diagnosis" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Windows\WER" rd /s /q "%LOCALAPPDATA%\Microsoft\Windows\WER" >nul 2>&1

:: ETAPE 6 - Cache Windows Update, SoftwareDistribution, Delivery Optimization (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Update et Delivery Optimization"
net stop wuauserv >nul 2>&1
net stop bits >nul 2>&1
net stop cryptsvc >nul 2>&1
net stop dosvc >nul 2>&1
timeout /t 2 /nobreak >nul
rd /s /q "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
rd /s /q "%SystemRoot%\SoftwareDistribution\DataStore" >nul 2>&1
rd /s /q "%SystemRoot%\SoftwareDistribution\PostRebootEventCache" >nul 2>&1
del /s /q /f "%SystemRoot%\SoftwareDistribution\ReportingEvents.log" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\Download" >nul 2>&1
md "%SystemRoot%\SoftwareDistribution\DataStore" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" (
    rd /s /q "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
    md "%ProgramData%\Microsoft\Windows\DeliveryOptimization\Cache" >nul 2>&1
)
net start wuauserv >nul 2>&1
net start bits >nul 2>&1
net start cryptsvc >nul 2>&1
net start dosvc >nul 2>&1

:: ETAPE 7 - Corbeille
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Corbeille"
powershell -NoProfile -Command "Clear-RecycleBin -Force -ErrorAction SilentlyContinue" >nul 2>&1

:: ETAPE 8 - Journaux composants Windows (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux composants Windows"
del /s /q /f "%SystemRoot%\Logs\CBS\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\CBS\*.cab" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.log" >nul 2>&1
del /s /q /f "%SystemRoot%\Logs\DISM\*.cab" >nul 2>&1

:: ETAPE 9 - Cache de polices
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache de polices"
net stop FontCache >nul 2>&1
timeout /t 1 /nobreak >nul
del /s /q /f "%SystemRoot%\ServiceProfiles\LocalService\AppData\Local\FontCache\*.*" >nul 2>&1
del /q /f "%SystemRoot%\System32\FNTCACHE.DAT" >nul 2>&1
net start FontCache >nul 2>&1

:: ETAPE 10 - Cache Windows Store et applications (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Windows Store et applications"
powershell -NoProfile -Command "Get-ChildItem -Path ""$env:LOCALAPPDATA\Packages"" -Directory -ErrorAction SilentlyContinue | Where-Object { $_.Name -notmatch 'Edge|WebView|Microsoft\.Windows' } | ForEach-Object { Remove-Item -Path ""$($_.FullName)\AC\INetCache\*"" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path ""$($_.FullName)\AC\Temp\*"" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item -Path ""$($_.FullName)\LocalState\Cache\*"" -Recurse -Force -ErrorAction SilentlyContinue }" >nul 2>&1
:: wsreset.exe supprime (ouvre UI Store + 5-15s); vidage PS du cache suffit

:: ETAPE 11 - Cache DNS
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache DNS"
ipconfig /flushdns >nul 2>&1

:: ETAPE 12 - Journaux Event Viewer (async - lancement parallele, gain ~1-3min)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Journaux Event Viewer (async)"
powershell -NoProfile -Command "$logs=wevtutil el 2>$null; foreach($l in $logs){ if($l -notmatch '54849625-5478-4994-a5ba-3e3b0328c30d' -and $l -notmatch 'bf022046-1f4a-4b91-8a96-bcdb4d6c39f1'){ Start-Process wevtutil -ArgumentList @('cl', $l) -NoNewWindow -ErrorAction SilentlyContinue } }" >nul 2>&1
ping -n 3 127.0.0.1 >nul 2>&1

:: ETAPE 13 - Windows.old + $SysReset + ~BT (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Anciennes installations Windows"
if exist "%SystemDrive%\Windows.old" (
    echo %COLOR_RED%[ATTENTION]%COLOR_RESET% %COLOR_WHITE%Suppression definitive de Windows.old ^(~15-25 Go^).%COLOR_RESET%
    call :ASK_IF_INTERACTIVE :SUPPR_WINDOWSOLD "Supprimer Windows.old ? [O/N]: "
    if !errorlevel! EQU 0 (
        takeown /f "%SystemDrive%\Windows.old" /r /d y >nul 2>&1
        icacls "%SystemDrive%\Windows.old" /grant administrators:F /t >nul 2>&1
        rd /s /q "%SystemDrive%\Windows.old" >nul 2>&1
    ) else (
        echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Windows.old conserve.%COLOR_RESET%
    )
)
if exist "%SystemDrive%\$SysReset" (
    takeown /f "%SystemDrive%\$SysReset" /r /d y >nul 2>&1
    icacls "%SystemDrive%\$SysReset" /grant administrators:F /t >nul 2>&1
    rd /s /q "%SystemDrive%\$SysReset" >nul 2>&1
)
if exist "%SystemDrive%\$Windows.~BT" rd /s /q "%SystemDrive%\$Windows.~BT" >nul 2>&1
if exist "%SystemDrive%\$Windows.~WS" rd /s /q "%SystemDrive%\$Windows.~WS" >nul 2>&1

:: ETAPE 14 - Optimisation disque (TRIM/Defrag)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation disque (TRIM/Defrag)"
defrag %SystemDrive% /O /H >nul 2>&1

:: ETAPE 15 - Nettoyage Windows Cleanmgr (ameliore - plus de categories 2026)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Nettoyage Windows Cleanmgr"
set "SAGEID=100"
for /f "tokens=*" %%R in ('reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches" /s /f "StateFlags" /d 2^>nul ^| findstr /i "StateFlags"') do (
    reg delete "%%R" /f >nul 2>&1
) 2>nul
for %%K in ("Active Setup Temp Folders" "BranchCache" "Content Indexer Cleaner" "Delivery Optimization Files" "Device Driver Packages" "Diagnostic Data Viewer database files" "Downloaded Program Files" "GameNewsFiles" "GameStatisticsFiles" "GameUpdateFiles" "Language Pack" "Memory Dump Files" "Offline Pages Files" "Old ChkDsk Files" "Previous Installations" "Recycle Bin" "RetailDemo Offline Content" "Service Pack Cleanup" "Setup Log Files" "System error memory dump files" "System error minidump files" "Temporary Files" "Temporary Setup Files" "Temporary Sync Files" "Thumbnail Cache" "Update Cleanup" "Upgrade Discarded Files" "User file versions" "Windows Defender" "Windows Error Reporting Archive Files" "Windows Error Reporting Files" "Windows Error Reporting Queue Files" "Windows Error Reporting System Archive Files" "Windows Error Reporting System Queue Files" "Windows Error Reporting Temp Files" "Windows ESD installation files" "Windows Upgrade Log Files") do (
    reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\%%~K" /v StateFlags%SAGEID% /t REG_DWORD /d 2 /f >nul 2>&1
)
powershell -NoProfile -Command "$p=Get-Process cleanmgr -ErrorAction SilentlyContinue; if(-not $p){ Start-Process -FilePath 'cleanmgr' -ArgumentList '/sagerun:%SAGEID% /d C:' -NoNewWindow -PassThru }" >nul 2>&1
powershell -NoProfile -Command "$waitCount=0; while((Get-Process cleanmgr -ErrorAction SilentlyContinue) -and ($waitCount -lt 120)){ Start-Sleep -s 1; $waitCount++ }" >nul 2>&1

:: ETAPE 16 - Nettoyage composants systeme (via DISM)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Composants systeme (nettoyage)"
powershell -NoProfile -Command "dism /online /Cleanup-Image /StartComponentCleanup /Quiet 2>&1 | Out-Null" >nul 2>&1
:: /SPSuperseded obsolete sur W11 (MS docs), StartComponentCleanup suffit

:: ETAPE 17 - Fichiers temporaires profil systeme (ameliore)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Profil systeme et caches Internet"
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\*.tmp" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\Local\Microsoft\Windows\INetCache\*.*" >nul 2>&1
del /s /q /f "%SystemRoot%\System32\config\systemprofile\AppData\LocalLow\*.tmp" >nul 2>&1

:: ETAPE 18 - Cache d'icones (securise - redemarre l'explorateur)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache d'icones"
taskkill /f /im explorer.exe >nul 2>&1
timeout /t 1 /nobreak >nul
del /q /f "%LOCALAPPDATA%\Microsoft\Windows\Explorer\iconcache_*" >nul 2>&1
del /q /f "%LOCALAPPDATA%\Microsoft\Windows\Explorer\thumbcache_*" >nul 2>&1
start explorer.exe >nul 2>&1

:: ETAPE 19 - Caches Windows 11 : Widgets, Copilot, Recall (nouveau W11 2026)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Widgets, Copilot, Recall"
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AC\INetCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\AC\INetCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.CBS_cw5n1h2txyewy\LocalCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\AC\INetCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\AC\INetCache" >nul 2>&1
if exist "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\LocalCache" rd /s /q "%LOCALAPPDATA%\Packages\MicrosoftWindows.Client.WebExperience_cw5n1h2txyewy\LocalCache" >nul 2>&1
:: Copilot (W11 24H2+)
if exist "%LOCALAPPDATA%\Packages\Microsoft.Windows.Copilot_*\AC\INetCache" for /d %%d in ("%LOCALAPPDATA%\Packages\Microsoft.Windows.Copilot_*") do (
    if exist "%%d\AC\INetCache" rd /s /q "%%d\AC\INetCache" >nul 2>&1
    if exist "%%d\LocalCache" rd /s /q "%%d\LocalCache" >nul 2>&1
)
:: Recall / AI Explorer (W11 2025+) - caches INet temporaires uniquement
if exist "%LOCALAPPDATA%\Packages\Microsoft.Windows.AI.Explorer_*\AC\Temp" for /d %%d in ("%LOCALAPPDATA%\Packages\Microsoft.Windows.AI.Explorer_*") do (
    if exist "%%d\AC\Temp" rd /s /q "%%d\AC\Temp" >nul 2>&1
)
:: Recall snapshots conserves (donnees personnelles)

:: ETAPE 20 - Cache notifications logs (inofensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs notifications"
if exist "%LOCALAPPDATA%\Microsoft\Windows\Notifications" (
    del /s /q /f "%LOCALAPPDATA%\Microsoft\Windows\Notifications\*.log" >nul 2>&1
)

:: ETAPE 21 - Logs et setup OneDrive (inofensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs OneDrive"
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\logs" rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive\logs" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\setup" rd /s /q "%LOCALAPPDATA%\Microsoft\OneDrive\setup" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\OneDrive\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\OneDrive\*.tmp" >nul 2>&1

:: ETAPE 22 - Logs support Windows Defender (inofensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Logs support Defender"
if exist "%ProgramData%\Microsoft\Windows Defender\Support" rd /s /q "%ProgramData%\Microsoft\Windows Defender\Support" >nul 2>&1
if exist "%ProgramData%\Microsoft\Windows Defender\Scans\*.tmp" del /s /q /f "%ProgramData%\Microsoft\Windows Defender\Scans\*.tmp" >nul 2>&1

:: ETAPE 23 - Optimisation indexation Windows Search (compacte uniquement)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Optimisation indexation recherche"
net stop WSearch >nul 2>&1
timeout /t 1 /nobreak >nul
if exist "%ProgramData%\Microsoft\Search\Data\Applications\Windows\*.log" del /s /q /f "%ProgramData%\Microsoft\Search\Data\Applications\Windows\*.log" >nul 2>&1
net start WSearch >nul 2>&1

:: ETAPE 24 - Cache RDP / Bureau a distance (nouveau)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Cache Bureau a distance (RDP)"
if exist "%LOCALAPPDATA%\Microsoft\TerminalServerClient\Cache" rd /s /q "%LOCALAPPDATA%\Microsoft\TerminalServerClient\Cache" >nul 2>&1
if exist "%LOCALAPPDATA%\Microsoft\Remote Desktop Connection Manager\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Remote Desktop Connection Manager\*.tmp" >nul 2>&1

:: ETAPE 25 - Logs et temps Office (inofensif)
set /a "CLEAN_STEP+=1"
call :PROGRESS_BAR %CLEAN_STEP% %CLEAN_TOTAL% "Temporaires Office"
if exist "%LOCALAPPDATA%\Microsoft\Office\*.tmp" del /s /q /f "%LOCALAPPDATA%\Microsoft\Office\*.tmp" >nul 2>&1
if exist "%TEMP%\Microsoft\Office\*.tmp" del /s /q /f "%TEMP%\Microsoft\Office\*.tmp" >nul 2>&1

:: Calcul final (PowerShell pour la precision des decimales)
for /f "tokens=1-3" %%a in ('powershell -NoProfile -Command "$before=[long]%SPACE_BEFORE_MB% * 1024 * 1024; $after=(Get-PSDrive C).Free; $freed=$after-$before; if($freed -lt 0){$freed=0}; $beforeGB=[math]::Round($before/1GB, 2); $afterGB=[math]::Round($after/1GB, 2); $freedGB=[math]::Round($freed/1GB, 2); Write-Output ""$beforeGB $afterGB $freedGB"""') do (
    set "SPACE_BEFORE_GB=%%a"
    set "SPACE_AFTER_GB=%%b"
    set "SPACE_FREED_GB=%%c"
)

set "CLEAN_STEP="
set "CLEAN_TOTAL="

echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %COLOR_GREEN%[TERMINE]%COLOR_RESET% %STYLE_BOLD%%COLOR_WHITE%Nettoyage avance termine%COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo   %COLOR_WHITE%Espace avant :%COLOR_RESET% %COLOR_YELLOW%%SPACE_BEFORE_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace apres :%COLOR_RESET% %COLOR_GREEN%%SPACE_AFTER_GB% Go%COLOR_RESET%
echo   %COLOR_WHITE%Espace gagne :%COLOR_RESET% %COLOR_CYAN%%SPACE_FREED_GB% Go%COLOR_RESET%
echo.
echo %COLOR_YELLOW%[INFO]%COLOR_RESET% %COLOR_WHITE%Un redemarrage est recommande pour finaliser.%COLOR_RESET%
call :PROMPT_MANUAL_REBOOT
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
set /a "VCINSTALLED_COUNT=%VC2015X86%+%VC2015X64%" 2>nul

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
    if "!SKIP_PAUSE!"=="0" (
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
        if !errorlevel! NEQ 0 (
            echo [*] %COLOR_YELLOW%VC++ 2015-2022 x86 : l'installateur a retourne une erreur.%COLOR_RESET%
        )
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
        if !errorlevel! NEQ 0 (
            echo [*] %COLOR_YELLOW%VC++ 2015-2022 x64 : l'installateur a retourne une erreur.%COLOR_RESET%
        )
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
set /a "VCINSTALL=%VC2015X86_NEW%+%VC2015X64_NEW%" 2>nul

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
powershell -NoProfile -Command "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; try { Invoke-WebRequest -Uri 'https://download.microsoft.com/download/8/4/A/84A35BF1-DAFE-4AE8-82AF-AD2AE20B6B14/directx_Jun2010_redist.exe' -OutFile '%DX_TEMP%\directx_redist.exe' -UseBasicParsing } catch { exit 1 }" >nul 2>&1
if !errorlevel! NEQ 0 (
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
<nul set /p ="%COLOR_YELLOW%Voulez-vous supprimer les bloatwares ? [O/N]: %COLOR_RESET%"
call :AZCHOICE ON
if !errorlevel! NEQ 1 goto :MENU_GESTION_WINDOWS

echo.
echo %COLOR_YELLOW%[*]%COLOR_RESET% %COLOR_WHITE%Suppression des applications en cours (PowerShell)...%COLOR_RESET%
powershell -NoProfile -Command "$apps = @('Microsoft.BingNews', 'Microsoft.MicrosoftOfficeHub', 'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.SkypeApp', 'Microsoft.FeedbackHub', 'Microsoft.GetHelp', 'Microsoft.Getstarted', 'Microsoft.OneConnect', 'Microsoft.WindowsMaps', 'Microsoft.MixedReality.Portal', 'Microsoft.People', 'Microsoft.Family', 'Microsoft.YourPhone', 'King.CandyCrushSaga', 'King.CandyCrushSodaSaga', 'Microsoft.QuickAssist'); $prov = Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue; foreach ($app in $apps) { Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue; if ($prov) { $prov | Where-Object {$_.PackageName -match $app} | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue } }" >nul 2>&1
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Suppression des bloatwares terminee.%COLOR_RESET%
pause
goto :MENU_GESTION_WINDOWS

:END_SCRIPT
:: Sans expansion retardee : evite que les "!" dans les textes ([*], AU REVOIR!, etc.) cassent la fin du script
setlocal DisableDelayedExpansion
cls
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo %STYLE_BOLD%%COLOR_WHITE% AU REVOIR! %COLOR_RESET%
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
echo.
echo %COLOR_GREEN%[OK]%COLOR_RESET% %COLOR_WHITE%Merci d'avoir utilise le script d'optimisation! %COLOR_RESET%
echo %COLOR_YELLOW%[!]%COLOR_RESET% %COLOR_YELLOW%N'oubliez pas de redemarrer votre PC pour finaliser l'optimisation.%COLOR_RESET%
echo.
echo %COLOR_CYAN%=================================================================================%COLOR_RESET%
timeout /t 3 /nobreak >nul
:: Ferme le setlocal DisableDelayedExpansion ouvert au debut de :END_SCRIPT
endlocal
:: Ferme le setlocal EnableDelayedExpansion global (ligne 5)
endlocal
exit /b 0






:: =================================================================================
:: HELPERS MATERIEL (NIC / USB) - factorisation des blocs reseaux/energie
:: =================================================================================
:: Parametres : %~1 = PROFIL_POWER (0=MaxPerf, 1=Eco).
::              %~2 = PROFIL_USAGE (0=Gaming, 1=Normal).
:: Gaming+MaxPerf (0,0) : RSC/LSO OFF, ITR 200, EEE/Wake OFF, buffers max.
:: Normal+MaxPerf (0,1) : RSC/LSO ON, ITR defaut, EEE/Wake OFF, buffers max.
:: Eco (1,*) : RSC/LSO/checksum ON, PowerManagement ON, economie pilote conservee.
:: Source unique de verite pour les sections 5.10 et 7.19 (evite la divergence des deux blocs).
:SET_NIC_PROFILE
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $eco=('%~1' -eq '1'); $gaming=('%~2' -eq '0'); function SetP($a,$kw,$vals,$cache){if(-not $cache.ContainsKey($kw)){return}; foreach($v in $vals){try{Set-NetAdapterAdvancedProperty -Name $a -RegistryKeyword $kw -RegistryValue $v -ErrorAction Stop; break}catch{}}}; Get-NetAdapter -Physical -ErrorAction SilentlyContinue | Where-Object {$_.Status -eq 'Up'} | ForEach-Object {$n=$_.Name; $props=@{}; Get-NetAdapterAdvancedProperty -Name $n -ErrorAction SilentlyContinue | ForEach-Object {$props[$_.RegistryKeyword]=$_}; Enable-NetAdapterRss -Name $n -ErrorAction SilentlyContinue; if($eco -or !$gaming){Enable-NetAdapterRsc -Name $n -ErrorAction SilentlyContinue; Enable-NetAdapterLso -Name $n -ErrorAction SilentlyContinue}else{Disable-NetAdapterRsc -Name $n -ErrorAction SilentlyContinue; Disable-NetAdapterLso -Name $n -ErrorAction SilentlyContinue}; SetP $n '*IPChecksumOffloadIPv4' @('3') $props; SetP $n '*TCPChecksumOffloadIPv4' @('3') $props; SetP $n '*TCPChecksumOffloadIPv6' @('3') $props; SetP $n '*UDPChecksumOffloadIPv4' @('3') $props; SetP $n '*UDPChecksumOffloadIPv6' @('3') $props; if($eco){Enable-NetAdapterPowerManagement -Name $n -ErrorAction SilentlyContinue; SetP $n '*WakeOnMagicPacket' @('0') $props; SetP $n '*WakeOnPattern' @('0') $props; SetP $n 'S5WakeOnLan' @('0') $props}else{Disable-NetAdapterPowerManagement -Name $n -ErrorAction SilentlyContinue; SetP $n '*FlowControl' @('0') $props; SetP $n '*GreenGbe' @('0') $props; if($gaming){SetP $n '*RscIPv6' @('0') $props}; SetP $n '*PacketCoalescing' @('0') $props; SetP $n 'EnableExtraPowerSaving' @('0') $props; SetP $n '*EEE' @('0') $props; SetP $n 'AdvancedEEE' @('0') $props; SetP $n 'EnableGreenEthernet' @('0') $props; SetP $n 'PowerSavingMode' @('0') $props; SetP $n 'GigaLite' @('0') $props; SetP $n 'ReduceSpeedOnPowerDown' @('0') $props; if($gaming){try{$desc=$_.InterfaceDescription;$w=Get-WmiObject Win32_NetworkAdapter|?{$_.Name-eq$desc};if($w){$k='{0:0000}'-f[int]$w.DeviceID;$r='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002bE10318}\'+$k;New-ItemProperty -Path $r -Name 'ITR' -PropertyType DWord -Value 200 -Force | Out-Null;New-ItemProperty -Path $r -Name 'TxIntDelay' -PropertyType DWord -Value 0 -Force | Out-Null}}catch{}}; SetP $n '*WakeOnMagicPacket' @('0') $props; SetP $n '*WakeOnPattern' @('0') $props; SetP $n 'S5WakeOnLan' @('0') $props; SetP $n '*ShutdownLinkSpeed' @('0') $props; SetP $n 'S3S4WolLinkSpeed' @('0') $props; SetP $n 'EnableDynamicPowerGating' @('0') $props; SetP $n 'AutoPowerSaveModeEnabled' @('0') $props; SetP $n 'EnableConnectedPowerGating' @('0') $props; SetP $n '*NicAutoPowerSaver' @('0') $props; SetP $n 'TxIntDelay' @('0') $props; if($_.InterfaceDescription -match 'Intel|Wireless|Wi-Fi|802\.11'){SetP $n 'MIMOPowerSaveMode' @('3') $props; SetP $n 'uAPSDSupport' @('0') $props; SetP $n 'FatChannelIntolerant' @('0') $props}; $rxp=$props['*ReceiveBuffers']; if($rxp -and $rxp.NumericParameterMaxValue -gt 0){$v=[math]::Min([int]$rxp.NumericParameterMaxValue,2048).ToString(); try{Set-NetAdapterAdvancedProperty -Name $n -RegistryKeyword '*ReceiveBuffers' -RegistryValue $v -ErrorAction Stop}catch{}}; $txp=$props['*TransmitBuffers']; if($txp -and $txp.NumericParameterMaxValue -gt 0){$v=[math]::Min([int]$txp.NumericParameterMaxValue,2048).ToString(); try{Set-NetAdapterAdvancedProperty -Name $n -RegistryKeyword '*TransmitBuffers' -RegistryValue $v -ErrorAction Stop}catch{}}; foreach($kw in @('PendingReceives','PendingTransmits')){$p=$props[$kw]; if($p -and $p.NumericParameterMaxValue -gt 0){$v=[math]::Min([int]$p.NumericParameterMaxValue,64).ToString(); if($v -ne $p.RegistryValue[0]){try{Set-NetAdapterAdvancedProperty -Name $n -RegistryKeyword $kw -RegistryValue $v -ErrorAction Stop}catch{}}}}}}" >nul 2>&1
exit /b

:: Parametre : %~1 = PROFIL_POWER (0=MaxPerf, 1=Eco).
:: MaxPerf (0) : desactive la gestion d'energie USB (WMI "Autoriser l'arret",
::   USB Selective Suspend, USB 3 LPM, DisableSelectiveSuspend).
:: Eco (1) : sort immediatement (ne touche pas a la gestion d'energie USB).
:: Source unique pour les sections 5.11 et 7.9 (supprime la triple duplication powercfg).
:SET_USB_POWER
if "%~1"=="1" exit /b 0
powershell -NoProfile -Command "$ErrorActionPreference='SilentlyContinue'; $usb=(Get-PNPDevice -Class USB -ErrorAction SilentlyContinue).InstanceId; Get-CimInstance -ClassName MSPower_DeviceEnable -Namespace root\wmi -Filter 'Enable=true' -ErrorAction SilentlyContinue | Where-Object { $_.InstanceName -replace '_0$' -in $usb } | Set-CimInstance -Property @{Enable = $false} -ErrorAction SilentlyContinue" >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 >nul 2>&1
powercfg /setacvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
powercfg /setdcvalueindex SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 d4e98f31-5ffe-4ce1-be31-1b38b384c009 0 >nul 2>&1
reg add "HKLM\SYSTEM\CurrentControlSet\Services\USB" /v DisableSelectiveSuspend /t REG_DWORD /d 1 /f >nul 2>&1
powercfg /setactive SCHEME_CURRENT >nul 2>&1
exit /b 0

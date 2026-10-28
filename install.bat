@echo off
rem Ryu Hayabusa costumes for DARK SOULS REMASTERED - one installer for every costume, with or without Ryu's voice.
rem Pick a costume (or uninstall) from the menu. Switching costume = just run it again and pick another one.
rem Before the first install, every game file it replaces is copied to <game>\RyuHayabusa_backup\; uninstall puts
rem them back. Also removes the older one-costume-per-zip versions (RyuNG4 / RyuNG4Black / RyuTrueFighter) if found.
rem Command line (optional): install.bat ["<game folder>" [1^|2^|3 [Y^|N]]]     install.bat uninstall ["<game folder>"]
setlocal EnableExtensions EnableDelayedExpansion
title Ryu Hayabusa costumes for DARK SOULS REMASTERED
set "HERE=%~dp0"
set "DATA=%HERE%data"
set "BKN=RyuHayabusa_backup"
set "MODE=install"
if /i "%~1"=="uninstall" (
  set "MODE=uninstall"
  shift
)
echo.
echo  ======================================================
echo   Ryu Hayabusa costumes for DARK SOULS REMASTERED
echo  ======================================================
echo.
if not exist "%DATA%\targets.txt" (
  echo ERROR: the data folder is missing. Extract the whole zip first, then run install.bat from it.
  goto :fail
)

rem ---------------------------------------------------------------- find the game
set "GAME=%~1"
set "ARG_C=%~2"
set "ARG_V=%~3"
if defined GAME goto :check
set N=0
set "SP="
for /f "tokens=2,*" %%a in ('reg query "HKCU\Software\Valve\Steam" /v SteamPath 2^>nul ^| findstr /i "SteamPath"') do set "SP=%%b"
if defined SP (
  set "SP=!SP:/=\!"
  call :cand "!SP!"
  if exist "!SP!\steamapps\libraryfolders.vdf" (
    for /f "usebackq tokens=1,*" %%a in (`findstr /c:"\"path\"" "!SP!\steamapps\libraryfolders.vdf"`) do (
      set "L=%%~b"
      set "L=!L:\\=\!"
      call :cand "!L!"
    )
  )
)
for %%d in (C D E F G H I J K L M N O P Q R S T U V W X Y Z) do (
  if exist "%%d:\" (
    call :cand "%%d:\SteamLibrary"
    call :cand "%%d:\Steam"
    call :cand "%%d:\Program Files (x86)\Steam"
    call :cand "%%d:\Program Files\Steam"
  )
)
if !N!==0 goto :askgame
if !N!==1 (
  set "GAME=!C1!"
  goto :check
)
echo DARK SOULS REMASTERED found in more than one place:
for /l %%i in (1,1,!N!) do echo   [%%i] !C%%i!
echo   [0] type another folder
set "PICK="
set /p "PICK=Which one? (Enter = 1): "
if not defined PICK set PICK=1
if "!PICK!"=="0" goto :askgame
if not defined C!PICK! (
  echo That is not one of the choices.
  goto :fail
)
set "GAME=!C%PICK%!"
goto :check

:askgame
echo Could not find DARK SOULS REMASTERED automatically.
echo Type or paste the game folder ^(the one with DarkSoulsRemastered.exe^):
set "GAME="
set /p "GAME=Folder: "
if not defined GAME goto :fail
set GAME=!GAME:"=!
if not defined GAME goto :fail

:check
if "!GAME:~-1!"=="\" set "GAME=!GAME:~0,-1!"
if not exist "!GAME!\DarkSoulsRemastered.exe" (
  echo ERROR: DarkSoulsRemastered.exe is not in "!GAME!".
  goto :fail
)
if not exist "!GAME!\parts\" (
  echo ERROR: "!GAME!" has no parts folder - is this really the game folder?
  goto :fail
)
set "BK=!GAME!\%BKN%"
echo Game folder: !GAME!
set "CUR="
if exist "!BK!\installed.txt" set /p CUR=<"!BK!\installed.txt"
if defined CUR echo Installed now: !CUR!
echo.
if "%MODE%"=="uninstall" goto :uninstall

rem ---------------------------------------------------------------- menu
set "C=!ARG_C!"
if defined C goto :havec
echo Pick a costume ^(pictures of each one are in the Reference folder^):
echo   [1] Ryu Hayabusa - Ninja Gaiden 4
echo   [2] Ryu Hayabusa - Ninja Gaiden 4, black
echo   [3] Ryu Hayabusa - True Fighter ^(Ninja Gaiden 3: Razor's Edge^)
echo   [U] Uninstall - put the original Dark Souls files back
echo   [Q] Quit
set /p "C=Your choice: "
if not defined C goto :quit
:havec
set "KEY="
set "VOICE="
if /i "!C!"=="Q" goto :quit
if /i "!C!"=="U" goto :uninstall
if "!C!"=="1" (set "KEY=NG4" & set "LABEL=Ninja Gaiden 4")
if "!C!"=="2" (set "KEY=NG4Black" & set "LABEL=Ninja Gaiden 4, black")
if "!C!"=="3" (set "KEY=TrueFighter" & set "LABEL=True Fighter")
if not defined KEY (
  echo That is not one of the choices.
  goto :fail
)
set "V=!ARG_V!"
if defined V goto :havev
echo.
echo Ryu's voice: replaces the player character's voice ^(grunts, shouts, death cries^) with Ryu's.
set /p "V=Use Ryu's voice? [Y/N] (Enter = Y): "
if not defined V set V=Y
:havev
if /i "!V!"=="Y" (set "VOICE=1" & set "LABEL=!LABEL!, Ryu's voice") else if /i "!V!"=="N" (set "VOICE=0" & set "LABEL=!LABEL!, original voice") else (
  echo Please answer Y or N.
  goto :fail
)
echo.
echo Installing: Ryu Hayabusa - !LABEL!
call :ensure_closed || goto :fail
call :remove_old || goto :fail

rem ---------------------------------------------------------------- back up the originals (once)
if exist "!BK!\" if not exist "!BK!\backup_ok.txt" (
  rem an earlier backup was interrupted before any game file was changed -> start it again
  rd /s /q "!BK!"
)
if not exist "!BK!\" (
  echo Backing up the original game files to %BKN% ...
  mkdir "!BK!" || goto :writefail
  type nul > "!BK!\missing.txt"
  for /f "usebackq delims=" %%t in ("%DATA%\targets.txt") do (
    if exist "!GAME!\%%t" (
      call :copyv "!GAME!\%%t" "!BK!\%%t" || goto :writefail
    ) else (
      echo %%t>>"!BK!\missing.txt"
    )
  )
  echo ok> "!BK!\backup_ok.txt"
)

rem ---------------------------------------------------------------- copy the costume
set FAILS=0
for /f "usebackq delims=" %%t in ("%DATA%\targets.txt") do call :place "%%t"
if not !FAILS!==0 (
  echo.
  echo ERROR: !FAILS! file^(s^) could not be written. Close the game and run install.bat again,
  echo or pick [U] to put the original files back.
  goto :fail
)
>"!BK!\installed.txt" echo Ryu Hayabusa - !LABEL!
echo.
echo  Done: Ryu Hayabusa - !LABEL!
echo  Start the game and load a save. Run install.bat again to switch costume or to uninstall.
echo.
goto :done

rem ---------------------------------------------------------------- uninstall
:uninstall
call :ensure_closed || goto :fail
set DID=0
call :remove_old || goto :fail
if exist "!BK!\backup_ok.txt" (
  echo Putting the original game files back ...
  set FAILS=0
  for /f "usebackq delims=" %%t in ("%DATA%\targets.txt") do (
    if exist "!BK!\%%t" call :copyv "!BK!\%%t" "!GAME!\%%t" || set /a FAILS+=1
  )
  for /f "usebackq delims=" %%t in ("!BK!\missing.txt") do if exist "!GAME!\%%t" del /q "!GAME!\%%t"
  if not !FAILS!==0 (
    echo ERROR: !FAILS! file^(s^) could not be restored. Your originals are still in !BK!
    echo Close the game and run the uninstall again.
    goto :fail
  )
  rd /s /q "!BK!"
  set DID=1
) else if exist "!BK!\" (
  rd /s /q "!BK!"
)
echo.
if !DID!==1 (echo  Uninstalled: the original Dark Souls files are back.) else (echo  No Ryu costume was installed. Nothing to do.)
echo.
goto :done

rem ================================================================ helpers
:place
set "T=%~1"
set "SRC="
if /i "!T:~0,6!"=="parts\" set "SRC=%DATA%\!KEY!\!T!"
if /i "!T:~0,6!"=="param\" set "SRC=%DATA%\common\!T!"
if /i "!T:~0,6!"=="sound\" (
  if "!VOICE!"=="1" (set "SRC=%DATA%\voice\!T!") else (set "SRC=!BK!\!T!")
)
if not exist "!SRC!" (
  rem original voice requested but the game had no such file -> make sure ours is gone
  if /i "!T:~0,6!"=="sound\" (
    if exist "!GAME!\!T!" del /q "!GAME!\!T!"
    exit /b 0
  )
  echo   missing in the package: !T!
  set /a FAILS+=1
  exit /b 0
)
call :copyv "!SRC!" "!GAME!\!T!" || set /a FAILS+=1
exit /b 0

:copyv
set "CA=%~1"
set "CB=%~2"
for %%D in ("!CB!") do if not exist "%%~dpD" mkdir "%%~dpD" 2>nul
copy /y "!CA!" "!CB!" >nul 2>&1 || (
  echo   could not write !CB!
  exit /b 1
)
fc /b "!CA!" "!CB!" >nul 2>&1 || (
  echo   verify failed: !CB!
  exit /b 1
)
exit /b 0

:remove_old
rem the older single-costume installers kept their originals in <game>\Ryu*_backup\ with a MANIFEST.sha256
for %%o in (RyuNG4_backup RyuNG4Black_backup RyuTrueFighter_backup) do (
  if exist "!GAME!\%%o\MANIFEST.sha256" (
    echo Removing an older version of the costume ^(%%o^) ...
    set OF=0
    for /f "usebackq tokens=1,2" %%a in ("!GAME!\%%o\MANIFEST.sha256") do call :old_one "%%o" "%%a" "%%b"
    if not !OF!==0 (
      echo ERROR: could not restore !OF! file^(s^) from %%o. Close the game and try again.
      exit /b 1
    )
    rd /s /q "!GAME!\%%o"
    set DID=1
  )
)
exit /b 0

:old_one
set "R=%~3"
set "R=!R:/=\!"
if /i "%~2"=="missing" (
  if exist "!GAME!\!R!" del /q "!GAME!\!R!"
  exit /b 0
)
call :copyv "!GAME!\%~1\!R!" "!GAME!\!R!" || set /a OF+=1
exit /b 0

:ensure_closed
tasklist /fi "imagename eq DarkSoulsRemastered.exe" 2>nul | find /i "DarkSoulsRemastered.exe" >nul && (
  echo ERROR: DARK SOULS REMASTERED is running. Close the game first.
  exit /b 1
)
exit /b 0

:cand
set "P=%~1\steamapps\common\DARK SOULS REMASTERED"
if not exist "!P!\DarkSoulsRemastered.exe" exit /b 0
for /l %%i in (1,1,!N!) do if /i "!C%%i!"=="!P!" exit /b 0
set /a N+=1
set "C!N!=!P!"
exit /b 0

:writefail
echo.
echo ERROR: could not write into the game folder. Close the game and try again
echo ^(if the game is under Program Files, right-click install.bat - Run as administrator^).
echo No game file was changed yet.
if exist "!BK!\" if not exist "!BK!\backup_ok.txt" rd /s /q "!BK!"
goto :fail

:quit
echo Nothing was changed.
goto :done

:fail
echo.
pause
exit /b 1

:done
pause
exit /b 0

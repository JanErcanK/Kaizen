@echo off
setlocal enableextensions

for %%I in ("%~dp0.") do set "PROJ_SHORT=%%~sI"

if not exist "%~dp0android\key.properties" (
  echo ERROR: android\key.properties is missing.
  echo Restore the upload keystore used for the first Play Store release.
  echo Do not create a different key unless Google approved an upload-key reset.
  exit /b 2
)

for /d %%J in ("%~dp0.jdk17\jdk-*") do (
  if exist "%%~fJ\bin\java.exe" (
    set "JAVA_HOME=%%~fJ"
    set "PATH=%%~fJ\bin;%PATH%"
  )
)

if defined FLUTTER_HOME (
  for %%I in ("%FLUTTER_HOME%") do set "FLUTTER_BAT=%%~sI\bin\flutter.bat"
) else if defined FLUTTER_ROOT (
  for %%I in ("%FLUTTER_ROOT%") do set "FLUTTER_BAT=%%~sI\bin\flutter.bat"
) else if exist "%USERPROFILE%\Desktop\flutter\bin\flutter.bat" (
  for %%I in ("%USERPROFILE%\Desktop\flutter") do set "FLUTTER_BAT=%%~sI\bin\flutter.bat"
) else (
  set "FLUTTER_BAT=flutter"
)

pushd "%PROJ_SHORT%" >nul
echo Using project: %CD%
echo Using flutter:  %FLUTTER_BAT%
echo.

if exist "build\app\outputs\bundle\release\app-release.aab" (
  del /q "build\app\outputs\bundle\release\app-release.aab"
)

set "KAIZEN_DEFINES="
if exist "config\local.defines.json" set "KAIZEN_DEFINES=--dart-define-from-file=config/local.defines.json"

call %FLUTTER_BAT% build appbundle --release %KAIZEN_DEFINES%
set "EXIT_CODE=%ERRORLEVEL%"
if "%EXIT_CODE%"=="0" (
  if not exist "build\app\outputs\bundle\release\app-release.aab" (
    echo ERROR: Flutter reported success, but no app bundle was found.
    set "EXIT_CODE=3"
  )
)
popd >nul

exit /b %EXIT_CODE%

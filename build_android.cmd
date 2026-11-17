@echo off
setlocal enableextensions

rem NuGet CLI (needed by flutter_tts on Windows). WinGet installs links here.
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\nuget.exe" (
  set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
)

rem Build Android APK using 8.3 short paths.
rem This avoids failures in some native-asset hooks when paths contain spaces
rem (e.g. "C:\Users\Jan Kilic\...").

rem Resolve project root (this file's directory) as short path.
for %%I in ("%~dp0.") do set "PROJ_SHORT=%%~sI"

rem Prefer FLUTTER_HOME/FLUTTER_ROOT if set.
rem Else, prefer a Flutter SDK at "%USERPROFILE%\Desktop\flutter" (common setup).
rem Else, fall back to whatever is on PATH.
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

set "KAIZEN_DEFINES="
if exist "config\local.defines.json" set "KAIZEN_DEFINES=--dart-define-from-file=config/local.defines.json"

call %FLUTTER_BAT% build apk --release %KAIZEN_DEFINES%
set "EXIT_CODE=%ERRORLEVEL%"
popd >nul

exit /b %EXIT_CODE%


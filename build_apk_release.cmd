@echo off
setlocal enableextensions

rem Release APK build using 8.3 short paths only (no SUBST).
rem Avoids:
rem   - native-asset hook failures when paths contain spaces ("Jan Kilic")
rem   - Kotlin incremental compile failures when project and pub cache use different drive letters

rem Drop stale SUBST / env overrides from earlier attempts.
subst P: /D >nul 2>&1
subst X: /D >nul 2>&1
subst F: /D >nul 2>&1
set "PUB_CACHE="
set "FLUTTER_ROOT="
set "FLUTTER_HOME="

for %%I in ("%~dp0.") do set "PROJ_SHORT=%%~sI"

if exist "%USERPROFILE%\Desktop\flutter\bin\flutter.bat" (
  for %%I in ("%USERPROFILE%\Desktop\flutter") do set "FLUTTER_BAT=%%~sI\bin\flutter.bat"
) else if defined FLUTTER_HOME (
  for %%I in ("%FLUTTER_HOME%") do set "FLUTTER_BAT=%%~sI\bin\flutter.bat"
) else if defined FLUTTER_ROOT (
  for %%I in ("%FLUTTER_ROOT%") do set "FLUTTER_BAT=%%~sI\bin\flutter.bat"
) else (
  set "FLUTTER_BAT=flutter"
)

rem Note: use cd /d, not pushd -- pushd causes flutter.bat's git-clone
rem detection to fail with "The Flutter directory is not a clone of the
rem GitHub project" when this script is invoked via `cmd /c`.
set "ORIG_DIR=%CD%"
cd /d "%PROJ_SHORT%"
echo Using project: %CD%
echo Using flutter:  %FLUTTER_BAT%
echo.

rem Note: FLUTTER_BAT is deliberately unquoted below. It is either the bare
rem word "flutter" (resolved via PATH) or an 8.3 short path (never contains
rem spaces). Quoting it breaks flutter.bat's own %~dp0 self-resolution when
rem invoked via PATH lookup, making it treat this project's cwd as the
rem Flutter SDK root and fail with the same "not a clone" error as above.
call %FLUTTER_BAT% clean
if errorlevel 1 goto :fail

call %FLUTTER_BAT% pub get
if errorlevel 1 goto :fail

set "KAIZEN_DEFINES="
if exist "config\local.defines.json" set "KAIZEN_DEFINES=--dart-define-from-file=config/local.defines.json"

call %FLUTTER_BAT% build apk --release %KAIZEN_DEFINES%
set "EXIT_CODE=%ERRORLEVEL%"
cd /d "%ORIG_DIR%"
exit /b %EXIT_CODE%

:fail
set "EXIT_CODE=1"
cd /d "%ORIG_DIR%" 2>nul
exit /b %EXIT_CODE%

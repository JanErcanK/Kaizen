@echo off
setlocal enableextensions

rem NuGet CLI (needed by flutter_tts on Windows). WinGet installs links here.
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\nuget.exe" (
  set "PATH=%LOCALAPPDATA%\Microsoft\WinGet\Links;%PATH%"
)

rem Run Flutter Windows build using 8.3 short paths.
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

rem Note: use cd /d, not pushd -- pushd causes flutter.bat's git-clone
rem detection to fail with "The Flutter directory is not a clone of the
rem GitHub project" when this script is invoked via `cmd /c`.
set "ORIG_DIR=%CD%"
cd /d "%PROJ_SHORT%"
echo Using project: %CD%
echo Using flutter:  %FLUTTER_BAT%
echo.

rem Note: deliberately unquoted. FLUTTER_BAT is either the bare word
rem "flutter" (resolved via PATH) or an 8.3 short path (never contains
rem spaces). Quoting it here breaks flutter.bat's own %~dp0
rem self-resolution when invoked via PATH lookup, making it treat the
rem caller's cwd (this git repo) as the Flutter SDK root and fail with
rem "The Flutter directory is not a clone of the GitHub project."
call %FLUTTER_BAT% clean
if errorlevel 1 goto :fail

call %FLUTTER_BAT% pub get
if errorlevel 1 goto :fail

set "KAIZEN_DEFINES="
if exist "config\local.defines.json" set "KAIZEN_DEFINES=--dart-define-from-file=config/local.defines.json"

call %FLUTTER_BAT% run -d windows %KAIZEN_DEFINES%
set "EXIT_CODE=%ERRORLEVEL%"
cd /d "%ORIG_DIR%"

exit /b %EXIT_CODE%

:fail
set "EXIT_CODE=1"
cd /d "%ORIG_DIR%" 2>nul
exit /b %EXIT_CODE%


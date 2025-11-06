@echo off
echo ========================================
echo   ReXplore Admin Panel Launcher
echo ========================================
echo.
echo Starting Flutter Web Admin Panel...
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

REM Check if Chrome is available
where chrome >nul 2>nul
if %errorlevel% neq 0 (
    echo WARNING: Chrome not found in PATH
    echo Will try to launch with default browser
    echo.
)

echo Flutter found!
echo.
echo Opening admin panel in Chrome...
echo.
echo TIP: Bookmark the URL that opens for quick access!
echo.

REM Run the admin panel
flutter run -d chrome --target=lib/admin/main_admin.dart

echo.
echo ========================================
echo Admin panel closed
echo ========================================
pause

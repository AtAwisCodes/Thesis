@echo off
echo ========================================
echo   ReXplore Admin Panel Builder
echo ========================================
echo.
echo Building Flutter Web Admin Panel for production...
echo.

REM Check if Flutter is installed
where flutter >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Flutter is not installed or not in PATH
    echo Please install Flutter: https://flutter.dev/docs/get-started/install
    pause
    exit /b 1
)

echo Flutter found!
echo.
echo Starting build process...
echo This may take a few minutes...
echo.

REM Build the admin panel
flutter build web --target=lib/admin/main_admin.dart --release

if %errorlevel% equ 0 (
    echo.
    echo ========================================
    echo Build successful!
    echo ========================================
    echo.
    echo Output location: build\web
    echo.
    echo Next steps:
    echo 1. Test locally: flutter run -d chrome --target=lib/admin/main_admin.dart
    echo 2. Deploy to hosting: firebase deploy --only hosting
    echo 3. Or upload build\web folder to any web server
    echo.
) else (
    echo.
    echo ========================================
    echo Build failed!
    echo ========================================
    echo.
    echo Please check the error messages above
    echo.
)

pause

@echo off
echo ====================================
echo Generating App Icons from logo.png
echo ====================================
echo.

echo Step 1: Getting dependencies...
call flutter pub get
echo.

echo Step 2: Generating launcher icons...
call dart run flutter_launcher_icons
echo.

echo ====================================
echo Done! App icons have been generated.
echo ====================================
echo.
echo The logo.png has been set as your app icon for:
echo - Android (all densities)
echo - iOS
echo.
echo You can now build and run your app to see the new icon.
echo.
pause

@echo off
echo ========================================
echo Starting Meshy AI Backend Server
echo ========================================
echo.
cd /d "%~dp0"
echo Current directory: %CD%
echo.
echo Installing/Checking dependencies...
pip install flask flask-cors requests google-cloud-firestore python-dotenv
echo.
echo ========================================
echo Starting Flask Server...
echo ========================================
echo.
echo Backend will run at: http://localhost:5000
echo Press Ctrl+C to stop the server
echo.
python app.py
pause

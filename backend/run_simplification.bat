@echo off
REM Quick Simplification Script
REM This automatically runs the simplification with Standard settings

echo ====================================
echo  SIMPLIFYING MESHY MODEL
echo ====================================
echo.
echo Input:  input\meshy_original.glb (5.93 MB)
echo Output: output\meshy_original_optimized.glb
echo Settings: 10,000 polygons, 1024x1024 textures
echo.
echo This will take about 30-60 seconds...
echo.

"C:\Program Files\Blender Foundation\Blender 4.5\blender.exe" --background --python simplify_meshy_glb.py -- "input\meshy_original.glb" "output\meshy_original_optimized.glb" 10000 1024

echo.
echo ====================================
echo  DONE!
echo ====================================
echo.
echo Check output folder for: meshy_original_optimized.glb
echo.
pause

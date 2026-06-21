@echo off
setlocal enabledelayedexpansion

echo ============================================
echo   Cosign Extension Build Script
echo ============================================
echo.

REM Check if tfx-cli is installed
where tfx >nul 2>&1
if %errorlevel% neq 0 (
    echo Error: tfx-cli is not installed
    echo Install it with: npm install -g tfx-cli
    exit /b 1
)

echo [√] tfx-cli is installed
echo.

REM Clean old builds
echo Cleaning old builds...
if exist *.vsix del /q *.vsix
echo [√] Cleaned
echo.

REM Create extension
echo Creating extension package...
call tfx extension create --manifest-globs vss-extension.json

if %errorlevel% neq 0 (
    echo [×] Failed to create extension package
    exit /b 1
)

REM Find the created vsix file
for /f "delims=" %%f in ('dir /b /o-d *.vsix 2^>nul') do (
    set "VSIX_FILE=%%f"
    goto :found
)

:found
if not defined VSIX_FILE (
    echo [×] Extension file not found
    exit /b 1
)

echo [√] Extension packaged successfully
echo.
echo ============================================
echo   Build Complete
echo ============================================
echo.
echo Extension file: %VSIX_FILE%
echo.
echo Next steps:
echo 1. Upload to Azure DevOps:
echo    - Go to Organization/Collection Settings
echo    - Navigate to Extensions
echo    - Click 'Upload new extension'
echo    - Select: %VSIX_FILE%
echo.
echo 2. Or use API:
echo    tfx extension publish --vsix %VSIX_FILE% --service-url ^<your-url^> --token ^<pat^>
echo.

endlocal

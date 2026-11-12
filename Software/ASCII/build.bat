@echo off
setlocal

set IMAGE_INPUT=input.png

if not exist "%IMAGE_INPUT%" (
    echo Error: %IMAGE_INPUT% not found! Drop an image named input.png into this folder.
    exit /b 1
)

echo [1/2] Converting image to ASCII and writing main.c...
python generate_ascii.py %IMAGE_INPUT% 95
if errorlevel 1 (
    echo Python generation failed!
    exit /b 1
)

echo [2/2] Compiling binary with cc65...
cl65 -t none -O -C linker.cfg -o program.bin crt0.s main.c
if errorlevel 1 (
    echo Compilation failed!
    exit /b 1
)

echo.
echo ========================================
echo  Build complete! Generated: program.bin
echo ========================================
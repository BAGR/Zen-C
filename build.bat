@echo off
setlocal enabledelayedexpansion

rem Compiler configuration (default to gcc)
if "%CC%"=="" set CC=gcc

rem Version
set ZEN_VERSION=0.1.0
for /f "delims=" %%i in ('git describe --tags --always --dirty 2^>nul') do set ZEN_VERSION=%%i

rem Compilation flags
set CFLAGS=-std=gnu11 -Wall -Wextra -Wshadow -Wformat=2 -Wmissing-prototypes ^
 -Wstrict-prototypes -Wnull-dereference -Wundef -Wfloat-equal ^
 -Wmissing-field-initializers -Wsign-compare -Wtype-limits -Wuninitialized ^
 -Wdouble-promotion -Wtautological-compare -Wshift-negative-value ^
 -Wdangling-else -Wreturn-local-addr ^
 -Wduplicated-cond -Wlogical-op -g ^
 -I./src -I./src/ast -I./src/parser -I./src/codegen -I./plugins -I./src/zen ^
 -I./src/utils -I./src/lexer -I./src/analysis -I./src/lsp -I./src/diagnostics ^
 -I./std/third-party/tre/include
set CFLAGS=%CFLAGS% -DZEN_VERSION=\"%ZEN_VERSION%\" -DZEN_SHARE_DIR=\".\" -DZC_ALLOW_INTERNAL

if "%ZC_HAS_JIT%"=="" set ZC_HAS_JIT=1
if "%ZC_HAS_JIT%"=="1" (
    set CFLAGS=%CFLAGS% -DZC_HAS_JIT
    set LIBS=-lws2_32 -ltcc
) else (
    set LIBS=-lws2_32
)

if "%NO_PLUGINS%"=="1" (
    set CFLAGS=%CFLAGS% -DZC_NO_PLUGINS
)

rem Source files — read from src-sources.txt (single source of truth)
set SRCS=
for /f "usebackq delims=" %%i in ("src-sources.txt") do (
    if not "%%i"=="" set "SRCS=!SRCS! %%i"
)

rem Build
echo Building Zen C (%ZEN_VERSION%)...
%CC% %CFLAGS% %SRCS% -o zc.exe %LIBS%
if %ERRORLEVEL% NEQ 0 (
    echo Build failed!
    exit /b %ERRORLEVEL%
)

echo Build success! zc.exe created.

rem Build plugins
if "%NO_PLUGINS%"=="1" (
    echo Plugins disabled by NO_PLUGINS flag.
    goto end
)
echo Building plugins...
if not exist plugins mkdir plugins
for %%f in (plugins\*.zc) do (
    echo Compiling native plugin %%f...
    .\zc.exe build %%f -shared -o %%~dpnf.dll
    if errorlevel 1 (
        echo Plugin build failed for %%f
        exit /b 1
    )
)

:end

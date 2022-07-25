@echo off
echo Running all tests in %cd%
set KICK=java -cp ..\build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node ..\build\aseparse65\png65.js

rem WHERE node.exe >nul
rem IF %ERRORLEVEL% NEQ 0 (
rem     echo NodeJS is not installed please install from https://nodejs.org/en/
rem     exit /B 1   
rem ) else (
rem     echo Found NodeJS...
rem )
rem cd ..\build\aseparse65
rem call npm install >nul
rem cd ..\..
rem cd build\m65debugger
rem call npm install >nul
rem cd ..\..


for %%i in (%cd%\*.s) do (
    echo %%~ni
    
    echo ASSEMBLING SOURCES...
    %KICK% %%~ni.s -libdir ..\ -odir bin

    echo TEST %%~ni DEPLOYING...
    node ..\build\m65debugger\client.js bin\main.prg

    pause
)

@echo off
set KICK=java -cp build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node build\aseparse65\png65.js


WHERE node.exe >nul
IF %ERRORLEVEL% NEQ 0 (
    echo NodeJS is not installed please install from https://nodejs.org/en/
    exit /B 1   
) else (
    echo Found NodeJS...
)
cd build\aseparse65
call npm install >nul
cd ..\..
cd build\m65debugger
call npm install >nul
cd ..\..


for %%i in (%cd%\includes\s65\tests\*.s) do (
    echo %%~ni
    

    rem MAKE SURE NODE IS INSTALLED

    echo ASSEMBLING SOURCES...
    %KICK% includes\s65\tests\%%~ni.s -odir bin

    echo TEST %%~ni DEPLOYING...
    node build\m65debugger\client.js includes\s65\tests\bin\%%~ni.prg

    pause
)

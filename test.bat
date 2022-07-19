@echo off
set KICK=java -cp build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node build\aseparse65\png65.js

for %%i in (%cd%\includes\s65\tests\*.s) do (
    echo %%~ni
    

    rem MAKE SURE NODE IS INSTALLED

    echo ASSEMBLING SOURCES...
    %KICK% includes\s65\tests\%%~ni.s -odir bin

    echo TEST %%~ni DEPLOYING...
    node Z:\Projects\JS\M65Debugger\client.js includes\s65\tests\bin\%%~ni.prg

    pause
)

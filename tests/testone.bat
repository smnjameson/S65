@echo off
set KICK=java -cp ..\build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node ..\build\aseparse65\png65.js

echo ASSEMBLING SOURCES...
%KICK% %1.s -libdir ..\ -odir bin

echo TEST %1 DEPLOYING...
node ..\build\m65debugger\client.js bin\%1.prg



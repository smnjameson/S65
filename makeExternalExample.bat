rem This file is an example of how to build from another folder external to S65
rem Change the variable S65PATH to point to the S65 folder
@echo off
set S65PATH=../S65
set KICK=java -cp %S65PATH%/build/kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node %S65PATH%/build/aseparse65/png65.js
set DEPLOY=node %S65PATH%/build/m65debugger/client.js



echo GENERATING ASSETS
%PNG65% chars --fcm --input "assets/source/tileset1.png" --output "assets/bin"

echo ASSEMBLING SOURCES...
%KICK% main.s -odir ./bin -libdir %S65PATH%

echo DEPLOYING...
%DEPLOY% ./bin/main.prg
rem "C:/Program Files/xemu/xmega65.exe" -besure  -prg "./bin/main.prg"
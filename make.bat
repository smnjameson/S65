@echo off

set KICKASM=java -cp Z:\Projects\Mega65\_build_utils\kickass.jar kickass.KickAssembler65CE02  -vicesymbols -showmem 
rem set ASP65="node ./_include/aseparse65/asp65 parse -i "

echo ASSEMBLING SOURCES...
%KICKASM%  main.s -odir ./bin

echo GENERATING DOCS
node build/gendocs ./includes/S65/S65.s ./docs

echo DEPLOYING...
node Z:\Projects\JS\M65Debugger\client.js ./bin/main.prg
rem "C:\Program Files\xemu\xmega65.exe" -besure -prg ./bin/main.prg
 


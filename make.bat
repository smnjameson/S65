@echo off

set KICKASM=java -cp Z:\Projects\Mega65\_build_utils\kickass.jar kickass.KickAssembler65CE02  -vicesymbols -showmem 
set SUBLIME_PACKAGES="%APPDATA%\Sublime Text\Packages\User"

echo ASSEMBLING SOURCES...
%KICKASM%  main.s -odir ./bin

echo GENERATING DOCS
node build/gendocs ./includes/S65/S65.s ./docs
copy .\docs\S65*.* %SUBLIME_PACKAGES%


echo DEPLOYING...
node Z:\Projects\JS\M65Debugger\client.js ./bin/main.prg

 


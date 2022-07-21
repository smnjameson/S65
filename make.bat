@echo off
rem MAKE SURE NODE IS INSTALLED
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

echo GENERATING DOCS
set SUBLIME_PACKAGES="%APPDATA%\Sublime Text\Packages\User"
node build/gendocs ./includes/S65/start.s ./docs
copy .\docs\S65*.* %SUBLIME_PACKAGES%
set KICK=java -cp build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node build\aseparse65\png65.js


echo GENERATING ASSETS
%PNG65% chars --ncm --input "assets\source\test4.png" --output "assets\bin"

echo ASSEMBLING SOURCES...
%KICK% main.s -odir ./bin

echo DEPLOYING...
node build\m65debugger\client.js ./bin/main.prg



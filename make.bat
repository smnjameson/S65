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

rem echo GENERATING DOCS
rem set SUBLIME_PACKAGES="%APPDATA%\Sublime Text\Packages\User"
rem node build/gendocs ./includes/S65/start.s ./docs

copy .\docs\S65*.* %SUBLIME_PACKAGES%
set KICK=java -cp build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node build\aseparse65\png65.js


rem echo GENERATING ASSETS
rem NOT USED in the hello world, but left here for examples
rem %PNG65% chars --fcm --input "assets\source\test5.png" --output "tests\assets\bin"
rem %PNG65% chars --ncm --input "assets\source\test4.png" --output "tests\assets\bin"

echo ASSEMBLING SOURCES...
%KICK% main.s -odir ./bin

echo DEPLOYING...
rem Launch on HW using M65Debugger
node build\m65debugger\client.js ./bin/main.prg

rem Launch on Xemu 
rem "C:\Program Files\xemu\xmega65.exe" -besure  -prg "./bin/main.prg"
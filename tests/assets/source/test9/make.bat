@echo off
rem Set this to match you COM port in Debugger
set SERIAL=COM6
rem Your path to the S65 Library
set S65PATH=..\S65

set KICK=java -cp %S65PATH%\build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node %S65PATH%\build\aseparse65\png65.js
set LDTK65=node %S65PATH%\build\ldtk65\ldtk65.js
set DEPLOY=node %S65PATH%\build\m65debugger\client.js
set CDIR=%cd%


echo GENERATING DOCS
set SUBLIME_PACKAGES="%APPDATA%\Sublime Text\Packages"
mkdir %SUBLIME_PACKAGES%\S65
cd %S65PATH%
node build\gendocs includes\S65\start.s docs
copy docs\S65*.* %SUBLIME_PACKAGES%\User
copy docs\Default.sublime-keymap %SUBLIME_PACKAGES%\S65
cd %CDIR%

rem Do your asset building here
echo GENERATING ASSETS
%PNG65% sprites --ncm --size 16,24 --input "assets\source\characters.png" --output "assets\bin"
%PNG65% chars --ncm --input "assets\source\maps\tileset1.png" --output "assets\bin"

%LDTK65% --ncm --input "assets\source\maps\map.ldtk" --output "assets\bin"


echo ASSEMBLING SOURCES...
%KICK% main.s -odir .\bin -libdir %S65PATH%

echo DEPLOYING...
IF [%1]==[] GOTO NO_ARGUMENT
	echo Deploy plus Assets to SDCard
	%DEPLOY% %SERIAL% .\bin\main.prg  
	GOTO DONE
:NO_ARGUMENT
	echo Deploy Without Assets
	%DEPLOY% .\bin\main.prg
:DONE
rem "C:\Program Files\xemu\xmega65.exe" -besure  -prg "./bin/main.prg"



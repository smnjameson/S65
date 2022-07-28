@echo off
rem Set this to match you COM port in Debugger
set SERIAL=COM6
rem Your path to the S65 Library
set S65PATH=.

set KICK=java -cp %S65PATH%\build\kickass.jar kickass.KickAssembler65CE02 -vicesymbols -showmem
set PNG65=node %S65PATH%\build\aseparse65\png65.js
set DEPLOY=node %S65PATH%\build\m65debugger\client.js




rem Do your asset building here
echo GENERATING ASSETS
rem %PNG65% sprites --ncm --size 16,16 --input "assets\source\sprites1.png" --output "assets\bin" --nofill
rem %PNG65% sprites --fcm --size 8,8 --input "assets\source\sprites2.png" --output "assets\bin" --nofill --palette "assets\bin\sprites1_palette.bin"
rem %PNG65% sprites --ncm --size 16,16 --input "assets\source\sprites3.png" --output "assets\bin" --palette "assets\bin\sprites2_palette.bin"
rem %PNG65% chars --fcm --input "assets\source\tileset1.png" --output "assets\bin" --nofill
rem %PNG65% chars --ncm --input "assets\source\tileset2.png" --output "assets\bin" --palette "assets\bin\tileset1_palette.bin"


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

echo IF THINGS LOOK WRONG BE SURE TO LOAD YOUR ASSETS TO THE SDCARD FIRST USING SHIFT+F8!!!
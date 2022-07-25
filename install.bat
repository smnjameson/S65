@echo off
rem MAKE SURE NODE IS INSTALLED
set SUBLIME_PACKAGES="%APPDATA%\Sublime Text\Packages"
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

echo Copying sublime files
mkdir %SUBLIME_PACKAGES%\S65
copy .\docs\S65*.* %SUBLIME_PACKAGES%\User
copy .\docs\Default.sublime-keymap %SUBLIME_PACKAGES%\S65


echo .
echo Installation complete




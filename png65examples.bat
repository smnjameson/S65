rem This file is not inteded to be run but instead serve as an example of how to use PNG65.js


set PNG65=node %S65PATH%\build\aseparse65\png65.js


rem Generates an FCM charset and palette from the input image
rem
rem files output:
rem     assets\bin\charsfcm_chars.bin			- The chars data
rem     assets\bin\charsfcm_palette.bin			- The FCM palette
%PNG65% chars --fcm --input "assets\source\charsfcm.png" --output "assets\bin"


rem Generates an NCM charset, palette and color table from the input image
rem
rem files output:
rem     assets\bin\tileset1_chars.bin			- The chars data
rem     assets\bin\tileset1_palette.bin			- The NCM sorted palette data
rem 	assets\bin\tileset1_ncm.bin				- The NCM color table for the charset
%PNG65% chars --ncm --input "assets\source\tileset1.png" --output "assets\bin"


rem Generates an FCM RRB spriteset and palette from the input image, RRB sprites defined as 32x32px
rem Sprite char data will be arranged in the correct order for RRB sprites
rem
rem files output:
rem     assets\bin\sprites_chars.bin			- The chars data
rem     assets\bin\sprites_palette.bin			- The FCM palette
%PNG65% sprites --fcm --size 32,32 --input "assets\source\sprites.png" --output "assets\bin"


rem Generates an NCM RRB spriteset and sorted palette from the input image, RRB sprites defined as 16x32px
rem Sprite char data will be arranged in the correct order for RRB sprites
rem
rem files output:
rem     assets\bin\spritesncm_chars.bin			- The chars data
rem     assets\bin\spritesncm_palette.bin			- The NCM sorted palette
%PNG65% sprites --ncm --size 16,32 --input "assets\source\sprites.png" --output "assets\bin"
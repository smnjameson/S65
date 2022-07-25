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


rem Processes three spritesets combining the palettes as it goes
rem by passing --nofill the palette generated is not padded out to 256 colors allowing
rem the following calls to use --palette option to prepend the previous nonpadded palette to the new one
rem the end result is the thrid palette here will contain all the palette for all three exports with 
rem the char data adjusted to match. You then only need to import the final palette (in this case assets\bin\sprites3_palette.bin)
rem for use with all three spritesets
%PNG65% sprites --ncm --size 16,16 --input "assets\source\sprites1.png" --output "assets\bin" --nofill
%PNG65% sprites --fcm --size 8,8 --input "assets\source\sprites2.png" --output "assets\bin" --nofill --palette "assets\bin\sprites1_palette.bin"
%PNG65% sprites --ncm --size 16,16 --input "assets\source\sprites3.png" --output "assets\bin" --palette "assets\bin\sprites2_palette.bin"

rem Processes two tilesets spritesets combining the palettes as it goes
rem by passing --nofill the palette generated is not padded out to 256 colors allowing
rem the following calls to use --palette option to prepend the previous nonpadded palette to the new one
%PNG65% chars --fcm --input "assets\source\tileset1.png" --output "assets\bin" --nofill
%PNG65% chars --ncm --input "assets\source\tileset2.png" --output "assets\bin" --palette "assets\bin\tileset1_palette.bin"

/**
* .data Spriteset
* The object returned by GetSpriteset
* @namespace Asset
* 
* @struct {byte} id The numerical id of the spriteset assigned by Asset_ImportSpriteset
* @struct {string} name The name of the spriteset
* @struct {word} address The start address for the spriteset char data
* @struct {word} metaAddress The start address for the spriteset metadata
* @struct {List} meta A List of bytes containing the metadata
* @struct {List} palette A List of bytes containing the palette data
* @struct {List} indices A List of character indexes for the sprites
*/
.struct Asset_Spriteset { id, name, address, metaAddress, meta, palette, indices }


/**
* .data Charset
* The object returned by GetCharset
* @namespace Asset
* 
* @struct {byte} id The numerical id of the charset assigned by Asset_ImportCharset
* @struct {string} name The name of the charset
* @struct {word} address The start address for the charset  data
* @struct {word} colorAddress The start address for the charset color data
* @struct {List} palette A List of bytes containing the palette data
* @struct {List} colors A list representing the color table fopr an ncm charset
* @struct {List} indices A list representing the in memory indices for charset
*/
.struct Asset_Charset { id, name, address, colorAddress, palette, colors, indices }


/**
* .data Tilemap
* The object returned by GetTilemap
* @namespace Asset
* 
* @struct {byte} id The numerical id of the tilemap assigned by Asset_ImportTilemap
* @struct {string} name The name of the tilemap
* @struct {word} tilemapAddress The start address for the tile definitions data
* @struct {word} tiledefAddress The start address for the tile definitions data
* @struct {List} tilemap A List of bytes containing the tilemap data
* @struct {List} tiles A List of bytes containing the tile definition data
*/
.struct Asset_Tilemap { id, name, tilemapAddress, tiledefAddress, tilemap, tiles }


.var Asset_CharList = List()
.var Asset_SpriteList = List()
.var Asset_TilemapList = List()
.var Asset_PreloaderList = List()


/**
* .var Asset_SpriteListMetaTable
*
* Pointer to the lookup table for the spritesets meta data tables
* @namespace Asset
*/
.var Asset_SpriteListMetaTable = $0000



/*
 * Segment definitions to enable the preloader system
 */
.macro Asset_PreloaderFetchSegment(num) {
	.if(num==0) .segment Preload0 [outBin="./sdcard/P0"]
	.if(num==1) .segment Preload1 [outBin="./sdcard/P1"]
	.if(num==2) .segment Preload2 [outBin="./sdcard/P2"]
	.if(num==3) .segment Preload3 [outBin="./sdcard/P3"]
	.if(num==4) .segment Preload4 [outBin="./sdcard/P4"]
	.if(num==5) .segment Preload5 [outBin="./sdcard/P5"]
	.if(num==6) .segment Preload6 [outBin="./sdcard/P6"]
	.if(num==7) .segment Preload7 [outBin="./sdcard/P7"]
	.if(num==8) .segment Preload8 [outBin="./sdcard/P8"]
	.if(num==9) .segment Preload9 [outBin="./sdcard/P9"]
	.if(num==10) .segment Preload10 [outBin="./sdcard/P10"]
	.if(num==11) .segment Preload11 [outBin="./sdcard/P11"]
	.if(num==12) .segment Preload12 [outBin="./sdcard/P12"]
	.if(num==13) .segment Preload13 [outBin="./sdcard/P13"]
	.if(num==14) .segment Preload14 [outBin="./sdcard/P14"]
	.if(num==15) .segment Preload15 [outBin="./sdcard/P15"]
	.if(num==16) .segment Preload16 [outBin="./sdcard/P16"]
	.if(num==17) .segment Preload17 [outBin="./sdcard/P17"]
	.if(num==18) .segment Preload18 [outBin="./sdcard/P18"]
	.if(num==19) .segment Preload19 [outBin="./sdcard/P19"]
	.if(num==20) .segment Preload20 [outBin="./sdcard/P20"]
	.if(num==21) .segment Preload21 [outBin="./sdcard/P21"]
	.if(num==22) .segment Preload22 [outBin="./sdcard/P22"]
	.if(num==23) .segment Preload23 [outBin="./sdcard/P23"]
	.if(num==24) .segment Preload24 [outBin="./sdcard/P24"]
	.if(num==25) .segment Preload25 [outBin="./sdcard/P25"]
	.if(num==26) .segment Preload26 [outBin="./sdcard/P26"]
	.if(num==27) .segment Preload27 [outBin="./sdcard/P27"]
	.if(num==28) .segment Preload28 [outBin="./sdcard/P28"]
	.if(num==29) .segment Preload29 [outBin="./sdcard/P29"]
	.if(num==30) .segment Preload30 [outBin="./sdcard/P30"]
	.if(num==31) .segment Preload31 [outBin="./sdcard/P31"]
}
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
* @struct {dword} tilemapAddress The start address for the tile definitions data
* @struct {dword} tiledefAddress The start address for the tile definitions data
* @struct {dword} colorAddress The start address for the ncm color lookups
* @struct {word} width The width of the tilemap in tiles
* @struct {word} height The height of the tilemap in tiles
* @struct {byte} tilewidth The width of a tile in chars
* @struct {byte} tileheight The height of a tile in chars
* @struct {List} tilemap A List of bytes containing the tilemap data
* @struct {List} tiles A List of bytes containing the tile definition data
*/
.struct Asset_Tilemap { id, name, tilemapAddress, tiledefAddress, colorAddress, width, height, tilewidth, tileheight, tilemap, tiles }


.var Asset_CharList = List()
.var Asset_SpriteList = List()
.var Asset_TilemapList = List()
.var Asset_PreloaderList = List()
.var Asset_ExternalAssetList = List()


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
	.if(num==0) .segment Preload0 [outBin="./sdcard/P0", start=0]
	.if(num==1) .segment Preload1 [outBin="./sdcard/P1", start=0]
	.if(num==2) .segment Preload2 [outBin="./sdcard/P2", start=0]
	.if(num==3) .segment Preload3 [outBin="./sdcard/P3", start=0]
	.if(num==4) .segment Preload4 [outBin="./sdcard/P4", start=0]
	.if(num==5) .segment Preload5 [outBin="./sdcard/P5", start=0]
	.if(num==6) .segment Preload6 [outBin="./sdcard/P6", start=0]
	.if(num==7) .segment Preload7 [outBin="./sdcard/P7", start=0]
	.if(num==8) .segment Preload8 [outBin="./sdcard/P8", start=0]
	.if(num==9) .segment Preload9 [outBin="./sdcard/P9", start=0]
	.if(num==10) .segment Preload10 [outBin="./sdcard/P10", start=0]
	.if(num==11) .segment Preload11 [outBin="./sdcard/P11", start=0]
	.if(num==12) .segment Preload12 [outBin="./sdcard/P12", start=0]
	.if(num==13) .segment Preload13 [outBin="./sdcard/P13", start=0]
	.if(num==14) .segment Preload14 [outBin="./sdcard/P14", start=0]
	.if(num==15) .segment Preload15 [outBin="./sdcard/P15", start=0]
	.if(num==16) .segment Preload16 [outBin="./sdcard/P16", start=0]
	.if(num==17) .segment Preload17 [outBin="./sdcard/P17", start=0]
	.if(num==18) .segment Preload18 [outBin="./sdcard/P18", start=0]
	.if(num==19) .segment Preload19 [outBin="./sdcard/P19", start=0]
	.if(num==20) .segment Preload20 [outBin="./sdcard/P20", start=0]
	.if(num==21) .segment Preload21 [outBin="./sdcard/P21", start=0]
	.if(num==22) .segment Preload22 [outBin="./sdcard/P22", start=0]
	.if(num==23) .segment Preload23 [outBin="./sdcard/P23", start=0]
	.if(num==24) .segment Preload24 [outBin="./sdcard/P24", start=0]
	.if(num==25) .segment Preload25 [outBin="./sdcard/P25", start=0]
	.if(num==26) .segment Preload26 [outBin="./sdcard/P26", start=0]
	.if(num==27) .segment Preload27 [outBin="./sdcard/P27", start=0]
	.if(num==28) .segment Preload28 [outBin="./sdcard/P28", start=0]
	.if(num==29) .segment Preload29 [outBin="./sdcard/P29", start=0]
	.if(num==30) .segment Preload30 [outBin="./sdcard/P30", start=0]
	.if(num==31) .segment Preload31 [outBin="./sdcard/P31", start=0]
}

/*
 * Segment definitions to enable the sd card loading system
 */
.macro Asset_ExternalAssetFetchSegment(num) {
	.if(num==0) .segment ExternalAsset0 [outBin="./sdcard/S0", start=0]
	.if(num==1) .segment ExternalAsset1 [outBin="./sdcard/S1", start=0]
	.if(num==2) .segment ExternalAsset2 [outBin="./sdcard/S2", start=0]
	.if(num==3) .segment ExternalAsset3 [outBin="./sdcard/S3", start=0]
	.if(num==4) .segment ExternalAsset4 [outBin="./sdcard/S4", start=0]
	.if(num==5) .segment ExternalAsset5 [outBin="./sdcard/S5", start=0]
	.if(num==6) .segment ExternalAsset6 [outBin="./sdcard/S6", start=0]
	.if(num==7) .segment ExternalAsset7 [outBin="./sdcard/S7", start=0]
	.if(num==8) .segment ExternalAsset8 [outBin="./sdcard/S8", start=0]
	.if(num==9) .segment ExternalAsset9 [outBin="./sdcard/S9", start=0]
	.if(num==10) .segment ExternalAsset10 [outBin="./sdcard/S10", start=0]
	.if(num==11) .segment ExternalAsset11 [outBin="./sdcard/S11", start=0]
	.if(num==12) .segment ExternalAsset12 [outBin="./sdcard/S12", start=0]
	.if(num==13) .segment ExternalAsset13 [outBin="./sdcard/S13", start=0]
	.if(num==14) .segment ExternalAsset14 [outBin="./sdcard/S14", start=0]
	.if(num==15) .segment ExternalAsset15 [outBin="./sdcard/S15", start=0]
	.if(num==16) .segment ExternalAsset16 [outBin="./sdcard/S16", start=0]
	.if(num==17) .segment ExternalAsset17 [outBin="./sdcard/S17", start=0]
	.if(num==18) .segment ExternalAsset18 [outBin="./sdcard/S18", start=0]
	.if(num==19) .segment ExternalAsset19 [outBin="./sdcard/S19", start=0]
	.if(num==20) .segment ExternalAsset20 [outBin="./sdcard/S20", start=0]
	.if(num==21) .segment ExternalAsset21 [outBin="./sdcard/S21", start=0]
	.if(num==22) .segment ExternalAsset22 [outBin="./sdcard/S22", start=0]
	.if(num==23) .segment ExternalAsset23 [outBin="./sdcard/S23", start=0]
	.if(num==24) .segment ExternalAsset24 [outBin="./sdcard/S24", start=0]
	.if(num==25) .segment ExternalAsset25 [outBin="./sdcard/S25", start=0]
	.if(num==26) .segment ExternalAsset26 [outBin="./sdcard/S26", start=0]
	.if(num==27) .segment ExternalAsset27 [outBin="./sdcard/S27", start=0]
	.if(num==28) .segment ExternalAsset28 [outBin="./sdcard/S28", start=0]
	.if(num==29) .segment ExternalAsset29 [outBin="./sdcard/S29", start=0]
	.if(num==30) .segment ExternalAsset30 [outBin="./sdcard/S30", start=0]
	.if(num==31) .segment ExternalAsset31 [outBin="./sdcard/S31", start=0]
}
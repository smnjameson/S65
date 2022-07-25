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

.var Asset_CharList = List()
.var Asset_SpriteList = List()

/**
* .var Asset_SpriteListMetaTable
*
* Pointer to the lookup table for the spritesets meta data tables
* @namespace Asset
*/
.var Asset_SpriteListMetaTable = $0000



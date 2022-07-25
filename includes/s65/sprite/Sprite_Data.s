


/**
* .data MetaData
*
* This is a byte array used by the engine when Asset_ImportSpriteset and Asset_ImportSpritesetMeta is used to store all the
* meta data for the sprites such as mappings from sprite to character numbers, colors etc. 
* 
* @namespace Sprite
* 
* @addr {byte} $00 Metafile version num
* @addr {byte} $01 NCM mode enable ($00 fcm, >$00 ncm)
* @addr {word} $02 Number of sprites
* @addr {byte} $04 Sprite width in chars
* @addr {byte} $05 Sprite height in chars
* @addr {byte} $06-$1f Reserved for future use
* @addr {table} $20+ character index LSB table
* @addr {table} $xx+ character index MSB table
* @addr {table} $xx+ sprite color table
*/
.var Sprite_MetaData = List()




/**
* .var SpriteIOLength
*
* The size in bytes of the IO registers for a single sprite
* 
* @namespace Sprite
*
*/
.var Sprite_SpriteIOLength = 0


/**
 * .var IOflags
 * 
 * Flags for the state of this sprite
 * 
 * bit 7 = Flip V (Not yet implemented)
 * bit 6 = Flip H 
 * bit 5 = Enabled
 * 
 * @namespace Sprite
 */
 .var Sprite_IOflags = Sprite_SpriteIOLength
 .eval Sprite_SpriteIOLength += 1



/**
* .var IOflagFlipH
* The value to set the flip H bit in <a href="#Sprite_IOflags">Sprite_IOflags</a>
* @namespace Sprite
*/
.const Sprite_IOflagFlipH = $40
/**
* .var IOflagFlipV
* The value to set the flip V bit in <a href="#Sprite_IOflags">Sprite_IOflags</a><br><br>
* NOTE: Currently due to HW limitations (missing ROWMASK functionality) this flag will cause
* rendering issues and should NOT be used
* @namespace Sprite
*/
.const Sprite_IOflagFlipV = $80
/**
* .var IOflagEnabled
* The value to set the enabled bit in <a href="#Sprite_IOflags">Sprite_IOflags</a>
* @namespace Sprite
*/
.const Sprite_IOflagEnabled = $20
/**
* .var IOflagNCM
* Turns on NCM for this sprite<br><br>
* NOTE: It is best to use NCM where possible as it takes half the processing time per visible sprite on
* a Layer_Update, less chars on a line, and less memory for the image data at the cost of dropping to 16 colors
* @namespace Sprite
*/
.const Sprite_IOflagNCM = $08


 /**
 * .var IOx
 * 
 * The IO register offset for looking up the a sprites x position
 * location in memory. Pass this to the
 * <a href='#Sprite_GetIO'>Sprite_GetIO</a>
 * function, to retrieve the address.
 * 
 * @namespace Sprite
 */
 .var Sprite_IOx = Sprite_SpriteIOLength
 .eval Sprite_SpriteIOLength += 2

/**
 * .var IOy
 * 
 * The IO register offset for looking up the a sprites y position
 * location in memory. Pass this to the
 * <a href='#Sprite_GetIO'>Sprite_GetIO</a>
 * function, to retrieve the address.
 * 
 * @namespace Sprite
 */
 .var Sprite_IOy = Sprite_SpriteIOLength
 .eval Sprite_SpriteIOLength += 2

/**
 * .var IOptr
 * 
 * The IO register offset for looking up the  sprite pointer
 * location in memory. Pass this to the
 * <a href='#Sprite_GetIO'>Sprite_GetIO</a>
 * function, to retrieve the address.
 * 
 * @namespace Sprite
 */
 .var Sprite_IOptr = Sprite_SpriteIOLength
 .eval Sprite_SpriteIOLength += 2

/**
 * .var IOwidth
 *  
 * The width in chars for this sprite, sprites will automatically advance
 * through the char set as they are drawn in pieces, top to bottom, left to right.
 * 
 * @namespace Sprite
 */
 .var Sprite_IOwidth = Sprite_SpriteIOLength
 .eval Sprite_SpriteIOLength += 1

/**
 * .var IOheight
 *  
 * The height in chars for this sprite, sprites will automatically advance
 * through the char set as they are drawn in pieces, top to bottom, left to right.
 * 
 * @namespace Sprite
 */
 .var Sprite_IOheight = Sprite_SpriteIOLength
 .eval Sprite_SpriteIOLength += 1

/**
 * .var IOcolor
 *  
 * The color to apply to all the chars in this sprite.
 * 
 * @namespace Sprite
 */
 .var Sprite_IOcolor = Sprite_SpriteIOLength
 .eval Sprite_SpriteIOLength += 1



/**
* .var IOflipHoffset
* This registers is set internally on creation of a sprite and should NOT be manually changed
* @namespace Sprite
*/
.var Sprite_IOflipHoffset = Sprite_SpriteIOLength
.eval Sprite_SpriteIOLength += 1
/**
* .var IOflipVoffset
* This registers is set internally on creation of a sprite and should NOT be manually changed
* @namespace Sprite
*
*/
.var Sprite_IOflipVoffset = Sprite_SpriteIOLength
.eval Sprite_SpriteIOLength += 1

//Pad out the array so it aligns to allow faster access
.eval Sprite_SpriteIOLength = $10





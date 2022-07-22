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
* The value to set the flip V bit in <a href="#Sprite_IOflags">Sprite_IOflags</a>
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
* This registers is set internally on creation of a sprite and should NOT be manually changed it should ALWAYS be set
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
 * The color to apply to all the cahrs in this sprite
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


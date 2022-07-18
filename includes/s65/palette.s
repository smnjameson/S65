/**
 * .namespace Palette
 * 
 * API for manipulating the <a href="##MEGA65_Palette">MEGA65 Palettes</a>
 * 
 * .data MEGA65_Palette
 * 
 * The MEGA65 has up to 4 palettes that can be assigned to the various
 * graphic types Sprite and Character. At any one time one of the palettes
 * will be banked into IO memory at $d100-$d3ff.
 * 
 * Note: While the palette format is RGB788 the nybbles of each byte are switched
 * e.g. $F0 becomes $0F, to maintain compatibility with the C65
 * 
 * @addr {byte} $000-$0ff Red channel data
 * @addr {byte} $100-$1ff Green channel data
 * @addr {byte} $200-$2ff Blue channel data
 * 
 * 
 */
#import "includes/S65/palette/Palette_Data.s"
#import "includes/S65/palette/Palette_Commands.s"


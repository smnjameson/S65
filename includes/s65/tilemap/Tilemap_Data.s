/**
* .data TilemapData
*
* Start of the tables for the Tilemap meta data
* 
* @namespace Tilemap
* 
* @addr {byte} $00 widthLSB
* @addr {byte} $XX widthMSB
* @addr {byte} $XX heightLSB
* @addr {byte} $XX heightMSB
* @addr {byte} $XX tilewidth
* @addr {byte} $XX tileheight
* @addr {byte} $XX tilesize, total char count per tile
* @addr {byte} $XX colorlookup byte 0
* @addr {byte} $XX colorlookup byte 1
* @addr {byte} $XX colorlookup byte 2
 */

.var Tilemap_TilemapData = $0000
/**
* .data Sequence
* The object returned by Anim_Get
* @namespace Anim
* 
* @struct {byte} id The numerical id of the animation
* @struct {string} name The name of the aniamtion
* @struct {word} address The start address for the animation data
* @struct {Asset_Spriteset} spriteSet The struct for the spriteset
* @struct {byte} startFrame The starting frame in the spriteset
* @struct {byte} endFrame The end frame in the spriteset
**/
.struct Anim_Sequence { id, name, address, spriteSet, startFrame, endFrame}


/**
* .data SequenceData
*
* This is a byte array used by the engine for storing animation sequences.
* Animations are not stored in a table but in a sequential list, specific aniamtion
* data addresses can be retrievd using Anim_Get().address
* 
* @namespace Sprite
* 
* @addr {byte} $00 type (for now always 0)
* @addr {byte} $01 spritesetId
* @addr {byte} $02 startFrame
* @addr {byte} $03 endFrame
 */
.var Anim_SeqList = List().add(null)
.var Anim_SequenceData = $0000
.var Anim_SequenceAddrTable = $0000
.var Anim_FrameCounts = $0000
.var Anim_Speeds = $0000
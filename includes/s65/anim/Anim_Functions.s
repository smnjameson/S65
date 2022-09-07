/**
* .function Define 
*
* Defines an animation sequence
* 
* @namespace Anim
*
* @param {byte} name The name of this animation sequence
* @param {byte} spriteSet The Spriteset this animation is from
* @param {byte} start The start frame
* @param {byte} end The end frame
* @return {Anim_Sequence} The struct containing this animation
*/
.function Anim_Define (name, spriteSet, start, end) {
		//id, name, address, spriteSet, startFrame, endFrame, color
		.var meta = spriteSet.get("meta")
		.var numSprites = meta.get($02) + meta.get($03) * 256
		.var color = meta.get($20 + numSprites * 2 + start)	

		.var id = Anim_SeqList.size()
		.eval Anim_SeqList.add(Anim_Sequence(
			id,
			name, 
			$0000,		//address
			spriteSet,
			start,
			end,
			color
		))
		.return Anim_SeqList.get(id)
}

/**
* .function Get 
*
* Returns the animation sequence object
* 
* @namespace Anim
*
* @param {string} name The name of the animation to fetch
*
* @return {Anim_Sequence} The animation sequence object
*/
.function Anim_Get (name) {
	.for(var i=0; i<Anim_SeqList.size(); i++) {
		.if(Anim_SeqList.get(i).name == name) .return i
	}
	.error "Anim_Get: " + name + " animation not found"
}
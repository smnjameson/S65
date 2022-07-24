/**
* .function GetIO
*
* Returns the base address for the given layer & IO register.<br>
* See <a href='#Sprite_Vars'>Sprite_IO<a> for register list
* 
* @namespace Sprite
*
* @param {byte} layerNumber The layer number to fetch
* @param {byte} spriteNumber The sprite number to fetch
* @param {word} register The register to fetch
*/
.function Sprite_GetIO(layerNumber, spriteNumber, register) {
	.var base = Layer_LayerList.get(layerNumber).get("spriteIOAddr")
	.return  [base + [spriteNumber * Sprite_SpriteIOLength] + register]
}


/**
* .function GetSprites
*
* Sprite sets are assigned numerical values from 0 to 15 in order as they are imported. 
* This method retrieves that value for a given name and is a required parameter in 
* <a href="#Sprite_SetSpriteMeta">Sprite_SetSpriteMeta</a><br>
* 
* @namespace Sprite
*
* @param {byte} name <add a description here>
*
* @return {byte} <add description here>
*/
.function Sprite_GetSprites(name) {
	.for(var i=0; i<Sprite_SpriteList.size(); i++) {
		.if(Sprite_SpriteList.get(i).get("name") == name) .return i
	}
	.error "Sprite_GetSpriteSet: " + name + " spriteset not found"
}
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
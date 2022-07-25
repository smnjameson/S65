
/**
* .function GetSpriteset
*
* Sprite sets are assigned numerical values from 0 to 15 in order as they are imported. 
* This method returns the spriteset object containing all the vars needed to perform many
* operations, .id is used whenever referencing a spriteset in commands e.g. 
* <a href="#Sprite_SetSpriteMeta">Sprite_SetSpriteMeta</a><br><br>
* 
* id - The numerical id of the spriteset assigned by Asset_ImportSprites
* name - The name of the spriteset<br>
* address - The start address for the spriteset char data <br>
* metaAddress - The start address for the spriteset metadata <br>
* meta - A {List} of bytes containing the metadata<br>
* palette - A {List} of bytes containign the palette data <br>    
* 
* @namespace Asset
*
* @param {byte} name The name of sprite set to retrieve
* @return {Hashtable} The sprite set info
* 
* 
*/
.function Asset_GetSpriteset(name) {
	.for(var i=0; i<Sprite_SpriteList.size(); i++) {
		.if(Sprite_SpriteList.get(i).get("name") == name) {
			.return Sprite_SpriteList.get(i)
		}
	}
	.error "Asset_GetSpriteset: " + name + " spriteset not found"
}

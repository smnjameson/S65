
/**
* .function GetSpriteset
*
* Sprite sets are assigned numerical values from 0 to 15 in order as they are imported. 
* This method returns the spriteset object containing all the vars needed to perform many
* operations, .id is used whenever referencing a spriteset in commands e.g. 
* <a href="#Sprite_SetSpriteMeta">Sprite_SetSpriteMeta</a><br><br>
* 
* id - The numerical id of the spriteset assigned by Asset_ImportSpriteset
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
	.for(var i=0; i<Asset_SpriteList.size(); i++) {
		.if(Asset_SpriteList.get(i).get("name") == name) {
			.return Asset_SpriteList.get(i)
		}
	}
	.error "Asset_GetSpriteset: " + name + " spriteset not found"
}



/**
* .function GetCharset
* 
* This method returns the charset object containing all the vars needed to perform many
* operations.<br><br>
* 
* id - The numerical id of the charset assigned by Asset_ImportCharset
* name - The name of the spriteset<br>
* address - The start address for the spriteset char data <br>
* colorAddress - The start address for the colro table if present<br>
* palette - A {List} of bytes containign the palette data <br>    
* colors - A {List} of bytes containign the ncm color mapping data <br>    
* 
* @namespace Asset
*
* @param {byte} name The name of sprite set to retrieve
* @return {Hashtable} The sprite set info
* 
* 
*/
.function Asset_GetCharset(name) {
	.for(var i=0; i<Asset_CharList.size(); i++) {
		.if(Asset_CharList.get(i).get("name") == name) {
			.return Asset_CharList.get(i)
		}
	}
	.error "Asset_GetCharset: " + name + " charset not found"
}

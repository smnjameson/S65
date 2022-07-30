
/**
* .function GetSpriteset
*
* Sprite sets are assigned numerical values from 0 to 15 in order as they are imported. 
* This method returns the spriteset object containing all the vars needed to perform many
* operations, .id is used whenever referencing a spriteset in commands e.g. 
* <a href="#Sprite_SetSpriteMeta">Sprite_SetSpriteMeta</a><br><br>
* 
* id - The numerical id of the spriteset assigned by Asset_ImportSpriteset<br>
* name - The name of the spriteset<br>
* address - The start address for the spriteset char data <br>
* metaAddress - The start address for the spriteset metadata <br>
* meta - A {List} of bytes containing the metadata<br>
* palette - A {List} of bytes containing the palette data <br>    
* 
* @namespace Asset
*
* @param {string} name The name of sprite set to retrieve
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
* id - The numerical id of the charset assigned by Asset_ImportCharset<br>
* name - The name of the charset<br>
* address - The start address for the charset char data <br>
* colorAddress - The start address for the color table if present<br>
* palette - A {List} of bytes containing the palette data <br>    
* colors - A {List} of bytes containing the ncm color mapping data <br>    
* 
* @namespace Asset
*
* @param {string} name The name of charset to retrieve
* @return {Hashtable} The charset info
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


/**
* .function GetTilemap
* 
* This method returns the tilemap object containing all the vars needed to perform many
* operations.<br><br>
* 
* NOTE: The first four bytes of the tilemap data are thew width and height of the map
* in tiles (16 bit word values)<br><br>
* 
* id - The numerical id of the tilemap assigned by Asset_ImportTilemap<br>
* name - The name of the tilemap<br>
* tilemapAddress - The start address for the tilemap data<br>
* tiledefAddress - The start address for the tile definition data<br>
* tilemap - A {List} of bytes containing the tilemap data <br>    
* tiles - A {List} of bytes containing the tile definiton data<br>    
* 
* @namespace Asset
*
* @param {string} name The name of tilemap to retrieve
* @return {Hashtable} The tilemap info
* 
* 
*/
.function Asset_GetTilemap(name) {
	.for(var i=0; i<Asset_TilemapList.size(); i++) {
		.if(Asset_TilemapList.get(i).get("name") == name) {
			.return Asset_TilemapList.get(i)
		}
	}
	.error "Asset_TilemapList: " + name + " tilemap not found"
}

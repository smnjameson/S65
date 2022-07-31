/**
* .macro LoadFromExternal
*
* Loads a full 256 color palette from SD card into the currently active palette using the name 
* referenced in a <a href="#Asset_AddExternal">Asset_AddExternal</a>
* 
* @namespace Palette
*
* @param {string} name The Asset name defined in the Asset_AddExternal macro call
* @flags nzc
*/
.macro Palette_LoadFromExternal(name){
	S65_AddToMemoryReport("Palette_LoadFromExternal")
	S65_SaveRegisters()
		.for(var i=0; i< Asset_ExternalAssetList.size(); i++) {
			.if(Asset_ExternalAssetList.get(i).get("name") == name) {
				SDCard_LoadToChipRam Palette_SDBuffer : Asset_ExternalAssetList.get(i).get("filename")
			}
		}
		jsr _CopyPaletteFromBuffer
	S65_RestoreRegisters()
	S65_AddToMemoryReport("Palette_LoadFromExternal")
}
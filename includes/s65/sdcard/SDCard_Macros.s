/**
* .macro LoadExternalToChipRam
*
* Loads a binary from SD card into the chip ram location provided
* 
* @namespace SDCard
*
* @param {string} name The Asset name defined in the Asset_AddExternal macro call
* @param {dword} name The address to load the file into
* @flags nzc
*/
.macro SDCard_LoadExternalToChipRam(name, addr){
	S65_AddToMemoryReport("SDCard_LoadExternalToChipRam")
	S65_SaveRegisters()
		.for(var i=0; i< Asset_ExternalAssetList.size(); i++) {
			.if(Asset_ExternalAssetList.get(i).get("name") == name) {
				SDCard_LoadToChipRam addr : Asset_ExternalAssetList.get(i).get("filename")
			}
		}
	S65_RestoreRegisters()
	S65_AddToMemoryReport("SDCard_LoadExternalToChipRam")
}

/**
* .macro LoadExternalToAtticRam
*
* Loads a binary from SD card into the attic ram location provided
* 
* @namespace SDCard
*
* @param {string} name The Asset name defined in the Asset_AddExternal macro call
* @param {dword} name The address to load the file into
* @flags nzc
*/
.macro SDCard_LoadExternalToAtticRam(name, addr){
	S65_AddToMemoryReport("SDCard_LoadExternalToAtticRam")
	S65_SaveRegisters()
		.for(var i=0; i< Asset_ExternalAssetList.size(); i++) {
			.if(Asset_ExternalAssetList.get(i).get("name") == name) {
				SDCard_LoadToAtticRam addr : Asset_ExternalAssetList.get(i).get("filename")
			}
		}
	S65_RestoreRegisters()
	S65_AddToMemoryReport("SDCard_LoadExternalToAtticRam")
}
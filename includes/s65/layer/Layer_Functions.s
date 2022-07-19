/**
* .function GetScreenAddress
*
* Returns the address of the char at the given position on this screen layer
* 
* @namespace Layer
*
* @param {byte} layerNumber The layer number to fetch
* @param {byte} xpos The character x position on the screen layer
* @param {byte} ypos The character y position on the screen layer
* 
* @return {dword} The screen RAM address
*/
.function Layer_GetScreenAddress(layerNumber, xpos, ypos) {
	.return Layer_LayerList.get(layerNumber).get("startAddr") + S65_SCREEN_RAM + ypos * S65_SCREEN_LOGICAL_ROW_WIDTH + xpos * 2
}


/**
* .function GetColorAddress
*
* Returns the address of the color RAM at the given position on this screen layer
* 
* @namespace Layer
*
* @param {byte} layerNumber The layer number to fetch
* @param {byte} xpos The character x position on the screen layer
* @param {byte} ypos The character y position on the screen layer
*
* @return {dword} The color RAM address
*/
.function Layer_GetColorAddress(layerNumber, xpos, ypos) {
	.var colAddr = [Layer_LayerList.get(layerNumber).get("startAddr") + S65_COLOR_RAM] + ypos * S65_SCREEN_LOGICAL_ROW_WIDTH + xpos * 2
	.return colAddr
}

/**
* .function GetLayerCount
*
* Returns the current number of layers, useful for assigning to constants
* to name each layer for use in your code.
* 
* @namespace Layer
*
* @return {byte} Current number of layers
*/
.function Layer_GetLayerCount() {
	.return Layer_LayerList.size() 
}

/**
* .function GetIO
*
* Returns the base address for the given layer & register.<br>
* See <a href='#Layer_Vars'>Layer_IO<a> for register list
*  
* @namespace Layer
*
* @param {byte} layerNumber The layer number to fetch
* @param {word} register The register to fetch
*/
.function Layer_GetIO(layerNumber, register) {
	.return Layer_LayerList.get(layerNumber).get("dynamicDataAddr") + register
}

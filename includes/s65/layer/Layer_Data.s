
/**
 * .data IO
 * 
 * The IO registers for a standard screen layer<br><br>
 * Note: You can retrieve the base address of this layers
 * IO registers with the
 * <a href='#Layer_GetIOAddress'>Layer_GetIOAddress</a>
 * function.
 * 
 * @namespace Layer
 * 
 * @addr {word} Layer_IOGotoX The GOTOX value to apply to this layer
 */
.const Layer_IOGotoX = $00



/**
 * .list LayerList
 * 
 * The list of defined layers used to create the Screen RAM layout
 * 
 * @namespace Layer
 * 
 * @key {hashtable} LayerListTable Layer data hashtable
 * 
 * .hashtable LayerListTable
 * 
 * A layer definition used to create the Screen RAM layout
 * 
 * @key {bool} rrbSprites Is this layer a RRB Sprite layer?
 * @key {word} startAddr The offset in bytes from the start of the screen row for this layer
 * @key {byte} charWidth The width of this layer in chars
 * @key {word} offsetX The GotoX offset for this layer, RRB Sprite layers cannot be offset
 * @key {byte} gotoX The offset in bytes from the start of the screen row for this layers GOTOX marker
 * @key {word} dynamicDataAddr The memory address for this layers dynamic data area
 */
.var Layer_LayerList = List()



S65_AddToMemoryReport("Layer_DynamicDataAndIO")
	/**
	* .var DynamicDataIndex
	*
	* A pointer to the table containing the address of each layers dynamic data, this memory is initialised
	* on a <a href='#Layer_InitScreen'>Layer_InitScreen</a> it's size is dependant 
	* on the screen layer structure, RRB sprite layers use the most memory
	* 
	* @namespace Layer
	*/
	.var Layer_DynamicDataIndex = $0000

	/**
	* .var RowAddressLSB
	*
	* Pointer to the table of LSB values for the address of the start of each screen row directly after the first GOTOX
	* 
	* @namespace Layer
	*/
	.var Layer_RowAddressLSB = $0000
	/**
	* .var RowAddressMSB
	*
	* Pointer to the table of MSB values for the address of the start of each screen row directly after the first GOTOX
	* 
	* @namespace Layer
	*/
	.var Layer_RowAddressMSB = $0000

	/**
	* .var DMAClear
	*
	* Pointer to a dma subroutine that clears the layer, A=layer, X=charLo, Y=charHi
	* 
	* @namespace Layer
	*
	*/
	.var Layer_DMAClear  = $0000

	.var Layer_src = $0000
	.var Layer_width = $0000
	.var Layer_offsetAdd = $0000

	/**
	 * .data LogicalWidth
	 * 
	 * Contains the current Screen Row Logical Width in bytes
	 * 
	 * @namespace Layer
	 * 
	 * @addr {word} $00 Screen Row Logical Width
	 */
	Layer_LogicalWidth:
		.word $0000

	/**
	 * .data GotoXPositions
	 * 
	 * Table of current GOTOX positions for all the layers
	 * 
	 * @namespace Layer
	 * 
	 * @addr {word} $00 Layer X position
	 */
	Layer_GotoXPositions:
		.fill S65_MAX_LAYERS * 2, 00

	/**
	 * .data GotoXColorPositions
	 * 
	 * Table of GOTOX Attribute in color ram for each layer
	 * 
	 * @namespace Layer
	 * 
	 * @addr {word} $00 Layer X position
	 */	
	Layer_GotoXColorPositions:
		.fill S65_MAX_LAYERS * 2, 00


	/**
	 * .data AddrOffsets
	 * 
	 * Table of start address offsets for each layer
	 * 
	 * @namespace Layer
	 * 
	 * @addr {word} $00 Layer start address byte offset
	 */
	Layer_AddrOffsets:
		.fill S65_MAX_LAYERS * 2, 00

S65_AddToMemoryReport("Layer_DynamicDataAndIO")












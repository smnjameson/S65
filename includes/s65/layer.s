/////////////////////////////////////////// 
// Layers
///////////////////////////////////////////
/**
 * .namespace Layer
 * 
 * API for controlling the screen ram and color ram.
 * Using the raster rewrite buffer to create and manipulate layers
 */


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


/**
* .var DynamicDataIndex
*
* A pointer to the table containing the address of each layers dynamic data, this memory is initialised
* on a <a href='#Layer_InitScreen'>Layer_InitScreen</a> it's size is dependant 
* on the screen layer structure, RRB sprite layers use the most memory
* 
* @namespace Layer
*
*/
.var Layer_DynamicDataIndex = $0000


/**
 * .data GotoXPositions
 * 
 * Table of current X positions for all the layers
 * 
 * @namespace Layer
 * 
 * @addr {word} $00 Layer X position
 */
  .print "Layer_GotoXPositions $"+toHexString(*)
Layer_GotoXPositions:
	.fill $40, 00

/**
 * .data AddrOffsets
 * 
 * Table of start address offsets for each layer
 * 
 * @namespace Layer
 * 
 * @addr {word} $00 Layer start address byte offset
 */
 .print "Layer_AddrOffsets $"+toHexString(*)
Layer_AddrOffsets:
	.fill $40, 00






/**
* .pseudocommand ClearAllLayers
*
* Fills the screen RAM area with a given 16bit value. Note this will overwrite any 
* RRB GotoX markers also
* 
* @namespace Layer 
*
* @param {word?} {REG|IMM|ABS} clearChar The 16bit char value to clear with, defaults to $0000
* @param {word?} {REG|IMM|ABS} clearChar The 16bit char value to clear with, defaults to $0000
* 
* @registers A
* @flags zn
*/
.pseudocommand Layer_ClearAllLayers clearChar {
			.if(_isReg(clearChar)) {
				 _saveReg(clearChar)
			} else {
				.if(!_isAbsImmOrNone(clearChar)) .error "Layer_ClearAllLayers: Only supports REGISTERS, AT_IMMEDIATE or AT_NONE"
			}
	        

			.const SCREEN_BYTE_SIZE = S65_SCREEN_LOGICAL_ROW_WIDTH * S65_VISIBLE_SCREEN_CHAR_HEIGHT
			//REGISTER
			.if(_isReg(clearChar)) {
				lda S65_PseudoReg
				sta jobIf.Job1_Source
				lda #$00
				sta jobIf.Job2_Source	

			//ABSOLUTE			
			} else .if(_isAbs(clearChar)) {
				lda clearChar.getValue()
				sta jobIf.Job1_Source
				lda clearChar.getValue() + 1
				sta jobIf.Job2_Source
			}

			DMA_Execute job
			jmp end
		job:
			DMA_Header #$00 : #$00
			jobIf:
			.if(clearChar.getType() != AT_NONE) {
				DMA_Step #$0100 : #$0200 

				.label Job1_Source = * + $04
				DMA_FillJob #<clearChar.getValue() : S65_SCREEN_RAM + 0 : #SCREEN_BYTE_SIZE : #TRUE

				.label Job2_Source = * + $04		
				DMA_FillJob #>clearChar.getValue() : S65_SCREEN_RAM + 1 : #SCREEN_BYTE_SIZE : #FALSE

			} else {
				DMA_FillJob #$00 : S65_SCREEN_RAM + 0 : #SCREEN_BYTE_SIZE : #FALSE						
			}
		end:
}



 /**
  * .pseudocommand DefineBGLayer
  * 
  * Defines the mandatory first layer in Screen RAM, acting as a background. 
  * Can have only one background at any time.
  * 
  * @namespace Layer
  * 
  * @param {byte} {IMM} charWidth The screen base visible width in chars
  * @param {byte} {IMM} charHeight The screen base visible height in chars
  * @param {word?} {IMM} offsetX The new RRB GotoX position to set for this layer, defaults to 0
  * 
  * @registers A
  * @flags nz
  * 
  * @setreg {byte} A The layer number this layer was created at
  */
.pseudocommand Layer_DefineBGLayer charWidth : charHeight : offsetX {
	.var index = Layer_LayerList.size()
	.if(index != 0) {
		.error("Can only define a single BG layer.")
	}
 	.if(!_isImm(charWidth)) .error "Layer_DefineBGLayer: charWidth Only supports AT_IMMEDIATE"
 	.if(!_isImm(charHeight)) .error "Layer_DefineBGLayer: charHeight Only supports AT_IMMEDIATE"
 	.if(!_isImmOrNone(offsetX)) .error "Layer_DefineBGLayer: offsetX Only supports AT_IMMEDIATE or AT_NONE"


	.eval S65_VISIBLE_SCREEN_CHAR_WIDTH = charWidth.getValue()
	.eval S65_VISIBLE_SCREEN_CHAR_HEIGHT = charHeight .getValue()

	.eval S65_SCREEN_ROW_WIDTH += charWidth.getValue() + 1 //add a gotox
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars

	.eval Layer_LayerList.add(Hashtable())
	.eval Layer_LayerList.get(index).put("rrbSprites", false)
	.eval Layer_LayerList.get(index).put("gotoX", 0 )
	.eval Layer_LayerList.get(index).put("startAddr", 2 )
	.eval Layer_LayerList.get(index).put("charWidth", charWidth.getValue())
	.eval Layer_LayerList.get(index).put("offsetX", offsetX.getValue())

	lda #$00
	sta Layer_AddrOffsets + 0
	sta Layer_AddrOffsets + 1

	lda #<offsetX.getValue()
	sta Layer_GotoXPositions + 0
	lda #>offsetX.getValue()
	sta Layer_GotoXPositions + 1
	lda #index
}


/**
 * .pseudocommand DefineScreenLayer
 * 
 * Defines a new screen layer in Screen RAM optionally shifting its
 * RRB GOTOX offset.
 * 
 * @namespace Layer
 * 
 * @registers A
 * @flags zn
 * 
 * @param {byte} {IMM} charWidth The screen layers width in chars
 * @param {word?} {IMM} offsetX The new RRB GotoX position to set for this layer
 * 
 * @setreg {byte} A The layer number this layer was created at
 */
 .pseudocommand Layer_DefineScreenLayer charWidth : offsetX {
 		.var cw = charWidth.getValue()
 		.var t_cw = charWidth.getType()
 		.var ox = offsetX.getValue()
 		.var t_ox = offsetX.getType()

	 	.if(!_isImm(charWidth)) .error "Layer_DefineScreenLayer: charWidth Only supports AT_IMMEDIATE"
	 	.if(!_isImmOrNone(offsetX)) .error "Layer_DefineScreenLayer: offsetX Only supports AT_IMMEDIATE or AT_NONE"

		.var index = Layer_LayerList.size()
		.if(offsetX.getType() == AT_NONE) {
			.eval ox = 0
		}

		.if(index == 0) {
			.error("Must define a BG layer first with S65_DefineBGLayer.")
		}

		.eval Layer_LayerList.add(Hashtable())
		.eval Layer_LayerList.get(index).put("rrbSprites", false)
		.eval Layer_LayerList.get(index).put("gotoX", S65_SCREEN_LOGICAL_ROW_WIDTH )
		.eval Layer_LayerList.get(index).put("startAddr", S65_SCREEN_LOGICAL_ROW_WIDTH + 2 )
		.eval Layer_LayerList.get(index).put("charWidth", cw )
		.eval Layer_LayerList.get(index).put("offsetX", ox )

		lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
		sta [Layer_AddrOffsets + index * 2]
		lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
		sta [Layer_AddrOffsets + index * 2 + 1]

		.eval S65_SCREEN_ROW_WIDTH += cw + 1 //add a gotox
		.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars

		lda #<offsetX.getValue()
		sta Layer_GotoXPositions + index * 2
		lda #>offsetX.getValue()
		sta Layer_GotoXPositions + index * 2 + 1	

		lda #index
 }


/**
 * .pseudocommand DefineRRBSpriteLayer
 * 
 * Defines a new RRB Sprite layer in Screen RAM. <br><br>
 * 
 * RRB Sprite space is a buffer limited by a set amount of chars per line, each new Sprite 
 * takes a GOTOX marker and however many RRB chars wide it is. So, for example, a 32x32 RRB sprite 
 * is 2 chars wide + a GOTOX marker so will take 3 chars of space.<br><br>
 * Note: There is a 256 RRB Sprite hard limit per RRB Sprite layer.
 * 
 * @namespace Layer
 * 
 * @param {byte} {IMM} maxSprites The maximum number of RRB Sprites for this layer, lower numbers improve performance
 * @param {byte?} {IMM} charsPerLine The number of RRB chars reserved in the buffer for this layer, lower numbers improve performance. Defaults to 40
 * 
 * @registers A
 * @flags nz
 *  
 * @setreg {byte} A The layer number this layer was created at
 */
.pseudocommand Layer_DefineRRBSpriteLayer maxSprites : charsPerLine {
	.var index = Layer_LayerList.size()


	 .if(!_isImm(maxSprites)) .error "Layer_DefineRRBSpriteLayer: maxSprites Only supports AT_IMMEDIATE"
	 .if(!_isImmOrNone(charsPerLine)) .error "Layer_DefineRRBSpriteLayer: charsPerLine Only supports AT_IMMEDIATE or AT_NONE"

	.if(index == 0) {
		.error("Must define a BG layer first with S65_DefineBGLayer.")
	}

	.var cpl =  charsPerLine.getType() == AT_NONE ? 40 : charsPerLine.getValue()

	.eval Layer_LayerList.add(Hashtable())
	.eval Layer_LayerList.get(index).put("rrbSprites", true)
	.eval Layer_LayerList.get(index).put("maxSprites", maxSprites.getValue())
	.eval Layer_LayerList.get(index).put("charWidth", cpl)
	.eval Layer_LayerList.get(index).put("startAddr", S65_SCREEN_LOGICAL_ROW_WIDTH)
	.eval Layer_LayerList.get(index).put("gotoX", S65_SCREEN_LOGICAL_ROW_WIDTH )
	.eval Layer_LayerList.get(index).put("offsetX", $01ff)

	lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2]
	lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2 + 1]

	lda #$00
	sta Layer_GotoXPositions + index * 2
	lda #$00
	sta Layer_GotoXPositions + index * 2 + 1

	.eval S65_SCREEN_ROW_WIDTH += cpl
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars	

	lda #index
}



/**
* .pseudocommand SetAllMarkers
*
* Sets the RRB GotoX markers for all but the 
* RRB sprite layers
* 
* @namespace Layer
*
* @registers A
* @flags znc
*/
.pseudocommand Layer_SetAllMarkers {
		phx 
		phy
		phz

		S65_SetBasePage()
			//Transfer the GOTOX values from the dynamic IO
			ldy #$00
			ldx #$00
		!loop:
			lda Layer_DynamicDataIndex, x
			inx
			sta.z S65_TempWord1 + 0
			lda Layer_DynamicDataIndex, x
			sta.z S65_TempWord1 + 1
			dex

			lda.z (S65_TempWord1), y 
			iny
			sta Layer_GotoXPositions, x
			inx 
			lda.z (S65_TempWord1), y 
			and #$03 //Clamp the value to only use the first 2 bits	
			dey
			sta Layer_GotoXPositions, x 
			inx
			cpx #[Layer_LayerList.size() * 2]
			bne !loop-



			.const COLOR_PTR = S65_TempDword1
			.const SCREEN_PTR = S65_TempDword2
 		
			//add the rrb GOTOX markers
			ldx #$00
		!outerLoop:
			clc 
			lda Layer_AddrOffsets, x
			adc #<S65_COLOR_RAM
			inx
			sta COLOR_PTR + 0
			lda Layer_AddrOffsets, x
			adc #>S65_COLOR_RAM
			sta COLOR_PTR + 1
			lda #[S65_COLOR_RAM >> 16]
			adc #$00
			sta COLOR_PTR + 2
			lda #[S65_COLOR_RAM >> 24]
			sta COLOR_PTR + 3
			dex

			clc 
			lda Layer_AddrOffsets, x
			adc #<S65_SCREEN_RAM
			inx
			sta SCREEN_PTR + 0
			lda Layer_AddrOffsets, x
			adc #>S65_SCREEN_RAM
			sta SCREEN_PTR + 1
			lda #[S65_SCREEN_RAM >> 16]
			adc #$00
			sta SCREEN_PTR + 2
			lda #[S65_SCREEN_RAM >> 24]
			sta SCREEN_PTR + 3
			dex


				ldy #S65_VISIBLE_SCREEN_CHAR_HEIGHT
			!loop:
				//COLOR RAM
				ldz #$00
				lda #$10 //If this is the first BG layer its NOT transparent
				cpx #$00
				beq !+
				lda #$90 //All other layers transparent
			!:
				sta ((COLOR_PTR)), z 
				inz
				lda #$00
				sta ((COLOR_PTR)), z 

				//next row
				clc 
				lda COLOR_PTR + 0
				adc #<S65_SCREEN_LOGICAL_ROW_WIDTH
				sta COLOR_PTR + 0
				lda COLOR_PTR + 1
				adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
				sta COLOR_PTR + 1		
				bcc !+
				inc COLOR_PTR + 2				
			!:

				//SCREEN RAM
				dez
				lda Layer_GotoXPositions, x
				inx
				sta ((SCREEN_PTR)), z 
				inz
				lda ((SCREEN_PTR)), z
				and #%11111100
				ora Layer_GotoXPositions, x
				dex
				sta ((SCREEN_PTR)), z 

				//next row
				clc 
				lda SCREEN_PTR + 0
				adc #<S65_SCREEN_LOGICAL_ROW_WIDTH
				sta SCREEN_PTR + 0
				lda SCREEN_PTR + 1
				adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
				sta SCREEN_PTR + 1		
				bcc !+
				inc SCREEN_PTR + 2
			!:

				// jmp *

				dey 
				bne !loop-

				inx
				inx
			cpx #[[Layer_LayerList.size() + 1]* 2] //Include the terminating block
			lbcc !outerLoop-
		!end:
		S65_RestoreBasePage()

		plz
		ply
		plx
}




/**
 * .pseudocommand InitScreen
 * 
 * Initialises the MEGA65 and VIC-IV and parses the Layer definitions
 * into a Screen RAM layout
 * 
 * @namespace Layer
 * 
 * @param {word} {IMM} screenBaseAddress The base address of the Screen RAM
 * 
 * @registers AXYZ
 * @flags znc
 */
.pseudocommand Layer_InitScreen screenBaseAddress {
	.const GOTOX = 1

	.if(!_isImm(screenBaseAddress)) .error "Layer_InitScreen: screenBaseAddress Only supports AT_IMMEDIATE"

	.eval S65_SCREEN_RAM = screenBaseAddress.getValue()

	//Total screen width in chars = 
	// Base screen width +
	// ScreenLayer Widths +
	// ScreenLayers count (gotox)
	// RRB Layers total charsPerLine +
	// Terminating GOTOX + char (2chars)

	S65_Trace("Layer_InitScreen - Calculating screen configuration...")
	S65_Trace("")	
	.var currsize = 0
	.for(var i=0; i<Layer_LayerList.size(); i++) {
		.var layer = Layer_LayerList.get(i)
		.if(layer.get("rrbSprites") == true) {
			.eval layer.put("addrOffset", currsize)
			S65_Trace("RRB Sprite Layer at byte offset $"+ toHexString(layer.get("addrOffset"))+" of width $"+toHexString(layer.get("charWidth"))+ " chars.")
			.eval currsize += layer.get("charWidth") * 2
		} else {
			.eval layer.put("addrOffset", currsize)
			S65_Trace("Screen Layer at byte offset $"+ toHexString(layer.get("addrOffset"))+" of width $"+toHexString(layer.get("charWidth"))+ " chars.")
			.eval currsize += [layer.get("charWidth") * 2 + 2] //include gotox
		}
	}


	//Termination layer
	lda #<[S65_SCREEN_ROW_WIDTH * 2]
	sta [Layer_AddrOffsets + Layer_LayerList.size() * 2]
	lda #>[S65_SCREEN_ROW_WIDTH * 2]
	sta [Layer_AddrOffsets + Layer_LayerList.size() * 2 + 1]
	lda #$00
	sta [Layer_GotoXPositions + Layer_LayerList.size() * 2]
	lda #$02
	sta [Layer_GotoXPositions + Layer_LayerList.size() * 2 + 1]

	.eval S65_SCREEN_TERMINATOR_OFFSET = S65_SCREEN_ROW_WIDTH
	.eval S65_SCREEN_ROW_WIDTH += [GOTOX + 1]
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2

	S65_Trace("Screen row width is $"+toHexString(S65_SCREEN_ROW_WIDTH)+ " chars / $"+ toHexString(S65_SCREEN_LOGICAL_ROW_WIDTH) + " bytes.")

	jsr S65.Init

	//Set logical row width
	//bytes per screen row (16 bit value in $d058-$d059)
	lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
	sta $d058
	lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
	sta $d059

	//Set number of chars per row
	lda #S65_SCREEN_ROW_WIDTH
	sta $d05e

	//Relocate screen RAM using $d060-$d063
	lda #<S65_SCREEN_RAM 
	sta $d060 
	lda #>S65_SCREEN_RAM 
	sta $d061
	lda #[S65_SCREEN_RAM >> 16] 
	sta $d062
	lda #[S65_SCREEN_RAM >> 24] 
	sta $d063

	//ColorRAM initialisation
		.const SCREEN_BYTE_SIZE = S65_SCREEN_LOGICAL_ROW_WIDTH * S65_VISIBLE_SCREEN_CHAR_HEIGHT
		DMA_Execute job
		jmp end
	job:
		DMA_Header #$00 : #$ff
		DMA_FillJob #0 : S65_COLOR_RAM : #SCREEN_BYTE_SIZE : #FALSE			

		//This area can be used for dynamic memory based on the size of layers and sprites
		//////////////////////////
		//Sprites data
		//////////////////////////
		_configureDynamicData()
	end:
}




/**
* .pseudocommand AddColor
*
* Writes a string of bytes to color RAM, setting Color RAM Byte 1 all bits (so includes bit4-blink, bit5-reverse, bit6-bold and bit7-underline), 
* this will only work on non NCM layers with char indices less than $100 <br><br>
* 
* Note: When writing to color RAM. As layers are not contiguous in memory, its important to not let
* the colors extend off the right edge of the layer as it can break the RRB on other layers. 
* There is an upper limit length of 128
* 
* @namespace Layer
*
* @param {byte} {ABS} addrPtr The screen address to write to
* @param {byte} {REG|IMM|ABS|ABX}} color Color to write to color ram
* @param {byte} {IMM} length <add a description here>
*
* @registers A
* @flags nzc
* 
* @return {byte} A <add description here> 
*/
.pseudocommand Layer_AddColor addrPtr : color : length {
		.if(!_isAbs(addrPtr)) .error "Layer_InitScreen: addrPtr Only supports AT_ABSOLUTE"
		.if(!_isImm(length)) .error "Layer_InitScreen: addrPtr Only supports AT_IMMEDIATE"
		.if(!_isAbsX(color) && 
			!_isImm(color) && 
			!_isReg(color) && 
			color.getType() != AT_NONE) .error "Layer_InitScreen: textPtr Only supports REG, AT_IMMEDIATE, AT_ABSOLUTE, AT_ABSOLUTEX" 

		.if(_isReg(color)) {
			_saveReg(color)
		}

		.const COLOR_PTR = S65_TempDword2

		S65_SetBasePage()
			.var coladdr = addrPtr.getValue()

			.print "coladdr" + toHexString(coladdr) +"  "+length.getValue()
			lda #<coladdr
			sta.z COLOR_PTR + 0
			lda #>coladdr
			sta.z COLOR_PTR + 1
			lda #[coladdr >> 16]
			sta.z COLOR_PTR + 2
			lda #[coladdr >> 24]
			sta.z COLOR_PTR + 3	
			

			phz

			ldz #$00
		!loop:
			.if(_isReg(color)) {
				lda.z S65_PseudoReg
			} else {
				lda color 		
			}
			inz
			sta ((COLOR_PTR)), z
			inz
			
			tza
			cmp #[length.getValue() * 2]

			bne !loop-
		!exit:

			plz
		S65_RestoreBasePage()
}	

/**
* .pseudocommand AddText
*
* Writes a string of bytes to the given address. Optionally allows the
* use of color, setting Color RAM Byte 1 all bits (so includes bit4-blink, bit5-reverse, bit6-bold and bit7-underline), 
* this will only work on non NCM layers with char indices less than $100 <br><br>
* 
* Note: If writing to screen RAM. As layers are not contiguous in memory, its important to not let
* the string extend off the right edge of the layer as it can break the RRB on other layers. 
* There is an upper limit string length of 128
*
* @namespace Layer
*
* @param {word} {ABS} addrPtr The screen address to write to
* @param {word} {ABS} textPtr The address to fetch char data from
* @param {byte?} {REG|IMM|ABS|ABX} color Optional color to write to color ram
*
* @registers A
* @flags zn
*/
.pseudocommand Layer_AddText addrPtr : textPtr : color {
		.if(!_isAbs(addrPtr)) .error "Layer_InitScreen: addrPtr Only supports AT_ABSOLUTE"
		.if(!_isAbs(textPtr)) .error "Layer_InitScreen: textPtr Only supports AT_ABSOLUTE"
		.if(!_isAbsX(color) && 
			!_isImm(color) && 
			!_isReg(color) && 
			color.getType() != AT_NONE) .error "Layer_InitScreen: textPtr Only supports REG, AT_IMMEDIATE, AT_ABSOLUTE, AT_ABSOLUTEX" 

		.if(_isReg(color)) {
			_saveReg(color)
		}

		.const SCREEN_PTR = S65_TempDword1
		.const COLOR_PTR = S65_TempDword2

		S65_SetBasePage()

			lda #<addrPtr.getValue()
			sta.z SCREEN_PTR + 0
			lda #>addrPtr.getValue()
			sta.z SCREEN_PTR + 1
			lda #[addrPtr.getValue() >> 16]
			sta.z SCREEN_PTR + 2
			lda #[addrPtr.getValue() >> 24]
			sta.z SCREEN_PTR + 3

			.if(color.getType() != AT_NONE) {
				.var coladdr = [[addrPtr.getValue() - S65_SCREEN_RAM] + S65_COLOR_RAM]
				lda #<coladdr
				sta.z COLOR_PTR + 0
				lda #>coladdr
				sta.z COLOR_PTR + 1
				lda #[coladdr >> 16]
				sta.z COLOR_PTR + 2
				lda #[coladdr >> 24]
				sta.z COLOR_PTR + 3	
			}

			phy
			phz
			ldz #$00
			ldy #$00
		!loop:
			iny
			lda textPtr.getValue(), y
			cmp #$ff
			beq !exit+
			dey
			
				lda textPtr.getValue(), y
				iny
				sta ((SCREEN_PTR)), z
				inz
				lda textPtr.getValue(), y
				sta ((SCREEN_PTR)), z
				 	
				
				//Add color
				.if(color.getType() != AT_NONE) {
					.if(_isReg(color)) {
						lda.z S65_PseudoReg
					} else {
						lda color 		
					}
					sta ((COLOR_PTR)), z
				}

				inz
				iny
			bra !loop-
		!exit:
		plz
		ply
		S65_RestoreBasePage()
}		


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
	.print "coll Addr "+toHexString(colAddr)
	.return colAddr
}

/**
* .function GetIOAddress
*
* Returns the base address plus an optional offset for the given layers IO registers.<br>
* See <a href='#Layer_IO'>Layer_IO<a> for register list
* 
* @namespace Layer
*
* @param {byte} layerNumber The layer number to fetch
* @param {word} offset The byte offset into the IO register to fetch
*/
.function Layer_GetIOAddress(layerNumber, offset) {

	.return Layer_LayerList.get(layerNumber).get("dynamicDataAddr") + offset
}




.const Layer_IOGotoX = $00
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
.macro _configureDynamicData() {
	S65_Trace("Layer_InitScreen - Configuring dynamic layer memory...")
	S65_Trace("Start address $"+toHexString(*))	

	.var layerAddr = List()

	.for(var i=0; i<Layer_LayerList.size(); i++) {
		S65_Trace("Layer "+i+" start address $"+toHexString(*))	

		.eval layerAddr.add(*)
		//common values
		.eval Layer_LayerList.get(i).put("dynamicDataAddr", *)

		.word Layer_LayerList.get(i).get("offsetX") //GOTOX position value

		.if(Layer_LayerList.get(i).get("rrbSprites") == true) {
			//rrb only
			S65_Trace("RRB Sprites Layer")
		} else {
			//screenlayer only
			S65_Trace("Screen Layer")
		}
	}

	.eval Layer_DynamicDataIndex = *
	S65_Trace("Layer_DynamicDataIndex $"+toHexString(Layer_DynamicDataIndex))	
	
	.for(var i=0; i<layerAddr.size(); i++) {
		.word layerAddr.get(i)
	}
}








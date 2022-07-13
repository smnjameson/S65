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
 * @key {hashtable} LayerListTable
 * 
 * .hashtable LayerListTable
 * 
 * A layer definition used to create the Screen RAM layout
 * 
 * @key {bool} rrbSprites Is this layer a RRB Sprite layer?
 * @key {word} startAddr The offset in bytes from the start of the screen row for this layer
 * @key {byte} charWidth The width of this layer in chars
 * @key {word} offsetX The GotoX offset for this layer
 * @key {byte} gotoX The offset in bytes from the start of the screen row for this layers GOTOX marker
 */
.var Layer_LayerList = List()


/**
 * .data Layer_GotoXPositions
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
 * .data Layer_AddrOffsets
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
* .macro ClearAllLayers
*
* Fills the screen RAM area with a given 16bit value
* 
* @namespace Layer
*
* @param {word} clearChar The 16bit char value to clear with
* 
* @registers A
* @flags zn
*/
.macro Layer_ClearAllLayers(clearChar) {
			.const SCREEN_BYTE_SIZE = S65_SCREEN_LOGICAL_ROW_WIDTH * S65_VISIBLE_SCREEN_CHAR_HEIGHT

			DMA_Execute(job)
			jmp end
		job:
			DMA_Header(0,0)
			DMA_Step(1,0,2,0)
			DMA_FillJob(<clearChar, S65_SCREEN_RAM + 0, SCREEN_BYTE_SIZE, true)			
			DMA_FillJob(>clearChar, S65_SCREEN_RAM + 1, SCREEN_BYTE_SIZE, false)
		end:
}

 /**
  * .macro DefineBGLayer
  * 
  * Defines the mandatory first layer in Screen RAM, acting as a background. 
  * Can have only one background at any time.
  * 
  * @namespace Layer
  * @param {byte} charWidth The screen base visible width in chars
  * @param {byte} charHeight The screen base visible height in chars
  * @param {word} offsetX The new RRB GotoX position to set for this layer
  * 
  * @registers A
  * @flags nz
  * 
  */
.macro Layer_DefineBGLayer(charWidth, charHeight, offsetX) {
	.var index = Layer_LayerList.size()
	.if(index != 0) {
		.error("Can only define a single BG layer.")
	}

	.eval S65_VISIBLE_SCREEN_CHAR_WIDTH = charWidth
	.eval S65_VISIBLE_SCREEN_CHAR_HEIGHT = charHeight 

	.eval S65_SCREEN_ROW_WIDTH += charWidth + 1 //add a gotox
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars

	.eval Layer_LayerList.add(Hashtable())
	.eval Layer_LayerList.get(index).put("rrbSprites", false)
	.eval Layer_LayerList.get(index).put("gotoX", 0 )
	.eval Layer_LayerList.get(index).put("startAddr", 2 )
	.eval Layer_LayerList.get(index).put("charWidth", charWidth)
	.eval Layer_LayerList.get(index).put("offsetX", offsetX)

	lda #$00
	sta Layer_AddrOffsets + 0
	sta Layer_AddrOffsets + 1

	lda #<offsetX
	sta Layer_GotoXPositions + 0
	lda #>offsetX
	sta Layer_GotoXPositions + 1
}

/**
 * .macro DefineScreenLayer
 * 
 * Defines a new screen layer in Screen RAM optionally shifting its
 * RRB GOTOX offset.
 * 
 * @namespace Layer
 * 
 * @param {byte} charWidth The screen layers width in chars
 * @param {word} offsetX The new RRB GotoX position to set for this layer
 * 
 * @registers A
 * @flags zn
 */
.macro Layer_DefineScreenLayer(charWidth, offsetX) {
	.var index = Layer_LayerList.size()
	.if(offsetX == null) {
		.eval offsetX = 0
	}
	.if(index == 0) {
		.error("Must define a BG layer first with S65_DefineBGLayer.")
	}
	


	.eval Layer_LayerList.add(Hashtable())
	.eval Layer_LayerList.get(index).put("rrbSprites", false)
	.eval Layer_LayerList.get(index).put("gotoX", S65_SCREEN_LOGICAL_ROW_WIDTH )
	.eval Layer_LayerList.get(index).put("startAddr", S65_SCREEN_LOGICAL_ROW_WIDTH + 2 )
	.eval Layer_LayerList.get(index).put("charWidth", charWidth)
	.eval Layer_LayerList.get(index).put("offsetX", offsetX)


	lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2]
	lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2 + 1]

	.eval S65_SCREEN_ROW_WIDTH += charWidth + 1 //add a gotox
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars

	lda #<offsetX
	sta Layer_GotoXPositions + index * 2
	lda #>offsetX
	sta Layer_GotoXPositions + index * 2 + 1	
}




/**
 * .macro DefineRRBSpriteLayer
 * 
 * Defines a new RRB Sprite layer in Screen RAM. <br><br>
 * 
 * RRB Sprite space is a buffer limited by a set amount of chars per line, each new Sprite 
 * takes a GOTOX marker and however many RRB chars wide it is. So, for example, a 32x32 RRB sprite 
 * is 2 chars wide + a GOTOX marker so will take 3 chars of space.<br><br>
 * 
 * <small>Note: There is a 256 RRB Sprite hard limit per RRB Sprite layer.</small>
 * 
 * @namespace Layer
 * 
 * @param {byte} maxSprites The maximum number of RRB Sprites for this layer, lower numbers improve performance
 * @param {byte} charsPerLine The number of RRB chars reserved in the buffer for this layer, lower numbers improve performance.
 * 
 * @registers
 * @flags 
 */
.macro Layer_DefineRRBSpriteLayer(maxSprites, charsPerLine) {
	.var index = Layer_LayerList.size()
	.if(index == 0) {
		.error("Must define a BG layer first with S65_DefineBGLayer.")
	}

	.eval Layer_LayerList.add(Hashtable())
	.eval Layer_LayerList.get(index).put("rrbSprites", true)
	.eval Layer_LayerList.get(index).put("maxSprites", maxSprites)
	.eval Layer_LayerList.get(index).put("charWidth", charsPerLine)
	.eval Layer_LayerList.get(index).put("startAddr", S65_SCREEN_LOGICAL_ROW_WIDTH + 0 )

	lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2]
	lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2 + 1]

	.eval S65_SCREEN_ROW_WIDTH += charsPerLine
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars	


}


/**
 * .macro InitScreen
 * 
 * Initialises the MEGA65 and VIC-IV and parses the Layer definitions
 * into a Screen RAM layout
 * 
 * @namespace Layer
 * 
 * @param {word} screenBaseAddress The base address of the Screen RAM
 * 
 * @registers AXYZ
 * @flags znc
 */
.macro Layer_InitScreen(screenBaseAddress) {
	.const GOTOX = 1

	.eval S65_SCREEN_RAM = screenBaseAddress


	//Total screen width in chars = 
	// gotox marker (1 char) +
	// Base screen width +
	// ScreenLayer Widths +
	// ScreenLayers count (gotox)
	// RRB Layer charsPerLine +
	// Terminating GOTOX + char (2chars)
	
	S65_Trace("Calculating screen configuration...")
	S65_Trace("")	
	.for(var i=0; i<Layer_LayerList.size(); i++) {
		.var layer = Layer_LayerList.get(i)
		.if(layer.get("rrbSprites") == true) {
			.eval layer.put("addrOffset", S65_SCREEN_ROW_WIDTH * 2)
			S65_Trace("RRB Sprite Layer at byte offset $"+ toHexString(layer.get("addrOffset"))+" of width $"+toHexString(layer.get("charWidth"))+ " chars.")

		} else {
			.eval layer.put("addrOffset", S65_SCREEN_ROW_WIDTH * 2)
			S65_Trace("Screen Layer at byte offset $"+ toHexString(layer.get("addrOffset"))+" of width $"+toHexString(layer.get("charWidth"))+ " chars.")
		}
	}

	
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
		DMA_Execute(job)
		//add the rrb GOTOX markers
		jmp end
	job:
		DMA_Header($00,$ff)
		DMA_FillJob(0, S65_COLOR_RAM, SCREEN_BYTE_SIZE, false)				

	end:
}


/**
* .macro SetAllMarkers
*
* Sets the RRB GotoX markers for all but the 
* RRB sprite layers
* 
* @namespace Layer
*
* @registers AXYZ
* @flags znc
*/
.macro Layer_SetAllMarkers() {

		S65_SetBasePage()
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
				lda Layer_GotoXPositions, x
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
}



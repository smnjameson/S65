
/**
 * .macro DefineResolution
 *
 * Defines the screen resolution in 8x8 charachters (regardless if NCM is being used) and if it should be stretched
 * horizontally to fit the width of the display. <a href="##Layer_InitScreen">Layer_InitScreen</a>
 * will configure the borders and TEXTXPOS and TEXTYPOS to center the screen on the display.<br><br>
 * 
 * NOTE:<br>
 * - charHeight above 32 will use V400 mode and disable any RRB double buffering and double rate RRB<br>
 * - charWidth above 42 will use H640 mode<br>
 * 
 * @namespace Layer
 *
 * @param {byte} charWidth The screen base visible width in chars, range 1-84
 * @param {byte} charHeight The screen base visible height in chars, range 1-50
 * @param {bool} stretchWide should this screen be stetched horizontally to fit the screen
 */

.const Layer_MAX_SCREEN_WIDTH = 84
.const Layer_SCREEN_HORIZ_BREAK = 42
.const Layer_MAX_SCREEN_HEIGHT = 64
.var LAYER_RESOLUTION_DEFINED = false
.var LAYER_RESOLUTION_STRETCHED = false

.macro Layer_DefineResolution(charWidth, charHeight, stretchWide){
		.if(charHeight < 1 || charHeight > Layer_MAX_SCREEN_HEIGHT) .error "Layer_DefineResolution: charHeight must be between 1 and " + Layer_MAX_SCREEN_HEIGHT
		.if(charWidth < 1 || charWidth > Layer_MAX_SCREEN_WIDTH) .error "Layer_DefineResolution: charWidth must be between 1 and " + Layer_MAX_SCREEN_WIDTH

		.eval LAYER_RESOLUTION_DEFINED = true

		.eval S65_VISIBLE_SCREEN_CHAR_WIDTH = charWidth
		.eval S65_VISIBLE_SCREEN_CHAR_HEIGHT = charHeight 
		.eval S65_SCREEN_ROW_WIDTH = 0//charWidth + 1 //add a gotox
		.eval S65_SCREEN_LOGICAL_ROW_WIDTH = 0//S65_SCREEN_ROW_WIDTH * 2 //16bit chars

		.eval LAYER_RESOLUTION_STRETCHED = stretchWide
}

/**
 * .macro DefineScreenLayer
 * @namespace Layer
 * 
 * Defines a new screen layer in Screen RAM optionally shifting its
 * RRB GOTOX offset.<br>
 * Note: the maximum charWidth for a layer is 126
 * 
 * @registers A
 * @flags zn
 * 
 * @param {byte} charWidth The screen layers width in chars
 * @param {word} offsetX The new RRB GotoX position to set for this layer
 * @param {bool} ncm NCM enabled for this layer, defaults to FALSE
 * 
 * @setreg {byte} A The layer number this layer was created at
 */
 .macro Layer_DefineScreenLayer(charWidth, offsetX, ncm) {
 	S65_AddToMemoryReport("Layer_DefineScreenLayer")
		.if(charWidth < 1 || charWidth > 126) .error "Layer_DefineScreenLayer: charWidth must be between 1 and 126"

	 	// .if(!_isImm(charWidth)) .error "Layer_DefineScreenLayer: charWidth Only supports AT_IMMEDIATE"
	 	// .if(!_isImmOrNone(offsetX)) .error "Layer_DefineScreenLayer: offsetX Only supports AT_IMMEDIATE or AT_NONE"
	 	// .if(!_isImmOrNone(ncm)) .error "Layer_DefineScreenLayer: ncm Only supports AT_IMMEDIATE or AT_NONE"

		.var index = Layer_LayerList.size()

		.if(!LAYER_RESOLUTION_DEFINED) {
			.error("Layer_DefineBGLayer: Must define a resolution first with Layer_DefineResolution")
		}

		.eval Layer_LayerList.add(Hashtable())
		.eval Layer_LayerList.get(index).put("rrbSprites", false)
		.eval Layer_LayerList.get(index).put("gotoX", S65_SCREEN_LOGICAL_ROW_WIDTH )
		.eval Layer_LayerList.get(index).put("startAddr", S65_SCREEN_LOGICAL_ROW_WIDTH + 2 )
		.eval Layer_LayerList.get(index).put("charWidth", charWidth )
		.eval Layer_LayerList.get(index).put("offsetX", offsetX )
		.eval Layer_LayerList.get(index).put("ncm", ncm)

		lda #<charWidth 
		sta [Layer_LayerWidth + index * 2]
		lda #>charWidth 
		sta [Layer_LayerWidth + index * 2 + 1]
			
		lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
		sta [Layer_AddrOffsets + index * 2]
		lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
		sta [Layer_AddrOffsets + index * 2 + 1]

		.eval S65_SCREEN_ROW_WIDTH += charWidth + 1 //add a gotox
		.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars

		//screen ram
		lda #<offsetX
		sta Layer_GotoXPositions + index * 2
		lda #>offsetX
		sta Layer_GotoXPositions + index * 2 + 1	

		//color ram
		.var colRamB0 = $10 //GOTOX On!
		.var colRamB1 = $00 //This byte is actually for the data not the gotox header
		.if(index == 0) {
			.eval colRamB0 = colRamB0 | $80 //Transparency
		}
		.if(ncm) {
			.eval colRamB1 = colRamB1 | $08
		}
		lda #colRamB0
		sta Layer_GotoXColorPositions + 0
		lda #colRamB1
		sta Layer_GotoXColorPositions + 1

		lda #index
	S65_AddToMemoryReport("Layer_DefineScreenLayer")
 }



/**
 * .macro DefineRRBSpriteLayer
 * 
 * Defines a new RRB Sprite layer in Screen RAM. RRB Sprite layers are always NCM mode (16x8px chars).
 * IO for this layer is assigned to the Layer IO dynamic memory area<br>
 * Note that chars per line is NOT the max sprites per line as a sprite can be any multiple of 16 chars wide<br><br>
 * 
 * 
 * RRB Sprite space is a buffer limited by a set amount of chars per line. During an update each new Sprite 
 * uses a GOTOX marker and however many RRB chars wide it is. So, for example, a 32x32 RRB sprite 
 * is 2 chars wide + a GOTOX marker so will take 3 chars of space.<br><br>
 * Note: There is a RRB Sprite hard limit of 256 per RRB Sprite layer.
 * 
 * The majority of the memory and cpu time consumed by the RRB Sprite system is a result of the number of maxSprites.
 * Reducing this number will have the best impact on SpriteIO area memory usage as each sprite slot (regardless if its enabled or not in
 * <a href="#Sprite_IOflags">Sprite_IOflags</a>will use at least 10 bytes each. And every sprite that IS enabled will use some cpu time to 
 * update.
 * 
 * @namespace Layer
 * 
 * @param {byte} charsPerLine The number of RRB chars reserved in the buffer for this layer, lower numbers improve performance but reduce the number of visible sprites per line
 * @param {byte} maxSprites The maximum number of RRB Sprites for this layer, lower numbers improve performance
 * 
 * @registers A
 * @flags nz
 *  
 * @setreg {byte} A The layer number this layer was created at
 */
.macro Layer_DefineRRBSpriteLayer (charsPerLine, maxSprites) {
	S65_AddToMemoryReport("Layer_DefineBGLayer")

	// .eval charsPerLine = maxSprites/2 
	.var index = Layer_LayerList.size()

	.if(index == 0) {
		.error("Must define a BG layer first with S65_DefineBGLayer.")
	}

	.eval Layer_LayerList.add(Hashtable())
	.eval Layer_LayerList.get(index).put("rrbSprites", true)
	.eval Layer_LayerList.get(index).put("maxSprites", maxSprites)
	.eval Layer_LayerList.get(index).put("charWidth", charsPerLine)
	.eval Layer_LayerList.get(index).put("startAddr", S65_SCREEN_LOGICAL_ROW_WIDTH)
	.eval Layer_LayerList.get(index).put("gotoX", S65_SCREEN_LOGICAL_ROW_WIDTH )
	.eval Layer_LayerList.get(index).put("offsetX", $02a0)
	.eval Layer_LayerList.get(index).put("ncm", true)
	.eval Layer_LayerList.get(index).put("io", Hashtable())

	lda #<charsPerLine 
	sta [Layer_LayerWidth + index * 2]
	lda #>charsPerLine 
	sta [Layer_LayerWidth + index * 2 + 1]

	lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2]
	lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
	sta [Layer_AddrOffsets + index * 2 + 1]

	.eval S65_SCREEN_ROW_WIDTH += charsPerLine 
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2 //16bit chars	

	//screen ram
	lda #$00
	sta Layer_GotoXPositions + index * 2
	lda #$00
	sta Layer_GotoXPositions + index * 2 + 1

	//color ram
	.var colRamB0 = $90 //RRB sprite layer default is always transparent and offscreen
	.var colRamB1 = $08 //This byte is actually for the data not the gotox header and this layer is NCM on!
	lda #colRamB0
	sta Layer_GotoXColorPositions + 0
	lda #colRamB1
	sta Layer_GotoXColorPositions + 1

	lda #index

	S65_AddToMemoryReport("Layer_DefineBGLayer")
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
	S65_AddToMemoryReport("Layer_InitScreen")
	.const GOTOX = 1

	.eval S65_SCREEN_RAM = screenBaseAddress


	//Total screen width in chars = 
	// Base screen width +
	// ScreenLayer Widths +
	// ScreenLayers count (gotox)
	// RRB Layers total charsPerLine +
	// Terminating GOTOX + char (2chars)

	S65_Trace("Layer_InitScreen")
	S65_Trace("============================")
	S65_Trace("Calculating screen configuration...")
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
	lda #$a0
	sta [Layer_GotoXPositions + Layer_LayerList.size() * 2]
	lda #$02
	sta [Layer_GotoXPositions + Layer_LayerList.size() * 2 + 1]

	.eval S65_SCREEN_TERMINATOR_OFFSET = S65_SCREEN_ROW_WIDTH
	.eval S65_SCREEN_ROW_WIDTH += [GOTOX + 1]
	.eval S65_SCREEN_LOGICAL_ROW_WIDTH = S65_SCREEN_ROW_WIDTH * 2

	S65_Trace("")
	S65_Trace("Screen row width is $"+toHexString(S65_SCREEN_ROW_WIDTH)+ " chars / $"+ toHexString(S65_SCREEN_LOGICAL_ROW_WIDTH) + " bytes.")
	S65_Trace("")

	jsr S65.Init

	//Set logical row width
	//bytes per screen row (16 bit value in $d058-$d059)
	lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
	sta $d058
	lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
	sta $d059

	//Set number of chars per row
	lda #<S65_SCREEN_ROW_WIDTH
	sta $d05e
	lda $d063
	and #%11001111
	ora #[[>S65_SCREEN_ROW_WIDTH] << 4]
	sta $d063

	//Relocate screen RAM using $d060-$d063
	lda #<S65_SCREEN_RAM 
	sta $d060 
	lda #>S65_SCREEN_RAM 
	sta $d061
	lda #[S65_SCREEN_RAM >> 16] 
	sta $d062
	lda $d063
	and #%11111100
	ora #[S65_SCREEN_RAM >> 24] 
	sta $d063

	//Set border and text positions for this resolution
	.var ncmMult = 1//Layer_LayerList.get(0).get("ncm") ? 2 : 1
	.var adjust = S65_VISIBLE_SCREEN_CHAR_HEIGHT * 8
	.var borderTop = $130 - adjust
	.var borderBottom = borderTop + S65_VISIBLE_SCREEN_CHAR_HEIGHT * 8 * 2
	.var textYpos = borderTop - 1


	lda #$80    //Enable Rewrite double buffering
    trb $d051   //prevents clipping in FCM (bit 7)

	.if(S65_VISIBLE_SCREEN_CHAR_HEIGHT <= 32) {
		lda #$08
		trb $d031		
		System_EnableFastRRB()

		lda #<borderTop
		sta $d048
		lda $d049 
		and #%11110000
		ora #>borderTop 
		sta $d049

		lda #<[borderBottom - 1]
		sta $d04a
		lda $d04b 
		and #%11110000
		ora #>[borderBottom -1]
		sta $d04b

		lda #<[textYpos -3]
		sta $d04e 
		lda $d04f 
		and #%11110000
		ora #>[textYpos -3]
		sta $d04f

	} else {
		.eval adjust = S65_VISIBLE_SCREEN_CHAR_HEIGHT * 4
		.eval borderTop = $130 - adjust
		.eval borderBottom = borderTop + S65_VISIBLE_SCREEN_CHAR_HEIGHT * 4 * 2
		.eval textYpos = borderTop - 1
		lda #$08
		tsb $d031

		lda #$00
		sta $d05b

		lda #<[borderTop -1]
		sta $d048
		lda $d049 
		and #%11110000
		ora #>[borderTop -1]
		sta $d049

		lda #<[borderBottom -1]
		sta $d04a
		lda $d04b 
		and #%11110000
		ora #>[borderBottom -1]
		sta $d04b

		lda #<textYpos 
		sta $d04e 
		lda $d04f 
		and #%11110000
		ora #>textYpos 
		sta $d04f
	}


	.var adjustH = S65_VISIBLE_SCREEN_CHAR_WIDTH * 8  * ncmMult

	.if(S65_VISIBLE_SCREEN_CHAR_WIDTH <= (Layer_SCREEN_HORIZ_BREAK / ncmMult)) {
		// Set VIC to use 40 column mode display
		//turn off bit 7 
		lda #$80		
		trb $d031 

		.var textXpos = $18d - adjustH
		.var borderSide = textXpos + 3

		lda #S65_VISIBLE_SCREEN_CHAR_HEIGHT
		sta $d07b

	} else {
		// Set VIC to use 80 column mode display
		//turn on bit 7 
		lda #$80		
		tsb $d031 

		.eval adjustH = S65_VISIBLE_SCREEN_CHAR_WIDTH * 4  * ncmMult
		lda #S65_VISIBLE_SCREEN_CHAR_HEIGHT
		sta $d07b
	}

	.if(LAYER_RESOLUTION_STRETCHED) {
		.var textXpos = $3c
		.var borderSide = textXpos + 3

		.var hscale = ((S65_VISIBLE_SCREEN_CHAR_WIDTH  * ncmMult)/ (Layer_MAX_SCREEN_WIDTH - 0.5)) * $78
		.if(S65_VISIBLE_SCREEN_CHAR_WIDTH <= (Layer_SCREEN_HORIZ_BREAK / ncmMult)) {
			.eval hscale = ((S65_VISIBLE_SCREEN_CHAR_WIDTH * ncmMult) / (Layer_MAX_SCREEN_WIDTH/2)) * $78
		}
		lda #hscale
		sta $d05a	

		lda #<textXpos 
		sta $d04c 
		lda $d04d 
		and #%11110000
		ora #>textXpos 
		sta $d04d

		lda #<borderSide
		sta $d05c
		lda $d05d
		and #%11110000
		ora #>borderSide 
		sta $d05d
	} else {
		.var textXpos = $18f - adjustH
		.var borderSide = textXpos + 1

		lda #<textXpos 
		sta $d04c 
		lda $d04d 
		and #%11110000
		ora #>textXpos 
		sta $d04d

		lda #<borderSide
		sta $d05c
		lda $d05d
		and #%11110000
		ora #>borderSide 
		sta $d05d			
	}


		//Store screen and color ram address upper bytes
		lda #<S65_SCREEN_RAM
		sta S65_BaseScreenRamPointer + 0	
		lda #>S65_SCREEN_RAM
		sta S65_BaseScreenRamPointer + 1		
		lda #[S65_SCREEN_RAM >> 16]
		sta S65_BaseScreenRamPointer + 2	
		sta S65_ScreenRamPointer + 2
		lda #[S65_SCREEN_RAM >> 24]
		sta S65_BaseScreenRamPointer + 3	
		sta S65_ScreenRamPointer + 3

		lda #<S65_COLOR_RAM
		sta S65_BaseColorRamPointer + 0	
		lda #>S65_COLOR_RAM
		sta S65_BaseColorRamPointer + 1
		lda #[S65_COLOR_RAM >> 16]
		sta S65_BaseColorRamPointer + 2
		sta S65_ColorRamPointer + 2
		lda #[S65_COLOR_RAM >> 24]
		sta S65_BaseColorRamPointer + 3
		sta S65_ColorRamPointer + 3

		lda #<S65_SCREEN_LOGICAL_ROW_WIDTH
		sta Layer_LogicalWidth + 0
		lda #>S65_SCREEN_LOGICAL_ROW_WIDTH
		sta Layer_LogicalWidth + 1

	//ColorRAM initialisation
		.const SCREEN_BYTE_SIZE = S65_SCREEN_LOGICAL_ROW_WIDTH * S65_VISIBLE_SCREEN_CHAR_HEIGHT
		DMA_Execute job
		
		//FINAL SETUP based on previously unknown values
		_configureCharModes()

		lda #[Layer_LayerList.size()]
		sta _Layer_Update.ListSize0
		lda #[Layer_LayerList.size() * 2 + 2]
		sta _Layer_Update.ListSize1

		lda #S65_VISIBLE_SCREEN_CHAR_HEIGHT
		sta _Layer_Update.ScreenHeight

		jmp end


	job:
		DMA_Header #$00 : #$ff
		DMA_FillJob #0 : S65_COLOR_RAM : #SCREEN_BYTE_SIZE : #FALSE			

	S65_AddToMemoryReport("Layer_InitScreen")

		//This area can be used for dynamic memory based on the size of layers and sprites
		//////////////////////////
		//Sprites data
		//////////////////////////
		_configureDynamicData(*)
		
	end:

		//Has to be called after the _configureDynamicData call
		lda #<Layer_DynamicDataTable 
		sta S65_DynamicLayerData + 0
		lda #>Layer_DynamicDataTable
		sta S65_DynamicLayerData + 1
		



	.if(S65_SCREEN_LOGICAL_ROW_WIDTH > $1f4) {
		.error "Pixel clock limits S65_SCREEN_LOGICAL_ROW_WIDTH to values <= $1f4, you are using $"+toHexString(S65_SCREEN_LOGICAL_ROW_WIDTH)+" bytes per row.  Please reduce your layer widths..."
	}
}







.macro _configureDynamicData(pc) {
	S65_AddToMemoryReport("Layer_DynamicDataAndIO")

	S65_Trace("Configuring dynamic layer memory...")
	S65_Trace("")

	S65_Trace("")	

		//Add layer IO Data
		.var layerAddr = List()

		.for(var i=0; i<Layer_LayerList.size(); i++) {
			.eval Layer_LayerList.get(i).put("dynamicDataAddr", *)
			.eval layerAddr.add(*)
			S65_Trace("#"+i+"    $"+toHexString(*)+" Layer")
			.word Layer_LayerList.get(i).get("offsetX") //GOTOX position value

			.if(Layer_LayerList.get(i).get("rrbSprites") == true) {
				//rrb only
				Sprite_GenerateLayerData(i)
			} else {
				//screenlayer only
				
			}
			
		}
		S65_Trace("============================")

	//Layer IO address lookup table

	.eval Layer_DynamicDataTable = *	
		.print("Layer_DynamicDataTable $"+toHexString(Layer_DynamicDataTable))	
		.for(var i=0 ; i< layerAddr.size(); i++) {
			.print("layerAddr"+i+"   $"+ toHexString(layerAddr.get(i)))
		}
		.fill layerAddr.size(), [<layerAddr.get(floor(i)), >layerAddr.get(i)]
	
	//Screen row address table
	.eval Layer_RowAddressLSB = *
		.fill S65_VISIBLE_SCREEN_CHAR_HEIGHT, <[S65_SCREEN_RAM + i * S65_SCREEN_LOGICAL_ROW_WIDTH + 2]
	.eval Layer_RowAddressMSB = *
		.fill S65_VISIBLE_SCREEN_CHAR_HEIGHT, >[S65_SCREEN_RAM + i * S65_SCREEN_LOGICAL_ROW_WIDTH + 2]

	.eval Layer_RowAddressBaseLSB = *
		.fill S65_VISIBLE_SCREEN_CHAR_HEIGHT, <[S65_SCREEN_RAM + i * S65_SCREEN_LOGICAL_ROW_WIDTH]
	.eval Layer_RowAddressBaseMSB = *
		.fill S65_VISIBLE_SCREEN_CHAR_HEIGHT, >[S65_SCREEN_RAM + i * S65_SCREEN_LOGICAL_ROW_WIDTH]


	.eval Layer_SpriteIOAddrLSB = *
		.fill Layer_LayerList.size(), Layer_LayerList.get(i).get("rrbSprites") == true ? <Layer_LayerList.get(i).get("spriteIOAddr") : 0
	.eval Layer_SpriteIOAddrMSB = *
		.fill Layer_LayerList.size(), Layer_LayerList.get(i).get("rrbSprites") == true ? >Layer_LayerList.get(i).get("spriteIOAddr") : 0
	.eval Layer_IsRRBSprite = *
		.fill Layer_LayerList.size(), Layer_LayerList.get(i).get("rrbSprites") == true ? 1 : 0
	

	//Tables
	.eval Layer_src = *
		.fill Layer_LayerList.size(), Layer_LayerList.get(i).get("ncm") ? $08: $00
	.eval Layer_width = *		
		.fill Layer_LayerList.size(), Layer_LayerList.get(i).get("charWidth") * 2
	.eval Layer_offsetAdd = *		
		.var layerOffset = 0
		.for(var i=0; i<Layer_LayerList.size(); i++) {
			.var layer = Layer_LayerList.get(i)
			.byte [layer.get("startAddr") - layerOffset]
			.if( i == Layer_LayerList.size()-1) .byte [[layer.get("charWidth") * 2] + 4]
			.eval layerOffset = layer.get("startAddr")
		}		

		

	S65_AddToMemoryReport("Layer_DynamicDataAndIO")
}



.macro _configureCharModes() {
		S65_SetBasePage()

		jmp !+
		
		//Tables
		.eval Layer_src = *
			.fill Layer_LayerList.size(), Layer_LayerList.get(i).get("ncm") ? $08: $00
		.eval Layer_width = *		
			.fill Layer_LayerList.size(), Layer_LayerList.get(i).get("charWidth") * 2
		.eval Layer_offsetAdd = *		
			.var layerOffset = 0
			.for(var i=0; i<Layer_LayerList.size(); i++) {
				.var layer = Layer_LayerList.get(i)
				.byte [layer.get("startAddr") - layerOffset]
				.if( i == Layer_LayerList.size()-1) .byte [[layer.get("charWidth") * 2] + 4]
				.eval layerOffset = layer.get("startAddr")
			}
	!:

		//reset color ram pointer
		lda.z S65_BaseColorRamPointer + 0
		sta.z S65_ColorRamPointer + 0
		lda.z S65_BaseColorRamPointer + 1
		sta.z S65_ColorRamPointer + 1

		//loop through screen rows
		ldx #$00 //row
	!rows:
		//loop through layers
		ldy #$00
	!loop:
				//move to the start off this layers row
				clc
				lda.z S65_ColorRamPointer + 0
				adc Layer_offsetAdd, y
				sta.z S65_ColorRamPointer + 0
				bcc !+
				inc.z S65_ColorRamPointer + 1	
			!:

				//fill this layers row only
				ldz #$00
			!:
				lda Layer_src, y
				sta ((S65_ColorRamPointer)), z 
				inz 
				lda #$ff
				sta ((S65_ColorRamPointer)), z 
				inz 
				tza
				cmp Layer_width, y
				bne !-

				
		iny
		cpy #[Layer_LayerList.size()]
		bcc !loop-

		//advance to the nexxt screen row
		clc
		lda.z S65_ColorRamPointer + 0
		adc Layer_offsetAdd, y
		sta.z S65_ColorRamPointer + 0
		bcc !+
		inc.z S65_ColorRamPointer + 1	
	!:

		inx 
		cpx #S65_VISIBLE_SCREEN_CHAR_HEIGHT
		bne !rows-
		jmp end



		dmaClearJob:
			DMA_Header 
			DMA_Step #$0100 : #$0200

			.var lengthJobA = * + $02
			.var destJobA = * + $07
			.var jobDataA = * + $04
			.var jobChainA = * + $04
			DMA_FillJob #$0000 : S65_SCREEN_RAM + 0: #$00 : #TRUE

			.var lengthJobB = * + $02
			.var destJobB = * + $07
			.var jobDataB = * + $04
			DMA_FillJob #$0000 : S65_SCREEN_RAM + 1: #$00 : #FALSE

		dmaClearJob2:	
			DMA_Header #$00 : #$ff
			DMA_Step #$0100 : #$0200
			.var lengthJobC= * + $02
			.var destJobC = * + $07
			.var jobDataC = * + $04
			DMA_FillJob #$0000 : S65_COLOR_RAM + 0: #$00 : #FALSE

		dmaClearJob3:	
			DMA_Header #$00 : #$ff
			DMA_Step #$0100 : #$0200
			.var lengthJobD= * + $02
			.var destJobD = * + $07
			DMA_FillJob #$0090 : S65_COLOR_RAM + 0: #$00 : #TRUE
			.var lengthJobE= * + $02
			.var destJobE = * + $07			
			DMA_FillJob #$0000 : S65_COLOR_RAM + 1: #$00 : #FALSE


		//generate DMA lists for clearing a layer
		.eval Layer_DMAClear = *
		DMAClear: {
				//X=charLo, Y=charHi, A = layer
				stx jobDataA + 0
				sty jobDataB + 0
				asl 
				tay

				clc 
				lda Layer_AddrOffsets, y 	
				adc #<[S65_SCREEN_RAM + 2]				
				sta destJobA + 0
				sta destJobB + 0
				lda Layer_AddrOffsets + 1, y 
				adc #>[S65_SCREEN_RAM + 2]				
				sta destJobA + 1	
				sta destJobB + 1	

				inc destJobB + 0
				bne !+
				inc destJobB + 1	
			!:
				
			
				//Layer length 
				lda Layer_LayerWidth, y 
				
				sta lengthJobA + 0				
				sta lengthJobB + 0				

				lda Layer_LayerWidth + 1, y

				sta lengthJobA + 1
				sta lengthJobB + 1


				ldx #S65_VISIBLE_SCREEN_CHAR_HEIGHT
			!loop:

				DMA_Execute dmaClearJob

					lda destJobA + 0	
					clc 
					adc #<S65_SCREEN_LOGICAL_ROW_WIDTH		
					sta destJobA + 0
					sta destJobB + 0

					lda destJobA + 1
					adc #>S65_SCREEN_LOGICAL_ROW_WIDTH	
					sta destJobA + 1	
					sta destJobB + 1	

					inc destJobB + 0
					bne !+
					inc destJobB + 1	
				!:

				dex 
				bne !loop-

				
				rts 

		}

		.eval Layer_DMAClearColorRRB = *
		DMAClearColorRRB: {
				//X=color,  A = layer
				asl 
				tay

				clc 
				lda Layer_AddrOffsets, y 	
				adc #<[S65_COLOR_RAM]				
				sta destJobD + 0
				sta destJobE + 0
				lda Layer_AddrOffsets + 1, y 
				adc #>[S65_COLOR_RAM]					
				sta destJobD + 1	
				sta destJobE + 1	
				
				inc destJobE + 0
				bne !+
				inc destJobE + 1	
			!:

				//Layer length 
			

				lda Layer_LayerWidth + 1, y
				sta lengthJobD + 1
				sta lengthJobE + 1

				lda Layer_LayerWidth, y 		
				sta lengthJobD + 0				
				sta lengthJobE + 0	

				ldx #S65_VISIBLE_SCREEN_CHAR_HEIGHT
			!loop:
				
				DMA_Execute dmaClearJob3

					lda destJobD + 0	
					clc 
					adc #<S65_SCREEN_LOGICAL_ROW_WIDTH		
					sta destJobD + 0
					sta destJobE + 0

					lda destJobD + 1
					adc #>S65_SCREEN_LOGICAL_ROW_WIDTH		
					sta destJobD + 1	
					sta destJobE + 1	

					inc destJobE + 0
					bne !+
					inc destJobE + 1	
				!:
				dex 
				bne !loop-

				
				rts 			
		}

		.eval Layer_DMAClearColor = *
		DMAClearColor: {
				//X=color,  A = layer
				stx jobDataC + 0
				asl 
				tay

				clc 
				lda Layer_AddrOffsets, y 	
				adc #<[S65_COLOR_RAM + 3]				
				sta destJobC + 0
				lda Layer_AddrOffsets + 1, y 
				adc #>[S65_COLOR_RAM + 3]					
				sta destJobC + 1	
				
			
				//Layer length 
				lda Layer_LayerWidth, y 			
				sta lengthJobC + 0				

				lda Layer_LayerWidth + 1, y
				sta lengthJobC + 1


				ldx #S65_VISIBLE_SCREEN_CHAR_HEIGHT
			!loop:
				
				DMA_Execute dmaClearJob2

					lda destJobC + 0	
					clc 
					adc #<S65_SCREEN_LOGICAL_ROW_WIDTH		
					sta destJobC + 0

					lda destJobC + 1
					adc #>S65_SCREEN_LOGICAL_ROW_WIDTH		
					sta destJobC + 1	

				dex 
				bne !loop-

				
				rts 

		}

	end:
		S65_RestoreBasePage()
}


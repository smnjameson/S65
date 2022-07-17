/**
* .pseudocommand AddText
*
* Writes a string of bytes to the given layer and co-ordinate. Optionally allows the
* use of color, setting Color RAM Byte 1 all bits (so includes bit4-blink, bit5-reverse, bit6-bold and bit7-underline), 
* this will only work on non NCM layers with char indices less than $100 <br><br>
* 
* Note: As layer screen rows are interlaced in memory, its important to not let
* the string extend off the right edge of the layer as it can break the RRB on other layers. 
* There is an upper limit string length of 128
*
* @namespace Layer
*
* @param {word} {IMM} layer The layer number to write to
* @param {word} {REG|IMM} xpos Layer char X position
* @param {word} {REG|IMM} ypos Layer char Y position
* @param {word} {ABS} textPtr The address to fetch char data from
* @param {byte} {REG|IMM|ABS|ABX|ABY} color Color to write to color ram
*
* @flags znc
*/
.pseudocommand Layer_AddText layer: xpos: ypos: textPtr : color {
		S65_AddToMemoryReport("Layer_AddText")
		S65_SaveRegisters()

		.if(!_isImm(layer)) .error "Layer_AddText: layer does not support this addressing mode"
		.if(!_isReg(xpos) && !_isImm(xpos)) .error "Layer_AddText: xpos does not support this addressing mode"
		.if(!_isReg(ypos) && !_isImm(ypos)) .error "Layer_AddText: ypos does not support this addressing mode"
		.if(!_isAbs(textPtr)) .error "Layer_AddText: textPtr does not support this addressing mode"
		.if(!_isAbsXY(color) && !_isImm(color) && !_isReg(color)) .error "Layer_AddText: color does not support this addressing mode"
		
		_saveIfReg(color,	SMcolor)
		_saveIfReg(xpos, 	S65_PseudoReg + 1)
		_saveIfReg(ypos, 	S65_PseudoReg + 2)

		.const SCREEN_PTR = S65_ScreenRamPointer
		.const COLOR_PTR = S65_ColorRamPointer
		.const TEXT_PTR = S65_TempWord1

		S65_SetBasePage()
			.var ADDRESS = Layer_GetScreenAddress(layer.getValue(), xpos.getValue(), ypos.getValue())

			.if(_isImm(xpos) && _isImm(ypos)) {
				.eval ADDRESS = Layer_GetScreenAddress(layer.getValue(), xpos.getValue(), ypos.getValue())
				lda #<ADDRESS
				sta.z S65_ScreenRamPointer + 0
				lda #>ADDRESS
				sta.z S65_ScreenRamPointer + 1


			}
			.if(_isReg(xpos) && _isImm(ypos)) {
					.eval ADDRESS = Layer_GetScreenAddress(layer.getValue(), 0, ypos.getValue())
					asl.z S65_PseudoReg + 1
					clc
					lda #<ADDRESS
					adc.z S65_PseudoReg + 1
					sta.z S65_ScreenRamPointer + 0
					lda #>ADDRESS
					adc #$00
					sta.z S65_ScreenRamPointer + 1
			}

			.if(_isReg(xpos) && _isReg(ypos)) {
					asl.z S65_PseudoReg + 1 //xpos
					ldx S65_PseudoReg + 2 //ypos
					clc 
					lda Layer_RowAddressLSB, x 
					adc.z S65_PseudoReg + 1
					sta.z S65_ScreenRamPointer + 0
					lda Layer_RowAddressMSB, x 
					adc #$00
					sta.z S65_ScreenRamPointer + 1

					lda #layer.getValue()
					asl 
					tax
					clc 	
					lda.z S65_ScreenRamPointer + 0 
					adc.z Layer_AddrOffsets + 0, x
					sta.z S65_ScreenRamPointer + 0
					lda.z S65_ScreenRamPointer + 1
					adc.z Layer_AddrOffsets + 1, x
					sta.z S65_ScreenRamPointer + 1
				} 

			.if(_isImm(xpos) && _isReg(ypos)) {
					ldx S65_PseudoReg + 2

					clc 
					lda Layer_RowAddressLSB, x 
					adc.z #[xpos.getValue() * 2]
					sta.z S65_ScreenRamPointer + 0
					lda Layer_RowAddressMSB, x 
					adc #$00
					sta.z S65_ScreenRamPointer + 1


					lda #layer.getValue()
					asl 
					tax
					clc 	
					lda.z S65_ScreenRamPointer + 0 
					adc.z Layer_AddrOffsets + 0, x
					sta.z S65_ScreenRamPointer + 0
					lda.z S65_ScreenRamPointer + 1
					adc.z Layer_AddrOffsets + 1, x
					sta.z S65_ScreenRamPointer + 1					
			}
		
			clc
			lda.z S65_ScreenRamPointer + 0
			adc #<[S65_COLOR_RAM - S65_SCREEN_RAM]
			sta.z S65_ColorRamPointer + 0
			lda.z S65_ScreenRamPointer + 1
			adc #>[S65_COLOR_RAM - S65_SCREEN_RAM]
			sta.z S65_ColorRamPointer + 1					

			lda #<textPtr.getValue()
			sta.z TEXT_PTR + 0
			lda #>textPtr.getValue()
			sta.z TEXT_PTR + 1

			lda SMcolor:color 		
			sta _Layer_AddText.VALUE 

			jsr _Layer_AddText
		S65_RestoreRegisters()
		S65_AddToMemoryReport("Layer_AddText")
}
_Layer_AddText: {
			.const TEXT_PTR = S65_TempWord1

			phy
			phz
			ldz #$00
			ldy #$00
		!loop:
			iny
			lda.z (TEXT_PTR), y
			cmp #$ff
			beq !exit+
			dey
			
				lda.z (TEXT_PTR), y
				sta ((S65_ScreenRamPointer)), z
				inz
				iny

				lda.z (TEXT_PTR), y
				sta ((S65_ScreenRamPointer)), z
				 	
				lda.z VALUE:#$BEEF
				sta ((S65_ColorRamPointer)), z

				inz
				iny
			bra !loop-
		!exit:
		plz
		ply
		S65_RestoreBasePage()

		rts
}	



/**
* .pseudocommand ClearAllLayers
*
* Fills the screen RAM area with a given 16bit value. Note this will overwrite any 
* RRB GotoX markers also
* 
* @namespace Layer 
*
* @param {word?} {REG|IMM|ABS} clearChar The 16bit char value to clear with, defaults to $0000
* 
* @registers A
* @flags zn
*/
.pseudocommand Layer_ClearAllLayers clearChar {
	S65_AddToMemoryReport("Layer_ClearAllLayers")
			.if(_isReg(clearChar)) {
				 _saveIfReg(clearChar, S65_PseudoReg + 0)
			} else {
				.if(!_isAbsImmOrNone(clearChar)) .error "Layer_ClearAllLayers: does not support this addressing mode"
			}
	        
			.const SCREEN_BYTE_SIZE = S65_SCREEN_LOGICAL_ROW_WIDTH * S65_VISIBLE_SCREEN_CHAR_HEIGHT
			//REGISTER
			.if(_isReg(clearChar)) {
				lda S65_PseudoReg + 0
				sta jobIf.Job1_Source
				lda #$00
				sta jobIf.Job2_Source	
			} 

			//ABSOLUTE
			.if(_isAbs(clearChar) && !_isReg(clearChar)) {
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
				DMA_FillJob #<clearChar.getValue() : S65_SCREEN_RAM + 0 : #SCREEN_BYTE_SIZE/2 : #TRUE

				.label Job2_Source = * + $04		
				DMA_FillJob #>clearChar.getValue() : S65_SCREEN_RAM + 1 : #SCREEN_BYTE_SIZE/2 : #FALSE

			} else {
				DMA_FillJob #$00 : S65_SCREEN_RAM + 0 : #SCREEN_BYTE_SIZE : #FALSE						
			}
		end:
	S65_AddToMemoryReport("Layer_ClearAllLayers")
}


/**
* .pseudocommand ClearLayer
*
* Fills the screen RAM area for the layer with a given 16bit value. 
* 
* @namespace Layer The layer number to clear
*
* @param {byte} {IMM} layer <add a description here>
* @param {byte} {IMM} clearChar The 16bit char value to clear with, defaults to $0000
*
* @registers AXY
* @flags nzc
* 
* @return {byte} A <add description here> 
*/
.pseudocommand Layer_ClearLayer layer : clearChar {
	S65_AddToMemoryReport("Layer_ClearLayer")
		.if(!_isImm(layer) || !_isImm(clearChar)) .error "Layer_ClearLayer: does not support this addressing mode"	

		//X=charLo, Y=charHi, A = layer
.print ("layer.getValue(): $" + toHexString(layer.getValue()))
		lda #layer.getValue()
		ldx #<clearChar.getValue()
		ldy #>clearChar.getValue()
		jsr Layer_DMAClear
	S65_AddToMemoryReport("Layer_ClearLayer")
}



/**
* .pseudocommand UpdateLayerOffsets
*
* Updates the RRB GotoX markers for all but the 
* RRB sprite layers
* 
* @namespace Layer
*
* @registers A
* @flags znc
*/
.pseudocommand Layer_UpdateLayerOffsets {
		S65_AddToMemoryReport("Layer_UpdateLayerOffsets")
		jsr _Layer_UpdateLayerOffsets
		S65_AddToMemoryReport("Layer_UpdateLayerOffsets")
}
_Layer_UpdateLayerOffsets: {
		phx 
		phy
		phz

		.const DYN_TABLE = S65_TempWord1
		S65_SetBasePage()
			//Transfer the GOTOX values from the dynamic IO
			ldy #$00
			ldx #$00
			ldz #$00
		!loop:
			lda (S65_DynamicLayerData), y
			iny
			sta.z DYN_TABLE + 0
			lda (S65_DynamicLayerData), y
			dey
			sta.z DYN_TABLE + 1

			//yreg = 0 {word} Layer_IOGotoX
			lda (DYN_TABLE), z
			inz
			sta Layer_GotoXPositions, y
			inx 
			iny
			lda (DYN_TABLE), z 
			dez
			and #$03 //Clamp the value to only use the first 2 bits	
			sta Layer_GotoXPositions, y 
			iny
			inx
			cpx ListSize0:#$BEEF
			bne !loop-



			//add the rrb GOTOX markers
			.var offset = 0
			ldx #$00
		!outerLoop:
 
			clc 
			lda Layer_AddrOffsets, x//0
			adc.z S65_BaseColorRamPointer + 0
			inx
			sta.z S65_ColorRamPointer + 0
			lda Layer_AddrOffsets, x//1
			adc.z S65_BaseColorRamPointer + 1
			sta.z S65_ColorRamPointer + 1
			dex

			clc 
			lda Layer_AddrOffsets, x//0
			adc.z S65_BaseScreenRamPointer + 0
			inx
			sta.z S65_ScreenRamPointer + 0
			lda Layer_AddrOffsets, x//1
			adc.z S65_BaseScreenRamPointer + 1
			sta.z S65_ScreenRamPointer + 1
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

				sta ((S65_ColorRamPointer)), z 
				inz
				lda #$00
				sta ((S65_ColorRamPointer)), z 
				dez	

				//SCREEN RAM
				lda Layer_GotoXPositions, x//0
				inx
				sta ((S65_ScreenRamPointer)), z 
				inz
				lda ((S65_ScreenRamPointer)), z
				and #%11111100
				ora Layer_GotoXPositions, x//1
				dex
				sta ((S65_ScreenRamPointer)), z 


				//next row
				clc
				lda.z S65_ColorRamPointer + 0
				adc Layer_LogicalWidth + 0
				sta.z S65_ColorRamPointer + 0
				lda.z S65_ColorRamPointer + 1
				adc Layer_LogicalWidth + 1
				sta.z S65_ColorRamPointer + 1

				clc
				lda.z S65_ScreenRamPointer + 0
				adc Layer_LogicalWidth + 0
				sta.z S65_ScreenRamPointer + 0
				lda.z S65_ScreenRamPointer + 1
				adc Layer_LogicalWidth + 1
				sta.z S65_ScreenRamPointer + 1


				dey 
				bne !loop-

				inx
				inx
			cpx ListSize1:#$BEEF
			bcc !outerLoop-
		!end:
		S65_RestoreBasePage()

		plz
		ply
		plx
		rts
}




/**
* .pseudocommand Get
*
* This method sets the currently active layer for all Layer commands.<br><br>
* Note: This method will also call <a href="#S65_SetBasePage">S65_SetBasePage</a> which 
* is required for the Layer functions
* 
* @namespace Layer
* @param {byte} {IMM|REG|ABSXY} layerNum The layer to fetch
* @registers B
* @flags nzc
*/
.pseudocommand Layer_Get layer {
	S65_AddToMemoryReport("Layer_Get")
	.if(!_isImm(layer) && !_isReg(layer) && !_isAbs(layer) && !_isAbsXY(layer)) .error "Layer_Get:"+ S65_TypeError
	_saveIfReg(layer, S65_PseudoReg + 0)

	pha
	S65_SetBasePage()
		.if(!_isReg(layer)) {
			lda layer
			.eval LastLayerValue2 = layer.getValue() 
		} else {
			lda.z S65_PseudoReg + 0
			.eval LastLayerValue2 = 0

		}
		jsr _Layer_Get_SetPointers

	pla
	S65_AddToMemoryReport("Layer_Get")
}
_Layer_Get_SetPointers: {
	phy
		sta.z S65_CurrentLayer
		asl 
		tay 
		lda (S65_DynamicLayerData), y 
		sta.z S65_LastLayerIOPointer + 0
		lda (S65_DynamicLayerData), y 
		sta.z S65_LastLayerIOPointer + 0
		iny
		lda (S65_DynamicLayerData), y 
		sta.z S65_LastLayerIOPointer + 1
	ply
	rts
}	
.var LastLayerValue2 = 0



/**
* .pseudocommand SetGotoX
*
* Sets the gotox value for the current selected layer so that it is rendered in a 
* <a href="#Layer_Update">Layer_Update</a> with a new shifted X position<br>
* NOTE: Absolute addressing will fetch 2 bytes from the target address (aka ABS16)<br>
* 
* @namespace Layer
* @param {word} {IMM|REG|ABS16|ABX16|ABY16} gotox The gotox value to set
* @flags nz
*/
.pseudocommand Layer_SetGotoX gotox {
	S65_AddToMemoryReport("Layer_SetGotoX")
	.if(!_isReg(gotox) && !_isImm(gotox) && !_isAbs(gotox) && !_isAbsXY(gotox)) .error "Layer_SetGotoX:"+ S65_TypeError

	_saveIfReg(gotox, S65_PseudoReg + 0)
	pha	
	phy	
		//REG
		.if(_isReg(gotox)) {
			lda S65_PseudoReg + 0
			ldy #$00
			sta (S65_LastLayerIOPointer), y
			lda #$00
			iny
			sta (S65_LastLayerIOPointer), y

		} 
		//IMM
		.if(_isImm(gotox)) {
				ldy #$00
				lda #<gotox.getValue()
				sta (S65_LastLayerIOPointer), y
				iny
				lda #>gotox.getValue()
				sta (S65_LastLayerIOPointer), y

		} 
		//ABS
		.if(_isAbs(gotox)) {	
				lda gotox.getValue()
				ldy #$00
				sta (S65_LastLayerIOPointer), y
				iny
				lda gotox.getValue() + 1
				sta (S65_LastLayerIOPointer), y
		}

		.if(_isAbsX(gotox)) {	
				lda gotox.getValue(), x
				ldy #$00
				sta (S65_LastLayerIOPointer), y
				iny
				lda gotox.getValue() + 1, x
				sta (S65_LastLayerIOPointer), y
		}

		.if(_isAbsY(gotox)) {	
			ply 
			phy
				lda gotox.getValue(), y
				ldy #$00
				sta (S65_LastLayerIOPointer), y
			ply 
			phy
				lda gotox.getValue() + 1, y
				ldy #$01
				sta (S65_LastLayerIOPointer), y
		}				
	ply
	pla
	S65_AddToMemoryReport("Layer_SetGotoX")
}

/**
* .pseudocommand GetGotoX
*
* Returns the gotox value for the current selected layer into
* <a href="#Global_ReturnValue">S65_ReturnValue</a>
* 
* @namespace Layer
* @flags nz
* @returns {word} S65_ReturnValue
*/
.pseudocommand Layer_GetGotoX  {
	S65_AddToMemoryReport("Layer_GetGotoX")
	pha
	phy
			ldy #$00
			lda (S65_LastLayerIOPointer), y
			sta.z S65_ReturnValue + 0
			iny
			lda (S65_LastLayerIOPointer), y
			sta.z S65_ReturnValue + 1
	ply
	pla
	S65_AddToMemoryReport("Layer_GetGotoX")	
}



/**
* .pseudocommand AddText
*
* Writes a string of bytes to the currently active layer at the provide co-ordinates. Optionally allows the
* use of color, setting Color RAM Byte 1 all bits (so includes bit4-blink, bit5-reverse, bit6-bold and bit7-underline), 
* this will only work on non NCM layers with char indices less than $100 <br>
* This is a conveinience function it is better to use Layer_WriteToScreen as it is more efficient<br><br>
* Note: As layer screen rows are interlaced in memory, its important to not let
* the string extend off the right edge of the layer as it can break the RRB on other layers. 
* There is an upper limit string length of 128
*
* @namespace Layer
*
* @param {word} {REG|IMM} xpos Layer char X position
* @param {word} {REG|IMM} ypos Layer char Y position
* @param {word} {ABS} textPtr The address to fetch char data from
* @param {byte} {REG|IMM|ABSXY} color Color to write to color ram
* @flags znc
*/
.pseudocommand Layer_AddText xpos: ypos: textPtr : color {
	S65_AddToMemoryReport("Layer_AddText")
	S65_SaveRegisters()
	.if(!_isReg(xpos) && !_isImm(xpos)) .error "Layer_AddText:"+ S65_TypeError
	.if(!_isReg(ypos) && !_isImm(ypos)) .error "Layer_AddText:"+ S65_TypeError
	.if(!_isAbs(textPtr)) .error "Layer_AddText:"+ S65_TypeError
	.if(!_isAbsXY(color) && !_isImm(color) && !_isReg(color)) .error "Layer_AddText:"+ S65_TypeError	
	_saveIfReg(color,	S65_PseudoReg + 0)
	_saveIfReg(xpos, 	S65_PseudoReg + 1)
	_saveIfReg(ypos, 	S65_PseudoReg + 2)
	pha
	phx
	phy
		.const SCREEN_PTR = S65_ScreenRamPointer
		.const COLOR_PTR = S65_ColorRamPointer
		.const TEXT_PTR = S65_TempWord1

			.if(_isImm(xpos) && _isImm(ypos)) {
					ldy #ypos.getValue()
					ldx #xpos.getValue()
					jsr _Layer_AddText_CalcAddressFromXY
			}

			.if(_isReg(xpos) && _isImm(ypos)) {
					ldy #ypos.getValue()
					ldx.z S65_PseudoReg + 1
					jsr _Layer_AddText_CalcAddressFromXY		
			}


			.if(_isReg(xpos) && _isReg(ypos)) {
					ldy.z S65_PseudoReg + 2 //ypos
					ldx.z S65_PseudoReg + 1 //xpos
					jsr _Layer_AddText_CalcAddressFromXY	
			} 

			.if(_isImm(xpos) && _isReg(ypos)) {
					ldy.z S65_PseudoReg + 2 //ypos
					ldx #xpos.getValue()
					jsr _Layer_AddText_CalcAddressFromXY
			}
		
	
			lda #<textPtr.getValue()
			sta.z TEXT_PTR + 0
			lda #>textPtr.getValue()
			sta.z TEXT_PTR + 1


			.if(_isReg(color)) {
				lda S65_PseudoReg + 0
			} else {
				.if(_isAbsXY(color)) {
					ply 
					plx 
					lda color 
					phx 
					phy
				} else {
					lda color
				}
			} 		
			sta _Layer_AddText.VALUE 
			jsr _Layer_AddText

	ply
	plx 
	pla
	S65_RestoreRegisters()
	S65_AddToMemoryReport("Layer_AddText")
}
_Layer_AddText_CalcAddressFromXY: {
		lda (S65_Layer_RowAddressLSB), y
		sta.z S65_ScreenRamPointer + 0
		lda (S65_Layer_RowAddressMSB), y
		sta.z S65_ScreenRamPointer + 1
		
		lda.z S65_CurrentLayer
		asl 
		tay
		clc 
		lda (S65_Layer_OffsetTable), y
		adc.z S65_ScreenRamPointer + 0
		sta.z S65_ScreenRamPointer + 0
		lda.z S65_ScreenRamPointer + 1
		iny
		adc (S65_Layer_OffsetTable), y
		sta.z S65_ScreenRamPointer + 1	

		txa 
		asl //double for 16 bit chars
		clc 
		adc.z S65_ScreenRamPointer + 0
		sta.z S65_ScreenRamPointer + 0
		lda.z S65_ScreenRamPointer + 1 
		adc #$00
		sta.z S65_ScreenRamPointer + 1	

		//Now adjust color ram pointer
		clc
		lda.z S65_ScreenRamPointer + 0
		adc.z S65_ColorRamLSBOffset
		sta.z S65_ColorRamPointer + 0
		lda.z S65_ScreenRamPointer + 1
		adc.z S65_ColorRamMSBOffset
		sta.z S65_ColorRamPointer + 1	

		rts
}
_Layer_AddText: {
	phz
			.const TEXT_PTR = S65_TempWord1
			ldz #$00
			ldy #$00
		!loop:
			iny
			lda (TEXT_PTR), y
			cmp #$ff
			beq !exit+
			dey
			
				lda (TEXT_PTR), y
				sta ((S65_ScreenRamPointer)), z
				inz
				iny

				lda (TEXT_PTR), y
				sta ((S65_ScreenRamPointer)), z
				 	
				lda.z VALUE:#$BEEF
				sta ((S65_ColorRamPointer)), z

				inz
				iny
			bra !loop-
		!exit:
	plz
	rts
}	



/**
* .pseudocommand ClearAllLayers
*
* Fills the screen RAM area for ALL layers with a given 16bit value. Note this will overwrite any 
* RRB GotoX markers also<br>
* NOTE: Absolute addressing will fetch 2 bytes from the target address (aka ABS16)<br>
* 
* @namespace Layer 
* @param {word?} {REG|IMM|ABS16|ABX16|ABY16} clearChar The 16bit char value to clear with, defaults to $0000
* @flags zn
*/
.pseudocommand Layer_ClearAllLayers clearChar {
	S65_AddToMemoryReport("Layer_ClearAllLayers")
	.if(!_isAbsImmOrNone(clearChar) && !_isReg(clearChar) && !_isAbsXY(clearChar)) .error "Layer_ClearAllLayers:"+ S65_TypeError
	_saveIfReg(clearChar, S65_PseudoReg + 0)
	phy
	phx
	pha        
		
		//REGISTER
		.if(_isReg(clearChar)) {
			lda S65_PseudoReg + 0
			sta DMA_Layer_ClearAllLayersFull.job1 + $04
			lda #$00
			sta DMA_Layer_ClearAllLayersFull.job2 + $04
		} 
		//IMM
		.if(_isImm(clearChar)) {
			lda #<clearChar.getValue()
			sta DMA_Layer_ClearAllLayersFull.job1 + $04
			lda #>clearChar.getValue()
			sta DMA_Layer_ClearAllLayersFull.job2 + $04
		} 
		//ABS16
		.if(_isAbs(clearChar) && !_isReg(clearChar)) {
			lda clearChar.getValue()
			sta DMA_Layer_ClearAllLayersFull.job1 + $04
			lda clearChar.getValue() + 1
			sta DMA_Layer_ClearAllLayersFull.job2 + $04
		}
		//ABX16
		.if(_isAbsX(clearChar)) {
			lda clearChar.getValue(),x
			sta DMA_Layer_ClearAllLayersFull.job1 + $04
			lda clearChar.getValue() + 1,x 
			sta DMA_Layer_ClearAllLayersFull.job2 + $04
		}
		//ABY16
		.if(_isAbsY(clearChar)) {
			lda clearChar.getValue(),y
			sta DMA_Layer_ClearAllLayersFull.job1 + $04
			lda clearChar.getValue() + 1,y 
			sta DMA_Layer_ClearAllLayersFull.job2 + $04
		}

		.if(clearChar.getType() != AT_NONE) {
			DMA_Execute DMA_Layer_ClearAllLayersFull

		} else {
			DMA_Execute DMA_Layer_ClearAllLayersZero
		}
	pla
	plx 
	ply
	S65_AddToMemoryReport("Layer_ClearAllLayers")
}
DMA_Layer_ClearAllLayersFull: {
	DMA_Header #$00 : #$00
	DMA_Step #$0100 : #$0200 
	job1:
	DMA_FillJob #$00 : S65_SCREEN_RAM + 0 : #$100 : #TRUE
	job2:		
	DMA_FillJob #$00 : S65_SCREEN_RAM + 1 : #$100 : #FALSE	
}
DMA_Layer_ClearAllLayersZero: {
	DMA_Header #$00 : #$00
	job1:
	DMA_FillJob #$00 : S65_SCREEN_RAM + 0 : #$100 : #FALSE	
}


/**
* .pseudocommand ClearLayer
*
* Fills the screen RAM area for the currently selected layer with a given 16bit value. Optionally clearing the color too
* 
* @namespace Layer
*
* @param {word?} {REG|IMM|ABS16|ABX16|ABY16} clearChar The 16bit char value to clear with, defaults to $0000
* @param {word?} {REG|IMM|ABS|ABX|ABY} clearColor The 8bit char value to clear with, defaults to $00
* @flags nzc
*/
.pseudocommand Layer_ClearLayer clearChar : clearColor {
	S65_AddToMemoryReport("Layer_ClearLayer")
	.if(!_isAbsImmOrNone(clearChar) && !_isReg(clearChar)  && !_isAbsXY(clearChar)) .error "Layer_ClearLayer:"+ S65_TypeError
	.if(!_isAbsImmOrNone(clearColor) && !_isReg(clearColor)  && !_isAbsXY(clearColor)) .error "Layer_ClearLayer:"+ S65_TypeError
	_saveIfReg(clearChar, S65_PseudoReg + 0)
	_saveIfReg(clearColor, S65_PseudoReg + 1)
	pha 
	phx 
	phy	

		//X=charLo, Y=charHi, A = layer
		//NONE
		.if(_isNone(clearChar)) {
			ldx #$00
			ldy #$00
		} 
		//REG
		.if(_isReg(clearChar)) {
			lda S65_PseudoReg + 0
			tax 
			ldy #$00
		} 
		//IMM
		.if(_isImm(clearChar)) {
			ldx #<clearChar.getValue()
			ldy #>clearChar.getValue()
		}
		//ABS16
		.if(_isAbs(clearChar)) {
			ldx clearChar.getValue() + 0
			ldy clearChar.getValue() + 1
		}		
		//ABX16
		.if(_isAbsX(clearChar)) {
			lda clearChar.getValue() + 1, x
			tay
			lda clearChar.getValue() + 0, x
			tax
		}	
		//ABY16
		.if(_isAbsY(clearChar)) {
			lda clearChar.getValue() + 0, y
			tax
			lda clearChar.getValue() + 1, y
			tay			
		}	
		lda S65_CurrentLayer
		jsr Layer_DMAClear



		//REG
		.if(_isReg(clearColor)) {
			ldx S65_PseudoReg + 1
		} 
		//IMM
		.if(_isImm(clearColor)) {
			ldx #clearColor.getValue()
		}
		//ABS16
		.if(_isAbs(clearColor)) {
			ldx clearColor.getValue()
		}		
		//ABX16
		.if(_isAbsX(clearColor)) {
			ply 
			plx 
			phx 
			phy
			lda clearColor.getValue(), x
			tax
		}	
		//ABY16
		.if(_isAbsY(clearColor)) {
			ply 
			phy
			lda clearColor.getValue(), y
			tax		
		}	
		.if(!_isNone(clearColor)) {
			lda S65_CurrentLayer
			jsr Layer_DMAClearColor
		}

	ply
	plx		
	pla 
	S65_AddToMemoryReport("Layer_ClearLayer")
}



/**
* .pseudocommand Update
*
* Updates ALL the layers. This is basically the render method, it sets all the GOTOX markers for 
* the various layers and calls the Sprite_Update method<br><br>
* Note: this is an expensive operation in both memory and cpu, it should be called once only per frame
* and put it in a subroutine if you need to call it from more than one place
* 
* @namespace Layer
*/
.pseudocommand Layer_Update {
		S65_AddToMemoryReport("Layer_Update")
		pha
		phx 
		phy
		phz
			System_BorderDebug($0c)
			jsr _Layer_Update
			System_BorderDebug($09)
			Sprite_Update Layer_LayerList.size()

			#if NODEBUG
			#else
				Debug_Update()
			#endif
		plz
		ply
		plx
		pla
		S65_AddToMemoryReport("Layer_Update")
}
_Layer_Update: {
		.const DYN_TABLE = S65_TempWord1
			//Transfer the GOTOX values from the dynamic IO
			ldx #$00
			ldy #$00 
			ldz #$00 
		!loop:

			lda (S65_DynamicLayerData), y
			iny
			sta.z DYN_TABLE + 0
			lda (S65_DynamicLayerData), y
			dey
			sta.z DYN_TABLE + 1

			lda (DYN_TABLE), z
			sta Layer_GotoXPositions, y
			iny
			inz 
			lda (DYN_TABLE), z 
			and #$03 //Clamp the value to only use the first 2 bits	
			sta Layer_GotoXPositions, y 

			iny
			dez		
			inx 
			cpx ListSize0:#$BEEF
			bne !loop-

			.var offset = 0
			ldx #$00
		!outerLoop:
 
			clc 
			lda Layer_AddrOffsets, x//0
			adc.z S65_BaseColorRamPointer + 0
			inx
			sta.z S65_ColorRamPointer + 0
			sta.z S65_ScreenRamPointer + 0

			php
			lda Layer_AddrOffsets, x//1
			adc.z S65_BaseColorRamPointer + 1
			sta.z S65_ColorRamPointer + 1

			plp
			lda Layer_AddrOffsets, x//1
			adc.z S65_BaseScreenRamPointer + 1
			sta.z S65_ScreenRamPointer + 1
			dex


			ldy ScreenHeight:#S65_VISIBLE_SCREEN_CHAR_HEIGHT
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

		rts
}


/**
* .pseudocommand AdvanceScreenPointers
*
* Advances the S65 Basepage dword values for
* <a href="#Global_ColorRamPointer">ColorRamPointer<a> and
* <a href="#Global_ScreenRamPointer">ScreenRamPointer<a>
* by the given byte offset.<br><br>
* 
* Note: This method assumes you are already in the S65 base page, this is true after a 
* <a href="#Layer_Get">Layer_Get</a> command, 
* be careful not to use this command if base page is not set, otherwise it will likely write to 
* unintended locations
* 
* @namespace Layer
*
* @param {byte?} {REG|IMM} Optional byte offset (defaults to S65_SCREEN_LOGICAL_ROW_WIDTH)
*
* @registers A
* @flags nzc
*/
.pseudocommand Layer_AdvanceScreenPointers offset {
	S65_AddToMemoryReport("Layer_AdvanceScreenPointers")
	.if(!_isImmOrNone(offset) && !_isReg(offset)) .error "Layer_AdvanceScreenPointers:" +S65_TypeError
	_saveIfReg(offset, S65_PseudoReg)
	pha

		.if(_isReg(offset)) {
			lda S65_PseudoReg + 0
			sta BRANCH_REGORB8BIT + 4 //Byte offset as labels wont work through the if
		}

		BRANCH_REGORB8BIT:
		.if(!_isNone(offset) && (offset.getValue() < $100 || _isReg(offset))){
				clc
				lda.z S65_ScreenRamPointer + 0
				adc #offset.getValue()
				sta.z S65_ScreenRamPointer + 0
				sta.z S65_ColorRamPointer + 0
				bcc !+
				inc.z S65_ScreenRamPointer + 1
				inc.z S65_ColorRamPointer + 1
			!:
		} else {
			.if(_isNone(offset)) {
				.if(S65_SCREEN_LOGICAL_ROW_WIDTH < $100) {
					clc
					lda.z S65_ScreenRamPointer + 0
					adc #<S65_SCREEN_LOGICAL_ROW_WIDTH
					sta.z S65_ScreenRamPointer + 0
					sta.z S65_ColorRamPointer + 0
					bcc !+
					inc.z S65_ScreenRamPointer + 1
					inc.z S65_ColorRamPointer + 1
				!:	
				} else {
					clc
					lda.z S65_ScreenRamPointer + 0
					adc #<S65_SCREEN_LOGICAL_ROW_WIDTH
					sta.z S65_ScreenRamPointer + 0
					sta.z S65_ColorRamPointer + 0
					
					php
					lda.z S65_ScreenRamPointer + 1
					adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
					sta.z S65_ScreenRamPointer + 1
		
					plp
					lda.z S65_ColorRamPointer + 1
					adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
					sta.z S65_ColorRamPointer + 1
				!:
				}
			} else {
				clc
				lda.z S65_ScreenRamPointer + 0
				adc #<offset.getValue()
				sta.z S65_ScreenRamPointer + 0
				sta.z S65_ColorRamPointer + 0
				bcc !+

				php
				lda.z S65_ScreenRamPointer + 1
				adc #>offset.getValue()
				sta.z S65_ScreenRamPointer + 1

				plp
				lda.z S65_ColorRamPointer + 1
				adc #>offset.getValue()
				sta.z S65_ColorRamPointer + 1	
			!:
			}
		}
	pla
	S65_AddToMemoryReport("Layer_AdvanceScreenPointers")
}





/**
* .pseudocommand Shift
*
* Shift the cahrs on this layer horizontally
* 
* @namespace Layer
*
* @param {byte} {IMM|REG|ABS|ABX|ABY} xshift The number of chars to shift (Currently values other than -1 or 1 may cause issues)
* @flags nzc
*/
.pseudocommand Layer_Shift xshift {
	S65_AddToMemoryReport("Layer_Shift")
	.if(!_isAbsImmOrNone(xshift) && !_isReg(xshift) && !_isAbsXY(xshift)) .error "Layer_Shift:" +S65_TypeError
	_saveIfReg(xshift, S65_TempByte1)

	.var lengthJob= DMA_Layer_Shift.job + $02
	.var lengthJob2 = DMA_Layer_Shift.job2 + $02
	pha 
	phx 
	phy 
	phz
		//ALL but REG
		.if(!_isReg(xshift)) {
			lda xshift
			sta S65_TempByte1
			bpl !+
			neg
		!:
			asl 
			sta.z S65_TempByte2
		} else {
			lda S65_TempByte1
			bpl !+
			neg
		!:
			asl
			sta.z S65_TempByte2
		}

		
		
		jsr _Layer_Shift_ResetScreen	

		ldy.z S65_CurrentLayer
		lda.z S65_TempByte1
		bmi !negative+
	!postitive:
		lda Layer_width, y
		jsr _Layer_Shift_PrepPos
		bra !done+
	!negative:
		lda Layer_width, y
		jsr _Layer_Shift_PrepNeg
	!done:
	plz
	ply 
	plx 
	pla
	S65_AddToMemoryReport("Layer_Shift")
}

_Layer_Shift_ResetScreen: {
	Layer_SetScreenPointersXY #0 : #0
	rts
}
_Layer_Shift_PrepPos: {
		jsr _Layer_Shift_SetLength
		lda S65_TempByte2
		sta _Layer_Shift_X_Positive.ScreenAdd
		sta _Layer_Shift_X_Positive.ColorAdd
		jmp _Layer_Shift_X_Positive	//tail call	

}
_Layer_Shift_PrepNeg: {
		jsr _Layer_Shift_SetLength
		lda S65_TempByte2
		sta _Layer_Shift_X_Negative.ScreenAdd
		sta _Layer_Shift_X_Negative.ColorAdd
		jmp _Layer_Shift_X_Negative //tail call		
}

_Layer_Shift_SetLength: {
		.var lengthJob= DMA_Layer_Shift.job + $02
		.var lengthJob2 = DMA_Layer_Shift.job2 + $02	

		sec 
		sbc #$02
		sta lengthJob
		sta lengthJob2
		rts
}
_Layer_Shift_X_Negative: {
		.var lengthJob= DMA_Layer_Shift.job + $02
		.var destJob = DMA_Layer_Shift.job + $07
		.var srcJob = DMA_Layer_Shift.job + $04

		.var lengthJob2= DMA_Layer_Shift.job2 + $02
		.var destJob2 = DMA_Layer_Shift.job2 + $07
		.var srcJob2 = DMA_Layer_Shift.job2 + $04
		
.print ("lengthJob: $" + toHexString(lengthJob))
.print ("destJob: $" + toHexString(destJob))
.print ("srcJob: $" + toHexString(srcJob))

		sec 
		lda.z S65_ScreenRamPointer  + 0	
		sta destJob + 0
		sbc ScreenAdd:#$02
		sta srcJob + 0

		lda.z S65_ScreenRamPointer  + 1
		sta destJob + 1
		sbc #$00
		sta srcJob + 1	

		lda.z S65_ScreenRamPointer  + 2
		and #$0f
		ora #$40	//backwards
		sta destJob + 2
		sbc #$00
		sta srcJob + 2

			//adjust src and dest as we go backwards
				clc
				lda lengthJob
				adc #$01
				sta lengthJobback 
				// inc lengthJob
				// dec lengthJob
				// dec lengthJob

				// inc lengthJob
				// inc lengthJob


				clc
				lda srcJob+0
				adc lengthJobback:#$BEEF
				sta srcJob+0
				lda srcJob+1
				adc #$00
				sta srcJob+1

				clc 
				lda destJob+0
				adc lengthJobback
				sta destJob+0
				lda destJob+1
				adc #$00
				sta destJob+1





		sec 
		lda.z S65_ColorRamPointer  + 0
		sta destJob2 + 0
		sbc ColorAdd:#$02
		sta srcJob2 + 0

		lda.z S65_ColorRamPointer  + 1
		sta destJob2 + 1
		sbc #$00
		sta srcJob2 + 1	

		lda.z S65_ColorRamPointer  + 2
		and #$0f
		ora #$40	//backwards
		sta destJob2 + 2
		sbc #$00
		sta srcJob2 + 2	

				clc 
				lda srcJob2+0
				adc lengthJobback
				sta srcJob2+0
				lda srcJob2+1
				adc #$00
				sta srcJob2+1

				clc 
				lda destJob2+0
				adc lengthJobback
				sta destJob2+0
				lda destJob2+1
				adc #$00
				sta destJob2+1
// jmp *
		jsr DMA_Layer_Shift_ExecuteRows
		rts
}

_Layer_Shift_X_Positive: {
		.var lengthJob= DMA_Layer_Shift.job + $02
		.var destJob = DMA_Layer_Shift.job + $07
		.var srcJob = DMA_Layer_Shift.job + $04

		.var lengthJob2= DMA_Layer_Shift.job2 + $02
		.var destJob2 = DMA_Layer_Shift.job2 + $07
		.var srcJob2 = DMA_Layer_Shift.job2 + $04
	


		clc 
		lda.z S65_ScreenRamPointer  + 0
		sta destJob + 0
		adc ScreenAdd:#$02
		sta srcJob + 0

		lda.z S65_ScreenRamPointer  + 1
		sta destJob + 1
		adc #$00
		sta srcJob + 1	

		lda.z S65_ScreenRamPointer  + 2
		and #$0f
		sta destJob + 2
		adc #$00
		sta srcJob + 2



		clc 
		lda.z S65_ColorRamPointer  + 0
		sta destJob2 + 0
		adc ColorAdd:#$02
		sta srcJob2 + 0

		lda.z S65_ColorRamPointer  + 1
		sta destJob2 + 1
		adc #$00
		sta srcJob2 + 1	

		lda.z S65_ColorRamPointer  + 2
		and #$0f
		sta destJob2 + 2
		adc #$00
		sta srcJob2 + 2	

		jsr DMA_Layer_Shift_ExecuteRows
		rts
}
DMA_Layer_Shift_ExecuteRows: {
			.var lengthJob= DMA_Layer_Shift.job + $02
			.var destJob = DMA_Layer_Shift.job + $07
			.var srcJob = DMA_Layer_Shift.job + $04

			.var lengthJob2= DMA_Layer_Shift.job2 + $02
			.var destJob2 = DMA_Layer_Shift.job2 + $07
			.var srcJob2 = DMA_Layer_Shift.job2 + $04

			ldx #$00
	!:
			DMA_Execute DMA_Layer_Shift

			clc 
			lda srcJob + 0
			adc RowWidthLSB:#$BEEF
			sta srcJob  + 0
			lda srcJob  + 1
			adc RowWidthMSB:#$BEEF
			sta srcJob  + 1

			clc 
			lda destJob + 0
			adc RowWidthLSB
			sta destJob  + 0
			lda destJob  + 1
			adc RowWidthMSB
			sta destJob  + 1

			clc 
			lda srcJob2 + 0
			adc RowWidthLSB
			sta srcJob2  + 0
			lda srcJob2  + 1
			adc RowWidthMSB
			sta srcJob2  + 1

			clc 
			lda destJob2 + 0
			adc RowWidthLSB
			sta destJob2  + 0
			lda destJob2  + 1
			adc RowWidthMSB
			sta destJob2  + 1

		inx 
		cpx RowCount:#$BEEF
		bne !-
		rts
}
DMA_Layer_Shift: {
		DMA_Header #0 : #0
	job:
		.var lengthJob = * + $02
		.var destJob = * + $07
		.var srcJob = * + $04
		DMA_CopyJob S65_ScreenRamPointer : S65_ScreenRamPointer : #$0002 : #TRUE : #FALSE
		DMA_Header #$ff : #$ff
	job2:
		.var lengthJob2 = * + $02
		.var destJob2 = * + $07
		.var srcJob2 = * + $04		
		DMA_CopyJob S65_ScreenRamPointer : S65_ScreenRamPointer : #$0002 : #FALSE : #FALSE
}


/**
* .pseudocommand SortSprites
*
* Y sorts the sprite render order for this layer, using the sprite y pos + its height as a base
* 
* @namespace Layer
* @param {byte} {IMM?} count Optional count of sprites to sort, allows you to keep some always on top in the higher areas
* @flags nzc
*/

.pseudocommand Layer_SortSprites count {
	S65_AddToMemoryReport("Layer_SortSprites")
	.if(!_isImmOrNone(count)).error "Layer_SortSprites:"+ S65_TypeError

	phx 
	phy
	pha
			.const SprIO = S65_TempWord1
			.const SprIOBase = S65_TempWord4
			.const SprIndices = S65_TempWord5

			ldx.z S65_CurrentLayer	
			lda Layer_SpriteSortListLSB, x
			sta.z SprIndices + 0
			sta SortDMAClearTable.sm_lsb + 0
			lda Layer_SpriteSortListMSB, x
			sta.z SprIndices + 1
			sta SortDMAClearTable.sm_lsb + 1
			lda Layer_SpriteIOAddrLSB, x
			sta.z SprIO + 0
			lda Layer_SpriteIOAddrMSB, x
			sta.z SprIO + 1
			.if(_isImm(count)) {
				lda count.getValue()
			} else {
				lda Layer_SpriteCount, x 
			}
			sta sm_count
			sta SortDMAClearTable.sm_count

			jsr SortDMAClearTable

			ldx #$00
		!loop:
			ldy #Sprite_IOflags
			lda (SprIO), y	
			bit #Sprite_IOflagEnabled 
			beq !done+	//If not enabled skip

			//Otheriwse get its baseline y pos
			ldy #Sprite_IOheight
			lda (SprIO), y
			tay 
			lda Times8Table, y 
			ldy #Sprite_IOy
			clc
			adc (SprIO), y
			tay 	//Y = baseline Y pos

			//find closest slot in table
		!next:
			lda SortTempTable, y 
			beq !+
			iny 
			bra !next-
		!:

			cpx #$00 //First needs recording
			bne !+
			lda #$ff 
			sta SortTempTable, y 
			bra !done+
		!:
			txa 
			sta SortTempTable, y 
		!done:
			clc 
			lda.z SprIO + 0
			adc #Sprite_SpriteIOLength
			sta.z SprIO + 0
			bcc !+
			inc.z SprIO + 1
		!:
			inx 
			cpx sm_count:#$BEEF

			bne !loop-

			//Now copy the list to 
			//the sorted list 
			ldx #$00
			ldy #$00
		!loop:
			lda SortTempTable, x 
			beq !next+		
			cmp #$ff
			bne !+
			lda #$00
		!:
			sta (SprIndices), y
			iny 
		!next:
			inx 
			bne !loop-

		//fill rest with $ff
			lda #$ff
		!:
			cpy sm_count
			bcs !exit+
			sta (SprIndices), y
			iny 
			bra !-
		!exit:

	pla
	ply
	plx                
    S65_AddToMemoryReport("Layer_SortSprites")
}
SortDMAClearTable: {
		DMA_Execute job 
		rts 
	job:
		DMA_Header #0 : #0
		DMA_FillJob #0 : SortTempTable : #256 : #TRUE
		.label sm_count= * + $02
		.label sm_lsb = * + $07	
		DMA_FillJob #$ff : SortTempTable : #$00 : #FALSE
}
Times8Table:	.fill 16, i* 8
SortTempTable: .fill 256, 0
SortTempZero: .byte $00

/**
* .pseudocommand WriteToScreen
*
* Copys up to 256 bytes from the source addresses to the locations
* pointed at by
* <a href="#Global_ScreenRamPointer">ScreenRamPointer<a> and optionally
* <a href="#Global_ColorRamPointer">ColorRamPointer<a>. Does NOT change the contents of
* the screen and color ram pointers.<br>
* If immediate values are used for source then this byte is written directly<br><br>
* Note: This method assumes you are already in the S65 base page, this is true after a 
* <a href="#Layer_Get">Layer_Get</a> command, 
* be careful not to use this command if base page is not set, otherwise it will likely write to 
* unintended locations<br>
* If ABSY mode is used for either source then the y register is added to the address before
* writing. Additionally upon completion the Y register will be incremented
* by the amount of bytes written<br><br>
* Note: Writing past the end of your layers right edge can cause RRB and memory issues
* please use <a href="#Layer_AdvanceScreenPointers">Layer_AdvanceScreenPointers<a> to move 
* the pointers safely to the next row
* 
* @namespace Layer
*
* @param {byte} {REG|IMM|ABS|ABSY} screenSource The color source data address to use or a value to use if IMM defaults to #$00
* @param {byte?} {REG|IMM|ABS|ABSY} colorSource The color source data address to use or a value to use if IMM defaults to #$00
* @param {byte} {REG|IMM} size The lengh of the data in CHARS (so bytes/2)
*
* @flags nzc
*/
.pseudocommand Layer_WriteToScreen screenSource : colorSource : size {
	S65_AddToMemoryReport("Layer_WriteToScreen")
	.if(!_isAbsImmOrReg(screenSource) && !_isAbsY(screenSource)) .error "Layer_WriteToScreen:"+ S65_TypeError
	.if(!_isAbsImmOrReg(colorSource) && !_isNone(colorSource) && !_isAbsY(colorSource)) .error "Layer_WriteToScreen:"+ S65_TypeError
	.if(!_isImmOrReg(size)) .error "Layer_WriteToScreen:"+ S65_TypeError
	phz
	phx
	pha	
	phy
	

	_saveIfReg(size, S65_PseudoReg + 0)
	_saveIfReg(screenSource, S65_PseudoReg + 1)
	_saveIfReg(colorSource, S65_PseudoReg + 2)

	.if(_isAbsY(screenSource)) {
		tya 
		clc 
		adc #<screenSource.getValue()		
		sta BRANCH_ABSY_SCREEN + 3
		lda #>screenSource.getValue()
		adc #$00
		sta BRANCH_ABSY_SCREEN + 4
	}	

	.if(_isAbsY(colorSource)) {
		tya 
		lsr
		clc 
		adc #<colorSource.getValue()		
		sta BRANCH_ABSY_COLOR + 7
		lda #>colorSource.getValue()
		adc #$00
		sta BRANCH_ABSY_COLOR + 8
	}	

			.if(_isReg(size)) {
				asl.z S65_PseudoReg + 0
			}


			ldz #$00
			ldx #$00  //offset index 
		!layerloop:
		BRANCH_ABSY_SCREEN:
			//screen ABSY
			.if(_isAbsY(screenSource)) {
					ldy #$02
				!:
					lda SMsource:$BEEF, x //char lsb
					sta ((S65_ScreenRamPointer)), z 
					inz 
					inx 
					dey 
					bne !-
					dex 
					dez

			} else {
				//screen ABS
				.if(_isAbs(screenSource)) {
					lda screenSource.getValue(), x //char lsb
					sta ((S65_ScreenRamPointer)), z 
					inz 
					inx 
					lda screenSource.getValue(), x //char msb
					sta ((S65_ScreenRamPointer)), z 	
				} else {
					//screen REG
					.if(_isReg(screenSource)) {
						lda S65_PseudoReg + 1 //char lsb
						sta ((S65_ScreenRamPointer)), z 
						inz 
						inx 
						lda #$00 //char msb
						sta ((S65_ScreenRamPointer)), z 		
					} else {
						//screen IMM
						lda #<screenSource.getValue()
						sta ((S65_ScreenRamPointer)), z 
						inz 
						inx 
						lda #>screenSource.getValue() //char msb
						sta ((S65_ScreenRamPointer)), z 					
					}
				}
			}
			

			//X=+1, Z=+1

		BRANCH_ABSY_COLOR:
			.if(!_isNone(colorSource)) {
				.if(_isAbsY(colorSource)) {					
						stx RestX1
						txa 
						lsr 
						tax 

						lda SMcolor:$BEEF, x //char lsb
						sta ((S65_ColorRamPointer)), z 
						ldx RestX1:#$BEEF	
				} else {
					.if(_isAbs(colorSource)) {
						lda colorSource.getValue(), x
						sta ((S65_ColorRamPointer)), z 	
					} else {
						.if(_isReg(colorSource)) {
							lda S65_PseudoReg + 2
							sta ((S65_ColorRamPointer)), z 	
						} else {
							lda #colorSource.getValue()
							sta ((S65_ColorRamPointer)), z 				
						}				
					}
				}
			}

			inz 
			inx 	
			.if(_isReg(size)) {
				cpz.z S65_PseudoReg + 0
			} else {
				cpz #[size.getValue() * 2]  //Layer width * 2 because 16bit chars
			}
			bne !layerloop-

	ply
		.if(_isAbsY(screenSource)||_isAbsY(colorSource)) {
			sty ADDSM
			tza 
			clc 
			adc ADDSM:#$BEEF 
			tay 
		}
	pla
	plx
	plz
	S65_AddToMemoryReport("Layer_WriteToScreen")			
}



/**
* .pseudocommand SetScreenPointersXY
*
* Sets the basepage to point to the S65 base page area
* and then sets screen and color ram pointers
* <a href="#Global_ScreenRamPointer">ScreenRamPointer<a> and 
* <a href="#Global_ColorRamPointer">ColorRamPointer<a>
* to point to the given layers x and y co-ordinate
* @namespace Layer
*
* @param {byte} {REG|IMM|ABS|ABX|ABY} xpos x position on layer
* @param {byte} {REG|IMM|ABS|ABX|ABY} ypos y position on layer
* @flags nzc
*/
.pseudocommand Layer_SetScreenPointersXY xpos : ypos {
	S65_AddToMemoryReport("Layer_SetScreenPointersXY")
	.if(!_isAbsImmOrReg(xpos) && !_isAbsXY(xpos)) .error "Layer_SetScreenPointersXY:"+S65_TypeError
	.if(!_isAbsImmOrReg(ypos) && !_isAbsXY(ypos)) .error "Layer_SetScreenPointersXY:"+S65_TypeError
	_saveIfReg(xpos, S65_PseudoReg + 0)
	_saveIfReg(ypos, S65_PseudoReg + 1)
	pha 
	phy
	phx
		//xpos
		.if(_isReg(xpos)) {
			ldx S65_PseudoReg + 0
		}
		.if(_isImm(xpos)) {
			ldx #xpos.getValue()
		}
		.if(_isAbs(xpos)) {
			ldx xpos.getValue()
		}
		.if(_isAbsX(xpos)) {
			lda xpos.getValue(), x 
			tax 
		}
		.if(_isAbsY(xpos)) {
			lda xpos.getValue(), y 
			tax 
		}

		//ypos
		.if(_isReg(ypos)) {
			ldy S65_PseudoReg + 1
		}
		.if(_isImm(ypos)) {
			ldy #ypos.getValue()
		}
		.if(_isAbs(ypos)) {
			ldy ypos.getValue()
		}
		.if(_isAbsX(ypos)) {
			plx
			phx
			lda ypos.getValue(), x 
			tay 
		}
		.if(_isAbsY(ypos)) {
			plx 
			ply
			phy
			phx
			lda ypos.getValue(), y 
			tay 
		}

		jsr _Layer_AddText_CalcAddressFromXY
	plx
	ply		
	pla
	S65_AddToMemoryReport("Layer_SetScreenPointersXY")	
}
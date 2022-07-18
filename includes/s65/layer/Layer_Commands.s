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

		.if(!_isImm(layer)) .error "Layer_AddText:"+ S65_TypeError
		.if(!_isReg(xpos) && !_isImm(xpos)) .error "Layer_AddText:"+ S65_TypeError
		.if(!_isReg(ypos) && !_isImm(ypos)) .error "Layer_AddText:"+ S65_TypeError
		.if(!_isAbs(textPtr)) .error "Layer_AddText:"+ S65_TypeError

		.if(!_isAbsXY(color) && !_isImm(color) && !_isReg(color)) .error "Layer_AddText:"+ S65_TypeError
			
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
				phx
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
				plx
				} 

			.if(_isImm(xpos) && _isReg(ypos)) {
				phx
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
				plx				
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

			lda SMcolor: color 		
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
* @param {word?} {IMM} clearChar The 16bit char value to clear with, defaults to $0000
* 
* @flags zn
*/
.pseudocommand Layer_ClearAllLayers clearChar {
	S65_AddToMemoryReport("Layer_ClearAllLayers")
	phy
	phx
	pha
			.if(_isReg(clearChar)) {
				 _saveIfReg(clearChar, S65_PseudoReg + 0)
			} else {
				.if(!_isAbsImmOrNone(clearChar)) .error "Layer_ClearAllLayers:"+ S65_TypeError
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
	pla
	plx 
	ply
	S65_AddToMemoryReport("Layer_ClearAllLayers")
}


/**
* .pseudocommand ClearLayer
*
* Fills the screen RAM area for the layer with a given 16bit value. 
* 
* @namespace Layer
*
* @param {byte} {REG|IMM} layer The layer number to clear
* @param {word?} {REG|IMM} clearChar The 16bit char value to clear with, defaults to $0000
*
* @registers AXY
* @flags nzc
* 
* @return {byte} A <add description here> 
*/
.pseudocommand Layer_ClearLayer layer : clearChar {
	S65_AddToMemoryReport("Layer_ClearLayer")
		.if(_isReg(layer)) {
			 _saveIfReg(layer, SMlayer)
		} else {
			.if(!_isImmOrNone(layer)) .error "Layer_ClearLayer:"+ S65_TypeError
		}
		.if(_isReg(clearChar)) {
			 _saveIfReg(clearChar, S65_PseudoReg + 0)
		} else {
			.if(!_isImmOrNone(clearChar)) .error "Layer_ClearLayer:"+ S65_TypeError
		}

		_saveIfReg(layer, SMlayer)

		//X=charLo, Y=charHi, A = layer
		
			
		//REGISTER
		.if(_isReg(clearChar)) {
			lda S65_PseudoReg + 0
			tax 
			ldy #$00
		}  else {
			ldx #<clearChar.getValue()

			ldy #>clearChar.getValue()

		}
		lda SMlayer:#[layer.getValue()]
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


/**
* .pseudocommand AdvanceScreenPointers
*
* Advances the S65 Basepage dword values for
* <a href="#Global_ColorRamPointer">ColorRamPointer<a> and
* <a href="#Global_ScreenRamPointer">ScreenRamPointer<a>
* by the given byte offset.<br><br>
* 
* Note: This method assumes you are already in the S65 base page, this is true after a 
* <a href="#Layer_SetScreenPointersXY">Layer_SetScreenPointersXY</a> command, 
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


		.if(_isReg(offset)) {
			lda S65_PseudoReg + 0
			sta BRANCH_REGORB8BIT + 4 //Byte offset as lables wont work through the if
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

					lda.z S65_ScreenRamPointer + 1
					adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
					sta.z S65_ScreenRamPointer + 1
					bcc !+
					lda.z S65_ColorRamPointer + 1
					adc #[[>S65_SCREEN_LOGICAL_ROW_WIDTH]-1]
					sta.z S65_ColorRamPointer + 1
				!:
				}


			} else {
				clc
				lda.z S65_ScreenRamPointer + 0
				adc #<offset.getValue()
				sta.z S65_ScreenRamPointer + 0
				sta.z S65_ColorRamPointer + 0
				lda.z S65_ScreenRamPointer + 1
				adc #>offset.getValue()
				sta.z S65_ScreenRamPointer + 1
				bcc !+
				lda.z S65_ColorRamPointer + 1
				adc #[[>offset.getValue()] -1]
				sta.z S65_ColorRamPointer + 1	
			!:
			}

		}
	S65_AddToMemoryReport("Layer_AdvanceScreenPointers")
}

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
* <a href="#Layer_SetScreenPointersXY">Layer_SetScreenPointersXY</a> command, 
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
* @param {byte} {ABSY|IMM|REG} screenSource The color source data address to use or a value to use if IMM defaults to #$00
* @param {byte?} {ABSY|IMM|REG} colorSource The color source data address to use or a value to use if IMM defaults to #$00
* @param {byte} {REG|IMM} size The lengh of the data in CHARS (so bytes/2)
*
* @registers
* @flags
*/
.pseudocommand Layer_WriteToScreen screenSource : colorSource : size {
	S65_AddToMemoryReport("Layer_WriteToScreen")
	.if(!_isAbsImmOrReg(screenSource) && !_isAbsY(screenSource)) .error "Layer_WriteToScreen:"+ S65_TypeError
	.if(!_isAbsImmOrReg(colorSource) && !_isNone(colorSource) && !_isAbsY(colorSource)) .error "Layer_WriteToScreen:"+ S65_TypeError
	.if(!_isImmOrReg(size)) .error "Layer_WriteToScreen:"+ S65_TypeError
	phz
	phx
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
					sta.z ((S65_ScreenRamPointer)), z 
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
					sta.z ((S65_ScreenRamPointer)), z 
					inz 
					inx 
					lda screenSource.getValue(), x //char msb
					sta.z ((S65_ScreenRamPointer)), z 	
				} else {
					//scewen REG
					.if(_isReg(screenSource)) {
						lda S65_PseudoReg + 1 //char lsb
						sta.z ((S65_ScreenRamPointer)), z 
						inz 
						inx 
						lda #$00 //char msb
						sta.z ((S65_ScreenRamPointer)), z 		
					} else {
						//screen IMM
						lda #screenSource.getValue()
						sta.z ((S65_ScreenRamPointer)), z 
						inz 
						inx 
						lda #$00 //char msb
						sta.z ((S65_ScreenRamPointer)), z 					
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
						sta.z ((S65_ColorRamPointer)), z 
						ldx RestX1:#$BEEF	
				} else {
					.if(_isAbs(colorSource)) {
						lda colorSource.getValue(), x
						sta.z ((S65_ColorRamPointer)), z 	
					} else {
						.if(_isReg(colorSource)) {
							lda S65_PseudoReg + 2
							sta.z ((S65_ColorRamPointer)), z 	
						} else {
							lda #colorSource.getValue()
							sta.z ((S65_ColorRamPointer)), z 				
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
* @param {byte} {IMM} layer Layer to get pointer to
* @param {byte} {REG|IMM} xpos Optional xposition on layer
* @param {byte} {REG|IMM} ypos Optional yposition on layer
*
* @registers AB
* @flags nzc
*/
	// .var Layer_RowAddressLSB = $0000
	// .var Layer_RowAddressMSB = $0000

.pseudocommand Layer_SetScreenPointersXY layer : xpos : ypos {
	S65_AddToMemoryReport("Layer_SetScreenPointersXY")
	S65_SetBasePage()
	.if(!_isImm(layer)) .error "Layer_SetScreenPointersXY:"+S65_TypeError
	.if(!_isImmOrReg(xpos)) .error "Layer_SetScreenPointersXY:"+S65_TypeError
	.if(!_isImmOrReg(ypos)) .error "Layer_SetScreenPointersXY:"+S65_TypeError
	_saveIfReg(xpos, S65_PseudoReg + 0)
	_saveIfReg(ypos, S65_PseudoReg + 1)
	phx 

		.var address = S65_SCREEN_RAM
		.if(!_isReg(ypos)) .eval address += ypos.getValue() * S65_SCREEN_LOGICAL_ROW_WIDTH
		.if(!_isReg(xpos)) .eval address += xpos.getValue() * 2
		.eval address += Layer_LayerList.get(layer.getValue()).get("startAddr")

		.if(!_isReg(xpos) && !_isReg(ypos)) {
				lda #<address 
				sta.z S65_ScreenRamPointer + 0
				sta.z S65_ColorRamPointer + 0	
				lda #>address 
				sta.z S65_ScreenRamPointer + 1
				lda #>[address - S65_SCREEN_RAM]
				sta.z S65_ColorRamPointer + 1	
					
		} else {

				.if(_isReg(xpos) && _isReg(ypos)) {
						ldx S65_PseudoReg + 1 //YPOS
						clc 
						lda Layer_RowAddressLSB, x 
						adc S65_PseudoReg + 0 //XPOS
						php
						clc
						adc #<address
						sta.z S65_ScreenRamPointer + 0
						sta.z S65_ColorRamPointer + 0
						lda Layer_RowAddressMSB, x 
						adc #>address
						plp 
						adc #$00
						sta.z S65_ScreenRamPointer + 1
						sec 
						sbc #<S65_SCREEN_RAM 
						sta.z S65_ColorRamPointer + 1


				} else {
					.if(_isReg(ypos)) {
						ldx S65_PseudoReg + 1
						clc 
						lda Layer_RowAddressLSB, x 
						adc #<address
						sta.z S65_ScreenRamPointer + 0
						sta.z S65_ColorRamPointer + 0
						lda Layer_RowAddressMSB, x 
						adc #>address
						sta.z S65_ScreenRamPointer + 1
						sec 
						sbc #<S65_SCREEN_RAM 
						sta.z S65_ColorRamPointer + 1

					} else {
						clc 
						lda #<address 
						adc S65_PseudoReg + 0 //XPOS
						sta.z S65_ScreenRamPointer + 0
						sta.z S65_ColorRamPointer + 0
						lda Layer_RowAddressMSB, x 
						adc #$00
						sta.z S65_ScreenRamPointer + 1
						sec 
						sbc #<S65_SCREEN_RAM 
						sta.z S65_ColorRamPointer + 1
					}
				}

		}

	plx
	S65_AddToMemoryReport("Layer_SetScreenPointersXY")
	//DO NOT RESTORE BASE PAGE 	
}

// #define ROWMASK_FIXED

.pseudocommand Sprite_Enable layerNum : sprNum : xpos : ypos {
		phx
			ldx layerNum
			jsr _getSprIOoffsetForLayer
			jmp *
		plx
}
.pseudocommand Sprite_SetPosition layerNum : sprNum : xpos : ypos {

}
.pseudocommand Sprite_SetPointer layerNum : sprNum : pointer {
	
}
.pseudocommand Sprite_SetDimensions layerNum : sprNum : width : height {
	
}
.pseudocommand Sprite_SetColor layerNum : sprNum : color {
	
}
_lastFetchedLayer: .byte $ff
_lastFetchedSprite: .byte $ff 

_getSprIOoffsetForLayer: {	//Layer = x, Sprite = y
	
		//Only fetch if we dont already have it
		cpx _lastFetchedLayer
		bne !+
		cpy  _lastFetchedSprite
		bne !+
		bra !exit+

	!:	
	S65_SetBasePage()
		lda #$00
		sta.z S65_LastSpriteIOPointer + 1
		tya 
		asl 
		rol S65_LastSpriteIOPointer + 1		
		asl 
		rol S65_LastSpriteIOPointer + 1
		asl 
		rol S65_LastSpriteIOPointer + 1		
		asl 
		rol S65_LastSpriteIOPointer + 1
		sta.z S65_LastSpriteIOPointer + 0
		clc
		adc Layer_SpriteIOAddrLSB, x
		sta.z S65_LastSpriteIOPointer + 0
		lda S65_LastSpriteIOPointer + 1
		adc Layer_SpriteIOAddrMSB, x
		sta.z S65_LastSpriteIOPointer + 1
		
		
	S65_SetBasePage()
	!exit:

		rts

}

/**
* .pseudocommand Update
*
* @namespace Sprite
*/
.pseudocommand Sprite_Update ListSize {
		ldx #$00
	!layerloop:
		lda Layer_IsRRBSprite, x 
		lbeq !nextlayer+
		phx 
			//WE ARE IN AN RRB LAYER
			
			//clear the layer
				phx 
				txa 
				ldx #$a0
				ldy #$02
				jsr Layer_DMAClear
				pla 
				pha 		
				jsr Layer_DMAClearColorRRB	
				plx


			//Prep the base addresses 

			//get the Base address of the IO
			.const SprIO = S65_TempWord1
			.const LayerIO = S65_TempWord2
			// .const ScreenRowAddr = S65_TempWord3

			// Sprite IO base
			lda Layer_SpriteIOAddrLSB, x
			sta.z SprIO + 0
			lda Layer_SpriteIOAddrMSB, x
			sta.z SprIO + 1


			// Layer IO base ; TODO- Optimize
			txa 
			asl 
			tax 
			clc 
			adc #<Layer_DynamicDataTable
			sta.z S65_TempWord2 + 0
			lda #>Layer_DynamicDataTable
			adc #$00
			sta.z S65_TempWord2 + 1
			ldy #$00
			lda ((S65_TempWord2)), y 
			pha 
			iny 
			lda ((S65_TempWord2)), y 
			sta.z S65_TempWord2 + 1
			pla 
			sta.z S65_TempWord2 + 0


			//Clear the rowCharCountTable
			ldz #Layer_IOrowCountTableRRB //RowCountTable
			lda #$00//Reset to zero
		!: 
			sta (LayerIO), z
			inz 
			cpz #S65_VISIBLE_SCREEN_CHAR_HEIGHT + Layer_IOrowCountTableRRB
			bne !-

			// jmp *

			_Sprite_Update()
		plx	
	!nextlayer:
		inx 
		cpx #ListSize.getValue()
		lbne !layerloop-
}
.print ("MaskRowValue: $" + toHexString(MaskRowValue))
MaskRowValue:
		.fill 8, 255 - pow(2, 8-i) 

//As much as I want this next bit to be a base library method, it has to stay a macro due to
//references to addresses not defined until AFTER Layer_InitScreen
.macro _Sprite_Update() {
		.const SprIO = S65_TempWord1
		.const LayerIO = S65_TempWord2

		ldy #Layer_IOmaxSpritesRRB //maxSprite offset
		lda (LayerIO), y 
		sta MaxSprites

		//cycle the sprites
		ldz #$00 //sprite
	!spriteloop:
			phz
			ldy #Sprite_IOflags 
			lda (SprIO), y

			//Skip if not enabled
			lbpl !nextsprite+

				//Sprite is active so add an entry to the RRB

				//Figure out its screen row (ypos /8) and set screen/col pointers
				ldy #Sprite_IOy + 1

				lda (SprIO), y //MSB
				and #$03
				sta S65_TempByte1
				dey
				lda (SprIO), y //LSB
		pha 	//store so we can grab the 0-7 fine Y
				lsr S65_TempByte1
				ror 
				lsr S65_TempByte1
				ror 
				lsr S65_TempByte1
				ror 
				tay 

				jsr ResetScreenPointer


				//y is the row number store it (+3 = Layer_IOrowCountTableRRB to save adding later)
				tya 
				clc 
				adc #Layer_IOrowCountTableRRB
				sta.z S65_SpriteRowTablePtr


				//get and store base pointer
				ldy #Sprite_IOptr
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 0 //byte 0
				sta.z S65_SpritePointerOld + 0 //byte 0
				iny
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 1 //byte 1
				sta.z S65_SpritePointerOld + 1 //byte 1


			///////////////////
			//ROWs
			///////////////////
			ldy #Sprite_IOheight
			lda (SprIO), y
			sta.z S65_SpriteRowCounter

			lda #$00
			sta MaskEnable
			sta RowMask

				//retrieve the ypos lsb and use it to get the inverse 0-7 fine y
		pla 
				and #$07
				sta YscrollOffset
				sta S65_SpriteFineY

#if ROWMASK_FIXED
//TODO on HW	//Disabled row mask until its working
//ENABLE THIS BLOCK WHEN ROWMASK WORKS
				pha 
					tay 
					lda MaskRowValue, y 
					sta RowMask
				pla 
#endif



				beq !nextrow+
				eor #$07
				clc 
				adc #$01
				sta S65_SpriteFineY
				lsr 	//Have to move to bits 5-7
				ror 
				ror 
				ror 
				sta YscrollOffset
				beq !nextrow+

				//finey!=0 so We are spanning 1 extra row 
				inc S65_SpriteRowCounter
				//And that means we need to fetch 1 char back instead
				ldy #Sprite_IOwidth
				dew.z S65_SpritePointerTemp + 0 //byte 0
				dew.z S65_SpritePointerOld + 0 //byte 0

				
#if ROWMASK_FIXED
//TODO on HW	//Disabled row mask until its working
				// //And set the first row mask on //ENABLE THIS BLOCK WHEN ROWMASK WORKS
				lda #$08 //bit 3 (for color ram byte 0 ROWMASK)
				sta MaskEnable
#endif
			!:
			!nextrow:
				//If this row is off screen then skip this row
				ldy S65_SpriteRowTablePtr
				cpy #[S65_VISIBLE_SCREEN_CHAR_HEIGHT + Layer_IOrowCountTableRRB]
				bcc !continue+
					clc 
					ldy #Sprite_IOwidth
					lda (SprIO), y	
					adc.z S65_SpritePointerOld + 0
					sta.z S65_SpritePointerTemp + 0
					lda.z S65_SpritePointerOld + 0
					adc #$00
					sta.z S65_SpritePointerTemp + 0
					inc.z S65_SpritePointerTemp + 0
					inc.z S65_SpritePointerOld + 0
				jmp !skiprow+
			!continue:

				//Where do we start? get offset from rowcount table into z
				//and double it to give the byte offset
				ldz S65_SpriteRowTablePtr //RowCountTable y position offset
				lda (LayerIO), z
					//Skip if no room left in line buffer
					ldy #Layer_IOmaxCharsRRB
					cmp (LayerIO), y
					// jmp *
					lbcs !nextsprite+ 
				asl
				taz 

				//GOTOX Marker
				ldy #Sprite_IOx
				//in Screen ram
				lda (SprIO), y	
				sta ((S65_ScreenRamPointer)), z //scr byte 0
				//and color ram
				lda #$90 //transparent and gotox
				ora MaskEnable:#$BEEF	
				sta ((S65_ColorRamPointer)), z //col byte 0				
				iny //$02
				inz
				lda (SprIO), y
				and #$03
				ora YscrollOffset:#$BEEF	
				sta ((S65_ScreenRamPointer)), z //scr byte 1
				lda RowMask
				sta ((S65_ColorRamPointer)), z //col byte 1
				inz 



				/////////////////////////
				//COLUMNS
				/////////////////////////
				//Loop through the width of the char
						phx 
						ldy #Sprite_IOwidth
						lda (SprIO), y	
						sta WidthIncrement
						tax

						!charwidthLoop:
							//CHAR RAM 
							lda.z S65_SpritePointerTemp + 0
							sta ((S65_ScreenRamPointer)), z //scr byte 0
							lda #$08
							sta ((S65_ColorRamPointer)), z //col byte 0

							inz
							lda.z S65_SpritePointerTemp + 1	
							sta ((S65_ScreenRamPointer)), z //scr byte 1

							// inz
							// COLOR RAM 
							ldy #Sprite_IOcolor
							lda (SprIO), y	
							sta ((S65_ColorRamPointer)), z //col byte 1
							inz
								

							//increment pointer to next column
							ldy #Sprite_IOwidth
							lda (SprIO), y
							cmp #$01
							beq !+
#if ROWMASK_FIXED
//TODO on HW				//Disabled row mask until its working
							clc //SWITCH SEC for CLC THIS WHEN ROWMASK WORKS	
#else 
							sec //Using SEC isntead of CLC so we add an extra 1 
#endif
							lda.z S65_SpritePointerTemp + 0
							adc (SprIO), y			
							sta.z S65_SpritePointerTemp + 0
							bcc !+
							inc.z S65_SpritePointerTemp + 1
						!:

							dex 
							bne !charwidthLoop-		


							//set pointer to next row
							inw.z S65_SpritePointerOld
							lda.z S65_SpritePointerOld + 0		
							sta.z S65_SpritePointerTemp + 0
							lda.z S65_SpritePointerOld + 1		
							sta.z S65_SpritePointerTemp + 1

// 							ldy #Sprite_IOheight
// 							clc //Using CLC isntead of SEC so we subtract an extra 1 

// 							lda.z S65_SpritePointerTemp + 0
// 							sbc (SprIO), y			
// 							sta.z S65_SpritePointerTemp + 0
// 							bcs !+
// 							dec.z S65_SpritePointerTemp + 1
// 						!:		
// #if ROWMASK_FIXED
// #else
// //TODO on HW				//Disabled row mask until its working
// 							dew.z S65_SpritePointerTemp + 0 //DISABLE THIS WHEN ROWMASK WORKS
// 							dew.z S65_SpritePointerTemp + 0 //DISABLE THIS WHEN ROWMASK WORKS
// #endif

						plx

				//increment row count table entry by width + 1
				ldz S65_SpriteRowTablePtr //RowCountTable 

				lda (LayerIO), z
				clc 
				adc WidthIncrement:#$00
				adc #$01
				sta (LayerIO), z
				
		!skiprow:
			dec.z S65_SpriteRowCounter
			beq !nextsprite+		//Sprite is complete
			//Increment for next row
			clc 
			lda S65_ScreenRamPointer + 0
			adc #<S65_SCREEN_LOGICAL_ROW_WIDTH
			sta S65_ScreenRamPointer + 0
			sta S65_ColorRamPointer + 0
			php
			lda S65_ScreenRamPointer + 1
			adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
			sta S65_ScreenRamPointer + 1
			plp
			lda S65_ColorRamPointer + 1
			adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
			sta S65_ColorRamPointer + 1	

			inc S65_SpriteRowTablePtr	
			ldy S65_SpriteRowTablePtr
			


			cpy #[$80 + Layer_IOrowCountTableRRB]
			bne !noreset+
			//We are at the last row so reset screen pointers

			
			ldy #$00

			jsr ResetScreenPointer
			ldy #Layer_IOrowCountTableRRB
			sty S65_SpriteRowTablePtr

			// jmp *
		!noreset:	
			jmp !nextrow-



					
	!nextsprite:
		lda.z S65_SpriteFineY
		beq !+
		lda.z S65_SpriteRowCounter
		cmp #$01 //Last row??
		bne !+
		lda RowMask:#$ff
		eor #$ff 
		sta RowMask
	!:

		//increment sprite IO pointer
		clc 
		lda.z SprIO + 0
		adc #Sprite_SpriteIOLength
		sta.z SprIO + 0
		bcc !+
		inc.z SprIO + 1
	!: 	


		plz
		inz 
		cpz MaxSprites:#$BEEF
		lbne !spriteloop-
		///////////////////
		jmp End 


	ResetScreenPointer:
		clc
		lda Layer_RowAddressBaseLSB, y
		adc Layer_AddrOffsets + 0, x 
		sta.z S65_ScreenRamPointer + 0
		sta.z S65_ColorRamPointer + 0

		lda Layer_RowAddressBaseMSB, y
		adc Layer_AddrOffsets + 1, x 
		sta.z S65_ScreenRamPointer + 1	
		clc 
		adc #>[S65_COLOR_RAM - S65_SCREEN_RAM]						
		sta.z S65_ColorRamPointer+ 1
		rts

	End:
		//Now clear the remaining space
	
}
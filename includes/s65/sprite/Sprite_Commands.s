
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
			// Layer_ClearLayer #REGX : #$100 : #$01

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
				sta S65_TempByte1
				dey
				lda (SprIO), y //LSB
				lsr S65_TempByte1
				ror 
				lsr S65_TempByte1
				ror 
				lsr S65_TempByte1
				ror 
				tay 

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

				//y is the row number stopre it (+3 = Layer_IOrowCountTableRRB to save adding later)
				iny
				iny
				iny
				sty.z S65_SpriteRowTablePtr

				//get and store base pointer
				ldy #Sprite_IOptr
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 0 //byte 0
				iny
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 1 //byte 1


			///////////////////
			//ROWs
			///////////////////
			ldy #Sprite_IOheight
			lda (SprIO), y
			sta.z S65_SpriteRowCounter

			!nextrow:
				//Where do we start? get offset from rowcount table into z
				//and double it to give the byte offset
				ldz S65_SpriteRowTablePtr //RowCountTable y position offset
				lda (LayerIO), z
					//Skip if no room left in line buffer
					ldy #Layer_IOmaxCharsRRB
					cmp (LayerIO), y
					// jmp *
					bcs !nextsprite+ 
				asl
				taz 

				//GOTOX Marker
				ldy #Sprite_IOx
				//in Screen ram
				lda (SprIO), y	
				sta ((S65_ScreenRamPointer)), z //scr byte 0
				//and color ram
				lda #$90 //transparent and gotox	
				sta ((S65_ColorRamPointer)), z //col byte 0				
				iny //$02
				inz
				lda (SprIO), y	
				sta ((S65_ScreenRamPointer)), z //scr byte 1
				lda #$00
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
							sta ((S65_ScreenRamPointer)), z //byte 0
							inz
							lda.z S65_SpritePointerTemp + 1	
							sta ((S65_ScreenRamPointer)), z //byte 1
							// inz
							// COLOR RAM 
							lda #$20
							sta ((S65_ColorRamPointer)), z //byte 1
							inz
													
							//increment pointer
							inw.z S65_SpritePointerTemp
							dex 
							bne !charwidthLoop-				
						plx

				//increment row count table entry by width + 1
				ldz S65_SpriteRowTablePtr //RowCountTable 

				lda (LayerIO), z
				clc 
				adc WidthIncrement:#$00
				adc #$01
				sta (LayerIO), z
				

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
			jmp !nextrow-



					
	!nextsprite:

		//icnrement sprite IO pointer
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


		
}
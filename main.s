
//////////////////////////////////////////////////
// NCM Asset pipeline, Hi res and Layering test
//////////////////////////////////////////////////

// #define NODEBUG
#import "includes/s65/start.s"
	jmp Start 

		//Safest to define all the data before your code to avoid assembler pass errors
		.encoding "screencode_upper"
		palette:
			.import binary "assets/bin/test3_palette.bin"
		testScreenChars:
			.fill 16 * 8, [<[$200 + i], >[$200 + i]]
		testScreenColors:
			.import binary "assets/bin/test3_ncm.bin"
		message:
			S65_Text16("LAYER 2 - THIS IS AN FCM LAYER")

	Start:
		

		.const BLANK = $200
		.const BRICK = $206
		.const NUM_SPRITES = 128

		//Define and initlayers
		Layer_DefineResolution(40, 28, false)		//Resolution

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(20, 0, true) 

		.const LYR_LV = Layer_GetLayerCount()
		Layer_DefineScreenLayer(16, 200, true)  

		.const LYR_SP = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(32, NUM_SPRITES) 

		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, false) 

		Layer_InitScreen($10000)							//Initialize


	
		Palette_SetPalettes #$03 : #$00 : #$00
		Palette_LoadFromMem #$03 : palette : #$100

		//Clear layers
		Layer_ClearAllLayers #BLANK
		Layer_ClearLayer #LYR_BG : #BRICK : #$01

		//Add some text to UI layer
		Layer_AddText #LYR_UI : #0 : #0 : message : #4

		//Copy 8 rows of data from testScreenChars and testScreenColors to the
		//screen and color ram 
		Layer_SetScreenPointersXY #LYR_LV : #0: #0

		//Now draw the char set 4 times slightly offset each time
		ldz #$04
	!charsetloop:
			ldy #$00 //Source offset
			ldx #$00 
		!rowloop:	
				Layer_WriteToScreen testScreenChars,y  : testScreenColors, y : #$10
				Layer_AdvanceScreenPointers 
			inx 
			cpx #$08 //How many rows to draw
			bne !rowloop-
		dez 
		lbne !charsetloop-


		//Add some RRB sprites
		S65_SetBasePage()
		
			ldx #$00
		!:	
				Sprite_Enable #LYR_SP : #REGX

				System_GetRandom16 
				Sprite_SetPositionX #LYR_SP : #REGX : S65_ReturnValue

				System_GetRandom16 
				Sprite_SetPositionY #LYR_SP : #REGX : S65_ReturnValue
			
				Sprite_SetPointer #LYR_SP : #REGX : #$0261
				Sprite_SetDimensions #LYR_SP : #REGX : #$01 : #$02
				Sprite_SetColor #LYR_SP : #REGX : #$03

			inx 
			cpx #NUM_SPRITES
			lbne !-	
		S65_RestoreBasePage()

		
!loop:
	System_WaitForRaster($080)

		//Update - Call once per frame, its expensive!!
		Layer_Update

		//Move the BG Layer
		inc Layer_GetIO(LYR_LV, Layer_IOgotoX) + 0
		bne !+
		inc Layer_GetIO(LYR_LV, Layer_IOgotoX) + 1
	!:
		//Move the UI layer
		lda Layer_GetIO(LYR_UI, Layer_IOgotoX) + 0
		bne !+
		dec Layer_GetIO(LYR_UI, Layer_IOgotoX) + 1
	!:
		dec Layer_GetIO(LYR_UI, Layer_IOgotoX) + 0
 		

 		S65_SetBasePage()
 		System_BorderDebug($11)
	 		ldx #$00
	 	!:	
	 		txa 
	 		and #$01
	 		lbeq !direction2+
	 	!direction1:
	 		Sprite_GetPositionX #LYR_SP : #REGX 
	 		dew.z S65_ReturnValue
	 		Sprite_SetPositionX #LYR_SP : #REGX : S65_ReturnValue

	 		Sprite_GetPositionY #LYR_SP : #REGX 
	 		dew.z S65_ReturnValue
	 		Sprite_SetPositionY #LYR_SP : #REGX : S65_ReturnValue
	 		jmp !directiondone+

	 	!direction2:
	 		Sprite_GetPositionX #LYR_SP : #REGX 
	 		inw.z S65_ReturnValue
	 		Sprite_SetPositionX #LYR_SP : #REGX : S65_ReturnValue

	 		Sprite_GetPositionY #LYR_SP : #REGX 
	 		inw.z S65_ReturnValue
	 		Sprite_SetPositionY #LYR_SP : #REGX : S65_ReturnValue

	 	!directiondone:			 		
	 		inx 
	 		cpx #NUM_SPRITES
	 		lbne !-
	 	System_BorderDebug($0f)
 		S65_RestoreBasePage()



	jmp !loop-


S65_MemoryReport()

*=$8000
	.import binary "assets/bin/test3_chars.bin"

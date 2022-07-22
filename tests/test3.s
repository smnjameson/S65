
//////////////////////////////////////////////////
// NCM Asset pipeline, Hi res and Layering test
//////////////////////////////////////////////////

#define NODEBUG
#import "../includes/s65/start.s"
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
			S65_Text16("LAYER 3 - THIS IS AN FCM LAYER")

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
		Layer_DefineRRBSpriteLayer(64, NUM_SPRITES) 

		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, false) 

		Layer_InitScreen($10000)							//Initialize

		Palette_Assign #$03 : #$00 : #$03
		Palette_Set #$03
		Palette_LoadFromMem palette : #$100 

		lda #$ff
		sta $d020

		//Clear layers
		Layer_ClearAllLayers #BLANK
		Layer_Get #LYR_BG
		Layer_ClearLayer #BRICK : #$01

		//Add some text to UI layer
		Layer_Get #LYR_UI
		Layer_AddText #0 : #0 : message : #4

		//Copy 8 rows of data from testScreenChars and testScreenColors to the
		//screen and color ram 
		Layer_Get #LYR_LV
		Layer_SetScreenPointersXY #0: #0 

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
		ldx #$00
	!:		
		Sprite_Get #LYR_SP : #REGX

		Sprite_SetFlags #[Sprite_IOflagEnabled | Sprite_IOflagNCM]

		System_GetRandom16 
		Sprite_SetPositionX S65_ReturnValue
		System_GetRandom16 
		Sprite_SetPositionY S65_ReturnValue
	
		Sprite_SetPointer #$0261
		Sprite_SetDimensions #$02 : #$02
		Sprite_SetColor #$00

		inx 
		cpx #NUM_SPRITES
		lbne !-	

!loop:
	System_WaitForRaster($100)
	//Update - Call once per frame, its expensive!!
	Layer_Update
	System_BorderDebug($11)
		//Move the BG Layer 
		Layer_Get #LYR_LV
		Layer_GetGotoX 
		inw.z S65_ReturnValue
		Layer_SetGotoX S65_ReturnValue

		//Move the UI
		Layer_Get #LYR_UI
		Layer_GetGotoX 
		dew.z S65_ReturnValue
		Layer_SetGotoX S65_ReturnValue	
 		
 		//Move the sprites
 		ldx #$00
 	!:	
 		Sprite_Get #LYR_SP : #REGX

 		Sprite_GetPositionX
 		dew.z S65_ReturnValue
 		Sprite_SetPositionX S65_ReturnValue

 		Sprite_GetPositionY
 		dew.z S65_ReturnValue
 		Sprite_SetPositionY S65_ReturnValue
 		
 		inx 
 		cpx #NUM_SPRITES
 		lbne !-

 	System_BorderDebug($0f)
	jmp !loop-


S65_MemoryReport()

*=$8000
	.import binary "assets/bin/test3_chars.bin"

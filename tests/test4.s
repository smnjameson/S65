
//////////////////////////////////////////////////
// NCM Asset pipeline, Hi res and Layering test
//////////////////////////////////////////////////
#define NODEBUG
#import "../includes/s65/start.s"
	jmp Start 

		//Safest to define all the data before your code to avoid assembler pass errors
		.encoding "screencode_upper"
		palette:
			.import binary "assets/bin/test4_palette.bin"
		testScreenChars:
			.fill 16 * 8, [<[$200 + i], >[$200 + i]]
		testScreenColors:
			.import binary "assets/bin/test4_ncm.bin"
		message:
			S65_Text16("OOOOOH RRB SPRITES!!!")
		sinus:
			.fill 256, 112 + sin(i/256 * PI * 6) * 96
		cosinus:
			.fill 256, 112 + cos(i/256 * PI * 2) * 96	
		sinusindex:
			.byte $00


	Start:
		
		.const BLANK = $200
		.const BRICK = $206
		.const NUM_SPRITES = 64

		//Define and initlayers
		Layer_DefineResolution(40, 28, false)		//Resolution

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(20, 0, true) 

		.const LYR_SP = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(32, NUM_SPRITES) 

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
		Layer_AddText #0 : #0 : message : #$20


		//Add some RRB sprites
		ldx #$00
	!:		
		Sprite_Get #LYR_SP : #REGX
		Sprite_SetFlags #[Sprite_IOflagEnabled | Sprite_IOflagNCM]
		Sprite_SetPointer #$0261
		Sprite_SetDimensions #$01 : #$02
		Sprite_SetColor #$00 			
		inx 
		cpx #NUM_SPRITES
		lbne !-	


		ldy #$00
!loop:
	System_WaitForRaster($100)
	//Update - Call once per frame, its expensive!!
	Layer_Update

	System_BorderDebug($11)		
 		//Move the sprites
 		inc sinusindex
 		ldy sinusindex
 		ldx #$00
 	!:	
 		Sprite_Get #LYR_SP : #REGX

 		lda sinus, y
 		Sprite_SetPositionX #REGA
 		lda cosinus, y
 		Sprite_SetPositionY #REGA
 		
		iny 
 		iny 
 		iny 
 		iny 

 		inx 
 		cpx #NUM_SPRITES
 		lbne !-

 	System_BorderDebug($0f)
	jmp !loop-


S65_MemoryReport()

*=$8000
	.import binary "assets/bin/test4_chars.bin"

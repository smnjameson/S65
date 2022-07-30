
//////////////////////////////////////////////////
// NCM Asset pipeline, Hi res and Layering test
//////////////////////////////////////////////////

// #define NODEBUG
#import "includes/s65/start.s"
	jmp Start 

		//Safest to define all the data before your code to avoid assembler pass errors
		.encoding "screencode_upper"
		palette:
			.import binary "assets/bin/sprites1_palette.bin"
		testScreenChars:
			.fill 16 * 8, [<[$200 + i], >[$200 + i]]
		testScreenColors:
			// .import binary "assets/bin/tileset1_ncm.bin"
		message:
			S65_Text16("PNG65 FCM SPRITE OUTPUT TEST")

	Start:
		

		.const BLANK = $200
		.const NUM_SPRITES = 32

		//Define and initlayers
		Layer_DefineResolution(40, 28, false)		//Resolution

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(20, 0, true) 

		.const LYR_SP = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(125, NUM_SPRITES) 

		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, false) 

		Layer_InitScreen($10000)							//Initialize

		Palette_Assign #$03 : #$00 : #$03
		Palette_Set #$03
		Palette_LoadFromMem palette : #$100

		//Clear layers
		Layer_ClearAllLayers #BLANK
		Layer_Get #LYR_BG
		Layer_ClearLayer #BLANK : #$01

		//Add some text to UI layer
		Layer_Get #LYR_UI
		Layer_AddText #0 : #0 : message : #$01


		//Add some RRB sprites
		ldx #$00
	!:		
		Sprite_Get #LYR_SP : #REGX

		// Sprite_SetEnabled #TRUE
		Sprite_SetFlags #[ Sprite_IOflagEnabled ]

		System_GetRandom16 
		Sprite_SetPositionX S65_ReturnValue
		System_GetRandom16 
		Sprite_SetPositionY S65_ReturnValue
	
		Sprite_SetPointer #$0201
		Sprite_SetDimensions #4 : #4

		inx 
		cpx #NUM_SPRITES
		lbne !-	

!loop:
	System_WaitForRaster($100)
	//Update - Call once per frame, its expensive!!
	Layer_Update
	System_BorderDebug($11)
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

 	System_BorderDebug($ff)
	jmp !loop-


S65_MemoryReport()

*=$8000
	.import binary "assets/bin/sprites1_chars.bin"

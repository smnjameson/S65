
//////////////////////////////////////////////////
// Sprite Asset pipeline test
//////////////////////////////////////////////////

// #define NODEBUG
#import "includes/s65/start.s"
	jmp Start 
		//Safest to define all the data before your code to avoid assembler pass errors	

		Asset_ImportSpriteset("player", "assets/bin/test7/sprites1", $6000)
		Asset_ImportSpriteset("enemy", "assets/bin/test7/sprites2", S65_LastImportPtr)//Carry on from last asset import
		Asset_ImportSpriteset("icons", "assets/bin/test7/sprites3", S65_LastImportPtr) //Carry on from last asset import
		.const PlayerSprites = Asset_GetSpriteset("player")
		.const EnemySprites = Asset_GetSpriteset("enemy")
		.const IconSprites = Asset_GetSpriteset("icons")

		Asset_ImportCharset("map", "assets/bin/test7/tileset1", S65_LastImportPtr) //Carry on from last asset import
		Asset_ImportCharset("mapfg", "assets/bin/test7/tileset2", S65_LastImportPtr) //Carry on from last asset import
		.const MapChars = Asset_GetCharset("map")
		.const MapFGChars = Asset_GetCharset("mapfg")

		paletteSpr:
			Asset_ImportSpritesetPalette("icons")
		palette:
			Asset_ImportCharsetPalette("mapfg")
		message:
			S65_Text16("multi asset palette merge pipeline test")
		testScreen1Chars:
			.fill 20 * 8, [<[MapChars.indices.get(0) + i], >[MapChars.indices.get(0)+ i]]
		testScreen2Chars:
			.fill 10 * 8, [<[MapFGChars.indices.get(0) + i], >[MapFGChars.indices.get(0) + i]]

	Start:
		.const BLANK = MapFGChars.indices.get(0) 
		.const BRICK = MapFGChars.indices.get(6)

		.const NUM_PLAYER_SPRITES = 100
		.const NUM_ICON_SPRITES = 64
	
		//Define and initlayers
		Layer_DefineResolution(40, 28, false)		//Resolution

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(20, 0, true) 

		.const LYR_SP1 = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(32, NUM_PLAYER_SPRITES) 
		.const LYR_LV = Layer_GetLayerCount()
		Layer_DefineScreenLayer(20, 0, false)  		
		.const LYR_FG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(10, 0, true)  		
		.const LYR_SP2 = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(32, NUM_ICON_SPRITES) 
		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(40, 0, false) 

		Layer_InitScreen($10000)							//Initialize

		Palette_Assign #$01: #$00 : #$03
		Palette_Set #$01
		Palette_LoadFromMem palette : #$100		
		Palette_Set #$03
		Palette_LoadFromMem paletteSpr : #$100


		lda #$ff 
		sta $d020

		//Clear layers
		Layer_ClearAllLayers #BLANK
		Layer_Get #LYR_BG
		Layer_ClearLayer #BRICK : #$30

		//Add some text to UI layer
		Layer_Get #LYR_UI
		Layer_AddText #1 : #14 : message : #$05



		//Now draw the char sets 
		//Charset 1 - FCM
		Layer_Get #LYR_LV
		Layer_SetScreenPointersXY #0: #3 		
		ldy #$00 //Source offset
		ldx #$00 
	!rowloop:	
			Layer_WriteToScreen testScreen1Chars,y  :  : #20 //FCM so leave color blank
			Layer_AdvanceScreenPointers 
		inx 
		cpx #$08 //How many rows to draw
		bne !rowloop-

		Layer_Get #LYR_FG
		Layer_SetScreenPointersXY #0: #16		
		ldy #$00 //Source offset
		ldx #$00 
	!rowloop:	
			Layer_WriteToScreen testScreen2Chars,y  :  MapFGChars.colorAddress,y : #10
			Layer_AdvanceScreenPointers 
		inx 
		cpx #$08 //How many rows to draw
		bne !rowloop-


		//Add some RRB sprites
		ldx #$00
	!:		
		Sprite_Get #LYR_SP1 : #REGX

		txa 
		and #$07
		Sprite_SetSpriteMeta #PlayerSprites.id : #REGA //Auto set pointer, dimensions, color, flags
		System_GetRandom16 
		Sprite_SetPositionX S65_ReturnValue
		System_GetRandom16
		Sprite_SetPositionY S65_ReturnValue

		inx 
		cpx #NUM_PLAYER_SPRITES
		lbne !-	


		//Add some FCM RRB sprites on another layer
		ldx #$00
	!:		
		Sprite_Get #LYR_SP2 : #REGX

		txa 
		and #$08
		beq !other+

		!standard:	
			txa 
			and #$07
			Sprite_SetSpriteMeta #IconSprites.id : #REGA//Auto set pointer, dimensions, color, flags
			System_GetRandom8 
			Sprite_SetPositionX #REGA
			System_GetRandom16
			Sprite_SetPositionY S65_ReturnValue
			jmp !done+
		!other:
			txa 
			and #$03
			Sprite_SetSpriteMeta #EnemySprites.id : #REGA//Auto set pointer, dimensions, color, flags
			System_GetRandom8 
			Sprite_SetPositionX #REGA
			System_GetRandom16
			Sprite_SetPositionY S65_ReturnValue	
		!done:

		inx 
		cpx #NUM_ICON_SPRITES
		lbne !-	

!mainloop:
	System_WaitForRaster($110)
	//Update - Call once per frame, its expensive!!
	Layer_Update
	System_BorderDebug($ff)
 		//Move the sprites
 		ldx #$00
 	!loop:	
	 		Sprite_Get #LYR_SP1 : #REGX
	 		Sprite_GetPositionX
	 		dew.z S65_ReturnValue
	 		Sprite_SetPositionX S65_ReturnValue
	 		Sprite_GetPositionY
	 		dew.z S65_ReturnValue
	 		Sprite_SetPositionY S65_ReturnValue	
 		inx 
 		cpx #NUM_PLAYER_SPRITES
 		bne !loop-

 		ldx #$00
 	!loop:	
	 		Sprite_Get #LYR_SP2 : #REGX
	 		Sprite_GetPositionY
	 		txa 
	 		and #$01 
	 		beq !+
		 		dew.z S65_ReturnValue
		 		bra !done+
		 	!:
		 		inw.z S65_ReturnValue
		 	!done:
		 	Sprite_SetPositionY S65_ReturnValue	
 		inx 
 		cpx #NUM_ICON_SPRITES
 		bne !loop-

 	System_BorderDebug($ff)
	jmp !mainloop-
	
S65_MemoryReport()


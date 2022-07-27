
//////////////////////////////////////////////////
// Animated sprite hflip test
//////////////////////////////////////////////////
// #define NODEBUG
#import "includes/s65/start.s"
	jmp Start 
		//Safest to define all the data before your code to avoid assembler pass errors	

		Asset_ImportSpriteset("hero", "tests/assets/bin/test8/characters", $8000)
		.const HeroSprites = Asset_GetSpriteset("hero")
		.const AnimKnight = Anim_Define("knight", HeroSprites, 0, 8)
		.const AnimWizard = Anim_Define("wizard", HeroSprites, 9, 17)


		.const BLANK = $0020
		.const NUM_SPRITES = 200

		paletteSpr:
			Asset_ImportSpritesetPalette("hero")
		message:
			////////////0         1         2         3         4
			S65_Text16("animated sprite and hflip test")
		heroDir:
			.fill NUM_SPRITES, floor(random() * 2)
	Start:

	
		//Define and initlayers
		Layer_DefineResolution(40, 28, false)		//Resolution

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(40, 0, false) 
		.const LYR_SP = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(64, NUM_SPRITES)  
		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(40, 0, false) 

		Layer_InitScreen($10000)							//Initialize

		Palette_Assign #$01: #$00 : #$03	
		Palette_Set #$03
		Palette_LoadFromMem paletteSpr : #$100


		lda #$ff 
		sta $d020

		//Clear layers
		Layer_ClearAllLayers #BLANK


		//Add some text to UI layer
		Layer_Get #LYR_UI
		Layer_AddText #5 : #14 : message : #$05


		//Add some RRB sprites
		ldx #$00
	!loop:		
		Sprite_Get #LYR_SP : #REGX

		Sprite_SetSpriteMeta #HeroSprites.id : #$08//Auto set pointer, dimensions, color, flags

		txa 
		and #$01
		beq !knight+
	!wizard:
		Sprite_SetAnim #AnimWizard.id : #$03 //Set sprites animation and speed
		bra !charSelectDone+
	!knight:
		Sprite_SetAnim #AnimKnight.id : #$03 //Set sprites animation and speed
	!charSelectDone:


		//Set a random frame (probably needs a method of its own)
		txa
		and #$07
		ldy #Sprite_IOanimFrame
		sta (S65_LastSpriteIOPointer), y 

		//Set flipH if we face left
 		lda heroDir, x 
 		beq !right+
 	!left:
 		Sprite_SetFlags #[Sprite_IOflagFlipH]
 	!right:

		//Set random position
		System_GetRandom16 
		Sprite_SetPositionX S65_ReturnValue
		System_GetRandom8	
		Sprite_SetPositionY S65_ReturnValue

		inx 
		cpx #NUM_SPRITES
		lbne !loop-	




!mainloop:
	System_WaitForRaster($100)
	//Update - Call once per frame, its expensive!!
	Layer_Update
	System_BorderDebug($ff)
 		//Move the sprites
 		ldx #$00
 	!loop:	
	 		Sprite_Get #LYR_SP : #REGX

	 		lda heroDir, x 
	 		beq !right+
	 	!left:
	 		Sprite_GetPositionX 		
	 		dew.z S65_ReturnValue
	 		bra !done+
	 	!right:
	 	 	Sprite_GetPositionX 		
	 		inw.z S65_ReturnValue
	 	!done:
	 		Sprite_SetPositionX S65_ReturnValue	

 		inx 
 		cpx #NUM_SPRITES
 		bne !loop-


 	System_BorderDebug($ff)
	jmp !mainloop-
	


S65_MemoryReport()


//////////////////////////////////////////////////
// Animated sprite hflip test
//////////////////////////////////////////////////
#define NODEBUG
#import "includes/s65/start.s"
	jmp Start 
		//Safest to define all the data before your code to avoid assembler pass errors	

		Asset_ImportSpriteset("hero", "assets/bin/test9/characters", $5000)
		.const HeroSprites = Asset_GetSpriteset("hero")
		.const AnimKnight = Anim_Define("knight", HeroSprites, 0, 4)

		Asset_ImportCharset("mapchars", "assets/bin/test9/tileset1", S65_LastImportPtr )
		.const MapCharset = Asset_GetCharset("mapchars")

		Asset_ImportTilemap("map", "assets/bin/test9/map", MapCharset, S65_LastImportPtr)
		.const Map = Asset_GetTilemap("map")

		.const BLANK = MapCharset.indices.get(0)
		.const NUM_SPRITES = 128

		paletteChr:
			Asset_ImportCharsetPalette("mapchars")
		paletteSpr:
			Asset_ImportSpritesetPalette("hero")

		message:
			////////////0         1         2         3         4
			S65_Text16("5x ncm tilemap + 2x fcm ui + 128 rrb spr")
		mapGotoX:
			.word $0000,$0000,$0000,$0000,$0000
		mapXPos:
			.byte $00,$00,$00,$00,$00	
		mapXSpeed:
			.byte $01,$02,$03,$04,$05		
		tilemapVerticalOffset:
			.byte 14,0,28,42,42

	Start:

	
		//Define and initlayers
		Layer_DefineResolution(40, 28, false)		//Resolution

		//Define our layer constants using an enum for neatness
		.enum { 
			LYR_BG, 
			LYR_PAR1, LYR_PAR2, LYR_PAR3, LYR_PAR4, 
			LYR_SP,
			LYR_UI, LYR_UI2
		}
		Layer_DefineScreenLayer(21, 0, true) 

		Layer_DefineScreenLayer(21, 0, true) 
		Layer_DefineScreenLayer(21, 0, true) 
		Layer_DefineScreenLayer(21, 0, true)
		Layer_DefineScreenLayer(21, 0, true) 

		Layer_DefineRRBSpriteLayer(48, NUM_SPRITES)  

		Layer_DefineScreenLayer(42, 1, false) 
		Layer_DefineScreenLayer(42, 0, false) 

		Layer_InitScreen($10000)							//Initialize

		
		Palette_Assign #$01 : #$00 : #$03 	
		Palette_Set #$01
		Palette_LoadFromMem paletteChr : #$100			
		Palette_Set #$03
		Palette_LoadFromMem paletteSpr : #$100		

		lda #$ff
		sta $d020
		lda #$0e
		sta $d021

		//Clear layers
		Layer_ClearAllLayers #BLANK

		Layer_Get #LYR_UI
		Layer_ClearLayer #$0020

		// Add some text to UI layer
		Layer_Get #LYR_UI
		Layer_AddText #0 : #25 : message : #$ff //shadow
		Layer_Get #LYR_UI2
		Layer_AddText #0 : #25 : message : #$0d

		//Add some RRB sprites
		ldx #$00
	!loop:		
		Sprite_Get #LYR_SP : #REGX
		Sprite_SetSpriteMeta #HeroSprites.id : //Auto set pointer, dimensions, color, flags
		Sprite_SetAnim #AnimKnight.id : #$03 //Set sprites animation and speed

		//Set random position
		System_GetRandom16
		Sprite_SetPositionX S65_ReturnValue
		System_GetRandom8	
		Sprite_SetPositionY S65_ReturnValue

		inx 
		cpx #NUM_SPRITES
		lbne !loop-	


!mainloop:
	System_BorderDebug($ff)
	System_WaitForRaster($f8)
		
		System_BorderDebug($01)
		//Update layer positions for parallax
		ldx #$00
	!loop:
			//Subtract speed from fineX
			txa 
			asl 
			tay //get index*2 for lookign up word values in table
			lda mapGotoX+0, y
			sec 
			sbc mapXSpeed, x
			sta mapGotoX+0, y
			lda mapGotoX+1, y
			sbc #$00
			sta mapGotoX+1, y
			lbeq !skip+	//We are at $0000?
			and #$03
			sta mapGotoX+1, y
			System_Compare16 mapGotoX,y : #$03f1 
			lbcs !skip+	//We are in the range $03f1-$03ff

			//We are at <$03f1 so its time to shift map
			//Shift gotoX back
			clc 
			lda mapGotoX+0, y
			adc #$10
			sta mapGotoX+0, y
			lda mapGotoX+1, y
			adc #$00
			sta mapGotoX+1, y

			//Increment map position
			inc mapXPos, x
			lda mapXPos, x
			cmp #[$7f - 21] //Map width - screen width, in tiles
			bne !+
			lda #$00
		!:
			sta mapXPos, x
			
			
			//Now shift and redraw the far right column for this layer
			Layer_Get #REGX
			Layer_Shift #1
			Layer_SetScreenPointersXY #20: #0
			Tilemap_Get #Map.id		
			Tilemap_Draw mapXPos,x : tilemapVerticalOffset,x : #1:  #14			

	!skip:
		//Set the layers gotoX
		Layer_Get #REGX
		Layer_SetGotoX mapGotoX, y
		inx 
		cpx #LYR_SP //All layers up to but not including the sprite layer
		lbne !loop-


		
	 	//Move the sprites
 		ldx #$00
 	!loop:	
 		Sprite_Get #LYR_SP : #REGX
 	 	Sprite_GetPositionX 		
 		inw.z S65_ReturnValue
 		Sprite_SetPositionX S65_ReturnValue	
 		inx 
 		cpx #NUM_SPRITES
 		bne !loop-

		
 	
 	//Now Update - Call once per frame, its expensive!!
	Layer_Update
	jmp !mainloop-

S65_MemoryReport()



//////////////////////////////////////////////////
// NCM Asset pipeline, Hi res and Layering test
//////////////////////////////////////////////////

// #define NODEBUG
#import "includes/s65/start.s"
	jmp Start 



			//Safest to define all the data before your code to avoid assembler pass errors
			.encoding "screencode_upper"
			palette:
				.import binary "assets/bin/test2_palette.bin"
			testScreenChars:
				.fill 16 * 8, [<[$100 + i], >[$100 + i]]
			testScreenColors:
				.import binary "assets/bin/test2_ncm.bin"
			message:
				S65_Text16("LAYER 2 - THIS IS AN FCM LAYER")

	Start:
		Layer_DefineResolution(42, 30, true)		//Resolution


		.const BLANK = $100
		.const BRICK = $106

		//Define and initlayers
		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(21, 0, true)  			
		.const LYR_LV = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, true)  			
		.const LYR_SP = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(64, 16) 		
		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, false) 
		Layer_InitScreen($10000)							//Initialize
	
		Palette_SetPalettes #$03 : #$00 : #$00
		Palette_LoadFromMem #$03 : palette : #256

		lda #$15
		sta $d021


		//Clear layers
		Layer_ClearAllLayers #BLANK
		Layer_ClearLayer #LYR_BG : #BRICK : #$01

		//Add some text to UI layer
		Layer_AddText #LYR_UI : #0 : #12 : message : #4

		//Copy 8 rows of data from testScreenChars and testScreenColors to the
		//screen and color ram 
		Layer_SetScreenPointersXY #LYR_LV : #0: #0

		//Now draw the char set 4 times slightly offset each time
		ldz #$04
	!charsetloop:
			ldy #$00 //Source offset
			ldx #$08 //How many rows to draw
		!rowloop:	
				Layer_WriteToScreen testScreenChars,y  : testScreenColors, y : #$10
				Layer_AdvanceScreenPointers 
			dex 
			bne !rowloop-
		dez 
		lbne !charsetloop-


		//Add some RRB sprites

		//First lets do it just using direct IO 
		//set x and y
		lda #$80
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOx)	+ 0	
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOy)	+ 0
		lda #$00
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOx) + 1
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOy) + 1	

		//set pointer for sprite 0
		lda #$01
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOptr) + 0	
		lda #$01
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOptr) + 1

		//enable
		lda #$80	
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOflags)	
		//width
		lda #$02
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOwidth)	
		//height
		lda #$02
		sta Sprite_GetIO(LYR_SP, 0, Sprite_IOheight)	

		//Now lets make one using helper commands	
		lda #$40
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOx)	+ 0	
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOy)	+ 0
		lda #$00
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOx) + 1
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOy) + 1	

		lda #$01
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOptr) + 0	
		lda #$01
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOptr) + 1

		//enable
		lda #$80	
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOflags)	
		//width
		lda #$02
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOwidth)			
		//height
		lda #$02
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOheight)	
!loop:
	System_WaitForRaster($030)
	System_BorderDebug($01)

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

		//Update - Call once per frame, its expensive!!
		Layer_Update

	System_BorderDebug($0f)
	jmp !loop-

S65_MemoryReport()

*=$4000
	.import binary "assets/bin/test2_chars.bin"

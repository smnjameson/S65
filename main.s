
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
		Layer_DefineResolution(40, 28, false)		//Resolution


		.const BLANK = $200
		.const BRICK = $206
		.const NUM_SPRITES = 32
		//Define and initlayers
		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(20, 0, true)  			
		.const LYR_LV = Layer_GetLayerCount()
		Layer_DefineScreenLayer(16, 200, true)  			
		.const LYR_SP = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(20, NUM_SPRITES + 1) 		
		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, false) 
		Layer_InitScreen($10000)							//Initialize
	
		Palette_SetPalettes #$03 : #$00 : #$00
		Palette_LoadFromMem #$03 : palette : #256

		lda #$15
		sta $d021


		// jmp *
		//Clear layers
		Layer_ClearAllLayers #BLANK
		Layer_ClearLayer #LYR_BG : #BRICK : #$01
		// Layer_ClearLayer #LYR_SP : #BRICK : #$00


		//Add some text to UI layer
		Layer_AddText #LYR_UI : #0 : #0 : message : #4

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

		// .for(var i=0; i<NUM_SPRITES; i++) {
		// 	lda #[random() * 200]
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOx)	+ 0
		// 	lda #[random() * 200]	
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOy)	+ 0
		// 	lda #$00
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOx) + 1
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOy) + 1	

		// 	//set pointer for sprite 0
		// 	lda #$61
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOptr) + 0	
		// 	lda #$02
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOptr) + 1

		// 	//enable
		// 	lda #$80	
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOflags)	
		// 	//width
		// 	lda #$01
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOwidth)	
		// 	//height
		// 	lda #$02
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOheight)	
		// 	//color
		// 	lda #$03
		// 	sta Sprite_GetIO(LYR_SP, i, Sprite_IOcolor)
		// }

		//Now lets make one using helper commands	
		lda #$40
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOx)	+ 0	
		lda #$00
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOx) + 1

		lda #$04
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOy)	+ 0
		lda #$00
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOy) + 1	

		lda #$61
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
		// color	
		lda #$03
		sta Sprite_GetIO(LYR_SP, 1, Sprite_IOcolor)
		
!loop:
	System_WaitForRaster($100)
	

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
 
		// .for(var i=0; i<NUM_SPRITES; i++) {
		// 	//Move the UI layer
		// 		inc Sprite_GetIO(LYR_SP, i, Sprite_IOx) + 0
		// 		bne !+
		// 		inc Sprite_GetIO(LYR_SP, i, Sprite_IOx) + 1
		// 	!:
		// 	//Move the UI layer
		// 		inc Sprite_GetIO(LYR_SP, i, Sprite_IOy) + 0
		// 		bne !+
		// 		inc Sprite_GetIO(LYR_SP, i, Sprite_IOy) + 1
		// 	!:			
		// }


		//Update - Call once per frame, its expensive!!
		Layer_Update

	
	jmp !loop-

S65_MemoryReport()

*=$8000
	.import binary "assets/bin/test3_chars.bin"

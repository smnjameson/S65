
//////////////////////////////////////////////////
// NCM Asset pipeline, stretched 336x240 res 
// and Layering test
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

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, true)  			//layer 1
		.const LYR_LV = Layer_GetLayerCount()
		Layer_DefineScreenLayer(32, 0, true)  			//layer 1
		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(30, 0, false)  			//layer 2
		Layer_InitScreen($8000)							//Initialize
	
		Palette_SetPalettes #$03 : #$00 : #$00
		Palette_LoadFromMem #$03 : palette : #256

		lda #$15
		sta $d021

		//clear screen
		.const BLANK = $100
		.const BRICK = $106
		//Clear all layers to blank
		Layer_ClearAllLayers #BLANK 
		//Then fill the background with briick in color #$01
		Layer_ClearLayer #LYR_BG : #BRICK : #$01
		// Layer_ClearLayer #LYR_BG : #$002e

		//Add some text to UI layer
		Layer_AddText #LYR_UI : #0 : #12 : message : #1


		//Copy 8 rows of data from testScreenChars and testScreenColors to the
		//screen and color ram 
		//Set the pointers for LayerBG at 0,9
		Layer_SetScreenPointersXY #LYR_LV : #0: #0

		//Now draw the char set 4 times slightly offset each time
		ldz #$04
	!charsetloop:
			//Draw full charset
			ldy #$00 //Source offset
			ldx #$08 //How many rows to draw
		!rowloop:	
				//draw a row at current position (updates y register)
				Layer_WriteToScreen testScreenChars,y  : testScreenColors, y : #$10
				//Advance screen pointers to next row (defaults to LOGICAL ROW SIZE)
				Layer_AdvanceScreenPointers 
			!:
			dex 
			bne !rowloop-

		Layer_AdvanceScreenPointers #$04	//Move the screen pointer across 4 bytes/2 chars for the next charset
		dez 
		lbne !charsetloop-


!loop:
	System_WaitForRaster($110)
	System_BorderDebug($01)

		//Move the BG Layer
		inc Layer_GetIOAddress(LYR_LV, Layer_IOGotoX) + 0
		bne !+
		inc Layer_GetIOAddress(LYR_LV, Layer_IOGotoX) + 1
	!:
		//Move the UI layer
		lda Layer_GetIOAddress(LYR_UI, Layer_IOGotoX) + 0
		bne !+
		dec Layer_GetIOAddress(LYR_UI, Layer_IOGotoX) + 1
	!:
		dec Layer_GetIOAddress(LYR_UI, Layer_IOGotoX) + 0

		//Update - Call once per frame, its expensive!!
		Layer_Update

	System_BorderDebug($0f)
	jmp !loop-

S65_MemoryReport()

*=$4000 "Char set"
	.import binary "assets/bin/test2_chars.bin"

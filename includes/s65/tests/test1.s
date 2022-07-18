// #define NODEBUG
#import "includes/s65/s65.s"

	jmp Start 

		//Safest to define all the data before your code to avoid assembler pass errors
		//Or have data with known addresses such as a block of data only with its 
		//own * program counter directive, see comment at top for alternative
		.encoding "screencode_upper"
		message:
			S65_Text16("THIS IS ON THE UI LAYER")
		palette:
			.import binary "assets/bin/test1_palette.bin"

	Start:
		.var width = 64 								//512x288 (uses 80 column mode)
		.var height = 36
		Layer_DefineResolution(width, height, false)	

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(64, 0, false)  			//layer 0

		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(40, 80, false)			//layer 1

		Layer_InitScreen($8000)							//Initialize

		Palette_SetPalettes #$03 : #$00 : #$00
		Palette_LoadFromMem #3 : palette : #256

		lda #$df
		sta $d021

		.const BLANK = $100				
		Layer_ClearLayer #LYR_UI : #BLANK			

		Layer_AddText #1 : #0 : #8 : message : #$0f

		Layer_UpdateLayerOffsets 

!loop:
	System_WaitForRaster($0ff)
	System_BorderDebug($01)

		//Increment the GOTOX for the UI Layer
		inc Layer_GetIOAddress(LYR_UI, Layer_IOGotoX) + 0
		bne !+
		inc Layer_GetIOAddress(LYR_UI, Layer_IOGotoX) + 1
	!:

		//Update all gotox markers
		Layer_UpdateLayerOffsets 

	System_BorderDebug($10)
	jmp !loop-


S65_MemoryReport()

//CHARSET
*=$4000 "charset"
	.import binary "assets/bin/test1_chars.bin"
//TEST SCREEN DATA
*=$8000 "Test screen"
	//Move down some lines
	.fill (S65_SCREEN_LOGICAL_ROW_WIDTH) * 3, [<BLANK, >BLANK]
	//Now draw the FCM charset
	.for(var y=0; y<7; y++) {
		.var rowStart = *
		.byte $00,$00 //Initial gotox
		.fill 32, [<[$100 + y * $20 + i], >[$100 + y * $20 + i]]
		//fill rest of line with BLANKS
		.fill (S65_SCREEN_LOGICAL_ROW_WIDTH - (*-rowStart))/2, [<BLANK, >BLANK]
	}
	//make sure the rest of the screen is blank too
	.fill ($8000 + S65_SCREEN_LOGICAL_ROW_WIDTH * S65_VISIBLE_SCREEN_CHAR_HEIGHT - *)/2, [<BLANK, >BLANK]

 
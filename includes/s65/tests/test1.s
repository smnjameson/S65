//////////////////////////////////////////////////
// Resolution, scaling and FCM layering test
//////////////////////////////////////////////////

// #define NODEBUG
#import "includes/s65/start.s"

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

		.const BLANK = $100	
		Layer_Get #LYR_UI			
		Layer_ClearLayer #BLANK			
		Layer_AddText #0 : #8 : message : #$0f

!loop:
	System_WaitForRaster($0ff)
	System_BorderDebug($01)

		// Layer_Get #LYR_UI (not needed we already have this layer active from above)
		//Increment the GOTOX for the UI Layer
		Layer_GetGotoX 
		inw.z S65_ReturnValue
		Layer_SetGotoX S65_ReturnValue

		//Update all gotox markers
		Layer_Update 

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

 
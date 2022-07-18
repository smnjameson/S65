// #define NODEBUG
#import "includes/s65/s65.s"

	jmp Start 

	//Safest to define all the data before your code to avoid assembler pass errors
	.encoding "screencode_upper"
	message:
		.fill 32, [<[$100 + i], >[$100 + i]]
		.word $ffff
	message2:
		.fill 32, [<[$120 + i], >[$120 + i]]
		.word $ffff		
	message3:
		.fill 32, [<[$140 + i], >[$140 + i]]
		.word $ffff	
	message4:
		.fill 32, [<[$160 + i], >[$160 + i]]
		.word $ffff					
	message5:
		.fill 32, [<[$180 + i], >[$180 + i]]
		.word $ffff					
	message6:
		.fill 32, [<[$1a0 + i], >[$1a0 + i]]
		.word $ffff					
	message7:
		.fill 32, [<[$1c0 + i], >[$1c0 + i]]
		.word $ffff	

	colors:
		.fill 64, i
	paletteFilename:
		.text @"PALETTE1.BIN\$00" //Zero terminated string
	palette:
		.import binary "assets/bin/test1_palette.bin"

	Start:

		.var width = 40 								//320x240
		.var height = 30

		Layer_DefineResolution(width, height, false)		//Resolution / stretch

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(40, 0, false)  			//layer 0

		.const LYR_FG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(40, 0, false)  			//layer 1

		.const LYR_SP = Layer_GetLayerCount()
		Layer_DefineRRBSpriteLayer(16, 128)  			//layer 2

		.const LYR_UI = Layer_GetLayerCount()
		Layer_DefineScreenLayer(40, 80, false)			//layer 3

		Layer_InitScreen($8000)							//Initialize

	
		Palette_SetPalettes #$03 : #$00 : #$00

		Palette_LoadFromSD #2 : paletteFilename
		// Palette_LoadFromMem #$00 : palette : #32
		Palette_LoadFromMem #3 : palette : #256


		lda #$10
		sta $d020
		sta $d021

		.const BLANK = $100
		Layer_ClearLayer #LYR_BG : #BLANK		
		Layer_ClearLayer #LYR_FG : #BLANK			
		Layer_ClearLayer #LYR_UI : #BLANK			


		Layer_AddText #0 : #0 : #0 : message : #0
		Layer_AddText #0 : #0 : #1 : message2 : #0
		Layer_AddText #0 : #0 : #2 : message3 : #0
		Layer_AddText #0 : #0 : #3 : message4 : #0
		Layer_AddText #0 : #0 : #4 : message5 : #0
		Layer_AddText #0 : #0 : #5 : message6 : #0
		Layer_AddText #0 : #0 : #6 : message7 : #0


		

!loop:
	System_WaitForRaster($0ff)
	System_BorderDebug(1)
		Layer_UpdateLayerOffsets 
	System_BorderDebug(0)
	jmp !loop-


S65_MemoryReport()


//NCM Test data
*=$4000
	.import binary "assets/bin/test1_chars.bin"

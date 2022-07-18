// #define NODEBUG
#import "includes/s65/s65.s"
	jmp Start 

			//Safest to define all the data before your code to avoid assembler pass errors
			.encoding "screencode_upper"
			palette:
				.import binary "assets/bin/test2_palette.bin"
			testScreenChars:
				.fill 16 * 7, [<[$100 + i], >[$100 + i]]
			testScreenColors:
				.for(var i=0; i<7; i++) {
					.byte $00,$10,$20,$30,$40,$50,$60,$70
					.byte $00,$10,$20,$30,$40,$50,$60,$70
				}

	Start:
		Layer_DefineResolution(32, 30, true)		//Resolution + stretch mode

		.const LYR_BG = Layer_GetLayerCount()
		Layer_DefineScreenLayer(16, 0, true)  			//layer 0
		Layer_InitScreen($8000)							//Initialize
	
		Palette_SetPalettes #$03 : #$00 : #$00
		Palette_LoadFromMem #$03 : palette : #256

		lda #$fe
		sta $d021

		.const BLANK = $100
		Layer_ClearAllLayers #BLANK

		Layer_SetScreenPointersXY #LYR_BG : #0: #0

		ldy #$00 //Source offset
		ldx #$07 //How many rows to draw
	!rowloop:	
			Layer_WriteToScreen testScreenChars,y  : testScreenColors,y : #$10
			Layer_AdvanceScreenPointers 
		!:
		dex 
		bne !rowloop-



!loop:
	System_WaitForRaster($0ff)
	System_BorderDebug($01)
		Layer_UpdateLayerOffsets 
	System_BorderDebug($0f)
	jmp !loop-


S65_MemoryReport()


*=$4000
	.import binary "assets/bin/test2_chars.bin"

#import "includes/s65/s65.s"
	.const SCREEN_RAM = $8000

	.const MAX_LAYERS = 10
	.const LayerBG = 0
	.const Layers = 1

	jmp Start 

	//Better to keep data before the code as it may not be parsable for some commands
	//using evaluated addressing modes. It also keeps the file neat with "declarations" of sort
	//at the top
	.encoding "screencode_upper"
	testString:
		S65_Text16("1")
		S65_Text16("1")
		S65_Text16(" ")
		S65_Text16("L")
		S65_Text16("A")
		S65_Text16("Y")
		S65_Text16("E")
		S65_Text16("R")
		S65_Text16("S")
		S65_Text16("!")
	ticker:
		.byte $00
	sinus:
		.fill 256 + MAX_LAYERS * 2, sin([i/256] * PI * 2) * $50 + $a0

	textColor1:
		.byte $00
	textColorRamp:
		.byte $01,$0d,$03,$0c,$04,$02,$09,$00
		.byte $00,$0b,$02,$04,$0e,$03,$0d,$01



Start:
	// Define the engine layering parameters first
	Layer_DefineBGLayer #40 : #25			//Background 40x25 add as ScreenLayer 0
	.for(var i=0; i<MAX_LAYERS; i++) {
		Layer_DefineScreenLayer #10				//Add 10 wide layer
	}
	
	
	Layer_InitScreen #SCREEN_RAM 				//Initialize the view and all the layers in memory
	Layer_ClearAllLayers #$0020 				//Clear all the layers


	//Draw text to each layer 1 char per layer and space out the layers
	//VERY WASTEFUL TO CALL THIS 250 TIMES!!!!
	.for(var i=0; i<MAX_LAYERS; i++) {
		.for(var j=0; j<25; j++) {
			Layer_AddText Layer_GetScreenAddress(Layers + i, [floor(sin(j/25 * PI * 2) * 5) + 5], j) : testString + i * 4 : [textColorRamp + mod(j + i,$10)]
		}
	}


	ldz #$00
!loop:
	System_WaitForRaster($0ff)
	System_BorderDebug(1)
		tza  
		tax
 		.for(var i=0; i<MAX_LAYERS; i++) {
 			lda sinus + i, x
 			sta Layer_GetIOAddress(Layers + i, Layer_IOGotoX + 0)
 			inx
 			inx
 		}
 		inz

		// Layer_AddText Layer_GetScreenAddress(Layers10,9,22) : testString2 : textColorRamp,x
		// inx 
		// txa 
		// and #$0f
		// tax

		//Update all the GOTOX markers for the non rrb sprite layers
	!end:
		Layer_UpdateLayerOffsets 

	System_BorderDebug(0)
	jmp !loop-






S65_MemoryReport()
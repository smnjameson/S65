* = $e000




#import "includes/s65/s65.s"
	.const SCREEN_RAM = $8000

	.const NUM_LAYERS = 12
	.const LayerBG = 0
	.const Layers = 1
	.const LayerMessage = Layers + NUM_LAYERS

.print ("Boot: $" + toHexString(Boot))
	Boot:
		jmp Start 


	//Better to keep data before the code as it may not be parsable for some commands
	//using evaluated addressing modes. It also keeps the file neat with "declarations" of sort
	//at the top. You can also put data in hard coded places using the kick asm program counter directive * = $c000
	.encoding "screencode_upper"
	messageString:
		S65_Text16("FCM MULTI LAYER TEST")
	testString:
		.for(var i=0; i<NUM_LAYERS; i++) {
			S65_Text16(toIntString([i+1],2)) //each string will be 6 bytes
		}

	ticker:
		.byte $00
	sinus:
		.fill 256 + NUM_LAYERS * 2, sin([i/256] * PI * 2) * $7f + $80

	textColor1:
		.byte $00
	textColorRamp:
		.byte $01,$0d,$03,$0c,$04,$02,$09,$00
		.byte $00,$0b,$02,$04,$0e,$03,$0d,$01



.print ("Start: $" + toHexString(Start))
	Start:
		// Define the engine layering parameters first

		//Background 40x25 add as ScreenLayer 0
		Layer_DefineBGLayer #40 : #25 :	#0 : #FALSE

		//Add moving layers		
		.for(var i=0; i<NUM_LAYERS; i++) {
			Layer_DefineScreenLayer #3				//Add small 3 char wide layer
		}

		//Message layer
		Layer_DefineScreenLayer #20 : #[[320 - 20 * 8]/2]	//Centered text offset


		//Initialize the view and all the layers in memory
		Layer_InitScreen #SCREEN_RAM 				
		Layer_ClearAllLayers #$004f 				

		//Draw message
		.var msgAddr = Layer_GetScreenAddress(LayerMessage, 0, 24)
		Layer_AddText msgAddr : messageString : #$01

		//Draw text to each layer
		//VERY WASTEFUL TO CALL THISALOT!!!!
		.for(var y=0; y<NUM_LAYERS; y++) {
			.var addr = Layer_GetScreenAddress(Layers + y, 0, y)
			Layer_AddText  addr : [testString + y * 6] : [textColorRamp + mod(y,$10)]
		}


	ldz #$00
!loop:
	System_WaitForRaster($0ff)
	System_BorderDebug(1)
		tza  
		tax
 		.for(var i=0; i<NUM_LAYERS; i++) {
 			lda sinus + i, x
 			sta Layer_GetIOAddress(Layers + i, Layer_IOGotoX + 0)
 			inx
 			inx
 		}
 		inz

		//Update all the GOTOX markers for the non rrb sprite layers
	!end:
		Layer_UpdateLayerOffsets 

	System_BorderDebug(0)
	jmp !loop-



.print ("End: $" + toHexString(End))
End:



S65_MemoryReport()
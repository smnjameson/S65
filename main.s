// #define NODEBUG
#import "includes/s65/s65.s"
	Start:

		// Define and initialize the engine layering parameters first
		.var width = 40
		.var height = 32

		Layer_DefineResolution(width, height, true)	//Resolution/stretch

		Layer_DefineScreenLayer(126, 0, false)  		//layer 0
		Layer_DefineScreenLayer(74, 0, false)  		//layer 0
		Layer_DefineScreenLayer(49, 0, false)  		//layer 0

		Layer_DefineScreenLayer(1, 80, true)			//layer 1

		Layer_InitScreen($8000)							//Initialize

		lda #$02
		sta $d020

		Layer_ClearAllLayers #$0000 				

		//Layer_GetIOAddress(1, Layer_IOGotoX)
		ldx #0
	!loop:
		// Layer_AddText #0 : #0 : #REGX : message : #0
		Layer_AddText #3 : #0 : #REGX : message : #0
		inx
		cpx #height
		lbne !loop-


!loop:
	System_WaitForRaster($100)
	// System_BorderDebug(1)

		Layer_UpdateLayerOffsets 

	System_BorderDebug(0)
	jmp !loop-

message:
	.encoding "screencode_upper"
	.for(var i=0; i< 1; i++) {
		.byte $00,$01
	}
	.byte $ff,$ff
	// S65_Text16("123456789-123456789-123456789-123456789-123456789-")

   
S65_MemoryReport()


*=$4000
	.byte $22,$55,$55,$55,$55,$55,$55,$22
	.byte $22,$00,$00,$00,$00,$00,$00,$22
	.byte $05,$00,$00,$00,$00,$00,$00,$50
	.byte $05,$00,$00,$00,$00,$00,$00,$50
	.byte $05,$00,$00,$00,$00,$00,$00,$50
	.byte $05,$00,$00,$00,$00,$00,$00,$50
	.byte $22,$00,$00,$00,$00,$00,$00,$22
	.byte $22,$55,$55,$55,$55,$55,$55,$22

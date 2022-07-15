#import "includes/s65/s65.s"


	.const SCREEN_RAM = $8000

	.const LayerBG = 0
	.const LayerSprites = 1
	.const LayerUI = 2

	// Define the engine layering parameters first
	Layer_DefineBGLayer #40 : #25 : #0			//Background 40x25 add as ScreenLayer 0 at offsetX 0
	Layer_DefineRRBSpriteLayer #128 : #20 		//128 Sprite layer (20/line) add as ScreenLayer 1
	Layer_DefineScreenLayer #10 : #0			//UI 10 wide add as ScreenLayer 2 at offsetX 0
	
	Layer_InitScreen #SCREEN_RAM 				//Initialize the view and all the layers in memory

	Layer_ClearAllLayers #$002e 				//Clear all the layers with the char index found in the x-register


	//Add some text on BG - no color
	Layer_AddText Layer_GetScreenAddress(LayerBG,9,12) : testString1

	ldx #$00
loop:
 	lda #$ff
 	cmp $d012 
 	bne loop
 	inc $d020

 		//Shift the UI layer GOTOX continuously
		inc Layer_GetIOAddress(LayerUI, Layer_IOGotoX + 0)
		bne !+
		inc Layer_GetIOAddress(LayerUI, Layer_IOGotoX + 1)
	!:


		//Draw UI text in increasing colors - REGISTER mode
		inc textColor1
		ldz textColor1
		Layer_AddText Layer_GetScreenAddress(LayerUI,0,0) : testString2 : REGZ

		//Draw BG text using a color ramp  - AT_ABSOLUTEX mode
		Layer_AddText Layer_GetScreenAddress(LayerBG,9,22) : testString3 : textColorRamp,x
		inx 
		txa 
		and #$0f
		tax

		//Animate jsut color on original text
		Layer_AddColor Layer_GetColorAddress(LayerBG,9,12) : REGZ : #22


		//Update all the GOTOX markers for the non rrb sprite layers
		Layer_UpdateLayerOffsets 					


	dec $d020
	jmp loop



.encoding "screencode_upper"
testString1:
	S65_Text16(" THIS IS THE BG LAYER ")
testString2:
	S65_Text16("10 WIDE UI")
testString3:
	S65_Text16(" THIS IS A COLOR RAMP ")	

textColor1:
	.byte $00
textColorRamp:
	.byte $01,$0d,$03,$0c,$04,$02,$09,$00
	.byte $00,$0b,$02,$04,$0e,$03,$0d,$01


S65_MemoryReport()
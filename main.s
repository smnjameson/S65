#import "includes/s65/s65.s"

	.const SCREEN_RAM = $0800


	//////////////////////////////////////////////////////////////////////
	//	Define the engine layering and parameters first
	//
	// (NB: chars per line in S65_DefineRRBSpriteLayer refers to the 
	// 		maximum number of 16 bit char indices reserved per line for 
	// 		single 16x8 sprites thats 2 chars per sprite; 1 gotox marker 
	// 		and 1 index)
	/////////////////////////////////////////////////////////////////////

	//charWidth, charHeight
	Layer_DefineBGLayer(40, 25, 0) 	//Background add as ScreenLayer 0

	// //maxSprites, charsPerLine
	// Layer_DefineRRBSpriteLayer(256, 80)		//Sprites add as ScreenLayer 1

	// //charWidth, offsetX
	Layer_DefineScreenLayer(10, 19)				//UI add as ScreenLayer 2 at offset x=240 


	//////////////////////////////////////////////////////////////////// 
	// Then call init screen passing the start adress of screen ram
	// 
	// This will initialise all the layers in memory
	////////////////////////////////////////////////////////////////////
	//address
	Layer_InitScreen(SCREEN_RAM)

	Layer_ClearAllLayers($0000)



 loop:
 	lda #$ff
 	cmp $d012 
 	bne loop
 	inc $d020
	
		Layer_SetAllMarkers() 

	dec $d020
	jmp loop




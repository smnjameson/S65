//Comment this next line out to get memory report and border debug colors
#define NODEBUG				

//Start the S65 library by importing includes/s65/start.s
#import "includes/s65/start.s"
	jmp Start 

		//Import to $18000 thereby forcing the SDcard preloader, Make sure to deploy assets firs twith SHIFT+F8
		Asset_ImportCharset("map", "tests/assets/bin/test7/tileset2", $8000)
		.const MapChars = Asset_GetCharset("map")


		//Safest to define all the data before your code to avoid assembler pass errors
		palette:
			Asset_ImportCharsetPalette("map")
		message:
			//Generate a text string of 16bit indices
			S65_Text16("hello world!")				
		testScreenChars:
			.fill 10 * 8, [<[MapChars.indices.get(0) + i], >[MapChars.indices.get(0)+ i]]
		


	Start:
		.const BRICK = MapChars.indices.get(6)

		//Resolution 42x30 chars with scaling
		Layer_DefineResolution(40, 25, false)		

		//define a layer 21 chars wide at X position 0 using NCM
		.const LYR_BG= Layer_GetLayerCount()
		Layer_DefineScreenLayer(21, 0, true) 

		//define a layer 42 chars wide at X position 0 using FCM
		.const LYR_LV = Layer_GetLayerCount()
		Layer_DefineScreenLayer(42, 0, false) 

		//Initialize layers with screen ram at $4000	
		Layer_InitScreen($10000)						

		//Black border
		lda #$ff									
		sta $d020


		//Set the active layer
		Layer_Get #LYR_BG							
		Layer_ClearLayer #BRICK : #$30				
		Layer_Get #LYR_LV						
		Layer_ClearLayer #$0020 : #$01				


		//set the palette
		Palette_Assign #$01: #$01 : #$01
		Palette_Set #$01
		Palette_LoadFromMem palette : #$100	


		//Now draw the char set
		//Charset FCM
		Layer_Get #LYR_BG
		Layer_SetScreenPointersXY #0: #3 		
		ldy #$00 //Source offset
		ldx #$00 
	!rowloop:	
			Layer_WriteToScreen testScreenChars,y  : MapChars.colorAddress,y : #10
			Layer_AdvanceScreenPointers 
		inx 
		cpx #$08 //How many rows to draw
		bne !rowloop-


		//Draw a message to screen at 15,10 in color $04
		Layer_Get #LYR_LV
		Layer_AddText #15 : #15 : message : #$05 	

		//Call a layer update to set all the layer data
		Layer_Update 								

		//loop forever
		jmp *			
		
//Include this at the end of your code to see a detailed report of the memory consumed
S65_MemoryReport()		



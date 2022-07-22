//Comment this next line out to get memory report and border debug colors
#define NODEBUG				
//Start the S65 library by importing includes/s65/start.s
#import "includes/s65/start.s"
	jmp Start 

		//Safest to define all the data before your code to avoid assembler pass errors
		message:
			//Generate a text string of 16bit indices
			S65_Text16("hello world!")				

	Start:
		//Resolution 42x30 chars with scaling
		Layer_DefineResolution(42, 30, true)		

		//stores the current layer count (0)
		.const BGLayer = Layer_GetLayerCount()		
		//define a layer 42 chars wide at X position 0 using FCM
		Layer_DefineScreenLayer(42, 0, false) 	
		//Initialize layers with screen ram at $4000	
		Layer_InitScreen($4000)						

		//Black border
		lda #$00									
		sta $d020

		//Set the active layer
		Layer_Get #BGLayer	
		//Clear the layer with char $20 in color #$01						
		Layer_ClearLayer #$0020 : #$01				

		//Draw a message to screen at 15,10 in color $04
		Layer_AddText #15 : #10 : message : #$04 	

		//Call a layer update to set all the layer data
		Layer_Update 								

		//loop forever
		jmp *			
		
//Include this at the end of your code to see a detailed report of the memory consumed
S65_MemoryReport()		



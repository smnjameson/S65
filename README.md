# S65
S65 kick assembler macro toolkit for MEGA65

## Overview

S65 is a Kick Assembler development library for the MEGA65 that provides a simple API into the Raster Rewrite system 
as well as other useful functionality without the need to create the complex backbone of things like layers and software
sprites.

## Installation

Once you have met the prerequisites below you can install the toolkit by running install.bat from the root of the S65 folder

## Prerequisites

#### NodeJS (required)
  The image parsing, document generation and debugger deploy script makses extensive use of NodeJS. You can install it from:
  
  [https://nodejs.org](https://nodejs.org)
  
#### Java (required)
  Kick Assembler uses Java, so you will need that installed:
  [https://www.oracle.com/java/technologies/downloads/](https://www.oracle.com/java/technologies/downloads/)
  
#### Sublime Text
  All of the syntax files and autocomplete functionality is currently for Sublime Text only. You can use other IDEs but you 
  will lack all the syntax highlighting and autocomplete hints. You can install it from:
  
  [https://www.sublimetext.com/download](https://www.sublimetext.com/download)
  
  Keep the install to default locations to ensure the build scripting functions correctly. 
  
  You will also require the KickAssembler plugin for sublim, which is installed as follows:
  - Using package control: Install Package Control for Sublime and install package Kick Assembler (C64)
  
#### M65 Debugger
  If you want to use the deploy method in the make.bat file to send your program to a real MEGA65 or a NExys board you will
  need the M65Debugger from [here](https://files.mega65.org?id=042e934f-c6e7-480f-8caa-4176be5ee784). The connection script 
  to launch the programs through the debugger is included by default in the S65 package
  
#### OS
  While the library itself can be used on operating systems other than Windows, you will at this time have to make your own
  build file (make.bat) for your OS. Likewise you may run into other issues such as needing to manually install the Sublime Text
  S65 files. (see below)
  
## Usage
  The S65 toolkit comes as a setup project ready for you to use. The main.s file in the root of the project is the entry point
  and you can replace the code in there with your own.
  The example code is a very basic Hello World application:
  
  ```swift
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
  ```
  



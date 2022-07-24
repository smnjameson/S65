/**
* .pseudocommand Get
*
* This method is a prerequisite for getting or setting any sprites IO registers
* it sets the "current active" sprite used by the Sprite Get and Set methods by storing the 
* pointer to that sprites IO area in 
* <a href="#S65_LastSpriteIOPointer">S65_LastSpriteIOPointer</a><br><br>
* Note: This method will also call <a href="#S65_SetBasePage">S65_SetBasePage</a> which 
* is required for the subsequent Sprite functions
* 
* @namespace Sprite
* @param {byte} {IMM} layerNum The layer to get sprite from, note if this is NOT an RRB layer writing to addresses pointed to by S65_LastSpriteIOPointer can cause crashes and corruption
* @param {byte} {IMM|REG|ABSXY} sprNum The sprite number to enable
* @registers B
* @flags nzc
*/
.pseudocommand Sprite_Get layerNum : sprNum {
	S65_AddToMemoryReport("Sprite_Get")
	.if(!_isImm(layerNum)) .error "Sprite_Get:"+ S65_TypeError
	.if(!_isReg(sprNum) && !_isImm(sprNum) && !_isAbs(sprNum) && !_isAbsXY(sprNum)) .error "Sprite_Get:"+ S65_TypeError
	_saveIfReg(sprNum, S65_PseudoReg + 0)
	phx 
	phy
	pha
		S65_SetBasePage()
		.if(_isReg(sprNum)) {
			ldy layerNum
			ldx.z S65_PseudoReg + 0
			jsr _getSprIOoffsetForLayer
		} else {
			.if(_isImm(sprNum)) {
				ldy layerNum
				ldx #sprNum.getValue()
				jsr _getSprIOoffsetForLayer
			} else {	
				lda sprNum
				tax
				ldy layerNum
				jsr _getSprIOoffsetForLayer					
			}
		}
	pla
	ply
	plx
	S65_AddToMemoryReport("Sprite_Get")
}
_getSprIOoffsetForLayer: {	//Layer = y, Sprite = x
		lda #$00
		sta.z S65_LastSpriteIOPointer + 1
	
		txa 
		asl 
		rol.z S65_LastSpriteIOPointer + 1		
		asl 
		rol.z S65_LastSpriteIOPointer + 1
		asl 
		rol.z S65_LastSpriteIOPointer + 1		
		asl 
		rol.z S65_LastSpriteIOPointer + 1
		sta.z S65_LastSpriteIOPointer + 0

		clc
		adc (S65_SpriteIOAddrLSB), y
		sta.z S65_LastSpriteIOPointer + 0
		lda S65_LastSpriteIOPointer + 1
		adc (S65_SpriteIOAddrMSB), y
		sta.z S65_LastSpriteIOPointer + 1
	!exit:
		rts
}


/**
* .pseudocommand SetFlags
*
* Sets one or more of the currently selected sprites flags. You can use the <a href="#Sprite_IOflagEnabled">flag constants</a> provided by S65
* to abstract the values. The other flags are left untouched
* 
* @namespace Sprite
* @param {byte} {IMM|REG|ABS} flags Sprite flags
* @flags nz 
*/
.pseudocommand Sprite_SetFlags flags {
	S65_AddToMemoryReport("Sprite_SetFlags")
	.if(!_isReg(flags) && !_isImm(flags)) .error "Sprite_SetFlags:"+ S65_TypeError
	_saveIfReg(flags,	S65_PseudoReg + 1)	
	phy
	pha	
			.if(_isReg(flags)) {
				lda.z S65_PseudoReg + 1
			} else {
				lda #flags.getValue()
			}
			ldy #[Sprite_IOflags]
			ora (S65_LastSpriteIOPointer), y
			sta (S65_LastSpriteIOPointer), y
	pla
	ply
	S65_AddToMemoryReport("Sprite_SetFlags")	
}

/**
* .pseudocommand ResetFlags
*
* Resets one or more of the currently selected sprites flags. You can use the <a href="#Sprite_IOflagEnabled">flag constants</a> provided by S65
* to abstract the values. The other flags are left untouched
* 
* @namespace Sprite
* @param {byte} {IMM|REG|ABS} flags Sprite flags
* @flags nz 
*/
.pseudocommand Sprite_ResetFlags flags {
	S65_AddToMemoryReport("Sprite_ResetFlags")
	.if(!_isReg(flags) && !_isImm(flags)) .error "Sprite_SetFlags:"+ S65_TypeError
	_saveIfReg(flags,	S65_PseudoReg + 1)	
	phy
	pha	
			lda #$ff
			sec
			.if(_isReg(flags)) {
				sbc.z S65_PseudoReg + 1
			} else {
				sbc #flags.getValue()
			}
			ldy #[Sprite_IOflags]
			and (S65_LastSpriteIOPointer), y
			sta (S65_LastSpriteIOPointer), y
	pla
	ply
	S65_AddToMemoryReport("Sprite_ResetFlags")	
}

/**
* .pseudocommand GetFlags
*
* Returns the flags of the current selected sprite into
* <a href="#Global_ReturnValue">S65_ReturnValue</a>
* 
* @namespace Sprite
* @flags nz
* @returns {bool} S65_ReturnValue value of the flags
*/
.pseudocommand Sprite_GetFlags {
	S65_AddToMemoryReport("Sprite_GetFlags")
	phy
	pha
			ldy #[Sprite_IOflags]
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 0
	pla
	ply
	S65_AddToMemoryReport("Sprite_GetFlags")	
}


/**
* .pseudocommand SetEnabled
*
* Enables or disables the current selected sprite so that it is rendered in a 
* <a href="#Layer_Update">Layer_Update</a><br>
* Sets <a href="#Global_LastSpriteIOPointer">S65_LastSpriteIOPointer</a><br><br>
* 
* @namespace Sprite
* @param {bool} {IMM|REG} enabled Sprite enabled flag in the sprites IO
* @flags nz
*/
.pseudocommand Sprite_SetEnabled enabled {
	S65_AddToMemoryReport("Sprite_SetEnabled")
	.if(!_isReg(enabled) && !_isImm(enabled)) .error "Sprite_SetEnabled:"+ S65_TypeError
	phy
	pha
		.if(_isReg(enabled)) {
			_saveIfReg(enabled,	Reg)
			ldy #Sprite_IOflags 
			lda Reg:#$BEEF

			sta (S65_LastSpriteIOPointer), y
		} else {
			.if(enabled.getValue() == 0) {
				ldy #Sprite_IOflags 
				lda (S65_LastSpriteIOPointer), y	
				and #%11011111
				sta (S65_LastSpriteIOPointer), y
			} else {
				ldy #Sprite_IOflags 
				lda (S65_LastSpriteIOPointer), y	
				ora #%00100000
				sta (S65_LastSpriteIOPointer), y				
			}
		}
	pla
	ply
	S65_AddToMemoryReport("Sprite_SetEnabled")	
}

/**
* .pseudocommand GetEnabled
*
* Returns the enabled state of the current selected sprite into
* <a href="#Global_ReturnValue">S65_ReturnValue</a>
* 
* @namespace Sprite
* @flags nz
* @returns {bool} S65_ReturnValue $20 if enabled $00 if not
*/
.pseudocommand Sprite_GetEnabled {
	S65_AddToMemoryReport("Sprite_GetEnabled")
	phy
	pha
			ldy #[Sprite_IOflags]
			lda (S65_LastSpriteIOPointer), y
			and #%00100000
			sta.z S65_ReturnValue + 0
	pla
	ply
	S65_AddToMemoryReport("Sprite_GetEnabled")	
}

/**
* .pseudocommand GetPositionY
*
* Returns the Y position of the current selected sprite into
* <a href="#Global_ReturnValue">S65_ReturnValue</a>
* 
* @namespace Sprite
* @flags nz
* @returns {word} S65_ReturnValue
*/
.pseudocommand Sprite_GetPositionY {
	S65_AddToMemoryReport("Sprite_GetPositionY")
	phy
	pha
			ldy #[Sprite_IOy + 1]
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 1
			dey
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 0
	pla
	ply
	S65_AddToMemoryReport("Sprite_GetPositionY")	
}

/**
* .pseudocommand GetPositionX
*
* Returns the X position of the current selected sprite into
* <a href="#Global_ReturnValue">S65_ReturnValue</a>
* 
* @namespace Sprite
* @flags nz
* @returns {word} S65_ReturnValue
*/
.pseudocommand Sprite_GetPositionX {
	S65_AddToMemoryReport("Sprite_GetPositionX")
	phy
	pha	
			ldy #[Sprite_IOx + 1]
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 1
			dey
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 0
	pla
	ply
	S65_AddToMemoryReport("Sprite_GetPositionX")	
}


/**
* .pseudocommand SetPositionX
*
* Sets the current selected sprite X position. If position is passed as a register it
* sets ONLY the LSB, MSB sets to 0. If ABS mode is used then two bytes are read from that address
* and used to set the value
* 
* @namespace Sprite
* @param {word} {IMM|REG|ABS} xpos The x position
* @flags nz
*/
.pseudocommand Sprite_SetPositionX xpos {
	S65_AddToMemoryReport("Sprite_SetPositionX")
	.if(!_isReg(xpos) && !_isImm(xpos) && !_isAbs(xpos)) .error "Sprite_SetPositionX:"+ S65_TypeError
	_saveIfReg(xpos,	S65_PseudoReg + 1)	
	phy
	pha	
		.if(_isReg(xpos)) {
			lda.z S65_PseudoReg + 1
		} else {
			.if(_isImm(xpos)) {
				lda #<xpos.getValue()
			} else {
				lda xpos.getValue()	+ 0	
			}
		}
		ldy #[Sprite_IOx + 0]
		sta (S65_LastSpriteIOPointer), y

		.if(_isReg(xpos)) {
			lda #$00
		} else {
			.if(_isImm(xpos)) {
				lda #>xpos.getValue()
			} else {
				lda xpos.getValue() + 1			
			}
		}
		iny
		sta (S65_LastSpriteIOPointer), y
	pla
	ply
	S65_AddToMemoryReport("Sprite_SetPositionX")	
}

/**
* .pseudocommand SetPositionY
*
* Sets the current selected sprite Y position. If position is passed as a register it
* sets ONLY the LSB, MSB sets to 0. If ABS mode is used then two bytes are read from that address
* and used to set the value
* 
* @namespace Sprite
* @param {word} {IMM|REG|ABS} ypos The y position
* @flags nz
*/
.pseudocommand Sprite_SetPositionY ypos {
	S65_AddToMemoryReport("Sprite_SetPositionY")
	.if(!_isReg(ypos) && !_isImm(ypos) && !_isAbs(ypos)) .error "Sprite_SetPositionY:"+ S65_TypeError
	_saveIfReg(ypos,	S65_PseudoReg + 1)	
	phy
	pha	
		.if(_isReg(ypos)) {
			lda.z S65_PseudoReg + 1
		} else {
			.if(_isImm(ypos)) {
				lda #<ypos.getValue()
			} else {
				lda ypos.getValue()	+ 0	
			}
		}
		ldy #[Sprite_IOy + 0]
		sta (S65_LastSpriteIOPointer), y

		.if(_isReg(ypos)) {
			lda #$00
		} else {
			.if(_isImm(ypos)) {
				lda #>ypos.getValue()
			} else {
				lda ypos.getValue() + 1			
			}
		}
		iny
		sta (S65_LastSpriteIOPointer), y
	pla
	ply
	S65_AddToMemoryReport("Sprite_SetPositionY")	
}


/**
* .pseudocommand SetPointer
*
* Sets the current selected sprite pointer. If pointer is passed as a register it
* sets ONLY the LSB, MSB sets to 0. If ABS mode is used then two bytes are read from that address
* and used to set the value
* 
* @namespace Sprite
* @param {word} {IMM|REG|ABS} pointer The sprite pointer to set
* @flags nz
*/
.pseudocommand Sprite_SetPointer pointer {
	S65_AddToMemoryReport("Sprite_SetPointer")
	.if(!_isReg(pointer) && !_isImm(pointer) && !_isAbs(pointer)) .error "Sprite_SetPointer:"+ S65_TypeError
	_saveIfReg(pointer,	S65_PseudoReg + 1)	
	phy
	pha	
		.if(_isReg(pointer)) {
			lda.z S65_PseudoReg + 1
		} else {
			.if(_isImm(pointer)) {
				lda #<pointer.getValue()
			} else {
				lda pointer.getValue()	+ 0	
			}
		}
		ldy #[Sprite_IOptr + 0]
		sta (S65_LastSpriteIOPointer), y

		.if(_isReg(pointer)) {
			lda #$00
		} else {
			.if(_isImm(pointer)) {
				lda #>pointer.getValue()
			} else {
				lda pointer.getValue() + 1			
			}
		}
		iny
		sta (S65_LastSpriteIOPointer), y
	pla
	ply
	S65_AddToMemoryReport("Sprite_SetPointer")		
}

/**
* .pseudocommand GetPointer
*
* Returns the current pointer of the currently selected sprite into
* <a href="#Global_ReturnValue">S65_ReturnValue</a>
* 
* @namespace Sprite
* @flags nz
* @returns {word} S65_ReturnValue
*/
.pseudocommand Sprite_GetPointer {
	S65_AddToMemoryReport("Sprite_GetPointer")
	phy
	pha	
			ldy #[Sprite_IOptr + 1]
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 1
			dey
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 0
	pla
	ply
	S65_AddToMemoryReport("Sprite_GetPointer")	
}


/**
* .pseudocommand SetDimensions
*
* Sets the currently selected sprites width and height. There is a hard limit of 255 chars
* to make up any one sprite therefore width * height MUST be less than 256
*
* @namespace Sprite
* @param {byte} {IMM|REG|ABS} width Sprite width in chars
* @param {byte} {IMM|REG|ABS} height Sprite height in chars
* @flags nz 
*/
.pseudocommand Sprite_SetDimensions width : height {
	S65_AddToMemoryReport("Sprite_SetDimensions")
	.if(!_isReg(width) && !_isImm(width) && !_isAbs(width)) .error "Sprite_SetDimensions:"+ S65_TypeError
	.if(!_isReg(height) && !_isImm(height) && !_isAbs(width)) .error "Sprite_SetDimensions:"+ S65_TypeError
	_saveIfReg(width,	S65_PseudoReg + 1)
	_saveIfReg(height,	S65_PseudoReg + 2)	
	phy
	pha	
			.if(_isReg(width)) {
				lda.z S65_PseudoReg + 1
			} else {
				.if(_isImm(width)) {
					lda #width.getValue()	
				} else {
					lda width
				}
				
			}
			ldy #[Sprite_IOwidth + 0]
			sta (S65_LastSpriteIOPointer), y

			//Store width -1 for the flipH ptr offset start value
			//offset = (width - 1) * (height + 1)
			sec 
			sbc #$01 
			sta $d770	//Multiply A0

			.if(_isReg(height)) {
				lda.z S65_PseudoReg + 2
			} else {
				.if(_isImm(height)) {
					lda #height.getValue()	
				} else {
					lda height
				}
			}

			ldy #[Sprite_IOheight + 0]
			sta (S65_LastSpriteIOPointer), y

			//Store height + 1 for the flipH ptr offset start value
			//offset = (width - 1) * (height + 1)
			//Carry will already be set here so jst adc #0 instead of clc + adc #1
			adc #$00 
			sta $d774	//Multiply B0
			lda $d778   //Math Result0
			ldy #[Sprite_IOflipHoffset]
			sta (S65_LastSpriteIOPointer), y

	pla
	ply
	S65_AddToMemoryReport("Sprite_SetDimensions")	
}

/**
* .pseudocommand GetDimensions
*
* Returns the dimensions of the currently selected sprite into
* <a href="#Global_ReturnValue">S65_ReturnValue</a><br>
* Lo byte is width, Hi byte is height
* 
* @namespace Sprite
* @flags nz 
* @returns {word} S65_ReturnValue
*/
.pseudocommand Sprite_GetDimensions {
	S65_AddToMemoryReport("Sprite_GetDimensions")
	phy
	pha	
			ldy #[Sprite_IOheight]
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 1
			ldy #[Sprite_IOwidth]
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 0
	pla
	ply
	S65_AddToMemoryReport("Sprite_GetDimensions")	
}


/**
* .pseudocommand SetColor
*
* Sets the currently selected sprites color. Note that colors are in the upper nybble in NCM mode,
* so palette slice $02 is represented as $20
* 
* @namespace Sprite
* @param {byte} {IMM|REG|ABS} color Sprites color
* @flags nz 
*/
.pseudocommand Sprite_SetColor color {
	S65_AddToMemoryReport("Sprite_SetColor")
	.if(!_isReg(color) && !_isImm(color)) .error "Sprite_SetColor:"+ S65_TypeError
	_saveIfReg(color,	S65_PseudoReg + 1)	
	phy
	pha	
			.if(_isReg(color)) {
				lda.z S65_PseudoReg + 1
			} else {
				lda #color.getValue()
			}
			ldy #[Sprite_IOcolor]
			sta (S65_LastSpriteIOPointer), y
	pla
	ply
	S65_AddToMemoryReport("Sprite_SetColor")	
}


/**
* .pseudocommand GetColor
*
* Returns the color of the currently selected sprite in 
* <a href="#Global_ReturnValue">S65_ReturnValue</a> and the accumulator
* Lo byte is color<br>
* Note that colors are in the upper nybble in NCM mode,
* so palette slice $02 is represented as $20
* 
* @namespace Sprite
* @flags nz
* @returns {word} S65_ReturnValue
*/
.pseudocommand Sprite_GetColor {
	S65_AddToMemoryReport("Sprite_GetColor")
	phy
	pha	
			ldy #[Sprite_IOcolor]
			lda (S65_LastSpriteIOPointer), y
			sta.z S65_ReturnValue + 0
	pla
	ply
	S65_AddToMemoryReport("Sprite_GetColor")	
}



/**
* .pseudocommand SetSpriteMeta
*
* Enables the currently selected sprite and popualtes its IO registers with the meta data for
* the given spriteset index. Affects:<br>
* - IOflags (Enabled, NCM)<br>
* - IOwidth<br>
* - IOheight<br>
* - IOptr<br>
* - IOcolor<br>
* 
* @namespace Sprite
*
* @param {byte} {IMM} spritesId The spriteset index retrieved from Sprite_GetSprites
* @param {byte} {IMM|REG|ABSXY} spriteNum The sprite index from the spriteset (ordered left to right, top to bottom)

* @flags nzc
*/
.pseudocommand Sprite_SetSpriteMeta spritesId : spriteNum {
	S65_AddToMemoryReport("Sprite_SetSprite")
	pha
	phy
		.if(spritesId.getValue() > S65_SPRITESET_LIMIT) .error "Sprite_SetSprite: spritesId must be between 0 and "+(S65_SPRITESET_LIMIT-1)
		.if(!_isImm(spritesId)) .error "Sprite_SetSprite: "+S65_TypeError
		.if(!_isImm(spriteNum) && !_isReg(spriteNum) && !_isAbs(spriteNum) && !_isAbsXY(spriteNum)) .error "Sprite_SetSprite: "+S65_TypeError

		_saveIfReg(spriteNum, S65_PseudoReg + 0)


		//We can use preloaded sprite meta data
		.if(spritesId.getValue() < Sprite_SpriteList.size() &&
			_isImm(spriteNum) && !_isReg(spriteNum)) {

					.var meta = Sprite_SpriteList.get(spritesId.getValue()).get("meta")
					.var numSprites = meta.get($02) + meta.get($03) * $100
					//FLAGS
					lda #[Sprite_IOflagEnabled | [meta.get($01)!=0 ? Sprite_IOflagNCM : 0]]

					ldy #[Sprite_IOflags]
					sta (S65_LastSpriteIOPointer), y

					//POINTER
					lda #meta.get($20 + numSprites * 0 + spriteNum.getValue())		
					ldy #[Sprite_IOptr]
					sta (S65_LastSpriteIOPointer), y
					lda #meta.get($20 + numSprites * 1 + spriteNum.getValue())	
					iny 
					sta (S65_LastSpriteIOPointer), y	

					//DIMENSIONS
					iny
					lda #meta.get($04)
					sta (S65_LastSpriteIOPointer), y
					iny
					lda #meta.get($05)
					sta (S65_LastSpriteIOPointer), y	

					//COLOR
					iny
					lda #meta.get($20 + numSprites * 2 + spriteNum.getValue())	
					sta (S65_LastSpriteIOPointer), y												
		} else {
					//We must instead use lookup tables for meta data
					.const SprMETA = S65_TempWord1
					.const NumSPRITE = S65_TempWord2

					lda [Sprite_SpritesetMetaTable + spritesId.getValue()* 2 + 0]
					sta.z SprMETA + 0 
					lda [Sprite_SpritesetMetaTable + spritesId.getValue()* 2 + 1]
					sta.z SprMETA + 1				
					
					.if(_isReg(spriteNum)) {
						lda S65_PseudoReg + 0
					}  else {
						lda spriteNum
					}
					jsr _Sprite_SetSpriteMeta.SetData
		}
	ply
	pla
	S65_AddToMemoryReport("Sprite_SetSprite")
}
_Sprite_SetSpriteMeta: {
.print ("S65_TempWord1: $" + toHexString(S65_TempWord1))
		.const SprMETA = S65_TempWord1
.print ("S65_TempWord2: $" + toHexString(S65_TempWord2))
		.const NumSPRITE = S65_TempWord2	

		SetData: {
					//Pass sprite index in A
					sta SpriteIndex
					//FLAGS
					ldy #$01
					lda (SprMETA), y //NCM mode?
					beq !+
					lda #[Sprite_IOflagNCM]
				!:
					ora #[Sprite_IOflagEnabled]
					ldy #[Sprite_IOflags]
					sta (S65_LastSpriteIOPointer), y


					//DIMENSIONS
					ldy #$04
					lda (SprMETA), y //width
					ldy #[Sprite_IOwidth]
					sta (S65_LastSpriteIOPointer), y

					ldy #$05
					lda (SprMETA), y //height
					ldy #[Sprite_IOheight]
					sta (S65_LastSpriteIOPointer), y	


					//POINTER
					ldy #$02
					lda (SprMETA), y //numsprLo
					sta.z NumSPRITE + 0 
					iny
					lda (SprMETA), y //numsprHi
					sta.z NumSPRITE + 1

					jsr _Sprite_SetSpriteMeta.AdvanceToTables

					ldy SpriteIndex:#$00
					lda (SprMETA), y //PtrLo
					ldy #[Sprite_IOptr + 0]
					sta (S65_LastSpriteIOPointer), y


					jsr _Sprite_SetSpriteMeta.AdvanceToNextTable

					ldy SpriteIndex
					lda (SprMETA), y //PtrHi
					ldy #[Sprite_IOptr + 1]
					sta (S65_LastSpriteIOPointer), y

					jsr _Sprite_SetSpriteMeta.AdvanceToNextTable

					//COLOR
					ldy SpriteIndex
					lda (SprMETA), y //PtrColor
					ldy #[Sprite_IOcolor]
					sta (S65_LastSpriteIOPointer), y
					rts			
		}

		AdvanceToTables: {
			clc 
			lda.z SprMETA + 0
			adc #[$20]
			sta.z SprMETA + 0
			lda.z SprMETA + 1
			adc #[$00]
			sta.z SprMETA + 1	
			rts
		}

		AdvanceToNextTable: {
			clc 
			lda.z SprMETA + 0
			adc.z NumSPRITE + 0 
			sta.z SprMETA + 0
			lda.z SprMETA + 1
			adc.z NumSPRITE + 1
			sta.z SprMETA + 1
			rts
		}
}












/**
* .pseudocommand Update
* 
* Called internally by <a href="#Layer_Update">Layer_Update</a><br>
* 
* @namespace Sprite
*/
.pseudocommand Sprite_Update ListSize {
		ldx #$00
	!layerloop:
		lda Layer_IsRRBSprite, x 
		lbeq !nextlayer+
		phx 
			//WE ARE IN AN RRB LAYER
			
			//clear the layer
				phx 
				txa 
				ldx #$a0
				ldy #$02
				jsr Layer_DMAClear
				pla 
				pha 		
				jsr Layer_DMAClearColorRRB	
				plx


			//Prep the base addresses 

			//get the Base address of the IO
			.const SprIO = S65_TempWord1
			.const LayerIO = S65_TempWord2
			// .const ScreenRowAddr = S65_TempWord3

			// Sprite IO base
			lda Layer_SpriteIOAddrLSB, x
			sta.z SprIO + 0
			lda Layer_SpriteIOAddrMSB, x
			sta.z SprIO + 1


			// Layer IO base ; TODO- Optimize
			txa 
			asl 
			tax 
			clc 
			adc #<Layer_DynamicDataTable
			sta.z S65_TempWord2 + 0
			lda #>Layer_DynamicDataTable
			adc #$00
			sta.z S65_TempWord2 + 1
			ldy #$00
			lda ((S65_TempWord2)), y 
			pha 
			iny 
			lda ((S65_TempWord2)), y 
			sta.z S65_TempWord2 + 1
			pla 
			sta.z S65_TempWord2 + 0


			//Clear the rowCharCountTable
			ldz #Layer_IOrowCountTableRRB //RowCountTable
			lda #$00//Reset to zero
		!: 
			sta (LayerIO), z
			inz 
			cpz #S65_VISIBLE_SCREEN_CHAR_HEIGHT + Layer_IOrowCountTableRRB
			bne !-

			// jmp *

			_Sprite_Update()
		plx	
	!nextlayer:
		inx 
		cpx #ListSize.getValue()
		lbne !layerloop-
}
MaskRowValue:
		.fill 8, 255 - pow(2, 8-i) 

//As much as I want this next bit to be a base library method, it has to stay a macro due to
//references to addresses not defined until AFTER Layer_InitScreen
.macro _Sprite_Update() {
		.const SprIO = S65_TempWord1
		.const LayerIO = S65_TempWord2

		ldy #Layer_IOmaxSpritesRRB //maxSprite offset
		lda (LayerIO), y 
		sta MaxSprites

		//cycle the sprites
		ldz #$00 //sprite
	!spriteloop:
			phz
			ldy #Sprite_IOflags 
			lda (SprIO), y
			and #%00100000

			//Skip if not enabled
			lbeq !nextsprite+

			//store flags to apply later
			lda (SprIO), y
			and #%11011111
			sta S65_SpriteFlags

				//Sprite is active so add an entry to the RRB

				//Figure out its screen row (ypos /8) and set screen/col pointers
				ldy #Sprite_IOy + 1

				lda (SprIO), y //MSB
				and #$03
				sta S65_TempByte1
				dey
				lda (SprIO), y //LSB
		pha 	//store so we can grab the 0-7 fine Y
				lsr S65_TempByte1
				ror 
				lsr S65_TempByte1
				ror 
				lsr S65_TempByte1
				ror 
				tay 

				jsr ResetScreenPointer


				//y is the row number store it (+3 = Layer_IOrowCountTableRRB to save adding later)
				tya 
				clc 
				adc #Layer_IOrowCountTableRRB
				sta.z S65_SpriteRowTablePtr


				//get and store base pointer
				ldy #Sprite_IOptr
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 0 //byte 0
				sta.z S65_SpritePointerOld + 0 //byte 0
				iny
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 1 //byte 1
				sta.z S65_SpritePointerOld + 1 //byte 1


			///////////////////
			//ROWs
			///////////////////
			ldy #Sprite_IOheight
			lda (SprIO), y
			sta.z S65_SpriteRowCounter

			!checkHFlip:
				//If we have H flipped we need to also set the pointer to a new right side offset
				bbr6 S65_SpriteFlags, !noHFlip+

					ldy #Sprite_IOflipHoffset
					clc 
					lda.z S65_SpritePointerTemp + 0
					adc (SprIO), y 
					sta.z S65_SpritePointerTemp + 0
					sta.z S65_SpritePointerOld + 0
					bcc !+
					inc.z S65_SpritePointerTemp + 1 //byte 0
					inc.z S65_SpritePointerOld + 1 //byte 0				
				!:
			!noHFlip:


				//retrieve the ypos lsb and use it to get the inverse 0-7 fine y
		pla 
				and #$07
				sta YscrollOffset
				sta S65_SpriteFineY

				beq !nextrow+
				eor #$07
				clc 
				adc #$01
				sta S65_SpriteFineY
				lsr 	//Have to move to bits 5-7
				ror 
				ror 
				ror 
				sta YscrollOffset
				beq !nextrow+

				//finey!=0 so We are spanning 1 extra row 
				inc S65_SpriteRowCounter
				//And that means we need to fetch 1 char back instead
				ldy #Sprite_IOwidth
				dew.z S65_SpritePointerTemp + 0 //byte 0
				dew.z S65_SpritePointerOld + 0 //byte 0






			!nextrow:
				//If this row is off screen then skip this row
				ldy S65_SpriteRowTablePtr
				cpy #[S65_VISIBLE_SCREEN_CHAR_HEIGHT + Layer_IOrowCountTableRRB]
				bcc !continue+
					clc 
					ldy #Sprite_IOwidth
					lda (SprIO), y	
					adc.z S65_SpritePointerOld + 0
					sta.z S65_SpritePointerTemp + 0
					lda.z S65_SpritePointerOld + 0
					adc #$00
					sta.z S65_SpritePointerTemp + 0
					inc.z S65_SpritePointerTemp + 0
					inc.z S65_SpritePointerOld + 0
				jmp !skiprow+
			!continue:

				//Where do we start? get offset from rowcount table into z
				//and double it to give the byte offset
				ldy #Sprite_IOwidth
				lda (SprIO), y 
				ldz S65_SpriteRowTablePtr //RowCountTable y position offset
				clc 
				adc (LayerIO), z

					//Skip if no room left in line buffer
					ldy #Layer_IOmaxCharsRRB
					cmp (LayerIO), y
					// jmp *
					lbcs !nextsprite+ 
				lda (LayerIO), z
				asl
				taz 

				//GOTOX Marker
				ldy #Sprite_IOx
				//in Screen ram
				lda (SprIO), y	
				sta ((S65_ScreenRamPointer)), z //scr byte 0
				//and color ram
				lda #$90 //transparent and gotox
				sta ((S65_ColorRamPointer)), z //col byte 0				
				iny //$02
				inz
				lda (SprIO), y
				and #$03
				ora YscrollOffset:#$BEEF	
				sta ((S65_ScreenRamPointer)), z //scr byte 1
				lda #$f0 //transparent gotox and alt palette
				sta ((S65_ColorRamPointer)), z //col byte 0						
				inz 



				/////////////////////////
				//COLUMNS
				/////////////////////////
				//Loop through the width of the char
						phx 
						ldy #Sprite_IOwidth
						lda (SprIO), y	
						sta WidthIncrement
						tax

						!charwidthLoop:
							//CHAR RAM 
							lda.z S65_SpritePointerTemp + 0
							sta ((S65_ScreenRamPointer)), z //scr byte 0
							lda S65_SpriteFlags
							sta ((S65_ColorRamPointer)), z //col byte 0

							inz
							lda.z S65_SpritePointerTemp + 1	
							sta ((S65_ScreenRamPointer)), z //scr byte 1

							// inz
							// COLOR RAM 
							ldy #Sprite_IOcolor
							lda (SprIO), y	
							sta ((S65_ColorRamPointer)), z //col byte 1
							inz
								

							//increment pointer to next column
							ldy #Sprite_IOwidth
							lda (SprIO), y
							cmp #$01
							beq !columnadvDone+


								//deal with hflip flag
								bbr6 S65_SpriteFlags, !noHflip+

							!yesHFlip:
								//Subtract height + 1 (+1 comes from the CLC being clear) 
								//from Sprite pointer counter							
								ldy #Sprite_IOheight						
								clc
								lda.z S65_SpritePointerTemp + 0	
								sbc (SprIO), y
								sta.z S65_SpritePointerTemp + 0
								bcs !+
								dec.z S65_SpritePointerTemp + 1
							!:
								bra !columnadvDone+

							!noHflip:
								//Add height + 1 (+1 comes from the SEC being set) 
								//to Sprite pointer counter
								ldy #Sprite_IOheight
								lda (SprIO), y							
								sec
								adc.z S65_SpritePointerTemp + 0	
								sta.z S65_SpritePointerTemp + 0
								bcc !+
								inc.z S65_SpritePointerTemp + 1
							!:

						!columnadvDone:
							dex 
							bne !charwidthLoop-		



							//set pointer to next row
							inw.z S65_SpritePointerOld
							lda.z S65_SpritePointerOld + 0		
							sta.z S65_SpritePointerTemp + 0
							lda.z S65_SpritePointerOld + 1		
							sta.z S65_SpritePointerTemp + 1
						!rowadvDone:

						plx

				//increment row count table entry by width + 1
				ldz S65_SpriteRowTablePtr //RowCountTable 

				lda (LayerIO), z
				clc 
				adc WidthIncrement:#$00
				adc #$01
				sta (LayerIO), z
				
		!skiprow:
			dec.z S65_SpriteRowCounter
			beq !nextsprite+		//Sprite is complete
			//Increment for next row
			clc 
			lda S65_ScreenRamPointer + 0
			adc #<S65_SCREEN_LOGICAL_ROW_WIDTH
			sta S65_ScreenRamPointer + 0
			sta S65_ColorRamPointer + 0
			php
			lda S65_ScreenRamPointer + 1
			adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
			sta S65_ScreenRamPointer + 1
			plp
			lda S65_ColorRamPointer + 1
			adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
			sta S65_ColorRamPointer + 1	

			inc S65_SpriteRowTablePtr	
			ldy S65_SpriteRowTablePtr
			


			cpy #[$80 + Layer_IOrowCountTableRRB]
			bne !noreset+
			//We are at the last row so reset screen pointers

			
			ldy #$00

			jsr ResetScreenPointer
			ldy #Layer_IOrowCountTableRRB
			sty S65_SpriteRowTablePtr

			// jmp *
		!noreset:	
			jmp !nextrow-

					
	!nextsprite:
		//increment sprite IO pointer
		clc 
		lda.z SprIO + 0
		adc #Sprite_SpriteIOLength
		sta.z SprIO + 0
		bcc !+
		inc.z SprIO + 1
	!: 	


		plz
		inz 
		cpz MaxSprites:#$BEEF
		lbne !spriteloop-
		///////////////////
		jmp End 


	ResetScreenPointer:
		clc
		lda Layer_RowAddressBaseLSB, y
		adc Layer_AddrOffsets + 0, x 
		sta.z S65_ScreenRamPointer + 0
		sta.z S65_ColorRamPointer + 0

		lda Layer_RowAddressBaseMSB, y
		adc Layer_AddrOffsets + 1, x 
		sta.z S65_ScreenRamPointer + 1	
		clc 
		adc #>[S65_COLOR_RAM - S65_SCREEN_RAM]						
		sta.z S65_ColorRamPointer+ 1
		rts
	End:
}
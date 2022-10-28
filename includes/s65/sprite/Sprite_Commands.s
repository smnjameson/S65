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
			_saveIfReg(enabled,	S65_PseudoReg+ 0)
 
			ldy #Sprite_IOflags
			lda S65_PseudoReg + 0
			beq !+

				lda (S65_LastSpriteIOPointer), y	
				ora #%00100000
				sta (S65_LastSpriteIOPointer), y
				bra !done+
			!:
				lda (S65_LastSpriteIOPointer), y	
				and #%11011111
				sta (S65_LastSpriteIOPointer), y
			!done:
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
* .pseudocommand SetAnim
*
* Sets the sprites animation id and resets its timer and frame counter.
* A value of 0 turns off the animation
* and returns control of the sprites pointer to Sprite_IOptr.
* 
* @namespace Sprite
*
* @param {byte} {IMM|REG|ABS|ABSX} animId The id of the animation to assign
* @param {byte?} {IMM|REG|ABS|ABSX} speed The speed of the animation, lower=faster, minimum 1 defaults to 4
*
* @flags nz
*/
.pseudocommand Sprite_SetAnim animId : speed {
	S65_AddToMemoryReport("Sprite_SetAnim")
	.if(!_isImm(animId) && !_isReg(animId) && !_isAbs(animId) && !_isAbsX(animId)) .error "Sprite_SetAnim:"+ S65_TypeError	
	.if(!_isImm(speed)&& !_isReg(animId) && !_isAbs(animId) && !_isAbsX(animId) &&!_isNone(speed)) .error "Sprite_SetAnim:"+ S65_TypeError	
	.if(_isImm(speed) && speed.getValue()<1) .error "Sprite_SetAnim: speed should be minimum 1"

	_saveIfReg(animId, S65_PseudoReg + 0)
	_saveIfReg(speed, S65_PseudoReg + 1)
	phy
	pha	

			.if(_isReg(animId)) {
				lda.z S65_PseudoReg + 0
			} else {
				lda animId
			}
			ldy #[Sprite_IOanim]
			cmp (S65_LastSpriteIOPointer), y				
			beq !exit+
			sta (S65_LastSpriteIOPointer), y
				//reset the one shot flag if this is new anim	
				ldy #[Sprite_IOflags]			
				lda (S65_LastSpriteIOPointer), y	
				and #[255 - Sprite_IOflagOneShot]
				sta (S65_LastSpriteIOPointer), y	
			ldy #[Sprite_IOanim]
		!:
			lda #$00
			iny	//timer
			sta (S65_LastSpriteIOPointer), y
			iny //frame
			sta (S65_LastSpriteIOPointer), y



//Apply color of first frame to anim
//TODO - Fix for other addressing modes
.if(_isImm(animId)) {	
	.var firstFrame = Anim_SeqList.get(animId.getValue()).startFrame
	.var meta = Anim_SeqList.get(animId.getValue()).spriteSet.get("meta")
	.var numSprites = meta.get($02) + meta.get($03) * 256
	lda #meta.get($20 + numSprites * 2 + firstFrame)		
	ldy #[Sprite_IOcolor]
	sta (S65_LastSpriteIOPointer), y	
} else {
	
}



			.if(_isReg(speed)) {
				lda.z S65_PseudoReg + 1
			} else {
				.if(_isNone(speed)) {
					lda #$04
				} else {
					lda speed
				}
			}		
			ldy #[Sprite_IOanimSpeed] //speed
			sta (S65_LastSpriteIOPointer), y	
		!exit:		
	pla
	ply
	S65_AddToMemoryReport("Sprite_SetAnim")	
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
* @param {byte} {IMM|REG} spritesId The spriteset index retrieved from Sprite_GetSprites
* @param {byte?} {IMM|REG|ABSXY} spriteNum The sprite index from the spriteset (ordered left to right, top to bottom)

* @flags nzc
*/
.pseudocommand Sprite_SetSpriteMeta spritesId : spriteNum {
	S65_AddToMemoryReport("Sprite_SetSprite")
	pha
	phy
		.if(_isImm(spritesId) && spritesId.getValue() > S65_SPRITESET_LIMIT) .error "Sprite_SetSprite: spritesId must be between 0 and "+(S65_SPRITESET_LIMIT-1)
		.if(!_isImmOrReg(spritesId)) .error "Sprite_SetSprite: "+S65_TypeError
		.if(!_isNone(spriteNum) && !_isImm(spriteNum) && !_isReg(spriteNum) && !_isAbs(spriteNum) && !_isAbsXY(spriteNum)) .error "Sprite_SetSprite: "+S65_TypeError

		_saveIfReg(spriteNum, S65_PseudoReg + 0)
		_saveIfReg(spritesId, S65_PseudoReg + 1)


		//We can use preloaded sprite meta data
		.if(spritesId.getValue() < Asset_SpriteList.size() &&
			_isImm(spriteNum) && !_isReg(spriteNum) && !_isReg(spritesId)) {

					.var meta = Asset_SpriteList.get(spritesId.getValue()).get("meta")
					.var numSprites = meta.get($02) + meta.get($03) * $100
					.var isNcm = meta.get($01)!=0
					//FLAGS
					lda #[Sprite_IOflagEnabled | [isNcm ? Sprite_IOflagNCM : 0]]

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

					.if(isNcm && !_isNone(spriteNum)) {
					//COLOR only req for ncm
						iny
						lda #meta.get($20 + numSprites * 2 + spriteNum.getValue())	
						sta (S65_LastSpriteIOPointer), y
					} 
					// else {
					// 	iny
					// 	lda #$00
					// 	sta (S65_LastSpriteIOPointer), y
					// }											
		} else {
			// jsr MapSpriteMeta
					//We must instead use lookup tables for meta data
					.const SprMETA = S65_TempWord1
					.const NumSPRITE = S65_TempWord2
					.const SprLookup = S65_TempWord2

					.if(_isImm(spritesId)) {
						lda [Asset_SpriteListMetaTable + spritesId.getValue()* 2 + 0]
						sta.z SprMETA + 0 
						lda [Asset_SpriteListMetaTable + spritesId.getValue()* 2 + 1]
						sta.z SprMETA + 1		
					} else {
						lda S65_PseudoReg + 1 
						asl 
						pha
						clc 
						adc #<Asset_SpriteListMetaTable
						// lda [Asset_SpriteListMetaTable + spritesId.getValue()* 2 + 0]
						// sta.z SprMETA + 0 
						sta.z SprLookup + 0
						pla 
						adc #>Asset_SpriteListMetaTable
						// sta.z SprMETA + 1	
						sta.z SprLookup + 1

						ldy #$00
						lda (SprLookup), y 
						sta.z SprMETA + 0 
						iny
						lda (SprLookup), y 
						sta.z SprMETA + 1 
					}		
					
					.if(_isReg(spriteNum)) {
						lda S65_PseudoReg + 0
					}  else {
						.if(_isNone(spriteNum)) {
							lda #$00
						} else {
							lda spriteNum			
						}
					}
					jsr _Sprite_SetSpriteMeta.SetData
			// jsr UnmapSpriteMeta
					// jsr _Sprite_SetDimensions
		}
	ply
	pla
	S65_AddToMemoryReport("Sprite_SetSprite")
}
_Sprite_SetSpriteMeta: {
		.const SprMETA = S65_TempWord1
		.const NumSPRITE = S65_TempWord2	

		SetData: {
					//Pass sprite index in A
					sta SpriteIndex
					//FLAGS
					ldy #$01
					lda (SprMETA), y //NCM mode?
					pha
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

					pla //NCM mode?
					beq !+
					jsr _Sprite_SetSpriteMeta.AdvanceToNextTable
					//COLOR
					ldy SpriteIndex
					lda (SprMETA), y //PtrColor
					ldy #[Sprite_IOcolor]
					sta (S65_LastSpriteIOPointer), y
				!:
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

/*
MapSpriteMeta: {
		phx 
		phz 
			mapMemory($80fe000,$e000)
		plz
		plx 
		rts
}

UnmapSpriteMeta: {
		phx 
		phz 
			lda #$00
			tax 
			tay 
			taz 
			map 
			eom	
		plz
		plx 
		rts
}
*/


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
			.const AnimData = S65_TempWord3
			.const SprIOBase = S65_TempWord4
			.const SprIndices = S65_TempWord5

			// Sprite IO base
			lda Layer_SpriteIOAddrLSB, x
			sta.z SprIOBase + 0
			lda Layer_SpriteIOAddrMSB, x
			sta.z SprIOBase + 1
			lda Layer_SpriteSortListLSB, x
			sta.z SprIndices + 0
			lda Layer_SpriteSortListMSB, x
			sta.z SprIndices + 1

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
		.const AnimData = S65_TempWord3
		.const SprIOBase = S65_TempWord4
		.const SprIndices = S65_TempWord5

		ldy #Layer_IOmaxSpritesRRB //maxSprite offset
		lda (LayerIO), y 
		sta MaxSprites

		//cycle the sprites
		ldz #$00 //sprite
	!spriteloop:
			phz

			//Convert Z to new SPRIO using lookup table
			lda #$00 
			sta.z SprIO + 1
			lda (SprIndices), z 
			asl 
			rol.z SprIO + 1
			asl 
			rol.z SprIO + 1
			asl 
			rol.z SprIO + 1
			asl 
			rol.z SprIO + 1
			clc
			adc.z SprIOBase + 0
			sta.z SprIO + 0
			lda.z SprIO + 1
			adc.z SprIOBase + 1
			sta.z SprIO + 1





			ldy #Sprite_IOflags 
			lda (SprIO), y
			bit #%00100000

			//Skip if not enabled
			lbeq !nextsprite+

			// lda (SprIndices), z 
			lda (SprIndices), z 
			cmp #$ff 
			lbeq !nextsprite+

			//store flags to apply later
			// lda (SprIO), y
			ldy #Sprite_IOflags 
			lda (SprIO), y
			and #%11011111
			sta S65_SpriteFlags

						//Is the sprite on screen horizontal???					 
						ldy #Sprite_IOwidth 
						lda (SprIO), y //Width 
						sta SM_AddLow
						lda #$00
						asl SM_AddLow
						rol 
						asl SM_AddLow
						rol 
						asl SM_AddLow
						rol 
						asl SM_AddLow
						rol 
						sta SM_AddHigh


						ldy #Sprite_IOx +0
						clc
						lda (SprIO), y //x 	LSB					
						adc SM_AddLow:#$BEEF 
						sta SM_WidthX0
						iny
						lda (SprIO), y //x 	MSB				
						adc SM_AddHigh:#$BEEF 
						and #$03
						sta SM_WidthX1

						lda SM_WidthX0:#$BEEF
						sec 
						sbc #<[S65_ScreenPixelWidth]
						sta SM_Test0
						lda SM_WidthX1:#$BEEF
						and #$03
						sbc #>[S65_ScreenPixelWidth]
						lbmi !dosprite+
						sta SM_Test1 

						sec 
						lda SM_Test0:#$BEEF 
						sbc SM_AddLow
						lda SM_Test1:#$BEEF 
						sbc SM_AddHigh
						lbpl !nextsprite+
			!dosprite:
				//Sprite is active so add an entry to the RRB

				//Figure out its screen row (ypos /8) and set screen/col pointers
				ldy #Sprite_IOy + 1

				lda (SprIO), y //MSB
				and #$03
				sta S65_TempByte1
				dey
				lda (SprIO), y //LSB
				//store so we can grab the 0-7 fine Y
				sta YposLSB
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

				ldy #Sprite_IOanim
				lda (SprIO), y	
				beq !io+
			!anim:

//get and store base pointer from sprites animation
				sta SM_AnimID
				iny // Sprite_IOanimTimer
				iny // Sprite_IOanimFrame
				lda (SprIO), y	 
				sta SM_FrameID

	
				//get sequence Data pointer
				ldy SM_AnimID:#$BEEF //data index is supplied +1
				lda Anim_SequenceAddrTable - 1, y //LSB
				sta.z AnimData + 0
				lda Anim_SequenceAddrTable -1 + (Anim_SeqList.size()-1), y //MSB
				sta.z AnimData + 1

				ldy #Sprite_IOanimTimer
				lda (SprIO), y	
				bne !noNewFrame+

				//Speed
				ldy #Sprite_IOanimSpeed
				lda (SprIO), y
				ldy #Sprite_IOanimTimer
				sta (SprIO), y	
				bra !animdone+	

			!noNewFrame:
				sec 
				sbc #$01
				sta (SprIO), y
				bne !animdone+

				//speed not implemented yet
			!nextframe:
				//get frame
				ldy #Sprite_IOanimFrame
				lda (SprIO), y	
				clc 
				adc #$01
				ldy SM_AnimID
				cmp Anim_FrameCounts -1, y 
				
				bcc !noWrap+
				ldy #Sprite_IOflags 
				lda (SprIO), y	
				ora #Sprite_IOflagOneShot
				sta (SprIO), y	
				lda #$00
			!noWrap:
				ldy #Sprite_IOanimFrame
				sta (SprIO), y	
			
			!animdone:
			// System_WaitForRaster($100)
				//get frame ptr
				lda SM_FrameID:#$BEEF
				asl
				tay 
				lda (AnimData), y //ptrLo
				sta.z S65_SpritePointerTemp + 0 //byte 0
				sta.z S65_SpritePointerOld + 0 //byte 0		
				iny	
				lda (AnimData), y //ptrHi
				sta.z S65_SpritePointerTemp + 1 //byte 0
				sta.z S65_SpritePointerOld + 1 //byte 0	


				bra !ptrDone+
//get and store base pointer from standard Sprite_IOptr

			!io:
				ldy #Sprite_IOptr
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 0 //byte 0
				sta.z S65_SpritePointerOld + 0 //byte 0
				iny
				lda (SprIO), y	
				sta.z S65_SpritePointerTemp + 1 //byte 1
				sta.z S65_SpritePointerOld + 1 //byte 1
			!ptrDone:


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
		lda YposLSB:#$BEEF 
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

				//Store some stuff up front
				ldy #Sprite_IOcolor
				lda (SprIO), y	
				sta SpriteColor				

				ldy #Sprite_IOwidth
				lda (SprIO), y 
				sta WidthIncrement

				//Where do we start? get offset from rowcount table into z
				//and double it to give the byte offset			
				ldz S65_SpriteRowTablePtr //RowCountTable y position offset
				clc 
				adc (LayerIO), z

					//Skip if no room left in line buffer
					ldy #Layer_IOmaxCharsRRB
					cmp (LayerIO), y
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
				// phx 
				stx RestX
						ldx WidthIncrement
						!charwidthLoop:
							//CHAR RAM 
							lda.z S65_SpritePointerTemp + 0
							sta ((S65_ScreenRamPointer)), z //scr byte 0
							lda.z S65_SpriteFlags
							sta ((S65_ColorRamPointer)), z //col byte 0

							inz
							lda.z S65_SpritePointerTemp + 1	
							sta ((S65_ScreenRamPointer)), z //scr byte 1

							// COLOR RAM 
							lda SpriteColor:#$BEEF//(SprIO), y	
							sta ((S65_ColorRamPointer)), z //col byte 1
							inz
							

							//increment pointer to next column
							lda WidthIncrement:#$BEEF
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

				ldx RestX:#$BEEF

				//increment row count table entry by width + 1
				ldy.z S65_SpriteRowTablePtr //RowCountTable 

				lda (LayerIO), y
				clc 
				adc WidthIncrement
				adc #$01
				sta (LayerIO), y
				
		!skiprow:
			dec.z S65_SpriteRowCounter
			beq !nextsprite+		//Sprite is complete
			//Increment for next row
			clc 
			lda.z S65_ScreenRamPointer + 0
			adc #<S65_SCREEN_LOGICAL_ROW_WIDTH
			sta.z S65_ScreenRamPointer + 0
			sta.z S65_ColorRamPointer + 0
			php
			lda.z S65_ScreenRamPointer + 1
			adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
			sta.z S65_ScreenRamPointer + 1
			plp
			lda.z S65_ColorRamPointer + 1
			adc #>S65_SCREEN_LOGICAL_ROW_WIDTH
			sta.z S65_ColorRamPointer + 1	

			inc.z S65_SpriteRowTablePtr	
			ldy.z S65_SpriteRowTablePtr
			


			cpy #[$80 + Layer_IOrowCountTableRRB]
			bne !noreset+
			//We are at the last row so reset screen pointers

			
			ldy #$00

			jsr ResetScreenPointer
			ldy #Layer_IOrowCountTableRRB
			sty.z S65_SpriteRowTablePtr

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

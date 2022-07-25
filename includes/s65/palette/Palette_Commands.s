/**
* .pseudocommand Set
*
* Sets the currently active palette in IO memory.
* 
* @namespace Palette
* @flags nz
* @param {byte} {REG|IMM} paletteNum The MEGA palette number to map
*/
.pseudocommand Palette_Set paletteNum {
	S65_AddToMemoryReport("Palette_Set")
	_saveIfReg(paletteNum, SMpaletteNum)
	pha

		.if(!_isImmOrNone(paletteNum) && !_isReg(paletteNum)) .error "Palette_Set:"+ S65_TypeError

		lda #%11000000
		trb $d070

		lda SMpaletteNum:#paletteNum.getValue()
		lsr 
		ror 
		ror 

		tsb $d070
	pla
	S65_AddToMemoryReport("Palette_Set")
}


/**
* .pseudocommand Assign
*
* Assigns palettes to the MEGA65 palette banks.
* 
* @namespace Palette
*
* @param {byte?} {IMM} palleteChar The Palette for Character/Bitmap
* @param {byte?} {IMM} paletteHWSprite The Palette for HW Sprites
* @param {byte?} {IMM} paletteRRBSprite The Palette for RRB Sprites
* @flags nzc
*/
.pseudocommand Palette_Assign palleteChar : paletteHWSprite : paletteRRBSprite {
	S65_AddToMemoryReport("Palette_Assign")
	.const SMpaletteHWSprite = S65_PseudoReg + 0
	.const SMpaletteChar = S65_PseudoReg + 1
	.const SMpaletteRRBSprite = S65_PseudoReg + 2

	_saveIfRegOrNone(paletteHWSprite, SMpaletteHWSprite)
	_saveIfRegOrNone(palleteChar, SMpaletteChar)
	_saveIfRegOrNone(paletteRRBSprite, SMpaletteRRBSprite)

	.if(!_isImmOrNone(paletteHWSprite) && !_isReg(paletteHWSprite)) .error "Palette_Assign:"+ S65_TypeError
	.if(!_isImmOrNone(palleteChar) && !_isReg(palleteChar)) .error "Palette_Assign:"+ S65_TypeError
	.if(!_isImmOrNone(paletteRRBSprite) && !_isReg(paletteRRBSprite)) .error "Palette_Assign:"+ S65_TypeError
	pha
		lda #%00111111
		trb $d070

		lda #$00
		lda #[[palleteChar.getValue() & $03] << 4] + [[paletteHWSprite.getValue() & $03] << 2] + [[paletteRRBSprite.getValue() & $03]]
		tsb $d070
	pla
	S65_AddToMemoryReport("Palette_Assign")
}


/**
* .pseudocommand LoadFromMem
*
* Copys palette data from a given address into the currently active palette.
* 
* @namespace Palette
*
* @param {word} {ABS} addr The location of the source palette data in memory
* @param {byte?} {IMM} size The number of colors in the palette data, defaults to 256
* @flags nzc
*/
.pseudocommand Palette_LoadFromMem addr : size {
	S65_AddToMemoryReport("Palette_LoadFromMem")
	.if(!_isAbs(addr) || !_isImmOrNone(size)) .error "Palette_LoadFromMem:"+S65_TypeError
	pha 
	phx
		.var off = _isNone(size) ? 0 : size.getValue()
		ldx #$00
	!:
		lda addr.getValue(), x 
		sta $d100, x
		lda addr.getValue() + off, x 
		sta $d200, x
		lda addr.getValue() + off*2, x 
		sta $d300, x
		inx
		cpx #[_isNone(size) ? 0 : size.getValue()]
		bne !-
	plx 
	pla
	S65_AddToMemoryReport("Palette_LoadFromMem")
}


/**
* .pseudocommand LoadFromSD
*
* Loads a full 256 color palette from SD card into the currently active palette
* 
* @namespace Palette
*
* @param {word} {ABS} addr Pointer to the filename in CAPITALS and zero terminated
* @flags nzc
*/
.pseudocommand Palette_LoadFromSD addr {
	S65_AddToMemoryReport("Palette_LoadFromSD")
	.if(!_isAbs(addr) ) .error "Palette_LoadFromSD:"+S65_TypeError
	S65_SaveRegisters()
		SDCard_LoadToChipRam Palette_SDBuffer : addr
		jsr _CopyPaletteFromBuffer
	S65_RestoreRegisters()
	S65_AddToMemoryReport("Palette_LoadFromSD")
}

_CopyPaletteFromBuffer: {
		ldx #$00
	!:
		lda Palette_SDBuffer, x 
		sta $d100, x
		lda Palette_SDBuffer + $100, x 
		sta $d200, x
		lda Palette_SDBuffer + $200, x 
		sta $d300, x
		inx
		bne !-
		rts
}
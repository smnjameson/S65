/**
* .pseudocommand Map
*
* Maps a palette into IO memory
* 
* @namespace Palette
*
* @registers A
* @flags nz
* 
* @param {byte} {REG|IMM} paletteNum The MEGA palette number to map
*/
.pseudocommand Palette_Map paletteNum {
	S65_AddToMemoryReport("Palette_Map")
		_saveIfReg(paletteNum, SMpaletteNum)

		.if(!_isImmOrNone(paletteNum) && !_isReg(paletteNum)) .error "Palette_Map:"+ S65_TypeError

		lda #%11000000
		trb $d070

		lda SMpaletteNum:#paletteNum.getValue()
		lsr 
		ror 
		ror 

		tsb $d070
	S65_AddToMemoryReport("Palette_Map")
}


/**
* .pseudocommand SetPalettes
*
* Assigns palettes to the MEGA65 palette banks.
* 
* @namespace Palette
*
* @param {byte?} {IMM} palleteChar The VIC IV Character/Bitmap color palette
* @param {byte?} {IMM} paletteSprite The VIC IV Sprite color palette
* @param {byte?} {IMM} paletteAltChar The VIC IV Alternate Character/Bitmap color palette
*
* @registers A
* @flags nzc
*/
.pseudocommand Palette_SetPalettes palleteChar : paletteSprite : paletteAltChar {
	S65_AddToMemoryReport("Palette_SetPalettes")
		.const SMpaletteSprite = S65_PseudoReg + 0
		.const SMpaletteChar = S65_PseudoReg + 1
		.const SMpaletteAltChar = S65_PseudoReg + 2

		_saveIfRegOrNone(paletteSprite, SMpaletteSprite)
		_saveIfRegOrNone(palleteChar, SMpaletteChar)
		_saveIfRegOrNone(paletteAltChar, SMpaletteAltChar)

		.if(!_isImmOrNone(paletteSprite) && !_isReg(paletteSprite)) .error "paletteSprite:"+ S65_TypeError
		.if(!_isImmOrNone(palleteChar) && !_isReg(palleteChar)) .error "palleteChar:"+ S65_TypeError
		.if(!_isImmOrNone(paletteAltChar) && !_isReg(paletteAltChar)) .error "paletteAltChar:"+ S65_TypeError

		lda #%00111111
		trb $d070

		lda #$00
		lda #[[palleteChar.getValue() & $03] << 4] + [[paletteSprite.getValue() & $03] << 2] + [[paletteAltChar.getValue() & $03]]
		tsb $d070
	S65_AddToMemoryReport("Palette_SetPalettes")
}


/**
* .pseudocommand LoadFromMem
*
* Copys data from agiven address into one of the MEGA65 palettes.
* The palette will remain the active mapped palette at $d100
* 
* @namespace Palette
*
* @param {byte} {IMM} paletteNum The MEGA65 Palette number to load to
* @param {word} {ABS} addr The location of the source palette data in memory
* @param {byte?} {IMM} size The number of colors in the palette data, defaults to 256
*
* @registers AX
* @flags nzc
*/
.pseudocommand Palette_LoadFromMem paletteNum : addr : size {
	S65_AddToMemoryReport("Palette_LoadFromMem")
		.if(!_isImm(paletteNum) || !_isAbs(addr) || !_isImmOrNone(size)) .error "Palette_LoadFromMem:"+S65_TypeError
		
		lda #%11000000
		trb $d070	

		.var pn = [paletteNum.getValue() & $03]
		lda #[pn << 6]
		tsb $d070	

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
	S65_AddToMemoryReport("Palette_LoadFromMem")
}


/**
* .pseudocommand LoadFromSD
*
* Loads a full 256 color palette from SD card
* 
* @namespace Palette
*
* @param {byte} {IMM} paletteNum The MEGA65 Palette number to load to
* @param {word} {ABS} addr Pointer to the filename in CAPITALS and zero terminated
*
* @registers AX
* @flags nzc
*/
.pseudocommand Palette_LoadFromSD paletteNum : addr {
	S65_AddToMemoryReport("Palette_LoadFromMem")
		.if(!_isImm(paletteNum) || !_isAbs(addr) ) .error "Palette_LoadFromMem:"+S65_TypeError

		lda #%11000000
		trb $d070

		.var pn = [paletteNum.getValue() & $03]
		lda #[pn << 6]
		tsb $d070	

		SDCard_LoadToChipRam $d100 : addr

		ldx #$00
	!:
		lda addr.getValue(), x 
		sta $d100, x
		lda addr.getValue() + $100, x 
		sta $d200, x
		lda addr.getValue() + $200, x 
		sta $d300, x
		inx
		bne !-
	S65_AddToMemoryReport("Palette_LoadFromMem")
}
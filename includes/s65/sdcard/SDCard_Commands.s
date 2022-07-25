
/**
 * .pseudocommand LoadToChipRam
 * 
 * Loads a file from the SDCard into chip RAM
 * 
 * @namespace SDCard
 * @param {dword} {ABS} addr Pointer to the memory load location
 * @param {word} {ABS} filePtr Pointer to the filename (zero terminated) on the SDCard to load
 * @flags izc
 */
.pseudocommand SDCard_LoadToChipRam addr : filePtr {
	.if(!_isAbs(addr) && !_isReg(filePtr)) .error "SDCard_LoadToChipRam:"+ S65_TypeError
	S65_AddToMemoryReport("SDCard_LoadToChipRam")
	S65_SaveRegisters()

.print ("filePtr.getValue(): $" + toHexString(filePtr.getValue()))
		lda #>filePtr.getValue()
		ldx #<filePtr.getValue()
		jsr SDIO.CopyFileName

		ldx #<addr.getValue()
		ldy #>addr.getValue()
		ldz #[[addr.getValue() & $ff0000] >> 16]

		jsr SDIO.LoadChip
	S65_RestoreRegisters()
	S65_AddToMemoryReport("SDCard_LoadToChipRam")
}


/**
 * .pseudocommand LoadToAtticRam
 * 
 * Loads a file from the SDCard into attic RAM
 * 
 * @namespace SDCard
 * @param {word} {ABS} addr Pointer to the memory load location
 * @param {string} {ABS} filePtr Pointer to the filename (zero terminated) on the SDCard to load
 * @flags izc
 */
.pseudocommand SDCard_LoadToAtticRam addr : filePtr {
	.if(!_isAbs(addr) && !_isReg(filePtr)) .error "SDCard_LoadToAtticRam:"+ S65_TypeError
	S65_AddToMemoryReport("SDCard_LoadToChipRam")
	S65_SaveRegisters()	

		lda #>filePtr 
		ldx #<filePtr 
		jsr SDIO.CopyFileName

		ldx #<addr
		ldy #>addr
		ldz #[[addr & $ff0000] >> 16]

		ldx #>filePtr.getValue()
		ldy #<filePtr.getValue()
		jsr SDIO.CopyFileName

		ldx #<addr.getValue()
		ldy #>addr.getValue()
		ldz #[[addr.getValue() & $ff0000] >> 16]

		jsr SDIO.LoadAttic
	S65_RestoreRegisters()
	S65_AddToMemoryReport("SDCard_LoadToChipRam")		
}

SDIO: {
	CopyFileName: {
		sta FileName + 1
		stx FileName + 0

		ldx #$00
	!:
		lda FileName:$BEEF, x 
		sta SDFILENAME, x 
		inx
		bne !-

		ldx #<SDFILENAME
		ldy #>SDFILENAME
		lda #$2e	
		sta $d640 
		nop
		bcs !success+
		jmp SDIO.Error
	!success:
		rts
	}
	LoadAttic: {
		lda #HVC_SD_TO_ATTICRAM
		sta $d640 
		nop
		bcs !success+
		jmp SDIO.Error
	!success:		
		rts		
	}
	LoadChip: {
		lda #HVC_SD_TO_CHIPRAM
		sta $d640 
		nop
		bcs !success+
		jmp SDIO.Error
	!success:
		rts		
	}

	Error: {
		lda #$38
		sta $d640
		clv 
		inc $d020
		jmp *-3
	}

}
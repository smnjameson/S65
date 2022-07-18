
/**
 * .pseudocommand LoadToChipRam
 * 
 * Loads a file from the SDCard into chip RAM
 * 
 * @namespace SDCard
 * 
 * @param {dword} {ABS} addr Pointer to the memory load location
 * @param {word} {ABS} filePtr Pointer to the filename (zero terminated) on the SDCard to load
 * 
 * @registers AXYZ
 * @flags izc
 */
.pseudocommand SDCard_LoadToChipRam addr : filePtr {
		lda #>filePtr.getValue()
		ldx #<filePtr.getValue()
		jsr SDIO.CopyFileName

		ldx #<addr.getValue()
		ldy #>addr.getValue()
		ldz #[[addr.getValue() & $ff0000] >> 16]

		lda #HVC_SD_TO_CHIPRAM
		sta $d640 
		nop
}


/**
 * .pseudocommand LoadToAtticRam
 * 
 * Loads a file from the SDCard into attic RAM
 * 
 * @namespace SDCard
 * 
 * @param {word} {ABS} addr Pointer to the memory load location
 * @param {string} {ABS} filePtr Pointer to the filename (zero terminated) on the SDCard to load
 * 
 * @registers AXYZ
 * @flags izc
 */
.pseudocommand SDCard_LoadToAtticRam addr : filePtr {
		lda #>filePtr.getValue()
		ldx #<filePtr.getValue()
		jsr SDIO.CopyFileName

		ldx #<addr.getValue()
		ldy #>addr.getValue()
		ldz #[[addr.getValue() & $ff0000] >> 16]

		lda #HVC_SD_TO_ATTICRAM
		sta $d640 
		nop
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

		//Make hypervisor call to set filename to load
		ldx #<SDFILENAME
		ldy #>SDFILENAME
		lda #$2e	
		sta $d640 
		nop
		rts
	}
}
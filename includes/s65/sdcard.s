/////////////////////////////////////////// 
// SDCard
///////////////////////////////////////////
/**
 * .namespace SDCard
 * 
 * API for using the SD card to load assets to memory
 */
 * = * "SDCard IO code"


.const SDFILENAME = $0200 //-$03ff
.const HVC_SD_TO_CHIPRAM = $36
.const HVC_SD_TO_ATTICRAM = $3e


/**
 * .macro LoadToChipRam
 * 
 * Loads a file from the SDCard into chip RAM
 * 
 * @namespace SDCard
 * 
 * @param {dword} addr Pointer to the memory load location
 * @param {string} filenamr The filename on the SDCard to load
 * 
 * @registers AXYZ
 * @flags izc
 */
.macro SDCard_LoadToChipRAM(addr, filename) {
		bra !+
	File:
		.encoding "screencode_mixed"
		.text filename
		.byte $00
	!:	
		lda #>File
		ldx #<File
		jsr SDIO.CopyFileName

		ldx #<addr
		ldy #>addr
		ldz #[[addr & $ff0000] >> 16]

		lda #HVC_SD_TO_CHIPRAM
		sta $d640 
		nop
}


/**
 * .macro LoadToAtticRAM
 * 
 * Loads a file from the SDCard into attic RAM
 * 
 * @namespace SDCard
 * 
 * @param {word} addr Pointer to the memory load location
 * @param {string} filenamr The filename on the SDCard to load
 * 
 * @registers AXYZ
 * @flags izc
 */
.macro SDCard_LoadToAtticRAM(addr, filename) {
		bra !+
	File:
		.text filename
		.byte $00
	!:	
		lda #>File 
		ldx #<File
		jsr SDIO.CopyFileName

		ldx #<addr
		ldy #>addr
		ldz #[[addr & $ff0000] >> 16]

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
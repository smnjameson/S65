/////////////////////////////////////////// 
// System
///////////////////////////////////////////
/**
 * .namespace System
 * 
 * Tools and utilities for configuring the processor and launching
 * programs.
 */
 
/**
 * .macro BasicUpstart65
 * 
 * Creates the 
 * <a href='#System_BasicUpstart65_Format'>Basic Upstart</a>
 * for the MEGA65 at location $2001
 * pointing to the given SYS entry address
 * 
 * @namespace System
 * 
 * @param {word} addr Pointer to the program entry point
 * 
 * .data BasicUpstart65_Format
 * 
 * @addr {word} $2001 Pointer to next end of command marker $2009
 * @addr {word} $2003 Basic Line number 10
 * @addr {dword} $2005 Basic "BANK 0"
 * @addr {word} $2009 Pointer to next snd of command marker after screencode string
 * @addr {word} $200b Basic Line number 20
 * @addr {byte} $200d Basic "SYS"
 * @addr {string} $200e Entry point as screencode string
 * @addr {byte} ???? Terminating Zero
 * @addr {word} ???? End of Basic terminating zeros
 * 
 */
 .macro System_BasicUpstart65(addr) {
	* = $2001
		.var addrStr = toIntString(addr)

		.byte $09,$20 //End of command marker (first byte after the 00 terminator)
		.byte $0a,$00 //10
		.byte $fe,$02,$30,$00 //BANK 0
		.byte <end, >end //End of command marker (first byte after the 00 terminator)
		.byte $14,$00 //20
		.byte $9e //SYS
		.text addrStr
		.byte $00
	end:
		.byte $00,$00	//End of basic terminators
}

 
/**
 * .macro Enable40Mhz
 * 
 * Switches the MEGA65 45GS_02 processor to use 40.5Mhz mode
 * 
 * @namespace System
 * 
 * @registers A
 * @flags iz
 */
.macro System_Enable40Mhz() {
		lda #$41
		sta $00 //40 Mhz mode
}


/**
 * .macro EnableVIC4
 * 
 * Switches the VIC chip in the MEGA65 into VIC4 mode.
 * 
 * @namespace System
 * 
 * @registers AXYZ
 * @flags iz
 */
.macro System_EnableVIC4() {
		lda #$00
		tax 
		tay 
		taz 
		map
		eom

		lda #$47	//Enable VIC IV
		sta $d02f
		lda #$53
		sta $d02f
		eom
}

/**
 * .macro DisableC65ROM
 * 
 * Disables the C65 rom protection making it writable
 * 
 * @namespace System
 * 
 * @registers A
 * @flags iz
 */
.macro System_DisableC65ROM() {
		lda #$70
		sta $d640
		eom
}



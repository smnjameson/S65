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
* .macro EnableFastRRB
*
* Enables rewrite double buffering to prevent clipping on the
* left side of the screen and enable 2 raster scans per line for 
* double pixel clock in V200 mode.
* 
* @namespace System
*
* @registers A
* @flags nz
*/
.macro System_EnableFastRRB() {
    
        //Enable double line RRB to double the time for RRB operations 
        //by setting V400 mode, enabling bit 6 in $d051 and setting $d05b Y scale to 0
        lda #$08
        tsb $d031
        lda #$40    
        tsb $d051
        lda #$00    
        sta $d05b


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


/**
* .macro WaitForRaster
*
* Halts execution and waits for the given raster line
* 
* @namespace System
*
* @param {byte} raster The line to wait for
*
* @registers A
* @flags czn
*/
.macro System_WaitForRaster(raster) {
	    lda #<raster
    !:
        cmp $d012 
        bne !-
    .if(raster>=$100) {
        bit $d011
        bpl !-
    }

}

/**
* .macro BorderDebug
*
* If the preprocessor #define NODEBUG is not defined
* this will set the border color to the give value. Useful 
* for debugging
* 
* @namespace System
*
* @param {byte} color The color to set the border
*
* @registers A
* @flags zn
*/
.macro System_BorderDebug(color) {
    #if NODEBUG
    #else
        lda #color
        sta $d020
    #endif
}


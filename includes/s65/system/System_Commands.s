/**
* .pseudocommand GetRandom8
*
* Returns a random 8 bit number in
* <a href="#Global_ReturnValue">S65_ReturnValue</a> and the accumulator
* 
* @namespace System
*/
.pseudocommand System_GetRandom8 {
		jsr _System_Random8
		sta S65_ReturnValue + 0	
}
/**
* .pseudocommand GetRandom16
*
* Returns a random 16 bit number in
* <a href="#Global_ReturnValue">S65_ReturnValue</a>
* 
* @namespace System
*/
.pseudocommand System_GetRandom16 {
	 	jsr _System_Random8
		sta S65_ReturnValue + 1
		jsr _System_Random8
		sta S65_ReturnValue + 0	
}
_System_Random8: {
	phx
	    ldx randindex
	    dex
	    bpl *+4
	    ldx #$0c
	!:
	    stx randindex
	    lda randtab,x
	    eor $d012
	    sta randtab,x
	plx
	rts
	randtab:
   		.fill 13, random() * 256
   	randindex: 
   		.byte $00

}
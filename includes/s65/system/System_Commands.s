/**
* .pseudocommand GetRandom8
*
* Returns a random 8 bit number in
* <a href="#Global_ReturnValue">S65_ReturnValue</a> and the accumulator
* 
* @namespace System
* @registers A
* @flags nzc 
*/
.pseudocommand System_GetRandom8 {        
        lda #$00
        sta S65_ReturnValue + 1
		jsr _System_Random16
		sta S65_ReturnValue + 0	

}
/**
* .pseudocommand GetRandom16
*
* Returns a random 16 bit number in
* <a href="#Global_ReturnValue">S65_ReturnValue</a><br>
* Accumulator will have the hi byte
* 
* @namespace System
* @registers A
* @flags nzc
*/
.pseudocommand System_GetRandom16 {

	 	jsr _System_Random16
		sta S65_ReturnValue + 0
		lda _System_Random16.rng_zp_low
		sta S65_ReturnValue + 1	
}
_System_Random16: {
		// from https://codebase64.org/doku.php?id=base:16bit_xorshift_random_generator
        
        // the RNG. You can get 8-bit random numbers in A or 16-bit numbers
        // from the rng_zp_lo/high. Leaves X/Y unchanged. 
        lda rng_zp_high
        lsr
        lda rng_zp_low
        ror
        eor rng_zp_high
        sta rng_zp_high // high part of x ^= x << 7 done
        ror             // A has now x >> 9 and high bit comes from low byte
        eor rng_zp_low
        sta rng_zp_low  // x ^= x >> 9 and the low part of x ^= x << 7 done
        eor rng_zp_high 
        sta rng_zp_high // x ^= x << 8 done
        rts 
    rng_zp_low: .byte $a7   // seed, can be anything except 0
    rng_zp_high: .byte $2d   
}
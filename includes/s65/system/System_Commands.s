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


/**
* .pseudocommand Compare16
*
* peforms a 16bit compare between value A and valueB, setting flags accordingly
* 
* @namespace System
*
* @param {byte} {IMM|ABS16|ABX16|ABY16} valueA Vlaue to compare against valueB
* @param {byte} {IMM|ABS16|ABX16|ABY16} valueB Value to compare against valueA
*
* @flags nzc
*/
.pseudocommand System_Compare16 valueA : valueB {
    S65_AddToMemoryReport("System_Compare16")
    .if(!_isAbsImm(valueA) && !_isAbsXY(valueA)) .error "System_Compare16:"+S65_TypeError
    .if(!_isAbsImm(valueB) && !_isAbsXY(valueB)) .error "System_Compare16:"+S65_TypeError
    pha
        .if(_isAbs(valueA)) {
            lda valueA.getValue() + 0
        } 
        .if(_isAbsX(valueA)) {
            lda valueA.getValue() + 0, x 
        }  
        .if(_isAbsY(valueA)) {
            lda valueA.getValue() + 0, y 
        }                   
        .if(_isImm(valueA)){
            lda #<valueA.getValue()
        }



        .if(_isAbs(valueB)) {
            cmp valueB.getValue() + 0
        } 
        .if(_isAbsX(valueB)) {
            cmp valueB.getValue() + 0, x 
        }  
        .if(_isAbsY(valueB)) {
            cmp valueB.getValue() + 0, y 
        }          
        .if(_isImm(valueB)){
            cmp #<valueB.getValue()
        } 



        .if(_isAbs(valueA)) {
            lda valueA.getValue() + 1
        } 
         .if(_isAbsX(valueA)) {
            lda valueA.getValue() + 1, x 
        }  
        .if(_isAbsY(valueA)) {
            lda valueA.getValue() + 1, y 
        }         
        .if(_isImm(valueA)){
            lda #>valueA.getValue()
        }



        .if(_isAbs(valueB)) {
            sbc valueB.getValue() + 1
        } 
        .if(_isAbsX(valueB)) {
            sbc valueB.getValue() + 1, x 
        }  
        .if(_isAbsY(valueB)) {
            sbc valueB.getValue() + 1, y 
        }           
        .if(_isImm(valueB)){
            sbc #>valueB.getValue()
        }                
    pla
    S65_AddToMemoryReport("System_Compare16")
}
/**
* .pseudocommand Execute
*
* Executes the DMagic job at the given address. 
* 
* @namespace DMA
*
* @param {byte} {ABS} address Pointer to a DMagic job to execute
*
* @registers A
* @flags nz
*/
.pseudocommand DMA_Execute address {
    S65_AddToMemoryReport("DMA_Execute")
        .if(address.getType() != AT_ABSOLUTE) .error "DMA_Execute:"+ S65_TypeError
        .var addr = address.getValue()
		lda #[addr >> 16]
		sta $d702
		sta $d704
		lda #>addr
		sta $d701
		lda #<addr
		sta $d705
    S65_AddToMemoryReport("DMA_Execute")
}


/**
 * .pseudocommand Header
 * 
 * Sets the DMagic header bytes defining the source and
 * destination banks.<br><br>
 * Note: The bank number of a memory adress is its 
 * 5th and 6th nybble. e.g. $ff80000 is bank number $ff
 * 
 * @namespace DMA
 * 
 * @param {byte?} {IMM} sourceBank The source bank number Defaults to 0
 * @param {byte?} {IMM} destBank The destination bank number Defaults to 0
 */
.pseudocommand DMA_Header sourceBank : destBank {
        .if( !_isImmOrNone(sourceBank) || !_isImmOrNone(destBank)) .error "DMA_Header:"+ S65_TypeError

        .byte $0A // Request format is F018B
        .if(sourceBank.getType() == AT_NONE) {
            .byte $80, $00
        } else {
            .byte $80, sourceBank.getValue()
        }
        .if(destBank.getType() == AT_NONE) {
            .byte $81, $00
        } else {
            .byte $81, destBank.getValue()
        }  
}


/**
 * .pseudocommand Step
 * 
 * Sets the source and/or destination stepping values. The DMA will use a 
 * fixed point step for each increment on the source and destination 
 * by default they are both set to the fixed point 8:8 value $0100 (or 1.0 in decimal)
 * 
 * @namespace DMA
 * 
 * @param {word?} {IMM} sourceStep Source data stepping value in 8:8 fixed point format
 * @param {word?} {IMM} destStep Destination data stepping value  in 8:8 fixed point format
 */
.pseudocommand DMA_Step sourceStep : destStep {
        .if(    !_isImmOrNone(sourceStep) || 
                !_isImmOrNone(destStep)) .error "DMA_Step:"+ S65_TypeError


		.if(sourceStep.getType() != AT_NONE) {
            .byte $82, <sourceStep.getValue()
			.byte $83, >sourceStep.getValue()
		}
		.if(destStep.getType() != AT_NONE) {
            .byte $84, <destStep.getValue()
			.byte $85, >destStep.getValue()
		}		
}


/**
 * .pseudocommand DisableTransparency
 * 
 * Disables any transparent byte masking. This is the default state.
 * 
 * @namespace DMA
 */
.pseudocommand DMA_DisableTransparency {
		.byte $06
}

/**
 * .pseudocommand EnableTransparency
 * 
 * Enables transparent byte masking. This will ignore any source bytes that 
 * match the given byte and leave the destination byte untouched.
 * 
 * @namespace DMA
 * 
 * @param {byte} {IMM} transparentByte The byte value to match from source for transparency.
 */
.pseudocommand DMA_EnableTransparency transparentByte {
        .if(!_isImm(transparentByte)) .error "DMA_EnableTransparency:"+ S65_TypeError
		.byte $07 
		.byte $86, transparentByte
}


/**
 * .pseudocommand CopyJob
 * 
 * Copys a defined number of bytes from one location in memory
 * to another using the DMagic chip @ 20mb/s
 * 
 * @namespace DMA
 * 
 * @param {dword} {ABS} source The source data pointer
 * @param {dword} {ABS} destination The destination data pointer
 * @param {word} {IMM} length The number of bytes to copy
 * @param {bool} {IMM} chain Job chains to another
 * @param {bool} {IMM} Destination pointer progresses backwards
 * 
 */
.pseudocommand DMA_CopyJob source : destination : length : chain : backwards : modulo : rowcount {
    .if(!_isAbs(source)) .error "DMA_CopyJob:"+ S65_TypeError
    .if(!_isAbs(destination)) .error "DMA_CopyJob:"+ S65_TypeError
    .if(!_isImm(length)) .error "DMA_CopyJob:"+ S65_TypeError
    .if(!_isImm(chain)) .error "DMA_CopyJob:"+ S65_TypeError
    .if(!_isImmOrNone(backwards)) .error "DMA_CopyJob:"+ S65_TypeError

    .var backwardsVal = false
    .if(!_isNone(backwards)) .eval backwardsVal = [backwards.getValue() == 1]

    .var isModulo = !_isNone(modulo)

	.byte $00 //No more options
	.if(chain.getValue() != 0) {
		.byte $04 //Copy and chain
	} else {
		.byte $00 //Copy and last request
	}	
	
	.var backByte = 0
    .var sourceVal = source.getValue()
    .var destinationVal = destination.getValue()
	.if(backwardsVal) {
		.eval backByte = $40
		.eval sourceVal += [length.getValue() - 1]
		.eval destinationVal += [length.getValue() - 1]
	}
	.word length.getValue() //Size of Copy


	.word sourceVal & $ffff
	.byte [sourceVal >> 16] + backByte


	.word destinationVal & $ffff
	.byte [[destinationVal >> 16] & $0f]  + backByte
	.if(chain.getValue() != 0) {
		.word $0000
	}
}


/**
 * .pseudocommand FillJob
 * 
 * Fills a defined number of bytes from one location in memory
 * to another using the DMagic chip @ 40mb/s
 * 
 * @namespace DMA
 * 
 * @param {byte} {IMM} sourceByte The source data byte value
 * @param {dword} {ABS} destination The destination data pointer
 * @param {word} {IMM} length The number of bytes to fill
 * @param {bool} {IMM} chain Job chains to another
 */
 .pseudocommand DMA_FillJob sourceByte : destination : length : chain {
    .if(!_isImm(sourceByte)) .error "DMA_FillJob:"+ S65_TypeError
    .if(!_isAbs(destination)) .error "DMA_FillJob:"+ S65_TypeError
    .if(!_isImm(length)) .error "DMA_FillJob:"+ S65_TypeError
    .if(!_isImm(chain)) .error "DMA_FillJob:"+ S65_TypeError


	.byte $00 //No more options
	.if(chain.getValue() != 0) {
		.byte $07 //Fill and chain
	} else {
		.byte $03 //Fill and last request
	}	
	
    .word length.getValue() //Size of Copy
	
	.word <sourceByte.getValue()
	.byte $00


	.word destination.getValue() & $ffff
	.byte [[destination.getValue() >> 16] & $0f]
    .if(chain.getValue() > 0) {
        .word $0000
    }
}


/////////////////////////////////////////// 
// DMA
///////////////////////////////////////////
/**
 * .namespace DMA
 * 
 * API for controlling the configuration and execution of DMagic jobs. Uses the
 * <a href="#DMA_F018_DMA_11_byte_format">F018 11 byte data format</a>.
 * throughout.
 *
 * .data F018_DMA_11_byte_format
 * 
 * Offsets into the DMagic job for the
 * <a target="_blank" href="https://files.mega65.org/manuals-upload/mega65-chipset-reference.pdf#F018%20DMA%20Job%20List%20Format">F018 11 byte data format</a>.
 * 
 * @addr {byte} $00 End of options
 * @addr {byte} $01 Command
 * @addr {word} $02 Count
 * @addr {word} $04 Source
 * @addr {byte} $06 Source bank + flags
 * @addr {word} $07 Destination
 * @addr {byte} $09 Destination bank + flags
 * @addr {word} $0a Modulo
 */            

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
        .if(address.getType() != AT_ABSOLUTE) .error "DMA_Execute: Only supports AT_ABSOLUTE"
        .var addr = address.getValue()
		lda #[addr >> 16]
		sta $d702
		sta $d704
		lda #>addr
		sta $d701
		lda #<addr
		sta $d705
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
 * @param {byte} {IMM} sourceBank The source bank number
 * @param {byte} {IMM} destBank The destination bank number
 */
.pseudocommand DMA_Header sourceBank : destBank {
    .if( !_isImm(sourceBank) || !_isImm(destBank)) .error "DMA_Header: Only supports AT_IMMEDIATE"

    .byte $0A // Request format is F018B
    .byte $80, sourceBank.getValue()
    .byte $81, destBank.getValue()
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
                !_isImmOrNone(destStep)) .error "DMA_Step: Only supports AT_IMMEDIATE or AT_NONE"


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
        .if(!_isImm(transparentByte)) .error "DMA_EnableTransparency: Only supports AT_IMMEDIATE"
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
 */
.macro DMA_CopyJob(source, destination, length, chain, backwards) {
    .if(!_isAbs(source)) .error "DMA_CopyJob: source Only supports AT_ABSOLUTE"
    .if(!_isAbs(destination)) .error "DMA_CopyJob: sourceByte Only supports AT_ABSOLUTE"
    .if(!_isImm(length)) .error "DMA_CopyJob: length Only supports AT_IMMEDIATE"
    .if(!_isImm(chain)) .error "DMA_CopyJob: chain Only supports AT_IMMEDIATE"
    .if(!_isImm(backwards)) .error "DMA_CopyJob: chain Only supports AT_IMMEDIATE"

	.byte $00 //No more options
	.if(chain.getValue() != 0) {
		.byte $04 //Copy and chain
	} else {
		.byte $00 //Copy and last request
	}	
	
	.var backByte = 0
	.if(backwards.getValue() != 0) {
		.eval backByte = $40
		.eval source = source.getValue() + length.getValue() - 1
		.eval destination = destination.getValue() + length.getValue() - 1
	}
	.word length.getValue() //Size of Copy

	.word source.getValue() & $ffff
	.byte [source.getValue() >> 16] + backByte

	.word destination.getValue() & $ffff
	.byte [[destination.getValue() >> 16] & $0f]  + backByte
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
 * 
 */
.pseudocommand DMA_FillJob sourceByte : destination : length : chain {
    .if(!_isImm(sourceByte)) .error "DMA_FillJob: sourceByte Only supports AT_IMMEDIATE"
    .if(!_isAbs(destination)) .error "DMA_FillJob: sourceByte Only supports AT_ABSOLUTE"
    .if(!_isImm(length)) .error "DMA_FillJob: length Only supports AT_IMMEDIATE"
    .if(!_isImm(chain)) .error "DMA_FillJob: chain Only supports AT_IMMEDIATE"

	.byte $00 //No more options
	.if(chain.getValue() != 0) {
		.byte $07 //Fill and chain
	} else {
		.byte $03 //Fill and last request
	}	
	
	.word length.getValue() //Size of Copy
	.word sourceByte.getValue()
	.byte $00
	.word destination.getValue() & $ffff
	.byte [[destination.getValue() >> 16] & $0f] 
	.if(chain.getValue() != 0) {
		.word $0000
	}
}


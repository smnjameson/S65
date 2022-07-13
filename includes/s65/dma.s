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
 * @addr {byte} $00 Command
 * @addr {word} $01 Count
 * @addr {word} $03 Source
 * @addr {byte} $05 Source bank + flags
 * @addr {word} $06 Destination
 * @addr {byte} $08 Destination bank + flags
 * @addr {word} $09 Modulo
 */
 
/**
 * .macro Execute
 * 
 * Executes the DMagic job at the given address. 
 * 
 * @namespace DMA
 * 
 * @param {word} address Pointer to a DMagic job to execute
 * 
 * @registers A
 * @flags nz
 */
.macro DMA_Execute(address) {
		lda #[address >> 16]
		sta $d702
		sta $d704
		lda #>address
		sta $d701
		lda #<address
		sta $d705
}


/**
 * .macro Header
 * 
 * Sets the DMagic header bytes defining the source and
 * destination banks.<br><br>
 * <small>Note: The bank number of a memory adress is its 
 * 5th and 6th nybble. e.g. $ff80000 is bank number $ff
 * 
 * @namespace DMA
 * 
 * @param {word} address
 */
.macro DMA_Header(SourceBank, DestBank) {
		.byte $0A // Request format is F018B
		.byte $80, SourceBank
		.byte $81, DestBank
}

/**
 * .macro Step
 * 
 * Sets the source and destination stepping values. The DMA will use a 
 * fixed point (8:8) step for each increment on the source and destination 
 * by default they are both set to $01.00 
 * 
 * @namespace DMA
 * 
 * @param {byte} sourceStep Source data stepping value integer
 * @param {byte} sourceStepFrac Source data stepping value fraction
 * @param {byte} destStep Destination data stepping value integer
 * @param {byte} destStepFrac Destination data stepping value fraction
 */
.macro DMA_Step(sourceStep, sourceStepFrac, destStep, destStepFrac) {
		.if(sourceStepFrac != 0) {
			.byte $82, sourceStepFrac
		}
		.if(sourceStep != 1) {
			.byte $83, sourceStep
		}
		.if(destStepFrac != 0) {
			.byte $84, destStepFrac
		}
		.if(destStep != 1) {
			.byte $85, destStep
		}		
}

/**
 * .macro DisableTransparency
 * 
 * Disables any transparent byte masking. This is the default state.
 * 
 * @namespace DMA
 */
.macro DMA_DisableTransparency() {
		.byte $06
}

/**
 * .macro EnableTransparency
 * 
 * Enables transparent byte masking. This will ignore any source bytes that 
 * match the given byte and leave the destination byte untouched.
 * 
 * @namespace DMA
 * 
 * @param {byte} transparentByte The byte value to match from source for transparency.
 */
.macro DMA_EnableTransparency(transparentByte) {
		.byte $07 
		.byte $86, transparentByte
}

/**
 * .macro CopyJob
 * 
 * Copys a defined number of bytes from one location in memory
 * to another using the DMagic chip @ 20mb/s
 * 
 * @namespace DMA
 * 
 * @param {dword} source The source data pointer
 * @param {dword} destination The destination data pointer
 * @param {word} length The number of bytes to copy
 * @param {bool} chain Job chains to another
 * @param {bool} backwards Destination pointer progresses backwards
 * 

 */
.macro DMA_CopyJob(source, destination, length, chain, backwards) {
	.byte $00 //No more options
	.if(chain) {
		.byte $04 //Copy and chain
	} else {
		.byte $00 //Copy and last request
	}	
	
	.var backByte = 0
	.if(backwards) {
		.eval backByte = $40
		.eval source = source + length - 1
		.eval destination = destination + length - 1
	}
	.word length //Size of Copy

	.word source & $ffff
	.byte [source >> 16] + backByte

	.word destination & $ffff
	.byte [[destination >> 16] & $0f]  + backByte
	.if(chain) {
		.word $0000
	}
}

/**
 * .macro FillJob
 * 
 * Fills a defined number of bytes from one location in memory
 * to another using the DMagic chip @ 40mb/s
 * 
 * @namespace DMA
 * 
 * @param {byte} sourceByte The source data byte value
 * @param {dword} destination The destination data pointer
 * @param {word} length The number of bytes to fill
 * @param {bool} chain Job chains to another
 * 
 */
.macro DMA_FillJob(sourceByte, destination, length, chain) {
	.byte $00 //No more options
	.if(chain) {
		.byte $07 //Fill and chain
        .print "CHAIN"
	} else {
		.byte $03 //Fill and last request
	}	
	
	.word length //Size of Copy
	.word sourceByte
	.byte $00
	.word destination & $ffff
	.byte [[destination >> 16] & $0f] 
	.if(chain) {
		.word $0000
	}
}

/**
 * .global S65
 * 
 * Shallan65 macro toolkit for the MEGA65.
 * <br><br>
 * - Uses NCM mode and the raster rewrite buffer to provide
 * a powerful layer and sprite framework<br>
 * - DMA job data macros<br>
 * - SDCard loading
 * <br>
 * <br>
 * The Global(S65) namespace is mostly used internally
 * by the engine, however some methods and vars may be of
 * use.
 *
 * @author     Shallan50k
 * @date       13/07/2022
 */
.cpu _45gs02
.const S65_MAX_LAYERS = $10

* = $1400 "Pre BASIC small code"
#import "includes/s65/sdcard.s"

System_BasicUpstart65(S65_InitComplete)
* = $2016 "S65 Base page area"

//Constants and functions for use with the pseudocommandsystem
.const AT_IMMEDIATE16 = -6
.const REGA = $f0128ceee1
.const REGX = $f0128ceee2
.const REGY = $f0128ceee3
.const REGZ = $f0128ceee4

.const S65_TypeError = " does not support this addressing mode."

.const TRUE = 1
.const FALSE = 0

.function _isReg(p) {
	.return ((p.getType() == AT_IMMEDIATE16 || p.getType() == AT_IMMEDIATE || p.getType() == AT_ABSOLUTE) && _isRegValue(p))
}
.function _isRegValue(p) {
	.return (p.getValue() >=REGA && p.getValue() <= REGZ)
}
.function _isNone(p) {
	.return (p.getType() == AT_NONE) && !_isRegValue(p)
}
.function _isAbs(p) {
	.return (p.getType() == AT_ABSOLUTE)
}
.function _isImm(p) {
	.return (p.getType() == AT_IMMEDIATE16 || p.getType() == AT_IMMEDIATE) && !_isRegValue(p)
}
.function _isAbsX(p) {
	.return (_isAbs(p) || p.getType() == AT_ABSOLUTEX) && !_isRegValue(p)
}
.function _isAbsXY(p) {
	.return (_isAbsX(p) || p.getType() == AT_ABSOLUTEY) && !_isRegValue(p)
}
.function _isAbsImm(p) {
	.return (_isAbs(p) || _isImm(p)) && !_isRegValue(p)
}
.function _isImmOrNone(p) {
	.return (_isImm(p) || _isNone(p)) && !_isRegValue(p)
} 
.function _isAbsImmOrNone(p) {
	.return (_isAbs(p) || _isNone(p) || _isImm(p)) && !_isRegValue(p)
}



.macro _saveIfReg(p , addr) {
	.if(_isReg(p)) {
		.if(p.getValue() == REGA) sta addr
		.if(p.getValue() == REGX) stx addr
		.if(p.getValue() == REGY) sty addr
		.if(p.getValue() == REGZ) stz addr
	}
}
.macro _saveIfRegOrNone(p , addr) {
	.if(_isReg(p)) {
		.if(p.getValue() == REGA) sta addr
		.if(p.getValue() == REGX) stx addr
		.if(p.getValue() == REGY) sty addr
		.if(p.getValue() == REGZ) stz addr
	} 
	.if(_isNone(p)) {
		lda #$00
		sta addr
	}	
}

////////////////////////////////////////////
//Base page vars
////////////////////////////////////////////
.align $20 //Ensure theres enough room in the page for the base vars
.var 		S65_BASEPAGE = [* >> 8]		//Gets the page# of this address
				
			S65_BaseScreenRamPointer: .dword $00000000
			S65_BaseColorRamPointer: .dword $00000000
			S65_ScreenRamPointer: .dword $00000000
			S65_ColorRamPointer: .dword $00000000

			S65_DynamicLayerData: .word $0000
 			S65_PseudoReg:	.byte $00,$00,$00,$00
 			S65_LastBasePage: .byte $00

 			S65_TempDword1:	.dword $00000000
 			S65_TempDword2:	.dword $00000000
 			S65_TempWord1:	.word $0000
 			S65_TempByte1:	.byte $00


///////////////////////////////////////////// 31 bytes

				
#import "includes/s65/common.s"
#import "includes/s65/layer.s"
#import "includes/s65/system.s"
#import "includes/s65/dma.s"
#import "includes/s65/palette.s"

S65: {
	Init: {
			sei 
			lda #$35
			sta $01
			//Disable CIA interrupts
			lda #$7f
			sta $dc0d
			sta $dd0d

			System_Enable40Mhz()
			System_EnableVIC4()
			System_DisableC65ROM()

			//Disable IRQ raster interrupts
			//because C65 uses raster interrupts in the ROM
			lda #$00
			sta $d01a

			//Unmap C65 Roms $d030 by clearing bits 3-7
			lda #%11111000
			trb $d030
			cli

			//Disable hot register so VIC2 registers 
			//turn off bit 7 
			lda #$80		
			trb $d05d		//wont destroy VIC4 values (bit 7)


			//Disable VIC3 ATTR register to enable 8bit color
			lda #$20 
			trb $d031

			//Enable RAM palettes
			lda #$04
			tsb $d030

			//Turn on FCM mode and
			//16bit per char number
			//bit 0 = Enable 16 bit char numbers
			//bit 1 = Enable Fullcolor for chars <=$ff
			//bit 2 = Enable Fullcolor for chars >$ff
			lda #$05
			sta $d054


			
			rts
	}


}


//This label S65_InitComplete MUST always be at the end of the library 
//as it is where the program continues execution when initialised
S65_InitComplete:


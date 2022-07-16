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
.const REGA = $10000001
.const REGX = $10000002
.const REGY = $10000003
.const REGZ = $10000004

.const TRUE = 1
.const FALSE = 0

.function _isImm(p) {
	.return (p.getType() == AT_IMMEDIATE16 || p.getType() == AT_IMMEDIATE)
}
.function _isAbs(p) {
	.return (p.getType() == AT_ABSOLUTE)
}
.function _isAbsX(p) {
	.return (p.getType() == AT_ABSOLUTE || p.getType() == AT_ABSOLUTEX)
}
.function _isAbsXY(p) {
	.return (p.getType() == AT_ABSOLUTE || p.getType() == AT_ABSOLUTEX || p.getType() == AT_ABSOLUTEY)
}
.function _isAbsImm(p) {
	.return (p.getType() == AT_IMMEDIATE16 || p.getType() == AT_IMMEDIATE || p.getType() == AT_ABSOLUTE)
}
.function _isImmOrNone(p) {
	.return (p.getType() == AT_IMMEDIATE16 || p.getType() == AT_IMMEDIATE || p.getType() == AT_NONE)
}
.function _isAbsImmOrNone(p) {
	.return (p.getType() == AT_IMMEDIATE16 || p.getType() == AT_IMMEDIATE || p.getType() == AT_ABSOLUTE || p.getType() == AT_NONE)
}
.function _isReg(p) {
	.return (p.getType() == AT_ABSOLUTE  && p.getValue() >=REGA && p.getValue() <= REGZ)
}
.macro _saveReg(p) {
	.if(!_isReg(p)) .error "_saveReg: Cannot use saveReg as value is not a register"
	.if(p.getValue() == REGA) sta S65_PseudoReg 
	.if(p.getValue() == REGX) stx S65_PseudoReg 
	.if(p.getValue() == REGY) sty S65_PseudoReg 
	.if(p.getValue() == REGZ) stz S65_PseudoReg 
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
 			S65_PseudoReg:	.byte $00
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

			// Set VIC to use 40 column mode display
			//turn off bit 7 
			lda #$80		
			trb $d031 

			//Set VIC3 ATTR register to enable 8bit color
			lda #$20 
			tsb $d031

			//Turn on FCM mode and
			//16bit per char number
			//bit 0 = Enable 16 bit char numbers
			//bit 1 = Enable Fullcolor for chars <=$ff
			//bit 2 = Enable Fullcolor for chars >$ff
			lda #$05
			sta $d054

			System_EnableFastRRB()
			
			rts
	}


}


//This label S65_InitComplete MUST always be at the end of the library 
//as it is where the program continues execution when initialised
S65_InitComplete:


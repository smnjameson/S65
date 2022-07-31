 .file [name="main.prg", segments="S65Code,PreloadFilenames", allowOverlap]
 .segmentdef S65Code [start=$2001]
 .segmentdef PreloadFilenames [start=$1700]
.segment S65Code

/**
 * .global S65
 * 
 * Shallan65 macro toolkit for the MEGA65.<br><br>
 * - Uses NCM and FCM mode and the raster rewrite buffer to provide
 * a powerful layer and sprite framework<br>
 * - DMA job data macros<br>
 * - SDCard loading
 * <br>
 * <br>
 * The S65 namespace is mostly used internally
 * by the engine, however some methods and vars may be of
 * use.
 *
 * @author     Shallan50k
 * @date       13/07/2022
 */
.cpu _45gs02

//Constants for limits on various objects
.var S65_MAX_LAYERS = $10
.var S65_SPRITESET_LIMIT = $10
.var S65_MAX_TILEMAPS = $20


.const S65_HIGHEST_LOAD = $f000


// * = $1400 "SDCard Palette Buffer"
	.const Palette_SDBuffer = $1400
// 	.fill 768,0

// * = $1700 "SDCard preloader info"
	.var Asset_PreloaderFilenamePointer = $1700


* = $2001 "S65 BasicUpstart"
System_BasicUpstart65(S65_InitComplete)
* = $2016 "S65 Base page area"

.var PreLayerInitScreen = *
.var DataLayerInitScreen = * 
.var PostLayerInitScreen = *

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
	.return (p.getType() == AT_ABSOLUTEX) && !_isRegValue(p)
}
.function _isAbsXY(p) {
	.return (_isAbsX(p) || p.getType() == AT_ABSOLUTEY) && !_isRegValue(p)
}
.function _isAbsY(p) {
	.return (p.getType() == AT_ABSOLUTEY) && !_isRegValue(p)
}
.function _isAbsImm(p) {
	.return (_isAbs(p) || _isImm(p)) && !_isRegValue(p)
}
.function _isImmOrNone(p) {
	.return (_isImm(p) || _isNone(p)) && !_isRegValue(p)
} 
.function _isImmOrReg(p) {
	.return (_isImm(p) || _isReg(p))
} 
.function _isAbsImmOrNone(p) {
	.return (_isAbs(p) || _isNone(p) || _isImm(p)) && !_isRegValue(p)
}
.function _isAbsImmOrReg(p) {
	.return (_isAbs(p) || _isReg(p) || _isImm(p))
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

//Hardware math unit addresses
.const HW_MULTA0 = $d770
.const HW_MULTA1 = $d771
.const HW_MULTA2 = $d772
.const HW_MULTA3 = $d773
.const HW_MULTB0 = $d774
.const HW_MULTB1 = $d775
.const HW_MULTB2 = $d776
.const HW_MULTB3 = $d777
.const HW_MULTRES0 = $d778
.const HW_MULTRES1 = $d779
.const HW_MULTRES2 = $d77a
.const HW_MULTRES3 = $d77b
.const HW_MULTRES4 = $d77c
.const HW_MULTRES5 = $d77d
.const HW_MULTRES6 = $d77e
.const HW_MULTRES7 = $d77f

////////////////////////////////////////////
//Base page vars
////////////////////////////////////////////
.align $20 //Ensure theres enough room in the page for the base vars
.var 		S65_BASEPAGE = [* >> 8]		//Gets the page# of this address
			
/** 
 * .var ScreenRamPointer
 * 
 * {dword} S65 BasePage pointer into screen ram. It is guaranteed to have the upper two bytes set
 * at all times so can be used to access the screen ram using 32bit indirect z addressing.
 * DO NOT change bytes 2 and 3!<br><br>
 * 
 * For this reason you MUST use a Screen RAM location that does not cross a 64kb boundary
 * and aligned to page boundarys as the engine assumes this for speed<br><br>
 * 
 * Note: Requires <a href="#Global_SetBasePage">S65_SetBasePage</a> or 
 * <a href="#Layer_SetScreenPointersXY">Layer_SetScreenPointersXY</a>
 * to correctly set up the base page
 * before using indirect indexed adressing modes.
 */			
			S65_ScreenRamPointer: .dword $00000000
/** 
 * .var ColorRamPointer
 * 
 * {dword} S65 BasePage pointer into color ram. It is guaranteed to have the upper two bytes set
 * at all times so can be used to access the color ram using 32bit indirect z addressing.
 * DO NOT change bytes 2 and 3!<br><br>
 * Note: Requires <a href="#Global_SetBasePage">S65_SetBasePage</a> or 
 * <a href="#Layer_SetScreenPointersXY">Layer_SetScreenPointersXY</a>
 * to correctly set up the base page
 * before using indirect indexed adressing modes.
 */	
			S65_ColorRamPointer: .dword $00000000	
						
			S65_BaseScreenRamPointer: .dword $00000000
			S65_BaseColorRamPointer: .dword $00000000



 			S65_PseudoReg:	
 				.byte $00,$00,$00,$00
 				.byte $00,$00,$00,$00
 			S65_LastBasePage: .byte $00

 			S65_TempDword1:	.dword $00000000
 			S65_TempDword2:	.dword $00000000
 			S65_TempDword3:	.dword $00000000
 			S65_TempDword4:	.dword $00000000
 			S65_TempDword5:	.dword $00000000
 			S65_TempWord1:	.word $0000
 			S65_TempWord2:	.word $0000
 			S65_TempWord3:	.word $0000
 			S65_TempWord4:	.word $0000
 			S65_TempByte1:	.byte $00
 			S65_TempByte2:	.byte $00
 			S65_TempByte3:	.byte $00
 			S65_TempByte4:	.byte $00

			S65_SpritePointerTemp:	.word $0000
			S65_SpritePointerOld:	.word $0000
			S65_SpriteRowCounter:	.byte $00
			S65_SpriteRowTablePtr:	.word $0000
			S65_SpriteFlags:	.byte $00

/** 
 * .var LastLayerIOPointer
 * 
 * {word} S65 BasePage pointer into to the IO data for the last layer that was
 * fetched using <a href="#Layer_Get">Layer_Get</a>
 */	

			S65_LastLayerIOPointer: .word $0000	
			S65_CurrentLayer:		.byte $00
			S65_DynamicLayerData: .word $0000
			S65_Layer_RowAddressLSB:	.word $0000
			S65_Layer_RowAddressMSB:	.word $0000
			S65_Layer_OffsetTable:	.word $0000
			S65_ColorRamLSBOffset:	.byte $00
			S65_ColorRamMSBOffset:	.byte $00


			S65_TilemapPointer:		.dword $00000000
			S65_TiledefPointer:		.dword $00000000
			S65_TileColordefPointer: .dword $00000000
			S65_CurrentTilemap:		.byte $00
/** 
 * .var ReturnValue
 * 
 * {word} S65 BasePage value that is used as a return for many commands
 * when the result is a word rather than a byte. 
 */	
			S65_ReturnValue:	.word $0000

/** 
 * .var LastSpriteIOPointer
 * 
 * {word} S65 BasePage pointer into to the IO data for the last sprite that was
 * fetched using <a href="#Sprite_Get">Sprite_Get</a>
 */	
			S65_LastSpriteIOPointer: .word $0000

	

			S65_SpriteIOAddrLSB: .word $0000
			S65_SpriteIOAddrMSB: .word $0000

 			S65_Counter: .word $0000
 			S65_SpriteFineY: .byte $00

/** 
 * .var SpareBasePage
 * 
 * 16 bytes of spare storage free for use when the S65 base page is active
 * to assist with using commands that expect to be in S65 base page
 */	 			
 			S65_SpareBasePage: .fill 16, 0

///////////////////////////////////////////// 51 of 64 bytes reserved
* = * "S65 Base Library methods"

#import "includes/s65/sdcard.s"		
#import "includes/s65/s65.s"
#import "includes/s65/layer.s"
#import "includes/s65/sprite.s"
#import "includes/s65/asset.s"
#import "includes/s65/system.s"
#import "includes/s65/dma.s"
#import "includes/s65/palette.s"
#import "includes/s65/anim.s"
#import "includes/s65/tilemap.s"

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

* = * "Pre Layer_InitScreen User Code and Data"
.eval PreLayerInitScreen = *
//This label S65_InitComplete MUST always be at the end of the library 
//as it is where the program continues execution when initialised
S65_InitComplete:

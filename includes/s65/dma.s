
/**
 * .namespace DMA
 * 
 * API for controlling the configuration and execution of DMagic jobs. Uses the
 * <a href="##DMA_F018_DMA_11_byte_format">F018 11 byte data format</a>.
 * throughout.
 *
 * .data F018_DMA_11_byte_format
 * 
 * Offsets into the DMagic job for the
 * <a target="_blank" href="#https://files.mega65.org/manuals-upload/mega65-chipset-reference.pdf#F018%20DMA%20Job%20List%20Format">F018 11 byte data format</a>.
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

#import "includes/s65/dma/DMA_Commands.s"


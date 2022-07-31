/////////////////////////////////////////// 
// SDCard
///////////////////////////////////////////
/**
 * .namespace SDCard
 * 
 * API for using the SD card to load assets to memory using
 * mostly macros
 */
.const SDFILENAME = $0200 //-$03ff
.const HVC_SD_TO_CHIPRAM = $36
.const HVC_SD_TO_ATTICRAM = $3e

#import "includes/s65/sdcard/SDCard_Macros.s"
#import "includes/s65/sdcard/SDCard_Commands.s"



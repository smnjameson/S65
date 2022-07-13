/**
* .var SCREEN_RAM
* Defaults to $0800
*/
.var 		S65_SCREEN_RAM = $0800

/**
* .var COLOR_RAM
* Defaults to $ff80000
*/
.var 		S65_COLOR_RAM = $ff80000

/**
* .var VISIBLE_SCREEN_CHAR_WIDTH
* Width of the visible screen background layer in characters
*/
.var 		S65_VISIBLE_SCREEN_CHAR_WIDTH = 40

/**
* .var VISIBLE_SCREEN_CHAR_HEIGHT
* Height of the visible screen background layer in characters
*/
.var 		S65_VISIBLE_SCREEN_CHAR_HEIGHT = 25

/**
* .var SCREEN_ROW_WIDTH
* Number of characters that make up an entire screen row
*/
.var 		S65_SCREEN_ROW_WIDTH = 0

/**
* .var SCREEN_LOGICAL_ROW_WIDTH
* Number of bytes that make up an entire screen row
*/
.var 		S65_SCREEN_LOGICAL_ROW_WIDTH = 0

/**
* .var SCREEN_TERMINATOR_OFFSET
* Screen row offset for the row terminator bytes
*/
.var 		S65_SCREEN_TERMINATOR_OFFSET = 0





/**
 * .macro Trace
 * 
 * Outputs a string to the kick assembler console at build time
 * 
 * @param {string} str The string to output in the console
 */
.macro S65_Trace(str) {
	.print "-=[S65]=- "+str
}


/**
 * .macro SetBasePage
 * 
 * Saves the current base page in S65_LastBasePage and sets the
 * base page to the S65 Base page area
 * 
 * @registers AB
 * @flags nz
 */
.macro S65_SetBasePage() {
		tba 
		sta S65_LastBasePage
		lda #S65_BASEPAGE
		tab 
}

/**
 * .macro RestoreBasePage
 * 
 * Restores the base page from S65_LastBasePage
 * 
 * @registers AB
 * @flags nz
 */
.macro S65_RestoreBasePage() {
		lda.z S65_LastBasePage
		tab 
}
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
        jsr _S65_SetBasePage
}
_S65_SetBasePage: {
		tba 
		sta S65_LastBasePage
		lda #S65_BASEPAGE
		tab 
        rts
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


/**
* .macro Text16
*
* Generates a string of 16 bit words based on the text input.
* The upper nybblwe of each word is $00 and the lower nybble 
* is the normal 8 bit .screencode encoded value. terminates the string with $ffff
*
* @param {byte} str The string to convert
*/
.macro S65_Text16(str) {
    .for(var i=0; i<str.size(); i++) {
        .byte str.charAt(i), $00
    }
    .word $ffff
}






/**
* .macro MemoryReport
*
* Called at the very end of your program code this macro will
* produce a report of the memory used in each of the framework calls
* 
* @namespace S65
*/
.macro S65_MemoryReport() {

    S65_Trace("Method MemoryReport")
    S65_Trace("============================")
    S65_Trace("")
    .var keys = _MemoryReport.keys()
    .for (var i=0; i<keys.size(); i++) {
        .var ht = _MemoryReport.get(keys.get(i))
        S65_Trace(keys.get(i) + " called " + ht.get("count")+ " times.")
        S65_Trace("    Total memory used $"+ toHexString(ht.get("bytes"))+" bytes")
        S65_Trace("    Average per call  $"+ toHexString(floor(ht.get("bytes") / ht.get("count")))+" bytes")
        S65_Trace("")
    }
    S65_Trace("")
    S65_Trace("============================")    
}
.const _MemoryReport = Hashtable()
.macro S65_AddToMemoryReport(name) {
    .if(_MemoryReport.containsKey(name) == false ) {
        .eval _MemoryReport.put(name, Hashtable().put("count",0).put("bytes",0).put("start", 0))
    }
    .if(_MemoryReport.get(name).get("start") == 0) {
        .eval _MemoryReport.get(name).put("start", *)
    } else {
        .var count = _MemoryReport.get(name).get("count") + 1
        .var b = _MemoryReport.get(name).get("bytes") + [* - _MemoryReport.get(name).get("start")]
        .eval _MemoryReport.get(name).put("count",count).put("bytes",b)
        .eval _MemoryReport.get(name).put("start", 0)
    }
}
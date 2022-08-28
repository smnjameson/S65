/**
 * .namespace Debug
 * 
 * Simple debug time namespace for displaying live memory contents
 * via watchers
 */

 .var LAYER_DEBUG = 0
.var Debug_Data = 0
.var Debug_DataLabel = 0
.var Debug_WatcherList = null

.eval Debug_WatcherList = List()




/**
* .function AddWatcher
*
* Creates a watcher that is then displayed in the debug overlay. 
* 4 bytes at a time are watcehd at each address. Best declared directly after your 
* S65 library import.
* 
* Requires NODEBUG to NOT be defined
* 
* @namespace Debug
*
* @param {string} label The label to give the watcher
* @param {dword} address The address from which to watch data
*
* @return {byte} <add description here>
*/
.macro Debug_AddWatcher(label, address) {
		.var t = Debug_AddWatcherFunc(label, address)
}

.function Debug_AddWatcherFunc(label, address) {
	#if WATCHERS
		.eval Debug_WatcherList.add( Hashtable().put(
			"name", label,
			"address", address
		))
	
	#endif
}

.macro Debug_Start () {
	jmp end

		.eval Debug_DataLabel = *
		.for(var i=0; i<Debug_WatcherList.size(); i++) {
			.text Debug_WatcherList.get(i).get("name")
			.byte $00
		}
		.eval Debug_Data = *
		.for(var i=0; i<Debug_WatcherList.size(); i++) {
			.dword Debug_WatcherList.get(i).get("address")
		}	

	end:
}



.macro Debug_Update() {
	#if NODEBUG
	#else 
	.if(Debug_WatcherList.size() > 0) {
		inc $d020
		Layer_Get #LAYER_DEBUG
		Layer_ClearLayer #$20 : #$0b		
		

			S65_SetBasePage()

			ldx #$00
			ldy #$00
		!rowloop:
		// .for(var i=0; i<Debug_WatcherList.size(); i++) {
			tya 
			lsr 
			lsr
			Layer_SetScreenPointersXY #0 : #REGA
			ldz #$00
		!:
			lda Debug_DataLabel, x 
			php
			inx
			plp
			beq !done+
			sta ((S65_ScreenRamPointer)), z 
			inz 
			lda #$00
			sta ((S65_ScreenRamPointer)), z 
			inz 
			bra !-
		!done:
			inz 
			inz 

			
			lda Debug_Data, y
			sta.z S65_SpareBasePage + 0
			iny
			lda Debug_Data, y
			sta.z S65_SpareBasePage + 1
			iny
			lda Debug_Data, y
			sta.z S65_SpareBasePage + 2
			iny
			lda Debug_Data, y
			sta.z S65_SpareBasePage + 3
			iny

			
			phy
			stz sm_screen

					ldz #$00
				!addrloop:
					lda ((S65_SpareBasePage)), z
					phz

					pha 
					lsr 
					lsr 
					lsr
					lsr 
					pha 
					ldy #$02
				!charloop:
					pla
					and #$0f 
					cmp #$0a 
					bcs !letters+
				!nums:
					adc #$30
					bra !done+
				!letters:
					sbc #$09 
				!done:
					ldz sm_screen:#$BEEF
					sta ((S65_ScreenRamPointer)), z 
					inz 
					lda #$00
					sta ((S65_ScreenRamPointer)), z 
					inz 
					stz sm_screen 
					dey 
					bne !charloop-
					inc sm_screen 
					inc sm_screen 
					plz 
					inz 
					cpz #$04
					bne !addrloop-

			ldz sm_screen
			ply

			cpy #[Debug_WatcherList.size() * 4]
			lbcc !rowloop-

			S65_RestoreBasePage()
		dec $d020
	}
	#endif
}

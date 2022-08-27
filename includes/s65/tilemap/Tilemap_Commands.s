/**
* .pseudocommand Get
*
* This method sets the currently active tilemap for all tilemap commands.<br><br>
* Note: This method will also call <a href="#S65_SetBasePage">S65_SetBasePage</a> which 
* is required for the Tilemap functions
* 
* @namespace Tilemap
* @param {byte} {IMM} tilemapId The id of the tilemap to fetch
* @registers B
* @flags nzc
*/
.pseudocommand Tilemap_Get tilemapId {
	S65_AddToMemoryReport("Tilemap_Get")	
	.if(!_isImm(tilemapId)) .error "Tilemap_Get:"+ S65_TypeError

	.var tilemap = Asset_TilemapList.get(tilemapId.getValue())
	pha
	phy
	S65_SetBasePage()

		lda #tilemapId.getValue()	
		sta.z S65_CurrentTilemap


			lda #<tilemap.tilemapAddress
			sta.z S65_TilemapPointer + 0
			lda #>tilemap.tilemapAddress
			sta.z S65_TilemapPointer + 1
			lda #[[tilemap.tilemapAddress >> 16] & $ff]
			sta.z S65_TilemapPointer + 2

			lda #<tilemap.tiledefAddress
			sta.z S65_TiledefPointer + 0
			lda #>tilemap.tiledefAddress
			sta.z S65_TiledefPointer + 1
			lda #[[tilemap.tiledefAddress >> 16] & $ff]
			sta.z S65_TiledefPointer + 2
			

			lda #<tilemap.colorAddress
			sta.z S65_TileColordefPointer + 0
			lda #>tilemap.colorAddress
			sta.z S65_TileColordefPointer + 1
			lda #[[tilemap.colorAddress >> 16] & $ff]
			sta.z S65_TileColordefPointer + 2
			
			lda $00
			sta.z S65_TilemapPointer + 3
			sta.z S65_TiledefPointer + 3	
			sta.z S65_TileColordefPointer + 3


		// jsr _Tilemap_RestorePointers
	ply
	pla
	S65_AddToMemoryReport("Tilemap_Get")	
}	

_Tilemap_RestorePointers: {
		ldy.z S65_CurrentTilemap



		lda tilemap0:$BEEF, y
		sta.z S65_TilemapPointer + 0
		lda tilemap1:$BEEF, y
		sta.z S65_TilemapPointer + 1
		lda tilemap2:$BEEF, y
		sta.z S65_TilemapPointer + 2

		lda tiledef0:$BEEF, y
		sta.z S65_TiledefPointer + 0
		lda tiledef1:$BEEF, y
		sta.z S65_TiledefPointer + 1
		lda tiledef2:$BEEF, y
		sta.z S65_TiledefPointer + 2

		lda tilecolors0:$BEEF, y
		sta.z S65_TileColordefPointer + 0
		lda tilecolors1:$BEEF, y
		sta.z S65_TileColordefPointer + 1
		lda tilecolors2:$BEEF, y
		sta.z S65_TileColordefPointer + 2
		
		lda #$00
		sta.z S65_TilemapPointer + 3		
		sta.z S65_TiledefPointer + 3	
		sta.z S65_TileColordefPointer + 3

		rts
}

/**
* .pseudocommand Draw
*
* Draws a rectangle from the currently active tilemap to 
* the currently active layer using the current screenpointers<br>
* NOTE: that this routine will NOT wrap at the edge of the later so make sure to 
* not ewxceed the layers right edge or you may cause RRB corruption
* 
* @namespace Tilemap
*
* @param {byte} {IMM|REG|ABS|ABSX|ABSY} srcX The source rectangle X 
* @param {byte} {IMM|REG|ABS|ABSX|ABSY} srcY The source rectangle Y
* @param {byte} {IMM|REG|ABS|ABSX|ABSY} srcWidth The source rectangle width
* @param {byte} {IMM|REG|ABS|ABSX|ABSY} srcHeight The source rectangel height

* @flags nzc
*/
.pseudocommand Tilemap_Draw srcX : srcY : srcWidth : srcHeight {
	S65_AddToMemoryReport("Tilemap_Draw")	
	.if(!_isImm(srcX) && !_isReg(srcX) && !_isAbsXY(srcX) && !_isAbs(srcX)) .error "Tilemap_Draw:" + S65_TypeError
	.if(!_isImm(srcY) && !_isReg(srcY) && !_isAbsXY(srcY) && !_isAbs(srcY)) .error "Tilemap_Draw:" + S65_TypeError
	.if(!_isImm(srcWidth) && !_isReg(srcWidth) && !_isAbsXY(srcWidth) && !_isAbs(srcWidth)) .error "Tilemap_Draw:" + S65_TypeError
	.if(!_isImm(srcHeight) && !_isReg(srcHeight) && !_isAbsXY(srcHeight) && !_isAbs(srcHeight)) .error "Tilemap_Draw:" + S65_TypeError
	pha 
	phz 
	phy
		_saveIfReg(srcX, S65_PseudoReg + 0)
		_saveIfReg(srcY, S65_PseudoReg + 1)
		_saveIfReg(srcWidth, S65_PseudoReg + 2)
		_saveIfReg(srcHeight, S65_PseudoReg + 3)


		//Set up layer pointers
		.const TileDef = S65_TempDword1
		.const ScreenRam = S65_TempDword2
		.const ColorRam = S65_TempDword3
		.const MapPtr = S65_TempDword4
		.const ColorPtr = S65_TempDword5

		.const RowCount = S65_TempByte1
		.const ColCount = S65_TempByte2
		.const RectWidthCount = S65_TempByte3
		.const RectHeightCount = S65_TempByte4

		ldy.z S65_CurrentTilemap
		lda [Tilemap_TilemapData + S65_MAX_TILEMAPS * 6], y
		sta _Tilemap_Draw.TilemapTilesize
		asl
		sta _Tilemap_Draw.TilemapTilesizeDouble

		lda [Tilemap_TilemapData + S65_MAX_TILEMAPS * 5], y
		sta _Tilemap_Draw.TilemapTileheight
		lda [Tilemap_TilemapData + S65_MAX_TILEMAPS * 4], y
		sta _Tilemap_Draw.TilemapTilewidth

		// lda [Tilemap_TilemapData + S65_MAX_TILEMAPS * 2], y
		// sta _Tilemap_Draw.mapHeight

		lda [Tilemap_TilemapData + S65_MAX_TILEMAPS * 1], y
		sta _Tilemap_Draw.mapWidthMSB				
		lda [Tilemap_TilemapData + S65_MAX_TILEMAPS * 0], y
		sta _Tilemap_Draw.mapWidthLSB


		//Do Y first as We need to store X in accumulator
		.if(_isReg(srcY)) {
			ldy S65_PseudoReg + 1
		} 		
		.if(_isImm(srcY) || _isAbs(srcY)) {
			ldy srcY 
		}
		.if(_isAbsX(srcY)) {
			lda srcY.getValue(), x  
			tay 
		}
		.if(_isAbsY(srcY)) {
			ply 
			phy
			lda srcY.getValue(), y 
			tay 
		}


		.if(_isReg(srcX)) {
			lda S65_PseudoReg + 0
		} 
		.if(_isImm(srcX) || _isAbs(srcX)) {
			lda srcX 
		}
		.if(_isAbsX(srcX)) {
			lda srcX.getValue(), x  
		}
		.if(_isAbsY(srcX)) {
			ply 
			phy
			lda srcX.getValue(), y  
		}


		jsr _Tilemap_Draw_ResetPointers




		.if(_isReg(srcHeight)) {
			lda S65_PseudoReg + 3
		} 		
		.if(_isImm(srcHeight) || _isAbs(srcHeight)) {
			lda srcHeight 
		}
		.if(_isAbsX(srcHeight)) {
			lda srcHeight.getValue(), x  
		}
		.if(_isAbsY(srcHeight)) {
			ply 
			phy
			lda srcHeight.getValue(), y 
		}
		sta _Tilemap_Draw.RectHeight




		.if(_isReg(srcWidth)) {
			lda S65_PseudoReg + 2
		}
		.if(_isImm(srcWidth) || _isAbs(srcWidth)) {
			lda srcWidth 
		}
		.if(_isAbsX(srcWidth)) {
			lda srcWidth.getValue(), x  
		}
		.if(_isAbsY(srcHeight)) {
			ply 
			phy
			lda srcHeight.getValue(), y 
		}
		sta _Tilemap_Draw.RectWidth

		jsr _Tilemap_Draw

	ply 
	plz 
	pla		
	S65_AddToMemoryReport("Tilemap_Draw")
}

_Tilemap_Draw_ResetPointers: {
		.const TileDef = S65_TempDword1
		.const ScreenRam = S65_TempDword2
		.const ColorRam = S65_TempDword3
		.const MapPtr = S65_TempDword4
		.const ColorPtr = S65_TempDword5

		.const RowCount = S65_TempByte1
		.const ColCount = S65_TempByte2
		.const RectWidthCount = S65_TempByte3
		.const RectHeightCount = S65_TempByte4

		//add column offset	first to use A	
		clc
		adc.z S65_TilemapPointer + 0
		sta.z S65_TilemapPointer + 0
		bcc !+
		inw.z S65_TilemapPointer + 1
	!:


		sty $d770 //hw mult A lsb
		lda #$00
		sta $d771
		sta $d772
		sta $d776
		lda _Tilemap_Draw.mapWidthLSB //hw mult A lsb
		sta $d774
		lda _Tilemap_Draw.mapWidthMSB //hw mult A lsb
		sta $d775		
		
		//add row offset
		clc 
		lda.z S65_TilemapPointer + 0		
		adc $d778		
		sta.z S65_TilemapPointer + 0
		lda.z S65_TilemapPointer + 1		
		adc $d779		
		sta.z S65_TilemapPointer + 1
		lda.z S65_TilemapPointer + 2		
		adc $d77a		
		sta.z S65_TilemapPointer + 2

		lda.z S65_TiledefPointer + 0
		sta.z TileDef + 0		
		lda.z S65_TiledefPointer + 1
		sta.z TileDef + 1		
		lda.z S65_TiledefPointer + 2
		sta.z TileDef + 2		
		lda.z S65_TiledefPointer + 3
		sta.z TileDef + 3


		lda.z S65_TileColordefPointer + 0
		sta.z ColorPtr + 0		
		lda.z S65_TileColordefPointer + 1
		sta.z ColorPtr + 1		
		lda.z S65_TileColordefPointer + 2
		sta.z ColorPtr + 2		
		lda.z S65_TileColordefPointer + 3
		sta.z ColorPtr + 3

		rts
}







/////////////////////////////////////////////base code from here????
_Tilemap_Draw: {
		.const TileDef = S65_TempDword1
		.const ScreenRam = S65_TempDword2
		.const ColorRam = S65_TempDword3
		.const MapPtr = S65_TempDword4
		.const ColorPtr = S65_TempDword5

		.const RowCount = S65_TempByte1
		.const ColCount = S65_TempByte2
		.const RectWidthCount = S65_TempByte3
		.const RectHeightCount = S65_TempByte4


		lda.z S65_ScreenRamPointer + 0
		sta.z ScreenRam + 0
		lda.z S65_ScreenRamPointer + 1
		sta.z ScreenRam + 1
		lda.z S65_ScreenRamPointer + 2
		sta.z ScreenRam + 2
		lda.z S65_ScreenRamPointer + 3
		sta.z ScreenRam + 3

		lda.z S65_ColorRamPointer + 0
		sta.z ColorRam + 0
		lda.z S65_ColorRamPointer + 1
		sta.z ColorRam + 1
		lda.z S65_ColorRamPointer + 2
		sta.z ColorRam + 2
		lda.z S65_ColorRamPointer + 3
		sta.z ColorRam + 3


		lda.z S65_TilemapPointer + 0
		sta.z MapPtr + 0
		lda.z S65_TilemapPointer + 1
		sta.z MapPtr + 1
		lda.z S65_TilemapPointer + 2
		sta.z MapPtr + 2
		lda.z S65_TilemapPointer + 3
		sta.z MapPtr + 3		


		lda TilemapTilewidth
		asl 
		sta ScreenInc


		lda RectWidth:#$BEEF
		sta.z RectWidthCount

	!screenloop:
			lda RectHeight:#$BEEF
			sta.z RectHeightCount


	!screencolloop:

				//fetch a tile
				ldz #$00
				stz $d771	//reset hw mult msb
				stz $d775   //reset hw mult msb
				lda ((MapPtr)), z 
				asl 			//double for 16 bit chars
				sta $d770		//HW mult A lsb
				lda #$00
				rol
				sta $d771		//HW mult A msb

				//fetch charlookup multiply by tilesize
				lda TilemapTilesize:#$BEEF 
				//use hw mult
				sta $d774		//HW MULT B lsb
				clc 

				lda.z S65_TiledefPointer + 0
				adc $d778 //mult result lsb
				sta.z TileDef + 0

				lda.z S65_TiledefPointer + 1
				adc $d779 //mult result msb
				sta.z TileDef + 1

				lda.z S65_TiledefPointer + 2
				adc #$00 
				sta.z TileDef + 2


				//push tile chars onto stack backwards
				ldz TilemapTilesizeDouble:#$BEEF
				dez
			!:
				lda ((TileDef)), z 
				pha 
				dez 
				bpl !-



				lda TilemapTileheight:#$BEEF
				sta.z RowCount
			!rowloop:
				lda TilemapTilewidth:#$BEEF
				sta.z ColCount

				ldz #$00 //column counter
				// clc
				!colloop:
						pla 
						sta ((ScreenRam)), z	
						lda #$08
						sta ((ColorRam)), z	
						inz
						pla
	 					sta ((ColorRam)), z
	 					and #$0f
						sta ((ScreenRam)), z 
						inz

						dec.z ColCount 
						bne !colloop-



				//add to screenRamPointer and colorRamPointer
				clc
				lda.z ScreenRam + 0
				adc $d058 //LOGICAL ROW SIZE LSB
				sta.z ScreenRam + 0
				sta.z ColorRam + 0

				php
				lda.z ScreenRam + 1
				adc $d059 //LOGICAL ROW SIZE LSB
				sta.z ScreenRam + 1
				plp
				lda.z ColorRam + 1
				adc $d059 //LOGICAL ROW SIZE LSB
				sta.z ColorRam + 1				
			
				dec.z RowCount 
				bne !rowloop-



				//next screen row
				clc 
				lda.z MapPtr + 0
				adc mapWidthLSB:#$BEEF
				sta.z MapPtr + 0

				lda.z MapPtr + 1
				adc mapWidthMSB:#$BEEF
				sta.z MapPtr + 1
				bcc !+
				inw.z MapPtr + 2
			!:

				dec.z RectHeightCount 
				lbne !screencolloop-

			//screen column done 
			//so reset MapPtr adding 1 to move to next column
			clc
			lda.z S65_TilemapPointer + 0
			adc #$01
			sta.z S65_TilemapPointer + 0
			sta.z MapPtr + 0

			lda.z S65_TilemapPointer + 1
			adc #$00
			sta.z S65_TilemapPointer + 1
			sta.z MapPtr + 1

			lda.z S65_TilemapPointer + 2
			adc #$00
			sta.z S65_TilemapPointer + 2
			sta.z MapPtr + 2


			//reset screen and color ram adding 2 to move to next column
			clc
			lda.z S65_ScreenRamPointer + 0
			adc ScreenInc:#$BEEF
			sta.z ScreenRam + 0
			sta.z S65_ScreenRamPointer + 0

			lda.z S65_ScreenRamPointer + 1
			adc #$00
			sta.z ScreenRam + 1
			sta.z S65_ScreenRamPointer + 1


			clc
			lda.z S65_ColorRamPointer + 0
			adc ScreenInc
			sta.z ColorRam + 0
			sta.z S65_ColorRamPointer + 0

			lda.z S65_ColorRamPointer + 1
			adc #$00
			sta.z ColorRam + 1
			sta.z S65_ColorRamPointer + 1
			

			dec.z RectWidthCount 
			lbne !screenloop-
	!done:
		rts

}
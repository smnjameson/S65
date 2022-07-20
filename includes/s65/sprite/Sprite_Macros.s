/**
* .macro GenerateLayerData
*
* @namespace Sprite
*/
.macro Sprite_GenerateLayerData(layerNum) {
		.var layer = Layer_LayerList.get(layerNum)
		.var io = layer.get("io")

		.var count = layer.get("maxSprites")
		.var charPerLine = layer.get("charWidth") 

.print ("count: $" + toHexString(count)+"   "+toHexString(*-2))
		//$00 - gotoX from parent macro
		//Start with whole layer specific static sized data

		//$02 - max chars per line
		.var offset = *;
		.var startOffset = *
		.eval io.put("maxChars", offset)
		.byte charPerLine


		//$03 - max chars per line
		.eval offset = *;
		.eval io.put("maxSprites", offset)
		.byte count

		//$04 - rowCharCountTable
		//table of row current row counts
		.eval offset = *
		.eval io.put("rowCharCountTable", offset)
		.fill S65_VISIBLE_SCREEN_CHAR_HEIGHT, $00 

		// .eval io.put("spriteIOOffsetsLsb", offset)
		// .fill count, <[* + count * 2 + i * Sprite_SpriteIOLength] 
		// .eval io.put("spriteIOOffsetsLsb", offset)
		// .fill count, >[* + count * 2 + i * Sprite_SpriteIOLength] 

		S65_Trace("      Sprite IO registers for layer "+layerNum+ " at $"+toHexString(*))
		.eval Layer_LayerList.get(layerNum).put("spriteIOAddr", *)
		.var startAddr = *
		//sprite data
		.fill Sprite_SpriteIOLength * count, $00

		


	S65_Trace("      Register dimensions $"+toHexString(count)+ " x $"+toHexString((*-startAddr)/count))	
}




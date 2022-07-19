/**
* .macro GenerateLayerData
*
* @namespace Sprite
*/
.macro Sprite_GenerateLayerData(layerNum) {
	S65_AddToMemoryReport("Sprite_DynamicDataAndIO_"+layerNum)
		.print(toHexString(*))
		.var layer = Layer_LayerList.get(layerNum)
		.var io = layer.get("io")
		.var count = layer.get("maxSprites")
		.var charPerLine = layer.get("charWidth")

		//$00 - gotoX from parent macro
		//Start with whole layer specific static sized data

		//$01 - max chars per line
		.var offset = *;
		.eval io.put("maxChars", offset)
		.byte $00

		//$02 - rowCharCountTable
		//table of row current row counts
		.eval offset = *
		.eval io.put("rowCharCountTable", offset)
		.fill S65_VISIBLE_SCREEN_CHAR_HEIGHT, $00 

		//sprite data
		//xpos of sprite
		.eval offset = *
		.eval io.put("xmsb", offset)
		.fill count, $00

		.eval offset = *
		.eval io.put("xlsb", offset)
		.fill count, $00

		//ypos of sprite
		.eval offset = *
		.eval io.put("ymsb", offset)
		.fill count, $00

		.eval offset = *
		.eval io.put("ylsb", offset)
		.fill count, $00

	S65_AddToMemoryReport("Sprite_DynamicDataAndIO_"+layerNum)		
}	
/**
* .macro GenerateLayerData
* Internally used macro for assigning sprite IO area during a 
* <a href="#Layer_InitScreen">Layer_InitScreen</a>
* @namespace Sprite
*/
.macro Sprite_GenerateLayerData(layerNum) {
		.var layer = Layer_LayerList.get(layerNum)
		.var io = layer.get("io")

		.var count = layer.get("maxSprites")
		.var charPerLine = layer.get("charWidth") 

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

		.eval Layer_LayerList.get(layerNum).put("spriteSortList", *)
		.fill count, i
			

	S65_Trace("      Register dimensions $"+toHexString(count)+ " x $"+toHexString((*-startAddr)/count))	
}


/**
* .macro GenerateMetaData
*
* Internally used to generate the runtime lookup tables for sprite meta data
* 
* @namespace Sprite
*/
.macro Sprite_GenerateMetaData() {
		.for(var i=0; i<Asset_SpriteList.size(); i++) {
			.var spriteSheet = Asset_SpriteList.get(i)
			.var data = spriteSheet.meta
			.var offset = spriteSheet.address / $40
			.var numSprites = data.get($02) + data.get($03) * $100

			.eval spriteSheet.metaAddress = *
			.fill data.size(), data.get(i)
		}
}



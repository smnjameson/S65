const PNG = require('pngjs/browser').PNG;
const fs = require('fs');
const path = require('path');
const yargs = require('yargs/yargs')
const { hideBin } = require('yargs/helpers')
const argv = yargs(hideBin(process.argv))
		.command('chars', 'Convert an image to chars', () => {}, (argv) => {
    		runCharMapper(argv)
    	})

        .option('input', {
            alias: 'i',
            description: 'The path to the Aseprite file - eg: ./images/myimage.aseprite',
            type: 'string',
        })
        .option('output', {
            alias: 'o',
            description: 'Folder to output files to - eg: ./output',
            type: 'string',
        })  
        .option('fcm', {
            alias: 'f',
            description: 'use FCM char mode',
            type: 'boolean',
        })     
        .option('ncm', {
            alias: 'n',
            description: 'use NCM char mode',
            type: 'boolean',
        })                   
        .option('dedupe', {
            alias: 'd',
            description: 'Remove duplicate chars when getting char data',
            type: 'boolean',
        })


        .help()
        .alias('help', 'h')
        .argv;






async function getPngData(pathName) {
	var data = fs.readFileSync(path.resolve(pathName));
	return PNG.sync.read(data);
}

function setOutputPath(pathName) {
    let outputPath = pathName || "./"
    if (!fs.existsSync(outputPath)) {
        fs.mkdirSync(outputPath);
    }
    console.log("output path " + outputPath);
    return outputPath;
}



function getIndexedCharData(png) {

}
function getFCMData(png, palette) {
    let data = []
    for(var y=0; y<png.height; y+=8) {
        for(var x=0; x<png.width; x+=8) {
            for(var r=0; r<8; r++) {
                for(var c=0; c<8; c++) {
                    let i = ((y + r) * (png.width * 4) + ((x + c) * 4))
                    //find the color
                    let col = palette.findIndex(a => {
                        return (
                            png.data[i+0] === a.red &&
                            png.data[i+1] === a.green &&
                            png.data[i+2] === a.blue &&
                            png.data[i+3] === a.alpha
                        );
                    })
                    data.push(col)
                }
            }
        }
    }

    return { data }
}

function getNCMData(png, palette) {
    let data = []
    let charColors = []
    let originalPalIndex = []
    for(var y=0; y<png.height; y+=8) {
        for(var x=0; x<png.width; x+=16) {
            let charCols = []
            for(var r=0; r<8; r++) {
                for(var c=0; c<16; c+=2) {
                    let i = ((y + r) * (png.width * 4) + ((x + c) * 4))
                    let j = i + 4
                    //find the color
                    let col1 = palette.findIndex(a => {
                        return (
                            png.data[i+0] === a.red &&
                            png.data[i+1] === a.green &&
                            png.data[i+2] === a.blue &&
                            png.data[i+3] === a.alpha
                        );
                    })
                    originalPalIndex.push(col1)
                    if(charCols.indexOf(col1) === -1)  charCols.push(col1)  
                    let nyb1 = charCols.indexOf(col1)
                    

                    let col2 = palette.findIndex(a => {
                        return (
                            png.data[j+0] === a.red &&
                            png.data[j+1] === a.green &&
                            png.data[j+2] === a.blue &&
                            png.data[j+3] === a.alpha
                        );
                    })   
                     originalPalIndex.push(col2)
                    if(charCols.indexOf(col2) === -1)  charCols.push(col2) 
                    let nyb2 = charCols.indexOf(col2)

                    //push colors in this order so they can be turned into bytes easily alter

                   
                    

                    if(nyb1 > 0xf || nyb2 > 0xf) {
                        throw(new Error(`Too many colors in this char: $${data.length.toString(16)}`))
                    }
                    data.push(( nyb2 << 4 ) + nyb1)
                }
            }
            charCols = charCols.sort((a,b) => a-b)
            charColors.push(charCols)
        }
    }

    // console.log(charColors)
    // console.log("===================")
    // console.log(originalPalIndex)

    return { data, charColors, originalPalIndex }
}

function getPaletteData(png) {
    let palette = [];
    for (var c = 0; c < png.palette.length; c++) {
        let color = png.palette[c]
        let pal = {
            red: color[0],
            green: color[1],
            blue: color[2],
            alpha: color[3]
        };
        palette.push(pal);
    }
    console.log("Palette size: " + palette.length + " colors");

    let pal = { r: [], g: [], b: [] }
    for(var i=0;i<palette.length; i++) {
        let color = palette[i]
        pal.r.push(nswap(color.red))
        pal.g.push(nswap(color.green))
        pal.b.push(nswap(color.blue))
    }
    return {palette, pal}
}

function findBestFitForCharColors(inp, out) {
        let max=0
        let best=-1
        let unq = null
        for(var i=0; i<out.length; i++) {
            let matches = inp.filter(a => out[i].includes(a));
            let uniques = inp.filter(a => !out[i].includes(a));
            if( matches.length > best && //most matches in this palette slice
                uniques.length + out[i].length <= 15) {
                best = i 
                max = matches.length
                unq = uniques
            }
        }
        if(best === -1) {
            throw(new Error("There is not enough room in the palette to sort these colors"))
        }

        out[best] = out[best].concat(unq).sort((a,b) => a-b)
        return out
}

function sortNCMPalette(charData, paletteData) {
        let sortedArray = new Array(16).fill([0])

        for(var i=0; i<charData.charColors.length; i++) {

            let colors = charData.charColors[i]
            sortedArray = findBestFitForCharColors(colors, sortedArray)
        }
      
        let palette = [];
        let pal = { r: [], g: [], b: [] }
        for(var s = 0; s<16; s++){
             
            for(var i=0; i<16; i++){

                var col = sortedArray[s][i]

                if(typeof col !== 'undefined') {
                    let color = paletteData.palette[col]
                    palette.push(color)
                    pal.r.push(nswap(color.red))
                    pal.g.push(nswap(color.green))
                    pal.b.push(nswap(color.blue))
                } else {
                    palette.push({
                        red: 0,
                        green: 0,
                        blue: 0,
                        alpha: 0
                    }); 
                    pal.r.push(0)
                    pal.g.push(0)
                    pal.b.push(0)                   
                }
            }


            if(sortedArray[s].reduce((p, a) => p + a, 0)) {
                console.log ("Palette NCM $"+s.toString(16)+":   " + (sortedArray[s].map(a => a.toString(16).padStart(2,"0") )))
            }
        }

        


        paletteData.palette = palette
        paletteData.pal = pal


        //Get the color table for NCM
        charData.slices = []
        
        for(var i=0; i<charData.charColors.length ; i++) {
            for(var j=0; j<sortedArray.length; j++) {
                var colors = charData.charColors[i]
                let matches = sortedArray[j].filter(a => colors.includes(a));

                if(matches && matches.length === colors.length) {
                    charData.charColors[i] =  j << 4
                    charData.slices.push(j)

                    break
                }
            }

        }

        console.log(charData.originalPalIndex.length)

        //with the palette found and the color table and slcie array done,
        //now need to change every pixels data to 
        //reflect the new color indices changing each nybble
        for(var i=0; i<charData.originalPalIndex.length; i+=2) {

            //get old value
            let orig = charData.originalPalIndex[i]
            //find its new index
            var s= charData.slices[Math.floor(i/128)]
            var palSlice = sortedArray[ s ]
            var index = palSlice.indexOf(orig)

            var out = index 

            //get next value
            orig = charData.originalPalIndex[i+1]
            //find its new index
            s= charData.slices[Math.floor(i/128)]
            palSlice = sortedArray[ s ]
            index = palSlice.indexOf(orig)

            out += (index  <<4)

            charData.data[Math.floor(i/2)] = out
        }
        

        

        //return a palette
        return {paletteData, sortedArray, charColors: charData.charColors}
}




function nswap(a) {
    return (((a & 0xf) << 4) | ((a >> 4) & 0xf))
}


function getCols(data) {
    var cols = []
    for (var j = 0; j < data.length; j++) {
        if (cols.indexOf(data[j]) === -1 && data[j] !== 0) {
            cols.push(data[j])
        }
    }
    return cols
}




////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////





async function runCharMapper(argv) {
    
    let outputPath = setOutputPath(argv.output)
    let inputName = path.parse(argv.input).name
	let png = await getPngData(argv.input)

    let pal = null

    let paletteData = getPaletteData(png)
    let charData = null
    if(argv.fcm) {
        convertedPal = paletteData.pal
        charData = getFCMData(png, paletteData.palette)
    }
    if(argv.ncm) {
        charData = getNCMData(png, paletteData.palette)
        sortedPalette = sortNCMPalette(charData, paletteData)
        paletteData = sortedPalette.paletteData

        convertedPal = paletteData.pal

        //save NCM color table
        fs.writeFileSync(path.resolve(outputPath, inputName+"_ncm.bin"), Buffer.from(sortedPalette.charColors))
    }


    //SAVE PALETTE
    fs.writeFileSync(path.resolve(outputPath, inputName+"_palette.bin"), Buffer.from(convertedPal.r.concat(convertedPal.g).concat(convertedPal.b)))

    //SAVE CHARS
    fs.writeFileSync(path.resolve(outputPath, inputName+"_chars.bin"), Buffer.from(charData.data))
}

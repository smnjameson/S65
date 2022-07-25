const META_VERSION = 1

const PNG = require('pngjs/browser').PNG;
const fs = require('fs');
const path = require('path');
const yargs = require('yargs/yargs')
const { hideBin } = require('yargs/helpers')
const argv = yargs(hideBin(process.argv))
		.command('chars', 'Convert an image to chars', () => {}, (argv) => {
    		runCharMapper(argv)
    	})
        .command('sprites', 'Convert an image to sprites', () => {}, (argv) => {
            runSpriteMapper(argv)
        })   
        .option('input', {
            alias: 'i',
            description: 'The path to the PNG file - eg: ./images/myimage.png',
            type: 'string',
        })
        .option('output', {
            alias: 'o',
            description: 'Folder to output files to - eg: ./output',
            type: 'string',
        })
        .option('palette', {
            alias: 'p',
            description: 'if provided this is the path to the palette which will be prepended to the one created',
            type: 'string',
        })  
        .option('nofill', {
            alias: 'l',
            description: 'if provided the palette will not be padded out to 256 colors, useful for appending with --palette option',
            type: 'boolean',
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
        // .option('dedupe', {
        //     alias: 'd',
        //     description: 'Remove duplicate chars when getting char data',
        //     type: 'boolean',
        // })


        .help()
        .alias('help', 'h')
        .argv;






async function getPngData(pathName) {
    console.log(`============================`)
    console.log(`Parsing ${pathName}`)
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


function sortFCMDataForSprites(png, sw, sh, palette, charData, isSprite) {
        let spriteData = {}
        let charNewData = []



        let mult = isSprite ? 2 : 1

        let numSprites = (png.width / (sw*8*mult))  * (png.height / (sh*8))
        let spritesPerRow = (png.width / (sw*8*mult))
        let spritesPerCol = (png.height / (sh*8))
        
        spriteData.metaversion = META_VERSION
        spriteData.numsprites = numSprites
        spriteData.spritewidth = sw
        spriteData.spriteheight = sh
        spriteData.charindices = [] 
        spriteData.colors = [] 

        //keep track of the current char index as we go
        let charIndex = 0x0000
        for(var s = 0; s<numSprites; s++) {
                // console.log(index)
            spriteData.charindices.push(charIndex+1)
            
            for(var sx=0; sx<sw; sx++){
                for(var j=0; j<64;j++) charNewData.push(0)
                charIndex++

                for(var sy=0; sy<sh; sy++){
                  


                    var index = (png.width/8) * (Math.floor(s / spritesPerRow) + sy) //8 = char width
                    index += (s % spritesPerRow) + sx
                    index *= 64

                    // let index = sy * (png.width / 16) + sx + s*sw
                    // index *=64
                    // console.log(index)

                    for(var y=0; y<8; y++) {
                        for(var x=0; x<8; x++) { //8 = char width
                            let i = (index + ((y * 8) + x ))//
                            // let i = index + y * (png.width / 16) + x 
                            // i *=64
                             // let i = ((y + sy) * (png.width / 16) + x + sx 

                            charNewData.push(charData.data[i])
                        }
                    }  
                    charIndex++    
                }
            }
        }
        for(var j=0; j<64;j++) charNewData.push(0)

        return {    data:charNewData, 
                    charColors:charData.charColors, 
                    originalPalIndex: charData.originalPalIndex,
                    spriteData}
}




function sortNCMDataForSprites(png, sw, sh, palette, charData) {
        let spriteData = {}

        let numSprites = (png.width / (sw*16))  * (png.height / (sh*8))
        let spritesPerRow = (png.width / (sw*16))
        let spritesPerCol = (png.height / (sh*8))
        
        let charNewData = []

        spriteData.metaversion = META_VERSION
        spriteData.numsprites = numSprites
        spriteData.spritewidth = sw
        spriteData.spriteheight = sh
        spriteData.charindices = [] 
        spriteData.colors = [] 

        //keep track of the current char index as we go
        let charIndex = 0x0000

        for(var s = 0; s<numSprites; s++) {
            spriteData.charindices.push(charIndex+1)
            


            for(var sx=0; sx<sw; sx++){
                for(var j=0; j<64;j++) charNewData.push(0)
                charIndex++

                for(var sy=0; sy<sh; sy++){

                    var id = s * (sw * sh) + (sx + sy * sw) 

                    var index = (png.width/8) * (Math.floor(s / spritesPerRow) + sy) //8 = char width
                    index += (s % spritesPerRow) + sx

                    index = id
                    index *= 64

                    for(var y=0; y<8; y++) {
                        for(var x=0; x<8; x++) { //8 = char width
                            let i = (index + ((y * 8) + x ))//
                            charNewData.push(charData.data[i])

                            if(y|x|sx|sy===0) {
                                spriteData.colors.push(charData.slices[i])
                            }
                        }
                    }  
                    charIndex++;    
                }
            }
        }
        for(var j=0; j<64;j++) charNewData.push(0)


        return {    data:charNewData, 
                    charColors:charData.charColors, 
                    originalPalIndex: charData.originalPalIndex,
                    spriteData}
}



function getNCMData(png, palette, wid, hei) {
    let data = []
    let charColors = []
    let originalPalIndex = []

    for(var y=0; y<png.height; y+=(8 * hei)) {
        for(var x=0; x<png.width; x+=(16 * wid)) {

            let charCols = []


            for(var tx=0; tx<wid ; tx++) {
            for(var r=0; r<8 * hei; r++) {
                for(var c=0; c<16; c+=2) {

                    let i = ((y + r) * (png.width * 4) + ((x + c + tx*16) * 4))
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
                        throw(new Error(`Too many colors in this char: $${(y * hei + x * wid).toString(16)}   ${x},${y},${charCols.length}`))
                    }
                    data.push(( nyb2 << 4 ) + nyb1)
                }
            }
            }
            charCols = charCols.sort((a,b) => a-b)
            for(var k=0; k<wid*hei;k++) charColors.push(charCols)
        }
    }

    // console.log(charColors)
    // console.log("===================")
    // console.log(originalPalIndex)

    return { data, charColors, originalPalIndex }
}



function getNCMDataForSprites(png, palette, wid, hei) {
    let data = []
    let charColors = []
    let originalPalIndex = []
    let row = (png.width)

    for(var y=0; y<png.height; y+=(8 * hei)) {
        for(var x=0; x<png.width; x+=(16 * wid)) {

            let charCols = [0]

            for(var ty=0; ty<hei; ty++) {
            for(var tx=0; tx<wid; tx++) {

            for(var r=0; r<8; r++) {


                for(var c=0; c<16; c+=2) {


                    let i = ( row * (y + ty * 8 ) + (x + tx * 16) + r*row + c)//row * (y + ty * 8 + r) + (x + tx * 16 + c)

                    i *=4
                    let j = i + 4

                    //find the color
                    let col1 = palette.findIndex(a => {
                        return (
                            png.data[i+0] === a.red &&
                            png.data[i+1] === a.green &&
                            png.data[i+2] === a.blue
                        );
                    })


                    originalPalIndex.push(col1)
                    if(charCols.indexOf(col1) === -1)  charCols.push(col1)  
                    let nyb1 = charCols.indexOf(col1)
                    

                    let col2 = palette.findIndex(a => {
                        return (
                            png.data[j+0] === a.red &&
                            png.data[j+1] === a.green &&
                            png.data[j+2] === a.blue 
                        );
                    })   
                    originalPalIndex.push(col2)
                    if(charCols.indexOf(col2) === -1)  charCols.push(col2) 
                    let nyb2 = charCols.indexOf(col2)

                    //push colors in this order so they can be turned into bytes easily alter
               
                   
                    

                    // if(nyb1 > 0xf || nyb2 > 0xf) {
                    //     throw(new Error(`Too many colors in this char: $${(y * hei + x * wid).toString(16)}   ${x},${y},${charCols}`))
                    // }
                    data.push(( nyb2 << 4 ) + nyb1)
                }
            }
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


    if (palette.length <256 && !argv.nofill) {
        console.log("Padding to 256 colors")
        while(palette.length <256) { 
            palette.push({
                red: 0,
                green: 0,
                blue: 0,
                alpha: 0
            });
        }
    }
        

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
                uniques.length + out[i].length <= 16) {
                best = i 
                max = matches.length
                unq = uniques
                break;
            }
        }
        if(best === -1) {
            throw(new Error("There is not enough room in the palette to sort these colors. Trying to fit "+inp.length))
        }

        out[best] = out[best].concat(unq).sort((a,b) => a-b)
        return out
}

function sortNCMPalette(charData, paletteData, wid, hei) {
        wid = wid || 1
        hei = hei || 1
        let sortedArray = new Array(16).fill([0])

        // console.log(charData.charColors)
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
                    if(!argv.nofill) {
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
            }


            if(sortedArray[s].reduce((p, a) => p + a, 0)) {
                console.log ("Palette NCM $"+s.toString(16)+":   " + (sortedArray[s].map(a => a.toString(16).padStart(2,"0") )))
            }
        }


        if(argv.nofill) {
            for(var i=0; i<16; i++) {
                if(sortedArray[i].length === 1) break
            }
            let sliceCount = i
            pal.r.splice(i * 16, pal.r.length)
            pal.g.splice(i * 16, pal.g.length)
            pal.b.splice(i * 16, pal.b.length)
        }

        paletteData.palette = palette
        paletteData.pal = pal


        //Get the color table for NCM
        charData.slices = []

        for(var i=0; i<charData.charColors.length ; i++) {
            for(var j=0; j<sortedArray.length; j++) {
                var colors = charData.charColors[i]
                let matches = sortedArray[j].filter(a => colors.includes(a));
                // console.log(matches, colors)
                if(matches && matches.length === colors.length) {
                    charData.charColors[i] =  j << 4
                    charData.slices.push(j)

                    break
                }
            }

        }

        //with the palette found and the color table and slice array done,
        //now need to change every pixels data to 
        //reflect the new color indices changing each nybble
        for(var i=0; i<charData.originalPalIndex.length; i+=2) {

            //get old value
            let orig = charData.originalPalIndex[i]
            //find its new index
            var s= charData.slices[Math.floor(i/(128*wid*hei))]
            // console.log("CCC",i,Math.floor(i/128),charData.slices.length,s,charData.originalPalIndex.length)
            var palSlice = sortedArray[ s ]
            var index = palSlice.indexOf(orig)

            var out = index 

            //get next value
            orig = charData.originalPalIndex[i+1]
            //find its new index
            s= charData.slices[Math.floor(i/(128*wid*hei))]
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


function fillPalette (palette) {
    while(palette.r.length <256) { 
        palette.r.push(0);
        palette.g.push(0);
        palette.b.push(0);
    }
    
    return palette
}


function appendPaletteFCM(palette, charData) {
    let existingPalette = []
    let data = charData.data 
    let spriteData = charData.spriteData

    existingPalette = fs.readFileSync(path.resolve(argv.palette), null)
        
    let pal = { r: [], g: [], b: [] }
    var numCols = existingPalette.length/3
    let startIndex = Math.ceil(numCols / 16) * 16

    

    //put existing palette in place
    for(var i=0; i<startIndex; i++) {
        if(i<numCols) {
            pal.r.push(existingPalette[i + numCols*0])
            pal.g.push(existingPalette[i + numCols*1])
            pal.b.push(existingPalette[i + numCols*2])
        } else {
            pal.r.push(0)
            pal.g.push(0)
            pal.b.push(0)            
        }
    }
    //now check every char and add a new color offset
    let cnt = 0
    for(var i=0; i< data.length; i++) {
        //push new color onto palette
        if(data[i] != 0) {
            let col = -1
            for(var j=0; j<pal.r.length; j++) {
                if( pal.r[j] === palette.r[data[i]] &&
                    pal.g[j] === palette.g[data[i]] &&
                    pal.b[j] === palette.b[data[i]]) {
                    col = j
                }
            }
            let newVal = 0
            if(col>=0) {
                newVal = col  
            } else {
                if(data[i] !== 0) {
                    cnt++
                    newVal = pal.r.length
                    pal.r.push( palette.r[data[i]] )
                    pal.g.push( palette.g[data[i]] )
                    pal.b.push( palette.b[data[i]] )
                }
            }
            if(data[i] !== 0) data[i] = newVal
        } else {
            
        }

    }
    console.log(`Palette append: Existing ${numCols} from  ${startIndex} plus ${cnt} new colors`)
    return {pal, data}
}


function appendPaletteNCM(palette, charData) {
    let existingPalette = []
    let data = charData.data 
    let spriteData = charData.spriteData

    existingPalette = fs.readFileSync(path.resolve(argv.palette), null)
        
    let pal = { r: [], g: [], b: [] }
    var numCols = existingPalette.length/3
    let startIndex = Math.ceil(numCols / 16) * 16

    console.log(`Palette append: Existing ${numCols} from  ${startIndex}`)

    //put existing palette in place
    for(var i=0; i<startIndex; i++) {
        if(i<numCols) {
            pal.r.push(existingPalette[i + numCols*0])
            pal.g.push(existingPalette[i + numCols*1])
            pal.b.push(existingPalette[i + numCols*2])
        } else {
            pal.r.push(0)
            pal.g.push(0)
            pal.b.push(0)            
        }
    }

    for(var i=0; i<palette.r.length; i++) {
            pal.r.push(palette.r[i])
            pal.g.push(palette.g[i])
            pal.b.push(palette.b[i])        
    }

    for(var i=0; i<spriteData.colors.length; i++) {
        spriteData.colors[i] += startIndex/16
    }
    //now check every char and add a new color offset
    // let cnt = 0
    // for(var i=0; i< data.length; i++) {
    //     if(data[i] !== 0) data[i] = newVal
    // }
    pal.r.splice(256,pal.r.length)
    pal.g.splice(256,pal.g.length)
    pal.b.splice(256,pal.b.length)
    return {pal, data, spriteData}
}
////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////





async function runCharMapper(argv) {
    
    let outputPath = setOutputPath(argv.output)
    let inputName = path.parse(argv.input).name
	let png = await getPngData(argv.input)

    if(png.height % 8 !== 0)  throw(new Error(`Your input image's height is not a multiple of 8, it is ${png.height}`))
    if(png.width % 8 !== 0 && argv.fcm)  throw(new Error(`Your input image's width is not a multiple of 8, it is ${png.width}`))
    if(png.width % 16 !== 0 && argv.ncm)  throw(new Error(`Your input image's width is not a multiple of 16, it is ${png.width}`))

    let pal = null
    let paletteData = getPaletteData(png)
    let charData = null
    if(argv.fcm) {
        convertedPal = paletteData.pal
        charData = getFCMData(png, paletteData.palette)
    }

    if(argv.ncm) {
        charData = getNCMData(png, paletteData.palette, 1, 1)
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



async function runSpriteMapper(argv) {
    
    let outputPath = setOutputPath(argv.output)
    let inputName = path.parse(argv.input).name
    let png = await getPngData(argv.input)

    if(!argv.size) throw(new Error(`You must supply a sprite size using --size pxWidth,pxHeight`))
    if(!argv.size) throw(new Error(`You must supply a sprite size using --size pxWidth,pxHeight`))
 
    let spriteWidth = 0
    let spriteHeight = 0
    try {
        let size = argv.size.split(",")
        spriteWidth = parseInt(size[0], 10)
        spriteHeight = parseInt(size[1], 10)
        if(spriteHeight % 8 !== 0)  throw(new Error(`Your sprite height is not a multiple of 8, it is ${spriteHeight}`))
        if(spriteWidth % 8 !== 0 && argv.fcm)  throw(new Error(`Your sprite width is not a multiple of 8, it is ${spriteWidth}`))
        if(spriteWidth % 16 !== 0 && argv.ncm)  throw(new Error(`Your sprite width is not a multiple of 16, it is ${spriteWidth}`))  

        if(png.width % spriteWidth !== 0 && argv.fcm)  throw(new Error(`Your input image width is not a multiple of sprite width, it is ${spriteWidth}:${png.width}`))
        if(png.height % spriteHeight !== 0 && argv.ncm)  throw(new Error(`Your input image height is not a multiple of sprite height, it is ${spriteHeight}:${png.height}`))           

    } catch(e) {
        throw(new Error(`Invalid sprite size parameter. Please use the format --size pxWidth,pxHeight`))
    }
    if(png.height % 8 !== 0)  throw(new Error(`Your input image's height is not a multiple of 8, it is ${png.height}`))
    if(png.width % 8 !== 0 && argv.fcm)  throw(new Error(`Your input image's width is not a multiple of 8, it is ${png.width}`))
    if(png.width % 16 !== 0 && argv.ncm)  throw(new Error(`Your input image's width is not a multiple of 16, it is ${png.width}`))


    let pal = null

    let paletteData = getPaletteData(png)
    let charData = null
    let spriteData = null

    console.log("paletteData.pal.length "+paletteData.pal.r.length)
    if(argv.fcm) {
        console.log("Building sprites in FCM mode")

        convertedPal = paletteData.pal
        charData = getFCMData(png, paletteData.palette)
        charData = sortFCMDataForSprites(png, spriteWidth/8, spriteHeight/8,  paletteData.palette, charData)
    }

    if(argv.ncm) {
        console.log("Building sprites in NCM mode")

        charData = getNCMDataForSprites(png, paletteData.palette, spriteWidth/16, spriteHeight/8)
        sortedPalette = sortNCMPalette(charData, paletteData, spriteWidth/16, spriteHeight/8)
        charData = sortNCMDataForSprites(png, spriteWidth/16, spriteHeight/8,  paletteData.palette, charData, false)

        convertedPal = paletteData.pal
    }


    if(argv.nofill) {
        console.log("NOFILL")
    }


    if(argv.palette) {
        let appendPal = null
        if(argv.ncm) {
            appendPal = appendPaletteNCM(convertedPal, charData)
        } else {
            appendPal = appendPaletteFCM(convertedPal, charData)
        }
        if(!argv.nofill) {
            convertedPal = fillPalette(appendPal.pal)
        }  else {
            convertedPal = appendPal.pal
        }
        charData.data = appendPal.data 
        if(argv.ncm) charData.spriteData = appendPal.spriteData
    }
    
    console.log("New palette size = "+convertedPal.r.length)


    //SAVE META
    let meta = charData.spriteData 
    let metaBuffer = []
    metaBuffer.push(
        meta.metaversion & 0xff,
        argv.ncm ? 0x01 : 0x00,
        meta.numsprites & 0xff,
        (meta.numsprites >> 8) & 0xff, 
        meta.spritewidth & 0xff, 
        meta.spriteheight & 0xff, 
        0,0,0,0,0,0,0,0,0,0,
        0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
    ) 
    metaBuffer = metaBuffer.concat(meta.charindices.map(a => a & 0xff))
    metaBuffer = metaBuffer.concat(meta.charindices.map(a => (a>>8) & 0xff))
    if(argv.ncm) metaBuffer = metaBuffer.concat(meta.colors.map( a=> a << 4))


    fs.writeFileSync(path.resolve(outputPath, inputName+"_meta.bin"), Buffer.from(metaBuffer))
    
    


    //SAVE PALETTE
    fs.writeFileSync(path.resolve(outputPath, inputName+"_palette.bin"), Buffer.from(convertedPal.r.concat(convertedPal.g).concat(convertedPal.b)))
    
    
    //SAVE CHARS
    fs.writeFileSync(path.resolve(outputPath, inputName+"_chars.bin"), Buffer.from(charData.data))
}
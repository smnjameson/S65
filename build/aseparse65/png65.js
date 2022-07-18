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

function getPaletteData(png) {
    let palette = [];
    for (var c = 0; c < png.palette.length; c++) {
    	let color = png.palette[c]
        let pal = {
            red: color[0],
            green: color[1],
            blue: color[2],
            alpha: color[3],
            useCount: 0,
            originalIndex: palette.length
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
    for(var y=0; y<png.height; y+=8) {
        for(var x=0; x<png.width; x+=16) {
            let charCols = []
            for(var r=0; r<8; r++) {
                for(var c=0; c<16; c+=2) {
                    let i = ((y + r) * (png.width * 4) + ((x + c) * 4))
                    let j = ((y + r) * (png.width * 4) + ((x + c + 1) * 4))

                    let byte = 0x00

                                
                    //find the color
                    let col1 = palette.findIndex(a => {
                        return (
                            png.data[i+0] === a.red &&
                            png.data[i+1] === a.green &&
                            png.data[i+2] === a.blue &&
                            png.data[i+3] === a.alpha
                        );
                    })
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
                    if(charCols.indexOf(col2) === -1)  charCols.push(col2) 
                    let nyb2 = charCols.indexOf(col2)

                    if(nyb1 > 0xf || nyb2 > 0xf) {
                        throw(new Error(`Too many colors in this char: $${data.length.toString(16)}`))
                    }
                    data.push((nyb2 << 4) | nyb1)
                }
            }
            charCols = charCols.sort((a,b) => a-b)
            charColors.push(charCols)
        }
    }

    return { data, charColors }
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
        convertedPal = paletteData.pal
        charData = getNCMData(png, paletteData.palette)
    }

    

        

    //SAVE PALETTE
    fs.writeFileSync(path.resolve(outputPath, inputName+"_palette.bin"), Buffer.from(convertedPal.r.concat(convertedPal.g).concat(convertedPal.b)))

    //SAVE CHARS
    fs.writeFileSync(path.resolve(outputPath, inputName+"_chars.bin"), Buffer.from(charData.data))
}
/*

    //Tile details
    let tw = 1
    let th = 2
    let charbase = parseInt(argv.charbase / 64) || 0
    let tilebase = parseInt(argv.tilebase) || 0


    //Process layers into chars and tiles
    for (var frame = 0; frame < aseFile.frames.length; frame++) {
        console.log("\nPROCESSING " + aseFile.frames[frame].cels.length + " cel arrays from frame #" + frame)

        for (var lyr = 0; lyr < aseFile.frames[frame].cels.length; lyr++) {
            mapdata[lyr + "-" + frame] = []

            let layer = aseFile.layers[lyr]
            let cels = aseFile.frames[frame].cels[lyr]


            let w = cels.w + cels.xpos;
            let h = cels.h + cels.ypos;

            let tilewidth = 16;
            mapdimensions[lyr + "-" + frame] = [(w / tilewidth), (h / 8)]

            console.log("____________________________________");
            console.log("\\____ Layer #" + lyr + " - " + layer.name + " Frame #" + frame);
            console.log("   \\___ Dimensions " + w + " x " + h);
            console.log("    \\__ Map " + (w / tilewidth / tw) + " x " + (h / 8 / th));
            console.log("     \\_ Processing cels @" + cels.xpos + "," + cels.ypos + "   tile width: " + tilewidth)

            let tiledata = getTilesFromCels(cels, palette, chars, !argv.nodedupe)

            mapdata[lyr + "-" + frame] = tiledata.mapdata
            // console.log("      \\___ Offset char  = " + offset)
            console.log("       \\__ Total char count = " + tiledata.totalCount)
            console.log("        \\_ Deduped char count = " + tiledata.dedupedCount + "\n\n")
        }
    }



    fs.writeFileSync(path.resolve(outputPath, "palred.bin"), Buffer.from(pal.r))
    fs.writeFileSync(path.resolve(outputPath, "palgrn.bin"), Buffer.from(pal.g))
    fs.writeFileSync(path.resolve(outputPath, "palblu.bin"), Buffer.from(pal.b))
    


    ////////////////////////////////////
    // GENERATE TILESETS 
    ////////////////////////////////////
    let ccData = getCharDataFromChars(chars, p, argv.preserve)
    var chardata = ccData.chardata
    var charcols = ccData.charcols


    /////////////////////////////////////////////////////////////////////
    //If tw or th are more than 1 then start to form tiles//
    /////////////////////////////////////////////////////////////////////
    var maptiles = []
    // if(tw >1 || th > 1) {
    console.log("____________________________________");
    console.log("\\____ Tile generation @ " + tw + "x" + th);
    let count = 0

    for (var frame = 0; frame < aseFile.frames.length; frame++) {
        for (var lyr = 0; lyr < aseFile.frames[frame].cels.length; lyr++) {
            if (mapdata[lyr + "-" + frame]) {
                let data = []

                for (var y = 0; y < mapdimensions[lyr + "-" + frame][1]; y += ty) {
                    for (var x = 0; x < mapdimensions[lyr + "-" + frame][0]; x += tw) {
                        count++
                        let i = y * mapdimensions[lyr + "-" + frame][0] + x

                        let tile = {
                            data: [],
                            str: ""
                        }

                        for (var ty = 0; ty < th; ty++) {
                            for (var tx = 0; tx < tw; tx++) {
                                let off = ty * mapdimensions[lyr + "-" + frame][0] + tx
                                off = i + off

                                // console.log(mapdata[lyr][off], charcols[mapdata[lyr][off]])
                                // Old method of including color map for chars (2 bytes)
                                // tile.data.push(	mapdata[lyr+"-"+frame][off] & 0xff , 
                                // 				( (mapdata[lyr+"-"+frame][off] >> 8) & 0x0f) + 
                                // 				  (charcols[mapdata[lyr+"-"+frame][off]] & 0xf0) )


                                // New method pushes chars LSB/MSB then color slice as a third byte
                                // This allows charbase
                                tile.data.push((mapdata[lyr + "-" + frame][off] + charbase) & 0xff,
                                    (((mapdata[lyr + "-" + frame][off] + charbase) >> 8) & 0xff),
                                    charcols[mapdata[lyr + "-" + frame][off]]
                                );
                            }
                        }

                        tile.str = tile.data.join(",")

                        var found = -1
                        for (var j = 0; j < maptiles.length; j++) {
                            if (maptiles[j].str === tile.str) {
                                found = j
                                break
                            }
                        }
                        if (found === -1) {
                            found = maptiles.length
                            maptiles.push(tile)

                        }
                        data.push(found)
                    }
                }

                mapdata[lyr + "-" + frame] = []
                for (var i = 0; i < data.length; i++) {
                    data[i] = data[i] * (tw * th * 3) //Size of a tile
                    mapdata[lyr + "-" + frame].push((data[i] + tilebase) & 0xff, (data[i] + tilebase) >> 8)
                }

            }
        }
    }
    console.log("   \\__ Total tile count = " + count)
    console.log("    \\_ Deduped tile count = " + maptiles.length)


    maptiles = maptiles.map(a => a.data)
    maptiles = maptiles.join(",").split(",")
    fs.writeFileSync(path.resolve(outputPath, "tiles.bin"), Buffer.from(maptiles))
    fs.writeFileSync(path.resolve(outputPath, "chars.bin"), Buffer.from(chardata))


    let cData = []
    for (var frame = 0; frame < aseFile.frames.length; frame++) {
        for (var lyr = 0; lyr < aseFile.frames[frame].cels.length; lyr++) {

            if (mapdata[lyr + "-" + frame]) {
                cData = cData.concat(mapdata[lyr + "-" + frame])
                fs.writeFileSync(path.resolve(outputPath, "map_" + aseFile.layers[lyr].name + "_Frame" + (frame + 1) + ".bin"), Buffer.from(mapdata[lyr + "-" + frame]))
            }

        }
    }
    fs.writeFileSync(path.resolve(outputPath, "map_all.bin"), Buffer.from(cData))
}




























function findBestMatch(cols, p) {
    let cnt = new Array(16).fill(0)

    //Find matches in each palette slice
    for (var i = 0; i < 16; i++) {
        for (var j = 0; j < cols.length; j++) {
            if (p[i].indexOf(cols[j]) > -1) cnt[i]++
        }
        //If not enough room in palette ignore
        if ((cols.length - cnt[i] + p[i].length) > 16) {
            cnt[i] = -1
        }
    }

    var most = -1
    for (var i = 0; i < 16; i++) {
        if (cnt[i] > -1) {
            if (most === -1 || (cnt[i] > cnt[most])) {
                most = i
            }
        }
    }

    if (most !== -1) {
        for (var i = 0; i < cols.length; i++) {
            if (p[most].indexOf(cols[i]) === -1) {
                p[most].push(cols[i])
            }
        }
    } else {
        //IF MOST === -1 NOT ENOUGH PALETTE ROOM	
        console.log("ERROR PALETTE TO SMALL")
    }
    return most
}




function getCharDataFromChars(chars, p, preserve, noswap) {
    let charcols = [];
    let chardata = [];


    for (let i = 0; i < chars.length; i++) {
        let c = chars[i]
        charcols.push((c.slice << 4) + 0x0f)

        let toggle = 0;
        let data = 0
        for (var j = 0; j < c.data.length; j++) {

            let val = p[c.slice].indexOf(c.data[j])
            if (preserve) {
                val = (c.data[j] & 0x0f)
            }
            if (val < 0) val = 0
            data = data + val
            toggle++
            if (toggle === 2) {
                toggle = 0
                if (!noswap) data = nswap(data)
                chardata.push(data)
                data = 0
            } else {
                data = data << 4
            }
        }
    }
    return { charcols, chardata };
}
*/
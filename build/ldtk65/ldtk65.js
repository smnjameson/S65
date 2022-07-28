const fs = require('fs');
const path = require('path');
const yargs = require('yargs/yargs')
const { hideBin } = require('yargs/helpers')

const argv = yargs(hideBin(process.argv))
        .option('input', {
            alias: 'i',
            description: 'The path to the PNG file - eg: ./maps/mymap.ldtk',
            type: 'string',
        })
        .option('output', {
            alias: 'o',
            description: 'Folder to output files to - eg: ./output',
            type: 'string',
        })                
        .option('fcm', {
            alias: 'f',
            description: 'use input png file is for FCM',
            type: 'boolean',
        })     
        .option('ncm', {
            alias: 'n',
            description: 'the input png file is for NCM',
            type: 'boolean',
        })                   
        .help()
        .alias('help', 'h')
        .argv;


if(!argv.ncm && !argv.fcm) {
    throw new Error("You must provide a char mode, --ncm or --fcm")
}







let ldtk = fetchLDTKFile(argv.input)
let tiles = fetchTiles(ldtk)
saveTiledefs(tiles)

let map = fetchMap(ldtk)
saveMap(map)

function fetchLDTKFile(filename) {
    var data = fs.readFileSync(path.resolve(filename));
    try {
        return JSON.parse(data)
    } catch(e) {
        throw new Error("Could not parse the LDTK file "+filename+" Is this an LDTK file????")
    }
}

function fetchTiles(ldtk) {
    let tileset = ldtk.defs.tilesets[0]
    let wid = tileset.pxWid
    let hei = tileset.pxHei
    let size = tileset.tileGridSize

    //create  tile definitions
    let tiles = []
    let rowsize = wid / size
    let charsPerRow = wid / (argv.ncm ? 16 : 8)
    let tileCount = (wid/size) * (hei/size) 

    for(var t=0; t<tileCount; t++) {
        let base = Math.floor(t / rowsize) * (wid/16) * (size/8) + (t%rowsize) * (size/16)
        
        let tile = []
        for(var y=0; y<size /8; y++) {
            for(var x=0; x< size/(argv.ncm ? 16 : 8); x++) {
                tile.push(base + x + y * charsPerRow)
            }
        }
        tiles.push(tile)
        // console.log(t, tile.map( a=> "$"+a.toString(16).padStart(4,'0')))
    }
    return tiles
}


function saveTiledefs(tiles) {
    let basename = path.basename(argv.input)
    let ext = path.extname(argv.input)
    let name = basename.substring(0,basename.length - ext.length)

    let out = []
    for(var i=0; i<tiles.length; i++) {
        for(var j=0; j<tiles[i].length; j++) {
            out.push(tiles[i][j] & 0xff)
            out.push((tiles[i][j] >> 8) & 0xff)
        }
    }
    fs.writeFileSync(path.resolve(argv.output, name+"_tiles.bin"), Buffer.from(out))
}


function fetchMap(ldtk)  {
    let map = []
    let data = ldtk.levels[0].layerInstances[0]
    let width = data.__cWid
    let height = data.__cHei
    let size = ldtk.defs.tilesets[0].tileGridSize

    for(var i=0; i<width; i++) map.push(new Array(height).fill(0))

    for(var i=0; i<data.gridTiles.length; i++) {
        let x=data.gridTiles[i].px[0] / size
        let y=data.gridTiles[i].px[1] / size
        map[x][y] = data.gridTiles[i].t
    }
    return {width, height, map}
}

function saveMap(map) {
    let basename = path.basename(argv.input)
    let ext = path.extname(argv.input)
    let name = basename.substring(0,basename.length - ext.length)

    let out = []
    out.push(map.width & 0xff)
    out.push((map.width >> 8) & 0xff)
    out.push(map.height & 0xff)
    out.push((map.height >> 8) & 0xff)    
    for(var y=0; y<map.height; y++) {
        for(var x=0; x<map.width; x++) {
            out.push(map.map[x][y])
        }
    }
    fs.writeFileSync(path.resolve(argv.output, name+"_map.bin"), Buffer.from(out))
}
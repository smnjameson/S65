const WebSocket = require('ws');
const fs = require('fs')
const path = require('path')
const { exec } = require("child_process");



async function pause(amount) {
    return new Promise(res => {
        setTimeout(()=> {
            res()
        }, amount)
    })
}


console.log("S65 Debugger deploy script")
var ws = new WebSocket("ws://localhost:8082");
ws.binaryType = 'arraybuffer';
ws.onopen = async () => {
    let data = null
    if(process.argv[3]) {
        data = fs.readFileSync(process.argv[3])
        await sendFilesToSD(process.argv[3])
    } else {
        data = fs.readFileSync(process.argv[2])
    }
    console.log("Launching application...")
    ws.send(data);
    ws.onmessage = function(message) {
        ws.close()
    };    
    ws.onclose = () => {
        process.exit(1)
    }
}


async function sendFilesToSD(prgname) {
    let sdcardPath = path.resolve(path.dirname(prgname), "./sdcard")

    return new Promise(res => {
        fs.readdir(sdcardPath, async (err, files) => {
            console.log(sdcardPath, files)
            if(files) {
                ws.send("RESET")
                await pause(3000)

                ws.send("DROPCOM")
                await pause(2000)
      
                await sendFiles(sdcardPath, files)
                
                ws.send("CONNECT")
                await pause(2000)

                res()

            } else {
                res()
            }          
        });
      
    })
 
}

async function sendFiles(fpath, files) {
    let BATCH_SIZE = 8
    
    for(var i=0; i<files.length; i+=BATCH_SIZE) {
        await new Promise(res => {
            let cmd = path.resolve(__dirname, "../", "mega65_ftp.exe") 
            
            
            let commands = ``
            for(var j=0; j<BATCH_SIZE; j++) {
                if(i+j < files.length) {
                    let src = path.resolve(fpath, files[i+j]) 
                    console.log("Uploading "+src)
                    commands += `-c "put ${src} ${files[i+j]}" `
                }
            }
           
            let proc = exec(`${cmd} -l${process.argv[2]} ${commands} -c "quit"`, 
            (error, stdout, stderr) => {
                if (error) {
                    console.log(`error: ${error.message}`);
                    return;
                }
                if (stderr) {
                    console.log(`stderr: ${stderr}`);
                    return;
                }
                console.log(`stdout: ${stdout}`);
            });

            proc.on('exit', async () => {
                // await pause(15000)
                res()
            })
            
        })
    }
}
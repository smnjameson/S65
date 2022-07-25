
const fs = require('fs');
const path = require('path');
const readline = require('readline');

const inputPath = process.argv.slice(2)[0];
const outputPath = process.argv.slice(2)[1];
let globalNamespace = '';

//make directory if not there
try {
	fs.mkdirSync( path.resolve(outputPath))
} catch(e) {}



let currentComment = emptyComment();
let commentStack = []
let currentType = null;
let comments = {
	"Global": emptyCategory()
};

let openCount = 0
let cssData = null

let completions = {
	"scope": "source.assembly.kickassembler",
	"completions": []
}

let keywords = []
let funcs=[]
let macs=[]
let vars=[]
let structkeys = []

//fetch css first
fs.readFile('./build/theme.css', {}, (err, data)=> {
	cssData = data.toString()
	parseFile(inputPath)
})

function parseFile(filename) {
	openCount++;
	var currentComment = null;

	var lineReader = readline.createInterface({
	  	input: fs.createReadStream(path.resolve(filename))
	});

	onLine = onLine.bind(this)
	onClose = onClose.bind(this)

	lineReader.on('line', onLine)
	lineReader.on('close', onClose)

}



function emptyCategory() {
	return {
		name: "",
		description: "",
		macro: [],
		pseudocommand: [],
		list: [],
		hashtable: [],
		function:[],
		data: [],
		var: []
	};
}

function emptyComment() {
	return {
		name: "",
		text: "",
		type: "",
		support: "",
		category: null,
		description: "",
		registers:[],
		flags:[],
		params: [],
		returns: [],
		retval: [],
	};
}

function makeTable(arr, size) {
	if(arr.length === 0) return '';
	size = size || 5
	let html =`
		<table><th></th><tr style="display:inline-block;">
	`;
	for(var i=0; i<arr.length; i++) {
		html += `
			<td >${arr[i]}</td>
		`;
	}

	html += `
		</tr></table>
	`;
	return html;
}

function checkForLinks(category, param) {
	if(param.type === '{hashtable}') {
		return `
			<a href='#${category || globalNamespace}_${param.name}'>${param.name}</a>
		`;
	} else {
		return param.name
	}
}

function addParams(trim, structName) {
	let type = trim.shift()
	let name = trim.shift()
	let support = ''
	if(name.trim().substr(0,1) === '{') {
		support = name
		name = trim.shift()
	}
	if(type.indexOf('?') > -1) {
		type = type.substr(0,type.indexOf('?')) + type.substr(type.indexOf('?') + 1)
		type = '<small><i>optional</i></small>'+type
	}
	let description = trim.join(' ')

	
	if(structName) {
		structkeys.push(name)
		completions.completions.push({
            "trigger": name,
            "annotation": `${structName}`,
            "kind": "snippet"
		})	
	}

	currentComment.params.push({
		type,
		name,
		description,
		support
	})	


}

function addReturnVals(trim) {
	let type = trim.shift()
	let description = trim.join(' ')

	currentComment.retval.push({
		type,
		description
	})
}

function addReturns(trim) {
	let type = trim.shift()
	let name = trim.shift()
	let description = trim.join(' ')

	currentComment.returns.push({
		type,
		name,
		description,
	})
}

function createButtons(cat) {
	let btns = `<span class='sectionButtonContainer'>`
	if(cat.pseudocommand.length) btns += `<a style='text-decoration:none;' href='#${(cat.name || "Global")}_Pseudocommands'><div class='sectionButton'>Pseudocommands</div></a>`
	if(cat.macro.length) btns += `<a style='text-decoration:none;' href='#${(cat.name || "Global")}_Macros'><div class='sectionButton'>Macros</div></a>`
	if(cat.function.length) btns += `<a style='text-decoration:none;' href='#${(cat.name || "Global")}_Functions'><div class='sectionButton'>Functions</div></a>`
	if(cat.data.length) btns += `<a style='text-decoration:none;' href='#${(cat.name || "Global")}_Data'><div class='sectionButton'>Data</div></a>`
	if(cat.var.length) btns += `<a style='text-decoration:none;' href='#${(cat.name || "Global")}_Vars'><div class='sectionButton'>Vars</div></a>`
	if(cat.list.length) btns += `<a style='text-decoration:none;' href='#${(cat.name || "Global")}_Lists'><div class='sectionButton'>Lists</div></a>`
	if(cat.hashtable.length) btns += `<a style='text-decoration:none;' href='#${(cat.name || "Global")}_Hashtables'><div class='sectionButton'>Hashtables</div></a>`


	btns += `</span>`
	return btns
}

function onLine(line) {
  	let trim = line.trim();
  	trim = trim.replace(/\s\s+/g, ' ');

  	if(currentComment !== null) {
  		currentComment.text += line + '\n'

  		//Close comment
  		if(trim.substr(0,2) == "*/") {
  			if(currentComment.type === "namespace") {
  				comments[currentComment.name] = comments[currentComment.name] || emptyCategory()
  				comments[currentComment.name].name = currentComment.name
  				comments[currentComment.name].description = currentComment.description
  				currentComment = null 
  			} else {
  	  			comments[currentComment.category || "Global"][currentComment.type].push(currentComment)
  				currentComment = null 			
  			}
	

  		//Object type and name
  		} else if(trim.substr(0,3) == "* .") {
  			//If already comment open push it and add new object
  			if(currentComment.type !== "") {
  				 if(currentComment.type === "namespace") {
  				 	let cat = currentComment.name
	  				comments[currentComment.name] = comments[currentComment.name] || emptyCategory()
	  				comments[currentComment.name].name = currentComment.name
	  				comments[currentComment.name].description = currentComment.description
	  				currentComment = emptyComment()
	  				currentComment.category = cat
	  			} else {
	  				let cat = currentComment.category
	  			  	comments[cat || "Global"][currentComment.type].push(currentComment)
	  			  	
	  				currentComment = emptyComment()
	  				currentComment.category =  cat
	  				
  				}
  			}
  			trim = trim.substr(3).split(" ")

  			if(trim[0] === "global") {
  				globalNamespace = trim[1]
  				currentComment = comments["Global"]
  				currentComment.type = 'namespace'
  				currentComment.category = 'Global'
  				currentComment.name = 'Global'
  			} else {
  				currentComment.type = trim[0]
  				currentComment.name = trim.slice(1).join(" ")
  			}

  		//Object category
  		} else if(trim.substr(0,12) == "* @namespace") {
  			trim = trim.substr(12).trim()
  			if(trim === globalNamespace) trim = 'Global'
  			currentComment.category = trim
			comments[currentComment.category] = comments[currentComment.category] || emptyCategory()

	  		//Object macro params
	  		} else if(trim.substr(0,8) == "* @param") {
	  			trim = trim.substr(8).trim().split(" ")
	  			addParams(trim)

	  		//Object macro params
	  		} else if(trim.substr(0,7) == "* @item") {
	  			trim = trim.substr(7).trim().split(" ")
	  			addParams(trim)

	  		//Object hashtable keys
	  		} else if(trim.substr(0,6) == "* @key") {
	  			trim = trim.substr(6).trim().split(" ")
	  			addParams(trim)

	  		//Object data addr
	  		} else if(trim.substr(0,7) == "* @addr") {
	  			trim = trim.substr(7).trim().split(" ")
	  			addParams(trim)


	  		//Object register effects
	  		} else if(trim.substr(0,12) == "* @registers") {
	  			trim = trim.substr(12).trim()
	  			currentComment.registers = trim.split('')

	  		//Object flag effects
	  		} else if(trim.substr(0,8) == "* @flags") {
	  			trim = trim.substr(8).trim()
	  			currentComment.flags = trim.split('')

	  		//Object returns effects
	  		} else if(trim.substr(0,9) == "* @setreg") {
	  			trim = trim.substr(9).trim().split(" ")
	  			addReturns(trim)

	  		//Object returns effects
	  		} else if(trim.substr(0,10) == "* @returns") {
	  			trim = trim.substr(10).trim().split(" ")
	  			addReturnVals(trim)

	  		//Struct info
	  		} else if(trim.substr(0,9) == "* @struct") {
	  			trim = trim.substr(9).trim().split(" ")
	  			addParams(trim, currentComment.category+"_"+currentComment.name)


  		//ignore unknown tags
  	  	} else if(trim.substr(0,3) == "* @") {
  		//Otherwise assume part of the description
  		} else {
  			currentComment.description += trim.substr(2) + " "
  		}


  	} else if(trim.substr(0,9) == "#import \"") {
  		var filepath = trim.substr(9, trim.length-10)
  		parseFile(path.resolve( '.', filepath))
  		console.log("Importing "+filepath)
  		

  	} else if(trim.substr(0,3) == '/**') {
  		//New comment
  		currentComment = emptyComment()
  	}

}


function onClose(line){
	openCount--;
	if(openCount > 0) return

	//Generate HTML
	let html = `
		<html>
		<head>
			<style>${cssData}</style>
		</head>
		<body>
	`;



	let lastCategory = ""
	let sortedCategorys = Object.keys(comments).sort();
	let idx = sortedCategorys.indexOf('Global')
	let cat  = sortedCategorys.splice(idx, 1)
	sortedCategorys.unshift(cat)


	html += `
		<table><th></th><tr><td style="vertical-align:top;width:20%;">
		<div class='namespaceHeader'>Namespaces</div>

	`;

	for(var i in sortedCategorys) {
		let cat = comments[sortedCategorys[i]]
		html += `
			<div class='macroIndex'><a href='#${(cat.name || "Global")}'>${cat.name !== "Global" ? cat.name : "Global ("+globalNamespace+")" }</a></div>
		`;	
	}

	html += `
		</td><td><div style="overflow-y:scroll;height:95vh;">
	`;
	for(var i in sortedCategorys) {
		let cat = comments[sortedCategorys[i]]

		//Category Header
		html += `
			<div class='categoryHeader' id='${(cat.name || "Global")}'><span><h4>Namespace<h2>${cat.name !== "Global" ? cat.name : "Global ("+globalNamespace+")"}</h2></h4></span></div>
			${createButtons(cat)}
			<div class='categoryDescription'>${cat.description}</div>
			<br>
		`;



		if(cat.pseudocommand.length) {
			//pseudocommand header
			html += `
				<div class='macroHeader' id='${(cat.name || "Global")}_Pseudocommands'>Pseudocommands</div>
			`;	

			//pseudocommand index
			cat.pseudocommand = cat.pseudocommand.sort((a,b) => {
				return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
			})
			for(var j=0; j<cat.pseudocommand.length; j++) {
				let name = cat.pseudocommand[j].name
				
				html += `
					<div class='macroIndex'><a href='#${(cat.name || "Global") + "_" + name}'>${name}</a></div>
				`;		
			}

			//pseudocommand details
			for(var j=0; j<cat.pseudocommand.length; j++) {
				let name = cat.pseudocommand[j].name 
				let desc = cat.pseudocommand[j].description
				let registers = makeTable(cat.pseudocommand[j].registers.sort())
				let flags = makeTable(cat.pseudocommand[j].flags.sort())
				let fullcmd = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name
				let usage =  fullcmd + " "

				let paramNotes = []
				let params = ``;

				for(var k=0; k<cat.pseudocommand[j].params.length;k++) {
					usage += '<i>' + cat.pseudocommand[j].params[k].name + '</i>'
					if( k !== cat.pseudocommand[j].params.length - 1) {
						usage += " : "
					} 
					if(k === 0) {
						params += `
							<div class='macroUsageText'><i>Parameters:</i></div>
						`
					}
					params += `
						<div class='macroUsage'> 
						<span><div class='paramHeader'>${cat.pseudocommand[j].params[k].type} ${cat.pseudocommand[j].params[k].support} ${checkForLinks(cat.name,cat.pseudocommand[j].params[k])} - ${cat.pseudocommand[j].params[k].description}</div></span>
						</div>
					`;
					paramNotes.push(cat.pseudocommand[j].params[k].name)
				}

				let returns = ``
				for(var k=0; k<cat.pseudocommand[j].returns.length;k++) {
					if(k === 0) {
						returns += `
							<div class='macroUsageText'><i>Returns:</i></div>
						`
					}
					returns += `
						<div class='macroUsage'> 
						<span><div class='paramHeader'>${cat.pseudocommand[j].returns[k].type} in ${cat.name,cat.pseudocommand[j].returns[k].name} - ${cat.pseudocommand[j].returns[k].description}</div></span>
						</div>
					`;
				}


				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}
							
							<div class='macroItemSubHeader'>
								<span  style='display:inline-flex;'>${registers || flags ? "registers: " + registers + " flags: "+flags : ""}</span>
							</div>
							
						</div>
						<div class='macroItemDescription'>${desc}</div>
						<div class='macroUsageText'><i>Usage:</i></div>
						<div class='macroUsage'>${usage}</div>
						${params}
						${returns}
						
					</div>`;	

				completions.completions.push({
		            "trigger": fullcmd,

		            "annotation": `${paramNotes.map((a,i) => {
		            	return `${a.trim()}${i !== paramNotes.length - 1 ? ":" : ""}`
		            }).join('')}`,

		            "contents": `${fullcmd} ${paramNotes.map((a,i) => {
		            	return `\${${i+1}:${a.trim()}}${i !== paramNotes.length - 1 ? " : " : ""}`
		            }).join('')}`,

		            "kind": "snippet",
		            "details": `${desc.trim()}`
        		})	

        		keywords.push(fullcmd)
			}
			html += '<br>'


		}


		if(cat.macro.length) {
			//macros header
			html += `
				<div class='macroHeader' id='${(cat.name || "Global")}_Macros'>Macros</div>
			`;	

			//macros index
			cat.macro = cat.macro.sort((a,b) => {
				return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
			})
			for(var j=0; j<cat.macro.length; j++) {
				let name = cat.macro[j].name
				
				html += `
					<div class='macroIndex'><a href='#${(cat.name || "Global") + "_" + name}'>${name}</a></div>
				`;		
			}

			//macro details
			for(var j=0; j<cat.macro.length; j++) {
				let name = cat.macro[j].name 
				let desc = cat.macro[j].description
				let registers = makeTable(cat.macro[j].registers.sort())
				let flags = makeTable(cat.macro[j].flags.sort())
				var fullcmd = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name
				let usage = fullcmd + "("

				let params = ``;
				let paramNotes = []

				for(var k=0; k<cat.macro[j].params.length;k++) {
					usage += '<i>' + cat.macro[j].params[k].name + '</i>' 
					if( k !== cat.macro[j].params.length - 1) {
						usage += ", "
					} 
					if(k === 0) {
						params += `
							<div class='macroUsageText'><i>Parameters:</i></div>
						`
					}
					params += `
						<div class='macroUsage'> 
						<span><div class='paramHeader'>${cat.macro[j].params[k].type} ${checkForLinks(cat.name,cat.macro[j].params[k])} - ${cat.macro[j].params[k].description}</div></span>
						</div>
					`;
					paramNotes.push(cat.macro[j].params[k].name)
				}
				usage += ")"

				let returns = ``
				for(var k=0; k<cat.macro[j].returns.length;k++) {
					if(k === 0) {
						returns += `
							<div class='macroUsageText'><i>Sets Registers:</i></div>
						`
					}
					returns += `
						<div class='macroUsage'> 
						<span><div class='paramHeader'>${cat.name,cat.macro[j].returns[k].name} ${cat.macro[j].returns[k].type} - ${cat.macro[j].returns[k].description}</div></span>
						</div>
					`;
				}


				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}
							<div class='macroItemSubHeader'>
								<span  style='display:inline-flex;'>${registers || flags ? "registers: " + registers + " flags: "+flags : ""}</span>
							</div>
						</div>
						<div class='macroItemDescription'>${desc}</div>
						<div class='macroUsageText'><i>Usage:</i></div>
						<div class='macroUsage'>${usage}</div>
						${params}
						${returns}
						
					</div>`;	

				completions.completions.push({
		            "trigger": fullcmd,

		            "annotation": `${paramNotes.map((a,i) => {
		            	return `${a.trim()}${i !== paramNotes.length - 1 ? "," : ""}`
		            }).join('')}`,

		            "contents": `${fullcmd}(${paramNotes.map((a,i) => {
		            	return `\${${i+1}:${a.trim()}}${i !== paramNotes.length - 1 ? ", " : ""}`
		            }).join('')})`,

		            "kind": "snippet",
		            "details": `${desc.trim()}`
        		})		

        		macs.push(fullcmd)

			}
			html += '<br>'
		}

		if(cat.function.length) {
			//function header
			html += `
				<div class='macroHeader' id='${(cat.name || "Global")}_Functions'>Functions</div>
			`;	

			//function index
			cat.function = cat.function.sort((a,b) => {
				return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
			})
			for(var j=0; j<cat.function.length; j++) {
				let name = cat.function[j].name
				
				html += `
					<div class='macroIndex'><a href='#${(cat.name || "Global") + "_" + name}'>${name}</a></div>
				`;		
			}

			//function details
			for(var j=0; j<cat.function.length; j++) {
				let name = cat.function[j].name 
				let desc = cat.function[j].description
				var fullcmd = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name
				let usage = fullcmd + "("

				let params = ``;
				let paramNotes = []

				for(var k=0; k<cat.function[j].params.length;k++) {
					usage += '<i>' + cat.function[j].params[k].name + '</i>' 
					if( k !== cat.function[j].params.length - 1) {
						usage += ", "
					} 
					if(k === 0) {
						params += `
							<div class='macroUsageText'><i>Parameters:</i></div>
						`
					}
					params += `
						<div class='macroUsage'> 
						<span><div class='paramHeader'>${cat.function[j].params[k].type} ${checkForLinks(cat.name,cat.function[j].params[k])} - ${cat.function[j].params[k].description}</div></span>
						</div>
					`;
					paramNotes.push(cat.function[j].params[k].name)
				}
				usage += ")"

				let retvals = ``
				for(var k=0; k<cat.function[j].retval.length;k++) {
					if(k === 0) {
						retvals += `
							<div class='macroUsageText'><i>Returns:</i></div>
						`
					}
					retvals += `
						<div class='macroUsage'> 
						<span><div class='paramHeader'>${cat.function[j].retval[k].type} - ${cat.function[j].retval[k].description}</div></span>
						</div>
					`;
				}

				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}
						</div>
						<div class='macroItemDescription'>${desc}</div>
						<div class='macroUsageText'><i>Usage:</i></div>
						<div class='macroUsage'>${usage}</div>
						${params}
						${retvals}
						
					</div>`;	

				completions.completions.push({
		            "trigger": fullcmd,

		            "annotation": `${paramNotes.map((a,i) => {
		            	return `${a.trim()}${i !== paramNotes.length - 1 ? "," : ""}`
		            }).join('')}`,

		            "contents": `${fullcmd}(${paramNotes.map((a,i) => {
		            	return `\${${i+1}:${a.trim()}}${i !== paramNotes.length - 1 ? ", " : ""}`
		            }).join('')})`,

		            "kind": "snippet",
		            "details": `${desc.trim()}`
        		})		

        		funcs.push(fullcmd)

			}
			html += '<br>'
		}


		if(cat.data.length) {
			
			//data header
			html += `
				<div class='macroHeader' id='${(cat.name || "Global")}_Data'>Data</div>
			`;	

			//data index
			cat.data = cat.data.sort((a,b) => {
				return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
			})
			for(var j=0; j<cat.data.length; j++) {
				let name = cat.data[j].name 
				
				html += `
					<div class='macroIndex'><a href='#${(cat.name || "Global") + "_" + name}'>${name}</a></div>
				`;		
			}	
			
			//data details
			for(var j=0; j<cat.data.length; j++) {
				let name = cat.data[j].name 
				let desc = cat.data[j].description
				let params = ``;
				let usage = (cat.name || globalNamespace) + "_" + name
				var fullcmd = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name


				for(var k=0; k<cat.data[j].params.length;k++) {
					params += `
						<div class='macroUsage'>
						<span><div class='paramHeader'>${cat.data[j].params[k].type} ${checkForLinks(cat.name, cat.data[j].params[k])} - ${cat.data[j].params[k].description}</div></span>
						
						</div>
					`;
				}

				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}</div>
						<div class='macroItemDescription'>${desc}</div>
						<div class='macroUsageText'><i>Usage:</i></div>
						<div class='macroUsage'>${usage}</div>						
						${params}
					</div>`;	

				completions.completions.push({
		            "trigger": fullcmd,
		            "annotation": `${desc.trim()}`,
		            "kind": "snippet",
		            "details": `${desc.trim()}`
        		})	
			}	
			html += '<br>'
		}

		if(cat.var.length) {
			//var header
			html += `
				<div class='macroHeader' id='${(cat.name || "Global")}_Vars'>Vars</div>
			`;	
			

			//var index
			cat.var = cat.var.sort((a,b) => {
				return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
			})
			for(var j=0; j<cat.var.length; j++) {
				let name = cat.var[j].name 
				
				html += `
					<div class='macroIndex'><a href='#${(cat.name || "Global") + "_" + name}'>${name}</a></div>
				`;		
			}	
			
			//var details
			for(var j=0; j<cat.var.length; j++) {
				let name = cat.var[j].name 
				let desc = cat.var[j].description
				let usage = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name
				var fullcmd = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name

				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}</div>
						<div class='macroItemDescription'>${desc}</div>
						<div class='macroUsageText'><i>Usage:</i></div>
						<div class='macroUsage'>${usage}</div>						
					</div>`;	

				completions.completions.push({
		            "trigger": fullcmd,
		            "annotation": `${desc.trim()}`,
		            "kind": "snippet",
		            "details": `${desc.trim()}`
        		})		

        		vars.push(fullcmd)				
			}	
			html += '<br>'
		}

		if(cat.list.length) {
			//lists header
			html += `
				<div class='macroHeader' id='${(cat.name || "Global")}_Lists'>Lists</div>
			`;	

			//lists index
			cat.list = cat.list.sort((a,b) => {
				return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
			})
			for(var j=0; j<cat.list.length; j++) {
				let name = cat.list[j].name 
				
				html += `
					<div class='macroIndex'><a href='#${(cat.name || "Global") + "_" + name}'>${name}</a></div>
				`;		
			}	
			
			//list details
			for(var j=0; j<cat.list.length; j++) {
				let name = cat.list[j].name 
				let desc = cat.list[j].description
				let usage = (cat.name || globalNamespace) + "_" + name
				let params = ``;

				for(var k=0; k<cat.list[j].params.length;k++) {
					if(k === 0) {
						params += `
							<div class='macroUsageText'><i>Items:</i></div>
						`
					}
					params += `
						<div class='macroUsage'>
						<span><div class='paramHeader'>${cat.list[j].params[k].type} ${checkForLinks(cat.name, cat.list[j].params[k])} - ${cat.list[j].params[k].description}</div></span>
						</div>
					`;
				}

				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}</div>
						<div class='macroItemDescription'>${desc}</div>
						<div class='macroUsageText'><i>Usage:</i></div>
						<div class='macroUsage'>${usage}</div>
						${params}

					</div>`;	
			}	
			html += '<br>'
		}


		if(cat.hashtable.length) {
			//hashtables header
			html += `
				<div class='macroHeader' id='${(cat.name || "Global")}_Hashtables'>Hashtables</div>
			`;	

			//lists index
			cat.hashtable = cat.hashtable.sort((a,b) => {
				return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
			})
			for(var j=0; j<cat.hashtable.length; j++) {
				let name = cat.hashtable[j].name 
				
				html += `
					<div class='macroIndex'><a href='#${(cat.name || "Global") + "_" + name}'>${name}</a></div>
				`;		
			}	
			
			//hashtables details
			for(var j=0; j<cat.hashtable.length; j++) {
				let name = cat.hashtable[j].name 
				let desc = cat.hashtable[j].description
				let usage = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name
				let params = ``;

				for(var k=0; k<cat.hashtable[j].params.length;k++) {
					if(k === 0) {
						params += `
							<div class='macroUsageText'><i>Keys:</i></div>
						`
					}
					params += `
						<div class='macroUsage'>
						<span><div class='paramHeader'>${cat.hashtable[j].params[k].type} ${checkForLinks(cat.name, cat.hashtable[j].params[k])} - ${cat.hashtable[j].params[k].description}</div></span>
						</div>
					`;
				}

				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}</div>
						<div class='macroItemDescription'>${desc}</div>
						<div class='macroUsageText'><i>Usage:</i></div>
						<div class='macroUsage'>${usage}</div>
						${params}
					</div>`;	
			}	
			html += '<br>'
		}

		html += `<br>`
	}

	html += `
	</div></td></table>
	</body>
	</html>
	`
	fs.writeFile(path.resolve(outputPath, 'docs.html'), html, function (err) {
	  	if (err) return console.log(err);
	});

	fs.writeFile(path.resolve(outputPath, globalNamespace+'.sublime-completions'), JSON.stringify(completions,null, 4), function (err) {
	  	if (err) return console.log(err);
	});

	fs.writeFile(path.resolve(outputPath, globalNamespace+'.sublime-syntax'), `%YAML 1.2
---
# http://www.sublimetext.com/docs/3/syntax.html
name: KickAss S65 (Mega65) 
file_extensions:
  - .s
scope: source.assembly.kickassembler
contexts:
  main:
    - match: \\b(${keywords.join('|')})\\b
      scope: storage.type.macro
    - match: \\b(${funcs.join('|')})\\b
      scope: constant.language.pseudocommand
    - match: \\b(${macs.join('|')})\\b
      scope: support.function.3d
    - match: \\b(${vars.join('|')})\\b
      scope: constant.language.color      
    - match: '#TRUE'
      scope: constant.language.pseudocommand
    - match: '#FALSE'
      scope: constant.language.pseudocommand          
    - match: \\b(REGA|REGX|REGY|REGZ)\\b
      scope: constant.language.pseudocommand
    - match: \\b(rmb0|adc|adcq|and|andq|asl|aslq|asr|asrq|asw|bit|bitq|clc|cld|cle|cli|clv|cmp|cmpq|cpx|cpy|cpz|dec|deq|dew|dex|dey|dez|eom|eor|eorq|inc|inq|inw|inx|iny|inz|lda|ldq|ldx|ldy|ldz|lsr|lsrq|map|neg|nop|ora|orq|pha|php|phw|phx|phy|phz|pla|plp|plx|ply|plz|rmb0|rmb1|rmb2|rmb3|rmb4|rmb5|rmb6|rmb7|rol|rolq|ror|rorq|row|sbc|sbcq|sec|sed|see|sei|smb0|smb1|smb2|smb3|smb4|smb5|smb6|smb7|sta|staq|stx|stq|sty|stz|tab|tax|txa|tay|tya|tys|taz|tza|tba|trb|tsb|tsx|tsy|txs)\\b
      scope: keyword
    - match: \\b(bbr0|bbr1|bbr2|bbr3|bbr4|bbr5|bbr6|bbr7|bbs0|bbs1|bbs2|bbs3|bbs4|bbs5|bbs6|bbs7|bcc|bcs|beq|bmi|bne|bpl|bra|brk|bsr|bvc|bvs|jmp|jsr|lbcc|lbcs|lbeq|lbmi|lbne|lbpl|lbra|rti|rts)\\b
      scope: keyword.control
    - match: /\\*
      captures:
        0: punctuation.definition.comment
      push:
        - meta_scope: comment.block
        - match: \\*/\\n?
          captures:
            0: punctuation.definition.comment
          pop: true
    - match: //
      captures:
        1: punctuation.definition.comment
      push:
        - meta_scope: comment.line.double-slashs
        - match: $\\n?
          captures:
            1: punctuation.definition.comment
          pop: true
    - match: (?:^|\\s)(\\.(word|byte|text|dword))\\b
      captures:
        1: storage.type.kickass
    - match: \\b(CmdArgument)\\b
      scope: storage.type.kickass
    - match: \\b(getNamespace)\\b
      scope: support.function.language
    - match: \\b(toIntString|toBinaryString|toOctalString|toHexString)\\b
      scope: support.function.string
    - match: \\b(abs|acos|asin|atan|atan2|cbrt|ceil|cos|cosh|exp|expm1|floor|hypot|IEEEremainder|log|log10|log1p|max|min|pow|mod|random|round|signum|sin|sinh|sqrt|tan|tanh|toDegrees|toRadians)\\b
      scope: support.function.math
    - match: \\b(LoadBinary|LoadPicture|LoadSid|createFile)\\b
      scope: support.function.file
    - match: \\b(Matrix|RotationMatrix|ScaleMatrix|MoveMatrix|PerspectiveMatrix|Vector)\\b
      scope: support.function.3d
    - match: (?:^|\\s)(\\.(var|label|const|cpu))\\b
      captures:
        1: storage.type.keyword.kickass.field
    - match: (?:^|\\s)(\\.(struct|enum))\\b
      captures:
        1: keyword.kickass.function.object
    - match: (?:^|\\s)(\\.(eval|fill|lohifill|print|printnow|import|align|assert|asserterror|error))\\b
      captures:
        1: keyword.kickass.function
    - match: (?:^|\\s)(\\.(pc|importonce|pseudopc|return|eval))\\b
      captures:
        1: keyword.kickass
    - match: (?:^\\s*|;\\s*)(\\*)(?=\\s*\\=\\s*)
      captures:
        1: keyword.kickass
    - match: (?:^|\\s)(\\.(encoding))\\b
      scope: keyword.kickass.encoding
    - match: '(?:^\\s*|;\\s*)(\\#(define|elif|if|undef))\\s+(([A-Za-z_][A-Za-z0-9_]*)+)\\b'
      captures:
        1: keyword.kickass.preprocessor
        3: constant.kickass.preprocessor
    - match: (?:^\\s*|;\\s*)(\\#(else|endif|importonce))\\b
      captures:
        1: keyword.kickass.preprocessor
    - match: (?:^\\s*|;\\s*)(\\#(import))(?=\\s+\\".*\\")
      captures:
        1: keyword.kickass.preprocessor
    - match: '(?:^\\s*|;\\s*)(\\#(importif))\\s+!*(([A-Za-z_][A-Za-z0-9_]*)+)(?=\\s+\\".*\\")'
      captures:
        1: keyword.kickass.preprocessor
        3: constant.kickass.preprocessor
    - match: \\b(true|false)\\b
      scope: constant.language
    - match: \\b(BLACK|WHITE|RED|CYAN|PURPLE|GREEN|BLUE|YELLOW|ORANGE|BROWN|LIGHT_RED|DARK_GRAY|GRAY|DARK_GREY|GREY|LIGHT_GREEN|LIGHT_BLUE|LIGHT_GRAY|LIGHT_GREY)\\b
      scope: constant.language.color
    - match: \\b(LDA_IMM|LDA_ZP|LDA_ZPX|LDX_ZPY|LDA_IZPX|LDA_IZPY|LDA_ABS|LDA_ABSX|LDA_ABSY|JMP_IND|BNE_REL|RTS)\\b
      scope: constant.language.opcodes
    - match: \\b(BF_C64FILE|BF_BITMAP_SINGLECOLOR|BF_KOALA|BF_FLI)\\b
      scope: constant.language.file
    - match: \\b(AT_ABSOLUTE|AT_ABSOLUTEX|AT_ABSOLUTEY|AT_IMMEDIATE|AT_INDIRECT|AT_IZEROPAGEX|AT_IZEROPAGEY|AT_NONE|AT_IZEROPAGEZ|AT_INDIRECTX)\\b
      scope: constant.language.pseudocommand
    - match: \\b(PI|E)\\b
      scope: constant.language.math
    - match: \\b(Hashtable)\\b
      scope: storage.type.hashtable
    - match: \\b(list|List)\\(\\s*(\\$?\\d+)*\\s*\\)
      scope: list
      captures:
        1: storage.type.list
        2: variable.parameter
    - match: (?:^|\\s)(\\.for)\\s*\\((var)\\b
      captures:
        1: keyword.control.for
        2: storage.type.for
    - match: (?:^|\\s)((\\.if)\\b|(else)\\b)
      captures:
        1: keyword.control.if
    - match: (?:^|\\s)(\\.while)(?=\\s*\\(.*\\))
      captures:
        1: keyword.control.while
    - match: '"'
      push:
        - meta_scope: string.quoted.double.untitled
        - match: '"'
          pop: true
        - match: \\\\.
          scope: constant.character.escape
    - match: '(?:^\\s*|;\\s*)((\\.filenamespace)\\s*([A-Za-z_][A-Za-z0-9_]*))\\b'
      captures:
        1: meta.filenamespace.identifier
        2: keyword.type.filenamespace
        3: entity.name.filenamespace
    - match: '(?:^\\s*|;\\s*)((\\.namespace)\\s*([A-Za-z_][A-Za-z0-9_]*))\\b'
      captures:
        1: meta.namespace.identifier
        2: keyword.type.namespace
        3: entity.name.namespace
    - match: '(?:^\\s*|;\\s*)(((!)|(!?(\\@*[A-Za-z_][A-Za-z0-9_]*)+))\\:)'
      scope: label
      captures:
        1: meta.label.identifier
        2: entity.name.label
    - match: '(?:^\\s*|;\\s*)((\\.pseudocommand)\\s*(\\@*[A-Za-z_][A-Za-z0-9_]*))\\b'
      captures:
        1: meta.pseudocommand.identifier
        2: storage.type.pseudocommand
        3: entity.name.pseudocommand
    - match: '(?:|,^\\s*|;\\s*)((\\.function)\\s*(\\@*[A-Za-z0-9_]*))\\b'
      captures:
        1: meta.label.identifier
        2: storage.type.function
        3: entity.name.function
    - match: '(?:^\\s*|;\\s*)((\\.macro)\\s*(\\@*[A-Za-z_][A-Za-z0-9_]*))\\b'
      captures:
        1: meta.macro.identifier
        2: storage.type.macro
        3: entity.name.macro
    - match: '\\$\\h+'
      scope: constant.numeric.hex
    - match: '\\b\\d+'
      scope: constant.numeric.decimal
    - match: '\\%[0-1]+'
      scope: constant.numeric.binary     
`, function (err) {
	  	if (err) return console.log(err);
	});

}






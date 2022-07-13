
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
parseFile(inputPath)

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
		list: [],
		hashtable: [],
		data: [],
		var: []
	};
}

function emptyComment() {
	return {
		name: "",
		text: "",
		type: "",
		category: null,
		description: "",
		registers:[],
		flags:[],
		params: [],
	};
}

function makeTable(arr, size) {
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

function addParams(trim) {
	let type = trim.shift()
	let name = trim.shift()
	let description = trim.join(' ')

	currentComment.params.push({
		type,
		name,
		description,
	})
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
			<link rel="stylesheet" href='./theme.css'>
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
			<div class='categoryDescription'>${cat.description}</div>
			<br>
		`;

		if(cat.macro.length) {
			//macros header
			html += `
				<div class='macroHeader'>Macros</div>
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
				let usage = (cat.name !== "Global" ? cat.name : globalNamespace) + "_" + name + "("

				let params = ``;

				for(var k=0; k<cat.macro[j].params.length;k++) {
					usage += cat.macro[j].params[k].name
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
				}
				usage += ")"
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
						
					</div>`;	
			}
			html += '<br>'
		}


		if(cat.list.length) {
			//lists header
			html += `
				<div class='macroHeader'>Lists</div>
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
				<div class='macroHeader'>Hashtables</div>
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

		if(cat.data.length) {
			//data header
			html += `
				<div class='macroHeader'>Data</div>
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
						${params}
					</div>`;	
			}	
			html += '<br>'
		}




		if(cat.var.length) {
			//var header
			html += `
				<div class='macroHeader'>Vars</div>
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
				let params = ``;

				for(var k=0; k<cat.var[j].params.length;k++) {
					params += `
						<div class='macroUsage'>
						<span><div class='paramHeader'>${cat.var[j].params[k].type} ${checkForLinks(cat.name, cat.var[j].params[k])} - ${cat.var[j].params[k].description}</div></span>
						
						</div>
					`;
				}

				html += `
					<div class='macroItem'>
						<div class='macroItemHeader' id='${(cat.name || "Global") + "_" + name}'>${name}</div>
						<div class='macroItemDescription'>${desc}</div>
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
}






const path = require('path')
const fs = require('fs')
const proc = require('child_process');
const os = require('os').platform()
//Get args from CLI
let args = process.argv.slice(2);
let from = args[0]
let to = args[1]
let toFile = args[2]
let metaInfo = null
// Try to get it from installation location
if( os === 'darwin') {
  //MAC OS
  metaInfo = require(path.resolve(__dirname, '/usr/local/lib/sfdx/node_modules/salesforce-alm/metadata/describe.json'))
} else if( os === 'win32') {
  let instsfdx = proc.execSync("where sfdx", {encoding: "UTF-8"})
  console.log(instsfdx)
  instsfdx = instsfdx.substr(0, instsfdx.indexOf(path.sep + 'bin' + path.sep + 'sfdx'))
  console.log(instsfdx)
  metaInfo = require(path.join(instsfdx, 'client/node_modules/salesforce-alm/metadata/describe.json'))
}
const typeDefs = Object.values(metaInfo.metadataObjects)
//run diff and strip lines
// require('child_process').execSync("$env:LC_ALL='C.UTF-8'", {encoding: "UTF-8"})
// Set git to dont remove accents or any diacritic
console.log(` RUNNING GIT COMMANDS:
  git config core.quotepath off 
  git diff --name-only ${from} ${to}`
)
proc.execSync("git config core.quotepath off", {encoding: "UTF-8"})
//Get results
const result = proc.execSync('git diff --name-only ' + from + ' ' + to, {encoding: "UTF-8"}).toString();
let xmlMap = {}
let xmlHeader = `<?xml version="1.0" encoding="UTF-8"?>
  <Package xmlns="http://soap.sforce.com/2006/04/metadata">`
let xmlFooter = ` 
  <version>50.0</version>
</Package>`
let xmlBody = ''
//Process git diff
let lines = result.split('\n')
lines.forEach(line => {
  if(!line || line.trim() === '') return
  let parts = line.split('/')
  let folder = parts[3]
  let name
  try {
    let entry = typeDefs.find(def => def.directoryName === folder)
    if (!entry) return
    if ( entry.inFolder === 'true') {
      name = parts[4] + '/' + parts[5].split('.')[0]
    } else {
      name = parts[4].split('.')[0]
    }
    //find in typeDefs and add to map
    if(entry) {
      if(xmlMap[entry.xmlName]) {
        if(!xmlMap[entry.xmlName].has(name)) {
          xmlMap[entry.xmlName].add(name)
        }
      } else {
        xmlMap[entry.xmlName] = new Set()
        xmlMap[entry.xmlName].add(name)
      }
    }
  } catch(e) {
    console.error(e.message)
  }
})
Object.keys(xmlMap).forEach(type => {
  xmlBody += `
    <types>`
  xmlBody += [ ...xmlMap[type]].map(typeEntry => {
    return `
        <members>${typeEntry}</members>`
  }).join('')
  xmlBody += `
      <name>${type}</name>
    </types>`
})
let finalXml = xmlHeader + xmlBody + xmlFooter
//Write response
fs.writeFileSync(path.resolve(__dirname, toFile ), finalXml, 'utf8')

console.log('DONE. Check your file')
"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
let log = console.log;
const path = require("path");
const shelljs = require("shelljs");
const fs = require("fs");
let workspaceFolder = path.join(__dirname, '../');
let hdFilePath = path.join(workspaceFolder, 'src/LEECHUNG.vhd');
let nasmFilePath = path.join(__dirname, 'nasm-2.13.03/nasm.exe');
let buildPath = process.argv[2];
if (!buildPath) {
    buildPath = path.join(workspaceFolder, 'src/c07');
}
shelljs.cd(buildPath);
log('workspaceFolder:' + workspaceFolder);
log('buildPath:' + buildPath);
log('nasmFilePath:' + nasmFilePath);
log('');
const asmExt = '.asm';
const binExt = '.bin';
const listExt = '.list';
const linkFileName = 'link.json';
function getNasmArgs(fileName, ext) {
    return `${nasmFilePath} ${fileName}${ext} -o ${fileName}${binExt} -l ${fileName}${listExt}`;
}
function getExtFiles(aimExt) {
    let files = [];
    for (const fileName of shelljs.ls()) {
        let ext = path.extname(fileName);
        if (ext.toLowerCase() === aimExt) {
            let file = path.basename(fileName, ext);
            files.push([file, ext]);
        }
    }
    return files;
}
function clear() {
    const binFiles = getExtFiles(binExt);
    const listFiles = getExtFiles(listExt);
    for (const binFile of binFiles) {
        let fileName = binFile[0];
        let ext = binFile[1];
        shelljs.rm(`${fileName}${ext}`);
    }
    for (const listFile of listFiles) {
        let fileName = listFile[0];
        let ext = listFile[1];
        shelljs.rm(`${fileName}${ext}`);
    }
    log('clear ok !');
}
clear();
function compile() {
    const asmFiles = getExtFiles(asmExt);
    for (const asmFile of asmFiles) {
        let fileName = asmFile[0];
        let ext = asmFile[1];
        let cmd = getNasmArgs(fileName, ext);
        log(cmd);
        shelljs.exec(cmd);
    }
    log('compile ok !');
}
compile();
function writeToHD() {
    let configArray = [];
    if (fs.existsSync(linkFileName)) {
        configArray = JSON.parse(fs.readFileSync(linkFileName).toString());
    }
    else {
        const binFiles = getExtFiles(binExt);
        if (binFiles.length > 0) {
            configArray.push({
                name: binFiles[0][0],
                start: 0
            });
        }
    }
    const fd = fs.openSync(hdFilePath, 'r+');
    for (const config of configArray) {
        const file = `${config.name}${binExt}`;
        const start = config.start;
        const buffer = fs.readFileSync(file);
        let writeNum = fs.writeSync(fd, buffer, 0, buffer.length, start);
        if (writeNum !== buffer.length) {
            throw new Error('writeNum !== buffer.length');
        }
    }
    fs.closeSync(fd);
    log('writeToHD ok !');
}
writeToHD();
//# sourceMappingURL=build.js.map
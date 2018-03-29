"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
let log = console.log;
const path = require("path");
const shelljs = require("shelljs");
let workspaceFolder = process.argv[2];
let nasmFilePath = path.join(__dirname, 'nasm-2.13.03/nasm.exe');
let buildPath = process.argv[3];
shelljs.cd(buildPath);
log('workspaceFolder:' + workspaceFolder);
log('buildPath:' + buildPath);
log('nasmFilePath:' + nasmFilePath);
log('');
function getNasmArgs(fileName, ext) {
    return `${nasmFilePath} ${fileName}${ext} -o ${fileName}.bin -l ${fileName}.list`;
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
    const binFiles = getExtFiles('.bin');
    const listFiles = getExtFiles('.list');
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
}
clear();
function compile() {
    const asmFiles = getExtFiles('.asm');
    for (const asmFile of asmFiles) {
        let fileName = asmFile[0];
        let ext = asmFile[1];
        let cmd = getNasmArgs(fileName, ext);
        log(cmd);
        shelljs.exec(cmd);
    }
}
compile();
//# sourceMappingURL=build.js.map
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
let isDebug = false;
if (!buildPath) {
    isDebug = true;
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
const hdSectionSize = 512;
function getNasmArgs(fileName, ext) {
    return `${nasmFilePath} ${fileName}${ext} -o ${fileName}${binExt} -l ${fileName}${listExt}`;
}
function getExtFiles(aimExt) {
    let files = [];
    for (const fileName of shelljs.ls()) {
        const ext = path.extname(fileName);
        if (ext.toLowerCase() === aimExt) {
            const file = path.basename(fileName, ext);
            files.push([file, ext]);
        }
    }
    return files;
}
function clear() {
    const binFiles = getExtFiles(binExt);
    const listFiles = getExtFiles(listExt);
    for (const binFile of binFiles) {
        shelljs.rm(`${binFile[0]}${binFile[1]}`);
    }
    for (const listFile of listFiles) {
        shelljs.rm(`${listFile[0]}${listFile[1]}`);
    }
    log('clear ok !');
}
clear();
function compile() {
    const asmFiles = getExtFiles(asmExt);
    for (const asmFile of asmFiles) {
        const cmd = getNasmArgs(asmFile[0], asmFile[1]);
        log(cmd);
        let output = shelljs.exec(cmd);
        if (output.code !== 0) {
            if (isDebug) {
                log(output.stderr);
            }
            log('>>>>> Compile Faild <<<<<');
            process.exit(1);
        }
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
        let file = `${config.name}${binExt}`;
        if (path.extname(config.name)) {
            file = config.name;
        }
        const start = config.start;
        const buffer = fs.readFileSync(file);
        const writeNum = fs.writeSync(fd, buffer, 0, buffer.length, start * hdSectionSize);
        if (writeNum !== buffer.length) {
            throw new Error('writeNum !== buffer.length');
        }
    }
    fs.closeSync(fd);
    log('writeToHD ok !');
}
writeToHD();
//# sourceMappingURL=build.js.map
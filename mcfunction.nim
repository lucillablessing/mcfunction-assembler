## MCFunction assembler
## by Lucilla


import os, strutils, tables



type
  Namespace   = string
  FilePath    = string
  FileName    = string
  MCFnName    = string
  MCFnCode    = string

  LineNumber  = int

  MCFnNames   = seq[MCFnName]
  MCFnLines   = seq[MCFnCode]

  NSFiles     = Table[Namespace, MCFnNames]
  Namespaces  = Table[MCFnName, Namespace]
  FilePaths   = Table[MCFnName, FilePath]
  FileNames   = Table[MCFnName, FileName]
  MCFunctions = Table[MCFnName, MCFnLines]



const
  fWord      = "function"
  fileEnding = ".mcfunction"

  prefix     = "##"
  pComment   = '#'
  pInclude   = '+'
  pNamespace = ':'
  pFilePath  = '/'
  pStartCode = '{'
  pEndCode   = '}'

  aliases = toTable {
    "ex": "execute",
    "fn": "function"
  }



var
  namespace   {.global.}: Namespace
  filePath    {.global.}: FilePath

  nsFiles     {.global.}: NSFiles
  namespaces  {.global.}: Namespaces
  filePaths   {.global.}: FilePaths
  fileNames   {.global.}: FileNames
  mcFunctions {.global.}: MCFunctions



proc generatePath(s: MCFnName): string =
  return namespaces[s] & ":" & (filePaths[s] / fileNames[s]).replace(DirSep, AltSep)



proc replaceNames(l: MCFnCode, kw: string): MCFnCode =

  var
    rLeft, rRight, rStop: int
    line, lLE, lLT, lEQ, lGE, lGT, lNew: MCFnCode
  
  let
    keyword = kw & " "
    kwLen   = keyword.len

  line  = l & " "
  rLeft = line.find(keyword, rStop)
  while rLeft >= 0:
    rLeft  = rLeft + kwLen
    lLT    = line[0 .. rLeft - 1]
    lGE    = line[rLeft .. ^1]
    rRight = lGE.find(" "); if rRight < 0: break
    lEQ    = lGE[0 .. rRight - 1]
    lGT    = lGE[rRight .. ^1]
    lNew   = lEQ.generatePath
    lLE    = lLT & lNew
    line   = lLE & lGT
    rStop  = lLE.len
    rLeft  = line.find(keyword, rStop)

  line.removeSuffix(" ")
  
  return line



proc mcPrepareFile(lines: MCFnLines): MCFnCode =

  var
    line:     MCFnCode
    linesOut: MCFnLines = newSeqOfCap[MCFnCode](lines.len)

  for i, l in pairs(lines):

    line = l

    if line.isEmptyOrWhitespace or line[0] == pComment:
      continue

    for r_i, r_o in pairs(aliases):
      line = line.replaceWord(r_i, r_o)

    line = line.strip
    line = line.replaceNames(fWord)

    linesOut.add(line)

  return linesOut.join("\p")



proc mcRequestFiles(lines: MCFnLines) =

  var
    line:      MCFnCode
    linePair:  MCFnLines
    lineStart: LineNumber
    lineEnd:   LineNumber
    fnName:    MCFnName
    fnPath:    FilePath
    fnParent:  FilePath
    fnFile:    FileName

  for i, l in pairs(lines):

    line = l

    if line.isEmptyOrWhitespace:
      continue

    if line.startsWith(prefix):
      line.removePrefix(prefix)

      if line.startsWith(pNamespace):
        namespace = line[1 .. ^1].strip

      if line.startsWith(pFilePath):
        filePath  = line[1 .. ^1].strip

      if line.startsWith(pInclude):
        let newFile = line[1 .. ^1].strip
        let newCode = readFile(newFile & fileEnding).splitLines
        mcRequestFiles(newCode)

      if line.startsWith(pStartCode):
        lineStart = i + 1
        linePair  = line[1 .. ^1].splitWhitespace
        fnName    = linePair[0]
        fnPath    = linePair[1]
        fnParent  = fnPath.parentDir
        fnFile    = fnPath.extractFilename
        if fnParent == ".": fnParent = ""
        if namespace in nsFiles:
          nsFiles[namespace].add(fnName)
        else:
          nsFiles[namespace] = @[fnName]
        namespaces[fnName] = namespace
        filePaths[fnName]  = filePath / fnParent
        fileNames[fnName]  = fnFile

      if line.startsWith(pEndCode):
        lineEnd = i - 1
        mcFunctions[fnName] = lines[lineStart .. lineEnd]



proc mcMakeFiles(dir: FilePath) =

  var
    innerDir:  FilePath
    innerPath: FilePath
    filePath:  FilePath
    fileName:  FileName
    fileCode:  MCFnCode

  let home = getCurrentDir() / dir / "data"
  createDir(home)
  setCurrentDir(home)

  for namespace, fnNames in pairs(nsFiles):

    innerDir = home / namespace / "functions"
    createDir(innerDir)
    setCurrentDir(innerDir)

    for fnName in fnNames:

      filePath  = filePaths[fnName]
      fileName  = fileNames[fnName] & fileEnding
      fileCode  = mcPrepareFile(mcFunctions[fnName])
      innerPath = innerDir / filePath
      createDir(innerPath)
      setCurrentDir(innerPath)
      writeFile(fileName, fileCode)
      setCurrentDir(innerDir)

    setCurrentDir(home)



let file = paramStr(1)
let sourceCode = readFile(file).splitLines
mcRequestFiles(sourceCode)
mcMakeFiles(file.splitFile.name)

#!/usr/bin/env python

__author__ = 'zhangweiping@baiyi-mobile.com'

import os
import sys
import string
import re

patternLink = re.compile(r'^symlink\((.*?)\);', re.M | re.S)
patternFilePerm = re.compile(r'^set_perm\((.*?)\);', re.M | re.S)
patternDirPerm = re.compile(r'^set_perm_recursive\((.*?)\);', re.M | re.S)

class LinkParse:
    """
    parse symlink line in updater-script
    """
    def __init__(self, scriptPath, infoPath):
        self.scriptPath = scriptPath
        self.infoPath = infoPath

    def parse(self):
        sFile = open(self.scriptPath, 'r')
        iFile = open(self.infoPath, 'w')
        sFileString = sFile.read()

        for i in re.finditer(patternLink, sFileString):
            linkList = self.parseToLinkList(i.group(1))
            for linkPair in linkList:
                iFile.write(linkPair+"\n")

        sFile.close()
        iFile.close()

    def parseToLinkList(self, lineString):
        """
        parse symlink script to link list
        e.g.
            symlink("mksh", "/system/bin/sh"); -> system/bin/sh|system/bin/mksh
        """
        linkList = lineString.replace(' ', '').replace('\n', '').replace('\"', '').split(",")

        newList = []
        if linkList[0][0] == '/':
            sourcePath = linkList[0]
        else:
            sourcePath = os.path.join(os.path.dirname(linkList[1]), linkList[0])

        for linkPath in linkList[1:]:
            newList.append(linkPath[1:]+"|"+sourcePath[1:])

        return newList

# End of LinkParse

class PermParse:
    """
    parse set permission line in updater-script
    """
    def __init__(self, otaPackagePath, scriptPath, infoPath):
        self.otaPackagePath = otaPackagePath
        self.scriptPath = scriptPath
        self.infoPath = infoPath
        self.systemInfoDict = {}

    def parse(self):
        sFile = open(self.scriptPath, 'r')
        iFile = open(self.infoPath, 'w')
        sFileString = sFile.read()

        for i in re.finditer(patternFilePerm, sFileString):
            lineString = i.group(1)
            self.parseFilePerm(lineString)

        for i in re.finditer(patternDirPerm, sFileString):
            lineString = i.group(1)
            self.parseDirPerm(lineString)

        for filename in sorted(self.systemInfoDict.keys()):
            iFile.write(filename+" "+self.systemInfoDict[filename]+"\n")

        sFile.close()
        iFile.close()

    def parseFilePerm(self, lineString):
        """
        parse one file perm, add to systemInfoDict
        e.g.
            set_perm(0, 2000, 02755, "/system/bin/pcscd");
            ->   {'system/bin/pcscd' : '0 2000 2755'}
        """
        parmList=lineString.replace(' ', '').replace('\n', '').replace('\"', '').split(",")
        if len(parmList) != 4:
            raise ValueError("parseFilePerm Error in " + parmList)
        filePath = parmList[3][1:]
        groupId  = parmList[0]
        owerId   = parmList[1]
        filePerm = parmList[2][1:]
        self.systemInfoDict[filePath] = groupId+" "+owerId+" "+filePerm

    def parseDirPerm(self, lineString):
        """
        parse dir perm, add to systemInfoDict
        e.g
            set_perm_recursive(0, 2000, 0755, 0644, "/system/lib");
            ->    {'system/lib' : '0 2000 0755',
                   'system/lib/libc.so' : '0 2000 0644',
                   'system/lib/xxxx.so' : '0 2000 0644',
                  .... }
        """
        parmList=lineString.replace(' ', '').replace('\n', '').replace('\"', '').split(",")
        if len(parmList) != 5:
            raise ValueError("parseDirPerm Error in " + parmList)

        dirPath  = parmList[4][1:]
        groupId  = parmList[0]
        owerId   = parmList[1]
        dirPerm  = parmList[2][1:]
        filePerm = parmList[3][1:]

        """ not process path not in system dir """
        if cmp(dirPath[0:6], "system"):
            #print "WARNING: "+dirPath+" is not a system dir path"
            return

        """ add dir """
        self.systemInfoDict[dirPath] = groupId+" "+owerId+" "+dirPerm

        """ add files in dir """
        for root, dirs, files in os.walk(os.path.join(self.otaPackagePath, dirPath)):
            for f in files:
                filename = os.path.join(root, f)[len(self.otaPackagePath)+1:]
                self.systemInfoDict[filename] = groupId+" "+owerId+" "+filePerm

# End of PermParse

def main(otaPackagePath, systemInfoPath, linkInfoPath):
    packagePath = os.path.abspath(otaPackagePath)
    scriptPath = os.path.join(packagePath, "META-INF/com/google/android/updater-script")

    LinkParse(scriptPath, linkInfoPath).parse()
    PermParse(packagePath, scriptPath, systemInfoPath).parse()


def Usage():
    print "Usage: getInfoFromScript.py  ota-dir  system.info  link.info "

if __name__ == '__main__':
    argLen = len(sys.argv)
    if argLen == 4:
        main(sys.argv[1], sys.argv[2], sys.argv[3])
    else:
        Usage()

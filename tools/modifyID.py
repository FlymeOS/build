#!/usr/bin/env python

'''
Created on 2012-12-19

@author: jock
'''
import sys
import re
import os

class ModifyId(object):
    '''
    classdocs
    '''


    def __init__(self, updateFile, inDir):
        '''
        Constructor
        '''
        self.smaliFileList = self.getInFileList(inDir)
        self.idMap = self.getUpdateIdMap(updateFile)

    def getInFileList(self, inDir):
        filelist = []
        smaliRe = re.compile(r'.*\.smali')
        for root, dirs, files in os.walk(inDir):
            for fn in files:
                if bool(smaliRe.match(fn)) is True:
                    filelist.append("%s/%s" % (root, fn))

        return filelist

    def getUpdateIdMap(self, updateFile):
        upfile = file(updateFile, 'r')
        idMap = {}

        for line in upfile.readlines():
            itemList = line.split()
            if (len(itemList) == 4):
                # print itemList[0], itemList[1], itemList[2], itemList[3]
                idMap[itemList[2]] = itemList[3]
            else:
                print "<<< WRONG merged_update.txt: %s" % line

        return idMap

    def getArrayId(self, arrayIdStr):
        idList = arrayIdStr.split()
        arrayId = "%s%s%s%s" % (idList[3][-3:-1], idList[2][-3:-1], idList[1][-3:-1], idList[0][-3:-1])
        arrayId = "0x%s" % (arrayId.replace('x', '0'))
        return arrayId.replace('0x0', '0x')

    def getArrayStr(self, arrayId):
        if cmp(arrayId[-8], "x") == 0:
            arrayStr = '0x%st 0x%st 0x%st 0x%st' % (arrayId[-2:], arrayId[-4:-2], arrayId[-6:-4], arrayId[-7:-6])
        else:
            arrayStr = '0x%st 0x%st 0x%st 0x%st' % (arrayId[-2:], arrayId[-4:-2], arrayId[-6:-4], arrayId[-8:-6])
        return arrayStr.replace('0x0', '0x')

    def modifyId(self):
        normalIdRule = re.compile(r'0x(?:[1-9]|7f)[0-1][0-9a-f]{5}')
        arrayIdRule = re.compile(r'(?:0x[0-9a-f]{1,2}t ){3}0x(?:[1-9]|7f)t')

        for smaliFile in self.smaliFileList:
            # print ">>> start modify: %s" % smaliFile
            sf = file(smaliFile, 'r+')
            fileStr = sf.read()
            modify = False

            for matchId in normalIdRule.findall(fileStr):
                newId = self.idMap.get(matchId, None)
                if newId is not None:
                    fileStr = fileStr.replace(matchId, r'0x#%s' % newId[2:])
                    modify = True
                    # print ">>> modify id from %s to %s" % (matchId, newId)

            for matchArrIdStr in  arrayIdRule.findall(fileStr):
                matchArrId = self.getArrayId(matchArrIdStr)
                newArrId = self.idMap.get(matchArrId, None)
                if newArrId is not None:
                    newArrIdStr = self.getArrayStr(newArrId)
                    fileStr = fileStr.replace(matchArrIdStr, r'0x#%s' % newArrIdStr[2:])
                    modify = True
                    # print ">>> modify array id from %s to %s" % (matchArrIdStr, newArrIdStr)

            if modify is True:
                sf.seek(0, 0)
                sf.truncate()
                fileStr = fileStr.replace(r'0x#', '0x')
                sf.write(fileStr)
            sf.close()

def main():
    if len(sys.argv) < 3:
        print " usage:./ModifyId.py <MAP_FILE> <INPUT_DIR> [OUT_DIR]"
        print "eg. : ./ModifyId.py merge_update.txt Phone.apk.out/ Phone.apk.out.mod/"
        print " if <OUT_DIR> is not specified,the OUT_DIR is INPUT_DIR"
        print "eg. : ./ModifyId.py merge_update.txt Phone.apk.out/"
        print "eg. : ./ModifyId.py merge_update.txt framework.jar.out/smali/com/baidu"
        print "eg. : ./ModifyId.py merge_update.txt <You want to modify dir name>/"
        sys.exit(1)

    print ">>>> modify resource id: %s ..." %(sys.argv[2])
    if len(sys.argv) >= 4:
        os.system("cp %s %s -rf" % (sys.argv[2], sys.argv[3]))
        ModifyId(sys.argv[1], sys.argv[3]).modifyId()
    else:
        ModifyId(sys.argv[1], sys.argv[2]).modifyId()
    print "<<<< modify resource id: %s done" %(sys.argv[2])

if __name__ == '__main__':
    main()

#!/usr/bin/env python

'''
Created on 2012-12-20

@author: jock
'''

import sys
import os
import re

DIRECT_METHOD_FLAG = "# direct methods"

class UpInterrJava(object):
    '''
    classdocs
    '''


    def __init__(self, addFile, inDir):
        '''
        Constructor
        '''
        self.idsList = self.getAddIdList(addFile)
        self.inDir = inDir

    def getAddIdList(self, addFile):
        '''
        getAddIdList: get add id list from merge_add.txt
        '''
        upfile = file(addFile, 'r')
        idList = {}

        for line in upfile.readlines():
            itemList = line.split()
            if (len(itemList) == 3):
                # print itemList[0], itemList[1], itemList[2]
                if idList.has_key(itemList[0]) is False:
                    idList[itemList[0]] = []

                idList[itemList[0]].append([itemList[1], itemList[2]])
            else:
                print "WRONG merged_add.txt: %s" % line

        return idList

    def upInterrJava(self):
        '''
        update the internal R*.smali
        '''
        for rType in self.idsList.keys():
            resFileName = r'%s/R$%s.smali' % (self.inDir, rType)

            if os.path.exists(resFileName):
                resFile = file(resFileName, 'r+')
                fileContent = resFile.read()

                for addItem in self.idsList[rType]:
                    rName = addItem[0]
                    rId = addItem[1]
                    if rType == "style":
                        rName = rName.replace(r'.', r'_')

                    linefill = "\n.field public static final %s:I = %s\n" % (rName, rId)
                    fileContent = re.sub(r'^.field public static final %s:I *=.*$' %(rName), '',  fileContent, 0, re.M)
                    fileContent = fileContent.replace("\n%s" % DIRECT_METHOD_FLAG, "%s\n%s" % (linefill, DIRECT_METHOD_FLAG), 1)

                resFile.seek(0, 0)
                resFile.truncate()
                resFile.write(fileContent)
                resFile.close()
            else:
                print "%s not exist!!" % resFileName

def main():
    if len(sys.argv) < 3:
        print " usage:./UpInterr.py <MAP_ADD_FILE> <R_DIR> "
        print "eg. : ./UpInterr.py merge_add.txt framework.jar.out/smali/com/android/internal/"
        sys.exit(1)

    print "start update %s/R*.smali ..." % sys.argv[2]
    UpInterrJava(sys.argv[1], sys.argv[2]).upInterrJava()
    print "update done!!"

if __name__ == '__main__':
    main()

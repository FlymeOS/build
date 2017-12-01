#!/usr/bin/env python

'''
Created on 2012-12-12

@author: jock
'''
from xml.dom import minidom
import codecs
import sys
import traceback

reload(sys)
sys.setdefaultencoding("utf-8")

class MapGen():
    def __init__(self, ori_xml, board_xml, out_file, none_ListFile=None):
        try:
            self.ori = minidom.parse(ori_xml)
            self.board = minidom.parse(board_xml)
            self.out = codecs.open(out_file, "w")
            if none_ListFile is not None:
                self.noneList = codecs.open(none_ListFile, "w")
            print "generate the map from %s to %s" % (board_xml, ori_xml)
        except:
            traceback.print_exc()
            sys.exit(1)

    def getOriIdList(self):
        root = self.ori.documentElement
        idList = {}

        for item in root.childNodes:
            if item.nodeType == minidom.Node.ELEMENT_NODE:
                itemType = item.getAttribute("type")
                itemName = item.getAttribute("name")
                itemId = item.getAttribute("id")
                idList["%s@%s" % (itemType, itemName)] = itemId

        return idList

    def genUpdateMap(self):
        oriIdList = self.getOriIdList()
        boardRoot = self.board.documentElement

        for item in boardRoot.childNodes:
            if item.nodeType == minidom.Node.ELEMENT_NODE:
                itemType = item.getAttribute("type")
                itemName = item.getAttribute("name")
                itemId = item.getAttribute("id")
                oriId = oriIdList.get("%s@%s" % (itemType, itemName), None)
                if oriId is None:
                    #print "added: type: %s, name: %s, id: %s" % (itemType, itemName, itemId)
                    itemId = itemId.replace("0x0", "0x")
                    self.noneList.write("%s %s %s\n" % (itemType, itemName, itemId))
                else:
                    if itemId != oriId:
                        itemId = itemId.replace("0x0", "0x")
                        oriId = oriId.replace("0x0", "0x")
                        #print "update: type: %s, name: %s, from id: %s to %s" % (itemType, itemName, itemId, oriId)
                        self.out.write("%s %s %s %s\n" % (itemType, itemName, itemId, oriId))
        self.out.close()
        self.noneList.close()

    def genAddMap(self):
        oriIdList = self.getOriIdList()
        boardRoot = self.board.documentElement

        for item in boardRoot.childNodes:
            if item.nodeType == minidom.Node.ELEMENT_NODE:
                itemType = item.getAttribute("type")
                itemName = item.getAttribute("name")
                itemId = item.getAttribute("id")
                oriId = oriIdList.get("%s@%s" % (itemType, itemName), None)
                if oriId is None:
                    itemId = itemId.replace("0x0", "0x")
                    #print "added: type: %s, name: %s, id: %s" % (itemType, itemName, itemId)
                    self.out.write("%s %s %s\n" % (itemType, itemName, itemId))

        self.out.close()

def main():
    if len(sys.argv) < 5:
        print "USAGE: GenMap.py -add/-map public_ori.xml public_board.xml out1.txt [out2.txt]"
        sys.exit(1)
    elif sys.argv[1] == "-add" and (len(sys.argv) == 5):
        MapGen(sys.argv[2], sys.argv[3], sys.argv[4]).genAddMap()
    elif (sys.argv[1] == "-map") and (len(sys.argv) == 6):
        MapGen(sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]).genUpdateMap()
    else:
        print "USAGE: GenMap.py -add/-map public_ori.xml public_board.xml out1.txt [out2.txt]"
        sys.exit(1)

    print "generate the map done"

if __name__ == '__main__':
    main()

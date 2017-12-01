#!/usr/bin/env python

import sys
import os
import traceback

try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET


__author__ = "duanqz@gmail.com (duanqz)"

__VERSION = (0, 1)

'''
This tool reads a mac_permissions.xml and replaces keys by keywords
'''

class RestoreTags():

    TAGS_TO_RESTORE = ["PLATFORM", "MEDIA", "SHARED", "RELEASE"]

    def __init__(self, mac_permission_xml):

        XMLDom = ET.parse(mac_permission_xml)

        for signer in XMLDom.findall('signer'):
            self.handleRestore(signer)

        XMLDom.write(mac_permission_xml)


    def handleRestore(self, signer):
        # Restore the signer signature back based on the seinfo
        for child in signer.getchildren():
            if child.tag == "seinfo":
                try:
                     value = child.attrib['value'].upper()
                     if value in RestoreTags.TAGS_TO_RESTORE:
                         signer.attrib['signature'] = "@%s" %value
                except KeyError:
                    traceback.print_exc()
                    pass



if __name__ == "__main__":
    mac_permission_xml = sys.argv[1]
    RestoreTags(mac_permission_xml)

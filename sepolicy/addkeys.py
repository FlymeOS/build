#!/usr/bin/env python

import sys
import os
import traceback

try:
    import xml.etree.cElementTree as ET
except ImportError:
    import xml.etree.ElementTree as ET

'''
This tool reads a mac_permissions.xml and add signer key
'''

class AddSigner():

    def __init__(self, add_xml, mac_permission_xml):

        XMLDomAdd = ET.parse(add_xml)

        for signer in XMLDomAdd.findall('signer'):
            for child in signer.getchildren():
                if child.tag == "seinfo":
                    self.addSigner(child.attrib['value'], signer.attrib['signature'])

    def addSigner(self, seinfoValue, signature):

        XMLDom = ET.parse(mac_permission_xml)
        duplicate = False
        for signer in XMLDom.findall('signer'):
            for child in signer.getchildren():
                if child.tag == "seinfo":
                    if child.attrib['value'] == seinfoValue and signer.attrib['signature'] == signature:
                        duplicate = True

        if not duplicate:
            signatureElement = ET.Element("signer", {"signature":signature})
            seinfoValueElement = ET.Element("seinfo", {"value":seinfoValue})
            signatureElement.append(seinfoValueElement)
            root = XMLDom.getroot()
            root.append(signatureElement)
            XMLDom.write(mac_permission_xml)

if __name__ == "__main__":
    add_xml = sys.argv[1]
    mac_permission_xml = sys.argv[2]
    AddSigner(add_xml, mac_permission_xml)

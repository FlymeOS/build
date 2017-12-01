#!/usr/bin/env python
# Copyright (C) 2012 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import os
import sys

class UpdateFilesystem:
    __name = ""
    filepathlist = []
    filelist = []
    dirlist = []

    def __init__(self):
	self.__name = "UpdateFilesystem"

    def visitDir(self, path):
	for root, dirs, files in os.walk(path):
		for dirpath in dirs:
		    self.dirlist.append(os.path.join(root, dirpath))
		for filepath in files:
		    self.filepathlist.append(os.path.join(root, filepath))

    def getListAll(self, files, path):
	self.visitDir(path)
	f = file(files, 'rw')
	lines = f.readlines()
	for line in lines:
	    value = line.find('system/app') and line.find('system/framework')
	    if value != 0:
	        self.filelist.append(line)
	f.close()
    
    def strcmp(self, stra, strb):
	if len(stra) != len(strb):
	    return False
	else:
	    for i in range(len(stra)):
		if stra[i] != strb[i]:
			return False
	return True

    def updateFiles(self, files, path):
	self.getListAll(files, path)

	for dirs in self.dirlist:
	    dirtmp = "system/" + dirs.replace('./', '')
	    dircmp = False
	    for i in range(len(self.filelist)):
		tmp = self.filelist[i]
		tmp = tmp.split(' ', 1)[0]
		dircmp = self.strcmp(dirtmp, tmp)
		if dircmp is True:
		    break

	    if dircmp is False:
		dirfull = dirtmp + " 0 0 755 selabel=u:object_r:system_file:s0 capabilities=0x0\n"
		self.filelist.append(dirfull)
	
	for path in self.filepathlist:
	    filetmp = "system/" + path.replace('./', '')
	    filecmp = False
	    for i in range(len(self.filelist)):
		tmp = self.filelist[i]
		tmp = tmp.split(' ', 1)[0]
		filecmp = self.strcmp(filetmp, tmp)
		if filecmp is True:
		    break

	    if filecmp is False:
		filetmpdir = os.path.dirname(filetmp)
		pptmp = False
		for i in range(len(self.filelist)):
		    splitArray = self.filelist[i].split(' ', 1)
		    if len(splitArray) < 2:
		        continue
		    filep = splitArray[0]
		    filepr =  splitArray[1]
		    pptmp = self.strcmp(filetmpdir, filep)
		    if pptmp is True:
		        filefull = filetmp + " " + filepr
		        self.filelist.append(filefull)
		        break		

	os.remove(files)
	f = file(files, 'w')
	f.writelines(self.filelist)
	f.close

	
if __name__ == '__main__':
  try:
    update = UpdateFilesystem()
    if len(sys.argv) != 3:
        print "***Need two args***"
	print "such as: UpdateFilesystem filesystem.txt  system"
	sys.exit(1)
    if os.path.isfile(sys.argv[1]):
	if os.path.isdir(sys.argv[2]):
	    curdir = os.getcwd()
            absfile = os.path.abspath(sys.argv[1])
	    os.chdir(sys.argv[2])
    	    update.updateFiles(absfile, "./")
	    os.chdir(curdir)
	else:
	    print sys.argv[2] + " not a dir!!!"
	    sys.exit(1) 
    else:
	print sys.argv[1] + " not a file!!!"
	sys.exit(1) 
  except IOError:
    print "ERROR"
    sys.exit(1)

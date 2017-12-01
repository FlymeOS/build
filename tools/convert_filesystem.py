#!/usr/bin/env python

'''
Created on 2015-08-06. add targetfiles data partition surpport

@author: duanlusheng@meizu.com
'''

import sys
import os
import os.path
import re

def convertName(dirname, filename):
	with open(sys.argv[1] + "/filesystem_config.txt","r") as f:
		for item in f.read().split("\n"):
			if item.split():
				if os.path.basename(item.split()[0]) == filename:
					return item.replace(item.split()[0], dirname + "/" + filename)

def main():

	with open(sys.argv[1] + "/data_filesystem_config.txt","w") as f2:
		for parent, dirnames, filenames in os.walk(sys.argv[2]):
			for filename in filenames:
				dirname = parent.replace("out/merged_target_files/DATA", "data")
				data_item = convertName(dirname, filename)
				if data_item:
					f2.write(data_item + "\n")

if __name__ == "__main__":
	main()

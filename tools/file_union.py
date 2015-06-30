#!/usr/bin/env python
#
# Copyright (C) 2014 The Coron
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

"""
Given a two files, generate a output file which is a union.
Concat the different between the two files instead of append.

Usage: file_union in_file1.txt in_file2.txt out_file.txt
"""

__author__ = 'duanqizhi'


import os, sys

def union(in_files1, in_file2, out_file):
    file1 = file(in_file1, "r")
    file2 = file(in_file2, "r")

    union_lines = set(file1.readlines()) | set(file2.readlines())

    file3 = file(out_file, "w")
    file3.writelines(sorted(union_lines))

    file1.close()
    file2.close()
    file3.close()

if __name__ == '__main__':
    argc = len(sys.argv)
    if argc < 3:
        print __doc__
        sys.exit(1)

    if argc >= 3:
        in_file1 = sys.argv[1]
        in_file2 = sys.argv[2]
        out_file = "%s_union_%s" %(os.path.basename(in_file1), os.path.basename(in_file2))

    if argc >= 4:
        out_file = sys.argv[3]

    union(in_file1, in_file2, out_file)

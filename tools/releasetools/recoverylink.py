#!/usr/bin/python

import os
import sys

DEBUG = False

link_info = sys.argv[1]
root_path = sys.argv[2]


try:
    file_handle = open(link_info)
    lines = file_handle.read().split()
    for line in lines:
        line = line.rstrip()
        link_item = line.split('|')
        if len(link_item) >= 2:

            # parse the link_src -> link_name
            link_name = os.path.join(root_path, link_item[0])
            link_src = link_item[1]

            # unlink existing link_name if needed
            if os.path.islink(link_name):
                if DEBUG: print "unlink the existing %s" % link_name
                os.unlink(link_name)
            elif os.path.isfile(link_name):
                if DEBUG: print "remove the existing %s, will re-create as link" % link_name
                os.remove(link_name)

            # update the link_src
            if os.path.dirname(link_item[0]) == os.path.dirname(link_src):
                link_src = os.path.basename(link_src)

            # relink
            if DEBUG: print "link %s -> %s" % (link_src, link_name)
            os.symlink(link_src, link_name)

        file_handle.close()
except IOError:
    print "%s isn't exist" % link_info
    sys.exit(1)

sys.exit(0)

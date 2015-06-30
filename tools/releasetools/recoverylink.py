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
            #
            # Phase 1: parse the link_src -> link_name
            #

            link_name = link_item[0].replace("system", "SYSTEM")
            link_src = link_item[1]

            # rename against with the root_path
            link_name = os.path.join(root_path, link_name)
            local_link_src = root_path + "/" + link_src

            #
            # Phase 2: Whether to link
            #

            link_name_dir = os.path.dirname(link_name)
            # Whether the local_link_src exists
            local_link_src = local_link_src.replace("system", "SYSTEM")
            if not os.path.exists(local_link_src):
                if DEBUG: print "link_src %s not exists, fall through restore the link %s" % (local_link_src, link_item[0])

            # Whether the link_name exists
            splitArray = link_name.split("/lib/")
            if len(splitArray) >= 2:
                # Case 1: link_name contains system/app, system/priv-app
                if not os.path.exists(splitArray[0]):
                    if DEBUG: print "app %s not exits, no need to restore the link %s" % (splitArray[0], link_item[0])
                    continue
            else:
                # Case 2: link_name_dir exists
                if not os.path.exists(link_name_dir):
                    if DEBUG: print "parent dir %s not exits, fall through to restore the link %s" % (link_name_dir, link_item[0])

            #
            # Phase 3: link again
            #

            # unlink existing link_name if needed
            if os.path.islink(link_name):
                if DEBUG: print "unlink the existing %s" % link_name
                os.unlink(link_name)
            elif os.path.isfile(link_name):
                if DEBUG: print "remove the existing %s, will re-create as link" % link_name
                os.remove(link_name)

            if not os.path.exists(link_name_dir):
                if DEBUG: print "create %s" % link_name_dir
                os.makedirs(link_name_dir)

            if not link_src.startswith("/"):
                link_src = "/" + link_src

            try:
                if DEBUG: print "link %s -> %s" % (link_src, link_name)
                os.symlink(link_src, link_name)
            except OSError:
                print "WARNING: Failed to link %s -> %s" % (link_src, link_name)
                pass

        file_handle.close()
except IOError:
    print "%s isn't exist" % link_info
    sys.exit(1)

sys.exit(0)

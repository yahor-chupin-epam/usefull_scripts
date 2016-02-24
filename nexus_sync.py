#!/usr/bin/env python

import sys
import os
import shutil
import hashlib
import urllib
import urllib2
import requests
from urllib2 import urlopen, HTTPError, Request, ProxyHandler
from urllib import urlretrieve
from base64 import encodestring
from xml.etree import ElementTree as ET

from HTMLParser import HTMLParser
import glob

temp_folder = '******'
source_url = '******'
auth=('*****', '*****')



class MyHTMLParser(HTMLParser):
 
    def __init__(self):
        HTMLParser.__init__(self)
        self.links = []
    def handle_starttag(self, tag, attrs):
        if tag == 'a':
            attrs_dict = dict(attrs)            
            if attrs_dict.get('href'):
                self.links.append(attrs_dict['href'])


### --- getting list of existing files
fileList_on_dest = []
rootdir = temp_folder
for root, subFolders, files in os.walk(rootdir):
    for filik in files:
        fileList_on_dest.append(unicode(os.path.join(root,filik).replace(temp_folder, "")))

def walk(url, creds):
    r = requests.get(url, auth=creds)
    parser = MyHTMLParser()
    parser.feed(r.text)
    without_slash = []

    for link in parser.links:
        if link.endswith('../'):
            ### --- skipping root folders
            pass
        elif link.endswith('/'):
            ### --- additional search in the folders
            without_slash.extend(walk(link, creds))
        else:
            ### --- adding to the links list
            without_slash.append(link.replace(source_url, ""))
        
        folder_to_create_uncut = os.path.dirname(link)
        folder_to_create = temp_folder + folder_to_create_uncut.replace(source_url, "")

        ### --- creating folders recursivele
        if not os.path.exists(folder_to_create):
            os.makedirs(folder_to_create)
        
        if not folder_to_create.endswith('..') and os.path.basename(link) != "":
            ### --- downloading file to the required folder
            print "#### - downloading necessary files to the " + temp_folder + ":"
            path_to_save = folder_to_create + '/' + os.path.basename(link)

            ### --- downloading of the files partly
            # NOTE the stream=True parameter
            if not os.path.exists(path_to_save):
                print "downloading " + link
                r = requests.get(link, stream=True, auth=creds) 
                with open(path_to_save, 'wb') as f:
                    for chunk in r.iter_content(chunk_size=1024): 
                        if chunk: # filter out keep-alive new chunks
                            f.write(chunk)
                      #f.flush() commented by recommendation from J.F.Sebastian
            else: 
                print path_to_save + " was already downloaded" 
    return without_slash

final_list = walk(source_url, auth)


fileList_on_source = set(final_list) #.replace(source_url, "")
fileList_on_dest = set(fileList_on_dest)

print 'Removing unnecessary files'
files_to_remove = fileList_on_dest - fileList_on_source

for rmfile in files_to_remove:
    full_remove_path = temp_folder + rmfile
    print 'removing: ' +  full_remove_path
    if os.path.isfile(full_remove_path):
        os.remove(full_remove_path)
##### --- need to add folder removing

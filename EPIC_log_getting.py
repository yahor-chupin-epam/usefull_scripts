# -*- coding: utf-8 -*-
#!/usr/bin/env python

'''
task is:
1. We have a directory with weeks’ worth of hourly log files (you can assume that the log files are rolled *****daily with the format ******YYYY_MM_DD_HH.log, and contain log lines in the apache combined log format).
  a. Write a script to secure copy all log files from  ****mon-fri daily  to a remote
  b. Write a script to print out the request with all HTTP response status code 500 server. within the last 10 min.
2. Design and implement deployment system to deploy and start a single  jar java app on a remote server. Explain the choice of any tools that you use (if any)
'''


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
from os import walk

import datetime
import re


### --- declaring variables
mypath = '/opt/LEARNING/python'

### --- getting day of the week today
currnet_day = str(datetime.datetime.today().weekday())

### --- getting list of files in folder recursively
f = []
matched_files = []

for dirpath, dirnames, filenames in walk(mypath):
    f.extend(filenames)
    #print filenames
    #break


for file in f:
    ### --- parcing date from file name
    m = re.search('\.([0-9]*-[0-9][0-9]-[0-9][0-9]).log', file)
    if m:
        file_date = m.group(1)
        ### --- parcing day of the week (DOF) from filename
        file_DOF = datetime.datetime.strptime(file_date, '%Y-%m-%d').strftime('%w')
#    print file_date + " is " + file_DOF

    ### --- checking if file is in required ranged of DOF
    if int(file_DOF) in range(1,6):
        matched_files.append(file)
        #print file
print len(matched_files)
    #print file_date + " is " + file_DOF



#f = set(f)
#print len(f_uniq)

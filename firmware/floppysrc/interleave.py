#!/usr/bin/python

import getopt
import sys

filename=""
content=[]
try:
    filename = sys.argv[1]
    content = open(filename,'rb').read()
except:
    print "boo!"
    sys.exit(1)

s = content
even = ''.join(s[x*2] if x*2<len(s) else '' for x in range(len(s)/2+1)) 
odd = ''.join(s[x*2+1] if x*2+1<len(s) else '' for x in range(len(s)/2+1))

nameparts = filename.split('.')
ext = nameparts[-1]
name  =  '.'.join(nameparts[0:-1])

open('.'.join(name,"even",ext), "wb").write(even)
open('.'.join(name, "odd",ext),"wb").write(odd)

sys.exit(0)

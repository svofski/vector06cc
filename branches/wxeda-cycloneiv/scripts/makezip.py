import time
import datetime
import os


repurl='http://vector06cc.googlecode.com/svn/trunk/'

print 'Querying repository %s' % repurl

pipa = os.popen('svn info %s' % repurl)
results = pipa.read().rsplit()
pipa.close()
irev = results.index('Revision:')
revidx = results[irev+1]

zipfilename='vector06cc-src-%d%d%d-rev%s.zip' % tuple(list(time.localtime()[0:3]) + [revidx])

print 'Creating zip: ', zipfilename

dirname='vector06cc-rev%s' % revidx

print 'Checking out source tree to %s' % dirname

os.system('svn export %s %s' % (repurl,dirname))
os.system('zip -r %s %s' % (zipfilename,dirname))
os.system('rd /s/q %s' % dirname)

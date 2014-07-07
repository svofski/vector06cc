del /q *.zip
makezip.py
for %%z in (*.zip) do googlecode_upload.py -s "svn snapshot" -p vector06cc %%z
del /q *.zip
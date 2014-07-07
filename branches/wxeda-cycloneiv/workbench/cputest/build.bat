@echo off
if ""=="%1" @goto error
set P=%1

del %P%.com
c:\bin\as\bin\asw %P%.asm
c:\bin\as\bin\p2bin -r 256-2048 %P%.p
ren %P%.bin %P%.com
del %P%.p

:error
echo usage: build.bat sourcefile-without-extension

:done
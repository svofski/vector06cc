objcopy --input-target=ihex --output-target=binary zagr512.hex zagr512.bin
cat>zagr512.mi <<BS
#File_format=Hex
#Address_depth=2048
#Data_width=8
BS

cat zagr512.bin | hexdump -v -e '/1 "%02X\n"' >> zagr512.mi

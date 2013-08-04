/* Script for -N: mix text and data on same page; don't align data */
OUTPUT_FORMAT("a.out-pdp11", "a.out-pdp11",
	      "a.out-pdp11")
OUTPUT_ARCH(pdp11)
SEARCH_DIR("/usr/local/pdp11/pdp11-aout/lib");
PROVIDE (__stack = 0x200);

ENTRY(_start)

SECTIONS
{
  . = 0;
  .text :
  {
    /* CREATE_OBJECT_SYMBOLS*/
    *(.text)
    /* The next six sections are for SunOS dynamic linking.  The order
       is important.  */
    *(.dynrel)
    *(.hash)
    *(.dynsym)
    *(.dynstr)
    *(.rules)
    *(.need)
    _etext = .;
    __etext = .;
  }
  . = .;
  .data :
  {
    /* The first three sections are for SunOS dynamic linking.  */
    *(.dynamic)
    *(.got)
    *(.plt)
    *(.data)
    *(.linux-dynamic) /* For Linux dynamic linking.  */
    CONSTRUCTORS
    _edata  =  .;
    __edata  =  .;
  }
  .bss :
  {
    __bss_start = .;
   *(.bss)
   *(COMMON)
   . = ALIGN(4);
   _end = . ;
   __end = . ;
  }
}

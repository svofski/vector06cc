#include <stdio.h>

#include "tff.h"

// tff

FRESULT f_open (
    FIL *fp,            /* Pointer to the blank file object */
    const char *path,   /* Pointer to the file name */
    BYTE mode           /* Access mode and file open mode flags */
)
{
    fp->file = fopen(path, "r");
    if (fp->file == NULL) return FR_NO_FILE;

    return FR_OK;
}

DWORD f_tell(FIL *f)
{
    return ftell(f->file);
}

FRESULT f_read(FIL *f, void *buf, UINT count, UINT* bytesread)
{
    size_t br = fread(buf, 1, count, f->file);
    *bytesread = (UINT)br;
    return FR_OK;
}

FRESULT f_lseek(FIL *f, DWORD pos)
{
    int res = fseek(f->file, pos, SEEK_SET);
    return res >= 0 ? FR_OK : FR_NO_FILE;
}

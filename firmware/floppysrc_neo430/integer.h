#ifndef _INTEGER

/* These types are assumed as 16-bit or larger integer */
typedef signed int		INT;
typedef unsigned int	UINT;

/* These types are assumed as 8-bit integer */
typedef signed char		CHAR;
typedef unsigned char	UCHAR;
typedef unsigned char	BYTE;

/* These types are assumed as 16-bit integer */
typedef signed short	SHORT;
typedef unsigned short	USHORT;
typedef unsigned short	WORD;

/* These types are assumed as 32-bit integer */
typedef signed long		LONG;
typedef unsigned long	ULONG;
typedef unsigned long	DWORD;

/* Boolean type */
typedef enum { FALSE = 0, TRUE } BOOL;

#ifndef SIMULATION
typedef BYTE 	uint8_t;
typedef WORD	uint16_t;
typedef DWORD	uint32_t;
#else
#include <stdint.h>
#endif

#define _INTEGER
#endif

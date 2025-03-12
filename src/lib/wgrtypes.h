#ifndef WGRTYPES_H
#define WGRTYPES_H

#ifndef NULL
#define NULL ((void *)0)
#endif

#ifndef bool
typedef _Bool bool;
#define true 1
#define false 0
#endif

#ifndef uint8_t
typedef unsigned char uint8_t;
#endif

#ifndef int8_t
typedef signed char int8_t;
#endif

#ifndef uint16_t
typedef unsigned short uint16_t;
#endif

#ifndef int16_t
typedef short int16_t;
#endif

#ifndef uint32_t
typedef unsigned int uint32_t;
#endif

#ifndef int32_t
typedef int int32_t;
#endif

#ifndef uint64_t
typedef unsigned long long uint64_t;
#endif

#ifndef int64_t
typedef long long int64_t;
#endif

#ifndef size_t
typedef unsigned int size_t;
#endif

typedef enum
{
    SPI_OK = 0,
    SPI_ERR_TIMEOUT = -1,
    SPI_ERR_PARAM = -2,
    SPI_ERR_COMM = -3
} wgr_status_t;

typedef enum
{
    BAUD_115200 = 0,
    BAUD_57600 = 1,
    BAUD_38400 = 2,
    BAUD_28800 = 3,
    BAUD_23040 = 4,
    BAUD_19200 = 5,
    BAUD_14400 = 6,
    BAUD_9600 = 7,
    BAUD_4800 = 8,
    BAUD_2400 = 9,
    BAUD_1200 = 10,
    BAUD_300 = 11
} baud_sel_t;

typedef char *va_list;

#define VA_ALIGN(type) ((sizeof(type) + sizeof(int) - 1) & ~(sizeof(int) - 1))

#define va_start(ap, last_named_arg) \
    (ap = (va_list)(&last_named_arg + 1))

#define va_arg(ap, type) \
    (*(type *)((ap += VA_ALIGN(type)) - VA_ALIGN(type)))

#define va_end(ap) (ap = NULL)

#endif /* WGRTYPES_H */

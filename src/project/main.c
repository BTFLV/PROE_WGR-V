#include "wgrhal.h"
#include "wgrhal_ext.h"

int main()
{
    uint32_t a = 40;
    spi_enable();
    spi_set_clock_divider(2);
    uart_enable();
    while(1)
    {
        if(uart_getchar(10) == 68)
        {
            terminal_init();
        }

    }
}

typedef struct
{
    uint8_t a;
    uint16_t b;
    int8_t c;
} str_8_16_8;

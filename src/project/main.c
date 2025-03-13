#include "wgrhal.h"
#include "wgrhal_ext.h"

int main()
{
    uint8_t a = 5;
    while(1)
    {
        debug_write(a);
        delay_micro(1);
        a++;
    }
}

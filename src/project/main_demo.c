#include "wgrhal.h"
#include "wgrhal_ext.h"

#define TEXT_BUFFER 128

char *buffer = NULL;
uint32_t cursor = 0;
uint32_t current_note = 0;
uint32_t current_octave = 0;

const char setpwm[] = "setpwm ";
const char spibaud[] = "spibaud "; //div
const char note[] = "note ";
const char octave[] = "octave ";
const char systime[] = "systime ";

// pwm_precompute_notes_malloc 2ms

void setup()
{
    uart_set_baud(BAUD_115200);
    uart_enable();
    //spi_enable();
    //spi_automatic_cs(1);
    //spi_set_clock_divider(1);
    //terminal_init();
    //pwm_precompute_notes_malloc();
    gpio_write(0x0F);
    buffer = (char *)malloc(TEXT_BUFFER * sizeof(char));
    gpio_write(0x02);
}

int32_t read_cmd()
{
    cursor = 0;
    while(1)
    {
        if(cursor >= (TEXT_BUFFER - 2))
        {
            return -1;
        }
        
        char data = -1;
        while(uart_read_byte(&data, 10))
        {
            
        }
        buffer[cursor] = data;
        //gpio_write(data);
        //terminal_print(buffer + cursor);
        //uart_putchar(data, 10);
        cursor++;
        if(data == '\n')
        {
            buffer[cursor] = '\0';
            return 0;
        }
    }
}

int32_t interpret_cmd()
{
    if(strncmp(buffer, setpwm, strlen(setpwm)) == 0)
    {
        int32_t parameter = parse_integer(buffer + strlen(setpwm));
        uart_print("\nPWM: ");
        uart_print_int(parameter);
        return 1;
    }
    if(strncmp(buffer, spibaud, strlen(spibaud)) == 0)
    {
        int32_t parameter = parse_integer(buffer + strlen(spibaud));
        if(parameter != -1)
        {
            uart_print("\nBAUD: ");
            uart_print_int(parameter);
        }
        return 2;
    }
    if(strncmp(buffer, note, strlen(note)) == 0)
    {
        int32_t parameter = parse_integer(buffer + strlen(note));
        if(parameter != -1)
        {
            uart_print("\nNOTE: ");
            uart_print_int(parameter);
            current_note = parameter;
        }
        return 3;
    }
    if(strncmp(buffer, octave, strlen(octave)) == 0)
    {
        int32_t parameter = parse_integer(buffer + strlen(octave));
        if(parameter != -1)
        {
            uart_print("\nOCTAVE: ");
            uart_print_int(parameter);
            current_octave = parameter;
        }
        return 4;
    }
    if(strncmp(buffer, systime, strlen(systime)) == 0)
    {
        uint32_t current_time = millis();
        uart_print("\nTIME: ");
        uart_print_uint(current_time, 10);
        uart_print("ms");
        return 5;
    }
    uart_print("\nWat?");
    return 0xF0;
}

int main()
{
    int32_t last_cmd = 0;
    setup();
    uart_print("WGR\n");

    while(1)
    {
        if(read_cmd() != -1)
        {
            uart_putchar('\n', 10);
            last_cmd = interpret_cmd();
            gpio_write(last_cmd);
        }
    }
}

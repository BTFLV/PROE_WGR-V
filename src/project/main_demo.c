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

void set_note();

void setup()
{
    setup();
    uart_enable();
    uart_set_baud(BAUD_115200);
    spi_enable();
    spi_automatic_cs(1);
    spi_set_clock_divider(1);
    terminal_init();
    pwm_precompute_notes_malloc();
    buffer = (char *)malloc(TEXT_BUFFER * sizeof(char));
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
        char data = uart_getchar(10);
        buffer[cursor] = data;
        terminal_print(buffer + cursor);
        if(data == '\n')
        {
            buffer[cursor + 1] = '\0';
            return 0;
        }
    }
}

int32_t interpret_cmd()
{
    if(strncmp(buffer, setpwm, sizeof(setpwm)) == 0)
    {
        int32_t parameter = parse_integer(buffer + sizeof(setpwm));
        return 1;
    }
    if(strncmp(buffer, spibaud, sizeof(spibaud)) == 0)
    {
        int32_t parameter = parse_integer(buffer + sizeof(spibaud));
        if(parameter != -1)
        {
            uart_set_baud(parameter);
            terminal_print("SPI Baud set\n");
        }
        return 2;
    }
    if(strncmp(buffer, note, sizeof(note)) == 0)
    {
        int32_t parameter = parse_integer(buffer + sizeof(note));
        if(parameter != -1)
        {
            pwm_play_note_malloc(parameter, current_octave);
            current_note = parameter;
            terminal_print("Note changed\n");
        }
        return 3;
    }
    if(strncmp(buffer, octave, sizeof(octave)) == 0)
    {
        int32_t parameter = parse_integer(buffer + sizeof(octave));
        if(parameter != -1)
        {
            pwm_play_note_malloc(current_note, parameter);
            current_octave = parameter;
            terminal_print("Octave changed\n");
        }
        return 4;
    }
    if(strncmp(buffer, systime, sizeof(systime)) == 0)
    {
        uint32_t current_time = millis();
        char time_buffer[11];
        int_to_str(current_time, 10, time_buffer);
        terminal_print("Time: ");
        terminal_print(time_buffer);
        terminal_print("ms\n");
        return 5;
    }
}

int main()
{
    setup();

    while(1)
    {
        if(read_cmd() != -1)
        {
            interpret_cmd();
        }
    }
}

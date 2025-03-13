#include "wgrhal.h"
#include "wgrhal_ext.h"

#define TEXT_BUFFER 128

char *buffer = NULL;
uint32_t cursor = 0;
uint32_t current_note = 0;
uint32_t current_octave = 0;

const char setpwm[] = "setpwm ";
const char spibaud[] = "spibaud ";
const char note[] = "note ";
const char octave[] = "octave ";
const char systime[] = "systime";

void int_to_str(int32_t num, int base, char *str);
int32_t parse_integer(const char *str);
const char *skip_spaces(const char *str)
{
    while (*str == ' ' || *str == '\t')
    {
        str++;
    }
    return str;
}

void setup()
{
    spi_enable();
    spi_automatic_cs(0);
    spi_set_clock_divider(0);
    terminal_init();
    draw_status_bar("WGR Terminal", COLOR_YELLOW, COLOR_BLACK);
    buffer = (char *)malloc(TEXT_BUFFER);
}

void print_time()
{
    char numStr[16];
    terminal_set_text_color(COLOR_GREEN);
    terminal_print("TIME: ");
    int_to_str((int32_t)(millis() / 1000), 10, numStr);
    terminal_print(numStr);
    terminal_print("s");
    terminal_set_text_color(COLOR_WHITE);
}

int32_t read_cmd()
{
    cursor = 0;
    while (1)
    {
        if (cursor >= (TEXT_BUFFER - 1))
        {
            buffer[cursor] = 0;
            return 0;
        }
        char data = -1;
        while (uart_read_byte(&data, 10))
        {
        }
        if (data < 0)
        {
            continue;
        }
        if (data == '\n')
        {
            buffer[cursor] = 0;

            terminal_put_char('\n');
            return 0;
        }

        terminal_set_text_color(COLOR_WHITE);
        terminal_put_char(data);
        buffer[cursor++] = data;
    }
}

void print_ok(const char *label, int32_t value)
{
    char numStr[16];
    terminal_set_text_color(COLOR_GREEN);
    terminal_print(label);
    int_to_str(value, 10, numStr);
    terminal_print(numStr);
    terminal_print("\n");
    terminal_set_text_color(COLOR_WHITE);
}

void print_error(const char *label)
{
    terminal_set_text_color(COLOR_RED);
    terminal_print(label);
    terminal_print("\n");
    terminal_set_text_color(COLOR_WHITE);
}

int32_t interpret_cmd()
{
    const char *param;
    if (strncmp(buffer, setpwm, strlen(setpwm)) == 0)
    {
        param = skip_spaces(buffer + strlen(setpwm));
        int32_t val = parse_integer(param);
        if (val != -1)
        {
            print_ok("PWM: ", val);
        }
        else
        {
            print_error("PWM: invalid");
        }
        return 1;
    }

    if (strncmp(buffer, spibaud, strlen(spibaud)) == 0)
    {
        param = skip_spaces(buffer + strlen(spibaud));
        int32_t val = parse_integer(param);
        if (val != -1)
        {
            print_ok("BAUD: ", val);
        }
        else
        {
            print_error("BAUD: invalid");
        }
        return 2;
    }

    if (strncmp(buffer, note, strlen(note)) == 0)
    {
        param = skip_spaces(buffer + strlen(note));
        int32_t val = parse_integer(param);
        if (val != -1)
        {
            current_note = val;
            print_ok("NOTE: ", val);
        }
        else
        {
            print_error("NOTE: invalid");
        }
        return 3;
    }

    if (strncmp(buffer, octave, strlen(octave)) == 0)
    {
        param = skip_spaces(buffer + strlen(octave));
        int32_t val = parse_integer(param);
        if (val != -1)
        {
            current_octave = val;
            print_ok("OCTAVE: ", val);
        }
        else
        {
            print_error("OCTAVE: invalid");
        }
        return 4;
    }

    if (strncmp(buffer, systime, strlen(systime)) == 0)
    {
        param = skip_spaces(buffer + strlen(systime));
        if (strncmp(param, "-ms", 3) == 0)
        {
            char numStr[16];
            terminal_set_text_color(COLOR_GREEN);
            terminal_print("TIME: ");
            int_to_str((int32_t)millis(), 10, numStr);
            terminal_print(numStr);
            terminal_print("ms\n");
            terminal_set_text_color(COLOR_WHITE);
        }
        else
        {
            print_time();
        }
        return 5;
    }

    print_error("Wat?");
    return 0xF0;
}

int main()
{
    int32_t last_cmd = 0;
    setup();

    terminal_print("WGR ready\n");

    while (1)
    {
        if (read_cmd() == 0)
        {
            last_cmd = interpret_cmd();
        }
    }
}

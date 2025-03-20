#include "wgrhal.h"
#include "wgrhal_ext.h"

#define TEXT_BUFFER 128

char *buffer = NULL;
uint32_t cursor = 0;
uint32_t current_note = 0;
uint32_t current_octave = 0;
uint32_t last_housekeep = 0;

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
    draw_status_bar("  - WGR Terminal -", COLOR_CYAN, COLOR_BLACK);
    buffer = (char *)malloc(TEXT_BUFFER);
    if (buffer == NULL)
    {
        terminal_print("TEXT_BUFFER malloc failed.\nhalting.\n");
        while (1)
            ;
    }
    int pwm_err = pwm_precompute_notes();
    if (pwm_err == -1)
    {
        terminal_print("pwm_precompute_notes\nmalloc failed.\nhalting.\n");
        while (1)
            ;
    }
}

void print_help(void)
{
    terminal_print_col("\nCommands:\n", COLOR_GREEN);
    terminal_set_text_color(COLOR_WHITE);

    terminal_print("\nmult <a> <b>");
    terminal_print("\ndiv  <a> <b>");

    terminal_print("\ninvert");
    terminal_print("\nclear");
    terminal_print("\nscroll");

    terminal_print("\ntime [-ms]");
    terminal_print("\nheap");

    terminal_print("\nnote <note> <oct>");
    terminal_print("\nnote [-off]");

    terminal_print("\nws <r> <g> <b> [led]");
    terminal_print("\nws -off");

    terminal_print("\npin [0..5] -on/-off");
}

int parse_and_play_note(const char *paramString)
{

    paramString = skip_spaces(paramString);

    char noteStr[8];
    uint8_t i = 0;
    while (*paramString && !(*paramString == ' ' || *paramString == '\t') && i < (sizeof(noteStr) - 1))
    {
        noteStr[i++] = *paramString++;
    }
    noteStr[i] = '\0';
    paramString = skip_spaces(paramString);

    int32_t parsedOctave = parse_integer(paramString);
    if (parsedOctave < 0)
    {
        print_error("OCTAVE: invalid");
        return -1;
    }

    note_t selectedNote;
    if (strcmp(noteStr, "C") == 0)
    {
        selectedNote = NOTE_C;
    }
    else if (strcmp(noteStr, "Cs") == 0)
    {
        selectedNote = NOTE_Cs;
    }
    else if (strcmp(noteStr, "D") == 0)
    {
        selectedNote = NOTE_D;
    }
    else if (strcmp(noteStr, "Ds") == 0)
    {
        selectedNote = NOTE_Ds;
    }
    else if (strcmp(noteStr, "E") == 0)
    {
        selectedNote = NOTE_E;
    }
    else if (strcmp(noteStr, "F") == 0)
    {
        selectedNote = NOTE_F;
    }
    else if (strcmp(noteStr, "Fs") == 0)
    {
        selectedNote = NOTE_Fs;
    }
    else if (strcmp(noteStr, "G") == 0)
    {
        selectedNote = NOTE_G;
    }
    else if (strcmp(noteStr, "Gs") == 0)
    {
        selectedNote = NOTE_Gs;
    }
    else if (strcmp(noteStr, "A") == 0)
    {
        selectedNote = NOTE_A;
    }
    else if (strcmp(noteStr, "As") == 0)
    {
        selectedNote = NOTE_As;
    }
    else if (strcmp(noteStr, "B") == 0)
    {
        selectedNote = NOTE_B;
    }
    else
    {
        print_error("NOTE: invalid");
        return -2;
    }

    pwm_play_note(selectedNote, (uint32_t)parsedOctave);

    print_ok_res("NOTE: ", parsedOctave);
    return 0;
}

int32_t read_cmd(void)
{
    cursor = 0;
    bool received_input = false;
    uint8_t data;

    while (cursor < (TEXT_BUFFER - 1))
    {
        housekeeping();
        int32_t ret = uart_read_byte(&data, 10);

        if (ret != 0)
        {
            continue;
        }

        if (data == '\n' || data == '\r')
        {
            terminal_put_char('\n');
            if (cursor == 0)
            {

                continue;
            }
            buffer[cursor] = '\0';
            return 0;
        }

        if (data == '\b' || data == 0x7F)
        {
            if (cursor > 0)
            {
                cursor--;
                terminal_put_char('\b');
            }
            continue;
        }

        if (data < 32 || data > 126)
        {
            continue;
        }
        if((cursor == 0) && (ssd1351_cursor_x != 0))
        {
            terminal_put_char('\n');
        }
        buffer[cursor++] = (char)data;
        terminal_set_text_color(COLOR_WHITE);
        terminal_put_char((char)data);
    }

    buffer[cursor] = '\0';
    return 0;
}

int32_t interpret_cmd()
{
    const char *param;

    if (strncmp(buffer, "setpwm", strlen("setpwm")) == 0)
    {
        param = skip_spaces(buffer + strlen("setpwm"));
        int32_t val = parse_integer(param);

        if (val != -1)
        {
            print_ok_res("PWM: ", val);
        }
        else
        {
            print_error("PWM: invalid");
            return -1;
        }
    }
    else if (strncmp(buffer, "pin", strlen("pin")) == 0)
    {
        param = skip_spaces(buffer + strlen("pin"));
        int32_t pinIndex = parse_int_multi(param, &param);
        if (pinIndex < 0 || pinIndex > 5)
        {
            print_error("USAGE:\npin [0..5] -on/-off");
            return -1;
        }

        uint8_t actualPin = (uint8_t)(pinIndex + 2);
        param = skip_spaces(param);

        if (strncmp(param, "-on", 3) == 0)
        {
            gpio_write_pin(actualPin, 1);
            print_ok_res("PIN ", pinIndex);
            print_ok(" on");
        }
        else if (strncmp(param, "-off", 4) == 0)
        {
            gpio_write_pin(actualPin, 0);
            print_ok_res("PIN ", pinIndex);
            print_ok(" off");
        }
        else
        {
            print_error("USAGE:\nPIN [0..5] -on/-off");
            return -1;
        }
    }
    else if (strncmp(buffer, "spibaud", strlen("spibaud")) == 0)
    {
        param = skip_spaces(buffer + strlen("spibaud"));
        int32_t val = parse_integer(param);

        if (val != -1)
        {
            print_ok_res("BAUD: ", val);
        }
        else
        {
            print_error("BAUD: invalid");
            return -1;
        }
    }
    else if (strncmp(buffer, "note", strlen("note")) == 0)
    {
        param = skip_spaces(buffer + strlen("note"));

        if (strncmp(param, "off", 3) == 0)
        {
            pwm_set_mode(0);
            terminal_print_col("NOTE OFF\n", COLOR_GREEN);
        }

        parse_and_play_note(param);
    }
    else if (strncmp(buffer, "heap", strlen("heap")) == 0)
    {
        uint32_t free_space = heap_free_space();
        print_ok_res("Free: ", free_space);
        print_ok("MB");
    }
    else if (strncmp(buffer, "time", strlen("time")) == 0)
    {
        param = skip_spaces(buffer + strlen("time"));
        if (strncmp(param, "-ms", 3) == 0)
        {
            print_ok_res("TIME: ", (int32_t)(millis()));
            print_ok("ms");
        }
        else
        {
            print_ok_res("TIME: ", (int32_t)(millis() / 1000));
            print_ok("s");
        }
    }
    else if (strncmp(buffer, "mult", strlen("mult")) == 0)
    {
        param = skip_spaces(buffer + strlen("mult"));
        int32_t multiplicand = parse_int_multi(param, &param);
        if (multiplicand < 0)
        {
            print_error("USAGE: mult [a] [b]");
            return -1;
        }

        param = skip_spaces(param);
        int32_t multiplier = parse_int_multi(param, &param);
        if (multiplier < 0)
        {
            print_error("USAGE: mult [a] [b]");
            return -1;
        }

        uint32_t result = mult_calc((uint32_t)multiplicand, (uint32_t)multiplier);

        print_ok_res("MULT: ", result);
    }
    else if (strncmp(buffer, "div", strlen("div")) == 0)
    {
        param = skip_spaces(buffer + strlen("div"));
        int32_t dividend = parse_int_multi(param, &param);
        if (dividend <= 0)
        {
            print_error("USAGE: div [a] [b]");
            return -1;
        }

        param = skip_spaces(param);
        int32_t divisor = parse_int_multi(param, &param);
        if (divisor < 0)
        {
            print_error("USAGE: div [a] [b]");
            return -1;
        }

        uint32_t result = div_calc_quotient((uint32_t)dividend, (uint32_t)divisor);

        print_ok_res("DIV: ", result);
    }
    else if (strncmp(buffer, "ws", strlen("ws")) == 0)
    {
        param = skip_spaces(buffer + strlen("ws"));

        if (strncmp(param, "-off", 4) == 0)
        {
            ws2812_clear();
            print_ok("WS OFF");
        }
        else
        {
            int32_t r = parse_int_multi(param, &param);
            param = skip_spaces(param);
            int32_t g = parse_int_multi(param, &param);
            param = skip_spaces(param);
            int32_t b = parse_int_multi(param, &param);
            param = skip_spaces(param);

            if (r < 0 || g < 0 || b < 0 || r > 255 || g > 255 || b > 255)
            {
                print_error("- USAGE:\nws <r> <g> <b> [n]\n- OF\nws -off");
                return -1;
            }

            rgb_color_t color = { .r = (uint8_t)r, .g = (uint8_t)g, .b = (uint8_t)b };

            if (*param != '\0')
            {
                int32_t led = parse_int_multi(param, &param);
                if (ws2812_set_color((uint8_t)led, color) == 0)
                {
                    print_ok_res("WS ", led);
                    print_ok(" SET.");
                }
                else
                {
                    print_error("[n] must be 0-7");
                }
            }
            else
            {
                ws2812_fill(color);
                print_ok("WS ON");
            }
        }
    }
    else if (strncmp(buffer, "invert", strlen("invert")) == 0)
    {
        ssd1351_inv();
        print_ok("INVERTED");
    }
    else if (strncmp(buffer, "clear", strlen("clear")) == 0)
    {
        clear_terminal();
    }
    else if (strncmp(buffer, "help", strlen("help")) == 0)
    {
        print_help();
    }
    else
    {
        print_error("Wat?");
    }

    return 0;
}

int main()
{
    int32_t last_cmd = 0;
    setup();
    terminal_print_col("WGR-V by\n", COLOR_GREEN);
    terminal_print("\n-Tobias Kling\n-Philip Mohr");

    while (1)
    {
        if (read_cmd() == 0)
        {
            last_cmd = interpret_cmd();
        }
    }
}

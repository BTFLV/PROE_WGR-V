#include "wgrhal.h"
#include "wgrhal_ext.h"

// ----------------------- WGR-V -----------------------
//
//         Hardware Multiplication and Division
//
//------------------------------------------------------

uint64_t mult_calc_64(uint32_t multiplicand, uint32_t multiplier)
{
    HWREG32(MULT_BASE_ADDR + MUL1_OFFSET) = multiplicand;
    HWREG32(MULT_BASE_ADDR + MUL2_OFFSET) = multiplier;

    while (HWREG32(MULT_BASE_ADDR + MULT_INFO_OFFSET));

    uint64_t high = (uint64_t)HWREG32(MULT_BASE_ADDR + RESH_OFFSET);
    uint64_t low  = (uint64_t)HWREG32(MULT_BASE_ADDR + RESL_OFFSET);

    return (high << 32) | low;
}

uint32_t mult_calc(uint32_t multiplicand, uint32_t multiplier)
{
    HWREG32(MULT_BASE_ADDR + MUL1_OFFSET) = multiplicand;
    HWREG32(MULT_BASE_ADDR + MUL2_OFFSET) = multiplier;

    while (HWREG32(MULT_BASE_ADDR + MULT_INFO_OFFSET));

    return HWREG32(MULT_BASE_ADDR + RESL_OFFSET);
}

int32_t div_calc(uint32_t dividend, uint32_t divisor, div_result_t *result)
{
    if (result == NULL || divisor == 0)
    {
        return -1;
    }

    HWREG32(DIV_BASE_ADDR + DIV_END_OFFSET) = dividend;
    HWREG32(DIV_BASE_ADDR + DIV_SOR_OFFSET) = divisor;

    while (HWREG32(DIV_BASE_ADDR + DIV_INFO_OFFSET));

    result->quotient = HWREG32(DIV_BASE_ADDR + DIV_QUO_OFFSET);
    result->remainder = HWREG32(DIV_BASE_ADDR + DIV_REM_OFFSET);

    return 0;
}

uint32_t div_calc_quotient(uint32_t dividend, uint32_t divisor)
{
    if (divisor == 0)
    {
        return -1;
    }

    HWREG32(DIV_BASE_ADDR + DIV_END_OFFSET) = dividend;
    HWREG32(DIV_BASE_ADDR + DIV_SOR_OFFSET) = divisor;

    while (HWREG32(DIV_BASE_ADDR + DIV_INFO_OFFSET));

    return HWREG32(DIV_BASE_ADDR + DIV_QUO_OFFSET);
}

uint32_t div_calc_remainder(uint32_t dividend, uint32_t divisor)
{
    if (divisor == 0)
    {
        return -1;
    }

    HWREG32(DIV_BASE_ADDR + DIV_END_OFFSET) = dividend;
    HWREG32(DIV_BASE_ADDR + DIV_SOR_OFFSET) = divisor;

    while (HWREG32(DIV_BASE_ADDR + DIV_INFO_OFFSET));

    return HWREG32(DIV_BASE_ADDR + DIV_REM_OFFSET);
}

// ----------------------- WGR-V -----------------------
//
//                     SPI Functions
//
//------------------------------------------------------

void spi_enable(void)
{
    uint32_t reg = HWREG32(SPI_BASE_ADDR + SPI_CTRL_OFFSET);
    reg |= 1U;
    HWREG32(SPI_BASE_ADDR + SPI_CTRL_OFFSET) = reg;
}

void spi_disable(void)
{
    uint32_t reg = HWREG32(SPI_BASE_ADDR + SPI_CTRL_OFFSET);
    reg &= ~1U;
    HWREG32(SPI_BASE_ADDR + SPI_CTRL_OFFSET) = reg;
}

void spi_automatic_cs(bool active)
{
    uint32_t reg = HWREG32(SPI_BASE_ADDR + SPI_CTRL_OFFSET);
    if (active)
    {
        reg |= 2U;
    }
    else
    {
        reg &= ~2U;
    }
    HWREG32(SPI_BASE_ADDR + SPI_CTRL_OFFSET) = reg;
}

void spi_cs(uint32_t active)
{
    HWREG32(SPI_BASE_ADDR + SPI_CS_OFFSET) = active;
}

void spi_set_clock_offset(uint32_t offset)
{
    HWREG32(SPI_BASE_ADDR + SPI_CLK_OFFSET) = offset;
}

void spi_set_clock_divider(uint32_t divider)
{
    uint32_t offset = 0;

    if (divider > 15)
    {
        offset = 0x8000;
    }
    else if (divider != 0)
    {
        offset = 1 << (divider - 1);
    }

    spi_set_clock_offset(offset);
}

uint32_t spi_get_status(void)
{
    return HWREG32(SPI_BASE_ADDR + SPI_STATUS_OFFSET);
}

uint32_t spi_fifo_full(void)
{
    return ((spi_get_status() >> 6) & (uint32_t)1);
}

uint32_t spi_is_ready(void)
{
    return ((spi_get_status() >> 5) & (uint32_t)1);
}

uint32_t spi_is_busy(void)
{
    return ((spi_get_status() >> 4) & (uint32_t)1);
}

uint32_t spi_rx_full(void)
{
    return ((spi_get_status() >> 3) & (uint32_t)1);
}

uint32_t spi_rx_empty(void)
{
    return ((spi_get_status() >> 2) & (uint32_t)1);
}

uint32_t spi_tx_full(void)
{
    return ((spi_get_status() >> 1) & (uint32_t)1);
}

uint32_t spi_tx_empty(void)
{
    return ((spi_get_status() >> 0) & (uint32_t)1);
}

int32_t spi_wait_rx_data(uint32_t timeout_ms)
{
    uint32_t start_time = millis();

    while (spi_rx_empty())
    {
        if ((millis() - start_time) >= timeout_ms)
        {
            return -1;
        }
        __asm__ volatile("nop");
    }
    return 0;
}

int32_t spi_write_byte(uint8_t data, uint32_t timeout_ms)
{
    uint32_t tx_word = (uint32_t)data;
    uint32_t start_time = millis();
    while (spi_tx_full())
    {
        if ((millis() - start_time) >= timeout_ms)
        {
            return -1;
        }
        __asm__ volatile("nop");
    }

    HWREG32(SPI_BASE_ADDR + SPI_TX_OFFSET) = tx_word;
    return 0;
}

int32_t spi_read_byte(uint8_t *data, uint32_t timeout_ms)
{
    uint32_t re_data = (uint32_t)data | 0x00000100;
    uint32_t start_time = millis();
    while (spi_fifo_full())
    {
        if ((millis() - start_time) >= timeout_ms)
        {
            return -1;
        }
        __asm__ volatile("nop");
    }
    HWREG32(SPI_BASE_ADDR + SPI_TX_OFFSET) = re_data;
    int32_t ret = spi_wait_rx_data(timeout_ms);
    if (ret != 0)
    {
        return ret;
    }
    *data = (uint8_t)(HWREG32(SPI_BASE_ADDR + SPI_RX_OFFSET) & 0xFF);
    return 0;
}

int32_t spi_write_buffer(const uint8_t *buf, uint32_t length, uint32_t timeout_ms)
{
    if (buf == 0)
    {
        return -1;
    }
    for (uint32_t i = 0; i < length; i++)
    {
        int32_t ret = spi_write_byte(buf[i], timeout_ms);
        if (ret != 0)
        {
            return ret;
        }
    }
    return 0;
}

int32_t spi_write_uint32(uint32_t value, uint32_t timeout_ms)
{
    uint8_t buf[4];
    buf[0] = (uint8_t)((value >> 24) & 0xFF);
    buf[1] = (uint8_t)((value >> 16) & 0xFF);
    buf[2] = (uint8_t)((value >> 8) & 0xFF);
    buf[3] = (uint8_t)(value & 0xFF);
    return spi_write_buffer(buf, 4, timeout_ms);
}

int32_t spi_read_buffer(uint8_t *buf, uint32_t length, uint32_t timeout_ms)
{
    if (buf == 0)
    {
        return -1;
    }
    for (uint32_t i = 0; i < length; i++)
    {
        int32_t ret = spi_read_byte(&buf[i], timeout_ms);
        if (ret < 0)
        {
            return ret;
        }
    }
    return 0;
}


// ----------------------- WGR-V -----------------------
//
//                   WS2812B Functions
//
//------------------------------------------------------


int32_t ws2812_set_color(uint8_t led, rgb_color_t color)
{
    if (led > 7)
    {
        return -1;
    }
    uint32_t color_val = ((uint32_t)color.g << 16) | ((uint32_t)color.r << 8) | color.b;
    HWREG32(WS_BASE_ADDR + (led << 2)) = color_val;
    return 0;
}

rgb_color_t ws2812_get_color(uint8_t led)
{
    rgb_color_t color = {0, 0, 0};
    if (led > 7)
    {
        return color;
    }
    uint32_t color_val = HWREG32(WS_BASE_ADDR + (led << 2));
    color.g = (color_val >> 16) & 0xFF;
    color.r = (color_val >> 8) & 0xFF;
    color.b = color_val & 0xFF;
    return color;
}

int32_t ws2812_write_all(const rgb_color_t colors[8])
{
    if (colors == NULL)
    {
        return -1;
    }
    for (uint8_t i = 0; i < 8; i++)
    {
        int32_t ret = ws2812_set_color(i, colors[i]);
        if (ret != 0)
        {
            return ret;
        }
    }
    return 0;
}

int32_t ws2812_fill(rgb_color_t color)
{
    for (uint8_t i = 0; i < 8; i++) {
        int32_t ret = ws2812_set_color(i, color);
        if (ret != 0)
        {
            return ret;
        }
    }
    return 0;
}

void ws2812_clear(void)
{
    rgb_color_t off = {0, 0, 0};
    for (uint8_t i = 0; i < 8; i++)
    {
        ws2812_set_color(i, off);
    }
}



#ifdef PWM_NOTES

// ----------------------- WGR-V -----------------------
//
//       Play Frequencies with the PWM Module
//
//------------------------------------------------------

#ifdef PWM_NOTES
    #ifndef MALLOC
        #error "Requires malloc. Define MALLOC to use PWM_NOTES."
    #endif
#endif

static uint32_t *note_buffer = 0;

const uint8_t note_freq_halfbase[12] = {
    131,
    139,
    147,
    156,
    165,
    175,
    185,
    196,
    208,
    220,
    233,
    247};

int pwm_precompute_notes(void)
{
    uint32_t sys_clk = get_sys_clk();
    debug_write(sys_clk);

    if (note_buffer == NULL)
    {
        note_buffer = (uint32_t *)malloc(12 * sizeof(uint32_t));
        if (!note_buffer)
        {
            return -1;
        }
    }

    for (int i = 0; i < 12; i++)
    {
        note_buffer[i] = (uint32_t)(sys_clk / note_freq_halfbase[i]);
        debug_write(note_buffer[i]);
    }

    return 0;
}

void pwm_play_note(note_t note, uint32_t octave)
{
    if (!note_buffer)
    {
        return;
    }

    uint32_t period = 0;
    uint16_t prescaler = 0;

    if (note < NOTE_C || note > NOTE_B)
    {
        return;
    }

    if (octave > 10)
    {
        period = note_buffer[note] >> 10;
        period = period ? period : 1;
        prescaler = 1;
    }
    else if (octave > 2)
    {
        period = note_buffer[note] >> (octave - 2);
        prescaler = 1;
    }
    else
    {
        period = note_buffer[note];
        prescaler = 1 << (2 - octave);
    }

    pwm_set_mode(1);
    pwm_set_50_percent_mode(1);

    pwm_set_period(period);
    pwm_set_pre_counter(prescaler);
}

void pwm_free_note_buffer(void)
{
    if (note_buffer)
    {
        free(note_buffer);
        note_buffer = 0;
    }
}

#endif

#ifdef MALLOC

// ----------------------- WGR-V -----------------------
//
//                        malloc
//
//------------------------------------------------------

typedef int ptrdiff_t;

void free(void *ap);

int errno;
#define ENOMEM 12

extern char _heap_start;
extern char _heap_end;

static char *heap_ptr = &_heap_start;

void *sbrk(int32_t incr)
{
    char *prev = heap_ptr;
    if (heap_ptr + incr > &_heap_end)
    {
        errno = ENOMEM;
        return (void *)-1;
    }
    heap_ptr += incr;
    return prev;
}

typedef long Align;

union header
{
    struct
    {
        union header *next;
        uint32_t size;
    } s;
    Align x;
};

typedef union header Header;

static Header base;
static Header *freep = 0;

#define NALLOC 1024

uint32_t heap_free_space(void)
{
    uint32_t free_space = (uint32_t)(&_heap_end - heap_ptr);
    return free_space;
}

static Header *morecore(uint32_t nu)
{
    if (nu < NALLOC)
        nu = NALLOC;
    char *cp = sbrk(nu * sizeof(Header));
    if (cp == (char *)-1)
    {
        return 0;
    }
    Header *up = (Header *)cp;
    up->s.size = nu;
    free((void *)(up + 1));
    return freep;
}

void *malloc(uint32_t nbytes)
{
    Header *p, *prevp;
    uint32_t nunits = (nbytes + sizeof(Header) - 1) / sizeof(Header) + 1;
    if ((prevp = freep) == 0)
    {
        base.s.next = freep = &base;
        base.s.size = 0;
    }
    for (p = freep->s.next;; prevp = p, p = p->s.next)
    {
        if (p->s.size >= nunits)
        {
            if (p->s.size == nunits)
                prevp->s.next = p->s.next;
            else
            {
                p->s.size -= nunits;
                p += p->s.size;
                p->s.size = nunits;
            }
            freep = prevp;
            return (void *)(p + 1);
        }
        if (p == freep)
        {
            p = morecore(nunits);
            if (p == 0)
            {
                return 0;
            }
        }
    }
}

void free(void *ap)
{
    if (!ap)
    {
        return;
    }
    Header *bp = (Header *)ap - 1;
    Header *p;

    for (p = freep; !(bp > p && bp < p->s.next); p = p->s.next)
    {
        if (p >= p->s.next && (bp > p || bp < p->s.next))
            break;
    }

    if ((bp + bp->s.size) == p->s.next)
    {
        bp->s.size += p->s.next->s.size;
        bp->s.next = p->s.next->s.next;
    }
    else
    {
        bp->s.next = p->s.next;
    }

    if ((p + p->s.size) == bp)
    {
        p->s.size += bp->s.size;
        p->s.next = bp->s.next;
    }
    else
    {
        p->s.next = bp;
    }
    freep = p;
}

void *realloc(void *ptr, uint32_t size)
{
    if (!ptr)
        return malloc(size);
    if (size == 0)
    {
        free(ptr);
        return 0;
    }

    Header *old_hdr = (Header *)ptr - 1;

    uint32_t old_data_size = (old_hdr->s.size - 1) * sizeof(Header);
    void *newptr = malloc(size);
    if (newptr)
    {
        char *src = (char *)ptr;
        char *dst = (char *)newptr;

        uint32_t copy_bytes = (size < old_data_size) ? size : old_data_size;
        for (uint32_t i = 0; i < copy_bytes; i++)
            dst[i] = src[i];
    }
    free(ptr);
    return newptr;
}

void *calloc(uint32_t nmemb, uint32_t size)
{
    uint32_t total = nmemb * size;
    void *ptr = malloc(total);
    if (ptr)
    {
        char *p = (char *)ptr;
        for (uint32_t i = 0; i < total; i++)
            p[i] = 0;
    }
    return ptr;
}

#endif

#ifdef SSD1351

// ----------------------- WGR-V -----------------------
//
//         SSD1351 Display with Scroll Function
//
//------------------------------------------------------

// SSD1351 Init Sequence
static const uint8_t ssd1351_init_cmds[] = {
    0xFD, 1, 0x12,
    0xFD, 1, 0xB1,
    0xAE, 0,
    0xB3, 1, 0xF1,
    0xCA, 1, 0x7F,
    0xA0, 1, 0x74,
    0xA1, 1, 0x00,
    0xA2, 1, 0x00,
    0xA6, 0,
    0xAB, 1, 0x01,
    0xB1, 1, 0x32,
    0xB2, 3, 0xA4, 0x00, 0x00,
    0xB4, 3, 0xA0, 0xB5, 0x55,
    0xB6, 1, 0x01,
    0xC1, 3, 0xC8, 0x80, 0xC8,
    0xC7, 1, 0x0F,
    0xBE, 1, 0x05,
    0x15, 2, 0x00, 0x7F,
    0x75, 2, 0x00, 0x7F,
    0xAF, 0};

static uint8_t scroll_offset = 0;
static uint8_t term_cursor_x = 0;
static uint8_t term_cursor_y = TOTAL_ROWS - 1;
static uint16_t term_text_color = COLOR_WHITE;
static uint16_t term_bg_color = COLOR_BLACK;

void ssd1351_send_data(const uint8_t *data, size_t len)
{
    gpio_write_pin(0, 1);
    spi_cs(1);
    spi_write_buffer(data, len, SSD1351_SPI_TIMEOUT);
    spi_cs(0);
}

void ssd1351_send_command(uint8_t cmd)
{
    gpio_write_pin(0, 0);
    spi_cs(1);
    spi_write_byte(cmd, SSD1351_SPI_TIMEOUT);
    spi_cs(0);
}

void ssd1351_send_command_with_data(uint8_t cmd, const uint8_t *data, size_t len)
{
    spi_cs(1);
    gpio_write_pin(0, 0);
    spi_write_byte(cmd, SSD1351_SPI_TIMEOUT);
    if (len > 0)
    {
        gpio_write_pin(0, 1);
        spi_write_buffer(data, len, SSD1351_SPI_TIMEOUT);
    }
    spi_cs(0);
}

void ssd1351_send_commands(const uint8_t *buf, size_t len)
{
    size_t i = 0;
    while (i < len)
    {
        uint8_t cmd = buf[i++];
        uint8_t dataLen = buf[i++];
        ssd1351_send_command_with_data(cmd, &buf[i], dataLen);
        i += dataLen;
    }
}

void ssd1351_init(void)
{
    spi_cs(0);

    gpio_write_pin(1, 0);
    delay(100);
    gpio_write_pin(1, 1);
    delay(100);

    ssd1351_send_commands(ssd1351_init_cmds, sizeof(ssd1351_init_cmds));
    delay(100);

    uint8_t scroll_area[2] = {CHAR_HEIGHT, (uint8_t)(SSD1351_HEIGHT - CHAR_HEIGHT)};
    ssd1351_send_command(0xA3);
    ssd1351_send_data(scroll_area, 2);

    scroll_offset = 0;
    uint8_t scroll_start = scroll_offset + CHAR_HEIGHT;
    ssd1351_send_command(0xA1);
    ssd1351_send_data(&scroll_start, 1);
}

void ssd1351_set_position(uint8_t x, uint8_t y, uint8_t w, uint8_t h)
{
    uint8_t colArgs[2] = {x, (uint8_t)(x + w - 1)};
    uint8_t rowArgs[2] = {y, (uint8_t)(y + h - 1)};

    ssd1351_send_command(0x15);
    ssd1351_send_data(colArgs, 2);

    ssd1351_send_command(0x75);
    ssd1351_send_data(rowArgs, 2);

    ssd1351_send_command(0x5C);
}

void draw_char_cell_custom(uint8_t row, uint8_t col, char c, uint16_t fg, uint16_t bg)
{
    if (c < 32 || c > 127)
    {
        c = '?';
    }
    const uint8_t *glyph = font5x7[c - 32];
    uint8_t x = col * CHAR_WIDTH;
    uint8_t y = row * CHAR_HEIGHT;

    ssd1351_set_position(x, y, CHAR_WIDTH, CHAR_HEIGHT);

    uint16_t cell[CHAR_WIDTH * CHAR_HEIGHT];
    for (int i = 0; i < CHAR_WIDTH * CHAR_HEIGHT; i++)
    {
        cell[i] = bg;
    }
    for (uint8_t cx = 0; cx < 5; cx++)
    {
        uint8_t bits = glyph[cx];
        for (uint8_t cy = 0; cy < 7; cy++)
        {
            if (bits & (1 << cy))
            {
                cell[cy * CHAR_WIDTH + cx] = fg;
            }
        }
    }
    ssd1351_send_data((uint8_t *)cell, sizeof(cell));
}

void draw_char_cell(uint8_t row, uint8_t col, char c)
{
    draw_char_cell_custom(row, col, c, COLOR_WHITE, COLOR_BLACK);
}

void clear_terminal_row(uint8_t row)
{
    for (uint8_t col = 0; col < TERM_COLS; col++)
    {
        draw_char_cell_custom(row, col, ' ', term_text_color, term_bg_color);
    }
}

void draw_status_bar(const char *text, uint16_t bg_color, uint16_t fg_color)
{
    ssd1351_set_position(0, 0, SSD1351_WIDTH, CHAR_HEIGHT);

    uint16_t lineBuf[SSD1351_WIDTH * CHAR_HEIGHT];
    for (int i = 0; i < SSD1351_WIDTH * CHAR_HEIGHT; i++)
    {
        lineBuf[i] = bg_color;
    }
    ssd1351_send_data((uint8_t *)lineBuf, sizeof(lineBuf));

    uint8_t col = 0;
    while (*text && col < TERM_COLS)
    {
        draw_char_cell_custom(0, col, *text++, fg_color, bg_color);
        col++;
    }
}

void terminal_native_scroll(void)
{
    scroll_offset += CHAR_HEIGHT;
    if (scroll_offset >= (SSD1351_HEIGHT - CHAR_HEIGHT))
    {
        scroll_offset = 0;
    }
    uint8_t scroll_start = scroll_offset + CHAR_HEIGHT;
    ssd1351_send_command(0xA1);
    ssd1351_send_data(&scroll_start, 1);

    clear_terminal_row(TOTAL_ROWS - 1);
    term_cursor_y = TOTAL_ROWS - 1;
    term_cursor_x = 0;
}

void terminal_put_char(char c)
{
    if (c == '\n')
    {
        terminal_native_scroll();
        return;
    }
    draw_char_cell_custom(term_cursor_y, term_cursor_x, c, term_text_color, term_bg_color);
    term_cursor_x++;
    if (term_cursor_x >= TERM_COLS)
    {
        terminal_native_scroll();
    }
}

void terminal_print(const char *str)
{
    while (*str)
    {
        terminal_put_char(*str++);
    }
}

void terminal_set_text_color(uint16_t color)
{
    term_text_color = color;
}

void terminal_set_bg_color(uint16_t color)
{
    term_bg_color = color;
}

void terminal_draw_text(uint8_t row, uint8_t col, const char *str, uint16_t fg, uint16_t bg)
{
    while (*str && col < TERM_COLS)
    {
        draw_char_cell_custom(row, col, *str++, fg, bg);
        col++;
    }
}

void terminal_draw_text_default(uint8_t row, uint8_t col, const char *str)
{
    terminal_draw_text(row, col, str, COLOR_WHITE, COLOR_BLACK);
}

void ssd1351_fill_screen(uint16_t color)
{
    ssd1351_set_position(0, 0, SSD1351_WIDTH, SSD1351_HEIGHT);
    uint16_t lineBuf[SSD1351_WIDTH];
    for (int i = 0; i < SSD1351_WIDTH; i++)
    {
        lineBuf[i] = color;
    }
    for (int r = 0; r < SSD1351_HEIGHT; r++)
    {
        ssd1351_send_data((uint8_t *)lineBuf, sizeof(lineBuf));
    }
}

void ssd1351_draw_pixel(uint8_t x, uint8_t y, uint16_t color)
{
    ssd1351_set_position(x, y, 1, 1);
    ssd1351_send_data((uint8_t *)&color, 2);
}

void terminal_init(void)
{
    ssd1351_init();
    for (uint8_t r = STATUS_BAR_ROWS; r < TOTAL_ROWS; r++)
    {
        clear_terminal_row(r);
    }
    term_cursor_x = 0;
    term_cursor_y = TOTAL_ROWS - 1;
}

#endif

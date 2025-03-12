#include "wgrhal.h"
#include "wgrhal_ext.h"

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
    while ((!spi_tx_empty()) || spi_is_busy())
        ;
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

void gpio_set_pin_direction(uint8_t pin, uint8_t is_input)
{
    volatile uint32_t *const gpio_dir = (volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_DIR_OFFSET);
    uint32_t dir = *gpio_dir;

    if (is_input)
    {
        dir |= (1 << pin);
    }
    else
    {
        dir &= ~(1 << pin);
    }

    *gpio_dir = dir;
}

void gpio_write_pin(uint8_t pin, uint8_t value)
{
    volatile uint32_t *const gpio_out = (volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_OUT_OFFSET);
    uint32_t out = *gpio_out;

    if (value)
    {
        out |= (1 << pin);
    }
    else
    {
        out &= ~(1 << pin);
    }

    *gpio_out = out;
}

uint8_t gpio_read_pin(uint8_t pin)
{
    volatile uint32_t *const gpio_in = (volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_IN_OFFSET);
    return ((*gpio_in) & (1 << pin)) ? 1 : 0;
}

void gpio_set_direction(uint32_t dir_mask)
{
    volatile uint32_t *const gpio_dir = (volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_DIR_OFFSET);
    *gpio_dir = dir_mask;
}

void gpio_write(uint32_t value)
{
    volatile uint32_t *const gpio_out = (volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_OUT_OFFSET);
    *gpio_out = value;
}

uint32_t gpio_read(void)
{
    volatile uint32_t *const gpio_in = (volatile uint32_t *)(GPIO_BASE_ADDR + GPIO_IN_OFFSET);
    return *gpio_in;
}

#ifdef SSD1306

const uint8_t init_cmds[] = {
    0xAE, 0xD5, 0x80, 0xA8, SSD1306_HEIGHT - 1,
    0xD3, 0x00, 0x40, 0x8D, 0x14, 0x20, 0x00,
    0xA1, 0xC8, 0xDA, 0x12, 0x81, 0xCF, 0xD9,
    0xF1, 0xDB, 0x40, 0xA4, 0xA6, 0xAF};

void ssd1306_send_command(uint8_t cmd)
{
    spi_cs(1);
    spi_write_byte(cmd, SSD1306_SPI_TIMEOUT);
    spi_cs(0);
}

void ssd1306_send_commands(const uint8_t *cmds, size_t len)
{
    spi_cs(1);
    spi_write_buffer(cmds, len, SSD1306_SPI_TIMEOUT);
    spi_cs(0);
}

void ssd1306_send_data(uint8_t *data, size_t len)
{
    spi_cs(1);
    spi_write_buffer(data, len, SSD1306_SPI_TIMEOUT);
    spi_cs(0);
}

void ssd1306_set_position(uint8_t page, uint8_t col)
{
    ssd1306_send_command(0xB0 | page);
    ssd1306_send_command(0x00 | (col & 0x0F));
    ssd1306_send_command(0x10 | (col >> 4));
}

void ssd1306_init(void)
{
    spi_cs(0);
    spi_automatic_cs(0);
    ssd1306_send_commands(init_cmds, sizeof(init_cmds));
}

void draw_char_cell(uint8_t row, uint8_t col, char c)
{
    uint8_t page = row;
    uint8_t x = col * CHAR_WIDTH;
    uint8_t cell[CHAR_WIDTH] = {0};
    if (c < 32 || c > 127)
        c = '?';
    const uint8_t *glyph = font5x7[c - 32];
    for (uint8_t i = 0; i < 5; i++)
    {
        cell[i] = glyph[i];
    }
    cell[5] = 0x00;
    ssd1306_set_position(page, x);
    ssd1306_send_data(cell, CHAR_WIDTH);
}

void clear_terminal_row(uint8_t row)
{
    for (uint8_t col = 0; col < TERM_COLS; col++)
    {
        draw_char_cell(row, col, ' ');
    }
}

void terminal_native_scroll(void)
{
    ssd1306_send_command(0x29);
    ssd1306_send_command(0x00);
    ssd1306_send_command(0x00);
    ssd1306_send_command(0x00);
    ssd1306_send_command(TERM_ROWS - 1);
    ssd1306_send_command(CHAR_HEIGHT);
    ssd1306_send_command(0x2F);

    delay(100);

    ssd1306_send_command(0x2E);

    clear_terminal_row(TERM_ROWS - 1);
}

static uint8_t term_cursor_x = 0;

void terminal_put_char(char c)
{
    if (c == '\n')
    {
        terminal_native_scroll();
        term_cursor_x = 0;
    }
    else
    {
        draw_char_cell(TERM_ROWS - 1, term_cursor_x, c);
        term_cursor_x++;
        if (term_cursor_x >= TERM_COLS)
        {
            terminal_native_scroll();
            term_cursor_x = 0;
        }
    }
}

void terminal_print(const char *str)
{
    while (*str)
    {
        terminal_put_char(*str++);
    }
}

void terminal_init(void)
{
    ssd1306_init();
    for (uint8_t r = 0; r < TERM_ROWS; r++)
    {
        clear_terminal_row(r);
    }
    term_cursor_x = 0;
}

#endif

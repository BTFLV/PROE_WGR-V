#ifndef WGRHAL_EXT_H
#define WGRHAL_EXT_H

#include "wgrtypes.h"

#ifndef HWREG32
#define HWREG32(addr) (*((volatile uint32_t *)(addr)))
#endif

#define I2C_BASE_ADDR 0x00000500
#define I2C_CTRL_OFFSET 0x0
#define I2C_DATA_OFFSET 0x4
#define I2C_ADDR_OFFSET 0x8
#define ADC_BASE_ADDR 0x00000600
#define ADC_CTRL_OFFSET 0x0000
#define ADC_DATA_OFFSET 0x0004
#define ADC_TEMP_OFFSET 0x0008
#define CONV_START_BIT 0
#define CONV_DONE_BIT 8
#define ADC_VREF 3.3
#define TEMP_SENSOR_GAIN 503.975
#define TEMP_SENSOR_OFFSET 273.15
#define SPI_BASE_ADDR 0x00000700
#define SPI_CTRL_OFFSET 0x0000
#define SPI_CLK_OFFSET 0x0004
#define SPI_STATUS_OFFSET 0x0008
#define SPI_TX_OFFSET 0x000C
#define SPI_RX_OFFSET 0x0010
#define SPI_CS_OFFSET 0x0014
#define GPIO_BASE_ADDR 0x00000800
#define GPIO_DIR_OFFSET 0x0000
#define GPIO_OUT_OFFSET 0x0004
#define GPIO_IN_OFFSET 0x0008
#define FM_BASE_ADDR 0x00000900
#define FM_CARRIER_FREQ_OFFSET 0x00
#define FM_MODULATOR_FREQ_OFFSET 0x04
#define FM_MOD_INDEX_OFFSET 0x08
#define FM_AMPLITUDE_OFFSET 0x0C
#define FM_CONTROL_OFFSET 0x10
#define FM_SAMPLE_OFFSET 0x14
#define ADSR_ATTACK_RATE_OFFSET 0x18
#define ADSR_DECAY_RATE_OFFSET 0x1C
#define ADSR_SUSTAIN_LEVEL_OFFSET 0x20
#define ADSR_RELEASE_RATE_OFFSET 0x24
#define LFO_FREQ_OFFSET 0x28
#define LFO_DEPTH_OFFSET 0x2C
#define LP_COEFF_OFFSET 0x30
#define HP_COEFF_OFFSET 0x34
#define FM_ENABLE_BIT (1 << 0)
#define ADSR_GATE_BIT (1 << 1)
#define FILTER_SEL_BIT (1 << 2)

void i2c_set_slave_address(uint8_t slave_addr);
int32_t i2c_write_byte(uint8_t slave_addr, uint8_t data);
int32_t i2c_read_byte(uint8_t slave_addr, uint8_t *data);

void adc_start_conversion(void);
uint8_t adc_is_conversion_done(void);
void adc_wait_for_conversion(void);
uint16_t adc_get_value(void);
uint16_t adc_read(void);

void adc_start_temp_conversion(void);
uint16_t adc_get_temperature_raw(void);
float adc_convert_to_celsius(uint16_t raw_value);
float adc_read_temp(void);

void spi_enable(void);
void spi_disable(void);
void spi_automatic_cs(bool active);
void spi_cs(uint32_t active);
void spi_set_clock_offet(uint32_t offset);
void spi_set_clock_divider(uint32_t divider);
uint32_t spi_get_status(void);
uint32_t spi_fifo_full(void);
uint32_t spi_is_ready(void);
uint32_t spi_is_busy(void);
uint32_t spi_rx_full(void);
uint32_t spi_rx_empty(void);
uint32_t spi_tx_full(void);
uint32_t spi_tx_empty(void);
int32_t spi_wait_rx_data(uint32_t timeout_ms);
int32_t spi_write_byte(uint8_t data, uint32_t timeout_ms);
int32_t spi_read_byte(uint8_t *data, uint32_t timeout_ms);
int32_t spi_write_buffer(const uint8_t *buf, uint32_t length, uint32_t timeout_ms);
int32_t spi_write_uint32(uint32_t value, uint32_t timeout_ms);
int32_t spi_read_buffer(uint8_t *buf, uint32_t length, uint32_t timeout_ms);

void gpio_set_pin_direction(uint8_t pin, uint8_t is_input);
void gpio_write_pin(uint8_t pin, uint8_t value);
uint8_t gpio_read_pin(uint8_t pin);
void gpio_set_direction(uint32_t dir_mask);
void gpio_write(uint32_t value);
uint32_t gpio_read(void);

#ifdef SSD1306

#define SSD1306_WIDTH 128
#define SSD1306_HEIGHT 64

#define TERM_ROWS 4
#define TERM_COLS 23

#define CHAR_WIDTH 6
#define CHAR_HEIGHT 8

#define SSD1306_SPI_TIMEOUT 100

static const uint8_t font5x7[96][5] = {
    {0x00, 0x00, 0x00, 0x00, 0x00}, // ' ' (32)
    {0x00, 0x00, 0x5F, 0x00, 0x00}, // '!' (33)
    {0x00, 0x07, 0x00, 0x07, 0x00}, // '"' (34)
    {0x14, 0x7F, 0x14, 0x7F, 0x14}, // '#' (35)
    {0x24, 0x2A, 0x7F, 0x2A, 0x12}, // '$' (36)
    {0x23, 0x13, 0x08, 0x64, 0x62}, // '%' (37)
    {0x36, 0x49, 0x55, 0x22, 0x50}, // '&' (38)
    {0x00, 0x05, 0x03, 0x00, 0x00}, // ''' (39)
    {0x00, 0x1C, 0x22, 0x41, 0x00}, // '(' (40)
    {0x00, 0x41, 0x22, 0x1C, 0x00}, // ')' (41)
    {0x14, 0x08, 0x3E, 0x08, 0x14}, // '*' (42)
    {0x08, 0x08, 0x3E, 0x08, 0x08}, // '+' (43)
    {0x00, 0x50, 0x30, 0x00, 0x00}, // ',' (44)
    {0x08, 0x08, 0x08, 0x08, 0x08}, // '-' (45)
    {0x00, 0x60, 0x60, 0x00, 0x00}, // '.' (46)
    {0x20, 0x10, 0x08, 0x04, 0x02}, // '/' (47)
    {0x3E, 0x51, 0x49, 0x45, 0x3E}, // '0' (48)
    {0x00, 0x42, 0x7F, 0x40, 0x00}, // '1' (49)
    {0x42, 0x61, 0x51, 0x49, 0x46}, // '2' (50)
    {0x21, 0x41, 0x45, 0x4B, 0x31}, // '3' (51)
    {0x18, 0x14, 0x12, 0x7F, 0x10}, // '4' (52)
    {0x27, 0x45, 0x45, 0x45, 0x39}, // '5' (53)
    {0x3C, 0x4A, 0x49, 0x49, 0x30}, // '6' (54)
    {0x01, 0x71, 0x09, 0x05, 0x03}, // '7' (55)
    {0x36, 0x49, 0x49, 0x49, 0x36}, // '8' (56)
    {0x06, 0x49, 0x49, 0x29, 0x1E}, // '9' (57)
    {0x00, 0x36, 0x36, 0x00, 0x00}, // ':' (58)
    {0x00, 0x56, 0x36, 0x00, 0x00}, // ';' (59)
    {0x08, 0x14, 0x22, 0x41, 0x00}, // '<' (60)
    {0x14, 0x14, 0x14, 0x14, 0x14}, // '=' (61)
    {0x00, 0x41, 0x22, 0x14, 0x08}, // '>' (62)
    {0x02, 0x01, 0x51, 0x09, 0x06}, // '?' (63)
    {0x32, 0x49, 0x79, 0x41, 0x3E}, // '@' (64)
    {0x7E, 0x11, 0x11, 0x11, 0x7E}, // 'A' (65)
    {0x7F, 0x49, 0x49, 0x49, 0x36}, // 'B' (66)
    {0x3E, 0x41, 0x41, 0x41, 0x22}, // 'C' (67)
    {0x7F, 0x41, 0x41, 0x22, 0x1C}, // 'D' (68)
    {0x7F, 0x49, 0x49, 0x49, 0x41}, // 'E' (69)
    {0x7F, 0x09, 0x09, 0x09, 0x01}, // 'F' (70)
    {0x3E, 0x41, 0x49, 0x49, 0x7A}, // 'G' (71)
    {0x7F, 0x08, 0x08, 0x08, 0x7F}, // 'H' (72)
    {0x00, 0x41, 0x7F, 0x41, 0x00}, // 'I' (73)
    {0x20, 0x40, 0x41, 0x3F, 0x01}, // 'J' (74)
    {0x7F, 0x08, 0x14, 0x22, 0x41}, // 'K' (75)
    {0x7F, 0x40, 0x40, 0x40, 0x40}, // 'L' (76)
    {0x7F, 0x02, 0x0C, 0x02, 0x7F}, // 'M' (77)
    {0x7F, 0x04, 0x08, 0x10, 0x7F}, // 'N' (78)
    {0x3E, 0x41, 0x41, 0x41, 0x3E}, // 'O' (79)
    {0x7F, 0x09, 0x09, 0x09, 0x06}, // 'P' (80)
    {0x3E, 0x41, 0x51, 0x21, 0x5E}, // 'Q' (81)
    {0x7F, 0x09, 0x19, 0x29, 0x46}, // 'R' (82)
    {0x46, 0x49, 0x49, 0x49, 0x31}, // 'S' (83)
    {0x01, 0x01, 0x7F, 0x01, 0x01}, // 'T' (84)
    {0x3F, 0x40, 0x40, 0x40, 0x3F}, // 'U' (85)
    {0x1F, 0x20, 0x40, 0x20, 0x1F}, // 'V' (86)
    {0x3F, 0x40, 0x38, 0x40, 0x3F}, // 'W' (87)
    {0x63, 0x14, 0x08, 0x14, 0x63}, // 'X' (88)
    {0x07, 0x08, 0x70, 0x08, 0x07}, // 'Y' (89)
    {0x61, 0x51, 0x49, 0x45, 0x43}, // 'Z' (90)
    {0x00, 0x7F, 0x41, 0x41, 0x00}, // '[' (91)
    {0x02, 0x04, 0x08, 0x10, 0x20}, // '\' (92)
    {0x00, 0x41, 0x41, 0x7F, 0x00}, // ']' (93)
    {0x04, 0x02, 0x01, 0x02, 0x04}, // '^' (94)
    {0x40, 0x40, 0x40, 0x40, 0x40}, // '_' (95)
    {0x00, 0x01, 0x02, 0x04, 0x00}, // '`' (96)
    {0x20, 0x54, 0x54, 0x54, 0x78}, // 'a' (97)
    {0x7F, 0x48, 0x44, 0x44, 0x38}, // 'b' (98)
    {0x38, 0x44, 0x44, 0x44, 0x20}, // 'c' (99)
    {0x38, 0x44, 0x44, 0x48, 0x7F}, // 'd' (100)
    {0x38, 0x54, 0x54, 0x54, 0x18}, // 'e' (101)
    {0x08, 0x7E, 0x09, 0x01, 0x02}, // 'f' (102)
    {0x0C, 0x52, 0x52, 0x52, 0x3E}, // 'g' (103)
    {0x7F, 0x08, 0x04, 0x04, 0x78}, // 'h' (104)
    {0x00, 0x44, 0x7D, 0x40, 0x00}, // 'i' (105)
    {0x20, 0x40, 0x44, 0x3D, 0x00}, // 'j' (106)
    {0x7F, 0x10, 0x28, 0x44, 0x00}, // 'k' (107)
    {0x00, 0x41, 0x7F, 0x40, 0x00}, // 'l' (108)
    {0x7C, 0x04, 0x18, 0x04, 0x78}, // 'm' (109)
    {0x7C, 0x08, 0x04, 0x04, 0x78}, // 'n' (110)
    {0x38, 0x44, 0x44, 0x44, 0x38}, // 'o' (111)
    {0x7C, 0x14, 0x14, 0x14, 0x08}, // 'p' (112)
    {0x08, 0x14, 0x14, 0x18, 0x7C}, // 'q' (113)
    {0x7C, 0x08, 0x04, 0x04, 0x08}, // 'r' (114)
    {0x48, 0x54, 0x54, 0x54, 0x20}, // 's' (115)
    {0x04, 0x3F, 0x44, 0x40, 0x20}, // 't' (116)
    {0x3C, 0x40, 0x40, 0x20, 0x7C}, // 'u' (117)
    {0x1C, 0x20, 0x40, 0x20, 0x1C}, // 'v' (118)
    {0x3C, 0x40, 0x30, 0x40, 0x3C}, // 'w' (119)
    {0x44, 0x28, 0x10, 0x28, 0x44}, // 'x' (120)
    {0x0C, 0x50, 0x50, 0x50, 0x3C}, // 'y' (121)
    {0x44, 0x64, 0x54, 0x4C, 0x44}, // 'z' (122)
    {0x00, 0x08, 0x36, 0x41, 0x00}, // '{' (123)
    {0x00, 0x00, 0x7F, 0x00, 0x00}, // '|' (124)
    {0x00, 0x41, 0x36, 0x08, 0x00}, // '}' (125)
    {0x08, 0x04, 0x08, 0x10, 0x08}, // '~' (126)
    {0x00, 0x06, 0x09, 0x09, 0x06}  // DEL (127)
};

void ssd1306_set_position(uint8_t page, uint8_t col);
void ssd1306_init(void);
void draw_char_cell(uint8_t row, uint8_t col, char c);
void clear_terminal_row(uint8_t row);
void terminal_native_scroll(void);
void terminal_put_char(char c);
void terminal_print(const char *str);
void terminal_init(void);

#endif

#endif /* WGRHAL_EXT_H */

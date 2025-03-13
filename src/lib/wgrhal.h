#ifndef WGRHAL_H
#define WGRHAL_H

#define MALLOC
#define PWM_NOTES
#define SSD1306

#include "wgrtypes.h"

#define SYSTEM_CLOCK 10000000

// Access to memory mapped registers
#ifndef HWREG32
#define HWREG32(addr) (*((volatile uint32_t *)(addr)))
#endif

// Addresses of memory mapped peripherals
#define DEBUG_ADDR         0x00000100

#define UART_BASE_ADDR     0x00000200
#define UART_CTRL_OFFSET   0x00
#define UART_BAUD_OFFSET   0x04
#define UART_STATUS_OFFSET 0x08
#define UART_TX_OFFSET     0x0C
#define UART_RX_OFFSET     0x10

#define TIME_BASE_ADDR     0x00000300
#define TIME_MS_L_OFFSET   0x00
#define TIME_MS_H_OFFSET   0x04
#define TIME_MIK_L_OFFSET  0x08
#define TIME_MIK_H_OFFSET  0x0C
#define SYS_CLK_OFFSET     0x10

#define PWM_BASE_ADDR      0x00000400
#define PWM_PERIOD_OFFSET  0x00
#define PWM_DUTY_OFFSET    0x04
#define PWM_COUNTER_OFFSET 0x08
#define PWM_CTRL_OFFSET    0x0C

#define GPIO_BASE_ADDR    0x00000800
#define GPIO_DIR_OFFSET   0x0000
#define GPIO_OUT_OFFSET   0x0004
#define GPIO_IN_OFFSET    0x0008

#define DEFAULT_TIMEOUT    10

// Standard Memory Functions
void *memcpy(void *dest, const void *src, uint32_t n);
void *memset(void *dest, int32_t c, uint32_t n);
void *memmove(void *dest, const void *src, uint32_t n);

// Standard String Functions
uint32_t strlen(const char *s);
int32_t strcmp(const char *s1, const char *s2);
int32_t strncmp(const char *s1, const char *s2, uint32_t n);
char *strcpy(char *dest, const char *src);
void int_to_str(int32_t num, int base, char *str);
int32_t parse_integer(const char *str);

// Writing to Debug Register
void debug_write(uint32_t value);

// UART Functions
void uart_enable(void);
void uart_disable(void);
void uart_set_baud(baud_sel_t baud);
uint32_t uart_get_status(void);
uint32_t uart_is_ready(void);
uint32_t uart_is_busy(void);
uint32_t uart_rx_full(void);
uint32_t uart_rx_empty(void);
uint32_t uart_tx_full(void);
uint32_t uart_tx_empty(void);
int32_t uart_wait_tx_full(uint32_t timeout_ms);
int32_t uart_wait_rx_data(uint32_t timeout_ms);
int32_t uart_write_byte(uint8_t data, uint32_t timeout_ms);
int32_t uart_putchar(char c, uint32_t timeout_ms);
void uart_putchar_default_timeout(char c);
int32_t uart_write_buffer(const uint8_t *buffer, uint32_t length, uint32_t timeout_ms);
int32_t uart_read_byte(uint8_t *data, uint32_t timeout_ms);
char uart_getchar(uint32_t timeout_ms);
int32_t uart_read_buffer(uint8_t *buf, uint32_t length, uint32_t timeout_ms);
void uart_send_uint32(uint32_t value, uint32_t timeout_ms);
void uart_print_uint(uint32_t num, int32_t base);
void uart_print_int(int32_t num);
void uart_print(const char *s);

// Time Functions
uint32_t get_sys_clk(void);
void millis_reset(void);
uint64_t millis_long(void);
uint32_t millis(void);
void micros_reset(void);
uint64_t micros_long(void);
uint32_t micros(void);
void delay(uint32_t ms);
void delay_micro(uint32_t microsec);

// PWM Functions
void pwm_set_period(uint32_t period);
void pwm_set_duty(uint32_t duty);
uint32_t pwm_get_period(void);
uint32_t pwm_get_duty(void);
uint32_t pwm_get_counter(void);
void pwm_set_control(uint32_t control);
uint32_t pwm_get_control(void);
void pwm_set_mode(uint8_t enable_pwm);
uint32_t pwm_get_mode(void);
void pwm_set_50_percent_mode(uint8_t enable);
void pwm_set_pre_counter(uint16_t pre_counter);
uint32_t pwm_get_pre_counter(void);

// GPIO Functions
void gpio_set_pin_direction(uint8_t pin, uint8_t is_input);
void gpio_write_pin(uint8_t pin, uint8_t value);
uint8_t gpio_read_pin(uint8_t pin);
void gpio_set_direction(uint32_t dir_mask);
void gpio_write(uint32_t value);
uint32_t gpio_read(void);

#endif /* WGRHAL_H */

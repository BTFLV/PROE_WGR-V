#ifndef WGRHAL_H
#define WGRHAL_H

#define ADVANCED

#define SSD1306

#include "wgrtypes.h"

#define SYSTEM_CLOCK 10000000

#ifndef HWREG32
#define HWREG32(addr) (*((volatile uint32_t *)(addr)))
#endif

#define DEBUG_ADDR 0x00000100

#define UART_BASE_ADDR 0x00000200
#define UART_CTRL_OFFSET 0x00
#define UART_BAUD_OFFSET 0x04
#define UART_STATUS_OFFSET 0x08
#define UART_TX_OFFSET 0x0C
#define UART_RX_OFFSET 0x10

#define TIME_BASE_ADDR 0x00000300
#define TIME_MS_L_OFFSET 0x00
#define TIME_MS_H_OFFSET 0x04
#define TIME_MIK_L_OFFSET 0x08
#define TIME_MIK_H_OFFSET 0x0C
#define SYS_CLK_OFFSET 0x10

#define PWM_BASE_ADDR 0x00000400
#define PWM_PERIOD_OFFSET 0x00
#define PWM_DUTY_OFFSET 0x04
#define PWM_COUNTER_OFFSET 0x08
#define PWM_CTRL_OFFSET 0x0C

#define DEFAULT_TIMEOUT 10

void *memcpy(void *dest, const void *src, uint32_t n);
void *memset(void *dest, int32_t c, uint32_t n);
void *memmove(void *dest, const void *src, uint32_t n);

uint32_t strlen(const char *s);
int32_t strcmp(const char *s1, const char *s2);
int32_t strncmp(const char *s1, const char *s2, uint32_t n);
char *strcpy(char *dest, const char *src);

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
void uart_printf(const char *fmt, ...);

void millis_reset(void);
uint64_t millis_long(void);
uint32_t millis(void);
void micros_reset(void);
uint64_t micros_long(void);
uint32_t micros(void);
void delay(uint32_t ms);
void delay_micro(uint32_t microsec);

void debug_write(uint32_t value);
void debug_write_raw(void *value);

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

#ifdef ADVANCED

extern char _heap_start;
extern char _heap_end;
extern char _sstack;
extern char _estack;

typedef enum
{
    NOTE_C = 0,
    NOTE_Cs = 1,
    NOTE_D = 2,
    NOTE_Ds = 3,
    NOTE_E = 4,
    NOTE_F = 5,
    NOTE_Fs = 6,
    NOTE_G = 7,
    NOTE_Gs = 8,
    NOTE_A = 9,
    NOTE_As = 10,
    NOTE_B = 11
} note_t;

extern const uint8_t note_freq_halfbase[12];

int pwm_precompute_notes_malloc(void);
void pwm_play_note_malloc(note_t note, uint32_t octave);
void pwm_free_note_buffer(void);

void *malloc(uint32_t size);
void free(void *ptr);
void *realloc(void *ptr, uint32_t size);
void *calloc(uint32_t nmemb, uint32_t size);
uint32_t heap_free_space(void);

#endif

#endif /* WGRHAL_H */

#include "wgrhal.h"

void *memcpy(void *dest, const void *src, uint32_t n)
{
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;
    while (n--)
    {
        *d++ = *s++;
    }
    return dest;
}

void *memset(void *dest, int32_t c, uint32_t n)
{
    unsigned char *d = (unsigned char *)dest;
    while (n--)
    {
        *d++ = (unsigned char)c;
    }
    return dest;
}

void *memmove(void *dest, const void *src, uint32_t n)
{
    unsigned char *d = (unsigned char *)dest;
    const unsigned char *s = (const unsigned char *)src;
    if (d < s)
    {
        while (n--)
        {
            *d++ = *s++;
        }
    }
    else if (d > s)
    {
        d += n;
        s += n;
        while (n--)
        {
            *(--d) = *(--s);
        }
    }
    return dest;
}

uint32_t strlen(const char *s)
{
    uint32_t len = 0;
    while (*s++)
    {
        len++;
    }
    return len;
}

int32_t strcmp(const char *s1, const char *s2)
{
    while (*s1 && (*s1 == *s2))
    {
        s1++;
        s2++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
}

int32_t strncmp(const char *s1, const char *s2, uint32_t n)
{
    while (n && *s1 && (*s1 == *s2))
    {
        s1++;
        s2++;
        n--;
    }
    if (n == 0)
    {
        return 0;
    }
    else
    {
        return (int)((unsigned char)*s1 - (unsigned char)*s2);
    }
}

char *strcpy(char *dest, const char *src)
{
    char *d = dest;
    while ((*d++ = *src++))
        ;
    return dest;
}

void uart_enable(void)
{

    HWREG32(UART_BASE_ADDR + UART_CTRL_OFFSET) |= (uint32_t)1;
}

void uart_disable(void)
{

    HWREG32(UART_BASE_ADDR + UART_CTRL_OFFSET) &= ~(uint32_t)1;
}

void uart_set_baud(baud_sel_t baud)
{
    if (baud > 11)
    {
        baud = BAUD_9600;
    }
    HWREG32(UART_BASE_ADDR + UART_BAUD_OFFSET) = baud;
}

uint32_t uart_get_status(void)
{
    return HWREG32(UART_BASE_ADDR + UART_STATUS_OFFSET);
}

uint32_t uart_is_ready(void)
{
    return ((uart_get_status() >> 5) & (uint32_t)1);
}

uint32_t uart_is_busy(void)
{
    return ((uart_get_status() >> 4) & (uint32_t)1);
}

uint32_t uart_rx_full(void)
{
    return ((uart_get_status() >> 3) & (uint32_t)1);
}

uint32_t uart_rx_empty(void)
{
    return ((uart_get_status() >> 2) & (uint32_t)1);
}

uint32_t uart_tx_full(void)
{
    return ((uart_get_status() >> 1) & (uint32_t)1);
}

uint32_t uart_tx_empty(void)
{
    return ((uart_get_status() >> 0) & (uint32_t)1);
}

int32_t uart_wait_tx_full(uint32_t timeout_ms)
{
    uint32_t start_time = millis();

    while (uart_tx_full())
    {
        if ((millis() - start_time) >= timeout_ms)
        {
            return -1;
        }
        __asm__ volatile("nop");
    }
    return 0;
}

int32_t uart_wait_rx_data(uint32_t timeout_ms)
{
    uint32_t start_time = millis();

    while (uart_rx_empty())
    {
        if ((millis() - start_time) >= timeout_ms)
        {
            return -1;
        }
        __asm__ volatile("nop");
    }
    return 0;
}

int32_t uart_write_byte(uint8_t data, uint32_t timeout_ms)
{
    if (uart_tx_full())
    {
        int32_t ret = uart_wait_tx_full(timeout_ms);
        if (ret != 0)
        {
            return ret;
        }
    }

    uart_tx_full();
    HWREG32(UART_BASE_ADDR + UART_TX_OFFSET) = (uint32_t)data;
    return 0;
}

int32_t uart_putchar(char c, uint32_t timeout_ms)
{
    return uart_write_byte((uint8_t)c, timeout_ms);
}

void uart_putchar_default_timeout(char c)
{
    uart_putchar(c, DEFAULT_TIMEOUT);
}

int32_t uart_write_buffer(const uint8_t *buffer, uint32_t length, uint32_t timeout_ms)
{
    if (buffer == NULL || length == 0)
    {
        return -1;
    }

    for (uint32_t i = 0; i < length; i++)
    {
        int32_t ret = uart_write_byte(buffer[i], timeout_ms);
        if (ret != 0)
        {
            return ret;
        }
    }

    return 0;
}

int32_t uart_read_byte(uint8_t *data, uint32_t timeout_ms)
{
    int32_t ret = uart_wait_rx_data(timeout_ms);
    if (ret != 0)
    {
        return ret;
    }
    *data = (uint8_t)HWREG32(UART_BASE_ADDR + UART_RX_OFFSET);
    return 0;
}

char uart_getchar(uint32_t timeout_ms)
{
    uint8_t byte;
    int32_t ret = uart_read_byte(&byte, timeout_ms);
    if (ret != 0)
    {
        return -1;
    }
    return (char)byte;
}

int32_t uart_read_buffer(uint8_t *buf, uint32_t length, uint32_t timeout_ms)
{
    if (buf == 0)
    {
        return -1;
    }
    for (uint32_t i = 0; i < length; i++)
    {
        int32_t ret = uart_read_byte(&buf[i], timeout_ms);
        if (ret < 0)
        {
            return ret;
        }
    }
    return 0;
}

void uart_send_uint32(uint32_t value, uint32_t timeout_ms)
{
    uint8_t buffer[4];
    buffer[0] = (value >> 24) & 0xFF;
    buffer[1] = (value >> 16) & 0xFF;
    buffer[2] = (value >> 8) & 0xFF;
    buffer[3] = value & 0xFF;

    uart_write_buffer(buffer, sizeof(buffer), timeout_ms);
}

static void int_to_str(uint32_t num, int32_t base, char *buf)
{
    int32_t i = 0;
    do
    {
        int32_t digit = num % base;
        buf[i++] = (digit < 10) ? ('0' + digit) : ('a' + digit - 10);
        num /= base;
    } while (num > 0);

    int32_t j = 0;
    while (j < i / 2)
    {
        char temp = buf[j];
        buf[j] = buf[i - j - 1];
        buf[i - j - 1] = temp;
        j++;
    }
    buf[i] = '\0';
}

void uart_print_uint(uint32_t num, int32_t base)
{
    char buffer[16];
    int_to_str(num, base, buffer);
    for (int i = 0; buffer[i] != '\0'; i++)
    {
        uart_putchar_default_timeout(buffer[i]);
    }
}

void uart_print_int(int32_t num)
{
    if (num < 0)
    {
        uart_putchar_default_timeout('-');
        num = -num;
    }
    uart_print_uint((uint32_t)num, 10);
}

void uart_print(const char *s)
{
    while (*s)
    {
        uart_putchar_default_timeout(*s++);
    }
}

void uart_printf(const char *fmt, ...)
{
    va_list args;
    va_start(args, fmt);
    while (*fmt)
    {
        if (*fmt == '%')
        {
            fmt++;
            switch (*fmt)
            {
            case 'c':
            {

                int c = va_arg(args, int);
                uart_putchar_default_timeout((char)c);
                break;
            }
            case 's':
            {
                char *s = va_arg(args, char *);
                while (*s)
                {
                    uart_putchar_default_timeout(*s++);
                }
                break;
            }
            case 'd':
            {
                int32_t d = va_arg(args, int32_t);
                uart_print_int(d);
                break;
            }
            case 'u':
            {
                uint32_t u = va_arg(args, uint32_t);
                uart_print_uint(u, 10);
                break;
            }
            case 'x':
            {
                uint32_t x = va_arg(args, uint32_t);
                uart_print_uint(x, 16);
                break;
            }
            case '%':
            {
                uart_putchar_default_timeout('%');
                break;
            }
            default:

                uart_putchar_default_timeout('%');
                uart_putchar_default_timeout(*fmt);
                break;
            }
        }
        else
        {
            uart_putchar_default_timeout(*fmt);
        }
        fmt++;
    }
    va_end(args);
}

uint32_t get_sys_clk(void)
{
    return HWREG32(TIME_BASE_ADDR + SYS_CLK_OFFSET);
}

void millis_reset(void)
{
    HWREG32(TIME_BASE_ADDR + TIME_MS_L_OFFSET) = (uint32_t)0;
}

uint64_t millis_long(void)
{
    uint32_t high1, high2, low;

    do
    {
        high1 = HWREG32(TIME_BASE_ADDR + TIME_MS_H_OFFSET);
        low = HWREG32(TIME_BASE_ADDR + TIME_MS_L_OFFSET);
        high2 = HWREG32(TIME_BASE_ADDR + TIME_MS_H_OFFSET);
    } while (high1 != high2);

    return (((uint64_t)high1) << 32) | low;
}

uint32_t millis(void)
{
    return HWREG32(TIME_BASE_ADDR + TIME_MS_L_OFFSET);
}

void micros_reset(void)
{
    HWREG32(TIME_BASE_ADDR + TIME_MIK_L_OFFSET) = (uint32_t)0;
}

uint64_t micros_long(void)
{
    uint32_t high1, high2, low;

    do
    {
        high1 = HWREG32(TIME_BASE_ADDR + TIME_MIK_H_OFFSET);
        low = HWREG32(TIME_BASE_ADDR + TIME_MIK_L_OFFSET);
        high2 = HWREG32(TIME_BASE_ADDR + TIME_MIK_H_OFFSET);
    } while (high1 != high2);

    return (((uint64_t)high1) << 32) | low;
}

uint32_t micros(void)
{
    return HWREG32(TIME_BASE_ADDR + TIME_MIK_L_OFFSET);
}

void delay(uint32_t ms)
{
    uint32_t start_time = millis();
    while ((millis() - start_time) < ms)
    {
        __asm__ volatile("nop");
    }
}

void delay_micro(uint32_t microsec)
{
    uint32_t start_time = micros();
    while ((micros() - start_time) < microsec)
    {
        __asm__ volatile("nop");
    }
}

void debug_write(uint32_t value)
{
    HWREG32(DEBUG_ADDR) = value;
}

void debug_write_raw(void *value)
{
    const uint32_t *aligned_value = (const uint32_t *)((uint32_t)value & ~0x3);
    volatile uint32_t *debug_reg = (volatile uint32_t *)DEBUG_ADDR;
    *debug_reg = *aligned_value;
}

void pwm_set_period(uint32_t period)
{
    HWREG32(PWM_BASE_ADDR + PWM_PERIOD_OFFSET) = period;
}

void pwm_set_duty(uint32_t duty)
{
    HWREG32(PWM_BASE_ADDR + PWM_DUTY_OFFSET) = duty;
}

uint32_t pwm_get_period(void)
{
    return HWREG32(PWM_BASE_ADDR + PWM_PERIOD_OFFSET);
}

uint32_t pwm_get_duty(void)
{
    return HWREG32(PWM_BASE_ADDR + PWM_DUTY_OFFSET);
}

uint32_t pwm_get_counter(void)
{
    return HWREG32(PWM_BASE_ADDR + PWM_COUNTER_OFFSET);
}

void pwm_set_control(uint32_t control)
{
    HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET) = control;
}

uint32_t pwm_get_control(void)
{
    return HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET);
}

void pwm_set_mode(uint8_t enable_pwm)
{
    uint32_t ctrl = HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET);
    if (enable_pwm)
        ctrl |= 0x1;
    else
        ctrl &= ~0x1;
    HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET) = ctrl;
}

void pwm_set_50_percent_mode(uint8_t enable)
{
    uint32_t ctrl = HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET);
    if (enable)
        ctrl |= 0x2;
    else
        ctrl &= ~0x2;
    HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET) = ctrl;
}

void pwm_set_pre_counter(uint16_t pre_counter)
{
    uint32_t ctrl = HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET);
    ctrl = (ctrl & 0x0000FFFF) | (((uint32_t)pre_counter) << 16);
    HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET) = ctrl;
}

uint32_t pwm_get_pre_counter(void)
{
    uint32_t pwm_ctrl = HWREG32(PWM_BASE_ADDR + PWM_CTRL_OFFSET);
    return (pwm_ctrl >> 16);
}

#ifdef ADVANCED

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

int pwm_precompute_notes_malloc(void)
{
    uint32_t sys_clk = get_sys_clk();
    debug_write(sys_clk);

    if (!note_buffer)
    {
        note_buffer = (uint32_t *)malloc(12 * sizeof(uint32_t));
        if (!note_buffer)
        {
            return -1;
        }
    }

    for (int i = 0; i < 1; i++)
    {
        note_buffer[i] = (uint32_t)(sys_clk / note_freq_halfbase[i]);
        debug_write(note_buffer[i]);
    }

    return 0;
}

void pwm_play_note_malloc(note_t note, uint32_t octave)
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

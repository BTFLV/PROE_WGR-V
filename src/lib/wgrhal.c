#include "wgrhal.h"

// ----------------------- WGR-V -----------------------
//
//              Standard Memory Functions
//
//------------------------------------------------------

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

// ----------------------- WGR-V -----------------------
//
//              Standard String Functions
//
//------------------------------------------------------

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

void int_to_str(int32_t num, int base, char *str)
{
    char temp[35];
    int i = 0, j = 0;
    int is_negative = 0;

    if (base < 2 || base > 16)
    {
        str[0] = '\0';
        return;
    }

    if (num == 0)
    {
        str[j++] = '0';
        str[j] = '\0';
        return;
    }

    if (num < 0 && base == 10)
    {
        num = -num;
    }

    while (num != 0)
    {
        int rem = num % base;
        temp[i++] = (rem > 9) ? (rem - 10) + 'A' : rem + '0';
        num /= base;
    }

    if (is_negative)
    {
        temp[i++] = '-';
    }

    while (i > 0)
    {
        str[j++] = temp[--i];
    }
    str[j] = '\0';
}

int32_t parse_integer(const char *str)
{
    int result = 0;
    int sign = 1;

    while (*str == ' ')
    {
        str++;
    }

    if (*str == '-')
    {
        sign = -1;
        str++;
    }

    if (*str < '0' || *str > '9')
    {
        return -1;
    }

    while (*str >= '0' && *str <= '9')
    {
        result = result * 10 + (*str - '0');
        str++;
    }

    while (*str == ' ' || *str == '\n')
    {
        str++;
    }

    if (*str != '\0') {
        return -1;
    }

    return result * sign;
}

// ----------------------- WGR-V -----------------------
//
//              Writing to Debug Register
//
//------------------------------------------------------

void debug_write(uint32_t value)
{
    HWREG32(DEBUG_ADDR) = value;
}

// ----------------------- WGR-V -----------------------
//
//                    UART Functions
//
//------------------------------------------------------

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

void uart_print_uint(uint32_t num, int32_t base)
{
    char buffer[33];

    if (base < 2 || base > 16)
    {
        return;
    }

    if (num == 0)
    {
        uart_putchar_default_timeout('0');
        return;
    }

    int i = 0;
    while (num > 0)
    {
        uint32_t digit = num % base;
        buffer[i++] = (digit < 10) ? ('0' + digit) : ('A' + (digit - 10));
        num /= base;
    }

    while (i--)
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

// ----------------------- WGR-V -----------------------
//
//                    Time Functions
//
//------------------------------------------------------

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
        //__asm__ volatile("nop");
    }
}

// ----------------------- WGR-V -----------------------
//
//                    PWM Functions
//
//------------------------------------------------------

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

// ----------------------- WGR-V -----------------------
//
//                    GPIO Functions
//
//------------------------------------------------------

void gpio_write_pin(uint8_t pin, uint8_t value)
{
    if (pin < GPIO_PIN_COUNT)
    {
        HWREG32(GPIO_BASE_ADDR + GPIO_OUT_OFFSET + (pin * GPIO_OUT_STEP)) = value;
    }
}

uint8_t gpio_read_all_pins(void)
{
    return (uint8_t)(HWREG32(GPIO_BASE_ADDR + GPIO_IN_OFFSET) & 0xFF);
}

uint8_t gpio_read_pin(uint8_t pin)
{
    if (pin < GPIO_PIN_COUNT) {
        return (gpio_read_all_pins() >> pin) & 0x01;
    }
    return 0;
}

void gpio_set_direction(uint8_t pin, uint8_t direction)
{
    uint32_t dir = HWREG32(GPIO_BASE_ADDR + GPIO_DIR_OFFSET);
    
    if (direction) {
        dir |= (1 << pin);
    } else {
        dir &= ~(1 << pin);
    }

    HWREG32(GPIO_BASE_ADDR + GPIO_DIR_OFFSET) = dir;
}

uint8_t gpio_read_direction(uint8_t pin)
{
    uint32_t dir = HWREG32(GPIO_BASE_ADDR + GPIO_DIR_OFFSET);
    return (dir >> pin) & 0x01;
}

#include "wgrhal.h"

#define ITER_GENERAL 8
#define ITER_SOFTLIB 1
#define ARRAY_SIZE 64

uint32_t conv_time(uint32_t benchmark_iter_time, uint32_t iterations)
{
    uint32_t start = micros();
    uint32_t end = micros();
    uint32_t offset = end - start;
    uint32_t benchmark_time = (benchmark_iter_time / iterations) - offset;
    return benchmark_time;
}

uint32_t benchmark_loop() {
    volatile uint32_t sum = 0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        sum += i;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_array_write() {
    volatile uint32_t array[ARRAY_SIZE];
    uint32_t start = micros();
    for (uint32_t i = 0; i < ARRAY_SIZE; i++) {
        array[i] = i;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_array_read() {
    volatile uint32_t array[ARRAY_SIZE];
    volatile uint32_t sum = 0;
    for (uint32_t i = 0; i < ARRAY_SIZE; i++) {
        array[i] = i;
    }
    uint32_t start = micros();
    for (uint32_t i = 0; i < ARRAY_SIZE; i++) {
        sum += array[i];
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_conditional() {
    volatile uint32_t count = 0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        if (i % 2 == 0) {
            count++;
        }
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_bitwise_xor() {
    volatile uint32_t value = 0xF0F0F0F0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        value ^= 0x0F0F0F0F;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_simple_logic() {
    volatile uint32_t a = 0, b = 1, result = 0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        if (a != b) {
            result++;
        }
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_increment() {
    volatile uint32_t a = 0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        a++;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_malloc_free() {
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        volatile uint32_t* ptr = (uint32_t*)malloc(sizeof(uint32_t));
        *ptr = i;
        free((void*)ptr);
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_16bit_addition() {
    volatile uint16_t a = 1000, b = 2000, result = 0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        result = a + b;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_8bit_addition() {
    volatile uint8_t a = 100, b = 150, result = 0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        result = a + b;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_8bit_bitwise() {
    volatile uint8_t a = 0xAA, b = 0x55, result = 0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        result = a ^ b;
        result &= a;
        result |= b;
        result = ~result;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_16bit_shift() {
    volatile uint16_t a = 0x0F0F;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_GENERAL; i++) {
        a <<= 1;
        a >>= 1;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_addition()
{
    volatile float a = 0.0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_SOFTLIB; i++)
    {
        a += 0.000001f;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_multiplication()
{
    volatile float a = 1.0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_SOFTLIB; i++)
    {
        a *= 1.000001f;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_division()
{
    volatile float a = 1.0;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_SOFTLIB; i++)
    {
        a /= 1.000001f;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_integer_multiplication()
{
    volatile uint32_t a = 1;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_SOFTLIB; i++)
    {
        a *= 3;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_integer_division()
{
    volatile uint32_t a = 1000000;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_SOFTLIB; i++)
    {
        a /= 3;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_bitwise_shift()
{
    volatile uint32_t a = 1;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_SOFTLIB; i++)
    {
        a <<= 1;
    }
    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_conversion()
{
    volatile int32_t a = 123456;
    volatile float b = 0.0f;
    uint32_t start = micros();
    for (uint32_t i = 0; i < ITER_SOFTLIB; i++)
    {
        b = (float)a;
        a = (int32_t)b;
    }
    uint32_t end = micros();
    return end - start;
}

int main()
{
    // 10MHz Results
    debug_write(conv_time(benchmark_loop(), ITER_GENERAL));
    //   1µs
    debug_write(conv_time(benchmark_array_write(), ITER_GENERAL));
    //  29µs
    debug_write(conv_time(benchmark_array_read(), ITER_GENERAL));
    //  47µs
    debug_write(conv_time(benchmark_conditional(), ITER_GENERAL));
    //   2µs
    debug_write(conv_time(benchmark_bitwise_xor(), ITER_GENERAL));
    //   2µs
    debug_write(conv_time(benchmark_simple_logic(), ITER_GENERAL));
    //   4µs
    debug_write(conv_time(benchmark_increment(), ITER_GENERAL));
    //   2µs
    debug_write(conv_time(benchmark_malloc_free(), ITER_GENERAL));
    //  63µs
    debug_write(conv_time(benchmark_16bit_addition(), ITER_GENERAL));
    //   4µs
    debug_write(conv_time(benchmark_8bit_addition(), ITER_GENERAL));
    //   2µs
    debug_write(conv_time(benchmark_8bit_bitwise(), ITER_GENERAL));
    //  13µs
    debug_write(conv_time(benchmark_16bit_shift(), ITER_GENERAL));
    //   6µs
    debug_write(conv_time(benchmark_addition(), ITER_SOFTLIB));
    //  11µs
    debug_write(conv_time(benchmark_multiplication(), ITER_SOFTLIB));
    // 223µs
    debug_write(conv_time(benchmark_division(), ITER_SOFTLIB));
    // 710µs
    debug_write(conv_time(benchmark_integer_multiplication(), ITER_SOFTLIB));
    //   4µs
    debug_write(conv_time(benchmark_integer_division(), ITER_SOFTLIB));
    // 156µs
    debug_write(conv_time(benchmark_bitwise_shift(), ITER_SOFTLIB));
    //   2µs
    debug_write(conv_time(benchmark_conversion(), ITER_SOFTLIB));
    //  70µs
    while(1);
}

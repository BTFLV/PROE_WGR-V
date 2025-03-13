#include "wgrhal.h"
#include "wgrhal_ext.h"

#define ITERATIONS 8
#define RANDOM_SEED 0x12345678

volatile uint32_t *random_numbers_32 = NULL;
volatile uint64_t *random_numbers_64 = NULL;

uint32_t conv_time(uint32_t benchmark_iter_time, uint32_t iterations)
{
    uint32_t start = micros();
    uint32_t end = micros();
    uint32_t offset = end - start;
    uint32_t benchmark_time = (benchmark_iter_time - offset) / iterations;
    return benchmark_time;
}

static uint32_t xorshift32(uint32_t *state)
{
    uint32_t x = *state;
    x ^= x << 13;
    x ^= x >> 17;
    x ^= x << 5;
    *state = x;
    return x;
}

static uint64_t xorshift64(uint64_t *state)
{
    uint64_t x = *state;
    x ^= x << 13;
    x ^= x >> 7;
    x ^= x << 17;
    *state = x;
    return x;
}

void generate_random_numbers_32(uint32_t size, uint32_t seed)
{
    random_numbers_32 = (uint32_t *)malloc(size * sizeof(uint32_t));
    if (random_numbers_32 == NULL)
    {
        return;
    }

    uint32_t state = seed;
    for (uint32_t i = 0; i < size; i++)
    {
        random_numbers_32[i] = xorshift32(&state);
    }
}

void free_random_numbers_32(void)
{
    if (random_numbers_32 != NULL)
    {
        free((void *)random_numbers_32);
        random_numbers_32 = NULL;
    }
}

void generate_random_numbers_64(uint32_t size, uint64_t seed)
{
    random_numbers_64 = (uint64_t *)malloc(size * sizeof(uint64_t));
    if (random_numbers_64 == NULL)
    {
        return;
    }

    uint64_t state = seed;
    for (uint32_t i = 0; i < size; i++)
    {
        random_numbers_64[i] = xorshift64(&state);
    }
}

void free_random_numbers_64(void)
{
    if (random_numbers_64 != NULL)
    {
        free((void *)random_numbers_64);
        random_numbers_64 = NULL;
    }
}

uint32_t benchmark_multiplication_32(void)
{
    volatile uint32_t a = 0;
    uint32_t start = micros();

    for (uint32_t i = 0; i < ITERATIONS; i++)
    {
        a = random_numbers_32[i] * random_numbers_32[i + 1];
    }

    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_multiplication_64(void)
{
    volatile uint32_t a = 0;
    uint32_t start = micros();

    for (uint32_t i = 0; i < ITERATIONS; i++)
    {
        a = random_numbers_64[i] * random_numbers_64[i + 1];
    }

    uint32_t end = micros();
    return end - start;
}

uint32_t benchmark_division_32()
{
    volatile uint32_t a = 0;
    uint32_t start = micros();

    for (uint32_t i = 0; i < ITERATIONS; i++)
    {
        a = random_numbers_32[i] / random_numbers_32[i + 1];
    }

    uint32_t end = micros();
    return end - start;
}

// Benchmark Software vs Hardware Multiplication and Division
//
// 10MHz Software Results:
// uint32_t = uint32_t * uint32_t: 108µs
// uint32_t = uint64_t * uint64_t: 144µs
// uint32_t = uint32_t / uint32_t: 111µs
//
// 10MHz Hardware Results:
// uint32_t = uint32_t * uint32_t: 12µs 11%
// uint32_t = uint64_t * uint64_t: 13µs 9%
// uint32_t = uint32_t / uint32_t: 15µs 13%

int main()
{
    generate_random_numbers_32(ITERATIONS + 1, RANDOM_SEED);
    debug_write(conv_time(benchmark_multiplication_32(), ITERATIONS));
    debug_write(conv_time(benchmark_division_32(), ITERATIONS));
    free_random_numbers_32();

    generate_random_numbers_64(ITERATIONS + 1, RANDOM_SEED);
    debug_write(conv_time(benchmark_multiplication_64(), ITERATIONS));
    free_random_numbers_64();

    while(1);
}

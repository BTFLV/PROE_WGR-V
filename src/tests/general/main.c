#include <wgrhal.h>

#define ARRAY_SIZE 64

void debug_time()
{
    debug_write(0xEEEEEEEE);
    debug_write(millis());
    debug_write(0xEEEEEEEE);
}

void test_arithmetic()
{
    int32_t a = 2147483647, b = -2147483648;
    debug_write(a + 1);
    debug_write(b - 1);
    debug_write((uint32_t)(b / -1));
}

void test_shifts()
{
    int32_t x = -1;
    debug_write(x >> 31);
    debug_write(x << 31);
}

void test_signed_unsigned()
{
    int32_t s = -5;
    uint32_t u = 5;

    debug_write(s < u);
    debug_write((uint32_t)s > u);
}

void test_memory_alignment()
{
    volatile uint8_t misaligned[5] = {0x12, 0x34, 0x56, 0x78, 0x9A};

    uint16_t *ptr16 = (uint16_t *)(misaligned + 1);
    debug_write(*ptr16);

    uint32_t *ptr32 = (uint32_t *)(misaligned + 1);
    debug_write(*ptr32);
}

void test_self_modifying_code()
{
    uint32_t *code_ptr = (uint32_t *)test_self_modifying_code;

    uint32_t original_instruction = *code_ptr;

    *code_ptr = 0x00000013;

    debug_write(*code_ptr);

    *code_ptr = original_instruction;

    debug_write(*code_ptr);
}

uint32_t deep_recursion(uint32_t depth)
{
    if (depth == 0)
        return 1;
    return 1 + deep_recursion(depth - 1);
}

void test_recursion()
{
    debug_write(deep_recursion(100));
}

void test_branch_prediction()
{
    uint32_t x = 0;

    for (uint32_t i = 0; i < 100; i++)
    {
        if (i % 2 == 0)
            x++;
        else
            x--;
    }

    debug_write(x);
}

void test_64bit()
{
    uint64_t a = 0xFFFFFFFF00000000ULL;
    uint64_t b = 0x00000000FFFFFFFFULL;
    uint64_t c = a * b;

    debug_write((uint32_t)(c >> 32));
    debug_write((uint32_t)(c));
}

void test_floating_point()
{
    float f1 = 1.0f / 3.0f;
    float f2 = f1 * 3.0f;
    float f3 = 1.0f / 0.0f;
    float f4 = 0.0f / 0.0f;

    debug_write((int)f2);
    debug_write(*(uint32_t *)&f3);
    debug_write(*(uint32_t *)&f4);
}

void stress_test()
{
    volatile uint32_t result = 0;
    volatile uint32_t product = 1;
    volatile uint32_t sum = 0;
    volatile uint32_t fib = 0;
    volatile uint32_t i, j;
    volatile uint32_t data[ARRAY_SIZE];

    for (i = 0; i < ARRAY_SIZE; i++)
    {
        data[i] = i + 1;
    }

    for (i = 1; i < 500; i++)
    {

        product = product * (i | 1);
        product ^= (i << 3);
        product += (i >> 2);

        if ((i & 0x3F) == 0)
        {
            product = product / ((i & 0xFF) + 1);
        }

        {
            volatile uint32_t a = 0, b = 1;

            for (j = 0; j < (i % 20 + 5); j++)
            {
                fib = a + b;
                a = b;
                b = fib;
            }
        }

        sum = 0;
        for (j = 0; j < ARRAY_SIZE; j++)
        {
            if (((i + j) & 1) == 0)
                sum += data[j];
            else
                sum ^= data[j];
        }

        result = result + product + fib + sum;

        result = (result << 2) | (result >> 3);

        data[i % ARRAY_SIZE] = result ^ data[(i + 7) % ARRAY_SIZE];
    }

    debug_write(result);
}

int main()
{
    uint32_t hw = 69;
    debug_write(0xBBBB0001);
    test_arithmetic();
    debug_time();
    debug_write(0xBBBB0002);
    test_shifts();
    debug_time();
    debug_write(0xBBBB0003);
    test_signed_unsigned();
    debug_time();
    debug_write(0xBBBB0004);
    test_memory_alignment();
    debug_time();
    debug_write(0xBBBB0005);
    test_self_modifying_code();
    debug_time();
    debug_write(0xBBBB0006);
    test_recursion();
    debug_time();
    debug_write(0xBBBB0007);
    test_branch_prediction();
    debug_time();
    debug_write(0xBBBB0008);
    test_64bit();
    debug_time();
    debug_write(0xBBBB0009);
    test_floating_point();
    debug_time();

    debug_write(0xDEADBEEF);

    return 0;
}

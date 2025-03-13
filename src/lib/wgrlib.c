#include "wgrtypes.h"

//#define HARDWAREDIVISION

typedef union
{
    float f;
    uint32_t i;
} float_union;

#define FLOAT_SIGN(x) ((x) >> 31)
#define FLOAT_EXP(x) (((x) >> 23) & 0xFF)
#define FLOAT_MANT(x) ((x) & 0x7FFFFF)
#define FLOAT_BIAS 127
#define FLOAT_RECONSTRUCT(sign, exp, mant) (((sign) << 31) | ((exp) << 23) | (mant))

#ifdef HARDWAREDIVISION

#ifndef HWREG32
#define HWREG32(addr) (*((volatile uint32_t *)(addr)))
#endif

#define MULT_BASE_ADDR    0x00000500
#define MULT_INFO_OFFSET  0x0000
#define MUL1_OFFSET       0x0004
#define MUL2_OFFSET       0x0008
#define RESH_OFFSET       0x000C
#define RESL_OFFSET       0x0010

#define DIV_BASE_ADDR     0x00000600
#define DIV_INFO_OFFSET   0x00
#define DIV_END_OFFSET    0x04
#define DIV_SOR_OFFSET    0x08
#define DIV_QUO_OFFSET    0x0C
#define DIV_REM_OFFSET    0x10

static inline uint64_t mult_calc_64(uint32_t multiplicand, uint32_t multiplier)
{
    HWREG32(MULT_BASE_ADDR + MUL1_OFFSET) = multiplicand;
    HWREG32(MULT_BASE_ADDR + MUL2_OFFSET) = multiplier;

    while (HWREG32(MULT_BASE_ADDR + MULT_INFO_OFFSET));

    uint64_t high = (uint64_t)HWREG32(MULT_BASE_ADDR + RESH_OFFSET);
    uint64_t low  = (uint64_t)HWREG32(MULT_BASE_ADDR + RESL_OFFSET);
    return (high << 32) | low;
}

static inline uint32_t mult_calc_32(uint32_t multiplicand, uint32_t multiplier)
{
    HWREG32(MULT_BASE_ADDR + MUL1_OFFSET) = multiplicand;
    HWREG32(MULT_BASE_ADDR + MUL2_OFFSET) = multiplier;

    while (HWREG32(MULT_BASE_ADDR + MULT_INFO_OFFSET));

    return HWREG32(MULT_BASE_ADDR + RESL_OFFSET);
}

static inline uint32_t div_calc_quotient(uint32_t dividend, uint32_t divisor)
{
    if (divisor == 0)
    {
        return 0xFFFFFFFF;
    }

    HWREG32(DIV_BASE_ADDR + DIV_END_OFFSET) = dividend;
    HWREG32(DIV_BASE_ADDR + DIV_SOR_OFFSET) = divisor;

    while (HWREG32(DIV_BASE_ADDR + DIV_INFO_OFFSET));

    return HWREG32(DIV_BASE_ADDR + DIV_QUO_OFFSET);
}

static inline uint32_t div_calc_remainder(uint32_t dividend, uint32_t divisor)
{
    if (divisor == 0)
    {
        return 0xFFFFFFFF;
    }

    HWREG32(DIV_BASE_ADDR + DIV_END_OFFSET) = dividend;
    HWREG32(DIV_BASE_ADDR + DIV_SOR_OFFSET) = divisor;

    while (HWREG32(DIV_BASE_ADDR + DIV_INFO_OFFSET));

    return HWREG32(DIV_BASE_ADDR + DIV_REM_OFFSET);
}

static inline uint32_t div_get_quotient()
{
    return HWREG32(DIV_BASE_ADDR + DIV_QUO_OFFSET);
}

static inline uint32_t div_get_remainder()
{
    return HWREG32(DIV_BASE_ADDR + DIV_REM_OFFSET);
}

#endif

float __floatsisf(int32_t x)
{
    if (x == 0)
    {
        return 0.0f;
    }
    uint32_t sign = 0;
    uint32_t abs_x;
    if (x < 0)
    {
        sign = 1;

        abs_x = (x == (-2147483647 - 1)) ? 0x80000000U : (uint32_t)(-x);
    }
    else
    {
        abs_x = (uint32_t)x;
    }

    int shift = 31;
    while (!(abs_x & (1u << shift)))
        shift--;

    int exp = shift + FLOAT_BIAS;
    uint32_t mantissa;
    if (shift > 23)
    {

        int rshift = shift - 23;
        uint32_t extra = abs_x & ((1u << rshift) - 1);
        mantissa = abs_x >> rshift;

        uint32_t halfway = 1u << (rshift - 1);
        if (rshift > 0)
        {
            if ((extra > halfway) || ((extra == halfway) && (mantissa & 1)))
                mantissa++;
        }

        if (mantissa & (1u << 24))
        {
            mantissa >>= 1;
            exp++;
        }
    }
    else
    {

        mantissa = abs_x << (23 - shift);
    }

    mantissa &= 0x7FFFFF;

    float_union u;
    u.i = FLOAT_RECONSTRUCT(sign, exp, mantissa);
    return u.f;
}

int32_t __fixsfsi(float x)
{
    float_union u = {.f = x};
    int32_t sign = FLOAT_SIGN(u.i);
    int32_t exp = FLOAT_EXP(u.i) - FLOAT_BIAS;

    if (exp < 0)
    {
        return 0;
    }

    if (exp > 31)
    {
        return sign ? -2147483648 : 2147483647;
    }

    uint32_t mant = FLOAT_MANT(u.i) | (1u << 23);
    int32_t result;
    if (exp > 23)
    {
        result = mant << (exp - 23);
    }
    else
    {
        result = mant >> (23 - exp);
    }
    return sign ? -result : result;
}

float __addsf3(float a, float b)
{
    float_union ua = {.f = a};
    float_union ub = {.f = b};

    if (FLOAT_EXP(ua.i) == 0xFF)
    {
        if (FLOAT_MANT(ua.i))
            return a;

        if ((FLOAT_EXP(ub.i) == 0xFF) && (FLOAT_MANT(ub.i) == 0) &&
            (FLOAT_SIGN(ua.i) != FLOAT_SIGN(ub.i)))
        {
            float_union res;
            res.i = 0xFFC00000;
            return res.f;
        }
        return a;
    }
    if (FLOAT_EXP(ub.i) == 0xFF)
    {
        if (FLOAT_MANT(ub.i))
            return b;
        return b;
    }

    if ((ua.i & 0x7FFFFFFF) == 0)
        return b;
    if ((ub.i & 0x7FFFFFFF) == 0)
        return a;

    int exp_a = FLOAT_EXP(ua.i);
    int exp_b = FLOAT_EXP(ub.i);
    uint32_t mant_a = FLOAT_MANT(ua.i);
    uint32_t mant_b = FLOAT_MANT(ub.i);

    if (exp_a == 0)
    {
        exp_a = 1 - FLOAT_BIAS;
    }
    else
    {
        mant_a |= (1u << 23);
    }
    if (exp_b == 0)
    {
        exp_b = 1 - FLOAT_BIAS;
    }
    else
    {
        mant_b |= (1u << 23);
    }
    int sign_a = FLOAT_SIGN(ua.i);
    int sign_b = FLOAT_SIGN(ub.i);

    int exp_diff = exp_a - exp_b;

    uint32_t mant_a_ext = mant_a << 3;
    uint32_t mant_b_ext = mant_b << 3;
    int exp_result;
    if (exp_diff > 0)
    {
        if (exp_diff < 32)
        {
            uint32_t lost = mant_b_ext & ((1u << exp_diff) - 1);
            mant_b_ext = mant_b_ext >> exp_diff;
            if (lost)
                mant_b_ext |= 1;
        }
        else
        {
            mant_b_ext = 0;
        }
        exp_result = exp_a;
    }
    else if (exp_diff < 0)
    {
        int shift = -exp_diff;
        if (shift < 32)
        {
            uint32_t lost = mant_a_ext & ((1u << shift) - 1);
            mant_a_ext = mant_a_ext >> shift;
            if (lost)
                mant_a_ext |= 1;
        }
        else
        {
            mant_a_ext = 0;
        }
        exp_result = exp_b;
    }
    else
    {
        exp_result = exp_a;
    }

    uint32_t result_mant;
    int result_sign;
    if (sign_a == sign_b)
    {
        result_mant = mant_a_ext + mant_b_ext;
        result_sign = sign_a;
    }
    else
    {
        if (mant_a_ext >= mant_b_ext)
        {
            result_mant = mant_a_ext - mant_b_ext;
            result_sign = sign_a;
        }
        else
        {
            result_mant = mant_b_ext - mant_a_ext;
            result_sign = sign_b;
        }
    }

    if (result_mant == 0)
    {
        float_union res;
        res.i = result_sign << 31;
        return res.f;
    }

    if (result_mant & (1u << (24 + 3)))
    {
        uint32_t lsb = result_mant & 1;
        result_mant = (result_mant >> 1) + lsb;
        exp_result++;
    }
    else
    {

        while ((result_mant & (1u << (23 + 3))) == 0)
        {
            result_mant <<= 1;
            exp_result--;
        }
    }

    uint32_t guard = (result_mant >> 2) & 1;
    uint32_t round_bit = (result_mant >> 1) & 1;
    uint32_t sticky = (result_mant & 1);
    uint32_t frac = result_mant >> 3;

    if (round_bit && (sticky || (frac & 1)))
    {
        frac++;
        if (frac & (1u << 24))
        {
            frac >>= 1;
            exp_result++;
        }
    }
    uint32_t final_mant = frac & 0x7FFFFF;

    if (exp_result <= 0)
    {
        int shift = 1 - exp_result;
        if (shift < 32)
            final_mant = frac >> shift;
        else
            final_mant = 0;
        exp_result = 0;
    }
    if (exp_result >= 255)
    {

        float_union res;
        res.i = (result_sign << 31) | (0xFF << 23);
        return res.f;
    }

    float_union res;
    res.i = (result_sign << 31) | ((exp_result & 0xFF) << 23) | (final_mant & 0x7FFFFF);
    return res.f;
}

float __subsf3(float a, float b)
{
    float_union ub = {.f = b};
    ub.i ^= (1u << 31);
    return __addsf3(a, ub.f);
}

float __mulsf3(float a, float b)
{
    float_union ua = {.f = a};
    float_union ub = {.f = b};

    if (FLOAT_EXP(ua.i) == 0xFF)
    {
        if (FLOAT_MANT(ua.i))
            return a;
        if ((ub.i & 0x7FFFFFFF) == 0)
        {
            float_union res;
            res.i = 0xFFC00000;
            return res.f;
        }
        return a;
    }
    if (FLOAT_EXP(ub.i) == 0xFF)
    {
        if (FLOAT_MANT(ub.i))
            return b;
        if ((ua.i & 0x7FFFFFFF) == 0)
        {
            float_union res;
            res.i = 0xFFC00000;
            return res.f;
        }
        return b;
    }

    if ((ua.i & 0x7FFFFFFF) == 0 || (ub.i & 0x7FFFFFFF) == 0)
    {
        float_union res;
        res.i = (FLOAT_SIGN(ua.i) ^ FLOAT_SIGN(ub.i)) << 31;
        return res.f;
    }

    int sign = FLOAT_SIGN(ua.i) ^ FLOAT_SIGN(ub.i);
    int exp_a = FLOAT_EXP(ua.i);
    int exp_b = FLOAT_EXP(ub.i);
    uint32_t mant_a = FLOAT_MANT(ua.i);
    uint32_t mant_b = FLOAT_MANT(ub.i);
    if (exp_a != 0)
        mant_a |= (1u << 23);
    else
        exp_a = 1 - FLOAT_BIAS;
    if (exp_b != 0)
        mant_b |= (1u << 23);
    else
        exp_b = 1 - FLOAT_BIAS;

    int exp_result = exp_a + exp_b - FLOAT_BIAS;

    uint64_t product = (uint64_t)mant_a * (uint64_t)mant_b;

    uint64_t shifted = product >> 23;
    if (shifted & (1ULL << 24))
    {
        shifted >>= 1;
        exp_result++;
    }
    uint32_t frac = shifted & ((1u << 23) - 1);

    if (exp_result <= 0)
    {

        int shift = 1 - exp_result;
        if (shift < 32)
            frac = (uint32_t)shifted >> shift;
        else
            frac = 0;
        exp_result = 0;
    }
    if (exp_result >= 255)
    {
        float_union res;
        res.i = (sign << 31) | (0xFF << 23);
        return res.f;
    }
    float_union res;
    res.i = (sign << 31) | ((exp_result & 0xFF) << 23) | (frac & 0x7FFFFF);
    return res.f;
}

float __divsf3(float a, float b)
{
    float_union ua = {.f = a};
    float_union ub = {.f = b};

    if (FLOAT_EXP(ua.i) == 0xFF)
    {
        if (FLOAT_MANT(ua.i))
            return a;
        if (FLOAT_EXP(ub.i) == 0xFF && (FLOAT_MANT(ub.i) == 0))
        {
            float_union res;
            res.i = 0xFFC00000;
            return res.f;
        }
        float_union res;
        res.i = FLOAT_RECONSTRUCT(FLOAT_SIGN(ua.i) ^ FLOAT_SIGN(ub.i), 0xFF, 0);
        return res.f;
    }
    if (FLOAT_EXP(ub.i) == 0xFF)
    {
        if (FLOAT_MANT(ub.i))
            return b;
        float_union res;
        res.i = FLOAT_RECONSTRUCT(FLOAT_SIGN(ua.i) ^ FLOAT_SIGN(ub.i), 0, 0);
        return res.f;
    }

    if ((ub.i & 0x7FFFFFFF) == 0)
    {
        if ((ua.i & 0x7FFFFFFF) == 0)
        {
            float_union res;
            res.i = 0xFFC00000;
            return res.f;
        }
        float_union res;
        res.i = FLOAT_RECONSTRUCT(FLOAT_SIGN(ua.i) ^ FLOAT_SIGN(ub.i), 0xFF, 0);
        return res.f;
    }
    if ((ua.i & 0x7FFFFFFF) == 0)
    {
        float_union res;
        res.i = FLOAT_RECONSTRUCT(FLOAT_SIGN(ua.i) ^ FLOAT_SIGN(ub.i), 0, 0);
        return res.f;
    }

    int sign = FLOAT_SIGN(ua.i) ^ FLOAT_SIGN(ub.i);
    int exp_a = (FLOAT_EXP(ua.i) == 0 ? 1 - FLOAT_BIAS : FLOAT_EXP(ua.i));
    int exp_b = (FLOAT_EXP(ub.i) == 0 ? 1 - FLOAT_BIAS : FLOAT_EXP(ub.i));
    uint32_t mant_a = (FLOAT_EXP(ua.i) == 0 ? FLOAT_MANT(ua.i) : (FLOAT_MANT(ua.i) | (1u << 23)));
    uint32_t mant_b = (FLOAT_EXP(ub.i) == 0 ? FLOAT_MANT(ub.i) : (FLOAT_MANT(ub.i) | (1u << 23)));

    uint64_t dividend = (uint64_t)mant_a << 31;
    uint32_t divisor = mant_b;
    uint64_t quotient = dividend / divisor;

    uint32_t q = quotient >> 8;
    uint32_t round_bit = (quotient >> 7) & 1;
    uint32_t sticky = ((quotient & 0x7F) != 0);
    if (round_bit && (sticky || (q & 1)))
    {
        q++;
        if (q == (1u << 24))
        {
            q >>= 1;
            exp_a++;
        }
    }
    int exp_result = exp_a - exp_b + FLOAT_BIAS;
    if (q & (1u << 24))
    {
        q >>= 1;
        exp_result++;
    }
    if (exp_result <= 0)
    {
        int shift = 1 - exp_result;
        if (shift < 32)
            q >>= shift;
        else
            q = 0;
        exp_result = 0;
    }
    if (exp_result >= 255)
    {
        float_union res;
        res.i = (sign << 31) | (0xFF << 23);
        return res.f;
    }
    float_union res;
    res.i = (sign << 31) | ((exp_result & 0xFF) << 23) | (q & 0x7FFFFF);
    return res.f;
}

int32_t __gesf2(float a, float b)
{
    return (a >= b) ? 1 : 0;
}

int32_t __ltsf2(float a, float b)
{
    return (a < b) ? 1 : 0;
}

uint32_t __clzsi2(uint32_t x)
{
    uint32_t count = 0;
    if (x == 0)
    {
        return 32;
    }
    while (!(x & 0x80000000))
    {
        count++;
        x <<= 1;
    }
    return count;
}

uint32_t __ffssi2(uint32_t x)
{
    if (x == 0)
    {
        return 0;
    }
    return 32 - __clzsi2(x);
}

typedef struct
{
    uint32_t quotient;
    uint32_t remainder;
} divmod_result;

divmod_result __divmodsi4(uint32_t dividend, uint32_t divisor) {
    divmod_result res = {0, 0};

#ifdef HARDWAREDIVISION
    if (divisor == 0) {
        res.quotient = 0xFFFFFFFF;
        res.remainder = 0xFFFFFFFF;
    } else {
        res.quotient = div_calc_quotient(dividend, divisor);
        res.remainder = div_get_remainder();
    }
#else
    if (divisor == 0) {
        res.quotient = 0;
        res.remainder = 0;
    } else {
        uint32_t temp = 0;
        for (int32_t i = 31; i >= 0; i--) {
            temp = (temp << 1) | ((dividend >> i) & 1);
            if (temp >= divisor) {
                temp -= divisor;
                res.quotient |= (1U << i);
            }
        }
        res.remainder = temp;
    }
#endif

    return res;
}

int64_t __muldi3(int64_t a, int64_t b)
{
    uint64_t ua, ub, result = 0;
    int negative = 0;

    ua = (uint64_t)a;
    if (a < 0)
    {
        negative = !negative;
        ua = (~ua) + 1;
    }

    ub = (uint64_t)b;
    if (b < 0)
    {
        negative = !negative;
        ub = (~ub) + 1;
    }

    while (ub)
    {
        if (ub & 1)
            result += ua;
        ua <<= 1;
        ub >>= 1;
    }

    if (negative)
        result = (~result) + 1;

    return (int64_t)result;
}

uint64_t __udivdi3(uint64_t dividend, uint64_t divisor)
{
    if (divisor == 0)
    {
        return ~((uint64_t)0);
    }
    uint64_t quotient = 0;
    for (int32_t i = 63; i >= 0; i--)
    {
        if ((dividend >> i) >= divisor)
        {
            quotient |= ((uint64_t)1 << i);
            dividend -= (divisor << i);
        }
    }
    return quotient;
}

uint64_t __umoddi3(uint64_t dividend, uint64_t divisor)
{
    if (divisor == 0)
    {
        return 0;
    }
    for (int32_t i = 63; i >= 0; i--)
    {
        if ((dividend >> i) >= divisor)
        {
            dividend -= (divisor << i);
        }
    }
    return dividend;
}

int64_t __divdi3(int64_t dividend, int64_t divisor)
{
    int negative = 0;
    uint64_t udividend, udivisor, quotient;

    udividend = (uint64_t)dividend;
    if (dividend < 0)
    {
        negative = !negative;
        udividend = (~udividend) + 1;
    }

    udivisor = (uint64_t)divisor;
    if (divisor < 0)
    {
        negative = !negative;
        udivisor = (~udivisor) + 1;
    }

    quotient = __udivdi3(udividend, udivisor);

    if (negative)
        quotient = (~quotient) + 1;

    return (int64_t)quotient;
}

int64_t __moddi3(int64_t dividend, int64_t divisor)
{
    int negative = 0;
    uint64_t udividend, udivisor, remainder;

    udividend = (uint64_t)dividend;
    if (dividend < 0)
    {
        negative = 1;
        udividend = (~udividend) + 1;
    }

    udivisor = (uint64_t)divisor;
    if (divisor < 0)
    {
        udivisor = (~udivisor) + 1;
    }

    remainder = __umoddi3(udividend, udivisor);

    if (negative)
        remainder = (~remainder) + 1;

    return (int64_t)remainder;
}

uint64_t __ashldi3(uint64_t a, int32_t b)
{
    uint32_t lo = (uint32_t)a;
    uint32_t hi = (uint32_t)(a >> 32);
    if (b == 0)
        return a;
    if (b >= 64)
        return 0ULL;
    if (b < 32)
    {
        uint32_t new_hi = (hi << b) | (lo >> (32 - b));
        uint32_t new_lo = lo << b;
        return ((uint64_t)new_hi << 32) | new_lo;
    }
    else
    {
        uint32_t new_hi = lo << (b - 32);
        return ((uint64_t)new_hi << 32);
    }
}

int64_t __ashrdi3(int64_t a, int32_t b)
{
    if (b == 0)
        return a;
    if (b >= 64)
        return a < 0 ? -1LL : 0LL;
    int32_t hi = (int32_t)(a >> 32);
    uint32_t lo = (uint32_t)a;
    if (b < 32)
    {
        uint32_t new_lo = (lo >> b) | (((uint32_t)hi) << (32 - b));
        int32_t new_hi = hi >> b;
        return ((uint64_t)(uint32_t)new_hi << 32) | new_lo;
    }
    else
    {

        int32_t new_hi = hi < 0 ? -1 : 0;
        int32_t new_lo = hi >> (b - 32);
        return ((uint64_t)(uint32_t)new_hi << 32) | ((uint32_t)new_lo);
    }
}

uint64_t __lshrdi3(uint64_t a, int32_t b)
{
    uint32_t lo = (uint32_t)a;
    uint32_t hi = (uint32_t)(a >> 32);
    if (b == 0)
        return a;
    if (b >= 64)
        return 0ULL;
    if (b < 32)
    {
        uint32_t new_lo = (lo >> b) | (hi << (32 - b));
        uint32_t new_hi = hi >> b;
        return ((uint64_t)new_hi << 32) | new_lo;
    }
    else
    {
        uint32_t new_lo = hi >> (b - 32);
        return new_lo;
    }
}

uint32_t __mulsi3(uint32_t a, uint32_t b)
{
#ifdef HARDWAREDIVISION
    return mult_calc_32(a, b);
#else
    uint32_t result = 0;
    while (b)
    {
        if (b & 1)
        {
            result += a;
        }
        a <<= 1;
        b >>= 1;
    }
    return result;
#endif
}

uint32_t __udivsi3(uint32_t dividend, uint32_t divisor)
{
#ifdef HARDWAREDIVISION
    return div_calc_quotient(dividend, divisor);
#else
    if (divisor == 0)
    {
        return 0;
    }

    uint32_t quotient = 0, temp = 0;
    for (int32_t i = 31; i >= 0; i--)
    {
        temp = (temp << 1) | ((dividend >> i) & 1);
        if (temp >= divisor) {
            temp -= divisor;
            quotient |= (1U << i);
        }
    }
    return quotient;
#endif
}

uint32_t __umodsi3(uint32_t dividend, uint32_t divisor)
{
#ifdef HARDWAREDIVISION
    return div_calc_remainder(dividend, divisor);
#else
    if (divisor == 0)
    {
        return 0;
    }

    uint32_t temp = 0;
    for (int32_t i = 31; i >= 0; i--)
    {
        temp = (temp << 1) | ((dividend >> i) & 1);
        if (temp >= divisor)
        {
            temp -= divisor;
        }
    }
    return temp;
#endif
}

int32_t __divsi3(int32_t dividend, int32_t divisor)
{
#ifdef HARDWAREDIVISION
    uint32_t abs_dividend = (dividend < 0) ? -dividend : dividend;
    uint32_t abs_divisor = (divisor < 0) ? -divisor : divisor;
    uint32_t result = div_calc_quotient(abs_dividend, abs_divisor);
    return ((dividend < 0) ^ (divisor < 0)) ? -(int32_t)result : (int32_t)result;
#else
    if (divisor == 0)
    {
        return 0;
    }

    uint32_t abs_dividend = (dividend < 0) ? -dividend : dividend;
    uint32_t abs_divisor = (divisor < 0) ? -divisor : divisor;
    uint32_t quotient = 0, temp = 0;

    for (int32_t i = 31; i >= 0; i--)
    {
        temp = (temp << 1) | ((abs_dividend >> i) & 1);
        if (temp >= abs_divisor)
        {
            temp -= abs_divisor;
            quotient |= (1U << i);
        }
    }

    return ((dividend < 0) ^ (divisor < 0)) ? -(int32_t)quotient : (int32_t)quotient;
#endif
}

int32_t __modsi3(int32_t dividend, int32_t divisor)
{
#ifdef HARDWAREDIVISION
    uint32_t abs_dividend = (dividend < 0) ? -dividend : dividend;
    uint32_t abs_divisor = (divisor < 0) ? -divisor : divisor;
    uint32_t result = div_calc_remainder(abs_dividend, abs_divisor);
    return (dividend < 0) ? -(int32_t)result : (int32_t)result;
#else
    if (divisor == 0)
    {
        return 0;
    }

    uint32_t abs_dividend = (dividend < 0) ? -dividend : dividend;
    uint32_t abs_divisor = (divisor < 0) ? -divisor : divisor;
    uint32_t temp = 0;

    for (int32_t i = 31; i >= 0; i--)
    {
        temp = (temp << 1) | ((abs_dividend >> i) & 1);
        if (temp >= abs_divisor)
        {
            temp -= abs_divisor;
        }
    }

    return (dividend < 0) ? -(int32_t)temp : (int32_t)temp;
#endif
}

float __negsf2(float a)
{
    float_union u = {.f = a};
    u.i ^= (1U << 31);
    return u.f;
}

float __floatunsisf(uint32_t x)
{
    if (x == 0)
    {
        return 0.0f;
    }
    int32_t shift = 31;
    while (!(x & (1U << shift)))
    {
        shift--;
    }
    int32_t exp = shift + FLOAT_BIAS;
    uint32_t mant = (x << (23 - shift)) & 0x7FFFFF;
    return ((float_union){.i = FLOAT_RECONSTRUCT(0, exp, mant)}).f;
}

uint32_t __fixunssfsi(float x)
{
    float_union u = {.f = x};
    if (u.i & 0x80000000)
    {
        return 0;
    }
    int32_t exp = FLOAT_EXP(u.i) - FLOAT_BIAS;
    if (exp < 0)
    {
        return 0;
    }
    if (exp > 31)
    {
        return ~0U;
    }
    uint32_t mant = FLOAT_MANT(u.i) | (1 << 23);
    if (exp > 23)
    {
        return mant << (exp - 23);
    }
    else
    {
        return mant >> (23 - exp);
    }
}

uint64_t __umuldi3(uint64_t a, uint64_t b)
{
#ifdef HARDWAREDIVISION
    uint32_t a_low   = (uint32_t)(a & 0xFFFFFFFF);
    uint32_t a_high  = (uint32_t)(a >> 32);
    uint32_t b_low   = (uint32_t)(b & 0xFFFFFFFF);
    uint32_t b_high  = (uint32_t)(b >> 32);
    uint64_t low_low = mult_calc_64(a_low, b_low);
    uint64_t cross1  = mult_calc_64(a_low, b_high);
    uint64_t cross2  = mult_calc_64(a_high, b_low);
    uint64_t cross   = cross1 + cross2;
    return   low_low + (cross << 32);
#else
    uint64_t result = 0;
    while (b)
    {
        if (b & 1)
        {
            result += a;
        }
        a <<= 1;
        b >>= 1;
    }
    return result;
#endif
}
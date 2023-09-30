#include <stdint.h>
#include <stdio.h>

uint16_t count_leading_zeros(uint64_t x)
{
    x |= (x >> 1);
    x |= (x >> 2);
    x |= (x >> 4);
    x |= (x >> 8);
    x |= (x >> 16);
    x |= (x >> 32);

    /* count ones (population count) */
    x -= ((x >> 1) & 0x5555555555555555);
    x = ((x >> 2) & 0x3333333333333333) + (x & 0x3333333333333333);
    x = ((x >> 4) + x) & 0x0f0f0f0f0f0f0f0f;
    x += (x >> 8);
    x += (x >> 16);
    x += (x >> 32);

    return (64 - (x & 0x7f));
}

// log base power of 2
uint16_t logp2(int power, uint16_t clz)
{
    uint16_t result = 0;
    int tmp = 64 - clz;
    while (1) {
        tmp -= power;
        if (tmp <= 0)
            break;
        result++;
    }
    return result;
}

int main(int argc, char* argv[])
{
    uint64_t a = 64;
    uint16_t clz = count_leading_zeros(a);
    printf("%d\n", logp2(2, clz));

    return 0;
}

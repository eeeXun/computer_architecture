#include <stdint.h>
#include <stdio.h>

extern uint64_t get_cycles();

float fp32_to_bf16(float x)
{
    float y = x;
    int* p = (int*)&y;
    unsigned int exp = *p & 0x7F800000;
    unsigned int man = *p & 0x007FFFFF;
    if (exp == 0 && man == 0) /* zero */
        return x;
    if (exp == 0x7F800000) /* infinity or NaN */
        return x;

    /* Normalized number */
    /* round to nearest */
    float r = x;
    int* pr = (int*)&r;
    *pr &= 0xFF800000; /* r has the same exp as x */
    r /= 0X100;
    y = x + r;

    *p &= 0xFFFF0000;

    return y;
}

// encoder : encode two bfloat number in one memory
int encoder(int* a, int* b)
{
    int c = 0;
    c = *a | (*b >> 16);
    return c;
}

// decoder : decode one memory number in two bfloat
void decoder(int c, void* n1, void* n2)
{
    *(int*)n1 = c & 0xffff0000;
    *(int*)n2 = (c & 0x0000ffff) << 16;
}

int main()
{
    uint64_t oldcount = get_cycles();
    // definition of num1 and transfer it to bfloat
    float num1 = -12.123;
    int* np1 = (int*)&num1;
    num1 = fp32_to_bf16(num1);
    // definition of num2 and transfer it to bfloat
    float num2 = 45.568;
    int* np2 = (int*)&num2;
    num2 = fp32_to_bf16(num2);

    float add;
    int* p = (int*)&add;
    *p = 0;
    // show num1 binary form and it's value
    printf("0x%x\n", *np1);
    printf("%f\n", num1);
    // show num2 binary form and it's value
    printf("0x%x\n", *np2);
    printf("%f\n", num2);
    // add two number together and print the binary form
    *p = encoder(np1, np2);
    decoder(*p, &num1, &num2);
    float mul_num;
    mul_num = num1 * num2;
    printf("%f\n", mul_num);
    uint64_t cyclecount = get_cycles() - oldcount;
    printf("cyle count: %u\n", (unsigned int)cyclecount);
    return 0;
}

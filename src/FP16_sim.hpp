#ifndef FP16_SIM
#define FP16_SIM

#include <cstdlib>
#include <iostream>
#include <bitset>

#define EXP      0x7C00
#define MANT     0x03FF
#define SIGN     0x8000
#define POINT16  0x0400
#define POINT32  0x000000100000

#define POS_ZERO 0x0000
#define NEG_ZERO 0x8000
#define POS_INF  0x7C00
#define NEG_INF  0xFC00

#define ZERO_F 0
#define INF_F  1
#define SUB_F  2
#define NORM_F 3
#define QNAN_F 4
#define SNAN_F 5

#define TEST_NAN 0x7E00

#define DEBUG_MODE 0

#define SR 0
#define NUM_BITS 16
#define MIN_EXP -14
#define MANT_WIDTH 10
#define EXP_WIDTH 5
#define NUM_ROUND_BITS 6

typedef struct FP16
{
    uint16_t val;
    int16_t exp;
    uint32_t mant;
    uint16_t sign;

    uint8_t flag_arr[6] = {0,0,0,0,0,0};

    FP16(uint16_t num);

    FP16 operator*(FP16& num2);

    FP16 operator+(FP16& num2);

    static uint16_t LFSR(uint8_t num_round_bits, bool reset);

    private:

    int16_t align_mantissas(uint32_t &mant_a, uint32_t &mant_b, int16_t &exp_a, int16_t &exp_b);

    void normalise_addsub(uint32_t &mant, int16_t &res_exp);

    static uint8_t clz(uint16_t);

    void set_zero(bool negative);

    void set_inf(bool negative);

    void round(uint32_t &mantissa);

    void round_addsub(uint32_t &mantissa);


}FP16;

#endif 



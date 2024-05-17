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

typedef struct FP16
{
    uint16_t val;
    int16_t exp;
    uint32_t mant;
    uint16_t sign;

    uint8_t flag_arr[6] = {0,0,0,0,0,0};

    FP16(uint16_t num);

    FP16 operator*(FP16& num2);

    //FP16 operator+(FP16& num2);


    private:

    static uint8_t clz(uint16_t);

    void set_zero(bool negative);

    void set_inf(bool negative);


}FP16;



#endif 
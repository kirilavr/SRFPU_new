#include "../src/FP16_sim.hpp"

FP16::FP16(uint16_t num)
{
    val = num;
    exp = ((num & EXP)>>10) - 15;
    mant = (num & MANT) + POINT16;
    sign = num & SIGN;

    //case: zero 
    if((mant == POINT16) & (exp < -14))
    {
        flag_arr[ZERO_F] = 1;
    }
    
    //case: normal number 
    else if((exp > -15) & (exp < 16))
    {
        flag_arr[NORM_F] = 1;
    }

    //case: subnormal 
    else if(exp == -15)
    {
        flag_arr[SUB_F] = 1;
        mant -= POINT16;
        exp += 1;
    }

    //case: infinity 
    else if((exp == 16) & (mant == POINT16))
    {
        flag_arr[INF_F] = 1;
    }

    //case: QNaN
    else if((exp == 16) & ((mant & (POINT16 >> 1)) == (POINT16>>1)))
    {
        flag_arr[QNAN_F] = 1;
    }

    //case: SNan
    else if((exp == 16) & ((mant & (POINT16 >> 1)) != POINT16>>1))
    {
        flag_arr[SNAN_F] = 1;
    }

    else
    {
        flag_arr[ZERO_F] = 1;
        flag_arr[INF_F] = 1;
        flag_arr[SUB_F] = 1;
    }

}


FP16 FP16::operator*(FP16& num2)
{
    int8_t res_exp;
    uint32_t res_mant;
    uint16_t res_sign;


    //setting SNaN
    if(flag_arr[SNAN_F] | num2.flag_arr[SNAN_F])
    {
        if(flag_arr[SNAN_F])
        {
            FP16 ret = FP16(val);
            return ret;
        }
        else
        {
            FP16 ret = FP16(num2.val);
            return ret;
        }
    }

    //setting QNaN
    else if(flag_arr[QNAN_F] | num2.flag_arr[QNAN_F])
    {
        if(flag_arr[QNAN_F])
        {
            FP16 ret = FP16(val);
            return ret;
        }
        else
        {
            FP16 ret = FP16(num2.val);
            return ret;
        }
    }  

    //setting 0 flag for 2 subnormal comb
    else if(flag_arr[SUB_F] & num2.flag_arr[SUB_F])
    {
        FP16 ret = FP16(sign ^ num2.sign ? NEG_ZERO : POS_ZERO);
        return ret;
    }

    //setting 0 flag for the case of zero
    else if(flag_arr[ZERO_F] | num2.flag_arr[ZERO_F])
    {
        if(flag_arr[INF_F] | num2.flag_arr[INF_F])
        {
            FP16 ret = FP16(TEST_NAN);
            return ret;
        }

        FP16 ret = FP16(sign ^ num2.sign ? NEG_ZERO : POS_ZERO);
        return ret;
    }

    //setting infinity in case of inf
    else if(flag_arr[INF_F] | num2.flag_arr[INF_F])
    {
        FP16 ret = FP16((sign ^ num2.sign) == SIGN ? NEG_INF : POS_INF);
        return ret;
    }



    //convert to normal number 
    if(flag_arr[SUB_F])
    {
        uint8_t lz = clz(mant);
        mant = (mant << (lz));
        exp = exp - (lz);
    }

    //convert subnormals 
    else if(num2.flag_arr[SUB_F])
    {
        uint8_t lz = clz(num2.mant);
        num2.mant = (num2.mant << (lz));
        num2.exp = num2.exp - (lz);
    }

    res_sign = sign ^ num2.sign;
    res_exp  = exp  + num2.exp;
    res_mant = mant * num2.mant;
    //std::cout<<(int)res_exp<<std::endl;
    //std::cout<<std::bitset<22>(res_mant)<<std::endl;

    if((res_mant & (POINT32<<1)) == POINT32<<1)
    {
        res_mant = res_mant >> 1;
        res_exp += 1;
    }

    if(res_exp > 15)
    {
        FP16 ret = FP16(res_sign == POS_ZERO ? POS_INF : NEG_INF);
        return ret;
    }

    else if(res_exp < -24 - NUM_ROUND_BITS)
    {
        FP16 ret = FP16(res_sign == POS_ZERO ? POS_ZERO : NEG_ZERO);
        return ret;
    }

    else if(res_exp < -14)
    {


        res_mant = res_mant >> (-14 - res_exp);
        res_exp  = 0;
        //std::cout<<std::bitset<22>(res_mant)<<std::endl;
        round(res_mant);
        //std::cout<<std::bitset<22>(res_mant)<<std::endl;

        if((res_mant&(POINT32)) == POINT32)
        {
            res_exp += 1;
        }
        //std::cout<<std::bitset<10>(res_mant>>10)<<std::endl;
        //std::cout<<(int)res_exp<<std::endl;

        FP16 ret = FP16((((uint16_t)res_exp)<<10) + res_sign + (((uint16_t)(res_mant>>10))&MANT));
        //std::cout<<std::bitset<16>(ret.val)<<std::endl;
        return ret;
    }

    else
    {
        res_exp += 15;  
        round(res_mant);

        //std::cout<<std::bitset<22>(res_mant)<<std::endl;

        if((res_mant&(POINT32<<1)) == (POINT32<<1))
        {
            res_mant >>= 1;
            res_exp += 1;
        }

        //std::cout<<std::bitset<22>(res_mant)<<std::endl;

        FP16 ret = FP16(0x0000 + res_sign + (res_exp<<10) + ((res_mant>>10)&MANT));

        return ret;
    }


}


FP16 FP16::operator+(FP16& num2)
{
    uint16_t res_sign;
    int16_t res_exp;
    uint32_t res_mant;


    //setting SNaN
    if(flag_arr[SNAN_F] | num2.flag_arr[SNAN_F])
    {
        if(flag_arr[SNAN_F])
        {
            FP16 ret = FP16(val);
            return ret;
        }
        else
        {
            FP16 ret = FP16(num2.val);
            return ret;
        }
    }

    //setting QNaN
    else if(flag_arr[QNAN_F] | num2.flag_arr[QNAN_F])
    {
        if(flag_arr[QNAN_F])
        {
            FP16 ret = FP16(val);
            return ret;
        }
        else
        {
            FP16 ret = FP16(num2.val);
            return ret;
        }
    }  

    else if(flag_arr[INF_F] & num2.flag_arr[INF_F])
    {
        //std::cout<<"two zeros: "<<std::bitset<16>(sign)<<" "<<std::bitset<16>(num2.sign)<<std::endl;

        if((sign ^ num2.sign) == SIGN)
        {
            //std::cout<<"inside here";
            FP16 ret = FP16(0b0111111000000000);
            return ret;
        }
        else
        {
            FP16 ret = flag_arr[INF_F] ? FP16(val) : FP16(num2.val);
            return ret;
        }
    }

    else if(flag_arr[ZERO_F] & num2.flag_arr[ZERO_F])
    {
        //std::cout<<"two zeros: "<<std::bitset<16>(sign)<<" "<<std::bitset<16>(num2.sign)<<std::endl;
        if((sign ^ num2.sign) == SIGN)
        {
            //std::cout<<"inside here";
            FP16 ret = FP16(0x0000);
            return ret;
        }
        else 
        {
            FP16 ret = FP16(num2.val);
            return ret;
        }
    }

    else if(flag_arr[INF_F] | num2.flag_arr[INF_F])
    {
        FP16 ret = flag_arr[INF_F] ? FP16(val) : FP16(num2.val);
        return ret;
    }

    else if(flag_arr[ZERO_F] | num2.flag_arr[ZERO_F])
    {
        FP16 ret = flag_arr[ZERO_F] ? FP16(num2.val) : FP16(val);
        return ret;
    }

    else 
    {
        #if DEBUG_MODE
        std::cout<<"prealign Mant 1: "<<std::bitset<18>(mant)<<std::endl;
        std::cout<<"prealign Mant 2: "<<std::bitset<18>(num2.mant)<<std::endl;

        std::cout<<"prealign exp 1: "<<exp<<std::endl;
        std::cout<<"prealign exp 2: "<<num2.exp<<std::endl;
        #endif

        res_exp = align_mantissas(mant, num2.mant, exp, num2.exp);

        #if DEBUG_MODE
        std::cout<<"Mant 1: "<<std::bitset<18>(mant)<<std::endl;
        std::cout<<"Mant 2: "<<std::bitset<18>(num2.mant)<<std::endl;

        std::cout<<"exp 1: "<<exp<<std::endl;
        std::cout<<"exp 2: "<<num2.exp<<std::endl;
        #endif

        if((sign ^ num2.sign) == SIGN)
        {
            if(mant < num2.mant)
            {
                res_mant = num2.mant - mant;
                res_sign = num2.sign;
            }
            else
            {
                res_mant = mant - num2.mant;
                res_sign = sign;
            }
        }
        else 
        {
            res_mant = num2.mant + mant;
            res_sign = num2.sign;
        }

        #if DEBUG_MODE
        std::cout<<"res mant: "<<std::bitset<18>(res_mant)<<std::endl;
        std::cout<<"res_exp: "<<res_exp<<std::endl;
        #endif

        normalise_addsub(res_mant, res_exp);

        #if DEBUG_MODE
        std::cout<<"norm mant: "<<std::bitset<18>(res_mant)<<std::endl;
        std::cout<<"norm_exp: "<<res_exp<<std::endl;
        #endif

        res_mant <<= (MANT_WIDTH-NUM_ROUND_BITS);

        round(res_mant);

        #if DEBUG_MODE
        std::cout<<"rounded mant: "<<std::bitset<20>(res_mant)<<std::endl;
        #endif

        if((res_mant&(POINT32<<1)) == (POINT32<<1))
        {
            res_mant >>= 1;
            res_exp += 1;
        }


        if(((res_mant&(POINT32)) == (POINT32)) & (res_exp == -15))
        {
            res_exp += 1;
        }

        #if DEBUG_MODE
        std::cout<<"rounded_res_exp: "<<res_exp<<std::endl;
        #endif

        uint16_t ret_val = res_sign + ((uint16_t) (res_mant>>10)&MANT) + ((res_exp+15)<<10);
        //std::cout<<" ret val: "<<std::bitset<16>(ret_val);
    
        FP16 ret = FP16(ret_val);

        #if DEBUG_MODE
        std::cout<<"final: "<<std::bitset<16>(ret.val)<<std::endl;
        #endif

        return ret;
    }
}


int16_t FP16::align_mantissas(uint32_t &mant_a, uint32_t &mant_b, int16_t &exp_a, int16_t &exp_b)
{
    if(exp_a > exp_b)
    {
        mant_a <<= NUM_ROUND_BITS;
        mant_b <<= NUM_ROUND_BITS;
        mant_b >>= (exp_a - exp_b);
        return exp_a;
    }
    else 
    {
        mant_b <<= NUM_ROUND_BITS;
        mant_a <<= NUM_ROUND_BITS;
        mant_a >>= (exp_b - exp_a);
        return exp_b;
    }
}


void FP16::normalise_addsub(uint32_t &mant, int16_t &res_exp)
{
    if(1<<(NUM_ROUND_BITS + MANT_WIDTH + 1) & mant)
    {
        mant >>= 1;
        res_exp++;
    }
    else if(1<<(NUM_ROUND_BITS + MANT_WIDTH) & mant)
    {
        
    }
    else 
    {
        uint8_t lz = 0;
        for(; (mant<<(lz)&(0x00000001<<(NUM_ROUND_BITS+MANT_WIDTH))) != (0x00000001<<(NUM_ROUND_BITS+MANT_WIDTH)); lz++){if(lz==100){break;}}
        //std::cout<<"lz:"<<(int)lz<<std::endl;

        if(lz < (res_exp - MIN_EXP))
        {
            mant <<= lz;
            res_exp -= lz;
        }
        else 
        {
            mant <<= (res_exp - MIN_EXP);
            res_exp = -15;
        }
    }
}




void FP16::round(uint32_t &mantissa)
{
    if(SR)
    {
        uint32_t rand = (uint32_t) LFSR(NUM_ROUND_BITS, 0);

        mantissa += rand<<(10-NUM_ROUND_BITS);
    }
    else
    {
        mantissa += 0x00000200;
    }
}

uint8_t FP16::clz(uint16_t num)
{
    /* simple implementation */
    unsigned short int shift = 1;
    for(; ((num<<shift) & POINT16) != POINT16; shift++){}

    return shift;
}


uint16_t FP16::LFSR(uint8_t num_round_bits, bool reset)
{
    uint16_t start_state = 0xACE1u;  /* Any nonzero start state will work. */
    static uint16_t lfsr;

    if(reset)
    {
        lfsr = start_state;
        return 0;
    }

    uint16_t feedback;                    /* Must be 16-bit to allow bit<<15 later in the code */
    uint16_t rand_out;
    
    for(uint8_t bit_idx = 0; bit_idx<num_round_bits; bit_idx++)
    {
        /* taps: 16 14 13 11; feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1 */
        feedback = ((lfsr) ^ (lfsr << 2) ^ (lfsr << 3) ^ (lfsr << 5)) & 0x8000;
        lfsr = (lfsr>>1) + (feedback);
    }
    rand_out = lfsr>>(16-num_round_bits);

    return rand_out;
}


#if DEBUG_MODE
int main()
{
    FP16 fp1 = FP16(0b0000000011100110);
    FP16 fp2 = FP16(0b1000000011100110);

    FP16 res = fp1+fp2;
}
#endif


// FP16::set_zero(bool negative)
// {
//     exp = 0;
//     sign = negative;
//     mant = 0;

//     flag_arr = {1, 0, 0, 0, 0, 0};
// }

// FP16::set_inf(bool negative)
// {
//     exp = 31;
//     mant = 0x3FF;
//     sign = negative;

//     flag_arr = {0, 1, 0, 0, 0, 0};
// }


//0043 7BFF
//0.000004 * 65504 = 0.26202



/*
void unit_tests(void)
{
    //manually selected tests verified by hand for initial testing of test framework and rtl 

    //0, -0, inf, -inf, subN, -subN, -Norm, +Norm (close to inf), QNaN, SNaN
    uint16_t unit_test_arr[10] = {0x0000, 0x8000, 0x7C00, 0xFC00,
                                  0x0043, 0x8052, 0x9700, 0x7BFF, 
                                  TEST_NAN, TEST_NAN};

    uint16_t unit_test_pve[55] = {0x0000, 0x8000, TEST_NAN, TEST_NAN, 0x0000, 0x8000, 0x8000, 0x0000, TEST_NAN, TEST_NAN,
                                  0x0000, TEST_NAN, TEST_NAN, 0x8000, 0x0000, 0x0000, 0x8000, TEST_NAN, TEST_NAN,
                                  0x7C00, 0xFC00, 0x7C00, 0xFC00, 0xFC00, 0x7C00, TEST_NAN, TEST_NAN,
                                  0x7C00, 0xFC00, 0x7C00, 0x7C00, 0xFC00, TEST_NAN, TEST_NAN,
                                  0x0000, 0x8000, 0x8000, 0x342F, TEST_NAN, TEST_NAN,
                                  0x0000, 0x0000, 0xB51F, TEST_NAN, TEST_NAN,
                                  0x0031, 0xD6FF, TEST_NAN, TEST_NAN,
                                  0x7C00, TEST_NAN, TEST_NAN,
                                  TEST_NAN, TEST_NAN, 
                                  TEST_NAN};
                                  

    uint8_t idx_1      = 0;
    uint8_t idx_2      = 0;
    uint8_t res_idx    = 0;
    uint8_t pass       = 0;
    unsigned int pass_count = 0;

    std::string suc_strings[2] = {"PASS", "FAIL"};

    for(; idx_1 < 10; idx_1++)
    {
        for(idx_2 = idx_1; idx_2 < 10; idx_2++)
        {
            FP16 op1 = FP16(unit_test_arr[idx_1]);
            FP16 op2 = FP16(unit_test_arr[idx_2]);
            
            FP16 res = op1*op2;

            if(res.val == unit_test_pve[res_idx])
            {
                pass = 0;
                pass_count++;
            }
            else
            {
                pass = 1;
            }

            std::cout<<suc_strings[pass]<<" res = "<<std::bitset<16>(res.val)<<" expected value = "<<std::bitset<16>(unit_test_pve[res_idx])<<"\n";
            
            res_idx++;
        }
    }
    std::cout<<"\n\n pass count = "<<pass_count<<"/55";
}
*/







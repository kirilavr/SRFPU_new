#include "../src/FP16_sim.hpp"

FP16::FP16(uint16_t num)
{
    val = num;
    exp = ((num & EXP)>>10) - 15;
    mant = (num & MANT) + POINT16;
    sign = num & SIGN;

    //case: zero 
    if((mant == POINT16) & (exp == -15))
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

    else if(res_exp < -24)
    {
        FP16 ret = FP16(res_sign == POS_ZERO ? POS_ZERO : NEG_ZERO);
        return ret;
    }

    else if(res_exp < -14)
    {
        res_mant = res_mant >> (-14 - res_exp);
        res_exp  = 0;

        FP16 ret = FP16(0x0000 + res_sign + ((res_mant>>10)&MANT));
        return ret;
    }

    else
    {
        res_exp += 15;  
        FP16 ret = FP16(0x0000 + res_sign + (res_exp<<10) + ((res_mant>>10)&MANT));

        return ret;
    }


}

/*
FP16::operator+(FP16& num2)
{
    
}
*/

uint8_t FP16::clz(uint16_t num)
{
    /* simple implementation */
    unsigned short int shift = 1;
    for(; ((num<<shift) & POINT16) != POINT16; shift++){}

    return shift;
}



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


int main()
{
    unit_tests();
}




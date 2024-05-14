#include "FPops_simulation.hpp"


FP16::FP16(float input)
{   
    /* Get inputs separately */
    uint32_t mantissa_32 = INPUT_MANTISSA(std::bit_cast<uint32_t>(input));
    uint32_t sign_32 = INPUT_SIGN(std::bit_cast<uint32_t>(input));
    uint32_t exp_32 = std::bit_cast<uint32_t>(input);

    /* bit operations: 
     * Converting to 2s complement:
     * 1. Get just the exponent and add 1 
     * 2. Flip the top bit
     * 3. Cast to 8 bit format so that can bit_cast to int8 
     */
    uint32_t exp_32_tmp = ((exp_32>>23) + 1) & 0x000000FF;
    exp_32 = (exp_32_tmp&0x0000007F) + ((exp_32_tmp ^ 0x00000080)&0x00000080);
    uint8_t exp_8 = exp_32;

    /* Bit cas to int8 for easy exponent manipulations 
     * shift the mantissa (not necessary but easier to keep it than change since add and multiply work with those bit positions) 
     * (the and with the mantissa bits serves only for debugging during tests the input will be only FP32 which can be
     * represented exactly in FP16)
     */
    this->exponent = std::bit_cast<int8_t>(exp_8);
    this->mantissa = (mantissa_32>>3) & 0x000FFC00;
    this->sign = ((uint8_t) sign_32>>31);

    #if DEBUG_MODE
    std::cout<<"mantissa, exp =  "<<std::bitset<32>(this->mantissa)<<" "<<std::bitset<8>(this->exponent);
    #endif
}


floating::floating(RNG gen)
{
    this->gen = gen;
    
    #if DEBUG_MODE
    std::cout<<"floating: constructed, RNG is "<<this->gen;
    #endif
}


short floating::normaliser(uint32_t &unnormalised)
{
    static const uint32_t ones = -1;

    short shift = 0;

    if(unnormalised == 0)
    {
        return 0;
    }

    /* The binary point is explicit and hence to find the shift we shift until there is nothing left */
    for(;((unnormalised >> 21)>>shift) > 0; shift ++){}

    unnormalised>>=shift;
    unnormalised = (unnormalised & 0x000FFFFF);

    #if DEBUG_MODE
    std::cout<<"Normaliser: shift = "<<shift<<std::endl;
    #endif

    return shift;
}

/* Round to nearest is detailed in the report: chapter 1.1 */
void floating::RN(uint32_t &unrounded)
{
    unrounded = (unrounded + 0x00000200) & 0xFFFFFC00;

    #if DEBUG_MODE
    std::cout<<"RN: remainder = "<<remainder<<" unrounded = "<<unrounded<<std::endl;
    #endif
}

/* The SR algorithm can be found in the report: Chapter 1.3 algorithm 2*/
void floating::SR(uint32_t &unrounded)
{
    uint32_t remainder = BOTTOM_10_BITS(unrounded);
    uint32_t random_number = (RNG_dict.at(this->gen))();

    remainder += BOTTOM_10_BITS(random_number);

    if(NOT_BOTTOM_10_BITS(remainder) != 0)
    {
        unrounded += (1<<10);
        unrounded = NOT_BOTTOM_10_BITS(unrounded);
    }
    else
    {
        unrounded = NOT_BOTTOM_10_BITS(unrounded);
    }
}

/* Floating point addition is detailed in chapter 1.1 */
FP16* floating::addition(FP16 *fp1, FP16 *fp2)
{
    uint32_t res_mantissa;
    int8_t res_exp;
    uint8_t res_sign;
    FP16* res = new FP16(0);

    if(fp1->exponent == -127 || fp2->exponent == -127)
    {
        if(fp1->exponent == -127)
        {
            res_exp = fp2->exponent;
            res_mantissa = fp2->mantissa;
        }
        else if(fp2->exponent == -127)
        {
            res_exp = fp1->exponent;
            res_mantissa = fp1->mantissa;
        }

        res->exponent = res_exp;
        res->mantissa = res_mantissa;
        res->sign = res_sign;

        #if DEBUG_MODE
        std::cout<<"Addition: 0 detected: res_exp="<<std::bitset<8>(res_exp)<<" res_mantissa"<<std::bitset<32>(res_mantissa)<<std::endl;
        #endif

        return res;
    }

    else if(fp1->exponent > fp2->exponent)
    {
        int exp_diff = fp1->exponent - fp2->exponent;

        #if DEBUG_MODE
        std::cout<<"Addition: condition: fp1->exp > fp2->exp: fp1 exp = "<<std::bitset<8>(fp1->exponent)<<" fp2 exp = "<<std::bitset<8>(fp2->exponent)<<std::endl;
        #endif

        res_exp = fp2->exponent + exp_diff;
        res_mantissa = (fp2->mantissa + EXPLICIT_POINT) >> exp_diff;
        res_mantissa += (fp1->mantissa + EXPLICIT_POINT);
    }
    else if(fp2->exponent > fp1->exponent)
    {
        int exp_diff = fp2->exponent - fp1->exponent;

        #if DEBUG_MODE
        std::cout<<"Addition: condition: fp2->exp > fp1->exp: fp1 exp = "<<std::bitset<8>(fp1->exponent)<<" fp2 exp = "<<std::bitset<8>(fp2->exponent)<<std::endl;
        #endif

        res_exp = fp1->exponent + exp_diff;
        res_mantissa = (fp1->mantissa + EXPLICIT_POINT)>> exp_diff;
        res_mantissa += (fp2->mantissa + EXPLICIT_POINT);
    }
    else
    {
        res_exp = fp1->exponent;
        res_mantissa = (fp1->mantissa + EXPLICIT_POINT) + (fp2->mantissa + EXPLICIT_POINT);
    }

    /* Not considering sign for now */
    res_sign = 0;

    #if DEBUG_MODE
    std::cout<<"Addition: res_exp = "<<std::bitset<8>(res_exp)<<"res_mantissa = "<<std::bitset<32>(res_mantissa)<<std::endl;
    #endif

    res_exp += normaliser(res_mantissa);
    
    #if DEBUG_MODE
    std::cout<<"Addition: normalisation complete, normalised mantissa = "<<std::bitset<32>(res_mantissa)<<"final exp = "<<std::bitset<8>(res_exp)<<"\n";
    #endif

    if(this->gen == 1)
    {
        RN(res_mantissa);
    }
    else
    {
        SR(res_mantissa);
    }

    #if DEBUG_MODE
    std::cout<<"Addition: rounding complete\n";
    #endif

    res->exponent = res_exp;
    res->mantissa = res_mantissa;
    res->sign = res_sign;


    return res;
}

/* Floating point multiplication is detailed in chapter 1.1 */
FP16* floating::multiplication(FP16 *fp1, FP16 *fp2)
{
    #if DEBUG_MODE
    std::cout<<"Multiplication: begin multiplication\n";
    #endif

    uint32_t res_mantissa = 0;
    int8_t res_exp;
    uint8_t res_sign;
    FP16* res = new FP16(0);

    if(fp1->exponent == -127 || fp2->exponent == -127)
    {
        res->exponent == 0;
        res->mantissa == 0;
        res->sign == 0;

        return res;
    }

    uint32_t multiplicand_mantissa = (fp1->mantissa + EXPLICIT_POINT);
    uint32_t multiplier_mantissa = (fp2->mantissa + EXPLICIT_POINT);

    for(uint8_t shift = 0; shift < 10; shift++)
    {
        if((multiplier_mantissa & (EXPLICIT_POINT >> shift)) > 0)
        {
            res_mantissa += (multiplicand_mantissa >> shift);
        }
    }

    res_exp = fp1->exponent + fp2->exponent + normaliser(res_mantissa);
    res_mantissa = res_mantissa & 0x000FFFFF;

    if(this->gen == 1)
    {
        RN(res_mantissa);
    }
    else
    {
        SR(res_mantissa);
    }

    #if DEBUG_MODE
    std::cout<<"Multiplication: complete result mantissa = "<<std::bitset<32>(res_mantissa)<<"res exp = "<<res_exp;
    #endif

    res->exponent = res_exp;
    res->mantissa = res_mantissa;

    #if DEBUG_MODE
    std::cout<<"Multiplication: Multiplication complete\n";
    #endif

    return res;
}


float floating::to_denary(FP16* num)
{
    uint32_t int_format;
    uint32_t exp_32;
    uint8_t exp_8;
    int8_t exp_8_s;

    exp_8_s = num->exponent - 1;
    exp_8 = std::bit_cast<uint8_t>(exp_8_s);
    exp_8 = exp_8^0x80;
    exp_32 = exp_8<<23;
    
    int_format += num->sign<<31;
    int_format += num->mantissa << 3;
    int_format += exp_32;

    #if DEBUG_MODE
    std::cout<<"to_denary: int_format = "<<std::bitset<32>(int_format)<<std::endl;
    #endif

    float res = std::bit_cast<float>(int_format);

    return res;
}




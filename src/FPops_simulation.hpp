#ifndef FPOPS_FILE
#define FPOPS_FILE

/*
 * Overview:
 * 
 * This file implements the FP16 stochastic rounding simulation
 * 
 * Use:
 * 
 * User provides input in denary 
 * The input is converted to FP16 
 * This file provides addition and multiplication functionality (others?)
 * 
 */


#include "RNGs.hpp"

#define WEIRD_2S_COMPLEMENT_CONVERTER(x) (x) /* ... */
#define EXPLICIT_POINT (1<<20)
#define BOTTOM_10_BITS(x) (x & 0x3FF)
#define NOT_BOTTOM_10_BITS(x) (x & 0xFFFFFC00)

#define INPUT_EXP(x) (x & 0x7F800000)
#define INPUT_MANTISSA(x) (x & 0x007FE000)
#define INPUT_SIGN(x) (x & 0x80000000)


typedef enum
{
    RN,
    LFSR,
    MT
} RNG;

/* Struct to represent FP16 */
typedef struct FP16
{
    uint8_t sign;
    uint32_t mantissa;
    int8_t exponent;

    FP16(float input);

} FP16;


/* class implementing FP operations */
class floating : public RNGs
{
    RNG gen;

public:

    floating(RNG gen);

private:
    
    /*
     * Performs normalisation, takes unrounded mantissa by reference
     * Returns the value to add to exponent from shifting
     */
    static short normaliser(uint32_t &unnormalised);


    /* Performs round to nearest, takes normalised (unrounded) mantissa by reference */
    static void RN(uint32_t &unrounded);


    /* Performs stochastic rounding */
    void SR(uint32_t &unrounded);

public:

    /* 
     * Performs addition 
     * Takes by reference two FP16s and returns the result in FP16
     */
    FP16* addition(FP16 *fp1, FP16 *fp2);

    FP16* multiplication(FP16 *fp1, FP16 *fp2);

    /*
     * Converts to denary
     * Accepts an FP16 input and returns the value in C++ double format
     */
    float to_denary(FP16 *num);

};

#endif
#ifndef RNG_FILE
#define RNG_FILE

/*
 * Overview
 * 
 * This file implements various random number generators to be used with floating::SR
 * 
 */

#define DEBUG_MODE false
#define TEN_BITS 0x3FF

#include <iostream>
#include <map>
#include <utility>
#include <random>
#include <boost/interprocess/shared_memory_object.hpp>
#include <boost/interprocess/mapped_region.hpp>
#include <sys/types.h>
#include <sys/random.h>
#include <unistd.h>
#include <string>
#include <filesystem>
#include <stdexcept>
#include <iostream>
#include <bitset>
#include <bit>


class RNGs
{
    #if DEBUG_MODE
    public:
    #endif




    /* LFSR */
    static uint16_t LFSR_gen(void);


    /* Mersenne Twister */
    static uint16_t MT_gen(void);


    /* Linux CSRNG */
    static uint16_t CSRNG_gen(void);


    /* Wrapper for interface.py to call */
    /*static uint16_t TRNG_gen(unsigned int num_vals);*/
    

    /* Does fork and exec for TRNG process */
    /*void TRNG_enable_shmem();*/



public:

    RNGs();


protected:

    typedef uint16_t (*func_ptr) (void);
    std::map<uint8_t, func_ptr> RNG_dict;

};



#endif 

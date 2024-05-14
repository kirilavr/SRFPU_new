#include "RNGs.hpp"



RNGs::RNGs()
{
    this->RNG_dict.insert(std::pair<uint8_t, func_ptr>(2, RNGs::LFSR_gen));
    this->RNG_dict.insert(std::pair<uint8_t, func_ptr>(3, RNGs::MT_gen));
    this->RNG_dict.insert(std::pair<uint8_t, func_ptr>(4, RNGs::CSRNG_gen));
}

/* Sourced from wikipedia */
uint16_t RNGs::LFSR_gen(void)
{
    constexpr uint16_t start_state = 0xACE1u;  /* Any nonzero start state will work. */
    static uint16_t lfsr = start_state;
    static uint16_t bit;                    /* Must be 16-bit to allow bit<<15 later in the code */

    uint16_t rand_out = 0;
    
    for(uint8_t bit_idx = 0; bit_idx<10; bit_idx++)
    {
        /* taps: 16 14 13 11; feedback polynomial: x^16 + x^14 + x^13 + x^11 + 1 */
        bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1u;
        lfsr = (lfsr >> 1) | (bit << 15);

        rand_out += bit<<bit_idx;
    }

    return rand_out;
}


uint16_t RNGs::MT_gen(void)
{
    static std::mt19937 mt_gen{};
    std::uniform_int_distribution<> dist{0, TEN_BITS};

    uint16_t rand_out = dist(mt_gen);

    return rand_out;
}

uint16_t RNGs::CSRNG_gen(void)
{
    void* buf = malloc(2);

    #if DEBUG_MODE
    std::cout<<"CSRNG: executing system call\n";
    #endif

    int ret = getrandom(buf, 2, 0);

    #if DEBUG_MODE
    if(ret == 2)
    {
        std::cout<<"CSRNG: getrandom system call successful\n";
    }
    else
    {
        std::cout<<"CSRNG: getrandom system call fail\n";
    }
    #endif

    uint16_t rand = *((uint16_t*) buf);
    free(buf);

    #if DEBUG_MODE
    std::cout<<"CSRNG: number = "<<std::bitset<16>(rand);
    #endif

    return rand;
}






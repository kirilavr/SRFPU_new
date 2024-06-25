#include <verilated.h>
#include <verilated_vcd_c.h>
#include "../obj_dir/Vintegrated.h"
#include "test_fw.hpp"
#include <iomanip>
#include <bit>
#include <cfenv>
//#include "bfloat16.h"


#define MAX_SIM_TIME  10000000000
#define NUM_ROUND_BITS 30
#define MANT_WIDTH 23
//#define debug_verification 1 



int main(int argc, char** argv, char** env) {
    /* dut model object */
    Vintegrated *dut = new Vintegrated;

    Verilated::traceEverOn(true);

    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    uint64_t sim_time = 0;


    std::ofstream fpu_debug_file("fpu_debug_file", std::ios::app);



    dut->resetn = 0;
    dut->clk = 0;
    dut->eval();

    dut->clk = 1;
    dut->eval();

    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();

    dut->resetn = 1;
    dut->clk = 0;
    dut->eval();

    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();
    dut->clk = 0;
    dut->eval();
    dut->clk = 1;
    dut->eval();






    while(sim_time<5000000)
    {


        uint8_t pre_flags = (dut->test_zero<<5) + (dut->test_inf<<4) + (dut->test_subn<<3) + (dut->test_norm<<2) + (dut->test_qnan<<1) + (dut->test_snan);

        uint8_t flags1 = (dut->test_zero1<<5) + (dut->test_inf1<<4) + (dut->test_subn1<<3) + (dut->test_norm1<<2) + (dut->test_qnan1<<1) + (dut->test_snan1);
        uint8_t flags2 = (dut->test_zero2<<5) + (dut->test_inf2<<4) + (dut->test_subn2<<3) + (dut->test_norm2<<2) + (dut->test_qnan2<<1) + (dut->test_snan2);


        fpu_debug_file<<"cycle: "<<sim_time<<" state: "<<(int)dut->state_test<<std::endl;
        fpu_debug_file<<"values available in EX big mant: "<<std::bitset<MANT_WIDTH+1>(dut->test_big_mant)<<" little mant: "<<std::bitset<2*MANT_WIDTH+2>(dut->test_little_mant)<<" arithmetic "<<(int)dut->test_use_dir_res\
        <<" direct result: "<<std::bitset<32>(dut->test_direct_result)<<" sign: "<<int(dut->test_sign)<<" flags: "<<std::bitset<6   >(pre_flags)<<" exp diff: "<<std::bitset<7>(dut->test_exp_diff)<<std::endl;
        fpu_debug_file<<"values available in NORM: adder_res: "<<std::bitset<2*MANT_WIDTH+3>(dut->adder_res_test)<<std::endl;
        fpu_debug_file<<" post processing values: unnorm_mant: "<<std::bitset<2*MANT_WIDTH+3>(dut->test_unnorm_mant)<<" unnorm exp: "<<std::bitset<9>(dut->test_unnorm_exp)<<" norm_mant: "\
        <<std::bitset<2*MANT_WIDTH+3>(dut->test_norm_mant)<<" test_exp_change: "<<std::bitset<9>(dut->test_exp_change)<<std::endl;
        fpu_debug_file<<" flags1 "<<std::bitset<6>(flags1)<<" flags2 "<<std::bitset<6>(flags2)<<std::endl;
        //fpu_debug_file<<" frs1: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->frs1_test<<" frs2 "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->frs2_test<<std::endl;
        //fpu_debug_file<<" op1 : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op1_test<<" op2: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op2_test<<std::endl;
        fpu_debug_file<<" addop1: "<<std::bitset<2*MANT_WIDTH+3>(dut->test_addop1)<<" addop2: "<<std::bitset<2*MANT_WIDTH+3>(dut->test_addop2)<<" shift test: ";
        fpu_debug_file<<std::bitset<9>(dut->shift_test)<<" unround exp: "<<std::bitset<9>(dut->unround_exp_test)<<std::endl;
        //fpu_debug_file<<" op1_fpu : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op1_test_fpu<<" op2_fpu: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op2_test_fpu<<std::endl;
        fpu_debug_file<<" rfrd1 : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->rfrd_1_test<<" rfrd2: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->rfrd_2_test<<std::endl;
        fpu_debug_file<<"rfwd: "<<std::bitset<32>(dut->rfwd_test)<<" pcpi_ready "<<(int)dut->test_pcpi_ready<<" rand val: "<<std::bitset<NUM_ROUND_BITS>(dut->rand_test)<<std::endl;
        fpu_debug_file<<"cvt_reg: "<<std::bitset<56>(dut->cvt_reg_test)<<"\n\n";

        sim_time++;

    }



    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);

}

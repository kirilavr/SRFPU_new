#include <verilated.h>
#include <verilated_vcd_c.h>
#include "../obj_dir/Vcleaner_top.h"
#include "test_fw.hpp"
#include <iomanip>
#include <bit>
#include <cfenv>
//#include "bfloat16.h"


#define MAX_SIM_TIME  10000000000
#define NUM_ROUND_BITS 30
#define MANT_WIDTH 23
//#define debug_verification 1 


uint32_t fmadd32(float test_val1_f, float test_val2_f, uint32_t accumulator, Vcleaner_top* dut, std::ofstream& fpu_debug_file, uint64_t sim_time)
{

    //std::cout<<"enter fmadd32";


    uint8_t pcpi_valid = 0;
    uint8_t mul = 1;
    uint32_t result;
    uint8_t catcher = 0;

    while(1)
    {
        //std::cout<<"enter fmadd32 while";

        dut->clk = 0;
        dut->eval();
        dut->clk = 1;
        dut->eval();

        uint8_t pre_flags = (dut->test_zero<<5) + (dut->test_inf<<4) + (dut->test_subn<<3) + (dut->test_norm<<2) + (dut->test_qnan<<1) + (dut->test_snan);

        uint8_t flags1 = (dut->test_zero1<<5) + (dut->test_inf1<<4) + (dut->test_subn1<<3) + (dut->test_norm1<<2) + (dut->test_qnan1<<1) + (dut->test_snan1);
        uint8_t flags2 = (dut->test_zero2<<5) + (dut->test_inf2<<4) + (dut->test_subn2<<3) + (dut->test_norm2<<2) + (dut->test_qnan2<<1) + (dut->test_snan2);



        fpu_debug_file<<"cycle: "<<sim_time<<" state: "<<(int)dut->state_test<<std::endl;
        fpu_debug_file<<"mantissa difference (available in ALIGN): "<<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->test_mantissa_diff)<<std::endl;
        fpu_debug_file<<"values available in EX big mant: "<<std::bitset<MANT_WIDTH+2>(dut->test_big_mant)<<" little mant: "<<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->test_little_mant)<<" arithmetic "<<(int)dut->test_use_dir_res\
        <<" direct result: "<<std::bitset<32>(dut->test_direct_result)<<" sign: "<<int(dut->test_sign)<<" flags: "<<std::bitset<6>(pre_flags)<<" exp diff: "<<std::bitset<7>(dut->test_exp_diff)<<std::endl;
        fpu_debug_file<<"values available in NORM: adder_res: "<<std::bitset<2*MANT_WIDTH+2>(dut->adder_res_test)<<std::endl;
        fpu_debug_file<<" post processing values: unnorm_mant: "<<std::bitset<2*MANT_WIDTH+2>(dut->test_unnorm_mant)<<" unnorm exp: "<<std::bitset<9>(dut->test_unnorm_exp)<<" norm_mant: "\
        <<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->test_norm_mant)<<" test_exp_change: "<<std::bitset<9>(dut->test_exp_change)<<" norm mant buffer: "<<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->test_norm_mant_buffer)<<std::endl;
        fpu_debug_file<<" flags1 "<<std::bitset<6>(flags1)<<" flags2 "<<std::bitset<6>(flags2)<<std::endl;
        fpu_debug_file<<" norm_mant_latched: "<<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->norm_mant_latched_test);
        fpu_debug_file<<" frs1: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->frs1_test<<" frs2 "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->frs2_test<<std::endl;
        //fpu_debug_file<<" op1 : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op1_test<<" op2: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op2_test<<std::endl;
        fpu_debug_file<<" addop1: "<<std::bitset<2*MANT_WIDTH+2>(dut->test_addop1)<<" addop2: "<<std::bitset<2*MANT_WIDTH+2>(dut->test_addop2)<<" shift test: ";
        fpu_debug_file<<std::bitset<9>(dut->shift_test)<<" unround exp: "<<std::bitset<9>(dut->unround_exp_test)<<std::endl;
        fpu_debug_file<<" op1_fpu : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op1_test_fpu<<" op2_fpu: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op2_test_fpu<<std::endl;
        fpu_debug_file<<" rfrd1 : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->rfrd_1_test<<" rfrd2: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->rfrd_2_test<<std::endl;
        fpu_debug_file<<"rfwd: "<<std::bitset<32>(dut->rfwd)<<" pcpi_ready "<<(int)dut->pcpi_ready<<" rand val: "<<std::bitset<NUM_ROUND_BITS>(dut->rand_test)<<std::endl;
        fpu_debug_file<<std::dec<<"mul_counter test: "<<(int)dut->mul_counter_test<<" multiplicand_test: "<<std::bitset<48>(dut->multiplicand_test)<<std::endl<<std::endl;

        if((dut->pcpi_ready == 0) & (pcpi_valid == 0) & mul)
        {
            dut->op1 = *reinterpret_cast<uint32_t*>(&test_val1_f);
            dut->op2 = *reinterpret_cast<uint32_t*>(&test_val2_f);
            dut->pcpi_valid = 1; 
            pcpi_valid = 1;
            dut->pcpi_insn = 0x10000053;
            dut->eval();
            mul = 0;
        }

        if((dut->pcpi_ready == 0) & (pcpi_valid == 0) & ~mul)
        {
            dut->op1 = accumulator;
            dut->op2 = result;
            dut->pcpi_valid = 1; 
            pcpi_valid = 1;
            dut->pcpi_insn = 0x00000053;
            dut->eval();
            mul = 1;
        }


        if(dut->pcpi_ready == 1)
        {
            dut->pcpi_valid = 0;
            pcpi_valid = 0;

            if(mul)
            {
                return ((uint32_t)dut->result)<<16;
            }
            else 
            {
                result = dut->result<<16;
                mul = 0;
            }
        }
    }
}


void notify(const std::string &message) {
    std::string command = "notify-send \"" + message + "\"";
    system(command.c_str());
}

int main(int argc, char** argv, char** env) {

    std::fesetround(FE_TONEAREST);

    /* dut model object */
    Vcleaner_top *dut = new Vcleaner_top;

    Verilated::traceEverOn(true);

    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    uint64_t sim_time = 0;


    std::ofstream fpu_debug_file("fpu_debug_file", std::ios::app);
    std::ofstream accumulator_file("accumulator", std::ios::app);
    std::ofstream filters_file("filters", std::ios::app);
    std::ofstream layer_file("layer", std::ios::app);
    std::ofstream fmaps_file("fmaps", std::ios::app);




    uint32_t test_val1;
    uint32_t test_val2;

    float test_val1_f;
    float test_val2_f;

    float test_res = 0;
    uint32_t test_res_int = 0;

    uint32_t result;
    float result_f;

    uint8_t pcpi_valid = 0;

    uint32_t accumulator;

    bool mul = 1;


    dut->resetn = 0;
    dut->clk = 0;
    dut->pcpi_valid = 0;
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

    static std::random_device rd;
    static std::mt19937 gen(rd());

    static std::uniform_int_distribution<uint32_t> dis(0x00000000, 0xffffffff);
    static std::uniform_real_distribution<float> filter_dis(0, 10);
    static std::uniform_int_distribution<uint8_t> layer_dis(0, 100);

    uint32_t max_problem_size = 10000000;
    
    std::cout<<"progress: \n";

    uint8_t filter_size = 21;
    uint16_t layer_size = 64 + (filter_size-1)/2;

    float filter1[filter_size][filter_size];
    float filter2[filter_size][filter_size];
    float filter3[filter_size][filter_size];
    float filter4[filter_size][filter_size];
    float filter5[filter_size][filter_size];

    float fmap1[layer_size][layer_size];
    float fmap2[layer_size][layer_size];
    float fmap3[layer_size][layer_size];
    float fmap4[layer_size][layer_size];
    float fmap5[layer_size][layer_size];

    float tfmap1[layer_size][layer_size];
    float tfmap2[layer_size][layer_size];
    float tfmap3[layer_size][layer_size];
    float tfmap4[layer_size][layer_size];
    float tfmap5[layer_size][layer_size];

    float ttfmap1[layer_size][layer_size];
    float ttfmap2[layer_size][layer_size];
    float ttfmap3[layer_size][layer_size];
    float ttfmap4[layer_size][layer_size];
    float ttfmap5[layer_size][layer_size];

    float (*fmaps[5])[layer_size][layer_size] = {&fmap1, &fmap2, &fmap3, &fmap4, &fmap5};
    float (*tfmaps[5])[layer_size][layer_size] = {&tfmap1, &tfmap2, &tfmap3, &tfmap4, &tfmap5};
    float (*ttfmaps[5])[layer_size][layer_size] = {&ttfmap1, &ttfmap2, &ttfmap3, &ttfmap4, &ttfmap5};

    float (*filters[5])[filter_size][filter_size] = {&filter1, &filter2, &filter3, &filter4, &filter5};

    float layer[layer_size][layer_size];

    for(int fil_idx = 0; fil_idx < 5; fil_idx++)
        for(int i = 0; i<filter_size; i++)
        {
            for(int j = 0; j<filter_size; j++)
            {
                (*filters[fil_idx])[i][j] = filter_dis(gen);
            }
        }

    for(int i = 0; i<layer_size; i++)
    {
        for(int j = 0; j<layer_size; j++)
        {
            layer[i][j] = (float)layer_dis(gen);
        }
    }



    for(int i = 0; i<1; i++)
    {
        float accumulator_true = 0;
        double accumulator_double = 0;
        accumulator = 0;
        uint32_t problem_size = 1;
        float a = 13.4;
        float b = 43.1;
        pcpi_valid = 0;

        while(sim_time<5000000)
        {




            // //std::cout<<"enter main loop";
            // accumulator = fmadd32(test_val1_f, test_val2_f, accumulator, dut, fpu_debug_file, sim_time);
            // accumulator_true += test_val1_f*test_val2_f;
            // accumulator_double += test_val1_f*test_val2_f;
            // if(problem_size%10000 == 0)
            // {
            //     //accumulator_file<<std::hex<<std::setw(8)<<std::setfill('0')<<"val1: "<<(*reinterpret_cast<uint32_t*>(&test_val1_f))<<"val2: "<<(*reinterpret_cast<uint32_t*>(&test_val2_f));
            //     accumulator_file<<"   "<<std::setprecision(10)<<problem_size<<","<<accumulator_true<<","<<*reinterpret_cast<float*>(&accumulator)<<","<<accumulator_double<<std::endl;}
            // test_val1_f = dis(gen);
            // test_val2_f = dis(gen);
            // problem_size++;

            dut->clk = 0;
            dut->eval();
            dut->clk = 1;
            dut->eval();

            if(!pcpi_valid)
            {
                test_val1 = dis(gen);
                test_val2 = dis(gen);
                test_val1_f = *reinterpret_cast<float*>(&test_val1);
                test_val2_f = *reinterpret_cast<float*>(&test_val2);
                dut->pcpi_valid = 1;
                pcpi_valid = 1;
                dut->pcpi_insn = 0x10000053;
                dut->op1 = test_val1;
                dut->op2 = test_val2;
                dut->pcpi_rs1 = test_val1;
            }

            uint8_t pre_flags = (dut->test_zero<<5) + (dut->test_inf<<4) + (dut->test_subn<<3) + (dut->test_norm<<2) + (dut->test_qnan<<1) + (dut->test_snan);
 
            uint8_t flags1 = (dut->test_zero1<<5) + (dut->test_inf1<<4) + (dut->test_subn1<<3) + (dut->test_norm1<<2) + (dut->test_qnan1<<1) + (dut->test_snan1);
            uint8_t flags2 = (dut->test_zero2<<5) + (dut->test_inf2<<4) + (dut->test_subn2<<3) + (dut->test_norm2<<2) + (dut->test_qnan2<<1) + (dut->test_snan2);


            fpu_debug_file<<"cycle: "<<sim_time<<" state: "<<(int)dut->state_test<<std::endl;
            fpu_debug_file<<"mantissa difference (available in ALIGN): "<<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->test_mantissa_diff)<<std::endl;
            fpu_debug_file<<"values available in EX big mant: "<<std::bitset<MANT_WIDTH+1>(dut->test_big_mant)<<" little mant: "<<std::bitset<2*MANT_WIDTH+2>(dut->test_little_mant)<<" arithmetic "<<(int)dut->test_use_dir_res\
            <<" direct result: "<<std::bitset<32>(dut->test_direct_result)<<" sign: "<<int(dut->test_sign)<<" flags: "<<std::bitset<6   >(pre_flags)<<" exp diff: "<<std::bitset<7>(dut->test_exp_diff)<<std::endl;
            fpu_debug_file<<"values available in NORM: adder_res: "<<std::bitset<2*MANT_WIDTH+3>(dut->adder_res_test)<<std::endl;
            fpu_debug_file<<" post processing values: unnorm_mant: "<<std::bitset<2*MANT_WIDTH+3>(dut->test_unnorm_mant)<<" unnorm exp: "<<std::bitset<9>(dut->test_unnorm_exp)<<" norm_mant: "\
            <<std::bitset<2*MANT_WIDTH+3>(dut->test_norm_mant)<<" test_exp_change: "<<std::bitset<9>(dut->test_exp_change)<<" norm mant buffer: "<<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->test_norm_mant_buffer)<<std::endl;
            fpu_debug_file<<" flags1 "<<std::bitset<6>(flags1)<<" flags2 "<<std::bitset<6>(flags2)<<std::endl;
            fpu_debug_file<<" norm_mant_latched: "<<std::bitset<MANT_WIDTH+NUM_ROUND_BITS+2>(dut->norm_mant_latched_test);
            //fpu_debug_file<<" frs1: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->frs1_test<<" frs2 "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->frs2_test<<std::endl;
            //fpu_debug_file<<" op1 : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op1_test<<" op2: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op2_test<<std::endl;
            fpu_debug_file<<" addop1: "<<std::bitset<2*MANT_WIDTH+3>(dut->test_addop1)<<" addop2: "<<std::bitset<2*MANT_WIDTH+3>(dut->test_addop2)<<" shift test: ";
            fpu_debug_file<<std::bitset<9>(dut->shift_test)<<" unround exp: "<<std::bitset<9>(dut->unround_exp_test)<<std::endl;
            //fpu_debug_file<<" op1_fpu : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op1_test_fpu<<" op2_fpu: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->op2_test_fpu<<std::endl;
            fpu_debug_file<<" rfrd1 : "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->rfrd_1_test<<" rfrd2: "<<std::hex<<std::setw(8) << std::setfill('0')<<dut->rfrd_2_test<<std::endl;
            fpu_debug_file<<"rfwd: "<<std::bitset<32>(dut->rfwd)<<" pcpi_ready "<<(int)dut->pcpi_ready<<" rand val: "<<std::bitset<NUM_ROUND_BITS>(dut->rand_test)<<std::endl;
            fpu_debug_file<<"cvt_reg: "<<std::bitset<56>(dut->cvt_reg_test);
            fpu_debug_file<<std::dec<<"mul_counter test: "<<(int)dut->mul_counter_test<<" multiplicand_test: "<<std::bitset<48>(dut->multiplicand_test)<<std::endl<<std::endl;


            if(dut->pcpi_ready)
            {
                result_f = test_val1_f*test_val2_f;
                result   = dut->result;

                dut->pcpi_valid = 0;
                pcpi_valid = 0;

                float cvt_res;
                
                if(test_val1_f != 0)
                {
                    cvt_res = (float)test_val1;//(test_val1_f >= 0x7fffffff ? 0x7fffffff : (int32_t)(std::round(test_val1_f)));
                }
                else 
                {
                    cvt_res = 0;//(abs(test_val1_f) >= 0x7fffffff ? 0x80000000 : (int32_t)(std::round(test_val1_f)));
                }

                bool pass_condition = /*(*reinterpret_cast<float*>(&dut->result) == cvt_res)*/(*reinterpret_cast<float*>(&dut->result) == result_f) || (std::isnan(*reinterpret_cast<float*>(&dut->result)) && std::isnan(result_f));

                if(pass_condition)
                {
                    fpu_debug_file.close();
                    fpu_debug_file.open("fpu_debug_file", std::ios::out);
                    fpu_debug_file.close();
                    fpu_debug_file.open("fpu_debug_file", std::ios::app);
                    // std::cout<<"input: "<<test_val1<<" binary input: "<<std::bitset<32>(test_val1)<<std::endl;
                    // std::cout<<" expected int val: "<<result_f<<" binary expected int val: "<<std::bitset<32>(*reinterpret_cast<uint32_t*>(&result_f))<<std::endl;
                    // std::cout<<" result: "<<*reinterpret_cast<float*>(&dut->result)<<" binary result: "<<std::bitset<32>(dut->result)<<std::endl<<std::endl;
                }
                else 
                {
                    std::cout<<"input: "<<test_val1<<" binary input: "<<std::bitset<32>(test_val1)<<std::endl;
                    std::cout<<" expected int val: "<<result_f<<" binary expected int val: "<<std::bitset<32>(*reinterpret_cast<uint32_t*>(&result_f))<<std::endl;
                    std::cout<<" result: "<<*reinterpret_cast<float*>(&dut->result)<<" binary result: "<<std::bitset<32>(dut->result)<<std::endl<<std::endl;


                //     std::cout<<"FAIL value 1: "<<std::bitset<32>(test_val1)<<" value 2: "<<std::bitset<32>(test_val2)<<std::endl;
                //     std::cout<<"value 1: "<<test_val1_f<<" value 2: "<<test_val2_f<<std::endl;
                //     std::cout<<"expected result: "<<result_f<<" result: "<<*reinterpret_cast<float*>(&dut->result)<<std::endl;
                //     std::cout<<"expected result: "<<std::bitset<32>(*reinterpret_cast<uint32_t*>(&result_f))<<" result: "<<std::bitset<32>(dut->result)<<std::endl;
                    break;
                }
            }






            // for(int fmap_idx = 0; fmap_idx<5; fmap_idx++)
            // {
            //     for(int i = (filter_size-1)/2; i<layer_size-(filter_size-1)/2; i++)
            //     {
            //         for(int j = (filter_size-1)/2; j<layer_size-(filter_size-1)/2; j++)
            //         {
            //             for(int k = -(filter_size-1)/2; k<(filter_size-1)/2+1; k++)
            //             {
            //                 for(int l = -(filter_size-1)/2; l<(filter_size-1)/2+1; l++)
            //                 {
            //                     //std::cout<<"fmap_idx "<<fmap_idx<<" i "<<i<< " j "<<j<<" k "<<k<<" l "<<l<<std::endl;
            //                     accumulator = fmadd32(layer[i+k][j+l], (*filters[fmap_idx])[k+(filter_size-1)/2][l+(filter_size-1)/2], accumulator, dut, fpu_debug_file, sim_time);
            //                     accumulator_true += layer[i+k][j+l] * (*filters[fmap_idx])[k+(filter_size-1)/2][l+(filter_size-1)/2];
            //                     accumulator_double += (double)layer[i+k][j+l] * (double)(*filters[fmap_idx])[k+(filter_size-1)/2][l+(filter_size-1)/2];
            //                 }
            //             }
                        
            //             (*fmaps[fmap_idx])[i][j] = *reinterpret_cast<float*>(&accumulator);
            //             (*tfmaps[fmap_idx])[i][j] = accumulator_true;
            //             (*ttfmaps[fmap_idx])[i][j] = accumulator_double;

            //             //std::cout<<*reinterpret_cast<float*>(&accumulator)<<std::endl;
            //             //std::cout<<accumulator_true<<std::endl;
            //             //std::cout<<accumulator_double<<std::endl<<std::endl;
            //             accumulator = 0;
            //             accumulator_true = 0;
            //             accumulator_double = 0;


            //         }
            //     }
            //     std::cout<<"Feature map completed \n";
            // }
            // break;




            sim_time++;

            if(sim_time % 1000000 == 0)
            {
                std::cout<<"=";
            }


        }
        std::cout<<"run"<<i<<" complete \n";
    }

    //notify("The program has finished!");
       
    fpu_debug_file.close();
    accumulator_file.close();

    for(int i = 0; i<layer_size; i++)
    {
        for(int j = 0; j<layer_size; j++)
        {
            layer_file<<layer[i][j]<<",";
        }
        layer_file<<"\n";
    }

    layer_file.close();

    for(int fmap_idx = 0; fmap_idx<5; fmap_idx++)
    {
        for(int i = 0; i<layer_size; i++)
        {
            for(int j = 0; j<layer_size; j++)
            {
                fmaps_file<<(*fmaps[fmap_idx])[i][j]<<",";
            }
            fmaps_file<<"\n";
        }
        fmaps_file<<"\n\n\n";
    }

    fmaps_file.close();

    std::ofstream tfmaps_file("tfmaps_file", std::ios::app);
    for(int fmap_idx = 0; fmap_idx<5; fmap_idx++)
    {
        for(int i = 0; i<layer_size; i++)
        {
            for(int j = 0; j<layer_size; j++)
            {
                tfmaps_file<<(*tfmaps[fmap_idx])[i][j]<<",";
            }
            tfmaps_file<<"\n";
        }
        tfmaps_file<<"\n\n\n";
    }

    tfmaps_file.close();


    for(int fmap_idx = 0; fmap_idx<5; fmap_idx++)
    {
        for(int i = 0; i<filter_size; i++)
        {
            for(int j = 0; j<filter_size; j++)
            {
                filters_file<<(*filters[fmap_idx])[i][j]<<",";
            }
            filters_file<<"\n";
        }
        filters_file<<"\n\n\n";
    }
    
    filters_file.close();

    double err_sp;
    double err_sr;

    for(int fmap_idx = 0; fmap_idx<5; fmap_idx++)
    {
        for(int i = (filter_size-1)/2; i<layer_size-(filter_size-1)/2; i++)
        {
            for(int j = (filter_size-1)/2; j<layer_size-(filter_size-1)/2; j++)
            {
                err_sp += abs((*tfmaps[fmap_idx])[i][j] - (*ttfmaps[fmap_idx])[i][j]) * abs((*tfmaps[fmap_idx])[i][j] - (*ttfmaps[fmap_idx])[i][j]);

                err_sr += abs((*fmaps[fmap_idx])[i][j] - (*ttfmaps[fmap_idx])[i][j]) * abs((*fmaps[fmap_idx])[i][j] - (*ttfmaps[fmap_idx])[i][j]);
            }
        }
    }

    dut->final();



 
    std::cout<<err_sp<<" "<<err_sr;

    //std::cout<<std::hex<<std::setw(8) << std::setfill('0')<<result;

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);

}











            // if(dut->pcpi_ready == 1)
            // {
            //     pcpi_valid = 0;
            //     result = dut->result;
            //     dut->pcpi_valid = pcpi_valid;

            //     test_val1_f = *reinterpret_cast<float*>(&test_val1);
            //     test_val2_f = *reinterpret_cast<float*>(&test_val2);

            //     test_res = test_val1_f * test_val2_f;

            //     test_res_int = *reinterpret_cast<uint32_t*>(&test_res);

            //     if(std::isnan(test_res))
            //     {
            //         test_res_int = 0x7fc00000;
            //     }
                
            //     if(test_res_int != dut->result)
            //     {
            //         std::cout<<"\nFAIL\n";
            //         fpu_res_file<<"test value 1: "<<std::bitset<32>(test_val1)<<" test value 2: "<<std::bitset<32>(test_val2)<<" expected_result: "<<std::bitset<32>(test_res_int)<<" result: "<<std::bitset<32>(dut->result);
            //         fpu_res_file.close();
            //         break;
            //     }
            //     else 
            //     {
            //         #ifndef debug_verification
            //         fpu_debug_file.close();
            //         fpu_debug_file.open("fpu_debug_file", std::ofstream::trunc);
            //         fpu_debug_file.close();
            //         fpu_debug_file.open("fpu_debug_file", std::ios::app);
            //         #endif 
                    
            //         //fpu_res_file<<"test value 1: "<<std::bitset<32>(test_val1)<<" test value 2: "<<std::bitset<32>(test_val2)<<" expected_result: "<<std::bitset<32>(test_res_int)<<" result: "<<std::bitset<32>(dut->result)<<std::endl;
                    
            //     }

            //     test_val1 = dist(rng);
            //     test_val2 = dist(rng);

            // }
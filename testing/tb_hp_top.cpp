#include "test_fw.hpp"

#define MAX_SIM_TIME 30000000
#define NUM_ROUND_BITS 6

vluint64_t sim_time = 0;

test_case get_test_case(bool soak, bool reset)
{
    int seed = 12345;
    static std::mt19937 rng(seed);
    static std::uniform_int_distribution<std::mt19937::result_type> dist(1, 32);

    static uint32_t i = 0;
    static uint32_t j = 0;

    static uint8_t  k = 0;
    static uint8_t  l = 0;

    uint8_t increment;

    if(reset)
    {
        i = 0;
        j = 0;

        k = 0;
        l = 0;

        test_case dummy_case = {0, 0, 0};

        return dummy_case;
    }

    if(soak)
    {
        increment = dist(rng);

        if(j+increment > 65536)
            if(i+increment > 65536)
            {
                FP16 op1 = FP16(0xFFFF);
                FP16 op2 = FP16(0xFFFF);
                FP16 expected_result = op1*op2;

                test_case Case = {op1, op2, expected_result};
                return Case;
            }
            else
            {
                i += increment;
                j = i;
            }

        FP16 op1 = FP16(i);
        FP16 op2 = FP16(j);

        FP16 expected_result = op1*op2;

        test_case Case = {op1, op2, expected_result};

        j+= increment;
        
        return(Case);
    }

    else
    {

        static uint16_t unit_test_arr[10] = {0x0000, 0x8000, 0x7C00, 0xFC00,
                                             0x0043, 0x8052, 0x9700, 0x7BFF, 
                                             TEST_NAN, TEST_NAN};

        FP16 op1 = FP16(unit_test_arr[k]);
        FP16 op2 = FP16(unit_test_arr[l]);

        FP16 expected_result = op1*op2;

        test_case Case = {op1, op2, expected_result};

        if(l == 9)
        {
            k++;
            l = k;
        }
        else
        {
            l++;
        }

        return Case;
    }
}


uint8_t get_expected_shift(uint64_t test_val)
{
    uint64_t top_bit = 1<<(9+NUM_ROUND_BITS);
    uint8_t shift = 0;
    
    for(;((test_val<<shift) & top_bit) != top_bit; shift++){if(shift > 10+NUM_ROUND_BITS){break;}};

    return shift;
}


bool test_top(Vhp_top* dut, bool soak)
{
    std::ofstream res_file_top("res_file_top.txt", std::ios::app);
    uint16_t sim_time = 0;
    std::string outcome_top;

    while(sim_time < MAX_SIM_TIME)
    {
        test_case Case = get_test_case(soak, false);
        vluint16_t op1 = Case.op1.val;
        vluint16_t op2 = Case.op2.val;

        dut->src_a = op1;
        dut->src_b = op2;

        dut->eval();

        vluint16_t result  = dut->res_out;

        if(result == Case.expected_res.val)
        {
            outcome_top = "PASS";
        }
        else
        {
            outcome_top = "FAIL";
        }

        res_file_top<<"test case "<<sim_time<<": "<<outcome_top<<" Input 1: "\
        <<std::bitset<16>(op1)<<" Input 2: "<<std::bitset<16>(op2)<<" result: "\
        <<std::bitset<16>(result)<<" expected result: "<<std::bitset<16>(Case.expected_res.val)<<"\n";

        sim_time++;

        if(soak)
        {
            if((op1 == 0xFFFF) & (op2 == 0xFFFF))
            {
                break;
            }
        }
    }

    res_file_top.close();

    return true;
}


bool test_mult(Vhp_top* dut, bool soak)
{
    std::ofstream res_file_mult("res_file_mult.txt", std::ios::app);
    uint16_t sim_time = 0;

    while(sim_time < MAX_SIM_TIME)
    {
        test_case Case = get_test_case(soak, false);
        vluint16_t op1 = Case.op1.val;
        vluint16_t op2 = Case.op2.val;

        dut->src_a = op1;
        dut->src_b = op2;

        dut->eval();

        vluint16_t res_mult  = dut->res_mult_t;
        vluint8_t flags_mult = dut->mult_flags_t;
        vluint8_t res_exp_mult = dut->res_exp_t;
        vluint32_t res_mant_mult = dut->res_mant_t;

        res_file_mult<<"test case: "<<sim_time<<" Input 1: "<<std::bitset<16>(op1)<<" Input 2: "\
        <<std::bitset<16>(op2)<<" result: "<<std::bitset<16>(res_mult)<<" flags: "\
        <<std::bitset<6>(flags_mult)<<" res mant: "<<std::bitset<22>(res_mant_mult)<<" res exp: "\
        <<std::bitset<6>(res_exp_mult)<<" shift: "<<std::bitset<4>(dut->shift)<<" rounding reg: "<<std::bitset<16>(dut->rounding_reg_test)<<"\n";

        sim_time++;

        if(soak)
        {
            if((op1 == 0xFFFF) & (op2 == 0xFFFF))
            {
                break;
            }
        }
    }

    res_file_mult.close();
    return true;
}


bool test_clz(Vhp_top* dut, bool soak)
{
    std::string outcome_clz;

    std::ofstream res_file_clz("res_file_clz.txt", std::ios::app);
    uint16_t sim_time = 0;

    std::random_device dev;
    std::mt19937 rng(dev());
    

    while(sim_time < 10+NUM_ROUND_BITS)
    {   
        std::uniform_int_distribution<std::mt19937::result_type> dist(0, pow(2, sim_time)-1);
        
        decltype(dut->clz_test) test_val = (1<<sim_time) + dist(dev);
        uint8_t expected_res = get_expected_shift(static_cast<uint64_t>(test_val));

        dut->clz_test = test_val;

        dut->eval();

        decltype(dut->clz_res) clz_res = dut->clz_res;

        if(dut->clz_res == expected_res)
        {
            outcome_clz = "PASS";
        }
        else
        {
            outcome_clz = "FAIL";
        }

        res_file_clz<<"test case: "<<sim_time<<" "<<outcome_clz<<" input: "<<std::bitset<10+NUM_ROUND_BITS>(test_val)<<" result: "
        <<static_cast<int>(clz_res)<<" expected result: "<<static_cast<int>(expected_res)<<std::endl;

        sim_time++;
    }

    res_file_clz.close();
    return true;
}


bool test_class(Vhp_top* dut, bool soak)
{
    std::ofstream res_file_class("res_file_class.txt", std::ios::app);
    uint16_t sim_time = 0;
    std::string outcome_class;

    while(sim_time < MAX_SIM_TIME)
    {
        test_case Case = get_test_case(soak, false);
        vluint16_t op1 = Case.op1.val;
        vluint16_t op2 = Case.op2.val;

        uint8_t flags_a = (Case.op1.flag_arr[0]<<5) + (Case.op1.flag_arr[1]<<4) + (Case.op1.flag_arr[2]<<3) +\
                          (Case.op1.flag_arr[3]<<2) + (Case.op1.flag_arr[4]<<1) + (Case.op1.flag_arr[5]);
        uint8_t flags_b = (Case.op2.flag_arr[0]<<5) + (Case.op2.flag_arr[1]<<4) + (Case.op2.flag_arr[2]<<3) +\
                          (Case.op2.flag_arr[3]<<2) + (Case.op2.flag_arr[4]<<1) + (Case.op2.flag_arr[5]);

        dut->src_a = op1;
        dut->src_b = op2;

        dut->eval();

        if((flags_a == dut->flags_a) & (flags_b == dut->flags_b))
        {
            outcome_class = "PASS";
        }
        else
        {
            outcome_class = "FAIL";
        }

        
        res_file_class<<"test_case: "<<sim_time<<" "<<outcome_class<<" flags a: "<<
        std::bitset<6>(dut->flags_a)<<" flags b: "<<std::bitset<6>(dut->flags_b)<<" expected flags a: "
        <<std::bitset<6>(flags_a)<<" expected flags b: "<<std::bitset<6>(flags_b)<<std::endl;

        

        sim_time++;
    }

    res_file_class.close();
    return true;
}


bool test_rng(Vhp_top* dut, bool soak)
{
    std::ofstream res_file_rng("res_file_rng.txt", std::ios::app);
    uint16_t sim_time = 0;
    std::string outcome_rng;
    FP16::LFSR(NUM_ROUND_BITS, true);

    while(sim_time < MAX_SIM_TIME)
    { 
        dut->clk = 0;
        dut->eval();
        
        decltype(dut->rand_out_t) rand_out = dut->rand_out_t;
        uint16_t expected_rand_out = FP16::LFSR(NUM_ROUND_BITS, false);

        if(static_cast<decltype(dut->rand_out_t)>(expected_rand_out) == rand_out)
        {
            outcome_rng = "PASS";
        }
        else
        {
            outcome_rng = "FAIL";
        }

        res_file_rng<<"test case: "<<sim_time<<" "<<outcome_rng<<" res: "<<std::bitset<NUM_ROUND_BITS>(dut->rand_out_t)<<" expected res: "<<
        std::bitset<NUM_ROUND_BITS>(expected_rand_out)<<std::endl;

        sim_time ++; 

        dut->clk = 1;
        dut->eval();
    }

    res_file_rng.close();
    return true;
}

/* This is more of a dummy function */
bool test_round(Vhp_top* dut, bool soak)
{
    std::ofstream res_file_round("res_file_round.txt", std::ios::app);
    uint16_t sim_time = 0;
    std::string outcome_class;

    dut->round_test_in = 0x0FC0;
    dut->eval();
    res_file_round<<"should not round up, input: "<<std::bitset<16>(0x0FC0)<<" output: "<<std::bitset<10>(dut->round_test_out)<<std::endl;

    dut->round_test_in = 0x0FE0;
    dut->eval();
    res_file_round<<"should round up input: "<<std::bitset<16>(0x0FE0)<<" output: "<<std::bitset<10>(dut->round_test_out);

    return true;
}



int main(int argc, char** argv, char** env) {

    /* dut model object */
    Vhp_top *dut = new Vhp_top;

    Verilated::traceEverOn(true);

    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");

    /* perform resets */
    dut->reset = 0;
    dut->clk = 0;
    dut->eval();
    dut->reset = 1;
    dut->eval();
    dut->reset = 0;
    dut->eval();

    /* call test function below */
    test_mult(dut, 1);
    /****************************/

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);

}











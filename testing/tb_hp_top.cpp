#include "test_fw.hpp"

#define MAX_SIM_TIME 100000
#define NUM_ROUND_BITS 6
#define SR 0

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





bool test_muldiv(Vhp_top* dut, bool soak)
{
    std::ofstream res_file_muldiv_pre("res_file_muldiv_pre.txt", std::ios::app);
    std::ofstream res_file_muldiv("res_file_muldiv.txt", std::ios::app);
    std::ofstream res_file_muldiv_norm("res_file_muldiv_norm.txt", std::ios::app);
    std::ofstream res_file_muldiv_top("res_file_muldiv_top.txt", std::ios::app);
    uint16_t sim_time = 0;

    std::string outcome;

    vluint16_t mantA;
    vluint16_t mantB;

    vluint8_t expA;
    vluint8_t expB;

    vluint8_t arithmetic;
    vluint16_t direct_res;
    vluint8_t sign;

    vluint32_t unnorm_mant;
    vluint8_t unnorm_exp;

    vluint16_t unrounded_mant;
    vluint8_t unrounded_exp;

    vluint16_t result;
    vluint8_t flag_test;

    int shift_test;

    uint8_t exp_flags;

    while(sim_time < MAX_SIM_TIME)
    {
        test_case Case = get_test_case(soak, false);
        vluint16_t op1 = Case.op1.val;
        vluint16_t op2 = Case.op2.val;

        dut->src_a = op1;
        dut->src_b = op2;

        dut->operation = 0x04;

        dut->eval();

        mantA = dut->muldiv_pre_test_mantA;
        mantB = dut->muldiv_pre_test_mantB;

        expA = dut->muldiv_pre_test_expA;
        expB = dut->muldiv_pre_test_expB;

        arithmetic = dut->muldiv_pre_test_arithmetic;
        direct_res = dut->muldiv_pre_test_direct_result;
        sign = dut->muldiv_pre_test_sign;

        unnorm_mant = dut->muldiv_test_unnorm_mant;
        unnorm_exp = dut->muldiv_test_unnorm_exp;

        unrounded_mant = dut->muldiv_norm_test_unrounded_mant;
        unrounded_exp = dut->muldiv_norm_test_unrounded_exp;

        shift_test = dut->shift_test;

        result = dut->res_out;
        flag_test = dut->flag_test;

        exp_flags = (Case.expected_res.flag_arr[0]<<5) + (Case.expected_res.flag_arr[1]<<4) + (Case.expected_res.flag_arr[2]<<3) +\
                    (Case.expected_res.flag_arr[3]<<2) + (Case.expected_res.flag_arr[4]<<1) + (Case.expected_res.flag_arr[5]);

        if(result == Case.expected_res.val)
        {
            outcome = "PASS";
        }
        else 
        {
            outcome = "FAIL";
        }

        res_file_muldiv_pre<<"test case "<<sim_time<<" input 1: "<<std::bitset<16>(op1)<<" input 2: "<<std::bitset<16>(op2)\
                           <<" mantA: "<<std::bitset<10>(mantA)<<" mantB: "<<std::bitset<10>(mantB)<<" expA: "<<std::bitset<7>(expA)
                           <<" expB: "<<std::bitset<10>(expB)<<" arithmetic: "<<arithmetic<<" dir_res: "<<std::bitset<16>(direct_res)
                           <<" sign: "<<sign<<"\n";

        res_file_muldiv<<"test case "<<sim_time<<" unnorm mant: "<<std::bitset<22>(unnorm_mant)<<" unnorm exp: "<<std::bitset<7>(unnorm_exp)<<" shift: "<<shift_test<<"\n";

        res_file_muldiv_norm<<"test case "<<sim_time<<" unrounded mant: "<<std::bitset<16>(unrounded_mant)<<" unrounded_exp: "<<std::bitset<7>(unrounded_exp)<<"\n";

        res_file_muldiv_top<<"test case "<<sim_time<<":"<<outcome<<" res out: "<<std::bitset<16>(result)<<" flags: "<<std::bitset<6>(flag_test)\
                           <<" expected res: "<<std::bitset<16>(Case.expected_res.val)<<" expected flags: "<<std::bitset<6>(exp_flags)<<" round_out: "<<std::bitset<11>(dut->round_out_test)<<"\n";

        sim_time++;

        if(soak)
        {
            if((op1 == 0xFFFF) & (op2 == 0xFFFF))
            {
                break;
            }
        }
    }

    res_file_muldiv_pre.close();
    res_file_muldiv.close();
    res_file_muldiv_norm.close();
    res_file_muldiv_top.close();

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
        
        decltype(dut->rand_test) rand_out = dut->rand_test;
        uint16_t expected_rand_out = FP16::LFSR(NUM_ROUND_BITS, false);

        if(static_cast<decltype(dut->rand_test)>(expected_rand_out) == rand_out)
        {
            outcome_rng = "PASS";
        }
        else
        {
            outcome_rng = "FAIL";
        }

        res_file_rng<<"test case: "<<sim_time<<" "<<outcome_rng<<" res: "<<std::bitset<NUM_ROUND_BITS>(dut->rand_test)<<" expected res: "<<
        std::bitset<NUM_ROUND_BITS>(expected_rand_out)<<std::endl;

        sim_time ++; 

        dut->clk = 1;
        dut->eval();
    }

    res_file_rng.close();
    return true;
}



int main(int argc, char** argv, char** env) {

    /* dut model object */
    Vhp_top *dut = new Vhp_top;
    INSTR instr = MUL_RN;

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
    dut->operation = instr;
    dut->eval();

    /* call test function below */
    test_muldiv(dut, 1);
    /****************************/

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);

}











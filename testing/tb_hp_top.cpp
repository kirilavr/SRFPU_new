#include "test_fw.hpp"

#define MAX_SIM_TIME 55


test_case get_test_case(bool soak)
{
    static uint16_t i = 0;
    static uint16_t j = 0;

    static uint8_t  k = 0;
    static uint8_t  l = 0;

    if(soak)
    {
        FP16 op1 = FP16(i);
        FP16 op2 = FP16(j);

        FP16 expected_result = op1*op2;

        test_case Case = {i, j, expected_result.val};

        i++;
        j++;
        
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

        test_case Case = {op1.val, op2.val, expected_result.val};

        if(l == 10)
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


vluint64_t sim_time = 0;



int main(int argc, char** argv, char** env) {

    /* dut model object */
    Vhp_top *dut = new Vhp_top;

    Verilated::traceEverOn(true);

    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");
    uint8_t test_idx = 0;

    /* opening file to write test results */
    std::ofstream res_file_top("res_file_top.txt", std::ios::app);
    std::ofstream res_file_class("res_file_class.txt", std::ios::app);

    //unit test loop
    while (sim_time < MAX_SIM_TIME) {


        test_case Case = get_test_case(0);
        vluint16_t op1 = Case.op1;
        vluint16_t op2 = Case.op2;

        dut->src_a = op1;
        dut->src_b = op2;

        dut->eval();

        vluint16_t result = dut->res_out;

        vluint8_t flags_a = dut->flags_a;
        vluint8_t flags_b = dut->flags_b;

        res_file_top<<"test case: "<<sim_time<<" Input 1: "<<std::bitset<16>(op1)<<" Input 2: "<<std::bitset<16>(op2)<<" result: "<<std::bitset<16>(result)<<"\n";
        res_file_class<<"test_case: "<<sim_time<<" flags a: "<<std::bitset<8>(flags_a)<<" flags b: "<<std::bitset<8>(flags_b)<<std::endl;


        sim_time++;
    }

    res_file_top.close();
    res_file_class.close();

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);

}



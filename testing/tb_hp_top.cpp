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
        }
        else
        {
            l++;
        }

        return Case;
    }
}


//vluint64_t sim_time = 0;


/*
int main(int argc, char** argv, char** env) {
    Vhp_top *dut = new Vhp_top;

    Verilated::traceEverOn(true);

    VerilatedVcdC *m_trace = new VerilatedVcdC;
    dut->trace(m_trace, 5);
    m_trace->open("waveform.vcd");
    uint8_t test_idx = 0;

    //unit test loop
    while (sim_time < MAX_SIM_TIME) {


        test_case Case = get_test_case(0);
        vluint16_t op1 = Case.op2;
        vluint16_t op2 = Case.op2;

        dut->src_a = op1;
        dut->src_b = op2;

        dut->eval();

        vluint16_t result = dut->res_out;
        std::cout<<std::bitset<16>(result);

        sim_time++;
    }

    m_trace->close();
    delete dut;
    exit(EXIT_SUCCESS);

}

*/

int main()
{
    test_case Case = get_test_case(0);
    std::cout<<Case.op1<<" "<<Case.op2;
}
#ifndef TEST_FW
#define TEST_FW

#include <stdlib.h>
#include <iostream>
#include <verilated.h>
#include <verilated_vcd_c.h>
#include "../obj_dir/Vhp_top.h"
#include <fstream>
#include <random>
#include <algorithm>




/* test specification:
 * 
 * Zero Inf SubN Norm QNan SNan with each of the others and with each sign must be tested 
 * These will be carried out as indpendent unit tests and are verified by hand
 * following this a full test carrying out any 2 fp16 numbers will be carried out to 
 * cover every possible test case 
 */


/* Unit tests */
typedef struct test_case
{
    FP16 op1;
    FP16 op2;

    FP16 expected_res;
}test_case;


test_case get_test_case(bool soak, bool reset);

bool test_top(Vhp_top* dut, bool soak);

bool test_mult(Vhp_top* dut, bool soak);

bool test_class(Vhp_top* dut, bool soak);

bool test_clz(Vhp_top* dut, bool soak);

bool test_rng(Vhp_top* dut, bool soak);




#endif 
#ifndef TEST_FW
#define TEST_FW

#include "../src/FP16_sim.hpp"
#include <stdlib.h>
#include <iostream>
//#include <verilated.h>
//#include <verilated_vcd_c.h>
//#include "../obj_dir/Vhp_top.h"


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
    uint16_t op1;
    uint16_t op2;

    uint16_t expected_res;
}test_case;


test_case get_test_case(bool soak);

#endif 
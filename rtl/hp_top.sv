`include "./rtl/hp_mul"
`include "./rtl/hp_class"
`include "./rtl/hp_round"
`include "./rtl/rng"


/*
   ------------------------------
   |           RISCY            |
   ------------------------------
   |           HP_TOP           |
   ------------------------------
   |           CLASS            |
   ------------------------------
   |    MULDIV    |    ADDSUB   |
   ------------------------------
   |          ROUNDING          |
   ------------------------------
*/


/*
 * inputs: 16 bit operands "a" and "b", 3 bit input to determine operation
 * outputs: 16 bit result of operation with flags
 */
module hp_top #
(
    parameter num_round_bits = 6, 
    parameter num_bits = 16,

    parameter exp_width  = (num_bits == 16) ? 5  : 8,
    parameter mant_width = (num_bits == 16) ? 10 : 23,

    parameter debug_mode = 1
)
(   
    input logic clk,
    input logic reset,

    input logic[num_bits-1:0] src_a,
    input logic[num_bits-1:0] src_b,

    input logic[2:0] operation,
    input logic ops_ready,

    output logic[num_bits-1:0] res_out,
    output logic zero, inf, subN, Norm, QNan, SNan,


    /* testing pins */
    output logic[7:0] flags_a,
    output logic[7:0] flags_b,
    output logic[num_bits-1:0] res_mult_t,
    output logic[7:0] mult_flags_t,
    output logic[5:0] res_exp_t,
    output logic[mant_width*2+1:0] res_mant_t,
    output logic[7:0] shift,

    input logic[9+num_round_bits:0] clz_test,
    output logic[7:0] clz_res,
    output logic[num_round_bits-1:0] rand_out_t,

    input logic[mant_width+num_round_bits-1:0] round_test_in,
    input logic[num_round_bits-1:0] rand_test_in,
    output logic[mant_width-1:0] round_test_out,
    output logic[mant_width+num_round_bits-1:0] rounding_reg_test


);

    /* testing outputs */
    assign flags_a[7] = 0;
    assign flags_a[6] = 0;

    assign flags_a[5] = a_zero;
    assign flags_a[4] = a_inf;
    assign flags_a[3] = a_subN;
    assign flags_a[2] = a_Norm;
    assign flags_a[1] = a_QNan;
    assign flags_a[0] = a_SNan;

    assign flags_b[7] = 0;
    assign flags_b[6] = 0;

    assign flags_b[5] = b_zero;
    assign flags_b[4] = b_inf;
    assign flags_b[3] = b_subN;
    assign flags_b[2] = b_Norm;
    assign flags_b[1] = b_QNan;
    assign flags_b[0] = b_SNan;

    assign mult_flags_t[7] = 0;
    assign mult_flags_t[6] = 0;

    assign mult_flags_t[5] = mul_res_zero;
    assign mult_flags_t[4] = mul_res_inf;
    assign mult_flags_t[3] = mul_res_subN;
    assign mult_flags_t[2] = mul_res_Norm;
    assign mult_flags_t[1] = mul_res_QNan;
    assign mult_flags_t[0] = mul_res_SNan;

    assign res_mult_t        = trunc_result;
    assign rounding_reg_test = rounding_reg;


    /* operation parameters */
    parameter ADD_RN = 3'b000;
    parameter SUB_RN = 3'b010;
    parameter MUL_RN = 3'b100;
    parameter DIV_RN = 3'b110;
    parameter ADD_SR = 3'b001;
    parameter SUB_SR = 3'b011;
    parameter MUL_SR = 3'b101;
    parameter DIV_SR = 3'b111;

    /* defining output wires from "class" module */
    logic a_zero;
    logic a_inf;
    logic a_subN; 
    logic a_Norm;
    logic a_QNan;
    logic a_SNan;

    wire b_zero;
    wire b_inf;
    wire b_subN; 
    wire b_Norm;
    wire b_QNan;
    wire b_SNan;

    /* defining outputs path from operational block currently ADDSUB and MULDIV. */
    wire mul_res_zero;
    wire mul_res_inf;
    wire mul_res_subN; 
    wire mul_res_Norm;
    wire mul_res_QNan; 
    wire mul_res_SNan;

    wire[num_round_bits-1:0] rand_out;

    /* variable output width from operational blocks: note that the maximum from MULDIV */
    reg[mant_width+num_round_bits-1:0] rounding_reg;
    reg[mant_width-1:0]                rounded_result;
    reg[num_bits-1:0]                  trunc_result;


    /* Classifying simultaneously, this could be a potential point of improvement */
    hp_class #(num_bits, exp_width, mant_width) classifier_1(src_a, a_zero, a_inf, a_subN, a_Norm, a_QNan, a_SNan);
    hp_class #(num_bits, exp_width, mant_width) classifier_2(src_b, b_zero, b_inf, b_subN, b_Norm, b_QNan, b_SNan);

    hp_mul #(num_round_bits, num_bits, exp_width, mant_width) multiplier
                     (src_a, a_zero, a_inf, a_subN, a_Norm, a_QNan, a_SNan, 
                      src_b, b_zero, b_inf, b_subN, b_Norm, b_QNan, b_SNan,
                      trunc_result, rounding_reg, 
                      mul_res_zero, mul_res_inf, mul_res_subN, mul_res_Norm, mul_res_QNan, mul_res_SNan,
                      /*testing outputs*/res_exp_t, res_mant_t, shift);

    rng #(num_round_bits) rng(clk, reset, rand_out);
    hp_round #(num_round_bits, num_bits, mant_width) rounding(operation[0], rounding_reg, rand_out, rounded_result);
    hp_round #(num_round_bits, num_bits, mant_width) rounding_testesr(operation[0], round_test_in, rand_test_in, round_test_out);

    clz #(num_round_bits) clz_tester(clz_test, clz_res);
    rng #(num_round_bits) rng_tester(clk, reset, rand_out_t);
    
    

    always_comb
    begin

        case(operation)
            ADD_RN,
            ADD_SR,
            SUB_RN,
            SUB_SR:
            begin 
            end

            MUL_RN,
            MUL_SR:
            begin
                zero = mul_res_zero;
                inf  = mul_res_inf;
                subN = mul_res_subN;
                Norm = mul_res_Norm;
                QNan = mul_res_QNan;
                SNan = mul_res_SNan;
            end 

            DIV_RN,
            DIV_SR:
            begin
            end


        endcase

        if(Norm | subN)
        begin
            res_out = {trunc_result[15:10], rounded_result};
        end
        else
        begin
            res_out = trunc_result;
        end


        
    end      

endmodule;




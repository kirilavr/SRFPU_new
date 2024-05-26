`include "./rtl/classifier"

`include "./rtl/muldiv.sv"
`include "./rtl/muldiv_pre.sv"
`include "./rtl/normaliser_muldiv.sv"

`include "./rtl/addsub.sv"
`include "./rtl/normaliser_add.sv"

`include "./rtl/round"
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


`define debug_mode

module hp_top #
(
    parameter num_round_bits = 6, 
    parameter num_bits = 16,

    parameter exp_width  = (num_bits == 16) ? 5  : 8,
    parameter mant_width = (num_bits == 16) ? 10 : 23
)
(   
    input logic clk,
    input logic reset,

    input logic[num_bits-1:0] src_a,
    input logic[num_bits-1:0] src_b,

    input logic[2:0] operation,

    output logic[num_bits-1:0] res_out,
    output logic zero, inf, subN, Norm, QNan, SNan


    /*testing output*/ 
    `ifdef debug_mode
        ,
        /* test outputs: muldiv_pre */
        output logic [mant_width-1:0] muldiv_pre_test_mantA,
        output logic [mant_width-1:0] muldiv_pre_test_mantB,

        output logic [exp_width+1:0] muldiv_pre_test_expA,
        output logic [exp_width+1:0] muldiv_pre_test_expB,

        output logic                 muldiv_pre_test_arithmetic,
        output logic [num_bits-1:0]  muldiv_pre_test_direct_result,
        output logic                 muldiv_pre_test_sign,


        /* testing_outputs: muldiv */
        output logic [mant_width*2+1:0] muldiv_test_unnorm_mant,
        output logic [exp_width+1:0]    muldiv_test_unnorm_exp,

        /* testing_outputs: muldiv_norm */
        output logic [mant_width+num_round_bits-1:0] muldiv_norm_test_unrounded_mant,
        output logic [exp_width+1:0]                 muldiv_norm_test_unrounded_exp,

        output logic [5:0] flag_test,

        output logic [num_round_bits-1:0] rand_test,

        output logic [exp_width+1:0] shift_test,

        output logic [mant_width:0] round_out_test

    `endif
);

    parameter signed [exp_width+1:0] bias          = (num_bits==16) ? {{(exp_width-5){1'b0}}, 7'd15}: 
                                                                      {7'b0001111, {(exp_width-5){1'b1}}};

    parameter signed [exp_width+1:0] min_exp       = (num_bits==16) ? {{(exp_width-5){1'b1}}, 7'b1110010}: 
                                                                      {3'b111, {(exp_width-5){1'b0}}, 4'b0010};

    parameter signed [exp_width+1:0] max_exp       = (num_bits==16) ? {{(exp_width-5){1'b0}}, 7'b0001111}: 
                                                                      {7'b0001111, {(exp_width-5){1'b1}}};

    localparam signed [exp_width+1:0] min_exp_subN = (num_bits==16) ? {{(exp_width-5){1'b0}}, 7'b1101000}:
                                                                      {{(exp_width-5)/3{3'b110}}, 7'b1101011};
    

    wire[num_bits-1:0] result_mult;


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

    /* Connections to classifier modules*/
    wire mul_res_zero;
    wire mul_res_inf;
    wire mul_res_subN; 
    wire mul_res_Norm;
    wire mul_res_QNan; 
    wire mul_res_SNan;

    wire add_res_zero;
    wire add_res_inf;
    wire add_res_subN; 
    wire add_res_Norm;
    wire add_res_QNan; 
    wire add_res_SNan;

    wire [num_bits-1:0] direct_result_add;
    wire [num_bits-1:0] direct_result_mul;

    wire [mant_width+num_round_bits+1:0] unnorm_mant_add;
    wire [exp_width+1:0]                 unnorm_exp_add;

    wire [mant_width*2+1:0]              unnorm_mant_mul;
    wire [exp_width+1:0]                 unnorm_exp_mul;

    wire [mant_width-1:0]                mantA_mul;
    wire [mant_width-1:0]                mantB_mul;

    wire [exp_width+1:0]                 expA_mul;
    wire [exp_width+1:0]                 expB_mul;

    wire                                 sign_add;
    wire                                 sign_mul;      

    wire [mant_width+num_round_bits+1:0] unrounded_mant_add;
    wire [exp_width+1:0]                 unrounded_exp_add; 

    wire [mant_width+num_round_bits-1:0] unrounded_mant_mul;
    wire [exp_width+1:0]                 unrounded_exp_mul;

    wire [mant_width-1:0]                mantA_mul;
    wire [mant_width-1:0]                mantB_mul;
    wire [exp_width+1:0]                 expA_mul;
    wire [exp_width+1:0]                 expB_mul;

    logic[mant_width+num_round_bits-1:0] clz_in;
    logic[exp_width+1:0]                 clz_out;
    logic                                clz_shift;

    logic[mant_width+num_round_bits-1:0] round_in;
    logic[mant_width:0]                  round_out;

    wire [num_round_bits-1:0]            rand_bits;
    wire                                 arithmetic_add;
    wire                                 arithmetic_mult;


    /* assignments to test pins */
    `ifdef debug_mode

    assign muldiv_pre_test_mantA           = mantA_mul;
    assign muldiv_pre_test_mantB           = mantB_mul; 

    assign muldiv_pre_test_expA            = expA_mul;
    assign muldiv_pre_test_expB            = expB_mul;

    assign muldiv_pre_test_arithmetic      = arithmetic_mult;
    assign muldiv_pre_test_direct_result   = direct_result_mul;
    assign muldiv_pre_test_sign            = sign_mul;

    assign muldiv_test_unnorm_mant         = unnorm_mant_mul;
    assign muldiv_test_unnorm_exp          = unnorm_exp_mul;

    assign muldiv_norm_test_unrounded_mant = unrounded_mant_mul;
    assign muldiv_norm_test_unrounded_exp  = unrounded_exp_mul;

    assign rand_test                       = rand_bits;

    assign shift_test                      = clz_out;

    assign round_out_test                  = round_out;

    assign flag_test[5] = zero;
    assign flag_test[4] = inf; 
    assign flag_test[3] = subN;
    assign flag_test[2] = Norm;
    assign flag_test[1] = QNan;
    assign flag_test[0] = SNan;
    `endif


    assign clz_shift = a_subN | b_subN;

    classifier #(num_bits, exp_width, mant_width) classifier_1(src_a, a_zero, a_inf, a_subN, a_Norm, a_QNan, a_SNan);
    classifier #(num_bits, exp_width, mant_width) classifier_2(src_b, b_zero, b_inf, b_subN, b_Norm, b_QNan, b_SNan);

    addsub #(num_round_bits, num_bits, exp_width, mant_width, bias) addsub_inst
                     (src_a, a_zero, a_inf, a_subN, a_Norm, a_QNan, a_SNan, 
                      src_b, b_zero, b_inf, b_subN, b_Norm, b_QNan, b_SNan,
                      unnorm_mant_add, unnorm_exp_add, direct_result_add, sign_add, arithmetic_add,
                      add_res_zero, add_res_inf, add_res_subN, add_res_Norm, add_res_QNan, add_res_SNan);

    muldiv_pre #(num_bits, exp_width, mant_width, bias) muldiv_pre_inst
                (src_a, a_zero, a_inf, a_subN, a_Norm, a_QNan, a_SNan,
                 src_b, b_zero, b_inf, b_subN, b_Norm, b_QNan, b_SNan,
                 mantA_mul, mantB_mul, expA_mul, expB_mul, arithmetic_mult, direct_result_mul, sign_mul,
                 mul_res_zero, mul_res_inf, mul_res_subN, mul_res_Norm, mul_res_QNan, mul_res_SNan);

    muldiv #(num_round_bits, exp_width, mant_width) muldiv_inst
            (mantA_mul, mantB_mul, expA_mul, expB_mul, clz_out, clz_shift, unnorm_mant_mul, unnorm_exp_mul);

    normaliser_muldiv #(num_round_bits, mant_width, exp_width, min_exp) normaliser_muldiv_inst
                       (unnorm_mant_mul, unnorm_exp_mul, unrounded_mant_mul, unrounded_exp_mul);



    clz #(num_round_bits, exp_width, mant_width) clz_inst(clz_in, clz_out);

    normaliser_add #(num_round_bits, mant_width, exp_width, min_exp) normaliser_add_inst (unnorm_mant_add, unnorm_exp_add, clz_out, 
                                                                      unrounded_mant_add, unrounded_exp_add);

    rng #(num_round_bits) rng_inst (clk, reset, rand_bits);
    round #(num_round_bits, num_bits, mant_width) round_inst (operation[0], round_in, rand_bits, round_out);


    logic signed [exp_width+1:0] res_exp;
   


    always_comb
    begin

        zero = 0;
        inf  = 0;
        subN = 0;
        Norm = 0;
        QNan = 0;
        SNan = 0;

        case(operation)
            ADD_RN,
            ADD_SR,
            SUB_RN,
            SUB_SR:
            begin
                if(arithmetic_add)
                begin 
                    clz_in   = unnorm_mant_add[mant_width + num_round_bits -1:0];
                    round_in = unrounded_mant_add[mant_width+num_round_bits-1:0];

                    res_exp  = round_out[mant_width] ? unrounded_exp_add + bias : unrounded_exp_add + bias + 1;

                    zero     = ((res_exp == 0) & (unrounded_mant_add == 0)) ? 1 : 0;
                    inf      = (res_exp == max_exp)                         ? 1 : 0;
                    subN     = (~zero & res_exp == 0)                       ? 1 : 0;
                    Norm     = (~inf & res_exp != 0)                        ? 1 : 0;
                    SNan     = 0;
                    QNan     = 0;

                    res_out  = {sign_add, res_exp[exp_width-1:0], round_out[mant_width-1:0]};
                end
                else
                begin
                    zero    = add_res_zero;
                    inf     = add_res_zero;
                    QNan    = add_res_QNan;
                    SNan    = add_res_SNan;

                    res_out = direct_result_add;
                end
            end
            DIV_RN,
            DIV_SR,
            MUL_RN,
            MUL_SR:
            begin
                clz_in = {mantA_mul, {num_round_bits{1'b0}}};

                if(arithmetic_mult)
                begin 
                    round_in = unrounded_mant_mul;
                    res_exp  = round_out[mant_width] ? unrounded_exp_mul + 1 + bias : unrounded_exp_mul + bias;

                    if(res_exp > max_exp+bias)
                    begin 
                        inf     = 1;
                        res_out = {sign_mul, {exp_width{1'b1}}, {mant_width{1'b0}}};
                    end
                    else if((res_exp == 0) & (round_out == 0))
                    begin 
                        zero    = 1;
                        res_out = {sign_mul, {exp_width{1'b0}}, {mant_width{1'b0}}}; 
                    end
                    else
                    begin 
                        Norm = res_exp >  0 ? 1 : 0;
                        subN = res_exp == 0 ? 1 : 0;
                
                        res_out = {sign_mul, res_exp[exp_width-1:0], round_out[mant_width-1:0]};
                    end
                end 
                else 
                begin
                    res_out = direct_result_mul;

                    zero = mul_res_zero;
                    inf  = mul_res_inf;
                    subN = mul_res_subN;
                    Norm = mul_res_Norm;
                    SNan = mul_res_SNan;
                    QNan = mul_res_QNan;
                end
            end 
        endcase
        
    end   
  

endmodule;

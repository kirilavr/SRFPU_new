`include "./rtl/hp_mul.sv"
`include "./rtl/hp_class"
`include "./rtl/hp_round"


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
module hp_top
(
    input logic[15:0] src_a,
    input logic[15:0] src_b,

    input logic[2:0] operation,
    input logic ops_ready,

    output logic[15:0] res_out,
    output logic zero, inf, subN, Norm, QNan, SNan

);

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
    wire a_zero;
    wire a_inf;
    wire a_subN; 
    wire a_Norm;
    wire a_QNan;
    wire a_SNan;

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

    /* variable output width from operational blocks: note that the maximum from MULDIV */
    reg[21:0] rounding_reg;
    reg[9:0]  rounded_result;
    reg[15:0] trunc_result;

    /*flags to show op block operation status*/
    reg mul_res_ready   = 0;
    reg round_res_ready = 0;

    /* Classifying simultaneously, this could be a potential point of improvement */
    hp_class classifier_1(src_a, a_zero, a_inf, a_subN, a_Norm, a_QNan, a_SNan);
    hp_class classifier_2(src_b, b_zero, b_inf, b_subN, b_Norm, b_QNan, b_SNan);

    hp_mul multiplier(src_a, a_zero, a_inf, a_subN, a_Norm, a_QNan, a_SNan, 
                      src_b, b_zero, b_inf, b_subN, b_Norm, b_QNan, b_SNan,
                      trunc_result, rounding_reg, mul_res_zero, mul_res_inf, mul_res_subN, mul_res_Norm, mul_res_QNan, mul_res_SNan);

    hp_round rounding(operation[0], rounding_reg, rounded_result);
    

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
            if(zero | inf | SNan | QNan)
            res_out[9:0] = rounded_result;
        end
        else
        begin
            res_out = trunc_result;
        end


        
    end      

endmodule;




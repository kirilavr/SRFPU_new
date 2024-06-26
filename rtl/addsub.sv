`include "./rtl/clz"

module addsub #(parameter num_round_bits, parameter num_bits, parameter exp_width, parameter mant_width, parameter signed bias)
(
    input logic[num_bits-1:0] a_src,
    
    input logic a_zero,
    input logic a_inf,
    input logic a_subN, 
    input logic a_Norm,
    input logic a_QNan,
    input logic a_SNan,

    input logic[num_bits-1:0] b_src,

    input logic b_zero,
    input logic b_inf,
    input logic b_subN, 
    input logic b_Norm,
    input logic b_QNan,
    input logic b_SNan,

    output logic[mant_width+num_round_bits+1:0] unnorm_mant,
    output logic[exp_width+1:0]                 unnorm_exp,
    output logic[num_bits-1:0]                  direct_result,
    output logic                                sign,
    output logic                                arithmetic,
    
    output logic zero, inf, subN, Norm, QNan, SNan,

    output logic [6:0] exp_test_a,
    output logic [6:0] exp_test_b
);

    logic signed [exp_width+1:0]                     res_exp;

    logic        [mant_width + num_round_bits:0]     big_mant;
    logic        [mant_width + num_round_bits:0]     little_mant;

    logic signed [exp_width+1:0]                     exp_a;
    logic signed [exp_width+1:0]                     exp_b;

    wire                                             diff_sign;
    
    assign diff_sign = a_src[num_bits-1] ^ b_src[num_bits-1];

    always_comb 
    begin
        exp_a = $signed({2'b00, a_src[num_bits-2:mant_width]}) - (a_subN ? (bias-1) : bias);
        exp_b = $signed({2'b00, b_src[num_bits-2:mant_width]}) - (b_subN ? (bias-1) : bias);

        exp_test_a = exp_a;
        exp_test_b = exp_b;

        zero       = 0;
        inf        = 0;
        subN       = 0;
        Norm       = 0;
        QNan       = 0;
        SNan       = 0;
        res_exp    = 0;
        res_exp    = 0;
        sign       = 0;
        arithmetic = 0;
        
        /* Special result classification */
        if(a_SNan | b_SNan)
        begin
            SNan   = 1;
            direct_result = (a_SNan == 1) ? a_src : b_src;
        end

        else if(a_QNan | b_QNan)
        begin
            QNan    = 1;
            direct_result  = (a_QNan == 1) ? a_src : b_src;
        end

        else if(a_inf & b_inf)
        begin
            if(diff_sign)
            begin
                QNan   = 1;
                direct_result = 16'b0111111000000000;
            end
            else
            begin 
                inf = 1;
                direct_result = a_src;
            end
        end

        else if(a_zero & b_zero)
        begin
            zero   = 1;
            direct_result = {(~diff_sign)&a_src[num_bits-1], {exp_width{1'b0}}, {mant_width{1'b0}}};
        end 

        else if(a_inf | b_inf)
        begin
            direct_result = a_inf ? a_src : b_src;
            inf = 1;
        end
        
        else if(a_zero | b_zero)
        begin
            direct_result = a_zero ? b_src : a_src;

            subN   = a_zero ? b_subN : a_subN;
            Norm   = a_zero ? b_Norm : a_Norm;
        end

        /* Aligning mantissas */
        else 
        begin
            if(exp_a < exp_b)
            begin
                big_mant           = {1'b1, b_src[mant_width-1:0], {num_round_bits{1'b0}}};
                little_mant        = {a_Norm, a_src[mant_width-1:0], {num_round_bits{1'b0}}} >> (exp_b - exp_a);
                res_exp            = exp_b;

                sign               = b_src[num_bits-1];
                arithmetic         = 1;
            end

            else if(exp_b < exp_a)
            begin
                big_mant           = {1'b1, a_src[mant_width-1:0], {num_round_bits{1'b0}}};
                little_mant        = {b_Norm, b_src[mant_width-1:0], {num_round_bits{1'b0}}} >> (exp_a - exp_b);
                res_exp            = exp_a;

                sign               = a_src[num_bits-1];
                arithmetic         = 1;
            end 

            else
            begin
                arithmetic = 1;

                if({a_Norm, a_src[mant_width-1:0]}<{b_Norm, b_src[mant_width-1:0]})
                begin
                    big_mant    = {b_Norm, b_src[mant_width-1:0], {num_round_bits{1'b0}}};
                    little_mant = {a_Norm, a_src[mant_width-1:0], {num_round_bits{1'b0}}};
                    sign        = b_src[num_bits-1];
                end
                else
                begin
                    big_mant    = {a_Norm, a_src[mant_width-1:0], {num_round_bits{1'b0}}};
                    little_mant = {b_Norm, b_src[mant_width-1:0], {num_round_bits{1'b0}}};
                    sign        = a_src[num_bits-1];
                end

                res_exp         = exp_a;
            end


            if(a_src[num_bits-1] ^ b_src[num_bits-1])
            begin
                unnorm_mant = big_mant - little_mant;
                unnorm_exp  = res_exp;
            end
            else 
            begin 
                unnorm_mant = big_mant + little_mant;
                unnorm_exp  = res_exp;
            end
        end
    end


endmodule;
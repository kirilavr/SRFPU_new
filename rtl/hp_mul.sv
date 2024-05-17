`include "./rtl/clz"


module hp_mul #(parameter num_round_bits)
(

    input logic[15:0] a_src,
    
    input logic a_zero,
    input logic a_inf,
    input logic a_subN, 
    input logic a_Norm,
    input logic a_QNan,
    input logic a_SNan,

    input logic[15:0] b_src,

    input logic b_zero,
    input logic b_inf,
    input logic b_subN, 
    input logic b_Norm,
    input logic b_QNan,
    input logic b_SNan,

    output logic[15:0] result,
    output logic[9+num_round_bits:0] round_mant,
    output logic zero, inf, subN, Norm, QNan, SNan,

    /* Test outputs */
    output logic[5:0] res_exp_t,
    output logic[21:0] res_mant_t,
    output logic[7:0] shift

);

    logic signed [5:0]  a_exp, b_exp;
    logic        [10:0] a_mant, b_mant;
    logic signed [5:0]  res_exp;
    logic        [21:0] res_mant;

    logic        [9 + num_round_bits:0]  clz_rin;
    logic        [7:0]  clz_rout;




    /*clz_rin is a register for the count leading zeros module which is combinatorial and is used to deal with subNs.*/
    clz #(num_round_bits) clz(clz_rin, clz_rout);

    assign a_exp  = a_src[14:10] - 15;
    assign b_exp  = b_src[14:10] - 15;

    /* output testing */
    assign res_exp_t  = res_exp;
    assign res_mant_t = res_mant;
    assign shift = clz_rout;
    
    always_comb 
    begin

        result = 0;

        zero = 0;
        inf  = 0;
        subN = 0;
        Norm = 0;
        QNan = 0;
        SNan = 0;

        
        /* combinatorial evaluation of special results and Normisation */
        if(a_SNan | b_SNan)
        begin
            SNan   = 1;
            result = (a_SNan == 1) ? a_src : b_src;
        end

        else if(a_QNan | b_QNan)
        begin
            QNan    = 1;
            result  = (a_QNan == 1) ? a_src : b_src;
        end

        /* dealing with infinity */
        else if(a_inf | b_inf)
        begin
            if(a_zero | b_zero)
            begin
                QNan   = 1;
                result = 16'b0111111000000000;    
            end
            else
            begin
                inf    = 1;
                result = {a_src[15]^b_src[15], {5{1'b1}}, {10{1'b0}}};
            end

        end

        /* dealing with when the result is zero */
        else if(a_zero | b_zero | (a_subN & b_subN))
        begin
            zero   = 1;
            result = {a_src[15]^b_src[15], {15{1'b0}}};
        end 
    
        else if(a_subN)
        begin
            /* clz */
            clz_rin =  {a_src[9:0], {num_round_bits{1'b0}}};
            a_mant  =  {1'b1, a_src[9:0] << (clz_rout + 1)};
            a_exp   =  a_src[14:10] - clz_rout[5:0] - 15;

            b_exp   = b_src[14:10] - 15;
            b_mant  = {1'b1, b_src[9:0]};
        end
        
        else if(b_subN)
        begin
            /* clz */
            clz_rin =  {b_src[9:0], {num_round_bits{1'b0}}};
            b_mant  =  {1'b1, b_src[9:0] << (clz_rout + 1)};
            b_exp   =  b_src[14:10] - clz_rout[5:0] - 15;

            a_exp   = a_src[14:10] - 15;
            a_mant  = {1'b1, a_src[9:0]};
        end

        else 
        begin 

            a_exp   = a_src[14:10] - 15;
            a_mant  = {1'b1, a_src[9:0]};

            b_exp   = b_src[14:10] - 15;
            b_mant  = {1'b1, b_src[9:0]};
        end 


        if((a_subN & b_Norm) | (a_Norm & b_subN) | (a_Norm & b_Norm))
        begin 

            res_mant = a_mant * b_mant;
            res_exp  = a_exp  + b_exp;

            /* Normisation */
            if(res_mant[21])
            begin 
                res_mant = res_mant >> 1;
                res_exp  = res_exp + 1;
            end

            if(res_exp < -24)
            begin 
                result = {a_src[15]^b_src[15], {5{1'b0}}, {10{1'b0}}};
                zero   = 1;
            end
            else if(res_exp > 15)
            begin
                result = {a_src[15] ^ b_src[15], {5{1'b1}}, {10{1'b0}}};
                inf    = 1;
            end 
            else if(res_exp < -14)
            begin
                res_mant   = res_mant >> (-14 - res_exp);
                round_mant = res_mant[21:12-num_round_bits];
                result     = {a_src[15] ^ b_src[15], {5{1'b0}}, res_mant[19:10]};
                subN       = 1;
            end 
            else
            begin
                res_exp    = res_exp + 15;
                result     = {a_src[15] ^ b_src[15], res_exp[4:0], res_mant[19:10]};
                Norm       = 1;
                round_mant = res_mant[19:10-num_round_bits];
            end
        end
    end
    
    

endmodule;



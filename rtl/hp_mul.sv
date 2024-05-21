`include "./rtl/clz"


module hp_mul #(parameter num_round_bits, parameter num_bits, parameter exp_width, parameter mant_width)
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

    output logic[num_bits-1:0] result,
    output logic[mant_width+num_round_bits-1:0] round_mant,
    output logic zero, inf, subN, Norm, QNan, SNan,

    /* Test outputs */
    output logic[exp_width+1:0]        res_exp_t,
    output logic[(mant_width*2) + 1:0] res_mant_t,
    output logic[7:0]                  shift

);
    /* defining parameters as defined by the IEEE FP16 and FP32 standards
     * min exponents are -14 and -126 for FP16 and FP32
     * min exponents for normalised subnormals are -24 and -149 
     */
    localparam signed [exp_width+1:0]   min_exp      = (num_bits==16) ? {{(exp_width-5){1'b1}}, 7'b1110010}: 
                                                                        {3'b111, {(exp_width-5){1'b0}}, 4'b0010};

    localparam signed [exp_width+1:0]     min_exp_subN = (num_bits==16) ? {{(exp_width-5){1'b0}}, 7'b1101000}:
                                                                          {{(exp_width-5)/3{3'b110}}, 7'b1101011};
    
    /* Max exp for FP16 = 15 and for FP32 = 127, the biases are equivalent to the maximums*/
    localparam signed [exp_width+1:0]  max_exp = (num_bits==16) ?  {{(exp_width-5){1'b0}}, 7'b0001111}: 
                                                                   {7'b0001111, {(exp_width-5){1'b1}}};

    localparam signed [exp_width+1:0]  bias    = (num_bits==16) ?  {{(exp_width-5){1'b0}}, 7'd15}: 
                                                                   {7'b0001111, {(exp_width-5){1'b1}}};


    logic signed [exp_width+1:0]      a_exp, b_exp;
    logic        [mant_width:0]       a_mant, b_mant;
    logic signed [exp_width+1:0]      res_exp;
    logic        [(mant_width*2)+1:0] res_mant;

    logic        [mant_width + num_round_bits - 1:0]  clz_rin;
    logic        [7:0]  clz_rout;




    /*clz_rin is a register for the count leading zeros module which is combinatorial and is used to deal with subNs.*/
    clz #(num_round_bits) clz(clz_rin, clz_rout);

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
                result = {a_src[num_bits-1]^b_src[num_bits-1], {exp_width{1'b1}}, {mant_width{1'b0}}};
            end

        end

        /* dealing with when the result is zero */
        else if(a_zero | b_zero | (a_subN & b_subN))
        begin
            zero   = 1;
            result = {a_src[num_bits-1]^b_src[num_bits-1], {(num_bits-1){1'b0}}};
        end 
    
        else if(a_subN)
        begin
            /* clz */
            clz_rin =  {a_src[mant_width-1:0], {num_round_bits{1'b0}}};
            a_mant  =  {1'b1, a_src[mant_width-1:0] << (clz_rout + 1)};
            a_exp   =  -$signed(clz_rout[exp_width+1:0]) - bias;

            b_exp   =  {{2{1'b0}}, b_src[num_bits-2:num_bits-exp_width-1]} - bias;
            b_mant  =  {1'b1, b_src[mant_width-1:0]};
        end
        
        else if(b_subN)
        begin
            /* clz */
            clz_rin =  {b_src[mant_width-1:0], {num_round_bits{1'b0}}};
            b_mant  =  {1'b1, b_src[mant_width-1:0] << (clz_rout + 1)};
            b_exp   =  -$signed(clz_rout[exp_width+1:0]) - bias;

            a_exp   =  {{2{1'b0}}, a_src[num_bits-2:num_bits-exp_width-1]} - bias;
            a_mant  =  {1'b1, a_src[mant_width-1:0]};
        end

        else 
        begin 

            a_exp   = {2'b00, a_src[num_bits-2:num_bits-exp_width-1]} - bias;
            a_mant  = {1'b1, a_src[mant_width-1:0]};

            b_exp   = {2'b00, b_src[num_bits-2:num_bits-exp_width-1]} - bias;
            b_mant  = {1'b1, b_src[mant_width-1:0]};
        end 


        if((a_subN & b_Norm) | (a_Norm & b_subN) | (a_Norm & b_Norm))
        begin 

            res_mant = a_mant * b_mant;
            res_exp  = a_exp  + b_exp;

            /* Normisation */
            if(res_mant[(mant_width*2)+1])
            begin 
                res_mant = res_mant >> 1;
                res_exp  = res_exp + 1;
            end

            if(res_exp < min_exp_subN)
            begin 
                result = {a_src[num_bits-1]^b_src[num_bits-1], {exp_width{1'b0}}, {mant_width{1'b0}}};
                zero   = 1;
            end
            else if(res_exp > max_exp)
            begin
                result = {a_src[num_bits-1] ^ b_src[num_bits-1], {exp_width{1'b1}}, {mant_width{1'b0}}};
                inf    = 1;
            end 
            else if(res_exp < min_exp)
            begin
                res_mant   = res_mant >> (min_exp - res_exp);
                round_mant = res_mant[(mant_width*2)-1:mant_width-num_round_bits];
                result     = {a_src[num_bits-1] ^ b_src[num_bits-1], {exp_width{1'b0}}, res_mant[(mant_width*2)-1:mant_width]};
                subN       = 1;
            end 
            else
            begin
                res_exp    = res_exp + bias;
                result     = {a_src[num_bits-1] ^ b_src[num_bits-1], res_exp[exp_width-1:0], res_mant[(mant_width*2)-1:mant_width]};
                Norm       = 1;
                round_mant = res_mant[(mant_width*2)-1:mant_width-num_round_bits];
            end
        end
    end
    
    

endmodule;



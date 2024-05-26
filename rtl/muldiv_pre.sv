module muldiv_pre #(parameter num_bits, parameter exp_width, parameter mant_width, parameter bias)
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

    output logic [mant_width-1:0] mantA,
    output logic [mant_width-1:0] mantB,

    output logic signed [exp_width+1:0] exp_a,
    output logic signed [exp_width+1:0] exp_b,


    output logic                arithmetic,
    output logic [num_bits-1:0] direct_result,
    output logic                sign,

    output logic zero, inf, subN, Norm, QNan, SNan
);

    always_comb
    begin 
        arithmetic = 0;

        zero = 0;
        inf  = 0;
        subN = 0;
        Norm = 0;
        QNan = 0;
        SNan = 0;

        sign = a_src[num_bits-1] ^ b_src[num_bits-1];

        if(a_SNan | b_SNan)
        begin
            SNan          = 1;
            direct_result = (a_SNan == 1) ? a_src : b_src;
        end

        else if(a_QNan | b_QNan)
        begin
            QNan          = 1;
            direct_result = (a_QNan == 1) ? a_src : b_src;
        end

        /* dealing with infinity */
        else if(a_inf | b_inf)
        begin
            if(a_zero | b_zero)
            begin
                QNan          = 1;
                direct_result = 16'b0111111000000000;    
            end
            else
            begin
                inf           = 1;
                direct_result = {a_src[num_bits-1]^b_src[num_bits-1], {exp_width{1'b1}}, {mant_width{1'b0}}};
            end

        end

        /* dealing with when the result is zero */
        else if(a_zero | b_zero | (a_subN & b_subN))
        begin
            zero          = 1;
            direct_result = {a_src[num_bits-1]^b_src[num_bits-1], {(num_bits-1){1'b0}}};
        end 
        
        else if(b_subN)
        begin
            arithmetic = 1;

            mantA      = b_src[mant_width-1:0];
            mantB      = a_src[mant_width-1:0];

            exp_b      =  {{2{1'b0}}, b_src[num_bits-2:num_bits-exp_width-1]} - bias + 1;
            exp_a      =  {{2{1'b0}}, a_src[num_bits-2:num_bits-exp_width-1]} - bias;
        end

        
        else
        begin
            arithmetic = 1;

            mantA      = a_src[mant_width-1:0];
            mantB      = b_src[mant_width-1:0];

            exp_a      =  {{2{1'b0}}, a_src[num_bits-2:num_bits-exp_width-1]} - bias + (a_subN ? 1 : 0);
            exp_b      =  {{2{1'b0}}, b_src[num_bits-2:num_bits-exp_width-1]} - bias;
        end
    end
endmodule;
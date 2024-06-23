//`timescale 1ns / 1ps

module addmul_pre #(parameter round_bits_surp, parameter num_bits, parameter exp_width, parameter mant_width)
(
    input logic[num_bits-1:0] rs1,
    
    input logic zero1,
    input logic inf1,
    input logic subn1, 
    input logic norm1,
    input logic qnan1,
    input logic snan1,

    input logic[num_bits-1:0] rs2,

    input logic zero2,
    input logic inf2,
    input logic subn2, 
    input logic norm2,
    input logic qnan2,
    input logic snan2,

    input logic mul,
    input logic rs2_big,
    input logic [exp_width+1:0] exp_diff,

    input logic [exp_width+1:0] lz,

    output logic [mant_width:0] big_mant,
    output logic [2*mant_width+1:0] little_mant,

    output logic[exp_width+1:0] unnorm_exp,
    output logic[num_bits-1:0]  direct_result,
    output logic                sign,
    output logic                use_dir_res,
    
    output logic zero, subn, inf, norm, qnan, snan
);

    logic signed [exp_width+1:0]                     res_exp;

    logic signed [exp_width+1:0]                     exp1;
    logic signed [exp_width+1:0]                     exp2;

    wire                                             diff_sign;
    
    assign diff_sign = rs1[num_bits-1] ^ rs2[num_bits-1];

    always_comb 
    begin
        exp1 = {2'b00, rs1[num_bits-2:mant_width]};
        exp2 = {2'b00, rs2[num_bits-2:mant_width]};

        use_dir_res = 1;

        
        /* Special result classification */
        if(snan1 | snan2)
        begin
            qnan          = 1;
            direct_result = {12'h7fc, {num_bits-12{1'b0}}};
        end

        else if(qnan1 | qnan2)
        begin
            qnan           = 1;
            direct_result  = {12'h7fc, {num_bits-12{1'b0}}};
        end

        else if(inf1 & inf2)
        begin 
            if(mul)
            begin 
                direct_result = {diff_sign, {exp_width{1'b1}}, {mant_width{1'b0}}};
            end 
            else
            begin 
                direct_result = diff_sign ? {12'h7fc, {num_bits-12{1'b0}}} : {rs1[num_bits-1], {exp_width{1'b1}}, {mant_width{1'b0}}};
            end
        end 

        else if(zero1 & zero2) 
        begin 
            zero = 1;
            direct_result = {((~mul & rs1[num_bits-1] & rs2[num_bits-1]) | (mul &(rs1[num_bits-1] ^ rs2[num_bits-1]))), {num_bits-1{1'b0}}};
        end

        else if((zero1 & inf2) | (zero2 & inf1))
        begin 
            zero = mul ? 0 : 1;
            qnan = mul ? 1 : 0;
            direct_result = mul ? {12'h7fc, {num_bits-12{1'b0}}} :  {inf1?rs1[num_bits-1]:rs2[num_bits-1], {exp_width{1'b1}}, {mant_width{1'b0}}};
        end 


        else if(inf1 | inf2)
        begin 
            if(mul)
            begin 
                direct_result = diff_sign ? {1'b1, {exp_width{1'b1}}, {mant_width{1'b0}}} : {1'b0, {exp_width{1'b1}}, {mant_width{1'b0}}} ;
            end 
            else 
            begin 
                direct_result = {inf1 ? rs1[num_bits-1] : rs2[num_bits-1], {exp_width{1'b1}}, {mant_width{1'b0}}};
            end 
        end 

        else if(zero1 | zero2)
        begin 
            if(mul)
            begin 
                direct_result = zero1 ? rs1 : rs2;
                zero = 1;
            end 
            else
            begin 
                if(zero1)
                begin 
                    direct_result = rs2;

                    zero = zero2;
                    inf = inf2;
                    subn = subn2;
                    norm = norm2;
                end
                else 
                begin 
                    direct_result = rs1;

                    zero = zero1;
                    inf = inf1;
                    subn = subn1;
                    norm = norm1;
                end
            end 
        end

        /* Aligning mantissas */
        else if(~mul)
        begin
            if(rs2_big)
            begin
                big_mant           = {norm2, rs2[mant_width-1:0]};
                little_mant        = {norm1, rs1[mant_width-1:0], {mant_width+round_bits_surp+1{1'b0}}}>> (subn1&~subn2 ? exp_diff - 1 : exp_diff);
                unnorm_exp         = exp2;

                sign               = rs2[num_bits-1];
                use_dir_res        = 0;
            end

            else
            begin
                big_mant           = {norm1, rs1[mant_width-1:0]};
                little_mant        = {norm2, rs2[mant_width-1:0], {mant_width+round_bits_surp+1{1'b0}}}>> (subn2&~subn1 ? exp_diff -1 : exp_diff);
                unnorm_exp         = exp1;

                sign               = rs1[num_bits-1];
                use_dir_res        = 0;
            end 

            subn = subn1 & subn2;
            norm = norm1 | norm2;
        end

        else
        begin 
            use_dir_res = 0;

            if(subn1)
            begin 
                big_mant = {1'b1, rs2[mant_width-1:0]};
                little_mant = {{1'b0, rs1[mant_width-1:0]}<<lz, {mant_width+1+round_bits_surp{1'b0}}};
            end 
            else if(subn2)
            begin 
                big_mant = {1'b1, rs1[mant_width-1:0]};
                little_mant = {{1'b0, rs2[mant_width-1:0]}<<lz, {mant_width+1+round_bits_surp{1'b0}}};
            end 
            else 
            begin 
                big_mant = {1'b1, rs1[mant_width-1:0]};
                little_mant = {1'b1, rs2[mant_width-1:0], {mant_width+1+round_bits_surp{1'b0}}};
            end

            sign = rs1[num_bits-1]^rs2[num_bits-1];


        end

    end


endmodule;


module normaliser_muldiv #(parameter num_round_bits, parameter mant_width, parameter exp_width, parameter signed min_exp)
(
    input logic       [mant_width*2+1:0] unnorm_mant,
    input logic signed[exp_width+1:0]    unnorm_exp,

    output logic       [mant_width+num_round_bits-1:0] unrounded_mant, 
    output logic signed[exp_width+1:0]                 unrounded_exp
);

    logic        [mant_width*2+1:0] mant_working_reg;
    logic signed [exp_width+1:0]    exp_working_reg;

    always_comb 
    begin

        mant_working_reg = unnorm_mant>>(unnorm_mant[mant_width*2+1] ? 1 : 0);
        exp_working_reg  = unnorm_exp + (unnorm_mant[mant_width*2+1] ? 1 : 0);

        if(exp_working_reg < min_exp)
        begin 
            unrounded_mant = mant_working_reg[mant_width*2:mant_width-num_round_bits+1]>>(min_exp - exp_working_reg - 1);
            unrounded_exp  = min_exp - 1;
        end

        else 
        begin 
            unrounded_mant = mant_working_reg[mant_width*2-1:mant_width-num_round_bits];
            unrounded_exp  = exp_working_reg;
        end

    end 

endmodule;
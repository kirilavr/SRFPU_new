
module muldiv #(parameter num_round_bits, parameter exp_width, parameter mant_width)
(
    input logic [mant_width-1:0] mantA,
    input logic [mant_width-1:0] mantB,

    input logic signed [exp_width+1:0] expA,
    input logic signed [exp_width+1:0] expB,

    input logic signed [exp_width+1:0] lz,

    output logic       [mant_width*2 + 1:0]   unnorm_mant,
    output logic signed[exp_width+1:0]        unnorm_exp
);

    logic [mant_width:0] work_mant_a;
    logic [mant_width:0] work_mant_b;

    always_comb 
    begin 

        work_mant_a = {1'b1,mantA<<lz};
        work_mant_b = {1'b1,mantB};
        
        unnorm_exp  = expA + expB;
        unnorm_mant = work_mant_a*work_mant_b;

    end 
    
endmodule;



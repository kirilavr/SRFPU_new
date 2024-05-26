
module muldiv #(parameter num_round_bits, parameter exp_width, parameter mant_width)
(
    input logic        [mant_width-1:0]     mantA,
    input logic        [mant_width-1:0]     mantB,

    input logic signed [exp_width+1:0]      expA,
    input logic signed [exp_width+1:0]      expB,

    input logic signed [exp_width+1:0]      lz,
    input logic                             clz_shift,

    output logic       [mant_width*2 + 1:0] unnorm_mant,
    output logic signed[exp_width+1:0]      unnorm_exp
);

    logic [mant_width:0] work_mant_a;
    logic [mant_width:0] work_mant_b;

    always_comb 
    begin 
        if(clz_shift)
        begin
            work_mant_a = {mantA<<(lz), 1'b0};
        end 
        else 
        begin 
            work_mant_a = {1'b1, mantA};
        end

        work_mant_b = {1'b1,mantB};
        
        if(clz_shift)
        begin
            unnorm_exp = expA + expB - (lz+1);
        end
        else 
        begin
            unnorm_exp = expA + expB; 
        end

        unnorm_mant = work_mant_a*work_mant_b;

    end 
    
endmodule;



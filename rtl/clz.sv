`ifndef CLZ_F
`define CLZ_F

module clz #(parameter num_round_bits, parameter exp_width, parameter mant_width)
(
    input  logic[mant_width + num_round_bits:0] in,
    output logic[exp_width+1:0] out
);

    localparam num_log_check = 
        num_round_bits+mant_width >= 32 ? 6:
        num_round_bits+mant_width >= 16 ? 5:
        num_round_bits+mant_width >= 8  ? 4: 3;

    localparam reg_size = 
        num_round_bits+mant_width >= 32 ? 64:
        num_round_bits+mant_width >= 16 ? 32:
        num_round_bits+mant_width >= 8  ? 16: 8;

    logic [exp_width+1:0] cur_check_width; 
    logic [reg_size-1:0] rin;
    logic [exp_width+1:0] out_reg;


    always_comb 
    begin 

        cur_check_width = reg_size>>1;
        out_reg = 0;

        rin = {in, {reg_size - num_round_bits - mant_width - 1{1'b0}}};

        for(logic[2:0] i = 0; i < num_log_check; i++)
        begin
            if(rin[reg_size-1 -: (reg_size>>1)] == 0)
            begin 
                out_reg = out_reg + cur_check_width;
                rin = rin << (cur_check_width>>1);
            end 
            else 
            begin
                rin = rin >> (cur_check_width>>1);  
            end

            cur_check_width = cur_check_width>>1;
        end 

        out = out_reg;


    end 
endmodule;


`endif


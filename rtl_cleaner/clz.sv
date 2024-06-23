`ifndef CLZ_F
`define CLZ_F

module clz #(parameter round_bits_surp, parameter exp_width, parameter mant_width)
(
    input  logic[2*mant_width+2+round_bits_surp:0] in,
    output logic[exp_width+1:0] lz
);

    localparam num_log_check = 
        2*mant_width+2+round_bits_surp >= 32 ? 6:
        2*mant_width+2+round_bits_surp >= 16 ? 5:
        2*mant_width+2+round_bits_surp >= 8  ? 4: 3;

    localparam reg_size = 
        2*mant_width+2+round_bits_surp >= 32 ? 64:
        2*mant_width+2+round_bits_surp >= 16 ? 32:
        2*mant_width+2+round_bits_surp >= 8  ? 16: 8;

    logic [exp_width+1:0] cur_check_width; 
    logic [reg_size-1:0] rin;
    logic [exp_width+1:0] out_reg;


    always_comb 
    begin 

        cur_check_width = reg_size>>1;
        out_reg = 0;

        rin = {in, {reg_size - 2*mant_width-3-round_bits_surp{1'b0}}};

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

        lz = out_reg;


    end 
endmodule;


`endif


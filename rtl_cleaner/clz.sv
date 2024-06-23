`ifndef CLZ_F
`define CLZ_F

module clz #(parameter clz_width, parameter exp_width)
(
    input  logic[clz_width-1:0] in,
    output logic[exp_width+1:0] lz
);

    localparam num_log_check = 
        clz_width >= 32 ? 6:
        clz_width >= 16 ? 5:
        clz_width >= 8  ? 4: 3;

    localparam reg_size = 
        clz_width >= 32 ? 64:
        clz_width >= 16 ? 32:
        clz_width >= 8  ? 16: 8;

    logic [exp_width+1:0] cur_check_width; 
    logic [reg_size-1:0] rin;
    logic [exp_width+1:0] out_reg;


    always_comb 
    begin 

        cur_check_width = reg_size>>1;
        out_reg = 0;

        rin = {in, {reg_size - clz_width{1'b0}}};

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


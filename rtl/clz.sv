module clz
(
    input  logic[9:0] in,
    output logic[3:0] out
);

    reg [9:0] rin;

    always_comb 
    begin 
        out = 0;
        rin = in;

        if(in[9:6] == 0) begin out = out + 4; rin = rin << 4; end
        if(in[9:8] == 0) begin out = out + 2; rin = rin << 2; end  
        if(in[9]   == 0) begin out = out + 1;                 end 
        
        out = out + {{3{1'b0}}, ~rin[8]} + {{3{1'b0}}, ~(rin[8]&rin[9])};
    end 

endmodule;






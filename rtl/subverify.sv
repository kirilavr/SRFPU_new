`include "./rtl/clz.sv"

module subverify
(
    input logic[35:0] in,
    output logic[9:0] out
);


    clz #(12, 8, 23) clz_inst(.in(in), .out(out));



endmodule;
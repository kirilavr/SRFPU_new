module hp_round
(
    input logic       mode,
    input logic[21:0] mantissa,

    output logic[9:0] rounded
);

    assign rounded = mantissa[20:11];

endmodule;
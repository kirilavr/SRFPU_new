module hp_class
(

    input logic[15:0] f,

    output logic zero,
    output logic inf,
    output logic subN,
    output logic Norm,
    output logic QNan,
    output logic SNan

);

    logic expOnes;
    logic expZeroes;
    logic sigZeroes;

    assign expOnes   = &f[14:10];
    assign expZeroes = ~|f[14:10];
    assign sigZeroes = ~|f[9:0];

    assign SNan      = expOnes   & ~f[9] & ~sigZeroes;
    assign QNan      = expOnes   &  f[9];
    assign inf       = expOnes   & sigZeroes;
    assign zero      = expZeroes & sigZeroes;
    assign subN      = expZeroes & ~sigZeroes;
    assign Norm      = ~expOnes  & ~expZeroes;


endmodule
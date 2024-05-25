module classifier #(parameter num_bits, parameter exp_width, parameter mant_width)
(

    input logic[num_bits-1:0] f,

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

    assign expOnes   = &f[num_bits-2:num_bits-exp_width-1];
    assign expZeroes = ~|f[num_bits-2:num_bits-exp_width-1];
    assign sigZeroes = ~|f[9:0];

    assign SNan      = expOnes   & ~f[mant_width-1] & ~sigZeroes;
    assign QNan      = expOnes   &  f[mant_width-1];
    assign inf       = expOnes   & sigZeroes;
    assign zero      = expZeroes & sigZeroes;
    assign subN      = expZeroes & ~sigZeroes;
    assign Norm      = ~expOnes  & ~expZeroes;


endmodule;
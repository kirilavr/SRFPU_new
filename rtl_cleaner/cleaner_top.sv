`include "./rtl_cleaner/SRFPU.sv"
`define debug_mode 1

module cleaner_top #(parameter mant_width = 23, parameter num_round_bits = 18, parameter num_bits = 32, parameter exp_width = 8
)
(
    input logic clk,
    input logic resetn,

    // PCPI interface 
    input logic               pcpi_valid,
	input logic [31:0]        pcpi_insn,
	input logic [31:0]        pcpi_rs1,
	input logic [31:0]        pcpi_rs2,

	output logic              pcpi_wr,
    output logic[31:0]        pcpi_rd,
	output logic              pcpi_wait,
	output logic              pcpi_ready,

    //mem interface
    output logic              mem_valid,
	input logic               mem_ready,
	input logic [31:0]        mem_rdata,

	output logic [31:0]       mem_addr,
	output logic [31:0]       mem_wdata,
	output logic [ 3:0]       mem_wstrb,

	//test_interface
	output logic [3:0] 		  state_test

	`ifdef debug_mode
	,
	//testing outputs
	output logic[adder_size-1:0]	test_mantissa_diff,
	output logic[mant_width:0]	test_big_mant,
	output logic[2*mant_width+1+round_bits_surp:0]	test_little_mant,
	output logic[exp_width+1:0]	test_res_exp,
	output logic	test_use_dir_res,
	output logic[num_bits-1:0]	test_direct_result,

	output logic	test_sign,
	output logic	test_zero,
	output logic	test_inf,
	output logic	test_subn,
	output logic	test_norm,
	output logic	test_qnan,
	output logic	test_snan,

	output logic signed [exp_width+1:0]	test_exp_diff,

	output logic	test_zero1,
	output logic	test_inf1,
	output logic	test_subn1,
	output logic	test_norm1,
	output logic	test_snan1,
	output logic	test_qnan1,
	output logic	test_zero2,
	output logic	test_inf2,
	output logic	test_subn2,
	output logic	test_norm2,
	output logic	test_snan2,
	output logic	test_qnan2,


	output logic[adder_size-1:0] adder_res_test,

	
	output logic [2*mant_width+2+round_bits_surp:0] test_unnorm_mant,
	output logic [exp_width+1:0] test_unnorm_exp,
	output logic [round_bits_surp+2*mant_width+2:0] test_norm_mant,
	output logic [exp_width+1:0] test_exp_change,
	output logic [mant_width+num_round_bits+1:0] test_norm_mant_buffer,
    output logic [num_round_bits+mant_width+1:0] norm_mant_latched_test,
    output logic [adder_size-1:0] test_addop1,
    output logic [adder_size-1:0] test_addop2,

    output logic[exp_width+1:0] shift_test,
    output logic[exp_width+1:0] unround_exp_test,
    output logic[mant_width*2+1:0] multiplicand_test,
    output logic[5:0] mul_counter_test

	`endif
    ,
    input logic[31:0] op1,
    input logic[31:0] op2,
    output logic[num_bits-1:0] result,
    output logic[num_bits-1:0] frs1_test,
    output logic[num_bits-1:0] frs2_test,

    output logic[31:0] op1_test_fpu,
    output logic[31:0] op2_test_fpu,
    output logic[num_bits-1:0] rfrd_1_test,
    output logic[num_bits-1:0] rfrd_2_test,
    output logic[num_bits-1:0] rfwd,
    output logic[num_round_bits-1:0] rand_test
);

    localparam round_bits_surp = num_round_bits>mant_width+1?mant_width+1-num_round_bits:0;
    localparam adder_size = 2*mant_width+3+round_bits_surp > 32 ? 2*mant_width+3+round_bits_surp : 31;
    
    


    SRFPU #(.num_bits(num_bits),
            .num_round_bits(num_round_bits)
    )SRFPU_inst(
            .clk(clk),
            .resetn(resetn),
            .pcpi_valid(pcpi_valid),
	        .pcpi_insn(pcpi_insn),
	        .pcpi_rs1(pcpi_rs1),
	        .pcpi_rs2(pcpi_rs2),

	        .pcpi_wr(pcpi_wr),
            .pcpi_rd(pcpi_rd),
	        .pcpi_wait(pcpi_wait),
	        .pcpi_ready(pcpi_ready),

    //mem interface
            .mem_valid(mem_valid),
	        .mem_ready(mem_ready),
	        .mem_rdata(mem_rdata),
	        .mem_addr(mem_addr),
	        .mem_wdata(mem_wdata),
	        .mem_wstrb(mem_wstrb),
            
    //tests
            .state_test(state_test)

            `ifdef debug_mode
            ,
            .test_mantissa_diff(test_mantissa_diff),
            .test_big_mant(test_big_mant),
            .test_little_mant(test_little_mant),
            .test_res_exp(test_res_exp),
            .test_use_dir_res(test_use_dir_res),
            .test_direct_result(test_direct_result),
            .test_sign(test_sign),
            .test_zero(test_zero),
            .test_inf(test_inf),
            .test_subn(test_subn),
            .test_norm(test_norm),
            .test_qnan(test_qnan),
            .test_snan(test_snan),
            .test_exp_diff(test_exp_diff),
            .test_zero1(test_zero1),
            .test_inf1(test_inf1),
            .test_subn1(test_subn1),
            .test_norm1(test_norm1),
            .test_snan1(test_snan1),
            .test_qnan1(test_qnan1),
            .test_zero2(test_zero2),
            .test_inf2(test_inf2),
            .test_subn2(test_subn2),
            .test_norm2(test_norm2),
            .test_snan2(test_snan2),
            .test_qnan2(test_qnan2),
            .adder_res_test(adder_res_test),
            .test_unnorm_mant(test_unnorm_mant),
            .test_unnorm_exp(test_unnorm_exp),
            .test_norm_mant(test_norm_mant),
            .test_exp_change(test_exp_change),
            .test_addop1(test_addop1),
            .test_addop2(test_addop2),
            .shift_test(shift_test),
            .unround_exp_test(unround_exp_test),
            .mul_counter_test(mul_counter_test),
            .multiplicand_test(multiplicand_test),
            .op1(op1),
            .op2(op2),
            .res(result),
            .frs1_test(frs1_test),
            .frs2_test(frs2_test),
            .rfrd_1_test(rfrd_1_test),
            .rfrd_2_test(rfrd_2_test),
            .rfwd_test(rfwd),
            .rand_test(rand_test)
            `endif
    );

endmodule;
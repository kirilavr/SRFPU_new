`include "./rtl/picorv32.v"
`include "./rtl_cleaner/SRFPU.sv"

//`timescale 1ns / 1ps

`define debug_mode 1

//the memory is implemented as a von neunmann architecture of simplicity though this does require a memory arbiter 
//This also may slow down memory accesses for the fpu given that picorv performs instruction fetch in the cycle after 
//pcpi goes valid which happens at the same time as 
module memory #(parameter mem_size = 2050, parameter fpu = 0, parameter sr = 0)
(
    input logic        clk,
    input logic        reset,

    input logic        mem_valid,
    input logic        mem_instr,

    output logic       mem_ready,

    input logic[31:0]  mem_addr,
    input logic[31:0]  mem_wdata,
    input logic[3:0]   mem_wstrb,
 
    output logic[31:0] mem_rdata,

    input logic        mem_la_read,
    input logic        mem_la_write,

    input logic[31:0]  mem_la_addr,
    input logic[31:0]  mem_la_wdata,
    input logic[3:0]   mem_la_wstrb,

    output logic[31:0] test_val
);

    logic [31:0] mem [0:mem_size-1];

    assign test_val = mem[0'h0000_0800];

    initial begin
        $readmemh("./testing/firmware.hex", mem); // Load the binary file into memory
    end

    logic[31:0] la_rdata;
    logic       la_ready;


    always_comb 
    begin 

        if(!reset)
        begin 
            mem_ready = 0;
        end 

        else 
        begin 
            if(mem_valid)
            begin 
                if(mem_la_write)
                begin 
                    if (mem_la_wstrb[0]) mem[mem_la_addr[14:2]][7:0]   = mem_la_wdata[7:0];
                    if (mem_la_wstrb[1]) mem[mem_la_addr[14:2]][15:8]  = mem_la_wdata[15:8];
                    if (mem_la_wstrb[2]) mem[mem_la_addr[14:2]][23:16] = mem_la_wdata[23:16];
                    if (mem_la_wstrb[3]) mem[mem_la_addr[14:2]][31:24] = mem_la_wdata[31:24];
                    mem_ready = 1;
                end
                else if(mem_la_read)
                begin 
                    mem_rdata = mem[mem_la_addr[14:2]];
                    mem_ready = 1;
                end
                else if(mem_wstrb)
                begin 
                    if (mem_wstrb[0]) mem[mem_addr[14:2]][7:0]   = mem_wdata[7:0];
                    if (mem_wstrb[1]) mem[mem_addr[14:2]][15:8]  = mem_wdata[15:8];
                    if (mem_wstrb[2]) mem[mem_addr[14:2]][23:16] = mem_wdata[23:16];
                    if (mem_wstrb[3]) mem[mem_addr[14:2]][31:24] = mem_wdata[31:24];
                    mem_ready = 1;
                end
                else 
                begin 
                    mem_rdata = mem[mem_addr[14:2]];
                    mem_ready = 1;
                end 
            end
        end
    end

        
    final 
    begin 
        $writememh("./testing/memory_dump.hex", mem);
    end

endmodule;


module integrated #(parameter fpu = 0, parameter exp_width = 5, parameter mant_width = 23, parameter num_bits = 32, parameter num_round_bits = 12)
(
    input logic clk,
    input logic resetn,
    output logic trap

    //testing outputs
    `ifdef debug_mode
    ,
    output logic test_pcpi_valid,
    output logic test_pcpi_ready,

	output logic[mant_width:0]	test_big_mant,
	output logic[2*mant_width+round_bits_surp+1:0]	test_little_mant,
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

	
	output logic [2*mant_width+2 + round_bits_surp:0] test_unnorm_mant,
	output logic [exp_width+1:0] test_unnorm_exp,
	output logic [2*mant_width+2 + round_bits_surp:0] test_norm_mant,
	output logic [exp_width+1:0] test_exp_change,
	output logic [adder_size-1:0] test_addop1,
	output logic [adder_size-1:0] test_addop2,
	output logic [exp_width+1:0] shift_test,
	output logic[num_bits-1:0] res, 
	output logic[num_bits-1:0] rfrd_1_test,
	output logic[num_bits-1:0] rfrd_2_test,
	output logic[num_bits-1:0] rfwd_test,
	output logic [exp_width+1:0] unround_exp_test,

	output logic[num_round_bits-1:0] rand_test,
	output logic[32+mant_width:0] cvt_reg_test,

    output logic[31:0] pc_test,
    output logic[7:0] state_test
    `endif 
);

	localparam round_bits_surp 				= num_round_bits > mant_width+1 ? num_round_bits-mant_width-1 : 0;
	localparam adder_size                   = 2*mant_width+3+round_bits_surp > 32 ? 2*mant_width+3+round_bits_surp : 32;

    `ifdef debug_mode
    assign test_pcpi_ready = pcpi_ready;
    assign test_pcpi_valid = pcpi_valid;
    `endif 


    logic mem_valid;
    wire mem_instr;
    wire mem_ready;

    
	logic [31:0] mem_addr;  
	logic [31:0] mem_wdata;
	logic [ 3:0] mem_wstrb;
    wire  [31:0] mem_rdata;

	// Look-Ahead Interface
	wire        mem_la_read;
	wire        mem_la_write;
	wire [31:0] mem_la_addr;
	wire [31:0] mem_la_wdata;
	wire [ 3:0] mem_la_wstrb;

	// Pico Co-Processor Interface (PCPI)
	wire        pcpi_valid;
	wire [31:0] pcpi_insn;
	wire [31:0] pcpi_rs1;
	wire [31:0] pcpi_rs2;
	wire        pcpi_wr;
	wire [31:0] pcpi_rd;
	wire        pcpi_wait;
	wire        pcpi_ready;

	// IRQ Interface
	wire [31:0] irq;
	wire [31:0] eoi;

    

    memory mem_inst(  
        .clk(clk),      
        .reset(resetn),

        .mem_valid(mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(mem_ready),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),

        .mem_rdata(mem_rdata),
        .mem_la_read(mem_la_read),
        .mem_la_write(mem_la_write),
        .mem_la_addr(mem_la_addr),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb)
    );

    wire [31:0] pico_mem_addr;
    wire [31:0] pico_mem_wdata;
    wire  [3:0] pico_mem_wstrb;
    wire        pico_mem_valid;

    logic       pico_mem_ready;

    picorv32 #(
        .ENABLE_COUNTERS(1),
	    .ENABLE_COUNTERS64(1), 
	    .ENABLE_REGS_16_31(1),
	    .ENABLE_REGS_DUALPORT(1),
	    .LATCHED_MEM_RDATA(0),
	    .TWO_STAGE_SHIFT(1),
	    .BARREL_SHIFTER(0),
	    .TWO_CYCLE_COMPARE(0),
	    .TWO_CYCLE_ALU(0),
	    .COMPRESSED_ISA(0),
	    .CATCH_MISALIGN(1),
	    .CATCH_ILLINSN(1),
	    .ENABLE_PCPI(1),
	    .ENABLE_MUL(0),
	    .ENABLE_FAST_MUL(0),
	    .ENABLE_DIV(0),
	    .ENABLE_IRQ(0),
	    .ENABLE_IRQ_QREGS(1),
	    .ENABLE_IRQ_TIMER(1),
	    .ENABLE_TRACE(0),
	    .REGS_INIT_ZERO(0),
	    .MASKED_IRQ(32'h 0000_0000),
	    .LATCHED_IRQ(32'h ffff_ffff),
	    .PROGADDR_RESET(32'h 0000_0000),
	    .PROGADDR_IRQ(32'h 0000_0010),
	    .STACKADDR(32'h 0000_2000)

    )picorv_inst(
        .clk(clk),
        .resetn(resetn),
        .trap(trap),

        .mem_valid(pico_mem_valid),
        .mem_instr(mem_instr),
        .mem_ready(pico_mem_ready),
        .mem_addr(pico_mem_addr),
        .mem_wdata(pico_mem_wdata),
        .mem_wstrb(pico_mem_wstrb),

        .mem_rdata(mem_rdata),
        .mem_la_read(mem_la_read),
        .mem_la_write(mem_la_write),
        .mem_la_addr(mem_la_addr),
        .mem_la_wdata(mem_la_wdata),
        .mem_la_wstrb(mem_la_wstrb),

        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
	    .pcpi_rs2(pcpi_rs2),
	    .pcpi_wr(pcpi_wr),
	    .pcpi_rd(pcpi_rd),
	    .pcpi_wait(pcpi_wait),
	    .pcpi_ready(pcpi_ready),

        .irq(irq),
        .eoi(eoi),

        .reg_pc_test(pc_test),
        .state_machine_test(state_test)
        
    );

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
            .mem_valid(fpu_mem_valid),
	        .mem_ready(fpu_mem_ready),
	        .mem_rdata(mem_rdata),
	        .mem_addr(fpu_mem_addr),
	        .mem_wdata(fpu_mem_wdata),
	        .mem_wstrb(fpu_mem_wstrb),
            
    //tests
            .state_test(state_test)

            `ifdef debug_mode
            ,
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
            .rfrd_1_test(rfrd_1_test),
            .rfrd_2_test(rfrd_2_test),
            .rfwd_test(rfwd_test),
            .rand_test(rand_test),
            .cvt_reg_test(cvt_reg_test)
            `endif
    );

    wire [31:0] fpu_mem_addr;
    wire [31:0] fpu_mem_wdata;
    wire  [3:0] fpu_mem_wstrb;
    wire        fpu_mem_valid;

    logic       fpu_mem_ready;

    

    always_comb
    begin 
        fpu_mem_ready  = 0;
        pico_mem_ready = 0;

        if(pico_mem_valid)
        begin 
            mem_addr       = pico_mem_addr;
            mem_wdata      = pico_mem_wdata;
            mem_wstrb      = pico_mem_wstrb;
            mem_valid      = pico_mem_valid;
            pico_mem_ready = mem_ready;
            fpu_mem_ready  = 0;
        end
        else if(fpu_mem_valid)
        begin 
            mem_addr      = fpu_mem_addr;
            mem_wdata     = fpu_mem_wdata;
            mem_wstrb     = fpu_mem_wstrb;
            mem_valid     = fpu_mem_valid;
            fpu_mem_ready = mem_ready;
            pico_mem_ready= 0;
        end
    end 




endmodule;
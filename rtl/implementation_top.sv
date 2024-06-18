`include "./rtl/picorv32.v"
`include "./rtl/SRFPU.sv"

module implementation_top#
(
    parameter mant_width     = 7,
    parameter num_bits       = 16,
    parameter num_round_bits = 12,
    parameter enable_SR      = 1
) 
(
    input logic clk,
    input logic resetn,

    output logic mem_valid,
    output logic mem_instr,
    input logic mem_ready,

    output logic[31:0] mem_addr,
    output logic[31:0] mem_wdata,
    output logic[3:0]  mem_wstrb,
    input logic[31:0] mem_rdata,

    output logic trap

);

    wire pcpi_ready;
    wire pcpi_valid;
    wire pcpi_wait;
    wire pcpi_wr;
    
    wire[31:0] pcpi_rs1;
    wire[31:0] pcpi_rs2;
    wire[31:0] pcpi_rd;
    wire[31:0] pcpi_insn;

    wire fpu_mem_valid;
    
    wire[31:0] fpu_mem_addr;
    wire[31:0] fpu_mem_wdata;
    wire[31:0] fpu_mem_wstrb;

    logic fpu_mem_ready;

    wire pico_mem_valid;

    wire[31:0] pico_mem_addr;
    wire[31:0] pico_mem_wdata;
    wire[31:0] pico_mem_wstrb;

    logic pico_mem_ready;

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

        .pcpi_valid(pcpi_valid),
        .pcpi_insn(pcpi_insn),
        .pcpi_rs1(pcpi_rs1),
	    .pcpi_rs2(pcpi_rs2),
	    .pcpi_wr(pcpi_wr),
	    .pcpi_rd(pcpi_rd),
	    .pcpi_wait(pcpi_wait),
	    .pcpi_ready(pcpi_ready),

        .mem_rdata(mem_rdata),
        .mem_la_read(),
        .mem_la_write(),
        .mem_la_addr(),
        .mem_la_wdata(),
        .mem_la_wstrb(),

        .irq(),
        .eoi(),

        .reg_pc_test(),
        .state_machine_test()        
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
    );



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
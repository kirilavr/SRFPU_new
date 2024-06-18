`ifndef SRFPU
`define SRFPU

`include "./rtl/classifier.sv"
`include "./rtl/regfile.sv"
`include "./rtl/addmul_pre.sv"
`include "./rtl/rng.sv"
`include "./rtl/clz.sv"

//`define debug_mode 1
//`define verify 1

//`timescale 1ns / 1ps

typedef enum logic[3:0] 
{
	WAIT,
	DECODE,
	LDMEM,
	SMEM,
	CVT,
	CMP,
	PREALIGN,
	ALIGN,
	EX,
	NORM,
	ROUND,
	WB
} state_t;

typedef enum logic[2:0]
{
	RNE = 3'b000,
	RTZ = 3'b001,
	RDN = 3'b010,
	RUP = 3'b011,
	RMM = 3'b100,
	RSR = 3'b101
} round_mode_t;


module SRFPU#(
    parameter num_bits       = 32,
    parameter num_round_bits = 15
)(
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
	output logic[adder_size:0]	test_mantissa_diff,
	output logic[mant_width:0]	test_big_mant,
	output logic[mant_width+num_round_bits:0]	test_little_mant,
	output logic[exp_width+1:0]	test_res_exp,
	output logic	test_arithmetic,
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


	output logic[adder_size:0] adder_res_test,

	
	output logic [num_round_bits+mant_width+1:0] test_unnorm_mant,
	output logic [exp_width+1:0] test_unnorm_exp,
	output logic [num_round_bits+mant_width+1:0] test_norm_mant,
	output logic [exp_width+1:0] test_exp_change,
	output logic [mant_width+num_round_bits+1:0] test_norm_mant_buffer,
	output logic [mant_width+num_round_bits+1:0] norm_mant_latched_test,

	output logic [adder_size:0] test_addop1,
	output logic [adder_size:0] test_addop2,

	output logic [exp_width+1:0] shift_test,

	output logic [mant_width*2+1:0] multiplicand_test,
	output logic [5:0] mul_counter_test,
	output logic[num_bits-1:0] res

	, 
	input logic[31:0] op1,
	input logic[31:0] op2,
	
	output logic[num_bits-1:0] frs1_test,
	output logic[num_bits-1:0] frs2_test,
	output logic[num_bits-1:0] rfrd_1_test,
	output logic[num_bits-1:0] rfrd_2_test,
	output logic[num_bits-1:0] rfwd_test,
	output logic [exp_width+1:0] unround_exp_test,

	output logic[num_round_bits-1:0] rand_test

	`endif



);

	`ifdef debug_mode
	assign res = rfwd;
	assign rfwd_test = rfwd;
	assign state_test = state;
	assign frs1_test = rfrd_1;
	assign frs2_test = rfrd_2;
	`endif


    localparam exp_width                    = 8;//(num_bits == 16) ? 5  : 8;
    localparam mant_width                   = (num_bits == 16) ? 7 : 23;
	localparam adder_size                   = (mant_width+num_round_bits+2 < mant_width*2+2) ? (mant_width*2+1 < 31? 31:mant_width*2+1) : mant_width+num_round_bits+1 < 31 ? 31 : mant_width+num_round_bits+1;
	localparam logic[exp_width+1:0] bias    = 127;
	localparam logic signed[exp_width+1:0] neg_bias = -127;
	localparam logic[exp_width+1:0] bias_of = 128;

	localparam logic signed[exp_width+1:0] max_exp = 127;
	localparam logic signed[exp_width+1:0] min_exp = -126;
	localparam logic signed[exp_width+1:0] min_subn_exp = -127 - mant_width - num_round_bits;



	logic [4:0] rfar_1;
	logic [4:0] rfar_2;
	logic [4:0] rfaw;

	logic [num_bits-1:0] rfrd_1;
	logic [num_bits-1:0] rfrd_2;
	logic [num_bits-1:0] rfwd;

	logic rfwe;

	logic mul_bottom_bit;

	`ifdef verify

	logic [31:0] bfloat_in1;
	logic [31:0] bfloat_in2;

	logic [31:0] bfloat1;
	logic [31:0] bfloat2;


	generate 
		if(num_bits == 16) begin 
			always_comb begin 
				bfloat_in1 = op1;
				bfloat_in2 = op2;
				if(round_mode == RSR) begin

					if(state == DECODE) begin 
						bfloat1 = bfloat_in1 + {{16{1'b0}}, rand_val[num_round_bits-1:num_round_bits<16?0:(num_round_bits-16)], {num_round_bits>16?0:16-num_round_bits{1'b0}}};
						rfrd_1  = bfloat1[31:16];
					end else if (state == PREALIGN) begin 
						bfloat2 = bfloat_in2 + {{16{1'b0}}, rand_val[num_round_bits-1:num_round_bits<16?0:(num_round_bits-16)], {num_round_bits>16?0:16-num_round_bits{1'b0}}};
						rfrd_2  = bfloat2[31:16];
					end
				end else if(state == DECODE) begin 
					bfloat1 = bfloat_in1 + {16'b0, bfloat_in1[15] & (bfloat_in1[16] | (|bfloat_in1[14:0])), 15'b0};
					bfloat2 = bfloat_in2 + {16'b0, bfloat_in2[15] & (bfloat_in2[16] | (|bfloat_in2[14:0])), 15'b0};

					rfrd_1 = bfloat1[31:16];
					rfrd_2 = bfloat2[31:16];
				end
			end 
		end 
	endgenerate

	`else 
		regfile #(num_bits) regfile_inst(.clk(clk), .rst(resetn), .read_addr1(rfar_1), .read_addr2(rfar_2), .write_addr(rfaw), .write_data(rfwd),
						 .write_enable(rfwe), .read_data1(rfrd_1), .read_data2(rfrd_2));
	`endif
	
	state_t state;
	logic[31:0] fcsr;
	
	round_mode_t round_mode;

	assign round_mode = RSR;

	logic signed [adder_size:0] adder_op1;
	logic signed [adder_size:0] adder_op2;
	logic signed [adder_size:0] adder_res;

	logic [mant_width*2+1:0] multiplicand;

	logic mul_valid;

	logic mem_access;

	logic signed [exp_width+1:0] unround_exp;
	logic signed [exp_width+1:0] unbiased_exp1;

	logic [num_bits-1:0] pre1;
	logic [num_bits-1:0] pre2;

	wire adder_neg;
	logic sub;

	logic op_mul;
	logic op_cvt;
	logic op_add;
	logic op_cvt_to_int;
	logic op_cvt_signed;
	logic op_eq;
	logic op_le;
	logic op_lt;
	logic op_min;
	logic op_max;
	logic op_mvWX;
	logic op_mvXW;

	logic arithmetic;
	logic rs2_big;

	logic signed [exp_width+1:0] exp_diff;
	logic [num_bits-1:0] direct_result;
	logic [num_bits-1:0] direct_result_latched;

	logic [31:0] instr_latched;

	logic [31+mant_width:0] cvt_reg;
	logic [5:0] mul_counter;

	assign adder_neg = adder_res[adder_size];
	assign adder_res = sub ? adder_op1 - adder_op2 : adder_op1 + adder_op2;


	always_ff @(posedge clk)
	begin 
		if(!resetn)
		begin 
			state          <= DECODE;
			pcpi_ready     <= 0;
			pcpi_wait      <= 0;
			pcpi_wr        <= 0;
			pcpi_rd        <= 0;
			fcsr           <= {{24{1'b0}}, round_mode, {5{1'b0}}};
		end 

		(* parallel_case, full_case *)
		case(state)

			//if pipelined this stage can be omitted: since the pico core is not pipelined in the traditional sense of the word
			//the pcpi_ready flag must be asserted for one clock cycle then reset, since the pcpi cannot be enabled in the cycle 
			//after a pcpi instruction is completed this will not affect performance
			//This is a consideration for future work which may involve pipelining and integration with a pipelined core.
			//this state is needed at the moment so that the wb data to the core remains available until pico acknowledges receipt by
			//resetting pcpi_valid
			WAIT: begin 
				if(~pcpi_valid)
				begin 
					pcpi_ready <= 0;
					pcpi_wr    <= 0;
					pcpi_rd    <= 0;
					pcpi_wait  <= 0;
					adder_op1  <= 0;
					adder_op2  <= 0;
					mem_wdata  <= 0;
					mem_wstrb  <= 0;
					mul_valid  <= 0;
					op_mul     <= 0;
					op_cvt     <= 0;   
					op_add     <= 0;     
					op_eq      <= 0;   
					op_le      <= 0;   
					op_lt      <= 0;   
					op_min     <= 0;   
					op_max     <= 0;   
					op_mvWX    <= 0;   
					op_mvXW    <= 0;   
					get_next_val  <= num_bits == 32 ? 0 : 1;
					op_cvt_to_int <= 0; 
					op_cvt_signed <= 0;
					mem_access <= 0;


					state      <= DECODE;
				end
			end 

			DECODE: begin 
				//pcpi_ready <= 0;
				//pcpi_wait  <= 1;

				if(pcpi_valid)
				begin 

					if(~pcpi_insn[6])
					begin 
						instr_latched          <= pcpi_insn;
						adder_op1[31:0] 	   <= pcpi_rs1;
						adder_op2[31:0] 	   <= ~pcpi_insn[5] ? {{20{1'b0}}, pcpi_insn[31:20]} : {{20{1'b0}}, pcpi_insn[31:25], pcpi_insn[11:7]};
						sub 				   <= pcpi_insn[31] ? 1 : 0;
						mem_access  		   <= 1;
						
						rfar_1                 <= pcpi_insn[24:20];
						state <= ~pcpi_insn[5] ? LDMEM : SMEM;
					end 
					else 
					begin 
						rfar_1 <= pcpi_insn[19:15];
						rfar_2 <= pcpi_insn[24:20];
						(* parallel_case, full_case *)
						case(pcpi_insn[31:25]) 
							//add and subtract
							7'b0000100, 7'b0000000: begin
								`ifdef verify
								if(num_bits == 32) begin
									rfrd_1 <= op1[num_bits-1:0];
									rfrd_2 <= op2[num_bits-1:0];
								end
								`endif
								state  <= PREALIGN;
								op_add <= 1;

								get_next_val <= 1;
							end

							//multiply
							7'b0001000: begin 
								`ifdef verify
								if(num_bits == 32) begin
									rfrd_1 <= op1[num_bits-1:0];
									rfrd_2 <= op2[num_bits-1:0];
								end
								`endif
								state  <= PREALIGN;
								op_mul <= 1;
								get_next_val <= 1;
							end

							//conversion operations
							7'b1100000, 7'b1101000: begin 
								state  <= CVT;
								op_cvt <=1;
								op_cvt_to_int <= ~pcpi_insn[28];
								op_cvt_signed <= ~pcpi_insn[20];

								get_next_val <= 1;
							end 

							//min max operations
							7'b0010100: begin 
								rfar_1 <= pcpi_insn[19:15];
								rfar_2 <= pcpi_insn[24:20];

								op_min <= pcpi_insn[14:12] == 0;
								op_max <= pcpi_insn[14:12] == 1;

								state <= CMP;
							end 
							
							//comparison operations
							7'b1010000: begin 
								op_eq <= pcpi_insn[14:12] == 2;
								op_lt <= pcpi_insn[14:12] == 1;
								op_le <= pcpi_insn[14:12] == 0;

								state <= CMP;
							end 

							//floating point to integer move
							7'b1110000: begin 
								op_mvXW <= 1;
								state <= WB;
							end 

							7'b1111000: begin 
								op_mvWX <= 1;
								state <= WB;
							end 



							default: begin end 
						endcase
					end 
				end 
			end 

			LDMEM: begin 
				mem_valid <= 1;
				mem_addr  <= adder_res[31:0];
				
				if(num_bits == 16) begin 
					state <= ROUND;
				end else begin 
					state     <= WB;
				end
			end

			SMEM: begin 
				mem_addr  <= adder_res[31:0];
				mem_wdata <= {rfrd_1, {num_bits == 16 ? 16 : 0{1'b0}}};
				mem_wstrb <= 4'b1111;
				mem_valid <= 1;

				if(mem_ready)
				begin 
					mem_valid <= 0;
					state     <= WAIT;
					pcpi_ready<= 1;
					pcpi_wait <= 0;
				end
			
			end

			//Cases: if exponents are different mul_counter is zero in WB
			// 		 if exponents are the same mul_counter is 1 in WB
			CMP: begin 
				if(~mul_counter[0]) begin
					adder_op1 <= {{adder_size - exp_width + 1{1'b0}}, rfrd_1[num_bits-2:mant_width]};
					adder_op2 <= {{adder_size - exp_width + 1{1'b0}}, rfrd_1[num_bits-2:mant_width]};
					sub <= 1;
					mul_counter[0] <= 1;
				end else if(mul_counter[0]) begin 
					adder_op1 <= {{adder_size - mant_width + 1{1'b0}}, rfrd_1[mant_width-1:0]};
					adder_op2 <= {{adder_size - mant_width + 1{1'b0}}, rfrd_1[mant_width-1:0]};
					
					rs2_big <= adder_neg;
					mul_counter[0] <= adder_res == 0;
					state <= WB;
				end 
			end
 

			CVT: begin 
				if(op_cvt_to_int)
				begin

					if(rfrd_1[num_bits-2] & ((rfrd_1[num_bits-2:mant_width] == 8'b10011111) | rfrd_1[mant_width+5] | rfrd_1[mant_width+6]))
					begin 
						pcpi_rd    <= 32'hffff_ffff;
						pcpi_wr    <= 1;
						state      <= WAIT;
						pcpi_ready <= 1;

					end else if(rfrd_1[num_bits-2:mant_width] == 8'b01111110 | rfrd_1[num_bits-2]) begin
						cvt_reg <= {{32{1'b0}}, rfrd_1[mant_width-1:0]};
						state   <= ROUND;

					end else if(rfrd_1[num_bits-2]) begin 
						cvt_reg <= {{31{1'b0}}, 1'b1, rfrd_1[mant_width-1:0]}<<rfrd_1[num_bits-3:mant_width];
						state   <= ROUND;

					end else begin 
						pcpi_rd    <= 32'h0000_0000;
						pcpi_wr    <= 1;
						state      <= WAIT;
						pcpi_ready <= 1;
					end
				end 
			end

			PREALIGN: begin 
				//operands go into pre-processing for addmul (alignment)

				get_next_val <= 0;

				//calculate exponent difference (grrr comparison operation adding needless stuff need to figure out how to get rid of it !!!!!!!!!!!!!!!)
				//Not too bad since exp is small but still annoying 
				
				if(op_add) begin


					if(subn1 & subn2) begin 
						adder_op1 <= {adder_size+1{1'b0}};
						adder_op2 <= {adder_size+1{1'b0}};
						rs2_big <= 0;
						sub <= 0;

					end else if(rfrd_1[num_bits-2:mant_width] < rfrd_2[num_bits-2:mant_width]) begin
						adder_op2 <= subn1 ? {{adder_size{1'b0}}, 1'b0} : {{adder_size - exp_width+1{1'b0}}, rfrd_1[num_bits-2:mant_width]};
						adder_op1 <= {{adder_size - exp_width+1{1'b0}}, rfrd_2[num_bits-2:mant_width]};
						rs2_big <= 1;
						sub <= 1;

					end else begin

						adder_op1 <= {{adder_size - exp_width +1{1'b0}}, rfrd_1[num_bits-2:mant_width]};
						adder_op2 <= subn2 ? {{adder_size{1'b0}}, 1'b0} : {{adder_size - exp_width+1{1'b0}}, rfrd_2[num_bits-2:mant_width]};
						rs2_big <= 0;
						sub <= 1;
					end


				end else if(op_mul) begin
					adder_op1 <= subn1 ? {{adder_size-exp_width+1{1'b0}}, rfrd_2[num_bits-2:mant_width]} : {{adder_size-exp_width+1{1'b0}}, rfrd_1[num_bits-2:mant_width]};
					adder_op2 <= {{adder_size - exp_width - 1{1'b0}}, bias};
					sub       <= 1;
				end 
					

				state <= ALIGN;
			end

			ALIGN: begin

				if(op_add) begin
						
					//mantissa difference calculated in case both are subnormal
					adder_op1 <= {{adder_size-mant_width+1{1'b0}}, rfrd_1[mant_width-1:0]};
					adder_op2 <= {{adder_size-mant_width+1{1'b0}}, rfrd_2[mant_width-1:0]};
					sub 					  <= 1;
					
					//specify add preprocessing, larger value and latch exp diff
					exp_diff <= adder_res[exp_width+1:0];

					state <= EX;

				end else if (op_mul) begin 

					unbiased_exp1 <= adder_res[exp_width+1:0];

					adder_op2 <= subn1 | subn2 ? {{adder_size - exp_width - 1{1'b0}}, lz} : {{adder_size-exp_width+1{1'b0}}, rfrd_2[num_bits-2:mant_width]};
					adder_op1 <= {{adder_size - exp_width - 1{1'b0}}, subn1|subn2 ? min_exp : neg_bias};
					sub       <= subn1|subn2;

					state <= EX;
				end 

					
				


				//operands passed to alignment module
				pre1 <= rfrd_1;
				pre2 <= rfrd_2;
				
				//flags passed in to prealignment
			end 

			EX: begin 

				if(op_add) begin

					if(arithmetic) begin
	
						//perform addsub
						if(adder_neg & (rfrd_1[num_bits-2:mant_width] == rfrd_2[num_bits-2:mant_width])) begin 

							adder_op2 <= {{adder_size-num_round_bits-mant_width{1'b0}}, big_mant, {num_round_bits{1'b0}}};
							adder_op1 <= {{adder_size-num_round_bits-mant_width{1'b0}}, little_mant};
							sign <= rfrd_2[num_bits-1];

						end else begin 
							adder_op2 <= {{adder_size-mant_width-num_round_bits{1'b0}}, little_mant};
							adder_op1 <= {{adder_size-mant_width-num_round_bits{1'b0}}, big_mant, {num_round_bits{1'b0}}};
							sign <= sign_out;
						end 

						//set sub flag if the signs are different
						sub <= rfrd_1[num_bits-1]^rfrd_2[num_bits-1];

						//latch exponent and sign from preprocessing stage
						unnorm_exp_latched <= unnorm_exp;

						state <= NORM;

					end else begin 
						//in cases of infinity, zeroes or nans ie. no arithmetic the result is available directly
						direct_result_latched <= direct_result;
						state  <= WB;
					end


				end else if(op_mul) begin 

					sign <= sign_out;
					

					if(arithmetic) begin 

						if(skip_mul) begin 
							mul_valid <= 0;
							state     <= WB;

						end else if(~mul_valid) begin
						    adder_op1 <= adder_res;
						    adder_op2 <= {{adder_size-exp_width-1{unbiased_exp1[exp_width+1]}}, unbiased_exp1};
						    sub <= 0;
							mul_counter  <= 0;
							mul_valid    <= 1;
							sub 		 <= 0;
							multiplicand <= {{mant_width+1{1'b0}}, big_mant};

						end else if(mul_counter == mant_width+1) begin 
							mul_valid    <= 0;
							state        <= NORM;

						end else if(mul_valid) begin 
							adder_op1   <= {{adder_size-mant_width*2-1{1'b0}}, little_mant[num_round_bits+mul_counter] ? multiplicand : {mant_width*2+2{1'b0}}};
							adder_op2   <= mul_counter == 0 ? 0 : adder_res;

							mul_counter  <= mul_counter + 1;
							multiplicand <= multiplicand << 1;
						end 
						
					end else begin 
						direct_result_latched <= direct_result;
						state <= WB; 
					end
				end

			end

			//shift - exponent if negative: can shift by the e
			//exponent - shift: neg: shift by exponent pos: shift by shift
			NORM: begin 
				
				if(op_add) begin

					adder_op1 <= {{adder_size-exp_width-1{1'b0}}, unnorm_exp};
					adder_op2 <= {{adder_size-exp_width-1{1'b0}}, adder_res[mant_width + num_round_bits + 1] ? {{exp_width+1{1'b0}}, 1'b1} : lz};

					unnorm_mant <= adder_res[mant_width+num_round_bits+1:0];

					simple_norm <= adder_res[mant_width+num_round_bits+1];

					sub <= ~adder_res[num_round_bits + mant_width + 1];

					lz_latched <= lz;

				end else if(op_mul) begin 
					//unnorm mant is mant width + num_round bits + 1:0 => if mant_width*2+2 > mant_width+num_round bits dont zero extend, otherwise need mant_widht + num_round_bits - mant_width*2+2 = num_round_bits - mant_width-2
					//unnorm_mant <= adder_res[mant_width*2+1:mant_width-num_round_bits];
					unnorm_mant <= {adder_res[mant_width*2+1:mant_width>num_round_bits?mant_width-num_round_bits:0], {mant_width<num_round_bits ? num_round_bits-mant_width:0{1'b0}}};
					simple_norm <= adder_res[mant_width*2+1];


					if(unround_exp < min_exp) begin 
						adder_op1 <= {{adder_size-exp_width-1{1'b1}}, min_exp};
						adder_op2 <= {{adder_size-exp_width-1{1'b1}}, unround_exp};
						sub       <= 1;

					end else begin
						adder_op1   <= {{adder_size - exp_width - 1{1'b0}}, unround_exp};
						adder_op2   <= {adder_res[mant_width*2+1] ? {{adder_size - exp_width - 1{1'b0}}, bias_of} : {{adder_size - exp_width - 1{1'b0}}, bias}};
						sub         <= 0;
					end
				end 
				

				state       <= ROUND;
			end

			ROUND: begin 
				//rounding not yet implemented
				sub <= 0;

				if(num_bits==16 & mem_access & mem_ready) begin 
					adder_op1 <= {{adder_size - mant_width+1{1'b0}}, mem_rdata[mant_width-1:0]};
					//adder_op2 <= {{adder_size - 15{1'b0}}, rand_val[15:0]};
					state     <= WB;
					mem_valid <= 0;

				end else if(op_cvt) begin 
					adder_op1 <= {{adder_size-mant_width+1{1'b0}}, cvt_reg[mant_width-1:0]};

					if(round_mode == RDN)
					begin 
						adder_op2 <= {{adder_size-mant_width+1{1'b0}}, 1'b1, {mant_width-1{1'b0}}};
						state <= WB;
					end 
					else if(round_mode == RSR)
					begin 
						//adder_op2 <= {{adder_size - num_round_bits + 1{1'b0}}, rand_val, {(mant_width < num_round_bits ? 0 : mant_width-num_round_bits){1'b0}}};
						state <= WB;
					end 

				end else begin

					adder_op1 <= {{adder_size-num_round_bits-mant_width-1{1'b0}}, norm_mant};

					(* parallel_case, full_case *)
					case(round_mode)
						//round up if bottom mant bit and guard bit set, or if guard bit and any other
						RDN: begin adder_op2 <= {{adder_size-num_round_bits+1{1'b0}}, norm_mant[num_round_bits-1] & (norm_mant[num_round_bits] | (|norm_mant[num_round_bits-2:0])) , {num_round_bits-1{1'b0}}}; end
						RSR: begin adder_op2 <= {{adder_size-num_round_bits+1{1'b0}}, rand_val}; end
						RTZ: begin adder_op2 <= {{adder_size-num_round_bits+1{1'b0}}, sign_out ? 1'b1 : 1'b0, {num_round_bits-1{1'b0}}}; end
						default: begin end
					endcase

					state <= WB;
				end

			end 

			WB: begin 
				
				if(op_cvt) begin 
					pcpi_rd <= cvt_reg[31+mant_width:mant_width] + (adder_res[mant_width] ? 1 : 0);
					pcpi_wr <= 1;
					pcpi_ready <=1;
					state <= WAIT;

				end else if(op_add) begin
					rfaw       <= pcpi_insn[11:7];
					rfwe       <= 1;
					state      <= WAIT;
					pcpi_ready <= 1;
					pcpi_wait  <= 0;
					mem_valid  <= 0;

					if(arithmetic) begin 

						if(unround_exp == {2'b00, {exp_width{1'b1}}} | unround_exp[exp_width] == 1) begin 
							rfwd <= {sign, {exp_width{1'b1}}, {mant_width{1'b0}}};

						end else if(unround_exp == {2'b00, {exp_width-1{1'b1}}, 1'b0} & adder_res[mant_width+num_round_bits+1]) begin
							rfwd <= {sign, {exp_width{1'b1}}, {mant_width{1'b0}}};

						end else begin 
							if(adder_res[mant_width+num_round_bits+1]) begin
								rfwd <= {sign, (unround_exp[exp_width-1:0]+{{exp_width-1{1'b0}},1'b1}), adder_res[num_round_bits+mant_width:num_round_bits+1]};

							end else begin 
								rfwd <= {sign, unround_exp[exp_width-1:0], adder_res[num_round_bits+mant_width-1:num_round_bits]};
							end
						end

					end else begin 
						rfwd <= direct_result_latched;
					end

				end else if (op_mul) begin 

					if(~arithmetic) begin 
						rfwd <= direct_result_latched;
					end else if(skip_mul) begin 
						rfwd <= {sign, unround_exp[exp_width-1:0], {mant_width{1'b0}}};
					end else if(unround_exp[exp_width+1]) begin 
						rfwd <= {sign, {num_bits-1{1'b0}}};
					end else if (unround_exp[exp_width] | &unround_exp[exp_width-1:0] | (unround_exp == 10'b0011111110 & adder_res[num_round_bits+mant_width+1])) begin 
						rfwd <= {sign, {exp_width{1'b1}}, {mant_width{1'b0}}};
					end else if(adder_res[mant_width+num_round_bits+1]) begin 
						rfwd <= {sign, unround_exp[exp_width-1:0], adder_res[num_round_bits+mant_width:num_round_bits+1]};
					end else begin 
						rfwd <= {sign, unround_exp[exp_width-1:0], adder_res[num_round_bits+mant_width-1:num_round_bits]};
					end 

					rfaw       <= pcpi_insn[11:7];
					rfwe       <= 1;
					state      <= WAIT;
					pcpi_ready <= 1;
					pcpi_wait  <= 0;
					mem_valid  <= 0;

				end else if(op_eq | op_lt | op_le | op_min | op_max) begin 

					rfaw       <= pcpi_insn[11:7];
					rfwe       <= 1;
					state      <= WAIT;
					pcpi_ready <= 1;
					pcpi_wait  <= 0;
					mem_valid  <= 0;
					
					if(snan1 | snan2 | qnan1 | qnan2) begin rfwd <= {12'h7fc, {num_bits == 16 ? 4 : 20{1'b0}}}; end
					else if(op_eq) begin rfwd <= {{num_bits-1{1'b0}}, mul_counter[0] & adder_res == 0}; end 
					else if(op_lt) begin rfwd <= {{num_bits-1{1'b0}}, rs2_big | (mul_counter[0] & adder_neg)}; end
					else if(op_le) begin rfwd <= {{num_bits-1{1'b0}}, rs2_big | (mul_counter[0] & (adder_neg | adder_res == 0))}; end
					else if(op_min) begin rfwd <= rs2_big | (mul_counter[0] & adder_neg) ? rfrd_1 : rfrd_2; end
					else if(op_max) begin rfwd <= rs2_big | (mul_counter[0] & adder_neg) ? rfrd_2 : rfrd_1; end

				end else if (op_mvWX) begin 
					rfwd <= pcpi_rs1[num_bits-1:0];
					rfaw       <= pcpi_insn[11:7];
					rfwe       <= 1;
					state      <= WAIT;
					pcpi_ready <= 1;
					pcpi_wait  <= 0;
					mem_valid  <= 0;

				end else if (op_mvXW) begin 
					pcpi_rd[num_bits-1:0] <= rfrd_1;
					pcpi_wr <= 1;
					pcpi_ready <= 1;
					pcpi_wait  <= 0;
					mem_valid  <= 0;

				end else begin

					if(num_bits == 16) begin
						state      <= WAIT;
						pcpi_ready <= 1;
						pcpi_wait  <= 0;
						rfaw <= pcpi_insn[11:7];
						rfwe <= 1;
						rfwd <= mem_rdata[num_bits-1:0];
						
					end else if(mem_ready) begin
						mem_valid  <= 0;
						state      <= WAIT;
						pcpi_ready <= 1;
						pcpi_wait  <= 0;
						rfaw <= pcpi_insn[11:7];
						rfwe <= 1;
						rfwd <= mem_rdata[num_bits-1:0];
					end
				end 
			end 

			default: begin end 
		endcase
	end

	logic [mant_width+num_round_bits+1:0] norm_mant_buffer;
	logic [exp_width+1:0] lz_latched;
	logic skip_mul;
	
	always_comb begin 

		//normalisation: the shift amount and normalised exponent values become available in the rounding stage: since the rounding stage is short
		//this does not affect fmax and hence the subsequent shifts are performed in this stage: this is done in the interest of using one adder 
		//for the whole fpu	

		if(state == EX & op_mul & arithmetic)
		begin 
			mul_bottom_bit = little_mant[num_round_bits];
		end

		//normalisation cases (addsub):
		// simple norm: overflow bit set all test cases should be coverred.
		// lz_latched is 0: if the result is expected sub then it must be promoted to norm and the exponent set to one otherwise stays norm and nothing else needed
		// unnorm_exp - lz is -ve: if the num is sub then the unnorm exp is zero and hence just pass through else shift by the value of unnorm exp 
		// unnorm_exp - lz = 0 & lz != 0: occurs during the subtraction of two normal numbers and the result can be made normal with unround exp = 1 and the shift = lz
		// unnorm_exp - lz is +ve: occurs during subtraction and the normalisation is lz and unround_exp = adder res

		if(state == ROUND)
		begin	
			clz_in = adder_res[num_round_bits+mant_width:0];

			//In the case of a subnormal result the adder in NORM is used to calculate the shift needed to noramlise the result
			//If the sum of exponents is less than the minimum exponent (-126 for 8-bit exp) - mant_width - num_round-bits -1 the
			//result will have already been handled and multiplication will not have occurred since this results in zero
			//if the exponent result is -127 and simple norm is active then simple norm is sufficient and the result is normal
			//if the exponent result is -127 or less all normalisation cases are handled by shifting by the result of the adder 
			//and setting the exponent to zero: this always results in a subnormal result.
			//sub will be active in the ROUND state if the exponent is -127 or less.
			if(op_mul) begin 
				if(sub) begin 
					if(simple_norm & adder_res[exp_width+1:0] == 1) begin 
						unround_exp = 1;
						norm_mant = unnorm_mant>>1;
					end else begin 
						unround_exp = 0;
						norm_mant = unnorm_mant>>adder_res[exp_width+1:0];
					end 
				end else begin 
					unround_exp = adder_res[exp_width+1:0];
					if(simple_norm) begin 
						norm_mant = unnorm_mant>>1;
					end else begin 
						norm_mant = unnorm_mant;
					end
				end 


			end else if(simple_norm)
			begin 
				norm_mant = unnorm_mant >> 1;
				unround_exp = adder_res[exp_width+1:0];

			end else if(lz_latched == 0) begin 

				if(unnorm_exp == 0) begin 
					unround_exp = 1;

				end else begin
					unround_exp = unnorm_exp;

				end
				norm_mant = unnorm_mant;
			end

			else if(adder_neg)
			begin 
				norm_mant = unnorm_mant<<(unnorm_exp-1);
				unround_exp = 0;
			end 

			else if(adder_res == 0)
			begin 
				norm_mant = unnorm_mant<<(lz_latched-1);
				unround_exp = 0;
			end 

			else
			begin 
				norm_mant = unnorm_mant<<lz_latched;
				unround_exp = adder_res[exp_width+1:0];
				norm = 1;
				subn = 0;
			end

		end else if(state == EX & op_mul & mul_counter == 0 & mul_valid) begin 
			if($signed(adder_res[exp_width+1:0]) < min_subn_exp) begin 
				unround_exp = 0;
				skip_mul = 1;
			end else if($signed(adder_res[exp_width+1:0]) > max_exp) begin 
				unround_exp = {1'b0, {exp_width+1{1'b1}}};
				skip_mul = 1;
			end else begin 
				unround_exp = adder_res[exp_width+1:0];
				skip_mul = 0;
			end
		end 


		if(state == ALIGN)
		begin 
			clz_in = {1'b0, subn1 ? rfrd_1[mant_width-1:0] : rfrd_2[mant_width-1:0], {num_round_bits{1'b0}}};
			skip_mul = 0;
		end

		if(state == NORM) begin 
			clz_in = adder_res[mant_width+num_round_bits:0];
		end



	`ifdef debug_mode

		//exp width becomes available:
		test_exp_diff = exp_diff;

		

		//classification results become available:
		test_zero1 = zero1;
		test_inf1 = inf1;
		test_subn1 = subn1;
		test_norm1 = norm1;
		test_snan1 = snan1;
		test_qnan1 = qnan1;

		test_zero2 = zero2;
		test_inf2 = inf2;
		test_subn2 = subn2;
		test_norm2 = norm2;
		test_snan2 = snan2;
		test_qnan2 = qnan2;

		test_mantissa_diff = adder_res;

		test_big_mant = big_mant;
		test_little_mant = little_mant;

		test_res_exp = unnorm_exp;

		test_arithmetic = arithmetic;
		test_direct_result = direct_result;
		test_sign  = sign;

		test_zero  = zero;
		test_inf = inf;
		test_subn = subn;
		test_norm = norm;
		test_qnan = qnan;
		test_snan = snan;

		adder_res_test = adder_res;

		test_unnorm_mant = unnorm_mant;
		test_unnorm_exp = unnorm_exp;
		test_norm_mant = norm_mant;
		test_exp_change = exp_change;
		test_norm_mant_buffer = norm_mant_buffer;

		norm_mant_latched_test = norm_mant_latched;

		test_addop1 = adder_op1;
		test_addop2 = adder_op2;

		shift_test = lz;

		unround_exp_test = unround_exp;

		multiplicand_test = multiplicand;
		rand_test = rand_val;
	`endif

	end


classifier #(.num_bits(num_bits),
		   .mant_width(mant_width),
		   .exp_width(exp_width)
)classifier_1_inst (.f(rfrd_1),
					.zero(zero1),
					.inf(inf1),
					.subN(subn1),
					.Norm(norm1),
					.QNan(qnan1),
					.SNan(snan1)
);

classifier #(.num_bits(num_bits),
		   .mant_width(mant_width),
		   .exp_width(exp_width)
)classifier_2_inst (.f(rfrd_2),
					.zero(zero2),
					.inf(inf2),
					.subN(subn2),
					.Norm(norm2),
					.QNan(qnan2),
					.SNan(snan2)
);

logic zero1;
logic inf1;
logic subn1;
logic norm1;
logic qnan1;
logic snan1;

logic zero2;
logic inf2;
logic subn2;
logic norm2;
logic qnan2;
logic snan2;

logic zero;
logic inf;
logic subn;
logic norm;
logic qnan;
logic snan;

logic[exp_width+1:0] unnorm_exp;
logic[exp_width+1:0] unnorm_exp_latched;

logic[mant_width+num_round_bits+1:0] unnorm_mant;
logic[exp_width+1:0] norm_exp;
logic[mant_width+num_round_bits+1:0] norm_mant;
logic[mant_width+num_round_bits+1:0] norm_mant_latched;

logic[mant_width:0] big_mant;
logic[mant_width+num_round_bits:0] little_mant;

logic sign_out;
logic sign;

logic signed [exp_width+1:0] exp_change;
logic neg_shift;
logic simple_norm;
logic [mant_width+num_round_bits:0] clz_in;

addmul_pre #(num_round_bits, num_bits, exp_width, mant_width) 
			   addsub_pre_inst(.zero1(zero1), .inf1(inf1), .subn1(subn1), .norm1(norm1), .qnan1(qnan1), .snan1(snan1),
							   .zero2(zero2), .inf2(inf2), .subn2(subn2), .norm2(norm2), .qnan2(qnan2), .snan2(snan2),
							   .rs1(pre1), .rs2(pre2), .big_mant(big_mant), .little_mant(little_mant), .direct_result(direct_result), .sign(sign_out), .arithmetic(arithmetic), .exp_diff(exp_diff), .unnorm_exp(unnorm_exp),
							   .zero(zero), .inf(inf), .subn(subn), .norm(norm), .qnan(qnan), .snan(snan), .mul(op_mul), .rs2_big(rs2_big), .lz(lz));


logic [num_round_bits-1:0] rand_val;
logic get_next_val;

logic [exp_width+1:0] lz;

rng #(num_round_bits) rng_inst(.clk(clk), .resetn(resetn), .get_next_val(get_next_val), .out(rand_val));

clz #(num_round_bits, exp_width, mant_width) clz_inst(.in(clz_in), .out(lz));



endmodule;




`endif 
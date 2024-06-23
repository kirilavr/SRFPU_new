`ifndef SRFPU
`define SRFPU

`include "rtl_cleaner/classifier.sv"
`include "rtl_cleaner/regfile.sv"
`include "rtl_cleaner/addmul_pre.sv"
`include "rtl_cleaner/rng.sv"
`include "rtl_cleaner/clz.sv"

`define debug_mode 1
`define verify 1

typedef enum logic[3:0] 
{
	DECODE,
	MEM,
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
    parameter num_bits  = 32,
    parameter remainder = 24,
	parameter num_round_bits = 12
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
	output logic[adder_size-1:0]	test_mantissa_diff,
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

	output logic[num_round_bits-1:0] rand_test,
	output logic[32+mant_width:0] cvt_reg_test

	`endif



);

	`ifdef debug_mode
	assign res = rfwd;
	assign rfwd_test = rfwd;
	assign state_test = state;
	assign frs1_test = rfrd_1;
	assign frs2_test = rfrd_2;
	assign rfrd_1_test = rfrd_1;
	assign rfrd_2_test = rfrd_2;
	assign cvt_reg_test = cvt_reg;
	`endif


    localparam exp_width                    = 8;
    localparam mant_width                   = (num_bits == 16) ? 7 : 23;
	localparam round_bits_surp 				= num_round_bits > mant_width+1 ? num_round_bits-mant_width-1 : 0;
	localparam adder_size                   = 2*mant_width+3+round_bits_surp > 32 ? 2*mant_width+3+round_bits_surp : 32;
	localparam logic[exp_width+1:0] bias    = 127;
	localparam logic signed[exp_width+1:0] neg_bias = -127;
	localparam logic[exp_width+1:0] bias_of = 128;

	localparam logic signed[exp_width+1:0] max_exp = 127;
	localparam logic signed[exp_width+1:0] min_exp = -126;
	localparam logic signed[exp_width+1:0] min_subn_exp = -127 - mant_width - remainder;

	localparam logic [7:0] cvt_min = 8'b01111110;
	localparam logic [7:0] cvt_max = 8'b10011111;

	localparam clz_width = mant_width*2+3+round_bits_surp > 32 ? mant_width*2+3+round_bits_surp : 32;



	logic [4:0] rfar_1;
	logic [4:0] rfar_2;
	logic [4:0] rfaw;

	logic [num_bits-1:0] rfrd_1;
	logic [num_bits-1:0] rfrd_2;
	logic [num_bits-1:0] rfwd;

	logic rfwe;

	`ifndef verify
	regfile #(num_bits) regfile_inst(.clk(clk), .rst(resetn), .read_addr1(rfar_1), .read_addr2(rfar_2), .write_addr(rfaw), .write_data(rfwd),
						 .write_enable(rfwe), .read_data1(rfrd_1), .read_data2(rfrd_2));
	`endif 

	
	state_t state;
	logic[31:0] fcsr;
	
	round_mode_t round_mode;

	assign round_mode = RDN;

	logic signed [adder_size-1:0] adder_op1;
	logic signed [adder_size-1:0] adder_op2;
	logic signed [adder_size-1:0] adder_res;

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
    logic op_lw;
    logic op_sw;

	logic use_dir_res;
	logic rs2_big;

	logic signed [exp_width+1:0] exp_diff;
	logic [num_bits-1:0] direct_result;

	logic [31:0] instr_latched;

	logic [32+mant_width:0] cvt_reg;
	logic [5:0] mul_counter;

	assign adder_neg = adder_res[adder_size-1];
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
		end 

    	else begin 
		(* parallel_case, full_case *)
		case(state)
			DECODE: begin 
				if(~pcpi_valid && pcpi_ready) begin pcpi_ready <= 0; end
				if(pcpi_valid && ~pcpi_ready) begin

					rfar_1 <= pcpi_insn[19:15];
					rfar_2 <= pcpi_insn[24:20];
					(* parallel_case, full_case *)
					case(pcpi_insn[31:25]) 
						//load word
						7'b0000111: begin 
							adder_op1[31:0] <= pcpi_rs1;
							adder_op2       <= {{adder_size-12{pcpi_insn[31]}}, pcpi_insn[31:20]};
							state           <= MEM;
							op_lw           <= 1;
							get_next_val    <= num_bits == 16;

						end 
						//store word
						7'b0100111: begin 
							adder_op1[31:0] <= pcpi_rs1;
							adder_op2       <= {{adder_size-12{pcpi_insn[31]}}, pcpi_insn[31:25], pcpi_insn[11:7]};
							state           <= MEM;
							op_sw           <= 1;
						
						end 
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
						end

						//conversion to integer
						7'b1100000, 7'b1101000: begin 
							`ifdef verify
							if(num_bits == 32) begin
								rfrd_1 <= op1[num_bits-1:0];
								rfrd_2 <= op2[num_bits-1:0];
							end
							`endif
							//EX stage needed if the conversion is signed and the operand is negative
							state  <= ROUND;

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

							state <= EX;
						end 
						
						//comparison operations
						7'b1010000: begin 
							op_eq <= pcpi_insn[14:12] == 2;
							op_lt <= pcpi_insn[14:12] == 1;
							op_le <= pcpi_insn[14:12] == 0;

							state <= EX;
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
            

			MEM: begin

				mem_valid <= 1; 
				mem_addr  <= adder_res[31:0]; 

				if(op_lw) begin 
					state     <= num_bits == 32 ? WB : ROUND;
				end else begin 
					mem_addr  <= adder_res[31:0];
					mem_wdata <= {rfrd_1, {num_bits == 16 ? 16 : 0{1'b0}}};
					mem_wstrb <= 4'b1111;
				end 
			end 
 

			PREALIGN: begin 
				//operands go into pre-processing for addmul (alignment)

				get_next_val <= 0;

				//calculate exponent difference (grrr comparison operation adding needless stuff need to figure out how to get rid of it !!!!!!!!!!!!!!!)
				//Not too bad since exp is small but still annoying 
				
				if(op_add) begin


					if(subn1 & subn2) begin 
						adder_op1 <= 0;
						adder_op2 <= 0;
						rs2_big <= 0;
						sub <= 0;

					end else if(rfrd_1[num_bits-2:mant_width] < rfrd_2[num_bits-2:mant_width]) begin
						adder_op2 <= subn1 ? 0 : {{adder_size - exp_width{1'b0}}, rfrd_1[num_bits-2:mant_width]};
						adder_op1 <= {{adder_size - exp_width{1'b0}}, rfrd_2[num_bits-2:mant_width]};
						rs2_big <= 1;
						sub <= 1;

					end else begin

						adder_op1 <= {{adder_size - exp_width{1'b0}}, rfrd_1[num_bits-2:mant_width]};
						adder_op2 <= subn2 ? 0 : {{adder_size - exp_width{1'b0}}, rfrd_2[num_bits-2:mant_width]};
						rs2_big <= 0;
						sub <= 1;
					end


				end else if(op_mul) begin
					adder_op1 <= subn1 ? {{adder_size-exp_width{1'b0}}, rfrd_2[num_bits-2:mant_width]} : {{adder_size-exp_width{1'b0}}, rfrd_1[num_bits-2:mant_width]};
					adder_op2 <= {{adder_size - exp_width-2{1'b0}}, bias};
					sub       <= 1;
				end 

				state <= ALIGN;
			end

			ALIGN: begin

				if(op_add) begin
						
					//mantissa difference calculated in case both are subnormal
					adder_op1 <= {{adder_size-mant_width{1'b0}}, rfrd_1[mant_width-1:0]};
					adder_op2 <= {{adder_size-mant_width{1'b0}}, rfrd_2[mant_width-1:0]};
					sub 					  <= 1;
					
					//specify add preprocessing, larger value and latch exp diff
					exp_diff <= adder_res[exp_width+1:0];

					state <= EX;

				end else if (op_mul) begin 

					unbiased_exp1 <= adder_res[exp_width+1:0];

					adder_op2 <= {{adder_size - exp_width{1'b0}}, subn1|subn2 ? lz[exp_width-1:0] : rfrd_2[num_bits-2-:exp_width]};
					adder_op1 <= {{adder_size - exp_width-2{1'b1}}, subn1|subn2 ? min_exp : neg_bias};
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

					if(~use_dir_res) begin
	
						//perform addsub
						if(adder_neg && exp_diff == 0) begin 

							adder_op2 <= {{adder_size-2*mant_width-round_bits_surp-2{1'b0}}, big_mant, {mant_width+round_bits_surp+1{1'b0}}};
							adder_op1 <= {{adder_size-2*mant_width-round_bits_surp-2{1'b0}}, little_mant};
							sign <= rfrd_2[num_bits-1];

						end else begin 
							adder_op2 <= {{adder_size-2*mant_width-round_bits_surp-2{1'b0}}, little_mant};
							adder_op1 <= {{adder_size-2*mant_width-round_bits_surp-2{1'b0}}, big_mant, {mant_width+round_bits_surp+1{1'b0}}};
							sign <= sign_out;
						end 

						//set sub flag if the signs are different
						sub <= rfrd_1[num_bits-1]^rfrd_2[num_bits-1];

						state <= NORM;

					end else begin 
						//in cases of infinity, zeroes or nans ie. no arithmetic the result is available directly
						state  <= WB;
					end


				end else if(op_mul) begin 

					sign <= sign_out;
					

					if(~use_dir_res) begin 

						if(~mul_valid) begin
							adder_op1 <= adder_res;
							adder_op2 <= {{adder_size-exp_width-2{unbiased_exp1[exp_width+1]}}, unbiased_exp1};
							sub <= 0;
							mul_counter  <= 0;
							mul_valid    <= 1;
							sub 		 <= 0;
							multiplicand <= {{mant_width+1{1'b0}}, big_mant};

						end else if(mul_counter == mant_width+1) begin 
							mul_valid    <= 0;
							state        <= NORM;

						end else if(mul_valid) begin

							if(mul_counter == 0) begin 
								if($signed(adder_res[exp_width+1:0]) < min_subn_exp) begin 
									mul_valid <= 0;
									state <= WB;
									skip_mul <= 1;
									direct_result = {sign, {num_bits-1{1'b0}}};
								end else if($signed(adder_res[exp_width+1:0]) > max_exp) begin 
									mul_valid <= 0;
									state <= WB;
									skip_mul <= 1;
									direct_result = {sign, 8'hff, {mant_width{1'b0}}};
								end else begin 
									unround_exp = adder_res[exp_width+1:0];
									skip_mul <= 0;
								end
							end


							adder_op1   <= {little_mant[mant_width+1+round_bits_surp+mul_counter] ? {multiplicand, {adder_size-2*mant_width-2{1'b0}}} : {adder_size{1'b0}}};
							adder_op2   <= mul_counter == 0 ? 0 : adder_res;

							mul_counter  <= mul_counter + 1;
							multiplicand <= multiplicand << 1;
						end 


					end else if(op_le | op_eq | op_max | op_min) begin 
						adder_op1 <= {{adder_size-num_bits+1{1'b0}}, rfrd_1[num_bits-2:0]};
						adder_op2 <= {{adder_size-num_bits+1{1'b0}}, rfrd_2[num_bits-2:0]};
						state <= WB;

						
					end else begin 
						state <= WB; 
					end
				end 
			end

			

			//shift - exponent if negative: can shift by the e
			//exponent - shift: neg: shift by exponent pos: shift by shift
			NORM: begin 
				
				if(op_add) begin

					adder_op1 <= {{adder_size-exp_width-2{1'b0}}, unnorm_exp};
					adder_op2 <= {{adder_size-exp_width-2{1'b0}}, adder_res[2*mant_width+2+round_bits_surp] ? {{exp_width+1{1'b0}}, 1'b1} : lz};

					unnorm_mant <= adder_res[2*mant_width+2+round_bits_surp:0];

					simple_norm <= adder_res[2*mant_width+2+round_bits_surp];

					sub <= ~&adder_res[adder_size-1-:1];

					lz_latched <= lz;

				end else if(op_mul) begin 
					//unnorm mant is mant width + num_round bits + 1:0 => if mant_width*2+2 > mant_width+num_round bits dont zero extend, otherwise need mant_widht + remainder - mant_width*2+2 = remainder - mant_width-2
					//unnorm_mant <= adder_res[mant_width*2+1:mant_width-remainder];
					unnorm_mant <= adder_res[mant_width*2+2+round_bits_surp:0];
					simple_norm <= adder_res[mant_width*2+2+round_bits_surp];


					if(unround_exp < min_exp) begin 
						adder_op1 <= {{adder_size-exp_width-2{1'b1}}, min_exp};
						adder_op2 <= {{adder_size-exp_width-2{1'b1}}, unround_exp};
						sub       <= 1;

					end else begin
						adder_op1   <= {{adder_size - exp_width - 2{unround_exp[exp_width+1]}}, unround_exp};
						adder_op2   <= {adder_res[adder_size-1] ? {{adder_size-exp_width-2{1'b0}}, bias_of} : {{adder_size-exp_width-2{1'b0}}, bias}};
						sub         <= 0;
					end
				end 
				

				state       <= ROUND;
			end

			ROUND: begin 
				sub <= 0;

					//Since the results show that stochastic rounding in this case is useless if there not at least 16 rounding bits, 
					//it is assumed that at least that many are used.
				if(op_lw && num_bits == 16) begin 
					//await confirmation from memory
					if(mem_ready) begin 
						adder_op1 <= {{adder_size-31{1'b0}}, mem_rdata[30:0]};
						state <= WB;
					end 

				end else if (op_cvt_to_int && norm1 && (rfrd_1[num_bits-2:mant_width] == cvt_min) && (~op_cvt_signed && ~rfrd_1[num_bits-1] || op_cvt_signed)) begin 

					adder_op1 <= {{adder_size-mant_width-1{1'b0}}, 1'b1, rfrd_1[mant_width-1:0]};
					state <= WB;

				end else if (op_cvt_to_int && norm1 && ((rfrd_1[num_bits-2] && (~op_cvt_signed && rfrd_1[num_bits-3:mant_width] < 31 || op_cvt_signed && rfrd_1[num_bits-3:mant_width]<30)) || rfrd_1[num_bits-2:mant_width] == 8'b01111111)) begin 
				
					adder_op1 <= {{adder_size- 2*(mant_width+1) - 1{1'b0}}, cvt_reg[2*mant_width+2:0]};
					state <= WB;

				end else if(op_cvt_to_int) begin
					pcpi_wr    <= 1;
					pcpi_ready <= 1;
					op_cvt_to_int <= 0;
					op_cvt		  <= 0;
					op_cvt_signed <= 0;
					state 	   <= DECODE;

					if(snan1 || qnan1 || (rfrd_1[num_bits-1] && ~op_cvt_signed)) begin 
						pcpi_rd <= op_cvt_signed ? 32'h8000_0000 : 32'h0000_0000;
					end else if(~rfrd_1[num_bits-2]) begin 
						pcpi_rd <= 32'h0000_0000;
					end else begin 
						pcpi_rd <= op_cvt_signed ? (rfrd_1[num_bits-1] ? 32'h8000_0000 : 32'h7fff_ffff) : 32'hffff_ffff;
					end 
				 

				end else if(op_cvt) begin 
					//structured in the same way as arithmetic operations
					if(pcpi_rs1 == 0 || pcpi_rs1[31]&&~op_cvt_signed) begin 
						rfwd <= 0;
						rfwe <= 1;
						pcpi_ready <= 1;
						state <= DECODE;
						op_cvt <= 0;
						op_cvt_signed <= 0;
					end else begin
						adder_op1 <= {cvt_reg[32+mant_width-:mant_width+2], {adder_size-mant_width-2{1'b0}}};
						state <= WB;
					end
				
				end else begin 
					adder_op1 <= {{adder_size-2*mant_width-round_bits_surp-3{1'b0}}, norm_mant};
					state <= WB;
				end 

				
				(* parallel_case, full_case *)
				case(round_mode)
					//rounding logic for arithmetic operations uses norm mant values 
					//rounding logic for conversion operations uses values from the conversion register 
					//rounding logic for load word operations (only for bfloat) uses values from rfrd
					RDN: begin 
						//if bfloats are being used the addition needs to be in the 7th bit of the conversion register
						//otherwise it needs to be in the 23rd bit ie. mant width
						if(op_cvt_to_int) begin 
							adder_op2 <= {{adder_size-mant_width-1{1'b0}}, cvt_reg[mant_width] /* && (cvt_reg[mant_width+1] || |cvt_reg[mant_width-1:0])*/, {mant_width{1'b0}}};
						end else if(op_cvt) begin 
							adder_op2 <= {{adder_size-mant_width-2{1'b0}}, cvt_reg[30] && (cvt_reg[31] || |cvt_reg[29:0]), {mant_width+1{1'b0}}};
						end else if(op_lw & mem_ready) begin 
							adder_op2 <= {{adder_size-mant_width-1{1'b0}}, mem_rdata[mant_width-1] && (mem_rdata[mant_width] || |mem_rdata[mant_width-2:0]), {mant_width{1'b0}}};
						end else begin
							adder_op2 <= {{adder_size-mant_width-round_bits_surp-1{1'b0}}, norm_mant[mant_width+round_bits_surp] && (norm_mant[mant_width+round_bits_surp+1] || |norm_mant[mant_width+round_bits_surp-1:0]) , {mant_width+round_bits_surp{1'b0}}};
						end 
					end
					
					RSR: 
					begin 
						if(op_cvt_to_int) begin 
							adder_op2 <= {{adder_size-mant_width-round_bits_surp-1{1'b0}}, rand_val, {num_round_bits<mant_width+1?(mant_width+1-num_round_bits):0{1'b0}}};
						end else if(op_lw & mem_ready) begin 
							adder_op2 <= {{adder_size-16{1'b0}}, rand_val[num_round_bits-1-:num_round_bits > 16 ? 16 : num_round_bits], {16-num_round_bits{1'b0}}};
						end else begin 
							adder_op2 <= {{adder_size-mant_width-round_bits_surp-1{1'b0}}, rand_val, {num_round_bits<mant_width+1?(mant_width+1-num_round_bits):0{1'b0}}}; 
						end
	
					end

					RTZ: 
					begin 
						//In the case of round towards zero cvt, lw and mul this is always handles by simply truncating, 
						//for sub, since the subtraction does not actually occur if the exponent difference is too large,
						//One must be subtracted: if the subtraction actually occured this is just a truncation, if it did not,
						//this must subtract 1
						if(op_cvt | (op_lw & mem_ready) | op_mul) begin
							adder_op2 <= 0;
						end else begin 
							adder_op2 <= use_dir_res ? {{adder_size-mant_width-round_bits_surp-1{1'b0}}, 1'b1, {mant_width+round_bits_surp{1'b0}}} : 0;
							sub		  <= 1; 
						end 
					end 
					default: begin end
				endcase
			end

			

			WB: begin 

				if(op_cvt_to_int) begin 
					pcpi_rd_intermediate = ~|cvt_reg[mant_width:0] ? cvt_reg[mant_width+1+:32] : {{32-mant_width{1'b0}}, adder_res[mant_width+1+:mant_width]};
					pcpi_rd <= op_cvt_signed && rfrd_1[num_bits-1] ? -pcpi_rd_intermediate : pcpi_rd_intermediate;
					pcpi_wr <= 1;
					pcpi_ready <= 1;
					op_cvt_to_int <= 0;
					op_cvt_signed <= 0;
					op_cvt 		  <= 0;
					state <= DECODE;

				end else begin 

					pcpi_ready <= 1;
					state <= DECODE;

					if(use_dir_res || skip_mul) begin 
						rfwd <= direct_result;
					

					end else if(op_cvt) begin 
						rfwd <= {pcpi_rs1[31], adder_res[adder_size-1] ? {unround_exp[7:0]+7'b00000001, adder_res[adder_size-2-:mant_width]} : {unround_exp[7:0], adder_res[adder_size-3-:mant_width]}};
						op_cvt_signed <= 0;
						op_cvt 		  <= 0;
					
					end else if(op_mul || op_add) begin
						//overflow detection

						if(adder_res[2*mant_width+round_bits_surp+2]) begin 
							rfwd <= unround_exp[exp_width-2:0] == 7'b1111111 ? {sign, 8'hff, {mant_width{1'b0}}} : {sign, unround_exp[7:0] + 8'h01, adder_res[2*mant_width+round_bits_surp+1-:mant_width]};
						end else begin 
							rfwd <= unround_exp[exp_width-1:0] == 8'hff ? {sign, 8'hff, {mant_width{1'b0}}} : {sign, unround_exp[7:0], adder_res[2*mant_width+round_bits_surp-:mant_width]};
						end

						op_add <= 0;
						op_mul <= 0;

					end else if(op_lw) begin 
						rfwd <= {mem_rdata[num_bits-1:0]};

						op_lw <= 0;
				
					end else if(op_eq || op_le || op_lt) begin 
						if(qnan1||qnan2||snan1||snan2) begin rfwd <= {12'h7fc, {num_bits-12{1'b0}}}; end
						else if(adder_res == 0 && op_le || op_eq) begin rfwd <= 1; end
						else if(adder_neg && (op_le || op_lt)) begin rfwd <= 1; end 
						else begin rfwd <= 0; end 

						op_le <= 0;
						op_eq <= 0;
						op_lt <= 0;
					end 
				end
			end

			default: begin end
                	
		endcase
		end
	end

	logic [31:0] pcpi_rd_intermediate;
	logic [exp_width+1:0] lz_latched;
	logic skip_mul;
	
	always_comb begin 

		//normalisation: the shift amount and normalised exponent values become available in the rounding stage: since the rounding stage is short
		//this does not affect fmax and hence the subsequent shifts are performed in this stage: this is done in the interest of using one adder 
		//for the whole fpu	


		//normalisation cases (addsub):
		// simple norm: overflow bit set all test cases should be coverred.
		// lz_latched is 0: if the result is expected sub then it must be promoted to norm and the exponent set to one otherwise stays norm and nothing else needed
		// unnorm_exp - lz is -ve: if the num is sub then the unnorm exp is zero and hence just pass through else shift by the value of unnorm exp 
		// unnorm_exp - lz = 0 & lz != 0: occurs during the subtraction of two normal numbers and the result can be made normal with unround exp = 1 and the shift = lz
		// unnorm_exp - lz is +ve: occurs during subtraction and the normalisation is lz and unround_exp = adder res

		if(state == ROUND)
		begin	

			if(op_cvt_to_int) begin 
				cvt_reg = {{32{1'b0}}, 1'b1, rfrd_1[mant_width-1:0]}<<(rfrd_1[num_bits-2:mant_width+1] == 7'b0111111 ? {5'b00000, (rfrd_1[mant_width])} : (rfrd_1[num_bits-4:mant_width]+6'b00010));
			end else if(op_cvt) begin 
				clz_in  = {op_cvt_signed && pcpi_rs1[31] ? -pcpi_rs1 : pcpi_rs1, {clz_width-32{1'b0}}};
				cvt_reg = {1'b0, op_cvt_signed && pcpi_rs1[31] ? -pcpi_rs1 : pcpi_rs1, {mant_width{1'b0}}}<<lz;
				unround_exp = lz == 31 ? 10'b0001111111 : {5'b00100, 5'b11110-lz[4:0]};



			//clz_in = adder_res[remainder+mant_width:0];

			//In the case of a subnormal result the adder in NORM is used to calculate the shift needed to noramlise the result
			//If the sum of exponents is less than the minimum exponent (-126 for 8-bit exp) - mant_width - num_round-bits -1 the
			//result will have already been handled and multiplication will not have occurred since this results in zero
			//if the exponent result is -127 and simple norm is active then simple norm is sufficient and the result is normal
			//if the exponent result is -127 or less all normalisation cases are handled by shifting by the result of the adder 
			//and setting the exponent to zero: this always results in a subnormal result.
			//sub will be active in the ROUND state if the exponent is -127 or less

			end else if(op_mul) begin 
				if(sub) begin 
					if(simple_norm && adder_res[exp_width+1:0] == 1) begin 
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
				norm_mant = unnorm_mant<<(unnorm_exp==0?0:(unnorm_exp-1));
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
		end

		if(state == ALIGN)
		begin 
			clz_in = {1'b0, subn1 ? rfrd_1[mant_width-1:0] : rfrd_2[mant_width-1:0], {clz_width-mant_width-1{1'b0}}};
		end

		if(state == NORM) begin 
			clz_in = {adder_res[2*mant_width+round_bits_surp+1:0], {clz_width-2*mant_width-round_bits_surp-2{1'b0}}};
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

		test_use_dir_res = use_dir_res;
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

logic[2*mant_width+2 + round_bits_surp:0] unnorm_mant;
logic[exp_width+1 + round_bits_surp:0] norm_exp;
logic[2*mant_width+2+round_bits_surp:0] norm_mant;

logic[mant_width:0] big_mant;
logic[2*mant_width+1 + round_bits_surp:0] little_mant;

logic sign_out;
logic sign;

logic signed [exp_width+1:0] exp_change;
logic neg_shift;
logic simple_norm;
logic [clz_width-1:0] clz_in;

addmul_pre #(round_bits_surp, num_bits, exp_width, mant_width) 
			   addsub_pre_inst(.zero1(zero1), .inf1(inf1), .subn1(subn1), .norm1(norm1), .qnan1(qnan1), .snan1(snan1),
							   .zero2(zero2), .inf2(inf2), .subn2(subn2), .norm2(norm2), .qnan2(qnan2), .snan2(snan2),
							   .rs1(pre1), .rs2(pre2), .big_mant(big_mant), .little_mant(little_mant), .direct_result(direct_result), .sign(sign_out), .use_dir_res(use_dir_res), .exp_diff(exp_diff), .unnorm_exp(unnorm_exp),
							   .zero(zero), .inf(inf), .subn(subn), .norm(norm), .qnan(qnan), .snan(snan), .mul(op_mul), .rs2_big(rs2_big), .lz(lz));


logic [num_round_bits-1:0] rand_val;
logic get_next_val;

logic [exp_width+1:0] lz;

rng #(num_round_bits) rng_inst(.clk(clk), .resetn(resetn), .get_next_val(get_next_val), .out(rand_val));


clz #(clz_width, exp_width) clz_inst(.in(clz_in), .lz(lz));





endmodule;




`endif 
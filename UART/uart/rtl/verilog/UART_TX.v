/********************************************************************************
 *																				*
 *		ID_CP.v  Ver 0.1														*
 *																				*
 *		Designed by	Yoon Dong Joon                                              *
 *																				*
 ********************************************************************************
 *																				*
 *		Support Verilog 2001 Syntax												*
 *																				*
 *		Update history : 2012.07.25	 original authored (Ver.0.1)				*
 *																				*		
 *		Instruction Decode controlpath module of ARM Compatible processor		*
 *																				*
 ********************************************************************************/	

`default_nettype	none

module ID_CP(
	//---------------------------------------------------------------------------
	//	input signals
	//---------------------------------------------------------------------------
	input	wire			VALID,
	input	wire			INT_DETECT,

	input	wire	[31:0]	INST,
	// instruction start
	input	wire			INST_START,
	// The 'NEW' prefix means updated value.
	input	wire	[3:0]	NEW_RM_ADDR,
	input	wire	[3:0]	NEW_RSRD_ADDR,
	input	wire	[15:0]	NEW_PAT,
	// Last request for LDM/STM
	input 	wire			NEW_LDMSTM_REQ,

	//---------------------------------------------------------------------------
	//	output signals
	//---------------------------------------------------------------------------

	/******************************	To IF ***********************************/
	output	wire	[2:0]	cSEL_PC,
	output	wire			cIREQ,	

	// freeze signal when multicycle
	output	wire			F_PIPE_EN,

	/******************************	To ID ***********************************/
	// operand selection signals
	output	wire			cSEL_X,
	output	wire	[5:0]	cSEL_Y,
	output	wire	[3:0]	cSEL_Z, 
	output	wire			cSTEP_LAST,	

	// shift amount
	output	wire	[4:0]	SHIMM,
	// immediate
	output	wire	[11:0]	IMM12,

	// To feed id_cp itself
	output	wire	[3:0]	NXT_RM_ADDR,
	output	wire	[3:0]	NXT_RSRD_ADDR,
	output	wire	[15:0]	NXT_PAT,
	output	wire			NXT_PAT_EN,
	output	wire			NXT_LDMSTM_REQ,
	
	// freeze signal when multicycle
	output	wire			D_PIPE_EN,

	/******************************	To EX1 **********************************/
	output	wire		 	cFREEZE_PPD,	
	output	wire			cROR,	
	output	wire			cSWP,
	output	wire			cSEL_BASE_ADDR,	
	output	wire	[2:0]	cSEL_INDEX_ADDR,
	output	wire	[1:0]	cST_SIZE,	
	output	wire			cLDM_STM,	
	output	wire			cBR,	
	output	wire			cUMULT,	
	output	wire	[3:0]	cSEL_PSR,	
	output	wire			cT_VAL_SEL,	
	output	wire			cT_UPDATE,
	output	wire			cDREQ,	
	output	wire			cALU,
	output	wire			cSR,
	output  wire			cNRW,

	output	wire	[28:0]	BR_INFO,
	output	wire	[1:0]	SHTYPE,
	output	wire	[3:0]	COND,
	output	wire	[3:0]	PSR_MASK,
	output	wire			DEST_RD15,
	output	wire			IR_P,
	output	wire			IR_U,
	output	wire			IR_R,
	output	wire			IR_S,

	output	wire	[6:0]	RLISTX4,
	output	wire			SWP_ON,
	output	wire			LDMSTM_LAST,

	/******************************	To EX2 **********************************/
	output	wire	[5:0]	cSEL_A,	
	output	wire	[2:0]	cSEL_RdLo,	
	output	wire			cSEL_B,	
	output	wire	[3:0]	cALU_OP,	
	output	wire	[2:0]	cSEL_ALU_X,	
	output	wire	[2:0]	cSEL_ALU_Y,	
	output	wire	[2:0]	cSEL_ALU_C,	
	output	wire	[2:0]	cSEL_NZ,	
	output	wire		 	cSEL_SHC,
	output	wire	[3:0]	cNZCV_UPDATE,	
	output	wire		 	cLD_SIGN,	
	output	wire	[1:0]	cLD_SIZE,	

	/******************************	To WB **********************************/
	output	wire		 	cEN_A,	
	output	wire		 	cEN_B,	
	output	wire		 	cEN_CPSR,	
	output	wire			cEN_SPSR,	

	output	wire		 	cSEL_BL,	

	output	wire	[3:0]	WDA_ADDR,
	output	wire	[3:0]	WDB_ADDR,

	/******************************	To REGISTER FILE **************************/
	output	wire	[3:0]	GPR_RN_ADDR,
	output	wire	[3:0]	GPR_RM_ADDR,
	output	wire	[3:0]	GPR_RSRD_ADDR,

	/******************************	To next stage *****************************/
	output	wire			ATOMIC,
	output	wire			INVD,
	output	wire			SWI,

	output	wire			VALID_OUT
);

//-------------------------------------------------------------------------------
//	internal signals
//-------------------------------------------------------------------------------
// decoding signals
wire	[3:0]	DEC_RD_ADDR;
wire	[3:0]	DEC_RN_ADDR;
wire	[3:0]	DEC_RM_ADDR;
wire	[3:0]	DEC_RS_ADDR;
wire	[23:0]	DEC_SIMM24;
wire	[11:0]	DEC_IMM12;  
wire			DEC_BLX_H;	   
wire	[1:0]	DEC_SHTYPE; 
wire	[4:0]	DEC_SHIMM;
wire	[15:0]	DEC_RLIST;  
wire	[3:0]	DEC_COND; 
wire	[3:0]	DEC_PSR_MASK;
wire			DEC_IR_P;	
wire			DEC_IR_U;	
wire			DEC_IR_R;	
wire			DEC_IR_S;	
wire			DEC_IR_W;	
wire			DEC_ATOMIC;
wire			DEC_SWI;	
wire			DEC_MULA_ON;
wire			DEC_MULL_ON;
wire			DEC_DEST_RD15;
wire			DEC_COND_ALL;
wire			DEC_RSRD_ADDR_SEL;
wire			DEC_LDST_SHAMT_ZERO; 
wire	[6:0]	DEC_RLISTX4; 

// remain intenal signals
wire	[3:0]	rsrd_addr;
wire			ldm_stm_first;
wire	[15:0]	ldm_stm_pat;
wire	[3:0]	ldm_stm_addr;
wire			ldm_stm_full;
wire	[4:0]	rlist_sum;
wire	[1:0]	c_en_cpsr_cmd;
wire	[3:0]	cSEL_BR;
wire			cLDST;
wire			ldst_rlist_last;

wire			c_dreq_cmd;
wire			c_en_cpsr_temp;
wire			c_en_spsr_cmd;
wire			c_en_a_cmd;
wire			c_en_b_cmd;
wire			c_sel_bl_cmd;

//-------------------------------------------------------------------------------
//	Decoding stage
//-------------------------------------------------------------------------------
assign	DEC_RD_ADDR		=	INST[15:12]; // RdLo, Rn for MUL, MLA
assign	DEC_RN_ADDR		=	INST[19:16]; // RdHi
assign	DEC_RM_ADDR		=	INST[3:0];
assign	DEC_RS_ADDR		=	INST[11:8];
assign	DEC_SIMM24		=	INST[23:0];
assign	DEC_IMM12		=	INST[11:0];
assign	DEC_BLX_H		=	INST[24];
assign	DEC_SHTYPE		=	INST[6:5];
assign	DEC_SHIMM		=	INST[11:7];
assign	DEC_RLIST		=	INST[15:0];
assign	DEC_COND		=	INST[31:28];
assign	DEC_PSR_MASK	=	INST[19:16];
assign	DEC_IR_P		=	INST[24];
assign	DEC_IR_U		=	INST[23];
assign	DEC_IR_R		=	INST[22];
assign	DEC_IR_S		= 	INST[20];
assign	DEC_IR_W		= 	INST[21];

//	SWAP detection
assign	DEC_ATOMIC		=	(INST[27:24]==4'b0001) & (INST[7:4] == 4'b1001);
assign	DEC_SWI			=	(& INST[27:24]);

// RM and RSRD address should be changed to RdLo and RdHi for Accumulate operation
// MUL, MLA detection
assign	DEC_MULA_ON		=	(INST[27:23]==5'b00000) & (INST[7:4]==4'b1001) & (INST[31:28] != 4'b1111);
// Multiply long, Multiply and accumulate long detection
assign	DEC_MULL_ON		=	(INST[27:23]==5'b00001) & (INST[7:4]==4'b1001) & (INST[31:28] != 4'b1111);
assign	DEC_DEST_RD15	=	(& INST[15:12]);
assign	DEC_COND_ALL	=	(& INST[31:28]);

// Store instruction detection
// 0: RS addr
// 1: RD addr
assign	DEC_RSRD_ADDR_SEL = ((INST[27:26]==2'b01) & ~INST[20]) |							// STR, STRB
							((INST[27:25]==3'b000) & ~INST[20] & (INST[7:4]==4'b1011));// | 	// STRH
		//					((INST[27:25]==3'b100) & ~INST[20]) ; 							// STM

assign	DEC_LDST_SHAMT_ZERO = ~( | INST[11:7]);

assign	rlist_sum = {4'b0000, INST[15]} + 
					{4'b0000, INST[14]} +
					{4'b0000, INST[13]} +
					{4'b0000, INST[12]} + 
					{4'b0000, INST[11]} +
					{4'b0000, INST[10]} +
					{4'b0000, INST[9]} +
					{4'b0000, INST[8]} + 
					{4'b0000, INST[7]} + 
					{4'b0000, INST[6]} + 
					{4'b0000, INST[5]} +
					{4'b0000, INST[4]} + 
					{4'b0000, INST[3]} + 
					{4'b0000, INST[2]} + 
					{4'b0000, INST[1]} + 
					{4'b0000, INST[0]};

assign	DEC_RLISTX4 = {rlist_sum, 2'd0};

// outputs receive direct decoding result 
assign	SHIMM			= DEC_SHIMM;
assign	IMM12			= DEC_IMM12;
assign	SHTYPE			= DEC_SHTYPE;
assign	COND			= DEC_COND;
assign	PSR_MASK		= DEC_PSR_MASK;	
assign	DEST_RD15		= DEC_DEST_RD15;	
assign	IR_P			= DEC_IR_P;			
assign	IR_U			= DEC_IR_U;		
assign	IR_R			= DEC_IR_R;		
assign	IR_S			= DEC_IR_S;		
assign	RLISTX4			= DEC_RLISTX4;		
assign	ATOMIC			= DEC_ATOMIC;
assign	SWI				= DEC_SWI;


//-------------------------------------------------------------------------------
//	Control signal generation
//-------------------------------------------------------------------------------
// Need signal for CMD except IR is like below
//	LDST_SHAMT_ZERO	- FROM Decoding stage
//	COND_ALL		- FROM Decoding stage
//	RLIST_LAST		- From input
//	INSTR_START		- From input

assign	ldst_rlist_last	= (INST_START)?	1'b0 : ~NEW_LDMSTM_REQ; 

CMD_ID	ID_CP_CMD (
		// inputs
		.OPCODE1				(INST[27:21]),	
		.OPCODE2				(INST[7:4]),	
		.ALU_LDST_I				(INST[25]),	
		.LDST_P					(INST[24]),	
		.ALU_LDST_SHIMM_REG		(INST[4]),	
		.LDST_B_I_S				(INST[22]),	
		.LDST_W					(INST[21]),	
		.LDST_L					(INST[20]),	
		.LDST_SHAMT_ZERO		(DEC_LDST_SHAMT_ZERO),
		.LDST_SEL				(INST[15]),	
		.LDST_RLIST_LAST		(ldst_rlist_last),
		.B_20					(INST[20]),	
		.B_L					(INST[24]),	
		.B_COND_ALL_ONE			(DEC_COND_ALL),	
		.SR_R					(INST[22]),	
		.SR_20					(INST[20]),	
		.MISC_20				(INST[20]),	
		.INSTR_START			(INST_START),	

		// outputs
		.cSEL_PC 				(cSEL_PC),
		.cIREQ   				(cIREQ),		
		.cSTEP_LAST				(cSTEP_LAST),
		.cSEL_X  				(cSEL_X),	
		.cSEL_Y  				(cSEL_Y),	
		.cSEL_Z  				(cSEL_Z),	
		.cFREEZE_PPD			(cFREEZE_PPD),	
		.cROR					(cROR),	
		.cSWP					(cSWP),	
		.cSEL_BASE_ADDR			(cSEL_BASE_ADDR),	
		.cSEL_INDEX_ADDR		(cSEL_INDEX_ADDR),	
		.cST_SIZE				(cST_SIZE),	
		.cLDMSTM				(cLDM_STM),	
		.cBR	 				(cBR),	
		.cUMULT  				(cUMULT),
		.cSEL_PSR				(cSEL_PSR),	
		.cT_VAL_SEL				(cT_VAL_SEL),	
		.cT_UPDATE				(cT_UPDATE),	
		.cDREQ    				(c_dreq_cmd),
		.cALU    				(cALU),
		.cSR	  				(cSR),
		.cNRW					(cNRW),
		.cSEL_A  				(cSEL_A),	
		.cSEL_RdLo				(cSEL_RdLo),	
		.cSEL_B  				(cSEL_B),	
		.cALU_OP 				(cALU_OP),	
		.cSEL_ALU_X				(cSEL_ALU_X),	
		.cSEL_ALU_Y				(cSEL_ALU_Y),
		.cSEL_ALU_C				(cSEL_ALU_C),	
		.cSEL_NZ 				(cSEL_NZ),	
		.cSEL_SHC				(cSEL_SHC),	
		.cNZCV_UPDATE			(cNZCV_UPDATE),	
		.cLD_SIGN				(cLD_SIGN),	
		.cLD_SIZE				(cLD_SIZE),	
		.cEN_CPSR				(c_en_cpsr_cmd),	
		.cEN_SPSR				(c_en_spsr_cmd),	
		.cSEL_BR 				(cSEL_BR),
		.cEN_A   				(c_en_a_cmd),	
		.cEN_B   				(c_en_b_cmd),	
		.cLDST					(cLDST),
		.cSEL_BL 				(c_sel_bl_cmd),

		.UND_INST				(INVD)
);

//-------------------------------------------------------------------------------
//	KILL control outputs (because interrupt or kill)
//-------------------------------------------------------------------------------
assign	cDREQ		= c_dreq_cmd	& VALID_OUT;
assign	cEN_CPSR	= c_en_cpsr_temp & VALID_OUT & ~(DEC_IR_S & DEC_DEST_RD15 & cALU);
assign	cEN_SPSR	= c_en_spsr_cmd & VALID_OUT;
assign	cEN_A		= c_en_a_cmd	& VALID_OUT;
assign	cEN_B		= c_en_b_cmd	& VALID_OUT;
assign	cSEL_BL		= c_sel_bl_cmd	& VALID_OUT;

assign	VALID_OUT	= VALID & ~INT_DETECT;

//-------------------------------------------------------------------------------
//	GPR READ, WRITE ADDRESS GENERATION
//-------------------------------------------------------------------------------
// For LDM & STM, RSRD address should be changed at each cycle
// For UMLAL & SMLAL, RM and RSRD address should be changed to RdLo and RdHi address after 1st cycle
assign	rsrd_addr		= (DEC_RSRD_ADDR_SEL)?		DEC_RD_ADDR : DEC_RS_ADDR;
 
assign	GPR_RN_ADDR		= (DEC_MULA_ON)?			DEC_RD_ADDR : DEC_RN_ADDR;
assign	GPR_RM_ADDR		= (INST_START)?				DEC_RM_ADDR : NEW_RM_ADDR;
assign	GPR_RSRD_ADDR	= (INST_START)?				rsrd_addr	: NEW_RSRD_ADDR;

assign	NXT_RM_ADDR		= (DEC_MULL_ON)?			DEC_RD_ADDR : DEC_RM_ADDR;

MUX3to1 #(4) NXT_RSRD_ADDR_SEL_MUX(
	.DI0(rsrd_addr),
	.DI1(DEC_RN_ADDR),		// RdHi address
	.DI2(ldm_stm_addr),		// LDM,STM address
	.SEL({ cLDM_STM, DEC_MULL_ON, ~(DEC_MULL_ON | cLDM_STM) }),
	.DO (NXT_RSRD_ADDR)
);

// W_DA port can select one of the below 2 sources
// Rd(Rd of ALU op, RdLo of MLAL), Rn(base register update, Rd of MUL & MLA)
assign	WDA_ADDR		= ( (cLDST & (DEC_IR_W | (~DEC_IR_P & ~DEC_IR_W)) ) | DEC_MULA_ON)?	DEC_RN_ADDR : DEC_RD_ADDR;
// W_DB port can select one of the below 3 sources
// Rn(RdHi of MLAL), Ri(LDM destination), Rd(LDR)
assign	WDB_ADDR		= (DEC_MULL_ON)?			DEC_RN_ADDR	:		// for MLAL
						  (cLDM_STM)?				NEW_RSRD_ADDR :		// for LDM
													DEC_RD_ADDR;

//-------------------------------------------------------------------------------
//	PATTERN CONTROL
//-------------------------------------------------------------------------------
assign			ldm_stm_first	= cLDM_STM & INST_START;
assign			ldm_stm_pat		= (ldm_stm_first)? DEC_RLIST : NEW_PAT;

PAT_CTRL		PAT_COUNT (
					.PAT		(ldm_stm_pat),
					.COUNT		(ldm_stm_addr),
					.FULL		(ldm_stm_full),
					.NEXT_PAT	(NXT_PAT)
				);

assign	NXT_PAT_EN				= cLDM_STM & ~ldm_stm_full;
assign	NXT_LDMSTM_REQ			= cLDM_STM & ~ldm_stm_full;

//-------------------------------------------------------------------------------
//	BRANCH INFORMATION
//-------------------------------------------------------------------------------
assign	BR_INFO = {DEC_BLX_H, DEC_SIMM24, cSEL_BR};		

//-------------------------------------------------------------------------------
//	ETC
//-------------------------------------------------------------------------------
//	CPSR enable signal generation
assign	c_en_cpsr_temp	=	(c_en_cpsr_cmd==2'b00)?	1'b0 :	
						(c_en_cpsr_cmd==2'b01)?	1'b1 :	
						(c_en_cpsr_cmd==2'b10)?	DEC_IR_S : 1'b0;

//	SWP, SWPB instruction detection
assign	SWP_ON			= DEC_ATOMIC;

//	Freeze signal when multicycle
assign	F_PIPE_EN		= cSTEP_LAST;
assign	D_PIPE_EN		= cSTEP_LAST;

// LDM, STM last flag
assign	LDMSTM_LAST	= ldst_rlist_last;

endmodule

//-------------------------------------------------------------------------------
//	PAT_CTRL: LEADING ONE DETECTOR FOR LDM/STM
//-------------------------------------------------------------------------------
module PAT_CTRL(
	input	wire	[15:0]		PAT,
	output	reg		[3:0]		COUNT,
	output	wire				FULL,
	output	wire	[15:0]		NEXT_PAT
);

	// ALL ZERO CASE (MEANS NOTHING TO LOAD/STORE)
	assign	FULL	= ~(| PAT);

	// COUNTS THE NUMBER OF ZEROS
	always @ *
	begin
		casex (PAT)
			16'bxxxxxxxxxxxxxxx1:	COUNT = 4'h0;
			16'bxxxxxxxxxxxxxx10:	COUNT = 4'h1;
			16'bxxxxxxxxxxxxx100:	COUNT = 4'h2;
			16'bxxxxxxxxxxxx1000:	COUNT = 4'h3;
			16'bxxxxxxxxxxx10000:	COUNT = 4'h4;
			16'bxxxxxxxxxx100000:	COUNT = 4'h5;
			16'bxxxxxxxxx1000000:	COUNT = 4'h6;
			16'bxxxxxxxx10000000:	COUNT = 4'h7;
			16'bxxxxxxx100000000:	COUNT = 4'h8;
			16'bxxxxxx1000000000:	COUNT = 4'h9;
			16'bxxxxx10000000000:	COUNT = 4'ha;
			16'bxxxx100000000000:	COUNT = 4'hb;
			16'bxxx1000000000000:	COUNT = 4'hc;
			16'bxx10000000000000:	COUNT = 4'hd;
			16'bx100000000000000:	COUNT = 4'he;
			16'b1000000000000000:	COUNT = 4'hf;
			16'b0000000000000000:	COUNT = 4'bxxxx;
		endcase
	end

	// MASK FOR NEXT PATTERN
	reg		[15:0]	mask;

	always @ *
	begin
		casex (PAT)
			16'bxxxxxxxxxxxxxxx1:	mask = 16'b1111111111111110;
			16'bxxxxxxxxxxxxxx10:	mask = 16'b111111111111110x;
			16'bxxxxxxxxxxxxx100:	mask = 16'b11111111111110xx;
			16'bxxxxxxxxxxxx1000:	mask = 16'b1111111111110xxx;
			16'bxxxxxxxxxxx10000:	mask = 16'b111111111110xxxx;
			16'bxxxxxxxxxx100000:	mask = 16'b11111111110xxxxx;
			16'bxxxxxxxxx1000000:	mask = 16'b1111111110xxxxxx;
			16'bxxxxxxxx10000000:	mask = 16'b111111110xxxxxxx;
			16'bxxxxxxx100000000:	mask = 16'b11111110xxxxxxxx;
			16'bxxxxxx1000000000:	mask = 16'b1111110xxxxxxxxx;
			16'bxxxxx10000000000:	mask = 16'b111110xxxxxxxxxx;
			16'bxxxx100000000000:	mask = 16'b11110xxxxxxxxxxx;
			16'bxxx1000000000000:	mask = 16'b1110xxxxxxxxxxxx;
			16'bxx10000000000000:	mask = 16'b110xxxxxxxxxxxxx;
			16'bx100000000000000:	mask = 16'b10xxxxxxxxxxxxxx;
			16'b1000000000000000:	mask = 16'b0xxxxxxxxxxxxxxx;
			16'b0000000000000000:	mask = 16'bxxxxxxxxxxxxxxxx;
		endcase
	end

//	wire	[15:0]	mask	= (16'h0001 << COUNT);

	assign	NEXT_PAT	= PAT & mask;
endmodule

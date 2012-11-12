/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                           Core-A Processor TOP Module                       *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module CoreA (
	input	wire				CLK,		// EXTERNAL CLOCK
	input	wire				RST,		// ASYNC. RESET

	input	wire				INT,		// EXT. INTERRUPT
	output	wire				INT_ACK,	// EXT. INTERRUPT ACK.

	output	wire				IREAD,		// IMEM. REQUEST
	output	wire	[29:0]		IADDR,		// IMEM. ADDRESS
	input	wire	[31:0]		INSTR,		// INSTRUCTION
	input	wire				IFAULT,		// IMMU FAULT
	input	wire				IMEM_DED,	// IMEM. DED
	input	wire				nIWAIT,		// IMEM. READY

	output	wire				DREQ,		// DMEM. REQUEST
	output	wire	[31:0]		DADDR,		// DMEM. ADDRESS
	output	wire				DRW,		// DMEM. READ/WRITE
	output	wire				DLOCK,		// DMEM. BUS LOCK
	output	wire	[1:0]		DTYPE,		// DMEM. REQUEST TYPE
	output	wire				DMODE,		// OPERATING MODE
	output	wire	[1:0]		DSIZE,		// DMEM. SIZE
	output	wire	[31:0]		DWDATA,		// DMEM. WRITE DATA
	input	wire	[31:0]		DRDATA,		// DMEM. READ DATA
	input	wire				DFAULT,		// DMMU FAULT
	input	wire				DMEM_DED,	// DMEM. DED
	input	wire				nDWAIT,		// DMEM. READY
	input	wire				CPINT		// COPROCESSOR INTERRUPT

);

	wire	clk_en;
	//wire	latched_clk_en;
	wire	ireq;
	wire	dreq;
	wire	latched_int;
	wire	CLK_GATED;

	assign	clk_en = nIWAIT & nDWAIT;
	assign	IREAD = ireq & clk_en;
	assign	DREQ = dreq & clk_en;
	//assign	IREAD = ireq & latched_clk_en;
	//assign	DREQ = dreq & latched_clk_en;

	//LatchN		CLK_EN_LATCH (
	//	.CLK(CLK),
	//	.D(clk_en),
	//	.Q(latched_clk_en)
	//);

	SyncRegN	#(1)	INT_FF(
		.CLK(CLK),
		.D(INT),
		.Q(latched_int)
	);
	
	ClockGate CLOCK_GATE(
		.en(clk_en),
		.CLK(CLK),
		.gCLK(CLK_GATED)
	);

	GatedCoreA	INTERNAL_COREA (
		.CLK(CLK_GATED),		// Gated clock
		.RST(RST),
		.INT(latched_int),
		.INT_ACK(INT_ACK),
		.IREQ(ireq),
		.IADDR(IADDR),
		.IFAULT(IFAULT),
		.IMEM_DED(IMEM_DED),
		.INSTR(INSTR),
		.DREQ(dreq),
		.DTYPE(DTYPE),
		.DADDR(DADDR),
		.DRW(DRW),
		.DLOCK(DLOCK),
		.DMODE(DMODE),
		.DSIZE(DSIZE),
		.DWDATA(DWDATA),
		.DFAULT(DFAULT),
		.DMEM_DED(DMEM_DED),
		.DRDATA(DRDATA),
		.CPINT(CPINT)
	);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                           Core-A Processor TOP Module                       *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module GatedCoreA (
	input	wire				CLK,		// Gated clock
	input	wire				RST,

	// External Interrupt
	input	wire				INT,
	output	wire				INT_ACK,

	// Instruction Memory
	output	wire				IREQ,
	output	wire	[29:0]		IADDR,
	input	wire				IFAULT,
	input	wire				IMEM_DED,
	input	wire	[31:0]		INSTR,

	// Data Memory
	output	wire				DREQ,
	output	wire	[1:0]		DTYPE,
	output	wire	[31:0]		DADDR,
	output	wire				DRW,
	output	wire				DLOCK,
	output	wire				DMODE,
	output	wire	[1:0]		DSIZE,		// 00 : Byte	01 : Half-Word		10 : Word
	output	wire	[31:0]		DWDATA,
	input	wire				DFAULT,
	input	wire				DMEM_DED,
	input	wire	[31:0]		DRDATA,
	input	wire				CPINT
);

	//---------------------------------------------------------------
	//		FOR PIPELINE REG
	//---------------------------------------------------------------
	wire		f_pipe_en;
	wire		d_pipe_en;

	wire	[29:0]	f_pc;
	wire	[29:0]	d_pc;
	wire	[29:0]	e_pc;
	wire	[29:0]	m_pc;
	wire	[29:0]	w_pc;

	wire	[31:0]	ir_di;
	wire	[31:0]	ir;
	wire	[31:0]	e_ir;

	wire	[3:0]	nx_ra_di;
	wire	[3:0]	nx_ra;
	wire	[3:0]	ny_ra_di;
	wire	[3:0]	ny_ra;

	wire	[3:0]	gpr_x_ra;
	wire	[3:0]	gpr_y_ra;
	wire	[31:0]	gpr_x_rd;
	wire	[31:0]	gpr_y_rd;
	wire		gpr_a_wen;
	wire		gpr_b_wen;
	wire	[3:0]	gpr_a_wa;
	wire	[3:0]	gpr_b_wa;
	wire	[31:0]	gpr_a_wd;

	//---------------------------------------------------------------
	//		FOR PIPELINE REG (DATAPATH)
	//---------------------------------------------------------------
	wire		ps_we;
	wire	[31:0]	ps_di;
	wire	[31:0]	ps;

	wire		e_x_we;
	wire	[31:0]	e_x_di;
	wire	[31:0]	e_x;

	wire		e_y_we;
	wire	[31:0]	e_y_di;
	wire	[31:0]	e_y;

	wire		e_z_we;
	wire	[4:0]	e_z_di;
	wire	[4:0]	e_z;

	wire		e_pat_we;
	wire	[15:0]	e_pat_di;
	wire	[15:0]	e_pat;

	wire		m_da_we;
	wire	[31:0]	m_da_di;
	wire	[31:0]	m_da;

	wire		m_acc_we;
	wire	[63:0]	m_acc_di;
	wire	[63:0]	m_acc;

	wire		m_ppd_we;
	wire	[63:0]	m_ppd1_di;
	wire	[63:0]	m_ppd1;
	wire	[63:0]	m_ppd2_di;
	wire	[63:0]	m_ppd2;

	wire		m_nzcv_we;
	wire	[3:0]	m_nzcv_di;
	wire	[3:0]	m_nzcv;

	wire		m_shamt_we;
	wire	[1:0]	m_shamt_di;
	wire	[1:0]	m_shamt;

	wire		w_da_we;
	wire	[31:0]	w_da_di;
	wire	[31:0]	w_da;

	wire		w_db_we;
	wire	[31:0]	w_db_di;
	wire	[31:0]	w_db;

	wire		w_nzcv_we;
	wire	[3:0]	w_nzcv_di;
	wire	[3:0]	w_nzcv;

	wire		p_da_we;
	wire	[31:0]	p_da;

	wire		p_db_we;
	wire	[31:0]	p_db;

	//---------------------------------------------------------------
	//		FOR PIPELINE REG (CONTROL)
	//---------------------------------------------------------------
	wire		inst_start;
	wire		d_valid;

	wire		e_valid_di;
	wire		e_valid;

	wire	[1:0]	e_cmd_eop_di;
	wire	[1:0]	e_cmd_eop;

	wire	[16:0]	e_cmd_alu_di;
	wire	[16:0]	e_cmd_alu;

	wire	[7:0]	e_cmd_shift_di;
	wire	[7:0]	e_cmd_shift;

	wire	[4:0]	e_cmd_mul_di;
	wire	[4:0]	e_cmd_mul;

	wire	[9:0]	e_cmd_mem_di;
	wire	[9:0]	e_cmd_mem;

	wire	[1:0]	e_cmd_mop_di;
	wire	[1:0]	e_cmd_mop;

	wire	[4:0]	e_cmd_da_di;
	wire	[4:0]	e_cmd_da;

	wire	[4:0]	e_cmd_db_di;
	wire	[4:0]	e_cmd_db;

	wire	[2:0]	e_cmd_ps_di;
	wire	[2:0]	e_cmd_ps;

	wire	[2:0]	e_cmd_nzcv_di;
	wire	[2:0]	e_cmd_nzcv;

	wire		m_valid_di;
	wire		m_valid;

	wire	[3:0]	m_cmd_mem_di;
	wire	[3:0]	m_cmd_mem;

	wire	[1:0]	m_cmd_mop_di;
	wire	[1:0]	m_cmd_mop;

	wire	[4:0]	m_cmd_da_di;
	wire	[4:0]	m_cmd_da;

	wire	[4:0]	m_cmd_db_di;
	wire	[4:0]	m_cmd_db;

	wire	[2:0]	m_cmd_ps_di;
	wire	[2:0]	m_cmd_ps;

	wire		w_valid_di;
	wire		w_valid;

	wire	[4:0]	w_cmd_da_di;
	wire	[4:0]	w_cmd_da;

	wire	[4:0]	w_cmd_db_di;
	wire	[4:0]	w_cmd_db;

	wire	[2:0]	w_cmd_ps_di;
	wire	[2:0]	w_cmd_ps;


	//---------------------------------------------------------------
	//		IF STAGE
	//---------------------------------------------------------------
	wire	[29:0]	pc_offset;
	wire	[29:0]	pc_target;
	wire	[2:0]	int_vec;
	wire	[3:0]	pc_sel;
	wire		ir_nop;

	//---------------------------------------------------------------
	//		ID STAGE
	//---------------------------------------------------------------
	wire	[4:0]	cnt_count;
	wire		cnt_zero;

	wire		mm_req;
	wire		mm_req_di;

	// CMD_GEN
	wire		cg_last;
	wire		cg_ir;
	wire	[2:0]	cg_br;
	wire	[1:0]	cg_pat;
	wire		cg_nx;
	wire	[2:0]	cg_ny;
	wire	[2:0]	cg_ex;
	wire		cg_ps_x;
	wire		cg_fwd_x;
	wire	[2:0]	cg_ey;
	wire	[1:0]	cg_fwd_y;
	wire	[5:0]	cg_eop;
	wire		cg_wda;
	wire		cg_wdb;
	wire	[3:0]	cg_mul;
	wire	[5:0]	cg_mem;
	wire	[2:0]	cg_ps;
	wire	[3:0]	cg_dst_a;
	wire	[3:0]	cg_dst_b;

	// DECODER
	wire		ci_do_shift;
	wire		ci_n;
	wire	[3:0]	ci_r1;
	wire	[3:0]	ci_r2;
	wire	[3:0]	ci_r3;
	wire	[3:0]	ci_r4;
	wire		ci_sign;
	wire	[1:0]	ci_size;
	wire		ci_u;
	wire	[1:0]	ci_cut;
	wire		ci_use_condz;
	wire		ci_cond_inst;
	wire	[3:0]	ci_alu;
	wire	[2:0]	ci_shift;
	wire	[4:0]	ci_shamt;
	wire	[7:0]	ci_imm;
	wire		ci_umult;
	wire		ci_atomic;
	wire		ci_invd;
	wire		ci_swi;
	wire	[15:0]	ci_pat;

	wire		d_cond_true;
	wire		d_pat_sel;
	wire	[3:0]	d_reg_sel;
	wire	[7:0]	d_imm_sel;
	wire		d_cond_sel;
	wire	[4:0]	d_shamt;
	wire	[2:0]	e_x_sel;
	wire	[2:0]	e_y_sel;

	//---------------------------------------------------------------
	//		EX STAGE
	//---------------------------------------------------------------
	wire	[3:0]	e_nzcv;
	wire		e_nzcv_sel;
	wire	[5:0]	e_op_x_sel_di;
	wire	[5:0]	e_op_y_sel_di;
	wire	[5:0]	e_op_x_sel;
	wire	[5:0]	e_op_y_sel;

	wire	[3:0]	e_alu_op;
	wire		e_alu_x;
	wire	[7:0]	e_alu_y;
	wire	[2:0]	e_alu_c;
	wire		e_alu_ps_sel;
	wire		e_shamt_sel;
	wire		e_shift_dir;
	wire	[4:0]	e_shift_hi;
	wire		e_shift_lo;
	wire		e_umult;
	wire		e_acc_hi_sel;
	wire		e_acc_lo_sel;
	wire		e_nz_update;
	wire		e_c_update;
	wire		e_v_update;
	wire	[1:0]	e_msize;
	wire	[2:0]	e_maddr_sel;
	wire		m_da_sel;

	//---------------------------------------------------------------
	//		MEM STAGE
	//---------------------------------------------------------------
	wire		m_msign;
	wire	[1:0]	m_msize;
	wire		w_da_sel;
	wire		w_db_sel;

	//---------------------------------------------------------------
	//		WB STAGE
	//---------------------------------------------------------------
	wire		w_gpr_a_sel;
	wire	[3:0]	w_ps_sel;

	//---------------------------------------------------------------
	//		INTERRUPT CONTROL
	//---------------------------------------------------------------
	wire		int_detect;
	wire		dont_mreq;

	wire       	e_udi, m_udi, w_udi;
	wire		gpr_ded_x, gpr_ded_y, e_rde_x, e_rde_y, m_rde, w_rde;
	wire		d_swi, e_swi, m_swi, w_swi;
	wire		d_imf, e_imf, m_imf, w_imf;
	wire		d_ide, e_ide, m_ide, w_ide;
	wire		d_ext, e_ext, m_ext, w_ext;
	wire		w_dmf;
	wire		w_dde;
	wire		w_cpint;
	wire	    w_rst;
	wire	    m_mreq, m_cpreq;


	//---------------------------------------------------------------
	//		IF STAGE
	//---------------------------------------------------------------
	// CONTROLPATH
	PipeReg	#(30)		F_PC_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(f_pipe_en),
							.D		(IADDR),
							.Q		(f_pc)
						);

	IF_DP				DATAPATH_IF (
							.F_PC		(f_pc),
							// FROM ID DATAPATH
							.PC_OFFSET	(pc_offset),
							.PC_TARGET	(pc_target),
							// FROM INTERRUPT CONTROL
							.INT_VEC	(int_vec),
							// FROM INST. MEMROY
							.INSTR		(INSTR),
							// FROM ID CONTROL
							.PC_SEL		(pc_sel),
							.IR_SEL		(ir_nop),

							// TO PIPELINE REG.
							.PC_OUT		(IADDR),
							.IR_OUT		(ir_di)
						);

	//---------------------------------------------------------------
	//		ID STAGE
	//---------------------------------------------------------------
	// DATAPATH
	RegFile16x32_ECC	GPR (
							.CLK		(CLK),
							.RA_A		(gpr_x_ra),
							.RA_B		(gpr_y_ra),
							.GRF_X		(gpr_x_rd),
							.GRF_Y		(gpr_y_rd),
							.WEN_A		(gpr_a_wen),
							.WEN_B		(gpr_b_wen),
							.WA_A		(gpr_a_wa),
							.WA_B		(gpr_b_wa),
							.W_DA		(gpr_a_wd),
							.W_DB		(w_db),
							.DED_X		(gpr_ded_x),
							.DED_Y		(gpr_ded_y)
						);

	PipeReg	#(4)		NX_RA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(nx_ra_di),
							.Q		(nx_ra)
						);

	PipeReg	#(4)		NY_RA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(ny_ra_di),
							.Q		(ny_ra)
						);

	// CONTROLPATH
	PipeReg	#(30)		D_PC_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(d_pipe_en),
							.D		(f_pc),
							.Q		(d_pc)
						);

	PipeReg	#(1)		N_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(d_pipe_en | ir[31]),
							.D		(~ir[31] & ir_di[31]),
							.Q		(ir[31])
						);

	PipeReg	#(31)		IR_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(d_pipe_en),
							.D		(ir_di[30:0]),
							.Q		(ir[30:0])
						);

	PipeReg	#(1)		INST_START_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(cg_last | ci_n),
							.Q		(inst_start)
						);

	PipeReg	#(1)		D_VALID_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(d_pipe_en),
							.D		(~ir_nop),	// do NOT use CG_IR here
							.Q		(d_valid)
						);

	PipeReg	#(1)		MMREQ_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(mm_req_di),
							.Q		(mm_req)
						);

	// INTERRUPT
	PipeReg #(1)		D_SWI_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(cg_last & ~ir[31]),
							.D		(ci_swi),
							.Q		(d_swi)
						);

	PipeReg #(1)		D_IMF_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(cg_last & ~ir[31]),
							.D		(IFAULT & ~ir_nop & ~ci_atomic),
							.Q		(d_imf)
						);

	PipeReg #(1)		D_IDE_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(cg_last & ~ir[31]),
							.D		(IMEM_DED & ~ir_nop & ~ci_atomic),
							.Q		(d_ide)
						);

	PipeReg #(1)		D_EXT_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(cg_last & ~ir[31]),
							.D		(INT & ~ir_nop & ~ci_atomic),
							.Q		(d_ext)
						);

	// MODULE
	Counter				COUNTER (
							.CLK		(CLK),
							.RST		(RST | cg_last | ci_n),
							.COUNT		(cnt_count),
							.ZERO		(cnt_zero)
						);

	CMD_GEN				CONTROLPATH_COMMAND (
							.INST		({ir[30:22], ir[4:0]}),
							// FRON DECODER
							.SHIFT		(ci_do_shift),
							// FROM COUNTER
							.COUNT		(cnt_count),
							.ZERO		(cnt_zero),
							// FROM MMREQ REG.
							.MMREQ		(mm_req),

							.LAST		(cg_last),
							// TO ID CONTROL
							.IR		(cg_ir),
							.BR		(cg_br),
							.PAT		(cg_pat),
							.EX		(cg_ex),
							.EY		(cg_ey),
							.NRX		(cg_nx),
							.NRY		(cg_ny),
							.PS_X		(cg_ps_x),
							.FWD_X		(cg_fwd_x),
							.FWD_Y		(cg_fwd_y),
							.EOP		(cg_eop),
							.MUL		(cg_mul),
							.MEM		(cg_mem),
							.WDA		(cg_wda),
							.WDB		(cg_wdb),
							.PS		(cg_ps),
							.DST_A		(cg_dst_a),
							.DST_B		(cg_dst_b)
						);

	DECODER				CONTROLPATH_DECODER (
							.IR		(ir),
							.PS_MODE	(ps[1:0]),

							// TO COMMAND GEN.
							.DO_SHIFT	(ci_do_shift),
							// TO ID CONTROL
							.N		(ci_n),
							.R1		(ci_r1),
							.R2		(ci_r2),
							.R3		(ci_r3),
							.R4		(ci_r4),
							.USE_CONDZ	(ci_use_condz),
							.CONDINST	(ci_cond_inst),
							.SHAMT		(ci_shamt),
							.CT_IMM		(ci_imm),
							.CT_ALU		(ci_alu),
							.CT_SHIFT	(ci_shift),
							.U		(ci_u),
							.CUT		(ci_cut),
							.UMULT		(ci_umult),
							.SIGN		(ci_sign),
							.SIZE		(ci_size),
							// TO INTERRUPT CONTROL
							.ATOMIC		(ci_atomic),
							.INVD		(ci_invd),
							.SWI		(ci_swi),
							.PAT		(ci_pat)
						);

	ID_DP				DATAPATH_ID (
							// FROM PIPELINE REG.
							.F_PC		(f_pc),	
							.IR		(ir),			// FOR IMM.
							.IDR		(e_y[23:0]),
							// FROM GPR
							.GPR_X_RD	(gpr_x_rd),
							.GPR_Y_RD	(gpr_y_rd),
							// FROM PIPELINE REG. (FORWARDING)
							.M_DA		(m_da),
							.W_DA		(w_da),
							.W_DB		(w_db),
							.E_NZCV		(e_nzcv),
							// FROM FORWARD CONTROL
							.REG_SEL	(d_reg_sel),
							// FROM ID CONTROL
							.IMM_SEL	(d_imm_sel),
							.COND_SEL	(d_cond_sel),
							.SHAMT		(d_shamt),
							.X_SEL		(e_x_sel),
							.Y_SEL		(e_y_sel),

							// TO PIPELINE REG
							.X_OUT		(e_x_di),
							.Y_OUT		(e_y_di),
							.Z_OUT		(e_z_di),
							// TO IF DATAPATH
							.PC_OFFSET	(pc_offset),
							.PC_TARGET	(pc_target),
							// TO ID CONTROL
							.COND_TRUE	(d_cond_true)
						);

	ID_CP				CONTROLPATH_ID (
							// INPUT
							.VALID		(d_valid),
							.INST_START	(inst_start),
							// FROM INTERRUPT CONTROL
							.INT_DETECT	(int_detect),
							
							// FROM PIPELINE REG.
							.MODE		(ps[0]),
							.X_RA		(nx_ra),
							.Y_RA		(ny_ra),
							.PAT		(e_pat),
							// FROM COMMAND GEN.
							.CG_LAST	(cg_last),
							.CG_IR		(cg_ir),
							.CG_BR		(cg_br),
							.CG_PAT		(cg_pat),
							.CG_EX		(cg_ex),
							.CG_EY		(cg_ey),
							.CG_NRX		(cg_nx),
							.CG_NRY		(cg_ny),
							.CG_PS_X	(cg_ps_x),
							.CG_EOP		(cg_eop),
							.CG_MUL		(cg_mul),
							.CG_MEM		(cg_mem),
							.CG_WDA		(cg_wda),
							.CG_WDB		(cg_wdb),
							.CG_PS		(cg_ps),
							.CG_DST_A	(cg_dst_a),
							.CG_DST_B	(cg_dst_b),
							// FROM DECODER
							.CI_N		(ci_n),
							.CI_R1		(ci_r1),
							.CI_R2		(ci_r2),
							.CI_R3		(ci_r3),
							.CI_R4		(ci_r4),
							.CI_SIGN	(ci_sign),
							.CI_SIZE	(ci_size),
							.CI_U		(ci_u),
							.CI_CUT		(ci_cut),
							.CI_USE_CONDZ	(ci_use_condz),
							.CI_COND_INST	(ci_cond_inst),
							.CI_ALU		(ci_alu),
							.CI_SHIFT	(ci_shift),
							.CI_SHAMT	(ci_shamt),
							.CI_IMM_SEL	(ci_imm),
							.CI_UMULT	(ci_umult),
							.CI_PAT		(ci_pat),
							// FROM ID DATAPATH
							.COND_TRUE	(d_cond_true),

							// TO INST. MEMORY
							.IREQ		(IREQ),
							// TO IF DATAPATH
							.PC_SEL		(pc_sel),
							.IR_SEL		(ir_nop),
							// TO ID DATAPATH
							.IMM_SEL	(d_imm_sel),
							.COND_SEL	(d_cond_sel),
							.SHAMT		(d_shamt),
							.X_SEL		(e_x_sel),
							.Y_SEL		(e_y_sel),
							// TO GPR
							.GPR_X_RA	(gpr_x_ra),
							.GPR_Y_RA	(gpr_y_ra),
							// TO PIPELINE REG.
							.F_PIPE_EN	(f_pipe_en),
							.D_PIPE_EN	(d_pipe_en),
							.NX_RA_OUT	(nx_ra_di),
							.NY_RA_OUT	(ny_ra_di),
							.X_WE		(e_x_we),
							.Y_WE		(e_y_we),
							.Z_WE		(e_z_we),
							.PAT_WE		(e_pat_we),
							.PAT_OUT	(e_pat_di),
							.MMREQ_OUT	(mm_req_di),
							.CMD_EOP_OUT	(e_cmd_eop_di),
							.CMD_ALU_OUT	(e_cmd_alu_di),
							.CMD_SHIFT_OUT	(e_cmd_shift_di),
							.CMD_MUL_OUT	(e_cmd_mul_di),
							.CMD_MEM_OUT	(e_cmd_mem_di),
							.CMD_MOP_OUT	(e_cmd_mop_di),
							.CMD_DA_OUT	(e_cmd_da_di),
							.CMD_DB_OUT	(e_cmd_db_di),
							.CMD_PS_OUT	(e_cmd_ps_di),
							.CMD_NZCV_OUT	(e_cmd_nzcv_di),
							.VALID_OUT	(e_valid_di)
						);

	//---------------------------------------------------------------
	//		EX STAGE
	//---------------------------------------------------------------
	// DATAPATH
	PipeReg	#(32)		PS_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(ps_we),
							.D		(ps_di),
							.Q		(ps)
						);

	PipeReg	#(32)		E_X_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(e_x_we),
							.D		(e_x_di),
							.Q		(e_x)
						);

	PipeReg	#(32)		E_Y_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(e_y_we),
							.D		(e_y_di),
							.Q		(e_y)
						);

	PipeReg	#(5)		E_Z_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(e_z_we),
							.D		(e_z_di),
							.Q		(e_z)
						);

	// CONTROLPATH
	PipeReg	#(30)		E_PC_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(d_pc),
							.Q		(e_pc)
						);


 	PipeReg #(32)		E_IR_FF (
 							.CLK		(CLK),
 							.RST		(RST),
 							.EN		(1'b1),
 							.D		(ir),
 							.Q		(e_ir)
 						);

	PipeReg	#(1)		E_VALID_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_valid_di),
							.Q		(e_valid)
						);

	PipeReg	#(2)		E_CMD_EOP_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_eop_di),
							.Q		(e_cmd_eop)
						);

	PipeReg	#(17)		E_CMD_ALU_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_alu_di),
							.Q		(e_cmd_alu)
						);

	PipeReg	#(8)		E_CMD_SHIFT_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_shift_di),
							.Q		(e_cmd_shift)
						);

	PipeReg	#(5)		E_CMD_MUL_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_mul_di),
							.Q		(e_cmd_mul)
						);

	PipeReg	#(10)		E_CMD_MEM_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_mem_di),
							.Q		(e_cmd_mem)
						);

	PipeReg	#(2)		E_CMD_MOP_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_mop_di),
							.Q		(e_cmd_mop)
						);

	PipeReg	#(5)		E_CMD_DA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_da_di),
							.Q		(e_cmd_da)
						);

	PipeReg	#(5)		E_CMD_DB_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_db_di),
							.Q		(e_cmd_db)
						);

	PipeReg	#(3)		E_CMD_PS_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_ps_di),
							.Q		(e_cmd_ps)
						);

	PipeReg	#(3)		E_CMD_NZCV_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_cmd_nzcv_di),
							.Q		(e_cmd_nzcv)
						);

	PipeReg	#(16)		E_PAT_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(e_pat_we),
							.D		(e_pat_di),
							.Q		(e_pat)
						);

	// INTERRUPT
	PipeReg #(1)		E_UDI_FF (
							.CLK	(CLK),
							.RST	(int_detect),
							.EN	(1'b1),
							.D	(ci_invd),
							.Q	(e_udi)
						);

	wire	gpr_x_pc_target = pc_sel[1] & d_reg_sel[3];
	PipeReg #(1)		E_RDE_FF_X (
							.CLK	(CLK),
							.RST	(int_detect),
							.EN	(e_x_we),
							.D	((gpr_x_pc_target|e_x_sel[1]) & gpr_ded_x & e_op_x_sel_di[5] & ps[15]),
							.Q	(e_rde_x)
						);
	PipeReg #(1)		E_RDE_FF_Y (
							.CLK	(CLK),
							.RST	(int_detect),
							.EN	(e_y_we),
							.D	(e_y_sel[1] & gpr_ded_y & e_op_y_sel_di[5] & ps[15]),
							.Q	(e_rde_y)
						);

	PipeReg #(1)		E_SWI_FF (
							.CLK	(CLK),
							.RST	(int_detect),
							.EN	(1'b1),
							.D	(d_swi),
							.Q	(e_swi)
						);

	PipeReg #(1)		E_IMF_FF (
							.CLK	(CLK),
							.RST	(int_detect),
							.EN	(1'b1),
							.D	(d_imf | (IFAULT & ci_atomic)),
							.Q	(e_imf)
						);

	PipeReg #(1)		E_IDE_FF (
							.CLK	(CLK),
							.RST	(int_detect),
							.EN	(1'b1),
							.D	({d_ide | (IMEM_DED & ci_atomic)} & ps[15]),
							.Q	(e_ide)
						);

	PipeReg #(1)		E_EXT_FF (
							.CLK	(CLK),
							.RST	(int_detect),
							.EN	(1'b1),
							.D	(d_ext & ps[2]),
							.Q	(e_ext)
						);

	// MODULE
	EX_DP				DATAPATH_EX	(
							// FROM PIPELINE REG.
							.PS		(ps),
							.E_X		(e_x),
							.E_Y		(e_y),
							.E_Z		(e_z),
							.CPN		(e_ir[1:0]),
							// FROM PIPELINE REG. (FORWARDING)
							.M_DA		(m_da),
							.W_DA		(w_da),
							.W_DB		(w_db),
							.P_DA		(p_da),
							.P_DB		(p_db),
							.M_NZCV		(m_nzcv),
							// FROM FORWARDING CONTROL
							.OP_X_SEL	(e_op_x_sel),
							.OP_Y_SEL	(e_op_y_sel),
							.NZCV_SEL	(e_nzcv_sel),
							// FROM EX CONTROL
							.ALU_OP		(e_alu_op),
							.ALU_X		(e_alu_x),
							.ALU_Y		(e_alu_y),
							.ALU_C		(e_alu_c),
							.ALU_PS_SEL	(e_alu_ps_sel),
							.SHAMT_SEL	(e_shamt_sel),
							.SHIFT_DIR	(e_shift_dir),
							.SHIFT_HI	(e_shift_hi),
							.SHIFT_LO	(e_shift_lo),
							.UMULT		(e_umult),
							.ACC_HI_SEL	(e_acc_hi_sel),
							.ACC_LO_SEL	(e_acc_lo_sel),
							.NZ_UPDATE	(e_nz_update),
							.C_UPDATE	(e_c_update),
							.V_UPDATE	(e_v_update),
							.MSIZE		(e_msize),
							.DA_SEL		(m_da_sel),
							.MADDR_SEL	(e_maddr_sel),

							// TO ID DATAPATH
							.E_NZCV		(e_nzcv),
							// TO PIPELINE REG.
							.DA_OUT		(m_da_di),
							.ACC_OUT	(m_acc_di),
							.PPD1_OUT	(m_ppd1_di),
							.PPD2_OUT	(m_ppd2_di),
							.NZCV_OUT	(m_nzcv_di),
							.SHAMT_OUT	(m_shamt_di),	// DHYOU EDIT
							// TO DATA MEMORY
							.MADDR		(DADDR),
							.MDOUT		(DWDATA),
							.DSIZE		(DSIZE)
						);

	EX_CP 				CONTROLPATH_EX (
							// FROM PIPELINE REG.
							.VALID		(e_valid),
							.CMD_EOP	(e_cmd_eop),
							.CMD_ALU	(e_cmd_alu),
							.CMD_SHIFT	(e_cmd_shift),
							.CMD_MUL	(e_cmd_mul),
							.CMD_MEM	(e_cmd_mem),
							.CMD_MOP	(e_cmd_mop),
							.CMD_DA		(e_cmd_da),
							.CMD_DB		(e_cmd_db),
							.CMD_PS		(e_cmd_ps),
							.CMD_NZCV	(e_cmd_nzcv),
							// FROM INTERRUPT CONTROL
							.INT_DETECT	(int_detect),
							.DONT_MREQ	(dont_mreq),

							// TO EX DATAPATH
							.ALU_OP		(e_alu_op),
							.ALU_X		(e_alu_x),
							.ALU_Y		(e_alu_y),
							.ALU_C		(e_alu_c),
							.ALU_PS_SEL	(e_alu_ps_sel),
							.SHAMT_SEL	(e_shamt_sel),
							.SHIFT_DIR	(e_shift_dir),
							.SHIFT_HI	(e_shift_hi),
							.SHIFT_LO	(e_shift_lo),
							.UMULT		(e_umult),
							.ACC_HI_SEL	(e_acc_hi_sel),
							.ACC_LO_SEL	(e_acc_lo_sel),
							.NZ_UPDATE	(e_nz_update),
							.C_UPDATE	(e_c_update),
							.V_UPDATE	(e_v_update),
							.MTYPE		(DTYPE),		// FOR ALIGN
							.MSIZE		(e_msize),
							.DA_SEL		(m_da_sel),
							.MADDR_SEL	(e_maddr_sel),
							// TO DATA MEMORY
							.MREQ		(DREQ),
							.MODE		(DMODE),
							.MRW		(DRW),
							.MLOCK		(DLOCK),
							// TO PIPELINE REG.
							.SHAMT_WE	(m_shamt_we),
							.DA_WE		(m_da_we),
							.ACC_WE		(m_acc_we),
							.PPD_WE		(m_ppd_we),
							.NZCV_WE	(m_nzcv_we),
							.CMD_MEM_OUT	(m_cmd_mem_di),
							.CMD_MOP_OUT	(m_cmd_mop_di),
							.CMD_DA_OUT	(m_cmd_da_di),
							.CMD_DB_OUT	(m_cmd_db_di),
							.CMD_PS_OUT	(m_cmd_ps_di),
							.VALID_OUT	(m_valid_di)
						);

	//---------------------------------------------------------------
	//		MEM STAGE
	//---------------------------------------------------------------
	// DATAPATH
	PipeReg	#(4)		M_NZCV_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(m_nzcv_we),
							.D		(m_nzcv_di),
							.Q		(m_nzcv)
						);

	PipeReg	#(32)		M_DA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(m_da_we),
							.D		(m_da_di),
							.Q		(m_da)
						);

	PipeReg	#(64)		M_ACC_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(m_acc_we),
							.D		(m_acc_di),
							.Q		(m_acc)
						);

	PipeReg	#(64)		M_PPD1_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(m_ppd_we),
							.D		(m_ppd1_di),
							.Q		(m_ppd1)
						);

	PipeReg	#(64)		M_PPD2_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(m_ppd_we),
							.D		(m_ppd2_di),
							.Q		(m_ppd2)
						);

	// CONTROLPATH
	PipeReg	#(30)		M_PC_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(e_pc),
							.Q		(m_pc)
						);

	PipeReg	#(1)		M_VALID_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(m_valid_di),
							.Q		(m_valid)
						);

	PipeReg	#(4)		M_CMD_MEM_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(m_cmd_mem_di),
							.Q		(m_cmd_mem)
						);

	PipeReg	#(2)		M_CMD_MOP_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(m_cmd_mop_di),
							.Q		(m_cmd_mop)
						);

	PipeReg	#(5)		M_CMD_DA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(m_cmd_da_di),
							.Q		(m_cmd_da)
						);

	PipeReg	#(5)		M_CMD_DB_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(m_cmd_db_di),
							.Q		(m_cmd_db)
						);

	PipeReg	#(3)		M_CMD_PS_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(m_cmd_ps_di),
							.Q		(m_cmd_ps)
						);

	// INTERRUPT
	PipeReg #(1)		M_UDI_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(e_udi),
							.Q		(m_udi)
						);

	PipeReg #(1)		M_RDE_FF_X (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(e_rde_x | e_rde_y),
							.Q		(m_rde)
						);

	PipeReg #(1)		M_SWI_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(e_swi),
							.Q		(m_swi)
						);

	PipeReg #(1)		M_IMF_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(e_imf),
							.Q		(m_imf)
						);

	PipeReg #(1)		M_IDE_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(e_ide),
							.Q		(m_ide)
						);

	PipeReg #(1)		M_EXT_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(e_ext),
							.Q		(m_ext)
						);

	PipeReg #(1)		M_MREQ_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(DREQ & (DTYPE == 2'b00)),
							.Q		(m_mreq)
						);

	PipeReg #(1)		M_CPREQ_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(DREQ & (DTYPE[1] == 1'b1)),
							.Q		(m_cpreq)
						);
	// DHYOU EDIT
        PipeReg #(2)            M_SHAMT_FF (
                                                       .CLK            (CLK),
                                                       .RST            (RST),
                                                       .EN                     (m_shamt_we),
                                                       .D                      (m_shamt_di),
                                                       .Q                      (m_shamt)
						);
	// MODULE
	MEM_DP				DATAPATH_MEM (
							// FROM PIPELINE REG.
							.SHAMT		(m_shamt),	// DHYOU EDIT
							.DA		(m_da),
							.ACC		(m_acc),
							.PPD1		(m_ppd1),
							.PPD2		(m_ppd2),
							.NZCV		(m_nzcv),
							// FROM DATA MEMORY
							.MDIN		(DRDATA),
							// FROM MEM CONTROL
							.MSIGN		(m_msign),
							.MSIZE		(m_msize),
							.DA_SEL		(w_da_sel),
							.DB_SEL		(w_db_sel),

							// TO PIPELINE REG.
							.DA_OUT		(w_da_di),
							.DB_OUT		(w_db_di),
							.NZCV_OUT	(w_nzcv_di)
						);

	MEM_CP				CONTROLPATH_MEM (
							// FOMR PIPELINE REG.
							.VALID		(m_valid),
							.CMD_MEM	(m_cmd_mem),
							.CMD_MOP	(m_cmd_mop),
							.CMD_DA		(m_cmd_da),
							.CMD_DB		(m_cmd_db),
							.CMD_PS		(m_cmd_ps),
							// FROM INTERRUPT CONTROL
							.INT_DETECT	(int_detect),

							// TO MEM DATAPATH
							.MSIGN		(m_msign),
							.MSIZE		(m_msize),
							.DA_SEL		(w_da_sel),
							.DB_SEL		(w_db_sel),
							// TO PIPELINE REG.
							.DA_WE		(w_da_we),
							.DB_WE		(w_db_we),
							.NZCV_WE	(w_nzcv_we),
							.CMD_DA_OUT	(w_cmd_da_di),
							.CMD_DB_OUT	(w_cmd_db_di),
							.CMD_PS_OUT	(w_cmd_ps_di),
							.VALID_OUT	(w_valid_di)
						);

	//---------------------------------------------------------------
	//		WB STAGE
	//---------------------------------------------------------------
	// DATAPATH
	PipeReg	#(4)		W_NZCV_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(w_nzcv_we),
							.D		(w_nzcv_di),
							.Q		(w_nzcv)
						);

	PipeReg	#(32)		W_DA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(w_da_we),
							.D		(w_da_di),
							.Q		(w_da)
						);

	PipeReg	#(32)		W_DB_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(w_db_we),
							.D		(w_db_di),
							.Q		(w_db)
						);

	// CONTROLPATH
	PipeReg		#(30)	W_PC_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(m_pc),
							.Q		(w_pc)
						);

	PipeReg	#(1)		W_VALID_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(w_valid_di),
							.Q		(w_valid)
						);

	PipeReg		#(5)	W_CMD_DA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(w_cmd_da_di),
							.Q		(w_cmd_da)
						);

	PipeReg		#(5)	W_CMD_DB_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(w_cmd_db_di),
							.Q		(w_cmd_db)
						);

	PipeReg		#(3)	W_CMD_PS_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(1'b1),
							.D		(w_cmd_ps_di),
							.Q		(w_cmd_ps)
						);

	// INTERRUPT
	PipeReg #(1)		W_UDI_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(m_udi),
							.Q		(w_udi)
						);

	PipeReg #(1)		W_RDE_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(m_rde),
							.Q		(w_rde)
						);

	PipeReg #(1)		W_SWI_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(m_swi),
							.Q		(w_swi)
						);

	PipeReg #(1)		W_IMF_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(m_imf),
							.Q		(w_imf)
						);

	PipeReg #(1)		W_IDE_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(m_ide),
							.Q		(w_ide)
						);

	PipeReg #(1)		W_EXT_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(m_ext),
							.Q		(w_ext)
						);

	// FOR 1 CYCLE INT_ACK GENERATION
	// MAY USE EXTERNAL CLOCK (NOT GATED)
	PipeReg #(1)		W_ACK_FF   (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(m_ext),
							.Q		(INT_ACK)
						);

	PipeReg #(1)		W_DMF_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(DFAULT & m_mreq),
							.Q		(w_dmf)
						);

	PipeReg #(1)		W_DDE_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(DMEM_DED & m_mreq & ps[15]),
							.Q		(w_dde)
						);

	PipeReg #(1)		W_CPINT_FF (
							.CLK		(CLK),
							.RST		(int_detect),
							.EN		(1'b1),
							.D		(CPINT & m_cpreq),
							.Q		(w_cpint)
						);

	// MAY USE EXTERNAL CLOCK (NOT GATED) OR MAY NOT
	// TO USE GATED-CLOCK nWAIT FROM MEMORY SHOULD BE 1'b1 DURING RESET.
	PipeReg #(1)		W_RST_FF (
							.CLK		(CLK),
							.RST		(1'b0),		// NO RESET
							.EN		(1'b1),
							.D		(RST),
							.Q		(w_rst)
						);

	// MODULE
	WB_DP				DATAPATH_WB (
							// FROM PIPELINE REG.
							.W_PC		(w_pc),
							.PS			(ps),
							.W_NZCV		(w_nzcv),
							.DA			(w_da),
							.INT_DED	({w_ide, w_rde, w_dde}),

							// FROM WB CONTROL
							.PS_SEL		(w_ps_sel),
							.GPR_A_SEL	(w_gpr_a_sel),

							// TO PS
							.PS_OUT		(ps_di),
							// TO GPR
							.GPR_A_WD	(gpr_a_wd)
						);

	WB_CP				CONTROLPATH_WB (
							// FROM PIPELINE REG.
							.VALID		(w_valid),
							.CMD_DA		(w_cmd_da),
							.CMD_DB		(w_cmd_db),
							.CMD_PS		(w_cmd_ps),
							// FROM INTERRUPT CONTROL
							.INT_DETECT	(int_detect),

							// TO PIPELINE REG.
							.PS_WE		(ps_we),
							.DA_WE		(p_da_we),
							.DB_WE		(p_db_we),
							// TO WB DATAPATH
							.PS_SEL		(w_ps_sel),
							.GPR_A_SEL	(w_gpr_a_sel),
							// TO GPR
							.GPR_A_WEN	(gpr_a_wen),
							.GPR_B_WEN	(gpr_b_wen),
							.GPR_A_WA	(gpr_a_wa),
							.GPR_B_WA	(gpr_b_wa)
						);

	IntControl			INT_CTRL (
							.E_INT		(e_udi | e_rde_x | e_rde_y | e_swi | e_imf | e_ide | e_ext),
							.M_INT		(m_udi | m_rde | m_swi | m_imf | m_ide | m_ext),
							.DFAULT		(m_mreq & (DFAULT|DMEM_DED) | m_cpreq & CPINT),
							.INT_FIELD	({w_rst, w_dmf, w_dde, w_udi, w_rde, w_swi, w_ext, w_imf, w_ide, w_cpint}),

							.DONT_MREQ	(dont_mreq),
							.INT_DETECT	(int_detect),
							.INT_VECTOR	(int_vec)
						);

	//---------------------------------------------------------------
	//		WB_FWD STAGE
	//---------------------------------------------------------------
	// DATAPATH
	PipeReg	#(32)		P_DA_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(p_da_we),
							.D		(w_da),
							.Q		(p_da)
						);

	PipeReg	#(32)		P_DB_FF (
							.CLK		(CLK),
							.RST		(RST),
							.EN		(p_db_we),
							.D		(w_db),
							.Q		(p_db)
						);

	//---------------------------------------------------------------
	//		FWD Control
	//---------------------------------------------------------------
	FWD_CP_IMME			CONTROLPATH_FWD_IMME (
							// FROM IR
							.D_DA_IDX	(ir[19:16]),			// R2
							// FROM PIPELINE REG.
							.M_DA_VALID	(m_cmd_da[4] & m_valid),
							.M_DA_IDX	(m_cmd_da[3:0]),
							.M_U_WE		(m_cmd_ps[2] & m_cmd_ps[1] & m_valid),
							.W_DA_VALID	(w_cmd_da[4] & w_valid),
							.W_DA_IDX	(w_cmd_da[3:0]),
							.W_DB_VALID	(w_cmd_db[4] & w_valid),
							.W_DB_IDX	(w_cmd_db[3:0]),
							.W_U_WE		(w_cmd_ps[2] & w_cmd_ps[1] & w_valid),

							// TO ID DATAPATH
							.D_REG_SEL	(d_reg_sel),
							// TO EX DATAPATH
							.E_NZCV_SEL	(e_nzcv_sel)
						);

	FWD_CP				CONTROLPATH_FWD (
							// FROM ID CONTROL
							.D_DA_VALID	(e_x_sel[1]),	// 0:OTHERS, 1:REG
							.D_DA_IDX	(gpr_x_ra),
							.D_DB_VALID	(e_y_sel[1]),	// 0:OTHERS, 1:REG
							.D_DB_IDX	(gpr_y_ra),
							// FROM PIPELINE REG.
							// (DO NOT NEED TO CONSIDER INT_DETECT)
							.E_DA_VALID	(e_cmd_da[4] & e_valid),
							.E_DA_IDX	(e_cmd_da[3:0]),
							.M_DA_VALID	(m_cmd_da[4] & m_valid),
							.M_DA_IDX	(m_cmd_da[3:0]),
							.M_DB_VALID	(m_cmd_db[4] & m_valid),
							.M_DB_IDX	(m_cmd_db[3:0]),
							.W_DA_VALID	(w_cmd_da[4] & w_valid),
							.W_DA_IDX	(w_cmd_da[3:0]),
							.W_DB_VALID	(w_cmd_db[4] & w_valid),
							.W_DB_IDX	(w_cmd_db[3:0]),
							// FROM COMMAND GEN.
							.FWD_X		(cg_fwd_x),
							.FWD_Y		(cg_fwd_y),
							
							// TO EX DATAPATH
							.E_OP_X_SEL	(e_op_x_sel_di),
							.E_OP_Y_SEL	(e_op_y_sel_di)
						);

	PipeRegS	#(6)	E_OP_X_SEL_FF (
							.CLK		(CLK),
							.SET		(RST),
							.EN		(1'b1),
							.D		(e_op_x_sel_di),
							.Q		(e_op_x_sel)
						);

	PipeRegS	#(6)	E_OP_Y_SEL_FF (
							.CLK		(CLK),
							.SET		(RST),
							.EN		(1'b1),
							.D		(e_op_y_sel_di),
							.Q		(e_op_y_sel)
						);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                   2-Read/2-Write 16x32bit Register File                     *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module RegFile16x32 (
	input	wire					CLK, 
	input	wire					WEN_A,
	input	wire					WEN_B,
	input	wire		[31:0]		W_DA,
	input	wire		[31:0]		W_DB,
	input	wire		[3:0]		RA_A,
	input	wire		[3:0]		RA_B,
	input	wire		[3:0]		WA_A,
	input	wire		[3:0]		WA_B,
	output	wire		[31:0]		GRF_X,
	output	wire		[31:0]		GRF_Y
);

	reg		[31:0]		ram[15 : 0];

	assign	GRF_X = ram[RA_A];
	assign	GRF_Y = ram[RA_B];

	wire	Contention = (WA_A==WA_B) & ~WEN_B;

	always @ (posedge CLK)
	begin
			if(~Contention & ~WEN_A)	ram[WA_A] <= W_DA;
			if(~WEN_B)	ram[WA_B] <= W_DB;
	end


///////

wire	[31:0]	test_r00 = ram[0];
wire	[31:0]	test_r01 = ram[1];
wire	[31:0]	test_r02 = ram[2];
wire	[31:0]	test_r03 = ram[3];
wire	[31:0]	test_r04 = ram[4];
wire	[31:0]	test_r05 = ram[5];
wire	[31:0]	test_r06 = ram[6];
wire	[31:0]	test_r07 = ram[7];
wire	[31:0]	test_r08 = ram[8];
wire	[31:0]	test_r09 = ram[9];
wire	[31:0]	test_r10 = ram[10];
wire	[31:0]	test_r11 = ram[11];
wire	[31:0]	test_r12 = ram[12];
wire	[31:0]	test_r13 = ram[13];
wire	[31:0]	test_r14 = ram[14];
wire	[31:0]	test_r15 = ram[15];

///////

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                2-Read/2-Write 16x32bit Register File with SEC DED           *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Bongjin Kim    *
*                                                         Byeong Yong Kong    *
*                                                                Injae Yoo    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module RegFile16x32_ECC (
	input	wire					CLK, 
	input	wire					WEN_A,
	input	wire					WEN_B,
	input	wire		[31:0]		W_DA,
	input	wire		[31:0]		W_DB,
	input	wire		[3:0]		RA_A,
	input	wire		[3:0]		RA_B,
	input	wire		[3:0]		WA_A,
	input	wire		[3:0]		WA_B,
	output	wire		[31:0]		GRF_X,
	output	wire		[31:0]		GRF_Y,
	output	wire					DED_X,
	output	wire					DED_Y
);

reg 	[38:0]  ram [15:0];

HAMM_DEC_SYS32	RegFile_HD1	(
	.DIN	(ram[RA_A]),
	.DOUT	(GRF_X),
	.SEC	(),
	.DED	(DED_X)
);

HAMM_DEC_SYS32	RegFile_HD2	(
	.DIN	(ram[RA_B]),
	.DOUT	(GRF_Y),
	.SEC	(),
	.DED	(DED_Y)
);


wire    [38:0]  W_DA_HE;
HAMM_ENC_SYS32	RegFile_HE1	(
	.DIN	(W_DA),
	.DOUT	(W_DA_HE)
);

wire    [38:0]  W_DB_HE;
HAMM_ENC_SYS32	RegFile_HE2	(
	.DIN	(W_DB),
	.DOUT	(W_DB_HE)
);

wire    Contention = (WA_A==WA_B) & ~WEN_B;

always @ (posedge CLK)
begin
	if(~Contention & ~WEN_A)
			ram[WA_A] <= W_DA_HE;
	if(~WEN_B) 
			ram[WA_B] <= W_DB_HE;
end


///////

wire	[38:0]	test_r00 = ram[0];
wire	[38:0]	test_r01 = ram[1];
wire	[38:0]	test_r02 = ram[2];
wire	[38:0]	test_r03 = ram[3];
wire	[38:0]	test_r04 = ram[4];
wire	[38:0]	test_r05 = ram[5];
wire	[38:0]	test_r06 = ram[6];
wire	[38:0]	test_r07 = ram[7];
wire	[38:0]	test_r08 = ram[8];
wire	[38:0]	test_r09 = ram[9];
wire	[38:0]	test_r10 = ram[10];
wire	[38:0]	test_r11 = ram[11];
wire	[38:0]	test_r12 = ram[12];
wire	[38:0]	test_r13 = ram[13];
wire	[38:0]	test_r14 = ram[14];
wire	[38:0]	test_r15 = ram[15];

///////


endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                                      ALU                                    *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module ALU ( 
			// Input 
			input 	wire 	[31:0]	OP_X,	
			input	wire	[31:0]	OP_Y,
			input 	wire			C_IN,

			//ALU Ctrl
			input	wire	[3:0]	MUX_CTRL_ALU,
			input	wire			MUX_CTRL_X,
			input	wire	[7:0]	MUX_CTRL_Y,
			input	wire	[2:0]	MUX_CTRL_C,

			// Output
			output	wire			C_OUT,
			output	wire			V_OUT,
			output	wire	[31:0]	ALU_OUT
		);
	
	/**************************************************************/
	/***	Total ALU Operation									***/
	/***	Op.			Fn		MUX_OP_X	MUX_OP_Y	C_IN	***/
	/***	OR 		->	OR		OP_X		OP_Y		-		***/
	/***	XOR 	->	XOR		OP_X		OP_Y		-		***/
	/***	AND 	->	AND		OP_X		OP_Y		-		***/
	/***	NOR	 	->	AND 	~OP_X		~OP_Y		-		***/
	/***	ANDN 	->	AND		OP_X		~OP_Y		-		***/
	/***	MOVX	->	OR		OP_X		0			-		***/
	/***	ADD	 	->	ADD		OP_X		OP_Y		0		***/
	/***	SUB		->	ADD		OP_X		~OP_Y		1		***/
	/***	RSB	 	->	ADD		~OP_X		OP_Y		1		***/
	/***	ADC	 	->	ADD		OP_X		OP_Y		C		***/
	/***	SBB	 	->  ADD		OP_X		~OP_Y		C		***/
	/***	ADD1	->	ADD		OP_X		1			-		***/	//LDM, STM
	/***	ADD2	->	ADD		OP_X		2			-   	***/	//LDM, STM
	/***	ADD4	->	ADD		OP_X		4			-		***/	//LDM, STM
	/***	SUB1	->	ADD		OP_X		FFFF_FFFE	1		***/	//BD
	/***	ANDN4	->	AND		OP_X		FFFF_FFFB	-		***/	//INEN
	/**************************************************************/	

	/******************************************/
	/***	Unique ALU Operation			***/
	/***	1.OR 							***/
	/***	2.XOR 							***/
	/***	3.AND 							***/
	/***	4.ADD							***/
	/******************************************/	
	wire	[31:0]	OP_X_In;
	wire	[31:0]	OP_Y_In;
	wire			OPC_In;

	wire	[31:0]	OR_Out;
	wire	[31:0]	XOR_Out;
	wire 	[31:0]	AND_Out;
	wire	[31:0]	ADD_Out;
	wire			ADD_Cout;

	// MUX_CTRL_X 
	//0 : X
	//1	: ~X
	assign OP_X_In = (MUX_CTRL_X) ? ~OP_X: OP_X;
	
	// MUX_CTRL_Y
	//00000001 : Y
	//00000010 : ~Y	<= 1's Complement of 'Y'
	//00000100 : 0
	//00001000 : 1
	//00010000 : 2
	//00100000 : 4
	//01000000 : FFFF_FFFE <= 1's Complement of '1'
	//10000000 : FFFF_FFFB <= 1's Complement of '4'
	MUX8to1 #(32)	MUX_Y (
						.DI0		(OP_Y), 
						.DI1		(~OP_Y), 
						.DI2		(32'h0), 
						.DI3		(32'h1), 
						.DI4		(32'h2), 
						.DI5		(32'h4),	
						.DI6		(32'hFFFF_FFFE),
						.DI7		(32'hFFFF_FFFB),
						.SEL		(MUX_CTRL_Y),
						.DO			(OP_Y_In)
					);

	//MUX_CTRL_C
	//001 : 0
	//010 : 1
	//100 : C_IN (Carry In)
	MUX3to1 #(1)	MUX_C (
						.DI0		(1'b0), 
						.DI1		(1'b1), 
						.DI2		(C_IN), 
						.SEL		(MUX_CTRL_C),
						.DO			(OPC_In)
					);

	assign OR_Out 	= OP_X_In | OP_Y_In;
	assign XOR_Out	= OP_X_In ^ OP_Y_In;
	assign AND_Out 	= OP_X_In & OP_Y_In;

	//ADDER
	DW01_add #(32)	adder (
						.A			(OP_X_In),
						.B			(OP_Y_In),
						.CI			(OPC_In),
						.CO			(ADD_Cout),
						.SUM		(ADD_Out)
					);

	//MUX_CTRL_ALU_OUT 
	//0001 : OR_Out
	//0010 : XOR_Out
	//0100 : AND_Out
	//1000 : ADD_Out
	MUX4to1 #(32)	MUX_OUT (
						.DI0		(OR_Out), 
						.DI1		(XOR_Out), 
						.DI2		(AND_Out), 
						.DI3		(ADD_Out), 
						.SEL		(MUX_CTRL_ALU),
						.DO			(ALU_OUT)
					);

	assign C_OUT = ADD_Cout;
	assign V_OUT =(OP_X_In[31] & OP_Y_In[31] & (~ADD_Out[31])) | ((~OP_X_In[31]) & (~OP_Y_In[31]) & ADD_Out[31]);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                                  MULTIPLIER                                 *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module MUL1 (
	input	wire	[31:0]		DX,
	input	wire	[31:0]		DY,
	input	wire				UMULT,
	output	wire	[63:0]		PPD1,
	output	wire	[63:0]		PPD2
);

		wire	[65:0]	mult_out1;
		wire	[65:0]	mult_out2;

`ifndef _NO_MULT_

		DW02_multp	#(32, 32, 66)	U1(
			.a		(DX),
			.b		(DY),
			.tc		(~UMULT),	// 0:UNSIGNED, 1:SIGNED
			.out0	(mult_out1),
			.out1	(mult_out2)
		);

		assign	PPD1 = mult_out1[63:0];
		assign	PPD2 = mult_out2[63:0];
`else
	assign	PPD1 = 64'd0;
	assign	PPD2 = 64'd0;
`endif

endmodule


module MUL2 (
	input	wire	[63:0]		PPD1,
	input	wire	[63:0]		PPD2,
	input	wire	[63:0]		ACC,
	output	wire	[31:0]		HI,
	output	wire	[31:0]		LO
);

	wire	[63:0]	SUM;

`ifndef _NO_MULT_

	DW02_sum	#(3, 64)	U1(
		.INPUT	({ACC, PPD1, PPD2}),
		.SUM	({HI, LO})
	);

`else
	assign	{HI, LO} = 64'd0;
`endif

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                               Modules for FPGA                              *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

/*
*	These Modules are to replace modules 
*	which are made from DesignWare Library.
*	Taehwan Kim & Sungjin Kim	July.2007
*/

`ifndef _DESIGNWARE_
module DW01_add(
	A, B, CI, SUM, CO
);

parameter width = 32;

input	[width-1:0]	A;
input	[width-1:0]	B;
input			CI;
output	[width-1:0]	SUM;
output			CO;

wire	[width-1:0]	A;
wire	[width-1:0]	B;
wire			CI;
wire	[width-1:0]	SUM;
wire			CO;

assign	{CO, SUM} = A + B + CI;

endmodule

/////////////////////////////////////////

module DW02_multp(
	a, b, tc, out0, out1
);

parameter a_width = 32;
parameter b_width = 32;
parameter out_width = 66;

//npp	8/2	+ 2		= 6
//xdim	8 + 8 + 1	= 17
//bsxt	8 + 1		= 9

input	[31:0]	a;
input	[31:0]	b;
input			tc;
output	signed [65:0]	out0;
output	[65:0]	out1;

wire		[31:0]	a;
wire		[31:0]	b;
wire				tc;
reg signed	[65:0]	out0;
reg 		[65:0]	out1;

wire signed	[31:0]	as;
wire signed	[31:0]	bs;
assign as = a;
assign bs = b;

always @ *	begin
	if(tc)	begin
		out0 = as * bs;
		out1 = 66'b0;
	end
	else	begin
		out0 = 66'b0;
		out1 = a * b;
	end
end

endmodule

/////////////////////////////////////

module DW02_sum(
	INPUT, SUM
);

parameter num_inputs = 3;
parameter input_width = 66;

input	[191:0]	INPUT;
output	[63:0]	SUM;

assign	SUM = INPUT[63:0] + INPUT[127:64] + INPUT[191:128];

endmodule
`endif

//////////////////////////////////////

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                                    SHIFTER                                  *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module EXTRACTOR (
	input	wire	[31:0]			OP_X, 	
	input	wire	[31:0]			OP_Y, 	
	input	wire	[4:0]			OP_Z, 	
	input	wire					DIR,
	input	wire					MUX_CTRL1,
	input	wire	[4:0]			MUX_CTRL2,
	output	wire					COUT, 
	output	wire	[31:0]			DOUT
);

	wire	[31:0]		shift_in1;
	wire	[31:0]		shift_in2;
	wire	[4:0]		shamt;
	wire	[63:0]		shift_out;
	wire				shift_c;

	// DIR = 0 : Left
	// DIR = 1 : Right
	assign	shamt = (DIR)? OP_Z : ~OP_Z;
	
	// Lower Part in Funnel Shifter
	// Left Shift : {OP_Y[0], 31'b0}
	// Right Shift : OP_Y
	assign	shift_in1 = (MUX_CTRL1)? OP_Y : {OP_Y[0], 31'b0};
	
	// Higher Part in Funnel Shifter	
	MUX5to1	#(32)	MUX	(
						.DI0		(32'b0), 				// LSR
						.DI1		({1'b0, OP_Y[31:1]}), 	// SHL
						.DI2		({32{OP_Y[31]}}), 		// ASR
						.DI3		(OP_Y), 				// ROR
						.DI4		(OP_X),					// EXTD
						.SEL		(MUX_CTRL2),
						.DO			(shift_in2)
					);
	
	SHIFTER			SHIFHT_EXTD (
						.DIN		({shift_in2, shift_in1}), 
						.SHAMT		(shamt), 
						.COUT		(shift_c),
						.DOUT		(shift_out)
					);

	assign	DOUT = shift_out[31:0];
	assign	COUT = (DIR) ? shift_c : shift_out[32];

endmodule


module SHIFTER ( 
	/* input */
	input	wire	[63:0]			DIN, 		// Operand to be shifted
	input	wire	[4:0]			SHAMT,		// Shift Amount

	/* output */
	output	wire					COUT,		// Carry Out
	output	wire	[63:0]			DOUT		// Shifted Value
);

	wire    [63:0]  lsr_mid0;
    wire    [63:0]  lsr_mid1;
    wire    [63:0]  lsr_mid2;
    wire    [63:0]  lsr_mid3;
	wire	[5:0]	mux_ctrl;

    assign lsr_mid0 = SHAMT[0] ? { 1'b0,      DIN[63:1]} : DIN;
    assign lsr_mid1 = SHAMT[1] ? { 2'b0, lsr_mid0[63:2]} : lsr_mid0;
    assign lsr_mid2 = SHAMT[2] ? { 4'b0, lsr_mid1[63:4]} : lsr_mid1;
    assign lsr_mid3 = SHAMT[3] ? { 8'b0, lsr_mid2[63:8]} : lsr_mid2;
    assign DOUT		= SHAMT[4] ? {16'b0, lsr_mid3[63:16]}: lsr_mid3;

	assign	mux_ctrl[0] =  SHAMT[4];	
	assign	mux_ctrl[1] = ~SHAMT[4] &  SHAMT[3];
	assign	mux_ctrl[2] = ~SHAMT[4] & ~SHAMT[3] &  SHAMT[2];
	assign	mux_ctrl[3] = ~SHAMT[4] & ~SHAMT[3] & ~SHAMT[2] &  SHAMT[1];	
	assign	mux_ctrl[4] = ~SHAMT[4] & ~SHAMT[3] & ~SHAMT[2] & ~SHAMT[1] &  SHAMT[0];	
	assign	mux_ctrl[5] = ~SHAMT[4] & ~SHAMT[3] & ~SHAMT[2] & ~SHAMT[1] & ~SHAMT[0];	

	MUX6to1	#(1)	MUX_C (
						.DI0		(lsr_mid3[15]),
						.DI1		(lsr_mid2[7]),
						.DI2		(lsr_mid1[3]),
						.DI3		(lsr_mid0[1]),
						.DI4		(DIN[0]),
						.DI5		(1'b0),
						.SEL		(mux_ctrl),
						.DO			(COUT)
					);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                               IF Stage Datapath                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module IF_DP (
	// FROM PIPELINE REG.
	input	wire	[29:0]		F_PC,

	// FROM ID_DP
	input	wire	[29:0]		PC_OFFSET,	// RELATIVE
	input	wire	[29:0]		PC_TARGET,	// ABSOLUTE

	// FROM INT_CTRL
	input	wire	[2:0]		INT_VEC,

	// FROM MEMORY
	input	wire	[31:0]		INSTR,

	// FROM ID_CP
	input	wire	[3:0]		PC_SEL,
	input	wire				IR_SEL,		// 0:INSTR, 1:NOP

	// TO PIPELINE REG. & MEMORY
	output	wire	[29:0]		PC_OUT,
	output	wire	[31:0]		IR_OUT
);

	wire	[29:0]		pc_rel;
	wire	[29:0]		pc_inc4;
	wire				co1;
	wire				co2;

	DW01_add #(30)	F_U1 (
						.A			(PC_OFFSET),
						.B			(F_PC),
						.CI			(1'b0),
						.SUM		(pc_rel),
						.CO			(co1)
					);

	DW01_add #(30)	F_U2 (
						.A			(F_PC),
						.B			(30'b1),
						.CI			(1'b0),
						.SUM		(pc_inc4),
						.CO			(co2)
					);


	MUX4to1	#(30)	F_MUX (
						.DI0		({27'b0, INT_VEC}), 
						.DI1		(PC_TARGET),
						.DI2		(pc_rel), 
						.DI3		(pc_inc4), 
						.SEL		(PC_SEL),
						.DO			(PC_OUT)
					);

	// NOP Insertion
	assign	IR_OUT = (~IR_SEL) ? INSTR : 32'b0;

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                               ID Stage Datapath                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module ID_DP (
	// FROM PIPELINE REG.
	input	wire	[29:0]			F_PC,
	input	wire	[31:0]			IR,

	input	wire	[23:0]			IDR,			// E_Y[23:0]

	// FROM GPR
	input	wire	[31:0]			GPR_X_RD,		// FROM GPR PORT 0
	input	wire	[31:0]			GPR_Y_RD,		// FROM GPR PORT 1

	// REG. FORWARDING
	input	wire	[31:0]			M_DA,
	input	wire	[31:0]			W_DA,
	input	wire	[31:0]			W_DB,

	// NZCV FORWARDING
	input	wire	[3:0]			E_NZCV,

	// FROM FWD_CTRL
	input	wire	[3:0]			REG_SEL,

	// FROM ID_CP
	input	wire	[7:0]			IMM_SEL,
	input	wire				COND_SEL,		// 0:COND, 1:CONDZ
	input	wire	[4:0]			SHAMT,			// IR[11:7]
	input	wire	[2:0]			X_SEL,
	input	wire	[2:0]			Y_SEL,

	// TO PIPELINE REG.
	output	wire	[31:0]			X_OUT,
	output	wire	[31:0]			Y_OUT,
	output	wire	[4:0]			Z_OUT,

	// TO IF_DP
	output	wire	[29:0]			PC_OFFSET,
	output	wire	[29:0]			PC_TARGET,

	// TO ID_CP
	output	wire					COND_TRUE
);

	// synopsys dc_script_begin
	// set_max_delay 0.6 -from all_inputs() -to all_outputs()
	// synopsys dc_script_end

	wire	[31:0]	imm_out;		// SELECTED IMMEDIATE VALUE
	wire	[31:0]	reg_out;		// SELECTED REGISTER VALUE

	// IMMEDIATE
	// ALL PC RELATIVE BRANCHES USE IMMEDIATE VALUE AS AN OFFSET.
	wire	[31:0]	concat	= {IDR[23:0], IR[14:12], IR[4:0]};
	wire	[31:0]	imm9s	= {{23{IR[15]}}, {IR[15:12], IR[4:0]}};
	wire	[31:0]	imm12z	= {20'b0, IR[11:0]};
	wire	[31:0]	imm12s	= {{20{IR[11]}}, IR[11:0]};		// MTA/MFA/LDC/STC
	wire	[31:0]	imm16z	= {16'b0, IR[15:0]};
	wire	[31:0]	imm16s	= {{16{IR[15]}}, IR[15:0]};
	wire	[31:0]	imm20s	= {{12{IR[19]}}, IR[19:0]};
	wire	[31:0]	imm24s	= {{8{IR[23]}}, IR[23:0]};

	wire	[31:0]	masked_imm12s = (IR[29] == 1'b1)? {imm12s[31:2],2'b0} : imm12s;
	// LDC/STC : IR[29] = 1'b1	MTA/MFA : IR[29] = 1'b0 - Edited by Ji-Hoon Kim_

	// IDR IS NOT REQUIRED BECAUSE CONCAT MODE SHOULD FOLLOW MUI INSTRUCTION.
	MUX8to1#(32)	MUX_IMM (
						.DI0		(concat),
						.DI1		(imm9s),
						.DI2		(imm12z),
						.DI3		(imm16z),
						.DI4		(imm16s),
						.DI5		(imm20s),
						.DI6		(imm24s),
						.DI7		(masked_imm12s),
						.SEL		(IMM_SEL),
						.DO			(imm_out)
					);

	// REGISTER AS A BRANCH TARGET
	// ALL ABSOLUTE BRANCHES USE REGISTER VALUE AS A TARGET.
	MUX4to1	#(32)	MUX_REG (
						.DI0		(M_DA),
						.DI1		(W_DA),
						.DI2		(W_DB),
						.DI3		(GPR_X_RD), 
						.SEL		(REG_SEL),
						.DO			(reg_out)
					);

	// OPERAND: X, Y, Z
	MUX3to1 #(32)	MUX_X (
						.DI0		(imm_out),
						.DI1		(GPR_X_RD),
						.DI2		({2'b0, F_PC}),
						.SEL		(X_SEL),
						.DO			(X_OUT)
					);

	MUX3to1 #(32)	MUX_Y (
						.DI0		(imm_out),
						.DI1		(GPR_Y_RD),
						.DI2		(IR),		// FOR CDP/MTC/MFC/LDC/STC
						.SEL		(Y_SEL),
						.DO			(Y_OUT)
					);

	assign	Z_OUT = SHAMT[4:0];

	// CONDITION CHECK
	wire	[1:0]	nz_out;
	wire			cond_out;
	wire			condz_out;

	// NZ CHECK
	assign	nz_out[1] = reg_out[31];
	assign	nz_out[0] = ~(| reg_out);

	COND_CHECK		D_COND (
						.NZCV		(E_NZCV[3:0]), 
						.COND		(IR[23:20]), 
						.OUT		(cond_out)
					);

	CONDZ_CHECK		D_CONDZ (
						.NZ			(nz_out), 
						.COND		(IR[22:20]), 
						.OUT		(condz_out)
					);

	assign	COND_TRUE = (~COND_SEL) ? cond_out : condz_out;
	assign	PC_OFFSET = imm_out[29:0];
	assign	PC_TARGET = reg_out[29:0];

endmodule


/*
 * 0000 Z or EQ
 * 0001 NZ or NE
 * 0010 GT
 * 0011 LT
 * 0100 GE
 * 0101 LE
 * 0110 AL
 * 0111 NO
 * 1000 N
 * 1001 NN
 * 1010 GTU
 * 1011 NC or LTU
 * 1100 C or GEU
 * 1101 LEU
 * 1110 V
 * 1111 NV
 */
module COND_CHECK (
	input	wire	[3:0]			NZCV,
	input	wire	[3:0]			COND,
	output	reg						OUT
);

	// synopsys dc_script_begin
	// set_max_delay 0.4 -from all_inputs() -to all_outputs()
	// synopsys dc_script_end

	always @ *
	begin
		casex(COND)		// synopsys parallel_case
						// synopsys full_case
			4'b0000: OUT <= NZCV[2];
			4'b0001: OUT <= ~NZCV[2];
			4'b0010: OUT <= ~(NZCV[2]|(NZCV[3]&(~NZCV[0]))|((~NZCV[3])&NZCV[0]));
			4'b0011: OUT <= ~(((~NZCV[3])&(~NZCV[0]))|(NZCV[3]&NZCV[0]));
			4'b0100: OUT <= ((~NZCV[3])&(~NZCV[0]))|(NZCV[3]&NZCV[0]);
			4'b0101: OUT <= NZCV[2]|(NZCV[3]&(~NZCV[0]))|((~NZCV[3])&NZCV[0]);
			4'b0110: OUT <= 1'b1;
			4'b0111: OUT <= 1'b0;
			4'b1000: OUT <= NZCV[3];
			4'b1001: OUT <= ~NZCV[3];
			4'b1010: OUT <= ~(~NZCV[1] | NZCV[2]);
			4'b1011: OUT <= ~NZCV[1];
			4'b1100: OUT <= NZCV[1];
			4'b1101: OUT <= ~NZCV[1] | NZCV[2];
			4'b1110: OUT <= NZCV[0];
			4'b1111: OUT <= ~NZCV[0];
		endcase
	end
endmodule


/*
 * 000 Z or EQ
 * 001 NZ or NE
 * 010 GT
 * 011 LT
 * 100 GE
 * 101 LE
 * 110 AL
 * 111 NO 
 */
module CONDZ_CHECK (
	input	wire	[1:0]			NZ,
	input	wire	[2:0]			COND,
	output	reg						OUT
);

	// synopsys dc_script_begin
	// set_max_delay 0.4 -from all_inputs() -to all_outputs()
	// synopsys dc_script_end

	always @ *
	begin
		casex(COND)		// synopsys parallel_case
						// synopsys full_case
			3'b000: OUT <= NZ[0];
			3'b001: OUT <= ~NZ[0];
			3'b010: OUT <= ~(NZ[0]|NZ[1]);
			3'b011: OUT <= 	NZ[1];
			3'b100: OUT <= ~NZ[1];
			3'b101: OUT <= 	NZ[0]|NZ[1];
			3'b110: OUT <= 1'b1;
			3'b111: OUT <= 1'b0;

		endcase
	end
endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                               EX State Datapath                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module EX_DP (
	// FROM PIPELINE REG.
	input	wire	[31:0]			PS,
	input	wire	[31:0]			E_X,
	input	wire	[31:0]			E_Y,
	input	wire	[4:0]			E_Z,
	input	wire	[1:0]			CPN,

	// REG. FORWARDING
	input	wire	[31:0]			M_DA,
	input	wire	[31:0]			W_DA,
	input	wire	[31:0]			W_DB,
	input	wire	[31:0]			P_DA,
	input	wire	[31:0]			P_DB,

	// NZCV FORWARDING
	input	wire	[3:0]			M_NZCV,

	// FROM FWD_CTRL
	input	wire	[5:0]			OP_X_SEL,
	input	wire	[5:0]			OP_Y_SEL,
	input	wire					NZCV_SEL,		// 0:PS,   1:M_NZCV

	// FROM EX_CP
	input	wire	[3:0]			ALU_OP,
	input	wire					ALU_X,
	input	wire	[7:0]			ALU_Y,
	input	wire	[2:0]			ALU_C,
	input	wire					ALU_PS_SEL,		// 0:OP_X, 1:PS

	input	wire					SHAMT_SEL,		// 0:IMM,  1:REG
	input	wire					SHIFT_DIR,		// 0:LEFT, 1:RIGHT
	input	wire	[4:0]			SHIFT_HI,
	input	wire					SHIFT_LO,

	input	wire					UMULT,			// 0:SIGNED, 1:UNSIGNED
	input	wire					ACC_HI_SEL,		// 0:32'b0,  1:Y
	input	wire					ACC_LO_SEL,		// 0:32'b0,  1:X

	input	wire					NZ_UPDATE,
	input	wire					C_UPDATE,
	input	wire					V_UPDATE,

	input	wire	[1:0]			MSIZE,			// MEMORY DATA SIZE

	input	wire					DA_SEL,			// 0:ALU, 1:SHIFT
	input	wire	[2:0]			MADDR_SEL,

	// TO ID_DP
	output	wire	[3:0]			E_NZCV,

	// TO PIPELINE REG.
	output	wire	[63:0]			ACC_OUT,
	output	wire	[63:0]			PPD1_OUT,
	output	wire	[63:0]			PPD2_OUT,
	output	wire	[31:0]			DA_OUT,
	output	wire	[1:0]			SHAMT_OUT,		// DHYOU EDIT
	output	wire	[3:0]			NZCV_OUT,


	// TO MEMORY
	output	wire	[31:0]			MADDR,
	output	wire	[31:0]			MDOUT,

	output	wire	[1:0]			DSIZE		// 00 : Byte	01 : Half-Word		10 : Word 

);

	wire	[31:0]		alu_op_x;
	wire	[31:0]		op_x;
	wire	[31:0]		op_y;
	wire	[31:0]		shift_out;
	wire	[31:0]		alu_out;

	wire				alu_c;
	wire				alu_v;
	wire				shift_c;
	wire	[1:0]		nz_out;
	wire	[4:0]		shamt;

	// OPERAND X
	MUX6to1			MUX_X (
						.DI0		(M_DA),
						.DI1		(W_DA),
						.DI2		(W_DB),
						.DI3		(P_DA),
						.DI4		(P_DB),
						.DI5		(E_X),
						.SEL		(OP_X_SEL),
						.DO			(op_x)
					);

	// OPERAND Y
	MUX6to1			MUX_Y (
						.DI0		(M_DA),
						.DI1		(W_DA),
						.DI2		(W_DB),
						.DI3		(P_DA),
						.DI4		(P_DB),
						.DI5		(E_Y),
						.SEL		(OP_Y_SEL),
						.DO			(op_y)
					);

	// OPERAND X FOR ALU ONLY
	assign	alu_op_x = (~ALU_PS_SEL) ? op_x : {PS[31:7], E_NZCV, PS[2:0]};
//	assign	alu_op_x = (~ALU_PS_SEL) ? op_x : {PS[31:7], M_NZCV, PS[2:0]};

	// SHIFT AMOUNT
	assign	shamt	= (~SHAMT_SEL) ? E_Z : op_x[4:0];

	// NZCV INPUT
	assign	E_NZCV	= (~NZCV_SEL) ? PS[6:3] : M_NZCV[3:0];


	// ARITHMETIC UNITS
	ALU				EX_ALU (
						.OP_X		(alu_op_x),
						.OP_Y		(op_y),
						.C_IN		(E_NZCV[1]),
						.MUX_CTRL_ALU(ALU_OP),
						.MUX_CTRL_X	(ALU_X),
						.MUX_CTRL_Y	(ALU_Y),
						.MUX_CTRL_C	(ALU_C),
						.C_OUT		(alu_c),
						.V_OUT		(alu_v),
						.ALU_OUT	(alu_out)
					);

	EXTRACTOR		EX_SHIFT (
						.OP_X		(op_x),
						.OP_Y		(op_y),
						.OP_Z		(shamt),
						.DIR		(SHIFT_DIR),
						.MUX_CTRL1	(SHIFT_LO),
						.MUX_CTRL2	(SHIFT_HI),
						.COUT		(shift_c),
						.DOUT		(shift_out)
					);

	MUL1			EX_MULT (
						.DX			(op_x),
						.DY			(op_y),
						.UMULT		(UMULT),
						.PPD1		(PPD1_OUT),
						.PPD2		(PPD2_OUT)
					);


	// OUTPUT
	assign		ACC_OUT[31:0]	= (~ACC_LO_SEL) ? 32'b0 : op_y;
	assign		ACC_OUT[63:32]	= (~ACC_HI_SEL) ? 32'b0 : op_x;
	assign		DA_OUT			= (~DA_SEL) ? alu_out: shift_out;

	// NZ CHECK
	assign	nz_out[1] = DA_OUT[31];
	assign	nz_out[0] = ~(| DA_OUT);

	// NZCV OUTPUT
	assign	NZCV_OUT[3:2]	= (~NZ_UPDATE) ? E_NZCV[3:2] : nz_out;
	assign	NZCV_OUT[1]		= (~C_UPDATE)  ? E_NZCV[1] : (~DA_SEL) ? alu_c : shift_c;
	assign	NZCV_OUT[0]		= (~V_UPDATE)  ? E_NZCV[0] : alu_v;

	// MEMORY ADDRESS
	// COPROCESSOR NUMBER
	// FOR ALIGNMENT CPN MUST BE MUTIPLE OF 4.
	wire	[31:0]	cpn		= {CPN, 30'b0};	// Edited by Ji-Hoon Kim

	MUX3to1	#(32)	MUX_MADDR (
						.DI0		(op_x),
						.DI1		(alu_out),
						.DI2		(cpn),
						.SEL		(MADDR_SEL),
						.DO			(MADDR)
					);


	assign	DSIZE = MSIZE;
	assign	MDOUT = op_y;

       // FOR MEMORY LOAD (ALIGN)
       assign  SHAMT_OUT       = MADDR[1:0];

endmodule



// DHYOU EDIT
module ST_GEN (
      input   wire            [31:0]          DIN,
      input   wire            [1:0]           SIZE,   // SIZE
      input   wire            [1:0]           SHAMT,  // EFFECTIVE ADDRESS
      output  wire            [31:0]          DOUT,
      output  reg             [3:0]           BE
);

      /*
       * SIZE
       *      2'b00: BYTE
       *              SHAMT: 00       : 4'b0001
       *              SHAMT: 01       : 4'b0010
       *              SHAMT: 10       : 4'b0100
       *              SHAMT: 11       : 4'b1000
       *      2'b01: HALFWORD
       *              SHAMT: 00       : 4'b0011
       *              SHAMT: 10       : 4'b1100
       *      2'b1x: WORD             : 4'b1111
       */

      wire    [3:0]   align_sel;
      wire            is_word = SIZE[1];

      assign  align_sel[0] = (SHAMT[1:0] == 2'b00) | is_word;
      assign  align_sel[1] = (SHAMT[1:0] == 2'b01) & ~is_word;
      assign  align_sel[2] = (SHAMT[1:0] == 2'b10) & ~is_word;
      assign  align_sel[3] = (SHAMT[1:0] == 2'b11) & ~is_word;

      MUX4to1 #(32)   MUX_MDOUT (
                                              .DI0            (DIN),
                                              .DI1            ({DIN[23:0], 8'b0}),
                                              .DI2            ({DIN[15:0], 16'b0}),
                                              .DI3            ({DIN[7:0], 24'b0}),
                                              .SEL            (align_sel),
                                              .DO             (DOUT)
                                      );

      always @ *
      begin
              casex ({SIZE, SHAMT})   // synopsys full_case
                      4'b00_00:       BE <= 4'b0001;
                      4'b00_01:       BE <= 4'b0010;
                      4'b00_10:       BE <= 4'b0100;
                      4'b00_11:       BE <= 4'b1000;
                      4'b01_0x:       BE <= 4'b0011;
                      4'b01_1x:       BE <= 4'b1100;
                      4'b1x_xx:       BE <= 4'b1111;
              endcase
      end
endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                              MEM Stage Datapath                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module MEM_DP (
	// FROM MEM PIPELINE REG.
	input	wire	[63:0]			PPD1,
	input	wire	[63:0]			PPD2,
	input	wire	[63:0]			ACC,
	input	wire	[31:0]			DA,
	input	wire	[1:0]			SHAMT,		// DHYOU EDIT (ADDED)
	input	wire	[3:0]			NZCV,

	// FROM MEMORY
	input	wire				MSIGN,
	input	wire	[1:0]			MSIZE,
	input	wire	[31:0]			MDIN,

	// FROM MECP
	input	wire				DA_SEL,		// 0:DA,  1:MUL
	input	wire				DB_SEL,		// 0:MEM, 1:MUL

	// TO PIPELINE REG.
	output	wire	[31:0]			DA_OUT,
	output	wire	[31:0]			DB_OUT,
	output	wire	[3:0]			NZCV_OUT
);

	wire	[31:0]			mult_hi;
	wire	[31:0]			mult_lo;
	wire	[31:0]			align_out;

	// MULTIPLY CYCLE 2
	MUL2			MEACC (
						.PPD1		(PPD1),
						.PPD2		(PPD2),
						.ACC		(ACC),
						.HI			(mult_hi),
						.LO			(mult_lo)
					);

	// MEMORY LOAD
	LD_EXTENSION	MEXTENSION (
						.DIN		(MDIN),
						.SIGN		(MSIGN),
						.SIZE		(MSIZE),
						.DOUT		(align_out)
					);

	
	assign	DA_OUT	= (~DA_SEL) ? DA : mult_hi;
	assign	DB_OUT	= (~DB_SEL) ? align_out : mult_lo;

	assign	NZCV_OUT	= NZCV;

endmodule



// DHYOU EDIT
module LD_ALIGN (
        input   wire            [31:0]          DIN,
        input   wire                            SIGN,
        input   wire            [1:0]           SHAMT,  // EFFECTIVE ADDRESS
        input   wire            [1:0]           SIZE,
        output  wire            [31:0]          DOUT
);

        wire    [3:0]   mux_ctrl1;
        wire    [2:0]   mux_ctrl2;
        wire    [31:0]  mux_out;
        wire            msb;

        assign  mux_ctrl1[0] = (SHAMT[1:0] == 2'b00);
        assign  mux_ctrl1[1] = (SHAMT[1:0] == 2'b01);
        assign  mux_ctrl1[2] = (SHAMT[1:0] == 2'b10);
        assign  mux_ctrl1[3] = (SHAMT[1:0] == 2'b11);

        assign  mux_ctrl2[0] = (SIZE[1:0] == 2'b00);
        assign  mux_ctrl2[1] = (SIZE[1:0] == 2'b01);
        assign  mux_ctrl2[2] = (SIZE[1]   == 1'b1);

        MUX4to1 #(32)   MUX1 (
                                                .DI0            (DIN),
                                                .DI1            ({8'b0, DIN[31:8]}),
                                                .DI2            ({16'b0, DIN[31:16]}),
                                                .DI3            ({24'b0, DIN[31:24]}),
                                                .SEL            (mux_ctrl1),
                                                .DO             (mux_out)
                                        );

        assign  msb = ((SIZE[0]) ? mux_out[15] : mux_out[7]) & SIGN;

        MUX3to1 #(32)   MUX3 (
                                                .DI0            ({{24{msb}}, mux_out[7:0]}),
                                                .DI1            ({{16{msb}}, mux_out[15:0]}),
                                                .DI2            (mux_out[31:0]),
                                                .SEL            (mux_ctrl2),
                                                .DO             (DOUT)
                                        );
endmodule


module LD_EXTENSION (
	input	wire		[31:0]		DIN,
	input	wire					SIGN,
	input 	wire		[1:0]		SIZE,
	output	wire		[31:0]		DOUT
);

	wire	[2:0]	mux_ctrl;
	wire			msb;

	assign	mux_ctrl[0] = (SIZE[1:0] == 2'b00);
	assign	mux_ctrl[1] = (SIZE[1:0] == 2'b01);
	assign	mux_ctrl[2] = (SIZE[1]   == 1'b1);


	assign	msb = ((SIZE[0]) ? DIN[15] : DIN[7]) & SIGN;

	MUX3to1	#(32)	MUX3 (
						.DI0		({{24{msb}}, DIN[7:0]}),
						.DI1		({{16{msb}}, DIN[15:0]}),
						.DI2		(DIN[31:0]),
						.SEL		(mux_ctrl),
						.DO			(DOUT)
					);
endmodule
/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                               WB Stage Datapath                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module WB_DP (
	input	wire	[29:0]			W_PC,
	input	wire	[31:0]			PS,
	input	wire	[3:0]			W_NZCV,
	input	wire	[31:0]			DA,
	input	wire	[2:0]			INT_DED,

	// FROM WB_CP
	input	wire	[3:0]			PS_SEL,
	input	wire					GPR_A_SEL,

	output	wire	[31:0]			PS_OUT,
	output	wire	[31:0]			GPR_A_WD
);

	// GPR PORT A UPDATE
	assign	GPR_A_WD = (~GPR_A_SEL) ? DA : {2'b0, W_PC[29:0]};

	// PS UPDATE
	MUX4to1	#(32)	MUX_PS	(
						.DI0		({PS[31:7], W_NZCV, PS[2:0]}),	// NZCV UPDATE
						.DI1		({PS[15], INT_DED, PS[11:0], 14'b0, 2'b01}), 	// INTERRUPT
						.DI2		({16'b0, PS[31:16]}),			// RFI
						.DI3		(DA),							// MOVTPS
						.SEL		(PS_SEL),
						.DO			(PS_OUT)
					);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                                DECODER PLA                                  *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module pla( v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,v17_0,v17_1,v17_2,v17_3,v17_4,v17_5,v17_6,v17_7,v17_8,v17_9,v17_10,v17_11,v17_12,v17_13,v17_14,v17_15,v17_16,v17_17,v17_18,v17_19,v17_20 );
input v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16;
output v17_0,v17_1,v17_2,v17_3,v17_4,v17_5,v17_6,v17_7,v17_8,v17_9,v17_10,v17_11,v17_12,v17_13,v17_14,v17_15,v17_16,v17_17,v17_18,v17_19,v17_20;
	assign v17_0 = (~v0&v1&v2&v3&v4&~v7) | (~v0&v1&v2&v3&v4&~v5);
	assign v17_1 = (~v0&v1&~v2&v4&v5&~v12&~v13&~v14&~v15) | (~v0&v1&~v2&v4&~v12&v14
    &v15) | (~v0&v1&~v2&~v4&v5&~v9) | (~v0&v1&~v2&v4&v13&v14) | (~v0&~v1
    &~v3&~v4);
	assign v17_2 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v10&~v11) | (~v0&v1&~v2&~v3&~v4
    &v5&v6&~v7&~v8&v10&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&~v11) | (
    ~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6
    &~v7&v8&~v9&v10) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&v8&v9) | (~v0&~v2&v5
    &~v12&~v13) | (~v0&~v1&v2&v3&~v4) | (~v0&~v1&v2&v3&v4) | (~v0&v1&~v2
    &v4&~v12&~v14) | (~v0&v1&~v2&~v4&v6&v7) | (~v0&~v1&v2&~v3&~v4) | (~v0
    &~v1&v2&~v3&v4) | (~v0&~v1&~v2&~v11) | (~v0&~v1&~v2&v11);
	assign v17_3 = (v1&v4&v5);
	assign v17_4 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v10&~v11) | (~v0&v1&~v2&~v3&~v4
    &v5&v6&~v7&~v8&v10&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&~v11) | (
    ~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6
    &~v7&v8&~v9&v10) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&v8&v9) | (~v0&v1&v4
    &~v5&~v14) | (~v0&v1&~v2&~v4&v6&v7);
	assign v17_5 = (~v0&v1&~v2&v4&~v12&~v14) | (~v0&v1&~v2&~v4&v6&v7) | (v1&v4&v5);
	assign v17_6 = (v0&~v1&~v2&~v3&v4&~v5) | (v0&~v1&~v2&~v3&v4&v5) | (~v0&v1&v2&v3
    &v4&~v5) | (~v0&v1&v4&~v5&~v14) | (~v0&~v1&v2&v3&v4) | (v0&v1&v2&v6) | (
    ~v0&v1&v2&~v3&v4) | (~v0&~v2&v3&v4) | (v1&v3&~v4);
	assign v17_7 = (~v0&v1&v2&v3&v4&~v7) | (~v0&v1&v2&v3&v4&~v5) | (~v0&v1&v2&~v3&~v4) | (
    ~v0&v1&v2&~v3&v4) | (v1&v3&~v4);
	assign v17_8 = (~v0&v1&~v2&~v3&~v4&~v5&~v6);
	assign v17_9 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v10&~v11) | (~v0&v1&~v2&~v3&~v4
    &v5&v6&~v7&~v8&v10&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&~v11) | (
    ~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6
    &~v7&v8&~v9&v10) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&v8&v9) | (v0&v1&v2
    &~v3&v5&~v6) | (~v0&v1&~v2&~v3&~v4&~v5&~v6) | (v0&~v1&~v2&~v3&v4&v5) | (
    ~v0&v1&~v2&v4&~v12&~v14) | (v0&~v1&v2&~v3) | (~v0&v1&~v2&~v4&v6&v7) | (
    v0&v1&~v2&~v3&v6) | (~v0&v1&v2&~v3&~v4) | (~v0&~v1&v2&~v3&~v4) | (~v0
    &~v1&v2&~v3&v4) | (~v0&v1&v2&~v3&v4) | (v1&~v16) | (~v0&~v1&~v2&~v11) | (
    ~v0&~v1&~v2&v11) | (v1&v4&v5) | (v0&~v5) | (v3);
	assign v17_10 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v10&~v11) | (~v0&v1&~v2&~v3&~v4
    &v5&v6&~v7&~v8&v10&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&~v11) | (
    ~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v9&v11) | (~v0&v1&~v2&~v3&~v4&v5&v6
    &~v7&v8&~v9&v10) | (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&v8&v9) | (~v0&v1&~v2
    &v4&v13&v14) | (~v0&~v2&v5&~v12&~v13) | (~v0&~v1&v2&v3&~v4) | (~v0&~v1
    &v2&v3&v4) | (~v0&v1&~v2&v4&~v12&~v14) | (~v0&v1&~v2&~v4&v6&v7) | (
    ~v0&~v1&v2&~v3&~v4) | (~v0&~v1&v2&~v3&v4) | (~v0&~v1&~v2&~v11) | (~v0
    &~v1&~v2&v11) | (v1&~v2&~v6);
	assign v17_11 = (v0&~v1&~v2&~v3&~v4&v5&~v15&v16) | (~v0&v1&~v2&v4&~v5&~v14&~v15
    &v16) | (~v0&v1&~v2&~v4&v6&~v7&~v9&~v10) | (v1&~v2&v4&~v6&v12&~v14
    &v16) | (v1&~v2&v4&~v5&~v6&v14&v15) | (~v0&v1&~v2&~v4&v6&v7&v8) | (
    v1&~v2&v4&~v6&v12&v13) | (v1&~v2&v4&~v5&~v6&v12) | (~v0&v1&~v2&~v5&v6
    &v14) | (~v0&v1&~v2&v4&~v5&v13) | (~v0&v1&~v2&v4&v6&v12) | (v1&v3&v4
    &v5&v7) | (~v0&v1&~v2&~v4&~v5&v6) | (v0&v1&v2&v5&v6) | (v0&v1&v4&~v5
    &~v6) | (v0&v2&v3&v4) | (v1&~v2&~v4&v5&~v6) | (v0&v1&~v2&~v6) | (v0
    &v1&v3) | (v1&~v2&v3);
	assign v17_12 = (v0&~v1&~v2&~v3&~v4&~v5);
	assign v17_13 = (v0&v1&v2&~v3&v5&~v6) | (v0&~v1&~v2&~v3&v4&v5);
	assign v17_14 = (~v0&v1&~v2&~v3&~v4&~v5&~v6) | (~v0&v1&v2&~v3&~v4);
	assign v17_15 = (~v0&v1&v2&~v3&v4);
	assign v17_16 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&v8&~v9&v10) | (~v0&v1&v2&v3&v4&~v7) | (
    ~v0&v1&v2&v3&v4&~v5) | (~v0&~v1&v2&v3&v4) | (~v0&~v1&v2&~v3&~v4);
	assign v17_17 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&v8&v9) | (v0&~v1&~v2&~v3&~v4&~v5) | (
    v0&~v1&~v2&~v3&v4&~v5) | (~v0&~v1&v2&v3&~v4) | (v0&v1&~v2&~v3&v6) | (
    ~v0&~v1&v2&~v3&v4);
	assign v17_18 = (v0&~v1&v2&~v4) | (v0&~v1&v2&~v3);
	assign v17_19 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v10&~v11) | (~v0&v1&~v2&~v3&~v4
    &v5&v6&~v7&~v8&v9&~v11) | (~v0&~v1&~v2&~v11);
	assign v17_20 = (~v0&v1&~v2&~v3&~v4&v5&v6&~v7&~v8&v10&v11) | (~v0&v1&~v2&~v3&~v4
    &v5&v6&~v7&~v8&v9&v11) | (~v0&~v1&~v2&v11);
endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                                    DECODER                                  *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

/******************************************/
//	FOR ALU
`define		AOP_ADD		4'b0000
`define		AOP_SUB		4'b0001
`define		AOP_AND		4'b0010
`define		AOP_XOR		4'b0011
`define		AOP_OR		4'b0100
`define		AOP_NOR		4'b0101
`define		AOP_ADC		4'b0110
`define		AOP_SBB		4'b0111
`define		AOP_MOVI	4'b1000		// MOVI, MOVIS
`define		AOP_RSBI	4'b1001
`define		AOP_ANDNI	4'b1010
/*******************************************/

module DECODER ( 

	// synopsys dc_script_begin
	// set_max_delay 0.5 -from all_inputs() -to all_outputs()
	// synopsys dc_script_end

	/******* Input  ************************************************************************/
	input 	wire	[31:0]			IR,			// Instruction
	input	wire	[1:0]			PS_MODE,	// PS MODE : current PS mode. i.e. PS[1:0]

	/******* output ************************************************************************/
	output	wire	[7:0]			CT_IMM,		// IMM
	output	wire	[3:0]			CT_ALU,		// Control signal for the mux
	// Shift-relevant
	output	wire	[2:0]			CT_SHIFT,	// Shift Operation Type	: 
	output	wire					DO_SHIFT,	// 1: shift! 0: Do NOT shift 
	output	wire	[4:0]			SHAMT,		// SHIFT AMOUNT ( IR[15:11] or IR[11:7] )
	
	output	wire					UMULT,		// 1: Unsigned MUL

	///////////////////////////////////////////////////////////////////
	// Bypassed from IR
	output	wire					N,			// IR[31]		-
	// R1 ~ R4
	output	wire	[3:0]			R1,			// IR[23:20]	-
	output	wire	[3:0]			R2,			// IR[19:16]	-
	output	wire	[3:0]			R3,			// IR[15:12]	-
	output	wire	[3:0]			R4, 		// IR[11: 8]	-

	// LD/STM-relevant
	output	wire					SIGN,		// IR[22]		-
	output	wire	[1:0]			SIZE,		// IR[21:20]	-
	output	wire	[15:0]			PAT,		// IR[15:0]
	///////////////////////////////////////////////////////////////////

	// Cond.-relevant
	output	wire	[1:0]			CUT,		// Condition Update : NZ, NZC, NZCV or NU (Not Update)
	output	wire					USE_CONDZ,	// 0: Use COND (IR[23:20]), 1: Use CONDZ (IR[22:20])
	output	wire					CONDINST,	// 1: Conditional inst. 0: Non-cond. inst
	
	// Inst. property-relevant
	output	wire					ATOMIC,		// 0: Not Atomic, 1: Atomic
	output	wire					INVD,		// 1: Invalid inst. 
	output	wire					SWI,		// 1: This inst. is SWI	
	output	wire					U			// Bypass U field (IR[24]) when U exists, 0 whenever no U field exists
);

	///////////////////////////////////////////////////////////////////
	// Internal Wires & Reg.s
	// IMode : Immediate mode : IMM9, IMM12Z, IMM16{Z,S}, IMM20S, IMM24Z, ASRI (=Use {ASR_AH, ASR_AL})
	wire			[2:0]			IMode;		
	wire			[1:0]			SelA;		// SEL_FG for ALU
	wire							SelS;		// SEL_FG for Shifter
	wire							SelShamt;	// SEL_SHAMT	- determine which FG to use for SHAMT
	
	//USRMODE : NOUSR(0) :User mode prohibited 	: MOVTPS, RFI only, USRAL(1): User mode allowed
	wire							UAINST;		// User-mode allowed inst. i.e NOT Supervisor-mode-Only Inst.
	wire							UNDEF_INST;	// Undefined inst. i.e) not listed in the inst. map (INVDx in control.txt)
	wire							HAS_U;
	wire			[1:0]			Atomic_mode;// 'Atomic' field in Table 1 - 00: NA, 01: AA, 10: BRSLT

	// Wires for CT_SHIFT
	wire							EXTD;		//	IR[25],[3],[2] 110: EXTD
	wire			[1:0]			SHTYPE;
	reg			[3:0]			REG_CT_ALU;	// Control signal for the mux
	///////////////////////////////////////////////////////////////////
	
	//
	// Assignment 
	//
	// Output
	// 
	/////////////////////////////////////
	// UMULT - 1: Unsigned MUL	- IR[2:0] == 101 (MULUL) or 111 (MACUL)
	assign	UMULT	= IR[2] & IR[0];
	//	
	/////////////////////////////////////
	// Bypassed Field from IR
	// R1 ~ R4
	assign	R1		= IR[23:20];
	assign	R2		= IR[19:16];
	assign	R3		= IR[15:12];
	assign	R4		= IR[11: 8];

	assign	SIGN	= IR[22];
	assign	SIZE	= IR[21:20];
	assign	PAT		= IR[15:0];

	assign	N		= IR[31];
	/////////////////////////////////////

	assign	U		= (HAS_U) ? IR[24]: 1'b0;		// BR-type inst. with slot		MUI	
	
	// [restored]
	assign	ATOMIC	= ( |Atomic_mode ) ? ((Atomic_mode[1] & IR[24]) | Atomic_mode[0]) : 1'b0 ;
	// Atomic_mode == 00 -> 0, Atomic_mode == 01: MUI (always atomic)
	// Atomic_mode == 10 : br. with slot - if SLOT==1 -> 1 (IR[24] indicates)

	// [invalidated]
	// MUI or Br. with slot (even in case SLOT==0) - Atomic.
	//assign	ATOMIC = ( |Atomic_mode )? 1'b1 : 1'b0;
	
	// INVD
	// 1) Undefined instruction	such as INVD3 in control.txt
	// 2) PS_MODE == 00 (User mode) and the current inst. is a Supervisor-mode-only inst.(MOVTPS, RFI)
	// where UAINST: user-mode-allowed inst
	assign	INVD	= UNDEF_INST | ( ~UAINST & ~PS_MODE[1] & ~PS_MODE[0] ); 

	/********************************************************************/

	// 1. pla.v
	//	Table input:	IR[30:20]xIR[6]xIR[4:0]
	pla TableDec ( 
																			
		IR[30], IR[29], IR[28], IR[27], IR[26], IR[25], IR[24], IR[23], IR[22], IR[21], IR[20],
		IR[6], IR[4], IR[3], IR[2], IR[1], IR[0],
		USE_CONDZ,
		CUT[1], CUT[0],		// CUT=00: NU, 01: NZ, 10: NZC, 11:NZCV
		SelA[1], SelA[0],
		SelS,			// 0: Use MODE		1: Use SHTYPE
		CONDINST,
		Atomic_mode[1], Atomic_mode[0],
		UAINST,			// User-mode-Allowed Inst. i.e) Not Supervisor-mode-only inst.
		HAS_U,
		UNDEF_INST,		//	1: undefined inst. 
		SWI,			// 	1: this inst. is SWI
		CT_IMM[7], CT_IMM[6], CT_IMM[5], CT_IMM[4], CT_IMM[3], CT_IMM[2], CT_IMM[1], CT_IMM[0]
		);

	/****************************************************************/		
	// 2. CT_ALU
	// <Input>
	// SEL_FG : Select the group of bits to use
	// 0: IR[27:25]	 
	// 1: IR[21:20]	
	// 2: IR[2:0]	
	// <Output>
	// [3:0] CT_ALU: control signal to determine the ALU op. type
	assign	CT_ALU	= REG_CT_ALU;			// CT_ALU: output signal (DECODER)
	always@*
	begin
		casex( { SelA, IR[27:25] } )	// synopsys full_case
										// synopsys parallel_case
			// Use FG0: ADDI, RSBII, ANDI, XORI, ORI, ANDNII, MOVI, MOVIS
			6'b00_000: 	REG_CT_ALU	= `AOP_ADD;
			6'b00_001: 	REG_CT_ALU	= `AOP_RSBI;
			6'b00_010: 	REG_CT_ALU	= `AOP_AND;
			6'b00_011: 	REG_CT_ALU	= `AOP_XOR;
			6'b00_100: 	REG_CT_ALU	= `AOP_OR;
			6'b00_101: 	REG_CT_ALU	= `AOP_ANDNI;
			6'b00_11x: 	REG_CT_ALU	= `AOP_MOVI;	// MOVI, MOVS
		
			// Use FG1: TADD ~ TXOR, TSUBI, TANDI, TXORI	
			6'b01_xxx:	REG_CT_ALU= { 2'b00, IR[21:20] };

			// Use FG2: ADD, SUB, AND, XOR, OR, NOR, ADC, SBB
			6'b10_xxx: 	REG_CT_ALU= { 1'b0, IR[2:0] };
			  default:	REG_CT_ALU= 4'bx;		// For Warning Suppression
		endcase
	end	
	/**************************************************************************************************/		
	
	/**************************************************************************************************/		
	// 4. CT_SHIFT
	// [NOTE]	DO_SHIFT deleted
	// SHTYPE(=IR[6:5])		CT_SHIFT	MODE (=IR[6:5])							
	// ROR		00			3'b000		ROR	
	// SHL		01			3'b001		SHL
	// LSR		10			3'b010		CONCATENATE
	// ASR		11			3'b011		CONCATENATE
	// EXTD					3'b100		- 
		
	// [NOTE]	DO_SHIFT deleted
	// 1. CT_SHIFT	
	// 1) SelS == 0:	Use MODE[0]
	// 2) SelS == 1: 	i)  Use SHTYPE ( not EXTD inst.)
	// 					ii) Outputs 100 - indicates EXTD
	
	// Internal wire assignment
	assign	SHTYPE	= IR[6:5]; 		// SelS==0: MODE , 1: SHTYPE 
	assign	EXTD	= IR[25] & IR[3] & ~IR[2];	// IR[25],[3],[2] 110: EXTD

	// Outputs : CT_SHIFT and SHAMT
	assign	CT_SHIFT = (~SelS)? { 2'b00, SHTYPE[0] } : ((EXTD)? 3'b100 : {1'b0, SHTYPE});
	// SHIFT amount
	assign	SHAMT	= IR[11:7];
	// DO_SHIFT for datapath ( NOT to be used in Comm. Gen )
	assign	DO_SHIFT = |SHAMT;
	/**************************************************************************************************/		

endmodule

/******************************************************************************
*                                                                             *
*                            Core-A Processor                                 *
*                                                                             *
*                                                                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                               Designed By Ji-Hoon Kim       *
*                                                          Duk-Hyun You       *
*                                                          Ki-Seok Kwon       *
*                                                           Eun-Joo Bae       *
*                                                           Won-Hee Son       *
*                                                                             *
*                                           Supervised By In-Cheol Park       *
*                                                                             *
*                                        E-mail : icpark@ee.kaist.ac.kr       *
*                                                                             *
*******************************************************************************/

module CMD_PLA( v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,v17,v18,v19,v20_0,v20_1,v20_2,v20_3,v20_4,v20_5,v20_6,v20_7,v20_8,v20_9,v20_10,v20_11,v20_12,v20_13,v20_14,v20_15,v20_16,v20_17,v20_18,v20_19,v20_20,v20_21,v20_22,v20_23,v20_24,v20_25,v20_26,v20_27,v20_28,v20_29,v20_30,v20_31,v20_32,v20_33,v20_34,v20_35,v20_36,v20_37,v20_38,v20_39,v20_40,v20_41,v20_42,v20_43,v20_44,v20_45,v20_46,v20_47,v20_48 );
input v0,v1,v2,v3,v4,v5,v6,v7,v8,v9,v10,v11,v12,v13,v14,v15,v16,v17,v18,v19;
output v20_0,v20_1,v20_2,v20_3,v20_4,v20_5,v20_6,v20_7,v20_8,v20_9,v20_10,v20_11,v20_12,v20_13,v20_14,v20_15,v20_16,v20_17,v20_18,v20_19,v20_20,v20_21,v20_22,v20_23,v20_24,v20_25,v20_26,v20_27,v20_28,v20_29,v20_30,v20_31,v20_32,v20_33,v20_34,v20_35,v20_36,v20_37,v20_38,v20_39,v20_40,v20_41,v20_42,v20_43,v20_44,v20_45,v20_46,v20_47,v20_48;
	assign v20_0 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v12&~v13&v18) | (~v0&v1&~v2&~v3&v4
    &~v5&~v9&~v10&v11&~v12&~v13) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&v12
    &v18) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v12&~v13) | (~v0&v1&~v2&~v3&v4
    &v5&v9&~v10&v11&~v12) | (~v0&~v2&~v3&v4&v5&~v9&~v10&v14&v18) | (v0&v2
    &~v3&~v4&v5&~v6&v17&v18) | (v0&v1&v2&~v3&v4&~v5&v6&v18) | (~v0&~v2&~v3
    &~v4&v5&~v8&v14&v18) | (v0&v1&v2&~v3&v4&v5&~v6&v17) | (v0&~v1&~v2&~v3
    &~v4&~v12&v13) | (~v0&v1&v4&v9&~v11&v13) | (v0&~v1&~v2&v3&~v4&~v5&~v7) | (
    ~v0&~v2&~v3&~v4&v5&~v8&~v14) | (v0&~v1&~v2&~v3&v4&~v5&v6) | (v0&v1&~v2
    &~v15&~v19) | (v0&~v1&~v2&v3&~v5&v7&v18) | (v0&v1&v2&~v3&~v4&~v5&v18) | (
    v0&~v1&~v2&~v3&v4&~v6&v18) | (v0&~v1&v2&~v3&~v4&~v5&~v7) | (v0&~v1&v3
    &~v4&v5&v18) | (v0&~v1&v2&v3&~v4&v18) | (~v0&v1&~v2&~v3&~v4&~v5) | (
    v0&~v1&v2&~v3&~v5&v7&v18) | (~v0&~v2&~v3&v4&v5&~v9&~v14) | (v0&~v1&v2
    &~v4&v5&v18) | (~v0&v1&~v5&~v11) | (~v0&v1&~v5&v12) | (~v0&v1&~v5&v9) | (
    ~v0&v1&~v4&v8) | (~v0&v1&v4&v10) | (~v0&~v1&~v2&~v4&v14&v18) | (~v0
    &v1&v2&~v3&v4) | (v1&v2&v5&v6) | (v0&v1&~v5&~v6) | (v0&v1&~v2&~v6) | (
    ~v0&~v1&~v2&~v3&v14&v18) | (v0&~v1&~v2&~v3&v4&v5&v6) | (~v1&v17&v18) | (
    ~v0&v1&v2&~v4) | (~v0&v17&v18) | (v0&~v1&~v2&v3&v4) | (v0&~v1&~v2&~v3
    &~v4&~v5) | (~v1&v2&v3&v4) | (v0&~v1&v2&~v3&v4) | (~v0&~v1&~v2&v3&v4) | (
    v1&v3) | (~v0&~v1&~v4&~v14) | (~v0&~v1&v2&~v3) | (~v0&~v1&~v3&~v14) | (
    ~v0&~v1&v2&~v4);
	assign v20_1 = (v0&~v1&~v4&v5&~v12&~v13&v17&v18) | (~v0&v1&v2&v3&~v5&~v6) | (~v0
    &v1&v2&~v6&~v7) | (~v0&v1&v2&~v4&~v6) | (~v0&v1&v2&~v3&~v6) | (v0&~v1
    &~v2&~v3&~v4&~v5);
	assign v20_2 = (~v0&v1&v2&v3&~v5&v6) | (~v0&v1&v2&v3&~v5&~v6) | (~v0&v1&v2&v3&v4
    &v5&~v7) | (~v0&v1&v2&~v3&v4) | (~v0&v1&v2&~v4);
	assign v20_3 = (v0&~v1&~v4&v5&~v12&~v13&v17&v18) | (~v0&v1&v2&v3&~v5&v6) | (~v0
    &v1&v2&v3&~v5&~v6) | (~v0&v1&v2&v3&v4&v5&~v7) | (~v0&v1&v2&v3&~v4&v5) | (
    ~v0&v1&v2&~v3&v4);
	assign v20_4 = (~v0&v1&v2&~v4);
	assign v20_5 = (v0&v1&~v2&~v3&v4&v6&~v15&v19) | (v0&v1&~v2&~v3&~v4&v6&~v15&v19) | (
    v0&v1&~v2&~v3&v6&v15);
	assign v20_6 = (v0&v1&~v2&~v3&v4&v6&~v15&v19) | (v0&v1&~v2&~v3&~v4&v6&~v15&v19);
	assign v20_7 = (~v0&~v2&~v3&~v4&v5&~v8&v14&~v18) | (~v0&~v2&~v3&v4&v5&~v9&v14
    &~v18) | (v0&~v1&~v2&v3&~v4&~v5&~v18) | (v0&~v1&~v2&~v3&~v4&~v13) | (
    v0&v2&~v3&~v4&~v5&~v18) | (~v0&~v1&~v2&v14&~v18) | (~v1&v2&~v6);
	assign v20_8 = (v0&v1&~v2&~v3&~v4&v6&~v15&v19) | (v0&v1&~v2&~v3&v6&v15);
	assign v20_9 = (v0&v1&v2&~v3&~v4&~v6&~v17) | (v0&~v1&~v2&v3&~v4&~v5&~v18) | (v0
    &v2&~v3&~v4&~v5&~v18) | (v0&~v1&~v2&v3&v5&~v18) | (v0&~v1&v2&~v4&~v18) | (
    v0&~v1&~v3&v4&v5&~v18);
	assign v20_10 = (v0&~v1&~v2&~v3&~v5&~v6&~v18) | (v0&~v1&~v2&v3&v5&~v18);
	assign v20_11 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&v11&~v12&v13&v15) | (~v0&v1&~v2
    &~v3&v4&v5&v9&~v10&v11&~v18) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v13&~v18) | (
    ~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&v12&v18) | (~v0&v1&~v2&~v3&v4&v5&v9
    &~v10&~v12&~v13) | (v0&~v1&~v4&v5&~v12&~v13&v17&v18) | (v0&~v1&~v2&~v3
    &~v4&v5&~v12&~v13&v15) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&~v12) | (
    ~v0&~v2&~v3&v4&v5&~v9&~v10&v14&v18) | (~v0&~v2&~v3&~v4&v5&~v8&v14&v18) | (
    ~v0&v1&~v2&~v3&~v4&v5&~v7&v8) | (v0&v2&~v3&~v4&v5&~v6&v17&~v18) | (
    ~v0&v1&v2&v3&v4&~v5&v7) | (v0&~v1&~v2&v3&~v4&~v5&~v18) | (~v0&v1&~v2
    &~v3&v4&v5&~v9&v10) | (v0&v1&v2&~v3&v4&v5&~v6&v15) | (~v0&v1&v2&v3&v4
    &v5&~v7) | (v0&~v1&~v2&v3&~v4&~v5&~v7) | (v0&~v1&~v2&~v3&~v5&~v6&~v18) | (
    ~v0&~v2&~v3&~v4&v5&~v8&~v14) | (v0&~v1&~v2&~v3&v4&~v5&v6) | (v0&~v1
    &~v2&v3&~v5&v7&v18) | (v0&~v1&v2&~v3&~v4&~v5&~v7) | (~v0&v1&v2&v3&~v4
    &v5) | (v0&v1&~v2&~v3&v6&v15) | (v0&~v1&~v2&v3&v5&~v18) | (v0&~v1&v2
    &~v3&~v5&v7&v18) | (~v0&~v2&~v3&v4&v5&~v9&~v14) | (~v0&~v1&~v2&~v4
    &v14&v18) | (v0&~v1&v2&~v4&~v18) | (v0&~v1&~v3&v4&v5&~v18) | (~v0&~v1
    &~v2&~v3&v14&v18) | (v0&~v1&~v2&~v3&v4&v5&v6) | (v0&~v1&~v2&v3&v4) | (
    ~v0&v1&v2&~v3&v5) | (v0&~v1&~v2&~v3&~v4&~v5) | (~v0&~v1&v2&~v5) | (
    v0&~v1&v2&~v3&v4) | (~v0&~v1&~v4&~v14) | (~v0&~v1&v2&~v3) | (~v0&~v1
    &~v3&~v14) | (~v0&~v1&v2&~v4);
	assign v20_12 = (v0&v2&~v3&~v4&v5&~v6&v17&~v18) | (v0&v1&v2&~v3&v4&v5&~v6&v15) | (
    v0&~v1&~v2&~v3&~v5&~v6&~v18) | (v0&~v1&~v2&~v3&v4&~v5&v6) | (v0&~v1
    &~v2&~v3&~v4&~v5) | (~v1&v2&v3&v4);
	assign v20_13 = (~v0&v1&v2&v3&v4&~v5&v7) | (~v0&v1&v2&v3&~v4&v5) | (~v0&v1&v2&~v3
    &v5);
	assign v20_14 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&v11&~v12&~v13) | (v0&~v1&~v2&~v3
    &~v4&v5&v12&v15);
	assign v20_15 = (v0&v1&~v2&~v3&v6&v7&~v15&~v19) | (v0&v1&v2&~v3&v4&v5&~v6&v7&~v15) | (
    v0&v2&~v3&~v4&v5&~v6&v17&v18) | (v0&v1&~v2&~v3&v4&v6&~v15&v19) | (v0
    &v1&~v2&~v3&~v4&v6&~v15&v19) | (v0&~v1&~v2&~v3&v4&~v6&v18) | (v0&~v1
    &v3&~v4&v5&v18) | (v0&~v1&v2&v3&~v4&v18) | (v0&~v1&v2&~v4&v5&v18);
	assign v20_16 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v12&~v13&v18) | (~v0&v1&~v2&~v3&v4
    &~v5&~v9&~v10&~v11&~v12&~v13) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&~v18) | (
    ~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v13&~v18) | (~v0&v1&~v2&~v3&v4&v5&v9
    &~v10&v11&v12&v18) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v12&~v13) | (~v0
    &v1&~v2&~v3&v4&v5&v9&~v10&v11&~v12) | (~v0&~v2&~v3&~v4&v5&~v8&v14&~v18) | (
    ~v0&~v2&~v3&v4&v5&~v9&v14&~v18) | (~v0&v1&~v2&~v3&~v4&v5&~v7&v8) | (
    v0&v1&v2&~v3&v4&v5&~v6&v18) | (v0&v2&~v3&~v4&v5&~v6&v17&~v18) | (v0
    &v1&v2&~v3&~v4&~v6&v15) | (v0&v1&~v2&~v3&~v4&v6&~v15&v19) | (v0&v1&v2
    &~v3&~v5&v6&~v18) | (v0&~v1&~v2&v3&~v4&~v5&~v18) | (~v0&v1&~v2&~v3&v4
    &v5&~v9&v10) | (v0&v1&v2&~v3&v4&v5&~v6&v15) | (v0&~v1&~v2&v3&~v4&~v5
    &~v7) | (~v0&~v2&~v3&~v4&v5&~v8&~v14) | (v0&~v1&~v2&v3&~v5&v7&v18) | (
    v0&v1&v2&~v3&~v4&~v5&v18) | (v0&v2&~v3&~v4&~v5&~v18) | (v0&~v1&~v2&~v3
    &v4&~v6&v18) | (v0&~v1&v2&~v3&~v4&~v5&~v7) | (v0&~v1&v3&~v4&v5&v18) | (
    v0&~v1&v2&v3&~v4&v18) | (~v0&v1&~v2&~v3&~v4&~v5) | (v0&~v1&~v2&v3&v5
    &~v18) | (v0&~v1&v2&~v3&~v5&v7&v18) | (~v0&~v2&~v3&v4&v5&~v9&~v14) | (
    ~v1&~v2&v3&v4&v7) | (~v0&~v1&~v2&v14&~v18) | (v0&~v1&v2&~v4&v5&v18) | (
    ~v1&~v2&v3&v4&v5) | (v0&~v1&v2&~v4&~v18) | (v0&~v1&~v3&v4&v5&~v18) | (
    ~v1&v2&~v3&v4&v7) | (~v1&v2&~v3&v4&v5) | (v0&~v1&~v2&~v3&v4&v5&v6) | (
    ~v0&~v1&~v2&v3&v4) | (~v0&~v1&~v4&~v14) | (~v0&~v1&v2&~v3) | (~v0&~v1
    &~v3&~v14) | (~v0&~v1&v2&~v4);
	assign v20_17 = (v0&~v1&v2&v3&~v4&~v18) | (~v1&v2&~v4&v5&~v18) | (~v0&v1&~v2&~v3
    &~v4&~v5) | (v0&~v1&v2&~v3&~v5&v7&v18) | (~v0&~v1&~v2&v14&~v18) | (
    v0&~v1&~v3&v4&v5&~v18) | (~v0&~v4&~v7) | (v0&~v1&~v2&~v3&v4&v5&v6) | (
    v0&~v1&v2&~v3&v4) | (~v0&~v1&~v2&v3&v4) | (~v0&~v1&~v4&~v14) | (~v0
    &~v1&v2&~v3) | (~v0&~v1&~v3&~v14) | (~v0&~v1&v2&~v4);
	assign v20_18 = (v0&v1&v2&~v3&v4&v5&~v6&v18) | (v0&v1&v2&~v3&~v4&~v6&v15) | (v0
    &v1&v2&~v3&~v5&v6&~v18) | (v0&v1&~v5&~v6);
	assign v20_19 = (~v0&~v2&~v3&v4&v5&~v9&~v10&v14&v18) | (~v0&~v2&~v3&~v4&v5&~v8
    &v14&v18) | (~v0&~v1&~v2&~v4&v14&v18) | (~v0&~v1&~v2&~v3&v14&v18);
	assign v20_20 = (v0&v2&~v3&~v4&v5&~v6&v17&v18) | (v0&v1&v2&~v3&v4&v5&~v6&v17);
	assign v20_21 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&v11&~v12&v13&v15) | (~v0&v1&~v2
    &~v3&v4&~v5&~v9&~v10&~v11&~v12&~v13) | (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10
    &v11&~v12&~v13) | (v0&~v1&~v2&~v3&~v4&v5&~v12&~v13&v15) | (v0&v2&~v3
    &~v4&v5&~v6&v7&v17&v18) | (v0&v1&v2&~v3&v4&v5&~v6&v7&~v15) | (~v0&~v2
    &~v3&~v4&v5&~v8&v14&~v18) | (~v0&~v2&~v3&v4&v5&~v9&v14&~v18) | (~v0
    &~v2&~v3&v4&v5&~v9&~v10&v14&v18) | (v0&~v1&~v2&~v3&~v4&v5&v12&v15) | (
    v0&v1&~v2&~v3&v4&v6&~v15&v19) | (v0&v2&~v3&~v4&v5&~v6&v17&~v18) | (
    v0&v1&~v2&~v3&~v4&v6&~v15&v19) | (~v0&v1&v2&v3&v4&~v5&v7) | (~v0&v1
    &~v2&~v3&v4&v5&~v9&v10) | (v0&v1&v2&~v3&v4&v5&~v6&v15) | (~v0&v1&v2
    &v3&v4&v5&~v7) | (v0&~v1&~v2&~v3&~v5&~v6&~v18) | (v0&~v1&v2&v3&~v4
    &~v18) | (v0&~v1&~v2&v3&~v5&v7&v18) | (~v1&v2&~v4&v5&~v18) | (~v0&v1
    &v2&v3&~v4&v5) | (v0&v1&~v2&~v3&v6&v15) | (v0&~v1&~v2&v3&v5&~v18) | (
    v0&~v1&v2&~v3&~v5&v7&v18) | (~v0&~v2&~v3&v4&v5&~v9&~v14) | (~v1&~v2
    &v3&v4&v7) | (~v0&~v1&~v2&v14&~v18) | (~v1&~v2&v3&v4&v5) | (~v0&~v1
    &~v2&~v4&v14&v18) | (v0&~v1&~v3&v4&v5&~v18) | (~v1&v2&~v3&v4&v7) | (
    ~v1&v2&~v3&v4&v5) | (~v0&~v1&~v2&~v3&v14&v18) | (v0&~v1&~v2&~v3&v4&v5
    &v6) | (~v0&v1&v2&~v3&v5) | (v0&~v1&~v2&~v3&~v4&~v5) | (~v0&~v1&v2&~v5) | (
    ~v0&~v1&~v2&v3&v4) | (~v0&~v1&~v4&~v14) | (~v0&~v1&~v3&~v14) | (~v0
    &~v1&v2&~v4);
	assign v20_22 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&~v11&~v12&~v13) | (~v0&~v2&~v3
    &~v4&v5&~v8&v14&~v18) | (~v0&~v2&~v3&v4&v5&~v9&v14&~v18) | (~v0&v1&~v2
    &~v3&v4&v5&~v9&v10) | (~v0&~v1&~v2&v14&~v18) | (~v0&~v1&~v2&v3&v4);
	assign v20_23 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&v11&~v12&v13&v15) | (~v0&v1&~v2
    &~v3&v4&~v5&~v9&~v10&v11&~v12&~v13) | (v0&v2&~v3&~v4&v5&~v6&v7&v17
    &v18) | (v0&v1&v2&~v3&v4&v5&~v6&v7&~v15) | (v0&~v1&~v2&~v3&~v4&v5&v12
    &v15) | (v0&v1&~v2&~v3&v4&v6&~v15&v19) | (v0&v2&~v3&~v4&v5&~v6&v17
    &~v18) | (v0&v1&~v2&~v3&~v4&v6&~v15&v19) | (v0&v1&v2&~v3&v4&v5&~v6
    &v15) | (v0&~v1&~v2&~v3&~v5&~v6&~v18) | (v0&~v1&~v2&~v3&~v4&~v13) | (
    v0&~v1&~v2&v3&~v5&v7&v18) | (v0&v1&~v2&~v3&v6&v15) | (v0&~v1&~v2&v3
    &v5&~v18) | (v0&~v1&v2&~v3&~v5&v7&v18) | (v0&~v1&v2&~v4&~v18) | (v0
    &~v1&~v3&v4&v5&~v18) | (v0&~v1&~v2&~v3&v4&v5&v6) | (v0&~v1&~v2&v3&v4) | (
    ~v0&v1&v2&~v3&v5) | (v0&~v1&~v2&~v3&~v4&~v5) | (~v1&v2&v3&v4) | (v0
    &~v1&v2&~v3&v4) | (v1&v3);
	assign v20_24 = (v0&~v1&~v2&~v3&~v4&v5&v12&v15) | (~v0&v1&v2&v3&~v5&v6) | (~v0
    &v1&v2&v3&v4&v5&~v7) | (v1&v2&v5&v6);
	assign v20_25 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&v11&~v12&v13&v15) | (~v0&v1&~v2
    &~v3&v4&~v5&~v9&~v10&v11&~v12&~v13) | (v0&v2&~v3&~v4&v5&~v6&v7&v17
    &v18) | (v0&v1&v2&~v3&v4&v5&~v6&v7&~v15) | (v0&~v1&~v2&~v3&~v4&v5&v12
    &v15) | (v0&v1&~v2&~v3&v4&v6&~v15&v19) | (v0&v1&~v2&~v3&~v4&v6&~v15
    &v19) | (~v0&v1&v2&v3&~v5&~v6) | (v0&~v1&~v2&~v3&~v5&~v6&~v18) | (v0
    &~v1&~v2&~v3&~v4&~v13) | (~v0&v1&v2&~v4&~v6) | (~v0&v1&v2&~v3&~v6) | (
    v0&v1&~v2&~v3&v6&v15) | (v0&~v1&~v2&~v3&~v4&~v5) | (~v1&v2&v3&v4);
	assign v20_26 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&v11&~v12&v13&v15) | (~v0&v1&~v2
    &~v3&v4&~v5&~v9&~v10&v11&~v12&~v13) | (v0&v2&~v3&~v4&v5&~v6&v7&v17
    &v18) | (v0&v1&v2&~v3&v4&v5&~v6&v7&~v15) | (~v0&v1&~v2&v4&v10&v11) | (
    ~v0&v1&v2&v3&~v5&~v6) | (~v0&v1&v2&v3&v4&v5&~v7) | (v0&~v1&~v2&~v3&~v5
    &~v6&~v18) | (v0&~v1&~v2&~v3&~v4&~v13) | (~v0&v1&v2&~v4&~v6) | (~v0
    &v1&v2&~v3&~v6) | (v0&v1&~v2&~v3&v6&v15) | (v0&v3&~v6) | (~v1&v2&~v6) | (
    v0&~v1&~v2&~v3&~v4&~v5) | (~v1&v2&v3&v4);
	assign v20_27 = (v0&v2&~v3&~v4&v5&~v6&v17&v18) | (v0&v1&~v2&~v3&v4&v6&~v15&v19) | (
    v0&v1&v2&~v3&v4&~v5&v6&v18) | (v0&v1&v2&~v3&~v4&~v6&~v17) | (v0&v1&v2
    &~v3&v4&v5&~v6&v17) | (v0&v1&v2&~v3&v4&v5&~v6&v18) | (v0&v1&~v2&~v3
    &~v4&v6&~v15&v19) | (v0&v1&v2&~v3&~v5&v6&~v18) | (v0&~v1&~v2&v3&~v4
    &~v5&~v18) | (v0&v1&v2&~v3&v4&v5&~v6&v15) | (v0&~v1&~v2&v3&~v4&~v5&~v7) | (
    v0&~v1&v2&v3&~v4&~v18) | (v0&~v1&~v2&~v3&v4&~v5&v6) | (v0&v1&v2&~v3
    &~v4&~v5&v18) | (v0&v2&~v3&~v4&~v5&~v18) | (v0&~v1&~v2&~v3&v4&~v6&v18) | (
    v0&~v1&v2&~v3&~v4&~v5&~v7) | (v0&~v1&v3&~v4&v5&v18) | (v0&~v1&v2&v3
    &~v4&v18) | (v0&~v1&v2&~v4&v5&v18) | (v0&~v1&~v2&~v3&v4&v5&v6) | (v0
    &~v1&~v2&v3&v4) | (v0&~v1&v2&~v3&v4);
	assign v20_28 = (v0&v1&v2&~v3&v4&~v5&v6&v18) | (v0&v1&v2&~v3&~v4&~v6&~v17) | (
    v0&v1&v2&~v3&v4&v5&~v6&v17) | (v0&v1&v2&~v3&v4&v5&~v6&v18) | (v0&v1
    &v2&~v3&~v5&v6&~v18) | (v0&v1&v2&~v3&~v4&~v5&v18) | (v0&v1&~v5&~v6);
	assign v20_29 = (v0&v1&v2&~v3&v4&v5&~v6&v18) | (v0&v1&v2&~v3&~v4&~v6&v15) | (v0
    &v1&v2&~v3&~v5&v6&~v18) | (v0&~v1&~v2&~v3&v4&~v5&v6) | (v0&~v1&~v2&~v3
    &v4&~v6&v18) | (v0&v1&~v5&~v6) | (v0&~v1&~v2&~v3&v4&v5&v6);
	assign v20_30 = (v0&v2&~v3&~v4&v5&~v6&v17&v18) | (v0&v1&v2&~v3&v4&v5&~v6&v17) | (
    v0&v1&v2&~v3&v4&v5&~v6&v18) | (v0&v1&v2&~v3&~v4&~v6&v15) | (v0&v1&~v2
    &~v3&~v4&v6&~v15&v19) | (v0&v1&v2&~v3&~v5&v6&~v18) | (v0&~v1&~v2&v3
    &~v4&~v5&~v18) | (v0&~v1&~v2&v3&~v4&~v5&~v7) | (v0&v1&v2&~v3&~v4&~v5
    &v18) | (v0&v2&~v3&~v4&~v5&~v18) | (v0&~v1&~v2&~v3&v4&~v6&v18) | (v0
    &~v1&v2&~v3&~v4&~v5&~v7) | (v0&~v1&v3&~v4&v5&v18) | (v0&~v1&v2&v3&~v4
    &v18) | (v0&~v1&v2&~v4&v5&v18);
	assign v20_31 = (v0&~v1&v2&v3&~v4&~v18);
	assign v20_32 = (v0&v1&v2&~v3&v4&v5&~v6&v15) | (v0&~v1&v2&v3&~v4&~v18) | (~v2&~v3
    &v5&v6) | (~v1&~v2&v3&v4&v5) | (~v1&v2&~v3&v4&v5);
	assign v20_33 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v12&~v13&v18) | (~v0&v1&~v2&~v3&v4
    &v5&v9&~v10&v11&v12&v18) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v12&~v13) | (
    ~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&~v12);
	assign v20_34 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&~v18) | (~v0&v1&~v2&~v3&v4&v5
    &v9&~v10&~v13&~v18) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v12&~v13) | (~v0
    &v1&~v2&~v3&v4&v5&v9&~v10&v11&~v12);
	assign v20_35 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v12&~v13&v18) | (~v0&v1&~v2&~v3&v4
    &v5&v9&~v10&v11&v12&v18) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v12&~v13) | (
    ~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&~v12);
	assign v20_36 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&v12&v18);
	assign v20_37 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v12&~v13&v18) | (~v0&v1&~v2&~v3&v4
    &v5&v9&~v10&v11&v12&v18);
	assign v20_38 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&v11&~v12&v13&v15) | (~v0&v1&~v2
    &~v3&v4&~v5&~v9&~v10&~v11&~v12&~v13) | (v0&~v1&~v2&~v3&~v4&v5&~v12
    &~v13&v15) | (~v0&~v2&~v3&v4&v5&~v9&~v10&v14&v18) | (v0&~v1&~v2&~v3
    &~v4&v5&v12&v15) | (~v0&~v2&~v3&~v4&v5&~v8&v14&v18) | (~v0&v1&~v2&~v3
    &~v4&v5&~v7&v8) | (~v0&v1&~v2&~v3&v4&v5&~v9&v10) | (~v0&~v2&~v3&~v4
    &v5&~v8&~v14) | (~v0&~v2&~v3&v4&v5&~v9&~v14) | (~v0&~v1&~v2&~v4&v14
    &v18) | (~v0&~v1&~v2&~v3&v14&v18) | (~v0&~v1&v2&~v5) | (~v0&~v1&~v2
    &v3&v4) | (~v0&~v1&~v4&~v14) | (~v0&~v1&v2&~v3) | (~v0&~v1&~v3&~v14) | (
    ~v0&~v1&v2&~v4);
	assign v20_39 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&~v11&~v12&~v13) | (~v0&~v2&~v3
    &v4&v5&~v9&~v10&v14&v18) | (~v0&~v2&~v3&~v4&v5&~v8&v14&v18) | (~v0&v1
    &~v2&~v3&~v4&v5&~v7&v8) | (~v0&v1&~v2&~v3&v4&v5&~v9&v10) | (~v0&~v2
    &~v3&~v4&v5&~v8&~v14) | (~v0&~v2&~v3&v4&v5&~v9&~v14) | (~v0&~v1&~v2
    &~v4&v14&v18) | (~v0&~v1&~v2&~v3&v14&v18) | (~v1&v2&v3&v4) | (~v0&~v1
    &~v2&v3&v4) | (~v0&~v1&~v4&~v14) | (~v0&~v1&v2&~v3) | (~v0&~v1&~v3
    &~v14) | (~v0&~v1&v2&~v4);
	assign v20_40 = (v0&~v1&~v2&~v3&~v4&v5&~v12&~v13&v15);
	assign v20_41 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&~v11&~v12&~v13) | (~v0&v1&~v2&~v3
    &v4&~v5&~v9&~v10&v11&~v12&~v13) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11
    &v12&v18) | (v2&~v3&v4&v5&~v6&v7&~v15&~v18) | (v0&v1&~v2&~v3&v6&v7
    &~v15&~v19) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&~v12) | (v0&v2&~v3&~v4
    &v5&~v6&v7&v17&v18) | (~v0&~v2&~v3&v4&v5&~v9&~v10&v14&v18) | (v0&~v1
    &~v2&v3&v7&v18) | (~v0&v1&v2&v3&v4&~v5&v7) | (~v0&v1&~v2&~v3&v4&v5&~v9
    &v10) | (~v0&v1&v2&v3&v4&v5&~v7) | (~v1&v2&~v3&v7&v18) | (~v0&v1&v2
    &v3&~v4&v5) | (~v0&~v2&~v3&v4&v5&~v9&~v14) | (~v1&~v2&v3&v4&v7) | (
    ~v0&~v1&~v2&~v4&v14&v18) | (~v1&v2&~v3&v4&v7) | (~v0&~v1&~v2&~v3&v14
    &v18) | (~v0&v1&v2&~v3&v5) | (v0&~v1&~v2&~v3&~v4&~v5) | (~v0&~v1&v2
    &~v5) | (~v0&~v1&~v2&v3&v4) | (~v0&~v1&~v4&~v14) | (~v0&~v1&v2&~v3) | (
    ~v0&~v1&~v3&~v14) | (~v0&~v1&v2&~v4);
	assign v20_42 = (~v0&v1&v2&v3&v4&~v5&v7) | (~v0&v1&v2&v3&~v4&v5) | (~v0&v1&v2&~v3
    &v5);
	assign v20_43 = (~v0&v1&~v2&~v3&v4&~v5&~v9&~v10&~v11&~v12&~v13) | (~v0&v1&~v2&~v3
    &v4&~v5&~v9&~v10&v11&~v12&~v13) | (v0&v1&~v2&~v3&v6&v7&~v15&~v19) | (
    v0&v2&~v3&~v4&v5&~v6&v7&v17&v18) | (v0&v1&v2&~v3&v4&v5&~v6&v7&~v15) | (
    v0&~v1&~v2&v3&v7&v18) | (v0&~v1&v2&~v3&~v5&v7&v18) | (v0&~v1&v2&~v4
    &v5&v18) | (v0&~v1&~v2&v3&v4) | (~v1&v2&v3&v4) | (v0&~v1&v2&~v3&v4) | (
    ~v0&~v1&~v2&v3&v4) | (v1&v3);
	assign v20_44 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&v12&v18) | (~v0&v1&~v2&~v3&v4
    &v5&v9&~v10&v11&~v12) | (v0&v2&~v3&~v4&v5&~v6&v7&v17&v18) | (v0&v1&v2
    &~v3&v4&v5&~v6&v7&~v15);
	assign v20_45 = (~v0&v1&~v2&~v3&v4&v5&v9&~v10&v12&~v13&v18) | (~v0&v1&~v2&~v3&v4
    &v5&v9&~v10&v11&v12&v18) | (~v0&v1&~v2&~v3&v4&v5&v9&~v10&~v12&~v13) | (
    ~v0&v1&~v2&~v3&v4&v5&v9&~v10&v11&~v12) | (v0&v1&~v2&~v3&v4&v6&~v15
    &v19) | (v0&v1&v2&~v3&v4&~v5&v6&v18) | (v0&~v1&v2&v3&~v4&~v18) | (v0
    &~v1&~v2&~v3&v4&~v5&v6) | (v0&~v1&~v2&~v3&v4&v5&v6) | (v0&~v1&~v2&v3
    &v4) | (v0&~v1&v2&~v3&v4);
	assign v20_46 = (v0&v1&~v2&~v3&v4&v6&~v15&v19);
	assign v20_47 = (v0&v1&v2&~v3&v4&~v5&v6&v18) | (v0&~v1&v2&~v4&~v18) | (v0&~v1&~v2
    &~v3&v4&v5&v6) | (v0&~v1&~v2&v3&v4) | (v0&~v1&v2&~v3&v4);
	assign v20_48 = (v0&~v1&~v2&~v3&v4&~v5&v6) | (v0&~v1&~v2&v3&v4);
endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                               Command Generator                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module CMD_GEN(
	input	wire	[13:0]	INST,		// IR[30:22], IR[4:0]
	input	wire			SHIFT,		// IR[10]
	input	wire			ZERO,		// FIRST CYCLE?
	input	wire	[4:0]	COUNT,		// CYCLE COUNT
	input	wire			MMREQ,		// LDM/STM REQUEST IN THIS CYCLE?

	output	wire			LAST,		// LAST CYCLE
	output	wire			IR,			// IR INPUT SELECT
	output	wire	[2:0]	BR,			// BRANCH INSTRUCTION (INCLUDING RFI)
	output	wire	[1:0]	PAT,		// PAT WRITE ENABLE, INPUT SELECT (FOR LDM/STM)
	output	wire			NRX,		// NX INPUT SELECT
	output	wire	[2:0]	NRY,		// NY INPUT SELECT
	output	wire	[2:0]	EX,			// EX WRITE ENABLE, INPUT SELECT
	output	wire			PS_X,		// ALU INPUT FROM PS
	output	wire			FWD_X,		// FORCE FORWARDING OF X FROM MDA
	output	wire	[2:0]	EY,			// EY WRITE ENABLE, INPUT SELECT
	output	wire	[1:0]	FWD_Y,		// FORCE FORWARDING OF Y FROM MDA/WDA
	output	wire	[5:0]	EOP,		// ALU/SHIFT OP, MDA WRITE ENABLE, MDA INPUT SELECT
	output	wire			WDA,		// WDA INPUT SELECT
	output	wire			WDB,		// WDB INPUT SELECT
	output	wire	[3:0]	MUL,		// MUL WRITE ENABLE, INPUT SELECT
	output	wire	[5:0]	MEM,		// MEMORY REQUEST, TYPE, R/W, LOCK, ADDRESS SOURCE SELECT
	output	wire	[2:0]	PS,			// PS WRITE ENABLE, INPUT SELECT
	output	wire	[3:0]	DST_A,		// REG FILE WRITE INDEX
	output	wire	[3:0]	DST_B		// REG FILE WRITE INDEX
);

	// command.v:   for RTL simulation
	// command_g.v: for gate-level synthesis

	assign	WDB		= WDA;

	CMD_PLA	CommandPLA(
		/* inputs */
		INST[13], INST[12], INST[11], INST[10], INST[9], INST[8], INST[7], INST[6], INST[5], INST[4], INST[3], INST[2], INST[1], INST[0],
		SHIFT, ZERO, COUNT[2], COUNT[1], COUNT[0], MMREQ,
		/* outputs */
		LAST,
		IR,
		BR[2], BR[1],			// BR_TYPE
		BR[0],					// IMM/REG
		PAT[1],					// PAT_WE
		PAT[0],					// PAT_SEL
		NRX,
		NRY[2], NRY[1], NRY[0],
		EX[2],					// E_X_WE
		EX[1], EX[0],			// E_X_SEL
		PS_X,					// OP_X <- PS
		FWD_X,					// OP_X <- M_DA
		EY[2],					// E_Y_WE
		EY[1], EY[0],			// E_Y_SEL
		FWD_Y[1],				// OP_Y <- M_DA
		FWD_Y[0],				// OP_Y <- W_DB
		EOP[5],					// M_DA_WE
		EOP[4],					// M_DA_SEL
		EOP[3], EOP[2], EOP[1], EOP[0],
		MEM[5],					// REQ
		MEM[4], MEM[3],			// TYPE
		MEM[2],					// RW
		MEM[1],					// LOCK
		MEM[0],					// ADDR_SEL
		WDA,
		MUL[3],					// PPD_WE
		MUL[2],					// ACC_WE
		MUL[1], MUL[0],			// ACC_SEL
		PS[2],					// PS_WE
		PS[1], PS[0],			// PS_SEL
		DST_A[3],				// RA_WE
		DST_A[2], DST_A[1], DST_A[0],
		DST_B[3],				// RA_WE
		DST_B[2], DST_B[1], DST_B[0]
	);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                                    Counter                                  *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module Counter (
	input	wire			CLK, 
	input	wire			RST,
	output	reg		[4:0]	COUNT,
	output	wire			ZERO
);

	always @ (posedge CLK)
	begin
		if (RST)	COUNT <= 5'b00000;
		else		COUNT <= COUNT + 5'b00001;
	end

	assign	ZERO	= ~(| COUNT);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                              ID Stage Controlpath                           *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module	ID_CP (
	input	wire				VALID,
	input	wire				INST_START,		// END | IR[31]
	input	wire				INT_DETECT,

	// FROM PIPELINE REG.
	input	wire				MODE,			// 0:USER, 1:KERNEL

	input	wire	[3:0]		X_RA,			// GPR READ INDEX
	input	wire	[3:0]		Y_RA,			// GPR READ INDEX
												// GPR WRITE INDEX FOR LDM

	// FOR LDM/STM
	input	wire	[1:0]		CG_PAT,
	input	wire	[15:0]		CI_PAT,			// PATTERN FROM IR
	input	wire	[15:0]		PAT,			// PATTERN FROM PAT
	output	wire				PAT_WE,
	output	wire	[15:0]		PAT_OUT,
	output	wire				MMREQ_OUT,

	// FROM CMD_GEN (CHECK CMD_GEN.v)
	input	wire				CG_LAST,		// LAST CYCLE OF AN INST.
	input	wire				CG_IR,			// 0:IDATA, 1:NOP
	input	wire	[2:0]		CG_BR,
	input	wire				CG_NRX,
	input	wire	[2:0]		CG_NRY,
	input	wire	[2:0]		CG_EX,
	input	wire				CG_PS_X,
	input	wire	[2:0]		CG_EY,
	input	wire	[5:0]		CG_EOP,
	input	wire	[3:0]		CG_MUL,
	input	wire	[5:0]		CG_MEM,
	input	wire				CG_WDA,
	input	wire				CG_WDB,
	input	wire	[2:0]		CG_PS,
	input	wire	[3:0]		CG_DST_A,
	input	wire	[3:0]		CG_DST_B,

	// FROM DECODER
	input	wire				CI_N,			// IR[31]
	input	wire	[3:0]		CI_R1,
	input	wire	[3:0]		CI_R2,
	input	wire	[3:0]		CI_R3,
	input	wire	[3:0]		CI_R4,
	input	wire				CI_SIGN,		// IR[26]
	input	wire	[1:0]		CI_SIZE,		// IR[25:24]
	input	wire				CI_U,			// IR[24]
	input	wire	[3:0]		CI_ALU,
	input	wire	[2:0]		CI_SHIFT,
	input	wire	[4:0]		CI_SHAMT,		// IR[11:7]
	input	wire	[7:0]		CI_IMM_SEL,
	input	wire	[1:0]		CI_CUT,
	input	wire				CI_USE_CONDZ,
	input	wire				CI_COND_INST,
	input	wire				CI_UMULT,		// 0:SIGNED, 1:UNSIGNED

	// FROM ID_DP
	input	wire				COND_TRUE,

	// TO INSTR. MEMORY
	output	wire				IREQ,

	// TO IF_DP
	output	wire	[3:0]		PC_SEL,
	output	wire				IR_SEL,			// 0:IDATA, 1:NOP

	// TO ID_DP
	output	wire	[7:0]		IMM_SEL,
	output	wire				COND_SEL,		// 0:COND,  1:CONDZ
	output	wire	[4:0]		SHAMT,			// TO Z REG.
	output	wire	[2:0]		X_SEL,
	output	wire	[2:0]		Y_SEL,

	// TO GPR
	output	wire	[3:0]		GPR_X_RA,
	output	wire	[3:0]		GPR_Y_RA,

	// TO PIPELINE REG.
	output	wire				F_PIPE_EN,
	output	wire				D_PIPE_EN,

	output	wire	[3:0]		NX_RA_OUT,
	output	reg		[3:0]		NY_RA_OUT,

	output	wire				X_WE,
	output	wire				Y_WE,
	output	wire				Z_WE,

	output	wire	[1:0]		CMD_EOP_OUT,
	output	wire	[16:0]		CMD_ALU_OUT,
	output	wire	[7:0]		CMD_SHIFT_OUT,
	output	wire	[4:0]		CMD_MUL_OUT,
	output	wire	[9:0]		CMD_MEM_OUT,
	output	wire	[1:0]		CMD_MOP_OUT,
	output	wire	[4:0]		CMD_DA_OUT,
	output	wire	[4:0]		CMD_DB_OUT,
	output	wire	[2:0]		CMD_PS_OUT,
	output	wire	[2:0]		CMD_NZCV_OUT,

	output	wire				VALID_OUT
);

	// synopsys dc_script_begin
	// set_max_delay 0.5 -from all_inputs() -to all_outputs()
	// synopsys dc_script_end

	//---------------------------------------------------------------
	//		PIPELINE CONTROL
	//---------------------------------------------------------------
	// LAST CYCLE OF AN INSTRUCTION
	wire	inst_end	= CG_LAST & ~CI_N;

	// IF/ID:     CAN BE MULTI-CYCLE
	// EX/MEM/WB: MUST BE SINGLE-CYCLE
	assign	F_PIPE_EN	= inst_end | INT_DETECT;
	assign	D_PIPE_EN	= inst_end | INT_DETECT;


	//---------------------------------------------------------------
	//		IF STAGE
	//---------------------------------------------------------------
	assign	IREQ		= inst_end | INT_DETECT;

	wire	br_0		= (CG_BR[2:1] == 2'b00);	// NO BRANCH
	wire	br_rfi		= (CG_BR[2:1] == 2'b01);	// RFI
	wire	br_u		= (CG_BR[2:1] == 2'b10);	// UNCOND. BRANCH
	wire	br_c		= (CG_BR[2:1] == 2'b11);	// COND. BRANCH
	wire	br_ci		= (CG_BR[2:0] == 3'b110);	// COND. BRANCH (IMM.)
	wire	br_cr		= (CG_BR[2:0] == 3'b111);	// COND. BRANCH (REG.)

	// 4'b0001 : INTERRUPT VECTOR
	// 4'b0010 : PC TARGET (REG.)
	// 4'b0100 : PC RELATVIE (IMM.)
	// 4'b1000 : PC+4
	assign	PC_SEL[0]	= INT_DETECT;
	assign	PC_SEL[1]	= (~INT_DETECT) & (br_rfi | (br_cr &  COND_TRUE)); 
	assign	PC_SEL[2]	= (~INT_DETECT) & (br_u   | (br_ci &  COND_TRUE));
	assign	PC_SEL[3]	= (~INT_DETECT) & (br_0   | (br_c  & ~COND_TRUE));

	// {SLOT, COND_TRUE}
	// 2'b01: IR <- NOP
	// 2'b00: IR <- IDATA
	// 2'b1x: IR <- IDATA
	assign	IR_SEL = INT_DETECT | (CG_IR & (br_0 | br_rfi | br_u | (br_c & COND_TRUE)));

	//---------------------------------------------------------------
	//		ID STAGE (LDM/STM)
	//---------------------------------------------------------------
	wire			mm_ldmstm	= CG_PAT[1];
	wire			mm_first	= mm_ldmstm & ~CG_PAT[0];
	wire	[15:0]	mm_pat		= (mm_first) ? CI_PAT : PAT;
	wire	[3:0]	mm_ra;
	wire			mm_full;

	PAT_CTRL		PAT_COUNT (
						.PAT		(mm_pat),
						.COUNT		(mm_ra),
						.FULL		(mm_full),
						.NEXT_PAT	(PAT_OUT)
					);

	assign	PAT_WE		= mm_ldmstm & ~mm_full;
	assign	MMREQ_OUT	= mm_ldmstm & ~mm_full;

	//---------------------------------------------------------------
	//		ID STAGE
	//---------------------------------------------------------------
	// AT THE FIRST CYCLE OF EVERY INSTRUCTION ONLY GPR[R2] & GPR[R3] WOULD BE READ.
	assign	GPR_X_RA = (INST_START) ? CI_R2 : X_RA;
	assign	GPR_Y_RA = (INST_START) ? CI_R3 : Y_RA;

	// NEXT REGISTER INDEX FOR X
	assign	NX_RA_OUT = (CG_NRX) ? CI_R2 : {CI_R1[3:1], 1'b1};
	
	// NEXT REGISTER INDEX FOR Y
	always @ *
	begin
		casex ({CG_DST_B[2], CG_NRY})		// synopsys full_case
			4'b0000: NY_RA_OUT <= CI_R1;	// MAC ONLY
			4'b0001: NY_RA_OUT <= CI_R2;
			4'b0010: NY_RA_OUT <= CI_R3;
			4'b0011: NY_RA_OUT <= CI_R4;
			4'b01xx: NY_RA_OUT <= mm_ra;
			// FOR DESTINATION ADDRESS OF LDM
			// IN ORDER TO HOLD CONSISTENCY,
			// THE MECHANISM OF GENERATING SOURCE ADDRESS OF STM IS
			// THE SAME AS THAT OF GENERATING DESTINATION ADDRESS OF LDM.
			// i.e. ONE CYCLE DELAY FOR DESTINATION ADDRESS GENERATION
			4'b1xxx: NY_RA_OUT <= mm_ra;
		endcase
	end

	assign	COND_SEL	= CI_USE_CONDZ;
	assign	IMM_SEL		= CI_IMM_SEL;
	assign	SHAMT		= CI_SHAMT;

	// 3'b001: IMM.
	// 3'b010: GPR_X_RD
	// 3'b100: {2'b0, F_PC}
	assign	X_SEL[0]	=  CG_EX[1];
	assign	X_SEL[1]	= ~CG_EX[1] & ~CG_EX[0];
	assign	X_SEL[2]	= ~CG_EX[1] &  CG_EX[0];

	// 3'b001: IMM.
	// 3'b010: GPR_y_RD
	// 3'b100: IR
	assign	Y_SEL[0]	=  CG_EY[1];
	assign	Y_SEL[1]	= ~CG_EY[1] & ~CG_EY[0];
	assign	Y_SEL[2]	= ~CG_EY[1] &  CG_EY[0];

	// PIPELINE REG. WRITE ENABLE
	assign	X_WE		= CG_EX[2] & VALID_OUT;
	assign	Y_WE		= CG_EY[2] & VALID_OUT;
	assign	Z_WE		= VALID_OUT;

	//---------------------------------------------------------------
	//		EX STAGE (ALU)
	//---------------------------------------------------------------
	reg		[3:0]	alu_op;
	reg				alu_x;
	reg		[7:0]	alu_y;
	reg		[2:0]	alu_c;

	// OR Operation
	always @ *
	begin
		casex ({CG_EOP[3:0], CI_ALU})	
			{4'b0_xxx, 4'b0100}: alu_op[0] <= 1'b1; // A_D
			{4'b0_xxx, 4'b1000}: alu_op[0] <= 1'b1;
			{4'b1_011, 4'bxxxx}: alu_op[0] <= 1'b1; // A_OR0
			{4'b1_111, 4'bxxxx}: alu_op[0] <= 1'b1; // A_OR4
			default:			 alu_op[0] <= 1'b0;
		endcase
	end

	// XOR Operation
	always @ *
	begin
		casex ({CG_EOP[3:0], CI_ALU})	
			{4'b0_xxx, 4'b0011}: alu_op[1] <= 1'b1; // A_D
			default:			 alu_op[1] <= 1'b0;
		endcase
	end

	// AND Operation
	always @ *
	begin
		casex ({CG_EOP[3:0], CI_ALU})	
			{4'b0_xxx, 4'b0010}: alu_op[2] <= 1'b1; // A_D
			{4'b0_xxx, 4'b0101}: alu_op[2] <= 1'b1;
			{4'b0_xxx, 4'b1010}: alu_op[2] <= 1'b1;
			{4'b1_110, 4'bxxxx}: alu_op[2] <= 1'b1; // A_ANDN4
			default:			 alu_op[2] <= 1'b0;
		endcase
	end

	// ADD Operation
	always @ *
	begin
		casex ({CG_EOP[3:0], CI_ALU})	
			{4'b0_xxx, 4'b0000}: alu_op[3] <= 1'b1; // A_D
			{4'b0_xxx, 4'b0001}: alu_op[3] <= 1'b1;
			{4'b0_xxx, 4'b0110}: alu_op[3] <= 1'b1;
			{4'b0_xxx, 4'b0111}: alu_op[3] <= 1'b1;
			{4'b0_xxx, 4'b1001}: alu_op[3] <= 1'b1;
			{4'b1_000, 4'bxxxx}: alu_op[3] <= 1'b1; // A_ADD
			{4'b1_001, 4'bxxxx}: alu_op[3] <= 1'b1; // A_SUB
			{4'b1_010, 4'bxxxx}: alu_op[3] <= 1'b1; // A_ADDS
			{4'b1_100, 4'bxxxx}: alu_op[3] <= 1'b1; // A_ADD1
			{4'b1_101, 4'bxxxx}: alu_op[3] <= 1'b1; // A_SUB1
			default:			 alu_op[3] <= 1'b0;
		endcase
	end

	// 1 : ~X 	0 : X
	always @ *
	begin
		casex ({CG_EOP[3:0], CI_ALU})
			{4'b0_xxx, 4'b0101}: alu_x <= 1'b1;	// A_D
			{4'b0_xxx, 4'b1001}: alu_x <= 1'b1;
			default:			 alu_x <= 1'b0;
		endcase
	end
	
	// SIZE == 2'b00 : 1
	// SIZE == 2'b01 : 2
	// SIZE == 2'b1x : 4
	always @ *
	begin
		casex ({CG_EOP[3:0], CI_ALU, CI_SIZE})
			{4'b0_xxx, 4'b0101, 2'bxx}: alu_y <= 8'b00000_010; // A_D
			{4'b0_xxx, 4'b1010, 2'bxx}: alu_y <= 8'b00000_010;
			{4'b0_xxx, 4'b0001, 2'bxx}: alu_y <= 8'b00000_010;
			{4'b0_xxx, 4'b0111, 2'bxx}: alu_y <= 8'b00000_010;
			{4'b1_001, 4'bxxxx, 2'bxx}: alu_y <= 8'b00000_010; // A_SUB
			{4'b0_xxx, 4'b1000, 2'bxx}: alu_y <= 8'b00000_100; // A_D
			{4'b1_011, 4'bxxxx, 2'bxx}: alu_y <= 8'b00000_100; // A_OR0
			{4'b1_010, 4'bxxxx, 2'b00}: alu_y <= 8'b00001_000; // A_ADDS1
			{4'b1_100, 4'bxxxx, 2'bxx}: alu_y <= 8'b00001_000; // A_ADD1
			{4'b1_101, 4'bxxxx, 2'bxx}: alu_y <= 8'b01000_000; // A_SUB1
			{4'b1_010, 4'bxxxx, 2'b01}: alu_y <= 8'b00010_000; // A_ADDS2
			{4'b1_010, 4'bxxxx, 2'b1x}: alu_y <= 8'b00100_000; // A_ADDS4
			{4'b1_110, 4'bxxxx, 2'bxx}: alu_y <= 8'b10000_000; // A_ANDN4
			{4'b1_111, 4'bxxxx, 2'bxx}: alu_y <= 8'b00100_000; // A_OR4
			default:					alu_y <= 8'b00000_001; // OP_Y
		endcase
	end

	// 001 : 0
	// 010 : 1
	// 100 : C_OUT
	always @ *
	begin
		casex ({CG_EOP[3:0], CI_ALU})
			{4'b0_xxx, 4'b0000}: alu_c <= 3'b001;	// A_D
			{4'b0_xxx, 4'b0001}: alu_c <= 3'b010;
			{4'b0_xxx, 4'b0110}: alu_c <= 3'b100;
			{4'b0_xxx, 4'b0111}: alu_c <= 3'b100;
			{4'b0_xxx, 4'b1001}: alu_c <= 3'b010;
			{4'b1_000, 4'bxxxx}: alu_c <= 3'b001;	// A_ADD
			{4'b1_001, 4'bxxxx}: alu_c <= 3'b010;	// A_SUB
			{4'b1_010, 4'bxxxx}: alu_c <= 3'b001;	// A_ADDS
			{4'b1_100, 4'bxxxx}: alu_c <= 3'b001;	// A_ADD1
			{4'b1_101, 4'bxxxx}: alu_c <= 3'b010;	// A_SUB1
			default:			 alu_c <= 3'b001;
		endcase
	end

	wire			alu_ps		= CG_PS_X;

	//---------------------------------------------------------------
	//		EX STAGE (SHIFT)
	//---------------------------------------------------------------
	wire			shift_ror	= (CI_SHIFT == 3'b000);
	wire			shift_shl	= (CI_SHIFT == 3'b001);
	wire			shift_lsr	= (CI_SHIFT == 3'b010);
	wire			shift_asr	= (CI_SHIFT == 3'b011);
	wire			shift_extd	= (CI_SHIFT == 3'b100);

	wire			shamt_sel	= CG_EOP[0];
	wire			shift_dir	= ~shift_shl;	// 0:LEFT, 1:RIGHT
	wire	[4:0]	shift_hi	= {shift_extd, shift_ror, shift_asr, shift_shl, shift_lsr};
	wire			shift_lo	= ~shift_shl;

	//---------------------------------------------------------------
	//		EX STAGE (ALU, SHIFT)
	//---------------------------------------------------------------
	wire			e_da_we		= CG_EOP[5];
	wire			e_da_sel	= CG_EOP[4];

	assign	CMD_EOP_OUT		= {e_da_we, e_da_sel};
	assign	CMD_ALU_OUT		= {alu_op, alu_x, alu_y, alu_c, alu_ps};
	assign	CMD_SHIFT_OUT	= {shamt_sel, shift_dir, shift_hi, shift_lo};

	//---------------------------------------------------------------
	//		EX STAGE (MUL)
	//---------------------------------------------------------------
	wire			ppd_we		= CG_MUL[3];
	wire			umult		= CI_UMULT;
	wire			acc_we		= CG_MUL[2];
	wire			acc_hi		= CG_MUL[1];
	wire			acc_lo		= CG_MUL[0];

	assign	CMD_MUL_OUT		= {ppd_we, umult, acc_we, acc_hi, acc_lo};

	//---------------------------------------------------------------
	//		EX STAGE (NZCV)
	//---------------------------------------------------------------
	wire			nz			= (CI_CUT[1:0] == 2'b01);
	wire			nzc			= (CI_CUT[1:0] == 2'b10);
	wire	 		nzcv		= (CI_CUT[1:0] == 2'b11);

	wire			nz_update	= nzcv | nzc | nz;
	wire			c_update	= nzcv | nzc;
	wire			v_update	= nzcv;

	assign	CMD_NZCV_OUT	= {nz_update, c_update, v_update};

	//---------------------------------------------------------------
	//		EX, MEM STAGE (MEMORY)
	//---------------------------------------------------------------
	wire			m_req		= CG_MEM[5];
	wire	[1:0]	m_type		= CG_MEM[4:3];
	wire			m_rw		= CG_MEM[2];
	wire			m_lock		= CG_MEM[1];
	wire			m_addr_sel	= CG_MEM[0];
	wire			m_mode		= MODE;
	wire			m_sign		= CI_SIGN;
	wire	[1:0]	m_size		= CI_SIZE;

	assign	CMD_MEM_OUT		= {m_req, m_type, m_rw, m_lock, m_addr_sel, m_mode, m_sign, m_size};

	//---------------------------------------------------------------
	//		MEM STAGE
	//---------------------------------------------------------------
	wire			m_da_sel	= CG_WDA;	// 0:M_DA, 1:MUL_HI  
	wire			m_db_sel	= CG_WDB;	// 0:MEM,  1:MUL_LO

	assign	CMD_MOP_OUT		= {m_db_sel, m_da_sel};		// {DB, DA}

	//---------------------------------------------------------------
	//		WB STAGE
	//---------------------------------------------------------------
	wire			gpr_a_we	= CG_DST_A[3];
	wire			gpr_b_we	= CG_DST_B[3];

	wire			gpr_a_r1	= (CG_DST_A[2:0] == 3'b000);
	wire			gpr_a_r1_1	= (CG_DST_A[2:0] == 3'b001);
	wire			gpr_a_r2	= (CG_DST_A[2:0] == 3'b010);
	wire			gpr_a_r3	= (CG_DST_A[2:0] == 3'b011);
	wire			gpr_a_15	= (CG_DST_A[2]   == 1'b1);

	wire			gpr_b_r1	= (CG_DST_B[2:0] == 3'b000);
	wire			gpr_b_r2	= (CG_DST_B[2:0] == 3'b001);
	wire			gpr_b_r3	= (CG_DST_B[2:0] == 3'b010);
	wire			gpr_b_r4	= (CG_DST_B[2:0] == 3'b011);
	wire			gpr_b_cnt	= (CG_DST_B[2]   == 1'b1);

	wire	[3:0]	gpr_a_wa;
	wire	[3:0]	gpr_b_wa;

	wire			ps_nzcv		= CG_PS[1];
	// I THINK WE CAN JUST USE IR[24] INSTEAD OF CI_U
	wire			ps_we		= CG_PS[2] & (ps_nzcv & CI_U | ~ps_nzcv);
	wire	[1:0]	ps_sel		= CG_PS[1:0];

	MUX5to1	#(4)	MUX_WA_A (
						.DI0		(CI_R1),
						.DI1		({CI_R1[3:1], 1'b1}),
						.DI2		(CI_R2),
						.DI3		(CI_R3),
						.DI4		(4'b1111),
						.SEL		({gpr_a_15, gpr_a_r3, gpr_a_r2, gpr_a_r1_1, gpr_a_r1}), 
						.DO			(gpr_a_wa)
					);

	MUX5to1	#(4)	MUX_WA_B (
						.DI0		(CI_R1),
						.DI1		(CI_R2),
						.DI2		(CI_R3),
						.DI3		(CI_R4),
						.DI4		(Y_RA),		// FOR LDM
						.SEL		({gpr_b_cnt, gpr_b_r4, gpr_b_r3, gpr_b_r2, gpr_b_r1}),
						.DO			(gpr_b_wa)
					);

	assign	CMD_DA_OUT	= {gpr_a_we, gpr_a_wa};
	assign	CMD_DB_OUT	= {gpr_b_we, gpr_b_wa};
	assign	CMD_PS_OUT	= {ps_we, ps_sel};

	// DECIDES WHEATHER TO RUN INSTRUCTION OR NOT
	assign	VALID_OUT	= ~(~VALID | INT_DETECT | CI_N | (CI_COND_INST & ~COND_TRUE));
endmodule


/*
 * LEADING ONE DETECTOR FOR LDM/STM
 */
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

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                              EX Stage Controlpath                           *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module	EX_CP (
	input	wire				VALID,

	// COMMAND
	input	wire	[1:0]		CMD_EOP,
	input	wire	[16:0]		CMD_ALU,
	input	wire	[7:0]		CMD_SHIFT,
	input	wire	[4:0]		CMD_MUL,
	input	wire	[9:0]		CMD_MEM,
	input	wire	[1:0]		CMD_MOP,
	input	wire	[4:0]		CMD_DA,
	input	wire	[4:0]		CMD_DB,
	input	wire	[2:0]		CMD_PS,
	input	wire	[2:0]		CMD_NZCV,

	// FROM INTERRUPT CONTROLLER
	input	wire				INT_DETECT,
	input	wire				DONT_MREQ,

	// TO EX DATAPATH
	output	wire	[3:0]		ALU_OP,
	output	wire				ALU_X,
	output	wire	[7:0]		ALU_Y,
	output	wire	[2:0]		ALU_C,
	output	wire				ALU_PS_SEL,

	output	wire				SHAMT_SEL,
	output	wire				SHIFT_DIR,
	output	wire	[4:0]		SHIFT_HI,
	output	wire				SHIFT_LO,

	output	wire				UMULT,
	output	wire				ACC_HI_SEL,
	output	wire				ACC_LO_SEL,

	output	wire				NZ_UPDATE,
	output	wire				C_UPDATE,
	output	wire				V_UPDATE,

	output	wire				MREQ,
	output	wire	[1:0]		MTYPE,
	output	wire				MRW,
	output	wire				MLOCK,
	output	wire				MODE,
	output	wire	[1:0]		MSIZE,

	output	wire	[2:0]		MADDR_SEL,
	output	wire				DA_SEL,

	// PIPELINE REG. WRITE
	output	wire				SHAMT_WE,	// DHYOU EDIT
	output	wire				ACC_WE,
	output	wire				PPD_WE,
	output	wire				DA_WE,
	output	wire				NZCV_WE,

	// TO NEXT STAGE
	output	wire	[3:0]		CMD_MEM_OUT,
	output	wire	[1:0]		CMD_MOP_OUT,
	output	wire	[4:0]		CMD_DA_OUT,
	output	wire	[4:0]		CMD_DB_OUT,
	output	wire	[2:0]		CMD_PS_OUT,
	output	wire				VALID_OUT
);

	//---------------------------------------------------------------
	//		TO DATAPATH (ALU & SHIFT)
	//---------------------------------------------------------------
	wire			da_we		= CMD_EOP[1];

	assign	DA_SEL		= CMD_EOP[0];			// 0:ALU, 1:SHIFTER

	assign	ALU_OP		= CMD_ALU[16:13];
	assign	ALU_X		= CMD_ALU[12];
	assign	ALU_Y		= CMD_ALU[11:4];
	assign	ALU_C		= CMD_ALU[3:1];
	assign	ALU_PS_SEL	= CMD_ALU[0];			// 0:X, 1:PS

	assign	SHAMT_SEL	= CMD_SHIFT[7];			// 0:IMM, 1:REGISTER
	assign	SHIFT_DIR	= CMD_SHIFT[6];			// 0:LEFT, 1:RIGHT
	assign	SHIFT_HI	= CMD_SHIFT[5:1];
	assign	SHIFT_LO	= CMD_SHIFT[0];

	//---------------------------------------------------------------
	//		TO DATAPATH (MUL)
	//---------------------------------------------------------------
	wire			ppd_we		= CMD_MUL[4];
	wire			acc_we		= CMD_MUL[2];

	assign	UMULT		= CMD_MUL[3];			// 0:SIGNED, 1:UNSIGNED
	assign	ACC_HI_SEL	= CMD_MUL[1];
	assign	ACC_LO_SEL	= CMD_MUL[0];

	//---------------------------------------------------------------
	//		TO DATAPATH (NZCV)
	//---------------------------------------------------------------
	assign	NZ_UPDATE	= CMD_NZCV[2];
	assign	C_UPDATE	= CMD_NZCV[1];
	assign	V_UPDATE	= CMD_NZCV[0];

	//---------------------------------------------------------------
	//		TO DATAPATH (DATA MEMORY)
	//---------------------------------------------------------------
	wire			mreq		= CMD_MEM[9];

	wire			mt_mem		= (CMD_MEM[8:7] == 2'b00);
	wire			mt_asr		= (CMD_MEM[8:7] == 2'b01);
	wire			mt_cp		= (CMD_MEM[8]   == 1'b1);

	wire			addr_x		= ~mt_cp & ~CMD_MEM[4];
	wire			addr_alu	= ~mt_cp &  CMD_MEM[4];
	wire			addr_cpn	=  mt_cp;

	// ASR AND COPROCESSOR INTERFACES HAVE ONLY WORD TRANSFER
	wire	[1:0]	msize		= mt_mem ? CMD_MEM[1:0] : 2'b10;
	wire			msign		= CMD_MEM[2];

	// LDM/STM DOES NOT REQUIRE SEPCIAL HANDLING.
	// IT WILL BE PROCESSED IN ID STAGE.
	assign	MREQ		= mreq & ~DONT_MREQ & VALID_OUT;
	assign	MTYPE		= CMD_MEM[8:7];
	assign	MRW			= CMD_MEM[6];
	assign	MLOCK		= CMD_MEM[5];
	assign	MADDR_SEL	= {addr_cpn, addr_alu, addr_x};
	assign	MODE		= CMD_MEM[3];
	assign	MSIZE		= msize;

	//---------------------------------------------------------------
	//		DECODER
	//---------------------------------------------------------------
	wire			ps_we		= CMD_PS[2];
	wire	[1:0]	ps_sel		= CMD_PS[1:0];
	wire			ps_mtps		= (CMD_PS[1:0] == 2'b00);
	wire			ps_rfi		= (CMD_PS[1:0] == 2'b01);
	wire			ps_nzcv		= (CMD_PS[1]   == 1'b1);

	//---------------------------------------------------------------
	//		PIPELINE REG
	//---------------------------------------------------------------
	assign	SHAMT_WE	= MREQ;			// DHYOU EDIT
	assign	PPD_WE		= ppd_we & VALID_OUT;
	assign	ACC_WE		= acc_we & VALID_OUT;
	assign	DA_WE		= da_we & VALID_OUT;
	assign	NZCV_WE		= (ps_we & ps_nzcv) & VALID_OUT;

	//---------------------------------------------------------------
	//		TO NEXT STAGE
	//---------------------------------------------------------------
	assign	CMD_MEM_OUT	= {MREQ & ~MRW, msign, msize};	// MEMORY LOAD (NEEDED FOR LDC)
	assign	CMD_MOP_OUT	= CMD_MOP;
	assign	CMD_DA_OUT	= CMD_DA;
	assign	CMD_DB_OUT	= CMD_DB;
    assign  CMD_PS_OUT	= CMD_PS;

	assign	VALID_OUT	= VALID & ~INT_DETECT;
endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                             MEM Stage Controlpath                           *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module	MEM_CP (
	input	wire				VALID,

	// COMMAND
	input	wire	[3:0]		CMD_MEM,		// 0:STORE, 1:LOAD
	input	wire	[1:0]		CMD_MOP,		// {DB, DA}
	input	wire	[4:0]		CMD_DA,
	input	wire	[4:0]		CMD_DB,
	input	wire	[2:0]		CMD_PS,

	// FROM INTERRUPT CONTROLLER
	input	wire				INT_DETECT,

    // TO MEM DATAPATH
    output  wire                DA_SEL,
    output  wire                DB_SEL,
    output  wire                MSIGN,			// FOR MEMORY LOAD
    output  wire    [1:0]       MSIZE,			// FOR MEMORY LOAD

	// PIPELINE REG. WRITE
	output	wire				DA_WE, 
	output	wire				DB_WE, 
	output	wire				NZCV_WE,

	// TO NEXT STAGE
	output	wire	[4:0]		CMD_DA_OUT,
	output	wire	[4:0]		CMD_DB_OUT,
	output	wire	[2:0]		CMD_PS_OUT,
	output	wire				VALID_OUT
);

	//---------------------------------------------------------------
	//		DECODER
	//---------------------------------------------------------------
	wire			mem_load	= CMD_MEM[3];	// 0:STORE, 1:LOAD

	wire			gpr_a_we	= CMD_DA[4];
	wire			gpr_b_we	= CMD_DB[4];

	wire			ps_we		= CMD_PS[2];
	wire			ps_mtps		= (CMD_PS[1:0] == 2'b00);
	wire			ps_rfi		= (CMD_PS[1:0] == 2'b01);
	wire			ps_nzcv		= (CMD_PS[1]   == 1'b1);

	//---------------------------------------------------------------
	//		TO DATAPATH
	//---------------------------------------------------------------
	assign	DA_SEL		= CMD_MOP[0];	// 0:M_DA, 1:MUL
	assign	DB_SEL		= CMD_MOP[1];	// 0:MEM,  1:MUL

	assign	MSIGN		= CMD_MEM[2];
	assign	MSIZE		= CMD_MEM[1:0];

	//---------------------------------------------------------------
	//		PIPELINE REG
	//---------------------------------------------------------------
	// W_DA CAN BE USED AS A PIPELINE REGISTER FOR MTPS INSTRUCTION.
	// DURING PROCESSING MTPS, NOT GPR WRITE BUT PS WRITE OCCURS.
	// THUS, DA_WE DOES NOT NECESSARILY MEAN VALIDITY OF W_DA.
	// USE CMD_DA[4] AS THE VALIDITY SIGNAL OF W_DA.
	assign	DA_WE		= (gpr_a_we | (ps_we & ps_mtps)) & VALID_OUT;
	// W_DB CAN BE USED AS A TEMPORARY REGISTER FOR LDC/STC INSTRUCTION.
	// THUS, DB_WE DOES NOT NECESSARILY MEAN VALIDITY OF W_DB.
	// USE CMD_DB[4] AS THE VALIDITY SIGNAL OF W_DB.
	assign	DB_WE		= (gpr_b_we | mem_load) & VALID_OUT;
	assign	NZCV_WE		= (ps_we & ps_nzcv) & VALID_OUT;

	//---------------------------------------------------------------
	//		TO NEXT STAGE
	//---------------------------------------------------------------
	assign	CMD_DA_OUT	= CMD_DA;
	assign	CMD_DB_OUT	= CMD_DB;
    assign  CMD_PS_OUT	= CMD_PS;

	assign	VALID_OUT	= VALID & ~INT_DETECT;
endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                              WB Stage Controlpath                           *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module WB_CP (
	input	wire				VALID,

	// COMMAND
	input	wire	[4:0]		CMD_DA,
	input	wire	[4:0]		CMD_DB,
	input	wire	[2:0]		CMD_PS,

	// FROM INTERRUPT CONTROLLER
	input	wire				INT_DETECT,

	// PS WRITE BACK
	output	wire				PS_WE,
	output	wire	[3:0]		PS_SEL,

	// GPR WRITE BACK
	output	wire				GPR_A_WEN,		// ACTIVE LOW
	output	wire				GPR_B_WEN,		// ACTIVE LOW
	output	wire	[3:0]		GPR_A_WA,
	output	wire	[3:0]		GPR_B_WA,
	output	wire				GPR_A_SEL,		// TO WB_DP

	// PIPELINE REG. WRITE
	output	wire				DA_WE,
	output	wire				DB_WE
);

	wire		VALID_OUT;
	//---------------------------------------------------------------
	//		DECODER
	//---------------------------------------------------------------
	wire			gpr_a_we	= CMD_DA[4];
	wire			gpr_b_we	= CMD_DB[4];

	wire	[3:0]	gpr_a_wa	= CMD_DA[3:0];
	wire	[3:0]	gpr_b_wa	= CMD_DB[3:0];

	wire			ps_we		= CMD_PS[2];
	wire			ps_mtps		= (CMD_PS[1:0] == 2'b00);
	wire			ps_rfi		= (CMD_PS[1:0] == 2'b01);
	wire			ps_nzcv		= (CMD_PS[1]   == 1'b1);

	//---------------------------------------------------------------
	//		GPR WRITE BACK
	//---------------------------------------------------------------
	// GPR WRITE ENABLE (ACTIVE LOW)
	assign	GPR_A_WEN	= ~((gpr_a_we & VALID) | INT_DETECT);
	assign	GPR_B_WEN	= ~(gpr_b_we & VALID_OUT);

	// 4'b1110: EPC
	assign	GPR_A_WA	= (INT_DETECT) ? 4'b1110 : gpr_a_wa;
	assign	GPR_B_WA	= gpr_b_wa;

	// 0: W_DA
	// 1: W_PC
	assign	GPR_A_SEL	= INT_DETECT;

	//---------------------------------------------------------------
	//		PS WRITE BACK
	//---------------------------------------------------------------
	assign	PS_WE		= (ps_we & VALID) | INT_DETECT;

	assign  PS_SEL[0]	= ~INT_DETECT & ps_nzcv;	// NZCV UPDATE
	assign  PS_SEL[1]	=  INT_DETECT;				// INTERRUPT
	assign  PS_SEL[2]	= ~INT_DETECT & ps_rfi;		// RFI
	assign  PS_SEL[3]	= ~INT_DETECT & ps_mtps;	// MTPS/IEN/IDS

	//---------------------------------------------------------------
	//		PIPELINE REG
	//---------------------------------------------------------------
	assign  DA_WE		= gpr_a_we & VALID_OUT;
	assign  DB_WE		= gpr_b_we & VALID_OUT;

	assign	VALID_OUT	= VALID & ~INT_DETECT;		// NEEDED FOR FORWARDING
endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                             Forward Controlpath                             *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module	FWD_CP (
	//From ID STAGE
	input	wire	[3:0]	D_DA_IDX,
	input	wire			D_DA_VALID,
	input 	wire	[3:0]	D_DB_IDX,
	input	wire			D_DB_VALID,

	//From EX STAGE
	input	wire	[3:0]	E_DA_IDX,
	input	wire			E_DA_VALID,

	//From MEM STAGE
	input	wire	[3:0]	M_DA_IDX,
	input	wire			M_DA_VALID,
	input	wire	[3:0]	M_DB_IDX,
	input	wire			M_DB_VALID,

	//From WB STAGE
	input	wire	[3:0]	W_DA_IDX,
	input	wire			W_DA_VALID,
	input	wire	[3:0]	W_DB_IDX,
	input	wire			W_DB_VALID,

	//FWD_X : Force oprnd X to forward MDA
	input	wire			FWD_X,
	//FWD_Y : Force oprnd Y to forward MDA/WDA
	input	wire	[1:0]	FWD_Y,		// {MDA, WDB}

	//TO EX STAGE : Pipeline Reg. Should be needed
	output	wire 	[5:0]	E_OP_X_SEL,
	output	wire	[5:0]	E_OP_Y_SEL
);

	wire 	d_da_e_da	=	(D_DA_IDX == E_DA_IDX) & (D_DA_VALID & E_DA_VALID) | (FWD_X);
	wire	d_da_m_da	=	(D_DA_IDX == M_DA_IDX) & (D_DA_VALID & M_DA_VALID);
	wire	d_da_m_db 	=	(D_DA_IDX == M_DB_IDX) & (D_DA_VALID & M_DB_VALID);
	wire	d_da_w_da	=	(D_DA_IDX == W_DA_IDX) & (D_DA_VALID & W_DA_VALID);
	wire	d_da_w_db	=	(D_DA_IDX == W_DB_IDX) & (D_DA_VALID & W_DB_VALID);


	wire 	d_db_e_da	=	(D_DB_IDX == E_DA_IDX) & (D_DB_VALID & E_DA_VALID) | (FWD_Y[1]);
	wire	d_db_m_da	=	(D_DB_IDX == M_DA_IDX) & (D_DB_VALID & M_DA_VALID);
	wire	d_db_m_db 	=	(D_DB_IDX == M_DB_IDX) & (D_DB_VALID & M_DB_VALID) | (FWD_Y[0]);
	wire	d_db_w_da	=	(D_DB_IDX == W_DA_IDX) & (D_DB_VALID & W_DA_VALID);
	wire	d_db_w_db	=	(D_DB_IDX == W_DB_IDX) & (D_DB_VALID & W_DB_VALID);


	/************************************************************************************************
	*	<EX_FWD>
	*	ASSUMPTION: 
	*
	*			DATA DEPENDENCY could be occured from only one destination in the same stage.
	*			ex)
	* 			Rn in register_list of LDM  + Update the register Rn to be used as memory address
	*			specially, Rn=15, WB has same destination idx, the operation is not predictable.
	*			
	*			Actually, Mux has a priority. A>B>C>D(ctrl signal has more than 2 ones.)	
	*			   So, use this priority to check forwarding.
	*			
	*			control signals of the forwarding mux are made in ID stage.
	*			But, in Data path, the control signals are assigned 1 cycle after (i.e. EX stage) 
	*			
	*			Reg.File has a inverted CLK. AND there is a delay for storing data.
	*			- Data could be stored in the middle of WB STG.
	*			
	*			WHY don't FWD_WDA exist in D_DA_W_DA?
	*			-Other FWD Logics SHOULD NOT affect the effect of FWD_WDA.
	*			
	*			
	*			
	************************************************************************************************/
	//cE_MUX_CTRL_X(EX STAGE FWD - 1 cycle before)
	//000001 : M_DA
	//000010 : W_DA
	//000100 : W_DB
	//001000 : P_DA
	//010000 : P_DB
	//100000 : E_X
	assign E_OP_X_SEL[0] =  d_da_e_da;
	assign E_OP_X_SEL[1] = ~d_da_e_da &  d_da_m_da;
	assign E_OP_X_SEL[2] = ~d_da_e_da & ~d_da_m_da &  d_da_m_db;
	assign E_OP_X_SEL[3] = ~d_da_e_da & ~d_da_m_da & ~d_da_m_db &  d_da_w_da;
	assign E_OP_X_SEL[4] = ~d_da_e_da & ~d_da_m_da & ~d_da_m_db & ~d_da_w_da &  d_da_w_db;
	assign E_OP_X_SEL[5] = ~d_da_e_da & ~d_da_m_da & ~d_da_m_db & ~d_da_w_da & ~d_da_w_db;


	//cE_MUX_CTRL_Y(EX STAGE FWD - 1 cycle before)
	//000001 : M_DA
	//000010 : W_DA
	//000100 : W_DB
	//001000 : P_DA
	//010000 : P_DB
	//100000 : E_Y
	assign E_OP_Y_SEL[0] =  d_db_e_da;
	assign E_OP_Y_SEL[1] = ~d_db_e_da &  d_db_m_da;
	assign E_OP_Y_SEL[2] = ~d_db_e_da & ~d_db_m_da &  d_db_m_db;
	assign E_OP_Y_SEL[3] = ~d_db_e_da & ~d_db_m_da & ~d_db_m_db &  d_db_w_da;
	assign E_OP_Y_SEL[4] = ~d_db_e_da & ~d_db_m_da & ~d_db_m_db & ~d_db_w_da &  d_db_w_db;
	assign E_OP_Y_SEL[5] = ~d_db_e_da & ~d_db_m_da & ~d_db_m_db & ~d_db_w_da & ~d_db_w_db;

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                               Foward Controlpath                            *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module	FWD_CP_IMME (
	//From ID STAGE
	input	wire	[3:0]	D_DA_IDX,

	//From MEM STAGE
	input	wire	[3:0]	M_DA_IDX,
	input	wire			M_DA_VALID,
	input	wire			M_U_WE,

	//From WB STAGE
	input	wire	[3:0]	W_DA_IDX,
	input	wire			W_DA_VALID,
	input	wire	[3:0]	W_DB_IDX,
	input	wire			W_DB_VALID,
	input	wire			W_U_WE,

	//FWD_WDA : Force Oprnd WDA to forward WDA
//			input	wire			FWD_WDA,

	//TO ID STAGE : Pipeline Reg. Should NOT be needed
	output	wire	[3:0]	D_REG_SEL,

	//TO EX STAGE : Pipeline Reg. Should NOT be needed
	output	wire			E_NZCV_SEL
);

    // synopsys dc_script_begin
    // set_max_delay 0.5 -from all_inputs() -to all_outputs()
    // synopsys dc_script_end

	//START ID FWD
	wire	d_da_m_da_id	= (D_DA_IDX == M_DA_IDX) & (M_DA_VALID);
	wire	d_da_w_da_id	= (D_DA_IDX == W_DA_IDX) & (W_DA_VALID);
	wire	d_da_w_db_id	= (D_DA_IDX == W_DB_IDX) & (W_DB_VALID);

	/************************************************************************************************
	*	<EX_FWD>
	*	ASSUMPTION: 
	*
	*			DATA DEPENDENCY could be occured from only one destination in the same stage.
	*			ex)
	* 			Rn in register_list of LDM  + Update the register Rn to be used as memory address
	*			specially, Rn=15, WB has same destination idx, the operation is not predictable.
	*			
	*			Actually, Mux has a priority. A>B>C>D(ctrl signal has more than 2 ones.)	
	*			   So, use this priority to check forwarding.
	*			
	*			control signals of the forwarding mux are made in ID stage.
	*			But, in Data path, the control signals are assigned 1 cycle after (i.e. EX stage) 
	*			
	*			Reg.File has a inverted CLK. AND there is a delay for storing data.
	*			- Data could be stored in the middle of WB STG.
	*			
	*			WHY don't FWD_WDA exist in D_DA_W_DA?
	*			-Other FWD Logics SHOULD NOT affect the effect of FWD_WDA.
	*			
	*			
	*			
	************************************************************************************************/

	//D_REG_SEL(ID STAGE FWD - IMMEDIATE FWD)
	//0001 : M_DA 
	//0010 : W_DA
	//0100 : W_DB
	//1000 : D_GRF_X ( :->E_X, Next Cycle )
	assign D_REG_SEL[0] =  d_da_m_da_id;
	assign D_REG_SEL[1] = ~d_da_m_da_id &  d_da_w_da_id;
	assign D_REG_SEL[2] = ~d_da_m_da_id & ~d_da_w_da_id &  d_da_w_db_id;
	assign D_REG_SEL[3] = ~d_da_m_da_id & ~d_da_w_da_id & ~d_da_w_db_id;

	//E_NZCV_SEL
	//0 : PS[6:3]
	//1 : M_NZCV
	assign	E_NZCV_SEL	= (M_U_WE) | (W_U_WE);

endmodule

/******************************************************************************
*                                                                             *
*                               Core-A Processor                              *
*                                                                             *
*                            Interrupt Control Unit                           *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By Ji-Hoon Kim    *
*                                                             Duk-Hyun You    *
*                                                             Ki-Seok Kwon    *
*                                                              Eun-Joo Bae    *
*                                                              Won-Hee Son    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                            E-mail : icpark@ee.kaist.ac.kr   *
*                                                                             *
*******************************************************************************/

module	IntControl(
	input	wire			E_INT,
	input	wire			M_INT,
	input	wire			DFAULT,
	input	wire	[9:0]	INT_FIELD,
							// 9 SYNCHRONOUS RESET
							// 8 DMMU FAULT
							// 7 DMEM DED
							// 6 UNDEFINED INSTRUCTION
							// 5 GPR DED
							// 4 SOFTWARE INTERRUPT
							// 3 EXTERNAL INTERRUPT
							// 2 IMMU FAULT
							// 1 IMEM DED
							// 0 COPROCESSOR INTERRUPT

	output	wire			DONT_MREQ,
	output	reg				INT_DETECT,
	output	reg		[2:0]	INT_VECTOR
);

	assign	DONT_MREQ	= INT_DETECT | E_INT | M_INT | DFAULT;

	always @ *
	begin
		casex (INT_FIELD)
			10'b1xxxxxxxxx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b000 };
			10'b01xxxxxxxx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b001 };
			10'b001xxxxxxx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b111 };	// DMEM DED
			10'b0001xxxxxx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b010 };
			10'b00001xxxxx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b111 };	// GPR DED
			10'b000001xxxx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b011 };
			10'b0000001xxx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b100 };
			10'b00000001xx: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b101 };
			10'b000000001x: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b111 };	// IMEM DED
			10'b0000000001: {INT_DETECT, INT_VECTOR} <= { 1'b1, 3'b110 };
			10'b0000000000: {INT_DETECT, INT_VECTOR} <= { 1'b0, 3'bxxx };
		endcase
	end
endmodule

/****************************************************************************
*                                                                           *
*                 Slave  Wrapper for Synchronous on-chip SRAM				*
*                                                                           *
*****************************************************************************/
//	----------------------------------------------------------------------------
// 20110715
// Jinook Song
// Slave Wrapper for Synchronous on-chip SRAM
// 		See the SLV_WRP_timediagram_20110715.jpg
// 		Support Burst Transfer w/ incremental and wrapping modes
// 		Provide a register for latching the output of synchronous on-chip SRAM
//	----------------------------------------------------------------------------
//	20110907
//	Jinook Song
//		Separate generating en_SxRDY from big control table, due to timing
//		arc.


module SLV_WRP (
	// Common Control Signals
	input	wire					CLK, 
	input	wire					nRST, 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	input	wire					DxSEL, 

	input	wire					MmWT, 
	input	wire		[2:0]		MmSZ, 
	input	wire		[3:0]		MmRB, 
	input	wire		[2:0]		MmMOD, 
	input	wire		[31:0]		MmADDR, 
	input	wire		[38:0]		MmWDT, 

	input	wire					MsRDY, 

	// Signals To Core-B Lite On-Chip High-Speed Bus
	output	wire		[38:0]		SxRDT, 

	output	wire					SxRDY, 
	output	wire					SxERR, 

	// Signals From Slave Core
	input	wire					SCx_nWAIT, 
	input	wire					SCx_FAULT, 
	input	wire					SCx_TimeOut,
	input	wire		[38:0]		SCx_RDT, 

	// Signals To Slave Core
	output	wire					SCx_REQ, 
	output	wire					SCx_WT, 
	output	reg			[3:0]		SCx_BE,
	output	wire		[31:0]		SCx_ADDR, 

	output	wire		[38:0]		SCx_WDT
);
//////////////////////////////
//	MmMOD Signal Encoding	//
//////////////////////////////
localparam		IDLE		=	3'b000;
localparam		BUSY		=	3'b001;
localparam		LDADDR		=	3'b010;
localparam		SEQADDR		=	3'b011;
localparam		LDWRPADDR	=	3'b110;
localparam		WRPADDR		=	3'b111;

//////////////////////////////
//	MmWT Signal Encoding	//
//////////////////////////////
localparam		WT			=	1'b1;	//WRITE
localparam		RD			= 	1'b0;	//READ

//////////////////////////////
//	MmSZ Signal Encoding	//
//////////////////////////////
localparam		BT = 3'b000;
localparam		HWD= 3'b001;
localparam		WD = 3'b010;



//Latched Signals
reg					L_DxSEL;
reg					L_MmWT;
reg		[2:0]		L_MmMOD;
reg		[2:0]		L_MmSZ;
reg		[3:0]		L_MmRB;
reg		[31:0]		L_MmADDR;
reg		[3:0]		L_Burst_SZ;

wire				en_mx_addr;
wire				en_mx_control;
wire				rst_mx_control;
wire				sel_ld_addr;	// 1/0: MmADDR/(Incremended or wrapped MmADDR)
wire	[31:0]		operatedMmADDR;
//always	@(posedge	CLK	or negedge	nRST)	begin
always	@(posedge	CLK)	begin
	if(en_mx_addr)	begin
		L_MmADDR	<=	sel_ld_addr?	MmADDR	:	operatedMmADDR;	
		L_Burst_SZ	<=	MmRB;
	end
end

//always	@(posedge	CLK or negedge	nRST)	begin
always	@(posedge	CLK)	begin
	if(~nRST)	begin
		{L_DxSEL,	L_MmWT,	L_MmMOD,	L_MmSZ,	L_MmRB}	<=	{1'b0, RD, IDLE, BT, 4'd0}; 
	end
	else if(rst_mx_control)	begin
		{L_DxSEL,	L_MmWT,	L_MmMOD,	L_MmSZ,	L_MmRB}	<=	{1'b0, RD, IDLE, BT, 4'd0}; 
	end
	else	if(en_mx_control)	begin
		{L_DxSEL,	L_MmWT,	L_MmMOD,	L_MmSZ,	L_MmRB}	<=	{DxSEL, MmWT, MmMOD, MmSZ, MmRB}; 	
	end
end
wire				L_MmLST;	// Last Transfer
assign	L_MmLST		= ~(|L_MmRB);

reg		[7:0]		INC;
reg     [31:0]      Wrap_MASK;  // Wrapping Mask
//  INC :	Amount of Increment 
always @* begin
	casex(L_MmSZ)
		3'b000 : INC = 8'd1;	//Byte
		3'b001 : INC = 8'd2;	// Halfword
		3'b010 : INC = 8'd4;	// Word
		3'b011 : INC = 8'd8;	// 2 Words
		3'b100 : INC = 8'd16;	// 4 Words
		3'b101 : INC = 8'd32;	// 16 Words
		3'b110 : INC = 8'd64;	// 32 Words
		3'b111 : INC = 8'd128;	// 64 Words
	endcase
end
//  Wrap_MASK : Wrapping mask
always @* begin
	casex(L_MmSZ)
		3'b000 : Wrap_MASK	<=	{28'b0, L_Burst_SZ[3:0]};		// Byte
		3'b001 : Wrap_MASK	<=	{27'b0, L_Burst_SZ[3:0], 1'b0};	// Halfword
		3'b010 : Wrap_MASK	<=	{26'b0, L_Burst_SZ[3:0], 2'b0};	// Word
		3'b011 : Wrap_MASK	<=	{25'b0, L_Burst_SZ[3:0], 3'b0};	// 2 Words
		3'b100 : Wrap_MASK	<=	{24'b0, L_Burst_SZ[3:0], 4'b0};	// 4 Words
		3'b101 : Wrap_MASK	<=	{23'b0, L_Burst_SZ[3:0], 5'b0};	// 16 Words
		3'b110 : Wrap_MASK	<=	{22'b0, L_Burst_SZ[3:0], 6'b0};	// 32 Words
		3'b111 : Wrap_MASK	<=	{21'b0, L_Burst_SZ[3:0], 7'b0};	// 64 Words
	endcase
end
wire				find_WRAP;
assign  find_WRAP		= (L_MmMOD[2:1] == 2'b11)? ((Wrap_MASK&L_MmADDR) == Wrap_MASK) : 0;
assign	operatedMmADDR	= find_WRAP?	L_MmADDR&(~Wrap_MASK):	L_MmADDR	+ INC; 

//	----------------------------------------------------------------------------
//	Wrapper Outputs 
//	----------------------------------------------------------------------------
wire				sel_scx;	// 1/0: When Read/When Write
wire				sel_scx_addr;
wire				sel_opADDR;	// 1/0: Operated MmADDR/ loaded MmADDR
wire	[2:0]		t_SCx_BE;	// temporary signal of SCx_BE
wire	[31:0]		selected_opADDR;
wire				current_req;
wire				latched_req;
wire				en_SxRDY;
wire				en_SCxREQ;

assign	current_req		= DxSEL&MmMOD[1]&(~MmWT);
//assign	latched_req		= L_DxSEL&L_MmMOD[1]&L_MmWT; //!!
assign	latched_req		= L_DxSEL&L_MmMOD[1];
assign	SCx_REQ			= sel_scx?	current_req&en_SCxREQ	:	latched_req&en_SCxREQ;

assign	SCx_WT			= sel_scx?	MmWT			:	L_MmWT;

assign	t_SCx_BE		= sel_scx?	MmSZ			:	L_MmSZ;
always @* begin
	casex({t_SCx_BE, SCx_ADDR[1:0]})
		// Byte
		{3'b000, 2'b00} : SCx_BE <= 4'b0001;
		{3'b000, 2'b01} : SCx_BE <= 4'b0010;
		{3'b000, 2'b10} : SCx_BE <= 4'b0100;
		{3'b000, 2'b11} : SCx_BE <= 4'b1000;
		// Halfword
		{3'b001, 2'b00} : SCx_BE <= 4'b0011;
		{3'b001, 2'b10} : SCx_BE <= 4'b1100;
		// Word
		{3'b010, 2'b00} : SCx_BE <= 4'b1111;
			default		: SCx_BE <= 4'b0000;
	endcase
end
assign	selected_opADDR	= sel_opADDR?	operatedMmADDR	:	L_MmADDR;
assign	SCx_ADDR		= sel_scx_addr?	MmADDR			:	selected_opADDR;

reg		[38:0]			t_SCx_WDT;
always@*
begin
	casex(	{L_MmWT,	L_MmSZ,	SCx_ADDR[1:0]})
	{1'bx,	BT,		2'b00}: t_SCx_WDT <= {7'b0, 8'b0, 8'b0, 8'b0, MmWDT[7:0]};
	{1'bx,	BT,		2'b01}: t_SCx_WDT <= {7'b0, 8'b0, 8'b0, MmWDT[7:0], 8'b0};
	{1'bx,	BT,		2'b10}: t_SCx_WDT <= {7'b0, 8'b0, MmWDT[7:0], 8'b0, 8'b0};
	{1'bx,	BT,		2'b11}: t_SCx_WDT <= {7'b0, MmWDT[7:0], 8'b0, 8'b0, 8'b0};
	{1'bx,	HWD,	2'b00}: t_SCx_WDT <= {7'b0, 16'b0, MmWDT[15:0]};
	{1'bx,	HWD,	2'b10}: t_SCx_WDT <= {7'b0, MmWDT[15:0], 16'b0};
	{1'bx,	WD,		2'bx} : t_SCx_WDT <= MmWDT;
	default		   		  : t_SCx_WDT <= MmWDT;
	endcase	
end
assign	SCx_WDT			= t_SCx_WDT;
reg		[38:0]			t_SCx_RDT;
reg		[38:0]			tt_SCx_RDT;
always	@(posedge	CLK)	begin
	if(SCx_nWAIT)	begin
		t_SCx_RDT		<= tt_SCx_RDT;
	end
end
//	1.	SxRDT
always@*
begin
	casex({L_MmWT,	L_MmSZ, SCx_ADDR[1:0]})
	{1'bx,	BT,		2'b00}: tt_SCx_RDT <= {7'b0, 8'b0,	8'b0,	8'b0,	SCx_RDT[7:0]};
	{1'bx,	BT,		2'b01}: tt_SCx_RDT <= {7'b0, 8'b0,	8'b0,	8'b0,	SCx_RDT[15:8]};
	{1'bx,	BT,		2'b10}: tt_SCx_RDT <= {7'b0, 8'b0, 	8'b0,	8'b0,	SCx_RDT[23:16]};
	{1'bx,	BT,		2'b11}: tt_SCx_RDT <= {7'b0, 8'b0,	8'b0,	8'b0,	SCx_RDT[31:24]};

	{1'bx,	HWD,	2'b00}: tt_SCx_RDT <= {7'b0, 16'b0,	SCx_RDT[15:0]};
	{1'bx,	HWD,	2'b10}: tt_SCx_RDT <= {7'b0, 16'b0,	SCx_RDT[31:16]};

	{1'bx,	WD,		2'bx} : tt_SCx_RDT <= SCx_RDT;
	default			      : tt_SCx_RDT <= SCx_RDT;
	endcase	
end

assign	SxRDT			= t_SCx_RDT;
assign	SxRDY			= (SCx_nWAIT&en_SxRDY)|SCx_FAULT;
reg						t_SCx_ERR;
always	@(posedge	CLK or	negedge	nRST)	begin
	if(~nRST)				t_SCx_ERR	<=	1'b0;
	else	if(SCx_nWAIT)	t_SCx_ERR	<=	SCx_FAULT;
end


assign	SxERR			= t_SCx_ERR;
//	----------------------------------------------------------------------------
//
//		FSM
//
//	----------------------------------------------------------------------------

reg		[1:0]		state;
wire	[1:0]		nxt_state;
wire	[4:0]		debug;
reg		[14:0]		temp;

assign	{nxt_state, en_mx_addr, sel_ld_addr, en_mx_control, rst_mx_control, en_SCxREQ, sel_scx, sel_scx_addr, sel_opADDR, debug}	=	temp;
localparam		ST_IDLE	=	2'b00;//DFT
localparam		ST_WREQ	=	2'b01;//WD
localparam		ST_RREQ	=	2'b10;//RD REQ
localparam		ST_RWAIT=	2'b11;//RD WAIT
//always	@(posedge	CLK	or	negedge	nRST)	begin
always	@(posedge	CLK)	begin
	if(~nRST)	state	<=	ST_IDLE;
	else		state	<=	nxt_state;
end

always  @*      begin
	        casex({state, DxSEL, MmMOD, MmWT, L_DxSEL, L_MmMOD, L_MmWT, L_MmLST, MsRDY, SCx_nWAIT, SCx_FAULT})
				{ST_IDLE , 1'bx, 3'bxxx   , 1'bx, 1'b1, LDADDR   , RD  , 1'bx, 1'bx, 1'b1, 1'b0}: temp <= {ST_RWAIT, 8'b11_00_10_00, 5'd0}; //!!

				{ST_IDLE , 1'b0, 3'bxxx   , 1'bx, 1'b0, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'bx, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd0};

				{ST_IDLE , 1'b1, BUSY     , 1'bx, 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'bx, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd1};
				{ST_IDLE , 1'b1, LDADDR   , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b0, 1'bx, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd2};
				{ST_IDLE , 1'b1, LDADDR   , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b1, 1'b0, 1'b0}: temp <= {ST_WREQ , 8'b11_10_10_00, 5'd3};
				{ST_IDLE , 1'b1, LDADDR   , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b1, 1'b1, 1'b0}: temp <= {ST_RWAIT, 8'b11_10_11_1x, 5'd4};
				{ST_IDLE , 1'b1, LDADDR   , WT  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b0, 1'bx, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd5};
				{ST_IDLE , 1'b1, LDADDR   , WT  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b1, 1'bx, 1'b0}: temp <= {ST_WREQ , 8'b11_10_00_00, 5'd6};

				{ST_IDLE , 1'b1, LDWRPADDR, RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b0, 1'bx, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd7};
				{ST_IDLE , 1'b1, LDWRPADDR, RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b1, 1'b0, 1'b0}: temp <= {ST_WREQ , 8'b11_10_10_00, 5'd8};
				{ST_IDLE , 1'b1, LDWRPADDR, RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b1, 1'b1, 1'b0}: temp <= {ST_RWAIT, 8'b11_10_11_1x, 5'd9};
				{ST_IDLE , 1'b1, LDWRPADDR, WT  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b0, 1'bx, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd10};
				{ST_IDLE , 1'b1, LDWRPADDR, WT  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'b1, 1'bx, 1'b0}: temp <= {ST_WREQ , 8'b11_10_00_00, 5'd11};


				{ST_RWAIT, 1'bx, 3'bxxx   , 1'bx, 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'b0, 1'b0}: temp <= {ST_RWAIT, 8'b00_00_01_00, 5'd12};
				{ST_RWAIT, 1'bx, 3'bxxx   , 1'bx, 1'bx, 3'bxxx   , 1'bx, 1'b1, 1'bx, 1'b1, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd13};
				{ST_RWAIT, 1'bx, 3'bxxx   , 1'bx, 1'bx, 3'bxxx   , 1'bx, 1'b0, 1'bx, 1'b1, 1'b0}: temp <= {ST_RREQ , 8'b0x_00_01_1x, 5'd14};

				{ST_RREQ , 1'b1, LDADDR   , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'bx, 1'b0}: temp <= {ST_RREQ , 8'b11_10_11_1x, 5'd15};
				{ST_RREQ , 1'b1, SEQADDR  , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'b0, 1'b0}: temp <= {ST_RREQ , 8'b00_10_11_01, 5'd16};
				{ST_RREQ , 1'b1, SEQADDR  , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'b1, 1'b0}: temp <= {ST_RWAIT, 8'b10_10_11_01, 5'd17};

				{ST_RREQ , 1'b1, LDWRPADDR, RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'bx, 1'b0}: temp <= {ST_RREQ , 8'b11_10_11_1x, 5'd18};
				{ST_RREQ , 1'b1, WRPADDR  , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'b0, 1'b0}: temp <= {ST_RREQ , 8'b00_10_11_01, 5'd19};
				{ST_RREQ , 1'b1, WRPADDR  , RD  , 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'b1, 1'b0}: temp <= {ST_RWAIT, 8'b10_10_11_01, 5'd20};

				{ST_WREQ , 1'b1, 3'bxxx   , 1'bx, 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'b0, 1'b0}: temp <= {ST_WREQ , 8'b0x_00_10_00, 5'd21};
				{ST_WREQ , 1'b1, BUSY     , 1'bx, 1'bx, 3'bxxx   , 1'bx, 1'bx, 1'bx, 1'b1, 1'b0}: temp <= {ST_WREQ , 8'b0x_00_00_00, 5'd22};

				{ST_WREQ , 1'b0, 3'bxxx   , 1'bx, 1'bx, 3'bxxx   , WT  , 1'b1, 1'bx, 1'b1, 1'b0}: temp <= {ST_IDLE , 8'bxx_x1_10_00, 5'd23};
				{ST_WREQ , 1'b1, 3'bxxx   , 1'bx, 1'bx, 3'bxxx   , WT  , 1'b1, 1'bx, 1'b1, 1'b0}: temp <= {ST_IDLE , 8'b11_10_10_00, 5'd24}; //!!

				{ST_WREQ , 1'b1, LDADDR   , WT  , 1'bx, 3'bxxx   , WT  , 1'b0, 1'bx, 1'b1, 1'b0}: temp <= {ST_WREQ , 8'b11_10_10_00, 5'd25};
				{ST_WREQ , 1'b1, SEQADDR  , WT  , 1'bx, 3'bxxx   , WT  , 1'b0, 1'bx, 1'b1, 1'b0}: temp <= {ST_WREQ , 8'b10_10_10_00, 5'd26};
				{ST_WREQ , 1'b1, LDWRPADDR, WT  , 1'bx, 3'bxxx   , WT  , 1'b0, 1'bx, 1'b1, 1'b0}: temp <= {ST_WREQ , 8'b11_10_10_00, 5'd27};
				{ST_WREQ , 1'b1, WRPADDR  , WT  , 1'bx, 3'bxxx   , WT  , 1'b0, 1'bx, 1'b1, 1'b0}: temp <= {ST_WREQ , 8'b10_10_10_00, 5'd28};

				{ST_WREQ , 1'bx, 3'bxxx   , 1'bx, 1'bx, LDADDR   , RD  , 1'bx, 1'bx, 1'b1, 1'b0}: temp <= {ST_RWAIT, 8'b0x_00_10_00, 5'd29};
				{ST_WREQ , 1'bx, 3'bxxx   , 1'bx, 1'bx, LDWRPADDR, RD  , 1'bx, 1'bx, 1'b1, 1'b0}: temp <= {ST_RWAIT, 8'b0x_00_10_00, 5'd30};

				default                                                                   : temp <= {ST_IDLE , 8'bxx_x1_01_1x, 5'd31};
        endcase
end

assign  en_SxRDY        = (state==ST_IDLE & ~L_DxSEL) | (state==ST_RREQ) | ((state==ST_WREQ)&((~(L_MmWT==WT)&(L_MmLST==1))|(~(L_MmWT==RD))));



endmodule

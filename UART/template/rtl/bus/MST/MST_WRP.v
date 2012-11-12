/****************************************************************************
*                                                                           *
*                           Master Wrapper                                  *
*                                                                           *
*****************************************************************************/
// 20110715, Jinook Song, MxMOD is modified, 3bits


module MST_WRP (
	// Common Control Signals
	input	wire						CLK, 
	input	wire						nRST, 
	
	// Signals From Master Core
	input	wire						MCx_REQ, 
	input	wire						MCx_LK, 
	input	wire						MCx_WT, 
	input	wire		[2:0]			MCx_SZ, 
	input	wire		[3:0]			MCx_RB, 
	input	wire		[2:0]			MCx_MOD, 
	input	wire		[31:0]			MCx_ADDR, 
	input	wire		[38:0]			MCx_WDT,

	// Signals To Master Core
	output	wire						MCx_nWAIT, 
	output	wire						MCx_ERR,
	output	wire		[38:0]			MCx_RDT,


	// Signals From Core-B Lite On-Chip High-Speed Bus
	input	wire						AxGNT, 
	input	wire						MsRDY, 
	input	wire						MsERR, 
	input	wire		[38:0]			MsRDT, 

	// Signals To Core-B Lite On-Chip High-Speed Bus
	output	wire						MxREQ, 
	output	wire						MxLK, 
	output	wire						MxWT, 		// Write(1) Read(0)
	output	wire		[2:0]			MxSZ,
	output	wire		[3:0]			MxRB, 
	output	wire		[2:0]			MxMOD, 
	output	wire		[31:0]			MxADDR, 
	output	wire		[38:0]			MxWDT
);

//	LATCHING the Signals from Master Core
reg						L_MCx_REQ;
reg		[2:0]			L_MCx_SZ; 
reg						L_MCx_LK; 
reg		[31:0]			L_MCx_ADDR; 
reg		[38:0]			L_MCx_WDT;
reg		[38:0]			L2_MCx_WDT;
reg						L_MCx_WT; 
reg		[3:0]			L_MCx_RB; 
reg		[2:0]			L_MCx_MOD; 


reg		[1:0]			state;
wire	[1:0]			next_state;

wire					LAST;
wire					MCx_latch_en;


/*******************************************/
/***		   State Assignment			 ***/
/*******************************************/
localparam		ST_DFT 			= 	2'b00;
localparam		ST_ADDR			= 	2'b01;
localparam		ST_ADnDT		=	2'b10; 
localparam		ST_DATA			=	2'b11; 


/*******************************************/
/***		 Finite State Machine		 ***/
/*******************************************/
always @ (posedge CLK or negedge nRST)
begin
	if(~nRST)	state <= ST_DFT;
	else		state <= next_state;
end


MST_WRP_FSM mst_wrp_fsm (
	.state			(state),
	.L_MCx_REQ		(L_MCx_REQ),
	.L_MCx_WT		(L_MCx_WT),
	.MsRDY			(MsRDY),
	.AxGNT			(AxGNT),
	.MsERR			(MsERR),
	.LAST			(LAST),
	.MxREQ			(MxREQ),
	.MCx_nWAIT		(MCx_nWAIT),
	.MCx_latch_en	(MCx_latch_en),
	.next_state		(next_state)
);

assign	LAST = (state[1])? (MCx_RB==4'b0) : (L_MCx_RB==4'b0);


/******************************************/
/***	Master Core Signal Capture		***/
/******************************************/
always @ (posedge CLK or negedge nRST)
begin
	if(~nRST)	
		{L_MCx_REQ, L_MCx_SZ, L_MCx_LK, L_MCx_ADDR, L_MCx_WDT, L_MCx_WT, L_MCx_RB, L_MCx_MOD} 
			<= {1'b0, 3'b0, 1'b0, 32'b0, 39'b0, 1'b0, 4'b0, 3'b0};

	else if(MCx_latch_en) begin
		L_MCx_REQ	<= MCx_REQ;
		if(MCx_REQ)
			{L_MCx_SZ, L_MCx_LK, L_MCx_ADDR, L_MCx_WDT, L_MCx_WT, L_MCx_RB, L_MCx_MOD} 
				<= {MCx_SZ, MCx_LK, MCx_ADDR, MCx_WDT, MCx_WT, MCx_RB, MCx_MOD};
	end
end

always @ (posedge CLK or negedge nRST)
begin
	if(~nRST)			L2_MCx_WDT <= 39'b0;
	else if(MCx_latch_en)
		if(state[1])	L2_MCx_WDT <= MCx_WDT;
		else			L2_MCx_WDT <= L_MCx_WDT;
end


/******************************************/
/***	Output Signals To Master Core	***/
/******************************************/

//assign	MCx_RDT = MsRDT;

reg		[38:0]	ext_MsRDT;
always @ (posedge CLK or negedge nRST)
begin
	if(~nRST)	ext_MsRDT <= 39'b0;
	else if(!L_MCx_WT & state[1] & MsRDY)
				ext_MsRDT <= MsRDT;
end

assign	MCx_RDT = (!L_MCx_WT & state[1] & MsRDY)?	MsRDT : ext_MsRDT;
assign	MCx_ERR = MsERR;


/******************************************/
/***		Output Signals To MCx_-B	***/
/******************************************/

assign	MxLK	= L_MCx_LK;
assign	MxWT	= L_MCx_WT;
assign	MxSZ	= L_MCx_SZ;
assign	MxRB	= (state[1])?  MCx_RB	: L_MCx_RB;
assign	MxMOD	= (state[1])?  MCx_MOD	: (state[0])? L_MCx_MOD : 3'b0;
assign	MxADDR	= (state[1])?  MCx_ADDR	: L_MCx_ADDR;
assign	MxWDT	= L2_MCx_WDT;

endmodule



/****************************************************************************
*                           Finite State Machine                            *
*****************************************************************************/
module MST_WRP_FSM(
	input	wire	[1:0]	state,
	input	wire			L_MCx_REQ,
	input	wire			L_MCx_WT,
	input	wire			MsRDY,
	input	wire			AxGNT,
	input	wire			MsERR,
	input	wire			LAST,
	output	wire			MxREQ,
	output	wire			MCx_nWAIT,
	output	wire			MCx_latch_en,
	output	wire	[1:0]	next_state
);
localparam ST_DFT = 2'd0;
localparam ST_ADDR = 2'd1;
localparam ST_ADnDT = 2'd2;
localparam ST_DATA = 2'd3;
reg	[4:0]	tmp13460875;
assign	{MxREQ, MCx_nWAIT, MCx_latch_en, next_state} = tmp13460875;
always @*
	casex({state[1:0], L_MCx_REQ, L_MCx_WT, MsRDY, AxGNT, MsERR, LAST})
		{ST_DFT  , 1'b0, 1'bx, 1'bx, 1'bx, 1'bx, 1'bx}: tmp13460875  <=  {1'b0, 1'b1, 1'b1, ST_DFT};
		{ST_DFT  , 1'b1, 1'bx, 1'b0, 1'bx, 1'bx, 1'bx}: tmp13460875  <=  {1'b1, 1'b0, 1'b0, ST_DFT};
		{ST_DFT  , 1'b1, 1'bx, 1'b1, 1'b0, 1'bx, 1'bx}: tmp13460875  <=  {1'b1, 1'b0, 1'b0, ST_DFT};
		{ST_DFT  , 1'b1, 1'bx, 1'b1, 1'b1, 1'bx, 1'bx}: tmp13460875  <=  {1'b1, 1'b0, 1'b0, ST_ADDR};

		{ST_ADDR , 1'bx, 1'bx, 1'b0, 1'bx, 1'bx, 1'bx}: tmp13460875  <=  {1'b0, 1'b0, 1'b0, ST_ADDR};
		{ST_ADDR , 1'bx, 1'bx, 1'b1, 1'bx, 1'bx, 1'b0}: tmp13460875  <=  {1'b0, 1'b0, 1'b1, ST_ADnDT};
		{ST_ADDR , 1'bx, 1'bx, 1'b1, 1'bx, 1'bx, 1'b1}: tmp13460875  <=  {1'b0, 1'b0, 1'b1, ST_DATA};

		{ST_ADnDT, 1'bx, 1'bx, 1'b0, 1'bx, 1'bx, 1'bx}: tmp13460875  <=  {1'b0, 1'b0, 1'b0, ST_ADnDT};
		{ST_ADnDT, 1'bx, 1'bx, 1'b1, 1'bx, 1'b1, 1'bx}: tmp13460875  <=  {1'b0, 1'b1, 1'b1, ST_DFT};
		{ST_ADnDT, 1'bx, 1'bx, 1'b1, 1'bx, 1'b0, 1'b0}: tmp13460875  <=  {1'b0, 1'b1, 1'b1, ST_ADnDT};
		{ST_ADnDT, 1'bx, 1'bx, 1'b1, 1'bx, 1'b0, 1'b1}: tmp13460875  <=  {1'b0, 1'b1, 1'b1, ST_DATA};

		{ST_DATA , 1'bx, 1'bx, 1'b0, 1'bx, 1'bx, 1'bx}: tmp13460875  <=  {1'b0, 1'b0, 1'b0, ST_DATA};
		{ST_DATA , 1'bx, 1'bx, 1'b1, 1'bx, 1'b1, 1'bx}: tmp13460875  <=  {1'b0, 1'b1, 1'b1, ST_DFT};
		{ST_DATA , 1'bx, 1'bx, 1'b1, 1'bx, 1'b0, 1'bx}: tmp13460875  <=  {1'b0, 1'b1, 1'b1, ST_DFT};

		//default: tmp13460875  <=  {1'b1, 1'b1, ST_DFT};
	endcase
endmodule

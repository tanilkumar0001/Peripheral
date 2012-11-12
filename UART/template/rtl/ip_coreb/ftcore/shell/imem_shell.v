module	IMEM_Shell	#(
	parameter	REWRITE_EN = 1
)(
	input	wire				CLK,
	input	wire				RST,
	
	// From MEMORY
	input	wire	[38:0]		IRDATAi,
	input	wire				nIWAITi,

	// To MEMORY
	output	wire				IREQo,
	output	wire	[29:0]		IADDRo,
	output	wire				IRWo,	// 0RD 1WT
	output	wire	[38:0]		IWDATAo,

	// From CORE
	input	wire				IREQi,
	input	wire	[29:0]		IADDRi,

	// To CORE
	output	wire	[31:0]		IRDATAo,
	output	wire				IMEM_DEDo,
	output	wire				nIWAITo
);


// WAIT PROCESS
wire			shell_ready;
assign			nIWAITo = shell_ready & nIWAITi;

wire			gCLK;

ClockGate	cg_imem_shell (
	.en		(nIWAITi),
	.CLK	(CLK),
	.gCLK	(gCLK)
);



// HAMMING ENCODER & DECODER
wire			IMEM_SEC;

HAMM_ENC_SYS32	enc	(
	.DIN	(IRDATAo),
	.DOUT	(IWDATAo)
);

HAMM_DEC_SYS32	dec	(
	.DIN	(IRDATAi),
	.DOUT	(IRDATAo),
	.SEC	(IMEM_SEC),
	.DED	(IMEM_DEDo)
);



// FSM
localparam	ST_DFT = 1'b0;
localparam	ST_SEC = 1'b1;

reg				state;
wire			next_state;

always @ (posedge gCLK)
begin
	if(RST)	state <= ST_DFT;
	else	state <= next_state;
end


reg				latched_IREQi;
reg		[29:0]	latched_IADDRi;
wire			iaddr_sel;	// 0:IADDRi // 1:latched_IADDRi

assign			IADDRo = (iaddr_sel)? latched_IADDRi : IADDRi;

always @ (posedge gCLK)
begin
	if(RST)
		{latched_IREQi, latched_IADDRi} <= {1'b0, 30'b0};
	else if(shell_ready)
		{latched_IREQi, latched_IADDRi} <= {IREQi, IADDRi};
end



reg		[8:0]	temp;
wire	[3:0]	debug;
assign	{next_state, IREQo, IRWo, iaddr_sel, shell_ready, debug} = temp;

always @ *
begin
	if(REWRITE_EN)
	    casex({state, latched_IREQi, IREQi, IMEM_SEC})
			{ST_DFT,1'b0,1'b0,1'bx}: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd0};
			{ST_DFT,1'b0,1'b1,1'bx}: temp <= {ST_DFT,1'b1,1'b0,1'b0,1'b1,4'd1};
	
			{ST_DFT,1'b1,1'b0,1'b0}: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd2};
			{ST_DFT,1'b1,1'b1,1'b0}: temp <= {ST_DFT,1'b1,1'b0,1'b0,1'b1,4'd3};
	
			{ST_DFT,1'b1,1'bx,1'b1}: temp <= {ST_SEC,1'b1,1'b1,1'b1,1'b1,4'd4};
	
			{ST_SEC,1'b0,1'b0,1'bx}: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd5};
			{ST_SEC,1'b0,1'b1,1'bx}: temp <= {ST_DFT,1'b1,1'b0,1'b0,1'b1,4'd6};
			{ST_SEC,1'b1,1'bx,1'bx}: temp <= {ST_DFT,1'b1,1'b0,1'b1,1'b0,4'd7};

						  //default: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd8};
	    endcase
	else
	    casex({state, latched_IREQi, IREQi, IMEM_SEC})
			{ST_DFT,1'b0,1'b0,1'bx}: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd9};
			{ST_DFT,1'b0,1'b1,1'bx}: temp <= {ST_DFT,1'b1,1'b0,1'b0,1'b1,4'd10};
	
			{ST_DFT,1'b1,1'b0,1'bx}: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd11};
			{ST_DFT,1'b1,1'b1,1'bx}: temp <= {ST_DFT,1'b1,1'b0,1'b0,1'b1,4'd12};
	
			{ST_SEC,1'bx,1'b0,1'bx}: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd13};
			{ST_SEC,1'bx,1'b1,1'bx}: temp <= {ST_DFT,1'b1,1'b0,1'b0,1'b1,4'd14};
	
						  //default: temp <= {ST_DFT,1'b0,1'b0,1'bx,1'b1,4'd15};
	    endcase
end



endmodule

module DMEM_Shell #(
	parameter	REWRITE_EN = 1
)(
	input	wire				CLK,
	input	wire				RST,

	// From MEMORY
	input	wire	[38:0]		DRDATAi,
	input	wire				nDWAITi,

	// To MEMORY
	output	wire				DREQo,		
	output	wire	[31:0]		DADDRo,
	output	wire				DRWo,	// 0RD 1WT
	output	wire				DLOCKo,
	output	wire	[1:0]		DTYPEo,
	output	wire				DMODEo,
	output	wire	[1:0]		DSIZEo,
	output	wire	[38:0]		DWDATAo,

	// From CORE
	input	wire				DREQi,
	input	wire	[31:0]		DADDRi,
	input 	wire				DRWi,	// 0RD 1WT
	input	wire				DLOCKi,
	input	wire	[1:0]		DTYPEi,
	input	wire				DMODEi,
	input	wire	[1:0]		DSIZEi,
	input	wire	[31:0]		DWDATAi,

	// To CORE
	output	reg		[31:0]		DRDATAo,
	output	wire				DMEM_DEDo,
	output	wire				nDWAITo
);

////////////////////////////////////////////
// WAIT PROCESS
wire			shell_ready;
assign			nDWAITo = shell_ready & nDWAITi;

wire			gCLK;

ClockGate	cg_dmem_shell (
	.en		(nDWAITi),
	.CLK	(CLK),
	.gCLK	(gCLK)
);


////////////////////////////////////////////
// LATCHINED SIGNALS
reg		[31:0]	L_DADDRi;
reg				L_DRWi;
reg				L_DLOCKi;
reg		[1:0]	L_DTYPEi;
reg				L_DMODEi;
reg		[1:0]	L_DSIZEi;
reg		[31:0]	L_DWDATAi;

always @ (posedge gCLK)
begin
	if(RST)
		{L_DADDRi,L_DRWi,L_DLOCKi,L_DTYPEi,L_DMODEi,L_DSIZEi,L_DWDATAi} <= 
		{   32'b0,  1'b0,    1'b0,    2'b0,    1'b0,    2'b0,    32'b0};
else if(shell_ready)
		{L_DADDRi,L_DRWi,L_DLOCKi,L_DTYPEi,L_DMODEi,L_DSIZEi,L_DWDATAi} <= 
		{  DADDRi,  DRWi,  DLOCKi,  DTYPEi,  DMODEi,  DSIZEi,  DWDATAi};
end



////////////////////////////////////////////
// HAMMING ENCODER & DECODER
wire			DMEM_SEC;
wire	[31:0]	enc_in;
wire	[3:0]	enc_in_sel;
wire	[31:0]	tDRDATAo;
wire			tDMEM_DEDo;

HAMM_ENC_SYS32	enc (
	.DIN	(enc_in),
	.DOUT	(DWDATAo)
);

HAMM_DEC_SYS32 dec (
	.DIN	(DRDATAi),
	.DOUT	(tDRDATAo),
	.SEC	(DMEM_SEC),
	.DED	(tDMEM_DEDo)
);

assign	DMEM_DEDo = tDMEM_DEDo & ~L_DRWi;


////////////////////////////////////////////
// HAMMING ENCODER INPUT SELECTION
// 	enc_in_sel
//		0: DWDATAi
//		1: L_DWDATAi
//		2: tDRDATAo
//		3: subw_wdata

wire	[31:0]	subw_wdata;
wire			subw_wdata_sel;

// byte wdata
wire	[31:0]	b_wdata;
wire	[3:0]	b_wdata_sel;

wire	[31:0]	bwdata_0;
wire	[31:0]	bwdata_1;
wire	[31:0]	bwdata_2;
wire	[31:0]	bwdata_3;

assign			bwdata_0 = {tDRDATAo[31:8],  L_DWDATAi[7:0]};
assign			bwdata_1 = {tDRDATAo[31:16], L_DWDATAi[7:0], tDRDATAo[7:0]};
assign			bwdata_2 = {tDRDATAo[31:24], L_DWDATAi[7:0], tDRDATAo[15:0]};
assign			bwdata_3 = {				 L_DWDATAi[7:0], tDRDATAo[23:0]};

MUX4to1 #(32)	MUX_subw_wdata (
	    .DI0	(bwdata_0),
	    .DI1	(bwdata_1),
	    .DI2	(bwdata_2),
	    .DI3	(bwdata_3),
	    .SEL	(b_wdata_sel),
	    .DO		(b_wdata)
);

// half-word wdata
wire	[31:0]	h_wdata;
wire			h_wdata_sel;

wire	[31:0]	hwdata_0;
wire	[31:0]	hwdata_1;

assign			hwdata_0 = {tDRDATAo[31:16], L_DWDATAi[15:0]};
assign			hwdata_1 = {L_DWDATAi[15:0], tDRDATAo[15:0]};

assign			h_wdata = (h_wdata_sel)? hwdata_1 : hwdata_0;

assign			subw_wdata = (subw_wdata_sel)? h_wdata : b_wdata;

// MUX_enc_in
MUX4to1 #(32)	MUX_enc_in (
	    .DI0	(DWDATAi),
	    .DI1	(L_DWDATAi),
	    .DI2	(tDRDATAo),
	    .DI3	(subw_wdata),
	    .SEL	(enc_in_sel),
	    .DO		(enc_in)
);



////////////////////////////////////////////
// OUTPUT ASSIGN
always @*
begin
	casex({L_DADDRi[1:0],L_DSIZEi})
		{2'b00,2'b00}: DRDATAo <= {24'd0,tDRDATAo[7:0]};
		{2'b01,2'b00}: DRDATAo <= {24'd0,tDRDATAo[15:8]};
		{2'b10,2'b00}: DRDATAo <= {24'd0,tDRDATAo[23:16]};
		{2'b11,2'b00}: DRDATAo <= {24'd0,tDRDATAo[31:24]};
		{2'b00,2'b01}: DRDATAo <= {16'd0,tDRDATAo[15:0]};
		{2'b10,2'b01}: DRDATAo <= {16'd0,tDRDATAo[31:16]};
		{2'b00,2'b10}: DRDATAo <= tDRDATAo;
		default:	   DRDATAo <= tDRDATAo;
	endcase
end

wire	[3:0]	DADDRo_sel;
MUX4to1 #(32)    MUX_DADDRo(
	    .DI0	(L_DADDRi),
	    .DI1	({L_DADDRi[31:2],2'b00}),
	    .DI2	({DADDRi[31:2],2'b00}),
	    .DI3	(DADDRi),
	    .SEL	(DADDRo_sel),
	    .DO		(DADDRo)
);

wire	[3:0]	DLOCKo_sel;
MUX4to1 #(1)	MUX_DLOCKo(
	.DI0	(1'b0),
	.DI1	(1'b1),
	.DI2	(L_DLOCKi),
	.DI3	(DLOCKi),
	.SEL	(DLOCKo_sel),
	.DO		(DLOCKo)
);

wire			type_mode_sel;
assign			DTYPEo = (type_mode_sel)? DTYPEi : L_DTYPEi;
assign			DMODEo = (type_mode_sel)? DMODEi : L_DMODEi;

assign			DSIZEo = 2'b10;


////////////////////////////////////////////
// FSM
localparam	ST_DFT = 2'b00;
localparam	ST_LD1 = 2'b01;
localparam	ST_ST1 = 2'b10;
localparam	ST_2ND = 2'b11;

reg		[1:0]	state;
wire	[1:0]	next_state;

always @ (posedge gCLK)
begin
	if(RST)	state <= ST_DFT;
	else	state <= next_state;
end


reg		[29:0]	temp;
wire	[5:0]	debug;

assign	{next_state,shell_ready,DREQo,DRWo,enc_in_sel,subw_wdata_sel,b_wdata_sel,h_wdata_sel,DLOCKo_sel,DADDRo_sel,type_mode_sel,debug} = temp;
//		 2			1			1	  1	   4		  1			     4		     1			 4 		    4		   1			 6	    = 30

always @*
begin
	if(REWRITE_EN)
		casex({state, L_DRWi, L_DSIZEi, L_DADDRi[1:0], DMEM_SEC, DREQi, DRWi, DSIZEi[1]})
			{ST_DFT,1'bx,2'bxx,2'bxx,1'bx,3'b111}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b0001,1'bx,4'bxxxx,1'bx, 4'b1000,4'b1000,1'b1, 6'd0};
			{ST_DFT,1'bx,2'bxx,2'bxx,1'bx,3'b10x}: temp <= {ST_LD1, 1'b1, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b1000,4'b0100,1'b1, 6'd1};
			{ST_DFT,1'bx,2'bxx,2'bxx,1'bx,3'b110}: temp <= {ST_ST1, 1'b1, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0010,4'b0100,1'b1, 6'd2};
                                                                                    
			{ST_LD1,1'bx,2'bxx,2'bxx,1'b0,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b0,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0001,4'bxxxx,1'bx, 6'd3};
			{ST_LD1,1'bx,2'bxx,2'bxx,1'b0,3'b111}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b0001,1'bx,4'bxxxx,1'bx, 4'b1000,4'b1000,1'b1, 6'd4};
			{ST_LD1,1'bx,2'bxx,2'bxx,1'b0,3'b10x}: temp <= {ST_LD1, 1'b1, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b1000,4'b0100,1'b1, 6'd5};
			{ST_LD1,1'bx,2'bxx,2'bxx,1'b0,3'b110}: temp <= {ST_ST1, 1'b1, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0010,4'b0100,1'b1, 6'd6};
			{ST_LD1,1'bx,2'bxx,2'bxx,1'b1,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b0100,1'bx,4'bxxxx,1'bx, 4'b0100,4'b0010,1'b0, 6'd7};
			{ST_LD1,1'bx,2'bxx,2'bxx,1'b1,3'b1xx}: temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b0100,1'bx,4'bxxxx,1'bx, 4'b0100,4'b0010,1'b0, 6'd8};
                                                                                    
			{ST_ST1,1'bx,2'b00,2'b00,1'bx,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0001,1'bx, 4'b0100,4'b0010,1'b0, 6'd9};
			{ST_ST1,1'bx,2'b00,2'b01,1'bx,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0010,1'bx, 4'b0100,4'b0010,1'b0, 6'd10};
			{ST_ST1,1'bx,2'b00,2'b10,1'bx,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0100,1'bx, 4'b0100,4'b0010,1'b0, 6'd11};
			{ST_ST1,1'bx,2'b00,2'b11,1'bx,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b1000,1'bx, 4'b0100,4'b0010,1'b0, 6'd12};
			{ST_ST1,1'bx,2'b01,2'b00,1'bx,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b0, 4'b0100,4'b0010,1'b0, 6'd13};
			{ST_ST1,1'bx,2'b01,2'b10,1'bx,3'b0xx}: temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b1, 4'b0100,4'b0010,1'b0, 6'd14};
                                                                                    
			{ST_ST1,1'bx,2'b00,2'b00,1'bx,3'b1xx}: temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0001,1'bx, 4'b0100,4'b0010,1'b0, 6'd15};
            {ST_ST1,1'bx,2'b00,2'b01,1'bx,3'b1xx}: temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0010,1'bx, 4'b0100,4'b0010,1'b0, 6'd16};
            {ST_ST1,1'bx,2'b00,2'b10,1'bx,3'b1xx}: temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0100,1'bx, 4'b0100,4'b0010,1'b0, 6'd17};
            {ST_ST1,1'bx,2'b00,2'b11,1'bx,3'b1xx}: temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b1000,1'bx, 4'b0100,4'b0010,1'b0, 6'd18};
            {ST_ST1,1'bx,2'b01,2'b00,1'bx,3'b1xx}: temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b0, 4'b0100,4'b0010,1'b0, 6'd19};
            {ST_ST1,1'bx,2'b01,2'b10,1'bx,3'b1xx}: temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b1, 4'b0100,4'b0010,1'b0, 6'd20};
                                                                                    
			{ST_2ND,1'b1,2'b1x,2'bxx,1'bx,3'bxxx}: temp <= {ST_DFT, 1'b0, 1'b1,1'b1, 4'b0010,1'bx,4'bxxxx,1'bx, 4'b0100,4'b0001,1'b0, 6'd21};
			{ST_2ND,1'b0,2'bxx,2'bxx,1'bx,3'bxxx}: temp <= {ST_LD1, 1'b0, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0100,4'b0010,1'b0, 6'd22};
			{ST_2ND,1'b1,2'b0x,2'bxx,1'bx,3'bxxx}: temp <= {ST_ST1, 1'b0, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0010,4'b0010,1'b0, 6'd23};
                                                                                    
					 		 		      default: temp <= {ST_DFT, 1'b1, 1'b0,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0001,4'bxxxx,1'bx, 6'd24};
		endcase
	else
		casex({state, L_DRWi, L_DSIZEi, L_DADDRi[1:0], DREQi, DRWi, DSIZEi[1]})
            {ST_DFT,1'bx,2'bxx,2'bxx,3'b111}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b0001,1'bx,4'bxxxx,1'bx, 4'b1000,4'b1000,1'b1, 6'd25};
            {ST_DFT,1'bx,2'bxx,2'bxx,3'b10x}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b1000,4'b0100,1'b1, 6'd26};
            {ST_DFT,1'bx,2'bxx,2'bxx,3'b110}:      temp <= {ST_ST1, 1'b1, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0010,4'b0100,1'b1, 6'd27};
                                                                                    
			{ST_ST1,1'b1,2'b00,2'b00,3'b0xx}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0001,1'bx, 4'b0100,4'b0010,1'b0, 6'd28};
            {ST_ST1,1'b1,2'b00,2'b01,3'b0xx}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0010,1'bx, 4'b0100,4'b0010,1'b0, 6'd29};
            {ST_ST1,1'b1,2'b00,2'b10,3'b0xx}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0100,1'bx, 4'b0100,4'b0010,1'b0, 6'd30};
            {ST_ST1,1'b1,2'b00,2'b11,3'b0xx}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b1000,1'bx, 4'b0100,4'b0010,1'b0, 6'd31};
            {ST_ST1,1'b1,2'b01,2'b00,3'b0xx}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b0, 4'b0100,4'b0010,1'b0, 6'd32};
            {ST_ST1,1'b1,2'b01,2'b10,3'b0xx}:      temp <= {ST_DFT, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b1, 4'b0100,4'b0010,1'b0, 6'd33};
                                                                                    
			{ST_ST1,1'b1,2'b00,2'b00,3'b1xx}:      temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0001,1'bx, 4'b0100,4'b0010,1'b0, 6'd34};
	        {ST_ST1,1'b1,2'b00,2'b01,3'b1xx}:      temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0010,1'bx, 4'b0100,4'b0010,1'b0, 6'd35};
			{ST_ST1,1'b1,2'b00,2'b10,3'b1xx}:      temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b0100,1'bx, 4'b0100,4'b0010,1'b0, 6'd36};
			{ST_ST1,1'b1,2'b00,2'b11,3'b1xx}:      temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b0,4'b1000,1'bx, 4'b0100,4'b0010,1'b0, 6'd37};
			{ST_ST1,1'b1,2'b01,2'b00,3'b1xx}:      temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b0, 4'b0100,4'b0010,1'b0, 6'd38};
			{ST_ST1,1'b1,2'b01,2'b10,3'b1xx}:      temp <= {ST_2ND, 1'b1, 1'b1,1'b1, 4'b1000,1'b1,4'bxxxx,1'b1, 4'b0100,4'b0010,1'b0, 6'd39};
                                                                                    
			{ST_2ND,1'b1,2'b1x,2'bxx,3'bxxx}:      temp <= {ST_DFT, 1'b0, 1'b1,1'b1, 4'b0010,1'bx,4'bxxxx,1'bx, 4'b0100,4'b0001,1'b0, 6'd40};
			{ST_2ND,1'b0,2'bxx,2'bxx,3'bxxx}:      temp <= {ST_DFT, 1'b0, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0100,4'b0010,1'b0, 6'd41};
			{ST_2ND,1'b1,2'b0x,2'bxx,3'bxxx}:      temp <= {ST_ST1, 1'b0, 1'b1,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0010,4'b0010,1'b0, 6'd42};
                                                                                    
									 default:      temp <= {ST_DFT, 1'b1, 1'b0,1'b0, 4'bxxxx,1'bx,4'bxxxx,1'bx, 4'b0001,4'bxxxx,1'bx, 6'd43};
	endcase
end



endmodule


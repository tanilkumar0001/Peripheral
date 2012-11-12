// =======================================================
//	Bongjin Kim
//	20100216
//	
//	External Interrupt Handler
// =======================================================

module	EXT_INT_HANDLER (
	input	wire	CLK,
	input	wire	RST,

	input	wire	EXT_CLKIN,
	input	wire	EXT_INT,
	output	wire	EXT_ACK,

	output	wire	CORE_INT,
	input	wire	CORE_ACK
);


reg		[1:0]	fsm1_state;
wire	[1:0]	fsm1_next_state;
wire			int_enable;

always @ (posedge EXT_CLKIN)
begin
	if(RST)
		fsm1_state <= 2'b0;
	else
		fsm1_state <= fsm1_next_state;
end

SINGLE_CYC_HIGH	external_ack_fsm (
	.state			(fsm1_state),
	.interrupt_input(EXT_INT),
	.int_enable		(int_enable),
	.one_cycle_high	(EXT_ACK),
	.next_state		(fsm1_next_state)
);


reg		[1:0]	fsm2_state;
wire	[1:0]	fsm2_next_state;

wire	int_start;

always @ (posedge CLK)
begin
	if(RST)
		fsm2_state <= 2'b0;
	else
		fsm2_state <= fsm2_next_state;
end

SINGLE_CYC_HIGH	internal_int_req (
	.state			(fsm2_state),
	.interrupt_input(EXT_ACK),
	.int_enable		(1'b1),
	.one_cycle_high	(int_start),
	.next_state		(fsm2_next_state)
);



reg		fsm3_state;
wire	fsm3_next_state;

always @ (posedge CLK)
begin
	if(RST)
		fsm3_state <= 1'b0;
	else
		fsm3_state <= fsm3_next_state;
end


INT_REQ	internal_ack_fsm (
	.state			(fsm3_state),
	.int_start		(int_start),
	.CORE_ACK		(CORE_ACK),
	.CORE_INT		(CORE_INT),
	.int_enable		(int_enable),
	.next_state		(fsm3_next_state)
);


endmodule



module SINGLE_CYC_HIGH(
	input	wire	[1:0]	state,
	input	wire			interrupt_input,
	input	wire			int_enable,
	output	reg				one_cycle_high,
	output	reg		[1:0]	next_state
);
localparam ST_READY = 2'd0;
localparam ST_HIGH = 2'd1;
localparam ST_WAIT = 2'd2;

always @*
    casex({state, interrupt_input, int_enable})
        {ST_READY,1'b0,1'bx}:{one_cycle_high, next_state}  <=  {1'b0,ST_READY};
        {ST_READY,1'b1,1'b0}:{one_cycle_high, next_state}  <=  {1'b0,ST_READY};
        {ST_READY,1'b1,1'b1}:{one_cycle_high, next_state}  <=  {1'b0,ST_HIGH};

        {ST_HIGH, 1'bx,1'bx}:{one_cycle_high, next_state}  <=  {1'b1,ST_WAIT};

        {ST_WAIT, 1'b1,1'bx}:{one_cycle_high, next_state}  <=  {1'b0,ST_WAIT};
        {ST_WAIT, 1'b0,1'bx}:{one_cycle_high, next_state}  <=  {1'b0,ST_READY};

       				 default:{one_cycle_high, next_state}  <=  {1'b0,ST_READY};
    endcase

endmodule



module INT_REQ(
	input	wire	state,
	input	wire	int_start,
	input	wire	CORE_ACK,
	output	reg		CORE_INT,
	output	reg		int_enable,
	output	reg		next_state
);
localparam ST_READY = 1'd0;
localparam ST_INT = 1'd1;

always @*
    casex({state, int_start, CORE_ACK})
        {ST_READY,1'b0,1'bx}:{CORE_INT, int_enable, next_state}  <=  {1'b0,1'b1,ST_READY};
        {ST_READY,1'b1,1'bx}:{CORE_INT, int_enable, next_state}  <=  {1'b0,1'b0,ST_INT};

        {ST_INT,  1'bx,1'b0}:{CORE_INT, int_enable, next_state}  <=  {1'b1,1'b0,ST_INT};
        {ST_INT,  1'b0,1'b1}:{CORE_INT, int_enable, next_state}  <=  {1'b1,1'b1,ST_READY};
        {ST_INT,  1'b1,1'b1}:{CORE_INT, int_enable, next_state}  <=  {1'b1,1'b0,ST_INT};

			       //default:{CORE_INT, int_enable, next_state}  <=  {1'b0,1'b1,ST_READY};
    endcase

endmodule


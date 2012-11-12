// =======================================================
//	Jinook Song
//	20100207
//	
//	External Interface for a host	
// =======================================================
// 
//	Jinook Song
//	20110419
//		SCx_nWAIT should be dependent on only the	sender_FULL
//	{ST_HOST_IDLE, 1'b0, 1'bx, 1'b0, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_IDLE , 1'b1};
//	{ST_HOST_IDLE, 1'b0, 1'bx, 1'b1, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_IDLE , 1'b0};


module	EXT_INTF_SENDER(
			input	wire			CLK,
			input	wire			RST,

			// SLV_WRP.v Interface 
			input	wire			SCx_REQ,
			input	wire			SCx_WT,
			input	wire	[3:0]	SCx_BE,
			input	wire	[31:0]	SCx_ADDR,
			input	wire	[31:0]	SCx_WDT,

			output	reg				SCx_nWAIT,
			output	reg				SCx_FAULT,
			output	wire			SCx_TimeOut,
			output	wire	[31:0]	SCx_RDT,

			// External Interface

			output	wire			Ext_CLK_out,
			output	wire			Ext_RST,	//reset active high

			output	wire			Ext_TRANS_VALID,
			output	wire	[2:0]	Ext_TRANS_PHASE,
			output	wire	[15:0]	Ext_TRANS_DATA,
			input	wire			Ext_TRANS_ACK,

			input	wire			Ext_CLK_in,
			input	wire			Ext_RESP_VALID,
			input	wire			Ext_RESP_RESP,
			input	wire	[7:0]	Ext_RESP_DATA,
			output	wire			Ext_RESP_ACK
	    );

assign	SCx_TimeOut	= 1'b0;
// Only for generating an external clock
// Ext_CLK can be set as an output of PLL or other clock generator
//begin
reg	[3:0]	counts;
always	@(posedge CLK)	begin
	if(RST)	begin
		counts	<=	4'b0;
	end
	else	begin
		counts	<=	counts + 4'b001;
	end
end	

assign	Ext_CLK_out	= counts[1]; // 1/4 FREQ (200MHz CLK --> 50MHz Ext_CLK_out)
assign	Ext_RST		= RST;
//end


// 32 bit <-> external interface

localparam	ST_HOST_IDLE	= 4'b0000;
localparam	ST_HOST_CNTR	= 4'b0001;
localparam	ST_HOST_ADDR0	= 4'b0010;
localparam	ST_HOST_ADDR1	= 4'b0011;
localparam	ST_HOST_WDAT0	= 4'b0100;
localparam	ST_HOST_WDAT1	= 4'b0101;
localparam	ST_HOST_RDAT0	= 4'b0110;
localparam	ST_HOST_RDAT1	= 4'b0111;
localparam	ST_HOST_RDAT2	= 4'b1000;
localparam	ST_HOST_RDAT3	= 4'b1001;

reg	[3:0]	host_state;
reg	[3:0]	next_host_state;

always	@(posedge CLK)	begin
	if(RST)	begin
		host_state	<=	ST_HOST_IDLE;
	end
	else	begin
		host_state	<=	next_host_state;
	end
end	

wire	sender_FULL	;
wire	sender_resp_EMPTY;
reg		L_SCx_WT;
always	@(posedge	CLK)	begin
	if(SCx_REQ&SCx_nWAIT)
		L_SCx_WT	<=	SCx_WT;
end

always	@*	begin
casex({host_state, SCx_REQ, L_SCx_WT, sender_FULL, sender_resp_EMPTY})
{ST_HOST_IDLE, 1'b0, 1'bx, 1'b0, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_IDLE , 1'b1};
{ST_HOST_IDLE, 1'b0, 1'bx, 1'b1, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_IDLE , 1'b0};
{ST_HOST_IDLE, 1'b1, 1'bx, 1'b0, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_CNTR , 1'b1};
{ST_HOST_IDLE, 1'b1, 1'bx, 1'b1, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_IDLE , 1'b0};

{ST_HOST_CNTR, 1'bx, 1'bx, 1'b1, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_CNTR , 1'b0};
{ST_HOST_CNTR, 1'bx, 1'bx, 1'b0, 1'bx}:	{next_host_state, SCx_nWAIT}	<= {ST_HOST_ADDR0, 1'b0};

{ST_HOST_ADDR0, 1'bx, 1'bx, 1'b1, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_ADDR0, 1'b0};
{ST_HOST_ADDR0, 1'bx, 1'bx, 1'b0, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_ADDR1, 1'b0};

{ST_HOST_ADDR1, 1'bx, 1'bx, 1'b1, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_ADDR1, 1'b0};
{ST_HOST_ADDR1, 1'bx, 1'b1, 1'b0, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_WDAT0, 1'b0};
{ST_HOST_ADDR1, 1'bx, 1'b0, 1'b0, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT0, 1'b0};

{ST_HOST_WDAT0, 1'bx, 1'bx, 1'b1, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_WDAT0, 1'b0};
{ST_HOST_WDAT0, 1'bx, 1'bx, 1'b0, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_WDAT1, 1'b0};

{ST_HOST_WDAT1, 1'bx, 1'bx, 1'b1, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_WDAT1, 1'b0};
{ST_HOST_WDAT1, 1'bx, 1'bx, 1'b0, 1'bx}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_IDLE , 1'b0};


{ST_HOST_RDAT0, 1'bx, 1'bx, 1'bx, 1'b1}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT0, 1'b0};
{ST_HOST_RDAT0, 1'bx, 1'bx, 1'bx, 1'b0}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT1, 1'b0};

{ST_HOST_RDAT1, 1'bx, 1'bx, 1'bx, 1'b1}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT1, 1'b0};
{ST_HOST_RDAT1, 1'bx, 1'bx, 1'bx, 1'b0}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT2, 1'b0};

{ST_HOST_RDAT2, 1'bx, 1'bx, 1'bx, 1'b1}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT2, 1'b0};
{ST_HOST_RDAT2, 1'bx, 1'bx, 1'bx, 1'b0}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT3, 1'b0};

{ST_HOST_RDAT3, 1'bx, 1'bx, 1'bx, 1'b1}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_RDAT3, 1'b0};
{ST_HOST_RDAT3, 1'bx, 1'bx, 1'bx, 1'b0}:{next_host_state, SCx_nWAIT}	<= {ST_HOST_IDLE , 1'b0};

								default:{next_host_state, SCx_nWAIT}	<= {host_state   , 1'b1};
endcase
end	

//reg	[18:0]	host_DIN;
reg	[15:0]	host_DIN;
reg		host_wen;

localparam	PH_CNTR	= 3'b100;
localparam	PH_ADDR	= 3'b010;
localparam	PH_WDAT	= 3'b001;
reg	[31:0]	L_SCx_ADDR;
always	@(posedge	CLK)	begin
	if(SCx_REQ&SCx_nWAIT) L_SCx_ADDR	<=	SCx_ADDR;
end
reg	[31:0]	L_SCx_WDT;
always	@(posedge	CLK)	begin
	if(SCx_REQ&SCx_nWAIT) L_SCx_WDT		<=	SCx_WDT;
end
reg	[3:0]	L_SCx_BE;
always	@(posedge	CLK)	begin
	if(SCx_REQ&SCx_nWAIT)	L_SCx_BE	<=	SCx_BE;
end


always	@*	begin
casex(host_state)
ST_HOST_IDLE	:{host_DIN, host_wen}<={16'bx, 1'b0};
ST_HOST_CNTR	:{host_DIN, host_wen}<={{{11'b0,L_SCx_WT,L_SCx_BE}}, 1'b1};
ST_HOST_ADDR0	:{host_DIN, host_wen}<={{L_SCx_ADDR[15:0]} , 1'b1};
ST_HOST_ADDR1	:{host_DIN, host_wen}<={{L_SCx_ADDR[31:16]}, 1'b1};

ST_HOST_WDAT0	:{host_DIN, host_wen}<={{L_SCx_WDT[15:0]} , 1'b1};
ST_HOST_WDAT1	:{host_DIN, host_wen}<={{L_SCx_WDT[31:16]}, 1'b1};

ST_HOST_RDAT0	:{host_DIN, host_wen}<={16'bx, 1'b0};
ST_HOST_RDAT1	:{host_DIN, host_wen}<={16'bx, 1'b0};
ST_HOST_RDAT2	:{host_DIN, host_wen}<={16'bx, 1'b0};
ST_HOST_RDAT3	:{host_DIN, host_wen}<={16'bx, 1'b0};
	default	:{host_DIN, host_wen}<={16'bx, 1'b0};
endcase

end	

reg	[7:0]	SCx_RDT0;
reg	[7:0]	SCx_RDT1;
reg	[7:0]	SCx_RDT2;
reg	[7:0]	SCx_RDT3;
wire	[8:0]	resp_fifo_out;
assign	SCx_RDT	= {SCx_RDT3, SCx_RDT2, SCx_RDT1, SCx_RDT0};

always	@(posedge CLK)	begin
	if(RST)	begin
		SCx_RDT3	<=	8'b0;
		SCx_RDT2	<=	8'b0;
		SCx_RDT1	<=	8'b0;
		SCx_RDT0	<=	8'b0;
		SCx_FAULT	<=	1'b0;
	end
	else	if(host_state==ST_HOST_RDAT0)
		{SCx_FAULT, SCx_RDT0}	<=	{1'b0, resp_fifo_out[7:0]};
	else	if(host_state==ST_HOST_RDAT1)
		{SCx_FAULT, SCx_RDT1}	<=	{1'b0, resp_fifo_out[7:0]};
	else	if(host_state==ST_HOST_RDAT2)
		{SCx_FAULT, SCx_RDT2}	<=	{1'b0, resp_fifo_out[7:0]};
	else	if(host_state==ST_HOST_RDAT3)
		{SCx_FAULT, SCx_RDT3}	<=	resp_fifo_out;
	else	SCx_FAULT		<=	1'b0;
end	

reg		host_ren;	

always	@*	begin
casex(host_state)
ST_HOST_IDLE	:host_ren	<= 1'b0;
ST_HOST_CNTR	:host_ren	<= 1'b0;
ST_HOST_ADDR0	:host_ren	<= 1'b0;
ST_HOST_ADDR1	:host_ren	<= 1'b0;

ST_HOST_WDAT0	:host_ren	<= 1'b0;
ST_HOST_WDAT1	:host_ren	<= 1'b0;

ST_HOST_RDAT0	:host_ren	<= 1'b1;
ST_HOST_RDAT1	:host_ren	<= 1'b1;
ST_HOST_RDAT2	:host_ren	<= 1'b1;
ST_HOST_RDAT3	:host_ren	<= 1'b1;
	default	:host_ren	<= 1'b0;
endcase

end	




// Synchronous dual-clock FIFO
// Transmission FIFO

wire			sender_clk_push		= CLK	;
wire			sender_clk_pop		= Ext_CLK_out;
wire			sender_rst_n		= ~RST;
wire			sender_push_req_n	= ~host_wen;
wire			sender_pop_req_n	= ~Ext_TRANS_ACK;
wire	[15:0]		sender_data_in		= host_DIN;
wire	    		sender_push_empty	;
wire			sender_push_ae		;
wire			sender_push_hf		;
wire			sender_push_af		;
wire			sender_push_full	;
wire			sender_push_error	; 
wire			sender_pop_empty	;
wire			sender_pop_ae		;
wire			sender_pop_hf		;
wire			sender_pop_af		;
wire			sender_pop_full		;
wire			sender_pop_error	;
wire	[15:0]		sender_data_out		;	

assign	sender_FULL	= sender_push_full;
assign	{Ext_TRANS_PHASE, Ext_TRANS_DATA}	= sender_data_out;
assign	Ext_TRANS_VALID	= ~sender_pop_empty;



DW_fifo_s2_sf	#(.width(16), .depth(4), .rst_mode(0), .push_sync(1), .pop_sync(1)) sender_fifo0(
	.clk_push	(sender_clk_push	),
	.clk_pop	(sender_clk_pop		),
	.rst_n		(sender_rst_n		),
	.push_req_n	(sender_push_req_n	),
	.pop_req_n	(sender_pop_req_n	),
	.data_in	(sender_data_in		), 
	.push_empty	(sender_push_empty	),
	.push_ae	(sender_push_ae		),
	.push_hf	(sender_push_hf		),
	.push_af	(sender_push_af		),
	.push_full	(sender_push_full	),
	.push_error	(sender_push_error	),
	.pop_empty	(sender_pop_empty	),
	.pop_ae		(sender_pop_ae		),
	.pop_hf		(sender_pop_hf		),
	.pop_af		(sender_pop_af		),
	.pop_full	(sender_pop_full	),
	.pop_error	(sender_pop_error	),
	.data_out	(sender_data_out	));
 

// Response FIFO


wire			resp_clk_push		= Ext_CLK_in;
wire			resp_clk_pop		= CLK;
wire			resp_rst_n			= ~Ext_RST;
wire			resp_push_req_n		= ~Ext_RESP_VALID;
wire			resp_pop_req_n		= ~host_ren;
wire	[8:0]	resp_data_in		= {Ext_RESP_RESP, Ext_RESP_DATA};
wire	    	resp_push_empty		;
wire			resp_push_ae		;
wire			resp_push_hf		;
wire			resp_push_af		;
wire			resp_push_full		;
wire			resp_push_error		; 
wire			resp_pop_empty		;
wire			resp_pop_ae		;
wire			resp_pop_hf		;
wire			resp_pop_af		;
wire			resp_pop_full		;
wire			resp_pop_error		;
wire	[8:0]		resp_data_out		;	

assign	sender_resp_EMPTY	= resp_pop_empty;
assign	resp_fifo_out		= resp_data_out;
assign	Ext_RESP_ACK		= ~resp_push_full;


DW_fifo_s2_sf	#(.width(9), .depth(4), .rst_mode(0), .push_sync(1), .pop_sync(1)) resp_fifo0(
	.clk_push	(resp_clk_push		),
	.clk_pop	(resp_clk_pop		),
	.rst_n		(resp_rst_n		),
	.push_req_n	(resp_push_req_n	),
	.pop_req_n	(resp_pop_req_n		),
	.data_in	(resp_data_in		), 
	.push_empty	(resp_push_empty	),
	.push_ae	(resp_push_ae		),
	.push_hf	(resp_push_hf		),
	.push_af	(resp_push_af		),
	.push_full	(resp_push_full		),
	.push_error	(resp_push_error	),
	.pop_empty	(resp_pop_empty		),
	.pop_ae		(resp_pop_ae		),
	.pop_hf		(resp_pop_hf		),
	.pop_af		(resp_pop_af		),
	.pop_full	(resp_pop_full		),
	.pop_error	(resp_pop_error		),
	.data_out	(resp_data_out		));
 
//synopsys translate_off
reg	[127:0]	debug_fsm_sender;
always	@*	begin
casex(host_state)
ST_HOST_IDLE	: debug_fsm_sender	<= "ST_HOST_IDLE";
ST_HOST_CNTR	: debug_fsm_sender	<= "ST_HOST_CNTR";
ST_HOST_ADDR0	: debug_fsm_sender	<= "ST_HOST_ADDR0";
ST_HOST_ADDR1	: debug_fsm_sender	<= "ST_HOST_ADDR1";

ST_HOST_WDAT0	: debug_fsm_sender	<= "ST_HOST_WDAT0";
ST_HOST_WDAT1	: debug_fsm_sender	<= "ST_HOST_WDAT1";

ST_HOST_RDAT0	: debug_fsm_sender	<= "ST_HOST_RDAT0";
ST_HOST_RDAT1	: debug_fsm_sender	<= "ST_HOST_RDAT1";
ST_HOST_RDAT2	: debug_fsm_sender	<= "ST_HOST_RDAT2";
ST_HOST_RDAT3	: debug_fsm_sender	<= "ST_HOST_RDAT3";
endcase


end	

//synopsys translate_on


endmodule


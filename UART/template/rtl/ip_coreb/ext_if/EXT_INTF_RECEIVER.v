// =======================================================
//	Jinook Song
//	20100207
//	
//	External Interface for a slave
// =======================================================

module	EXT_INTF_RECEIVER(
			input	wire			CLK,
			input	wire			RST,

			// SLV_WRP.v Interface 
			output	reg			SCx_REQ,
			output	wire			SCx_WT,
			output	wire	[3:0]		SCx_BE,
			output	reg	[31:0]		SCx_ADDR,
			output	reg	[31:0]		SCx_WDT,

			input	wire			SCx_nWAIT,
			input	wire			SCx_FAULT,
			input	wire			SCx_TimeOut,
			input	wire	[31:0]		SCx_RDT,

			// External Interface

			input	wire			Ext_CLK0,
			input	wire			Ext_RST,	//reset active high

			input	wire			Ext_TRANS_VALID,
			input	wire	[2:0]		Ext_TRANS_PHASE,
			input	wire	[15:0]		Ext_TRANS_DATA,
			output	wire			Ext_TRANS_ACK,

			output	wire			Ext_CLK1,
			output	wire			Ext_RESP_VALID,
			output	wire			Ext_RESP_RESP,
			output	wire	[7:0]		Ext_RESP_DATA,
			input	wire			Ext_RESP_ACK
	    );

// Only for generating an external clock
// Ext_CLK can be set as an output of PLL or other clock generator
//begin
reg	[1:0]	counts;
always	@(posedge CLK)	begin
	if(RST)	begin
		counts	<=	2'b0;
	end
	else	begin
		counts	<=	counts + 2'b01;
	end
end	

assign	Ext_CLK1	= counts[1];
//end



// 32 bit <-> external interface

localparam	ST_SLV_IDLE	= 4'b0000;
localparam	ST_SLV_CNTR	= 4'b0001;
localparam	ST_SLV_ADDR0	= 4'b0010;
localparam	ST_SLV_ADDR1	= 4'b0011;
localparam	ST_SLV_WDAT0	= 4'b0100;
localparam	ST_SLV_WDAT1	= 4'b0101;
localparam	ST_SLV_RDAT0	= 4'b0110;
localparam	ST_SLV_RDAT1	= 4'b0111;
localparam	ST_SLV_RDAT2	= 4'b1000;
localparam	ST_SLV_RDAT3	= 4'b1001;
localparam	ST_SLV_REQ	= 4'b1010;

reg	[3:0]	slv_state;
reg	[3:0]	next_slv_state;

always	@(posedge CLK)	begin
	if(RST)	begin
		slv_state	<=	ST_SLV_IDLE;
	end
	else	begin
		slv_state	<=	next_slv_state;
	end
end	

wire		sender_EMPTY;
wire		resp_FULL;
reg		rSCx_WT;
reg	[3:0]	rSCx_BE;

reg	[18:0]	sender_DOUT;
wire	[18:0]	sender_DOUTi;
reg		sender_ren;
reg		resp_wen;
reg	[8:0]	resp_DIN;

always	@*	begin
casex({slv_state, sender_EMPTY, rSCx_WT, resp_FULL, SCx_nWAIT})
{ST_SLV_IDLE, 1'b1, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_IDLE , 1'b0, 1'b0};
{ST_SLV_IDLE, 1'b0, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_CNTR , 1'b0, 1'b0};

{ST_SLV_CNTR, 1'b1, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_CNTR , 1'b0, 1'b0};
{ST_SLV_CNTR, 1'b0, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_ADDR0, 1'b0, 1'b0};

{ST_SLV_ADDR0,1'b1, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_ADDR0, 1'b0, 1'b0};
{ST_SLV_ADDR0,1'b0, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_ADDR1, 1'b0, 1'b0};

{ST_SLV_ADDR1,1'b1, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_ADDR1, 1'b0, 1'b0};
{ST_SLV_ADDR1,1'b0, 1'b1, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_WDAT0, 1'b0, 1'b0};
{ST_SLV_ADDR1,1'b0, 1'b0, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_REQ  , 1'b0, 1'b0};


{ST_SLV_WDAT0,1'b1, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_WDAT0, 1'b0, 1'b0};
{ST_SLV_WDAT0,1'b0, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_WDAT1, 1'b0, 1'b0};

{ST_SLV_WDAT1,1'b1, 1'bx, 1'bx, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_WDAT1, 1'b0, 1'b0};
{ST_SLV_WDAT1,1'b0, 1'bx, 1'bx, 1'b0}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_WDAT1, 1'b0, 1'b0};
{ST_SLV_WDAT1,1'b0, 1'bx, 1'bx, 1'b1}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_REQ  , 1'b0, 1'b0};

{ST_SLV_REQ , 1'bx, 1'bx, 1'bx, 1'b0}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_REQ  , 1'b1, 1'b0};
{ST_SLV_REQ , 1'bx, 1'b0, 1'bx, 1'b1}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT0, 1'b1, 1'b0};
{ST_SLV_REQ , 1'bx, 1'b1, 1'bx, 1'b1}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_IDLE , 1'b1, 1'b0};

{ST_SLV_RDAT0,1'bx, 1'bx, 1'b0, 1'b0}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT0, 1'b0, 1'b0};
{ST_SLV_RDAT0,1'bx, 1'bx, 1'b1, 1'b0}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT0, 1'b0, 1'b0};
{ST_SLV_RDAT0,1'bx, 1'bx, 1'b1, 1'b1}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT0, 1'b0, 1'b0};
{ST_SLV_RDAT0,1'bx, 1'bx, 1'b0, 1'b1}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT1, 1'b0, 1'b1};

{ST_SLV_RDAT1,1'bx, 1'bx, 1'b1, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT1, 1'b0, 1'b0};
{ST_SLV_RDAT1,1'bx, 1'bx, 1'b0, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT2, 1'b0, 1'b1};

{ST_SLV_RDAT2,1'bx, 1'bx, 1'b1, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT2, 1'b0, 1'b0};
{ST_SLV_RDAT2,1'bx, 1'bx, 1'b0, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT3, 1'b0, 1'b1};

{ST_SLV_RDAT3,1'bx, 1'bx, 1'b1, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_RDAT3, 1'b0, 1'b0};
{ST_SLV_RDAT3,1'bx, 1'bx, 1'b0, 1'bx}:{next_slv_state, SCx_REQ, resp_wen}<={ST_SLV_IDLE , 1'b0, 1'b1};

endcase
end

always	@(posedge CLK)	begin
	if(RST)	begin
		rSCx_WT	<=	1'b0;
		rSCx_BE	<=	4'b0;
	end
	else	if(slv_state==ST_SLV_CNTR)begin
		rSCx_WT	<=	sender_DOUT[4];
		rSCx_BE	<=	sender_DOUT[3:0];
	end
end	
assign	SCx_WT	= rSCx_WT;
assign	SCx_BE	= rSCx_BE;

always	@(posedge CLK)	begin
	if(RST)	begin
		SCx_ADDR	<=	32'b0;
	end
	else	if(slv_state==ST_SLV_ADDR0)begin
		SCx_ADDR[15:0]	<=	sender_DOUT[15:0];
	end
	else	if(slv_state==ST_SLV_ADDR1)begin
		SCx_ADDR[31:16]	<=	sender_DOUT[15:0];
	end
end	

always	@(posedge CLK)	begin
	if(RST)	begin
		SCx_WDT		<=	32'b0;
	end
	else	if(slv_state==ST_SLV_WDAT0)begin
		SCx_WDT[15:0]	<=	sender_DOUT[15:0];
	end
	else	if(slv_state==ST_SLV_WDAT1)begin
		SCx_WDT[31:16]	<=	sender_DOUT[15:0];
	end
end	




always	@*	begin
casex(slv_state)
ST_SLV_IDLE	:{sender_DOUT, sender_ren}	<= {19'bx, 1'b0};
ST_SLV_CNTR	:{sender_DOUT, sender_ren}	<= {sender_DOUTi, 1'b1};
ST_SLV_ADDR0	:{sender_DOUT, sender_ren}	<= {sender_DOUTi, 1'b1};
ST_SLV_ADDR1	:{sender_DOUT, sender_ren}	<= {sender_DOUTi, 1'b1};

ST_SLV_WDAT0	:{sender_DOUT, sender_ren}	<= {sender_DOUTi, 1'b1};
ST_SLV_WDAT1	:{sender_DOUT, sender_ren}	<= {sender_DOUTi, SCx_nWAIT};

ST_SLV_RDAT0	:{sender_DOUT, sender_ren}	<= {19'bx, 1'b0};
ST_SLV_RDAT1	:{sender_DOUT, sender_ren}	<= {19'bx, 1'b0};
ST_SLV_RDAT2	:{sender_DOUT, sender_ren}	<= {19'bx, 1'b0};
ST_SLV_RDAT3	:{sender_DOUT, sender_ren}	<= {19'bx, 1'b0};

endcase

end	

always	@*	begin
casex(slv_state)
ST_SLV_IDLE	:{resp_DIN}	<= {9'bx};
ST_SLV_CNTR	:{resp_DIN}	<= {9'bx};
ST_SLV_ADDR0	:{resp_DIN}	<= {9'bx};
ST_SLV_ADDR1	:{resp_DIN}	<= {9'bx};

ST_SLV_WDAT0	:{resp_DIN}	<= {9'bx};
ST_SLV_WDAT1	:{resp_DIN}	<= {9'bx};

ST_SLV_RDAT0	:{resp_DIN}	<= {SCx_FAULT, SCx_RDT[7:0]};
ST_SLV_RDAT1	:{resp_DIN}	<= {SCx_FAULT, SCx_RDT[15:8]};
ST_SLV_RDAT2	:{resp_DIN}	<= {SCx_FAULT, SCx_RDT[23:16]};
ST_SLV_RDAT3	:{resp_DIN}	<= {SCx_FAULT, SCx_RDT[31:24]};
endcase
end	




// Asymmetric Synchronous FIFO
// Transmission FIFO

wire			sender_clk_push		= Ext_CLK0;
wire			sender_clk_pop		= CLK;
wire			sender_rst_n		= ~Ext_RST;
wire			sender_push_req_n	= ~Ext_TRANS_VALID;
wire			sender_pop_req_n	= ~sender_ren;
wire	[18:0]		sender_data_in		= {Ext_TRANS_PHASE, Ext_TRANS_DATA};
//wire	[15:0]		sender_data_in		= Ext_TRANS_DATA;
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
wire	[18:0]		sender_data_out		;	

assign	Ext_TRANS_ACK	= ~sender_push_full;
assign	sender_EMPTY	= sender_pop_empty;
assign	sender_DOUTi	= sender_data_out;


DW_fifo_s2_sf	#(.width(19), .depth(4), .rst_mode(0), .push_sync(1), .pop_sync(2)) sender_fifo1(
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

wire			resp_clk_push		= CLK;
wire			resp_clk_pop		= Ext_CLK1;
wire			resp_rst_n		= ~RST;
wire			resp_push_req_n		= ~resp_wen;
wire			resp_pop_req_n		= ~Ext_RESP_ACK;
wire	[8:0]		resp_data_in		= resp_DIN;
wire	    		resp_push_empty		;
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

assign	Ext_RESP_VALID	= ~resp_pop_empty;
assign	{Ext_RESP_RESP, Ext_RESP_DATA}	= resp_data_out;
assign	resp_FULL	= resp_push_full;


DW_fifo_s2_sf	#(.width(9), .depth(4), .rst_mode(0), .push_sync(1), .pop_sync(2)) resp_fifo1(
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
reg	[127:0]	debug_fsm_receiver;
always	@*	begin
casex(slv_state)
ST_SLV_IDLE	: debug_fsm_receiver	<= "ST_SLV_IDLE";
ST_SLV_CNTR	: debug_fsm_receiver	<= "ST_SLV_CNTR";
ST_SLV_ADDR0	: debug_fsm_receiver	<= "ST_SLV_ADDR0";
ST_SLV_ADDR1	: debug_fsm_receiver	<= "ST_SLV_ADDR1";

ST_SLV_WDAT0	: debug_fsm_receiver	<= "ST_SLV_WDAT0";
ST_SLV_WDAT1	: debug_fsm_receiver	<= "ST_SLV_WDAT1";

ST_SLV_RDAT0	: debug_fsm_receiver	<= "ST_SLV_RDAT0";
ST_SLV_RDAT1	: debug_fsm_receiver	<= "ST_SLV_RDAT1";
ST_SLV_RDAT2	: debug_fsm_receiver	<= "ST_SLV_RDAT2";
ST_SLV_RDAT3	: debug_fsm_receiver	<= "ST_SLV_RDAT3";
ST_SLV_REQ	: debug_fsm_receiver	<= "ST_SLV_REQ";
endcase


end	

//synopsys translate_on




endmodule


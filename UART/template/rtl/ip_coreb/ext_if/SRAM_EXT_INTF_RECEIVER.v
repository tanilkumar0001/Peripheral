// =======================================================
//	Jinook Song
//	20100208
//	
//	External Interface for an External SRAM 
// =======================================================

module	SRAM_EXT_INTF_RECEIVER
#(parameter AWIDTH = 11, SIZE = 2048, ATIME = 2, RAND = 0, PER = 4, FAULT = 0, TIMEOUT = 16) (
			input	wire			CLK,
			input	wire			nRST,

			// External Interface

			input	wire			Ext_CLK0,
			input	wire			Ext_RST,	//reset active high

			input	wire			Ext_TRANS_VALID,
			//input	wire	[2:0]		Ext_TRANS_PHASE,
			input	wire	[15:0]		Ext_TRANS_DATA,
			output	wire			Ext_TRANS_ACK,

			output	wire			Ext_CLK1,
			output	wire			Ext_RESP_VALID,
			output	wire			Ext_RESP_RESP,
			output	wire	[7:0]		Ext_RESP_DATA,
			input	wire			Ext_RESP_ACK
	    );
wire			SCx_REQ;
wire			SCx_WT;
wire	[3:0]		SCx_BE;
wire	[31:0]		SCx_ADDR;
wire	[31:0]		SCx_WDT;
wire			SCx_nWAIT;
wire			SCx_FAULT;
wire			SCx_TimeOut;
wire	[31:0]		SCx_RDT;


wire	[31:0]	BIT_E;
assign	BIT_E = { {8{SCx_BE[3]}}, {8{SCx_BE[2]}}, {8{SCx_BE[1]}}, {8{SCx_BE[0]}} };

assign	SCx_nWAIT = 1'b1;
assign	SCx_FAULT = 1'b0;
assign	SCx_TimeOut = 1'b0;

SPSRAM #(
	.DEPTH(SIZE), 
	.A_WIDTH(AWIDTH) 
) SPSRAM_sim (
	.CK                 (CLK),
	.CSN                (~SCx_REQ),
	.WEN                (~SCx_WT),
	.OEN                (1'b0),
	.A		    (SCx_ADDR[AWIDTH+1:2]),
	.BWEN               (~BIT_E),
	.DI                 (SCx_WDT),
	.DOUT               (SCx_RDT)
);



EXT_INTF_RECEIVER	ext_receiv0(
		.CLK				(CLK			),
		.RST				(~nRST			),
		.SCx_REQ			(SCx_REQ		),
		.SCx_WT				(SCx_WT			),
		.SCx_BE				(SCx_BE			),
		.SCx_ADDR			(SCx_ADDR		),
		.SCx_WDT			(SCx_WDT		),
		.SCx_nWAIT			(SCx_nWAIT		),
		.SCx_FAULT			(SCx_FAULT		),
		.SCx_TimeOut		(SCx_TimeOut	),
		.SCx_RDT			(SCx_RDT		),
		.Ext_CLK0			(Ext_CLK0		),
		.Ext_RST			(Ext_RST		),	//reset active high
		.Ext_TRANS_VALID	(Ext_TRANS_VALID),
		//.Ext_TRANS_PHASE	(Ext_TRANS_PHASE),
		.Ext_TRANS_PHASE	(3'b0),
		.Ext_TRANS_DATA		(Ext_TRANS_DATA	),
		.Ext_TRANS_ACK		(Ext_TRANS_ACK	),
		.Ext_CLK1			(Ext_CLK1		),
		.Ext_RESP_VALID		(Ext_RESP_VALID	),
		.Ext_RESP_RESP		(Ext_RESP_RESP	),
		.Ext_RESP_DATA		(Ext_RESP_DATA	),
		.Ext_RESP_ACK		(Ext_RESP_ACK	)
	    );

endmodule

// =======================================================
//	Jinook Song
//	20100208
//	
//	Core-B SLAVE of External Interface for a host	
// =======================================================


module SLV_EXT_INTF_SENDER(
	// Common Control Signals
	input	wire			CLK, 
	input	wire			nRST, 

	// Signals From Core-B
	input	wire			DxSEL, 

	input	wire			MmWT, 
	input	wire	[2:0]	MmSZ, 
	input	wire	[3:0]	MmRB, 
	input	wire	[2:0]	MmMOD, 
	input	wire	[31:0]	MmADDR, 
	input	wire	[38:0]	MmWDT, 

	input	wire			MsRDY, 

	// Signals To Core-B 
	output	wire	[38:0]	SxRDT, 
	output	wire			SxRDY, 
	output	wire			SxERR, 

	// External Interface for a sender
	output	wire			Ext_CLK_out,
	output	wire			Ext_RST,	//reset active high

	output	wire			Ext_TRANS_VALID,
	output	wire	[15:0]	Ext_TRANS_DATA,
	input	wire			Ext_TRANS_ACK,

	input	wire			Ext_CLK_in,
	input	wire			Ext_RESP_VALID,
	input	wire			Ext_RESP_RESP,
	input	wire	[7:0]	Ext_RESP_DATA,
	output	wire			Ext_RESP_ACK
		
);

wire			SCx_nWAIT; 
wire			SCx_FAULT; 
wire			SCx_TimeOut;
wire	[38:0]	SCx_RDT_enc; 
wire	[31:0]	SCx_RDT_dec; 
wire			SCx_REQ; 
wire			SCx_WT; 
wire	[3:0]	SCx_BE;
wire	[31:0]	SCx_ADDR; 
wire	[38:0]	SCx_WDT_enc;
wire	[31:0]	SCx_WDT_dec;

SLV_WRP slv0(
	.CLK		(CLK), 
	.nRST		(nRST), 
	.DxSEL		(DxSEL	), 
	.MmWT		(MmWT	), 
	.MmSZ		(MmSZ	), 
	.MmRB		(MmRB	), 
	.MmMOD		(MmMOD	), 
	.MmADDR		(MmADDR	), 
	.MmWDT		(MmWDT	), 
	.MsRDY		(MsRDY	), 
	.SxRDT		(SxRDT	), 
	.SxRDY		(SxRDY	), 
	.SxERR		(SxERR	), 
	.SCx_nWAIT	(SCx_nWAIT	), 
	.SCx_FAULT	(SCx_FAULT	), 
	.SCx_TimeOut(SCx_TimeOut),
	.SCx_RDT	(SCx_RDT_enc), 
	.SCx_REQ	(SCx_REQ	), 
	.SCx_WT		(SCx_WT		), 
	.SCx_BE		(SCx_BE		),
	.SCx_ADDR	(SCx_ADDR	), 
	.SCx_WDT	(SCx_WDT_enc)
);

HAMM_ENC_SYS32 rdt_enc (
	.DIN	(SCx_RDT_dec),
	.DOUT	(SCx_RDT_enc)
);

HAMM_DEC_SYS32 wdt_dec (
	.DIN	(SCx_WDT_enc),
	.DOUT	(SCx_WDT_dec),
	.SEC	(),
	.DED	()
);

EXT_INTF_SENDER	extsender0(
	.CLK			(CLK),
	.RST			(~nRST),
	.SCx_REQ		(SCx_REQ	),
	.SCx_WT			(SCx_WT		),
	.SCx_BE			(SCx_BE		),
	.SCx_ADDR		(SCx_ADDR	),

	//.SCx_WDT		(SCx_WDT_dec),
	.SCx_WDT		(SCx_WDT_enc[31:0]),

	.SCx_nWAIT		(SCx_nWAIT	),
	.SCx_FAULT		(SCx_FAULT	),
	.SCx_TimeOut	(SCx_TimeOut),
	.SCx_RDT		(SCx_RDT_dec),
	.Ext_CLK_out	(Ext_CLK_out),
	.Ext_RST		(Ext_RST	),
	.Ext_TRANS_VALID(Ext_TRANS_VALID),
	.Ext_TRANS_PHASE(),
	.Ext_TRANS_DATA	(Ext_TRANS_DATA	),
	.Ext_TRANS_ACK	(Ext_TRANS_ACK	),
	.Ext_CLK_in		(Ext_CLK_in		),
	.Ext_RESP_VALID	(Ext_RESP_VALID	),
	.Ext_RESP_RESP	(Ext_RESP_RESP	),
	.Ext_RESP_DATA	(Ext_RESP_DATA	),
	.Ext_RESP_ACK	(Ext_RESP_ACK	)
);


endmodule

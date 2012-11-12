//===================================================
//	
//	Boot Loader for Core-A System
//		with Core-B Wrapper
//					
//					Ver 2010_1
//
//					Bongjin Kim
//
//===================================================

module	MST_BOOTLD	#(
	parameter
	MEM0_SIZE = 0,
	MEM1_SIZE = 0,
	MEM0_START = 0,
	MEM1_START = 0,
	MEMB_START = 0
)(
	// Common Control Signals
	input   wire					CLK,
	input   wire					nRST,
	
	// Signals From Core-B Lite On-Chip High-Speed Bus
	input   wire					AxGNT,
	
	input   wire    [38:0]          MsRDT,
	input   wire                    MsRDY,
	input   wire                    MsERR,
	
	// Signals To Core-B Lite On-Chip High-Speed Bus
	output  wire                    MxREQ,
	output  wire                    MxLK,
	output  wire                    MxWT,        // 1:Write   0:Read
	output  wire    [2:0]           MxSZ,
	output  wire    [3:0]           MxRB,
	output  wire    [2:0]           MxMOD,
	output  wire    [31:0]          MxADDR,
	output  wire    [38:0]          MxWDT,

	// Output to system
	output	wire					nRST_CORE,
	output	wire					BOOT_END
);



wire				MC_nREQ;
wire				MC_WEN;
wire	[29:0]		MC_ADDR;
wire	[31:0]		MC_WDT_dec,	MC_RDT_dec;
wire	[38:0]		MC_WDT_enc, MC_RDT_enc;
wire				MC_nWAIT;



MST_WRP		M1_WRP (
	.CLK                (CLK),
	.nRST               (nRST),
	
	// signals from bootloader
	.MCx_REQ            (~MC_nREQ),		//MCx_REQ==1 : Request
	.MCx_LK             (1'b0),
	.MCx_WT             (~MC_WEN),
	.MCx_SZ             (3'b010),
	.MCx_RB             (4'b0),
	.MCx_MOD            ({1'b0, ~MC_nREQ, 1'b0}),
	.MCx_ADDR           ({MC_ADDR, 2'b0}),
	.MCx_WDT            (MC_WDT_enc),
	
	// signals to bootloader
	.MCx_nWAIT          (MC_nWAIT),
	.MCx_ERR            (),
	.MCx_RDT            (MC_RDT_enc),
	
	// signals from bus
	.AxGNT              (AxGNT),
	.MsRDY              (MsRDY),
	.MsERR              (MsERR),
	.MsRDT              (MsRDT),
	
	// signals to bus
	.MxREQ              (MxREQ),
	.MxLK               (MxLK),
	.MxWT               (MxWT),
	.MxSZ               (MxSZ),
	.MxRB               (MxRB),
	.MxMOD              (MxMOD),
	.MxADDR             (MxADDR),
	.MxWDT              (MxWDT)
);

HAMM_ENC_SYS32 wdt_enc (
	.DIN	(MC_WDT_dec),
	.DOUT	(MC_WDT_enc)
);

HAMM_DEC_SYS32 rdt_dec (
	.DIN	(MC_RDT_enc),
	.DOUT	(MC_RDT_dec),
	.SEC	(),
	.DED	()
);


Boot_Loader	#(
	.MEM0_SIZE (MEM0_SIZE ),
	.MEM1_SIZE (MEM1_SIZE ),
	.MEM0_START(MEM0_START),
	.MEM1_START(MEM1_START),
	.MEMB_START(MEMB_START)
)	bootloader_mst	(


	.CLK		(CLK),
	.nRST		(nRST),

	/*Core Reset*/
	.nRST_CORE	(nRST_CORE),
	
	/*boot end => 1, initially 0*/
	.BOOT_END	(BOOT_END),
	
	/*Memory I/O (Core)*/
	.A			(MC_ADDR),
	.DIN		(MC_RDT_dec),
	.nREQ		(MC_nREQ),
	.WEN		(MC_WEN),

	.DOUT		(MC_WDT_dec),
	.nWAIT		(MC_nWAIT)
);

endmodule

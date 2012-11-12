/****************************************************************************
*                                                                           *
*                           	Bridge                                      *
*                                                                           *
*****************************************************************************
*                                                                           *
*  Description :  BRG_CBL_WRP + BRG_APB_WRP                                 * 
*  Modify signal timing to interconnect Core-B Lite with APB timing    	    *
*                                                                           *
*****************************************************************************
*                                                                           *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST     *
*                                                                           *
*  All rights reserved.                                                     *
*                                                                           *
*  Do Not duplicate without prior written consent of ICSL, KAIST.           *
*                                                                           *
*                                                                           *
*                                                  Designed By Ji-Hoon Kim  *
*                                                             Duk-Hyun You  *
*                                                                           *
*                                              Supervised By In-Cheol Park  *
*                                                                           *
*                                            E-mail : icpark@ee.kaist.ac.kr *
*                                                                           *
****************************************************************************/

module BRG
(
	// Common Control Signals
	input	wire					CLK, 
	input	wire					nRST, 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	input	wire					DxSEL, 
	input	wire					MmWT, 
	input	wire		[1:0]		MmMOD, 


	input	wire		[2:0]		MmSZ, 

	input	wire		[3:0]		MmRB, 
	input	wire		[31:0]		MmADDR, 
	input	wire		[38:0]		MmWDT, 

	input	wire					MsRDY, 

	// Signals To Core-B Lite On-Chip High-Speed Bus
	output	wire					SxRDY, 
	output	wire					SxERR, 
	output	wire		[38:0]		SxRDT, 

	// APB Common Signals
	input	wire					PCLK,
	input	wire					PRESETn,

	// To APB
	output	wire					PENABLE,
	output	wire					PWRITE,	
	output	wire		[31:0]		PADDR,	
	output	wire		[31:0]		PWDATA,
	output	wire					PSELEN,

	// From APB	
	input	wire		[31:0]		PRDATA
);


wire	[31:0]	MmWDT_dec;

HAMM_DEC_SYS32 wdt_dec_in_brg(
	.DIN 	(MmWDT),
	.DOUT	(MmWDT_dec),
	.SEC 	(),
	.DED 	()
);


wire	[31:0]	SxRDT_original;

HAMM_ENC_SYS32 rdt_enc_in_brg(
	.DIN 	(SxRDT_original),
	.DOUT	(SxRDT)
);


wire			SCx_REQ;
wire	[31:0]	SCx_ADDR;
wire			SCx_WT;
wire	[31:0]	SCx_WDT;

wire			PACK;
wire			SCx_nWAIT;
wire	[31:0]	SCx_RDT;
	

BRG_CBL_WRP I_BRG_CBL_WRP 
(
	// Common Control Signals
	.CLK			(CLK), 
	.nRST			(nRST), 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	.DxSEL			(DxSEL), 
	.MmWT			(MmWT), 
	.MmMOD			(MmMOD), 


	.MmSZ			(MmSZ), 

	.MmRB			(MmRB), 
	.MmADDR			(MmADDR), 
	.MmWDT			(MmWDT_dec), 

	.MsRDY			(MsRDY), 

	// Signals To Core-B Lite On-Chip High-Speed Bus
	.SxRDT			(SxRDT_original), 
	.SxRDY			(SxRDY), 
	.SxERR			(SxERR), 

	// Signals To APB
	.SCx_REQ		(SCx_REQ), 
	.SCx_ADDR		(SCx_ADDR), 
	.SCx_WT			(SCx_WT), 
	.SCx_WDT		(SCx_WDT),

	// Signals From Slave
	.PACK			(PACK),
	.SCx_nWAIT		(SCx_nWAIT), 
	.SCx_RDT		(SCx_RDT) 
);

BRG_APB_WRP I_BRG_APB_WRP
(
	// From Core-B Lite Slave Wrapper
	.SCx_REQ		(SCx_REQ), 
	.SCx_WT			(SCx_WT), 
	.SCx_ADDR		(SCx_ADDR), 
	.SCx_WDT		(SCx_WDT),

	// APB Common Signals
	.PCLK			(PCLK),
	.PRESETn		(PRESETn),

	// To APB
	.PENABLE		(PENABLE),
	.PWRITE			(PWRITE),	
	.PADDR			(PADDR),	
	.PWDATA			(PWDATA),
	.PSELEN			(PSELEN),
	// From APB	
	.PRDATA			(PRDATA),
	
	// To APBWrapper(SlaveWrapper)
	.PACK			(PACK),
	.SCx_nWAIT		(SCx_nWAIT),
	.SCx_RDT		(SCx_RDT)
);




endmodule

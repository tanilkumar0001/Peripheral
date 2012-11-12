/****************************************************************************
*                                                                           *
* 	                      APB  System 	                            *
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

module APB
(
	// From APB Masters
	input	wire				PMENABLE,	
	input	wire				PMWRITE,
	input	wire	[31:0]		PMADDR,
	input	wire	[31:0]		PMWDATA,	
	input	wire				PMSELEN,	

	// To APB Slave 0
	output	wire				PSEL0,
	// To APB Slave 1
	output	wire				PSEL1,
	// To APB Slave 2
	output	wire				PSEL2,

	// To All APB Slaves
	output	wire				PENABLE,	
	output	wire				PWRITE,
	output	wire	[31:0]		PADDR,
	output	wire	[31:0]		PWDATA,	

	// From APB Slave 0
	input	wire	[31:0]		PRDATA0,
	// From APB Slave 1
	input	wire	[31:0]		PRDATA1,
	// From APB Slave 2
	input	wire	[31:0]		PRDATA2,

	// To APB Master
	output	wire	[31:0]		PRDATA
);
	wire	[2:0]		iPSEL;
	wire	[2:0]		PSEL;

	assign PENABLE = PMENABLE;
	assign PWRITE  = PMWRITE;
	assign PADDR   = PMADDR;
	assign PWDATA = PMWDATA;

	assign PSEL0 = iPSEL[0] & PMSELEN;
	assign PSEL1 = iPSEL[1] & PMSELEN;
	assign PSEL2 = iPSEL[2] & PMSELEN;
	assign PSEL = {PSEL2, PSEL1, PSEL0}; 

APB_DCD	I_APB_DCD
(
	.PADDR		(PMADDR),
	.PSEL		(iPSEL)
);

APB_RMUX I_APB_RMUX
(
	.PRDATA0	(PRDATA0),
	.PRDATA1	(PRDATA1),
	.PRDATA2	(PRDATA2),
	.PSEL		(PSEL),
	.PRDATA		(PRDATA)
);	

endmodule

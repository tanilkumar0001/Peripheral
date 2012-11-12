/****************************************************************************
*                                                                           *
*                       Slave SRAM (16kB)                                   *
*                                                                           *
*****************************************************************************
*                                                                           *
*  Description :  SRAM(Slave Core) with Parity + Slave Wrapper              *
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
*                                                  Designed By Bongjin Kim  *
*                                                             YoungJoo Lee  *
*                                                                           *
*                                              Supervised By In-Cheol Park  *
*                                                                           *
*                                            E-mail : icpark@ee.kaist.ac.kr *
*                                                                           *
****************************************************************************/

module SLV_SRAM (

	// Common Control Signals
	input	wire					CLK, 
	input	wire					nRST, 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	input   wire                    DxSEL,
	input   wire                    MmWT,
	input   wire        [2:0]       MmSZ,
	input   wire        [3:0]       MmRB,
	input   wire        [2:0]       MmMOD,
	input   wire        [31:0]      MmADDR, 
	input   wire        [38:0]      MmWDT,  
	input   wire                    MsRDY,
	
	// Signals To Core-B Lite On-Chip High-Speed Bus
	output  wire        [38:0]      SxRDT,   
	output  wire                    SxRDY,
	output  wire                    SxERR

);

wire                    SCx_REQ, SCx_WT;
wire        [31:0]      SCx_ADDR;
wire		[38:0]		SCx_WDT, SCx_RDT_SRAM;
wire        [3:0]       SCx_BE;  


SLV_WRP   SLV_WRP (
                            .CLK                (CLK),
                            .nRST               (nRST),

                            // Input from Core-B Lite On-Chip High-Speed Bus
                            .DxSEL              (DxSEL),

                            .MmWT               (MmWT),
                            .MmSZ               (MmSZ),
                            .MmRB               (MmRB),
                            .MmMOD              (MmMOD),
                            .MmADDR             (MmADDR),
                            .MmWDT              (MmWDT),

                            .MsRDY              (MsRDY),

                            // Output to Core-B Lite On-Chip High-Speed Bus
                            .SxRDY              (SxRDY),
                            .SxERR              (SxERR),
                            .SxRDT              (SxRDT),

                            // Slave Core Interface
                            .SCx_nWAIT          (1'b1),
                            .SCx_FAULT          (1'b0),
                            .SCx_TimeOut        (1'b0),
                            .SCx_RDT            (SCx_RDT_SRAM),

                            .SCx_REQ            (SCx_REQ),
                            .SCx_WT             (SCx_WT),
                            .SCx_BE             (SCx_BE),
                            .SCx_ADDR           (SCx_ADDR),
                            .SCx_WDT            (SCx_WDT)
                        );

wire	[38:0]	BIT_WE;
assign	BIT_WE = {39{SCx_WT}}; // MmSZ is always 3'b010 (word)


`ifdef _STD150E_
spsrambw_hd_4096x39m8 main_mem (
	.CK         (CLK),
	.CSN        (~SCx_REQ),
	.WEN        (~SCx_WT),
	.OEN        (1'b0),
	.A          (SCx_ADDR[12+1:2]),
	.BWEN       (~BIT_WE),
	.DI         (SCx_WDT),
	.DOUT       (SCx_RDT_SRAM)
);
`else
SPSRAM #(
	.D_WIDTH(39),
	.DEPTH(4096), 
	.A_WIDTH(12), 
	.INIT_FILE("ASM.hex"),
	.INITIALIZE(0)
) main_mem (
	.CK         (CLK),
	.CSN        (~SCx_REQ),
	.WEN        (~SCx_WT),
	.OEN        (1'b0),
	.A		    (SCx_ADDR[12+1:2]),
	.BWEN       (~BIT_WE),
	.DI         (SCx_WDT),
	.DOUT       (SCx_RDT_SRAM)
);
`endif



endmodule

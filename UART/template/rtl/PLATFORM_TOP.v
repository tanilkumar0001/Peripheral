/******************************************************************************
*                                                                             *
*                              Platform Template                              *
*                                                                             *
*                                  Top Module                                 *
*                                                                             *
*******************************************************************************
*                                                                             *
*  Copyright (c) 2012 by Integrated Computer Systems Lab. (ICSL), KAIST       *
*                                                                             *
*  All rights reserved.                                                       *
*                                                                             *
*  Do Not duplicate without prior written consent of ICSL, KAIST.             *
*                                                                             *
*                                                                             *
*                                                  Designed By   Injae Yoo    *
*                                                              Bongjin Kim    *
*                                                                             *
*                                              Supervised By In-Cheol Park    *
*                                                                             *
*                                                E-mail : icpark@kaist.edu    *
*                                                                             *
*******************************************************************************/
//`default_nettype none


module PLATFORM_TOP (

	// CLK, nRST 2pin
	input	wire			CLK,
	input	wire			nRST,

	// PCLK, PRESETn 2pin (for peripherals)
	input	wire			PCLK,
	input	wire			PRESETn,

	// Your testing IP interface ?pin
	input	wire			CAN_rx,
	output	wire			CAN_tx,
	input	wire			UART_rx,
	output	wire			UART_tx,

	// External Interrupt 2pin
	input	wire			Ext_INT,
	output	wire			Ext_ACK,

	// External Interface 32pin
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


//--------------------------------------------------
// Boot Loader Wires
//--------------------------------------------------
wire		nRST_CORE;
wire		BOOT_END;




//--------------------------------------------------
// Debounce Reset
//--------------------------------------------------
reg		debounce1_nRST;
reg		debounce2_nRST;

always @ (posedge CLK)
begin
	debounce1_nRST	<= nRST;
	debounce2_nRST	<= debounce1_nRST;
end




//---------------------------------------------------
// Interrupt signal 
//---------------------------------------------------
wire	INT;
wire	INT_ACK;

wire	EXT_INT;
wire	EXT_INT_ACK;

//wire	eth_int;
//wire	i2c_int_0;
//wire	i2c_int_1;
//wire	spi_int_0;
//wire	spi_int_1;



//---------------------------------------------------
// Signals for Core-B Bus Masters
//---------------------------------------------------
// Default Master
wire			M0REQ; 
wire			M0LK;
wire			M0WT; 
wire	[2:0]	M0SZ; 
wire	[3:0]	M0RB; 
wire	[2:0]	M0MOD; 
wire	[31:0]	M0ADDR; 
wire	[38:0]	M0WDT; 

// FTCORE IMEM
wire			M1REQ; 
wire			M1LK;
wire			M1WT; 
wire	[2:0]	M1SZ; 
wire	[3:0]	M1RB; 
wire	[2:0]	M1MOD; 
wire	[31:0]	M1ADDR; 
wire	[38:0]	M1WDT; 

wire			A1GNT;

// FTCORE DMEM
wire			M2REQ; 
wire			M2LK;
wire			M2WT; 
wire	[2:0]	M2SZ; 
wire	[3:0]	M2RB; 
wire	[2:0]	M2MOD; 
wire	[31:0]	M2ADDR; 
wire	[38:0]	M2WDT; 

wire			A2GNT;

// Boot Loader
wire			M3REQ; 
wire			M3LK;
wire			M3WT; 
wire	[2:0]	M3SZ; 
wire	[3:0]	M3RB; 
wire	[2:0]	M3MOD; 
wire	[31:0]	M3ADDR; 
wire	[38:0]	M3WDT; 

wire			A3GNT;

// Common
wire	[38:0]	MsRDT;
wire			MsERR;
wire			MsRDY;




//----------------------------------------------------
// Signals for Core-B Lite BUS
//----------------------------------------------------
// Default Slave
wire			S0RDY;
wire			S0ERR;
wire	[38:0]	S0RDT;

wire			D0SEL;

// On Chip SRAM
wire			S1RDY;
wire			S1ERR;
wire	[38:0]	S1RDT;

wire			D1SEL;

// Core-B to APB Bridge
wire			S2RDY;
wire			S2ERR;
wire	[38:0]	S2RDT;

wire			D2SEL;

// Timer
wire			S3RDY;
wire			S3ERR;
wire	[38:0]	S3RDT;

wire			D3SEL;

// External Interface
wire			S4RDY;
wire			S4ERR;
wire	[38:0]	S4RDT;

wire			D4SEL;

// Common
wire			MmWT;
wire	[2:0]	MmSZ;
wire	[3:0]	MmRB;
wire	[2:0]	MmMOD;
wire	[31:0]	MmADDR;
wire	[38:0]	MmWDT;




//----------------------------------------------------
// Signals for APB 
//----------------------------------------------------
wire			PMENABLE;	
wire			PMWRITE;
wire	[31:0]	PMADDR;
wire	[31:0]	PMWDATA;	
wire			PMSELEN;	
	
wire	[31:0]	PRDATA;


wire			PSEL1;

wire			PENABLE;	
wire			PWRITE;
wire	[31:0]	PADDR;
wire	[31:0]	PWDATA;	

wire	[31:0]	PRDATA0;	
wire	[31:0]	PRDATA1;	




//----------------------------------------------------
// Core-B System BUS
//----------------------------------------------------
CoreB		CBL_BUS	(
	.CLK					(CLK),
	.nRST					(debounce2_nRST),
	
	// Signals From Master0
	.M0REQ					(M0REQ),
	.M0LK					(M0LK),
	.M0WT					(M0WT),
	.M0SZ					(M0SZ),
	.M0RB					(M0RB),
	.M0MOD					(M0MOD),
	.M0ADDR					(M0ADDR),
	.M0WDT					(M0WDT),
	
	.A0GNT					(),

	// Signals From Master1
	.M1REQ					(M1REQ),
	.M1LK					(M1LK),
	.M1WT					(M1WT),
	.M1SZ					(M1SZ),
	.M1RB					(M1RB),
	.M1MOD					(M1MOD),
	.M1ADDR					(M1ADDR),
	.M1WDT					(M1WDT),

	// Signal To Master1
	.A1GNT					(A1GNT),

	// Signals From Master2
	.M2REQ					(M2REQ),
	.M2LK					(M2LK),
	.M2WT					(M2WT),
	.M2SZ					(M2SZ),
	.M2RB					(M2RB),
	.M2MOD					(M2MOD),
	.M2ADDR					(M2ADDR),
	.M2WDT					(M2WDT),

	// Signal To Master2
	.A2GNT					(A2GNT),

	// Signals From Master3
	.M3REQ					(M3REQ),
	.M3LK					(M3LK),
	.M3WT					(M3WT),
	.M3SZ					(M3SZ),
	.M3RB					(M3RB),
	.M3MOD					(M3MOD),
	.M3ADDR					(M3ADDR),
	.M3WDT					(M3WDT),

	// Signal To Master3
	.A3GNT					(A3GNT),

	// Common Signals To All Masters
	.MsRDT					(MsRDT),
	.MsERR					(MsERR),

	// Signals From Slave0
	.S0RDY					(S0RDY),
	.S0ERR					(S0ERR),
	.S0RDT					(S0RDT),

	// Signals From Slave1
	.S1RDY					(S1RDY),
	.S1ERR					(S1ERR),
	.S1RDT					(S1RDT),

	// Signals From Slave2
	.S2RDY					(S2RDY),
	.S2ERR					(S2ERR),
	.S2RDT					(S2RDT),

	// Signals From Slave3
	.S3RDY					(S3RDY),
	.S3ERR					(S3ERR),
	.S3RDT					(S3RDT),

	// Signals From Slave4
	.S4RDY					(S4RDY),
	.S4ERR					(S4ERR),
	.S4RDT					(S4RDT),

	// Signal To Slave0
	.D0SEL					(D0SEL),

	// Signal To Slave1
	.D1SEL					(D1SEL),

	// Signal To Slave2
	.D2SEL					(D2SEL),

	// Signal To Slave3
	.D3SEL					(D3SEL),

	// Signal To Slave4
	.D4SEL					(D4SEL),

	// Common Signals To All Slaves
	.MmWT					(MmWT),
	.MmSZ					(MmSZ),
	.MmRB					(MmRB),
	.MmMOD					(MmMOD),
	.MmADDR					(MmADDR),
	.MmWDT					(MmWDT),
		
	// Common Signal To All Masters and All Slaves
	.MsRDY					(MsRDY)
);



//----------------------------------------------------
// MST0 : Default Master
//----------------------------------------------------
DFT_MST		CBL_MST_0	(	
	.CLK		(CLK),
	.nRST		(nRST_CORE),

	// Signals From Master0
	.MxREQ		(M0REQ),
	.MxLK		(M0LK),
	.MxWT		(M0WT),
	.MxSZ		(M0SZ),
	.MxRB		(M0RB),
	.MxMOD		(M0MOD),
	.MxADDR		(M0ADDR),
	.MxWDT		(M0WDT)
);



//---------------------------------------------------
// Core-A Processor
//	MST1 : IMEM ACCESS
//	MST2 : DMEM ACCESS
//---------------------------------------------------
MST_FTCoreA	CBL_MST_1_2 (
	.CLK		(CLK),
	.nRST		(nRST_CORE),

	.INT		(INT),
	.INT_ACK	(INT_ACK),

	// Signals From Master1
	.M1REQ		(M1REQ),
	.M1LK		(M1LK),
	.M1WT		(M1WT),
	.M1SZ		(M1SZ),
	.M1RB		(M1RB),
	.M1MOD		(M1MOD),
	.M1ADDR		(M1ADDR),
	.M1WDT		(M1WDT),

	// Signal To Master1
	.A1GNT		(A1GNT),

	// Signals From Master2
	.M2REQ		(M2REQ),
	.M2LK		(M2LK),
	.M2WT		(M2WT),
	.M2SZ		(M2SZ),
	.M2RB		(M2RB),
	.M2MOD		(M2MOD),
	.M2ADDR		(M2ADDR),
	.M2WDT		(M2WDT),

	// Signal To Master2
	.A2GNT		(A2GNT),

	// Common Signals To All Masters
	.MsRDT		(MsRDT),
	.MsERR		(MsERR),
	.MsRDY		(MsRDY)
);



//----------------------------------------------------
// MST3 : Boot Loader
//----------------------------------------------------
MST_BOOTLD	#(
	.MEMB_START     (30'h0008_4000), // Addr: 0x0021_0000
	.MEM0_START     (0),
	.MEM1_START     (0),
	.MEM0_SIZE      (4096), // 4K words: 16KB
	.MEM1_SIZE      (0)	
)	
	boot_loader	(

	// Common Control Signals
	.CLK		(CLK ),
	.nRST		(debounce2_nRST),
	
	// Signals From Core-B Lite On-Chip High-Speed Bus
	.AxGNT		(A3GNT),
	                      
	.MsRDT		(MsRDT),
	.MsRDY		(MsRDY),
	.MsERR		(MsERR),
	
	// Signals To Core-B Lite On-Chip High-Speed Bus
	.MxREQ		(M3REQ	),
	.MxLK		(M3LK	),
	.MxWT		(M3WT	),        // 1:Write   0:Read
	.MxSZ		(M3SZ	),
	.MxRB		(M3RB	),
	.MxMOD		(M3MOD	),
	.MxADDR		(M3ADDR	),
	.MxWDT		(M3WDT	),

	// Output to system
	.nRST_CORE	(nRST_CORE),
	.BOOT_END	(BOOT_END )
);



//----------------------------------------------------
// SLV0 : DEFAULT SLAVE
//----------------------------------------------------
DFT_SLV		CBL_SLV_0	(
	.CLK		(CLK),
	.nRST		(nRST_CORE),

	.DxSEL		(D0SEL),
	.MmWT		(MmWT),
	.MmSZ		(MmSZ),
	.MmRB		(MmRB),
	.MmMOD		(MmMOD),
	.MmADDR		(MmADDR),
	.MmWDT		(MmWDT),
	.MsRDY		(MsRDY),

	.SxRDT		(S0RDT),
	.SxRDY		(S0RDY),
	.SxERR		(S0ERR)
);



//----------------------------------------------------
// SLV1 - ON CHIP SRAM, 16KB
//----------------------------------------------------
SLV_SRAM	on_chip_sram (
	// Common Control Signals
	.CLK		(CLK), 
	.nRST		(debounce2_nRST), 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	.DxSEL		(D1SEL),
	.MmWT		(MmWT),
	.MmSZ		(MmSZ), // always 3'b010
	.MmRB		(MmRB),
	.MmMOD		(MmMOD),
	.MmADDR		(MmADDR), 
	.MmWDT		(MmWDT),  
	.MsRDY		(MsRDY),
	
	// Signals To Core-B Lite On-Chip High-Speed Bus
	.SxRDT		(S1RDT),   
	.SxRDY		(S1RDY),
	.SxERR		(S1ERR)
);



//----------------------------------------------------
// SLV2 - CORE-B TO APB BRIDGE 
//----------------------------------------------------
BRG coreb_apb_bridge (
	// Common Control Signals
	.CLK 		(CLK), 
	.nRST		(nRST_CORE), 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	.DxSEL		(D2SEL),  
	.MmWT 		(MmWT),   
	.MmSZ		(MmSZ),   
	.MmRB  		(MmRB),   
	.MmMOD 		(MmMOD[1:0]),  
	.MmADDR		(MmADDR), 
	.MmWDT 		(MmWDT),  
	.MsRDY 		(MsRDY),  

	// Signals To Core-B Lite On-Chip High-Speed Bus
	.SxRDY		(S2RDY), 
	.SxERR		(S2ERR), 
	.SxRDT		(S2RDT), 

	// APB Common Signals
	.PCLK   	(PCLK),
	.PRESETn	(PRESETn),

	// To APB
	.PENABLE	(PMENABLE),
	.PWRITE 	(PMWRITE ),	
	.PADDR  	(PMADDR  ),	
	.PWDATA 	(PMWDATA ),
	.PSELEN 	(PMSELEN ),

	// From APB	
	.PRDATA		(PRDATA	 )
);



//----------------------------------------------------
// SLV3 - TIMER WITH INTERRUPT CONTROLLER 
//----------------------------------------------------
SLV_TIMER	Timer (
	// Common Control Signals
	.CLK		(CLK), 
	.nRST		(nRST_CORE), 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	.DxSEL		(D3SEL),
	.MmWT		(MmWT),
	.MmSZ		(MmSZ),
	.MmRB		(MmRB),
	.MmMOD		(MmMOD),
	.MmADDR		(MmADDR), 
	.MmWDT		(MmWDT),  
	.MsRDY		(MsRDY),
	
	// Signals To Core-B Lite On-Chip High-Speed Bus
	.SxRDT		(S3RDT),   
	.SxRDY		(S3RDY),
	.SxERR		(S3ERR),
	                 
	.INT		(INT),
	.INT_ACK	(INT_ACK),

	.ETH_INT	(1'b0/*eth_int  */),
	.I2C_INT_0	(1'b0/*i2c_int_0*/),
	.I2C_INT_1	(1'b0/*i2c_int_1*/),
	.SPI_INT_0	(1'b0/*spi_int_0*/),
	.SPI_INT_1	(1'b0/*spi_int_1*/),

	.EXT_INT	(EXT_INT),
	.EXT_INT_ACK(EXT_INT_ACK)
);

EXT_INT_HANDLER	ext_int_handler (
	.CLK		(CLK),
	.RST		(~nRST_CORE),

	.EXT_CLKIN	(Ext_CLK_in),
	.EXT_INT	(Ext_INT),
	.EXT_ACK	(Ext_ACK),

	.CORE_INT	(EXT_INT),
	.CORE_ACK	(EXT_INT_ACK)
);



//----------------------------------------------------
// SLV4 - EXTERNAL INTERFACE 
//----------------------------------------------------
SLV_EXT_INTF_SENDER	Ext_Intf (
	// Common Control Signals
	.CLK				(CLK), 
	.nRST				(debounce2_nRST), 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	.DxSEL				(D4SEL), 
                	                
	.MmWT				(MmWT), 
	.MmSZ				(MmSZ), 
	.MmRB				(MmRB), 
	.MmMOD				(MmMOD), 
	.MmADDR				(MmADDR), 
	.MmWDT				(MmWDT), 
                                
	.MsRDY				(MsRDY), 

	// Signals To Core-B Lite On-Chip High-Speed Bus
	.SxRDT				(S4RDT), 
	.SxRDY				(S4RDY), 
	.SxERR				(S4ERR), 

	// External Interface for a sender
	.Ext_CLK_out		(Ext_CLK_out),	// clk from chip to external
	.Ext_RST			(Ext_RST),	//reset active high

	.Ext_TRANS_VALID	(Ext_TRANS_VALID),
	.Ext_TRANS_DATA		(Ext_TRANS_DATA),
	.Ext_TRANS_ACK		(Ext_TRANS_ACK),

	.Ext_CLK_in			(Ext_CLK_in),	// clk from exteranl to chip
	.Ext_RESP_VALID		(Ext_RESP_VALID),
	.Ext_RESP_RESP		(Ext_RESP_RESP),
	.Ext_RESP_DATA		(Ext_RESP_DATA),
	.Ext_RESP_ACK       (Ext_RESP_ACK)
);



//----------------------------------------------------
// Advanced Peripheral BUS (APB)
//----------------------------------------------------
APB	APB_inst (
	// From APB Masters
	.PMENABLE			(PMENABLE),	
	.PMWRITE 			(PMWRITE ),
	.PMADDR  			(PMADDR  ),
	.PMWDATA 			(PMWDATA ),	
	.PMSELEN 			(PMSELEN ),	

	// To APB Slave 0
	.PSEL0				(PSEL0),
	// To APB Slave 1
	.PSEL1				(PSEL1),
	// To APB Slave 2
	.PSEL2				(/*N.C.*/),

	// To All APB Slaves
	.PENABLE			(PENABLE),	
	.PWRITE 			(PWRITE ),
	.PADDR  			(PADDR  ),
	.PWDATA 			(PWDATA ),	

	// From APB Slave 0
	.PRDATA0			(PRDATA0),
	// From APB Slave 1
	.PRDATA1			(PRDATA1),
	// From APB Slave 2
	.PRDATA2			(/*N.C.*/),

	// To APB Master
	.PRDATA				(PRDATA	)
);



//----------------------------------------------------
// APB SLV0 - Default Slave
//----------------------------------------------------
// Default slave
APB_DFT_SLV APB_DFT_SLV_inst (
	.PRDATA				(PRDATA0)
);


//----------------------------------------------------
// APB SLV1 - Your Testing IP
//----------------------------------------------------
//SLV_APB_CAN SLV_APB_CAN_inst (
//    
//	// Common Control Signals
//	.CLK 				(PCLK),
//	.nRST				(PRESETn),
//
//	// CAN Interface Signals
//	.CAN_rx				(CAN_rx),
//	.CAN_tx				(CAN_tx),
//
//	// Core Interrupt Signal
//    .INT    			(/*N.C.*/),
//
//    // Signals From Advanced Peripheral Bus (APB)
//	.PSEL0  			(PSEL1  ),
//	.PENABLE			(PENABLE),	
//	.PWRITE 			(PWRITE ),
//	.PADDR  			(PADDR  ),
//	.PWDATA 			(PWDATA ),	
//
//    // Signals To Advanced Peripheral Bus (APB)
//	.PRDATA0			(PRDATA1)
//);

Uart SLV_APB_UART_inst (
	// Common Control Signals
	.PCLK 				(PCLK),
	.UART_CLK 			(PCLK),
	.RESETn				(PRESETn),

    // Signals From Advanced Peripheral Bus (APB)
	.PSEL	 			(PSEL1  ),
	.PENABLE			(PENABLE),	
	.PWRITE 			(PWRITE ),
	.PADDR  			(PADDR  ),
	.PWDATA 			(PWDATA ),	

    // Signals To Advanced Peripheral Bus (APB)
	.PRDATA				(PRDATA1),
  
	//	UART Tx/Rx Signals
	.TXD				(UART_tx),
	.RXD				(UART_rx),

	//	UART IRQ Signals
	.IRQn				()
);



endmodule

/****************************************************************************
*                                                                           *
*                               Bridge APB                                  *
*                                                                           *
*****************************************************************************
*                                                                           *
*  Description :                                                            *
*  Modify signal timing to interconnect Core-B Lite with SRAM timing        *
*  BRG_CBL_WRP plays a role of Core-B Lite Slave                            *
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

module BRG_CBL_WRP 
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
	input	wire		[31:0]		MmWDT, 

	input	wire					MsRDY, 

	// Signals To Core-B Lite On-Chip High-Speed Bus
`ifndef	_DBE_
	output	reg		[31:0]		SxRDT, 
`else
	output	wire		[31:0]		SxRDT, 
`endif
	output	wire					SxRDY, 
	output	wire					SxERR, 

	// Signals To APB
	output	reg						SCx_REQ, 
	output	wire		[31:0]		SCx_ADDR, 
	output	wire					SCx_WT, 
`ifndef	_DBE_
	output	reg		[31:0]		SCx_WDT,
`else
	output	wire		[31:0]		SCx_WDT,
`endif

	// Signals From Slave
	input	wire					PACK,
	input	wire					SCx_nWAIT, 
	input	wire		[31:0]		SCx_RDT 
);
//////////////////////////
//	State Parameters	//
//////////////////////////
localparam		ST_RDY 		= 3'b000;
localparam		ST_ADDR 	= 3'b001;	//ADDR SAMPLED
localparam		ST_DATA		= 3'b010;	//DATA SAMPLED
localparam		ST_REQD 	= 3'b011;	//Requeseted to SLV
localparam		ST_ERROR	= 3'b111;	//ERROR

//////////////////////////////
//	MmMOD Signal Encoding	//
//////////////////////////////
localparam		IDLE		=	2'b00;
localparam		BUSY		=	2'b01;
localparam		LDADDR		=	2'b10;
localparam		SEQADDR		=	2'b11;
localparam 		ACTIVE 		= 	2'b1x;
localparam 		INACTIVE 	= 	2'b0x;

//////////////////////////////
//	MmWT Signal Encoding	//
//////////////////////////////
localparam		WT			=	1'b1;	//WRITE
localparam		RD			= 	1'b0;	//READ
//////////////////////////////
//	MmSZ Signal Encoding	//
//////////////////////////////
localparam		BT = 3'b000;
localparam		HWD= 3'b001;
localparam		WD = 3'b010;



	reg		[2:0]		CurState;	
	reg		[2:0]		NextState;

	wire				ADDR_SMP;		//Detect the time when "MmADDR" should be sampled
	wire				DATA_SMP;		//Detect the time when "MmWDT" should be sampled

	wire				SLV_RDY;		// Slave Ready Status for the requested transfer 
										// READY : 1
										// WAIT  : 0

	wire				SLV_ERR;		// Slave Error Status for the requested transfer
										// OKAY  : 0
										// ERROR : 1

	// For Address Control Signals
	reg		[7:0]		INC;		// the amount of the increment
	wire 	[31:0]		INC_SCx_ADDR;	// Incremented slave address
	wire	[31:0]		iSCx_ADDR;		// Internal slave address
	reg		[31:0]		L_iSCx_ADDR;	// Latched internal slave address

	//Latched Signals
	reg					L_DxSEL;
	reg					L_MmWT;
	reg		[1:0]		L_MmMOD;
	reg		[2:0]		L_MmSZ;
	reg		[3:0]		L_MmRB;
	reg		[31:0]		L_MmADDR;
	reg		[31:0]		L_MmWDT;

	wire				L_MmLST;	// Last Transfer
									
	reg					L_SLV_ERR;	// Latched slave error status  
	reg		[31:0]		L_SCx_RDT;	// Latched slave data out


	wire				sDFAULT;
	wire				sTimeOut;
	
	assign	sDFAULT 	= 1'b0;
	assign	sTimeOut 	= 1'b0;

	//////////////////////////////
	//	New Transaction Detect	//
	//////////////////////////////

	//If Current State is RDY, MmADDR should be sampled 
	assign 	ADDR_SMP = (CurState == ST_RDY);

	//If Current State is ADDR, MmWDT should be sampled
 	assign 	DATA_SMP = (CurState == ST_ADDR) | (CurState == ST_DATA && NextState == ST_DATA);


	/////////////////////////////////////
	// Redefine Signals From the Slave //
	/////////////////////////////////////

	// Slave Error 
	// 		Error Case 
	//			1.Data Fault
	//			2.Time Out 
	// 	Assume that APB Slave Error never occur!!
	assign	SLV_ERR = 1'b0;

	// The CLK is different between
	//		Core-B Lite
	//		APB	
	// There Could be a skew between them
	// This Situation can be similar to the ASYNC Systems.
	// In order to fix this, Double Latching is used! 

	// Slave Ready 
	//	Ready Case
	// 		1. Wait 		: NOT asserted
	//		2. Error Occur  : Assume there is no Error, So Omit the component!
	reg					L_SCx_nWAIT;
	reg					Sync_SCx_nWAIT;

	assign	SLV_RDY = Sync_SCx_nWAIT;
	
	reg					L_PACK;
	reg					Sync_PACK;

	// Synchronizer 1
	always@(posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			{L_PACK,L_SCx_nWAIT} <= {1'b0,1'b1};
		end
		else
		begin
			{L_PACK,L_SCx_nWAIT} <= {PACK,SCx_nWAIT};
		end
	end

	// Synchronizer 2
	always@(posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			{Sync_PACK,Sync_SCx_nWAIT} <= {1'b0,1'b1};
		end
		else
		begin
			{Sync_PACK,Sync_SCx_nWAIT} <= {L_PACK,L_SCx_nWAIT};
		end
	end


//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//																	//
//					Finite State Machine(FSM)						//
//																	//
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
	always@ (posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			CurState <= ST_RDY;
		end
		else
		begin
			CurState <= NextState;
		end
	end

//////////////////////////
//	NextState Determine	//
//////////////////////////
//APB CLK is defined as Core-B Lite CLK/2 
// If APB CLK needs changing the CLK speed, 
// then State Changed should be re-considered

//  
	always@*
	begin
		casex(	{CurState,	DxSEL, 	MmMOD,	 	L_MmWT,		L_MmLST,	Sync_PACK,	SLV_RDY})
				//READY
			{ST_RDY,  	1'b1, 	ACTIVE,   	1'bx,		1'bx,		1'bx,		1'b1}:	NextState <= ST_ADDR; 

			//		~SLV_RDY(Cannot Sample) , Remain in the RDY State
			{ST_RDY,  	1'b1, 	ACTIVE,   	1'bx,		1'bx,		1'bx,		1'b0}:	NextState <= ST_RDY; 

			// 		There is NO VALID transfer, Remain in the RDY State
			{ST_RDY,  	1'b1,	INACTIVE,	1'bx,		1'bx,		1'bx,		1'bx}:	NextState <= ST_RDY;
			{ST_RDY,  	1'b0,	2'bx,		1'bx,		1'bx,		1'bx,		1'bx}:	NextState <= ST_RDY;

			//READ
			// 		The Read transfer doesn't need to wait for Valid WDT
			{ST_ADDR,  	1'bx,  	2'bx,   	RD,		1'bx,		1'b1,		1'bx}:	NextState <= ST_REQD; 
			{ST_ADDR,  	1'bx,  	2'bx,   	RD,		1'bx,		1'b0,		1'bx}:	NextState <= ST_ADDR; 
			
			//WRITE
			// 		The Write transfer should wait for Valid WDT
			{ST_ADDR,  	1'bx,  	2'bx,   	WT,		1'bx,		1'bx,		1'b1}:	NextState <= ST_DATA; 
			{ST_ADDR,  	1'bx,  	2'bx,   	WT,		1'bx,		1'bx,		1'b0}:	NextState <= ST_ADDR; 

			//WRITE
			// 		After Valid WDT is sampled, then REQUEST!!
			{ST_DATA,  	1'bx,	2'bx,	  	WT,		1'bx,		1'b1,		1'bx}:	NextState <= ST_REQD;
			{ST_DATA,  	1'bx,	2'bx,	  	WT,		1'bx,		1'b0,		1'bx}:	NextState <= ST_DATA;

			//REQUESTED
			// 		If Slave is ready for another transfer, go to RDY state
			{ST_REQD, 	1'bx,	2'bx,		1'bx,		1'bx,		1'bx,		1'b1}:	NextState <= ST_RDY; 

			// 		If Slave is not ready for another transfer, Remain the Requested State
			{ST_REQD, 	1'bx,	2'bx,		1'bx,		1'bx,		1'bx,		1'b0}:	NextState <= ST_REQD; 
			
				// If Weird inputs are coming, go to ERROR State
				// NOTICE) 
				//		ST_ERROR does NOT represent that SLV_ERR is asserted
				//		ST_ERROR exists for checking if there are unexpected input or not
			default:											NextState <= ST_ERROR;	
		endcase
	end

//////////////////////////////
// Latch the BUS ADDR		//
//////////////////////////////
	always@ (posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			L_MmADDR <= 32'b0;
		end
		else
		begin
			// Latch the MmADDR 
			// 		NO ERR CASE) 
			//			ADDR_SAMPLE
			// 		ERR CASE) 
			// 			L_MmLST : means that the ERROR occuring transfer is last transfer in the transaction 
			//		PREREQUISITE
			//			DxSEL  : the Slave is selected
			//			MmMOD : LDADDR, Master indicates that slave should use the given address
			//			MsRDY : PREVIOUS transfer is completed (The Enable Condition for Pipeline proceeding)
			if(  ADDR_SMP && DxSEL && (MmMOD == LDADDR) && Sync_SCx_nWAIT)
			begin
				L_MmADDR <= MmADDR; 
			end
		end
	end

//////////////////////////////////
// Latch the BUS Control		//
//////////////////////////////////
	always@(posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			{ L_MmWT, L_MmMOD, L_MmSZ, L_MmRB} <= { 1'b0, 2'b0, 3'b0, 4'b0};
		end	
		else
		begin
			// Latch the MmADDR 
			// 		NO ERR CASE) 
			//			ADDR_SAMPLE
			// 		ERR CASE) 
			// 			L_MmLST : means that the ERROR occuring transfer is last transfer in the transaction 
			//		PREREQUISITE
			//			DxSEL  : the Slave is selected
			//			MmMOD : ACTIVE, Master indicates that real transfer is requested
			//			MsRDY : PREVIOUS transfer is completed (The Enable Condition for Pipeline proceeding)
		  if(  ADDR_SMP & DxSEL & (MmMOD[1] == 1'b1) & Sync_SCx_nWAIT )
		  begin
			{ L_MmWT, L_MmMOD, L_MmSZ, L_MmRB} <= { MmWT, MmMOD, MmSZ, MmRB};
		  end
		end
	end

	// L_MmLST : Indicate if Sampled transfer is last transfer or not
	assign L_MmLST = ~(L_MmRB[3]|L_MmRB[2]|L_MmRB[1]|L_MmRB[0]);

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//																	//
//						OUTPUT	DETERMINE							//
//																	//
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

//////////////////////////////////
// 			To Slave Signals	//
//////////////////////////////////
	// 1.SCx_REQ
	always@*
	begin
		case({L_MmWT, CurState})
				{WT,	ST_DATA}	:	SCx_REQ <= 1'b1;
				{RD,	ST_ADDR}	:	SCx_REQ <= 1'b1;
				default	: 				SCx_REQ <= 1'b0;
		endcase
	end

	// 2. SCx_WT
	assign	SCx_WT	= L_MmWT;


	// 3. SCx_ADDR

	//  INC :	Amount of Increment 
	always @*
	begin
		casex(L_MmSZ)
			// Byte
			3'b000 : INC = 8'd1;
			// Halfword
			3'b001 : INC = 8'd2;
			// Word
			3'b010 : INC = 8'd4;
			// 2 Words
			3'b011 : INC = 8'd8;
			// 4 Words
			3'b100 : INC = 8'd16;
			// 16 Words
			3'b101 : INC = 8'd32;
			// 32 Words
			3'b110 : INC = 8'd64;
			// 64 Words
			3'b111 : INC = 8'd128;
		endcase
	end

	// INCREMENTED SCx_ADDR
	assign	INC_SCx_ADDR = L_iSCx_ADDR + INC;

	// Internal SCx_ADDR
	//  If sampled transfer is LDADDR		, Use Sampled Address
	//                         NOT LDADDR	, Use INC_SCx_ADDR
	//	NOTICE) IDLE, BUSY are considered in the L_iSCx_ADDR
	assign	iSCx_ADDR = (L_MmMOD == LDADDR)? L_MmADDR : INC_SCx_ADDR; 

	//LATCHED iSCx_ADDR
	//	Latch Internal SCx_ADDR
	//		Current State is ST_ADDR(ADDRESS SAMPLED)
	//		Sampled transfer is active transfer	
	always@(posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			L_iSCx_ADDR <= 32'b0;	
		end
		else 
		begin
			if( (CurState == ST_ADDR) && (L_MmMOD[1] == 1'b1) & ((~L_MmWT & Sync_PACK) | L_MmWT))	//if Transfer is Active, and PACK is arrived!
			begin
				L_iSCx_ADDR <= iSCx_ADDR;	
			end	
		end
	end

	// SCx_ADDR	
	// If Current State is ST_ADDR		, Select the iSCx_ADDR
	// 						NOT ST_ADDR	, maintain iSCx_ADDR
	assign	SCx_ADDR = ( ((~L_MmWT ) | L_MmWT) & (CurState == ST_ADDR)  )? iSCx_ADDR : L_iSCx_ADDR;


	// 4. SCx_WDT
	// 	Latch the Write Data
	//  	DATA_SMP(Current State is ST_ADDR)
	//		The requested transfer is Write Transfer
	always@(posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			L_MmWDT <= 32'b0;
		end
		else
		begin
			if(DATA_SMP && L_MmWT)
			begin
				L_MmWDT <= MmWDT;
			end
		end
	end

`ifndef	_DBE_
	always@*
	begin
		casex(	{L_MmWT,	L_MmSZ,	SCx_ADDR[1:0]})
			{RD,		3'bx,	2'bx} : SCx_WDT = L_MmWDT;	
			{WT,		BT,	2'b00}: SCx_WDT = {8'b0,		8'b0,		8'b0,		L_MmWDT[7:0]};
			{WT,		BT,	2'b01}: SCx_WDT = {8'b0,		8'b0,		L_MmWDT[7:0],	8'b0};
			{WT,		BT,	2'b10}: SCx_WDT = {8'b0, 		L_MmWDT[7:0],	8'b0,		8'b0};
			{WT,		BT,	2'b11}: SCx_WDT = {L_MmWDT[7:0],	8'b0,		8'b0,		8'b0};

			{WT,		HWD,	2'b00}: SCx_WDT = {16'b0,		L_MmWDT[15:0]};
			{WT,		HWD,	2'b10}: SCx_WDT = {L_MmWDT[15:0],	16'b0};

			{WT,		WD,	2'bx} : SCx_WDT = L_MmWDT;

			default		      : SCx_WDT = L_MmWDT;
		endcase	
	end
`else
	assign SCx_WDT = L_MmWDT;

`endif


//////////////////////////////////
// 			To BUS Signals		//
//////////////////////////////////


//////////////////////////////
// Latch the SCx_RDT			//
//////////////////////////////
	// Latch the SCx_RDT
	// 		Current State is ST_REQD(transfer is requested)
	//		~L_MmWT(READ Transfer)
	//		SCx_nWAIT is asserted(READY)
	//	NOTICE)
	//		The slave respond to the requested response when SCx_nWAIT of the slave is ASSERTED(READY), NOT MsRDY
	always@ (posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			L_SCx_RDT <= 32'b0;
		end
		else
		begin
			if( (CurState == ST_REQD) && (~L_MmWT) && Sync_SCx_nWAIT)	//Not MsRDY
			begin
				L_SCx_RDT <= SCx_RDT; 
			end
		end
	end

`ifndef	_DBE_
	//	1.	SxRDT
	always@*
	begin
		casex({L_MmWT,	L_MmSZ, SCx_ADDR[1:0]})
			{WT,	3'bx,	2'bx} : SxRDT = L_SCx_RDT;

			{RD,	BT,	2'b00}: SxRDT = {8'b0,		8'b0,		8'b0,		L_SCx_RDT[7:0]};
			{RD,	BT,	2'b01}: SxRDT = {8'b0,		8'b0,		8'b0,		L_SCx_RDT[15:8]};
			{RD,	BT,	2'b10}: SxRDT = {8'b0, 		8'b0,		8'b0,		L_SCx_RDT[23:16]};
			{RD,	BT,	2'b11}: SxRDT = {8'b0,		8'b0,		8'b0,		L_SCx_RDT[31:24]};

			{RD,	HWD,	2'b00}: SxRDT = {16'b0,		L_SCx_RDT[15:0]};
			{RD,	HWD,	2'b10}: SxRDT = {16'b0,		L_SCx_RDT[31:16]};

			{RD,	WD,	2'bx} : SxRDT = L_SCx_RDT;

			default			      : SxRDT = L_SCx_RDT;
		endcase	
	end

`else
	//	1.	SxRDT
	assign	SxRDT = L_SCx_RDT;
`endif



	//	2.	SxRDY
	//	Slave is ready for next transfer 
	//		Current State 	: ST_RDY
	assign	SxRDY = (CurState == ST_RDY);


	//	3.	SxERR
	//	Assume that APB Slave Error never occurs 
	assign	SxERR = 1'b0;
		
endmodule




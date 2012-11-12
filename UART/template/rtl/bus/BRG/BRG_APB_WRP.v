/****************************************************************************
*                                                                           *
*                               Bridge APB                                  *
*                                                                           *
*****************************************************************************
*                                                                           *
*  Description :  				                            *
*  Modify signal timing to interconnect SRAM with APB timing         	    *
*  BRG_APB_WRP plays a role of APB MASTER      	    			    *
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

module BRG_APB_WRP
(
	// From Core-B Lite Slave Wrapper
	input	wire					SCx_REQ, 
	input	wire					SCx_WT, 
	input	wire		[31:0]		SCx_ADDR, 
	input	wire		[31:0]		SCx_WDT,

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
	input	wire		[31:0]		PRDATA,
	
	// To APBWrapper(SlaveWrapper)
	output	wire					PACK,
	output	wire					SCx_nWAIT,
	output	wire		[31:0]		SCx_RDT
);
//////////////////////////
//	State Parameters	//
//////////////////////////
localparam		ST_IDLE 	= 3'b000;
localparam		ST_SETUP 	= 3'b001;	//Setup Stage
localparam		ST_ENABLE	= 3'b010;	//Enable Stage
localparam		ST_WAIT		= 3'b011;	//Wait Stage
localparam		ST_ERROR	= 3'b111;	//Error

	reg		[2:0]		CurState;	
	reg		[2:0]		NextState;

	// The CLK is different between
	//		Core-B Lite
	//		APB	
	// There Could be a skew between them
	// This Situation can be similar to the ASYNC Systems.
	// In order to fix this, Double Latching is used! 
	reg					L_SCx_REQ;
	reg					Sync_SCx_REQ;

	// Synchronizer 1
	always@(posedge PCLK or negedge PRESETn)
	begin
		if(~PRESETn)
		begin
			L_SCx_REQ <= 1'b0;
		end
		else
		begin
			L_SCx_REQ <= SCx_REQ;
		end
	end

	// Synchronizer 2
	always@(posedge PCLK or negedge PRESETn)
	begin
		if(~PRESETn)
		begin
			Sync_SCx_REQ <= 1'b0;
		end
		else
		begin
			Sync_SCx_REQ <= L_SCx_REQ;
		end
	end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//																	//
//					Finite State Machine(FSM)						//
//																	//
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
	always@ (posedge PCLK or negedge PRESETn)
	begin
		if(~PRESETn)
		begin
			CurState <= ST_IDLE;
		end
		else
		begin
			CurState <= NextState;
		end
	end

//////////////////////////
//	NextState Determine	//
//////////////////////////
	always@*
	begin
		casex(	{CurState,	Sync_SCx_REQ} )
				//IDLE
				{ST_IDLE,  	1'b1}:	NextState <= ST_SETUP; 

				// 		There is NO VALID transfer, Remain in the RDY State
				{ST_IDLE,  	1'b0}:	NextState <= ST_IDLE;

				//SETUP
				// 		The Read transfer doesn't need to wait for Valid WDT
				{ST_SETUP, 	1'bx}:	NextState <= ST_ENABLE;
				
				//ENABLE			
				//		There is Transfer,
				{ST_ENABLE, 1'b1}:	NextState <= ST_IDLE;

				//		There is NO Transfer, Go to IDLE
				{ST_ENABLE, 1'b0}:	NextState <= ST_IDLE;

				// If Weird inputs are coming, go to ERROR State
				// NOTICE) 
				//		ST_ERROR does NOT represent that SLV_ERR is asserted
				//		ST_ERROR exists for checking if there are unexpected input or not
				default:			NextState <= ST_ERROR;	
		endcase
	end

//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////
//																	//
//						OUTPUT	DETERMINE							//
//																	//
//////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////

//////////////////////////////////
// 		To APB Slave Signals	//
//////////////////////////////////
	// 1. PENABLE
	assign PENABLE = (CurState == ST_ENABLE)? 1'b1 : 1'b0;


	// 2. PWRITE
	wire				iPWRITE;
	reg					L_iPWRITE;

	assign iPWRITE = SCx_WT;
	always@(posedge PCLK or negedge PRESETn)
	begin
		if(~PRESETn)
		begin
			L_iPWRITE <= 1'b0;
		end
		else
		begin
			if( ( (CurState == ST_IDLE) | (CurState == ST_ENABLE) ) && Sync_SCx_REQ )
			begin
				L_iPWRITE <= iPWRITE;
			end
		end
	end
	assign PWRITE =  (CurState == ST_SETUP)? iPWRITE : L_iPWRITE;	

	// 3. PADDR
	wire	[31:0]		iPADDR;
	reg		[31:0]		L_iPADDR;


	assign iPADDR = SCx_ADDR;
	always@(posedge PCLK or negedge PRESETn)
	begin
		if(~PRESETn)
		begin
			L_iPADDR <= 32'b0;
		end
		else
		begin
			if( CurState == ST_SETUP )
			begin
				L_iPADDR <= iPADDR;
			end
		end
	end
	assign PADDR   = (CurState == ST_SETUP)? iPADDR : L_iPADDR;

	// 4. PWDATA
	wire	[31:0]		iPWDATA;
	reg		[31:0]		L_iPWDATA;

	assign iPWDATA = SCx_WDT;
	always@(posedge PCLK or negedge PRESETn)
	begin
		if(~PRESETn)
		begin
			L_iPWDATA <= 32'b0;
		end
		else
		begin
			if( CurState == ST_SETUP)
			begin
				L_iPWDATA <= iPWDATA;
			end
		end
	end
	assign PWDATA = (CurState == ST_SETUP)? iPWDATA : L_iPWDATA;

	// 5. PSELEN
	assign PSELEN = (CurState == ST_SETUP) | (CurState == ST_ENABLE);

//////////////////////////////////
// 		To Core-B BUS Wrapper	//
//////////////////////////////////
	// 1. PACK
	assign PACK = (NextState == ST_SETUP)? 1'b1 : 1'b0;

	// 2. SCx_nWAIT
	assign SCx_nWAIT = (CurState == ST_IDLE && NextState == ST_IDLE) | (CurState == ST_ENABLE);

	// 3. SCx_RDT

	reg		[31:0]		L_PRDATA;

	always@(posedge PCLK or negedge PRESETn)
	begin
		if(~PRESETn)
		begin
			L_PRDATA <= 32'b0;
		end
		else
		begin
			if(CurState == ST_ENABLE)
			begin
				L_PRDATA <= PRDATA;
			end
		end
	end

	assign SCx_RDT =  (CurState == ST_ENABLE)? PRDATA: L_PRDATA;
// 1)Core-B Lite I/F Part
//		Sample the Core-B Lite Bus Signals (Slave Wrapper Do this) 
//		Maintain the Core-B Lite Bus Signals until APB transfer is completed
//		Postpone the Core-B Lite Bus until APB transfer is completed
//		NOTICE) 
//			APB has No RDY signals, i.e) APB assume that slave respond to the requested transfer within 1 Cycle!!
//			But, Core-B Lite & APB has their own CLK & Reset signals
//				Core-B Lite : CLK, nRST
//				APB			: PCLK, PRESETn
//			So We need the self-made RDY signals in order to compensate the difference between 2 BUS CLK
//				RDY Signal Direction : APB --> Core-B Lite
//				But PENABLE coubld be used as READY Signals(We don't Need to define another Signals!)
//				Because PENABLE points to the cycle when valid data transfer should occur

// 2)APB I/F Part

	// Slave Ready 
	//	Ready Case
	// 		1. Wait 		: NOT asserted
	//			APB has no RDY signal!!
	//			However, ST_ENABLE points to the cycle that valid data transfer occurs in
	//			Little modification is needed, because the ST_ENABLE is not asserted when Slave is ST_IDLE
	//			So, ST_IDLE is also added for proceeding!
	//	i.e) Although the error occured in the memory, 
	//		 That indicates that the memory responds to the requested transfer
endmodule

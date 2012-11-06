/********************************************************************************
 *																				*
 *		UartRxFIFOCtrl.v  Ver 0.1												*
 *																				*
 *		COPYRIGHT (C) SAMSUNG THALES CO., LTD. ALL RIGHTS RESERVED				*
 *																				*
 *		Designed by	Yoon Dong Joon												*
 *																				*
 ********************************************************************************
 *																				*
 *		Support Verilog 2001 Syntax												*
 *																				*
 *		Update history : 2007.05.22	 original authored (Ver.0.1)				*
 *																				*
 ********************************************************************************/	

`timescale 1ns/1ps		

module UartRxFIFOCtrl(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input			RESETn,
	
	//---------------------------------------------------------------------------
	//	DSP Interface
	//---------------------------------------------------------------------------
	input			DSP_CLK,
	input			DSP_CEn,
	input	[4:1]	DSP_ADDR,
	output	[15:0]	DSP_RDATA,
	input			DSP_WEn,
	
	//---------------------------------------------------------------------------
	//	RxFIFO Control Signals
	//---------------------------------------------------------------------------
	input			FIFOEn,
	
	//---------------------------------------------------------------------------
	//	UART Rx Controller Interface
	//---------------------------------------------------------------------------
	input			RxBusy,
	input			RxDone,
	input	[7:0]	RxData,
	
	//---------------------------------------------------------------------------
	//	RxFIFO Status
	//---------------------------------------------------------------------------
	output			OverrunError,
	output			RxFIFO_Empty,		
	output			RxFIFO_Full,		    
	output			RxFIFO_L14_Full,	    
	output			RxFIFO_L12_Full,	    
	output			RxFIFO_L8_Full,	    
	output			RxFIFO_L4_Full,	    
	output			RxFIFO_L2_Full	    
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg		[7:0]	RxFIFO[0:15];
reg		[4:0]	iWp;
reg		[4:0]	iRp;  
wire	[4:0]	iRxFIFOLevel;
wire			iRxFIFO_Empty;

reg		[7:0]	iDSP_RDATA;

reg				d0_RxBusy;
reg				d1_RxBusy;
reg				d0_RxDone;
reg				d1_RxDone;

reg		[7:0]	d0_RxData;
reg		[7:0]	d1_RxData;
reg				iOverrunError;

//-------------------------------------------------------------------------------
//	UART Rx Controller Signals Synchronize
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		d0_RxBusy	<= 1'b0;
		d1_RxBusy	<= 1'b0;
		d0_RxDone	<= 1'b0;
		d1_RxDone	<= 1'b0;
		d0_RxData	<= 8'd0;
		d1_RxData	<= 8'd0;
	end
	else begin
		d0_RxBusy	<= RxBusy;
		d1_RxBusy	<= d0_RxBusy;
		
		d0_RxDone	<= RxDone;
		d1_RxDone	<= d0_RxDone;
		
		d0_RxData	<= RxData;
		d1_RxData	<= d0_RxData;
	end
end

//-------------------------------------------------------------------------------
//	FIFO Write Operation
//-------------------------------------------------------------------------------
integer i;
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		for(i=0;i<16;i=i+1) begin
			RxFIFO[i]	<= 8'd0;
		end	
		iWp		<= 4'd0;
		iOverrunError	<= 1'b0;
	end	
	else begin 
		if(d0_RxDone && !d1_RxDone)begin
			RxFIFO[iWp[3:0]]	<= d0_RxData;
			iWp					<= iWp + 1;
			if(RxFIFO_Full) begin
				iOverrunError	<= 1'b1;
			end
			else begin
				iOverrunError	<= 1'b0;
			end
		end
	end
end

assign OverrunError	= iOverrunError;

//-------------------------------------------------------------------------------
//	FIFO Read Operation
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iDSP_RDATA		<= 8'd0;
		iRp				<= 4'd0;
	end
	else begin
		if(!DSP_CEn && DSP_WEn && DSP_ADDR == 4'b0000) begin
			if(!RxFIFO_Empty) begin
				iDSP_RDATA		<= RxFIFO[iRp[3:0]];
				iRp				<= iRp + 1;
			end
			else begin
				iDSP_RDATA		<= 8'd0;
			end
		end
		else begin
			iDSP_RDATA		<= 8'd0;
		end
	end
end

assign DSP_RDATA		= {8'd0, iDSP_RDATA};

//-------------------------------------------------------------------------------
//	FIFO Status
//-------------------------------------------------------------------------------
assign iRxFIFOLevel		= iWp - iRp;

assign iRxFIFO_Empty	= (iWp == iRp) ? 1'b1 : 1'b0;

assign RxFIFO_Empty		= iRxFIFO_Empty;
assign RxFIFO_Full		= (iRxFIFOLevel == 16) ? 1'b1 : 1'b0;
assign RxFIFO_L14_Full	= (iRxFIFOLevel >= 14) ? 1'b1 : 1'b0;
assign RxFIFO_L12_Full	= (iRxFIFOLevel >= 12) ? 1'b1 : 1'b0;
assign RxFIFO_L8_Full	= (iRxFIFOLevel >= 8) ? 1'b1 : 1'b0;
assign RxFIFO_L4_Full	= (iRxFIFOLevel >= 4) ? 1'b1 : 1'b0;
assign RxFIFO_L2_Full	= (iRxFIFOLevel >= 2) ? 1'b1 : 1'b0;

endmodule

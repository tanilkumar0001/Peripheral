/********************************************************************************
 *																				*
 *		UartTxFIFOCtrl.v  Ver 0.1													*
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

module UartTxFIFOCtrl(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input			RESETn,
	
	//---------------------------------------------------------------------------
	//	DSP Interface
	//---------------------------------------------------------------------------
	input			DSP_CLK,
	input			DSP_CEn,
	input	[3:0]	DSP_ADDR,
	input	[31:0]	DSP_WDATA,
	input			DSP_WEn,
	
	//---------------------------------------------------------------------------
	//	TxFIFO Control Signals
	//---------------------------------------------------------------------------
	input			FIFOEn,
	
	//---------------------------------------------------------------------------
	//	UART Tx Controller Interface
	//---------------------------------------------------------------------------
	input			TxBusy,
	input			TxDone,
	output			TxDataReady,
	output	[7:0]	TxData,
	
	//---------------------------------------------------------------------------
	//	TxFIFO Status
	//---------------------------------------------------------------------------
	output			TxFIFO_Empty,		
	output			TxFIFO_Full,		    
	output			TxFIFO_L14_Full,	    
	output			TxFIFO_L12_Full,	    
	output			TxFIFO_L8_Full,	    
	output			TxFIFO_L4_Full,	    
	output			TxFIFO_L2_Full	    
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg		[7:0]	TxFIFO[0:15];
reg		[4:0]	iWp;
reg		[4:0]	iRp;  
wire	[4:0]	iTxFIFOLevel;
wire			iTxFIFO_Empty;

reg				d0_TxBusy;
reg				d1_TxBusy;
reg				d0_TxDone;
reg				d1_TxDone;

reg		[7:0]	iTxData;
reg				iTxDataReady;

//-------------------------------------------------------------------------------
//	UART Tx Controller Signals Synchronize
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		d0_TxBusy	<= 1'b0;
		d1_TxBusy	<= 1'b0;
		d0_TxDone	<= 1'b0;
		d1_TxDone	<= 1'b0;
	end
	else begin
		d0_TxBusy	<= TxBusy;
		d1_TxBusy	<= d0_TxBusy;
		
		d0_TxDone	<= TxDone;
		d1_TxDone	<= d0_TxDone;
	end
end

//-------------------------------------------------------------------------------
//	FIFO Write Operation
//-------------------------------------------------------------------------------
//integer i;
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		//for(i=0;i<16;i=i+1) begin
		//	TxFIFO[i]	<= 8'd0;
		//end	
		TxFIFO[0] <= 8'd0;
		TxFIFO[1] <= 8'd0;
		TxFIFO[2] <= 8'd0;
		TxFIFO[3] <= 8'd0;
		TxFIFO[4] <= 8'd0;
		TxFIFO[5] <= 8'd0;
		TxFIFO[6] <= 8'd0;
		TxFIFO[7] <= 8'd0;
		TxFIFO[8] <= 8'd0;
		TxFIFO[9] <= 8'd0;
		TxFIFO[10] <= 8'd0;
		TxFIFO[11] <= 8'd0;
		TxFIFO[12] <= 8'd0;
		TxFIFO[13] <= 8'd0;
		TxFIFO[14] <= 8'd0;
		TxFIFO[15] <= 8'd0;
		iWp		<= 4'd0;
	end	
	else begin 
		if(!TxFIFO_Full)begin
			if(iTxDataReady || d1_TxBusy) begin
				if(!DSP_CEn && !DSP_WEn && DSP_ADDR == 4'b0000) begin
					TxFIFO[iWp[3:0]]	<= DSP_WDATA[7:0];
					iWp					<= iWp + 1;
				end
			end
		end
	end
end
//-------------------------------------------------------------------------------
//	FIFO Read Operation
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iTxData			<= 8'd0;
		iTxDataReady	<= 1'b0;
		iRp				<= 4'd0;
	end
	else begin
		if(!iTxDataReady && !d1_TxBusy) begin
			if(!DSP_CEn && !DSP_WEn && DSP_ADDR == 4'b0000) begin
				iTxData			<= DSP_WDATA[7:0];
				iTxDataReady	<= 1'b1;
			end
		end
		else if(d0_TxDone && !d1_TxDone) begin
			if(iTxFIFO_Empty) begin
				iTxData			<= 8'd0;
				iTxDataReady	<= 1'b0;
			end
			else begin
				iTxData			<= TxFIFO[iRp[3:0]];
				iTxDataReady	<= 1'b1;
				iRp				<= iRp + 1;
			end
		end
	end
end

assign TxData		= iTxData;
assign TxDataReady	= iTxDataReady;

//-------------------------------------------------------------------------------
//	FIFO Status
//-------------------------------------------------------------------------------
assign iTxFIFOLevel		= iWp - iRp;

assign iTxFIFO_Empty	= (iWp == iRp) ? 1'b1 : 1'b0;

assign TxFIFO_Empty		= iTxFIFO_Empty;
assign TxFIFO_Full		= (iTxFIFOLevel == 16) ? 1'b1 : 1'b0;
assign TxFIFO_L14_Full	= (iTxFIFOLevel >= 14) ? 1'b1 : 1'b0;
assign TxFIFO_L12_Full	= (iTxFIFOLevel >= 12) ? 1'b1 : 1'b0;
assign TxFIFO_L8_Full	= (iTxFIFOLevel >= 8) ? 1'b1 : 1'b0;
assign TxFIFO_L4_Full	= (iTxFIFOLevel >= 4) ? 1'b1 : 1'b0;
assign TxFIFO_L2_Full	= (iTxFIFOLevel >= 2) ? 1'b1 : 1'b0;

endmodule

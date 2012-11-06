/********************************************************************************
 *																				*
 *		UartTxFIFOCtrl.v  Ver 0.1												*
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

module UartTxFIFOCtrl_TB(
  
);

	
//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 			RESETn;

reg 			DSP_CLK;
reg 			DSP_CEn;
reg 	[7:0]	DSP_WDATA;
reg 			DSP_WEn;

reg 			TxFIFO_En;

reg 			TxBusy;
reg 			TxDone;
wire			TxDataReady;
wire	[7:0]	TxData;

wire			TxFIFO_Empty;		
wire			TxFIFO_Full;		    
wire			TxFIFO_L14_Full;	    
wire			TxFIFO_L12_Full;    
wire			TxFIFO_L8_Full;	    
wire			TxFIFO_L4_Full;	    
wire			TxFIFO_L2_Full;	  

reg		[7:0]	iCnt;

//-------------------------------------------------------------------------------
//	UartTxFIFOCtrl                                                           
//-------------------------------------------------------------------------------
UartTxFIFOCtrl uUartTxFIFOCtrl(
	.RESETn					(RESETn),
	                                        
	.DSP_CLK				(DSP_CLK),
	.DSP_CEn				(DSP_CEn),
	.DSP_WDATA				(DSP_WDATA),
	.DSP_WEn				(DSP_WEn),
	                                        
	.TxFIFO_En				(TxFIFO_En),
	                                        
	.TxBusy					(TxBusy),
	.TxDone					(TxDone),
	.TxDataReady			(TxDataReady),
	.TxData					(TxData),
	                                        
	.TxFIFO_Empty			(TxFIFO_Empty),		
	.TxFIFO_Full			(TxFIFO_Full),		    
	.TxFIFO_L14_Full		(TxFIFO_L14_Full),	    
	.TxFIFO_L12_Full		(TxFIFO_L12_Full),	    
	.TxFIFO_L8_Full			(TxFIFO_L8_Full),	    
	.TxFIFO_L4_Full			(TxFIFO_L4_Full),	    
	.TxFIFO_L2_Full			(TxFIFO_L2_Full)	 
);
 
//---------------------------------------------------------------------------
//	Initialize & Clock, Reset Generation
//---------------------------------------------------------------------------
initial
begin
			DSP_CLK		<= 1'b0;
			RESETn		<= 1'b0;
			
	#500	RESETn		<= 1'b1;
end 

always      
	#10		DSP_CLK	<= !DSP_CLK;	

always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		DSP_CEn		<= 1'b1;
		DSP_WDATA	<= 8'd0;
		DSP_WEn		<= 1'b1;
		iCnt		<= 8'd0;
	end
	else begin
		if(!TxFIFO_Full) begin
			if(!iCnt[0]) begin
				DSP_CEn		<= 1'b0;
				DSP_WDATA	<= iCnt;
				DSP_WEn		<= 1'b0;
			end
			else begin
				DSP_CEn		<= 1'b1;
				DSP_WDATA	<= 8'd0;
				DSP_WEn		<= 1'b1;
			end
		end
		
		iCnt	<= iCnt + 1;
	end		
end

endmodule

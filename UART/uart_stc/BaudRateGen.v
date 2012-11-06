/********************************************************************************
 *																				*
 *		BaudRateGen.v  Ver 0.1													*
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

module BaudRateGen(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input 			CLK,
	input			RESETn,
	
	//---------------------------------------------------------------------------
	//	UART Control Signals
	//---------------------------------------------------------------------------
	input	[15:0]	IBRD,
	input	[15:0]	FBRD,
	input			En,
	
	//---------------------------------------------------------------------------
	//	UART Rx Signals
	//---------------------------------------------------------------------------
	output			Baud16
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 	[15:0]	iBaudRateCnt;
reg				iBaud16;


//-------------------------------------------------------------------------------
//	BaudRate Generator
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iBaudRateCnt	<= 16'd1;
		iBaud16			<= 1'b0;
	end
	else begin
		if(En) begin
			if(iBaudRateCnt == 1) begin
				iBaud16	<= 1'b1;
				iBaudRateCnt	<= IBRD;
			end 
			else begin
				iBaud16	<= 1'b0;
				iBaudRateCnt	<= iBaudRateCnt - 1;
			end
		end
		else begin
			iBaudRateCnt	<= 16'd1;
			iBaud16			<= 1'b0;
		end
	end
end

assign Baud16	= iBaud16;
      
endmodule

/********************************************************************************
 *																				*
 *		UartReg.v  Ver 0.1															*
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

module UartReg(
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
	input	[15:0]	DSP_WDATA,
	output	[15:0]	DSP_RDATA,
	input			DSP_WEn,
	
	//---------------------------------------------------------------------------
	//	UART Control Signals
	//---------------------------------------------------------------------------
	output	[1:0]	Parity,
	output			StopBits,
	output	[2:0]	DataBits,
	output			FIFOEn,
	
	output			UARTEn,
	output			RxEn,
	output			TxEn,
	
	output	[3:0]	RxFIFOL,
	output	[3:0]	TxFIFOL,
	
	output	[15:0]	IBRDVal,
	output	[15:0]	FBRDVal,
	
	//---------------------------------------------------------------------------
	//	UART Status Signals
	//---------------------------------------------------------------------------
	input			ParityError,
	input			FrameError,
	input			OverrunError,
	
	input			RxFIFO_Empty,
	input			RxFIFO_Full,
	input			TxFIFO_Empty,
	input			TxFIFO_Full
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 	[15:0]	LCR;
reg 	[15:0]	FCR;
reg 	[15:0]	CR;
reg 	[15:0]	FR;
reg 	[15:0]	IBRD;
reg 	[15:0]	FBRD;

reg		[15:0]	iDSP_RDATA;

//-------------------------------------------------------------------------------
//	Register Write Operation
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		LCR		<= 15'd0;
		FCR		<= 15'd0;
		CR		<= 15'd0; 
		IBRD	<= 15'd0;
		FBRD	<= 15'd0;
	end
	else begin
		if(!DSP_CEn && !DSP_WEn) begin
			case(DSP_ADDR)
				4'b0001 : LCR	<= DSP_WDATA;
				4'b0010 : FCR	<= DSP_WDATA;
				4'b0011 : CR	<= DSP_WDATA;
				4'b0111 : IBRD	<= DSP_WDATA;
				4'b1000 : FBRD	<= DSP_WDATA;
			endcase	
		end 		
	end
end

//-------------------------------------------------------------------------------
//	Register Read Operation                                                               
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iDSP_RDATA	<= 15'd0;
	end
	else begin
		if(!DSP_CEn && DSP_WEn) begin
			case(DSP_ADDR)
				4'b0001 : iDSP_RDATA	<= LCR;
				4'b0010 : iDSP_RDATA	<= FCR;
				4'b0011 : iDSP_RDATA	<= CR;
				4'b0100 : iDSP_RDATA	<= FR;
				4'b0111 : iDSP_RDATA	<= IBRD;
				4'b1000 : iDSP_RDATA	<= FBRD;
			endcase	
		end 		
	end
end

assign DSP_RDATA	= iDSP_RDATA;
                           
//-------------------------------------------------------------------------------
//	Register Outputs
//-------------------------------------------------------------------------------
assign Parity	= LCR[1:0];
assign StopBits	= LCR[2];
assign DataBits	= (LCR[4:3] == 2'b11) ? 3'b111 :
				  (LCR[4:3] == 2'b10) ? 3'b110 : 
				  (LCR[4:3] == 2'b01) ? 3'b101 : 
				  3'b100;
assign FIFOEn	= LCR[5];

assign UARTEn	= CR[0];
assign RxEn		= CR[1];
assign TxEn		= CR[2];

assign RxFIFOL	= FCR[3:0];
assign TxFIFOL	= FCR[7:4];

assign IBRDVal	= IBRD;
assign FBRDVal	= FBRD;

//-------------------------------------------------------------------------------
//	UART Status Register
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		FR		<= 15'd0; 
	end
	else begin
		FR		<= {TxFIFO_Full, TxFIFO_Empty, RxFIFO_Full, RxFIFO_Empty,
					1'b0, OverrunError, FrameError, ParityError};
	end
end
                           
endmodule                  
                           

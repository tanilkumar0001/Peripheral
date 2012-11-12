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
	input	[3:0]	DSP_ADDR,
	input	[31:0]	DSP_WDATA,
	output	[31:0]	DSP_RDATA,
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
	
	output	[31:0]	IBRDVal,
	output	[31:0]	FBRDVal,
	
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
reg 	[31:0]	LCR;
reg 	[31:0]	FCR;
reg 	[31:0]	ER;
reg 	[31:0]	SR;
reg 	[31:0]	IBRD;
reg 	[31:0]	FBRD;

reg		[31:0]	iDSP_RDATA;

//-------------------------------------------------------------------------------
//	Register Write Operation
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		LCR		<= 32'd0;
		FCR		<= 32'd0;
		ER		<= 32'd0; 
		IBRD	<= 32'd0;
		FBRD	<= 32'd0;
	end
	else begin
		if(!DSP_CEn && !DSP_WEn) begin
			case(DSP_ADDR)
				4'b0001 : LCR	<= DSP_WDATA;
				4'b0010 : FCR	<= DSP_WDATA;
				4'b0011 : ER	<= DSP_WDATA;
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
		iDSP_RDATA	<= 32'd0;
	end
	else begin
		if(!DSP_CEn && DSP_WEn) begin
			case(DSP_ADDR)
				4'b0001 : iDSP_RDATA	<= LCR;
				4'b0010 : iDSP_RDATA	<= FCR;
				4'b0011 : iDSP_RDATA	<= ER;
				4'b0100 : iDSP_RDATA	<= SR;
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

assign UARTEn	= ER[0];
assign RxEn		= ER[1];
assign TxEn		= ER[2];

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
		SR		<= 32'd0; 
	end
	else begin
		SR		<= {TxFIFO_Full, TxFIFO_Empty, RxFIFO_Full, RxFIFO_Empty,
					1'b0, OverrunError, FrameError, ParityError};
	end
end
                           
endmodule                  
                           

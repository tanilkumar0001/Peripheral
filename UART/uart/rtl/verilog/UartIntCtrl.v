/********************************************************************************
 *																				*
 *		UartIntCtrl.v  Ver 0.1													*
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

`define ST_READY	1'b0
`define ST_IRQ		1'b1

module UartIntCtrl(
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
	input	[31:0]	DSP_WDATA,
	output	[31:0]	DSP_RDATA,
	input			DSP_WEn,
	
	//---------------------------------------------------------------------------
	//	UART Control Signals
	//---------------------------------------------------------------------------
	input	[3:0]	RxFIFOL,
	input	[3:0]	TxFIFOL,
	
	//---------------------------------------------------------------------------
	//	UART Status Signals
	//---------------------------------------------------------------------------
	input			RxTimeOut,
	input			ParityError,
	input			FrameError,
	input			OverrunError,
	
	input			RxFIFO_Empty,
	input			RxFIFO_L14_Full,	
	input			RxFIFO_L12_Full,	
	input			RxFIFO_L8_Full,	  
	input			RxFIFO_L4_Full,	  
	input			RxFIFO_L2_Full,
	
	input			TxFIFO_L14_Full,	
	input			TxFIFO_L12_Full,	
	input			TxFIFO_L8_Full,	  
	input			TxFIFO_L4_Full,	  
	input			TxFIFO_L2_Full,
	
	//---------------------------------------------------------------------------
	//	UART Status Signals
	//---------------------------------------------------------------------------
	output			nIRQ	  
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 	[3:0]	IER;
wire	[3:0]	ISR;

reg				IRQ_State;
wire	[3:0]	iIntClear;

reg		[15:0]	iDSP_RDATA;

wire			iTxInt;
wire			iRxInt;
wire			iRxTimeOutInt;
wire			iRxErrInt;

//-------------------------------------------------------------------------------
//	Register Write Operation
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		IER		<= 8'd0;
	end
	else begin
		if(!DSP_CEn && !DSP_WEn && DSP_ADDR == 4'b0101) begin
			IER	<= DSP_WDATA[3:0]; 
		end 		
	end
end

assign iIntClear	= (!DSP_CEn && !DSP_WEn && DSP_ADDR == 4'b0110) ? DSP_WDATA[3:0] :
					  4'd0;	

//-------------------------------------------------------------------------------
//	Register Read Operation                                                               
//-------------------------------------------------------------------------------
always@(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iDSP_RDATA	<= 15'd0;
	end
	else begin
		if(!DSP_CEn && DSP_WEn && DSP_ADDR == 4'b0101) begin
			iDSP_RDATA	<= {12'd0, IER}; 
		end 
		else if(!DSP_CEn && DSP_WEn && DSP_ADDR == 4'b0110) begin
			iDSP_RDATA	<= {12'd0, ISR}; 
		end 		
	end
end

assign DSP_RDATA	= {16'd0, iDSP_RDATA};
                           
//-------------------------------------------------------------------------------
//	Interrupt Sources
//-------------------------------------------------------------------------------
assign iTxInt	= (TxFIFOL == 4'd2 && !TxFIFO_L2_Full) ? 1'b1 :
				  (TxFIFOL == 4'd4 && !TxFIFO_L4_Full) ? 1'b1 :
				  (TxFIFOL == 4'd8 && !TxFIFO_L8_Full) ? 1'b1 :
				  (TxFIFOL == 4'd12 && !TxFIFO_L12_Full) ? 1'b1 :
				  (TxFIFOL == 4'd14 && !TxFIFO_L14_Full) ? 1'b1 :
				  1'b0;
				  
assign iRxInt	= (RxFIFOL == 4'd2 && RxFIFO_L2_Full) ? 1'b1 :
				  (RxFIFOL == 4'd4 && RxFIFO_L4_Full) ? 1'b1 :
				  (RxFIFOL == 4'd8 && RxFIFO_L8_Full) ? 1'b1 :
				  (RxFIFOL == 4'd12 && RxFIFO_L12_Full) ? 1'b1 :
				  (RxFIFOL == 4'd14 && RxFIFO_L14_Full) ? 1'b1 :
				  1'b0;				  

assign iRxTimeOutInt	= !RxFIFO_Empty & RxTimeOut; 
				  
assign iRxErrInt	= OverrunError | FrameError | ParityError;

//-------------------------------------------------------------------------------
//	Interrupt Source Register
//-------------------------------------------------------------------------------
INT_SRC uINT_SRC0(DSP_CLK, RESETn, iIntClear[0], IER[0], iRxErrInt, ISR[0]);
INT_SRC uINT_SRC1(DSP_CLK, RESETn, iIntClear[1], IER[1], iRxTimeOutInt, ISR[1]);
INT_SRC uINT_SRC2(DSP_CLK, RESETn, iIntClear[2], IER[2], iRxInt, ISR[2]);
INT_SRC uINT_SRC3(DSP_CLK, RESETn, iIntClear[3], IER[3], iTxInt, ISR[3]);

//---------------------------------------------------------------------------
//	IRQ State Machine
//---------------------------------------------------------------------------
always @(posedge DSP_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		IRQ_State	<= `ST_READY;
	end
	else begin
		if(IRQ_State == `ST_READY) begin
			if(ISR != 4'b0000) begin
				IRQ_State	<= `ST_IRQ;	
			end
		end
		else if(IRQ_State == `ST_IRQ) begin
			if(!DSP_CEn && !DSP_WEn && DSP_ADDR == 4'b0110) begin
				IRQ_State	<= `ST_READY;
			end	
		end
	end
end				

assign nIRQ	= (IRQ_State == `ST_IRQ) ? 1'b0 : 1'b1;
                       
endmodule                  
                           

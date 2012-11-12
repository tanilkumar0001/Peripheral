/********************************************************************************
 *																				*
 *		UartRXCtrl.v  Ver 0.1													*
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

`define ST_IDLE			3'b000
`define ST_START		3'b001
`define ST_DATA			3'b010
`define ST_PARITY		3'b011
`define ST_STOP			3'b100

`define DATA8			3'b111
`define DATA7			3'b110
`define DATA6			3'b101
`define DATA5			3'b100

`define PARITY_NONE		2'b00
`define PARITY_ODD		2'b01
`define PARITY_EVEN		2'b10

`define STOP1			1'b0
`define STOP2			1'b1


module UartRxCtrl(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input 			CLK,
	input			RESETn,
	
	//---------------------------------------------------------------------------
	//	UART Control Signals
	//---------------------------------------------------------------------------
	input			Baud16,
	input			RxEn,
	
	input	[2:0]	DataBits,
	input	[1:0]	Parity,
	input			StopBits,
	
	//---------------------------------------------------------------------------
	//	UART Rx Signals
	//---------------------------------------------------------------------------
	input			RXD,
	
	output	[7:0]	RxData,
	
	output			RxBusy,
	output			RxDone,
	output			RxTimeOut,
	output			ParityError,
	output			FrameError
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 			d0_RXD;
reg 			d1_RXD;
reg 			d2_RXD;
reg 			iRXD;

reg		[2:0]	RxState;
reg		[7:0]	RxShiftReg;
reg		[3:0]	iBitPeriodCnt;
reg		[2:0]	iBitCnt;

reg				iRxTimeOut;
reg		[8:0]	iTimeOutCnt;

reg		[7:0]	iRxData;
reg				iParity;
reg				iRxBusy;
reg				iRxDone;

reg				iParityError;
reg				iFrameError;

//-------------------------------------------------------------------------------
//	External RXD Syncronize
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn)
begin
	if(!RESETn) begin
		d0_RXD	<= 1'b1;
		d1_RXD	<= 1'b1;
		d2_RXD	<= 1'b1;
		iRXD	<= 1'b1;
	end
	else begin
		if(Baud16) begin
			if( (d0_RXD && d1_RXD) || (d0_RXD && d2_RXD) || (d1_RXD && d2_RXD) ) begin
				iRXD	<= 1'b1;
			end
			else begin
				iRXD	<= 1'b0;
			end

			d0_RXD	<= RXD;
			d1_RXD	<= d0_RXD;
			d2_RXD	<= d1_RXD;
		end
	end
end

//-------------------------------------------------------------------------------
//	RX State Machine
//-------------------------------------------------------------------------------      
always@(posedge CLK, negedge RESETn)
begin                               
	if(!RESETn) begin
		iBitPeriodCnt	<= 4'd15;	
		iBitCnt			<= 3'd0;	
		iTimeOutCnt		<= 9'd511;
		iRxData			<= 8'd0;
		RxShiftReg		<= 8'd0;
		iParity			<= 1'b0;
		iRxBusy			<= 1'b0;
		iRxDone			<= 1'b0;
		iRxTimeOut		<= 1'b0;
		iParityError	<= 1'b0;
		iFrameError		<= 1'b0;
		RxState			<= `ST_IDLE;
	end
	else begin
		if(RxState == `ST_IDLE) begin
			if(RxEn && Baud16 && !iRXD) begin
				iBitPeriodCnt	<= 4'd7;
				iBitCnt			<= 4'd0;
				iTimeOutCnt		<= 9'd511;
				iParity			<= 1'b0;
				iRxBusy			<= 1'b1;
				iRxDone			<= 1'b0;
				iRxTimeOut		<= 1'b0;
				iParityError	<= 1'b0;
				iFrameError		<= 1'b0;
				RxState			<= `ST_START;
			end
			else if(RxEn && Baud16 && iRXD) begin
				if(iTimeOutCnt == 0) begin
					iTimeOutCnt	<= 9'd511;
					iRxTimeOut	<= 1'b1;
				end
				else begin
					iTimeOutCnt	<= iTimeOutCnt - 1;
					iRxTimeOut	<= 1'b0; 
				end
			end				
		end
		else if(RxEn) begin 
			if(RxState == `ST_START) begin
				if(Baud16) begin
					if(iRXD) begin
						iBitPeriodCnt	<= 4'd15;	
						iBitCnt			<= 3'd0;	
						iParity			<= 1'b0;
						iRxBusy			<= 1'b0;
						iRxDone			<= 1'b0;
						RxState			<= `ST_IDLE;
					end
					else if(iBitPeriodCnt == 0) begin		
						iBitPeriodCnt	<= 4'd15;
						iBitCnt			<= 4'd0;
						if(Parity == `PARITY_ODD) begin 
							iParity		<= 1'b1;
						end
						else begin
							iParity		<= 1'b0;
						end
						iRxBusy			<= 1'b1;
						iRxDone			<= 1'b0;
						RxState			<= `ST_DATA;
					end
					else begin
						iBitPeriodCnt	<= iBitPeriodCnt - 1;
					end
				end		
			end
			else if(RxState == `ST_DATA) begin
				if(Baud16) begin
					if(iBitPeriodCnt == 0) begin		
						if(iBitCnt == DataBits) begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= 4'd0;
							RxShiftReg		<= {iRXD, RxShiftReg[7:1]};
							iParity			<= iParity ^ iRXD;
							if(Parity == `PARITY_NONE) begin 
								RxState			<= `ST_STOP;
							end
							else begin
								RxState			<= `ST_PARITY;
							end
						end
						else begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= iBitCnt + 1;
							RxShiftReg		<= {iRXD, RxShiftReg[7:1]};
							iParity			<= iParity ^ iRXD;
							RxState			<= `ST_DATA;
						end
					end
					else begin
						iBitPeriodCnt	<= iBitPeriodCnt - 1;
					end
				end		
			end
			else if(RxState == `ST_PARITY) begin
				if(Baud16) begin
					if(iBitPeriodCnt == 0) begin		
						iBitPeriodCnt	<= 4'd15;
						iBitCnt			<= 4'd0;
						if(iParity != iRXD) begin
							iParityError	<= 1'b1;
						end
						else begin
							iParityError	<= 1'b0;
						end
						RxState			<= `ST_STOP;
					end
					else begin
						iBitPeriodCnt	<= iBitPeriodCnt - 1;
					end
				end				
			end
			else if(RxState == `ST_STOP) begin
				if(Baud16) begin
					if(iBitPeriodCnt == 0) begin		
						if(iBitCnt[0] == StopBits) begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= 4'd0;
							iFrameError 	<= iFrameError | (!iRXD);
							iRxData			<= RxShiftReg;
							iRxBusy			<= 1'b0;
							iRxDone			<= 1'b1;
							RxState			<= `ST_IDLE;
						end
						else begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= iBitCnt + 1;
							iFrameError		<= !iRXD;		
						end
					end
					else begin
						iBitPeriodCnt	<= iBitPeriodCnt - 1;
					end
				end		
			end
		end
		else begin
			iBitPeriodCnt	<= 4'd15;	
			iBitCnt			<= 3'd0;	
			iTimeOutCnt		<= 9'd511;
			iParity			<= 1'b0;
			iRxBusy			<= 1'b0;
			iRxDone			<= 1'b0;
			iRxTimeOut		<= 1'b0;
			iParityError	<= 1'b0;
			iFrameError		<= 1'b0;
			RxState			<= `ST_IDLE;
		end
	end
end

assign RxData		= iRxData;
assign RxBusy		= iRxBusy;
assign RxDone		= iRxDone;
assign RxTimeOut	= iRxTimeOut;
assign ParityError	= iParityError;
assign FrameError	= iFrameError;

endmodule

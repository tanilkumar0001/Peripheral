/********************************************************************************
 *																				*
 *		UartTXCtrl.v  Ver 0.1													*
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


module UartTxCtrl(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input 			CLK,
	input			RESETn,
	
	//---------------------------------------------------------------------------
	//	UART Control Signals
	//---------------------------------------------------------------------------
	input			Baud16,
	input			TxEn,
	
	input	[2:0]	DataBits,
	input	[1:0]	Parity,
	input			StopBits,
	
	input			TxDataReady,
	input	[7:0]	TxData,
	
	//---------------------------------------------------------------------------
	//	UART Tx Signals
	//---------------------------------------------------------------------------
	output			TXD,
	
	output			TxBusy,
	output			TxDone
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 			iTXD;

reg		[2:0]	TxState;
reg		[7:0]	TxShiftReg;
reg		[3:0]	iBitPeriodCnt;
reg		[2:0]	iBitCnt;

reg				iParity;
reg				iTxBusy;
reg				iTxDone;

//-------------------------------------------------------------------------------
//	Tx State Machine
//-------------------------------------------------------------------------------      
always@(posedge CLK, negedge RESETn)
begin                               
	if(!RESETn) begin
		iBitPeriodCnt	<= 4'd15;	
		iBitCnt			<= 3'd0;	
		iTXD			<= 1'b1;
		iParity			<= 1'b0;
		iTxBusy			<= 1'b0;
		iTxDone			<= 1'b0;
		TxState			<= `ST_IDLE;
	end
	else begin
		if(TxState == `ST_IDLE) begin
			if(TxEn && Baud16 && TxDataReady) begin
				iBitPeriodCnt	<= 4'd15;
				iBitCnt			<= 4'd0;
				iTXD			<= 1'b0;
				if(Parity == `PARITY_ODD) begin 
					iParity		<= 1'b1;
				end
				else begin
					iParity		<= 1'b0;
				end
				iTxBusy			<= 1'b1;
				iTxDone			<= 1'b0;
				TxShiftReg		<= TxData;
				TxState			<= `ST_START;
			end				
		end
		else if(TxEn) begin 
			if(TxState == `ST_START) begin
				if(Baud16) begin
					if(iBitPeriodCnt == 0) begin		
						iBitPeriodCnt	<= 4'd15;
						iBitCnt			<= 4'd0;
						iTXD			<= TxShiftReg[0];
						iParity			<= iParity ^ TxShiftReg[0];
						TxShiftReg		<= {1'b0, TxShiftReg[7:1]};
						TxState			<= `ST_DATA;
					end
					else begin
						iBitPeriodCnt	<= iBitPeriodCnt - 1;
					end
				end		
			end
			else if(TxState == `ST_DATA) begin
				if(Baud16) begin
					if(iBitPeriodCnt == 0) begin		
						if(iBitCnt == DataBits) begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= 4'd0;
							if(Parity == `PARITY_NONE) begin 
								iTXD			<= 1'b1;
								iTxDone			<= 1'b1;
								TxState			<= `ST_STOP;
							end
							else begin
								iTXD			<= iParity;
								TxState			<= `ST_PARITY;
							end
						end
						else begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= iBitCnt + 1;
							iTXD			<= TxShiftReg[0];
							iParity			<= iParity ^ TxShiftReg[0];
							TxShiftReg		<= {1'b0, TxShiftReg[7:1]};
							TxState			<= `ST_DATA;
						end
					end
					else begin
						iBitPeriodCnt	<= iBitPeriodCnt - 1;
					end
				end		
			end
			else if(TxState == `ST_PARITY) begin
				if(Baud16) begin
					if(iBitPeriodCnt == 0) begin		
						iBitPeriodCnt	<= 4'd15;
						iBitCnt			<= 4'd0;
						iTXD			<= 1'b1;
						iTxDone			<= 1'b1;
						TxState			<= `ST_STOP;
					end
					else begin
						iBitPeriodCnt	<= iBitPeriodCnt - 1;
					end
				end				
			end
			else if(TxState == `ST_STOP) begin
				if(Baud16) begin
					if(iBitPeriodCnt == 0) begin		
						if(iBitCnt[0] == StopBits) begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= 4'd0;
							if(TxDataReady) begin
								iTXD			<= 1'b0;
								if(Parity == `PARITY_ODD) begin 
									iParity		<= 1'b1;
								end
								else begin
									iParity		<= 1'b0;
								end
								iTxBusy			<= 1'b1;
								iTxDone			<= 1'b0;
								TxShiftReg		<= TxData;
								TxState			<= `ST_START;
							end
							else begin
								iTXD			<= 1'b1;
								iParity			<= 1'b0;
								iTxBusy			<= 1'b0;
								iTxDone			<= 1'b0;
								TxState			<= `ST_IDLE;
							end
						end
						else begin
							iBitPeriodCnt	<= 4'd15;
							iBitCnt			<= iBitCnt + 1;
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
			iTXD			<= 1'b1;
			iParity			<= 1'b0;
			iTxBusy			<= 1'b0;
			iTxDone			<= 1'b0;
			TxState			<= `ST_IDLE;	
		end
	end
end

assign TXD		= iTXD;
assign TxBusy	= iTxBusy;
assign TxDone	= iTxDone;

endmodule

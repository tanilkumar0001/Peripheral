/********************************************************************************
 *																				*
 *		I2C_Transceiver.v  Ver 0.1														*
 *																				*
 *		Designed by	Yoon Dong Joon                                              *
 *																				*
 ********************************************************************************
 *																				*
 *		Support Verilog 2001 Syntax												*
 *																				*
 *		Update history : 2011.10.23	 original authored (Ver.0.1)				*
 *																				*
 *		Support only Single Master												*
 *																				*
 ********************************************************************************/	

`timescale 1ns/1ps		

`define CMD_NOP			3'b000
`define CMD_START		3'b001
`define CMD_REPSTART	3'b010
`define CMD_STOP		3'b011
`define CMD_WRITE		3'b100
`define CMD_READ		3'b101

`define ST_IDLE			3'b000
`define ST_START		3'b001
`define ST_REPSTART		3'b010
`define ST_STOP			3'b011
`define ST_WRITE		3'b100
`define ST_READ			3'b101
`define ST_TXACK		3'b110
`define ST_RXACK		3'b111

`define ST_WADDR		3'b001
`define ST_WDATA		3'b010
`define ST_RDATA		3'b011


//`define ST_WCMD			3'b010
//`define ST_RADDR		3'b011
//`define ST_RDATA0		3'b100
//`define ST_RDATA1		3'b101
//`define ST_WAIT			3'b110

module I2C_Tranceiver(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input				CLK,
	input				I2C_CLK,
	input				RESETn,

	//---------------------------------------------------------------------------
	//	Control Signals
	//---------------------------------------------------------------------------
	input				Start,
	input				Stop,
	input				Repeat,
	input				Mode,

	//---------------------------------------------------------------------------
	//	Write/Read DATA
	//---------------------------------------------------------------------------
	input	[7:0]		I2C_TxDATA,
	output	[7:0]		I2C_RxDATA,

	//---------------------------------------------------------------------------
	//	Status Registers
	//---------------------------------------------------------------------------
	output				I2C_XRDY,
	output				I2C_RRDY,
	input				I2C_XRDY_CLR,
	input				I2C_RRDY_CLR,

	output				I2C_NACK,

	input	[15:0]		I2C_DCNT,

	//---------------------------------------------------------------------------
	//	I2C Signals
	//---------------------------------------------------------------------------
	output				SCL,
	output				SDA_o,
	input				SDA_i,
	output				SDA_OE
);		 
               
//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg		[2:0]	State;
reg 	[7:0]	TxReg;
reg 	[7:0]	TxShiftReg;
reg 	[7:0]	RxReg;
reg 	[7:0]	RxShiftReg;
reg 	[2:0]	iCMD;

reg		[7:0]	iI2C_RxDATA;
reg		[15:0]	iDataWord_Cnt;
reg				iI2C_XRDY;
reg				iI2C_RRDY;
reg				iI2C_NACK;

reg				iRxACK;
reg 			d_iRxACK;

reg				iACK;

reg 	[2:0]	I2C_State;
reg 	[1:0]	I2C_StateCnt;
reg 	[2:0]	iTxBitIndex;
reg 	[2:0]	iRxBitIndex;

reg				iSCL_o;
wire			iSDA_i;
reg				iSDA_o;
reg 			iSDA_OE;


//-------------------------------------------------------------------------------
//	I2C_State Machine
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iI2C_RxDATA		<= 7'd0;
		iCMD			<= 3'd0;
		TxReg			<= 8'd0;
		RxReg			<= 8'd0;
		iRxACK			<= 1'b0;
		d_iRxACK		<= 1'b0;

		iDataWord_Cnt	<= 16'd0;
		iI2C_XRDY		<= 1'b1;
		iI2C_RRDY		<= 1'b0;

		State			<= `ST_IDLE;
	end
	else if(I2C_CLK) begin
		if(State == `ST_IDLE) begin
			if(Start) begin
				if(I2C_XRDY_CLR) begin // if Data is on DXR
					iCMD	<= `CMD_START;
					TxReg	<= I2C_TxDATA; // Address Data is Transmitted
					iI2C_XRDY	<= 1'b0;
					State	<= `ST_WADDR;
				end
			end
		end
		else if(State == `ST_WADDR) begin
			if(iACK) begin
				iI2C_XRDY	<= 1'b1;

				if(I2C_XRDY_CLR) begin // if Data is on DXR
					if(Mode) begin // Transmitter
						iCMD	<= `CMD_WRITE;
						TxReg	<= I2C_TxDATA;
						iDataWord_Cnt	<= 16'd0;
						iI2C_XRDY	<= 1'b0;
						State	<= `ST_WDATA;
					end
					else begin // Receiver
						iCMD		<= `CMD_READ;
						iRxACK		<= 1'b0;
						iI2C_RRDY	<= 1'b0;
						State		<= `ST_RDATA;
					end
				end
			end
		end
		else if(State == `ST_WDATA) begin
			if(iACK) begin
				iI2C_XRDY	<= 1'b1;

				if(I2C_XRDY_CLR) begin // if Data is on DXR
					if(Repeat) begin
						if(Stop) begin
							iCMD	<= `CMD_STOP;
							iI2C_XRDY	<= 1'b0;
							State	<= `ST_IDLE;
						end
						else begin
							TxReg	<= I2C_TxDATA;
							iI2C_XRDY	<= 1'b0;
							iCMD	<= `CMD_WRITE;
						end
					end
					else begin
						if(iDataWord_Cnt == I2C_DCNT) begin
							if(Stop) begin
								iCMD	<= `CMD_STOP;
								iI2C_XRDY	<= 1'b0;
								State	<= `ST_IDLE;
							end
							else begin
								State	<= `ST_IDLE;
								iI2C_XRDY	<= 1'b0;
							end
						end
						else begin
							iDataWord_Cnt <= iDataWord_Cnt + 16'd1;
							iCMD	<= `CMD_WRITE;
							iI2C_XRDY	<= 1'b0;
							TxReg	<= I2C_TxDATA;
						end
					end
				end
			end
		end
		else if(State == `ST_RDATA) begin
			if(iACK) begin
				iI2C_RRDY	<= 1'b1;
				RxReg		<= RxShiftReg;

				if(I2C_RRDY_CLR) begin // if Data is readed by CPU
					if(Repeat) begin
						if(Stop) begin
							iCMD	<= `CMD_STOP;
							State	<= `ST_IDLE;
							iI2C_RRDY	<= 1'b0;
							iRxACK	<= 1'b1;
						end
						else begin
							iCMD	<= `CMD_READ;
							iI2C_RRDY	<= 1'b0;
							//RxReg	<= RxShiftReg;
							iRxACK	<= 1'b0;
						end
					end
					else begin
						if(iDataWord_Cnt == I2C_DCNT) begin
							if(Stop) begin
								iCMD	<= `CMD_STOP;
								iI2C_RRDY	<= 1'b0;
								State	<= `ST_IDLE;
								iRxACK	<= 1'b1;
							end
							else begin
								State	<= `ST_IDLE;
								iI2C_RRDY	<= 1'b0;
								iRxACK	<= 1'b1;
							end
						end
						else begin
							iDataWord_Cnt <= iDataWord_Cnt + 16'd1;
							iCMD	<= `CMD_READ;
							iI2C_RRDY	<= 1'b0;
							//RxReg	<= RxShiftReg;
							iRxACK	<= 1'b0;
						end
					end
				end
			end
		end

		d_iRxACK	<= iRxACK;
	end		
end

//-------------------------------------------------------------------------------
//	I2C Transceiver
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iSCL_o			<= 1'b1;
		iSDA_o			<= 1'b1;
		iSDA_OE			<= 1'b0;
		iTxBitIndex		<= 3'd7;
		iRxBitIndex		<= 3'd7;
		iACK			<= 1'b0;
		TxShiftReg		<= 8'd0;
		RxShiftReg		<= 8'd0;
		I2C_StateCnt	<= 2'd0;
		iI2C_NACK 		<= 1'b0;	

		I2C_State		<= `ST_IDLE;
	end
	else if(I2C_CLK) begin
		if(I2C_State == `ST_IDLE) begin
			if(iCMD == `CMD_START) begin
				I2C_State	<= `ST_START;
			end
			iSDA_OE		<= 1'b0;
			iACK		<= 1'b0;
		end
		else if(I2C_State == `ST_START) begin
			if(I2C_StateCnt == 2'd0) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b1;	

				I2C_StateCnt	<= I2C_StateCnt + 2'd1;			
			end
			else if(I2C_StateCnt == 2'd1) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b1;

				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd2) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b0;

				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd3) begin
				iSCL_o		<= 1'b0;
				iSDA_o		<= 1'b0;
				TxShiftReg	<= TxReg;
				I2C_StateCnt	<= 2'd0;

				I2C_State		<= `ST_WRITE;
			end
			iSDA_OE		<= 1'b1;
			iACK		<= 1'b0;
		end
		else if(I2C_State == `ST_REPSTART) begin
			if(I2C_StateCnt == 2'd0) begin
				iSCL_o		<= 1'b0;
				iSDA_o		<= 1'b1;				
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd1) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b1;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd2) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b0;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd3) begin
				iSCL_o		<= 1'b0;
				iSDA_o		<= 1'b0;
				TxShiftReg	<= TxReg;
				I2C_StateCnt	<= 2'd0;
				I2C_State		<= `ST_WRITE;
			end
			iSDA_OE		<= 1'b1;
			iACK		<= 1'b0;
		end
		else if(I2C_State == `ST_STOP) begin
			if(I2C_StateCnt == 2'd0) begin
				iSCL_o		<= 1'b0;
				iSDA_o		<= 1'b0;				
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd1) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b0;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd2) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b1;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd3) begin
				iSCL_o		<= 1'b1;
				iSDA_o		<= 1'b1;
				I2C_StateCnt	<= 2'd0;
				I2C_State		<= `ST_IDLE;
			end
			iSDA_OE		<= 1'b1;
			iACK		<= 1'b0;
		end
		else if(I2C_State == `ST_WRITE) begin
			if(I2C_StateCnt == 2'd0) begin
				iSCL_o		<= 1'b0;
				iSDA_o		<= TxShiftReg[iTxBitIndex];				
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd1) begin
				iSCL_o		<= 1'b1;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd2) begin
				iSCL_o		<= 1'b1;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd3) begin
				iSCL_o		<= 1'b0;
				I2C_StateCnt	<= 2'd0;
				if(iTxBitIndex == 0) begin
					iTxBitIndex		<= 3'd7;
					I2C_State		<= `ST_TXACK;
				end
				else begin
					iTxBitIndex	<= iTxBitIndex - 3'd1;
				end
			end
			iSDA_OE		<= 1'b1;
			iACK		<= 1'b0;
		end
		else if(I2C_State == `ST_READ) begin
			if(I2C_StateCnt == 2'd0) begin
				iSCL_o		<= 1'b0;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd1) begin
				iSCL_o		<= 1'b1;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd2) begin
				iSCL_o		<= 1'b1;
				RxShiftReg[iRxBitIndex] <= iSDA_i;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd3) begin
				iSCL_o		<= 1'b0;
				I2C_StateCnt	<= 2'd0;
				if(iRxBitIndex == 0) begin
					iRxBitIndex		<= 3'd7;
					I2C_State		<= `ST_RXACK;
				end
				else begin
					iRxBitIndex	<= iRxBitIndex - 3'd1;
				end
			end
			iSDA_OE		<= 1'b0;
			iACK		<= 1'b0;
		end
		else if(I2C_State == `ST_TXACK) begin
			if(I2C_StateCnt == 2'd0) begin
				iSCL_o		<= 1'b0;
				iACK		<= 1'b0;

				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd1) begin
				iSCL_o		<= 1'b1;
				iACK		<= 1'b1;

				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd2) begin
				iSCL_o		<= 1'b1;
				iACK		<= 1'b0;

				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd3) begin
				iSCL_o		<= 1'b0;
				iACK		<= 1'b0;
				I2C_StateCnt	<= 2'd0;
				if(iCMD == `CMD_WRITE) begin
					TxShiftReg	<= TxReg;
				end
				I2C_State		<= iCMD;
			end

			if(iSDA_i) begin
				iI2C_NACK <= 1'b1;	
			end

			iSDA_o		<= 1'b1;
			iSDA_OE		<= 1'b0;
		end
		else if(I2C_State == `ST_RXACK) begin
			if(I2C_StateCnt == 2'd0) begin
				iSCL_o		<= 1'b0;
				iACK		<= 1'b0;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd1) begin
				iSCL_o		<= 1'b1;
				iACK		<= 1'b1;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd2) begin
				iSCL_o		<= 1'b1;
				iACK		<= 1'b0;
				I2C_StateCnt	<= I2C_StateCnt + 2'd1;
			end
			else if(I2C_StateCnt == 2'd3) begin
				iSCL_o		<= 1'b0;
				iACK		<= 1'b0;
				I2C_StateCnt	<= 2'd0;
				//if(iCMD == `CMD_WRITE) begin
					//TxShiftReg	<= TxReg;
				//end
				I2C_State		<= iCMD;
			end
			iSDA_o		<= d_iRxACK;
			iSDA_OE		<= 1'b1;
		end
	end
end

assign I2C_RxDATA = RxReg;
	
assign I2C_XRDY	= iI2C_XRDY;
assign I2C_RRDY = iI2C_RRDY;
assign I2C_NACK	= iI2C_NACK;

assign SCL		= iSCL_o;
assign SDA_o	= iSDA_o;
assign iSDA_i	= SDA_i;

assign SDA_OE	= iSDA_OE;

		
endmodule

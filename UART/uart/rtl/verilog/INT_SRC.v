/****************************************************************************
 *																			*
 *		INT_SRC.v	Ver 0.1													*
 *																			*
 *		COPYRIGHT (C) 2006 ALL RIGHTS RESERVED								*
 *																			*
 *		Designed by	Yoon Dong Joon											*
 *																			*
 ****************************************************************************
 *																			*
 *		Support Verilog 2001 Syntax											*
 *																			*
 *		Update history : 2006.08.25	 original authored (Ver.0.1)			*
 *																			*
 ****************************************************************************/

`timescale 1ns/1ps

module INT_SRC(
	input			CLK,
	input			RESETn,
	input			CLEAR,
	input			ENABLE,
	input			IRQ,
	output	reg		IRQ_REG
);

wire			iRESETn;
reg				iIRQ_D0;
reg				iIRQ_D1;

always @(posedge CLK or negedge RESETn)
begin
	if(!RESETn) begin
		iIRQ_D0	<= 1'b0;
		iIRQ_D1	<= 1'b0;
	end
	else begin
		iIRQ_D0	<= IRQ;
		iIRQ_D1	<= iIRQ_D0;
	end
end

always @(posedge CLK or negedge iRESETn)
begin
	if(!iRESETn) begin
		IRQ_REG	<= 1'b0;
	end
	else if(iIRQ_D0 && !iIRQ_D1) begin
		if(ENABLE)
			IRQ_REG	<= 1'b1;
	end
end

assign iRESETn	= RESETn & !CLEAR;

endmodule

		
		

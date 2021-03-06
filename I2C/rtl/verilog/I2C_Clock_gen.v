/********************************************************************************
 *																				*
 *		I2C_Clock_gen.v  Ver 0.1														*
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

module I2C_Clock_gen(
	//---------------------------------------------------------------------------
	//	Clock Src and Reset Signals
	//---------------------------------------------------------------------------
	input				PLL_CLK,
	input				RESETn,

	//---------------------------------------------------------------------------
	//	Clock Divider	
	//---------------------------------------------------------------------------
	input	[15:0]		CLK_div_N,
	
	//---------------------------------------------------------------------------
	//	Generated I2C Clock
	//---------------------------------------------------------------------------
	output				I2C_CLK
);		 
               
//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg			iI2C_CLK;
reg	[15:0]	iCnt;

//-------------------------------------------------------------------------------
//	I2C Clock Genrerator
//-------------------------------------------------------------------------------
always@(posedge PLL_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		iI2C_CLK	<= 1'b0;
		iCnt		<= 16'd0;
	end
	else begin
		if(iCnt == CLK_div_N[15:0]) begin
			iI2C_CLK	<= 1'b1;
			//iI2C_CLK	<= !iI2C_CLK;
			iCnt		<= 16'd0;
		end 
		else begin
			iI2C_CLK	<= 1'b0;
			iCnt		<= iCnt + 16'd1;
		end
	end
end

assign I2C_CLK = iI2C_CLK;

endmodule

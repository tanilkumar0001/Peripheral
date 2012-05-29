/********************************************************************************
 *																				*
 *		SPI_Clock_gen.v  Ver 0.1														*
 *																				*
 *		Designed by	Yoon Dong Joon                                              *
 *																				*
 ********************************************************************************
 *																				*
 *		Support Verilog 2001 Syntax												*
 *																				*
 *		Update history : 2011.10.29	 original authored (Ver.0.1)				*
 *																				*
 *		Support only Single Master												*
 *																				*
 ********************************************************************************/	

`timescale 1ns/1ps		

module SPI_Clock_gen(
	//---------------------------------------------------------------------------
	//	Clock Src and Reset Signals
	//---------------------------------------------------------------------------
	input	wire			PLL_CLK,
	input	wire			RESETn,

	//---------------------------------------------------------------------------
	//	Clock Divider	
	//---------------------------------------------------------------------------
	input	wire	[15:0]	CLK_div_N,
	
	//---------------------------------------------------------------------------
	//	Generated SPI Clock
	//---------------------------------------------------------------------------
	output	wire			SPI_CLK
);		 
               
//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg			iSPI_CLK;
reg	[15:0]	iCnt;

//-------------------------------------------------------------------------------
//	SPI Clock Genrerator
//-------------------------------------------------------------------------------
always@(posedge PLL_CLK, negedge RESETn) begin
	if(!RESETn) begin
		iSPI_CLK	<= 1'b0;
		iCnt		<= 16'd0;
	end
	else begin
		if(iCnt == CLK_div_N[15:0]) begin
			iSPI_CLK	<= 1'b1;		// Pulse generation
			//iSPI_CLK	<= !iSPI_CLK;	// clock generation
			iCnt		<= 16'd0;
		end 
		else begin
			iSPI_CLK	<= 1'b0;		// Pulse generation
			iCnt		<= iCnt + 16'd1;
		end
	end
end

assign SPI_CLK = iSPI_CLK;

endmodule

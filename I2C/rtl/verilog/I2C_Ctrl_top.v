/********************************************************************************
 *																				*
 *		I2C_Ctrl_top.v  Ver 0.1														*
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

module I2C_Ctrl_top(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input				CLK,
	input				RESETn,

	//---------------------------------------------------------------------------
	//	Master Control Signals
	//---------------------------------------------------------------------------
	input				MST_CEn,
	input	[31:0]		MST_ADDR,
	input	[31:0]		MST_WDATA,
	output	[31:0]		MST_RDATA,
	input				MST_WEn,

	//---------------------------------------------------------------------------
	//	I2C Signals
	//---------------------------------------------------------------------------
	output				SCL,
	inout				SDA
);		 
               
//-------------------------------------------------------------------------------
//	Control Registers
//-------------------------------------------------------------------------------
// I2C Own Address Register
reg		[31:0]	CR_ICOAR;
// I2C Interrupt Mask Register
reg		[31:0]	CR_ICIMR;
// I2C Interrupt Vector Register
reg		[31:0]	CR_ICIVR;
// I2C Interrupt Status Register
reg		[31:0]	CR_ICSTR;
// I2C Clock Divider Register
reg 	[31:0]	CR_ICCDR;
// I2C Data Count Register
reg		[31:0]	CR_ICCNT;
// I2C Data Receive Register
reg		[31:0]	CR_ICDRR;
// I2C Data Transmit Register
reg		[31:0]	CR_ICDXR;
// I2C Slave Address Register
reg		[31:0]	CR_ICSAR;
// I2C Mode Register
reg		[31:0]	CR_ICMDR;

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 	[31:0]	iMST_RDATA;

wire			iIF_XRDY;
wire			iIF_RRDY;
reg				iIF_XRDY_CLR;
reg				iIF_RRDY_CLR;
wire			iIF_NACK;
wire	[7:0]	iIF_RxDATA;

reg				iI2CRST;
wire			iI2C_CLK;
wire			iRESETn;

reg				iStart;
reg				iStop;
reg				iRepeat;
reg				iMode;
reg		[15:0]	iIF_DCNT;


wire			iIFSCL;
wire			iIFSDA_i;
wire			iIFSDA_o;
wire			iIFSDA_OE;

//-------------------------------------------------------------------------------
//	Control Register Value Latch
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		CR_ICOAR	<= 32'b0;
		CR_ICIMR	<= 32'b0;
		CR_ICIVR	<= 32'b0;
		CR_ICSTR	<= 32'b0;
		CR_ICCDR	<= 32'b0;
		CR_ICCNT	<= 32'b0;
		//CR_ICDRR	<= 32'b0;
		CR_ICDXR	<= 32'b0;
		CR_ICSAR	<= 32'b0;
		CR_ICMDR	<= 32'b0;
	end
	else begin
		if(!MST_CEn && !MST_WEn) begin
			case(MST_ADDR[5:2])
				4'b0001 : CR_ICOAR	<= MST_WDATA;
				4'b0010 : CR_ICIMR	<= MST_WDATA;
				4'b0011 : CR_ICIVR	<= MST_WDATA;
				4'b0100 : CR_ICSTR	<= MST_WDATA;
				4'b0101 : CR_ICCDR	<= MST_WDATA;				                                      
				4'b0110 : CR_ICCNT	<= MST_WDATA;      
				//4'b0111 : CR_ICDRR	<= MST_WDATA;	
                4'b1000 : CR_ICDXR	<= MST_WDATA;
                4'b1001 : CR_ICSAR	<= MST_WDATA;
                4'b1010 : CR_ICMDR	<= MST_WDATA;
			endcase
		end
	end
end

//-------------------------------------------------------------------------------
//	Read Operation
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		iMST_RDATA	<= 32'd0;
		CR_ICDRR	<= 32'b0;
	end
	else begin
		if(!MST_CEn && MST_WEn) begin
			CR_ICDRR	<= {24'b0, iIF_RxDATA};
			case(MST_ADDR[5:2])
				4'b0001 : iMST_RDATA	<= CR_ICOAR;
				4'b0010 : iMST_RDATA	<= CR_ICIMR;
				4'b0011 : iMST_RDATA	<= CR_ICIVR;
				4'b0100 : iMST_RDATA	<= CR_ICSTR;
				4'b0101 : iMST_RDATA	<= CR_ICCDR;				                                      
				4'b0110 : iMST_RDATA	<= CR_ICCNT;      
                4'b0111 : iMST_RDATA	<= CR_ICDRR;
                4'b1000 : iMST_RDATA	<= CR_ICDXR;
                4'b1001 : iMST_RDATA	<= CR_ICSAR;
                4'b1010 : iMST_RDATA	<= CR_ICMDR;
			endcase
		end
	end
end

assign MST_RDATA	= iMST_RDATA;

//-------------------------------------------------------------------------------
//	Tx, Rx DATA is on
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		iIF_XRDY_CLR	<= 1'b0;
		iIF_RRDY_CLR	<= 1'b0;
	end
	else begin
		if(!MST_CEn && !MST_WEn && MST_ADDR[5:2]==4'b1000 && iIF_XRDY) begin
			iIF_XRDY_CLR <= 1'b1;
		end

		if(!iIF_XRDY) begin
			iIF_XRDY_CLR <= 1'b0;
		end

		if(!MST_CEn && MST_WEn && MST_ADDR[5:2]==4'b0111 && iIF_RRDY) begin
			iIF_XRDY_CLR <= 1'b1;
		end

		if(!iIF_RRDY) begin
			iIF_RRDY_CLR <= 1'b0;
		end
	end
end

//-------------------------------------------------------------------------------
//	Local Reset Generation
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		iI2CRST <= 1'b0;
	end
	else begin
		if(!CR_ICMDR[3]) begin
			iI2CRST <= 1'b0;
		end
		else begin
			iI2CRST <= 1'b1;
		end
	end
end

assign iRESETn = RESETn && iI2CRST;

//-------------------------------------------------------------------------------
//	I2C Tranceiver Start/Stop/Repeat Signal Generator
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge iRESETn) begin
	if(!iRESETn) begin
		iStart		<= 1'b0;
		iStop		<= 1'b0;
		iRepeat		<= 1'b0;
		iMode		<= 1'b0;
		iIF_DCNT		<= 16'd0;
	end
	else begin
		if(CR_ICMDR[9]) begin
			iStart	<= 1'd1;
		end
		
		if(CR_ICMDR[8]) begin
			iStop	<= 1'd1;
		end

		if(CR_ICMDR[4]) begin
			iRepeat	<= 1'd1;
		end

		if(CR_ICMDR[6]) begin
			iMode <= 1'b1;
		end

		iIF_DCNT <= CR_ICCNT[15:0];

	end
end

//-------------------------------------------------------------------------------
//	I2C Clock Genrerator
//-------------------------------------------------------------------------------
I2C_Clock_gen uI2C_Clock_gen(
	.PLL_CLK	(CLK),	
	.RESETn		(iRESETn),		
	.CLK_div_N	(CR_ICCDR[15:0]),	
	.I2C_CLK	(iI2C_CLK)	
);		 

//-------------------------------------------------------------------------------
//	I2C Tranceiver module
//-------------------------------------------------------------------------------
I2C_Tranceiver uI2C_Tranceiver(
	.CLK			(CLK),	
	.I2C_CLK		(iI2C_CLK),	
	.RESETn			(iRESETn),	

	.Start			(iStart),	
	.Stop			(iStop),
	.Repeat			(iRepeat),
	.Mode			(iMode),

	.I2C_TxDATA		(CR_ICDXR[7:0]),	
	//.I2C_RxDATA		(CR_ICDRR[7:0]),	
	.I2C_RxDATA		(iIF_RxDATA),	

	.I2C_NACK		(iIF_NACK),

	.I2C_XRDY		(iIF_XRDY),
	.I2C_RRDY		(iIF_RRDY),
	.I2C_XRDY_CLR	(iIF_XRDY_CLR),
	.I2C_RRDY_CLR	(iIF_RRDY_CLR),

	.I2C_DCNT		(iIF_DCNT),

	.SCL			(iIFSCL),	
	.SDA_o			(iIFSDA_o),	
	.SDA_i			(iIFSDA_i),	
	.SDA_OE			(iIFSDA_OE)	
);		 

assign SCL = iIFSCL;
assign iIFSDA_i = SDA;
assign SDA = (iIFSDA_OE)? iIFSDA_o:1'bz;

endmodule

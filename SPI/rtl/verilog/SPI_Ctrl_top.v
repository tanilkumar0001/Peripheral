/********************************************************************************
 *																				*
 *		SPI_Ctrl_top.v  Ver 0.1														*
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

module SPI_Ctrl_top(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input	wire				CLK, // Source CLK, Core CLK or Bus CLK
	input	wire				RESETn, // Source RESET, Active low

	//---------------------------------------------------------------------------
	//	Master Control Signals
	//---------------------------------------------------------------------------
	input	wire				MST_CEn,	// Master(core) Chip enable
	input	wire	[31:0]		MST_ADDR,	// Master(core) Address 
	input	wire	[31:0]		MST_WDATA,	// Master(core): Master(core) -> SPI
	output	wire	[31:0]		MST_RDATA,	// Master(core): 2C -> Master(core)
	input	wire				MST_WEn,	// Master(core) Write Enable, Active low

	//---------------------------------------------------------------------------
	//	SPI Signals
	//---------------------------------------------------------------------------
	output	wire				SCLK,
	input 	wire 	 			SDI,
	output	wire				SDO,

	output	wire				SS0,
	output	wire				SS1,
	output	wire				SS2,
	output	wire				SS3
);		 
//-------------------------------------------------------------------------------
//	Local parameters
//-------------------------------------------------------------------------------
localparam	ST_IDLE0	= 2'b00;
localparam	ST_IDLE1	= 2'b01;
localparam	ST_PHASE0	= 2'b10;
localparam	ST_PHASE1	= 2'b11;

//-------------------------------------------------------------------------------
//	Control Registers
//-------------------------------------------------------------------------------
// Serial Peripheral Control Register
//  31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |-----------------------------------------------------------------|-----|--|--|--|--|--|--|--|--|
// |                         reserved								 |  o  |o |o |o |o |o |o |o |o |
// |-----------------------------------------------------------------|-----|--|--|--|--|--|--|--|--|
reg		[31:0]	CR_SPCR;

// Serial Peripheral Status register 
//  31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |-----------------------------------------------------------------------|--|--|-----|--|--|--|--|
// |                         reserved								       |o |o |     |o |o |o |o |
// |-----------------------------------------------------------------------|--|--|-----|--|--|--|--|
reg		[31:0]	CR_SPSR;

// Serial Peripheral Extension register
//  31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |-----------------------------------------------------------------------------------------------|
// |                         reserved                   						                   |
// |-----------------------------------------------------------------------------------------------|
reg		[31:0]	CR_SPER;

// Clock divider register
//  31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |-----------------------------------------------|-----------------------------------------------|
// |                         reserved              |     		clock divide ratio                 |
// |-----------------------------------------------|-----------------------------------------------|
reg		[31:0]	CR_SCDR;

// Data to be transmitted
//  31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |-----------------------------------------------------------------------|-----------------------|
// |                         reserved								       |        Tx data        | 
// |-----------------------------------------------------------------------|-----------------------|
reg		[31:0]	CR_SPDR;

// Data be received
//  31 30 29 28 27 26 25 24 23 22 21 20 19 18 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 00
// |-----------------------------------------------------------------------|-----------------------|
// |                         reserved								       |            Rx data    | 
// |-----------------------------------------------------------------------|-----------------------|
reg		[31:0]	CR_SDRR;

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg 	[31:0]	iMST_RDATA;

wire			iSPI_CLK;
wire			iRESETn;


wire			iSPInt_en;	// Interrupt enable bit
wire			iSPI_en;		// System Enable bit
wire			iMaster;		// Master Mode Select Bit
wire			iCPOL;		// Clock Polarity Bit
wire			iCPHA;		// Clock Phase Bit

wire	[1:0]	iSPI_TCNT; // interrupt on transfer count

reg				iSPIntF;
reg				SPI_int;

reg		[7:0]	iTreg;

reg				iTxFIFO_col;
wire			iTxFIFO_ov;

wire			iTxFIFO_WE;
reg				iTxFIFO_RE;
wire			iTxFIFO_Full;
wire			iTxFIFO_Empty;
wire	[7:0]	iTxFIFO_Dout;

reg				iRxFIFO_WE;
wire			iRxFIFO_RE;
wire			iRxFIFO_Full;
wire			iRxFIFO_Empty;
wire	[7:0]	iRxFIFO_Dout;

reg		[1:0]	State;
reg				iSCLK_o;
reg		[1:0]	iTCnt; // transfer count
wire			iTIRQ;
reg				iSSn;
reg		[2:0]	iBitIndex;

//-------------------------------------------------------------------------------
//	SPI Tranceiver Control Signal Generator
//-------------------------------------------------------------------------------
assign SS0 = (CR_SPCR[9:8]==2'b00)? iSSn : 1'b1;
assign SS1 = (CR_SPCR[9:8]==2'b01)? iSSn : 1'b1;
assign SS2 = (CR_SPCR[9:8]==2'b10)? iSSn : 1'b1;
assign SS3 = (CR_SPCR[9:8]==2'b11)? iSSn : 1'b1;

assign iSPInt_en	= CR_SPCR[7]; 
assign iSPI_en		= CR_SPCR[6]; 
assign iMaster		= CR_SPCR[4];
assign iCPOL		= CR_SPCR[3]; 
assign iCPHA		= CR_SPCR[2]; 
assign iSPI_TCNT 	= CR_SPCR[1:0];

assign iRESETn = RESETn && iSPI_en;

//-------------------------------------------------------------------------------
//	Control Register Value Latch
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		CR_SPCR	<=	32'b0;
		CR_SPSR	<=	32'b0;
		CR_SPER	<=	32'b0;
		CR_SCDR	<=	32'b0;
		CR_SPDR	<=	32'b0;
		CR_SDRR	<=	32'b0;
	end
	else begin
		if(!MST_CEn && !MST_WEn) begin
			case(MST_ADDR[4:2])
				3'b000 : CR_SPCR	<= MST_WDATA | 32'h00000010; // always set master bit
				3'b001 : CR_SPSR	<= MST_WDATA;
				3'b010 : CR_SPER	<= MST_WDATA;
				3'b011 : CR_SCDR	<= MST_WDATA;
				3'b100 : CR_SPDR	<= MST_WDATA;
				//3'b101 : CR_SDRR	<= MST_WDATA; //read only
			endcase
		end
		else begin

			//CR_SPDR[7:0]	<= iRxFIFO_Dout;
			CR_SDRR[7:0]	<= iRxFIFO_Dout;

			if(iSPIntF) begin
				CR_SPSR[7]	<= 1'b1;
			end
			else begin
				CR_SPSR[7]	<= 1'b0;
			end

			if(iTxFIFO_col) begin
				CR_SPSR[6]	<= 1'b1;
			end
			else begin
				CR_SPSR[6]	<= 1'b0;
			end	
			
			if(iTxFIFO_Full) begin
				CR_SPSR[3]	<= 1'b1;
			end
			else begin
				CR_SPSR[3]	<= 1'b0;
			end
		
			if(iTxFIFO_Empty) begin
				CR_SPSR[2]	<= 1'b1;
			end
			else begin
				CR_SPSR[2]	<= 1'b0;
			end
		
			if(iRxFIFO_Full) begin
				CR_SPSR[1]	<= 1'b1;
			end
			else begin
				CR_SPSR[1]	<= 1'b0;
			end
		
			if(iRxFIFO_Empty) begin
				CR_SPSR[0]	<= 1'b1;
			end
			else begin
				CR_SPSR[0]	<= 1'b0;
			end
	
		end
	end
end

//-------------------------------------------------------------------------------
//	Read Operation
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		iMST_RDATA	<= 32'd0;
	end
	else begin
		if(!MST_CEn && MST_WEn) begin
			case(MST_ADDR[4:2])
				3'b000 : iMST_RDATA	<= CR_SPCR;
				3'b001 : iMST_RDATA	<= CR_SPSR;
				3'b010 : iMST_RDATA	<= CR_SPER;
				3'b011 : iMST_RDATA	<= CR_SCDR;
				3'b100 : iMST_RDATA	<= CR_SPDR;
				3'b101 : iMST_RDATA	<= CR_SDRR;
			endcase
		end
	end
end
	
assign MST_RDATA	= iMST_RDATA;

//-------------------------------------------------------------------------------
//	Generate status register & Interrupt
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge iRESETn) begin
	if(!iRESETn) begin
		iSPIntF	<= 1'b0;
		iTxFIFO_col	<= 1'b0;
	end
	else begin
		if(!MST_CEn && !MST_WEn && MST_ADDR[4:2]==3'b001 && MST_WDATA[7]) begin
			iSPIntF	<= 1'b0;
		end
		else begin
			iSPIntF	<= (iTIRQ || iSPIntF);
		end

		if(!MST_CEn && !MST_WEn && MST_ADDR[4:2]==3'b001 && MST_WDATA[6]) begin
			iTxFIFO_col	<= 1'b0;
		end
		else begin
			iTxFIFO_col	<= (iTxFIFO_ov|| iTxFIFO_col);
		end
	end
end

always@(posedge CLK) begin
	SPI_int	<=	iSPIntF && iSPI_en;
end

//-------------------------------------------------------------------------------
//	SPI Pulse Genrerator
//-------------------------------------------------------------------------------
SPI_Clock_gen uSPI_Clock_gen(
	.PLL_CLK	(CLK),	
	.RESETn		(iRESETn),		
	.CLK_div_N	(CR_SCDR[15:0]),	
	.SPI_CLK	(iSPI_CLK)	
);		 

//-------------------------------------------------------------------------------
//	SPI RxFIFO
//-------------------------------------------------------------------------------
fifo4 #(8) RxFIFO(
	.clk   ( CLK	),
	.rst   ( iRESETn),
	.clr   ( !iSPI_en ),
	.din   ( iTreg	),
	.we    ( iRxFIFO_WE),
	.dout  ( iRxFIFO_Dout  ),
	.re    ( iRxFIFO_RE    ),
	.full  ( iRxFIFO_Full  ),
	.empty ( iRxFIFO_Empty )
  );

assign iRxFIFO_RE = !MST_CEn && MST_WEn && (MST_ADDR[4:2] == 3'b101);

//-------------------------------------------------------------------------------
//	SPI TxFIFO
//-------------------------------------------------------------------------------
fifo4 #(8) TxFIFO(
	.clk   ( CLK	),
	.rst   ( iRESETn),
	.clr   ( !iSPI_en    ),
	.din   ( MST_WDATA[7:0]	),
	.we    ( iTxFIFO_WE),
	.dout  ( iTxFIFO_Dout  ),
	.re    ( iTxFIFO_RE    ),
	.full  ( iTxFIFO_Full  ),
	.empty ( iTxFIFO_Empty )
  );

assign iTxFIFO_WE = !MST_CEn && !MST_WEn && (MST_ADDR[4:2] == 3'b100);
assign iTxFIFO_ov = iTxFIFO_WE && iTxFIFO_Full;

//-------------------------------------------------------------------------------
//	SPI State machine
//-------------------------------------------------------------------------------
always @(posedge CLK, negedge iRESETn) begin
    if (!iRESETn) begin
          iBitIndex		<= 3'd7;
          iTreg			<= 8'd0;
          iTxFIFO_RE 	<= 1'b0;
          iRxFIFO_WE	<= 1'b0;
 		  iSCLK_o		<= 1'b0;
		  iSSn			<= 1'b0;
		  State			<= ST_IDLE0;
	end
    else begin
		if(State==ST_IDLE0) begin
			if (!iTxFIFO_Empty) begin
				iTxFIFO_RE  <= 1'b1;
				iRxFIFO_WE	<= 1'b0;
				iSCLK_o 	<= iCPOL;
				iSSn		<= 1'b1;
				iBitIndex	<= 3'd7; 
				State <= ST_IDLE1;
			end
			else begin
				iBitIndex	<= 3'd7;   
				iSCLK_o 	<= iCPOL; 
				iSSn		<= 1'b1;
				iBitIndex	<= 3'd7; 
				iTxFIFO_RE	<= 1'b0;
				iRxFIFO_WE	<= 1'b0;
			end
		end
		else if(State==ST_IDLE1) begin
			if(iSPI_CLK) begin
				if (!iTxFIFO_Empty) begin
					if (iCPHA)  begin
						iSCLK_o <= !iSCLK_o;
					end
					iTreg		<= iTxFIFO_Dout; 
					iSSn		<= 1'b0;
					iBitIndex	<= 3'd7;   // set transfer counter
					iTxFIFO_RE  <= 1'b0;
					iRxFIFO_WE	<= 1'b0;
					State <= ST_PHASE0;
				end
			end
			else begin
				iBitIndex	<= 3'd7;   // set transfer counter
				iSSn		<= 1'b1;
				iSCLK_o 	<= iCPOL;   // set sck
				iTxFIFO_RE	<= 1'b0;
				iRxFIFO_WE	<= 1'b0;
			end
		end
		else if(State==ST_PHASE0) begin
			if(iSPI_CLK) begin
				iSCLK_o <= !iSCLK_o;
				State	<= ST_PHASE1;
			end
		end
		else if(State==ST_PHASE1) begin
			if(iSPI_CLK) begin
				if(iBitIndex==3'd0) begin
					 iSCLK_o	<= iCPOL;
					 //iTreg		<= 8'd0;
					 iRxFIFO_WE	<= 1'b1;
					 iSSn		<= 1'b1;
					 State		<= ST_IDLE0;
				end
				else begin
					 iBitIndex	<= iBitIndex - 3'd1;
					 iTreg		<= {iTreg[6:0], SDI};
					 iSCLK_o	<= !iSCLK_o;
					 iSSn		<= 1'b0;
					 State		<= ST_PHASE0;
				end
			end
		end
	end
end

assign SDO = iTreg[7];
assign SCLK = iSCLK_o;

//-------------------------------------------------------------------------------
//	count number of transfers (for interrupt generation)
//-------------------------------------------------------------------------------
always @(posedge CLK, negedge iRESETn) begin
	if (!iRESETn) begin
		iTCnt <= iSPI_TCNT;
	end
	else begin
		if(iTCnt) begin
			iTCnt <= iTCnt - 2'd1;
		end
		else begin
			iTCnt <= iSPI_TCNT;
		end
	end
end

assign iTIRQ = (iTCnt==2'd0) && iRxFIFO_WE;

endmodule

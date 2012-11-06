/********************************************************************************
 *																				*
 *		Uart_TB.v  Ver 0.1														*
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

module Uart_TB(

);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
reg  			UART0_CLK;
reg 			RESETn;

reg 			DSP0_CLK;
reg 			DSP0_CEn;
reg 	[4:1]	DSP0_ADDR;
reg 	[15:0]	DSP0_WDATA;
wire	[15:0]	DSP0_RDATA;
reg 			DSP0_WEn;
	
wire			TXD0;
wire 			RXD0;

wire			IRQn0;

wire  			UART1_CLK;

wire 			DSP1_CLK;
reg 			DSP1_CEn;
reg 	[4:1]	DSP1_ADDR;
reg 	[15:0]	DSP1_WDATA;
wire	[15:0]	DSP1_RDATA;
reg 			DSP1_WEn;
	
wire			TXD1;
wire			RXD1;

wire			IRQn1;

reg		[7:0]	iCnt;

//-------------------------------------------------------------------------------
//	UART0
//-------------------------------------------------------------------------------
Uart uUart0(
	.UART_CLK		(UART0_CLK),
	.RESETn			(RESETn),
                                
	.DSP_CLK		(DSP0_CLK),
	.DSP_CEn		(DSP0_CEn),
	.DSP_ADDR		(DSP0_ADDR),
	.DSP_WDATA		(DSP0_WDATA),
	.DSP_RDATA		(DSP0_RDATA),
	.DSP_WEn		(DSP0_WEn),
	                            
	.TXD			(TXD0),
	.RXD			(RXD0),
                                
	.IRQn			(IRQn0)
);

//-------------------------------------------------------------------------------
//	UART1
//-------------------------------------------------------------------------------
Uart uUart1(
	.UART_CLK		(UART1_CLK),
	.RESETn			(RESETn),
                                
	.DSP_CLK		(DSP1_CLK),
	.DSP_CEn		(DSP1_CEn),
	.DSP_ADDR		(DSP1_ADDR),
	.DSP_WDATA		(DSP1_WDATA),
	.DSP_RDATA		(DSP1_RDATA),
	.DSP_WEn		(DSP1_WEn),
	                            
	.TXD			(TXD1),
	.RXD			(RXD1),
                                
	.IRQn			(IRQn1)
);

//---------------------------------------------------------------------------
//	Initialize & Clock, Reset Generation
//---------------------------------------------------------------------------
initial
begin
			UART0_CLK	<= 1'b0;
			RESETn		<= 1'b0;
			DSP0_CLK	<= 1'b0;
			
	#500	RESETn		<= 1'b1;
end 

always      
	#33.908420139		UART0_CLK	<= !UART0_CLK;	

always      
//	#10		DSP0_CLK	<= !DSP0_CLK;	
	#25.431		DSP0_CLK	<= !DSP0_CLK;	
		
assign UART1_CLK	= UART0_CLK;
	
assign DSP1_CLK		= DSP0_CLK;
	
assign 	RXD1	= TXD0;
assign 	RXD0	= TXD1;

//---------------------------------------------------------------------------
//	DSP0 Operations
//---------------------------------------------------------------------------
`define DSP_IDLE	3'b000
`define DSP_INIT	3'b001
`define DSP_IRQ		3'b010
`define DSP_TX		3'b011
`define DSP_RX		3'b100

wire	[19:0]	DSP_IDATA[0:4];

assign DSP_IDATA[0] = {4'd7, 16'h0008};		// IBRD
assign DSP_IDATA[1] = {4'd1, 16'h003D};		// LCR
assign DSP_IDATA[2] = {4'd2, 16'h00CC};		// FCR
assign DSP_IDATA[3] = {4'd5, 16'h000F};		// IER
assign DSP_IDATA[4] = {4'd3, 16'h0007};		// CR

reg 	[2:0]	DSP0_State;
reg 			DSP0_Init;
reg		[7:0]	DSP0_BusCnt;
reg		[3:0]	UART0_ISR;
reg		[7:0]	UART0_FR;
reg				d0_IRQn0;
reg		[7:0]	iTxData0;


always@(posedge DSP0_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		DSP0_CEn	<= 1'b1;
		DSP0_ADDR	<= 4'd0; 
		DSP0_WDATA	<= 16'd0; 
		DSP0_WEn	<= 1'b1;  
		DSP0_BusCnt	<= 8'd0;
		DSP0_Init	<= 1'b0;
		d0_IRQn0	<= 1'b1;
		iTxData0	<= 8'd1;
		DSP0_State	<= `DSP_IDLE;
	end
	else begin       
		d0_IRQn0	<= IRQn0;
		if(!IRQn0 && d0_IRQn0) begin
			DSP0_CEn	<= 1'b0;
			DSP0_ADDR	<= 4'd6; 
			DSP0_WEn	<= 1'b1;  
			DSP0_BusCnt	<= 8'd0;
			DSP0_State	<= `DSP_IRQ;	
		end
		else if(DSP0_State == `DSP_IDLE) begin   
			if(!DSP0_Init) begin
				DSP0_CEn	<= 1'b0;
				DSP0_ADDR	<= DSP_IDATA[0][19:16]; 
				DSP0_WDATA	<= DSP_IDATA[0][15:0]; 
				DSP0_WEn	<= 1'b0;  
				DSP0_BusCnt	<= 8'd1;
				DSP0_Init	<= 1'b1;
				DSP0_State	<= `DSP_INIT;
			end
		end
		else if(DSP0_State == `DSP_INIT) begin
			if(DSP0_BusCnt == 5) begin
				DSP0_CEn	<= 1'b1;
				DSP0_ADDR	<= 4'd0; 
				DSP0_WDATA	<= 16'd0; 
				DSP0_WEn	<= 1'b1;  
				DSP0_BusCnt	<= 8'd0;
				DSP0_State	<= `DSP_IDLE;
			end
			else begin
				DSP0_ADDR	<= DSP_IDATA[DSP0_BusCnt][19:16]; 
				DSP0_WDATA	<= DSP_IDATA[DSP0_BusCnt][15:0]; 
				DSP0_BusCnt	<= DSP0_BusCnt + 1;	
			end			
		end
		else if(DSP0_State == `DSP_IRQ) begin
			if(DSP0_BusCnt == 0) begin
				DSP0_CEn	<= 1'b1;
				DSP0_ADDR	<= 4'd0;
				DSP0_WDATA	<= 16'd0;
				DSP0_WEn	<= 1'b1;
				DSP0_BusCnt	<= DSP0_BusCnt + 1;	
			end
			else if(DSP0_BusCnt == 1) begin
				UART0_ISR	<= DSP0_RDATA[3:0];
				DSP0_BusCnt	<= DSP0_BusCnt + 1;
			end 
			else if(DSP0_BusCnt == 2) begin
				DSP0_CEn	<= 1'b0;
				DSP0_ADDR	<= 4'd6;
				DSP0_WDATA	<= {12'd0, UART0_ISR};
				DSP0_WEn	<= 1'b0;
				DSP0_BusCnt	<= DSP0_BusCnt + 1;
			end
			else if(DSP0_BusCnt == 3) begin
				DSP0_CEn	<= 1'b1;
				DSP0_ADDR	<= 4'd0;
				DSP0_WDATA	<= 16'd0;
				DSP0_WEn	<= 1'b1;
				DSP0_BusCnt	<= DSP0_BusCnt + 1;	
			end
			else if(DSP0_BusCnt == 4) begin
				if(UART0_ISR[3] && iTxData0 < 100) begin
					DSP0_CEn	<= 1'b0;
					DSP0_ADDR	<= 4'd0;
					DSP0_WDATA	<= {8'd0, iTxData0};
					DSP0_WEn	<= 1'b0;
					iTxData0	<= iTxData0 + 1;
					DSP0_BusCnt	<= 8'd0;
					DSP0_State	<= `DSP_TX;
				end
				else begin
					DSP0_State	<= `DSP_IDLE;
				end
			end
		end     
		else if(DSP0_State == `DSP_TX) begin
			if(DSP0_BusCnt == 0) begin
				DSP0_CEn	<= 1'b1;
				DSP0_ADDR	<= 4'd0;
				DSP0_WDATA	<= 16'd0;
				DSP0_WEn	<= 1'b1;
				DSP0_BusCnt	<= DSP0_BusCnt + 1;	
			end
			else if(DSP0_BusCnt == 1) begin
				DSP0_CEn	<= 1'b0;
				DSP0_ADDR	<= 4'd4;
				DSP0_WEn	<= 1'b1;
				DSP0_BusCnt	<= DSP0_BusCnt + 1;	
			end
			else if(DSP0_BusCnt == 2) begin
				DSP0_CEn	<= 1'b1;
				DSP0_ADDR	<= 4'd0;
				DSP0_WEn	<= 1'b1;
				DSP0_BusCnt	<= DSP0_BusCnt + 1;	
			end
			else if(DSP0_BusCnt == 3) begin
				UART0_FR	<= DSP0_RDATA[7:0];
				DSP0_CEn	<= 1'b1;
				DSP0_ADDR	<= 4'd0;
				DSP0_WEn	<= 1'b1;
				DSP0_BusCnt	<= DSP0_BusCnt + 1;	
			end
			else if(DSP0_BusCnt == 4) begin
				if(!UART0_FR[7]) begin
					DSP0_CEn	<= 1'b0;
					DSP0_ADDR	<= 4'd0;
					DSP0_WDATA	<= iTxData0;
					DSP0_WEn	<= 1'b0;
					iTxData0	<= iTxData0 + 1;
					DSP0_BusCnt	<= 8'd0;	
				end
				else begin
					DSP0_CEn	<= 1'b1;
					DSP0_ADDR	<= 4'd0; 
					DSP0_WDATA	<= 16'd0; 
					DSP0_WEn	<= 1'b1;  
					DSP0_BusCnt	<= 8'd0;
					DSP0_State	<= `DSP_IDLE;
				end
			end
		end
		else if(DSP0_State == `DSP_RX) begin
			
		end
	end 
end     

//---------------------------------------------------------------------------
//	DSP1 Operations
//---------------------------------------------------------------------------
reg 	[2:0]	DSP1_State;
reg 			DSP1_Init;
reg		[7:0]	DSP1_BusCnt;
reg		[3:0]	UART1_ISR;
reg		[7:0]	UART1_FR;
reg				d0_IRQn1;
reg		[7:0]	iRxData1;


always@(posedge DSP1_CLK, negedge RESETn)
begin
	if(!RESETn) begin
		DSP1_CEn	<= 1'b1;
		DSP1_ADDR	<= 4'd0; 
		DSP1_WDATA	<= 16'd0; 
		DSP1_WEn	<= 1'b1;  
		DSP1_BusCnt	<= 8'd0;
		DSP1_Init	<= 1'b0;
		d0_IRQn1	<= 1'b1;
		iRxData1	<= 8'd1;
		DSP1_State	<= `DSP_IDLE;
	end
	else begin       
		d0_IRQn1	<= IRQn1;
		if(!IRQn1 && d0_IRQn1) begin
			DSP1_CEn	<= 1'b0;
			DSP1_ADDR	<= 4'd6; 
			DSP1_WEn	<= 1'b1;  
			DSP1_BusCnt	<= 8'd0;
			DSP1_State	<= `DSP_IRQ;	
		end
		else if(DSP1_State == `DSP_IDLE) begin   
			if(!DSP1_Init) begin
				DSP1_CEn	<= 1'b0;
				DSP1_ADDR	<= DSP_IDATA[0][19:16]; 
				DSP1_WDATA	<= DSP_IDATA[0][15:0]; 
				DSP1_WEn	<= 1'b0;  
				DSP1_BusCnt	<= 8'd1;
				DSP1_Init	<= 1'b1;
				DSP1_State	<= `DSP_INIT;
			end
		end
		else if(DSP1_State == `DSP_INIT) begin
			if(DSP1_BusCnt == 5) begin
				DSP1_CEn	<= 1'b1;
				DSP1_ADDR	<= 4'd0; 
				DSP1_WDATA	<= 16'd0; 
				DSP1_WEn	<= 1'b1;  
				DSP1_BusCnt	<= 8'd0;
				DSP1_State	<= `DSP_IDLE;
			end
			else begin
				DSP1_ADDR	<= DSP_IDATA[DSP1_BusCnt][19:16]; 
				DSP1_WDATA	<= DSP_IDATA[DSP1_BusCnt][15:0]; 
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end			
		end
		else if(DSP1_State == `DSP_IRQ) begin
			if(DSP1_BusCnt == 0) begin
				DSP1_CEn	<= 1'b1;
				DSP1_ADDR	<= 4'd0;
				DSP1_WDATA	<= 16'd0;
				DSP1_WEn	<= 1'b1;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end
			else if(DSP1_BusCnt == 1) begin
				UART1_ISR	<= DSP1_RDATA[3:0];
				DSP1_BusCnt	<= DSP1_BusCnt + 1;
			end 
			else if(DSP1_BusCnt == 2) begin
				DSP1_CEn	<= 1'b0;
				DSP1_ADDR	<= 4'd6;
				DSP1_WDATA	<= {12'd0, UART1_ISR};
				DSP1_WEn	<= 1'b0;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;
			end
			else if(DSP1_BusCnt == 3) begin
				DSP1_CEn	<= 1'b1;
				DSP1_ADDR	<= 4'd0;
				DSP1_WDATA	<= 16'd0;
				DSP1_WEn	<= 1'b1;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end
			else if(DSP1_BusCnt == 4) begin
				if(UART1_ISR[2] || UART1_ISR[1]) begin
					DSP1_CEn	<= 1'b0;
					DSP1_ADDR	<= 4'd0;
					DSP1_WEn	<= 1'b1;
					DSP1_BusCnt	<= 8'd0;
					DSP1_State	<= `DSP_RX;
				end
				else begin
					DSP1_State	<= `DSP_IDLE;  
				end
			end
		end     
		else if(DSP1_State == `DSP_TX) begin

		end
		else if(DSP1_State == `DSP_RX) begin
			if(DSP1_BusCnt == 0) begin
				DSP1_CEn	<= 1'b1;
				DSP1_ADDR	<= 4'd0;
				DSP1_WDATA	<= 16'd0;
				DSP1_WEn	<= 1'b1;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end
			else if(DSP1_BusCnt == 1) begin
				iRxData1	<= DSP1_RDATA[7:0];
				DSP1_CEn	<= 1'b1;
				DSP1_ADDR	<= 4'd0;
				DSP1_WEn	<= 1'b1;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end
			else if(DSP1_BusCnt == 2) begin
				DSP1_CEn	<= 1'b0;
				DSP1_ADDR	<= 4'd4;
				DSP1_WEn	<= 1'b1;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end
			else if(DSP1_BusCnt == 3) begin
				DSP1_CEn	<= 1'b1;
				DSP1_ADDR	<= 4'd0;
				DSP1_WEn	<= 1'b1;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end
			else if(DSP1_BusCnt == 4) begin
				UART1_FR	<= DSP1_RDATA[7:0];
				DSP1_CEn	<= 1'b1;
				DSP1_ADDR	<= 4'd0;
				DSP1_WEn	<= 1'b1;
				DSP1_BusCnt	<= DSP1_BusCnt + 1;	
			end
			else if(DSP1_BusCnt == 5) begin
				if(!UART1_FR[4]) begin
					DSP1_CEn	<= 1'b0;
					DSP1_ADDR	<= 4'd0;
					DSP1_WEn	<= 1'b1;
					DSP1_BusCnt	<= 8'd0;	
				end
				else begin
					DSP1_CEn	<= 1'b1;
					DSP1_ADDR	<= 4'd0; 
					DSP1_WEn	<= 1'b1;  
					DSP1_BusCnt	<= 8'd0;
					DSP1_State	<= `DSP_IDLE;
				end
			end
		end
	end 
end     
        
endmodule

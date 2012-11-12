/********************************************************************************
 *																				*
 *		Uart.v  Ver 0.1															*
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

module Uart(
	//---------------------------------------------------------------------------
	//	Clock and Reset Signals
	//---------------------------------------------------------------------------
	input 	wire			PCLK,
	input 	wire			UART_CLK,
	input	wire			RESETn,

	//---------------------------------------------------------------------------
	//	APB Interface
	//---------------------------------------------------------------------------
	input	wire			PSEL,
	input	wire			PENABLE,
	input	wire			PWRITE,
	input	wire	[31:0]	PADDR,
	input	wire	[31:0]	PWDATA,
	output	wire	[31:0]	PRDATA,
   
	// simple SRAM interface
	//input			DSP_CLK,
	//input			DSP_CEn,
	//input	[4:1]	DSP_ADDR,
	//input	[15:0]	DSP_WDATA,
	//output	[15:0]	DSP_RDATA,
	//input			DSP_WEn,
		
	//---------------------------------------------------------------------------
	//	UART Tx/Rx Signals
	//---------------------------------------------------------------------------
	output	wire			TXD,
	input	wire			RXD,

	//---------------------------------------------------------------------------
	//	UART IRQ Signals
	//---------------------------------------------------------------------------	
	output	wire			IRQn
);

//-------------------------------------------------------------------------------
//	Internal Signals
//-------------------------------------------------------------------------------
wire	[31:0]	iPRDATA_CR;
wire	[31:0]	iPRDATA_RxFIFO;
wire	[31:0]	iPRDATA_INTC;

wire	[1:0]	iParity;		
wire			iStopBits;	
wire	[2:0]	iDataBits;	
wire			iFIFOEn;		

wire			iUARTEn;
wire			iRxEn;
wire			iTxEn;
                            
wire	[3:0]	iRxFIFOL;		
wire	[3:0]	iTxFIFOL;		
                            
wire	[31:0]	iIBRDVal;		
wire	[31:0]	iFBRDVal;		
                            
wire			iParityError;	
wire			iFrameError;	
wire			iOverrunError;
                            
wire			iRxFIFO_Empty;
wire			iRxFIFO_Full;	
wire			iTxFIFO_Empty;
wire			iTxFIFO_Full;	

wire			iBaud16;

wire	[7:0]	iRxData;

wire			iRxBusy;
wire			iRxDone;
wire			iRxTimeOut;


wire			iRxFIFO_L14_Full; 
wire			iRxFIFO_L12_Full; 
wire			iRxFIFO_L8_Full;	
wire			iRxFIFO_L4_Full;	
wire			iRxFIFO_L2_Full;	

wire			iTxDataReady;
wire	[7:0]	iTxData;
wire 			iTxBusy;
wire 			iTxDone;

wire			iTxFIFO_L14_Full;	    
wire			iTxFIFO_L12_Full;    
wire			iTxFIFO_L8_Full;	    
wire			iTxFIFO_L4_Full;	    
wire			iTxFIFO_L2_Full;	 


wire	[3:0]	iPADDR;
reg		[3:0]	d0_PADDR;


//-------------------------------------------------------------------------------
//	UART Control Register
//-------------------------------------------------------------------------------
UartReg uUartReg(
	.RESETn				(RESETn),
	
	.DSP_CLK			(PCLK),
	.DSP_CEn			(!PSEL),
	.DSP_ADDR			(iPADDR),
	.DSP_WDATA			(PWDATA),
	.DSP_RDATA			(iPRDATA_CR),
	.DSP_WEn			(!PWRITE),
	
	.Parity				(iParity),
	.StopBits			(iStopBits),
	.DataBits			(iDataBits),
	.FIFOEn				(iFIFOEn),
	
	.UARTEn				(iUARTEn),
	.RxEn				(iRxEn),	
	.TxEn				(iTxEn),
	
	.RxFIFOL			(iRxFIFOL),
	.TxFIFOL			(iTxFIFOL),
	
	.IBRDVal			(iIBRDVal),
	.FBRDVal			(iFBRDVal),
	
	.ParityError		(iParityError),
	.FrameError			(iFrameError),
	.OverrunError		(iOverrunError),
	
	.RxFIFO_Empty		(iRxFIFO_Empty),
	.RxFIFO_Full		(iRxFIFO_Full),
	.TxFIFO_Empty		(iTxFIFO_Empty),
	.TxFIFO_Full		(iTxFIFO_Full)
);

//-------------------------------------------------------------------------------
//	BaudRate Ganerator
//-------------------------------------------------------------------------------
BaudRateGen uBaudRateGen(
	.CLK				(UART_CLK),
	.RESETn				(RESETn),
	
	.IBRD				(iIBRDVal),
	.FBRD				(iFBRDVal),
	.En					(iUARTEn),
	
	.Baud16				(iBaud16)
);

//-------------------------------------------------------------------------------
//	RX Controller
//-------------------------------------------------------------------------------      
UartRxCtrl uUartRxCtrl(
	.CLK				(UART_CLK),
	.RESETn				(RESETn),
	                	
	.Baud16				(iBaud16),
	.RxEn				(iUARTEn & iRxEn),
	                	
	.DataBits			(iDataBits),
	.Parity				(iParity),
	.StopBits			(iStopBits),
	                	
	.RXD				(RXD),
	                	
	.RxData				(iRxData),
	                	
	.RxBusy				(iRxBusy),
	.RxDone				(iRxDone),
	.RxTimeOut			(iRxTimeOut),
	.ParityError		(iParityError),
	.FrameError			(iFrameError)
);

//-------------------------------------------------------------------------------
//	RX FIFO Controller
//-------------------------------------------------------------------------------  
UartRxFIFOCtrl uUartRxFIFOCtrl(
	.RESETn				(RESETn),
	
	.DSP_CLK			(PCLK),
	.DSP_CEn			(!PSEL),   
	.DSP_ADDR			(iPADDR),
	.DSP_RDATA			(iPRDATA_RxFIFO),
	.DSP_WEn			(!PWRITE),
	
	.FIFOEn				(iFIFOEn),
	
	.RxBusy				(iRxBusy),
	.RxDone				(iRxDone),
	.RxData				(iRxData),
	
	.OverrunError		(iOverrunError),
	
	.RxFIFO_Empty		(iRxFIFO_Empty),		
	.RxFIFO_Full		(iRxFIFO_Full),		    
	.RxFIFO_L14_Full	(iRxFIFO_L14_Full),	    
	.RxFIFO_L12_Full	(iRxFIFO_L12_Full),	    
	.RxFIFO_L8_Full		(iRxFIFO_L8_Full),	    
	.RxFIFO_L4_Full		(iRxFIFO_L4_Full),	    
	.RxFIFO_L2_Full		(iRxFIFO_L2_Full)	    
);

//-------------------------------------------------------------------------------
//	TX Controller
//-------------------------------------------------------------------------------   

UartTxCtrl uUartTxCtrl(
	.CLK				(UART_CLK),
	.RESETn				(RESETn),
	                	
	.Baud16				(iBaud16),
	.TxEn				(iUARTEn & iTxEn),
	                	
	.DataBits			(iDataBits),
	.Parity				(iParity),
	.StopBits			(iStopBits),
	                	
	.TxDataReady		(iTxDataReady),
	.TxData				(iTxData),
	                	
                    	
	.TXD				(TXD),
	.TxBusy				(iTxBusy),
	.TxDone				(iTxDone)
);

//-------------------------------------------------------------------------------
//	TX FIFO Controller
//-------------------------------------------------------------------------------   
UartTxFIFOCtrl uUartTxFIFOCtrl(
	.RESETn				(RESETn),
	                                    
	.DSP_CLK			(PCLK),
	.DSP_CEn			(!PSEL),
	.DSP_ADDR			(iPADDR),
	.DSP_WDATA			(PWDATA),
	.DSP_WEn			(!PWRITE),
	                                    
	.FIFOEn				(iFIFOEn),
	                                    
	.TxBusy				(iTxBusy),
	.TxDone				(iTxDone),
	.TxDataReady		(iTxDataReady),
	.TxData				(iTxData),
	                                    
	.TxFIFO_Empty		(iTxFIFO_Empty),		
	.TxFIFO_Full		(iTxFIFO_Full),		    
	.TxFIFO_L14_Full	(iTxFIFO_L14_Full),	    
	.TxFIFO_L12_Full	(iTxFIFO_L12_Full),	    
	.TxFIFO_L8_Full		(iTxFIFO_L8_Full),	    
	.TxFIFO_L4_Full		(iTxFIFO_L4_Full),	    
	.TxFIFO_L2_Full		(iTxFIFO_L2_Full)	 
);

//-------------------------------------------------------------------------------
//	UART Interrupt Controller
//-------------------------------------------------------------------------------  
UartIntCtrl uUartIntCtrl(
	.RESETn				(RESETn),
	
	.DSP_CLK			(PCLK),
	.DSP_CEn			(!PSEL),
	.DSP_ADDR			(iPADDR),
	.DSP_WDATA			(PWDATA),
	.DSP_RDATA			(iPRDATA_INTC),
	.DSP_WEn			(!PWRITE),
	
	.RxFIFOL			(iRxFIFOL),
	.TxFIFOL			(iTxFIFOL),
	
	.RxTimeOut			(iRxTimeOut),
	.ParityError		(iParityError),
	.FrameError			(iFrameError),
	.OverrunError		(iOverrunError),
	
	.RxFIFO_Empty		(iRxFIFO_Empty),
	.RxFIFO_L14_Full	(iRxFIFO_L14_Full),	
	.RxFIFO_L12_Full	(iRxFIFO_L12_Full),	
	.RxFIFO_L8_Full		(iRxFIFO_L8_Full),	  
	.RxFIFO_L4_Full		(iRxFIFO_L4_Full),	  
	.RxFIFO_L2_Full		(iRxFIFO_L2_Full),
	
	.TxFIFO_L14_Full	(iTxFIFO_L14_Full),	
	.TxFIFO_L12_Full	(iTxFIFO_L12_Full),	
	.TxFIFO_L8_Full		(iTxFIFO_L8_Full),	  
	.TxFIFO_L4_Full		(iTxFIFO_L4_Full),	  
	.TxFIFO_L2_Full		(iTxFIFO_L2_Full),
	
	.nIRQ				(IRQn)	  
);

//-------------------------------------------------------------------------------  
//	UART Read Bus Controller                                                      
//-------------------------------------------------------------------------------  
assign	iPADDR = PADDR[5:2];

always@(posedge PCLK, negedge RESETn)
begin
	if(!RESETn) begin
		d0_PADDR	<= 4'd0;
	end
	else begin
		d0_PADDR	<= iPADDR;
	end
end

assign	PRDATA	= (d0_PADDR == 4'b0000) ? iPRDATA_RxFIFO :
				  (d0_PADDR == 4'b0101 || d0_PADDR == 4'b0110) ? iPRDATA_INTC : iPRDATA_CR;

endmodule

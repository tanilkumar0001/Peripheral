/********************************************************************************
 *																				*
 *		uart_top.v  Ver 0.1														*
 *																				*
 *		Designed by	Yoon Dong Joon                                              *
 *																				*
 ********************************************************************************
 *																				*
 *		Support Verilog 2001 Syntax												*
 *																				*
 *		Update history : 2012.11.06	 original authored (Ver.0.1)				*
 *																				*		
 *		uart peripheral top module												*
 *																				*
 ********************************************************************************/	
`include "UART_DEFINES.v"
`include "TIMESCALE.v"

module UART_TOP(
	//---------------------------------------------------------------------------
	//	input signals
	//---------------------------------------------------------------------------
	// Clock, reset signal
	input					CLK,
	input					RESETn,

`ifdef WISHBONE_DEBUG
	// WISHBONE interface for debug
	input 	wire							wb_rst_i;
	input 	wire  	[uart_addr_width-1:0]	wb_adr_i;
	input 	wire  	[uart_data_width-1:0]	wb_dat_i;
	output	wire	[uart_data_width-1:0]	wb_dat_o;
	input 	wire							wb_we_i;
	input 	wire							wb_stb_i;
	input 	wire							wb_cyc_i;
	input 	wire  	[3:0]					wb_sel_i;
	output	wire 							wb_ack_o;
	output	wire 							int_o;
`else
	// Simple SRAM interface for Master
	input	wire			MST_WEn,
	input	wire			MST_CEn,
	input	wire	[31:0]	MST_ADDR,
	input	wire	[31:0]	MST_WDATA,
	input	wire	[31:0]	MST_RDATA,
`endif

	// Autoflow control signal
	input	wire			CTS,

	//---------------------------------------------------------------------------
	//	output signals
	//---------------------------------------------------------------------------
	// uart signal - serial input/output
	output	wire			TXD,
	output	wire			RXD,

	// Autoflow control signal
	output	wire			RTS
);

//-------------------------------------------------------------------------------
//	internal signals
//-------------------------------------------------------------------------------
reg	[31:0]	mst_rdata;

//-------------------------------------------------------------------------------
//	Control Regsters
//-------------------------------------------------------------------------------
// Receiver Buffer Register (read only)
reg	[31:0]	CR_RBR;
// Transmitter Holding Register (write only)
reg	[31:0]	CR_THR;
//  Interrupt Enable Register
reg	[31:0]	CR_IER;
// Interrupt Identification Register (read only)
reg	[31:0]	CR_IIR;
// FIFO Control Register (write only)
reg	[31:0]	CR_FCR;
// Line Control Register
reg	[31:0]	CR_LCR;
// Modem Control Register
reg	[31:0]	CR_MCR;
// Line Status Register
reg	[31:0]	CR_LSR;
// Divisor LSB Latch
reg	[31:0]	CR_DLL;
// Divisor MSB Latch
reg	[31:0]	CR_DLH;
// Peripheral Identification Register
//reg	[31:0]	CR_PID1;
// Peripheral Identification Register
//reg	[31:0]	CR_PID2;
// Power and Emulation Management Register Power and Emulation Management Register
reg	[31:0]	CR_PWREMU_MGMT;
// Scratch register
reg	[31:0]	CR_SCRATCH;

//-------------------------------------------------------------------------------
//	Master write operation
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		//CR_RBR		<=	32'd0;	// read-only
		CR_THR		<=	32'd0;
		CR_IER		<=	32'd0;
		//CR_IIR		<=	32'd0;	// read-only
		CR_FCR FIFO	<=	32'd0;
		CR_LCR		<=	32'd0;
		CR_MCR		<=	32'd0;
		CR_LSR		<= 	32'd0;
		CR_DLL		<=	32'd0;
		CR_DLH		<=	32'd0;
		CR_PWREMU_MGMT	<=	32'd0;
	end
	else begin
		if(!MST_CEn && !MST_WEn) begin
			case(MST_ADDR[5:2])
				//4'd0	:	CR_RBR		<=	MST_WDATA;	// read-only
				4'd0	:	CR_THR		<=	MST_WDATA;
				4'd1	:	CR_IER		<=	MST_WDATA;
				//4'd2	:	CR_IIR		<=	MST_WDATA;	// read-only
				4'd2	:	CR_FCR 		<=	MST_WDATA;
				4'd3	:	CR_LCR		<=	MST_WDATA;
				4'd4	:	CR_MCR		<=	MST_WDATA;
				4'd5	:	CR_LSR		<= 	MST_WDATA;
				4'd6	:	CR_DLL		<=	MST_WDATA;
				4'd7	:	CR_DLH		<=	MST_WDATA;
				4'd8	:	CR_PWREMU_MGMT	<=	MST_WDATA;

				default	:	CR_SCRATCH	<=	MST_WDATA;
			endcase
		end
	end
end

//-------------------------------------------------------------------------------
//	Master read operation
//-------------------------------------------------------------------------------
always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		mst_rdata	<=	32'd0;
	end
	else begin
		if(!MST_CEn && !MST_WEn) begin
			case(MST_ADDR[5:2])
				4'd0	:	mst_rdata	<=	CR_RBR;
				//4'd0	:	mst_rdata	<=	CR_THR;	// write-only
				4'd1	:	mst_rdata	<=	CR_IER;
				4'd2	:	mst_rdata	<=	CR_IIR;
				//4'd2	:	mst_rdata	<=	CR_FCR;	// write-only
				4'd3	:	mst_rdata	<=	CR_LCR;
				4'd4	:	mst_rdata	<=	CR_MCR;
				4'd5	:	mst_rdata	<=	CR_LSR;
				4'd6	:	mst_rdata	<=	CR_DLL;
				4'd7	:	mst_rdata	<=	CR_DLH;
				4'd8	:	mst_rdata	<=	CR_PWREMU_MGMT;

				default	:	mst_rdata	<=	CR_SCRATCH;
			endcase
		end
	end
end

assign MST_RDATA	= mst_rdata;

//-------------------------------------------------------------------------------
//	WISHBONE wrapper
//-------------------------------------------------------------------------------

//-------------------------------------------------------------------------------
//	Baudrate generator
//-------------------------------------------------------------------------------
BAUD_GEN	baud_gen(
	.CLK

);

//-------------------------------------------------------------------------------
//	UART_Tx
//-------------------------------------------------------------------------------
UART_TX uart_tx(

);

//-------------------------------------------------------------------------------
//	UART_Rx
//-------------------------------------------------------------------------------
UART_RX uart_rx(

);



endmodule

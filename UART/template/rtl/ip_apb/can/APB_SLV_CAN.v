// =======================================================
//  Injae Yoo 
//  20121106
//  
//  APB SLAVE of CAN controller
// =======================================================

module SLV_APB_CAN (
    
	// Common Control Signals
	input	wire				CLK,
	input	wire				nRST,

	// CAN Interface Signals
	input	wire				CAN_rx,
	output	wire				CAN_tx,

	// Core Interrupt Signal
    output  wire				INT,

    // Signals From Advanced Peripheral Bus (APB)
	input	wire				PSEL0,
	input	wire				PENABLE,	
	input	wire				PWRITE,
	input	wire	[31:0]		PADDR,
	input	wire	[31:0]		PWDATA,	

    // Signals To Advanced Peripheral Bus (APB)
	output	wire	[31:0]		PRDATA0
);

	wire	[7:0]	wb_dat_o;
	assign PRDATA0 = {24'b0,wb_dat_o};

	can_top can_top_inst ( 
		// WISHBONE interface signals
    	.wb_clk_i		(CLK),
    	.wb_rst_i		(~nRST),
    	.wb_dat_i		(PWDATA[7:0]),
    	.wb_dat_o		(wb_dat_o),
    	.wb_cyc_i		(PSEL0),
    	.wb_stb_i		(PSEL0),
    	.wb_we_i 		(~PWRITE),
    	.wb_adr_i		(PADDR[7:0]),
    	.wb_ack_o		(/*N.C.*/),

		// General signals
    	.clk_i			(CLK),
    	.rx_i 			(CAN_rx),
    	.tx_o 			(CAN_tx),
    	.bus_off_on		(/*N.C.*/),
    	.irq_on   		(/*N.C.*/),
    	.clkout_o  		(/*N.C.*/)
	);

endmodule

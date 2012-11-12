//=======================================================
//
//	PLATFORM TEMPLATE TB_TOP
//
//					Ver. 2012
//
//					Injae Yoo
//
//=======================================================

`timescale 1ns/10ps

module TB_TOP;

	/* Global Signals */
	reg				CLK, nRST;
	reg				PCLK, PRESETn;


	/* External Interrupt */
	reg				Ext_INT;
	wire			Ext_ACK;

	/* External Interface */
	wire			Ext_CLK_out;
	wire			Ext_RST;	//reset active high

	wire			Ext_TRANS_VALID;
	wire	[2:0]	Ext_TRANS_PHASE;
	wire	[15:0]	Ext_TRANS_DATA;
	wire			Ext_TRANS_ACK;

	wire			Ext_CLK_in;
	wire			Ext_RESP_VALID;
	wire			Ext_RESP_RESP;
	wire	[7:0]	Ext_RESP_DATA;
	wire			Ext_RESP_ACK;

	wire			UART_tx;


	/* CLOCK Generator */
	parameter	PER = 5.0;
	parameter	HPER = PER/2.0;

	initial CLK <= 1'b0;
	always #(HPER) CLK <= ~CLK;

	parameter	PERI_PER = 40.0;
	parameter	PERI_HPER = PERI_PER/2.0;

	initial PCLK <= 1'b0;
	always #(PERI_HPER) PCLK <= ~PCLK;


	/* External Interrupt */
	initial begin
		Ext_INT <= 1'b0;
	end

	always @ (posedge Ext_CLK_in)
		if(Ext_INT & Ext_ACK)
			Ext_INT = 1'b0;


	PLATFORM_TOP platform_top_inst (
		.CLK    			(CLK),
		.nRST   			(nRST),

		.PCLK   			(PCLK),
		.PRESETn			(PRESETn),

		.CAN_rx 			(),
		.CAN_tx 			(),

		.UART_rx 			(),
		.UART_tx 			(UART_Tx),

		.Ext_INT			(Ext_INT),
		.Ext_ACK			(Ext_ACK),
		
		.Ext_CLK_out		(Ext_CLK_out),
		.Ext_RST			(Ext_RST),	//reset active high
		                                        
		.Ext_TRANS_VALID	(Ext_TRANS_VALID),
		.Ext_TRANS_DATA		(Ext_TRANS_DATA),
		.Ext_TRANS_ACK		(Ext_TRANS_ACK),
		                                        
		.Ext_CLK_in			(Ext_CLK_in),
		.Ext_RESP_VALID		(Ext_RESP_VALID),
		.Ext_RESP_RESP		(Ext_RESP_RESP),
		.Ext_RESP_DATA		(Ext_RESP_DATA),
		.Ext_RESP_ACK		(Ext_RESP_ACK)
	);


	/* EXTERNAL MEMORY */
	SRAM_EXT_INTF_RECEIVER #(
		.AWIDTH(12),
		.SIZE(4096)
	) ext_mem (
		.CLK				(CLK),
		.nRST				(nRST),
		
		// External Interface
		.Ext_CLK0			(Ext_CLK_out),
		.Ext_RST			(Ext_RST),	//reset active high
		
		.Ext_TRANS_VALID	(Ext_TRANS_VALID),
		.Ext_TRANS_DATA		(Ext_TRANS_DATA),
		.Ext_TRANS_ACK		(Ext_TRANS_ACK),
		
		.Ext_CLK1			(Ext_CLK_in),
		.Ext_RESP_VALID		(Ext_RESP_VALID),
		.Ext_RESP_RESP		(Ext_RESP_RESP),
		.Ext_RESP_DATA		(Ext_RESP_DATA),
		.Ext_RESP_ACK		(Ext_RESP_ACK)
	);


	/* Simulation environment */
	initial begin
		$shm_open("PLATFORM_TOP.shm");
		$shm_probe("AC");

		nRST <= 1'b0;
		PRESETn <= 1'b0;
		#(4*PER)
		nRST <= 1'b1;
		PRESETn <= 1'b1;
		#(500000*PER)
		$finish();
	end


endmodule


module pre_load;
defparam	TB_TOP.ext_mem.SPSRAM_sim.INIT_FILE = "../codes/ASM.hex";
defparam	TB_TOP.ext_mem.SPSRAM_sim.INITIALIZE = 2;
endmodule

/****************************************************************************
*                                                                           *
*                          Default  Master                                  *
*                                                                           *
*****************************************************************************/
// 20110715, Jinook Song, MxMOD is modified, 3bits


module DFT_MST
(
	input	wire						CLK,
	input	wire						nRST,

	output	wire						MxREQ, 
	output	wire						MxLK, 
	output	wire						MxWT, 		// 1 : Write 		0 : Read
	output	wire		[2:0]			MxSZ,
	output	wire		[3:0]			MxRB, 
	output	wire		[2:0]			MxMOD, 
	output	wire		[31:0]			MxADDR, 
	output	wire		[38:0]			MxWDT
	
);


	assign 	MxREQ 	= 1'b1;				//always REQ, But Arbiter Will Not Look This Signal.
	assign	MxLK 	= 1'b0;				//always Divisible Transaction	
	assign	MxWT 	= 1'b0;				//always READ
	assign	MxSZ 	= 3'b000;			//always Byte(Smallest Size)
	assign	MxRB 	= 4'b0000;			//always Single Trnasfer 
	assign	MxMOD	= 3'b000;			//always IDLE(Slave Will Ignore 
	assign	MxADDR  = 32'hFFFF_FFFF;	//always ADDR = 32'hFFFF_FFFF(Mapped to Default Master)
	assign	MxWDT	= 39'h00_0000_0000;	//always WDT = 0
	
endmodule

/****************************************************************************
*                                                                           *
*                                 Arbiter                                   *
*                                                                           *
*****************************************************************************/


module ABT (
	// Common Control Signals
	input	wire						CLK, 
	input	wire						nRST, 

	// Signals From Each Master
	input	wire		[15:0]			MxREQ, 			// MxREQ Signals

	// Signals From BUS ( Master -> Slave )
	input	wire						MmLK, 
	input	wire						MmLST, 

	// Signals From BUS ( Slave -> Master )
	input	wire						MsRDY, 
	input	wire						MsERR, 

	// Signals To Each Master
	output	wire		[15:0]			AxGNT, 			// Grant Signals for Masters

	// Signals To CMUX
	output	reg			[15:0]			AmCMUX
);

reg		[15:0]		L_GNT;
reg		[15:0]		NEXT_GNT;

wire				NEW_ABT;	


// Fixed Priority 
// The higher the # of Master is, The Higher the priority of the Master is.
always @*
begin
	casex (MxREQ)
		16'b0000_0000_0000_0001 : NEXT_GNT <= 16'b0000_0000_0000_0001;

		//16'b0000_0000_0000_001x : NEXT_GNT <= 16'b0000_0000_0000_0010;
		//16'b0000_0000_0000_01xx : NEXT_GNT <= 16'b0000_0000_0000_0100;
		//16'b0000_0000_0000_1xxx : NEXT_GNT <= 16'b0000_0000_0000_1000;
		//16'b0000_0000_0001_xxxx : NEXT_GNT <= 16'b0000_0000_0001_0000;
		//16'b0000_0000_001x_xxxx : NEXT_GNT <= 16'b0000_0000_0010_0000;
		//16'b0000_0000_01xx_xxxx : NEXT_GNT <= 16'b0000_0000_0100_0000;
		//16'b0000_0000_1xxx_xxxx : NEXT_GNT <= 16'b0000_0000_1000_0000;
		//16'b0000_0001_xxxx_xxxx : NEXT_GNT <= 16'b0000_0001_0000_0000;
		//16'b0000_001x_xxxx_xxxx : NEXT_GNT <= 16'b0000_0010_0000_0000;
		//16'b0000_01xx_xxxx_xxxx : NEXT_GNT <= 16'b0000_0100_0000_0000;
		//16'b0000_1xxx_xxxx_xxxx : NEXT_GNT <= 16'b0000_1000_0000_0000;
		//16'b0001_xxxx_xxxx_xxxx : NEXT_GNT <= 16'b0001_0000_0000_0000;
		//16'b001x_xxxx_xxxx_xxxx : NEXT_GNT <= 16'b0010_0000_0000_0000;
		//16'b01xx_xxxx_xxxx_xxxx : NEXT_GNT <= 16'b0100_0000_0000_0000;
		//16'b1xxx_xxxx_xxxx_xxxx : NEXT_GNT <= 16'b1000_0000_0000_0000;

		16'bxxxx_xxxx_xxxx_xx1x : NEXT_GNT <= 16'b0000_0000_0000_0010;
		16'bxxxx_xxxx_xxxx_x10x : NEXT_GNT <= 16'b0000_0000_0000_0100;
		16'bxxxx_xxxx_xxxx_100x : NEXT_GNT <= 16'b0000_0000_0000_1000;
		16'bxxxx_xxxx_xxx1_000x : NEXT_GNT <= 16'b0000_0000_0001_0000;
		16'bxxxx_xxxx_xx10_000x : NEXT_GNT <= 16'b0000_0000_0010_0000;
		16'bxxxx_xxxx_x100_000x : NEXT_GNT <= 16'b0000_0000_0100_0000;
		16'bxxxx_xxxx_1000_000x : NEXT_GNT <= 16'b0000_0000_1000_0000;
		16'bxxxx_xxx1_0000_000x : NEXT_GNT <= 16'b0000_0001_0000_0000;
		16'bxxxx_xx10_0000_000x : NEXT_GNT <= 16'b0000_0010_0000_0000;
		16'bxxxx_x100_0000_000x : NEXT_GNT <= 16'b0000_0100_0000_0000;
		16'bxxxx_1000_0000_000x : NEXT_GNT <= 16'b0000_1000_0000_0000;
		16'bxxx1_0000_0000_000x : NEXT_GNT <= 16'b0001_0000_0000_0000;
		16'bxx10_0000_0000_000x : NEXT_GNT <= 16'b0010_0000_0000_0000;
		16'bx100_0000_0000_000x : NEXT_GNT <= 16'b0100_0000_0000_0000;
		16'b1000_0000_0000_000x : NEXT_GNT <= 16'b1000_0000_0000_0000;

						default : NEXT_GNT <= 16'b0000_0000_0000_0001;
	endcase
end

always @ (posedge CLK or negedge nRST)
begin
	if(~nRST)			L_GNT <= 16'b1;
	else if(MmLST)		L_GNT <= AxGNT;
end

// Detect the time when New Arbitration is needed
//	1. Error Occur
//	2. Last Transfer of the selected non-locked transaction
assign		NEW_ABT = MsERR | (MmLST & (~MmLK));


assign		AxGNT	= (NEW_ABT == 1'b1) ? NEXT_GNT : L_GNT;


//always @ (posedge CLK or negedge nRST)
always @ (posedge CLK)
begin
	if(~nRST)			AmCMUX <= 16'b1;	
	else if(MsRDY)		AmCMUX <= AxGNT;
end

endmodule

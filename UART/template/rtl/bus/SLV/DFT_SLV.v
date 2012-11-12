/****************************************************************************
*                                                                           *
*                           Default  Slave                                  *
*                                                                           *
*****************************************************************************/
// 20110715, Jinook Song, MxMOD is modified, 3bits


module DFT_SLV(
 	// Common Control Signals
	input	wire					CLK, 
	input	wire					nRST, 

	// Signals From Core-B Lite On-Chip High-Speed Bus
	input	wire					DxSEL, 
	input	wire					MmWT, 
	input	wire		[2:0]		MmSZ, 
	input	wire		[3:0]		MmRB, 
	input	wire		[2:0]		MmMOD, 
	input	wire		[31:0]		MmADDR, 
	input	wire		[38:0]		MmWDT, 
	input	wire					MsRDY, 

	// Signals To Core-B Lite On-Chip High-Speed Bus
	output	wire		[38:0]		SxRDT, 
	output	wire					SxRDY, 
	output	reg						SxERR

);
	localparam		IDLE	=	3'b000;
	localparam		BUSY	=	3'b001;
	localparam		LDADDR	=	3'b010;
	localparam		SEQADDR	=	3'b011;

	assign SxRDT = 39'h0;	 	//any data
	assign SxRDY = 1'b1;		//Always READY
	
	always@(posedge CLK or negedge nRST)
	begin
		if( ~nRST)
		begin
				SxERR <= 1'b0;	//During Reset, ERROR Will Not Occur
		end
		else	
		begin
			if( (DxSEL==1'b1) & (MsRDY==1'b1))	//If Selected, Current Trnasfer
			begin
				if( (MmMOD != IDLE) )
					SxERR <= 1'b1;
				else
					SxERR <= 1'b0;
			end
			
		end
	end

endmodule

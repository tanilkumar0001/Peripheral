/****************************************************************************
*                                                                           *
*                               Decoder                                     *
*                                                                           *
****************************************************************************/


module DCD	
(
	input	wire			CLK,
	input 	wire			nRST,
	input 	wire	[31:0]	MmADDR,
	input	wire	[2:0]	MmMOD,
	input	wire	[15:0]	AmCMUX,
	input	wire			MsRDY,
	output	reg		[15:0]	DxSEL,
	output	reg		[15:0]	DmRMUX
);
	localparam	IDLE 	= 3'b000;
	localparam	BUSY 	= 3'b001;
	localparam	LDADDR 	= 3'b010;
	localparam	SEQADDR = 3'b011;
	localparam	LDWRPADDR = 3'b110;
	localparam	WRPADDR = 3'b111;

	wire		 	DFT_MST;		//Default Master

	reg 	[31:0] 	L_MmADDR;
	wire	[31:0] 	FINAL_MmADDR;	
	
	// DFT_MST Detect
	//		DFT_MST is SELECTED when AmCMUX == 1	(No Master Request)
	assign		DFT_MST = (~(|AmCMUX[15:1]))&AmCMUX[0];

	// MmADDR is L when MmMOD == LDADDR
	always@(posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			L_MmADDR <= 32'h0000_0000;
		end
		else
		begin
			if((MmMOD==LDADDR)|(MmMOD==LDWRPADDR))
			begin
				L_MmADDR <= MmADDR;
			end
		end
	end

	// Mux for Determining MmADDR 
	// MmMOD==LDADDR/LDWRPADDR :  Transfer the MmADDR to Slave	
	//    Otherwise  :  Transfer the L MmADDR
	assign FINAL_MmADDR = ((MmMOD==LDADDR)|(MmMOD==LDWRPADDR))? MmADDR : L_MmADDR;

		
	// Address Decoding Map
		// SLV 1 : 0x0000_0000 ~ 0x0000_3FFF : On-Chip SRAM (16K)
		// SLV 2 : 0x0010_0000 ~ 0x001F_FFFF : Core-B to APB Bridge
		// SLV 3 : 0x0020_F000 ~ 0x0020_FFFF : Timer
		// SLV 4 : 0x0021_0000 ~ 0xFFFF_FFFF : Ext. I/F
	always@*
	begin
		casex({DFT_MST, FINAL_MmADDR[31:16], FINAL_MmADDR[15:12]})
		// DFT_SLV (DFT_MST Case) 
		{1'b1,16'bxxxx_xxxx_xxxx_xxxx, 4'bxxxx} :	DxSEL <= 16'h0001;

		// SLV 1 : 0x0000_0000 ~ 0x0000_3FFF : On-Chip SRAM
		{1'b0,16'b0000_0000_0000_0000, 4'b00xx} :	DxSEL <= 16'h0002;

		//         0x0000_4000 ~ 0x0000_7FFF : DFT_SLV 
		{1'b0,16'b0000_0000_0000_0000, 4'b01xx} :	DxSEL <= 16'h0001;

		//         0x0000_8000 ~ 0x0000_FFFF : DFT_SLV 
		{1'b0,16'b0000_0000_0000_0000, 4'b1xxx} :	DxSEL <= 16'h0001;

		//         0x0001_0000 ~ 0x0001_FFFF : DFT_SLV 
		{1'b0,16'b0000_0000_0000_0001, 4'bxxxx} :	DxSEL <= 16'h0001;

		//         0x0002_0000 ~ 0x0003_FFFF : DFT_SLV 
		{1'b0,16'b0000_0000_0000_001x, 4'bxxxx} :	DxSEL <= 16'h0001;

		//         0x0004_0000 ~ 0x0007_FFFF : DFT_SLV 
		{1'b0,16'b0000_0000_0000_01xx, 4'bxxxx} :	DxSEL <= 16'h0001;

		//         0x0008_0000 ~ 0x000F_FFFF : DFT_SLV 
		{1'b0,16'b0000_0000_0000_1xxx, 4'bxxxx} :	DxSEL <= 16'h0001;

		// SLV 2 : 0x0010_0000 ~ 0x001F_FFFF : Core-B to APB Bridge
		{1'b0,16'b0000_0000_0001_xxxx, 4'bxxxx} :	DxSEL <= 16'h0004;

		//         0x0020_0000 ~ 0x0020_7FFF : DFT_SLV
		{1'b0,16'b0000_0000_0010_0000, 4'b0xxx} :	DxSEL <= 16'h0001;

		//         0x0020_8000 ~ 0x0020_BFFF : DFT_SLV
		{1'b0,16'b0000_0000_0010_0000, 4'b10xx} :	DxSEL <= 16'h0001;

		//         0x0020_C000 ~ 0x0020_DFFF : DFT_SLV
		{1'b0,16'b0000_0000_0010_0000, 4'b110x} :	DxSEL <= 16'h0001;

		//         0x0020_E000 ~ 0x0020_EFFF : DFT_SLV
		{1'b0,16'b0000_0000_0010_0000, 4'b1110} :	DxSEL <= 16'h0001;

		// SLV 5 : 0x0020_F000 ~ 0x0020_FFFF : Timer 
		{1'b0,16'b0000_0000_0010_0000, 4'b1111} :	DxSEL <= 16'h0008;

		// SLV 6 : 0x0021_0000 ~ 0xFFFF_FFFF : EXT_INTF
		default :	DxSEL <= 16'h0010;
		endcase
	end

	always@(posedge CLK or negedge nRST)
	begin
		if(~nRST)
		begin
			DmRMUX <= 16'h0001;	//During Reset, Select DFT_SLV
		end
		else
		begin
			if(MsRDY==1'b1)
			begin
				DmRMUX <= DxSEL;
			end
		end
	end	

endmodule
	

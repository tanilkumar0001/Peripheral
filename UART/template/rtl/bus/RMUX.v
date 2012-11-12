/****************************************************************************
*                                                                           *
*	                Slave To Master Mux(Read Data Mux)                      *
*                                                                           *
*****************************************************************************/


module RMUX 
(
	//DFT_SLV
	input	wire	[38:0]		S0RDT,
	input	wire				S0RDY,
	input	wire				S0ERR,
	
	input	wire	[38:0]		S1RDT,
	input	wire				S1RDY,
	input	wire				S1ERR,

	input	wire	[38:0]		S2RDT,
	input	wire				S2RDY,
	input	wire				S2ERR,

	input	wire	[38:0]		S3RDT,
	input	wire				S3RDY,
	input	wire				S3ERR,

	input	wire	[38:0]		S4RDT,
	input	wire				S4RDY,
	input	wire				S4ERR,

	input	wire	[38:0]		S5RDT,
	input	wire				S5RDY,
	input	wire				S5ERR,

	input	wire	[38:0]		S6RDT,
	input	wire				S6RDY,
	input	wire				S6ERR,

	input	wire	[38:0]		S7RDT,
	input	wire				S7RDY,
	input	wire				S7ERR,

	input	wire	[38:0]		S8RDT,
	input	wire				S8RDY,
	input	wire				S8ERR,

	input	wire	[38:0]		S9RDT,
	input	wire				S9RDY,
	input	wire				S9ERR,

	input	wire	[38:0]		S10RDT,
	input	wire				S10RDY,
	input	wire				S10ERR,

	input	wire	[38:0]		S11RDT,
	input	wire				S11RDY,
	input	wire				S11ERR,

	input	wire	[38:0]		S12RDT,
	input	wire				S12RDY,
	input	wire				S12ERR,

	input	wire	[38:0]		S13RDT,
	input	wire				S13RDY,
	input	wire				S13ERR,

	input	wire	[38:0]		S14RDT,
	input	wire				S14RDY,
	input	wire				S14ERR,

	input	wire	[38:0]		S15RDT,
	input	wire				S15RDY,
	input	wire				S15ERR,

	input	wire	[15:0]		DmRMUX,

	output	reg		[38:0]		MsRDT,
	output  reg					MsRDY,
	output	reg					MsERR
);	


	always@*
	begin
		case(DmRMUX)
		16'h8000: MsRDT <= S15RDT;
		16'h4000: MsRDT <= S14RDT;
		16'h2000: MsRDT <= S13RDT;
		16'h1000: MsRDT <= S12RDT; 

		16'h0800: MsRDT <= S11RDT;
		16'h0400: MsRDT <= S10RDT;
		16'h0200: MsRDT <= S9RDT; 
		16'h0100: MsRDT <= S8RDT;

		16'h0080: MsRDT <= S7RDT;
		16'h0040: MsRDT <= S6RDT; 
		16'h0020: MsRDT <= S5RDT;
		16'h0010: MsRDT <= S4RDT;

		16'h0008: MsRDT <= S3RDT; 
		16'h0004: MsRDT <= S2RDT;
		16'h0002: MsRDT <= S1RDT;
		16'h0001: MsRDT <= S0RDT; 
		default:MsRDT <= S0RDT;					//Default Slave 
		endcase
	end

	always@*
	begin
		case(DmRMUX)
		16'h8000:  MsRDY <= S15RDY;
		16'h4000:  MsRDY <= S14RDY;
		16'h2000:  MsRDY <= S13RDY;
		16'h1000:  MsRDY <= S12RDY; 

		16'h0800:  MsRDY <= S11RDY;
		16'h0400:  MsRDY <= S10RDY;
		16'h0200:  MsRDY <= S9RDY;
		16'h0100:  MsRDY <= S8RDY; 

		16'h0080:  MsRDY <= S7RDY;
		16'h0040:  MsRDY <= S6RDY;
		16'h0020:  MsRDY <= S5RDY;
		16'h0010:  MsRDY <= S4RDY; 
                
		16'h0008:  MsRDY <= S3RDY;
		16'h0004:  MsRDY <= S2RDY;
		16'h0002:  MsRDY <= S1RDY;
		16'h0001:  MsRDY <= S0RDY; 
		default: MsRDY <= S0RDY;					//Default Slave 
		endcase
	end

	always@*
	begin
		case(DmRMUX)
		16'h8000:  MsERR <= S15ERR;
		16'h4000:  MsERR <= S14ERR;
		16'h2000:  MsERR <= S13ERR;
		16'h1000:  MsERR <= S12ERR; 

		16'h0800:  MsERR <= S11ERR;
		16'h0400:  MsERR <= S10ERR;
		16'h0200:  MsERR <= S9ERR;
		16'h0100:  MsERR <= S8ERR; 

		16'h0080:  MsERR <= S7ERR;
		16'h0040:  MsERR <= S6ERR;
		16'h0020:  MsERR <= S5ERR;
		16'h0010:  MsERR <= S4ERR; 

		16'h0008:  MsERR <= S3ERR;
		16'h0004:  MsERR <= S2ERR;
		16'h0002:  MsERR <= S1ERR;
		16'h0001:  MsERR <= S0ERR; 
		default: MsERR <= S0ERR;					//Default Slave
		endcase
	end



endmodule

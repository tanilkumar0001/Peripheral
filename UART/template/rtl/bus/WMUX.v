/****************************************************************************
*                                                                           *
*                 Master To Slave Mux(Write Data Mux)                       *
*                                                                           *
*****************************************************************************/


module WMUX 
(
	input 	wire			CLK,
	input	wire			nRST,
	
	input	wire			MsRDY,

	input	wire	[38:0]	M0WDT,
	input	wire	[38:0]	M1WDT,
	input	wire	[38:0]	M2WDT,
	input	wire	[38:0]	M3WDT,
	input	wire	[38:0]	M4WDT,
	input	wire	[38:0]	M5WDT,
	input	wire	[38:0]	M6WDT,
	input	wire	[38:0]	M7WDT,
	input	wire	[38:0]	M8WDT,
	input	wire	[38:0]	M9WDT,
	input	wire	[38:0]	M10WDT,
	input	wire	[38:0]	M11WDT,
	input	wire	[38:0]	M12WDT,
	input	wire	[38:0]	M13WDT,
	input	wire	[38:0]	M14WDT,
	input	wire	[38:0]	M15WDT,

	input	wire	[15:0]	AmCMUX,

	output	reg		[38:0]	MmWDT
);	

	reg	[15:0]	AmWMUX;

	always@*
	begin
		case(AmWMUX)			
		16'b1000_0000_0000_0000:	MmWDT <= M15WDT;  
		16'b0100_0000_0000_0000:	MmWDT <= M14WDT;  
		16'b0010_0000_0000_0000:	MmWDT <= M13WDT;  
		16'b0001_0000_0000_0000:	MmWDT <= M12WDT;  
		16'b0000_1000_0000_0000:	MmWDT <= M11WDT;  
		16'b0000_0100_0000_0000:	MmWDT <= M10WDT;  
		16'b0000_0010_0000_0000:	MmWDT <= M9WDT;   
		16'b0000_0001_0000_0000:	MmWDT <= M8WDT;   
		16'b0000_0000_1000_0000:	MmWDT <= M7WDT;   
		16'b0000_0000_0100_0000:	MmWDT <= M6WDT;   
		16'b0000_0000_0010_0000:	MmWDT <= M5WDT;   
		16'b0000_0000_0001_0000:	MmWDT <= M4WDT;   
		16'b0000_0000_0000_1000:	MmWDT <= M3WDT;   
		16'b0000_0000_0000_0100:	MmWDT <= M2WDT;   
		16'b0000_0000_0000_0010:	MmWDT <= M1WDT;   
		16'b0000_0000_0000_0001:	MmWDT <= M0WDT;
		default:					MmWDT <= M0WDT;	//Default Master : Any WDT 
		endcase
	end
	
	always@(posedge CLK or negedge nRST)
	begin	
		if(~nRST)
		begin
			AmWMUX <= 16'b0;	//During Reset, Select Default Slave
		end
		else
		begin
			if(MsRDY==1'b1)
			begin
				AmWMUX <= AmCMUX;
			end
		end
	end
endmodule

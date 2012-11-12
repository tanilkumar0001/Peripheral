/****************************************************************************
*                                                                           *
*                 Master To Slave Mux(Control Signal Mux)                   *
*                                                                           *
*****************************************************************************/
// 20110715, Jinook Song, MxMOD is modified, 3bits


module CMUX 
(
	input	wire			MsRDY,

	input	wire	     	M0LK,
	input	wire	     	M0WT,
	input	wire	[2:0]	M0SZ,
	input	wire	[3:0]	M0RB,
	input	wire	[2:0]	M0MOD,
	input	wire	[31:0] 	M0ADDR,

	input	wire			M1LK,
	input	wire			M1WT,
	input	wire	[2:0]	M1SZ,
	input	wire	[3:0]	M1RB,
	input	wire	[2:0]	M1MOD,
	input	wire	[31:0] 	M1ADDR,

	input	wire	     	M2LK,
	input	wire	     	M2WT,
	input	wire	[2:0]  	M2SZ,
	input	wire	[3:0]	M2RB,
	input	wire	[2:0]	M2MOD,
	input	wire	[31:0] 	M2ADDR,

	input	wire	     	M3LK,
	input	wire	     	M3WT,
	input	wire	[2:0]  	M3SZ,
	input	wire	[3:0]	M3RB,
	input	wire	[2:0]	M3MOD,
	input	wire	[31:0] 	M3ADDR,

	input	wire	     	M4LK,
	input	wire	     	M4WT,
	input	wire	[2:0]	M4SZ,
	input	wire	[3:0]	M4RB,
	input	wire	[2:0]	M4MOD,
	input	wire	[31:0] 	M4ADDR,

	input	wire	     	M5LK,
	input	wire	     	M5WT,
	input	wire	[2:0]	M5SZ,
	input	wire	[3:0]	M5RB,
	input	wire	[2:0]	M5MOD,
	input	wire	[31:0] 	M5ADDR,

	input	wire	     	M6LK,
	input	wire	     	M6WT,
	input	wire	[2:0]	M6SZ,
	input	wire	[3:0]	M6RB,
	input	wire	[2:0]	M6MOD,
	input	wire	[31:0] 	M6ADDR,

	input	wire	     	M7LK,
	input	wire	     	M7WT,
	input	wire	[2:0]	M7SZ,
	input	wire	[3:0]	M7RB,
	input	wire	[2:0]	M7MOD,
	input	wire	[31:0] 	M7ADDR,

	input	wire	     	M8LK,
	input	wire	     	M8WT,
	input	wire	[2:0]	M8SZ,
	input	wire	[3:0]	M8RB,
	input	wire	[2:0]	M8MOD,
	input	wire	[31:0] 	M8ADDR,

	input	wire	     	M9LK,
	input	wire	     	M9WT,
	input	wire	[2:0]	M9SZ,
	input	wire	[3:0]	M9RB,
	input	wire	[2:0]	M9MOD,
	input	wire	[31:0] 	M9ADDR,

	input	wire	     	M10LK,
	input	wire	     	M10WT,
	input	wire	[2:0]	M10SZ,
	input	wire	[3:0]	M10RB,
	input	wire	[2:0]	M10MOD,
	input	wire	[31:0] 	M10ADDR,

	input	wire	     	M11LK,
	input	wire	     	M11WT,
	input	wire	[2:0]	M11SZ,
	input	wire	[3:0]	M11RB,
	input	wire	[2:0]	M11MOD,
	input	wire	[31:0] 	M11ADDR,

	input	wire	     	M12LK,
	input	wire	     	M12WT,
	input	wire	[2:0]	M12SZ,
	input	wire	[3:0]	M12RB,
	input	wire	[2:0]	M12MOD,
	input	wire	[31:0] 	M12ADDR,

	input	wire	     	M13LK,
	input	wire	     	M13WT,
	input	wire	[2:0]	M13SZ,
	input	wire	[3:0]	M13RB,
	input	wire	[2:0]	M13MOD,
	input	wire	[31:0] 	M13ADDR,

	input	wire	     	M14LK,
	input	wire	     	M14WT,
	input	wire	[2:0]	M14SZ,
	input	wire	[3:0]	M14RB,
	input	wire	[2:0]	M14MOD,
	input	wire	[31:0] 	M14ADDR,

	input	wire	     	M15LK,
	input	wire	     	M15WT,
	input	wire	[2:0]   M15SZ,
	input	wire	[3:0]	M15RB,
	input	wire	[2:0]	M15MOD,
	input	wire	[31:0] 	M15ADDR,



	// Mux Control Signal From Arbiter
	input	wire	[15:0] AmCMUX,

	// Mux Output
	output	reg					MmLK,
	output	reg					MmWT,
	output	reg		[2:0]		MmSZ,
	output	reg		[3:0]		MmRB,
	output	reg					MmLST,
	output	reg		[2:0]		MmMOD,
	output	reg		[31:0]		MmADDR
);	

	always@*
	begin
		case(AmCMUX)				
		16'b1000_0000_0000_0000:    MmLK <= M15LK;
		16'b0100_0000_0000_0000:    MmLK <= M14LK;
		16'b0010_0000_0000_0000:    MmLK <= M13LK;
		16'b0001_0000_0000_0000:    MmLK <= M12LK;
		16'b0000_1000_0000_0000:    MmLK <= M11LK;
		16'b0000_0100_0000_0000:    MmLK <= M10LK;
		16'b0000_0010_0000_0000:    MmLK <= M9LK;
		16'b0000_0001_0000_0000:    MmLK <= M8LK;
		16'b0000_0000_1000_0000:    MmLK <= M7LK;
		16'b0000_0000_0100_0000:    MmLK <= M6LK;
		16'b0000_0000_0010_0000:    MmLK <= M5LK;
		16'b0000_0000_0001_0000:    MmLK <= M4LK;
		16'b0000_0000_0000_1000:    MmLK <= M3LK;
		16'b0000_0000_0000_0100:    MmLK <= M2LK;
		16'b0000_0000_0000_0010:    MmLK <= M1LK; 
		16'b0000_0000_0000_0001:	MmLK <= M0LK; 
		default:					MmLK <= M0LK;		//Default Master : divisible
		endcase
	end

	always@*
	begin
		case(AmCMUX)				
		16'b1000_0000_0000_0000:    MmWT <= M15WT;
		16'b0100_0000_0000_0000:    MmWT <= M14WT;
		16'b0010_0000_0000_0000:    MmWT <= M13WT;
		16'b0001_0000_0000_0000:    MmWT <= M12WT;
		16'b0000_1000_0000_0000:    MmWT <= M11WT;
		16'b0000_0100_0000_0000:    MmWT <= M10WT;
		16'b0000_0010_0000_0000:    MmWT <= M9WT;
		16'b0000_0001_0000_0000:    MmWT <= M8WT;
		16'b0000_0000_1000_0000:    MmWT <= M7WT;
		16'b0000_0000_0100_0000:    MmWT <= M6WT;
		16'b0000_0000_0010_0000:    MmWT <= M5WT;
		16'b0000_0000_0001_0000:    MmWT <= M4WT;
		16'b0000_0000_0000_1000:    MmWT <= M3WT;
		16'b0000_0000_0000_0100:    MmWT <= M2WT;
		16'b0000_0000_0000_0010:    MmWT <= M1WT;
		16'b0000_0000_0000_0001:	MmWT <= M0WT; 
		default:					MmWT <= M0WT;		//Default Master : READ
		endcase
	end

	always@*
	begin
		case(AmCMUX)		
		16'b1000_0000_0000_0000:    MmSZ <= M15SZ;
		16'b0100_0000_0000_0000:    MmSZ <= M14SZ;
		16'b0010_0000_0000_0000:    MmSZ <= M13SZ;
		16'b0001_0000_0000_0000:    MmSZ <= M12SZ;
		16'b0000_1000_0000_0000:    MmSZ <= M11SZ;
		16'b0000_0100_0000_0000:    MmSZ <= M10SZ;
		16'b0000_0010_0000_0000:    MmSZ <= M9SZ;
		16'b0000_0001_0000_0000:    MmSZ <= M8SZ;
		16'b0000_0000_1000_0000:    MmSZ <= M7SZ;
		16'b0000_0000_0100_0000:    MmSZ <= M6SZ;
		16'b0000_0000_0010_0000:    MmSZ <= M5SZ;
		16'b0000_0000_0001_0000:    MmSZ <= M4SZ;
		16'b0000_0000_0000_1000:    MmSZ <= M3SZ;
		16'b0000_0000_0000_0100:    MmSZ <= M2SZ;
		16'b0000_0000_0000_0010:    MmSZ <= M1SZ;
		16'b0000_0000_0000_0001:	MmSZ <= M0SZ; 
		default:					MmSZ <= M0SZ;		//Default Master : BYTE (Smallest)
		endcase
	end

	always@*
	begin
		case(AmCMUX)			
		16'b1000_0000_0000_0000:    MmRB <= M15RB;
		16'b0100_0000_0000_0000:    MmRB <= M14RB;
		16'b0010_0000_0000_0000:    MmRB <= M13RB;
		16'b0001_0000_0000_0000:    MmRB <= M12RB;
		16'b0000_1000_0000_0000:    MmRB <= M11RB;
		16'b0000_0100_0000_0000:    MmRB <= M10RB;
		16'b0000_0010_0000_0000:    MmRB <= M9RB;
		16'b0000_0001_0000_0000:    MmRB <= M8RB;
		16'b0000_0000_1000_0000:    MmRB <= M7RB;
		16'b0000_0000_0100_0000:    MmRB <= M6RB;
		16'b0000_0000_0010_0000:    MmRB <= M5RB;
		16'b0000_0000_0001_0000:    MmRB <= M4RB;
		16'b0000_0000_0000_1000:    MmRB <= M3RB;
		16'b0000_0000_0000_0100:    MmRB <= M2RB;
		16'b0000_0000_0000_0010:    MmRB <= M1RB; 
		16'b0000_0000_0000_0001:	MmRB <= M0RB; 
		default:					MmRB <= M0RB;	 //Default Master : Single Transfer
		endcase
	end

	always@*
	begin
		if(AmCMUX[0])
			MmLST <= ~(|MmRB) & MsRDY;
		else
			 MmLST <= ~(|MmRB) & MsRDY & MmMOD[1];
	end

	always@*
	begin
		case(AmCMUX)	
		16'b1000_0000_0000_0000:    MmMOD <= M15MOD;
		16'b0100_0000_0000_0000:    MmMOD <= M14MOD;
		16'b0010_0000_0000_0000:    MmMOD <= M13MOD;
		16'b0001_0000_0000_0000:    MmMOD <= M12MOD;
		16'b0000_1000_0000_0000:    MmMOD <= M11MOD;
		16'b0000_0100_0000_0000:    MmMOD <= M10MOD;
		16'b0000_0010_0000_0000:    MmMOD <= M9MOD;
		16'b0000_0001_0000_0000:    MmMOD <= M8MOD;
		16'b0000_0000_1000_0000:    MmMOD <= M7MOD;
		16'b0000_0000_0100_0000:    MmMOD <= M6MOD;
		16'b0000_0000_0010_0000:    MmMOD <= M5MOD;
		16'b0000_0000_0001_0000:    MmMOD <= M4MOD;
		16'b0000_0000_0000_1000:    MmMOD <= M3MOD;
		16'b0000_0000_0000_0100:    MmMOD <= M2MOD;
		16'b0000_0000_0000_0010:    MmMOD <= M1MOD; 
		16'b0000_0000_0000_0001:	MmMOD <= M0MOD; 
		default:					MmMOD <= M0MOD;	//Default Master : IDLE 
		endcase
	end

	always@*
	begin
		case(AmCMUX)
		16'b1000_0000_0000_0000:    MmADDR <= M15ADDR;
		16'b0100_0000_0000_0000:    MmADDR <= M14ADDR;
		16'b0010_0000_0000_0000:    MmADDR <= M13ADDR;
		16'b0001_0000_0000_0000:    MmADDR <= M12ADDR;
		16'b0000_1000_0000_0000:    MmADDR <= M11ADDR;
		16'b0000_0100_0000_0000:    MmADDR <= M10ADDR;
		16'b0000_0010_0000_0000:    MmADDR <= M9ADDR;
		16'b0000_0001_0000_0000:    MmADDR <= M8ADDR;
		16'b0000_0000_1000_0000:    MmADDR <= M7ADDR;
		16'b0000_0000_0100_0000:    MmADDR <= M6ADDR;
		16'b0000_0000_0010_0000:    MmADDR <= M5ADDR;
		16'b0000_0000_0001_0000:    MmADDR <= M4ADDR;
		16'b0000_0000_0000_1000:    MmADDR <= M3ADDR;
		16'b0000_0000_0000_0100:    MmADDR <= M2ADDR;
		16'b0000_0000_0000_0010:    MmADDR <= M1ADDR; 
		16'b0000_0000_0000_0001:	MmADDR <= M0ADDR; 
		default:					MmADDR <= M0ADDR;	//Default Master : Any Address
		endcase
	end
endmodule

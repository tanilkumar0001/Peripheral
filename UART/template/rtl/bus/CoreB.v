/****************************************************************************
*                                                                           *
*                           Core-B Bus System                               *
*                                                                           *
*****************************************************************************/
// 20110715, Jinook Song, MxMOD is modified, 3bits
// 20110718, Jinook Song, MmLK is only for the bridge of Core-I.


module CoreB (

	// Common Control Signals
	input	wire							CLK, 
	input	wire							nRST, 

	// Signals From Master0(DFT_MST)
	input	wire							M0REQ, 
	input	wire							M0LK,
	input	wire							M0WT, 
	input	wire		[2:0]				M0SZ, 
	input	wire		[3:0]				M0RB, 
	input	wire		[2:0]				M0MOD, 
	input	wire		[31:0]				M0ADDR, 
	input	wire		[38:0]				M0WDT, 
	
	// Signal To Master0
	output	wire							A0GNT, 

	// Signals From Master1
	input	wire							M1REQ, 
	input	wire							M1LK,
	input	wire							M1WT, 
	input	wire		[2:0]				M1SZ, 
	input	wire		[3:0]				M1RB, 
	input	wire		[2:0]				M1MOD, 
	input	wire		[31:0]				M1ADDR, 
	input	wire		[38:0]				M1WDT, 

	// Signal To Master1
	output	wire							A1GNT, 

	// Signals From Master2
	input	wire							M2REQ, 
	input	wire							M2LK,
	input	wire							M2WT, 
	input	wire		[2:0]				M2SZ, 
	input	wire		[3:0]				M2RB, 
	input	wire		[2:0]				M2MOD, 
	input	wire		[31:0]				M2ADDR, 
	input	wire		[38:0]				M2WDT, 

	// Signal To Master2
	output	wire							A2GNT, 

	// Signals From Master3
	input	wire							M3REQ, 
	input	wire							M3LK,
	input	wire							M3WT, 
	input	wire		[2:0]				M3SZ, 
	input	wire		[3:0]				M3RB, 
	input	wire		[2:0]				M3MOD, 
	input	wire		[31:0]				M3ADDR, 
	input	wire		[38:0]				M3WDT, 

	// Signal To Master3
	output	wire							A3GNT, 

	// Signals From Master4
	input	wire							M4REQ, 
	input	wire							M4LK,
	input	wire							M4WT, 
	input	wire		[2:0]				M4SZ, 
	input	wire		[3:0]				M4RB, 
	input	wire		[2:0]				M4MOD, 
	input	wire		[31:0]				M4ADDR, 
	input	wire		[38:0]				M4WDT, 

	// Signal To Master4
	output	wire							A4GNT, 

	// Signals From Master5
	input	wire							M5REQ, 
	input	wire							M5LK,
	input	wire							M5WT, 
	input	wire		[2:0]				M5SZ, 
	input	wire		[3:0]				M5RB, 
	input	wire		[2:0]				M5MOD, 
	input	wire		[31:0]				M5ADDR, 
	input	wire		[38:0]				M5WDT, 

	// Signal To Master5
	output	wire							A5GNT, 

	// Signals From Master6
	input	wire							M6REQ, 
	input	wire							M6LK,
	input	wire							M6WT, 
	input	wire		[2:0]				M6SZ, 
	input	wire		[3:0]				M6RB, 
	input	wire		[2:0]				M6MOD, 
	input	wire		[31:0]				M6ADDR, 
	input	wire		[38:0]				M6WDT, 

	// Signal To Master6
	output	wire							A6GNT, 

	// Signals From Master7
	input	wire							M7REQ, 
	input	wire							M7LK,
	input	wire							M7WT, 
	input	wire		[2:0]				M7SZ, 
	input	wire		[3:0]				M7RB, 
	input	wire		[2:0]				M7MOD, 
	input	wire		[31:0]				M7ADDR, 
	input	wire		[38:0]				M7WDT, 

	// Signal To Master7
	output	wire							A7GNT, 


	// Signals From Master8
	input	wire							M8REQ, 
	input	wire							M8LK,
	input	wire							M8WT, 
	input	wire		[2:0]				M8SZ, 
	input	wire		[3:0]				M8RB, 
	input	wire		[2:0]				M8MOD, 
	input	wire		[31:0]				M8ADDR, 
	input	wire		[38:0]				M8WDT, 

	// Signal To Master8
	output	wire							A8GNT, 

	// Signals From Master9
	input	wire							M9REQ, 
	input	wire							M9LK,
	input	wire							M9WT, 
	input	wire		[2:0]				M9SZ, 
	input	wire		[3:0]				M9RB, 
	input	wire		[2:0]				M9MOD, 
	input	wire		[31:0]				M9ADDR, 
	input	wire		[38:0]				M9WDT, 

	// Signal To Master9
	output	wire							A9GNT, 

	// Signals From Master10
	input	wire							M10REQ, 
	input	wire							M10LK,
	input	wire							M10WT, 
	input	wire		[2:0]				M10SZ, 
	input	wire		[3:0]				M10RB, 
	input	wire		[2:0]				M10MOD, 
	input	wire		[31:0]				M10ADDR, 
	input	wire		[38:0]				M10WDT, 

	// Signal To Master10
	output	wire							A10GNT, 

	// Signals From Master11
	input	wire							M11REQ, 
	input	wire							M11LK,
	input	wire							M11WT, 
	input	wire		[2:0]				M11SZ, 
	input	wire		[3:0]				M11RB, 
	input	wire		[2:0]				M11MOD, 
	input	wire		[31:0]				M11ADDR, 
	input	wire		[38:0]				M11WDT, 

	// Signal To Master11
	output	wire							A11GNT, 

	// Signals From Master12
	input	wire							M12REQ, 
	input	wire							M12LK,
	input	wire							M12WT, 
	input	wire		[2:0]				M12SZ, 
	input	wire		[3:0]				M12RB, 
	input	wire		[2:0]				M12MOD, 
	input	wire		[31:0]				M12ADDR, 
	input	wire		[38:0]				M12WDT, 

	// Signal To Master12
	output	wire							A12GNT, 

	// Signals From Master13
	input	wire							M13REQ, 
	input	wire							M13LK,
	input	wire							M13WT, 
	input	wire		[2:0]				M13SZ, 
	input	wire		[3:0]				M13RB, 
	input	wire		[2:0]				M13MOD, 
	input	wire		[31:0]				M13ADDR, 
	input	wire		[38:0]				M13WDT, 

	// Signal To Master13
	output	wire							A13GNT, 

	// Signals From Master14
	input	wire							M14REQ, 
	input	wire							M14LK,
	input	wire							M14WT, 
	input	wire		[2:0]				M14SZ, 
	input	wire		[3:0]				M14RB, 
	input	wire		[2:0]				M14MOD, 
	input	wire		[31:0]				M14ADDR, 
	input	wire		[38:0]				M14WDT, 

	// Signal To Master14
	output	wire							A14GNT, 

	// Signals From Master15
	input	wire							M15REQ, 
	input	wire							M15LK,
	input	wire							M15WT, 
	input	wire		[2:0]				M15SZ, 
	input	wire		[3:0]				M15RB, 
	input	wire		[2:0]				M15MOD, 
	input	wire		[31:0]				M15ADDR, 
	input	wire		[38:0]				M15WDT, 

	// Signal To Master15
	output	wire							A15GNT, 


	// Common Signals To All Masters
	output	wire		[38:0]				MsRDT, 
	output	wire							MsERR, 

	// Signals From Slave0
	input	wire							S0RDY, 
	input	wire							S0ERR, 
	input	wire		[38:0]				S0RDT, 

	// Signals From Slave1
	input	wire							S1RDY, 
	input	wire							S1ERR, 
	input	wire		[38:0]				S1RDT, 

	// Signals From Slave2
	input	wire							S2RDY, 
	input	wire							S2ERR, 
	input	wire		[38:0]				S2RDT, 

	// Signals From Slave3
	input	wire							S3RDY, 
	input	wire							S3ERR, 
	input	wire		[38:0]				S3RDT, 

	// Signals From Slave4
	input	wire							S4RDY, 
	input	wire							S4ERR, 
	input	wire		[38:0]				S4RDT, 

	// Signals From Slave5
	input	wire							S5RDY, 
	input	wire							S5ERR, 
	input	wire		[38:0]				S5RDT, 

	// Signals From Slave6
	input	wire							S6RDY, 
	input	wire							S6ERR, 
	input	wire		[38:0]				S6RDT, 

	// Signals From Slave7
	input	wire							S7RDY, 
	input	wire							S7ERR, 
	input	wire		[38:0]				S7RDT, 

	// Signals From Slave8
	input	wire							S8RDY, 
	input	wire							S8ERR, 
	input	wire		[38:0]				S8RDT, 

	// Signals From Slave9
	input	wire							S9RDY, 
	input	wire							S9ERR, 
	input	wire		[38:0]				S9RDT, 

	// Signals From Slave10
	input	wire							S10RDY, 
	input	wire							S10ERR, 
	input	wire		[38:0]				S10RDT, 

	// Signals From Slave11
	input	wire							S11RDY, 
	input	wire							S11ERR, 
	input	wire		[38:0]				S11RDT, 

	// Signals From Slave12
	input	wire							S12RDY, 
	input	wire							S12ERR, 
	input	wire		[38:0]				S12RDT, 

	// Signals From Slave13
	input	wire							S13RDY, 
	input	wire							S13ERR, 
	input	wire		[38:0]				S13RDT, 

	// Signals From Slave14
	input	wire							S14RDY, 
	input	wire							S14ERR, 
	input	wire		[38:0]				S14RDT, 

	// Signals From Slave15
	input	wire							S15RDY, 
	input	wire							S15ERR, 
	input	wire		[38:0]				S15RDT, 

	// Signals To Slave0
	output	wire							D0SEL, 

	// Signals To Slave1
	output	wire							D1SEL, 
	
	// Signals To Slave2
	output	wire							D2SEL, 

	// Signals To Slave3
	output	wire							D3SEL, 
	
	// Signals To Slave4
	output	wire							D4SEL, 

	// Signals To Slave5
	output	wire							D5SEL, 

	// Signals To Slave6
	output	wire							D6SEL, 

	// Signals To Slave7
	output	wire							D7SEL, 

	// Signals To Slave8
	output	wire							D8SEL, 

	// Signals To Slave9
	output	wire							D9SEL, 

	// Signals To Slave10
	output	wire							D10SEL, 

	// Signals To Slave11
	output	wire							D11SEL, 

	// Signals To Slave12
	output	wire							D12SEL, 

	// Signals To Slave13
	output	wire							D13SEL, 

	// Signals To Slave14
	output	wire							D14SEL, 

	// Signals To Slave15
	output	wire							D15SEL, 

	// Common Signals To All Slaves
	output	wire							MmWT, 
	output	wire		[2:0]				MmSZ, 
	output	wire		[3:0]				MmRB, 
	output	wire		[2:0]				MmMOD, 
	output  wire		[31:0]				MmADDR, 
	output  wire		[38:0]				MmWDT,
	output	wire							MmLK,

	// Common Signal To All Masters and All Slaves
	output	wire							MsRDY 
 );

 	wire	[15:0]		AxGNT;
	wire	[15:0]		MxREQ;
	wire	[15:0]		AmCMUX;
	wire				MmLST;

	assign		MxREQ = {11'b0, M4REQ, M3REQ, M2REQ, M1REQ, M0REQ};	

	assign		A15GNT = AxGNT[15];
	assign		A14GNT = AxGNT[14];
	assign		A13GNT = AxGNT[13];
	assign		A12GNT = AxGNT[12];

	assign		A11GNT = AxGNT[11];
	assign		A10GNT = AxGNT[10];
	assign		A9GNT = AxGNT[9];
	assign		A8GNT = AxGNT[8];

	assign		A7GNT = AxGNT[7];
	assign		A6GNT = AxGNT[6];
	assign		A5GNT = AxGNT[5];
	assign		A4GNT = AxGNT[4];

	assign		A3GNT = AxGNT[3];
	assign		A2GNT = AxGNT[2];
	assign		A1GNT = AxGNT[1];
	assign		A0GNT = AxGNT[0];

	ABT		CB_Arbiter	(
									// Common Control Signals
									.CLK				(CLK), 
									.nRST				(nRST), 

									// From Each Master
									.MxREQ				(MxREQ),
									
									// From M2S MUX
									.MmLK				(MmLK),
									.MmLST				(MmLST),

									// From S2M MUX
									.MsRDY				(MsRDY),
									.MsERR				(MsERR),
									
									// To Each Master
									.AxGNT				(AxGNT),

									// To M2S MUX
									.AmCMUX				(AmCMUX)
								);
	
	wire	[15:0]		DxSEL;
	wire	[15:0]		DmRMUX;

	assign		D15SEL = DxSEL[15];	
	assign		D14SEL = DxSEL[14];	
	assign		D13SEL = DxSEL[13];	
	assign		D12SEL = DxSEL[12];	

	assign		D11SEL = DxSEL[11];	
	assign		D10SEL = DxSEL[10];	
	assign		D9SEL = DxSEL[9];	
	assign		D8SEL = DxSEL[8];	

	assign		D7SEL = DxSEL[7];	
	assign		D6SEL = DxSEL[6];	
	assign		D5SEL = DxSEL[5];	
	assign		D4SEL = DxSEL[4];	

	assign		D3SEL = DxSEL[3];	
	assign		D2SEL = DxSEL[2];	
	assign		D1SEL = DxSEL[1];	
	assign		D0SEL = DxSEL[0];	

	DCD		CB_Decoder (
									// Common Control Signals
									.CLK				(CLK), 
									.nRST				(nRST), 
									
									// From M2S MUX
									.MmADDR				(MmADDR),
									.MmMOD				(MmMOD),

									// From Arbiter
									.AmCMUX				(AmCMUX),

									// From S2M MUX
									.MsRDY				(MsRDY),

									// To Slaves
									.DxSEL				(DxSEL),

									// To S2M MUX
									.DmRMUX				(DmRMUX)
								);

	CMUX	CB_CMUX (
									.MsRDY			(MsRDY),

									.M0LK			(M0LK),
									.M0WT			(M0WT),
									.M0SZ			(M0SZ),
									.M0RB			(M0RB),
									.M0MOD			(M0MOD),
									.M0ADDR			(M0ADDR),

									.M1LK			(M1LK),
									.M1WT			(M1WT),
									.M1SZ			(M1SZ),
									.M1RB			(M1RB),
									.M1MOD			(M1MOD),
									.M1ADDR			(M1ADDR),

									.M2LK			(M2LK),
									.M2WT			(M2WT),
									.M2SZ			(M2SZ),
									.M2RB			(M2RB),
									.M2MOD			(M2MOD),
									.M2ADDR			(M2ADDR),

									.M3LK			(M3LK),
									.M3WT			(M3WT),
									.M3SZ			(M3SZ),
									.M3RB			(M3RB),
									.M3MOD			(M3MOD),
									.M3ADDR			(M3ADDR),

									.M4LK			(M4LK),
									.M4WT			(M4WT),
									.M4SZ			(M4SZ),
									.M4RB			(M4RB),
									.M4MOD			(M4MOD),
									.M4ADDR			(M4ADDR),

									.M5LK			(M5LK),
									.M5WT			(M5WT),
									.M5SZ			(M5SZ),
									.M5RB			(M5RB),
									.M5MOD			(M5MOD),
									.M5ADDR			(M5ADDR),

									.M6LK			(M6LK),
									.M6WT			(M6WT),
									.M6SZ			(M6SZ),
									.M6RB			(M6RB),
									.M6MOD			(M6MOD),
									.M6ADDR			(M6ADDR),

									.M7LK			(M7LK),
									.M7WT			(M7WT),
									.M7SZ			(M7SZ),
									.M7RB			(M7RB),
									.M7MOD			(M7MOD),
									.M7ADDR			(M7ADDR),

									.M8LK			(M8LK),
									.M8WT			(M8WT),
									.M8SZ			(M8SZ),
									.M8RB			(M8RB),
									.M8MOD			(M8MOD),
									.M8ADDR			(M8ADDR),

									.M9LK			(M9LK),
									.M9WT			(M9WT),
									.M9SZ			(M9SZ),
									.M9RB			(M9RB),
									.M9MOD			(M9MOD),
									.M9ADDR			(M9ADDR),

									.M10LK			(M10LK),
									.M10WT			(M10WT),
									.M10SZ			(M10SZ),
									.M10RB			(M10RB),
									.M10MOD			(M10MOD),
									.M10ADDR		(M10ADDR),

									.M11LK			(M11LK),
									.M11WT			(M11WT),
									.M11SZ			(M11SZ),
									.M11RB			(M11RB),
									.M11MOD			(M11MOD),
									.M11ADDR		(M11ADDR),

									.M12LK			(M12LK),
									.M12WT			(M12WT),
									.M12SZ			(M12SZ),
									.M12RB			(M12RB),
									.M12MOD			(M12MOD),
									.M12ADDR		(M12ADDR),

									.M13LK			(M13LK),
									.M13WT			(M13WT),
									.M13SZ			(M13SZ),
									.M13RB			(M13RB),
									.M13MOD			(M13MOD),
									.M13ADDR		(M13ADDR),

									.M14LK			(M14LK),
									.M14WT			(M14WT),
									.M14SZ			(M14SZ),
									.M14RB			(M14RB),
									.M14MOD			(M14MOD),
									.M14ADDR		(M14ADDR),

									.M15LK			(M15LK),
									.M15WT			(M15WT),
									.M15SZ			(M15SZ),
									.M15RB			(M15RB),
									.M15MOD			(M15MOD),
									.M15ADDR		(M15ADDR),


									.AmCMUX			(AmCMUX),

									.MmLK			(MmLK),
									.MmWT			(MmWT),
									.MmSZ			(MmSZ),
									.MmRB			(MmRB),
									.MmLST			(MmLST),
									.MmMOD			(MmMOD),
									.MmADDR			(MmADDR)
								);

	WMUX	CB_WMUX	(
								.CLK			(CLK),
								.nRST			(nRST),

								.MsRDY			(MsRDY),

								.M0WDT			(M0WDT),
								.M1WDT			(M1WDT),
								.M2WDT			(M2WDT),
								.M3WDT			(M3WDT),

								.M4WDT			(M4WDT),
								.M5WDT			(M5WDT),
								.M6WDT			(M6WDT),
								.M7WDT			(M7WDT),
                                                   
								.M8WDT			(M8WDT),
								.M9WDT			(M9WDT),
								.M10WDT			(M10WDT),
								.M11WDT			(M11WDT),

								.M12WDT			(M12WDT),
								.M13WDT			(M13WDT),
								.M14WDT			(M14WDT),
								.M15WDT			(M15WDT),

								.AmCMUX			(AmCMUX),
								.MmWDT			(MmWDT)
							);
	
	RMUX	CB_RMUX	(
							.S0RDT			(S0RDT),
							.S0RDY			(S0RDY),
							.S0ERR			(S0ERR),

							.S1RDT			(S1RDT),
							.S1RDY			(S1RDY),
							.S1ERR			(S1ERR),

							.S2RDT			(S2RDT),
							.S2RDY			(S2RDY),
							.S2ERR			(S2ERR),

							.S3RDT			(S3RDT),
							.S3RDY			(S3RDY),
							.S3ERR			(S3ERR),

							.S4RDT			(S4RDT),
							.S4RDY			(S4RDY),
							.S4ERR			(S4ERR),

							.S5RDT			(S5RDT),
							.S5RDY			(S5RDY),
							.S5ERR			(S5ERR),

							.S6RDT			(S6RDT),
							.S6RDY			(S6RDY),
							.S6ERR			(S6ERR),

							.S7RDT			(S7RDT),
							.S7RDY			(S7RDY),
							.S7ERR			(S7ERR),

							.S8RDT			(S8RDT),
							.S8RDY			(S8RDY),
							.S8ERR			(S8ERR),

							.S9RDT			(S9RDT),
							.S9RDY			(S9RDY),
							.S9ERR			(S9ERR),

							.S10RDT			(S10RDT),
							.S10RDY			(S10RDY),
							.S10ERR			(S10ERR),

							.S11RDT			(S11RDT),
							.S11RDY			(S11RDY),
							.S11ERR			(S11ERR),

							.S12RDT			(S12RDT),
							.S12RDY			(S12RDY),
							.S12ERR			(S12ERR),

							.S13RDT			(S13RDT),
							.S13RDY			(S13RDY),
							.S13ERR			(S13ERR),

							.S14RDT			(S14RDT),
							.S14RDY			(S14RDY),
							.S14ERR			(S14ERR),

							.S15RDT			(S15RDT),
							.S15RDY			(S15RDY),
							.S15ERR			(S15ERR),

							.DmRMUX			(DmRMUX),

							.MsRDT			(MsRDT),
							.MsRDY			(MsRDY),
							.MsERR			(MsERR)
						);

endmodule


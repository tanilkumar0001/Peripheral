/****************************************************************************
*                                                                           *
*                             APB  Decoder                                  *
*                                                                           *
*****************************************************************************
*                                                                           *
*  Copyright (c) 2008 by Integrated Computer Systems Lab. (ICSL), KAIST     *
*                                                                           *
*  All rights reserved.                                                     *
*                                                                           *
*  Do Not duplicate without prior written consent of ICSL, KAIST.           *
*                                                                           *
*                                                                           *
*                                                  Designed By Ji-Hoon Kim  *
*                                                             Duk-Hyun You  *
*                                                                           *
*                                              Supervised By In-Cheol Park  *
*                                                                           *
*                                            E-mail : icpark@ee.kaist.ac.kr *
*                                                                           *
****************************************************************************/


module APB_DCD	
(
	input 	wire	[31:0]	PADDR,
	output	reg		[2:0]	PSEL
);

	// Address Decoding Map
	always@*
	begin
		casex(PADDR[17:16])
		// APB Slave 1 : 0x0000_0000 ~ 0x0000_FFFF
		2'b00 : PSEL <= 3'b010;

		// APB Slave 2 : 0x0001_0000 ~ 0x0001_FFFF
		2'b01 : PSEL <= 3'b100;

		// Default APB Slave : 0x0002_0000 ~ 0x0003_FFFF 
		2'b1x :   PSEL <= 3'b001;
		default : PSEL <= 3'b001;
		endcase
	end

endmodule
	

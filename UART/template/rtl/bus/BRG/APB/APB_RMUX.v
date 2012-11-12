/****************************************************************************
*                                                                           *
*                     APB  Read Date Multiplexor                            *
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


module APB_RMUX 
(
	input	wire	[31:0]		PRDATA0,
	
	input	wire	[31:0]		PRDATA1,

	input	wire	[31:0]		PRDATA2,

	input	wire	[2:0]		PSEL,

	output	reg		[31:0]		PRDATA
);	
	always@*
	begin
		case(PSEL)
		3'b100: PRDATA <= PRDATA2;
		3'b010: PRDATA <= PRDATA1;
		3'b001: PRDATA <= PRDATA0; 
		default:PRDATA <= PRDATA0;					//Default Slave 
		endcase
	end
endmodule

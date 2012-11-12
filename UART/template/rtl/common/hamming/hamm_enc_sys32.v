/**************************************************************************************
*                                                                                     *
*            Systematic Hamming Encoder with Double Error Detection                   *
*                                                                                     *
*                                                                                     *
*                                                                  Bongjin Kim        *
*                                                                  Byeong Yong Kong   *
*                                                                  Injae Yoo          *
*                                                                                     *
***************************************************************************************
*                                                                                     *
* Input:  32bit                                                                       *
* Output: 39bit                                                                       *
*                                                                                     *
* do[31:0] == di                                                                      *
* do: [3 3 3 3 3 3 3 3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0] *
*     [8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0 9 8 7 6 5 4 3 2 1 0] *
*      x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x x  *
*        x           x       x x     x   x   x   x     x x     x   x x x x   x x x x  *
*          x         x x     x   x   x x x x   x x x       x   x x x       x   x x    *
*            x         x x     x   x   x x x     x x x x     x   x   x   x   x x x    *
*              x         x x     x       x x       x x   x     x   x x x x x     x    *
*                x         x       x x     x x       x     x     x x x x   x x x x    *
*                  x         x         x       x       x     x                     x  *
*                                                                                     *
***************************************************************************************/


module HAMM_ENC_SYS32 (
	input	wire	[31:0]	DIN,
	output	wire	[38:0]	DOUT
);

	wire	[38:0]	parity_temp;

	assign	DOUT[31:0] = DIN;

	assign	DOUT[32] = ^{DIN[27], DIN[22], DIN[18], DIN[14], DIN[11], DIN[0]};
	assign	DOUT[33] = ^{DIN[28], DIN[24:23], DIN[20:19], DIN[15], DIN[12], DIN[9:6], DIN[4:1]};
	assign	DOUT[34] = ^{DIN[29:28], DIN[25], DIN[21:20], DIN[16:15], DIN[13], DIN[10], DIN[8:4], DIN[1]};
	assign	DOUT[35] = ^{DIN[30:29], DIN[26], DIN[24], DIN[22:20], DIN[17:14], DIN[11], DIN[9], DIN[7], DIN[5], DIN[3:1]};
	assign	DOUT[36] = ^{DIN[31:30], DIN[27], DIN[25], DIN[23:20], DIN[18:16], DIN[12], DIN[10:8], DIN[4], DIN[2:1]};
	assign	DOUT[37] = ^{DIN[31], DIN[27:26], DIN[23], DIN[21], DIN[19], DIN[17], DIN[14:13], DIN[10], DIN[8:5], DIN[3:0]};

	assign	DOUT[38] = ^DOUT[37:0];

endmodule

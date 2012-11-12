/**************************************************************************************
*                                                                                     *
*            Systematic Hamming Decoder with Double Error Detection                   *
*                                                                                     *
*                                                                                     *
*                                                                  Bongjin Kim        *
*                                                                  Byeong Yong Kong   *
*                                                                  Injae Yoo          *
*                                                                                     *
***************************************************************************************
*                                                                                     *
* Input:  39bit                                                                       *
* Output: 32bit                                                                       *
*         DED (Double error detection)                                                *
*                                                                                     *
* di: [3 3 3 3 3 3 3 3 3 2 2 2 2 2 2 2 2 2 2 1 1 1 1 1 1 1 1 1 1 0 0 0 0 0 0 0 0 0 0] *
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


module HAMM_DEC_SYS32 (
	input	wire	[38:0]	DIN,
	output	wire	[31:0]	DOUT,
	output	reg				SEC,
	output	reg				DED
);


wire	[38:0]	enc;

HAMM_ENC_SYS32 parity_gen (
	.DIN	(DIN[31:0]),
	.DOUT	(enc)
);

wire	[6:0]	parity_error;
assign			parity_error = DIN[38:32] ^ enc[38:32];

reg	[31:0]	correction;

always @*
begin
	casex(parity_error)
		7'b0_000000:{SEC, DED, correction} <= {1'b0, 1'b0, 32'h00000000}; 

		7'b1_100001:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000001}; 
		7'b0_111110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000002}; 
		7'b1_111010:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000004}; 
		7'b0_101010:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000008}; 
		7'b0_010110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000010}; 
		7'b0_101100:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000020}; 
		7'b0_100110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000040}; 
		7'b1_101110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000080}; 
		7'b1_110110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000100}; 
		7'b0_011010:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000200}; 
		7'b0_110100:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000400}; 
		7'b1_001001:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00000800}; 
		7'b1_010010:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00001000}; 
		7'b1_100100:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00002000}; 
		7'b0_101001:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00004000}; 
		7'b0_001110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00008000}; 
		7'b0_011100:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00010000}; 
		7'b0_111000:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00020000}; 
		7'b1_010001:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00040000}; 
		7'b1_100010:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00080000}; 
		7'b1_011110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00100000}; 
		7'b1_111100:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00200000}; 
		7'b0_011001:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00400000}; 
		7'b0_110010:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h00800000}; 
		7'b1_001010:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h01000000}; 
		7'b1_010100:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h02000000}; 
		7'b1_101000:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h04000000}; 
		7'b0_110001:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h08000000}; 
		7'b1_000110:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h10000000}; 
		7'b1_001100:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h20000000}; 
		7'b1_011000:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h40000000}; 
		7'b1_110000:{SEC, DED, correction} <= {1'b1, 1'b0, 32'h80000000}; 

		    default:{SEC, DED, correction} <= {1'b0, 1'b1, 32'h00000000};
	endcase
end

assign	DOUT = DIN[31:0] ^ correction;

endmodule

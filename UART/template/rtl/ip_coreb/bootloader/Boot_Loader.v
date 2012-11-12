//===================================================
//	
//	Boot Loader for Core-A System
//		Based on Core-B Lite
//					
//					Ver 2010_1
//
//					YoungJoo Lee
//
//===================================================


module Boot_Loader #(
	// note that address & size is a word-size address
	parameter MEMB_START = 30'h0000_2000,
		  MEM0_SIZE = 2048,
		  MEM1_SIZE = 0,
		  MEM0_START = 0,
		  MEM1_START = 0
) (
	/*Core Reset*/
	output	wire		nRST_CORE,
	
	/*boot end => 1, initially 0*/
	output	wire		BOOT_END,
	
	/*Memory I/O (Core)*/
	output	wire	[29:0]	A,
	input	wire	[31:0]	DIN,
	output	wire	[31:0]	DOUT,
	output	wire		nREQ,
	output	wire		WEN,
	input	wire		nWAIT,

	input	wire		CLK,
	input	wire		nRST
);


/*FSM*/
reg	[3:0]	state;
wire	[3:0]	next_state;
wire		end_m0;
wire		end_m1;
wire		latch_d;
wire		rst_mb_addr;
wire		inc_mb_addr;
wire		rst_m0_addr;
wire		inc_m0_addr;
wire		rst_m1_addr;
wire		inc_m1_addr;
wire		CEN_MB;
wire		CEN_M0;
wire		CEN_M1;

reg	[29:0]	addr_mb;
reg	[29:0]	addr_m0;
reg	[29:0]	addr_m1;
reg	[31:0]	latched_data;

/* State control */
always @ (posedge CLK)
begin
	if(~nRST)
	begin
		state 		<= 4'd0;
	end
	else
	begin
		state 		<= next_state;
	end
end

/* Latched data control */
always @ (posedge CLK)
begin
	if(latch_d)
	begin
		latched_data	<= DIN;
	end
end

/* addr_mb control */
always @ (posedge CLK)
begin
	if(rst_mb_addr)
	begin
		addr_mb		<= MEMB_START[29:0];
	end
	else
	begin
		if(inc_mb_addr)
		begin
			addr_mb <= addr_mb + 30'b1;
		end
	end
end

/* addr_m0 control */
always @ (posedge CLK)
begin
	if(rst_m0_addr)
	begin
		addr_m0		<= MEM0_START[29:0];
	end
	else
	begin
		if(inc_m0_addr)
		begin
			addr_m0 <= addr_m0 + 30'b1;
		end
	end
end

/* addr_m1 control */
always @ (posedge CLK)
begin
	if(rst_m1_addr)
	begin
		addr_m1		<= MEM1_START[29:0];
	end
	else
	begin
		if(inc_m1_addr)
		begin
			addr_m1 <= addr_m1 + 30'b1;
		end
	end
end

/* Signals generation for control */
assign end_m0	= (addr_m0 == (MEM0_START + MEM0_SIZE));
assign end_m1	= (addr_m1 == (MEM1_START + MEM1_SIZE));

BOOT_CTRL BOOT_Controller (
		.state		(state),
		.end_m0		(end_m0),
		.end_m1		(end_m1),
		.nWAIT		(nWAIT),
		.latch_d	(latch_d),
		.rst_mb_addr	(rst_mb_addr),
		.inc_mb_addr	(inc_mb_addr),
		.rst_m0_addr	(rst_m0_addr),
		.inc_m0_addr	(inc_m0_addr),
		.rst_m1_addr	(rst_m1_addr),
		.inc_m1_addr	(inc_m1_addr),
		.CEN_MB		(CEN_MB),
		.CEN_M0		(CEN_M0),
		.CEN_M1		(CEN_M1),
		.nRST_CORE	(nRST_CORE),
		.BOOT_END	(BOOT_END),
		.next_state	(next_state)
);


/* External component control */
 
assign A = ({CEN_MB, CEN_M0, CEN_M1} == 3'b011) ? addr_mb :
	   ({CEN_MB, CEN_M0, CEN_M1} == 3'b101) ? addr_m0 : 
	   ({CEN_MB, CEN_M0, CEN_M1} == 3'b110) ? addr_m1 :
	   {30{1'bx}};

assign DOUT = latched_data;
assign nREQ = &{CEN_MB, CEN_M0, CEN_M1};
assign WEN = ({CEN_MB, CEN_M0 & CEN_M1} == 2'b01) ? 1'b1 : 
	     ({CEN_MB, CEN_M0 & CEN_M1} == 2'b10) ? 1'b0 : 1'b1;
     
endmodule


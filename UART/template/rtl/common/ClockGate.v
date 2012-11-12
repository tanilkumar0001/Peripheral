module ClockGate (
	input	wire	en,
	input	wire	CLK,
	output	wire	gCLK
);

`ifdef	_STD130_	// Samsung 0.18um
	// synopsys dc_script_begin
	// set_dont_touch cg
	// synopsys dc_script_end
	cglpd4 cg(
		.TE	(1'b1),
		.EN	(en),
		.CK	(CLK),
		.GCK	(gCLK)
	);

`elsif	_MH018_		// Magnachip 0.18um
	// synopsys dc_script_begin
	// set_dont_touch cg
	// synopsys dc_script_end
	TLATNCAX8 cg(
		.E	(en),
		.CK	(CLK),
		.ECK	(gCLK)
	);

`elsif	_DB013_		// Dongbu 0.13um
	// synopsys dc_script_begin
	// set_dont_touch cg
	// synopsys dc_script_end
	SDN_CKGTPLT_8 cg (
		.EN	(en),
		.SE	(1'b0),
		.CK	(CLK),
		.Q	(gCLK)
	);

`elsif	_STD150E_	// Samsung 0.13um
	// synopsys dc_script_begin
	// set_dont_touch cg
	// synopsys dc_script_end
	cglpd20_hd	cg(
		.TE(1'b0),
		.EN(en),
		.CK(CLK),
		.GCK(gCLK)
	);

`elsif	_NAN45_		// NANGATE 45nm
	// synopsys dc_script_begin
	// set_dont_touch cg
	// synopsys dc_script_end
	CLKGATETST_X4 cg (
		.E	(en),
		.SE	(1'b1),
		.CK	(CLK),
		.GLK	(gCLK)
	);
`else

	wire	nFreeze;
	LatchN	freezeLatch (
		.CLK	(CLK),
		.D	(en),
		.Q	(nFreeze)
	);

	`ifdef	_XILINX_
	BUFGCE	CLOCK_BUF (
		.O	(gCLK),
		.CE	(nFreeze),
		.I	(CLK)
	);
	`else
	assign	gCLK	= nFreeze & CLK;
	`endif

`endif


endmodule

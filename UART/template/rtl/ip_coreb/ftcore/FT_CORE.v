module FT_CORE (
	input	wire			CLK,
	input	wire			RST,

	input	wire			INT,
	output	wire			INT_ACK,

	output	wire			IREAD,
	output	wire	[29:0]	IADDR,
	output	wire			IRW,
	output	wire	[38:0]	IWDATA,
	input	wire	[38:0]	IRDATA,
	input	wire			IFAULT,
	input	wire			nIWAIT,

	output	wire			DREQ,
	output	wire	[31:0]	DADDR,
	output	wire			DRW,
	output	wire			DLOCK,
	output	wire	[1:0]	DTYPE,
	output	wire			DMODE,
	output	wire	[1:0]	DSIZE,
	output	wire	[38:0]	DWDATA,
	input	wire	[38:0]	DRDATA,
	input	wire			DFAULT,
	input	wire			nDWAIT,

	input	wire			CPINT
);

	wire			core_ireq;
	wire	[29:0]	core_iaddr;
	wire	[31:0]	core_instr;
	wire			core_ided;
	wire			core_niwait;

	IMEM_Shell	#(
		.REWRITE_EN(1)
	) imem_shell (
		.CLK		(CLK),
		.RST		(RST),

		// From MEMORY
		.IRDATAi	(IRDATA),
		.nIWAITi	(nIWAIT),

		// To MEMORY
		.IREQo		(IREAD),
		.IADDRo		(IADDR),
		.IRWo		(IRW),	// 0RD 1ST
		.IWDATAo	(IWDATA),

		// From CORE
		.IREQi		(core_ireq),
		.IADDRi		(core_iaddr),

		// To CORE
		.IRDATAo	(core_instr),
		.IMEM_DEDo	(core_ided),
		.nIWAITo	(core_niwait)
	);

	wire			core_dreq;
	wire	[31:0]	core_daddr;
	wire			core_drw;
	wire			core_dlock;
	wire	[1:0]	core_dtype;
	wire			core_dmode;
	wire	[1:0]	core_dsize;
	wire	[31:0]	core_dwdata;
	wire	[31:0]	core_drdata;
	wire			core_dded;
	wire			core_ndwait;

	DMEM_Shell #(
		.REWRITE_EN(1)
	) dmem_shell (
		.CLK		(CLK),
		.RST		(RST),

		// From MEMORY
		.DRDATAi	(DRDATA),
		.nDWAITi	(nDWAIT),

		// To MEMORY
		.DREQo		(DREQ),		
		.DADDRo		(DADDR),
		.DRWo		(DRW),	// 0RD 1WT
		.DLOCKo		(DLOCK),
		.DTYPEo		(DTYPE),
		.DMODEo		(DMODE),
		.DSIZEo		(), // always 2'b10
		.DWDATAo	(DWDATA),

		// From CORE
		.DREQi		(core_dreq),
		.DADDRi		(core_daddr),
		.DRWi		(core_drw),	// 0RD 1WT
		.DLOCKi		(core_dlock),
		.DTYPEi		(core_dtype),
		.DMODEi		(core_dmode),
		.DSIZEi		(core_dsize),
		.DWDATAi	(core_dwdata),

		// To CORE
		.DRDATAo	(core_drdata),
		.DMEM_DEDo	(core_dded),
		.nDWAITo	(core_ndwait)
	);

	assign	DSIZE = 2'b10;


	CoreA	internal_corea	(
		.CLK		(CLK),			// EXTERNAL CLOCK
		.RST		(RST),			// ASYNC. RESET

		.INT		(INT),			// EXT. INTERRUPT
		.INT_ACK	(INT_ACK),		// EXT. INTERRUPT ACK.

		.IREAD		(core_ireq),	// IMEM. REQUEST
		.IADDR		(core_iaddr),	// IMEM. ADDRESS
		.INSTR		(core_instr),	// INSTRUCTION
		.IFAULT		(IFAULT),		// IMMU FAULT
		.IMEM_DED	(core_ided),	// IMEM. DED
		.nIWAIT		(core_niwait),	// IMEM. READY

		.DREQ		(core_dreq),	// DMEM. REQUEST
		.DADDR		(core_daddr),	// DMEM. ADDRESS
		.DRW		(core_drw),		// DMEM. READ/WRITE
		.DLOCK		(core_dlock),	// DMEM. BUS LOCK
		.DTYPE		(core_dtype),	// DMEM. REQUEST TYPE
		.DMODE		(core_dmode),	// OPERATING MODE
		.DSIZE		(core_dsize),	// DMEM. SIZE
		.DWDATA		(core_dwdata),	// DMEM. WRITE DATA
		.DRDATA		(core_drdata),	// DMEM. READ DATA
		.DFAULT		(DFAULT),		// DMMU FAULT
		.DMEM_DED	(core_dded),	// DMEM. DED
		.nDWAIT		(core_ndwait),	// DMEM. READY

		.CPINT		(CPINT)			// COPROCESSOR INTERRUPT
	);



endmodule

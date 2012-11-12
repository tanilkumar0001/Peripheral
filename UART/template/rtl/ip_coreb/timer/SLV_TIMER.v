// =======================================================
//  Bongjin Kim
//  20111025
//  
//  Core-B SLAVE of Timer
// =======================================================

module SLV_TIMER (

    // Common Control Signals
    input   wire                    CLK, 
    input   wire                    nRST, 

    // Signals From Core-B Lite On-Chip High-Speed Bus
    input   wire                    DxSEL,
    input   wire                    MmWT,
    input   wire        [2:0]       MmSZ,
    input   wire        [3:0]       MmRB,
    input   wire        [2:0]       MmMOD,
    input   wire        [31:0]      MmADDR, 
    input   wire        [38:0]      MmWDT,  
    input   wire                    MsRDY,

    // Signals To Core-B Lite On-Chip High-Speed Bus
    output  wire        [38:0]      SxRDT,   
    output  wire                    SxRDY,
    output  wire                    SxERR,

    output  wire                    INT,
    input   wire                    INT_ACK,

	input	wire					ETH_INT,
	input	wire					I2C_INT_0,
	input	wire					I2C_INT_1,
	input	wire					SPI_INT_0,
	input	wire					SPI_INT_1,

    input   wire                    EXT_INT,
    output  wire                    EXT_INT_ACK
);

wire                    SCx_REQ, SCx_WT, SCx_nWAIT, SCx_FAULT, SCx_TimeOut;
wire        [31:0]      SCx_ADDR;
wire		[38:0]		SCx_RDT;
wire		[38:0]		SCx_WDT;
wire        [3:0]       SCx_BE;  


SLV_WRP   slv_wrp_timer (
                            .CLK                (CLK),
                            .nRST               (nRST),

                            // Input from Core-B Lite On-Chip High-Speed Bus
                            .DxSEL              (DxSEL),

                            .MmWT               (MmWT),
                            .MmSZ               (MmSZ),
                            .MmRB               (MmRB),
                            .MmMOD              (MmMOD),
                            .MmADDR             (MmADDR),
                            .MmWDT              (MmWDT),

                            .MsRDY              (MsRDY),

                            // Output to Core-B Lite On-Chip High-Speed Bus
                            .SxRDY               (SxRDY),
                            .SxERR               (SxERR),
                            .SxRDT               (SxRDT),

                            // Slave Core Interface
                            .SCx_nWAIT           (SCx_nWAIT),
                            .SCx_FAULT           (SCx_FAULT),
                            .SCx_TimeOut         (SCx_TimeOut),
                            .SCx_RDT             (SCx_RDT),

                            .SCx_REQ             (SCx_REQ),
                            .SCx_WT              (SCx_WT),
                            .SCx_BE              (SCx_BE),
                            .SCx_ADDR            (SCx_ADDR),
                            .SCx_WDT             (SCx_WDT)
                        );

Timer timer_core (
                     .CLK            (CLK),
                     .RST            (~nRST),

                     .INT            (INT),
                     .INT_ACK        (INT_ACK),

                     .DREQ           (SCx_REQ),
                     .DRW            (SCx_WT),
                     .DADDR          (SCx_ADDR[3:2]),
                     .WDATA          (SCx_WDT),
                     
                     .RDATA          (SCx_RDT),
                     .DRDY           (SCx_nWAIT),

					 .ETH_INT		 (ETH_INT),
					 .I2C_INT_0		 (I2C_INT_0),
					 .I2C_INT_1		 (I2C_INT_1),
					 .SPI_INT_0		 (SPI_INT_0),
					 .SPI_INT_1		 (SPI_INT_1),

                     .EXT_INT        (EXT_INT),
                     .EXT_INT_ACK    (EXT_INT_ACK)
                 );

assign SCx_TimeOut = 1'b0;
assign SCx_FAULT = 1'b0;
        
endmodule

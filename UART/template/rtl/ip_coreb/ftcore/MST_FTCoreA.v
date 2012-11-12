/****************************************************************************
*                                                                           *
*               Master Fault Tolerant Core-A                                *
*                                                                           *
*****************************************************************************
*                                                                           *
*  Description :  FTCore-A(Master Core) + Master Wrapper                    *
*                                                                           *
*       Master 1 : Core-A Instruction Memory I/F                            *
*       Master 2 : Core-A Data        Memory I/F                            *
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
*                                                              Jinook Song  *
*                                                   Revised By Bongjin Kim  *
*                                                                           *
*                                              Supervised By In-Cheol Park  *
*                                                                           *
*                                            E-mail : icpark@ee.kaist.ac.kr *
*                                                                           *
****************************************************************************/

module MST_FTCoreA (
    // Common Control Signals
    input   wire                        CLK,
    input   wire                        nRST,

    input   wire                        INT,
    output  wire                        INT_ACK,

    // Signals From Core-B Lite On-Chip High-Speed Bus
    input   wire                        A1GNT,
    input   wire                        A2GNT,

    input   wire         [38:0]         MsRDT,
    input   wire                        MsRDY,
    input   wire                        MsERR,

    // Signals To Core-B Lite On-Chip High-Speed Bus
    output  wire                        M1REQ,
    output  wire                        M1LK,
    output  wire                        M1WT,        // 1:Write   0:Read
    output  wire         [2:0]          M1SZ,
    output  wire         [3:0]          M1RB,
    output  wire         [2:0]          M1MOD,
    output  wire         [31:0]         M1ADDR,
    output  wire         [38:0]         M1WDT,

    output  wire                        M2REQ,
    output  wire                        M2LK,
    output  wire                        M2WT,        // 1:Write   0:Read
    output  wire         [2:0]          M2SZ,
    output  wire         [3:0]          M2RB,
    output  wire         [2:0]          M2MOD,
    output  wire         [31:0]         M2ADDR,
    output  wire         [38:0]         M2WDT
);

    //////////////////////////////////
    //   Master  Signals Define     //
    //////////////////////////////////
    wire                    MC_RST = ~nRST; // Master Core RESET
	reg						L_MC_RST;
	always @ (posedge CLK)
		L_MC_RST <= MC_RST;

    //////////////////////////////////
    //   Master 1 Signals Define    //
    //////////////////////////////////
    wire                    MC1_REQ;
    wire    [29:0]          MC1_WD_ADDR;    //Master Core 1 Word Address 
    wire    [31:0]          MC1_ADDR = {MC1_WD_ADDR, 2'b0};
    wire                    MC1_WT;
    wire                    MC1_LK = 1'b0;
    wire    [2:0]           MC1_SZ = 3'b010;
    wire    [38:0]          MC1_WDT;
    wire    [38:0]          MC1_RDT;
    wire                    MC1_nWAIT;

    wire    [3:0]           MC1_RB = 4'b0;
    wire    [2:0]           MC1_MOD = {1'b0, MC1_REQ, 1'b0};

    //////////////////////////////////
    //   Master 2 Signals Define    //
    //////////////////////////////////
    wire                    MC2_REQ;
    wire    [31:0]          MC2_ADDR;
    wire                    MC2_WT;
    wire                    MC2_LK;
    wire    [2:0]           MC2_SZ = 3'b010;
    wire    [38:0]          MC2_WDT;
    wire    [38:0]          MC2_RDT;
    wire                    MC2_nWAIT;
    
    wire    [3:0]           MC2_RB = 4'b0;
    wire    [2:0]           MC2_MOD = {1'b0, MC2_REQ, 1'b0};


    //////////////////////////////////
    //      Master FT Core-A        //
    //////////////////////////////////
    FT_CORE   MST_CORE (
            .CLK        (CLK),
            .RST        (L_MC_RST),

            // EXTERNAL INTERRUPT
            .INT        (INT),
            .INT_ACK    (INT_ACK),

            // INSTRUCTION MEMORY   : Master Core 1
            .IREAD      (MC1_REQ),
            .IADDR      (MC1_WD_ADDR),
            .IRW        (MC1_WT),
            .IWDATA     (MC1_WDT),
            .IRDATA     (MC1_RDT),
            .IFAULT     (1'b0),
            .nIWAIT     (MC1_nWAIT),

            // DATA MEMORY          : Master Core 2
            .DREQ       (MC2_REQ),
            .DADDR      (MC2_ADDR),
            .DRW        (MC2_WT),
            .DLOCK      (MC2_LK),
            .DTYPE      (),
            .DMODE      (),
            .DSIZE      (),
            .DWDATA     (MC2_WDT),
            .DRDATA     (MC2_RDT),
            .DFAULT     (1'b0),
            .nDWAIT     (MC2_nWAIT),

            // COPROCESSOR
            .CPINT      (1'b0)
        );



MST_WRP     M1_WRP (
                            .CLK                (CLK),
                            .nRST               (nRST),

                            .MCx_REQ            (MC1_REQ),
                            .MCx_LK             (MC1_LK),
                            .MCx_WT             (MC1_WT),
                            .MCx_SZ             (MC1_SZ),
                            .MCx_RB             (MC1_RB),
                            .MCx_MOD            (MC1_MOD),
                            .MCx_ADDR           (MC1_ADDR),
                            .MCx_WDT            (MC1_WDT),

                            .MCx_nWAIT          (MC1_nWAIT),
                            .MCx_ERR            (),
                            .MCx_RDT            (MC1_RDT),

                            .AxGNT              (A1GNT),
                            .MsRDY              (MsRDY),
                            .MsERR              (MsERR),
                            .MsRDT              (MsRDT),

                            .MxREQ              (M1REQ),
                            .MxLK               (M1LK),
                            .MxWT               (M1WT),
                            .MxSZ               (M1SZ),
                            .MxRB               (M1RB),
                            .MxMOD              (M1MOD),
                            .MxADDR             (M1ADDR),
                            .MxWDT              (M1WDT)
                        );



MST_WRP     M2_WRP (
                            .CLK                (CLK),
                            .nRST               (nRST),

                            .MCx_REQ            (MC2_REQ),
                            .MCx_LK             (MC2_LK),
                            .MCx_WT             (MC2_WT),
                            .MCx_SZ             (MC2_SZ),
                            .MCx_RB             (MC2_RB),
                            .MCx_MOD            (MC2_MOD),
                            .MCx_ADDR           (MC2_ADDR),
                            .MCx_WDT            (MC2_WDT),

                            .MCx_nWAIT          (MC2_nWAIT),
                            .MCx_ERR            (),
                            .MCx_RDT            (MC2_RDT),

                            .AxGNT              (A2GNT),
                            .MsRDY              (MsRDY),
                            .MsERR              (MsERR),
                            .MsRDT              (MsRDT),

                            .MxREQ              (M2REQ),
                            .MxLK               (M2LK),
                            .MxWT               (M2WT),
                            .MxSZ               (M2SZ),
                            .MxRB               (M2RB),
                            .MxMOD              (M2MOD),
                            .MxADDR             (M2ADDR),
                            .MxWDT              (M2WDT)
                        );

endmodule

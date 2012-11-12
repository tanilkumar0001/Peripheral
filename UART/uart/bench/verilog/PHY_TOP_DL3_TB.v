/********************************************************************************
 *																				*
 *		PHY_TOP_DL3_TB.v  Ver 0.1													*
 *																				*
 *		COPYRIGHT (C) SAMSUNG THALES CO., LTD. ALL RIGHTS RESERVED				*
 *																				*
 *		Designed by	Yoon Dong Joon												*
 *																				*
 ********************************************************************************
 *																				*
 *		Support Verilog 2001 Syntax												*
 *																				*
 *		Update history : 2007.12.26	 original authored (Ver.0.1)				*
 *																				*
 ********************************************************************************/	

`timescale 1ns/1ps

`define SDSP_DELAY		5
`define RDSP_DELAY		5
`define LowMAC_DELAY	5
`define IF_DELAY		5

module PHY_TOP_DL3_TB(
);

//---------------------------------------------------------------------------
//	Clock and Reset Signals
//---------------------------------------------------------------------------
reg				CLK;
reg				CLK40M;
reg				SYSPORn;

//---------------------------------------------------------------------------
//	Scheduler DSP Interface Signals
//---------------------------------------------------------------------------
reg				SDSP_CLK;     
reg				SDSP_CEn;
reg		[20:0]	SDSP_ADDR;
wire	[15:0]	SDSP_DATA;
reg				SDSP_WEn;
reg				SDSP_OEn;

wire			SDSP_Report_IRQn;

//---------------------------------------------------------------------------
//	Ranging DSP Interface Signals
//---------------------------------------------------------------------------
reg				RDSP_CLK;     
reg				RDSP_CEn;
reg		[22:0]	RDSP_ADDR;
wire	[31:0]	RDSP_DATA;
reg				RDSP_WEn;
reg				RDSP_OEn;

wire			RDSP_RngBuffer_IRQn;
wire			RDSP_Report_IRQn;

//---------------------------------------------------------------------------
//	LowMAC Interface Signals
//---------------------------------------------------------------------------
reg				DL_LowMAC_IRQ;
wire			DL_LowMAC_Ready;
wire			DL_LowMAC_CE;
wire	[11:0]	DL_LowMAC_ADDR;
reg		[31:0]	DL_LowMAC_DATA;

reg				UL_LowMAC_CE;
reg		[13:0]	UL_LowMAC_ADDR;
wire	[31:0]	UL_LowMAC_DATA;	
wire			UL_LowMAC_IRQ;  
reg				UL_LowMAC_Ready;  

//---------------------------------------------------------------------------
//	TDD_Sync & Control Signals
//---------------------------------------------------------------------------			  
reg				GPS_Sync;
wire			DL_5msTic;
wire			UL_5msTic;
wire			DL_Sync;

//---------------------------------------------------------------------------
//	IF Interface Signals
//---------------------------------------------------------------------------
wire	[15:0]	DL_IF_DATA;
reg		[15:0]	UL_A1_IF_Data;
reg		[15:0]	UL_A2_IF_Data;


//---------------------------------------------------------------------------
//	PHY_TOP
//---------------------------------------------------------------------------
PHY_TOP uPHY_TOP(
	.CLK					(CLK),
	.CLK40M					(CLK40M),
	.SYSPORn				(SYSPORn),
	
	.SDSP_CLK				(SDSP_CLK),     
	.SDSP_CEn				(SDSP_CEn),
	.SDSP_ADDR				(SDSP_ADDR[20:1]),
	.SDSP_DATA				(SDSP_DATA),
	.SDSP_WEn				(SDSP_WEn),
	.SDSP_OEn				(SDSP_OEn),
	
	.SDSP_Report_IRQn		(SDSP_Report_IRQn),
	
	.RDSP_CLK				(RDSP_CLK),     
	.RDSP_CEn				(RDSP_CEn),
	.RDSP_ADDR				(RDSP_ADDR[22:3]),
	.RDSP_DATA				(RDSP_DATA),
	.RDSP_WEn				(RDSP_WEn),
	.RDSP_OEn				(RDSP_OEn),
	
	.RDSP_RngBuffer_IRQn	(RDSP_RngBuffer_IRQn),
	.RDSP_Report_IRQn		(RDSP_Report_IRQn),
	
	.DL_LowMAC_IRQ			(DL_LowMAC_IRQ),
	.DL_LowMAC_Ready		(DL_LowMAC_Ready),
	.DL_LowMAC_CE			(DL_LowMAC_CE),
	.DL_LowMAC_ADDR			(DL_LowMAC_ADDR),
	.DL_LowMAC_DATA			(DL_LowMAC_DATA),
	
	.UL_LowMAC_CE			(UL_LowMAC_CE),
	.UL_LowMAC_ADDR			(UL_LowMAC_ADDR),
	.UL_LowMAC_DATA			(UL_LowMAC_DATA),	
	.UL_LowMAC_IRQ			(UL_LowMAC_IRQ),  
	.UL_LowMAC_Ready		(UL_LowMAC_Ready),  
	
	.GPS_Sync				(GPS_Sync),
	.DL_5msTic				(DL_5msTic),
	.UL_5msTic				(UL_5msTic),
	.DL_Sync				(DL_Sync),
	
	.DL_IF_DATA				(DL_IF_DATA),
	.UL_A1_IF_Data			(UL_A1_IF_Data),
	.UL_A2_IF_Data			(UL_A2_IF_Data),
	
    .DAC_CS					(),	
    .DAC_CLK				(),	
    .DAC_SDI				(),	
    .DAC_SDO				(),
    
	.LED0					(),
	.LED1					()
);

//---------------------------------------------------------------------------
//	Initialize & Clock, Reset Generation
//---------------------------------------------------------------------------
initial
begin
			CLK			<= 1'b0;
			CLK40M		<= 1'b0;
			SYSPORn		<= 1'b0;
			SDSP_CLK	<= 1'b0;
			RDSP_CLK	<= 1'b0;
			DL_LowMAC_IRQ	<= 1'b1;
			
	#500	SYSPORn		<= 1'b1;
	#15000	DL_LowMAC_IRQ	<= 1'b0;
	#50		DL_LowMAC_IRQ	<= 1'b1;
end 

always      
	#7.8125	CLK	<= !CLK;	
	
always      
	#15.625	CLK40M	<= !CLK40M;	
	
always      
	#10		SDSP_CLK	<= !SDSP_CLK;	

always      
	#10		RDSP_CLK	<= !RDSP_CLK;	

//---------------------------------------------------------------------------
//	SDSP Interface
//---------------------------------------------------------------------------
`define SDSP_READY				4'b0000
`define SDSP_GLOBAL_REG			4'b0001
`define SDSP_INT_CTRL			4'b0010
`define SDSP_DAC_CTRL			4'b0011
`define SDSP_DL_FRAME_REG		4'b0100
`define SDSP_UL_FRAME_REG		4'b0101
`define SDSP_UL_BURSTINFO_RAM	4'b0110
`define	SDSP_WAIT				4'b0111
	
reg		[15:0]	SDSP_WDATA;
wire	[15:0]	SDSP_RDATA;

reg		[3:0]	SDSP_State;		
wire 	[15:0]	GlobalCtrlReg[0:6];
reg		[10:0]	iSDSP_BusCnt;
reg		[15:0]	iSDSP_Data;

reg				iSystem_Ready;

integer			InFILE1;

assign GlobalCtrlReg[0]	= 16'h4A59;		// RegLock;       
assign GlobalCtrlReg[1]	= 16'h0004;		// Mode;          
assign GlobalCtrlReg[2]	= 16'h0000;		// DL_Delay;      
assign GlobalCtrlReg[3]	= 16'h0AAA;		// DL_FFTScaleSch;
assign GlobalCtrlReg[4]	= 16'h0000;		// UL_Delay;      
assign GlobalCtrlReg[5]	= 16'h0000;		// UL_FFTScaleSch;
assign GlobalCtrlReg[6]	= 16'h0000;		// SW_RESETn, dummy;

always@(posedge SDSP_CLK, negedge SYSPORn)
begin
	if(!SYSPORn) begin
		SDSP_CEn		<= 1'b1;
		SDSP_ADDR		<= 21'd0;
		SDSP_WDATA		<= 16'd0;
		SDSP_WEn		<= 1'b1;
		SDSP_OEn		<= 1'b1;
		iSDSP_BusCnt	<= 11'd0;
		iSystem_Ready	<= 1'b0;
		SDSP_State		<= `SDSP_GLOBAL_REG;
	end
	else begin
		if(SDSP_State == `SDSP_READY) begin

		end
		else if(SDSP_State == `SDSP_GLOBAL_REG) begin
			if(iSDSP_BusCnt == 7) begin
				SDSP_CEn		<= #`SDSP_DELAY	1'b1;
				SDSP_ADDR		<= #`SDSP_DELAY	21'd0;
				SDSP_WDATA		<= #`SDSP_DELAY	16'd0;
				SDSP_WEn		<= #`SDSP_DELAY	1'b1;
				iSDSP_BusCnt	<= 11'd0;
				SDSP_State		<= `SDSP_WAIT;	
			end
			else begin
				SDSP_CEn		<= #`SDSP_DELAY	1'b0;
				SDSP_ADDR		<= #`SDSP_DELAY	{6'd0,3'b000,iSDSP_BusCnt, 1'b0};
				SDSP_WDATA		<= #`SDSP_DELAY	GlobalCtrlReg[iSDSP_BusCnt];
				SDSP_WEn		<= #`SDSP_DELAY	1'b0;
				iSDSP_BusCnt	<= iSDSP_BusCnt + 1;
			end		
		end
		else if(SDSP_State == `SDSP_DL_FRAME_REG) begin
			if(iSDSP_BusCnt == 36) begin
				$fclose(InFILE1);	
				SDSP_ADDR		<= #`SDSP_DELAY	{6'd0,3'b011,11'h24, 1'b0};
				SDSP_WDATA		<= #`SDSP_DELAY	16'd0;
				iSDSP_BusCnt	<= iSDSP_BusCnt + 1;
			end
			else if(iSDSP_BusCnt == 37) begin
				SDSP_CEn		<= #`SDSP_DELAY	1'b1;
				SDSP_ADDR		<= #`SDSP_DELAY	21'd0;
				SDSP_WDATA		<= #`SDSP_DELAY	16'd0;
				SDSP_WEn		<= #`SDSP_DELAY	1'b1;
				iSDSP_BusCnt	<= 11'd0;
				SDSP_State		<= `SDSP_READY;	
			end
			else begin
				$fscanf(InFILE1,"%x",iSDSP_Data);
			
				SDSP_CEn		<= #`SDSP_DELAY	1'b0;
				SDSP_ADDR		<= #`SDSP_DELAY	{6'd0,3'b011,iSDSP_BusCnt, 1'b0};
				SDSP_WDATA		<= #`SDSP_DELAY	iSDSP_Data;
				SDSP_WEn		<= #`SDSP_DELAY	1'b0;	
				iSDSP_BusCnt	<= iSDSP_BusCnt + 1;
			end
		end
		else if(SDSP_State == `SDSP_WAIT) begin
			if(iSDSP_BusCnt == 10) begin
				iSystem_Ready	<= 1'b1;
				InFILE1			= $fopen("./TestVector/DL_FrameReg.txt","r"); 
				iSDSP_BusCnt	<= 11'd0;  
				SDSP_State		<= `SDSP_DL_FRAME_REG;	
			end
			else begin
				iSDSP_BusCnt	<= iSDSP_BusCnt + 1;
			end
		end
	end
end

assign SDSP_DATA	= (SDSP_OEn) ? SDSP_WDATA : 16'hZZZZ;
assign SDSP_RDATA	= (!SDSP_OEn) ? SDSP_DATA : 16'hZZZZ;

//---------------------------------------------------------------------------
//	BurstRAM Interface
//---------------------------------------------------------------------------
`define Burst_INIT		2'b00
`define	Burst_READY		2'b01
`define Burst_READ		2'b10
`define Burst_END		2'b11

reg		[1:0]	BurstState;

reg 	[31:0]	iData_Burst;

integer			InFILE3;

always@(posedge CLK40M, negedge SYSPORn)
begin
	if(!SYSPORn) begin
		//DL_LowMAC_IRQ	<= 1'b1;
		BurstState		<= `Burst_INIT;
	end
	else if(iSystem_Ready) begin
		if(BurstState == `Burst_INIT) begin
			InFILE3			= $fopen("./TestVector/burst01.bin","rb");
			//DL_LowMAC_IRQ	<= 1'b0;
			BurstState		<= `Burst_READY;
		end
		else if(BurstState == `Burst_READY) begin
			if(DL_LowMAC_CE) begin
				$fseek(InFILE3,DL_LowMAC_ADDR*4,0);
				
				iData_Burst[7:0]	= $fgetc(InFILE3);
				iData_Burst[15:8]	= $fgetc(InFILE3);
				iData_Burst[23:16]	= $fgetc(InFILE3);
				iData_Burst[31:24]	= $fgetc(InFILE3);
				
				DL_LowMAC_DATA	<= #`LowMAC_DELAY	iData_Burst;
				
				DL_LowMAC_IRQ	<= 1'b1; 
				BurstState	<= `Burst_READ;
			end
		end
		else if(BurstState == `Burst_READ) begin
			if(DL_LowMAC_CE) begin
				$fseek(InFILE3,DL_LowMAC_ADDR*4,0);
				
				iData_Burst[7:0]	= $fgetc(InFILE3);
				iData_Burst[15:8]	= $fgetc(InFILE3);
				iData_Burst[23:16]	= $fgetc(InFILE3);
				iData_Burst[31:24]	= $fgetc(InFILE3);
				
				DL_LowMAC_DATA	<= #`LowMAC_DELAY	iData_Burst;
			end
			else begin
				BurstState	<= `Burst_READY;
			end
		end
		else if(BurstState == `Burst_END) begin
			
		end
	end
end

//---------------------------------------------------------------------------
//	IF Interface
//---------------------------------------------------------------------------
`define	IF_READY	2'b00
`define IF_WRITE	2'b01

reg		[1:0]	IF_State;
reg				d0_DL_Sync;

integer			OutFILE4;

always@(posedge CLK40M, negedge SYSPORn)
begin
	if(!SYSPORn) begin
		d0_DL_Sync	<= 1'b0;
		IF_State	<= `IF_READY;
	end
	else begin
		d0_DL_Sync	<= DL_Sync;
		if(IF_State	== `IF_READY) begin
			if(!DL_5msTic) begin
				OutFILE4	= $fopen("FFT_Wnd_Output.csv","w");
				IF_State	<= `IF_WRITE;
			end
		end
		else if(IF_State == `IF_WRITE) begin
			if(DL_Sync) begin
				$fdisplay(OutFILE4,"%h",DL_IF_DATA);
			end
			else if(!DL_Sync && d0_DL_Sync) begin 
				$fclose(OutFILE4);
				IF_State	<= `IF_READY;
			end
		end
	end
end



endmodule























































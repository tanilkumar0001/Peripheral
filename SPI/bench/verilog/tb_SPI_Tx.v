
`define	ST_TB_START			3'b000
`define	ST_SETUP_MODE		3'b001
`define	ST_SETUP_CLOCK		3'b010
`define	ST_RUN				3'b100


module tb_I2C();

	parameter BIT_WIDTH = 10;

	reg					CLK;
	reg					RESETn;

	reg					iMST_CEn;
	reg		[31:0]		iMST_ADDR;
	reg		[31:0]		iMST_WDATA;
	wire	[31:0]		iMST_RDATA;
	reg					iMST_WEn;

	wire				iSCLK;
	reg					iSDI;
	wire				iSDO;

	wire				iSS0;
	wire				iSS1;
	wire				iSS2;
	wire				iSS3;

	reg		[BIT_WIDTH-1:0]		iCnt;		
	reg		[7:0]		R;
	reg		[2:0]		State;
	
	initial begin
		$dumpvars();
		$dumpfile("SPI.vcd");
		$shm_open("SPI.shm");
		$shm_probe("AC");
		
		#(10000000)
		$finish();
	end

	initial begin
		CLK		<= 1'b0;
		RESETn	<= 1'b1;

		#10	 RESETn <=	1'b0;
		#100 RESETn <=	1'b1;
	end

	always #5 CLK <= ~CLK; // 100Mhz

//---------------------------------------------------------------------------
//	Module Instantiation
//---------------------------------------------------------------------------
SPI_Ctrl_top uSPI_Ctrl_top(
	.CLK		(CLK),
	.RESETn		(RESETn),	

	.MST_CEn	(iMST_CEn),	
	.MST_ADDR	(iMST_ADDR),	
	.MST_WDATA	(iMST_WDATA),	
	.MST_RDATA	(iMST_RDATA),	
	.MST_WEn	(iMST_WEn),	

	.SCLK		(iSCLK),	
	.SDI		(iSDI),	
	.SDO		(iSDO),	

	.SS0		(iSS0),	
	.SS1		(iSS1),	
	.SS2		(iSS2),	
	.SS3		(iSS3)	
);		 

always@(posedge CLK, negedge RESETn) begin
	if(!RESETn) begin
		iMST_CEn	<=	1'b1;	
		iMST_ADDR	<=	32'b0;	
		iMST_WDATA	<=	32'b0;	
		iMST_WEn	<=	1'b1;	

		iSDI		<= 1'b0;
		iCnt		<= 0;
		State		<= `ST_TB_START;
	end
	else begin
		if(State == `ST_TB_START) begin
			if(iCnt==4) begin
				iMST_CEn	<= 1'b0;
				iMST_WEn	<= 1'b0;	
				iMST_ADDR	<= {27'b0, 3'b000, 2'b00};
				iMST_WDATA	<= {22'b0, 10'b0011010011};

				iCnt		<= 0;
				State		<= `ST_SETUP_MODE;
			end
			else begin
				iMST_CEn 	<= 1'b1;
				iMST_WEn	<= 1'b1;	
				iCnt <= iCnt + 1;
			end
		end
		else if(State == `ST_SETUP_MODE) begin
			if(iCnt==4) begin
				iMST_CEn 	<= 1'b0;
				iMST_WEn	<= 1'b0;	
				iMST_ADDR	<= {27'b0, 3'b011, 2'b00};
				iMST_WDATA	<= {16'b0, 16'h63};

				iCnt		<= 0;
				State		<= `ST_SETUP_CLOCK;
			end
			else begin
				iMST_CEn 	<= 1'b1;
				iMST_WEn	<= 1'b1;	
				iCnt <= iCnt + 1;
			end
		end
		else if(State == `ST_SETUP_CLOCK) begin
			if(iCnt==4) begin
				iMST_CEn 	<= 1'b1;
				iMST_WEn	<= 1'b1;	
				iMST_ADDR	<= 32'd0;
				iMST_WDATA	<= 32'd0;

				iCnt		<= 0;
				State		<= `ST_RUN;
			end
			else begin
				iMST_CEn 	<= 1'b1;
				iMST_WEn	<= 1'b1;	
				iCnt <= iCnt + 1;
			end
		end
		else if(State == `ST_RUN) begin
			if(iCnt==4) begin
				iMST_CEn <= 1'b0;
				iMST_WEn <= 1'b0;
				iMST_ADDR	<= {27'b0, 3'b100, 2'b00};
				iMST_WDATA	<= {24'b0, R[7:0]};
			end
			else if(iCnt==8) begin
				iMST_CEn <= 1'b1;
				iMST_WEn <= 1'b1;
			end
			//else if(iCnt==20) begin
				//iMST_CEn <= 1'b0;
				//iMST_WEn <= 1'b0;
				//iMST_ADDR	<= {26'b0, 4'b0110, 2'b00};
				//iMST_WDATA	<= {24'b0, R[7:0]};
				//iOE			<=	1'b0;	
			//end

			R <= $random;
			iCnt <= iCnt + 1;

		end

	end
end

endmodule

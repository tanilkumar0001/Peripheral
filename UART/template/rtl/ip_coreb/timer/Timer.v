// =======================================================
//  Bongjin Kim
//  Goeun Lim
//  20110412
//  
//  Timer with Interrupt Handler
// =======================================================

module  Timer(
    input   wire            CLK,
    input   wire            RST,

    output  reg             INT,
    input   wire            INT_ACK,

    input   wire            DREQ,
    input   wire            DRW, // 0:R 1:W
    input   wire    [1:0]   DADDR,
    input   wire    [38:0]  WDATA,
    output  wire    [38:0]  RDATA,
    output  reg             DRDY,

	input	wire			ETH_INT,
	input	wire			I2C_INT_0,
	input	wire			I2C_INT_1,
	input	wire			SPI_INT_0,
	input	wire			SPI_INT_1,

    input   wire            EXT_INT,
    output  reg             EXT_INT_ACK
);

// Input signal latching
reg             L_DREQ;
reg             L_DRW;
reg     [38:0]  L_WDATA;
reg     [1:0]   L_DADDR;

always @ (posedge CLK)
begin
    if(RST)
        {L_DREQ, L_DRW, L_WDATA, L_DADDR} <= {1'b0, 1'b0, 39'b0, 2'b0};
    else
        {L_DREQ, L_DRW, L_WDATA, L_DADDR} <= {DREQ, DRW, WDATA, DADDR};
end

wire	[31:0]	WDATA_dec;
HAMM_DEC_SYS32 wdt_dec (
    .DIN	(L_WDATA),
    .DOUT	(WDATA_dec),
    .SEC	(),
    .DED	()
);

// DRDY
always @ (posedge CLK)
begin
	if(RST)
		DRDY <= 1'b1;
	else begin
		if(DREQ & DRW)
			DRDY <= 1'b0;
		if(DRDY == 1'b0)
			DRDY <= 1'b1;
	end
end



reg             extINT_check;
reg             ethINT_check;
reg             i2c0INT_check;
reg             i2c1INT_check;
reg             spi0INT_check;
reg             spi1INT_check;

reg				pended_ethINT;
reg				pended_i2c0INT;
reg				pended_i2c1INT;
reg				pended_spi0INT;
reg				pended_spi1INT;

reg             prev_INT;

reg 			L_ETH_INT;
reg 			L_I2C_INT_0;
reg 			L_I2C_INT_1;
reg 			L_SPI_INT_0;
reg 			L_SPI_INT_1;

always @ (posedge CLK)
begin
	if(RST)	begin
		L_ETH_INT 	<= 1'b0;
		L_I2C_INT_0 <= 1'b0;
		L_I2C_INT_1 <= 1'b0;
		L_SPI_INT_0 <= 1'b0;
		L_SPI_INT_1 <= 1'b0;
	end
	else begin
		L_ETH_INT 	<= ETH_INT;
		L_I2C_INT_0 <= I2C_INT_0;
		L_I2C_INT_1 <= I2C_INT_1;
		L_SPI_INT_0 <= SPI_INT_0;
		L_SPI_INT_1 <= SPI_INT_1;
	end
end

wire			ETH_INT_Trig = ETH_INT & !L_ETH_INT;
wire			I2C_INT_0_Trig = I2C_INT_0 & !L_I2C_INT_0;
wire			I2C_INT_1_Trig = I2C_INT_1 & !L_I2C_INT_1;
wire			SPI_INT_0_Trig = SPI_INT_0 & !L_SPI_INT_0;
wire			SPI_INT_1_Trig = SPI_INT_1 & !L_SPI_INT_1;



// Timer Control Registers
// ctrl[31]: timer interrupt
// ctrl[30]: external interrupt
// ctrl[29]: eth mac interrupt
// ctrl[28]: i2c0 interrupt
// ctrl[27]: i2c1 interrupt
// ctrl[26]: spi0 interrupt
// ctrl[25]: spi1 interrupt
// ctrl[1] : timer count enable
// ctrl[0] : timer interrupt only for once
reg		[31:0]	ctrl;       
reg		[31:0]	period;
reg		[31:0]	count;

wire	TIME_MATCH = (period == count);
wire	COUNT_EN   = ctrl[1];
wire	MATCH_ONCE = ctrl[0];

wire	sel_ctrl   = (DADDR == 2'b01);
wire	sel_period = (DADDR == 2'b10);
wire	sel_count  = (DADDR == 2'b11);

wire	L_sel_ctrl   = (L_DADDR == 2'b01);
wire	L_sel_period = (L_DADDR == 2'b10);
wire	L_sel_count  = (L_DADDR == 2'b11);




//register read
reg		[31:0]	tRDATA;

always @ (posedge CLK)    
begin
    if(RST)
        tRDATA   <=  32'b0;
    else if(DREQ & (~DRW))
        casex({sel_ctrl, sel_period, sel_count})
            3'b1xx: tRDATA   <= ctrl;
            3'b01x: tRDATA   <= period;
            3'b001: tRDATA   <= count;
        endcase
end

HAMM_ENC_SYS32 rdt_enc (
	.DIN	(tRDATA),
	.DOUT	(RDATA)
);



wire	CORE_IDLE = ~INT & ~INT_ACK;

// Timer Control Register: ctrl
always @ (posedge CLK)   
begin
	if(RST) 
		ctrl <= 32'b0;
	else begin
		if(L_DREQ & L_DRW & L_sel_ctrl)
			ctrl <= WDATA_dec;

		else begin
			if(CORE_IDLE & (TIME_MATCH | prev_INT))
				ctrl[31] <= 1'b1;   //timer interrupt
			if(INT & extINT_check)
				ctrl[30] <= 1'b1;   //external interrupt
			if(INT & INT_ACK & ethINT_check)
				ctrl[29] <= 1'b1;   //eth mac interrupt
			if(INT & INT_ACK & i2c0INT_check)
				ctrl[28] <= 1'b1;   //i2c0 interrupt
			if(INT & INT_ACK & i2c1INT_check)
				ctrl[27] <= 1'b1;   //i2c1 interrupt
			if(INT & INT_ACK & spi0INT_check)
				ctrl[26] <= 1'b1;   //spi0 interrupt
			if(INT & INT_ACK & spi1INT_check)
				ctrl[25] <= 1'b1;   //spi1 interrupt
		
			if(TIME_MATCH & MATCH_ONCE)
				ctrl[1] <= 1'b0;
		end
	end
end



// Timer Control Register: period
always @(posedge CLK)   
begin
    if(RST) 
		period <= 32'b0;
    else if(L_DREQ & L_DRW & L_sel_period)
        period <= WDATA_dec;
end



// Timer Control Register: count : READ ONLY
always @(posedge CLK)   
begin
    if(RST) 
		count <= 32'b1;

    else if(TIME_MATCH | ~COUNT_EN)
        count <= 1;
    else if(COUNT_EN)
        count <= count + 1'b1;
end



//extINT_check
always @(posedge CLK)   
begin
    if(RST) 
		extINT_check <= 1'b0;
    else if(CORE_IDLE & ~TIME_MATCH & EXT_INT & ~prev_INT)
		extINT_check <= 1'b1;
    else if(EXT_INT_ACK)
        extINT_check <= 1'b0;
end

//ethINT_check
always @(posedge CLK)   
begin
	if(RST) begin
		ethINT_check <= 1'b0;
		pended_ethINT <= 1'b0;
	end
    else if(CORE_IDLE & ~TIME_MATCH & ETH_INT_Trig & ~prev_INT)
		ethINT_check <= 1'b1;
    else if(~CORE_IDLE & ~TIME_MATCH & pended_ethINT & ~prev_INT)
		pended_ethINT <= 1'b1;
	else if(ethINT_check & INT_ACK) begin
        ethINT_check <= 1'b0;
		pended_ethINT <= 1'b0;
		//ctrl[29] <= 1'b1;
	end
end

//i2c0INT_check
always @(posedge CLK)   
begin
	if(RST) begin 
		i2c0INT_check <= 1'b0;
		pended_i2c0INT <= 1'b0;
	end
    else if(CORE_IDLE & ~TIME_MATCH & (I2C_INT_0_Trig | pended_i2c0INT) & ~prev_INT)
		i2c0INT_check <= 1'b1;
	else if(~CORE_IDLE & ~TIME_MATCH & I2C_INT_0_Trig & ~prev_INT)
		pended_i2c0INT <= 1'b1;
	else if(i2c0INT_check & INT_ACK) begin
        i2c0INT_check <= 1'b0;
		pended_i2c0INT <= 1'b0;
		//ctrl[28] <= 1'b1;
	end
end

//i2c1INT_check
always @(posedge CLK)   
begin
	if(RST) begin 
		i2c1INT_check <= 1'b0;
		pended_i2c1INT <= 1'b0;
	end
    else if(CORE_IDLE & ~TIME_MATCH & (I2C_INT_1_Trig | pended_i2c1INT) & ~prev_INT)
		i2c1INT_check <= 1'b1;
	else if(~CORE_IDLE & ~TIME_MATCH & I2C_INT_1_Trig & ~prev_INT)
		pended_i2c1INT <= 1'b1;
	else if(i2c1INT_check & INT_ACK) begin
        i2c1INT_check <= 1'b0;
		pended_i2c1INT <= 1'b0;
		//ctrl[27] <= 1'b1;
	end
end

//spi0INT_check
always @(posedge CLK)   
begin
	if(RST) begin
		spi0INT_check <= 1'b0;
		pended_spi0INT <= 1'b0;
	end
    else if(CORE_IDLE & ~TIME_MATCH & (SPI_INT_0_Trig | pended_spi0INT) & ~prev_INT)
		spi0INT_check <= 1'b1;
	else if(~CORE_IDLE & ~TIME_MATCH & SPI_INT_0_Trig & ~prev_INT)
		pended_spi0INT <= 1'b1;
	else if(spi0INT_check & INT_ACK) begin
        spi0INT_check <= 1'b0;
		pended_spi0INT <= 1'b0;
		//ctrl[26] <= 1'b1;
	end
end

//spi1INT_check
always @(posedge CLK)   
begin
    if(RST) 
		spi1INT_check <= 1'b0;
    else if(CORE_IDLE & ~TIME_MATCH & (SPI_INT_1_Trig | pended_spi1INT) & ~prev_INT)
		spi1INT_check <= 1'b1;
    else if(~CORE_IDLE & ~TIME_MATCH & pended_spi1INT & ~prev_INT)
		pended_spi1INT <= 1'b1;
	else if(spi1INT_check & INT_ACK) begin
        spi1INT_check <= 1'b0;
		pended_spi1INT <= 1'b0;
		//ctrl[25] <= 1'b1;
	end
end







// prev_INT
always @(posedge CLK)   
begin
    if(RST) 
		prev_INT <= 1'b0;
    else if(TIME_MATCH & (INT | INT_ACK))
		prev_INT <= 1'b1;
    else if(prev_INT & CORE_IDLE)
        prev_INT <= 1'b0;
end


// INT
wire	INT_TRIG = EXT_INT | ETH_INT_Trig | I2C_INT_0_Trig | I2C_INT_1_Trig | SPI_INT_0_Trig | SPI_INT_1_Trig;
wire	PENDED_INT = pended_ethINT | pended_i2c0INT | pended_i2c1INT | pended_spi0INT | pended_spi1INT;

always @(posedge CLK)   
begin
    if(RST) 
		INT <= 1'b0;
    else if(INT & INT_ACK)
        INT <= 1'b0;
    else if((TIME_MATCH | INT_TRIG | PENDED_INT) & ~prev_INT & CORE_IDLE)
		INT <= 1'b1;
    else if(prev_INT & CORE_IDLE)
        INT <= 1'b1;
end


//EXT_INT_ACK
always @(posedge CLK)   
begin
    if(RST) 
		EXT_INT_ACK <= 1'b0;
    else if(~TIME_MATCH & EXT_INT & INT & extINT_check)
        EXT_INT_ACK <= 1'b1;
    else
        EXT_INT_ACK <= 1'b0;    // 1 cycle synchronous ACK
end


endmodule

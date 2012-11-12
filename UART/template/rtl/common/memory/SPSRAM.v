module SPSRAM #(
	parameter	D_WIDTH = 32,
	parameter	DEPTH = 1024,
	parameter	A_WIDTH = 10,
	parameter	INIT_FILE = "test.hex",
	parameter	INITIALIZE = 0
)(
	input	wire	CK, 
	input	wire	CSN, 
	input	wire	WEN, 
	input	wire	OEN, 
	input	wire	[A_WIDTH-1:0]	A, 
	input	wire	[D_WIDTH-1:0]	BWEN, 
	input	wire	[D_WIDTH-1:0]	DI,
	output	reg	[D_WIDTH-1:0]	DOUT
);

reg	[D_WIDTH-1:0]	dataArray [0:DEPTH-1];

always @ (posedge CK) begin
	if(~CSN & ~OEN)
		DOUT <= dataArray[A];
end


always @ (posedge CK) begin
	if(~CSN & ~WEN)
		dataArray[A] <= (~BWEN&DI) | (BWEN&dataArray[A]);
end


initial begin
	if(INITIALIZE>0)
		$display($time, "\tLoading %s", INIT_FILE);
	if(INITIALIZE==1)
		$readmemb(INIT_FILE, dataArray);
	else if(INITIALIZE==2)
		$readmemh(INIT_FILE, dataArray);
end


endmodule

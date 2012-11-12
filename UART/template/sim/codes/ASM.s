/**********************************************************************************
		FILE NAME:		ASM.s 
		DESCRIPTION:	TEST VECTOR FOR PLATFORM TEMPLATE
				   
		CODED & COMMENTED BY 		
								Injae Yoo
								Bongjin Kim
		
***********************************************************************************/



@-----------	RSV MEMORY FOR INTERRUPT HANDLER 	------------------------------
@1.RST:	IM[0x00]
	J		0, RST_HANDLER
@2.DFT:	IM[0x04]
	J		0, DFT_HANDLER
@3.UDI:	IM[0x08]
	J		0, UDI_HANDLER
@4.SWI:	IM[0x0C]
	J		0, SWI_HANDLER
@5.EXT:	IM[0x10]
	J		0, EXT_HANDLER
@6.IFT:	IM[0x14]
	J		0, IFT_HANDLER
@7.CPI:	IM[0x18]
	J		0, CPI_HANDLER
@-----------	RSV MEMORY FOR INTERRUPT HANDLER 	------------------------------



@--------------	INTERRUPT HANDLER START  ---------------------------------------------
@1.
RST_HANDLER:

	@Timer SETUP
	MUI		0x0020F0
	MOVI	r0, CONCAT(0x00)	@ Timer Base Addr
	MOVI	r1, 0x500			@ Timer Period: 0x00000800
	MOVI    r2, 0x2				@ Timer : ON

	ST.W    r1, (r0+0x08)		@ Timer Period Setting
	ST.W    r2, (r0+0x04)		@ Timer Control Setting        


	@System Register Initialize & Jump to Main Function
	MOVI	R13, 0x0			@ EPARAM = 0x0
	MOVI	R14, 0x0			@ EPC	= 0x0
	MOVI	R15, 0x0			@ RA 	= 0x0

	MOVI	R10, 0x5			@ FOR EXTERNAL ENABLE and SUPERVISOR Mode  

	J		1, main				@ After .RESET, Start .MAIN Function with .PS AS BELOW 
	MTPS	R10					@ PS = {NZCV,IE,MODE} = {0000,INT_EN,SPV_MODE}
								@ WE DON'T NEED RFI 


@2.
DFT_HANDLER:
	RFI			@ WE SHOULD USE RFI


@3.	
UDI_HANDLER:
	RFI			@ WE SHOULD USE RFI


@4.
SWI_HANDLER:
	RFI			@ WE SHOULD USE RFI


@5. 		
EXT_HANDLER:
	MUI		0x0020F0
	MOVI	r0, CONCAT(0x00)	@ Timer Base Addr
	LD.W	r1, (r0+0x04)		@ Timer Ctrl Reg

	MOVI	r2, SHL(0x1, 31)	@ INT MASK : Timer
	TAND	r1, r2				@ Timer INT check
	CALL.NZ+	0,	TIME_INT 

	MOVI	r2, SHL(0x1, 30)	@ INT MASK : EXT 
	TAND	r1, r2				@ EXT INT check
	CALL.NZ+	0,	EXT_INT 

	RFI			@ WE SHOULD USE RFI

TIME_INT:
	XOR		r3, r1, r2
	ST.W	r3, (r0+0x04)		@ Turn off INT flag (Timer Ctrl Reg)
	BR		1, R15
	MOV		r1, r3

EXT_INT:
	XOR		r3, r1, r2
	ST.W	r3, (r0+0x04)		@ Turn off INT flag (Timer Ctrl Reg)
	BR		1, R15
	MOV		r1, r3


@6.		 	
IFT_HANDLER:
	RFI			@ WE SHOULD USE RFI


@7.
CPI_HANDLER:
	RFI			@ WE SHOULD USE RFI


@---------	INTERRUPT HANDLER END ----------------------------



@---------   MAIN  START  ----------------------------------------
.org	0x1000
.global	main
.type	main, %function
main:	

	MUI		0x001000
	MOVI	r0, CONCAT(0x00)	@ APB Bridge Base Addr
	
	@MUI		0x000000
	@MOVI	r1, CONCAT(0xF3)	@ Write data : 0x000000F3
	@
	@ST.W	r1, (r0+0x04)		@ Write addr.: 0x00100004 (APB SLV 1)

@ UART register setting

@ baudrate setting, 50Mhz, 115200 baudrate
	MUI		0x000000
	MOVI	r2, CONCAT(0x1B)	@ Write data : 0x0000001B
	ST.W	r2, (r0+0x1C)		@ Write addr.: 0x0010001C (APB SLV 1)

@ LCR setting
	MUI		0x000000
	MOVI	r3, CONCAT(0x38)	@ Write data : 0x00000038
	ST.W	r3, (r0+0x04)		@ Write addr.: 0x00100004 (APB SLV 1)

@ FCR setting
	MUI		0x000000
	MOVI	r4, CONCAT(0xCC)	@ Write data : 0x000000CC
	ST.W	r4, (r0+0x08)		@ Write addr.: 0x00100008 (APB SLV 1)

@ IER setting
	MUI		0x000000
	MOVI	r5, CONCAT(0x0F)	@ Write data : 0x0000000F
	ST.W	r5, (r0+0x14)		@ Write addr.: 0x00100014 (APB SLV 1)

	MUI		0x000000
	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007
	MUI		0x000000
	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007
	MUI		0x000000
	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007
	MUI		0x000000
	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007
	MUI		0x000000
	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007

@ uart enable
	MUI		0x000000
	MOVI	r1, CONCAT(0x07)	@ Write data : 0x00000007
	ST.W	r1, (r0+0x0C)		@ Write addr.: 0x0010000C (APB SLV 1)


@ transmit test
	MUI		0x000000
	MOVI	r7, CONCAT(0x34)	@ Write data : 0x00000034
	ST.W	r7, (r0+0x00)		@ Write addr.: 0x00100000 (APB SLV 1)

	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007
	MUI		0x000000
	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007
	MUI		0x000000
	MOVI	r6, CONCAT(0x07)	@ Write data : 0x00000007



	MUI		0x000000
	MOVI	r8, CONCAT(0x21)	@ Write data : 0x00000021
	ST.W	r8, (r0+0x00)		@ Write addr.: 0x00100000 (APB SLV 1)


@-------------------   MAIN  END  --------------------------------------------------
MAIN_END:
	J		0,	MAIN_END
	ADDI	r0, r0, 0




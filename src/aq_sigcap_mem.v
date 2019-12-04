module aq_sigcap_mem
  (
   input 		 RST,

   input 		 A_CLK,
   input [9:0] 	 A_ADDR,
   input [3:0] 	 A_WE,
   input [31:0]  A_DI,
   output [31:0] A_DO,

   input 		 B_CLK,
   input [9:0] 	 B_ADDR,
   input [3:0] 	 B_WE,
   input [31:0]  B_DI,
   output [31:0] B_DO
   );

/*
   RAMB36E1
	 #(
	   .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
	   .SIM_COLLISION_CHECK("ALL"),
	   .DOA_REG(0),
	   .DOB_REG(0),
	   .EN_ECC_READ("FALSE"),
	   .EN_ECC_WRITE("FALSE"),
	   .INIT_FILE("NONE"),
	   .RAM_MODE("TDP"),
	   .RAM_EXTENSION_A("NONE"),
	   .RAM_EXTENSION_B("NONE"),
	   .READ_WIDTH_A(36),
	   .READ_WIDTH_B(36),
	   .WRITE_WIDTH_A(36),
	   .WRITE_WIDTH_B(36),
	   .RSTREG_PRIORITY_A("RSTREG"),
	   .RSTREG_PRIORITY_B("RSTREG"),
	   .SRVAL_A(36'h000000000),
	   .SRVAL_B(36'h000000000),
	   .SIM_DEVICE("7SERIES"),
	   .WRITE_MODE_A("WRITE_FIRST"),
	   .WRITE_MODE_B("WRITE_FIRST")
	   )
   RAMB36E1_inst
	 (
	  .CASCADEOUTA(),
	  .CASCADEOUTB(),
	  .DBITERR(),
	  .ECCPARITY(),
	  .RDADDRECC(),
	  .SBITERR(),

	  .CASCADEINA(1'b0),
	  .CASCADEINB(1'b0),
	  .INJECTDBITERR(1'b0),
	  .INJECTSBITERR(1'b0),

	  .CLKARDCLK(A_CLK),
	  .ADDRARDADDR({1'd0, A_ADDR[9:0], 5'd0}),
	  .ENARDEN(1'b1),
	  .REGCEAREGCE(1'b1),
	  .RSTRAMARSTRAM(RST),
	  .RSTREGARSTREG(RST),
	  .WEA(A_WE[3:0]),
	  .DIADI(A_DI[31:0]),
	  .DIPADIP(4'h0),
	  .DOADO(A_DO[31:0]),
	  .DOPADOP(),

	  .ADDRBWRADDR({1'd0, B_ADDR[9:0], 5'd0}),
	  .CLKBWRCLK(B_CLK),
	  .ENBWREN(1'b1),
	  .REGCEB(1'B1),
	  .RSTRAMB(RST),
	  .RSTREGB(RST),
	  .WEBWE(B_WE),
	  .DIBDI(B_DI),
	  .DIPBDIP(4'd0),
	  .DOBDO(B_DO[31:0]),
	  .DOPBDOP()
	  );
*/

   reg [31:0]    buff[0:1023];
   reg [31:0]    reg_a, reg_b;

   always @(posedge A_CLK) begin
      if(A_WE) buff[A_ADDR] = A_DI;
      reg_a = buff[A_ADDR];
   end
   assign A_DO = reg_a;

   always @(posedge B_CLK) begin
      if(B_WE) buff[B_ADDR] = B_DI;
      reg_b = buff[B_ADDR];
   end
   assign B_DO = reg_b;

endmodule

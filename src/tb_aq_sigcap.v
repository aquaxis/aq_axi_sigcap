`timescale 1ns / 1ps
module tb_aq_sigcap;

   reg RST_N;
   reg CLK;

   wire LOCAL_CS;
   wire LOCAL_RNW;

   wire LOCAL_ACK;
   wire [31:0] LOCAL_ADDR;
   wire [3:0]  LOCAL_BE;
   wire [31:0] LOCAL_WDATA;
   wire [31:0] LOCAL_RDATA;

   reg 		   CAP_CLK;
   reg [31:0]  CAP_DATA;
   
   aq_sigcap u_aq_sigcap
	 (
	  .RST_N(RST_N),
	  .CLK(CLK),

	  .LOCAL_CS(LOCAL_CS),
	  .LOCAL_RNW(LOCAL_RNW),
	  .LOCAL_ACK(LOCAL_ACK),
	  .LOCAL_ADDR(LOCAL_ADDR),
	  .LOCAL_BE(LOCAL_BE),
	  .LOCAL_WDATA(LOCAL_WDATA),
	  .LOCAL_RDATA(LOCAL_RDATA),

	  .CAP_CLK(CAP_CLK),
	  .CAP_DATA(CAP_DATA)
	  );

   local_bus_model u_local
	 (
	  .CLK(CLK),

	  .LOCAL_CS(LOCAL_CS),
	  .LOCAL_RNW(LOCAL_RNW),
	  .LOCAL_ACK(LOCAL_ACK),
	  .LOCAL_ADDR(LOCAL_ADDR),
	  .LOCAL_BE(LOCAL_BE),
	  .LOCAL_WDATA(LOCAL_WDATA),
	  .LOCAL_RDATA(LOCAL_RDATA)   
	  );

   localparam CLK100M = 10;

   initial begin
	  RST_N <= 1'b0;
	  CLK <= 1'b0;
	  #100;

	  @(posedge CLK);
	  RST_N <= 1'b1;
	  $display("Simulatin Start");
   end

   always  begin
	  #(CLK100M/2) CLK <= ~CLK;
   end

   initial begin
	  wait(LOCAL_ADDR == 32'hFFFF_FFFF);
	  $display("Simulatin Finish");
	  $finish();
   end

   initial begin
	  wait(RST_N);

	  @(posedge CLK);

	  $display("Process Start");
	  
	  u_local.wdata(32'h0000_0004, 32'h0000_0004);
	  u_local.wdata(32'h0000_0008, 32'h0000_0100);
	  u_local.wdata(32'h0000_0000, 32'h0000_0001);

	  u_local.rdata(32'h0000_0000);
	  
	  repeat (2000) @(posedge CAP_CLK);
	  
	  u_local.rdata(32'h0000_0000);

	  u_local.rdata(32'h0000_1000);
	  u_local.rdata(32'h0000_1004);
	  u_local.rdata(32'h0000_1008);
	  u_local.rdata(32'h0000_100C);
	  u_local.rdata(32'h0000_1010);
	  u_local.rdata(32'h0000_1014);
	  u_local.rdata(32'h0000_1018);
	  u_local.rdata(32'h0000_101C);
	  u_local.rdata(32'h0000_13D0);
	  u_local.rdata(32'h0000_13D4);
	  u_local.rdata(32'h0000_13D8);
	  u_local.rdata(32'h0000_13DC);
	  u_local.rdata(32'h0000_13E0);
	  u_local.rdata(32'h0000_13E4);
	  u_local.rdata(32'h0000_13E8);
	  u_local.rdata(32'h0000_13EC);
	  u_local.rdata(32'h0000_13F0);
	  u_local.rdata(32'h0000_13F4);
	  u_local.rdata(32'h0000_13F8);
	  u_local.rdata(32'h0000_13FC);

	  repeat (10) @(posedge CAP_CLK);

	  u_local.rdata(32'hFFFF_FFFF);
	  
   end
   

   initial begin
	  CAP_CLK <= 1'b0;
   end
   
   localparam CLK25M = 40;
   always  begin
	  #(CLK25M/2) CAP_CLK <= ~CAP_CLK;
   end

   always @(posedge CAP_CLK or negedge RST_N) begin
	  if(!RST_N) begin
		 CAP_DATA <= 32'd0;
	  end else begin
		 CAP_DATA <= CAP_DATA + 32'd1;
	  end
   end

endmodule

module local_bus_model
  (
   input CLK,

   output reg LOCAL_CS,
   output reg LOCAL_RNW,
   input LOCAL_ACK,
   output reg [31:0] LOCAL_ADDR,
   output reg [3:0] LOCAL_BE,
   output reg [31:0] LOCAL_WDATA,
   input [31:0] LOCAL_RDATA   
   );
   
   initial begin
	  LOCAL_CS = 1'b0;
	  LOCAL_ADDR[31:0] = 32'd0;
	  LOCAL_BE[3:0] = 4'd0;
	  LOCAL_WDATA = 32'd0;
	  LOCAL_RNW = 1'b0;
   end
   
   task wdata;
	  input [31:0] addr;
	  input [31:0] data;
	  begin
		 @(negedge CLK);

		 LOCAL_CS <= 1'b1;
		 LOCAL_ADDR <= addr;
		 LOCAL_RNW <= 1'b0;
		 LOCAL_WDATA <= data;
		 $display("LOCAL Write[%08X]: %08X", addr, LOCAL_WDATA);

		 @(negedge CLK);

		 wait(LOCAL_ACK);
		 LOCAL_CS <= 1'b0;
		 LOCAL_ADDR <= 32'd0;
		 LOCAL_WDATA <= 32'd0;

		 @(negedge CLK);
	  end
   endtask

   task rdata;
	  input [31:0] addr;
	  begin
		 @(negedge CLK);

		 LOCAL_CS <= 1'b1;
		 LOCAL_ADDR <= addr;
		 LOCAL_RNW <= 1'b1;

		 @(negedge CLK);

		 wait(LOCAL_ACK);
		 LOCAL_CS <= 1'b0;
		 $display("LOCAL Read[%08X]: %08X", addr, LOCAL_RDATA);

		 @(negedge CLK);
	  end
   endtask   
   
endmodule

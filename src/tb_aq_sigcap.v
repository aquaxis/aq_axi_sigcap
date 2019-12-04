`timescale 1ns / 1ps
module tb_aq_sigcap;

   // --------------------------------------------------
   // AXI4 Lite Interface
   // --------------------------------------------------
   // Reset; Clock
   reg         S_AXI_ARESETN;
   reg         S_AXI_ACLK;

   // Write Address Channel
   wire [15:0] S_AXI_AWADDR;
   wire [3:0]  S_AXI_AWCACHE;
   wire [2:0]  S_AXI_AWPROT;
   wire        S_AXI_AWVALID;
   wire        S_AXI_AWREADY;

   // Write Data Channel
   wire [31:0] S_AXI_WDATA;
   wire [3:0]  S_AXI_WSTRB;
   wire        S_AXI_WVALID;
   wire        S_AXI_WREADY;

   // Write Response Channel
   wire        S_AXI_BVALID;
   wire        S_AXI_BREADY;
   wire [1:0]  S_AXI_BRESP;

   // Read Address Channel
   wire [15:0] S_AXI_ARADDR;
   wire [3:0]  S_AXI_ARCACHE;
   wire [2:0]  S_AXI_ARPROT;
   wire        S_AXI_ARVALID;
   wire        S_AXI_ARREADY;

   // Read Data Channel
   wire [31:0] S_AXI_RDATA;
   wire [1:0]  S_AXI_RRESP;
   wire        S_AXI_RVALID;
   wire        S_AXI_RREADY;

  reg        CAP_CLK;
  reg [31:0]  CAP_DATA;

  reg [31:0] rddata;

  aq_sigcap u_aq_sigcap
  (
      // --------------------------------------------------
      // AXI4 Lite Interface
      // --------------------------------------------------
      // Reset, Clock
      .S_AXI_ARESETN ( S_AXI_ARESETN ),
      .S_AXI_ACLK    ( S_AXI_ACLK    ),

      // Write Address Channel
      .S_AXI_AWADDR  ( S_AXI_AWADDR  ),
      .S_AXI_AWCACHE ( S_AXI_AWCACHE ),
      .S_AXI_AWPROT  ( S_AXI_AWPROT  ),
      .S_AXI_AWVALID ( S_AXI_AWVALID ),
      .S_AXI_AWREADY ( S_AXI_AWREADY ),

      // Write Data Channel
      .S_AXI_WDATA   ( S_AXI_WDATA   ),
      .S_AXI_WSTRB   ( S_AXI_WSTRB   ),
      .S_AXI_WVALID  ( S_AXI_WVALID  ),
      .S_AXI_WREADY  ( S_AXI_WREADY  ),

      // Write Response Channel
      .S_AXI_BVALID  ( S_AXI_BVALID  ),
      .S_AXI_BREADY  ( S_AXI_BREADY  ),
      .S_AXI_BRESP   ( S_AXI_BRESP   ),

      // Read Address Channel
      .S_AXI_ARADDR  ( S_AXI_ARADDR  ),
      .S_AXI_ARCACHE ( S_AXI_ARCACHE ),
      .S_AXI_ARPROT  ( S_AXI_ARPROT  ),
      .S_AXI_ARVALID ( S_AXI_ARVALID ),
      .S_AXI_ARREADY ( S_AXI_ARREADY ),

      // Read Data Channel
      .S_AXI_RDATA   ( S_AXI_RDATA   ),
      .S_AXI_RRESP   ( S_AXI_RRESP   ),
      .S_AXI_RVALID  ( S_AXI_RVALID  ),
      .S_AXI_RREADY  ( S_AXI_RREADY  ),


    .CAP_CLK(CAP_CLK),
    .CAP_DATA(CAP_DATA)
  );

   tb_axi_ls_master_model axi_ls_master
     (
      // Reset, Clock
      .ARESETN       ( S_AXI_ARESETN ),
      .ACLK          ( S_AXI_ACLK    ),

      // Write Address Channel
      .S_AXI_AWADDR  ( S_AXI_AWADDR  ),
      .S_AXI_AWCACHE ( S_AXI_AWCACHE ),
      .S_AXI_AWPROT  ( S_AXI_AWPROT  ),
      .S_AXI_AWVALID ( S_AXI_AWVALID ),
      .S_AXI_AWREADY ( S_AXI_AWREADY ),

      // Write Data Channel
      .S_AXI_WDATA   ( S_AXI_WDATA   ),
      .S_AXI_WSTRB   ( S_AXI_WSTRB   ),
      .S_AXI_WVALID  ( S_AXI_WVALID  ),
      .S_AXI_WREADY  ( S_AXI_WREADY  ),

      // Write Response Channel
      .S_AXI_BVALID  ( S_AXI_BVALID  ),
      .S_AXI_BREADY  ( S_AXI_BREADY  ),
      .S_AXI_BRESP   ( S_AXI_BRESP   ),

      // Read Address Channe
      .S_AXI_ARADDR  ( S_AXI_ARADDR  ),
      .S_AXI_ARCACHE ( S_AXI_ARCACHE ),
      .S_AXI_ARPROT  ( S_AXI_ARPROT  ),
      .S_AXI_ARVALID ( S_AXI_ARVALID ),
      .S_AXI_ARREADY ( S_AXI_ARREADY ),

      // Read Data Channel
      .S_AXI_RDATA   ( S_AXI_RDATA   ),
      .S_AXI_RRESP   ( S_AXI_RRESP   ),
      .S_AXI_RVALID  ( S_AXI_RVALID  ),
      .S_AXI_RREADY  ( S_AXI_RREADY  )
      );

  localparam CLK100M = 10;

   // Initialize and Free for Reset
   initial begin
      S_AXI_ARESETN <= 1'b0;
      S_AXI_ACLK    <= 1'b0;

	  #100;

	  @(posedge S_AXI_ACLK);
      S_AXI_ARESETN <= 1'b1;
	  $display("============================================================");
	  $display("Simulatin Start");
	  $display("============================================================");
   end

   // Clock
   always  begin
	  #(CLK100M/2) S_AXI_ACLK <= ~S_AXI_ACLK;
   end


  integer rslt = 0;

  initial begin
    wait(S_AXI_ARESETN);

    @(posedge S_AXI_ACLK);

    $display("Process Start");
    
    axi_ls_master.wrdata(32'h0000_0004, 32'h0000_0004);
    axi_ls_master.wrdata(32'h0000_0008, 32'h0000_0100);
    axi_ls_master.wrdata(32'h0000_0000, 32'h0000_0001);

    axi_ls_master.rddata(32'h0000_0000, rddata);
    
    rslt = 0;
    while(!rslt) begin
      axi_ls_master.rddata(32'h0000_0000, rddata);
      if(rddata & 32'h80000000) rslt = 1;
      @(posedge CAP_CLK);
    end
    
    axi_ls_master.rddata(32'h0000_0000, rddata);
    axi_ls_master.rddata(32'h0000_000c, rddata);

    axi_ls_master.rddata(32'h0000_1000, rddata);
    axi_ls_master.rddata(32'h0000_1004, rddata);
    axi_ls_master.rddata(32'h0000_1008, rddata);
    axi_ls_master.rddata(32'h0000_100C, rddata);
    axi_ls_master.rddata(32'h0000_1010, rddata);
    axi_ls_master.rddata(32'h0000_1014, rddata);
    axi_ls_master.rddata(32'h0000_1018, rddata);
    axi_ls_master.rddata(32'h0000_101C, rddata);
    axi_ls_master.rddata(32'h0000_13D0, rddata);
    axi_ls_master.rddata(32'h0000_13D4, rddata);
    axi_ls_master.rddata(32'h0000_13D8, rddata);
    axi_ls_master.rddata(32'h0000_13DC, rddata);
    axi_ls_master.rddata(32'h0000_13E0, rddata);
    axi_ls_master.rddata(32'h0000_13E4, rddata);
    axi_ls_master.rddata(32'h0000_13E8, rddata);
    axi_ls_master.rddata(32'h0000_13EC, rddata);
    axi_ls_master.rddata(32'h0000_13F0, rddata);
    axi_ls_master.rddata(32'h0000_13F4, rddata);
    axi_ls_master.rddata(32'h0000_13F8, rddata);
    axi_ls_master.rddata(32'h0000_13FC, rddata);

    repeat (10) @(posedge CAP_CLK);
    
    $display("Simulatin Finish");
    $finish();
  end
   

  initial begin
    CAP_CLK <= 1'b0;
  end
   
  localparam CLK25M = 40;
  always  begin
    #(CLK25M/2) CAP_CLK <= ~CAP_CLK;
  end

  always @(posedge CAP_CLK or negedge S_AXI_ARESETN) begin
    if(!S_AXI_ARESETN) begin
      CAP_DATA <= 32'd0;
    end else begin
      CAP_DATA <= CAP_DATA + 32'd1;
    end
  end

endmodule

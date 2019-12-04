module aq_sigcap
  (
   // --------------------------------------------------
   // AXI4 Lite Interface
   // --------------------------------------------------
   // Reset, Clock
   input         S_AXI_ARESETN,
   input         S_AXI_ACLK,

   // Write Address Channel
   input [15:0]  S_AXI_AWADDR,
   input [3:0]   S_AXI_AWCACHE, // 4'b0011
   input [2:0]   S_AXI_AWPROT, // 3'b000
   input         S_AXI_AWVALID,
   output        S_AXI_AWREADY,

   // Write Data Channel
   input [31:0]  S_AXI_WDATA,
   input [3:0]   S_AXI_WSTRB,
   input         S_AXI_WVALID,
   output        S_AXI_WREADY,

   // Write Response Channel
   output        S_AXI_BVALID,
   input         S_AXI_BREADY,
   output [1:0]  S_AXI_BRESP,

   // Read Address Channel
   input [15:0]  S_AXI_ARADDR,
   input [3:0]   S_AXI_ARCACHE, // 4'b0011
   input [2:0]   S_AXI_ARPROT, // 3'b000
   input         S_AXI_ARVALID,
   output        S_AXI_ARREADY,

   // Read Data Channel
   output [31:0] S_AXI_RDATA,
   output [1:0]  S_AXI_RRESP,
   output        S_AXI_RVALID,
   input         S_AXI_RREADY,

   output [31:0] DEBUG,

   input         CAP_CLK,
   input [31:0]  CAP_DATA
   );

   wire          aq_local_clk;
   wire          aq_local_cs;
   wire          aq_local_rnw;
   wire          aq_local_ack;
   wire [15:0]   aq_local_addr;
   wire [3:0]    aq_local_be;
   wire [31:0]   aq_local_wdata;
   wire [31:0]   aq_local_rdata;

   // AXI Lite Slave Interface
   aq_sigcap_axi_ls u_aq_sigcap_axi_ls
     (
      // AXI4 Lite Interface
      .ARESETN        ( S_AXI_ARESETN  ),
      .ACLK           ( S_AXI_ACLK     ),

      // Write Address Channel
      .S_AXI_AWADDR   ( S_AXI_AWADDR   ),
      .S_AXI_AWCACHE  ( S_AXI_AWCACHE  ),
      .S_AXI_AWPROT   ( S_AXI_AWPROT   ),
      .S_AXI_AWVALID  ( S_AXI_AWVALID  ),
      .S_AXI_AWREADY  ( S_AXI_AWREADY  ),

      // Write Data Channel
      .S_AXI_WDATA    ( S_AXI_WDATA    ),
      .S_AXI_WSTRB    ( S_AXI_WSTRB    ),
      .S_AXI_WVALID   ( S_AXI_WVALID   ),
      .S_AXI_WREADY   ( S_AXI_WREADY   ),

      // Write Response Channel
      .S_AXI_BVALID   ( S_AXI_BVALID   ),
      .S_AXI_BREADY   ( S_AXI_BREADY   ),
      .S_AXI_BRESP    ( S_AXI_BRESP    ),

      // Read Address Channel
      .S_AXI_ARADDR   ( S_AXI_ARADDR   ),
      .S_AXI_ARCACHE  ( S_AXI_ARCACHE  ),
      .S_AXI_ARPROT   ( S_AXI_ARPROT   ),
      .S_AXI_ARVALID  ( S_AXI_ARVALID  ),
      .S_AXI_ARREADY  ( S_AXI_ARREADY  ),

      // Read Data Channel
      .S_AXI_RDATA    ( S_AXI_RDATA    ),
      .S_AXI_RRESP    ( S_AXI_RRESP    ),
      .S_AXI_RVALID   ( S_AXI_RVALID   ),
      .S_AXI_RREADY   ( S_AXI_RREADY   ),

      // Local Interface
      .AQ_LOCAL_CLK   ( aq_local_clk   ),
      .AQ_LOCAL_CS    ( aq_local_cs    ),
      .AQ_LOCAL_RNW   ( aq_local_rnw   ),
      .AQ_LOCAL_ACK   ( aq_local_ack   ),
      .AQ_LOCAL_ADDR  ( aq_local_addr  ),
      .AQ_LOCAL_BE    ( aq_local_be    ),
      .AQ_LOCAL_WDATA ( aq_local_wdata ),
      .AQ_LOCAL_RDATA ( aq_local_rdata ),

      .DEBUG          ( DEBUG )
      );

   wire 	   A_CLK;
   wire [9:0]  A_ADDR;
   wire [3:0]  A_WE;
   wire [31:0] A_DO;

   wire 	   B_CLK;
   wire [9:0]  B_ADDR;
   wire [31:0] B_DI;

   aq_sigcap_ctl u_aq_sigcap_ctl
	 (
  	  .RST_N       ( S_AXI_ARESETN      ),
	  .CLK         ( S_AXI_ACLK         ),

  	  .AQ_LOCAL_CS    ( aq_local_cs          ),
  	  .AQ_LOCAL_RNW   ( aq_local_rnw         ),
   	  .AQ_LOCAL_ACK   ( aq_local_ack         ),
      .AQ_LOCAL_ADDR  ( aq_local_addr[15:0]  ),
   	  .AQ_LOCAL_BE    ( aq_local_be[3:0]     ),
      .AQ_LOCAL_WDATA ( aq_local_wdata[31:0] ),
	  .AQ_LOCAL_RDATA ( aq_local_rdata[31:0] ),

   	  .CAP_CLK     ( CAP_CLK           ),
  	  .CAP_DATA    ( CAP_DATA[31:0]    ),

	  .A_CLK       ( A_CLK             ),
      .A_ADDR      ( A_ADDR[9:0]       ),
      .A_WE        ( A_WE[3:0]         ),
	  .A_DO        ( A_DO[31:0]        ),

   	  .B_CLK       ( B_CLK             ),
      .B_ADDR      ( B_ADDR[9:0]       ),
      .B_DI        ( B_DI[31:0]        )
   );

   aq_sigcap_mem u_aq_sigcap_mem
	 (
  	  .RST    ( ~S_AXI_ARESETN      ),

   	  .A_CLK  ( A_CLK       ),
   	  .A_ADDR ( A_ADDR[9:0] ),
   	  .A_WE   ( A_WE[3:0]   ),
      .A_DI   ( A_DO[31:0]  ),
	  .A_DO   (),

  	  .B_CLK  ( B_CLK       ),
   	  .B_ADDR ( B_ADDR[9:0] ),
   	  .B_WE   ( 4'd0        ),
	  .B_DI   ( 32'd0       ),
	  .B_DO   ( B_DI[31:0]  )
   );

endmodule

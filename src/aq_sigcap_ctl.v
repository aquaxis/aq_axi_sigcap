/*
 * AXI4 Lite Slave
 *
 * Copyright (C)2014-2019 AQUAXIS TECHNOLOGY.
 *  Don't remove this header.
 * When you use this source, there is a need to inherit this header.
 *
 * License: MIT License
 *
 * For further information please contact.
 *  URI:    http://www.aquaxis.com/
 *  E-Mail: info(at)aquaxis.com
 */
module aq_sigcap_ctl
(
  // AXI4 Lite Interface
  input         ARESETN,
  input         ACLK,

  // Write Address Channel
  input [31:0]  S_AXI_AWADDR,
  input [3:0]   S_AXI_AWCACHE,
  input [2:0]   S_AXI_AWPROT,
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
  input [31:0]  S_AXI_ARADDR,
  input [3:0]   S_AXI_ARCACHE,
  input [2:0]   S_AXI_ARPROT,
  input         S_AXI_ARVALID,
  output        S_AXI_ARREADY,

  // Read Data Channel
  output [31:0] S_AXI_RDATA,
  output [1:0]  S_AXI_RRESP,
  output        S_AXI_RVALID,
  input         S_AXI_RREADY,

  // Local Interface
   input        CAP_CLK,
   input [31:0] CAP_DATA,

   output         A_CLK,
   output [9:0]   A_ADDR,
   output [3:0]   A_WE,
   output [31:0]  A_DO,

   output         B_CLK,
   output [9:0]   B_ADDR,
   input [31:0]   B_DI
);

/*
  CACHE[3:0]
    WA RA C  B
    0  0  0  0 Noncacheable and nonbufferable
    0  0  0  1 Bufferable only
    0  0  1  0 Cacheable, but do not allocate
   *0  0  1  1 Cacheable and Bufferable, but do not allocate
    0  1  1  0 Cacheable write-through, allocate on reads only
    0  1  1  1 Cacheable write-back, allocate on reads only
    1  0  1  0 Cacheable write-through, allocate on write only
    1  0  1  1 Cacheable write-back, allocate on writes only
    1  1  1  0 Cacheable write-through, allocate on both reads and writes
    1  1  1  1 Cacheable write-back, allocate on both reads and writes

  PROR[2:0]
    [2]:0:Data Access(*)
        1:Instruction Access
    [1]:0:Secure Access(*)
        1:NoSecure Access
    [0]:0:Privileged Access(*)
        1:Normal Access

  RESP[1:0]
    00: OK
    01: EXOK
    10: SLVERR
    11: DECERR
*/

  localparam S_IDLE   = 2'd0;
  localparam S_WRITE  = 2'd1;
  localparam S_WRITE2 = 2'd2;
  localparam S_READ   = 2'd3;

  reg [1:0]     state;
  reg           reg_rnw;
  reg [31:0]    reg_addr, reg_wdata;
  reg [3:0]     reg_be;
  reg           reg_wallready;

  wire          local_cs, local_rnw, local_ack;
  wire [3:0]    local_be;
  wire [31:0]   local_addr, local_wdata, local_rdata;

  always @( posedge ACLK or negedge ARESETN ) begin
    if( !ARESETN ) begin
      state         <= S_IDLE;
      reg_rnw       <= 1'b0;
      reg_addr      <= 32'd0;
      reg_wdata     <= 32'd0;
      reg_be        <= 4'd0;
      reg_wallready <= 1'b0;
    end else begin
      // Receive wdata
      if( S_AXI_WVALID ) begin
        reg_wdata     <= S_AXI_WDATA;
        reg_be        <= S_AXI_WSTRB;
        reg_wallready <= 1'b1;
      end else if( local_ack & S_AXI_BREADY ) begin
        reg_wallready <= 1'b0;
      end

      // Address state
      case( state )
        S_IDLE: begin
          if( S_AXI_AWVALID ) begin
            reg_rnw   <= 1'b0;
            reg_addr  <= S_AXI_AWADDR;
            state     <= S_WRITE;
          end else if( S_AXI_ARVALID ) begin
            reg_rnw   <= 1'b1;
            reg_addr  <= S_AXI_ARADDR;
            state     <= S_READ;
          end
        end
        S_WRITE: begin
          if( reg_wallready ) begin
            state     <= S_WRITE2;
          end
        end
        S_WRITE2: begin
          if( local_ack & S_AXI_BREADY ) begin
            state     <= S_IDLE;
          end
        end
        S_READ: begin
          if( local_ack & S_AXI_RREADY ) begin
            state     <= S_IDLE;
          end
        end
        default: state <= S_IDLE;
      endcase
    end
  end

  // Write Channel
  assign S_AXI_AWREADY  = ( state == S_WRITE || state == S_IDLE )?1'b1:1'b0;
  assign S_AXI_WREADY   = ( state == S_WRITE || state == S_IDLE )?1'b1:1'b0;
  assign S_AXI_BVALID   = ( state == S_WRITE2 )?local_ack:1'b0;
  assign S_AXI_BRESP    = 2'b00;

  // Read Channel
  assign S_AXI_ARREADY  = ( state == S_READ  || state == S_IDLE )?1'b1:1'b0;
  assign S_AXI_RVALID   = ( state == S_READ )?local_ack:1'b0;
  assign S_AXI_RRESP    = 2'b00;
  assign S_AXI_RDATA    = ( state == S_READ )?local_rdata:32'd0;

  // Local Interface
  wire          wr_ena, rd_ena, wr_ack;
  reg           rd_ack;
  reg [31:0]    reg_rdata;

  assign local_cs           = (( state == S_WRITE2 )?1'b1:1'b0) | (( state == S_READ )?1'b1:1'b0) | 1'b0;
  assign local_rnw          = reg_rnw;
  assign local_addr[31:0]   = reg_addr[31:0];
  assign local_be[3:0]      = reg_be[3:0];
  assign local_wdata[31:0]  = reg_wdata[31:0];
  assign local_ack          = wr_ack | rd_ack;
  assign local_rdata[31:0]  = reg_rdata[31:0];

  assign wr_ena = (local_cs & ~local_rnw)?1'b1:1'b0;
  assign rd_ena = (local_cs &  local_rnw)?1'b1:1'b0;
  assign wr_ack = wr_ena;

  localparam A_CTL      = 8'h00;
  localparam A_DP       = 8'h04;
  localparam A_TRIGER   = 8'h08;
  localparam A_POINTER  = 8'h0C;

  reg [9:0]   reg_dp;
  reg         req_start, reg_finish;
  reg [31:0]  reg_triger;
  reg         reg_rst;

  always @(posedge ACLK or negedge ARESETN) begin
    if(!ARESETN) begin
     req_start <= 1'b0;
     reg_triger[31:0] <= 32'd0;
     reg_dp[9:0] <= 10'd0;
     reg_rst <= 1'b0;
    end else begin
      if(wr_ena) begin
        case(local_addr[7:0] & 8'hFC)
          A_CTL:
            begin
              reg_rst <= local_wdata[31];
            end
          A_DP:
            begin
              reg_dp[9:0] <= local_wdata[9:0];
            end
          A_TRIGER:
            begin
              reg_triger[31:0] <= local_wdata[31:0];
          end
          default:
            begin
            end
        endcase
      end

      if(cap_state != S_IDLE) begin
        req_start <= 1'b0;
      end if(((local_addr[7:0] & 8'hFC) == A_CTL) & wr_ena) begin
        req_start <= 1'b1;
      end
    end
  end

  reg rd_ack_d;
  wire [9:0] wire_sp;

  always @(posedge ACLK or negedge ARESETN) begin
    if(!ARESETN) begin
      rd_ack <= 1'b0;
      rd_ack_d <= 1'b0;
      reg_rdata[31:0] <= 32'd0;
    end else begin
      if(local_addr[15:12] == 4'd0) begin
        rd_ack <= rd_ena;
        case(local_addr[7:0] & 8'hFC)
          A_CTL:      reg_rdata[31:0] <= {reg_finish, 30'd0, req_start};
          A_DP:       reg_rdata[31:0] <= {22'd0, reg_dp[9:0]};
          A_TRIGER:   reg_rdata[31:0] <= reg_triger[31:0];
          A_POINTER:  reg_rdata[31:0] <= {20'd0, wire_sp[9:0], 2'd0};
          default:    reg_rdata[31:0] <= 32'd0;
        endcase
      end else if(local_addr[15:12] == 4'd1) begin
        rd_ack_d        <= rd_ena;
        rd_ack          <= rd_ack_d;
        reg_rdata[31:0] <= B_DI[31:0];
      end else begin
        rd_ack <= rd_ena;
        reg_rdata[31:0] <= 32'd0;
      end
    end
  end

  assign B_ADDR[9:0] = local_addr[11:2];

  //
  reg [1:0] cap_state;
  reg [9:0] cap_cp, cap_sp, cap_dp;
  reg       cap_ena;

  reg [31:0] cap_data_d1, cap_data_d2;

  localparam SS_IDLE = 2'd0;
  localparam SS_WAIT = 2'd1;
  localparam SS_RUN  = 2'd2;
  localparam SS_FIN  = 2'd3;

  assign wire_sp[9:0] = cap_sp[9:0] + 10'd2;

  wire     wire_ARESETN;
  assign wire_ARESETN = ARESETN & ~reg_rst;

  always @(posedge CAP_CLK or negedge wire_ARESETN) begin
    if(!wire_ARESETN) begin
      cap_state <= SS_IDLE;
      cap_cp[9:0] <= 10'd0;
      cap_sp[9:0] <= 10'd0;
      cap_dp[9:0] <= 10'd0;
      cap_ena     <= 1'b0;
      reg_finish <= 1'b0;
    end else begin
      case(cap_state)
        SS_IDLE:
          begin
            if(req_start) begin
              cap_state <= SS_WAIT;
              cap_dp[9:0]      <= reg_dp[9:0];
              reg_finish <= 1'b0;
            end
            cap_cp[9:0] <= 10'd0;
            cap_ena <= 1'b0;
          end
        SS_WAIT:
          begin
            if((((cap_data_d1[31:0] & ~cap_data_d2[31:0]) & reg_triger[31:0]) == reg_triger[31:0]) != 32'd0) begin
              cap_state <= SS_RUN;
              cap_sp[9:0] <= cap_cp[9:0] - cap_dp[9:0] - 10'd2;
            end
            cap_cp[9:0] <= cap_cp[9:0] + 10'd1;
            cap_ena <= 1'b1;
          end
        SS_RUN:
          begin
            if(cap_cp[9:0] == cap_sp[9:0]) begin
              cap_state <= SS_FIN;
            end
            cap_cp[9:0] <= cap_cp[9:0] + 10'd1;
          end
        SS_FIN:
        begin
          cap_state <= SS_IDLE;
          cap_ena <= 1'b0;
          reg_finish <= 1'b1;
        end
        default:
        begin
          cap_state <= SS_IDLE;
        end
      endcase
    end
  end

  always @(posedge CAP_CLK or negedge ARESETN) begin
    if(!ARESETN) begin
      cap_data_d1[31:0] <= 32'd0;
      cap_data_d2[31:0] <= 32'd0;
    end else begin
      cap_data_d1[31:0] <= CAP_DATA;
      cap_data_d2[31:0] <= cap_data_d1[31:0];
    end
  end

  assign A_CLK       = CAP_CLK;
  assign A_ADDR[9:0] = cap_cp[9:0];
  assign A_WE[3:0]   = (cap_ena)?4'hF:4'h0;
  assign A_DO[31:0]  = cap_data_d1[31:0];

  assign B_CLK       = ACLK;

endmodule

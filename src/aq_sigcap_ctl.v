module aq_sigcap_ctl
  (
   input 		 RST_N,
   input 		 CLK,

   input 		 AQ_LOCAL_CS,
   input 		 AQ_LOCAL_RNW,
   output 		 AQ_LOCAL_ACK,
   input [15:0]  AQ_LOCAL_ADDR,
   input [3:0] 	 AQ_LOCAL_BE,
   input [31:0]  AQ_LOCAL_WDATA,
   output [31:0] AQ_LOCAL_RDATA,

   input 		 CAP_CLK,
   input [31:0]	 CAP_DATA,

   output 		 A_CLK,
   output [9:0]  A_ADDR,
   output [3:0]  A_WE,
   output [31:0] A_DO,

   output 		 B_CLK,
   output [9:0]  B_ADDR,
   input [31:0]  B_DI
   );

   localparam A_CTL = 8'h00;
   localparam A_DP = 8'h04;
   localparam A_TRIGER = 8'h08;
   localparam A_POINTER = 8'h0C;

   wire wr_ena, rd_ena, wr_ack;
   reg rd_ack;
   reg [31:0] reg_rdata;
   reg [9:0]  reg_dp;

   assign wr_ena = (AQ_LOCAL_CS & ~AQ_LOCAL_RNW)?1'b1:1'b0;
   assign rd_ena = (AQ_LOCAL_CS &  AQ_LOCAL_RNW)?1'b1:1'b0;
   assign wr_ack = wr_ena;

   reg 		  req_start, reg_finish;
   reg [31:0] reg_triger;
   reg 		  reg_rst;

   always @(posedge CLK or negedge RST_N) begin
	  if(!RST_N) begin
		 req_start <= 1'b0;
		 reg_triger[31:0] <= 32'd0;
		 reg_dp[9:0] <= 10'd0;
	  end else begin
		 if(wr_ena) begin
			case(AQ_LOCAL_ADDR[7:0] & 8'hFC)
			  A_CTL:
				begin
				   reg_rst <= AQ_LOCAL_WDATA[31];
				end
			  A_DP:
				begin
				   reg_dp[9:0] <= AQ_LOCAL_WDATA[9:0];
				end
			  A_TRIGER:
				begin
				   reg_triger[31:0] <= AQ_LOCAL_WDATA[31:0];
				end
			  default:
				begin
				end
			endcase
		 end

		 if(cap_state != S_IDLE) begin
			req_start <= 1'b0;
		 end if(((AQ_LOCAL_ADDR[7:0] & 8'hFC) == A_CTL) & wr_ena) begin
			req_start <= 1'b1;
		 end
	  end
   end

   reg rd_ack_d;
   wire [9:0] wire_sp;

   always @(posedge CLK or negedge RST_N) begin
	  if(!RST_N) begin
		 rd_ack <= 1'b0;
		 rd_ack_d <= 1'b0;
		 reg_rdata[31:0] <= 32'd0;
	  end else begin
		 if(AQ_LOCAL_ADDR[15:12] == 4'd0) begin
			rd_ack <= rd_ena;
			case(AQ_LOCAL_ADDR[7:0] & 8'hFC)
			  A_CTL: reg_rdata[31:0] <= {reg_finish, 30'd0, req_start};
			  A_DP: reg_rdata[31:0] <= {22'd0, reg_dp[9:0]};
			  A_TRIGER: reg_rdata[31:0] <= reg_triger[31:0];
			  A_POINTER: reg_rdata[31:0] <= {20'd0, wire_sp[9:0], 2'd0};
			  default: reg_rdata[31:0] <= 32'd0;
			endcase
		 end else if(AQ_LOCAL_ADDR[15:12] == 4'd1) begin
			rd_ack_d <= rd_ena;
			rd_ack <= rd_ack_d;
			reg_rdata[31:0] <= B_DI[31:0];
		 end else begin
			rd_ack <= rd_ena;
			reg_rdata[31:0] <= 32'd0;
		 end
	  end
   end

   assign AQ_LOCAL_ACK = (wr_ack | rd_ack);
   assign AQ_LOCAL_RDATA[31:0] = reg_rdata[31:0];

   assign B_ADDR[9:0] = AQ_LOCAL_ADDR[11:2];

   //
   reg [1:0] cap_state;
   reg [9:0] cap_cp, cap_sp, cap_dp;
   reg [31:0] cap_triger;
   reg 		  cap_ena;

   reg [31:0] cap_data_d1, cap_data_d2;

   localparam S_IDLE = 2'd0;
   localparam S_WAIT = 2'd1;
   localparam S_RUN  = 2'd2;
   localparam S_FIN  = 2'd3;

   assign wire_sp[9:0] = cap_sp[9:0] + 10'd1;

   wire 	  wire_rst_n;
   assign wire_rst_n = RST_N & ~reg_rst;

   always @(posedge CAP_CLK or negedge wire_rst_n) begin
	  if(!wire_rst_n) begin
		 cap_state <= S_IDLE;
		 cap_cp[9:0] <= 10'd0;
		 cap_sp[9:0] <= 10'd0;
		 cap_dp[9:0] <= 10'd0;
		 cap_ena     <= 1'b0;
		 reg_finish <= 1'b0;
	  end else begin
		 case(cap_state)
		   S_IDLE:
			 begin
				if(req_start) begin
				   cap_state <= S_WAIT;
				   cap_dp[9:0]      <= reg_dp[9:0];
				   reg_finish <= 1'b0;
				end
				cap_cp[9:0] <= 10'd0;
				cap_ena <= 1'b0;
			 end
		   S_WAIT:
			 begin
				if((((cap_data_d1[31:0] & ~cap_data_d2[31:0]) & reg_triger[31:0]) == reg_triger[31:0]) != 32'd0) begin
				   cap_state <= S_RUN;
				   cap_sp[9:0] <= cap_cp[9:0] - cap_dp[9:0] - 10'd2;
				end
				cap_cp[9:0] <= cap_cp[9:0] + 10'd1;
				cap_ena <= 1'b1;
			 end
		   S_RUN:
			 begin
				if(cap_cp[9:0] == cap_sp[9:0]) begin
				   cap_state <= S_FIN;
				end
				cap_cp[9:0] <= cap_cp[9:0] + 10'd1;
			 end
		   S_FIN:
			 begin
				cap_state <= S_IDLE;
				cap_ena <= 1'b0;
				reg_finish <= 1'b1;
			 end
		   default:
			 begin
				cap_state <= S_IDLE;
			 end
		 endcase
	  end
   end

   always @(posedge CAP_CLK or negedge RST_N) begin
	  if(!RST_N) begin
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

   assign B_CLK       = CLK;

endmodule

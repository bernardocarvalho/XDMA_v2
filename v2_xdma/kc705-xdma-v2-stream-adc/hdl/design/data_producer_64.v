/*
Company: IPFN-IST
Engineer: B. Carvalho 
 
Create Date:    Mar 27  WET 2018
Design Name:    
Module Name:    data_producer_64 
Project Name:   kc705-xdma-axi4-stream-adc
Target Devices: Kintex xc7kxx
Tool versions:  Vivado 2017.4
Description: 

Dependencies: 
    axis_fifo_64(hdl) or fifo_axi_stream_0 (IP)

Revision 0.01 - File Created
Additional Comments: 
Copyright 2018 IPFN-Instituto Superior Tecnico, Portugal
  
 Licensed under the EUPL, Version 1.2 or - as soon they
 will be approved by the European Commission - subsequent
 versions of the EUPL (the "Licence");
 You may not use this work except in compliance with the
 Licence.
 You may obtain a copy of the Licence at:
https://joinup.ec.europa.eu/software/page/eupl
  
 Unless required by applicable law or agreed to in
 writing, software distributed under the Licence is
 distributed on an "AS IS" basis,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 express or implied.
 See the Licence for the specific language governing
 permissions and limitations under the Licence.
*/
// Language: Verilog 2001
/*
Notes :  
*/
`timescale 1ns / 1ps
/*
 * AXI4-Stream Interface (64 bit datapath)
 */
module data_producer_64 #
(
    parameter DATA_WIDTH = 64,
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    parameter PKT_WIDTH = 11    //16kB (~20us/dma);  8kB; 512*8 = 4 kBytes , 32 samples * 4 * 32 dma packet size
    //parameter WAIT_WIDTH = 4
)
(
    input  user_clk,
    //input  user_rstn,
    
    input  data_clk,        // 40 Mhz
    input  new_sample,
    
    //input  adc_word_sync_n,

    input  dma_ena,
    input  dma_rstn,
    
    /*
     * AXI STREAM output interface
     */
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast
    //Debug
    //output state_o
);
/* internal data implementation with a counter ~2MHz*/

// user data interface to AXI fifo 
    wire [DATA_WIDTH-1:0]	       c2h_data_tdata;
    (* mark_debug = "true" *) wire c2h_data_tlast;
    (* mark_debug = "true" *) wire c2h_data_tready;
    
    wire axis_prog_full, m_axis_tvalid_o, m_axis_tready_i ;
 
    localparam COUNTER_WIDTH = 32;//DATA_WIDTH;
    reg [COUNTER_WIDTH-1:0] user_clk_cnt_r = 0;// {COUNTER_WIDTH{1'b1}};
    localparam PACKET_WORD_SIZE = {32'h0000_07FF}; 
    
    //reg [7:0]  ff_clk_cnt = 0;
    //reg [WAIT_WIDTH-1:0] wait_cnt = 0;
    //reg fifo_wr_en_r; 	
    
    //parameter WIDTH = $clog2(DEPTH);
   /* 
    localparam IDLE = 3'd0,
               FILL = 3'd1,
               WAIT = 3'd2,
             STATE3 = 3'd3;
*/
    localparam  IDLE   = 3'd0,       // wait for fifo space
                HEADER = 3'd1,
                WAIT_SAMPLE = 3'd2,  // wait for new batch of sampled channels
                DATA = 3'd3,            
                LAST = 3'd4;

   (* mark_debug = "true" *) reg [2:0] state = IDLE;

   always @(posedge data_clk)
      if (!dma_ena) begin
         user_clk_cnt_r  <=  0; 
      end
      else begin
          if (c2h_data_tready)   
            user_clk_cnt_r <= user_clk_cnt_r + 1;
      end

    reg [3:0]  chn_grp_count;         
    reg [COUNTER_WIDTH-1:0]  word_count;         
    reg data_valid_r;

    always @ (posedge data_clk or negedge dma_ena) begin
        if (!dma_ena) begin
            word_count <= 0;
            state <= IDLE;
        end
        else begin
       
            case (state)
                IDLE: begin
                    word_count <= 0;
                    chn_grp_count <= 4'b0;
                    data_valid_r <= 1'b0;
                    state <= WAIT_SAMPLE;
                end
                HEADER: begin 
                    word_count <= (c2h_data_tready)?  word_count + 1 : 
                        word_count;
                end
                WAIT_SAMPLE: begin 
                    chn_grp_count <= 4'b0;
                    state <= DATA;
                end
                DATA: begin 
                    data_valid_r <= 1'b1;
                    if (c2h_data_tready) 
                         if (word_count == 32'h0000_07FF)
                              state <= IDLE;
                    //else if(chn_grp_count == 4'hF)
                    //    state <= WAIT_SAMPLE;
                    else begin 
                        chn_grp_count <= chn_grp_count + 1;
                        word_count <= word_count + 1;
                    end
                end
                default:
                    state <= IDLE;
            endcase
        end
    end

   assign c2h_data_tvalid = 1'b1;// user_clk_cnt_r[PKT_WIDTH]; // 2048 on, 2048 off
   assign c2h_data_tlast  = (user_clk_cnt_r[PKT_WIDTH-1:0] == {PKT_WIDTH{1'b1}});  
   assign c2h_data_tdata  = {user_clk_cnt_r, 1'b1,   user_clk_cnt_r, 1'b0}; 
   assign m_axis_tvalid   = m_axis_tvalid_o;
   assign m_axis_tready_i = m_axis_tready;

/*    
   always @(posedge data_clk)
      if (!dma_ena) begin
         state <= IDLE;
         user_clk_cnt_r  <=  0; 
      end
      else
         case (state)
   
             
             always @(posedge data_clk)
      if (!dma_ena) begin
         state <= IDLE;
         user_clk_cnt_r  <=  0; 
      end
      else
         case (state)
            IDLE: begin
               if (new_sample)
                  state <= FILL;
                  
               wait_cnt <= 0;
            end
            FILL : begin
               if (user_clk_cnt_r[PKT_WIDTH-1:0] == {PKT_WIDTH{1'b1}})  //9'b1_11111111 
                  state <= IDLE;// WAIT;
               else if (user_clk_cnt_r[3:0] == 4'b1111)
                  state <= IDLE;
               if (c2h_data_tready)   
                    user_clk_cnt_r <= user_clk_cnt_r + 1;
            end
            WAIT : begin  // The Linux XDMA drivers requires some waiting state between DMAs 
               wait_cnt <= wait_cnt + 1;
               if (wait_cnt == {WAIT_WIDTH{1'b1}})
                  state <= IDLE;
            end
            STATE3 : begin // Just in case
                  state <= IDLE;
            end
         endcase

    assign c2h_data_tvalid = (state == FILL);
    assign c2h_data_tlast  = (state == FILL) && (user_clk_cnt_r[PKT_WIDTH-1:0] == {PKT_WIDTH{1'b1}});  
    assign c2h_data_tdata  = {c2h_data_tlast, user_clk_cnt_r[29:0], 1'b1,   user_clk_cnt_r, 1'b0}; 
*/

    
 
assign  m_axis_tkeep = {KEEP_WIDTH{1'b1}};

/*
 * 4096 depth , 2040 full flag
*/
fifo_axi_stream_0 fifo_data_inst (
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy(),      // output wire rd_rst_busy
  .m_aclk(user_clk),                // input wire m_aclk
  .s_aclk(data_clk),                // input wire s_aclk
  .s_aresetn(dma_rstn),          // input wire s_aresetn
  .s_axis_tvalid(c2h_data_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(c2h_data_tready),  // output wire s_axis_tready
  .s_axis_tdata(c2h_data_tdata),    // input wire [63 : 0] s_axis_tdata
  .s_axis_tlast(c2h_data_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(m_axis_tvalid_o),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready_i),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata),    // output wire [63 : 0] m_axis_tdata
  .m_axis_tlast(m_axis_tlast),    // output wire m_axis_tlast
  .axis_prog_full(axis_prog_full)  // output wire axis_prog_full
);

  
endmodule

// Archive
//  (* mark_debug = "true" *) reg [1:0] state_m = IDLE;
 //(* mark_debug = "true" *) reg  state_m = 1'b0;
   /*Allow DMA only when FIFO (almost) full. Could be done with Facket FIFO */ 
  // assign m_axis_tvalid   = (state_m == FILL)? m_axis_tvalid_o: 1'b0 ;
  // assign m_axis_tready_i = (state_m == FILL)? m_axis_tready: 1'b0 ;
//   assign m_axis_tvalid   = state_m  & m_axis_tvalid_o;
//   assign m_axis_tready_i = state_m  & m_axis_tready;

/*
   always @(posedge data_clk)
      if (!dma_ena) begin
         state_m <=  1'b0;
      end
      else begin
        if (m_axis_tlast)   
             state_m <= 1'b0;
        else if (axis_prog_full)
             state_m <= 1'b1;
      end
*/
	 
//assign c2h_data_tdata = {16'h8765, 8'h00, c2h_data_tlast, c2h_data_tvalid, user_clk_div_r, 
//                                cnt_en, 15'h0, user_clk_cnt_r}; 
//assign c2h_data_tdata = {user_clk_cnt_r, 1'b1,   user_clk_cnt_r, 1'b0}; 


//assign  c2h_data_tkeep = {KEEP_WIDTH{1'b1}};
//assign  c2h_data_tlast = pkt_last;  // (user_clk_cnt_r[7:0] == 8'h7F)? 1'b1 : 1'b0; // 128 64 bit words 

/*  


axis_fifo_64 fifo_xdma_inst (
  .clk(user_clk),                // input wire s_aclk
  .rst(!dma_rstn),          // input wire s_aresetn ~user_resetn
  .input_axis_tvalid(c2h_data_tvalid),  // input wire s_axis_tvalid
  .input_axis_tready(c2h_data_tready),  // output wire s_axis_tready
  .input_axis_tdata(c2h_data_tdata),    // input wire [63 : 0] s_axis_tdata
  .input_axis_tkeep(c2h_data_tkeep),    // input wire [7 : 0] s_axis_tkeep
  .input_axis_tlast(c2h_data_tlast),    // input wire s_axis_tlast
  .input_axis_tuser(1'b1),              // not used
  .output_axis_tvalid(m_axis_tvalid),  // output wire m_axis_tvalid
  .output_axis_tready(m_axis_tready),  // input wire m_axis_tready
  .output_axis_tdata(m_axis_tdata),    // output wire [63 : 0] m_axis_tdata
  .output_axis_tkeep(m_axis_tkeep),    // output wire [7 : 0] m_axis_tkeep
  .output_axis_tlast(m_axis_tlast),    // output wire m_axis_tlast
  .output_axis_tuser()                 // not used
 );
 
// Parameters
 localparam ADDR_WIDTH = 8;
 //localparam DATA_WIDTH = 64;
 localparam USER_ENABLE = 0;
 localparam KEEP_ENABLE = 0;

axis_async_fifo #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH),
	.KEEP_ENABLE(KEEP_ENABLE),
	.USER_ENABLE(USER_ENABLE)
)
fifo_data_inst  (
    // Common reset
    .async_rst( !dma_rstn ),
    // AXI input
    .input_clk(data_clk),
    .input_axis_tdata(c2h_data_tdata),
    //.input_axis_tkeep(input_axis_tkeep),
    .input_axis_tvalid(c2h_data_tvalid),
    .input_axis_tready(c2h_data_tready),
    .input_axis_tlast(c2h_data_tlast),
    //.input_axis_tid(input_axis_tid),
    //.input_axis_tdest(input_axis_tdest),
    //.input_axis_tuser(input_axis_tuser),
    // AXI output
    .output_clk(user_clk),
    .output_axis_tdata(m_axis_tdata),
//    .output_axis_tkeep(m_axis_output_axis_tkeep),
    .output_axis_tvalid(m_axis_tvalid),
    .output_axis_tready(m_axis_tready),
    .output_axis_tlast(m_axis_tlast)
    //.output_axis_tid(output_axis_tid),
    //.output_axis_tdest(output_axis_tdest),
    //.output_axis_tuser(output_axis_tuser)
);

*/

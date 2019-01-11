/*
Company: IPFN-IST
Engineer: B. Carvalho 
 
Create Date:    Mar 27  WET 2018
Design Name:    
Module Name:    single_packet 
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
module single_packet_64 #
(
    parameter DATA_WIDTH = 64,
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    parameter PKT_WIDTH = 12    //32kB  8KB (~30us/dma)
)
(
    input  user_clk,
    input  user_rstn,
    
    input  data_clk,        // 40 Mhz
    input  new_sample,
    
    //input  adc_word_sync_n,

    input  dma_ena,
    input  dma_rst,
    
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
    //(* mark_debug = "true" *) 
    wire c2h_data_tlast;
    wire c2h_data_tready;
    
    wire axis_prog_full, fifo_prog_empty, m_axis_tvalid_o, m_axis_tready_i ;
 
    localparam COUNTER_WIDTH = 32;
    //reg [COUNTER_WIDTH-1:0] user_clk_cnt_r = 0;// {COUNTER_WIDTH{1'b1}};
    //localparam PACKET_WORD_SIZE = {32'h0000_07FF}; 
    
    localparam COUNT_WORD_MAX = 28'h000_0FFF; // 4* 8 kB
    reg [3:0]  chn_grp_count;         
    reg [COUNTER_WIDTH-5:0]  word_count;         
    reg data_valid_r=1'b0;

    localparam  IDLE   = 3'd0,       // wait for fifo space
//                HEADER = 3'd1,
                WAIT_SAMPLE = 3'd1,  // wait for new batch of sampled channels
                DATA = 3'd2,            
                END_PACKET = 3'd3;

   reg [2:0] state = IDLE;

//   always @(posedge data_clk)
//      if (!dma_ena) begin
//         user_clk_cnt_r  <=  0; 
//      end
//      else begin
//          if (c2h_data_tready)   
//            user_clk_cnt_r <= user_clk_cnt_r + 1;
//      end


    always @ (posedge data_clk or negedge user_rstn) begin
        if (!user_rstn) begin
            word_count <= 0;
            state <= IDLE;
        end
        else begin
       
            case (state)
                IDLE: begin
                    chn_grp_count <= 4'h0;
                    if (dma_ena) begin
                        if (fifo_prog_empty)
                            state <= WAIT_SAMPLE;
                        end    
                    else
                        word_count <= 0;
                end
                WAIT_SAMPLE: begin 
                    chn_grp_count <= 4'h0;
                    if (new_sample) begin
                        state <= DATA;
                    end
                end
                DATA: begin 
                    if (c2h_data_tready) begin 
                    //    if (word_count == COUNT_WORD_MAX)
                        word_count <= word_count + 1'b1;
                        if (c2h_data_tlast)
                              state <= END_PACKET;
                        else begin 
                            if(chn_grp_count == 4'hF)
                                state <= WAIT_SAMPLE;
                            else  
                                chn_grp_count <= chn_grp_count + 1'b1;
                        end
                     end   
                  end
                END_PACKET: begin
                    //if (!dma_ena)
//                    word_count <= 0;
                    state <= IDLE;

                end
                 
                default:
                    state <= IDLE;
            endcase
        end
    end

    always @* begin
        data_valid_r = 0;
        case (state)
        DATA: begin  
                data_valid_r = 1'b1;
            end    
        default: begin
            data_valid_r = 0;
        end
        
    endcase
  end

  // assign c2h_data_tvalid = 1'b1;// user_clk_cnt_r[PKT_WIDTH]; // 2048 on, 2048 off
   assign c2h_data_tvalid = data_valid_r; //1'b1;// user_clk_cnt_r[PKT_WIDTH]; // 2048 on, 2048 off

   //assign c2h_data_tlast  = (word_count == COUNT_WORD_MAX)? 1'b1: 1'b0;  
   //assign c2h_data_tlast  = (word_count == 28'h000_07FF)? 1'b1: 1'b0;   
   assign c2h_data_tlast  = (word_count[PKT_WIDTH-1:0] == {PKT_WIDTH{1'b1}});  
   assign c2h_data_tdata  = {36'h0_000A_0000, word_count}; 
   assign m_axis_tvalid   = m_axis_tvalid_o;
   assign m_axis_tready_i = m_axis_tready;

 
    assign  m_axis_tkeep = {KEEP_WIDTH{1'b1}};

/*
 * 32768 depth 256kB, 2050 prog empty flag
*/
fifo_axi_stream_0 fifo_data_inst (
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy(),      // output wire rd_rst_busy
  .m_aclk(user_clk),                // input wire m_aclk
  .s_aclk(data_clk),                // input wire s_aclk
  .s_aresetn(user_rstn),          // input wire s_aresetn
  .s_axis_tvalid(c2h_data_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(c2h_data_tready),  // output wire s_axis_tready
  .s_axis_tdata(c2h_data_tdata),    // input wire [63 : 0] s_axis_tdata
  .s_axis_tlast(c2h_data_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(m_axis_tvalid_o),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready_i),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata),    // output wire [63 : 0] m_axis_tdata
  .m_axis_tlast(m_axis_tlast),    // output wire m_axis_tlast
  .axis_prog_empty(fifo_prog_empty),  // output 
  .axis_prog_full(axis_prog_full)  // output wire axis_prog_full
);

  
endmodule

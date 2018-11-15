`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IPFN - IST
// Engineer: Bernardo Carvalho
// 
// Create Date: 11/14/2018 03:48:16 PM
// Design Name: 
// Module Name: dma_packet
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
//Project Name:   kc705-xdma-axi4-stream-adc
//Target Devices: Kintex xc7kxx
//Tool versions:  Vivado 2017.4
//Description: 

//Dependencies: 
//    axis_fifo_64(hdl) or fifo_axi_stream_0 (IP)

//Revision 0.01 - File Created
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module dma_packet #(
    parameter DATA_WIDTH = 64,
    parameter KEEP_WIDTH = (DATA_WIDTH/8),
    parameter DMA_PACKET_SIZE = 12'h401 //0 //  16k + 16 in bytes >> 4
)(
    input data_clk,
    input new_sample,

    //input  adc_word_sync_n,

    // Async signals 
    input  dma_en,
    input  dma_rst_n,
    
//AXI STREAM output interface
    input m_axis_clk,
    output wire [DATA_WIDTH-1:0]  m_axis_tdata,
    output wire [KEEP_WIDTH-1:0]  m_axis_tkeep,
    output wire                   m_axis_tvalid,
    input  wire                   m_axis_tready,
    output wire                   m_axis_tlast
);

localparam
    IDLE   = 3'd0,                      // wait for fifo space
    HEADER = 3'd1,
    WAIT_SAMPLE = 3'd2,                    // wait for new batch of sampled channels
    DATA = 3'd3,            
    LAST = 3'd4;

localparam [DATA_WIDTH-1:0]
    HEADER_ONE = 64'h0,
    HEADER_TWO = {32'd0, 32'hA5};

// user data interface to AXI fifo 
reg [DATA_WIDTH-1:0]	c2h_data_tdata;
reg c2h_data_tlast;
reg c2h_data_tvalid;

reg [2:0] state, state_next; // state/next state variables
reg [3:0]   chn_grp_count;         
reg [11:0]  word_count;         

wire fifo_prog_empty;
wire c2h_data_tready;

always @ (posedge data_clk or negedge dma_en) begin
    if (!dma_en) begin
        word_count <= 12'b0;
        state <= IDLE;
    end
    else begin
        state <=  state_next;
       
        case (state)
            IDLE: begin
                word_count <= 12'b0;
                chn_grp_count <= 4'b0;
            end
            HEADER: begin 
                word_count <= (c2h_data_tready)?  word_count + 1 : word_count;
            end
            WAIT_SAMPLE: begin 
                chn_grp_count <= 4'b0;
            end
            DATA:  if (c2h_data_tready) begin
               chn_grp_count <= chn_grp_count + 1;
               word_count <= word_count + 1;
            end
 //           default:
        endcase
    end
end

//reg c2h_data_tready_reg, c2h_data_tready_next;
always @* begin
    c2h_data_tdata = 64'd0;
    c2h_data_tvalid= 0;
    c2h_data_tlast = 0;
    case (state)
        HEADER: begin  
                c2h_data_tdata  = (word_count == 12'd0) ? {32'd0, 32'h4010}: HEADER_TWO; //{32'd0, 32'hA5};
                c2h_data_tvalid = 1'b1;
            end    
        DATA: begin  
                c2h_data_tdata  =  {32'd0, 4'd0, word_count};
                c2h_data_tvalid = 1'b1;
                c2h_data_tlast  =(word_count == 12'h7FF)? 1'b1: 1'b0;
            end    
        default: begin
            c2h_data_tdata   = 64'd0;
            c2h_data_tvalid = 0;
            c2h_data_tlast  = 0;
        end
        
    endcase
  end

  always @* begin
    state_next = state;
    case (state)
        IDLE: state_next = HEADER; //(fifo_prog_empty) ? HEADER : state; //  Don't send packet if theres is no space
        HEADER: if (c2h_data_tready == 1'b1) begin
            state_next = ( word_count == 12'd1) ? WAIT_SAMPLE : state;
        end
        WAIT_SAMPLE: state_next = (new_sample == 1'b1) ? DATA : state;
        DATA: if (c2h_data_tready == 1'b1) begin
                if(word_count == 12'h7FF)
                    state_next = IDLE;
                else if(chn_grp_count==4'hF)
                    state_next = WAIT_SAMPLE;   
                else 
                    state_next = state;
            end
        default: state_next  = IDLE;
    endcase
  end
  
/*
 * 4096 depth , 2050 empty  flag
 */
fifo_axi_stream_0 fifo_data_inst (
  .wr_rst_busy(),      // output wire wr_rst_busy
  .rd_rst_busy(),      // output wire rd_rst_busy
  .m_aclk(m_axis_clk),                // input wire m_aclk
  .s_aclk(data_clk),                // input wire s_aclk
  .s_aresetn(dma_rst_n),          // input wire s_aresetn
  .s_axis_tvalid(c2h_data_tvalid),  // input wire s_axis_tvalid
  .s_axis_tready(c2h_data_tready),  // output wire s_axis_tready
  .s_axis_tdata(c2h_data_tdata),    // input wire [63 : 0] s_axis_tdata
  .s_axis_tlast(c2h_data_tlast),    // input wire s_axis_tlast
  .m_axis_tvalid(m_axis_tvalid),  // output wire m_axis_tvalid
  .m_axis_tready(m_axis_tready),  // input wire m_axis_tready
  .m_axis_tdata(m_axis_tdata),    // output wire [63 : 0] m_axis_tdata
  .m_axis_tlast(m_axis_tlast),    // output wire m_axis_tlast
  .axis_prog_empty(fifo_prog_empty)  // output 
);


endmodule

/*
Company: IPFN-IST
Engineer: B. Carvalho 
 
Create Date:    Wed Nov 15 12:08:40 WET 2017
Design Name:    
Module Name:    data_producer_64 
Project Name:   kc705-xdma-axi4-stream-lmaster
Target Devices: Kintex xc7kxx
Tool versions:  Vivado 2017.4
Description: 

Dependencies: 
    axis_fifo_64(hdl) or fifo_axi_stream_0 (IP)

Revision 0.01 - File Created
Additional Comments: 
Copyright 2017 IPFN-Instituto Superior Tecnico, Portugal
  
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

`timescale 1ns / 1ps
module system_clocks_tb;

	// Inputs
	reg reset;
	reg clk_200_in, clk_200_p, clk_200_n;
	//reg proc_clk;
	//reg [17:0] data_0, data_1;

	// Outputs
    wire clk_100, clk_200, data_clk_i, mmcm_locked_i;
    wire adc_word_sync_i, new_sample_i, adc_start_clk2_n, adc_start_conv_n, clk_2mhz_tte;
   
   parameter PERIOD_200 = 5.0;

   always begin
      clk_200_p = 1'b0;
      clk_200_n = 1'b1;
      #(PERIOD_200/2) clk_200_p = 1'b1;
      clk_200_n = 1'b0;
      #(PERIOD_200/2);
   end
   
//wires 
	//wire [2:0] state;
	


    system_clocks uut_0 ( 
        .clk_200_in_p(clk_200_p),
        .clk_200_in_n(clk_200_n),
        .reset(1'b0),
        .mmcm_locked(mmcm_locked_i), //o
        .clk_100_o(clk_100),
        .clk_200_o(clk_200),
        .clk_16(),
        .data_clk(data_clk_i),
        .new_sample(new_sample_i),
        .adc_word_sync(adc_word_sync_i),
        .adc_start_conv_n(adc_start_conv_n),
        .clk_2mhz_tte_o(clk_2mhz_tte)
    );
    
	initial begin
		$timeformat (-6, 2, " us", 13);
//      $timeformat (-3, 0, " ms", 8);		
		// Initialize Inputs
		reset = 1;
		clk_200_in = 0;
		// Wait 100 ns for global reset to finish
        #100;
        // Add stimulus here
         reset = 0;       
    end
endmodule



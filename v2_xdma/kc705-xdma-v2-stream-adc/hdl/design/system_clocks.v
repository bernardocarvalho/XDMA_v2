`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: IPFN-IST
// Engineer:  B. Carvalho
//  
// Create Date:    10:15:58 12/09/2015 
// Design Name:    
// Module Name:    system clocks
// Project Name:   ATCA MIMO version 2,  
// Target Devices: Kintex xc7k325t
// Tool versions:  Vivado 2017.4
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 

/* 
* Copyright 2017 IPFN-Instituto Superior Tecnico, Portugal
*  
* Licensed under the EUPL, Version 1.2 or - as soon they
will be approved by the European Commission - subsequent
versions of the EUPL (the "Licence");
* You may not use this work except in compliance with the
Licence.
* You may obtain a copy of the Licence at:
*  
*
https://joinup.ec.europa.eu/software/page/eupl
*  
* Unless required by applicable law or agreed to in
writing, software distributed under the Licence is
distributed on an "AS IS" basis,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
express or implied.
* See the Licence for the specific language governing
permissions and limitations under the Licence.
*/ 

module system_clocks (
    input  clk_200_in_p,
    input  clk_200_in_n,
    input  reset,
	output mmcm_locked,
	output clk_100_o,
	output clk_200_o,
	output clk_16,
	output data_clk,    //  40MHz clk 
	output new_sample,  //  40MHz clk domain 
	output adc_word_sync, //  450ns after adc_start_conv_n
	output adc_start_conv_n, 
	output clk_2mhz_tte_o  // sync with ADCs_word_sync but duty cycle = 50% 
);

	//reg [5:0] counter = 6'd0;

	reg [4:0] cnt_40_r = 5'd0;
    reg adc_start_conv_en= 1'b0;
    reg word_sync_r = 1'b0;
    reg new_sample_r= 1'b0;
    assign new_sample = new_sample_r;
    assign adc_word_sync = word_sync_r;
      
	//reg start_conv_n= 1'b1;
	reg clk_out_r= 1'b1;
	assign clk_2mhz_tte_o  = clk_out_r;

	//reg word_sync_n= 1'b1;
	wire  clk_200_i, clk_mmcm_fb, clk_mmcm_fb_buff, clk_100_mmcm, clk_16_mmcm, data_clk_mmcm, clk_200_mmcm, clk_20_mmcm;

	IBUFDS #(
      .DIFF_TERM("FALSE"),       // Differential Termination
      .IBUF_LOW_PWR("TRUE") //,     // Low power="TRUE", Highest performance="FALSE" 
      //.IOSTANDARD("DEFAULT")     // Specify the input I/O standard
	) IBUFDS_200_inst (
      .O(clk_200_i),  // Buffer output
      .I(clk_200_in_p),  // Diff_p buffer input (connect directly to top-level port)
      .IB(clk_200_in_n) // Diff_n buffer input (connect directly to top-level port)
	);

   MMCME2_BASE #(
      .BANDWIDTH("OPTIMIZED"),   // Jitter programming (OPTIMIZED, HIGH, LOW)
      .CLKFBOUT_MULT_F(4.0),     // Multiply value for all CLKOUT (2.000-64.000).
      .CLKFBOUT_PHASE(0.0),      // Phase offset in degrees of CLKFB (-360.000-360.000).
      .CLKIN1_PERIOD(5.0),       // Input clock period in ns to ps resolution : 200 MHz.
      // CLKOUT0_DIVIDE - CLKOUT6_DIVIDE: Divide amount for each CLKOUT (1-128)
      .CLKOUT0_DIVIDE_F(8.0),    // Divide amount for CLKOUT0 (1.000-128.000). 100 Mhz
//      .CLKOUT0_DIVIDE(8),   // Mhz
      .CLKOUT1_DIVIDE(50),  // 16 MHz
      .CLKOUT2_DIVIDE(80),  // testing 10Mhz data_clk,  20:40Mhz,  128:6.25 MHz
      .CLKOUT3_DIVIDE(4),   // 200 MHz
      .CLKOUT4_DIVIDE(40),  //20 Mhz
      .CLKOUT5_DIVIDE(1),
      .CLKOUT6_DIVIDE(1),
      // CLKOUT0_DUTY_CYCLE - CLKOUT6_DUTY_CYCLE: Duty cycle for each CLKOUT (0.01-0.99).
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT6_DUTY_CYCLE(0.5),
      // CLKOUT0_PHASE - CLKOUT6_PHASE: Phase offset for each CLKOUT (-360.000-360.000).
      .CLKOUT0_PHASE(0.0),
      .CLKOUT1_PHASE(0.0),
      .CLKOUT2_PHASE(0.0),
      .CLKOUT3_PHASE(0.0),
      .CLKOUT4_PHASE(0.0),
      .CLKOUT5_PHASE(0.0),
      .CLKOUT6_PHASE(0.0),
      .CLKOUT4_CASCADE("FALSE"), // Cascade CLKOUT4 counter with CLKOUT6 (FALSE, TRUE)
      .DIVCLK_DIVIDE(1),         // Master division value (1-106)
      .REF_JITTER1(0.0),         // Reference input jitter in UI (0.000-0.999).
      .STARTUP_WAIT("FALSE")     // Delays DONE until MMCM is locked (FALSE, TRUE)
   )
   MMCME2_BASE_200_osc (
      // Clock Outputs: 1-bit (each) output: User configurable clock outputs
      .CLKOUT0(clk_100_mmcm),     // 1-bit output: CLKOUT0
      .CLKOUT0B(),   // 1-bit output: Inverted CLKOUT0
      .CLKOUT1(clk_16_mmcm),     // 1-bit output: CLKOUT1
      .CLKOUT1B(),   // 1-bit output: Inverted CLKOUT1
      .CLKOUT2(data_clk_mmcm),     // 1-bit output: CLKOUT2
      .CLKOUT2B(),   // 1-bit output: Inverted CLKOUT2
      .CLKOUT3(clk_200_mmcm),     // 1-bit output: CLKOUT3
      .CLKOUT3B(),   // 1-bit output: Inverted CLKOUT3
      .CLKOUT4(clk_20_mmcm),     // 1-bit output: CLKOUT4
      .CLKOUT5(),     // 1-bit output: CLKOUT5
      .CLKOUT6(),     // 1-bit output: CLKOUT6
      // Feedback Clocks: 1-bit (each) output: Clock feedback ports
      .CLKFBOUT(clk_mmcm_fb),   // 1-bit output: Feedback clock
      .CLKFBOUTB(), // 1-bit output: Inverted CLKFBOUT
      // Status Ports: 1-bit (each) output: MMCM status ports
      .LOCKED(mmcm_locked),       // 1-bit output: LOCK
      // Clock Inputs: 1-bit (each) input: Clock input
      .CLKIN1(clk_200_i),       // 1-bit input: Clock
      // Control Ports: 1-bit (each) input: MMCM control ports
      .PWRDWN(1'b0),       // 1-bit input: Power-down
      .RST(reset),             // 1-bit input: Reset
      // Feedback Clocks: 1-bit (each) input: Clock feedback ports
      .CLKFBIN(clk_mmcm_fb_buff)      // 1-bit input: Feedback clock
   );

   BUFG BUFG_fb (
      .O(clk_mmcm_fb_buff), // 1-bit output: Clock output
      .I(clk_mmcm_fb)  // 1-bit input: Clock input
   );

	BUFG BUFG_100 (
      .O(clk_100_o), // 1-bit output: Clock output
      .I(clk_100_mmcm)  // 1-bit input: Clock input
	);
	BUFG BUFG_16 (
      .O(clk_16), // 1-bit output: Clock output
      .I(clk_16_mmcm)  // 1-bit input: Clock input
   	);
   	BUFG BUFG_data (
      .O(data_clk), // 1-bit output: Clock output
      .I(data_clk_mmcm)  // 1-bit input: Clock input
   	);
	BUFG BUFG_200 (
        .O(clk_200_o), 
        .I(clk_200_mmcm)  
    );
    /*
	BUFG BUFG_20 (
      .O(clk_20), // 1-bit output: Clock output
      .I(clk_20_mmcm)  // 1-bit input: Clock input
       );
    */   
    BUFGCE_1 BUFGCE_1_inst (
          .O(adc_start_conv_n),   // 1-bit output: Clock output
          .CE(adc_start_conv_en), // 1-bit input: Clock enable input for I0
          .I(clk_20_mmcm)    // 1-bit input: Primary clock
       );

/*	always @ (posedge clk_100_o)
		begin
			counter <= counter + 1;

			if(counter == 6'd17)
				clk_out_r <= 1'b0;
			else if(counter == 6'd33)
				word_sync_n <= 1'b0;
			else if(counter == 6'd38)
				word_sync_n <= 1'b1;
			else if(counter == 6'd43)
				begin
					start_conv_n <= 1'b0;
					clk_out_r <= 1'b1; 
				end
			else if(counter == 6'd49) // - divide by 50 -> 2MSMS
				begin
					start_conv_n <= 1'b1;
					counter <= 0; 
				end
		  end	
*/		  
	always @ (posedge data_clk)  // 40 MhHz T=25ns
              begin
                  cnt_40_r <= cnt_40_r + 1;
      
                  if(cnt_40_r == 5'd9)
				      clk_out_r <= 1'b1; 
                  else if(cnt_40_r == 5'd15)
                      word_sync_r <= 1'b1;
                  else if(cnt_40_r == 5'd16)
                        begin
                          word_sync_r <= 1'b0;
                          new_sample_r <= 1'b1;
                        end  
                  else if(cnt_40_r == 5'd17)
                        begin
                            adc_start_conv_en <= 1'b1;
                            new_sample_r <= 1'b0;
                        end  
                  else if(cnt_40_r == 5'd19) // - divide by 20 -> 2MSMS
                      begin
					      clk_out_r <= 1'b0; 
                          adc_start_conv_en <= 1'b0;
                          cnt_40_r <= 0; 
                      end
                end    

	//assign adc_word_sync_n = word_sync_n;
	//assign adc_start_conv_n = start_conv_n; // delay 50ns

endmodule



///////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Company: INSTITUTO DE PLASMAS E FUSAO NUCLEAR
// Engineer: BBC 
//
// Create Date:   13:45:00 15/04/2016
// Project Name:   
// Design Name:    
// Module Name:    shapi_stdrt_dev_inc
// Target Devices: 
// Tool versions:  Vivado 2017.4
// 
// Description: 
// Verilog Header
// SHAPI registers - standard device
//
//
// Copyright 2015 - 2017 IPFN-Instituto Superior Tecnico, Portugal
// Creation Date  2017-11-09
//
// Licensed under the EUPL, Version 1.2 or - as soon they
// will be approved by the European Commission - subsequent
// versions of the EUPL (the "Licence");
// You may not use this work except in compliance with the
// Licence.
// You may obtain a copy of the Licence at:
//
// https://joinup.ec.europa.eu/software/page/eupl
//
// Unless required by applicable law or agreed to in
// writing, software distributed under the Licence is
// distributed on an "AS IS" basis,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
// express or implied.
// See the Licence for the specific language governing
// permissions and limitations under the Licence.
//
`ifndef _shapi_stdrt_dev_inc_vh_
`define _shapi_stdrt_dev_inc_vh_

//####### SHAPI REGISTERS #############//

//#### STANDARD DEVICE REGISTERS ######//
`define DEV_MAGIC        16'h5348       //offset_addr 0x00     
`define DEV_MAJOR        8'h01   
`define DEV_MINOR        8'h00   
`define DEV_NEXT_ADDR    32'h0  	 // No other modules  32'h00000040,         //offset_addr 0x04 
`define DEV_NEXT_BAR1_REG    10'h10         // BAR1_WIDTH = 10  
`define DEV_HW_VENDOR    16'h10EE       //offset_addr 0x08 Xilinx Vendor
`define DEV_HW_ID        16'h0070 
`define DEV_FW_VENDOR    16'h1570       //offset_addr 0x0c
`define DEV_FW_ID        16'h1333  
`define DEV_FW_PATCH     16'h0001          //offset_addr 0x10
`define DEV_FW_MINOR     8'h01 
`define DEV_FW_MAJOR     8'h00 
// Linux command: date +%s
`define DEV_TSTAMP      32'd1547222996 //offset_addr 0x14 //unix timestamp-Tue Mar 2019

//`define DEV_NAME         96'h676E696D69544B4F54545349 //495354544F4B54696D696E67  //TimingISTTOK  //XDMAtest  58444D41 74657374
`define DEV_NAME1         32'h74657374 // 32'h54545349 
`define DEV_NAME2         32'h58444D41 
`define DEV_NAME3         32'h676E696D
`define DEV_ENDIAN_CAPAB   1'b0      //offset_addr 0x24 
`define DEV_RTM_CAPAB      1'b0      
`define DEV_SOFT_RST_CAPAB 1'b0      
`define DEV_FULL_RST_CAPAB 1'b0      

`define DEV_CNTRL_FULL_RST_BIT 31      
`define DEV_CNTRL_SFT_RST_BIT  30      
`define DEV_CNTRL_ENDIAN_BIT   0

`endif // _shapi_stdrt_dev_inc_vh_
      


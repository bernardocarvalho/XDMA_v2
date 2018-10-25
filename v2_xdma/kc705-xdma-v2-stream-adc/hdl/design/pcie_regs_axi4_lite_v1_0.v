//-----------------------------------------------------------------------------
//
// Project    : The Xilinx PCI Express DMA 
// File       : myip_axi4_lite_v1_0.v
// Version    : $IpVersion 
//-----------------------------------------------------------------------------
`timescale 1 ns / 1 ps
`include "shapi_stdrt_dev_inc.vh"

module pcie_regs_axi4_lite_v1_0 #(
		// Users to add parameters here

		// User parameters ends
		// Do not modify the parameters beyond this line

		// Width of S_AXI data bus
		parameter integer C_S_AXI_DATA_WIDTH	= 32,
		// Width of S_AXI address bus
		parameter integer C_S_AXI_ADDR_WIDTH	= 8
	)
	(
		// Users to add ports here

		// User ports ends
		// Do not modify the ports beyond this line

		// Global Clock Signal
		input wire  S_AXI_ACLK,
		// Global Reset Signal. This Signal is Active LOW
		input wire  S_AXI_ARESETN,
		// Write address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
		// Write channel Protection type. This signal indicates the
    		// privilege and security level of the transaction, and whether
    		// the transaction is a data access or an instruction access.
		//input wire [2 : 0] S_AXI_AWPROT,
		// Write address valid. This signal indicates that the master signaling
    		// valid write address and control information.
		input wire  S_AXI_AWVALID,
		// Write address ready. This signal indicates that the slave is ready
    		// to accept an address and associated control signals.
		output wire  S_AXI_AWREADY,
		// Write data (issued by master, acceped by Slave) 
		input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
		// Write strobes. This signal indicates which byte lanes hold
    		// valid data. There is one write strobe bit for each eight
    		// bits of the write data bus.    
		input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,  //Not used
		// Write valid. This signal indicates that valid write
    		// data and strobes are available.
		input wire  S_AXI_WVALID,
		// Write ready. This signal indicates that the slave
    		// can accept the write data.
		output wire  S_AXI_WREADY,
		// Write response. This signal indicates the status
    		// of the write transaction.
		output wire [1 : 0] S_AXI_BRESP,
		// Write response valid. This signal indicates that the channel
    		// is signaling a valid write response.
		output wire  S_AXI_BVALID,
		// Response ready. This signal indicates that the master
    		// can accept a write response.
		input wire  S_AXI_BREADY,
		// Read address (issued by master, acceped by Slave)
		input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
		// Protection type. This signal indicates the privilege
    		// and security level of the transaction, and whether the
    		// transaction is a data access or an instruction access.
		//input wire [2 : 0] S_AXI_ARPROT,
		// Read address valid. This signal indicates that the channel
    		// is signaling valid read address and control information.
		input wire  S_AXI_ARVALID,
		// Read address ready. This signal indicates that the slave is
    		// ready to accept an address and associated control signals.
		output wire  S_AXI_ARREADY,
		// Read data (issued by slave)
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
		// Read response. This signal indicates the status of the
    		// read transfer.
		output wire [1 : 0] S_AXI_RRESP,
		// Read valid. This signal indicates that the channel is
    		// signaling the required read data.
		output wire  S_AXI_RVALID,
		// Read ready. This signal indicates that the master can
    		// accept the read data and response information.
		input wire  S_AXI_RREADY,
		output wire [C_S_AXI_DATA_WIDTH-1 : 0] control_reg
		
	);

	// AXI4LITE signals
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_awaddr;
	reg  	axi_awready;
	reg  	axi_wready;
	reg [1 : 0] 	axi_bresp;
	reg  	axi_bvalid;
	reg [C_S_AXI_ADDR_WIDTH-1 : 0] 	axi_araddr;
	reg  	axi_arready;
	reg [C_S_AXI_DATA_WIDTH-1 : 0] 	axi_rdata;
	reg [1 : 0] 	axi_rresp;
	reg  	axi_rvalid;

    wire [31:0] wr_data_e = S_AXI_WDATA; // {S_AXI_WDATA[7:0], S_AXI_WDATA[15:8], S_AXI_WDATA[23:16], S_AXI_WDATA[31:24]}; // change endianess for Little Endian PCIe  

	// Example-specific design signals
	// local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	// ADDR_LSB is used for addressing 32/64 bit registers/memories
	// ADDR_LSB = 2 for 32 bits (n downto 2)
	// ADDR_LSB = 3 for 64 bits (n downto 3)
	localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH/32) + 1;
	localparam integer OPT_MEM_ADDR_BITS = 5;
	//----------------------------------------------
	//-- Signals for user logic register space example
	//------------------------------------------------
	//-- Number of Slave Registers 64

	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg10;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg11;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg12;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg13;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_reg14;
	reg [C_S_AXI_DATA_WIDTH-1:0]	dev_scratch_reg;
	reg [C_S_AXI_DATA_WIDTH-1:0]	slv_regs[63:16];

	integer	 reg_index;

	wire	 slv_reg_rden;
	wire	 slv_reg_wren;
	reg [C_S_AXI_DATA_WIDTH-1:0]	 reg_data_out;
	integer	 byte_index;

    assign control_reg = dev_scratch_reg;
	// I/O Connections assignments

	assign S_AXI_AWREADY	= axi_awready;
	assign S_AXI_WREADY	= axi_wready;
	assign S_AXI_BRESP	= axi_bresp;
	assign S_AXI_BVALID	= axi_bvalid;
	assign S_AXI_ARREADY	= axi_arready;
	assign S_AXI_RDATA	= axi_rdata; //32'h1234567A;
	assign S_AXI_RRESP	= axi_rresp;
	assign S_AXI_RVALID	= axi_rvalid;
	// Implement axi_awready generation
	// axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	// de-asserted when reset is low.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // slave is ready to accept write address when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_awready <= 1'b1;
	        end
	      else           
	        begin
	          axi_awready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_awaddr latching
	// This process is used to latch the address when both 
	// S_AXI_AWVALID and S_AXI_WVALID are valid. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_awaddr <= 0;
	    end 
	  else
	    begin    
	      if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID)
	        begin
	          // Write Address latching 
	          axi_awaddr <= S_AXI_AWADDR;
	        end
	    end 
	end       

	// Implement axi_wready generation
	// axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	// S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	// de-asserted when reset is low. 

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_wready <= 1'b0;
	    end 
	  else
	    begin    
	      if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID)
	        begin
	          // slave is ready to accept write data when 
	          // there is a valid write address and write data
	          // on the write address and data bus. This design 
	          // expects no outstanding transactions. 
	          axi_wready <= 1'b1;
	        end
	      else
	        begin
	          axi_wready <= 1'b0;
	        end
	    end 
	end       

	// Implement memory mapped register select and write logic generation
	// The write data is accepted and written to memory mapped registers when
	// axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	// select byte enables of slave registers while writing.
	// These registers are cleared when reset (active low) is applied.
	// Slave register write enable is asserted when valid address and data are available
	// and the slave is ready to accept the write address and write data.
	assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	    

	      slv_reg10 <= 0;
	      slv_reg11 <= 0;
	      slv_reg12 <= 0;
	      slv_reg13 <= 0;
	      slv_reg14 <= 0;
	      dev_scratch_reg <= 0;
	      for ( reg_index = 16; reg_index < 64; reg_index = reg_index +1 )
	           slv_regs[reg_index] <= 0;
	      
	    end 
	  else begin
	    if (slv_reg_wren)
	      begin
	        case ( axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
/*	          
	          6'h01:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 1
	                slv_reg1[(byte_index*8) +: 8] <= S_AXI_WDATA[(byte_index*8) +: 8];
	              end  

	          6'h0A:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 10
	                slv_reg10[(byte_index*8) +: 8] <= wr_data_e[(byte_index*8) +: 8];
	              end  
	          6'h0E:
	            for ( byte_index = 0; byte_index <= (C_S_AXI_DATA_WIDTH/8)-1; byte_index = byte_index+1 )
	              if ( S_AXI_WSTRB[byte_index] == 1 ) begin
	                // Respective byte enables are asserted as per write strobes 
	                // Slave register 14
	                slv_reg14[(byte_index*8) +: 8] <= wr_data_e[(byte_index*8) +: 8];
	              end  
	     */
	          6'h0A: slv_reg10 <= wr_data_e; 
              6'h0B: slv_reg11 <= wr_data_e; 
              6'h0C: slv_reg12 <= wr_data_e; 
              6'h0D: slv_reg13 <= wr_data_e; 
              6'h0E: slv_reg14 <= wr_data_e; 
	          6'h0F: dev_scratch_reg <= wr_data_e;   
	          6'h10: slv_regs[16] <= wr_data_e; 	       
	          6'h11: slv_regs[17] <= wr_data_e; 	       
	          6'h12: slv_regs[18] <= wr_data_e; 	       
	          6'h13: slv_regs[19] <= wr_data_e; 	       
	          6'h14: slv_regs[20] <= wr_data_e; 	       
	          6'h15: slv_regs[21] <= wr_data_e; 	       
	          6'h16: slv_regs[22] <= wr_data_e; 	       
	          6'h17: slv_regs[23] <= wr_data_e; 	       
	          6'h18: slv_regs[24] <= wr_data_e; 	       
	          6'h19: slv_regs[25] <= wr_data_e; 	       
	          6'h1A: slv_regs[26] <= wr_data_e; 	       
	          6'h1B: slv_regs[27] <= wr_data_e; 	       
	          6'h1C: slv_regs[28] <= wr_data_e; 	       
	          6'h1D: slv_regs[29] <= wr_data_e; 	       
	          6'h1E: slv_regs[30] <= wr_data_e; 	       
	          6'h1F: slv_regs[31] <= wr_data_e; 	       
	          6'h20: slv_regs[32] <= wr_data_e; 	       
	          6'h21: slv_regs[33] <= wr_data_e; 	       
	          6'h22: slv_regs[34] <= wr_data_e; 	       
	          6'h23: slv_regs[35] <= wr_data_e; 	       
	          6'h24: slv_regs[36] <= wr_data_e; 	       
	          6'h25: slv_regs[37] <= wr_data_e; 	       
	          6'h26: slv_regs[38] <= wr_data_e; 	       
	          6'h27: slv_regs[39] <= wr_data_e; 	       
	          	          
	          6'h28: slv_regs[40] <= wr_data_e; 	              
	          6'h29: slv_regs[41] <= wr_data_e; 	              
	          6'h2A: slv_regs[42] <= wr_data_e; 	              
	          6'h2B: slv_regs[43] <= wr_data_e; 	              
	          6'h2C: slv_regs[44] <= wr_data_e; 	              
	          6'h2D: slv_regs[45] <= wr_data_e; 	              
	          6'h2E: slv_regs[46] <= wr_data_e; 	              
	          6'h2F: slv_regs[47] <= wr_data_e; 	              
	          6'h30: slv_regs[48] <= wr_data_e; 	              
	          6'h31: slv_regs[49] <= wr_data_e; 	              
	          6'h32: slv_regs[50] <= wr_data_e; 	              
	          6'h33: slv_regs[51] <= wr_data_e; 	              
	          6'h34: slv_regs[52] <= wr_data_e; 	              
	          6'h35: slv_regs[53] <= wr_data_e; 	              
	          6'h36: slv_regs[54] <= wr_data_e; 	              
	          6'h37: slv_regs[55] <= wr_data_e; 	              
	          6'h38: slv_regs[56] <= wr_data_e; 	              
	          6'h39: slv_regs[57] <= wr_data_e; 	              
	          6'h3A: slv_regs[58] <= wr_data_e; 	              
	          6'h3B: slv_regs[59] <= wr_data_e; 	              
	          6'h3C: slv_regs[60] <= wr_data_e; 	              
	          6'h3D: slv_regs[61] <= wr_data_e; 	              
	          6'h2E: slv_regs[62] <= wr_data_e; 	              
	          6'h2F: slv_regs[63] <= wr_data_e; 	              
	          default : begin
                     
	                      slv_reg10 <= slv_reg10;
	                      slv_reg11 <= slv_reg11;
	                      slv_reg12 <= slv_reg12;
	                      slv_reg13 <= slv_reg13;
	                      slv_reg14 <= slv_reg14;
	                      dev_scratch_reg <= dev_scratch_reg;
	                       for (reg_index = 16; reg_index < 64; reg_index = reg_index +1 )
                               slv_regs[reg_index] <= slv_regs[reg_index];	                      

	                    end
	        endcase
	      end
	  end
	end    

	// Implement write response logic generation
	// The write response and response valid signals are asserted by the slave 
	// when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	// This marks the acceptance of address and indicates the status of 
	// write transaction.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_bvalid  <= 0;
	      axi_bresp   <= 2'b0;
	    end 
	  else
	    begin    
	      if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
	          // indicates a valid write response is available
	          axi_bvalid <= 1'b1;
	          axi_bresp  <= 2'b0; // 'OKAY' response 
	        end                   // work error responses in future
	      else
	        begin
	          if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
	              axi_bvalid <= 1'b0; 
	            end  
	        end
	    end
	end   

	// Implement axi_arready generation
	// axi_arready is asserted for one S_AXI_ACLK clock cycle when
	// S_AXI_ARVALID is asserted. axi_awready is 
	// de-asserted when reset (active low) is asserted. 
	// The read address is also latched when S_AXI_ARVALID is 
	// asserted. axi_araddr is reset to zero on reset assertion.

	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_arready <= 1'b0;
	      axi_araddr  <= 32'b0;
	    end 
	  else
	    begin    
	      if (~axi_arready && S_AXI_ARVALID)
	        begin
	          // indicates that the slave has acceped the valid read address
	          axi_arready <= 1'b1;
	          // Read address latching
	          axi_araddr  <= S_AXI_ARADDR;
	        end
	      else
	        begin
	          axi_arready <= 1'b0;
	        end
	    end 
	end       

	// Implement axi_arvalid generation
	// axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	// S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	// data are available on the axi_rdata bus at this instance. The 
	// assertion of axi_rvalid marks the validity of read data on the 
	// bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	// is deasserted on reset (active low). axi_rresp and axi_rdata are 
	// cleared to zero on reset (active low).  
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rvalid <= 0;
	      axi_rresp  <= 0;
	    end 
	  else
	    begin    
	      if (axi_arready && S_AXI_ARVALID && ~axi_rvalid)
	        begin
	          // Valid read data is available at the read data bus
	          axi_rvalid <= 1'b1;
	          axi_rresp  <= 2'b0; // 'OKAY' response
	        end   
	      else if (axi_rvalid && S_AXI_RREADY)
	        begin
	          // Read data is accepted by the master
	          axi_rvalid <= 1'b0;
	        end                
	    end
	end    

	// Implement memory mapped register select and read logic generation
	// Slave register read enable is asserted when valid address is available
	// and the slave is ready to accept the read address.
	assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
	always @(*)
	begin
/*

device: /dev/xdma0_control
address: 0x00000fff
access type: read
access width: word (32-bits)
character device /dev/xdma0_control opened.
Memory mapped at address 0x7fb269352000.
Read 32-bit value at address 0x00000fff (0x7fb269352fff): 0xc1800600

address: 0x00000000
access type: read
access width: word (32-bits)
character device /dev/xdma0_control opened.
Memory mapped at address 0x7ff4e0765000.
Read 32-bit value at address 0x00000000 (0x7ff4e0765000): 0x1fc08006

               10'd10: pcie_rd_data   <=#TCQ {dev_full_rst_status,dev_soft_rst_status,28'h0,dev_rtm_status,dev_endian_status};    //status
               10'd11: pcie_rd_data   <=#TCQ {dev_full_rst_control,dev_soft_rst_control,29'h0,dev_endian_control};                //control
               10'd12: pcie_rd_data   <=#TCQ dev_interrupt_mask_r;                                                                  //Interrupt_Mask
               10'd13: pcie_rd_data   <=#TCQ dev_interrupt_flag;                                                                  //Interrupt Flag
               10'd14: pcie_rd_data   <=#TCQ dev_interrupt_active_r;                                                                //Interrupt Active
               10'd15: pcie_rd_data   <=#TCQ dev_scratch_reg_r;  

*/
	      // Address decoding for reading registers
	      case ( axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] )
	        6'h00   : reg_data_out <= {`DEV_MAGIC,`DEV_MAJOR, `DEV_MINOR}; //slv_reg0; 32'h53480100
	        6'h01   : reg_data_out <= `DEV_NEXT_ADDR; // PC reg add
	        6'h02   : reg_data_out <= {`DEV_HW_ID,`DEV_HW_VENDOR};
	        6'h03   : reg_data_out <= {`DEV_FW_ID,`DEV_FW_VENDOR};
	        6'h04   : reg_data_out <= {`DEV_FW_MAJOR,`DEV_FW_MINOR,`DEV_FW_PATCH};
	        6'h05   : reg_data_out <= `DEV_TSTAMP;
	        6'h06   : reg_data_out <= `DEV_NAME1;
	        6'h07   : reg_data_out <= `DEV_NAME2;
	        6'h08   : reg_data_out <= `DEV_NAME3;
	        6'h09   : reg_data_out <= {`DEV_FULL_RST_CAPAB,`DEV_SOFT_RST_CAPAB,28'h0,`DEV_RTM_CAPAB,`DEV_ENDIAN_CAPAB};
	        6'h0A   : reg_data_out <= slv_reg10;
	        6'h0B   : reg_data_out <= slv_reg11;
	        6'h0C   : reg_data_out <= slv_reg12;
	        6'h0D   : reg_data_out <= slv_reg13;
	        6'h0E   : reg_data_out <= slv_reg14;
	        6'h0F   : reg_data_out <= dev_scratch_reg; 
	        6'h10   : reg_data_out <= slv_regs[16];
	        6'h11   : reg_data_out <= slv_regs[17];
	        6'h12   : reg_data_out <= slv_regs[18];
	        6'h13   : reg_data_out <= slv_regs[19];
	        6'h14   : reg_data_out <= slv_regs[20];
	        6'h15   : reg_data_out <= slv_regs[21];  //   // PC reg add 0x3c
	        6'h16   : reg_data_out <= slv_regs[22];
	        6'h17   : reg_data_out <= slv_regs[23];
	        6'h18   : reg_data_out <= slv_regs[24];
	        6'h19   : reg_data_out <= slv_regs[25];
	        6'h1A   : reg_data_out <= slv_regs[26];
	        6'h1B   : reg_data_out <= slv_regs[27];
	        6'h1C   : reg_data_out <= slv_regs[28];
	        6'h1D   : reg_data_out <= slv_regs[29];
	        6'h1E   : reg_data_out <= slv_regs[30];
	        6'h1F   : reg_data_out <= slv_regs[31];
	        6'h20   : reg_data_out <= slv_regs[32];
	        6'h21   : reg_data_out <= slv_regs[33];
	        6'h22   : reg_data_out <= slv_regs[34];
	        6'h23   : reg_data_out <= slv_regs[35];
	        6'h24   : reg_data_out <= slv_regs[36];
	        6'h25   : reg_data_out <= slv_regs[37];
	        6'h26   : reg_data_out <= slv_regs[38];
	        6'h27   : reg_data_out <= slv_regs[39];
	        
	        6'h28   : reg_data_out <= slv_regs[40];
	        6'h29   : reg_data_out <= slv_regs[41];
	        6'h2A   : reg_data_out <= slv_regs[42];
	        6'h2B   : reg_data_out <= slv_regs[43];
	        6'h2C   : reg_data_out <= slv_regs[44];
	        6'h2D   : reg_data_out <= slv_regs[45];
	        6'h2E   : reg_data_out <= slv_regs[46];
	        6'h2F   : reg_data_out <= slv_regs[47];
	        6'h30   : reg_data_out <= slv_regs[48];
	        6'h31   : reg_data_out <= slv_regs[49];
	        6'h32   : reg_data_out <= slv_regs[50];
	        6'h33   : reg_data_out <= slv_regs[51];
	        6'h34   : reg_data_out <= slv_regs[52];
	        6'h35   : reg_data_out <= slv_regs[53];
	        6'h36   : reg_data_out <= slv_regs[54];
	        6'h37   : reg_data_out <= slv_regs[55];
	        6'h38   : reg_data_out <= slv_regs[56];
	        6'h39   : reg_data_out <= slv_regs[57];
	        6'h3A   : reg_data_out <= slv_regs[58];
	        6'h3B   : reg_data_out <= slv_regs[59];
	        6'h3C   : reg_data_out <= slv_regs[60];
	        6'h3D   : reg_data_out <= slv_regs[61];
	        6'h3E   : reg_data_out <= slv_regs[62]; //slv_reg62;
	        6'h3F   : reg_data_out <= slv_regs[63]; //32'h0FFF0FF0; //slv_reg63;
	        default : reg_data_out <= 0;
	      endcase
	end

	// Output register or memory read data
	always @( posedge S_AXI_ACLK )
	begin
	  if ( S_AXI_ARESETN == 1'b0 )
	    begin
	      axi_rdata  <= 0;
	    end 
	  else
	    begin    
	      // When there is a valid read address (S_AXI_ARVALID) with 
	      // acceptance of read address by the slave (axi_arready), 
	      // output the read dada 
	      if (slv_reg_rden)
	        begin
	          axi_rdata <=  reg_data_out;     // register read data {reg_data_out[7:0], reg_data_out[15:8], reg_data_out[23:16], reg_data_out[31:24]}; // change endianess 
	        end   
	    end
	end    

	// Add user logic here

	// User logic ends

	endmodule

-------------------------------------------------------------------------------
-- Title      : AXI4 Stream simple source
-- Project    : 
-------------------------------------------------------------------------------
-- File       : axi4s_src1.vhd
-- Author     : Wojciech M. Zabolotny <wzab01@gmail.com>
-- Company    : 
-- Created    : 2016-08-09
-- Last update: 2017-04-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This file implements the minimalistic source of data
--              transmitted via AXI4 Stream
--              The source provides data sets consisting of 3 packets with length
--              of 704 bytes.
--              The delay between the packets is adjustable.
-------------------------------------------------------------------------------
-- Copyright (c) 2016 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2016-08-09  1.0      xl      Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.test_data_pkg.all;
-------------------------------------------------------------------------------
entity axi4s_src3 is

  port (
    -- AXI4 Stream interface
    tdata  : out std_logic_vector(703 downto 0);
    tkeep  : out std_logic_vector(87 downto 0);
    tlast  : out std_logic;
    tready : in  std_logic;
    tvalid : out std_logic;
    -- System interface
    clk    : in  std_logic;
    resetn : in  std_logic;
    -- Start signal
    start  : in  std_logic
    );

end entity axi4s_src3;

architecture rtl of axi4s_src3 is
  constant PKT_DEL   : integer                := 10;
  type     T_SRC_STATE is (ST_IDLE, ST_START_HEAD, ST_START_PKT, ST_SEND_PKT);
  signal   src_state : T_SRC_STATE            := ST_IDLE;
  signal   pkt_step  : integer                := 0;
  signal   s_data    : unsigned(255 downto 0) := (others => '0');
  signal   cnt_data  : unsigned(31 downto 0)  := (others => '0');
  signal   old_start : std_logic              := '0';
  signal   wrd_count : integer                := 0;
  signal   pkt_len   : integer                := 0;
  signal   del_cnt   : integer                := 0;
  signal   init_data : integer                := 0;
  signal   shift_reg : std_logic_vector(48 downto 0);
  signal   ack_pkt   : std_logic              := '0';
  signal   start_pkt : std_logic              := '0';

  function mk_rec (
    constant chn_num   : integer;
    constant timestamp : unsigned(31 downto 0);
    constant data      : unsigned(639 downto 0))
    return unsigned is
    variable res : unsigned(703 downto 0) := (others => '0');
  begin
    res(703 downto 696) := to_unsigned(chn_num,8);
    res(671 downto 640) := timestamp;
    res(639 downto 0) := data;
    return res;
  end function mk_rec;
  
begin  -- architecture rtl

  tkeep <= (others => '1');
  tdata <= std_logic_vector(s_data);

  -- Here we have the pseudorandom generator, used to generate the number of
  -- channel and the delay between the packets
  p2 : process (clk) is
    variable new_bit : std_logic := '0';
  begin  -- process p2
    if clk'event and clk = '1' then     -- rising clock edge
      if resetn = '0' then              -- synchronous reset (active high)
        shift_reg <= std_logic_vector(to_unsigned(1, 49));
      else
        -- Shift register
        new_bit   := shift_reg(48) xor shift_reg(39);
        shift_reg <= shift_reg(47 downto 0) & new_bit;
      end if;
    end if;
  end process p2;

  -- We need a process, that periodically starts sending of the new packet
  -- The delay between packets should not depend on the length of each packet
  p0 : process (clk) is
  begin  -- process p0
    if clk'event and clk = '1' then     -- rising clock edge
      if (resetn = '0') or (start = '0') then  -- synchronous reset (active high)
        del_cnt   <= 0;
        start_pkt <= '0';
      else
        -- If generation of packet is acknowledged, clear start_pkt
        if ack_pkt = '1' then
          start_pkt <= '0';
        end if;
        -- Update the delay counter, and set the start_pkt flag when necessary
        if del_cnt < PKT_DEL then
          del_cnt <= del_cnt + 1;
        else
          start_pkt <= '1';
          del_cnt   <= 0;
        end if;
      end if;
    end if;
  end process p0;


  p1 : process (clk) is
    variable v_chn_num : integer;
    signal s_timestamp : unsigned(31 downto 0);
  begin  -- process p1
    if clk'event and clk = '1' then     -- rising clock edge
      if resetn = '0' then              -- synchronous reset (active low)
        s_data    <= (others => '0');
        tvalid    <= '0';
        tlast     <= '0';
        old_start <= '0';
        ack_pkt   <= '0';
        src_state <= ST_IDLE;
      else
        -- Ensure default values of the signal
        ack_pkt <= '0';
        case src_state is
          when ST_IDLE =>
            if start_pkt = '1' then
              -- Get the randomized delay until the next packet.
              pkt_del <= to_integer(unsigned(shift_reg(30 downto 12))) + 160000;
              -- Get the number of the channel
              v_chn_num   := to_integer(unsigned(shift_reg(5 downto 0)));
              if v_chn_num=0 or v_chn_num=63 then
                v_chn_num := to_integer(unsigned(shift_reg(11 downto 6)));
                if v_chn_num = 0 then
                  v_chn_num = 1;
                end if;
                if v_chn_num = 63 then
                  v_chn_num = 62;
                end if;                
              end if;
              chn_num <= v_chn_num;
              s_timestamp <= timestamp;
              src_state <= ST_WORD0;
            end if;
          when ST_WORD0 =>
            s_data <= mk_rec(chn_num-1, s_timestamp, data_ch0);
            tvalid               <= '1';
            tlast                <= '0';
            ack_pkt              <= '1';
            src_state            <= ST_WORD1;
          when ST_WORD1 =>
            if tready = '1' then
              s_data <= mk_rec(chn_num, s_timestamp, data_ch1);
              src_state            <= ST_WORD2;              
            end if;
          when ST_WORD2 =>
            if tready = '1' then
              s_data <= mk_rec(chn_num+1, s_timestamp, data_ch1);
              tlast <= '1';
              src_state            <= ST_END;              
            end if;
          when ST_END =>
             if tready = '1' then
               wrd_count <= 0;
               s_data    <= (others => '0');
               tvalid    <= '0';
               tlast     <= '0';
               src_state <= ST_IDLE;
             end if;
          when others => null;
        end case;
      end if;
    end if;
  end process p1;

end architecture rtl;

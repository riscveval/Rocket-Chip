--*****************************************************************************
-- (c) Copyright 2008-2009 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor                : Xilinx
-- \   \   \/     Version               : 3.92
--  \   \         Application           : MIG
--  /   /         Filename              : arb_select.vhd
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : Tue Jun 30 2009
--  \___\/\___\
--
--Device            : Virtex-6
--Design Name       : DDR3 SDRAM
--Purpose           :
--Reference         :
--Revision History  :
--*****************************************************************************


library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.std_logic_arith.all;

-- Based on granta_r and grantc_r, this module selects a
-- row and column command from the request information
-- provided by the bank machines.
--
-- Depending on address mode configuration, nCL and nCWL, a column
-- command pipeline of up to three states will be created.

entity arb_select is
   generic (
            TCQ                      : integer := 100;
            ADDR_CMD_MODE            : string := "1T";
            BANK_VECT_INDX           : integer := 11;
            BANK_WIDTH               : integer := 3;
            BURST_MODE               : string := "8";
            CS_WIDTH                 : integer := 4;
            DATA_BUF_ADDR_VECT_INDX  : integer := 31;
            DATA_BUF_ADDR_WIDTH      : integer := 8;
            DRAM_TYPE                : string := "DDR3";
            EARLY_WR_DATA_ADDR       : string := "OFF";
            ECC                      : string := "OFF";
            nBANK_MACHS              : integer := 4;
            nCK_PER_CLK              : integer := 2;
            nCS_PER_RANK             : integer := 1;
            nSLOTS                   : integer := 2;
            RANK_VECT_INDX           : integer := 15;
            RANK_WIDTH               : integer := 2;
            ROW_VECT_INDX            : integer := 63;
            ROW_WIDTH                : integer := 16;
            RTT_NOM                  : string := "40";
            RTT_WR                   : string := "120";
            SLOT_0_CONFIG            : std_logic_vector(7 downto 0) := "00000101";
            SLOT_1_CONFIG            : std_logic_vector(7 downto 0) := "00001010"
           );
   
   port (
          col_periodic_rd          : out std_logic;
          col_ra                   : out std_logic_vector(RANK_WIDTH - 1 downto 0);
          col_ba                   : out std_logic_vector(BANK_WIDTH - 1 downto 0);
          col_a                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);
          col_rmw                  : out std_logic;
          col_size                 : out std_logic;
          col_row                  : out std_logic_vector(ROW_WIDTH - 1 downto 0);
          col_data_buf_addr        : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
          col_wr_data_buf_addr     : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
          -- Output dfi bus 0.
          dfi_bank0                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
          dfi_address0             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
          dfi_ras_n0               : out std_logic;
          dfi_cas_n0               : out std_logic;
          dfi_we_n0                : out std_logic;
          -- Output dfi bus 1.
          dfi_bank1                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
          dfi_address1             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
          dfi_ras_n1               : out std_logic;
          dfi_cas_n1               : out std_logic;
          dfi_we_n1                : out std_logic;
          -- Output dfi cs busses.
          dfi_cs_n0                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
          dfi_cs_n1                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
          -- Output io_config info.
          io_config                : out std_logic_vector(RANK_WIDTH downto 0);
          -- Generate ODT signals.
          -- Start by figuring out if the slot has more than one
          -- rank populated and should hence use dynamic ODT.
          -- if (nSLOTS > 1)
          -- else: !if(nSLOTS > 1)
          dfi_odt_nom0             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
          dfi_odt_wr0              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
          dfi_odt_nom1             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
          dfi_odt_wr1              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
          clk                      : in std_logic;
          rst                      : in std_logic;
          req_rank_r               : in std_logic_vector(RANK_VECT_INDX downto 0);
          req_bank_r               : in std_logic_vector(BANK_VECT_INDX downto 0);
          req_ras                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          req_cas                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          req_wr_r                 : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          grant_row_r              : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          row_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
          row_cmd_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          insert_maint_r1          : in std_logic;
          maint_zq_r               : in std_logic;
          maint_rank_r             : in std_logic_vector(RANK_WIDTH - 1 downto 0);
          req_periodic_rd_r        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          req_size_r               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          rd_wr_r                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          req_row_r                : in std_logic_vector(ROW_VECT_INDX downto 0);
          col_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
          req_data_buf_addr_r      : in std_logic_vector(DATA_BUF_ADDR_VECT_INDX downto 0);
          grant_col_r              : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          grant_col_wr             : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          send_cmd0_col            : in std_logic;
          send_cmd1_row            : in std_logic;
          cs_en0                   : in std_logic;
          cs_en1                   : in std_logic;
          force_io_config_rd_r1    : in std_logic;
          grant_config_r           : in std_logic_vector(nBANK_MACHS - 1 downto 0);
          io_config_strobe         : in std_logic;
          slot_0_present           : in std_logic_vector(7 downto 0);
          slot_1_present           : in std_logic_vector(7 downto 0)
         );
end entity arb_select;

architecture trans of arb_select is

   function REDUCTION_OR( A: in std_logic_vector) return std_logic is
   variable tmp : std_logic := '0';
   begin
     for i in A'range loop
        tmp := tmp or A(i);
     end loop;
     return tmp;
   end function REDUCTION_OR;
   
   
   function REDUCTION_NOR( A: in std_logic_vector) return std_logic is
   variable tmp : std_logic := '0';
   begin
     for i in A'range loop
        tmp := tmp or A(i);
     end loop;
     return not (tmp);
   end function REDUCTION_NOR;
   
   function SEL_SAT_ADD (A: in std_logic_vector; B: in std_logic_vector) return std_logic_vector is
   variable tmp : std_logic_vector (1 downto 0);
   begin
       tmp := A;
       for i in B'range loop
         if ( not (tmp (1)) = '1') then
            if ( B(i) = '1') then
              tmp := conv_std_logic_vector ( (conv_integer(tmp) + 1), 2);
            end if;
         end if;
       end loop;
       return tmp;
   end function SEL_SAT_ADD;
   
   function BOOLEAN_TO_STD_LOGIC(A : in BOOLEAN) return std_logic is
   begin
      if A = true then
          return '1';
      else
          return '0';
      end if;
   end function BOOLEAN_TO_STD_LOGIC;
   
   function and2bits ( io_config_one_hot, slot_0_present: std_logic_vector; CS_WIDTH : integer ) return std_logic_vector is
   begin
       if ( CS_WIDTH < 2 ) then
           return ('0' & (io_config_one_hot(0) and slot_0_present(0)));
       else
           return ( io_config_one_hot(1 downto 0) and slot_0_present);
       end if;
   end function and2bits;
   
   constant       OUT_CMD_WIDTH      : integer := RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + 1 + 1 + 1;
   constant ONE                      : std_logic_vector(nCS_PER_RANK -1 downto 0) := (others => '1');
   
   signal i                          : integer;
   signal row_cmd_ns                 : std_logic_vector(OUT_CMD_WIDTH - 1 downto 0);
   signal col_cmd_ns                 : std_logic_vector(OUT_CMD_WIDTH - 1 downto 0);
   signal col_cmd_r                  : std_logic_vector(OUT_CMD_WIDTH - 1 downto 0) := (others => '0');
   signal cmd0                       : std_logic_vector(OUT_CMD_WIDTH - 1 downto 0);
   signal cmd1                       : std_logic_vector(OUT_CMD_WIDTH - 1 downto 0) := conv_std_logic_vector(1,OUT_CMD_WIDTH);
   signal ra0                        : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal ra1                        : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal cs_one_hot                 : std_logic_vector(CS_WIDTH*nCS_PER_RANK - 1 downto 0);
   signal io_config_ns               : std_logic_vector(RANK_WIDTH downto 0);
   signal io_config_r                : std_logic_vector(RANK_WIDTH downto 0);
   signal io_config_one_hot          : std_logic_vector(CS_WIDTH - 1 downto 0);
   signal io_config_one_hot_temp     : std_logic_vector(1 downto 0);
   signal slot_0_present_concat      : std_logic_vector(1 downto 0);
   signal slot_0_select              : std_logic;
   signal slot_0_read                : std_logic;
   signal slot_0_write               : std_logic;
   signal slot_1_population          : std_logic_vector(1 downto 0) := (others => '0');
   signal slot_0_population          : std_logic_vector(1 downto 0);
   signal slot_0_dynamic_odt         : std_logic;
   signal odt_0_nom                  : std_logic;
   signal odt_0_wr                   : std_logic;
   signal odt_nom                    : std_logic_vector(nSLOTS * nCS_PER_RANK - 1 downto 0);
   signal odt_wr                     : std_logic_vector(nSLOTS * nCS_PER_RANK - 1 downto 0);
   signal col_size_r                 : std_logic;
   signal col_size_ns                : std_logic;
   signal odt_1_nom                  : std_logic;
   signal odt_1_wr                   : std_logic;
   signal col_data_buf_addr_r        : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal col_data_buf_addr_ns       : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal col_periodic_rd_ns         : std_logic;
   signal col_periodic_rd_r          : std_logic;
   signal col_rmw_r                  : std_logic;
   signal col_rmw_ns                 : std_logic;
   signal col_row_r                  : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_row_ns                 : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_wr_data_buf_ns         : std_logic_vector(DATA_BUF_ADDR_WIDTH -1 downto 0);
   signal col_wr_data_buf_addr_r     : std_logic_vector(DATA_BUF_ADDR_WIDTH -1 downto 0);
   signal col_wr_data_buf_addr_ns    : std_logic_vector(DATA_BUF_ADDR_WIDTH -1 downto 0);
   signal slot_1_select              : std_logic;
   signal slot_1_read                : std_logic;
   signal slot_1_write               : std_logic;
   signal slot_1_dynamic_odt         : std_logic;

   --Non Verilog signals
   signal cs_en0_tmp                 : std_logic_vector(CS_WIDTH * nCS_PER_RANK -1 downto 0);
   signal cs_en1_tmp                 : std_logic_vector(CS_WIDTH * nCS_PER_RANK -1 downto 0);
   signal dfi_cs_n1_one_hot_lshift   : std_logic_vector(CS_WIDTH * nCS_PER_RANK -1 downto 0);
   signal dfi_cs_n0_one_hot_lshift   : std_logic_vector(CS_WIDTH * nCS_PER_RANK -1 downto 0);
   signal nCS_PER_RANK_odt_0_nom     : std_logic_vector(nCS_PER_RANK - 1 downto 0);
   signal nCS_PER_RANK_odt_1_nom     : std_logic_vector(nCS_PER_RANK - 1 downto 0);
   signal nCS_PER_RANK_odt_1_wr      : std_logic_vector(nCS_PER_RANK - 1 downto 0);
   signal nCS_PER_RANK_odt_0_wr      : std_logic_vector(nCS_PER_RANK - 1 downto 0);

   -- X-HDL generated signals
   signal xhdl10                     : std_logic_vector(23 downto 0);
   signal col_cmd_ns_x1              : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal col_cmd_ns_x2              : std_logic_vector(OUT_CMD_WIDTH-3-RANK_WIDTH - 1 downto 0);
   signal col_cmd_ns_x3              : std_logic_vector(2 downto 0);
   signal col_cmd_ns_x4              : std_logic;
   
   -- Declare intermediate signals for referenced outputs
   signal dfi_bank0_xhdl2            : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_address0_xhdl0         : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal dfi_ras_n0_xhdl6           : std_logic;
   signal dfi_cas_n0_xhdl4           : std_logic;
   signal dfi_we_n0_xhdl8            : std_logic;
   signal dfi_bank1_xhdl3            : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_address1_xhdl1         : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal dfi_ras_n1_xhdl7           : std_logic;
   signal dfi_cas_n1_xhdl5           : std_logic;
   signal dfi_we_n1_xhdl9            : std_logic;
   signal maint_cmd                  : std_logic_vector(OUT_CMD_WIDTH-1 downto 0);
   signal row_cmd_r                  : std_logic_vector(OUT_CMD_WIDTH-1 downto 0) := (others => '0');
   signal maint_zq_r_value           : std_logic_vector(2 downto 0); 
   signal int_value1                 : std_logic_vector(OUT_CMD_WIDTH-1 downto 0);
   
begin

   -- Drive referenced outputs
   ra0          <= cmd0(RANK_WIDTH + BANK_WIDTH + ROW_WIDTH  + 2  downto BANK_WIDTH + ROW_WIDTH  + 3 );
   dfi_bank0    <= cmd0(BANK_WIDTH + ROW_WIDTH  + 2 downto ROW_WIDTH  + 3);
   dfi_address0 <= cmd0(ROW_WIDTH + 2 downto 3);
   dfi_ras_n0   <= cmd0(2);
   dfi_cas_n0   <= cmd0(1);
   dfi_we_n0    <= cmd0(0);
   ra1          <= cmd1(RANK_WIDTH + BANK_WIDTH + ROW_WIDTH  + 2  downto BANK_WIDTH + ROW_WIDTH  + 3 );
   dfi_bank1    <= cmd1(BANK_WIDTH + ROW_WIDTH  + 2 downto ROW_WIDTH  + 3);
   dfi_address1 <= cmd1(ROW_WIDTH + 2 downto 3);
   dfi_ras_n1   <= cmd1(2);
   dfi_cas_n1   <= cmd1(1);
   dfi_we_n1    <= cmd1(0);
   
   int_value1 <= (others => '0') when rst = '1' else
                    maint_cmd when insert_maint_r1 = '1' else
                    row_cmd_r;
   
   maint_zq_r_value <= "110" when maint_zq_r = '1' else "001";
                -- RANKWIDTH
   maint_cmd <= (maint_rank_r & row_cmd_r(BANK_WIDTH+ROW_WIDTH-11 + 15 - 1 downto 15) & 
                 '0' & row_cmd_r(13 - 1 downto 3) & maint_zq_r_value);
   
   process (grant_row_r, insert_maint_r1, maint_cmd,
            req_bank_r, req_cas, req_rank_r, req_ras,
            row_addr, row_cmd_r, row_cmd_wr, rst,int_value1)
   variable row_cmd_ns_tmp : std_logic_vector(OUT_CMD_WIDTH - 1 downto 0);
   begin
      row_cmd_ns_tmp := int_value1;
      for i in 0 to  nBANK_MACHS - 1 loop
         if (grant_row_r(i) = '1') then 
            row_cmd_ns_tmp := (req_rank_r(RANK_WIDTH * i + RANK_WIDTH - 1 downto (RANK_WIDTH * i)) &
                               req_bank_r(BANK_WIDTH * i + BANK_WIDTH - 1 downto (BANK_WIDTH * i)) &
                               row_addr(ROW_WIDTH * i + ROW_WIDTH - 1 downto (ROW_WIDTH * i)) & 
                               req_ras(i) & req_cas(i) & row_cmd_wr(i));
         end if;
      end loop;
      row_cmd_ns <= row_cmd_ns_tmp;
   end process;
   
   xhdl12 : if (not( (nCK_PER_CLK = 2 and (not(ADDR_CMD_MODE = "2T")) ) )) generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            row_cmd_r <= row_cmd_ns after (TCQ)*1 ps;
         end if;
      end process;
   end generate;
   
   col_cmd_ns_x1 <= (others => '0') when (rst = '1') else
                     col_cmd_r((OUT_CMD_WIDTH - 1) downto OUT_CMD_WIDTH - RANK_WIDTH );

   col_cmd_ns_x2 <= (others => '0') when (rst = '1' and (not (ECC = "OFF"))) else
                    col_cmd_r(OUT_CMD_WIDTH-3-RANK_WIDTH + 3- 1 downto 3);
                    
   col_cmd_ns_x3 <= (others => '0') when (rst = '1') else 
                    col_cmd_r(2 downto 0);

   col_cmd_ns_x4 <=  '0' when (rst = '1') else
                      col_size_r;

   process (col_addr, col_cmd_r, col_data_buf_addr_r, col_periodic_rd_r,
            col_rmw_r, col_row_r, col_size_r, grant_col_r, rd_wr_r,
            req_bank_r, req_data_buf_addr_r, req_periodic_rd_r, req_rank_r,
            req_row_r, req_size_r, req_wr_r, rst, col_cmd_ns_x1,
            col_cmd_ns_x2, col_cmd_ns_x3, col_cmd_ns_x4)
   variable col_size_tmp : std_logic;
   begin
      col_periodic_rd_ns <= not(rst) and col_periodic_rd_r;
      col_cmd_ns <= (col_cmd_ns_x1) & (col_cmd_ns_x2)  & (col_cmd_ns_x3);
      col_rmw_ns <= col_rmw_r;
      col_size_tmp := col_cmd_ns_x4;
      col_row_ns <= col_row_r;
      col_data_buf_addr_ns <= col_data_buf_addr_r;
      for i in 0 to  nBANK_MACHS - 1 loop
         if ((grant_col_r(i)) = '1') then
            col_periodic_rd_ns <= req_periodic_rd_r(i);
            col_cmd_ns <= (req_rank_r(RANK_WIDTH * i + RANK_WIDTH - 1 downto RANK_WIDTH * i) &
                           req_bank_r(BANK_WIDTH * i + BANK_WIDTH - 1 downto BANK_WIDTH * i) &
                           col_addr(ROW_WIDTH * i + ROW_WIDTH - 1 downto ROW_WIDTH * i) &
                           '1' & '0' & rd_wr_r(i));
            col_rmw_ns <= req_wr_r(i) and rd_wr_r(i);
            col_size_tmp := req_size_r(i);
            col_row_ns <= req_row_r(ROW_WIDTH * i + ROW_WIDTH - 1 downto (ROW_WIDTH * i));
            col_data_buf_addr_ns <= req_data_buf_addr_r( DATA_BUF_ADDR_WIDTH * i + DATA_BUF_ADDR_WIDTH - 1 downto
                                                         (DATA_BUF_ADDR_WIDTH * i));
         end if;
      end loop;
      col_size_ns <= col_size_tmp;
   end process;
   
   early_wr_data_addr_off : if (EARLY_WR_DATA_ADDR = "OFF") generate
      col_wr_data_buf_addr <= col_data_buf_addr_ns;
   end generate;
   
   early_wr_data_addr_on : if (not(EARLY_WR_DATA_ADDR = "OFF")) generate
      process (col_wr_data_buf_addr_r, grant_col_wr, req_data_buf_addr_r)
      variable col_wr_data_buf_addr_tmp : std_logic_vector(DATA_BUF_ADDR_WIDTH -1 downto 0);
      begin
         col_wr_data_buf_addr_tmp := col_wr_data_buf_addr_r;
         for i in 0 to  nBANK_MACHS - 1 loop
            if ((grant_col_wr(i)) = '1') then
               col_wr_data_buf_addr_tmp := req_data_buf_addr_r(DATA_BUF_ADDR_WIDTH * i + DATA_BUF_ADDR_WIDTH - 1
                                                               downto DATA_BUF_ADDR_WIDTH * i);
            end if;
         end loop;
         col_wr_data_buf_addr_ns <= col_wr_data_buf_addr_tmp;
      end process;
      process (clk)
      begin
         if (clk'event and clk = '1') then
            col_wr_data_buf_addr_r <= col_wr_data_buf_addr_ns after (TCQ)*1 ps;
         end if;
      end process;
      col_wr_data_buf_addr <= col_wr_data_buf_addr_ns;
   end generate;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         col_periodic_rd_r <= col_periodic_rd_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         col_rmw_r <= col_rmw_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         col_size_r <= col_size_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         col_data_buf_addr_r <= col_data_buf_addr_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   xhdl19 : if (not (ECC = "OFF")) generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            col_cmd_r <= col_cmd_ns after (TCQ)*1 ps;
         end if;
      end process;
      process (clk)
      begin
         if (clk'event and clk = '1') then
            col_row_r <= col_row_ns after (TCQ)*1 ps;
         end if;
      end process;
   end generate;

   col_periodic_rd <= col_periodic_rd_ns;
   
   col_ra <=  col_cmd_ns(3 + ROW_WIDTH + BANK_WIDTH + RANK_WIDTH - 1 downto 3 + ROW_WIDTH + BANK_WIDTH);
   
   col_ba <=  col_cmd_ns(3 + ROW_WIDTH + BANK_WIDTH - 1 downto 3 + ROW_WIDTH);
   
   col_a <=   col_cmd_ns(ROW_WIDTH + 3 - 1 downto 3);
   
   col_rmw <= col_rmw_ns;
   
   col_size <= col_size_ns;
   
   col_row <= col_row_ns;
   
   col_data_buf_addr <= col_data_buf_addr_ns;
   
   process (col_cmd_ns, row_cmd_ns, send_cmd0_col)
   begin
      cmd0 <= row_cmd_ns;
      if (send_cmd0_col = '1') then
         cmd0 <= col_cmd_ns;
      end if;
   end process;
   
   xhdl20 : if (nCK_PER_CLK = 2) generate
      process (col_cmd_ns, row_cmd_ns, send_cmd1_row)
      begin
         cmd1 <= col_cmd_ns;
         if (send_cmd1_row = '1') then
            cmd1 <= row_cmd_ns;
         end if;
      end process;
   end generate;
   
   
   
   cs_one_hot(nCS_PER_RANK -1 downto 0)  <= ONE;

   cs_one_hot_MSBs : if ( CS_WIDTH > 1 ) generate
      cs_one_hot( CS_WIDTH * nCS_PER_RANK - 1 downto nCS_PER_RANK) <= (others => '0');
   end generate;

   process(cs_en0)
   begin
     for i in 0 to CS_WIDTH * nCS_PER_RANK - 1  loop
       cs_en0_tmp(i) <= not(cs_en0);
     end loop;
   end process;
      
   process(cs_en1)
   begin
     for i in 0 to CS_WIDTH * nCS_PER_RANK - 1  loop
       cs_en1_tmp(i) <= not(cs_en1);
     end loop;
   end process;
  
   dfi_cs_n0_one_hot_lshift <= not ( to_stdlogicvector( to_bitvector(cs_one_hot) sll (conv_integer(ra0) * nCS_PER_RANK) ) );
   dfi_cs_n1_one_hot_lshift <= not ( to_stdlogicvector( to_bitvector(cs_one_hot) sll (conv_integer(ra1) * nCS_PER_RANK) ) );
   dfi_cs_n0 <= dfi_cs_n0_one_hot_lshift or cs_en0_tmp ;
   dfi_cs_n1 <= dfi_cs_n1_one_hot_lshift or cs_en1_tmp ;
   
   process (force_io_config_rd_r1, grant_config_r,
            io_config_r, io_config_strobe, rd_wr_r,
            req_rank_r, rst)
   begin
      if (rst = '1') then
         io_config_ns <= (others => '0');
      else
         io_config_ns <= io_config_r;
         if (io_config_strobe = '1') then
            if (force_io_config_rd_r1 = '1') then
               io_config_ns <= ('0' & io_config_r(RANK_WIDTH - 1 downto 0));
            else
               for i in 0 to  nBANK_MACHS - 1 loop
                  if ((grant_config_r(i)) = '1') then
                     io_config_ns <= (not(rd_wr_r(i)) & 
                                      req_rank_r(RANK_WIDTH * i + RANK_WIDTH - 1 downto RANK_WIDTH * i));
                  end if;
               end loop;
            end if;
         end if;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         io_config_r <= io_config_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   io_config <= io_config_ns;
   io_config_one_hot <= to_stdlogicvector(to_bitvector(cs_one_hot(CS_WIDTH-1 downto 0)) sll conv_integer(io_config_ns(RANK_WIDTH - 1 downto 0)));

   slot_0_present_concat <= (slot_0_present(2) & slot_0_present(0));
   io_config_one_hot_temp <= and2bits(io_config_one_hot,slot_0_present_concat,CS_WIDTH);

   slot_0_select <= REDUCTION_OR((io_config_one_hot and slot_0_present(CS_WIDTH-1 downto 0))) when ( nSLOTS = 1) else
                    REDUCTION_OR(io_config_one_hot_temp) when ( ( slot_0_present(2) and slot_0_present(0) ) = '1') else
                    io_config_one_hot(0) when (slot_0_present(0) = '1') else '0';
   
   slot_0_read <= slot_0_select and not(io_config_ns(RANK_WIDTH));
   
   slot_0_write <= slot_0_select and io_config_ns(RANK_WIDTH);
   
   process (slot_0_present)
   begin
      slot_0_population <= SEL_SAT_ADD("00",slot_0_present);
   end process;
   
   slot_0_dynamic_odt <= not(slot_0_population(1));
   odt_0_nom <= '0' when (RTT_NOM = "DISABLED") else ((slot_0_write and REDUCTION_NOR(slot_1_population)) or not(slot_0_select))
                when (not (DRAM_TYPE = "DDR3")) else
                slot_0_write; --Changed to fix ODT issue in case of DR single slot.
                --not(slot_0_select) when (slot_0_dynamic_odt /= '1') else
                --not(slot_0_read);
   odt_0_wr <= slot_0_write when ((not(RTT_WR = "OFF")) and (nSLOTS > 1) and (DRAM_TYPE = "DDR3")) else
               '0';--Changed to fix ODT issue in case of DR single slot.
  
   process(odt_0_wr)
   begin
     for i in 0 to nCS_PER_RANK - 1  loop
       nCS_PER_RANK_odt_0_wr(i) <= odt_0_wr;
     end loop;
   end process;

   process(odt_0_nom)
   begin
     for i in 0 to nCS_PER_RANK - 1  loop
       nCS_PER_RANK_odt_0_nom(i) <= odt_0_nom;
     end loop;
   end process;
   
   xhdl21 : if (nSLOTS > 1) generate
      slot_1_select <= REDUCTION_OR( io_config_one_hot((conv_integer(slot_0_population)) + 1) &
                                     io_config_one_hot((conv_integer(slot_0_population))) ) 
                       when ((slot_1_present(3) and slot_1_present(1)) = '1') else
                       io_config_one_hot((conv_integer(slot_0_population)))
                       when (slot_1_present(1) = '1') else '0';
      slot_1_read <= slot_1_select and not(io_config_ns(RANK_WIDTH));
      slot_1_write <= slot_1_select and io_config_ns(RANK_WIDTH);
      process (slot_1_present)
      begin
         slot_1_population <= SEL_SAT_ADD("00",slot_1_present);
      end process;
      slot_1_dynamic_odt <= not(slot_1_population(1));
      odt_1_nom <= '0' when (RTT_NOM = "DISABLED") else
                   ((slot_1_write and REDUCTION_NOR(slot_0_population)) or not(slot_1_select))
                   when (not(DRAM_TYPE = "DDR3")) else
                   not(slot_1_select) when (slot_1_dynamic_odt /= '1') else
                   not(slot_1_read);
      odt_1_wr <= slot_1_write when ((not(RTT_WR = "OFF")) and (DRAM_TYPE = "DDR3")) else
                  '0';
      process(odt_1_nom)
      begin
        for i in 0 to nCS_PER_RANK - 1  loop
          nCS_PER_RANK_odt_1_nom(i) <= odt_1_nom;
        end loop;
      end process;
      process(odt_1_wr)
      begin
        for i in 0 to nCS_PER_RANK - 1  loop
          nCS_PER_RANK_odt_1_wr(i) <= odt_1_wr;
        end loop;
      end process;
      odt_nom <= nCS_PER_RANK_odt_1_nom & nCS_PER_RANK_odt_0_nom;
      odt_wr <= nCS_PER_RANK_odt_1_wr & nCS_PER_RANK_odt_0_wr;
   end generate;

   xhdl22 : if (not(nSLOTS > 1)) generate
      odt_nom <= nCS_PER_RANK_odt_0_nom;
      odt_wr <= nCS_PER_RANK_odt_0_wr;
   end generate;

   dfi_odt_nom0 <= odt_nom;
   
   dfi_odt_wr0 <= odt_wr;
   
   dfi_odt_nom1 <= odt_nom;
   
   dfi_odt_wr1 <= odt_wr;
   
end architecture trans;

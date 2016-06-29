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
--  /   /         Filename              : bank_compare.vhd
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

-- This block stores the request for this bank machine.
--
-- All possible new requests are compared against the request stored
-- here.  The compare results are shared with the bank machines and
-- is used to determine where to enqueue a new request.
entity bank_compare is
   generic (
            BANK_WIDTH               : integer := 3;
            TCQ                      : integer := 100;
            BURST_MODE               : string := "8";
            COL_WIDTH                : integer := 12;
            DATA_BUF_ADDR_WIDTH      : integer := 8;
            ECC                      : string := "OFF";
            RANK_WIDTH               : integer := 2;
            RANKS                    : integer := 4;
            ROW_WIDTH                : integer := 16
           );
   port (
         req_data_buf_addr_r      : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         req_periodic_rd_r        : out std_logic;
         req_size_r               : out std_logic;
         rd_wr_r                  : out std_logic;
         req_rank_r               : out std_logic_vector(RANK_WIDTH - 1 downto 0);
         req_bank_r               : out std_logic_vector(BANK_WIDTH - 1 downto 0);
         req_row_r                : out std_logic_vector(ROW_WIDTH - 1 downto 0);
         req_wr_r                 : out std_logic;
         req_priority_r           : out std_logic;
         rb_hit_busy_r            : out std_logic;         -- rank-bank hit on non idle row machine
         rb_hit_busy_ns           : out std_logic;
         row_hit_r                : out std_logic;
         maint_hit                : out std_logic;
         col_addr                 : out std_logic_vector(ROW_WIDTH - 1 downto 0);
         req_ras                  : out std_logic;
         req_cas                  : out std_logic;
         row_cmd_wr               : out std_logic;
         row_addr                 : out std_logic_vector(ROW_WIDTH - 1 downto 0);
         rank_busy_r              : out std_logic_vector(RANKS - 1 downto 0);
         clk                      : in std_logic;
         idle_ns                  : in std_logic;
         idle_r                   : in std_logic;
         data_buf_addr            : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         periodic_rd_insert       : in std_logic;
         size                     : in std_logic;
         cmd                      : in std_logic_vector(2 downto 0);
         sending_col              : in std_logic;
         rank                     : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         periodic_rd_rank_r       : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         bank                     : in std_logic_vector(BANK_WIDTH - 1 downto 0);
         row                      : in std_logic_vector(ROW_WIDTH - 1 downto 0);
         col                      : in std_logic_vector(COL_WIDTH - 1 downto 0);
         hi_priority              : in std_logic;
         maint_rank_r             : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         maint_zq_r               : in std_logic;
         auto_pre_r               : in std_logic;
         rd_half_rmw              : in std_logic;
         act_wait_r               : in std_logic
        );
end entity bank_compare;

architecture trans of bank_compare is

   function BOOLEAN_TO_STD_LOGIC(A : in BOOLEAN) return std_logic is
   begin
      if A = true then
          return '1';
      else
          return '0';
      end if;
   end function BOOLEAN_TO_STD_LOGIC;

   signal req_data_buf_addr_ns       : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal req_periodic_rd_r_lcl      : std_logic;
   signal req_periodic_rd_ns         : std_logic;
   signal req_size_r_lcl             : std_logic;
   signal req_cmd_r                  : std_logic_vector(2 downto 0);
   signal req_cmd_ns                 : std_logic_vector(2 downto 0);
   signal rd_wr_r_lcl                : std_logic;
   signal rd_wr_ns                   : std_logic;
   signal req_rank_r_lcl             : std_logic_vector(RANK_WIDTH - 1 downto 0) := (others => '0');
   signal req_rank_ns                : std_logic_vector(RANK_WIDTH - 1 downto 0) := (others => '0');
   signal req_bank_r_lcl             : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal req_bank_ns                : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal req_row_r_lcl              : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal req_row_ns                 : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal req_col_r                  : std_logic_vector(15 downto 0) := (others => '0');
   signal req_col_ns                 : std_logic_vector(COL_WIDTH - 1 downto 0);
   signal req_wr_r_lcl               : std_logic;
   signal req_wr_ns                  : std_logic;
   signal req_priority_ns            : std_logic;
   signal rank_hit                   : std_logic;
   signal bank_hit                   : std_logic;
   signal rank_bank_hit              : std_logic;
   signal rb_hit_busy_ns_lcl         : std_logic;
   signal row_hit_ns                 : std_logic;
   signal col_addr_template          : std_logic_vector(15 downto 0) := (others => '0');
   signal rank_busy_ns               : std_logic_vector(RANKS - 1 downto 0);
   signal req_size_ns                : std_logic;
   signal req_size                   : std_logic;
   signal ranks_idle                 : std_logic_vector(RANKS-1 downto 0);
   
   -- X-HDL generated signals
   signal xhdl8                      : std_logic_vector(RANK_WIDTH-1 downto 0);
   signal xhdl9                      : std_logic_vector(RANK_WIDTH-1 downto 0);
   
   -- Declare intermediate signals for referenced outputs
   signal req_data_buf_addr_r_xhdl0  : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal req_priority_r_xhdl1       : std_logic;
   signal rank_busy_ns_tmp           : bit_vector(RANKS - 1 downto 0);
   signal ONE_RANKS_v                : std_logic_vector(RANKS - 1 downto 0);
   
   constant ONE                      : integer := 1;
   
begin

   ONE_RANKS_v          <= conv_std_logic_vector(1,RANKS ) ;--sll conv_integer(req_rank_ns);

   -- Drive referenced outputs
   req_data_buf_addr_r  <= req_data_buf_addr_r_xhdl0;
   req_priority_r       <= req_priority_r_xhdl1;
   req_data_buf_addr_ns <= data_buf_addr when (idle_r = '1') else
                           req_data_buf_addr_r_xhdl0;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_data_buf_addr_r_xhdl0 <= req_data_buf_addr_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   req_periodic_rd_ns <= periodic_rd_insert when (idle_ns = '1') else
                         req_periodic_rd_r_lcl;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_periodic_rd_r_lcl <= req_periodic_rd_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   req_periodic_rd_r <= req_periodic_rd_r_lcl;
   
   xhdl2 : if (BURST_MODE = "4") generate
      req_size_r_lcl <= '0';
   end generate;
 
   xhdl3 : if (not(BURST_MODE = "4")) generate

      xhdl4 : if (BURST_MODE = "8") generate
         req_size_r_lcl <= '1';
      end generate;
      
      xhdl5 : if (not(BURST_MODE = "8")) generate
         xhdl6 : if (BURST_MODE = "OTF") generate
            req_size_ns <= (periodic_rd_insert or size) when (idle_ns = '1') else
                           req_size;
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  req_size <= req_size_ns after (TCQ)*1 ps;
               end if;
            end process;
            req_size_r_lcl <= req_size;
         end generate;
      end generate;
   end generate;

   req_size_r <= req_size_r_lcl;
   req_cmd_ns <= req_cmd_r when (idle_ns /= '1') else
                 cmd when (periodic_rd_insert /= '1') else
                 "001";
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_cmd_r <= req_cmd_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   rd_wr_ns <= (BOOLEAN_TO_STD_LOGIC(req_cmd_ns(1 downto 0) = "11") or req_cmd_ns(0)) when (idle_ns = '1') else
               not(sending_col) and rd_wr_r_lcl;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rd_wr_r_lcl <= rd_wr_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   rd_wr_r <= rd_wr_r_lcl;
   
   xhdl7 : if (RANKS /= 1) generate
      xhdl8 <= periodic_rd_rank_r when (periodic_rd_insert = '1') else
                 rank;
      xhdl9 <= xhdl8 when (idle_ns = '1') else
                 req_rank_r_lcl;
      process (idle_ns, periodic_rd_insert, periodic_rd_rank_r, rank, req_rank_r_lcl,xhdl9)
      begin
         req_rank_ns <= xhdl9;
      end process;
      process (clk)
      begin
         if (clk'event and clk = '1') then
            req_rank_r_lcl <= req_rank_ns after (TCQ)*1 ps;
         end if;
      end process;
   end generate;
   
   req_rank_r <= req_rank_r_lcl;
   req_bank_ns <= bank when (idle_ns = '1') else
                  req_bank_r_lcl;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_bank_r_lcl <= req_bank_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   req_bank_r <= req_bank_r_lcl;
   
   req_row_ns <= row when (idle_ns = '1') else
                 req_row_r_lcl;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_row_r_lcl <= req_row_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   -- Make req_col_r as wide as the max row address.  This
   -- makes it easier to deal with indexing different column widths.
   req_row_r <= req_row_r_lcl;
   
   req_col_ns <= col when (idle_ns = '1') else
                 req_col_r(COL_WIDTH - 1 downto 0);
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_col_r(COL_WIDTH - 1 downto 0) <= req_col_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   req_wr_ns <= (BOOLEAN_TO_STD_LOGIC(req_cmd_ns(1 downto 0) = "11") or not(req_cmd_ns(0))) when (idle_ns = '1') else
                req_wr_r_lcl;
 
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_wr_r_lcl <= req_wr_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   req_wr_r <= req_wr_r_lcl;
   
   req_priority_ns <= hi_priority when (idle_ns = '1') else
                      req_priority_r_xhdl1;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         req_priority_r_xhdl1 <= req_priority_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   rank_hit <= BOOLEAN_TO_STD_LOGIC(req_rank_r_lcl = periodic_rd_rank_r) when (periodic_rd_insert = '1') else
               BOOLEAN_TO_STD_LOGIC(req_rank_r_lcl = rank) ;
   
   bank_hit <= BOOLEAN_TO_STD_LOGIC(req_bank_r_lcl = bank);
   
   rank_bank_hit <= rank_hit and bank_hit;
   
   rb_hit_busy_ns_lcl <= rank_bank_hit and not(idle_ns);
   
   rb_hit_busy_ns <= rb_hit_busy_ns_lcl;
   
   row_hit_ns <= BOOLEAN_TO_STD_LOGIC(req_row_r_lcl = row);
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rb_hit_busy_r <= rb_hit_busy_ns_lcl after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         row_hit_r <= row_hit_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   maint_hit <= BOOLEAN_TO_STD_LOGIC(req_rank_r_lcl = maint_rank_r) or maint_zq_r;

   -- Assemble column address.  Structure to be the same
   -- width as the row address.  This makes it easier
   -- for the downstream muxing.  Depending on the sizes
   -- of the row and column addresses, fill in as appropriate.
   process (auto_pre_r, rd_half_rmw, req_col_r, req_size_r_lcl)
   begin
      col_addr_template <= req_col_r;
      col_addr_template(10) <= auto_pre_r and ( not(rd_half_rmw) );
      col_addr_template(11) <= req_col_r(10);
      col_addr_template(12) <= req_size_r_lcl;
      col_addr_template(13) <= req_col_r(11);
   end process;
   
   col_addr <= col_addr_template(ROW_WIDTH - 1 downto 0);
   req_ras <= '0';
   req_cas <= '1';
   row_cmd_wr <= act_wait_r;
   
   process (act_wait_r, req_row_r_lcl)
   begin
      row_addr <= req_row_r_lcl;
  -- This causes all precharges to be precharge single bank command.
      if ((not(act_wait_r)) = '1') then
         row_addr(10) <= '0';
      end if;
   end process;
   
   process(idle_ns)
   begin
   for i in 0 to RANKS - 1  loop
     ranks_idle(i) <= not(idle_ns);
   end loop;
   
   end process;
   
   -- Indicate which, if any, rank this bank machine is busy with.
   -- Not registering the result would probably be more accurate, but
   -- would create timing issues.  This is used for refresh banking, perfect
   -- accuracy is not required.
   rank_busy_ns_tmp  <= to_bitvector(ONE_RANKS_v) sll conv_integer(req_rank_ns);
   rank_busy_ns <=   ranks_idle and to_stdlogicvector(to_bitvector(ONE_RANKS_v) sll conv_integer(req_rank_ns));
   process (clk)
   begin
      if (clk'event and clk = '1') then
         rank_busy_r <=  rank_busy_ns after (TCQ)*1 ps;                -- bank_compare
      end if;
   end process;
   
   --The following logic was added to maintian consistency with the verilog code. In the verilog code
   --the signal rank_busy_ns was taken as single bit which should not be the case. This is fixed in
   --verilog hence reverting back to the normal scenario
   --Temporary : if ( RANKS > 1 ) generate
   -- process (clk)
   -- begin
   --     if (clk'event and clk = '1') then
   --      rank_busy_r (RANKS - 1 downto 1) <= (others => '0');
   --   end if;
   -- end process;
   --end generate;
   
end architecture trans;

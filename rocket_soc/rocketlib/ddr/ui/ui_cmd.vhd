--LIBRARY xtek;
--   USE xtek.XHDL_std_logic.all;
LIBRARY ieee;
   USE ieee.std_logic_1164.all;
   USE ieee.std_logic_unsigned.all;
   USE ieee.numeric_std.all;

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
--  /   /         Filename              : ui_cmd.v
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

-- User interface command port.

ENTITY ui_cmd IS
   GENERIC (
      TCQ                   : INTEGER := 100;
      ADDR_WIDTH            : INTEGER := 33;
      BANK_WIDTH            : INTEGER := 3;
      COL_WIDTH             : INTEGER := 12;
      RANK_WIDTH            : INTEGER := 2;
      ROW_WIDTH             : INTEGER := 16;
      RANKS                 : INTEGER := 4;
      MEM_ADDR_ORDER        : STRING  := "BANK_ROW_COLUMN"
   );
   PORT (
      -- Outputs
      -- Inputs
      
      app_rdy               : OUT STD_LOGIC;
      
      -- always @ (posedge clk)
      
      use_addr              : OUT STD_LOGIC;
      
      rank                  : OUT STD_LOGIC_VECTOR(RANK_WIDTH - 1 DOWNTO 0);
      bank                  : OUT STD_LOGIC_VECTOR(BANK_WIDTH - 1 DOWNTO 0);
      row                   : OUT STD_LOGIC_VECTOR(ROW_WIDTH - 1 DOWNTO 0);
      col                   : OUT STD_LOGIC_VECTOR(COL_WIDTH - 1 DOWNTO 0);
      size                  : OUT STD_LOGIC;
      cmd                   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      hi_priority           : OUT STD_LOGIC;
      
      rd_accepted           : OUT STD_LOGIC;
      wr_accepted           : OUT STD_LOGIC;
      
      data_buf_addr         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      rst                   : IN STD_LOGIC;
      clk                   : IN STD_LOGIC;
      accept_ns             : IN STD_LOGIC;
      rd_buf_full           : IN STD_LOGIC;
      wr_req_16             : IN STD_LOGIC;
      app_addr              : IN STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
      app_cmd               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      app_sz                : IN STD_LOGIC;
      app_hi_pri            : IN STD_LOGIC;
      app_en                : IN STD_LOGIC;
      wr_data_buf_addr      : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      rd_data_buf_addr_r    : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
   );
END ENTITY ui_cmd;

ARCHITECTURE trans OF ui_cmd IS
   SIGNAL app_rdy_ns                 : STD_LOGIC;
   SIGNAL app_rdy_r                  : STD_LOGIC := '0';
   SIGNAL app_rdy_inv_r              : STD_LOGIC;
   SIGNAL app_addr_r1                : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (others => '0' );
   SIGNAL app_addr_r2                : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0) := (others => '0' );
   SIGNAL app_cmd_r1                 : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL app_cmd_r2                 : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL app_sz_r1                  : STD_LOGIC;
   SIGNAL app_sz_r2                  : STD_LOGIC;
   SIGNAL app_hi_pri_r1              : STD_LOGIC;
   SIGNAL app_hi_pri_r2              : STD_LOGIC;
   SIGNAL app_en_r1                  : STD_LOGIC;
   SIGNAL app_en_r2                  : STD_LOGIC;
   SIGNAL app_addr_ns1               : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
   SIGNAL app_rdy_r_concat           : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
   SIGNAL app_rdy_inv_r_concat       : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
   SIGNAL app_addr_ns2               : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
   SIGNAL app_en_concat              : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
   SIGNAL app_cmd_ns1                : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL app_cmd_ns2                : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL app_sz_ns1                 : STD_LOGIC;
   SIGNAL app_sz_ns2                 : STD_LOGIC;
   SIGNAL app_hi_pri_ns1             : STD_LOGIC;
   SIGNAL app_hi_pri_ns2             : STD_LOGIC;
   SIGNAL app_en_ns1                 : STD_LOGIC;
   SIGNAL app_en_ns2                 : STD_LOGIC;
   SIGNAL use_addr_lcl               : STD_LOGIC;
   SIGNAL request_accepted           : STD_LOGIC;
   SIGNAL rd                         : STD_LOGIC;
   SIGNAL wr                         : STD_LOGIC;
   SIGNAL wr_bytes                   : STD_LOGIC;
   SIGNAL write                      : STD_LOGIC;
   SIGNAL xhdl12                     : STD_LOGIC_VECTOR(RANK_WIDTH - 1 DOWNTO 0);

BEGIN
   app_rdy_ns <= accept_ns AND NOT(rd_buf_full) AND NOT(wr_req_16);
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         app_rdy_r <= app_rdy_ns AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;

   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         app_rdy_inv_r <= NOT(app_rdy_ns) AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;

   app_rdy_inv_r_concat <= (others => app_rdy_inv_r);
   app_rdy_r_concat <= (others => app_rdy_r);
   app_en_concat <= (others => app_en);
   
   app_rdy <= app_rdy_r;
   app_addr_ns1 <= (app_addr AND app_rdy_r_concat AND app_en_concat) OR
                   (app_addr_r1 AND app_rdy_inv_r_concat);
   app_addr_ns2 <= (app_addr_r1 AND app_rdy_r_concat) OR
                   (app_addr_r2 AND app_rdy_inv_r_concat);
   app_cmd_ns1 <= (app_cmd AND app_rdy_r_concat(2 DOWNTO 0)) OR
                  (app_cmd_r1 AND app_rdy_inv_r_concat(2 DOWNTO 0));
   app_cmd_ns2 <= (app_cmd_r1 AND app_rdy_r_concat(2 DOWNTO 0)) OR
                  (app_cmd_r2 AND app_rdy_inv_r_concat(2 DOWNTO 0));
   app_sz_ns1 <= (app_sz AND app_rdy_r ) OR
                 (app_sz_r1 AND app_rdy_inv_r);
   app_sz_ns2 <= (app_sz_r1 AND app_rdy_r ) OR
                 (app_sz_r2 AND app_rdy_inv_r);
   app_hi_pri_ns1 <= (app_hi_pri AND app_rdy_r ) OR
                     (app_hi_pri_r1 AND app_rdy_inv_r);
   app_hi_pri_ns2 <= (app_hi_pri_r1 AND app_rdy_r ) OR
                     (app_hi_pri_r2 AND app_rdy_inv_r);
   app_en_ns1 <= NOT(rst) AND ((app_en AND app_rdy_r ) OR
                               (app_en_r1 AND app_rdy_inv_r));
   app_en_ns2 <= NOT(rst) AND ((app_en_r1 AND app_rdy_r ) OR
                               (app_en_r2 AND app_rdy_inv_r));
   PROCESS (clk)
   BEGIN
      IF (clk'EVENT AND clk = '1') THEN
         app_addr_r1 <= app_addr_ns1 AFTER (TCQ)*1 ps;
         app_addr_r2 <= app_addr_ns2 AFTER (TCQ)*1 ps;
         app_cmd_r1 <= app_cmd_ns1 AFTER (TCQ)*1 ps;
         app_cmd_r2 <= app_cmd_ns2 AFTER (TCQ)*1 ps;
         app_sz_r1 <= app_sz_ns1 AFTER (TCQ)*1 ps;
         app_sz_r2 <= app_sz_ns2 AFTER (TCQ)*1 ps;
         app_hi_pri_r1 <= app_hi_pri_ns1 AFTER (TCQ)*1 ps;
         app_hi_pri_r2 <= app_hi_pri_ns2 AFTER (TCQ)*1 ps;
         app_en_r1 <= app_en_ns1 AFTER (TCQ)*1 ps;
         app_en_r2 <= app_en_ns2 AFTER (TCQ)*1 ps;
      END IF;
   END PROCESS;
   
   use_addr_lcl <= app_en_r2 AND app_rdy_r;
   use_addr <= use_addr_lcl;
   col <= (app_addr_r1(COL_WIDTH - 1 DOWNTO 0) AND app_rdy_r_concat(COL_WIDTH -1 DOWNTO 0)) OR
          (app_addr_r2(COL_WIDTH - 1 DOWNTO 0) AND app_rdy_inv_r_concat(COL_WIDTH -1 DOWNTO 0));

   gen_row_bank_column : if (MEM_ADDR_ORDER = "ROW_BANK_COLUMN") generate
     row <= (app_addr_r1(COL_WIDTH+BANK_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH+BANK_WIDTH) AND app_rdy_r_concat(COL_WIDTH+BANK_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH+BANK_WIDTH)) OR
            (app_addr_r2(COL_WIDTH+BANK_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH+BANK_WIDTH) AND app_rdy_inv_r_concat(COL_WIDTH+BANK_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH+BANK_WIDTH));
     bank <= (app_addr_r1(COL_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH) AND
              app_rdy_r_concat(COL_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH)) OR
             (app_addr_r2(COL_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH) AND
              app_rdy_inv_r_concat(COL_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH));
   end generate gen_row_bank_column;

   gen_bank_row_column : if (MEM_ADDR_ORDER /= "ROW_BANK_COLUMN") generate
     row <= (app_addr_r1(COL_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH) AND app_rdy_r_concat(COL_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH)) OR
            (app_addr_r2(COL_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH) AND app_rdy_inv_r_concat(COL_WIDTH+ROW_WIDTH-1 DOWNTO COL_WIDTH));
     bank <= (app_addr_r1(COL_WIDTH + ROW_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH) AND
              app_rdy_r_concat(COL_WIDTH + ROW_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH)) OR
             (app_addr_r2(COL_WIDTH + ROW_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH) AND
              app_rdy_inv_r_concat(COL_WIDTH + ROW_WIDTH + BANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH));
   end generate gen_bank_row_column;
   
   rank <= (others => '0') WHEN (RANKS = 1) ELSE xhdl12;
   xhdl12 <= (app_addr_r1(COL_WIDTH + ROW_WIDTH + BANK_WIDTH + RANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH + BANK_WIDTH) AND
              app_rdy_r_concat(COL_WIDTH + ROW_WIDTH + BANK_WIDTH + RANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH + BANK_WIDTH)) OR
	         (app_addr_r2(COL_WIDTH + ROW_WIDTH + BANK_WIDTH + RANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH + BANK_WIDTH) AND
              app_rdy_inv_r_concat(COL_WIDTH + ROW_WIDTH + BANK_WIDTH + RANK_WIDTH - 1 DOWNTO COL_WIDTH + ROW_WIDTH + BANK_WIDTH));
   size <= (app_sz_r1 AND app_rdy_r) OR
           (app_sz_r2 AND app_rdy_inv_r);
   cmd <= (app_cmd_r1 AND app_rdy_r_concat(2 DOWNTO 0)) OR
          (app_cmd_r2 AND app_rdy_inv_r_concat (2 DOWNTO 0));
   hi_priority <= (app_hi_pri_r1 AND app_rdy_r ) OR
                  (app_hi_pri_r2 AND app_rdy_inv_r );
   request_accepted <= use_addr_lcl AND app_rdy_r;
   rd <= '1' when (app_cmd_r2(1 DOWNTO 0) = "01") else '0';
   wr <= '1' when (app_cmd_r2(1 DOWNTO 0) = "00") else '0';
   wr_bytes <= '1' when (app_cmd_r2(1 DOWNTO 0) = "11") else '0';
   write <= wr OR wr_bytes;
   rd_accepted <= request_accepted AND rd;
   wr_accepted <= request_accepted AND write;
   
   data_buf_addr <= rd_data_buf_addr_r WHEN ((NOT(write)) = '1') ELSE
                    wr_data_buf_addr;
   
END ARCHITECTURE trans;


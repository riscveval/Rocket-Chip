--LIBRARY xtek;
--   USE xtek.XHDL_std_logic.all;
LIBRARY ieee;
   USE ieee.std_logic_1164.all;
   USE ieee.std_logic_unsigned.all;

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
--  /   /         Filename              : ui_top.v
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

-- Top level of simple user interface.

ENTITY ui_top IS
   GENERIC (
      TCQ                   : INTEGER := 100;
      APP_DATA_WIDTH        : INTEGER := 256;
      APP_MASK_WIDTH        : INTEGER := 32;
      BANK_WIDTH            : INTEGER := 3;
      COL_WIDTH             : INTEGER := 12;
      CWL                   : INTEGER := 5;
      ECC                   : STRING  := "OFF";
      ECC_TEST              : STRING  := "OFF";
      ORDERING              : STRING  := "NORM";
      RANKS                 : INTEGER := 4;
      RANK_WIDTH            : INTEGER := 2;
      ROW_WIDTH             : INTEGER := 16;
      MEM_ADDR_ORDER        : STRING  := "BANK_ROW_COLUMN"
   );
   PORT (
      -- Outputs
      -- Inputs
      
      -- Beginning of automatic inputs (from unused autoinst inputs)
      -- To ui_cmd0 of ui_cmd.v
      -- To ui_cmd0 of ui_cmd.v
      -- To ui_cmd0 of ui_cmd.v
      -- To ui_cmd0 of ui_cmd.v
      -- To ui_cmd0 of ui_cmd.v
      -- To ui_wr_data0 of ui_wr_data.v
      -- To ui_cmd0 of ui_cmd.v
      -- To ui_wr_data0 of ui_wr_data.v
      -- To ui_wr_data0 of ui_wr_data.v
      -- To ui_wr_data0 of ui_wr_data.v
      -- To ui_wr_data0 of ui_wr_data.v
      -- To ui_cmd0 of ui_cmd.v, ...
      -- To ui_rd_data0 of ui_rd_data.v
      -- To ui_rd_data0 of ui_rd_data.v
      -- To ui_rd_data0 of ui_rd_data.v
      -- To ui_rd_data0 of ui_rd_data.v
      -- To ui_rd_data0 of ui_rd_data.v
      -- To ui_rd_data0 of ui_rd_data.v
      -- To ui_cmd0 of ui_cmd.v, ...
      -- To ui_wr_data0 of ui_wr_data.v
      -- To ui_wr_data0 of ui_wr_data.v
      -- To ui_wr_data0 of ui_wr_data.v
      -- End of automatics
      
      -- Beginning of automatic outputs (from unused autoinst outputs)
      -- From ui_rd_data0 of ui_rd_data.v
      -- From ui_rd_data0 of ui_rd_data.v
      -- From ui_rd_data0 of ui_rd_data.v
      -- From ui_rd_data0 of ui_rd_data.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_wr_data0 of ui_wr_data.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_wr_data0 of ui_wr_data.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_cmd0 of ui_cmd.v
      -- From ui_wr_data0 of ui_wr_data.v
      wr_data_mask          : OUT STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);		-- From ui_wr_data0 of ui_wr_data.v
      wr_data               : OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
      use_addr              : OUT STD_LOGIC;
      size                  : OUT STD_LOGIC;
      row                   : OUT STD_LOGIC_VECTOR(ROW_WIDTH - 1 DOWNTO 0);
      raw_not_ecc           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      rank                  : OUT STD_LOGIC_VECTOR(RANK_WIDTH - 1 DOWNTO 0);
      hi_priority           : OUT STD_LOGIC;
      data_buf_addr         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      col                   : OUT STD_LOGIC_VECTOR(COL_WIDTH - 1 DOWNTO 0);
      cmd                   : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
      bank                  : OUT STD_LOGIC_VECTOR(BANK_WIDTH - 1 DOWNTO 0);
      app_wdf_rdy           : OUT STD_LOGIC;
      app_rdy               : OUT STD_LOGIC;
      app_rd_data_valid     : OUT STD_LOGIC;
      app_rd_data_end       : OUT STD_LOGIC;
      app_rd_data           : OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
      app_ecc_multiple_err  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
      correct_en            : OUT STD_LOGIC;
      wr_data_offset        : IN STD_LOGIC;
      wr_data_en            : IN STD_LOGIC;
      wr_data_addr          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      rst                   : IN STD_LOGIC;
      rd_data_offset        : IN STD_LOGIC;
      rd_data_end           : IN STD_LOGIC;
      rd_data_en            : IN STD_LOGIC;
      rd_data_addr          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      rd_data               : IN STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
      ecc_multiple          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      clk                   : IN STD_LOGIC;
      app_wdf_wren          : IN STD_LOGIC;
      app_wdf_mask          : IN STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
      app_wdf_end           : IN STD_LOGIC;
      app_wdf_data          : IN STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
      app_sz                : IN STD_LOGIC;
      app_raw_not_ecc       : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
      app_hi_pri            : IN STD_LOGIC;
      app_en                : IN STD_LOGIC;
      app_cmd               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
      app_addr              : IN STD_LOGIC_VECTOR(RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH - 1 DOWNTO 0);
      accept_ns             : IN STD_LOGIC;
      accept                : IN STD_LOGIC;
      app_correct_en        : IN STD_LOGIC
   );
END ENTITY ui_top;

ARCHITECTURE trans OF ui_top IS

   constant ADDR_WIDTH :integer := RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH;
   COMPONENT ui_cmd IS
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
         app_rdy               : OUT STD_LOGIC;
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
   END COMPONENT;
   
   COMPONENT ui_wr_data IS
      GENERIC (
         TCQ                   : INTEGER := 100;
         APP_DATA_WIDTH        : INTEGER := 256;
         APP_MASK_WIDTH        : INTEGER := 32;
         ECC                   : STRING := "OFF";
         ECC_TEST              : STRING := "OFF";
         CWL                   : INTEGER := 5
      );
      PORT (
         app_wdf_rdy           : OUT STD_LOGIC;
         wr_req_16             : OUT STD_LOGIC;
         wr_data_buf_addr      : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         wr_data               : OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
         wr_data_mask          : OUT STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
         raw_not_ecc           : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         rst                   : IN STD_LOGIC;
         clk                   : IN STD_LOGIC;
         app_wdf_data          : IN STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
         app_wdf_mask          : IN STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
         app_raw_not_ecc       : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         app_wdf_wren          : IN STD_LOGIC;
         app_wdf_end           : IN STD_LOGIC;
         wr_data_offset        : IN STD_LOGIC;
         wr_data_addr          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         wr_data_en            : IN STD_LOGIC;
         wr_accepted           : IN STD_LOGIC;
         ram_init_done_r       : IN STD_LOGIC;
         ram_init_addr         : IN STD_LOGIC_VECTOR(3 DOWNTO 0)
      );
   END COMPONENT;
   
   COMPONENT ui_rd_data IS
      GENERIC (
         TCQ                   : INTEGER := 100;
         APP_DATA_WIDTH        : INTEGER := 256;
         ECC                   : STRING := "OFF";
         ORDERING              : STRING := "NORM"
      );
      PORT (
         ram_init_done_r       : OUT STD_LOGIC;
         ram_init_addr         : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         app_rd_data_valid     : OUT STD_LOGIC;
         app_rd_data_end       : OUT STD_LOGIC;
         app_rd_data           : OUT STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
         app_ecc_multiple_err  : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         rd_buf_full           : OUT STD_LOGIC;
         rd_data_buf_addr_r    : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
         rst                   : IN STD_LOGIC;
         clk                   : IN STD_LOGIC;
         rd_data_en            : IN STD_LOGIC;
         rd_data_addr          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         rd_data_offset        : IN STD_LOGIC;
         rd_data_end           : IN STD_LOGIC;
         rd_data               : IN STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
         ecc_multiple          : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
         rd_accepted           : IN STD_LOGIC
      );
   END COMPONENT;
   
   -- End of automatics
   
   -- Beginning of automatic wires (for undeclared instantiated-module outputs)
   SIGNAL ram_init_addr              : STD_LOGIC_VECTOR(3 DOWNTO 0);		-- From ui_rd_data0 of ui_rd_data.v
   SIGNAL ram_init_done_r            : STD_LOGIC;		-- From ui_rd_data0 of ui_rd_data.v
   SIGNAL rd_accepted                : STD_LOGIC;		-- From ui_cmd0 of ui_cmd.v
   SIGNAL rd_buf_full                : STD_LOGIC;		-- From ui_rd_data0 of ui_rd_data.v
   SIGNAL rd_data_buf_addr_r         : STD_LOGIC_VECTOR(3 DOWNTO 0);		-- From ui_rd_data0 of ui_rd_data.v
   SIGNAL wr_accepted                : STD_LOGIC;		-- From ui_cmd0 of ui_cmd.v
   SIGNAL wr_data_buf_addr           : STD_LOGIC_VECTOR(3 DOWNTO 0);		-- From ui_wr_data0 of ui_wr_data.v
   SIGNAL wr_req_16                  : STD_LOGIC;		-- From ui_wr_data0 of ui_wr_data.v
   
   -- Declare intermediate signals for referenced outputs
   SIGNAL wr_data_mask_xhdl17        : STD_LOGIC_VECTOR(APP_MASK_WIDTH - 1 DOWNTO 0);
   SIGNAL wr_data_xhdl16             : STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
   SIGNAL use_addr_xhdl15            : STD_LOGIC;
   SIGNAL size_xhdl14                : STD_LOGIC;
   SIGNAL row_xhdl13                 : STD_LOGIC_VECTOR(ROW_WIDTH - 1 DOWNTO 0);
   SIGNAL raw_not_ecc_xhdl12         : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL rank_xhdl11                : STD_LOGIC_VECTOR(RANK_WIDTH - 1 DOWNTO 0);
   SIGNAL hi_priority_xhdl10         : STD_LOGIC;
   SIGNAL data_buf_addr_xhdl9        : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL col_xhdl8                  : STD_LOGIC_VECTOR(COL_WIDTH - 1 DOWNTO 0);
   SIGNAL cmd_xhdl7                  : STD_LOGIC_VECTOR(2 DOWNTO 0);
   SIGNAL bank_xhdl6                 : STD_LOGIC_VECTOR(BANK_WIDTH - 1 DOWNTO 0);
   SIGNAL app_wdf_rdy_xhdl5          : STD_LOGIC;
   SIGNAL app_rdy_xhdl4              : STD_LOGIC;
   SIGNAL app_rd_data_valid_xhdl3    : STD_LOGIC;
   SIGNAL app_rd_data_end_xhdl2      : STD_LOGIC;
   SIGNAL app_rd_data_xhdl1          : STD_LOGIC_VECTOR(APP_DATA_WIDTH - 1 DOWNTO 0);
   SIGNAL app_ecc_multiple_err_xhdl0 : STD_LOGIC_VECTOR(3 DOWNTO 0);
   SIGNAL rst_reg                    : STD_LOGIC_VECTOR(9 DOWNTO 0);
   SIGNAL rst_final                  : STD_LOGIC;
   SIGNAL app_addr_temp              : STD_LOGIC_VECTOR(ADDR_WIDTH - 1 DOWNTO 0);
   ATTRIBUTE max_fanout              : STRING;
   ATTRIBUTE max_fanout OF rst_final : SIGNAL IS "10";
BEGIN
   -- Drive referenced outputs
   wr_data_mask <= wr_data_mask_xhdl17;
   wr_data <= wr_data_xhdl16;
   use_addr <= use_addr_xhdl15;
   size <= size_xhdl14;
   row <= row_xhdl13;
   raw_not_ecc <= raw_not_ecc_xhdl12;
   rank <= rank_xhdl11;
   hi_priority <= hi_priority_xhdl10;
   data_buf_addr <= data_buf_addr_xhdl9;
   col <= col_xhdl8;
   cmd <= cmd_xhdl7;
   bank <= bank_xhdl6;
   app_wdf_rdy <= app_wdf_rdy_xhdl5;
   app_rdy <= app_rdy_xhdl4;
   app_rd_data_valid <= app_rd_data_valid_xhdl3;
   app_rd_data_end <= app_rd_data_end_xhdl2;
   app_rd_data <= app_rd_data_xhdl1;
   app_ecc_multiple_err <= app_ecc_multiple_err_xhdl0;
   correct_en <= app_correct_en;
   -- End of automatics

   rank_add_correction1: IF ( RANKS > 1 ) GENERATE

     app_addr_temp <= app_addr;

   END GENERATE;
   
   rank_add_correction2: IF ( RANKS = 1 ) GENERATE

     app_addr_temp <= ('0' & app_addr ( ADDR_WIDTH - 2 DOWNTO 0));

   END GENERATE;
   
   -- Parameters

   PROCESS (clk) 
   BEGIN
     IF ( clk'EVENT AND clk = '1') THEN
        rst_reg <= (rst_reg(8 DOWNTO 0) & rst);
     END IF;
   END PROCESS;

   PROCESS (clk) 
   BEGIN
     IF ( clk'EVENT AND clk = '1') THEN
        rst_final <= rst_reg(9);
     END IF;
   END PROCESS;
   
   
   ui_cmd0 : ui_cmd
      GENERIC MAP (
         TCQ            => TCQ,
         ADDR_WIDTH     => ADDR_WIDTH,
         BANK_WIDTH     => BANK_WIDTH,
         COL_WIDTH      => COL_WIDTH,
         RANK_WIDTH     => RANK_WIDTH,
         ROW_WIDTH      => ROW_WIDTH,
         RANKS          => RANKS,
         MEM_ADDR_ORDER => MEM_ADDR_ORDER
      )
      PORT MAP (
         -- Outputs
         app_rdy             => app_rdy_xhdl4,
         use_addr            => use_addr_xhdl15,
         rank                => rank_xhdl11(RANK_WIDTH - 1 DOWNTO 0),
         bank                => bank_xhdl6(BANK_WIDTH - 1 DOWNTO 0),
         row                 => row_xhdl13(ROW_WIDTH - 1 DOWNTO 0),
         col                 => col_xhdl8(COL_WIDTH - 1 DOWNTO 0),
         size                => size_xhdl14,
         cmd                 => cmd_xhdl7(2 DOWNTO 0),
         hi_priority         => hi_priority_xhdl10,
         rd_accepted         => rd_accepted,
         wr_accepted         => wr_accepted,
         data_buf_addr       => data_buf_addr_xhdl9(3 DOWNTO 0),
         -- Inputs
         rst                 => rst_final,
         clk                 => clk,
         accept_ns           => accept_ns,
         rd_buf_full         => rd_buf_full,
         wr_req_16           => wr_req_16,
         app_addr            => app_addr_temp(ADDR_WIDTH - 1 DOWNTO 0),
         app_cmd             => app_cmd(2 DOWNTO 0),
         app_sz              => app_sz,
         app_hi_pri          => app_hi_pri,
         app_en              => app_en,
         wr_data_buf_addr    => wr_data_buf_addr(3 DOWNTO 0),
         rd_data_buf_addr_r  => rd_data_buf_addr_r(3 DOWNTO 0)
      );
   
   -- Parameters
   
   
   ui_wr_data0 : ui_wr_data
      GENERIC MAP (
         TCQ             => TCQ,
         APP_DATA_WIDTH  => APP_DATA_WIDTH,
         APP_MASK_WIDTH  => APP_MASK_WIDTH,
         ECC             => ECC,
         ECC_TEST        => ECC_TEST,
         CWL             => CWL
      )
      PORT MAP (
         -- Outputs
         app_wdf_rdy       => app_wdf_rdy_xhdl5,
         wr_req_16         => wr_req_16,
         wr_data_buf_addr  => wr_data_buf_addr(3 DOWNTO 0),
         wr_data           => wr_data_xhdl16(APP_DATA_WIDTH - 1 DOWNTO 0),
         wr_data_mask      => wr_data_mask_xhdl17(APP_MASK_WIDTH - 1 DOWNTO 0),
         raw_not_ecc       => raw_not_ecc_xhdl12(3 DOWNTO 0),
         -- Inputs
         rst               => rst_final,
         clk               => clk,
         app_wdf_data      => app_wdf_data(APP_DATA_WIDTH - 1 DOWNTO 0),
         app_wdf_mask      => app_wdf_mask(APP_MASK_WIDTH - 1 DOWNTO 0),
         app_raw_not_ecc   => app_raw_not_ecc(3 DOWNTO 0),
         app_wdf_wren      => app_wdf_wren,
         app_wdf_end       => app_wdf_end,
         wr_data_offset    => wr_data_offset,
         wr_data_addr      => wr_data_addr(3 DOWNTO 0),
         wr_data_en        => wr_data_en,
         wr_accepted       => wr_accepted,
         ram_init_done_r   => ram_init_done_r,
         ram_init_addr     => ram_init_addr(3 DOWNTO 0)
      );
   
   -- Parameters
   
   
   ui_rd_data0 : ui_rd_data
      GENERIC MAP (
         TCQ             => TCQ,
         APP_DATA_WIDTH  => APP_DATA_WIDTH,
         ECC             => ECC,
         ORDERING        => ORDERING
      )
      PORT MAP (
         -- Outputs
         ram_init_done_r       => ram_init_done_r,
         ram_init_addr         => ram_init_addr(3 DOWNTO 0),
         app_rd_data_valid     => app_rd_data_valid_xhdl3,
         app_rd_data_end       => app_rd_data_end_xhdl2,
         app_rd_data           => app_rd_data_xhdl1(APP_DATA_WIDTH - 1 DOWNTO 0),
         app_ecc_multiple_err  => app_ecc_multiple_err_xhdl0(3 DOWNTO 0),
         rd_buf_full           => rd_buf_full,
         rd_data_buf_addr_r    => rd_data_buf_addr_r(3 DOWNTO 0),
         -- Inputs
         rst                   => rst_final,
         clk                   => clk,
         rd_data_en            => rd_data_en,
         rd_data_addr          => rd_data_addr(3 DOWNTO 0),
         rd_data_offset        => rd_data_offset,
         rd_data_end           => rd_data_end,
         rd_data               => rd_data(APP_DATA_WIDTH - 1 DOWNTO 0),
         ecc_multiple          => ecc_multiple(3 DOWNTO 0),
         rd_accepted           => rd_accepted
      );
   
END ARCHITECTURE trans;




-- ui_top

--*****************************************************************************
-- (c) Copyright 2008 - 2010 Xilinx, Inc. All rights reserved.
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
--  /   /         Filename              : bank_mach.vhd
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : 
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


-- Top level bank machine block.  A structural block instantiating the configured
-- individual bank machines, and a common block that computes various items shared
-- by all bank machines.

entity bank_mach is
   generic (
      TCQ                      : integer := 100;
      ADDR_CMD_MODE            : string := "1T";
      BANK_WIDTH               : integer := 3;
      BM_CNT_WIDTH             : integer := 2;
      BURST_MODE               : string := "8";
      COL_WIDTH                : integer := 12;
      CS_WIDTH                 : integer := 4;
      CWL                      : integer := 5;
      DATA_BUF_ADDR_WIDTH      : integer := 8;
      DRAM_TYPE                : string := "DDR3";
      EARLY_WR_DATA_ADDR       : string := "OFF";
      ECC                      : string := "OFF";
      LOW_IDLE_CNT             : integer := 1;
      nBANK_MACHS              : integer := 4;
      nCK_PER_CLK              : integer := 2;
      nCNFG2RD_EN              : integer := 2;
      nCNFG2WR                 : integer := 2;
      nCS_PER_RANK             : integer := 1;
      nOP_WAIT                 : integer := 0;
      nRAS                     : integer := 20;
      nRCD                     : integer := 5;
      nRFC                     : integer := 44;
      nRTP                     : integer := 4;
      nRP                      : integer := 10;
      nSLOTS                   : integer := 2;
      nWR                      : integer := 6;
      ORDERING                 : string := "NORM";
      RANK_BM_BV_WIDTH         : integer := 16;
      RANK_WIDTH               : integer := 2;
      RANKS                    : integer := 4;
      ROW_WIDTH                : integer := 16;
      RTT_NOM                  : string := "40";
      RTT_WR                   : string := "120";
      STARVE_LIMIT             : integer := 2;
      SLOT_0_CONFIG            : std_logic_vector(7 downto 0) := "00000101";
      SLOT_1_CONFIG            : std_logic_vector(7 downto 0) := "00001010";
      tZQCS                    : integer := 64   );
   port (
      
      maint_wip_r              : out std_logic;         -- From bank_common0 of bank_common.v
      insert_maint_r1          : out std_logic;
      dfi_we_n1                : out std_logic;
      dfi_we_n0                : out std_logic;
      dfi_ras_n1               : out std_logic;
      dfi_ras_n0               : out std_logic;
      dfi_odt_wr1              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_wr0              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom1             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom0             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n1                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n0                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cas_n1               : out std_logic;
      dfi_cas_n0               : out std_logic;
      dfi_bank1                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_bank0                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_address1             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_address0             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_wr_data_buf_addr     : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col_size                 : out std_logic;
      col_row                  : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_rmw                  : out std_logic;
      col_ra                   : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      col_periodic_rd          : out std_logic;
      col_data_buf_addr        : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col_ba                   : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      col_a                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      bank_mach_next           : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      accept_ns                : out std_logic;
      accept                   : out std_logic;
      io_config                : out std_logic_vector(RANK_WIDTH downto 0);
      io_config_strobe         : out std_logic;
      
      sending_row              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      sending_col              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      sent_col                 : out std_logic;
      
      periodic_rd_ack_r        : out std_logic;
      
      act_this_rank_r          : out std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
      wr_this_rank_r           : out std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
      rd_this_rank_r           : out std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
      
      rank_busy_r              : out std_logic_vector((RANKS * nBANK_MACHS) - 1 downto 0);
      wtr_inhbt_config_r       : in std_logic_vector(RANKS - 1 downto 0);
      use_addr                 : in std_logic;
      slot_1_present           : in std_logic_vector(7 downto 0);
      slot_0_present           : in std_logic_vector(7 downto 0);
      size                     : in std_logic;
      rst                      : in std_logic;
      row                      : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      rd_rmw                   : in std_logic;
      rd_data_addr             : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      rank                     : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      periodic_rd_rank_r       : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      periodic_rd_r            : in std_logic;
      maint_zq_r               : in std_logic;
      maint_req_r              : in std_logic;
      maint_rank_r             : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      inhbt_wr_config          : in std_logic;
      inhbt_rd_r               : in std_logic_vector(RANKS - 1 downto 0);
      inhbt_rd_config          : in std_logic;
      inhbt_act_faw_r          : in std_logic_vector(RANKS - 1 downto 0);
      hi_priority              : in std_logic;
      dq_busy_data             : in std_logic;
      dfi_rddata_valid         : in std_logic;
      dfi_init_complete        : in std_logic;
      data_buf_addr            : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col                      : in std_logic_vector(COL_WIDTH - 1 downto 0);
      cmd                      : in std_logic_vector(2 downto 0);
      clk                      : in std_logic;
      bank                     : in std_logic_vector(BANK_WIDTH - 1 downto 0)
   );
end entity bank_mach;

architecture trans of bank_mach is

component bank_common
   generic (
      TCQ                   : integer := 100;
      BM_CNT_WIDTH          : integer := 2;
      LOW_IDLE_CNT          : integer := 1;
      nBANK_MACHS           : integer := 4;
      nCK_PER_CLK           : integer := 2;
      nOP_WAIT              : integer := 0;
      nRFC                  : integer := 44;
      RANK_WIDTH            : integer := 2;
      RANKS                 : integer := 4;
      CWL                   : integer := 5; --Added to fix CR #528228
      tZQCS                 : integer := 64
   );
   port (
      
      accept_internal_r     : out std_logic;
      accept_ns             : out std_logic;
      accept                : out std_logic;
      periodic_rd_insert    : out std_logic;
      periodic_rd_ack_r     : out std_logic;
      accept_req            : out std_logic;
      rb_hit_busy_cnt       : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      idle_cnt              : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      order_cnt             : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      adv_order_q           : out std_logic;
      bank_mach_next        : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      op_exit_grant         : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      low_idle_cnt_r        : out std_logic;            -- = 1'b0;
      was_wr                : out std_logic;
      was_priority          : out std_logic;
      maint_wip_r           : out std_logic;
      maint_idle            : out std_logic;
      force_io_config_rd_r  : out std_logic;
      insert_maint_r        : out std_logic;
      clk                   : in std_logic;
      rst                   : in std_logic;
      idle_ns               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      dfi_init_complete     : in std_logic;
      periodic_rd_r         : in std_logic;
      use_addr              : in std_logic;
      rb_hit_busy_r         : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      idle_r                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      ordered_r             : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      ordered_issued        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      head_r                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      end_rtp               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      passing_open_bank     : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      op_exit_req           : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      start_pre_wait        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      cmd                   : in std_logic_vector(2 downto 0);
      hi_priority           : in std_logic;
      maint_req_r           : in std_logic;
      maint_zq_r            : in std_logic;
      maint_hit             : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      bm_end                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_valid_r     : in std_logic;
      io_config             : in std_logic_vector(RANK_WIDTH downto 0);
      slot_0_present        : in std_logic_vector(7 downto 0);
      slot_1_present        : in std_logic_vector(7 downto 0)
   );
end component;

component bank_cntrl
   generic (
      TCQ                      : integer := 100;
      ADDR_CMD_MODE            : string := "1T";
      BANK_WIDTH               : integer := 3;
      BM_CNT_WIDTH             : integer := 2;
      BURST_MODE               : string := "8";
      COL_WIDTH                : integer := 12;
      CWL                      : integer := 5;
      DATA_BUF_ADDR_WIDTH      : integer := 8;
      DRAM_TYPE                : string := "DDR3";
      ECC                      : string := "OFF";
      ID                       : integer := 4;
      nBANK_MACHS              : integer := 4;
      nCK_PER_CLK              : integer := 2;
      nCNFG2RD_EN              : integer := 2;
      nCNFG2WR                 : integer := 2;
      nOP_WAIT                 : integer := 0;
      nRAS_CLKS                : integer := 10;
      nRCD                     : integer := 5;
      nRTP                     : integer := 4;
      nRP                      : integer := 10;
      nWTP_CLKS                : integer := 5;
      ORDERING                 : string := "NORM";
      RANK_WIDTH               : integer := 2;
      RANKS                    : integer := 4;
      RAS_TIMER_WIDTH          : integer := 5;
      ROW_WIDTH                : integer := 16;
      STARVE_LIMIT             : integer := 2
   );
   port (
       wr_this_rank_r           : out std_logic_vector(RANKS - 1 downto 0);             -- From bank_state0 of bank_state.v
      start_rcd                : out std_logic;
      start_pre_wait           : out std_logic;
      rts_row                  : out std_logic;
      rts_col                  : out std_logic;
      rtc                      : out std_logic;
      row_cmd_wr               : out std_logic;
      row_addr                 : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      req_size_r               : out std_logic;
      req_row_r                : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      req_ras                  : out std_logic;
      req_periodic_rd_r        : out std_logic;
      req_cas                  : out std_logic;
      req_bank_r               : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      rd_this_rank_r           : out std_logic_vector(RANKS - 1 downto 0);
      rb_hit_busy_ns           : out std_logic;
      ras_timer_ns             : out std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
      rank_busy_r              : out std_logic_vector(RANKS - 1 downto 0);
      ordered_r                : out std_logic;
      ordered_issued           : out std_logic;
      op_exit_req              : out std_logic;
      end_rtp                  : out std_logic;
      demand_priority          : out std_logic;
      demand_act_priority      : out std_logic;
      col_rdy_wr               : out std_logic;
      col_addr                 : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      act_this_rank_r          : out std_logic_vector(RANKS - 1 downto 0);
      idle_ns                  : out std_logic;
      req_wr_r                 : out std_logic;
      rd_wr_r                  : out std_logic;
      bm_end                   : out std_logic;
      idle_r                   : out std_logic;
      head_r                   : out std_logic;
      req_rank_r               : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      rb_hit_busy_r            : out std_logic;
      passing_open_bank        : out std_logic;
      maint_hit                : out std_logic;
      req_data_buf_addr_r      : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      wtr_inhbt_config_r       : in std_logic_vector(RANKS - 1 downto 0);
      was_wr                   : in std_logic;
      was_priority             : in std_logic;
      use_addr                 : in std_logic;
      start_rcd_in             : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      size                     : in std_logic;
      sent_row                 : in std_logic;
      sent_col                 : in std_logic;
      sending_row              : in std_logic;
      sending_col              : in std_logic;
      rst                      : in std_logic;
      row                      : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      req_rank_r_in            : in std_logic_vector((RANK_WIDTH * nBANK_MACHS * 2) - 1 downto 0);
      rd_rmw                   : in std_logic;
      rd_data_addr             : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      rb_hit_busy_ns_in        : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      rb_hit_busy_cnt          : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      ras_timer_ns_in          : in std_logic_vector((2 * (RAS_TIMER_WIDTH * nBANK_MACHS)) - 1 downto 0);
      rank                     : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      periodic_rd_rank_r       : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      periodic_rd_insert       : in std_logic;
      periodic_rd_ack_r        : in std_logic;
      passing_open_bank_in     : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      order_cnt                : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      op_exit_grant            : in std_logic;
      maint_zq_r               : in std_logic;
      maint_req_r              : in std_logic;
      maint_rank_r             : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      maint_idle               : in std_logic;
      low_idle_cnt_r           : in std_logic;
      io_config_valid_r        : in std_logic;
      io_config_strobe         : in std_logic;
      io_config                : in std_logic_vector(RANK_WIDTH downto 0);
      inhbt_wr_config          : in std_logic;
      inhbt_rd_r               : in std_logic_vector(RANKS - 1 downto 0);
      inhbt_rd_config          : in std_logic;
      inhbt_act_faw_r          : in std_logic_vector(RANKS - 1 downto 0);
      idle_cnt                 : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      hi_priority              : in std_logic;
      dq_busy_data             : in std_logic;
      dfi_rddata_valid         : in std_logic;
      demand_priority_in       : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      demand_act_priority_in   : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      data_buf_addr            : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col                      : in std_logic_vector(COL_WIDTH - 1 downto 0);
      cmd                      : in std_logic_vector(2 downto 0);
      clk                      : in std_logic;
      bm_end_in                : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
      bank                     : in std_logic_vector(BANK_WIDTH - 1 downto 0);
      adv_order_q              : in std_logic;
      accept_req               : in std_logic;
      accept_internal_r        : in std_logic
   );
end component;

component arb_mux is
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
      nCK_PER_CLK              : integer := 2;          -- # DRAM CKs per fabric CLKs
      nCS_PER_RANK             : integer := 1;
      nCNFG2WR                 : integer := 2;
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

      sent_row                 : out std_logic;         -- From arb_row_col0 of arb_row_col.v
      sent_col                 : out std_logic;
      sending_row              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_valid_r        : out std_logic;
      io_config                : out std_logic_vector(RANK_WIDTH downto 0);
      dfi_we_n1                : out std_logic;
      dfi_we_n0                : out std_logic;
      dfi_ras_n1               : out std_logic;
      dfi_ras_n0               : out std_logic;
      dfi_odt_wr1              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_wr0              : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom1             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_odt_nom0             : out std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n1                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cs_n0                : out std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
      dfi_cas_n1               : out std_logic;
      dfi_cas_n0               : out std_logic;
      dfi_bank1                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_bank0                : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      dfi_address1             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      dfi_address0             : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_wr_data_buf_addr     : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col_size                 : out std_logic;
      col_row                  : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      col_rmw                  : out std_logic;
      col_ra                   : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      col_periodic_rd          : out std_logic;
      col_data_buf_addr        : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col_ba                   : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      col_a                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      
      sending_col              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_strobe         : out std_logic;
      insert_maint_r1          : out std_logic;
      slot_1_present           : in std_logic_vector(7 downto 0);
      slot_0_present           : in std_logic_vector(7 downto 0);
      rts_row                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rts_col                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rtc                      : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      row_cmd_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      row_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
      req_wr_r                 : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_size_r               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_row_r                : in std_logic_vector(ROW_VECT_INDX downto 0);
      req_ras                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_rank_r               : in std_logic_vector(RANK_VECT_INDX downto 0);
      req_periodic_rd_r        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_data_buf_addr_r      : in std_logic_vector(DATA_BUF_ADDR_VECT_INDX downto 0);
      req_cas                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      req_bank_r               : in std_logic_vector(BANK_VECT_INDX downto 0);
      rd_wr_r                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      maint_zq_r               : in std_logic;
      maint_rank_r             : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      insert_maint_r           : in std_logic;
      force_io_config_rd_r       : in std_logic;
      col_rdy_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      col_addr                 : in std_logic_vector(ROW_VECT_INDX downto 0);
      clk                      : in std_logic;
      rst                      : in std_logic
   );
end component;

function fRAS_CLKS (nCK_PER_CLK: integer; nRAS : integer )
return integer is
begin

if (nCK_PER_CLK = 1) then
    return (nRAS);
else 
    return ( nRAS/2 + (nRAS mod 2));
    
end if ;
end function fRAS_CLKS;


function fWTP (CWL: integer; nWR : integer; BURST_MODE : string )
return integer is
begin

if (BURST_MODE = "4") then
    return (CWL + 2 + nWR);
else 
    return ( CWL + 4 + nWR);
    
end if ;
end function fWTP;

function fWTP_CLKS (nCK_PER_CLK: integer; nWTP : integer; ADDR_CMD_MODE : string )
return integer is
begin

if (nCK_PER_CLK = 1) then
    return (nWTP);
else 
   if  (ADDR_CMD_MODE = "2T") then
    return ( nWTP/2 + (nWTP mod 2));
   else
    return ( nWTP/2 + 1);
   end if;
   
end if ;
end function fWTP_CLKS;


function clogb2(size: integer) return integer is
   variable tmp : integer range 0 to 24;

begin
  tmp := 0;

  for i in 23 downto 0 loop  
    if( size <= 2** i) then 
    tmp := i; 
    end if;
  end loop;
  return tmp;
end function clogb2;


function fRAS_TIMER_WIDTH (nRAS_CLKS: integer; nWTP_CLKS : integer)
return integer is
begin

if (nRAS_CLKS > nWTP_CLKS) then
    return (clogb2(nRAS_CLKS - 1));
else 
    return ( clogb2(nWTP_CLKS - 1));
    
end if ;
end function fRAS_TIMER_WIDTH;

      
constant RANK_VECT_INDX           : integer := (nBANK_MACHS * RANK_WIDTH) - 1;
constant BANK_VECT_INDX           : integer := (nBANK_MACHS * BANK_WIDTH) - 1;
constant ROW_VECT_INDX            : integer := (nBANK_MACHS * ROW_WIDTH) - 1;
constant DATA_BUF_ADDR_VECT_INDX  : integer := (nBANK_MACHS * DATA_BUF_ADDR_WIDTH) - 1;

constant nRAS_CLKS                : integer := fRAS_CLKS(nCK_PER_CLK,nRAS );
constant nWTP                     : integer := fWTP(CWL ,nWR,BURST_MODE) ;
       -- Unless 2T mode, add one to nWTP_CLKS.  This accounts for loss of one DRAM CK
       -- due to column command to row command fixed offset.
constant  nWTP_CLKS               : integer := fWTP_CLKS(nCK_PER_CLK ,nWTP ,ADDR_CMD_MODE) ;
                                                
constant  RAS_TIMER_WIDTH    : integer := fRAS_TIMER_WIDTH(nRAS_CLKS ,nWTP_CLKS );


   signal accept_internal_r        : std_logic;
   signal accept_req               : std_logic;
   signal adv_order_q              : std_logic;
   signal force_io_config_rd       : std_logic;
   signal idle_cnt                 : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal insert_maint_r           : std_logic;
   signal io_config_valid_r        : std_logic;
   signal low_idle_cnt_r           : std_logic;
   signal maint_idle               : std_logic;
   signal order_cnt                : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal periodic_rd_insert       : std_logic;
   signal rb_hit_busy_cnt          : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal sent_row                 : std_logic;
   signal was_priority             : std_logic;
   signal was_wr                   : std_logic;
   signal rts_row                  : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal rts_col                  : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal col_rdy_wr               : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal rtc                      : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal req_data_buf_addr_r      : std_logic_vector(DATA_BUF_ADDR_VECT_INDX downto 0);
   signal req_size_r               : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal req_rank_r               : std_logic_vector(RANK_VECT_INDX downto 0);
   signal req_bank_r               : std_logic_vector(BANK_VECT_INDX downto 0);
   signal req_row_r                : std_logic_vector(ROW_VECT_INDX downto 0);
   signal col_addr                 : std_logic_vector(ROW_VECT_INDX downto 0);
   signal req_periodic_rd_r        : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal req_wr_r                 : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal rd_wr_r                  : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal req_ras                  : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal req_cas                  : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal row_addr                 : std_logic_vector(ROW_VECT_INDX downto 0);
   signal row_cmd_wr               : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal demand_priority          : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal demand_act_priority      : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal idle_ns                  : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal rb_hit_busy_r            : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal bm_end                   : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal passing_open_bank        : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal ordered_r                : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal ordered_issued           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal rb_hit_busy_ns           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal maint_hit                : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal idle_r                   : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal head_r                   : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal start_rcd                : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal end_rtp                  : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal op_exit_req              : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal op_exit_grant            : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal start_pre_wait           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal ras_timer_ns             : std_logic_vector((RAS_TIMER_WIDTH * nBANK_MACHS) - 1 downto 0);
   -- X-HDL generated signals

   signal i40 : std_logic_vector((2*nBANK_MACHS) - 1 downto 0);
   signal i41 : std_logic_vector((2*nBANK_MACHS) - 1 downto 0);
   signal i42 : std_logic_vector((2*nBANK_MACHS) - 1 downto 0);
   signal i43 : std_logic_vector((2*nBANK_MACHS) - 1 downto 0);
   signal i44 : std_logic_vector((2*nBANK_MACHS) - 1 downto 0);
   signal i45 : std_logic_vector((2*RANK_VECT_INDX)+1 downto 0);
   signal i46 : std_logic_vector((2* nBANK_MACHS) - 1 downto 0);
   signal i47 : std_logic_vector((2*RAS_TIMER_WIDTH * nBANK_MACHS) - 1 downto 0);
   
   -- Declare intermediate signals for referenced outputs
   signal maint_wip_r_i          : std_logic;
   signal insert_maint_r1_i      : std_logic;
   signal dfi_we_n1_i            : std_logic;
   signal dfi_we_n0_i            : std_logic;
   signal dfi_ras_n1_i26           : std_logic;
   signal dfi_ras_n0_i           : std_logic;
   signal dfi_odt_wr1_i          : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_wr0_i          : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_nom1_i         : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_odt_nom0_i         : std_logic_vector((nSLOTS * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cs_n1_i            : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cs_n0_i            : std_logic_vector((CS_WIDTH * nCS_PER_RANK) - 1 downto 0);
   signal dfi_cas_n1_i           : std_logic;
   signal dfi_cas_n0_i           : std_logic;
   signal dfi_bank1_i            : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_bank0_i            : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal dfi_address1_i         : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal dfi_address0_i         : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_wr_data_buf_addr_i : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal col_size_i             : std_logic;
   signal col_row_i              : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal col_rmw_i               : std_logic;
   signal col_ra_i                : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal col_periodic_rd_i       : std_logic;
   signal col_data_buf_addr_i     : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
   signal col_ba_i                : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal col_a_i                 : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal bank_mach_next_i        : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal accept_ns_i             : std_logic;
   signal accept_i                : std_logic;
   signal io_config_i            : std_logic_vector(RANK_WIDTH downto 0);
   signal io_config_strobe_i     : std_logic;
   signal sending_row_i          : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal sending_col_i          : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal sent_col_i             : std_logic;
   signal periodic_rd_ack_r_i    : std_logic;
   signal act_this_rank_r_i       : std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
   signal wr_this_rank_r_i       : std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
   signal rd_this_rank_r_i       : std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
   signal rank_busy_r_i          : std_logic_vector((RANKS * nBANK_MACHS) - 1 downto 0);
begin
   -- Drive referenced outputs
   maint_wip_r <= maint_wip_r_i;
   insert_maint_r1 <= insert_maint_r1_i;
   dfi_we_n1 <= dfi_we_n1_i;
   dfi_we_n0 <= dfi_we_n0_i;
   dfi_ras_n1 <= dfi_ras_n1_i26;
   dfi_ras_n0 <= dfi_ras_n0_i;
   dfi_odt_wr1 <= dfi_odt_wr1_i;
   dfi_odt_wr0 <= dfi_odt_wr0_i;
   dfi_odt_nom1 <= dfi_odt_nom1_i;
   dfi_odt_nom0 <= dfi_odt_nom0_i;
   dfi_cs_n1 <= dfi_cs_n1_i;
   dfi_cs_n0 <= dfi_cs_n0_i;
   dfi_cas_n1 <= dfi_cas_n1_i;
   dfi_cas_n0 <= dfi_cas_n0_i;
   dfi_bank1 <= dfi_bank1_i;
   dfi_bank0 <= dfi_bank0_i;
   dfi_address1 <= dfi_address1_i;
   dfi_address0 <= dfi_address0_i;
   col_wr_data_buf_addr <= col_wr_data_buf_addr_i;
   col_size <= col_size_i;
   col_row <= col_row_i;
   col_rmw <= col_rmw_i;
   col_ra <= col_ra_i;
   col_periodic_rd <= col_periodic_rd_i;
   col_data_buf_addr <= col_data_buf_addr_i;
   col_ba <= col_ba_i;
   col_a <= col_a_i;
   bank_mach_next <= bank_mach_next_i;
   accept_ns <= accept_ns_i;
   accept <= accept_i;
   io_config <= io_config_i;
   io_config_strobe <= io_config_strobe_i;
   sending_row <= sending_row_i;
   sending_col <= sending_col_i;
   sent_col <= sent_col_i;
   periodic_rd_ack_r <= periodic_rd_ack_r_i;
   act_this_rank_r <= act_this_rank_r_i;
   wr_this_rank_r <= wr_this_rank_r_i;
   rd_this_rank_r <= rd_this_rank_r_i;
   rank_busy_r <= rank_busy_r_i;
   
   bank_cntrl_inst : for ID in 0 to  nBANK_MACHS - 1 generate
      -- Parameters
      
      
      i40 <= demand_priority & demand_priority;
      i41 <= demand_act_priority & demand_act_priority;
      i42 <= bm_end & bm_end;
      i43 <= passing_open_bank & passing_open_bank;
      i44 <= rb_hit_busy_ns & rb_hit_busy_ns;
      i45 <= req_rank_r & req_rank_r;
      i46 <= start_rcd & start_rcd;
      i47 <= ras_timer_ns & ras_timer_ns;
      bank0 : bank_cntrl
         generic map (
            tcq                  => TCQ,
            addr_cmd_mode        => ADDR_CMD_MODE,
            bank_width           => BANK_WIDTH,
            bm_cnt_width         => BM_CNT_WIDTH,
            burst_mode           => BURST_MODE,
            col_width            => COL_WIDTH,
            cwl                  => CWL,
            data_buf_addr_width  => DATA_BUF_ADDR_WIDTH,
            dram_type            => DRAM_TYPE,
            ecc                  => ECC,
            id                   => ID,
            nbank_machs          => nBANK_MACHS,
            nck_per_clk          => nCK_PER_CLK,
            ncnfg2rd_en          => nCNFG2RD_EN,
            ncnfg2wr             => nCNFG2WR,
            nop_wait             => nOP_WAIT,
            nras_clks            => nRAS_CLKS,
            nrcd                 => nRCD,
            nrtp                 => nRTP,
            nrp                  => nRP,
            nwtp_clks            => nWTP_CLKS,
            ordering             => ORDERING,
            rank_width           => RANK_WIDTH,
            ranks                => RANKS,
            ras_timer_width      => RAS_TIMER_WIDTH,
            row_width            => ROW_WIDTH,
            starve_limit         => STARVE_LIMIT
         )
         port map (
            demand_priority         => demand_priority(ID),
            demand_priority_in      => i40,
            demand_act_priority     => demand_act_priority(ID),
            demand_act_priority_in  => i41,
            rts_row                 => rts_row(ID),
            rts_col                 => rts_col(ID),
            col_rdy_wr              => col_rdy_wr(ID),
            rtc                     => rtc(ID),
            sending_row             => sending_row_i(ID),
            sending_col             => sending_col_i(ID),
            req_data_buf_addr_r     => req_data_buf_addr_r((ID * DATA_BUF_ADDR_WIDTH)+DATA_BUF_ADDR_WIDTH-1 downto (ID * DATA_BUF_ADDR_WIDTH)),
            req_size_r              => req_size_r(ID),
            req_rank_r              => req_rank_r((ID * RANK_WIDTH)+RANK_WIDTH-1 downto (ID*RANK_WIDTH)),
            req_bank_r              => req_bank_r((ID * BANK_WIDTH)+BANK_WIDTH-1 downto (ID*BANK_WIDTH)),
            req_row_r               => req_row_r((ID * ROW_WIDTH)+ROW_WIDTH-1 downto (ID*ROW_WIDTH)),
            col_addr                => col_addr((ID * ROW_WIDTH)+ROW_WIDTH-1 downto (ID*ROW_WIDTH)),
            req_wr_r                => req_wr_r(ID),
            rd_wr_r                 => rd_wr_r(ID),
            req_periodic_rd_r       => req_periodic_rd_r(ID),
            req_ras                 => req_ras(ID),
            req_cas                 => req_cas(ID),
            row_addr                => row_addr((ID * ROW_WIDTH)+ROW_WIDTH-1 downto (ID*ROW_WIDTH)),
            row_cmd_wr              => row_cmd_wr(ID),
            act_this_rank_r         => act_this_rank_r_i((ID * RANKS)+RANKS-1 downto (ID*RANKS)),
            wr_this_rank_r          => wr_this_rank_r_i((ID * RANKS)+RANKS-1 downto (ID*RANKS)),
            rd_this_rank_r          => rd_this_rank_r_i((ID * RANKS)+RANKS-1 downto (ID*RANKS)),
            idle_ns                 => idle_ns(ID),
            rb_hit_busy_r           => rb_hit_busy_r(ID),
            bm_end                  => bm_end(ID),
            bm_end_in               => i42,
            passing_open_bank       => passing_open_bank(ID),
            passing_open_bank_in    => i43,
            ordered_r               => ordered_r(ID),
            ordered_issued          => ordered_issued(ID),
            rb_hit_busy_ns          => rb_hit_busy_ns(ID),
            rb_hit_busy_ns_in       => i44,
            maint_hit               => maint_hit(ID),
            req_rank_r_in           => i45,
            idle_r                  => idle_r(ID),
            head_r                  => head_r(ID),
            start_rcd               => start_rcd(ID),
            start_rcd_in            => i46,
            end_rtp                 => end_rtp(ID),
            op_exit_req             => op_exit_req(ID),
            op_exit_grant           => op_exit_grant(ID),
            start_pre_wait          => start_pre_wait(ID),
            ras_timer_ns            => ras_timer_ns((ID * RAS_TIMER_WIDTH)+RAS_TIMER_WIDTH-1 downto (ID * RAS_TIMER_WIDTH)),
            ras_timer_ns_in         => i47,
            rank_busy_r             => rank_busy_r_i((ID * RANKS)+RANKS-1 downto (ID*RANKS)),
            -- Inputs
            accept_internal_r       => accept_internal_r,
            accept_req              => accept_req,
            adv_order_q             => adv_order_q,
            bank                    => bank(BANK_WIDTH - 1 downto 0),
            clk                     => clk,
            cmd                     => cmd(2 downto 0),
            col                     => col(COL_WIDTH - 1 downto 0),
            data_buf_addr           => data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
            dfi_rddata_valid        => dfi_rddata_valid,
            dq_busy_data            => dq_busy_data,
            hi_priority             => hi_priority,
            idle_cnt                => idle_cnt(BM_CNT_WIDTH - 1 downto 0),
            inhbt_act_faw_r         => inhbt_act_faw_r(RANKS - 1 downto 0),
            inhbt_rd_config         => inhbt_rd_config,
            inhbt_rd_r              => inhbt_rd_r(RANKS - 1 downto 0),
            inhbt_wr_config         => inhbt_wr_config,
            io_config               => io_config_i(RANK_WIDTH downto 0),
            io_config_strobe        => io_config_strobe_i,
            io_config_valid_r       => io_config_valid_r,
            low_idle_cnt_r          => low_idle_cnt_r,
            maint_idle              => maint_idle,
            maint_rank_r            => maint_rank_r(RANK_WIDTH - 1 downto 0),
            maint_req_r             => maint_req_r,
            maint_zq_r              => maint_zq_r,
            order_cnt               => order_cnt(BM_CNT_WIDTH - 1 downto 0),
            periodic_rd_ack_r       => periodic_rd_ack_r_i,
            periodic_rd_insert      => periodic_rd_insert,
            periodic_rd_rank_r      => periodic_rd_rank_r(RANK_WIDTH - 1 downto 0),
            rank                    => rank(RANK_WIDTH - 1 downto 0),
            rb_hit_busy_cnt         => rb_hit_busy_cnt(BM_CNT_WIDTH - 1 downto 0),
            rd_data_addr            => rd_data_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
            rd_rmw                  => rd_rmw,
            row                     => row(ROW_WIDTH - 1 downto 0),
            rst                     => rst,
            sent_col                => sent_col_i,
            sent_row                => sent_row,
            size                    => size,
            use_addr                => use_addr,
            was_priority            => was_priority,
            was_wr                  => was_wr,
            wtr_inhbt_config_r      => wtr_inhbt_config_r(RANKS - 1 downto 0)
         );
   end generate;



   
   -- Parameters
   
   
   bank_common0 : bank_common
      generic map (
         tcq           => TCQ,
         bm_cnt_width  => BM_CNT_WIDTH,
         low_idle_cnt  => LOW_IDLE_CNT,
         nbank_machs   => nBANK_MACHS,
         nck_per_clk   => nCK_PER_CLK,
         nop_wait      => nOP_WAIT,
         nrfc          => nRFC,
         rank_width    => RANK_WIDTH,
         ranks         => RANKS,
         CWL           => CWL, --Added to fix CR #528228
         tzqcs         => tZQCS
      )
      port map (
         op_exit_grant       => op_exit_grant(nBANK_MACHS - 1 downto 0),
         -- Outputs
         accept_internal_r   => accept_internal_r,
         accept_ns           => accept_ns_i,
         accept              => accept_i,
         periodic_rd_insert  => periodic_rd_insert,
         periodic_rd_ack_r   => periodic_rd_ack_r_i,
         accept_req          => accept_req,
         rb_hit_busy_cnt     => rb_hit_busy_cnt(BM_CNT_WIDTH - 1 downto 0),
         idle_cnt            => idle_cnt(BM_CNT_WIDTH - 1 downto 0),
         order_cnt           => order_cnt(BM_CNT_WIDTH - 1 downto 0),
         adv_order_q         => adv_order_q,
         bank_mach_next      => bank_mach_next_i(BM_CNT_WIDTH - 1 downto 0),
         low_idle_cnt_r      => low_idle_cnt_r,
         was_wr              => was_wr,
         was_priority        => was_priority,
         maint_wip_r         => maint_wip_r_i,
         maint_idle          => maint_idle,
         force_io_config_rd_r  => force_io_config_rd,
         insert_maint_r      => insert_maint_r,
         -- Inputs
         clk                 => clk,
         rst                 => rst,
         idle_ns             => idle_ns(nBANK_MACHS - 1 downto 0),
         dfi_init_complete   => dfi_init_complete,
         periodic_rd_r       => periodic_rd_r,
         use_addr            => use_addr,
         rb_hit_busy_r       => rb_hit_busy_r(nBANK_MACHS - 1 downto 0),
         idle_r              => idle_r(nBANK_MACHS - 1 downto 0),
         ordered_r           => ordered_r(nBANK_MACHS - 1 downto 0),
         ordered_issued      => ordered_issued(nBANK_MACHS - 1 downto 0),
         head_r              => head_r(nBANK_MACHS - 1 downto 0),
         end_rtp             => end_rtp(nBANK_MACHS - 1 downto 0),
         passing_open_bank   => passing_open_bank(nBANK_MACHS - 1 downto 0),
         op_exit_req         => op_exit_req(nBANK_MACHS - 1 downto 0),
         start_pre_wait      => start_pre_wait(nBANK_MACHS - 1 downto 0),
         cmd                 => cmd(2 downto 0),
         hi_priority         => hi_priority,
         maint_req_r         => maint_req_r,
         maint_zq_r          => maint_zq_r,
         maint_hit           => maint_hit(nBANK_MACHS - 1 downto 0),
         bm_end              => bm_end(nBANK_MACHS - 1 downto 0),
         io_config_valid_r   => io_config_valid_r,
         io_config           => io_config_i(RANK_WIDTH downto 0),
         slot_0_present      => slot_0_present(7 downto 0),
         slot_1_present      => slot_1_present(7 downto 0)
      );
   
   -- Parameters
                -- AUTOs wants to make this an input.
   
   arb_mux0 : arb_mux
      generic map (
         tcq                      => TCQ,
         addr_cmd_mode            => ADDR_CMD_MODE,
         bank_vect_indx           => BANK_VECT_INDX,
         bank_width               => BANK_WIDTH,
         burst_mode               => BURST_MODE,
         cs_width                 => CS_WIDTH,
         data_buf_addr_vect_indx  => DATA_BUF_ADDR_VECT_INDX,
         data_buf_addr_width      => DATA_BUF_ADDR_WIDTH,
         dram_type                => DRAM_TYPE,
         early_wr_data_addr       => EARLY_WR_DATA_ADDR,
         ecc                      => ECC,
         nbank_machs              => nBANK_MACHS,
         nck_per_clk              => nCK_PER_CLK,
         ncs_per_rank             => nCS_PER_RANK,
         ncnfg2wr                 => nCNFG2WR,
         nslots                   => nSLOTS,
         rank_vect_indx           => RANK_VECT_INDX,
         rank_width               => RANK_WIDTH,
         row_vect_indx            => ROW_VECT_INDX,
         row_width                => ROW_WIDTH,
         rtt_nom                  => RTT_NOM,
         rtt_wr                   => RTT_WR,
         slot_0_config            => SLOT_0_CONFIG,
         slot_1_config            => SLOT_1_CONFIG
      )
      port map (
         rts_col               => rts_col(nBANK_MACHS - 1 downto 0),
         -- Outputs
         col_a                 => col_a_i(ROW_WIDTH - 1 downto 0),
         col_ba                => col_ba_i(BANK_WIDTH - 1 downto 0),
         col_data_buf_addr     => col_data_buf_addr_i(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         col_periodic_rd       => col_periodic_rd_i,
         col_ra                => col_ra_i(RANK_WIDTH - 1 downto 0),
         col_rmw               => col_rmw_i,
         col_row               => col_row_i(ROW_WIDTH - 1 downto 0),
         col_size              => col_size_i,
         col_wr_data_buf_addr  => col_wr_data_buf_addr_i(DATA_BUF_ADDR_WIDTH - 1 downto 0),
         dfi_address0          => dfi_address0_i(ROW_WIDTH - 1 downto 0),
         dfi_address1          => dfi_address1_i(ROW_WIDTH - 1 downto 0),
         dfi_bank0             => dfi_bank0_i(BANK_WIDTH - 1 downto 0),
         dfi_bank1             => dfi_bank1_i(BANK_WIDTH - 1 downto 0),
         dfi_cas_n0            => dfi_cas_n0_i,
         dfi_cas_n1            => dfi_cas_n1_i,
         dfi_cs_n0             => dfi_cs_n0_i((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
         dfi_cs_n1             => dfi_cs_n1_i((CS_WIDTH * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_nom0          => dfi_odt_nom0_i((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_nom1          => dfi_odt_nom1_i((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_wr0           => dfi_odt_wr0_i((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_odt_wr1           => dfi_odt_wr1_i((nSLOTS * nCS_PER_RANK) - 1 downto 0),
         dfi_ras_n0            => dfi_ras_n0_i,
         dfi_ras_n1            => dfi_ras_n1_i26,
         dfi_we_n0             => dfi_we_n0_i,
         dfi_we_n1             => dfi_we_n1_i,
         io_config             => io_config_i(RANK_WIDTH downto 0),
         io_config_valid_r     => io_config_valid_r,
         sending_row           => sending_row_i(nBANK_MACHS - 1 downto 0),
         sent_col              => sent_col_i,
         sent_row              => sent_row,
         sending_col           => sending_col_i(nBANK_MACHS - 1 downto 0),
         io_config_strobe      => io_config_strobe_i,
         insert_maint_r1       => insert_maint_r1_i,
         -- Inputs
         col_addr              => col_addr(ROW_VECT_INDX downto 0),
         col_rdy_wr            => col_rdy_wr(nBANK_MACHS - 1 downto 0),
         force_io_config_rd_r  => force_io_config_rd,
         insert_maint_r        => insert_maint_r,
         maint_rank_r          => maint_rank_r(RANK_WIDTH - 1 downto 0),
         maint_zq_r            => maint_zq_r,
         rd_wr_r               => rd_wr_r(nBANK_MACHS - 1 downto 0),
         req_bank_r            => req_bank_r(BANK_VECT_INDX downto 0),
         req_cas               => req_cas(nBANK_MACHS - 1 downto 0),
         req_data_buf_addr_r   => req_data_buf_addr_r(DATA_BUF_ADDR_VECT_INDX downto 0),
         req_periodic_rd_r     => req_periodic_rd_r(nBANK_MACHS - 1 downto 0),
         req_rank_r            => req_rank_r(RANK_VECT_INDX downto 0),
         req_ras               => req_ras(nBANK_MACHS - 1 downto 0),
         req_row_r             => req_row_r(ROW_VECT_INDX downto 0),
         req_size_r            => req_size_r(nBANK_MACHS - 1 downto 0),
         req_wr_r              => req_wr_r(nBANK_MACHS - 1 downto 0),
         row_addr              => row_addr(ROW_VECT_INDX downto 0),
         row_cmd_wr            => row_cmd_wr(nBANK_MACHS - 1 downto 0),
         rtc                   => rtc(nBANK_MACHS - 1 downto 0),
         rts_row               => rts_row(nBANK_MACHS - 1 downto 0),
         slot_0_present        => slot_0_present(7 downto 0),
         slot_1_present        => slot_1_present(7 downto 0),
         clk                   => clk,
         rst                   => rst
      );
   
end architecture trans;



-- bank_mach

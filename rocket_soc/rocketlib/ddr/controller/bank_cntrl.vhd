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
--  /   /         Filename              : bank_cntrl.vhd
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

-- Structural block instantiating the three sub blocks that make up
-- a bank machine.
entity bank_cntrl is
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
end entity bank_cntrl;

architecture trans of bank_cntrl is

component bank_compare
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
end component;

component bank_queue
   generic (
            TCQ                    : integer := 100;
            BM_CNT_WIDTH           : integer := 2;
            nBANK_MACHS            : integer := 4;
            ORDERING               : string := "NORM";
            ID                     : integer := 0
           );
   port (
         head_r                 : out std_logic;
         tail_r                 : out std_logic;
         idle_ns                : out std_logic;
         idle_r                 : out std_logic;
         pass_open_bank_ns      : out std_logic;
         pass_open_bank_r       : out std_logic;
         auto_pre_r             : out std_logic;
         bm_end                 : out std_logic;
         passing_open_bank      : out std_logic;
         ordered_issued         : out std_logic;
         ordered_r              : out std_logic;
         order_q_zero           : out std_logic;
         rcv_open_bank          : out std_logic;           --= 1'b0;
         rb_hit_busies_r        : out std_logic_vector(nBANK_MACHS * 2 - 1 downto 0);
         q_has_rd               : out std_logic;
         q_has_priority         : out std_logic;
         wait_for_maint_r       : out std_logic;
         clk                    : in std_logic;
         rst                    : in std_logic;
         accept_internal_r      : in std_logic;
         use_addr               : in std_logic;
         periodic_rd_ack_r      : in std_logic;
         bm_end_in              : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         idle_cnt               : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
         rb_hit_busy_cnt        : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
         accept_req             : in std_logic;
         rb_hit_busy_r          : in std_logic;
         maint_idle             : in std_logic;
         maint_hit              : in std_logic;
         row_hit_r              : in std_logic;
         pre_wait_r             : in std_logic;
         allow_auto_pre         : in std_logic;
         sending_col            : in std_logic;
         bank_wait_in_progress  : in std_logic;
         precharge_bm_end       : in std_logic;
         req_wr_r               : in std_logic;
         rd_wr_r                : in std_logic;
         adv_order_q            : in std_logic;
         order_cnt              : in std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
         rb_hit_busy_ns_in      : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         passing_open_bank_in   : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         was_wr                 : in std_logic;
         maint_req_r            : in std_logic;
         was_priority           : in std_logic
        );
end component; 

component bank_state
   generic (
            TCQ                     : integer := 100;
            ADDR_CMD_MODE           : string := "1T";
            BM_CNT_WIDTH            : integer := 2;
            BURST_MODE              : string := "8";
            CWL                     : integer := 5;
            DATA_BUF_ADDR_WIDTH     : integer := 8;
            DRAM_TYPE               : string := "DDR3";
            ECC                     : string := "OFF";
            ID                      : integer := 0;
            nBANK_MACHS             : integer := 4;
            nCK_PER_CLK             : integer := 2;
            nCNFG2RD_EN             : integer := 2;
            nCNFG2WR                : integer := 2;
            nOP_WAIT                : integer := 0;
            nRAS_CLKS               : integer := 10;
            nRP                     : integer := 10;
            nRTP                    : integer := 4;
            nRCD                    : integer := 5;
            nWTP_CLKS               : integer := 5;
            ORDERING                : string := "NORM";
            RANKS                   : integer := 4;
            RANK_WIDTH              : integer := 4;
            RAS_TIMER_WIDTH         : integer := 5;
            STARVE_LIMIT            : integer := 2
           );
   port (
         start_rcd               : out std_logic;
         act_wait_r              : out std_logic;
         ras_timer_ns            : out std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
         rd_half_rmw             : out std_logic;
         end_rtp                 : out std_logic;
         bank_wait_in_progress   : out std_logic;
         start_pre_wait          : out std_logic;
         op_exit_req             : out std_logic;
         pre_wait_r              : out std_logic;
         allow_auto_pre          : out std_logic;
         precharge_bm_end        : out std_logic;
         demand_act_priority     : out std_logic;
         rts_row                 : out std_logic;
         act_this_rank_r         : out std_logic_vector(RANKS - 1 downto 0);
         demand_priority         : out std_logic;
         rtc                     : out std_logic;
         col_rdy_wr              : out std_logic;
         rts_col                 : out std_logic;
         wr_this_rank_r          : out std_logic_vector(RANKS - 1 downto 0);
         rd_this_rank_r          : out std_logic_vector(RANKS - 1 downto 0);
         clk                     : in std_logic;
         rst                     : in std_logic;
         bm_end                  : in std_logic;
         pass_open_bank_r        : in std_logic;
         sending_row             : in std_logic;
         rcv_open_bank           : in std_logic;
         sending_col             : in std_logic;
         rd_wr_r                 : in std_logic;
         req_wr_r                : in std_logic;
         rd_data_addr            : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         req_data_buf_addr_r     : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
         dfi_rddata_valid        : in std_logic;
         rd_rmw                  : in std_logic;
         ras_timer_ns_in         : in std_logic_vector((2 * (RAS_TIMER_WIDTH * nBANK_MACHS)) - 1 downto 0);
         rb_hit_busies_r         : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         idle_r                  : in std_logic;
         passing_open_bank       : in std_logic;
         low_idle_cnt_r          : in std_logic;
         op_exit_grant           : in std_logic;
         tail_r                  : in std_logic;
         auto_pre_r              : in std_logic;
         pass_open_bank_ns       : in std_logic;
         req_rank_r              : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         req_rank_r_in           : in std_logic_vector((RANK_WIDTH * nBANK_MACHS * 2) - 1 downto 0);
         start_rcd_in            : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         inhbt_act_faw_r         : in std_logic_vector(RANKS - 1 downto 0);
         wait_for_maint_r        : in std_logic;
         head_r                  : in std_logic;
         sent_row                : in std_logic;
         demand_act_priority_in  : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         order_q_zero            : in std_logic;
         sent_col                : in std_logic;
         q_has_rd                : in std_logic;
         q_has_priority          : in std_logic;
         req_priority_r          : in std_logic;
         idle_ns                 : in std_logic;
         demand_priority_in      : in std_logic_vector((nBANK_MACHS * 2) - 1 downto 0);
         io_config_strobe        : in std_logic;
         io_config_valid_r       : in std_logic;
         io_config               : in std_logic_vector(RANK_WIDTH downto 0);
         wtr_inhbt_config_r      : in std_logic_vector(RANKS - 1 downto 0);
         inhbt_rd_config         : in std_logic;
         inhbt_wr_config         : in std_logic;
         inhbt_rd_r              : in std_logic_vector(RANKS - 1 downto 0);
         dq_busy_data            : in std_logic
        );
end component;

   signal act_wait_r            : std_logic;
   signal allow_auto_pre        : std_logic;
   signal auto_pre_r            : std_logic;
   signal bank_wait_in_progress : std_logic;
   signal order_q_zero          : std_logic;
   signal pass_open_bank_ns     : std_logic;
   signal pass_open_bank_r      : std_logic;
   signal pre_wait_r            : std_logic;
   signal precharge_bm_end      : std_logic;
   signal q_has_priority        : std_logic;
   signal q_has_rd              : std_logic;
   signal rb_hit_busies_r       : std_logic_vector(nBANK_MACHS * 2 - 1 downto 0);
   signal rcv_open_bank         : std_logic;
   signal rd_half_rmw           : std_logic;
   signal req_priority_r        : std_logic;
   signal row_hit_r             : std_logic;
   signal tail_r                : std_logic;
   signal wait_for_maint_r      : std_logic;
   
   -- Declare intermediate signals for referenced outputs
   signal wr_this_rank_r_i      : std_logic_vector(RANKS - 1 downto 0);
   signal start_rcd_i           : std_logic;
   signal start_pre_wait_i      : std_logic;
   signal rts_row_i             : std_logic;
   signal rts_col_i             : std_logic;
   signal rtc_i                 : std_logic;
   signal row_cmd_wr_i          : std_logic;
   signal row_addr_i            : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal req_size_r_i          : std_logic;
   signal req_row_r_i           : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal req_ras_i             : std_logic;
   signal req_periodic_rd_r_i   : std_logic;
   signal req_cas_i             : std_logic;
   signal req_bank_r_i          : std_logic_vector(BANK_WIDTH - 1 downto 0);
   signal rd_this_rank_r_i      : std_logic_vector(RANKS - 1 downto 0);
   signal rb_hit_busy_ns_i      : std_logic;
   signal ras_timer_ns_i        : std_logic_vector(RAS_TIMER_WIDTH - 1 downto 0);
   signal rank_busy_r_i         : std_logic_vector(RANKS - 1 downto 0);
   signal ordered_r_i           : std_logic;
   signal ordered_issued_i      : std_logic;
   signal op_exit_req_i         : std_logic;
   signal end_rtp_i             : std_logic;
   signal demand_priority_i     : std_logic;
   signal demand_act_priority_i : std_logic;
   signal col_rdy_wr_i          : std_logic;
   signal col_addr_i            : std_logic_vector(ROW_WIDTH - 1 downto 0);
   signal act_this_rank_r_i     : std_logic_vector(RANKS - 1 downto 0);
   signal idle_ns_i             : std_logic;
   signal req_wr_r_i            : std_logic;
   signal rd_wr_r_i             : std_logic;
   signal bm_end_i              : std_logic;
   signal idle_r_i              : std_logic;
   signal head_r_i              : std_logic;
   signal req_rank_r_i          : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal rb_hit_busy_r_i       : std_logic;
   signal passing_open_bank_i   : std_logic;
   signal maint_hit_i           : std_logic;
   signal req_data_buf_addr_r_i : std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
begin
   -- Drive referenced outputs
   wr_this_rank_r           <= wr_this_rank_r_i;
   start_rcd                <= start_rcd_i;
   start_pre_wait           <= start_pre_wait_i;
   rts_row                  <= rts_row_i;
   rts_col                  <= rts_col_i;
   rtc                      <= rtc_i;
   row_cmd_wr               <= row_cmd_wr_i;
   row_addr                 <= row_addr_i;
   req_size_r               <= req_size_r_i;
   req_row_r                <= req_row_r_i;
   req_ras                  <= req_ras_i;
   req_periodic_rd_r        <= req_periodic_rd_r_i;
   req_cas                  <= req_cas_i;
   req_bank_r               <= req_bank_r_i;
   rd_this_rank_r           <= rd_this_rank_r_i;
   rb_hit_busy_ns           <= rb_hit_busy_ns_i;
   ras_timer_ns             <= ras_timer_ns_i;
   rank_busy_r              <= rank_busy_r_i;
   ordered_r                <= ordered_r_i;
   ordered_issued           <= ordered_issued_i;
   op_exit_req              <= op_exit_req_i;
   end_rtp                  <= end_rtp_i;
   demand_priority          <= demand_priority_i;
   demand_act_priority      <= demand_act_priority_i;
   col_rdy_wr               <= col_rdy_wr_i;
   col_addr                 <= col_addr_i;
   act_this_rank_r          <= act_this_rank_r_i;
   idle_ns                  <= idle_ns_i;
   req_wr_r                 <= req_wr_r_i;
   rd_wr_r                  <= rd_wr_r_i;
   bm_end                   <= bm_end_i;
   idle_r                   <= idle_r_i;
   head_r                   <= head_r_i;
   req_rank_r               <= req_rank_r_i;
   rb_hit_busy_r            <= rb_hit_busy_r_i;
   passing_open_bank        <= passing_open_bank_i;
   maint_hit                <= maint_hit_i;
   req_data_buf_addr_r      <= req_data_buf_addr_r_i;
   
   bank_compare0 : bank_compare
      generic map (
                   BANK_WIDTH           => BANK_WIDTH,
                   TCQ                  => TCQ,
                   BURST_MODE           => BURST_MODE,
                   COL_WIDTH            => COL_WIDTH,
                   DATA_BUF_ADDR_WIDTH  => DATA_BUF_ADDR_WIDTH,
                   ECC                  => ECC,
                   RANK_WIDTH           => RANK_WIDTH,
                   RANKS                => RANKS,
                   ROW_WIDTH            => ROW_WIDTH
                  )
      port map (
                -- Outputs
                req_data_buf_addr_r  => req_data_buf_addr_r_i(DATA_BUF_ADDR_WIDTH - 1 downto 0),
                req_periodic_rd_r    => req_periodic_rd_r_i,
                req_size_r           => req_size_r_i,
                rd_wr_r              => rd_wr_r_i,
                req_rank_r           => req_rank_r_i(RANK_WIDTH - 1 downto 0),
                req_bank_r           => req_bank_r_i(BANK_WIDTH - 1 downto 0),
                req_row_r            => req_row_r_i(ROW_WIDTH - 1 downto 0),
                req_wr_r             => req_wr_r_i,
                req_priority_r       => req_priority_r,
                rb_hit_busy_r        => rb_hit_busy_r_i,
                rb_hit_busy_ns       => rb_hit_busy_ns_i,
                row_hit_r            => row_hit_r,
                maint_hit            => maint_hit_i,
                col_addr             => col_addr_i(ROW_WIDTH - 1 downto 0),
                req_ras              => req_ras_i,
                req_cas              => req_cas_i,
                row_cmd_wr           => row_cmd_wr_i,
                row_addr             => row_addr_i(ROW_WIDTH - 1 downto 0),
                rank_busy_r          => rank_busy_r_i(RANKS - 1 downto 0),
                -- Inputs
                clk                  => clk,
                idle_ns              => idle_ns_i,
                idle_r               => idle_r_i,
                data_buf_addr        => data_buf_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
                periodic_rd_insert   => periodic_rd_insert,
                size                 => size,
                cmd                  => cmd(2 downto 0),
                sending_col          => sending_col,
                rank                 => rank(RANK_WIDTH - 1 downto 0),
                periodic_rd_rank_r   => periodic_rd_rank_r(RANK_WIDTH - 1 downto 0),
                bank                 => bank(BANK_WIDTH - 1 downto 0),
                row                  => row(ROW_WIDTH - 1 downto 0),
                col                  => col(COL_WIDTH - 1 downto 0),
                hi_priority          => hi_priority,
                maint_rank_r         => maint_rank_r(RANK_WIDTH - 1 downto 0),
                maint_zq_r           => maint_zq_r,
                auto_pre_r           => auto_pre_r,
                rd_half_rmw          => rd_half_rmw,
                act_wait_r           => act_wait_r
               );
   
   bank_state0 :  bank_state
      generic map (
                   TCQ                  => TCQ,
                   ADDR_CMD_MODE        => ADDR_CMD_MODE,
                   BM_CNT_WIDTH         => BM_CNT_WIDTH,
                   BURST_MODE           => BURST_MODE,
                   CWL                  => CWL,
                   DATA_BUF_ADDR_WIDTH  => DATA_BUF_ADDR_WIDTH,
                   DRAM_TYPE            => DRAM_TYPE,
                   ECC                  => ECC,
                   ID                   => ID,
                   NBANK_MACHS          => nBANK_MACHS,
                   NCK_PER_CLK          => nCK_PER_CLK,
                   NCNFG2RD_EN          => nCNFG2RD_EN,
                   NCNFG2WR             => nCNFG2WR,
                   NOP_WAIT             => nOP_WAIT,
                   NRAS_CLKS            => nRAS_CLKS,
                   NRP                  => nRP,
                   NRTP                 => nRTP,
                   NRCD                 => nRCD,
                   NWTP_CLKS            => nWTP_CLKS,
                   ORDERING             => ORDERING,
                   RANKS                => RANKS,
                   RANK_WIDTH           => RANK_WIDTH,
                   RAS_TIMER_WIDTH      => RAS_TIMER_WIDTH,
                   STARVE_LIMIT         => STARVE_LIMIT
                  )
      port map (
                -- Outputs
                start_rcd               => start_rcd_i,
                act_wait_r              => act_wait_r,
                ras_timer_ns            => ras_timer_ns_i(RAS_TIMER_WIDTH - 1 downto 0),
                end_rtp                 => end_rtp_i,
                bank_wait_in_progress   => bank_wait_in_progress,
                start_pre_wait          => start_pre_wait_i,
                op_exit_req             => op_exit_req_i,
                pre_wait_r              => pre_wait_r,
                allow_auto_pre          => allow_auto_pre,
                precharge_bm_end        => precharge_bm_end,
                demand_act_priority     => demand_act_priority_i,
                rts_row                 => rts_row_i,
                act_this_rank_r         => act_this_rank_r_i(RANKS - 1 downto 0),
                demand_priority         => demand_priority_i,
                rtc                     => rtc_i,
                col_rdy_wr              => col_rdy_wr_i,
                rts_col                 => rts_col_i,
                wr_this_rank_r          => wr_this_rank_r_i(RANKS - 1 downto 0),
                rd_this_rank_r          => rd_this_rank_r_i(RANKS - 1 downto 0),
                rd_half_rmw             => rd_half_rmw,
                -- Inputs
                clk                     => clk,
                rst                     => rst,
                bm_end                  => bm_end_i,
                pass_open_bank_r        => pass_open_bank_r,
                sending_row             => sending_row,
                rcv_open_bank           => rcv_open_bank,
                sending_col             => sending_col,
                rd_wr_r                 => rd_wr_r_i,
                req_wr_r                => req_wr_r_i,
                rd_data_addr            => rd_data_addr(DATA_BUF_ADDR_WIDTH - 1 downto 0),
                req_data_buf_addr_r     => req_data_buf_addr_r_i(DATA_BUF_ADDR_WIDTH - 1 downto 0),
                dfi_rddata_valid        => dfi_rddata_valid,
                rd_rmw                  => rd_rmw,
                ras_timer_ns_in         => ras_timer_ns_in((2 * (RAS_TIMER_WIDTH * nBANK_MACHS)) - 1 downto 0),
                rb_hit_busies_r         => rb_hit_busies_r((nBANK_MACHS * 2) - 1 downto 0),
                idle_r                  => idle_r_i,
                passing_open_bank       => passing_open_bank_i,
                low_idle_cnt_r          => low_idle_cnt_r,
                op_exit_grant           => op_exit_grant,
                tail_r                  => tail_r,
                auto_pre_r              => auto_pre_r,
                pass_open_bank_ns       => pass_open_bank_ns,
                req_rank_r              => req_rank_r_i(RANK_WIDTH - 1 downto 0),
                req_rank_r_in           => req_rank_r_in((RANK_WIDTH * nBANK_MACHS * 2) - 1 downto 0),
                start_rcd_in            => start_rcd_in((nBANK_MACHS * 2) - 1 downto 0),
                inhbt_act_faw_r         => inhbt_act_faw_r(RANKS - 1 downto 0),
                wait_for_maint_r        => wait_for_maint_r,
                head_r                  => head_r_i,
                sent_row                => sent_row,
                demand_act_priority_in  => demand_act_priority_in((nBANK_MACHS * 2) - 1 downto 0),
                order_q_zero            => order_q_zero,
                sent_col                => sent_col,
                q_has_rd                => q_has_rd,
                q_has_priority          => q_has_priority,
                req_priority_r          => req_priority_r,
                idle_ns                 => idle_ns_i,
                demand_priority_in      => demand_priority_in((nBANK_MACHS * 2) - 1 downto 0),
                io_config_strobe        => io_config_strobe,
                io_config_valid_r       => io_config_valid_r,
                io_config               => io_config(RANK_WIDTH downto 0),
                wtr_inhbt_config_r      => wtr_inhbt_config_r(RANKS - 1 downto 0),
                inhbt_rd_config         => inhbt_rd_config,
                inhbt_wr_config         => inhbt_wr_config,
                inhbt_rd_r              => inhbt_rd_r(RANKS - 1 downto 0),
                dq_busy_data            => dq_busy_data
               );
   
   bank_queue0 :  bank_queue
      generic map (
                   TCQ           => TCQ,
                   BM_CNT_WIDTH  => BM_CNT_WIDTH,
                   NBANK_MACHS   => nBANK_MACHS,
                   ORDERING      => ORDERING,
                   ID            => ID
                  )
      port map (
                -- Outputs
                head_r                 => head_r_i,
                tail_r                 => tail_r,
                idle_ns                => idle_ns_i,
                idle_r                 => idle_r_i,
                pass_open_bank_ns      => pass_open_bank_ns,
                pass_open_bank_r       => pass_open_bank_r,
                auto_pre_r             => auto_pre_r,
                bm_end                 => bm_end_i,
                passing_open_bank      => passing_open_bank_i,
                ordered_issued         => ordered_issued_i,
                ordered_r              => ordered_r_i,
                order_q_zero           => order_q_zero,
                rcv_open_bank          => rcv_open_bank,
                rb_hit_busies_r        => rb_hit_busies_r(nBANK_MACHS * 2 - 1 downto 0),
                q_has_rd               => q_has_rd,
                q_has_priority         => q_has_priority,
                wait_for_maint_r       => wait_for_maint_r,
                -- Inputs
                clk                    => clk,
                rst                    => rst,
                accept_internal_r      => accept_internal_r,
                use_addr               => use_addr,
                periodic_rd_ack_r      => periodic_rd_ack_r,
                bm_end_in              => bm_end_in((nBANK_MACHS * 2) - 1 downto 0),
                idle_cnt               => idle_cnt(BM_CNT_WIDTH - 1 downto 0),
                rb_hit_busy_cnt        => rb_hit_busy_cnt(BM_CNT_WIDTH - 1 downto 0),
                accept_req             => accept_req,
                rb_hit_busy_r          => rb_hit_busy_r_i,
                maint_idle             => maint_idle,
                maint_hit              => maint_hit_i,
                row_hit_r              => row_hit_r,
                pre_wait_r             => pre_wait_r,
                allow_auto_pre         => allow_auto_pre,
                sending_col            => sending_col,
                req_wr_r               => req_wr_r_i,
                rd_wr_r                => rd_wr_r_i,
                bank_wait_in_progress  => bank_wait_in_progress,
                precharge_bm_end       => precharge_bm_end,
                adv_order_q            => adv_order_q,
                order_cnt              => order_cnt(BM_CNT_WIDTH - 1 downto 0),
                rb_hit_busy_ns_in      => rb_hit_busy_ns_in((nBANK_MACHS * 2) - 1 downto 0),
                passing_open_bank_in   => passing_open_bank_in((nBANK_MACHS * 2) - 1 downto 0),
                was_wr                 => was_wr,
                maint_req_r            => maint_req_r,
                was_priority           => was_priority
               );
   
end architecture trans;

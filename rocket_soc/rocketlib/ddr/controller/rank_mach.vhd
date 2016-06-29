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
--  /   /         Filename              : rank_mach.vhd
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


-- Top level rank machine structural block.  This block
-- instantiates a configurable number of rank controller blocks.

entity rank_mach is
   generic (
      BURST_MODE                 : string := "8";
      CS_WIDTH                   : integer := 4;
      DRAM_TYPE                  : string := "DDR3";
      MAINT_PRESCALER_DIV        : integer := 40;
      nBANK_MACHS                : integer := 4;
      nCK_PER_CLK                : integer := 2;
      CL                         : integer := 5;
      nFAW                       : integer := 30;
      nREFRESH_BANK              : integer := 8;
      nRRD                       : integer := 4;
      nWTR                       : integer := 4;
      PERIODIC_RD_TIMER_DIV      : integer := 20;
      RANK_BM_BV_WIDTH           : integer := 16;
      RANK_WIDTH                 : integer := 2;
      RANKS                      : integer := 4;
      PHASE_DETECT               : string := "OFF"; --Added to control periodic reads
      REFRESH_TIMER_DIV          : integer := 39;
      ZQ_TIMER_DIV               : integer := 640000
   );
   port (
      -- Outputs
      -- Inputs
      
      -- Beginning of automatic inputs (from unused autoinst inputs)
      -- To rank_cntrl0 of rank_cntrl.v
      -- To rank_cntrl0 of rank_cntrl.v
      -- To rank_cntrl0 of rank_cntrl.v
      -- To rank_common0 of rank_common.v
      -- To rank_cntrl0 of rank_cntrl.v, ...
      -- To rank_cntrl0 of rank_cntrl.v, ...
      -- To rank_cntrl0 of rank_cntrl.v, ...
      -- To rank_common0 of rank_common.v
      -- To rank_common0 of rank_common.v
      -- To rank_cntrl0 of rank_cntrl.v
      -- To rank_cntrl0 of rank_cntrl.v
      -- To rank_cntrl0 of rank_cntrl.v, ...
      -- To rank_cntrl0 of rank_cntrl.v
      -- To rank_cntrl0 of rank_cntrl.v
      -- To rank_common0 of rank_common.v
      -- To rank_common0 of rank_common.v
      -- To rank_cntrl0 of rank_cntrl.v
      -- End of automatics
      
      -- Beginning of automatic outputs (from unused autoinst outputs)
      -- From rank_common0 of rank_common.v
      -- From rank_common0 of rank_common.v
      periodic_rd_rank_r         : out std_logic_vector(RANK_WIDTH - 1 downto 0);               -- From rank_common0 of rank_common.v
      periodic_rd_r              : out std_logic;
      maint_req_r                : out std_logic;
      -- End of automatics
      
      -- Beginning of automatic wires (for undeclared instantiated-module outputs)
      -- From rank_common0 of rank_common.v
      -- From rank_common0 of rank_common.v
      -- End of automatics
      
      inhbt_act_faw_r            : out std_logic_vector(RANKS - 1 downto 0);
      inhbt_rd_r                 : out std_logic_vector(RANKS - 1 downto 0);
      wtr_inhbt_config_r         : out std_logic_vector(RANKS - 1 downto 0);
      maint_rank_r               : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      maint_zq_r                 : out std_logic;
      wr_this_rank_r             : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
      slot_1_present             : in std_logic_vector(7 downto 0);
      slot_0_present             : in std_logic_vector(7 downto 0);
      sending_row                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      sending_col                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rst                        : in std_logic;
      rd_this_rank_r             : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
      rank_busy_r                : in std_logic_vector((RANKS * nBANK_MACHS) - 1 downto 0);
      periodic_rd_ack_r          : in std_logic;
      maint_wip_r                : in std_logic;
      insert_maint_r1            : in std_logic;
      dfi_init_complete          : in std_logic;
      clk                        : in std_logic;
      app_zq_req                 : in std_logic;
      app_ref_req                : in std_logic;
      app_periodic_rd_req        : in std_logic;
      act_this_rank_r            : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0)
   );
end entity rank_mach;

architecture trans of rank_mach is
   component rank_cntrl is
      generic (
         TCQ                        : integer := 100;
         BURST_MODE                 : string := "8";
         ID                         : integer := 0;
         nBANK_MACHS                : integer := 4;
         nCK_PER_CLK                : integer := 2;
         CL                         : integer := 5;
         nFAW                       : integer := 30;
         nREFRESH_BANK              : integer := 8;
         nRRD                       : integer := 4;
         nWTR                       : integer := 4;
         PERIODIC_RD_TIMER_DIV      : integer := 20;
         RANK_BM_BV_WIDTH           : integer := 16;
         RANK_WIDTH                 : integer := 2;
         RANKS                      : integer := 4;
         PHASE_DETECT               : string := "OFF";
         REFRESH_TIMER_DIV          : integer := 39
      );
      port (
         inhbt_act_faw_r            : out std_logic;
         inhbt_rd_r                 : out std_logic;
         wtr_inhbt_config_r         : out std_logic;
         refresh_request            : out std_logic;
         periodic_rd_request        : out std_logic;
         clk                        : in std_logic;
         rst                        : in std_logic;
         sending_row                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
         act_this_rank_r            : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
         sending_col                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
         wr_this_rank_r             : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0);
         app_ref_req                : in std_logic;
         dfi_init_complete          : in std_logic;
         rank_busy_r                : in std_logic_vector((RANKS * nBANK_MACHS) - 1 downto 0);
         refresh_tick               : in std_logic;
         insert_maint_r1            : in std_logic;
         maint_zq_r                 : in std_logic;
         maint_rank_r               : in std_logic_vector(RANK_WIDTH - 1 downto 0);
         app_periodic_rd_req        : in std_logic;
         maint_prescaler_tick_r     : in std_logic;
         clear_periodic_rd_request  : in std_logic;
         rd_this_rank_r             : in std_logic_vector(RANK_BM_BV_WIDTH - 1 downto 0)
      );
   end component;
   
   component rank_common is
      generic (
         TCQ                        : integer := 100;
         DRAM_TYPE                  : string := "DDR3";
         MAINT_PRESCALER_DIV        : integer := 40;
         nBANK_MACHS                : integer := 4;
         RANK_WIDTH                 : integer := 2;
         RANKS                      : integer := 4;
         REFRESH_TIMER_DIV          : integer := 39;
         ZQ_TIMER_DIV               : integer := 640000
      );
      port (
         maint_prescaler_tick_r     : out std_logic;
         refresh_tick               : out std_logic;
         maint_zq_r                 : out std_logic;
         maint_req_r                : out std_logic;
         maint_rank_r               : out std_logic_vector(RANK_WIDTH - 1 downto 0);
         clear_periodic_rd_request  : out std_logic_vector(RANKS - 1 downto 0);
         periodic_rd_r              : out std_logic;
         periodic_rd_rank_r         : out std_logic_vector(RANK_WIDTH - 1 downto 0);
         clk                        : in std_logic;
         rst                        : in std_logic;
         dfi_init_complete          : in std_logic;
         app_zq_req                 : in std_logic;
         insert_maint_r1            : in std_logic;
         refresh_request            : in std_logic_vector(RANKS - 1 downto 0);
         maint_wip_r                : in std_logic;
         slot_0_present             : in std_logic_vector(7 downto 0);
         slot_1_present             : in std_logic_vector(7 downto 0);
         periodic_rd_request        : in std_logic_vector(RANKS - 1 downto 0);
         periodic_rd_ack_r          : in std_logic
      );
   end component;
   
   signal maint_prescaler_tick_r     : std_logic;
   signal refresh_tick               : std_logic;
   
   signal refresh_request            : std_logic_vector(RANKS - 1 downto 0);
   signal periodic_rd_request        : std_logic_vector(RANKS - 1 downto 0);
   signal clear_periodic_rd_request  : std_logic_vector(RANKS - 1 downto 0);
   
   -- Declare intermediate signals for referenced outputs
   signal periodic_rd_rank_r_int6    : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal periodic_rd_r_int5         : std_logic;
   signal maint_req_r_int3           : std_logic;
   signal inhbt_act_faw_r_int0       : std_logic_vector(RANKS - 1 downto 0);
   signal inhbt_rd_r_int1            : std_logic_vector(RANKS - 1 downto 0);
   signal wtr_inhbt_config_r_int7    : std_logic_vector(RANKS - 1 downto 0);
   signal maint_rank_r_int2          : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal maint_zq_r_int4            : std_logic;
begin
   -- Drive referenced outputs
   periodic_rd_rank_r <= periodic_rd_rank_r_int6;
   periodic_rd_r <= periodic_rd_r_int5;
   maint_req_r <= maint_req_r_int3;
   inhbt_act_faw_r <= inhbt_act_faw_r_int0;
   inhbt_rd_r <= inhbt_rd_r_int1;
   wtr_inhbt_config_r <= wtr_inhbt_config_r_int7;
   maint_rank_r <= maint_rank_r_int2;
   maint_zq_r <= maint_zq_r_int4;
   
   rank_cntrl_inst : for ID in 0 to  RANKS - 1 generate
      -- Parameters
      
      
      rank_cntrl0 : rank_cntrl
         generic map (
            BURST_MODE             => BURST_MODE,
            ID                     => ID,
            nBANK_MACHS            => nBANK_MACHS,
            nCK_PER_CLK            => nCK_PER_CLK,
            CL                     => CL,
            nFAW                   => nFAW,
            nREFRESH_BANK          => nREFRESH_BANK,
            nRRD                   => nRRD,
            nWTR                   => nWTR,
            PERIODIC_RD_TIMER_DIV  => PERIODIC_RD_TIMER_DIV,
            RANK_BM_BV_WIDTH       => RANK_BM_BV_WIDTH,
            RANK_WIDTH             => RANK_WIDTH,
            RANKS                  => RANKS,
            PHASE_DETECT           => PHASE_DETECT,
            REFRESH_TIMER_DIV      => REFRESH_TIMER_DIV
         )
         port map (
            clear_periodic_rd_request  => clear_periodic_rd_request(ID),
            inhbt_act_faw_r            => inhbt_act_faw_r_int0(ID),
            inhbt_rd_r                 => inhbt_rd_r_int1(ID),
            periodic_rd_request        => periodic_rd_request(ID),
            refresh_request            => refresh_request(ID),
            wtr_inhbt_config_r         => wtr_inhbt_config_r_int7(ID),
            -- Inputs
            clk                        => clk,
            rst                        => rst,
            sending_row                => sending_row(nBANK_MACHS - 1 downto 0),
            act_this_rank_r            => act_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0),
            sending_col                => sending_col(nBANK_MACHS - 1 downto 0),
            wr_this_rank_r             => wr_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0),
            app_ref_req                => app_ref_req,
            dfi_init_complete          => dfi_init_complete,
            rank_busy_r                => rank_busy_r((RANKS * nBANK_MACHS) - 1 downto 0),
            refresh_tick               => refresh_tick,
            insert_maint_r1            => insert_maint_r1,
            maint_zq_r                 => maint_zq_r_int4,
            maint_rank_r               => maint_rank_r_int2(RANK_WIDTH - 1 downto 0),
            app_periodic_rd_req        => app_periodic_rd_req,
            maint_prescaler_tick_r     => maint_prescaler_tick_r,
            rd_this_rank_r             => rd_this_rank_r(RANK_BM_BV_WIDTH - 1 downto 0)
         );
   end generate;
   
   -- Parameters
   
   
   rank_common0 : rank_common
      generic map (
         DRAM_TYPE            => DRAM_TYPE,
         MAINT_PRESCALER_DIV  => MAINT_PRESCALER_DIV,
         nBANK_MACHS          => nBANK_MACHS,
         RANK_WIDTH           => RANK_WIDTH,
         RANKS                => RANKS,
         REFRESH_TIMER_DIV    => REFRESH_TIMER_DIV,
         ZQ_TIMER_DIV         => ZQ_TIMER_DIV
      )
      port map (
         clear_periodic_rd_request  => clear_periodic_rd_request(RANKS - 1 downto 0),
         -- Outputs
         maint_prescaler_tick_r     => maint_prescaler_tick_r,
         refresh_tick               => refresh_tick,
         maint_zq_r                 => maint_zq_r_int4,
         maint_req_r                => maint_req_r_int3,
         maint_rank_r               => maint_rank_r_int2(RANK_WIDTH - 1 downto 0),
         periodic_rd_r              => periodic_rd_r_int5,
         periodic_rd_rank_r         => periodic_rd_rank_r_int6(RANK_WIDTH - 1 downto 0),
         -- Inputs
         clk                        => clk,
         rst                        => rst,
         dfi_init_complete          => dfi_init_complete,
         app_zq_req                 => app_zq_req,
         insert_maint_r1            => insert_maint_r1,
         refresh_request            => refresh_request(RANKS - 1 downto 0),
         maint_wip_r                => maint_wip_r,
         slot_0_present             => slot_0_present(7 downto 0),
         slot_1_present             => slot_1_present(7 downto 0),
         periodic_rd_request        => periodic_rd_request(RANKS - 1 downto 0),
         periodic_rd_ack_r          => periodic_rd_ack_r
      );
   
end architecture trans;




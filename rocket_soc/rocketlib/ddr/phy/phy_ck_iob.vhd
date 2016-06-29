--*****************************************************************************
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
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
-- /___/  \  /    Vendor: Xilinx
-- \   \   \/     Version: 3.92
--  \   \         Application: MIG
--  /   /         Filename: phy_ck_iob.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--     Clock forwarding to memory 
--Reference:
--Revision History:
--*****************************************************************************
--
--******************************************************************************
--**$Id: phy_ck_iob.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_ck_iob.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_ck_iob is
   generic (
      TCQ             : integer := 100;			-- clk->out delay (sim only)
      WRLVL           : string  := "OFF";		-- Enable write leveling
      DRAM_TYPE       : string  := "DDR3";		-- Memory I/F type: "DDR3", "DDR2"
      REFCLK_FREQ     : real    := 300.0;		-- IODELAY Reference Clock freq (MHz)
      IODELAY_GRP     : string  := "IODELAY_MIG" 	-- May be assigned unique name when mult IP cores in design
   );
   port (
      clk_mem         : in std_logic;  -- full rate core clock
      clk             : in std_logic;  -- half rate core clock
      rst             : in std_logic;  -- half rate core clk reset
      ddr_ck_p        : out std_logic; -- forwarded diff. clock to memory
      ddr_ck_n        : out std_logic  -- forwarded diff. clock to memory
   );
end phy_ck_iob;

architecture trans of phy_ck_iob is

   signal ck_p_odelay     : std_logic;
   signal ck_p_oq         : std_logic;
   signal ck_p_out        : std_logic;

   attribute IODELAY_GROUP : string;

begin

   --*****************************************************************
   -- Note on generation of Control/Address signals - there are
   -- several possible configurations that affect the configuration
   -- of the OSERDES and possible ODELAY for each output (this will
   -- also affect the CK/CK# outputs as well
   --   1. DDR3, write-leveling: This is the simplest case. Use
   --      OSERDES without the ODELAY. Initially clock/control/address
   --      will be offset coming out of FPGA from DQ/DQS, but DQ/DQS
   --      will be adjusted so that DQS-CK alignment is established
   --   2. DDR2 or DDR3 (no write-leveling): Both DQS and DQ will use 
   --      ODELAY to delay output of OSERDES. To match this, 
   --      CK/control/address must also delay their outputs using ODELAY 
   --      (with delay = 0)
   --*****************************************************************
   
   u_obuf_ck : OBUFDS
      port map (
         o    => ddr_ck_p,
         ob   => ddr_ck_n,
         i    => ck_p_out
      );
   
   u_oserdes_ck_p : OSERDESE1
      generic map (
         data_rate_oq    => "DDR",
         data_rate_tq    => "BUF",
         data_width      => 4,
         ddr3_data       => 0,
         init_oq         => '0',
         init_tq         => '0',
         interface_type  => "DEFAULT",
         odelay_used     => 0,
         serdes_mode     => "MASTER",
         srval_oq        => '0',
         srval_tq        => '0',
         tristate_width  => 1
      )
      port map (
         ocbextend     => open,
         ofb           => open,
         oq            => ck_p_oq,
         shiftout1     => open,
         shiftout2     => open,
         tq            => open,
         clk           => clk_mem,
         clkdiv        => clk,
         clkperf       => 'Z',
         clkperfdelay  => 'Z',
         d1            => '0',
         d2            => '1',
         d3            => '0',
         d4            => '1',
         d5            => 'Z',
         d6            => 'Z',
         odv           => '0',
         oce           => '1',
         rst           => rst,
         -- Connect SHIFTIN1, SHIFTIN2 to 0 for simulation purposes
         -- (for all other OSERDES used in design, these are no-connects):
         -- ensures that CK/CK# outputs are not X at start of simulation
         -- Certain DDR2 memory models may require that CK/CK# be valid
         -- throughout simulation
         shiftin1      => '0',
         shiftin2      => '0',
         t1            => '0',
         t2            => '0',
         t3            => '0',
         t4            => '0',
         tfb           => open,
         tce           => '1',               
         wc            => '0'
      );   
      
   gen_ck_wrlvl:  if ((DRAM_TYPE = "DDR3") and (WRLVL = "ON")) generate

      --*******************************************************
      -- CASE1: DDR3, write-leveling
      --*******************************************************
      ck_p_out <= ck_p_oq;    

   end generate;                                       

   gen_ck_nowrlvl : if ( not(DRAM_TYPE = "DDR3") or not(WRLVL = "ON")) generate
     attribute IODELAY_GROUP of  u_iodelay_ck_p : label is IODELAY_GRP;
      --*******************************************************
      -- CASE2: No write leveling (DDR2 or DDR3) 
      --*******************************************************                 
   begin  
      ck_p_out <= ck_p_odelay;
      
      u_iodelay_ck_p : IODELAYE1
         generic map (
            cinvctrl_sel           => FALSE,
            delay_src              => "O",
            high_performance_mode  => TRUE,
            idelay_type            => "FIXED",
            idelay_value           => 0,
            odelay_type            => "FIXED",
            odelay_value           => 0,
            refclk_frequency       => REFCLK_FREQ,
            signal_pattern         => "CLOCK"
         )
         port map (
            dataout      => ck_p_odelay,
            c            => '0',
            ce           => '0',
            datain       => 'Z',
            idatain      => 'Z',
            inc          => '0',
            odatain      => ck_p_oq,
            rst          => '0',
            t            => 'Z',
            cntvaluein   => "ZZZZZ",
            cntvalueout  => open,
            clkin        => 'Z',
            cinvctrl     => '0'
         );
   end generate;
      
end trans;



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
--  /   /         Filename: phy_clock_io.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--  Top-level for CK/CK# clock forwarding to memory
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_clock_io.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_clock_io.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;


entity phy_clock_io is
   generic (
      TCQ             : integer := 100;			-- clk->out delay (sim only)
      CK_WIDTH        : integer := 2;			-- # of clock output pairs
      WRLVL           : string  := "OFF";		-- Enable write leveling
      DRAM_TYPE       : string  := "DDR3";		-- Memory I/F type: "DDR3", "DDR2"
      REFCLK_FREQ     : real    := 300.0;		-- IODELAY Reference Clock freq (MHz)
      IODELAY_GRP     : string  := "IODELAY_MIG"	-- May be assigned unique name
      							-- when mult IP cores in design
   );
   port (
      clk_mem         : in std_logic;					-- full rate core clock
      clk             : in std_logic;					-- half rate core clock
      rst             : in std_logic;					-- half rate core clk reset
      ddr_ck_p        : out std_logic_vector(CK_WIDTH - 1 downto 0);	-- forwarded diff. clock to memory
      ddr_ck_n        : out std_logic_vector(CK_WIDTH - 1 downto 0)	-- forwarded diff. clock to memory
   );
end entity phy_clock_io;

architecture trans of phy_clock_io is

   component phy_ck_iob is
      generic (
         TCQ             : integer := 100;		-- clk->out delay (sim only)
         WRLVL           : string  := "OFF";		-- Enable write leveling
         DRAM_TYPE       : string  := "DDR3";		-- Memory I/F type: "DDR3", "DDR2"
         REFCLK_FREQ     : real    := 300.0;		-- IODELAY Reference Clock freq (MHz)
         IODELAY_GRP     : string  := "IODELAY_MIG" 	-- May be assigned unique name when mult IP cores in design
      );
      port (
         clk_mem         : in std_logic;  		-- full rate core clock
         clk             : in std_logic;  		-- half rate core clock
         rst             : in std_logic;  		-- half rate core clk reset
         ddr_ck_p        : out std_logic; 		-- forwarded diff. clock to memory
         ddr_ck_n        : out std_logic  		-- forwarded diff. clock to memory
      );
   end component;

begin
	  
   gen_ck : for ck_i in 0 to  (CK_WIDTH-1) generate
      u_phy_ck_iob : phy_ck_iob
         generic map (
            TCQ             => TCQ,
            WRLVL           => WRLVL,
            DRAM_TYPE       => DRAM_TYPE,
            REFCLK_FREQ     => REFCLK_FREQ,
            IODELAY_GRP     => IODELAY_GRP
         )
         port map (
            clk_mem    => clk_mem,
            clk        => clk,
            rst        => rst,
            ddr_ck_p   => ddr_ck_p(ck_i),
            ddr_ck_n   => ddr_ck_n(ck_i)
         );
   end generate;
   
end architecture trans;



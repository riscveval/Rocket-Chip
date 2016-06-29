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
--  /   /         Filename: phy_rdctrl_sync.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Mon Jun 30 2008 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Synchronization of read control signal from MC/PHY rdlvl logic (clk) to
--   read capture logic (clk_rsync) clock domain. Also adds additional delay
--   to account for read latency
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_rdctrl_sync.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_rdctrl_sync.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_rdctrl_sync is
   generic (
      TCQ                   : integer := 100
   );
   port (
      clk                   : in std_logic;
      rst_rsync             : in std_logic;	-- Use only CLK_RSYNC[0] reset
      -- Control for control sync logic
      mc_data_sel           : in std_logic;
      rd_active_dly         : in std_logic_vector(4 downto 0);
      -- DFI signals from MC/PHY rdlvl logic
      dfi_rddata_en         : in std_logic;
      phy_rddata_en         : in std_logic;
      -- Control for read logic, initialization logic
      dfi_rddata_valid      : out std_logic;
      dfi_rddata_valid_phy  : out std_logic;
      rdpath_rdy            : out std_logic   -- asserted when read path
                                              -- ready for use
   );
end phy_rdctrl_sync;

architecture trans of phy_rdctrl_sync is

      -- # of clock cycles after RST_RSYNC has deasserted before init/cal logic
      -- is taken out of reset. This is only needed for simulation when the "no
      -- init/no cal" option is selected. In this case, PHY_INIT will assert
      -- DFI_INIT_COMPLETE signal almost instantaneously once it is taken out
      -- of reset - however, there are certain pipe stages that must "flush
      -- out" (related to circular buffer synchronization) for a few cycles after
      -- RST_RSYNC is deasserted - in particular, the one related to generating
      -- DFI_RDDATA_VALID must not drive an unknown value on the bus after
      -- DFI_INIT_COMPLETE is asserted.
      -- NOTE: # of cycles of delay required depends on the circular buffer
      --  depth for RD_ACTIVE - it should >= (0.5*depth + 1)
   constant RDPATH_RDY_DLY  : integer := 10;
   
   signal rddata_en         : std_logic;
   signal rddata_en_rsync   : std_logic;
   signal rddata_en_srl_out : std_logic;
   signal rdpath_rdy_dly_r  : std_logic_vector(RDPATH_RDY_DLY-1 downto 0);

begin
   
   --***************************************************************************
   -- Delay RDDATA_EN by an amount determined during read-leveling
   -- calibration to reflect the round trip delay from command issuance until
   -- when read data is returned
   --***************************************************************************
   rddata_en <= dfi_rddata_en when (mc_data_sel = '1') else
                phy_rddata_en;
   
   -- May need to flop output of SRL for better timing
   u_rddata_en_srl : SRLC32E
      port map (
         Q    => rddata_en_srl_out,
         Q31  => open,
         A    => rd_active_dly,
         CE   => '1',
         CLK  => clk,
         D    => rddata_en
      );
   
   -- Flop once more for better timing
   process (clk)
   begin
      if (clk'event and clk = '1') then
         -- Only assert valid on DFI bus after initialization complete            
         dfi_rddata_valid <= rddata_en_srl_out and mc_data_sel after (TCQ)*1 ps;
         -- Assert valid for PHY during initialization  
         dfi_rddata_valid_phy <= rddata_en_srl_out after (TCQ)*1 ps;
      end if;
   end process;
      
   --***************************************************************************
   -- Generate a signal that tells initialization logic that read path is
   -- ready for use (i.e. for read leveling). Use RST_RSYNC, and delay it by
   -- RDPATH_RDY_DLY clock cycles, then synchronize to CLK domain.
   -- NOTE: This logic only required for simulation; for final h/w, there will
   --   always be a long delay between RST_RSYNC deassertion and
   --   DFI_INIT_COMPLETE assertion (for DRAM init, and leveling)
   --***************************************************************************
   
   -- First delay by X number of clock cycles to guarantee that RDPATH_RDY
   -- isn't asserted too soon after RST_RSYNC is deasserted (to allow various
   -- synchronization pipe stages to "flush"). NOTE: Only RST_RSYNC[0] (or
   -- any of the up to 4 RST_RSYNC's) is used - any of them is sufficient
   -- close enough in timing to use
   process (clk, rst_rsync)
   begin
      if (rst_rsync = '1') then
         rdpath_rdy_dly_r <= (others => '0') after (TCQ)*1 ps;
      elsif (clk'event and clk = '1') then
         rdpath_rdy_dly_r((RDPATH_RDY_DLY-1) downto 1) <= (rdpath_rdy_dly_r((RDPATH_RDY_DLY-3) downto 0) & '1') after (TCQ)*1 ps;
      end if;
   end process;
      
   -- Flop once more to prevent ISE tools from analyzing asynchronous path
   -- through this flop to receiving logic
   process (clk)
   begin
      if (clk'event and clk = '1') then         
         rdpath_rdy <= rdpath_rdy_dly_r(RDPATH_RDY_DLY-1);
      end if;
   end process;
     
end trans;



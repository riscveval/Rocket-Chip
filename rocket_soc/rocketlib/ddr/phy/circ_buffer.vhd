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
-- \   \   \/     Version: %Version
--  \   \         Application: MIG
--  /   /         Filename: circ_buffer.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Mon Jun 23 2008 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--  Circular Buffer for synchronizing signals between clock domains. Assumes
--  write and read clocks are the same frequency (but can be varying phase).
--  Parameter List;
--    DATA_WIDTH:     # bits in data bus
--    BUF_DEPTH:      # of entries in circular buffer.
--  Port list:
--    rdata: read data
--    wdata: write data
--    rclk:  read clock
--    wclk:  write clock
--    rst:   reset - shared between read and write sides
--Reference:
--Revision History:
--   Rev 1.1 - Initial Checkin                                - jlogue 03/06/09
--*****************************************************************************

--******************************************************************************
--**$Id: circ_buffer.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/circ_buffer.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity circ_buffer is
   generic (
      TCQ             : integer := 100;
      BUF_DEPTH       : integer := 5;	-- valid values are 5, 6, 7, and 8		
      DATA_WIDTH      : integer := 1 		 
   );
   port (
      rdata           : out std_logic_vector(DATA_WIDTH-1 downto 0); 
      wdata           : in std_logic_vector(DATA_WIDTH-1 downto 0);  
      rclk            : in std_logic;  
      wclk            : in std_logic;  
      rst             : in std_logic
   );
end circ_buffer;

architecture trans of circ_buffer is

  --***************************************************************************
  -- Local parameters
  --***************************************************************************	
   constant SHFTR_MSB : integer :=  (BUF_DEPTH-1)/2;   

  --***************************************************************************
  -- Internal signals
  --***************************************************************************
   signal SyncResetRd		: std_logic;
   signal RdCEshftr     	: std_logic_vector(SHFTR_MSB downto 0);
   signal RdAdrsCntr     	: std_logic_vector(2 downto 0);

   signal SyncResetWt		: std_logic;
   signal WtAdrsCntr_ce		: std_logic;
   signal WtAdrsCntr     	: std_logic_vector(2 downto 0);
   signal wdata_xhdl		: std_logic_vector(DATA_WIDTH-1 downto 0);

begin

   --***************************************************************************
   -- read domain registers
   --***************************************************************************
   process (rclk, rst)
   begin
      if (rst = '1') then
   	 SyncResetRd <= '1' after TCQ*1 ps;     
      elsif (rclk'event and rclk = '1') then
   	 SyncResetRd <= '0' after TCQ*1 ps;     
      end if;
   end process;

   process (rclk, SyncResetRd)
   begin
      if (SyncResetRd = '1') then
   	 RdCEshftr  <= (others => '0') after TCQ*1 ps;     
   	 RdAdrsCntr <= (others => '0') after TCQ*1 ps;     
      elsif (rclk'event and rclk = '1') then
   	 RdCEshftr(0) <= WtAdrsCntr_ce after TCQ*1 ps;     
   	 RdCEshftr(SHFTR_MSB downto 1) <= RdCEshftr(SHFTR_MSB-1 downto 0) after TCQ*1 ps;     

	 if (RdCEshftr(SHFTR_MSB) = '1') then
	    if (RdAdrsCntr = (BUF_DEPTH-1)) then
               RdAdrsCntr <= (others => '0') after TCQ*1 ps;
            else   
               RdAdrsCntr <= (RdAdrsCntr + '1') after TCQ*1 ps;
            end if;   
         end if;   
      end if;
   end process;
  
   --***************************************************************************
   -- write domain registers
   --***************************************************************************
   process (wclk, SyncResetRd)
   begin
      if (SyncResetRd = '1') then
   	 SyncResetWt <= '1' after TCQ*1 ps;     
      elsif (wclk'event and wclk = '1') then
   	 SyncResetWt <= '0' after TCQ*1 ps;     
      end if;
   end process;

   process (wclk, SyncResetWt)
   begin
      if (SyncResetWt = '1') then
   	 WtAdrsCntr_ce <= '0' after TCQ*1 ps;     
   	 WtAdrsCntr    <= (others => '0') after TCQ*1 ps;     
      elsif (wclk'event and wclk = '1') then
   	 WtAdrsCntr_ce <= '1' after TCQ*1 ps;     

	 if (WtAdrsCntr_ce = '1') then
	    if (WtAdrsCntr = (BUF_DEPTH-1)) then
               WtAdrsCntr <= (others => '0') after TCQ*1 ps;
            else   
               WtAdrsCntr <= (WtAdrsCntr + '1') after TCQ*1 ps;
            end if;   
         end if;   
      end if;
   end process;
  
   --***************************************************************************
   -- instantiate one RAM64X1D for each data bit
   --***************************************************************************

   gen_ram: for i in 0 to (DATA_WIDTH-1) generate
 
      u_RAM64X1D: RAM64X1D
      generic map
      (
         INIT 	=> X"0000000000000000"
      )
      port map
      (
         DPO        => rdata(i),
         SPO        => open,
         A0         => WtAdrsCntr(0),
         A1         => WtAdrsCntr(1),
         A2         => WtAdrsCntr(2),
         A3         => '0',
         A4         => '0',
         A5         => '0',
         D          => wdata(i),
         DPRA0      => RdAdrsCntr(0),
         DPRA1      => RdAdrsCntr(1),
         DPRA2      => RdAdrsCntr(2),
         DPRA3      => '0',
         DPRA4      => '0',
         DPRA5      => '0',
         WCLK       => wclk,
         WE         => '1'
      );
   end generate;

end trans;

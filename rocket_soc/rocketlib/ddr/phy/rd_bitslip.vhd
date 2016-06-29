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
--  /   /         Filename: rd_bitslip.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:13 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--  Shifts and delays data from ISERDES, in both memory clock and internal
--  clock cycles. Used to uniquely shift/delay each byte to align all bytes
--  in data word
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: rd_bitslip.vhd,v 1.1 2011/06/02 07:18:13 mishra Exp $
--**$Date: 2011/06/02 07:18:13 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/rd_bitslip.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity rd_bitslip is
   generic (
      TCQ                    : integer := 100
   );
   port (
      clk              	: in std_logic;
      bitslip_cnt       : in std_logic_vector(1 downto 0);
      clkdly_cnt        : in std_logic_vector(1 downto 0);
      din               : in std_logic_vector(5 downto 0);
      qout              : out std_logic_vector(3 downto 0)
   );
end rd_bitslip;

architecture trans_rd_bitslip of rd_bitslip is
   
   signal din2_r         : std_logic;
   signal slip_out      : std_logic_vector(3 downto 0);
   signal slip_out_r    : std_logic_vector(3 downto 0);
   signal slip_out_r2   : std_logic_vector(3 downto 0);
   signal slip_out_r3   : std_logic_vector(3 downto 0);

begin
   
   --***************************************************************************
   
   process (clk)
   begin
      if (clk'event and clk = '1') then            
         din2_r <= din(2) after (TCQ)*1 ps;
      end if;
   end process;
   
   --Can shift data from ISERDES from 0-3 fast clock cycles
   --NOTE: This is coded combinationally, in order to allow register to
   --occur after MUXing of delayed outputs. Timing may be difficult to
   --meet on this logic, if necessary, the register may need to be moved
   --here instead, or another register added. 
   process (bitslip_cnt, din, din2_r)
   begin
      case bitslip_cnt is		
         when "00" => -- No slip 		
            slip_out <= (din(3) & din(2) & din(1) & din(0));
         when "01" => -- Slip = 0.5 cycle 		
            slip_out <= (din(4) & din(3) & din(2) & din(1));
         when "10" => -- Slip = 1 cycle  		
            slip_out <= (din(5) & din(4) & din(3) & din(2));
         when "11" => -- Slip = 1.5 cycle 		
            slip_out <= (din2_r & din(5) & din(4) & din(3));
	 when others =>
            null;
      end case;
   end process;
   
   --Can delay up to 3 additional internal clock cycles - this accounts
   --not only for delays due to DRAM, PCB routing between different bytes,
   --but also differences within the FPGA - e.g. clock skew between different
   --I/O columns, and differences in latency between different circular
   --buffers or whatever synchronization method (FIFO) is used to get the
   --data into the global clock domain
   process (clk)
   begin
      if (clk'event and clk = '1') then
	 slip_out_r  <= slip_out after TCQ*1 ps;
	 slip_out_r2 <= slip_out_r after TCQ*1 ps;
	 slip_out_r3 <= slip_out_r2 after TCQ*1 ps;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         case clkdly_cnt is		
            when "00" => 
               qout <= slip_out after (TCQ)*1 ps;
            when "01" => 
               qout <= slip_out_r after (TCQ)*1 ps;
            when "10" => 
               qout <= slip_out_r2 after (TCQ)*1 ps;
            when "11" => 
               qout <= slip_out_r3 after (TCQ)*1 ps;
  	    when others =>
               null;
         end case;
      end if;
   end process;

end trans_rd_bitslip;



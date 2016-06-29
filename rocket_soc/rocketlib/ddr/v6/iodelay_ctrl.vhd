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
--  /   /         Filename: iodelay_ctrl.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:11 $
-- \   \  /  \    Date Created: Wed Aug 16 2006
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   This module instantiates the IDELAYCTRL primitive, which continously
--   calibrates the IODELAY elements in the region to account for varying
--   environmental conditions. A 200MHz or 300MHz reference clock (depending
--   on the desired IODELAY tap resolution) must be supplied
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: iodelay_ctrl.vhd,v 1.1 2011/06/02 07:18:11 mishra Exp $
--**$Date: 2011/06/02 07:18:11 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/ip_top/iodelay_ctrl.vhd,v $
--******************************************************************************
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

entity iodelay_ctrl is
  generic (
    TCQ            : integer := 100;         -- clk->out delay (sim only)
    IODELAY_GRP    : string  := "IODELAY_MIG"  -- May be assigned unique name when
                                                -- multiple IP cores used in design
    );
  port (
    clk200        : in  std_logic;
    rstn          : in  std_logic;
    iodelay_ctrl_rdy : out std_logic
    );
end entity iodelay_ctrl;

architecture syn of iodelay_ctrl is
  constant RST_SYNC_NUM : integer := 15;

  signal  rst_ref        : std_logic;
  signal  rst_ref_sync_r : std_logic_vector(RST_SYNC_NUM-1 downto 0);
  signal  sys_rst_act_hi : std_logic;

  attribute syn_maxfan : integer;
  attribute IODELAY_GROUP : string;
  attribute syn_maxfan of rst_ref_sync_r : signal is 10;
  attribute IODELAY_GROUP of u_idelayctrl : label is IODELAY_GRP;

  begin

    sys_rst_act_hi <= not rstn;


  --*****************************************************************
  -- IDELAYCTRL reset
  -- This assumes an external clock signal driving the IDELAYCTRL
  -- blocks. Otherwise, if a PLL drives IDELAYCTRL, then the PLL
  -- lock signal will need to be incorporated in this.
  --*****************************************************************

  process (clk200, sys_rst_act_hi)
    begin
    if (sys_rst_act_hi = '1') then
      rst_ref_sync_r <= (others => '1') after (TCQ)*1 ps;
    elsif (clk200'event and clk200 = '1') then
      rst_ref_sync_r <= std_logic_vector(unsigned(rst_ref_sync_r) sll 1) after (TCQ)*1 ps;
    end if;
  end process;

  rst_ref  <= rst_ref_sync_r(RST_SYNC_NUM-1);

  --*****************************************************************

  u_idelayctrl : IDELAYCTRL
    port map (
     RDY    => iodelay_ctrl_rdy,
     REFCLK => clk200,
     RST    => rst_ref
     );


end architecture syn;

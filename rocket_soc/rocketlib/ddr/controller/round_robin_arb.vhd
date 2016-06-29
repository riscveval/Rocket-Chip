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
--  /   /         Filename              : round_robin_arb.vhd
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
   use ieee.numeric_std.all;
   use ieee.std_logic_arith.all;


-- A simple round robin arbiter implemented in a not so simple
-- way.  Two things make this special.  First, it takes width as
-- a parameter and secondly it's constructed in a way to work with
-- restrictions synthesis programs.
--
-- Consider each req/grant pair to be a
-- "channel".  The arbiter computes a grant response to a request
-- on a channel by channel basis.
--
-- The arbiter implementes a "round robin" algorithm.  Ie, the granting
-- process is totally fair and symmetric.  Each requester is given
-- equal priority.  If all requests are asserted, the arbiter will
-- work sequentially around the list of requesters, giving each a grant.
--
-- Grant priority is based on the "last_master".  The last_master
-- vector stores the channel receiving the most recent grant.  The
-- next higher numbered channel (wrapping around to zero) has highest
-- priority in subsequent cycles.  Relative priority wraps around
-- the request vector with the last_master channel having lowest priority.
--
-- At the highest implementation level, a per channel inhibit signal is computed.
-- This inhibit is bit-wise AND'ed with the incoming requests to
-- generate the grant.
--
-- There will be at most a single grant per state.  The logic
-- of the arbiter depends on this.
--
-- Once a grant is given, it is stored as the last_master.  The
-- last_master vector is initialized at reset to the zero'th channel.
-- Although the particular channel doesn't matter, it does matter
-- that the last_master contains a valid grant pattern.
--
-- The heavy lifting is in computing the per channel inhibit signals.
-- This is accomplished in the generate statement.
--
-- The first "for" loop in the generate statement steps through the channels.
--
-- The second "for" loop steps through the last mast_master vector
-- for each channel.  For each last_master bit, an inh_group is generated.
-- Following the end of the second "for" loop, the inh_group signals are OR'ed
-- together to generate the overall inhibit bit for the channel.
--
-- For a four bit wide arbiter, this is what's generated for channel zero:
--
--  inh_group[1] = last_master[0] && |req[3:1];  // any other req inhibits
--  inh_group[2] = last_master[1] && |req[3:2];  // req[3], or req[2] inhibit
--  inh_group[3] = last_master[2] && |req[3:3];  // only req[3] inhibits
--
-- For req[0], last_master[3] is ignored because channel zero is highest priority
-- if last_master[3] is true.
--

entity round_robin_arb is
   generic (
      TCQ              : integer := 100;
      WIDTH            : integer := 3
   );
   port (
      
      grant_ns         : out std_logic_vector(WIDTH - 1 downto 0);
      
      grant_r          : out std_logic_vector(WIDTH - 1 downto 0);
      clk              : in std_logic;
      rst              : in std_logic;
      req              : in std_logic_vector(WIDTH - 1 downto 0);
      disable_grant    : in std_logic;
      
      current_master   : in std_logic_vector(WIDTH - 1 downto 0);
      upd_last_master  : in std_logic
   );
end entity round_robin_arb;

architecture trans of round_robin_arb is

function REDUCTION_OR( A: in std_logic_vector) return std_logic is
variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp or A(i);
  end loop;
  return tmp;
end function REDUCTION_OR;

function SET_MSB ( WIDTH: integer) return std_logic_vector is
variable tmp : std_logic_vector (WIDTH - 1 downto 0):= (others => '0');
begin
    tmp(WIDTH - 1) := '1';
    return tmp;
end function SET_MSB;

   signal last_master_ns     : std_logic_vector(WIDTH - 1 downto 0);
   signal dbl_last_master_ns : std_logic_vector(WIDTH * 2 - 1 downto 0);
   signal dbl_req            : std_logic_vector(WIDTH * 2 - 1 downto 0);
   signal inhibit            : std_logic_vector(WIDTH - 1 downto 0) := (others => '0');
   signal last_master_r      : std_logic_vector(WIDTH - 1 downto 0);
   signal grant_ns_tmp       : std_logic_vector(WIDTH - 1 downto 0);
   signal dbl_req_tmp            : std_logic_vector(WIDTH - 2 downto 0);
   -- Declare intermediate signals for referenced outputs
   signal grant_ns_i        : std_logic_vector(WIDTH - 1 downto 0);
   constant  ONE            : std_logic_vector(WIDTH - 1 downto 0) := SET_MSB(WIDTH);--Changed form '1' to fix the CR #544024
                                                                                     --A '1' in the LSB of the last_master_r 
                                                                                     --signal gives a low priority to req[0]
                                                                                     --after reset. To avoid this made MSB as
                                                                                     --'1' at reset.
begin


   -- Drive referenced outputs
   grant_ns <= grant_ns_i;
   process (last_master_ns)
   begin
      dbl_last_master_ns <= (last_master_ns & last_master_ns);
   end process;
   
   process (req)
   begin
      dbl_req <= (req & req);
   end process;
   
   channel : for i in 0 to  WIDTH - 1 generate
   signal inh_group          : std_logic_vector(WIDTH - 1 downto 1);
   begin
   last_master: for j in 0 to  ((WIDTH - 1) - 1) generate
   begin
          inh_group(j + 1) <= dbl_last_master_ns(i + j) and REDUCTION_OR(dbl_req(i + WIDTH - 1 downto i + j + 1));

      end generate;

      process (inh_group)
      begin
         inhibit(i) <= REDUCTION_OR(inh_group);
      end process;
   
   end generate;
   
   process(disable_grant)
    begin
    for i in 0 to WIDTH - 1  loop
      grant_ns_tmp(i) <= not(disable_grant);
    end loop;
    
    end process;
      

   
   grant_ns_i <= req and not(inhibit) and grant_ns_tmp;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         grant_r <= grant_ns_i after (TCQ)*1 ps;
      end if;
   end process;
   
   last_master_ns <= ONE when (rst = '1') else
                     current_master when (upd_last_master = '1') else
                     last_master_r;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         
         last_master_r <= last_master_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   
end architecture trans;



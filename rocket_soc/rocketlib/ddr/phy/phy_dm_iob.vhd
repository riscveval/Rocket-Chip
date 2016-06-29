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
--  /   /         Filename: phy_dm_iob.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   This module places the data mask signals into the IOBs.
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_dm_iob.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_dm_iob.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;


entity phy_dm_iob is
   generic (
      TCQ                    : integer := 100;		-- clk->out delay (sim only)
      nCWL                   : integer := 5;		-- CAS Write Latency
      DRAM_TYPE              : string  := "DDR3";	-- Memory I/F type: "DDR3", "DDR2"
      WRLVL                  : string  := "ON";		-- "OFF" for "DDR3" component interface
      REFCLK_FREQ            : real    := 300.0;	-- IODELAY Reference Clock freq (MHz)
      IODELAY_HP_MODE        : string  := "ON";		-- IODELAY High Performance Mode
      IODELAY_GRP            : string  := "IODELAY_MIG" -- May be assigned unique name
                                                        -- when mult IP cores in design
   );
   port (
      clk_mem                : in std_logic;
      clk                    : in std_logic;
      clk_rsync              : in std_logic;
      rst                    : in std_logic;
      -- IODELAY I/F
      dlyval                 : in std_logic_vector(4 downto 0);
      dm_ce                  : in std_logic;
      inv_dqs                : in std_logic;
      wr_calib_dly           : in std_logic_vector(1 downto 0);
      mask_data_rise0        : in std_logic;
      mask_data_fall0        : in std_logic;
      mask_data_rise1        : in std_logic;
      mask_data_fall1        : in std_logic;
      ddr_dm                 : out std_logic
   );
end phy_dm_iob;

architecture trans_phy_dm_iob of phy_dm_iob is

   -- Set performance mode for IODELAY (power vs. performance tradeoff)
   function CALC_HIGH_PERF_MODE return boolean is
      begin
         if (IODELAY_HP_MODE = "OFF") then
	    return FALSE;
	 elsif (IODELAY_HP_MODE = "ON") then
	    return TRUE;
	 else
            return FALSE;
         end if;
   end function CALC_HIGH_PERF_MODE;

   constant HIGH_PERFORMANCE_MODE  : boolean := CALC_HIGH_PERF_MODE;
   signal dm_odelay                : std_logic;
   signal dm_oq                    : std_logic;
   signal mask_data_fall0_r1       : std_logic;
   signal mask_data_fall0_r2       : std_logic;
   signal mask_data_fall0_r3       : std_logic;
   signal mask_data_fall0_r4       : std_logic;
   signal mask_data_fall1_r1       : std_logic;
   signal mask_data_fall1_r2       : std_logic;
   signal mask_data_fall1_r3       : std_logic;
   signal mask_data_fall1_r4       : std_logic;
   signal mask_data_rise0_r1       : std_logic;
   signal mask_data_rise0_r2       : std_logic;
   signal mask_data_rise0_r3       : std_logic;
   signal mask_data_rise0_r4       : std_logic;
   signal mask_data_rise1_r1       : std_logic;
   signal mask_data_rise1_r2       : std_logic;
   signal mask_data_rise1_r3       : std_logic;
   signal mask_data_rise1_r4       : std_logic;
   signal out_d1                   : std_logic;
   signal out_d2                   : std_logic;
   signal out_d3                   : std_logic;
   signal out_d4                   : std_logic;
   signal xhdl1		   : std_logic_vector(2 downto 0);

   attribute IODELAY_GROUP : string;
   attribute IODELAY_GROUP of  u_odelay_dm : label is IODELAY_GRP;

begin

   -- drive xhdl1 from wr_calib_dly(1 downto 0) and inv_dqs  
   xhdl1 <= wr_calib_dly(1 downto 0) & inv_dqs;

   --***************************************************************************
   -- Data Mask Bitslip
   --***************************************************************************
   
   -- dfi_wrdata_en0 - even clk cycles channel 0
   -- dfi_wrdata_en1 - odd clk cycles channel 1
   -- tphy_wrlat set to 0 clk cycle for CWL = 5,6,7,8
   -- Valid dfi_wrdata* sent 1 clk cycle after dfi_wrdata_en* is asserted
   
   -- mask_data_rise0 - first rising edge data mask (rise0)
   -- mask_data_fall0 - first falling edge data mask (fall0)
   -- mask_data_rise1 - second rising edge data mask (rise1)
   -- mask_data_fall1 - second falling edge data mask (fall1)
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (DRAM_TYPE = "DDR3") then
            mask_data_rise0_r1 <= dm_ce and mask_data_rise0 after (TCQ)*1 ps;
            mask_data_fall0_r1 <= dm_ce and mask_data_fall0 after (TCQ)*1 ps;
            mask_data_rise1_r1 <= dm_ce and mask_data_rise1 after (TCQ)*1 ps;
            mask_data_fall1_r1 <= dm_ce and mask_data_fall1 after (TCQ)*1 ps;
         else
            mask_data_rise0_r1 <= mask_data_rise0 after (TCQ)*1 ps;
            mask_data_fall0_r1 <= mask_data_fall0 after (TCQ)*1 ps;
            mask_data_rise1_r1 <= mask_data_rise1 after (TCQ)*1 ps;
            mask_data_fall1_r1 <= mask_data_fall1 after (TCQ)*1 ps;
         end if;
         mask_data_rise0_r2 <= mask_data_rise0_r1 after (TCQ)*1 ps;
         mask_data_fall0_r2 <= mask_data_fall0_r1 after (TCQ)*1 ps;
         mask_data_rise1_r2 <= mask_data_rise1_r1 after (TCQ)*1 ps;
         mask_data_fall1_r2 <= mask_data_fall1_r1 after (TCQ)*1 ps;
         mask_data_rise0_r3 <= mask_data_rise0_r2 after (TCQ)*1 ps;
         mask_data_fall0_r3 <= mask_data_fall0_r2 after (TCQ)*1 ps;
         mask_data_rise1_r3 <= mask_data_rise1_r2 after (TCQ)*1 ps;
         mask_data_fall1_r3 <= mask_data_fall1_r2 after (TCQ)*1 ps;
         mask_data_rise0_r4 <= mask_data_rise0_r3 after (TCQ)*1 ps;
         mask_data_fall0_r4 <= mask_data_fall0_r3 after (TCQ)*1 ps;
         mask_data_rise1_r4 <= mask_data_rise1_r3 after (TCQ)*1 ps;
         mask_data_fall1_r4 <= mask_data_fall1_r3 after (TCQ)*1 ps;
      end if;
   end process;
   
   
   -- Different nCWL values: 5, 6, 7, 8, 9
   gen_dm_ddr3_write_lat : if (DRAM_TYPE = "DDR3") generate
      gen_dm_ncwl5_odd : if ((nCWL = 5) or (nCWL = 7) or (nCWL = 9)) generate
         process (clk)
         begin
            if (clk'event and clk = '1') then
	       if (WRLVL = "OFF") then
                  out_d1 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                  out_d2 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                  out_d3 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                  out_d4 <= mask_data_fall1_r1 after (TCQ)*1 ps;
	       else	    
                  -- write command sent by MC on channel1
                  -- D3,D4 inputs of the OCB used to send write command to DDR3
                  
                  -- Shift bitslip logic by 1 or 2 clk_mem cycles
                  -- Write calibration currently supports only upto 2 clk_mem cycles
                  case (xhdl1) is
                     -- 0 clk_mem delay required as per write calibration
                     when "000" =>
                        out_d1 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall1_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise0 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     when "001" =>
                        out_d1 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall1_r1 after (TCQ)*1 ps;
                     -- 1 clk_mem delay required as per write cal
                     when "010" =>
                        out_d1 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 1 clk_mem delay required as per write cal
                     when "011" =>
                        out_d1 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                     -- 2 clk_mem delay required as per write cal
                     when "100" =>
                        out_d1 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 2 clk_mem delay required as per write cal
                     when "101" =>
                        out_d1 <= mask_data_rise0_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                     -- 3 clk_mem delay required as per write cal
                     when "110" =>
                        out_d1 <= mask_data_fall1_r3 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise0_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 3 clk_mem delay required as per write cal
                     when "111" =>
                        out_d1 <= mask_data_rise1_r3 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall1_r3 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise0_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                     -- defaults to 0 clk_mem delay
	             when others =>
                        out_d1 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall1_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise0 after (TCQ)*1 ps;
                  end case;
               end if;
       	    end if;   
         end process;
      end generate;

      gen_dm_ncwl_even : if ((nCWL = 6) or (nCWL = 8)) generate
         process (clk)
         begin
            if (clk'event and clk = '1') then
               if (WRLVL = "OFF") then
                  out_d1 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                  out_d2 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                  out_d3 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                  out_d4 <= mask_data_fall0_r1 after (TCQ)*1 ps;
               else
                  -- write command sent by MC on channel1
                  -- D3,D4 inputs of the OCB used to send write command to DDR3
                  
                  -- Shift bitslip logic by 1 or 2 clk_mem cycles
                  -- Write calibration currently supports only upto 2 clk_mem cycles

                  case (xhdl1) is
                     -- 0 clk_mem delay required as per write calibration
                     -- could not test 0011 case
                     when "000" =>
                        out_d1 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     when "001" =>
                        out_d1 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                     -- 1 clk_mem delay required as per write cal
                     when "010" =>
                        out_d1 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 1 clk_mem delay required as per write cal
                     when "011" =>
                        out_d1 <= mask_data_rise0_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                     -- 2 clk_mem delay required as per write cal
                     when "100" =>
                        out_d1 <= mask_data_fall1_r3 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise0_r2 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise1_r2 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 2 clk_mem delay required as per write cal
                     when "101" =>
                        out_d1 <= mask_data_rise1_r3 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall1_r3 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise0_r2 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall0_r2 after (TCQ)*1 ps;
                     -- 3 clk_mem delay required as per write cal
                     when "110" =>
                        out_d1 <= mask_data_fall0_r3 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise1_r3 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall1_r3 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise0_r2 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 3 clk_mem delay required as per write cal
                     when "111" =>
                        out_d1 <= mask_data_rise0_r3 after (TCQ)*1 ps;
                        out_d2 <= mask_data_fall0_r3 after (TCQ)*1 ps;
                        out_d3 <= mask_data_rise1_r3 after (TCQ)*1 ps;
                        out_d4 <= mask_data_fall1_r3 after (TCQ)*1 ps;
                     -- defaults to 0 clk_mem delay
                     when others =>
                        out_d1 <= mask_data_fall1_r2 after (TCQ)*1 ps;
                        out_d2 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                        out_d3 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                        out_d4 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                  end case;
               end if;	
            end if;
         end process;
      end generate;
   end generate;

    gen_dm_lat_ddr2 : if (DRAM_TYPE = "DDR2") generate
       gen_ddr2_ncwl2 : if (nCWL = 2) generate
          process (mask_data_rise1_r1, mask_data_fall1_r1, mask_data_rise0, mask_data_fall0)
          begin
             out_d1 <= mask_data_rise1_r1;
             out_d2 <= mask_data_fall1_r1;
             out_d3 <= mask_data_rise0;
             out_d4 <= mask_data_fall0;
          end process;
          
       end generate;
       gen_ddr2_ncwl3 :  if (nCWL = 3) generate
             process (clk)
             begin
                if (clk'event and clk = '1') then
                   out_d1 <= mask_data_rise0 after (TCQ)*1 ps;
                   out_d2 <= mask_data_fall0 after (TCQ)*1 ps;
                   out_d3 <= mask_data_rise1 after (TCQ)*1 ps;
                   out_d4 <= mask_data_fall1 after (TCQ)*1 ps;
                end if;
             end process;               
        end generate;
          
        gen_ddr2_ncwl4 : if (nCWL = 4) generate
                process (clk)
                begin
                   if (clk'event and clk = '1') then
                      out_d1 <= mask_data_rise1_r1 ;
                      out_d2 <= mask_data_fall1_r1 ;
                      out_d3 <= mask_data_rise0 ;
                      out_d4 <= mask_data_fall0 ;
                   end if;
                end process;                  
        end generate;
             
        gen_ddr2_ncwl5 : if (nCWL = 5) generate
                 process (clk)
                 begin
                    if (clk'event and clk = '1') then
                       out_d1 <= mask_data_rise0_r1 after (TCQ)*1 ps;
                       out_d2 <= mask_data_fall0_r1 after (TCQ)*1 ps;
                       out_d3 <= mask_data_rise1_r1 after (TCQ)*1 ps;
                       out_d4 <= mask_data_fall1_r1 after (TCQ)*1 ps;
                    end if;
                 end process;                    
         end generate;

         gen_ddr2_ncwl6 : if (nCWL = 6) generate
                 process (clk)
                 begin
                    if (clk'event and clk = '1') then
                       out_d1 <= mask_data_rise1_r2;
                       out_d2 <= mask_data_fall1_r2;
                       out_d3 <= mask_data_rise0_r1;
                       out_d4 <= mask_data_fall0_r1;
                    end if;
                 end process;                    
         end generate;

   end generate;

   --***************************************************************************   
   u_oserdes_dm : OSERDESE1
      generic map (
         DATA_RATE_OQ   => "DDR",
         DATA_RATE_TQ   => "DDR",
         DATA_WIDTH     => 4,
         DDR3_DATA      => 0,
         INIT_OQ        => '0',
         INIT_TQ        => '0',
         INTERFACE_TYPE => "DEFAULT",
         ODELAY_USED    => 0,
         SERDES_MODE    => "MASTER",
         SRVAL_OQ       => '0',
         SRVAL_TQ       => '0',
         TRISTATE_WIDTH => 4
      )
      port map (
         OCBEXTEND     => open,
         OFB           => open,
         OQ            => dm_oq,
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         TQ            => open,
         CLK           => clk_mem,                
         CLKDIV        => clk,                 
         CLKPERF       => 'Z',
         CLKPERFDELAY  => 'Z',
         D1            => out_d1,
         D2            => out_d2,
         D3            => out_d3,
         D4            => out_d4,
         D5            => 'Z',
         D6            => 'Z',
         OCE           => '1',
         ODV           => '0',
         SHIFTIN1      => 'Z',
         SHIFTIN2      => 'Z',               
         RST           => rst,
         T1            => '0',
         T2            => '0',
         T3            => '0',
         T4            => '0',
         TFB           => open,
         TCE           => '1',               
         WC            => '0'
      );
         
   -- Output of OSERDES drives IODELAY (ODELAY)
   u_odelay_dm : IODELAYE1
      generic map (
         cinvctrl_sel           => FALSE,
         delay_src              => "O",
         high_performance_mode  => HIGH_PERFORMANCE_MODE,
         idelay_type            => "FIXED",
         idelay_value           => 0,
         odelay_type            => "VAR_LOADABLE",
         odelay_value           => 0,
         refclk_frequency       => REFCLK_FREQ,
         signal_pattern         => "DATA"
      )
      port map (
         dataout      => dm_odelay,
         c            => clk_rsync,
         ce           => '0',
         datain       => 'Z',
         idatain      => 'Z',
         inc          => '0',
         odatain      => dm_oq,
         rst          => '1',
         t            => 'Z',
         cntvaluein   => dlyval,
         cntvalueout  => open,
         clkin        => 'Z',
         cinvctrl     => '0'
      );

   -- Output of ODELAY drives OBUF                  
   u_obuf_dm : OBUF
      port map (
         i  => dm_odelay,
         o  => ddr_dm
      );
   
end trans_phy_dm_iob;



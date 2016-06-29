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
--  /   /         Filename: phy_dq_iob.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Instantiates I/O-related logic for DQ. Contains logic for both write
--   and read paths.
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--$Id: phy_dq_iob.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_dq_iob.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;


entity phy_dq_iob is
   generic (
      TCQ                    : integer := 100;		-- clk->out delay (sim only)
      nCWL                   : integer := 5;		-- Write CAS latency (in clk cyc)
      DRAM_TYPE              : string  := "DDR3";	-- Memory I/F type: "DDR3", "DDR2"
      WRLVL                  : string  := "ON";		-- "OFF" for "DDR3" component interface
      REFCLK_FREQ            : real    := 300.0;	-- IODELAY Reference Clock freq (MHz)
      IBUF_LPWR_MODE   	     : string  := "OFF";  	-- Input buffer low power mode
      IODELAY_HP_MODE        : string  := "ON";		-- IODELAY High Performance Mode
      IODELAY_GRP            : string  := "IODELAY_MIG" -- May be assigned unique name
                                                        -- when mult IP cores in design
   );
   port (
      clk_mem                : in std_logic;
      clk                    : in std_logic;
      rst                    : in std_logic;
      clk_cpt                : in std_logic;
      clk_rsync              : in std_logic;
      rst_rsync              : in std_logic;
      -- IODELAY I/F
      dlyval                 : in std_logic_vector(4 downto 0);
      -- Write datapath I/F
      inv_dqs                : in std_logic;
      wr_calib_dly           : in std_logic_vector(1 downto 0);
      dq_oe_n	             : in std_logic_vector(3 downto 0);
      wr_data_rise0          : in std_logic;
      wr_data_fall0          : in std_logic;
      wr_data_rise1          : in std_logic;
      wr_data_fall1          : in std_logic;
      -- Read datapath I/F
      rd_bitslip_cnt         : in std_logic_vector(1 downto 0);
      rd_clkdly_cnt	     : in std_logic_vector(1 downto 0);
      rd_clkdiv_inv          : in std_logic;
      rd_data_rise0          : out std_logic;
      rd_data_fall0          : out std_logic;
      rd_data_rise1          : out std_logic;
      rd_data_fall1          : out std_logic;
      -- DDR3 bus signals
      ddr_dq                 : inout std_logic;
      dq_tap_cnt             : out std_logic_vector(4 downto 0)
   );
end phy_dq_iob;

architecture trans_phy_dq_iob of phy_dq_iob is

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

   -- Enable low power mode for input buffer
   function CALC_IBUF_LOW_PWR return boolean is
      begin
         if (IBUF_LPWR_MODE = "OFF") then
	    return FALSE;
	 elsif (IBUF_LPWR_MODE = "ON") then
	    return TRUE;
	 else
            return FALSE;
         end if;
   end function CALC_IBUF_LOW_PWR;

   constant HIGH_PERFORMANCE_MODE  : boolean := CALC_HIGH_PERF_MODE;
   constant IBUF_LOW_PWR  	   : boolean := CALC_IBUF_LOW_PWR;
   signal dq_in                    : std_logic;
   signal dq_iodelay               : std_logic;
   signal dq_oe_n_r                : std_logic;
   signal dq_oq                    : std_logic;
   signal iodelay_dout             : std_logic;
   signal iserdes_clk              : std_logic;
   signal iserdes_clkb             : std_logic;
   signal iserdes_q                : std_logic_vector(5 downto 0);
   signal iserdes_q_mux            : std_logic_vector(5 downto 0);  
   signal iserdes_q_neg_r          : std_logic_vector(5 downto 0);
   signal iserdes_q_r              : std_logic_vector(5 downto 0); 
   signal ocb_d1                   : std_logic;
   signal ocb_d2                   : std_logic;
   signal ocb_d3                   : std_logic;
   signal ocb_d4                   : std_logic;
   signal ocb_tfb                  : std_logic;	-- Must be connected to T input of IODELAY
						-- TFB turns IODELAY to ODELAY enabling
   						-- CLKPERFDELAY required to lock out TQ
   signal rddata                   : std_logic_vector(3 downto 0);
   signal tri_en1_r1               : std_logic;
   signal tri_en2_r1               : std_logic;
   signal tri_en3_r1               : std_logic;
   signal tri_en4_r1               : std_logic;
   signal wr_data_fall0_r1         : std_logic;
   signal wr_data_fall0_r2         : std_logic;
   signal wr_data_fall0_r3         : std_logic;
   signal wr_data_fall0_r4         : std_logic;
   signal wr_data_fall1_r1         : std_logic;
   signal wr_data_fall1_r2         : std_logic;
   signal wr_data_fall1_r3         : std_logic;
   signal wr_data_fall1_r4         : std_logic;
   signal wr_data_rise0_r1         : std_logic;
   signal wr_data_rise0_r2         : std_logic;
   signal wr_data_rise0_r3         : std_logic;
   signal wr_data_rise0_r4         : std_logic;
   signal wr_data_rise1_r1         : std_logic;
   signal wr_data_rise1_r2         : std_logic;
   signal wr_data_rise1_r3         : std_logic;
   signal wr_data_rise1_r4         : std_logic;	
   signal xhdl1		   : std_logic_vector(2 downto 0);

   ------ rd_bitslip component -------
   component rd_bitslip
   generic (
      TCQ   	: integer := 100
   );
   port (
      clk       	: in std_logic;
      bitslip_cnt       : in std_logic_vector(1 downto 0);
      clkdly_cnt        : in std_logic_vector(1 downto 0);
      din               : in std_logic_vector(5 downto 0);
      qout              : out std_logic_vector(3 downto 0)
   );
   end component;

   attribute IODELAY_GROUP : string;
   attribute IODELAY_GROUP of u_iodelay_dq : label is IODELAY_GRP;

begin

   -- drive xhdl1 from xhdl1(1 downto 0) and inv_dqs  
   xhdl1 <= wr_calib_dly(1 downto 0) & inv_dqs;

   --***************************************************************************
   -- Bidirectional I/O
   --***************************************************************************

   u_iobuf_dq: IOBUF
      generic map(
         IBUF_LOW_PWR => IBUF_LOW_PWR	      
      ) 
      port map(
         I  => dq_iodelay,
         T  => dq_oe_n_r,
         IO => ddr_dq,
         O  => dq_in	    
	 ); 

   --***************************************************************************
   -- Programmable Delay element - used for both input and output paths
   --***************************************************************************      	 

   u_iodelay_dq : IODELAYE1
      generic map (
         CINVCTRL_SEL           => FALSE,
         DELAY_SRC              => "IO",
         HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
         IDELAY_TYPE            => "VAR_LOADABLE",
         IDELAY_VALUE           => 0,
         ODELAY_TYPE            => "VAR_LOADABLE",
         ODELAY_VALUE           => 0,
         REFCLK_FREQUENCY       => REFCLK_FREQ,
         SIGNAL_PATTERN         => "DATA"
      )
      port map (
         DATAOUT      => dq_iodelay,
         C            => clk_rsync,
         CE           => '0',
         DATAIN       => '0',
         IDATAIN      => dq_in,
         INC          => '0',
         ODATAIN      => dq_oq,		-- Input from OSERDES OQ
         RST          => '1',
         T            => ocb_tfb,
         CNTVALUEIN   => dlyval,
         CNTVALUEOUT  => dq_tap_cnt,
         CLKIN        => 'Z',
         CINVCTRL     => '0'
      );
   
   --***************************************************************************
   -- Write Path
   --***************************************************************************

   --***********************************************************************
   -- Write Bitslip
   --***********************************************************************
   
   -- dfi_wrdata_en0 - even clk cycles channel 0
   -- dfi_wrdata_en1 - odd clk cycles channel 1
   -- tphy_wrlat set to 0 clk cycle for CWL = 5,6,7,8
   -- Valid dfi_wrdata* sent 1 clk cycle after dfi_wrdata_en* is asserted
   -- WC for OCB (Output Circular Buffer) assertion for 1 clk cycle
   -- WC aligned with dfi_wrdata_en*
   
   -- first rising edge data (rise0)
   -- first falling edge data (fall0)
   -- second rising edge data (rise1)
   -- second falling edge data (fall1)
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         wr_data_rise0_r1 <= wr_data_rise0 after (TCQ)*1 ps;
         wr_data_fall0_r1 <= wr_data_fall0 after (TCQ)*1 ps;
         wr_data_rise1_r1 <= wr_data_rise1 after (TCQ)*1 ps;
         wr_data_fall1_r1 <= wr_data_fall1 after (TCQ)*1 ps;
         wr_data_rise0_r2 <= wr_data_rise0_r1 after (TCQ)*1 ps;
         wr_data_fall0_r2 <= wr_data_fall0_r1 after (TCQ)*1 ps;
         wr_data_rise1_r2 <= wr_data_rise1_r1 after (TCQ)*1 ps;
         wr_data_fall1_r2 <= wr_data_fall1_r1 after (TCQ)*1 ps;
         wr_data_rise0_r3 <= wr_data_rise0_r2 after (TCQ)*1 ps;
         wr_data_fall0_r3 <= wr_data_fall0_r2 after (TCQ)*1 ps;
         wr_data_rise1_r3 <= wr_data_rise1_r2 after (TCQ)*1 ps;
         wr_data_fall1_r3 <= wr_data_fall1_r2 after (TCQ)*1 ps;
         wr_data_rise0_r4 <= wr_data_rise0_r3 after (TCQ)*1 ps;
         wr_data_fall0_r4 <= wr_data_fall0_r3 after (TCQ)*1 ps;
         wr_data_rise1_r4 <= wr_data_rise1_r3 after (TCQ)*1 ps;
         wr_data_fall1_r4 <= wr_data_fall1_r3 after (TCQ)*1 ps;
      end if;
   end process;
   
   
   -- Different nCWL values: 5, 6, 7, 8, 9
   gen_ddr3_write_lat : if (DRAM_TYPE = "DDR3") generate
      gen_ncwl5_odd : if ((nCWL = 5) or (nCWL = 7) or (nCWL = 9)) generate
         process (clk)
         begin
            if (clk'event and clk = '1') then
               if (WRLVL = "OFF") then
                  ocb_d1 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                  ocb_d2 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                  ocb_d3 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                  ocb_d4 <= wr_data_fall1_r1 after (TCQ)*1 ps;
               else 
                  -- write command sent by MC on channel1
                  -- D3,D4 inputs of the OCB used to send write command to DDR3
                  
                  -- Shift bitslip logic by 1 or 2 clk_mem cycles
                  -- Write calibration currently supports only upto 2 clk_mem cycles
                  case (xhdl1) is
                     -- 0 clk_mem delay required as per write calibration
                     when "000" =>
                        ocb_d1 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_fall1_r1 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_rise0 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     when "001" =>
                        ocb_d1 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_fall1_r1 after (TCQ)*1 ps;
                     -- 1 clk_mem delay required as per write cal
                     when "010" =>
                        ocb_d1 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 1 clk_mem delay required as per write cal
                     when "011" =>
                        ocb_d1 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                     -- 2 clk_mem delay required as per write cal
                     when "100" =>
                        ocb_d1 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 2 clk_mem delay required as per write cal
                     when "101" =>
                        ocb_d1 <= wr_data_rise0_r2 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                     -- 3 clk_mem delay required as per write cal
                     when "110" =>
                        ocb_d1 <= wr_data_fall1_r3 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_rise0_r2 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                     -- DQS inverted during write leveling
                     -- 3 clk_mem delay required as per write cal
                     when "111" =>
                        ocb_d1 <= wr_data_rise1_r3 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_fall1_r3 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_rise0_r2 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                     -- defaults to 0 clk_mem delay
	             when others =>
                        ocb_d1 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                        ocb_d2 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                        ocb_d3 <= wr_data_fall1_r1 after (TCQ)*1 ps;
                        ocb_d4 <= wr_data_rise0 after (TCQ)*1 ps;
                  end case;
	       end if;  
            end if;
         end process;
      end generate;

      gen_ncwl_even : if ((nCWL = 6) or (nCWL = 8)) generate
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  if (WRLVL = "OFF") then
                     ocb_d1 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                     ocb_d2 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                     ocb_d3 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                     ocb_d4 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                  else
                     -- write command sent by MC on channel1
                     -- D3,D4 inputs of the OCB used to send write command to DDR3
                     
                     -- Shift bitslip logic by 1 or 2 clk_mem cycles
                     -- Write calibration currently supports only upto 2 clk_mem cycles
                     case (xhdl1) is
                        -- 0 clk_mem delay required as per write calibration
                        -- could not test 0011 case
                        when "000" =>
                           ocb_d1 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                        -- DQS inverted during write leveling
                        when "001" =>
                           ocb_d1 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                        -- 1 clk_mem delay required as per write cal
                        when "010" =>
                           ocb_d1 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                        -- DQS inverted during write leveling
                        -- 1 clk_mem delay required as per write cal
                        when "011" =>
                           ocb_d1 <= wr_data_rise0_r2 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                        -- 2 clk_mem delay required as per write cal
                        when "100" =>
                           ocb_d1 <= wr_data_fall1_r3 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_rise0_r2 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                        -- DQS inverted during write leveling
                        -- 2 clk_mem delay required as per write cal
                        when "101" =>
                           ocb_d1 <= wr_data_rise1_r3 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_fall1_r3 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_rise0_r2 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_fall0_r2 after (TCQ)*1 ps;
                        -- 3 clk_mem delay required as per write cal
                        when "110" =>
                           ocb_d1 <= wr_data_fall0_r3 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_rise1_r3 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_fall1_r3 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_rise0_r2 after (TCQ)*1 ps;
                        -- DQS inverted during write leveling
                        -- 3 clk_mem delay required as per write cal
                        when "111" =>
                           ocb_d1 <= wr_data_rise0_r3 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_fall0_r3 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_rise1_r3 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_fall1_r3 after (TCQ)*1 ps;
                        -- defaults to 0 clk_mem delay
                        when others =>
                           ocb_d1 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                           ocb_d2 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                           ocb_d3 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                           ocb_d4 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                     end case;
                  end if;	
               end if;
            end process;
         end generate;
    end generate;
    
    ddr2_write_lat : if (not(DRAM_TYPE = "DDR3")) generate
       gen_ddr2_ncwl2 : if (nCWL = 2) generate
          process (wr_data_rise1_r1, wr_data_fall1_r1, wr_data_rise0, wr_data_fall0)
          begin
             ocb_d1 <= wr_data_rise1_r1;
             ocb_d2 <= wr_data_fall1_r1;
             ocb_d3 <= wr_data_rise0;
             ocb_d4 <= wr_data_fall0;
          end process;
          
       end generate;
       gen_ddr2_ncwl3 :  if (nCWL = 3) generate
          process (clk)
          begin
             if (clk'event and clk = '1') then
                ocb_d1 <= wr_data_rise0 after (TCQ)*1 ps;
                ocb_d2 <= wr_data_fall0 after (TCQ)*1 ps;
                ocb_d3 <= wr_data_rise1 after (TCQ)*1 ps;
                ocb_d4 <= wr_data_fall1 after (TCQ)*1 ps;
             end if;
          end process;               
       end generate;
          
       gen_ddr2_ncwl4 : if (nCWL = 4) generate
          process (clk)
          begin
             if (clk'event and clk = '1') then
                ocb_d1 <= wr_data_rise1_r1;
                ocb_d2 <= wr_data_fall1_r1;
                ocb_d3 <= wr_data_rise0;
                ocb_d4 <= wr_data_fall0;
             end if;
          end process;                  
       end generate;
            
       gen_ddr2_ncwl5 : if (nCWL = 5) generate
          process (clk)
          begin
             if (clk'event and clk = '1') then
                ocb_d1 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                ocb_d2 <= wr_data_fall0_r1 after (TCQ)*1 ps;
                ocb_d3 <= wr_data_rise1_r1 after (TCQ)*1 ps;
                ocb_d4 <= wr_data_fall1_r1 after (TCQ)*1 ps;
             end if;
          end process;                     
       end generate;

       gen_ddr2_ncwl6 : if (nCWL = 6) generate
          process (clk)
          begin
             if (clk'event and clk = '1') then
                ocb_d1 <= wr_data_rise1_r2 after (TCQ)*1 ps;
                ocb_d2 <= wr_data_fall1_r2 after (TCQ)*1 ps;
                ocb_d3 <= wr_data_rise0_r1 after (TCQ)*1 ps;
                ocb_d4 <= wr_data_fall0_r1 after (TCQ)*1 ps;
             end if;
          end process;                     
       end generate;
        
   end generate;
   
   --***************************************************************************
   -- on a write, rising edge of DQS corresponds to rising edge of clk_mem
   -- We also know:
   --  1. DQS driven 1/2 clk_mem cycle after corresponding DQ edge
   --  2. first rising DQS edge driven on falling edge of clk_mem
   --  3. DQ to be delayed 1/4 clk_mem cycle using ODELAY taps
   --  4. therefore, rising data driven on rising edge of clk_mem
   --***************************************************************************
   u_oserdes_dq : OSERDESE1
      generic map (
         DATA_RATE_OQ   => "DDR",
         DATA_RATE_TQ   => "DDR",
         DATA_WIDTH     => 4,
         DDR3_DATA      => 0,
         INIT_OQ        => '0',
         INIT_TQ        => '1',
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
         OQ            => dq_oq,
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         TQ            => dq_oe_n_r,
         CLK           => clk_mem,                
         CLKDIV        => clk,                 
         CLKPERF       => 'Z',
         CLKPERFDELAY  => 'Z',
         D1            => ocb_d1,
         D2            => ocb_d2,
         D3            => ocb_d3,
         D4            => ocb_d4,
         D5            => 'Z',
         D6            => 'Z',
         OCE           => '1',
         ODV           => '0',
         SHIFTIN1      => 'Z',
         SHIFTIN2      => 'Z',               
         RST           => rst,
         T1            => dq_oe_n(0),
         T2            => dq_oe_n(1),
         T3            => dq_oe_n(2),
         T4            => dq_oe_n(3),
         TFB           => ocb_tfb,
         TCE           => '1',               
         WC            => '0'
      );
   
   --***************************************************************************
   -- Read Path
   --***************************************************************************   

   -- Assign equally to avoid delta-delay issues in simulation
   iserdes_clk  <=  clk_cpt;
   iserdes_clkb <=  not(clk_cpt);

   u_iserdes_dq : ISERDESE1
      generic map (
         DATA_RATE         => "DDR",
         DATA_WIDTH        => 4,
         DYN_CLKDIV_INV_EN => TRUE,
         DYN_CLK_INV_EN    => FALSE,
         INIT_Q1           => '0',
         INIT_Q2           => '0',
         INIT_Q3           => '0',
         INIT_Q4           => '0',
         INTERFACE_TYPE    => "MEMORY_DDR3",
         NUM_CE	           => 2,
         IOBDELAY	   => "IFD",
         OFB_USED          => FALSE,
         SERDES_MODE       => "MASTER",
         SRVAL_Q1          => '0',
         SRVAL_Q2          => '0',
         SRVAL_Q3          => '0',
         SRVAL_Q4          => '0'
      )
      port map (
         O             => open,
         Q1	       => iserdes_q(0),
         Q2	       => iserdes_q(1),
         Q3	       => iserdes_q(2),
         Q4	       => iserdes_q(3),
         Q5	       => iserdes_q(4),
         Q6	       => iserdes_q(5),
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         BITSLIP       => '0',
         CE1	       => '1',
         CE2	       => '1',
         CLK           => iserdes_clk,                
         CLKB          => iserdes_clkb,                
         CLKDIV        => clk_rsync,                 
         D             => 'Z',
         DDLY          => dq_iodelay,
         DYNCLKDIVSEL  => rd_clkdiv_inv,
         DYNCLKSEL     => '0',    
         OCLK          => clk_mem,	-- Not used, but connect to avoid DRC    
         OFB           => '0',
         RST           => rst_rsync,
         SHIFTIN1      => '0',
         SHIFTIN2      => '0' 
      );

   --*****************************************************************
   -- Selectable registers on ISERDES data outputs depending on
   -- whether DYNCLKDIVSEL is enabled or not
   --*****************************************************************
  
   -- Capture first using CLK_RSYNC falling edge domain, then transfer 
   -- to rising edge CLK_RSYNC. We could also attempt to transfer
   -- directly from falling edge CLK_RSYNC domain (in ISERDES) to
   -- rising edge CLK_RSYNC domain in fabric. This is allowed as long
   -- as the half-cycle timing on these paths can be met. 
   process (clk_rsync)
   begin
      if (clk_rsync'event and clk_rsync = '0') then
        iserdes_q_neg_r <= iserdes_q after (TCQ)*1 ps;
      end if;
   end process;

   process (clk_rsync)
   begin
      if (clk_rsync'event and clk_rsync = '1') then
        iserdes_q_r <= iserdes_q_neg_r after (TCQ)*1 ps;
      end if;
   end process;

   iserdes_q_mux <= iserdes_q_r when (rd_clkdiv_inv = '1') else
                    iserdes_q;
   
   --*****************************************************************
   -- Read bitslip logic
   --*****************************************************************	

   u_rd_bitslip: rd_bitslip
      generic map(
	 TCQ  =>  TCQ     
      )
      port map(
         clk          => clk_rsync,
         bitslip_cnt  => rd_bitslip_cnt,
         clkdly_cnt   => rd_clkdly_cnt,
         din          => iserdes_q_mux,
         qout         => rddata	      
      );

   rd_data_rise0 <= rddata(3);
   rd_data_fall0 <= rddata(2);
   rd_data_rise1 <= rddata(1);
   rd_data_fall1 <= rddata(0);
      
end trans_phy_dq_iob;





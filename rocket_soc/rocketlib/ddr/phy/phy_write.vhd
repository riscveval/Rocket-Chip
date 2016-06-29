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
--  /   /         Filename: phy_write.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:13 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Handles delaying various write control signals appropriately depending
--   on CAS latency, additive latency, etc. Also splits the data and mask in
--   rise and fall buses.
--Reference:
--Revision History:
-- Revision 1.22 Karthip merged DDR2 changes 11/11/2008
--*****************************************************************************

--******************************************************************************
--**$Id: phy_write.vhd,v 1.1 2011/06/02 07:18:13 mishra Exp $
--**$Date: 2011/06/02 07:18:13 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_write.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_write is
   generic (
      TCQ             	: integer := 100;
      WRLVL	   	: string  := "ON";		
      DRAM_TYPE	   	: string  := "DDR3";		
      DQ_WIDTH       	: integer := 64;	
      DQS_WIDTH     	: integer := 8; 
      nCWL		: integer := 5;
      REG_CTRL		: string  := "OFF";
      RANK_WIDTH	: integer := 1;   
      CLKPERF_DLY_USED 	: string  := "OFF"		
      );
   port (
      clk    	        	: in std_logic;  
      rst       		: in std_logic; 
      -- Write-leveling control
      mc_data_sel      		: in std_logic; 
      wrlvl_active     		: in std_logic; 
      wrlvl_done       		: in std_logic; 
      inv_dqs      		: in std_logic_vector(DQS_WIDTH-1 downto 0); 
      wr_calib_dly     		: in std_logic_vector(2*DQS_WIDTH-1 downto 0); 
      -- MC DFI Control/Address
      dfi_wrdata     		: in std_logic_vector(4*DQ_WIDTH-1 downto 0); 
      dfi_wrdata_mask  		: in std_logic_vector((4*DQ_WIDTH/8)-1 downto 0); 
      dfi_wrdata_en    		: in std_logic; 
      -- MC sideband signal
      mc_ioconfig_en   		: in std_logic; 				-- Possible future use
      mc_ioconfig    		: in std_logic_vector(RANK_WIDTH downto 0); 	-- Possible future use
      -- PHY DFI Control/Address
      phy_wrdata_en    		: in std_logic; 
      phy_wrdata    		: in std_logic_vector(4*DQ_WIDTH-1 downto 0);
      -- sideband signals
      phy_ioconfig_en  		: in std_logic; 				-- Possible future use
      phy_ioconfig    		: in std_logic_vector(0 downto 0);		-- Possible future use
      -- Write-path control
      out_oserdes_wc		: in std_logic;
      dm_ce  	  		: out std_logic_vector(DQS_WIDTH-1 downto 0);
      dq_oe_n    		: out std_logic_vector(4*DQS_WIDTH-1 downto 0);
      dqs_oe_n    		: out std_logic_vector(4*DQS_WIDTH-1 downto 0);
      dqs_rst    		: out std_logic_vector(4*DQS_WIDTH-1 downto 0);
      dq_wc			: out std_logic;
      dqs_wc			: out std_logic;
      mask_data_rise0		: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
      mask_data_fall0		: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
      mask_data_rise1		: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
      mask_data_fall1		: out std_logic_vector((DQ_WIDTH/8)-1 downto 0);
      wl_sm_start		: out std_logic;
      wr_lvl_start		: out std_logic;
      wr_data_rise0		: out std_logic_vector(DQ_WIDTH-1 downto 0);
      wr_data_fall0		: out std_logic_vector(DQ_WIDTH-1 downto 0);
      wr_data_rise1		: out std_logic_vector(DQ_WIDTH-1 downto 0);
      wr_data_fall1		: out std_logic_vector(DQ_WIDTH-1 downto 0)
      );
end phy_write;

architecture trans of phy_write is

   constant DQ_PER_DQS	: integer := DQ_WIDTH/DQS_WIDTH;
   constant RST_DLY_NUM	: integer := 8;

   signal rst_delayed		: std_logic_vector(RST_DLY_NUM-1 downto 0);
   signal dm_ce_r		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal dq_wc_r		: std_logic;
   signal dqs_wc_r		: std_logic;
   signal dqs_wc_asrt		: std_logic;
   signal dqs_wc_deasrt		: std_logic;
   signal dm_ce_0		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal dqs_asrt_cnt		: std_logic_vector(1 downto 0);
   signal mux_ioconfig_r	: std_logic_vector(0 downto 0);	
   signal mux_wrdata_en		: std_logic;
   signal mux_ioconfig_en	: std_logic;
   signal mux_ioconfig		: std_logic_vector(0 downto 0);		-- bus to be expanded later
   signal mc_wrdata		: std_logic_vector(4*DQ_WIDTH-1 downto 0);
   signal mc_wrdata_mask	: std_logic_vector((4*DQ_WIDTH/8)-1 downto 0);
   signal phy_wrdata_r		: std_logic_vector(4*DQ_WIDTH-1 downto 0);
   signal dfi_wrdata_r		: std_logic_vector(4*DQ_WIDTH-1 downto 0);
   signal dfi_wrdata_mask_r	: std_logic_vector((4*DQ_WIDTH/8)-1 downto 0);
   signal ocb_d1		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal ocb_d2		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal ocb_d3		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal ocb_d4		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal ocb_dq1		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal ocb_dq2		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal ocb_dq3		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal ocb_dq4		: std_logic_vector(DQS_WIDTH-1 downto 0);
   signal wrdata_en_r1		: std_logic;
   signal wrdata_en_r2		: std_logic;
   signal wrdata_en_r3		: std_logic;
   signal wrdata_en_r4		: std_logic;
   signal wrdata_en_r5		: std_logic;
   signal wrdata_en_r6		: std_logic;
   signal wrdata_en_r7		: std_logic;
   signal wrlvl_active_r1	: std_logic;
   signal wrlvl_active_r2	: std_logic;
   signal wrlvl_done_r1		: std_logic;
   signal wrlvl_done_r2		: std_logic;
   signal wrlvl_done_r3		: std_logic;
   signal wr_level_dqs_asrt_r	: std_logic;
   signal wr_level_dqs_stg_r	: std_logic_vector(19 downto 0);
   signal mux_ioconfig_latch	: std_logic;
   signal mux_ioconfig_last_r	: std_logic;
   signal dfi_wrdata_en_r	: std_logic;
   signal phy_wrdata_en_r	: std_logic;

begin

   --***************************************************************************
   -- NOTE: As of 08/13/08, many signals in this module are not used. This is
   --  because of a last-minute change to the WC timing - it was based on
   --  IOCONFIG_STROBE, however IOCONFIG_STROBE will only occur when there is
   --  a change in either the bus direction, or rank accessed. It will not
   --  occur for succeeding writes to the same rank. Therefore, it cannot be
   --  used to drive WC (which must be pulsed once to "restart" the circular
   --  buffer once the bus has gone tri-state). For now, revert to using
   --  WRDATA_EN to determining when WC is pulsed.
   --***************************************************************************	
   process (clk, rst)
   begin
      if (rst = '1') then
         rst_delayed <= (others => '1') after TCQ*1 ps;
      elsif (clk'event and clk = '1') then
         -- logical left shift by one (pads with 0)
         rst_delayed <= std_logic_vector(unsigned(rst_delayed) sll 1) after TCQ*1 ps;
      end if;
   end process;

   --***************************************************************************
   -- MUX control/data inputs from either external DFI master or PHY init
   --***************************************************************************
   gen_wrdata_en_rdimm: if ((DRAM_TYPE = "DDR3") and (REG_CTRL = "ON")) generate
      process(clk)
      begin
         if (clk'event and clk = '1') then
            phy_wrdata_r      <= phy_wrdata  after TCQ*1 ps;
            phy_wrdata_en_r   <= phy_wrdata_en after TCQ*1 ps;
            dfi_wrdata_en_r   <= dfi_wrdata_en after TCQ*1 ps;
            dfi_wrdata_r      <= dfi_wrdata after TCQ*1 ps;
            dfi_wrdata_mask_r <= dfi_wrdata_mask after TCQ*1 ps;
	 end if;	 
      end process;	 

      process (mc_data_sel,phy_wrdata_en_r,phy_wrdata_en,dfi_wrdata_en_r,dfi_wrdata_en)
      begin
         if ((mc_data_sel = '0') and (nCWL = 9)) then
            mux_wrdata_en <= phy_wrdata_en_r;
         else
            if (mc_data_sel = '0') then
               mux_wrdata_en <= phy_wrdata_en;
            else
               if ((nCWL = 7) or (nCWL = 9)) then
                  mux_wrdata_en <= dfi_wrdata_en_r;
               else
                  mux_wrdata_en <= dfi_wrdata_en;
	       end if;
            end if;
         end if;
      end process;
   end generate;
   
   gen_wrdata_en_udimm: if (not(DRAM_TYPE = "DDR3") or not(REG_CTRL = "ON")) generate   
      mux_wrdata_en <= dfi_wrdata_en when (mc_data_sel = '1') else
		    phy_wrdata_en;		  
   end generate;

   mux_ioconfig_en <= mc_ioconfig_en when (mc_data_sel = '1') else
		      phy_ioconfig_en;

   mux_ioconfig(0) <= mc_ioconfig(RANK_WIDTH) when (mc_data_sel = '1') else
		      phy_ioconfig(0);

   --***************************************************************************
   -- OCB WC pulse generation on a per byte basis
   --***************************************************************************

   -- Store value of MUX_IOCONFIG when enable(latch) signal asserted
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (mux_ioconfig_en = '1') then
            mux_ioconfig_last_r <= mux_ioconfig(0) after TCQ*1 ps;
	 end if;
      end if;
   end process;

   -- dfi_wrdata_en - data enable sent by MC
   -- ignoring dfi_wrdata_en1: data sent on both channels 0 and 1 simultaneously
   -- tphy_wrlat set to 0 'clk' cycle for CWL = 5,6,7,8
   -- Valid dfi_wrdata* sent 1 'clk' cycle after dfi_wrdata_en* is asserted
   -- WC for OCB (Output Circular Buffer) assertion for 1 clk cycle
   process (mux_ioconfig_en, mux_ioconfig_last_r, mux_ioconfig(0))
   begin
      if (mux_ioconfig_en = '1') then
         mux_ioconfig_latch <= mux_ioconfig(0);
      else
         mux_ioconfig_latch <= mux_ioconfig_last_r;	      
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            wl_sm_start <= '0' after TCQ*1 ps;
         else
            wl_sm_start <= wr_level_dqs_asrt_r after TCQ*1 ps;
	 end if;
      end if;
   end process;   

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((rst = '1') or ((mux_ioconfig_en = '1') and (mux_ioconfig(0) = '0'))) then
            mux_ioconfig_r(0) <= '0' after TCQ*1 ps;
         else
            mux_ioconfig_r(0) <= mux_ioconfig_latch after TCQ*1 ps;
	 end if;
      end if;
   end process;   

   process (clk)
   begin
      if (clk'event and clk = '1') then
         wrdata_en_r1 <= mux_wrdata_en after TCQ*1 ps;
         wrdata_en_r2 <= wrdata_en_r1 after TCQ*1 ps;
         wrdata_en_r3 <= wrdata_en_r2 after TCQ*1 ps;
         wrdata_en_r4 <= wrdata_en_r3 after TCQ*1 ps;
         wrdata_en_r5 <= wrdata_en_r4 after TCQ*1 ps;
         wrdata_en_r6 <= wrdata_en_r5 after TCQ*1 ps;
         wrdata_en_r7 <= wrdata_en_r6 after TCQ*1 ps;
      end if;
   end process;   

   -- One WC signal for all data bits
   -- Combinatorial for CWL=5 and registered for CWL>5
   gen_wc_ddr3: if ((DRAM_TYPE(1 to 4) = "DDR3") and (CLKPERF_DLY_USED(1 to 2) = "ON")) generate
   begin
      gen_wc_ncwl5: if (nCWL = 5) generate
      begin
         process (clk)
	 begin
	    if (clk'event and clk = '1') then
	       if ((rst = '1') or ((mux_ioconfig_en = '1') and (mux_ioconfig(0) = '0')) or (wrlvl_active = '1')) then
                  dq_wc_r <= '0' after TCQ*1 ps;
	       elsif (mux_ioconfig_latch = '1') then
                  dq_wc_r <= not(dq_wc_r) after TCQ*1 ps;
	       end if;
	    end if;
	 end process;

         process (clk)
	 begin
	    if (clk'event and clk = '1') then
	       if ((rst = '1') or ((mux_ioconfig_en = '1') and (mux_ioconfig(0) = '0') and (wrlvl_active_r1 = '0')) or 
	           (dqs_wc_deasrt = '1')) then
                  dqs_wc_r <= '0' after TCQ*1 ps;
	       elsif (dqs_wc_asrt = '1') then
		  dqs_wc_r <= '1' after TCQ*1 ps;
	       elsif ((mux_ioconfig_latch = '1') and (wrlvl_active_r1 = '0')) then  
                  dqs_wc_r <= not(dqs_wc_r) after TCQ*1 ps;
	       end if;
	    end if;
	 end process;
      end generate;

      gen_wc_ncwl7up: if ((nCWL = 7) or (nCWL = 6) or (nCWL = 8) or (nCWL = 9)) generate
      begin	      
         process (clk)
	 begin
	    if (clk'event and clk = '1') then
	       if ((rst = '1') or ((mux_ioconfig_en = '1') and (mux_ioconfig(0) = '0')) or (wrlvl_active = '1')) then
                  dq_wc_r <= '0' after TCQ*1 ps;
	       elsif (mux_ioconfig_r(0) = '1') then
                  dq_wc_r <= not(dq_wc_r) after TCQ*1 ps;
	       end if;
	    end if;
	 end process;

         process (clk)
	 begin
	    if (clk'event and clk = '1') then
	       if ((rst = '1') or ((mux_ioconfig_en = '1') and (mux_ioconfig(0) = '0') and (wrlvl_active_r1 = '0')) or (dqs_wc_deasrt = '1')) then
                  dqs_wc_r <= '0' after TCQ*1 ps;
	       elsif (dqs_wc_asrt = '1') then
		  dqs_wc_r <= '1' after TCQ*1 ps;
	       elsif ((mux_ioconfig_r(0) = '1') and (wrlvl_active_r1 = '0')) then  
                  dqs_wc_r <= not(dqs_wc_r) after TCQ*1 ps;
	       end if;
	    end if;
	 end process;
      end generate;
   end generate;

   gen_wc_ddr2: if ((DRAM_TYPE(1 to 4) /= "DDR3") or (CLKPERF_DLY_USED(1 to 2) /= "ON")) generate
   begin
      process (out_oserdes_wc)
      begin
         dq_wc_r  <= out_oserdes_wc;
         dqs_wc_r <= out_oserdes_wc;
      end process;
   end generate;

   -- DQ_WC is pulsed with rising edge of MUX_WRDATA_EN
   dq_wc  <= dq_wc_r;

   -- DQS_WC has the same timing, except there is an additional term for
   -- write leveling
   dqs_wc <= dqs_wc_r;

   --***************************************************************************
   -- DQS/DQ Output Enable Bitslip
   -- Timing for output enable:
   --  - Enable for DQS: For burst of 8 (over 4 clock cycles), OE is asserted
   --    one cycle before first valid data (i.e. at same time as DQS write
   --    preamble), and deasserted immediately after the last postamble
   --***************************************************************************	       
   gen_ddr3_dqs_ocb: if (DRAM_TYPE(1 to 4) = "DDR3") generate
   begin
      gen_ncwl5_odd: if ((nCWL = 5) and (CLKPERF_DLY_USED = "ON")) generate
      begin
         -- write command sent by MC on channel 1
         -- D3,D4 inputs of the OCB used to send write command to DDR3
         ncwl_odd_loop: for dqs_i in 0 to (DQS_WIDTH-1) generate
               signal xhdl1: std_logic_vector(2 downto 0);		    
         begin
	          xhdl1 <= wr_calib_dly(2*dqs_i + 1 downto 2*dqs_i) & inv_dqs(dqs_i);
            process (clk)
            begin

	       if (clk'event and clk = '1') then
	          if ((rst_delayed(RST_DLY_NUM-1) = '1') or (wrlvl_active_r1 = '1')) then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;			  
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_dq1(dqs_i) <= '1' after TCQ*1 ps;			  
                     ocb_dq2(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq3(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq4(dqs_i) <= '1' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
                  else
		     dm_ce_0(dqs_i) <= (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
                     
		     -- Shift bitslip logic by 1 or 2 clk_mem cycles
                     -- Write calibration currently supports only upto 2 clk_mem cycles
		     case ( xhdl1 ) is
                        -- 0 clk_mem delay required as per write calibration
			when "000" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
                        -- 1 clk_mem delay required as per write calibration
			when "010" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
                        -- 2 clk_mem delay required as per write calibration
			when "100" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- 3 clk_mem delay required as per write calibration
			when "110" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
                        -- 0 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "001" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
                        -- 1 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "011" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
                        -- 2 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "101" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- 3 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "111" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- defaults to 0 clk_mem delay and no DQS inversion
			when others =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
		     end case;
                  end if;
	       end if;
	    end process;
	 end generate;
      end generate;

      gen_ncwl5_noWC: if (((nCWL = 5) or (nCWL = 7) or (nCWL = 9)) 
      			  and (CLKPERF_DLY_USED = "OFF")) generate
      begin	      
         -- Extending tri-state signal at the end when CLKPERF_DELAYED is not used
         -- In this use case the data path goes through the ODELAY whereas the 
         -- tri-state path does not. Hence tri-state must be extended to
         -- compensate for the ODELAY insertion delay and number of taps.
         -- Tri-state signal is asserted for eight and a half clk_mem cycles.
         ncwl_odd_loop: for dqs_i in 0 to (DQS_WIDTH-1) generate
               signal xhdl2: std_logic_vector(2 downto 0);		    
         begin
	          xhdl2 <= wr_calib_dly(2*dqs_i + 1 downto 2*dqs_i) & inv_dqs(dqs_i);
            process (clk)		 
            begin

	       if (clk'event and clk = '1') then
	          if ((rst_delayed(RST_DLY_NUM-1) = '1') or (wrlvl_active_r1 = '1')) then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;			  
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_dq1(dqs_i) <= '1' after TCQ*1 ps;			  
                     ocb_dq2(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq3(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq4(dqs_i) <= '1' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
                  else
		     dm_ce_0(dqs_i) <= (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
                     
		     -- Shift bitslip logic by 1 or 2 clk_mem cycles
                     -- Write calibration currently supports only upto 2 clk_mem cycles
		     case (xhdl2) is
                        -- 0 clk_mem delay required as per write calibration
			when "000" =>     
                           ocb_d1(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
	                   ocb_dq1(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
	                                            wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;

                        -- 1 clk_mem delay required as per write calibration
			when "010" =>    
                           ocb_d1(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq1(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                             wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                             wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                             wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                   	     wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;

                        -- 2 clk_mem delay required as per write calibration
			when "100" =>       
	                   ocb_d1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                 	    wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;

                        -- 3 clk_mem delay required as per write calibration
			when "110" =>  
	                   ocb_d1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                            wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
	                                 	    wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;

                        -- 0 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "001" =>     
	                   ocb_d1(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
		           			 wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
                           ocb_dq1(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			  wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			  wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			  wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (mux_wrdata_en or wrdata_en_r1 or
					 	  wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;

                        -- 1 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "011" =>     
	                   ocb_d1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
		           ocb_dq1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
					 	  wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;

                        -- 2 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "101" =>     
	                   ocb_d1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
		           			 wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
		           ocb_dq1(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
						  wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;

                        -- 3 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "111" =>     
	                   ocb_d1(dqs_i)  <= NOT (wrdata_en_r3 or wrdata_en_r4 or
	                                            wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
		           ocb_dq1(dqs_i)  <= NOT (wrdata_en_r3 or wrdata_en_r4 or
	                                            wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
		           			 wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (wrdata_en_r2 or wrdata_en_r3 or
					 	  wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;

                        -- defaults to 0 clk_mem delay and no DQS inversion
			when others =>     
	                   ocb_d1(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_d4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                            wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq1(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                             wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq2(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                             wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq3(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                             wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
	                   ocb_dq4(dqs_i)  <= NOT (wrdata_en_r1 or wrdata_en_r2 or
	                                   	  wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
		     end case;
                  end if;
	       end if;
	    end process;
	 end generate;
      end generate;

      gen_ncwl7_odd: if (((nCWL = 7) or (nCWL = 9)) and (CLKPERF_DLY_USED = "ON")) generate
      begin	      
         -- write command sent by MC on channel 1
         -- D3,D4 inputs of the OCB used to send write command to DDR3
         ncwl_odd_loop: for dqs_i in 0 to (DQS_WIDTH-1) generate
               signal xhdl3: std_logic_vector(2 downto 0);		    
         begin
	          xhdl3 <= wr_calib_dly(2*dqs_i + 1 downto 2*dqs_i) & inv_dqs(dqs_i);
            process (clk)		 
            begin

	       if (clk'event and clk = '1') then
	          if ((rst_delayed(RST_DLY_NUM-1) = '1') or (wrlvl_active_r1 = '1')) then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;			  
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_dq1(dqs_i) <= '1' after TCQ*1 ps;			  
                     ocb_dq2(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq3(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq4(dqs_i) <= '1' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
                  else
		     dm_ce_0(dqs_i) <= (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;

		     -- Shift bitslip logic by 1 or 2 clk_mem cycles
                     -- Write calibration currently supports only upto 2 clk_mem cycles
		     case (xhdl3) is
                        -- 0 clk_mem delay required as per write calibration
			when "000" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- 1 clk_mem delay required as per write calibration
			when "010" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- 2 clk_mem delay required as per write calibration
			when "100" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
                        -- 3 clk_mem delay required as per write calibration
			when "110" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
                        -- 0 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "001" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- 1 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "011" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- 2 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "101" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
                        -- 3 clk_mem delay required as per write calibration
                        -- DQS inverted during write leveling
			when "111" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
                        -- defaults to 0 clk_mem delay and no DQS inversion
			when others =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
		     end case;
                  end if;
	       end if;
	    end process;
	 end generate;
      end generate;

--      gen_ncwl7_noWC: if (((nCWL = 7) or (nCWL = 9)) and (CLKPERF_DLY_USED = "OFF")) generate
--      begin	      
--         -- Extending tri-state signal at the end when CLKPERF_DELAYED is not used
--         -- In this use case the data path goes through the ODELAY whereas the 
--         -- tri-state path does not. Hence tri-state must be extended to
--         -- compensate for the ODELAY insertion delay and number of taps.
--         -- Tri-state signal is asserted for eight and a half clk_mem cycles.
--         ncwl_odd_loop: for dqs_i in 0 to (DQS_WIDTH-1) generate
--         begin
--            process (clk)		 
--               variable xhdl4: std_logic_vector(2 downto 0);		    
--            begin
--
--	       if (clk'event and clk = '1') then
--	          xhdl4 := wr_calib_dly(2*dqs_i + 1 downto 2*dqs_i) & inv_dqs(dqs_i);
--	          if ((rst_delayed(RST_DLY_NUM-1) = '1') or (wrlvl_active_r1 = '1')) then
--                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;			  
--                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
--                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
--                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
--                     ocb_dq1(dqs_i) <= '1' after TCQ*1 ps;			  
--                     ocb_dq2(dqs_i) <= '1' after TCQ*1 ps;
--                     ocb_dq3(dqs_i) <= '1' after TCQ*1 ps;
--                     ocb_dq4(dqs_i) <= '1' after TCQ*1 ps;
--                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
--                  else
--		     dm_ce_0(dqs_i) <= (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
--
--		     -- Shift bitslip logic by 1 or 2 clk_mem cycles
--                     -- Write calibration currently supports only upto 2 clk_mem cycles
--		     case (xhdl4) is
--                        -- 0 clk_mem delay required as per write calibration
--			when "000" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--                        -- 1 clk_mem delay required as per write calibration
--			when "010" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--                        -- 2 clk_mem delay required as per write calibration
--			when "100" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--                        -- 3 clk_mem delay required as per write calibration
--			when "110" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6 or wrdata_en_r7) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6 or wrdata_en_r7) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--                        -- 0 clk_mem delay required as per write calibration
--                        -- DQS inverted during write leveling
--			when "001" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--                        -- 1 clk_mem delay required as per write calibration
--                        -- DQS inverted during write leveling
--			when "011" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--                        -- 2 clk_mem delay required as per write calibration
--                        -- DQS inverted during write leveling
--			when "101" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--                        -- 3 clk_mem delay required as per write calibration
--                        -- DQS inverted during write leveling
--			when "111" =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
--                        -- defaults to 0 clk_mem delay and no DQS inversion
--			when others =>     
--			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
--			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
--		     end case;
--                  end if;
--	       end if;
--	    end process;
--	 end generate;
--      end generate;

      gen_ncwl_even: if (((nCWL = 6) or (nCWL = 8)) and (CLKPERF_DLY_USED = "ON")) generate
      begin	      
         ncwl_even_loop: for dqs_i in 0 to (DQS_WIDTH-1) generate
               signal xhdl5: std_logic_vector(2 downto 0);		    
         begin
	          xhdl5 <= wr_calib_dly(2*dqs_i + 1 downto 2*dqs_i) & inv_dqs(dqs_i);
            process (clk)		 
            begin

	       if (clk'event and clk = '1') then
	          if ((rst_delayed(RST_DLY_NUM-1) = '1') or (wrlvl_active_r1 = '1')) then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;			  
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_dq1(dqs_i) <= '1' after TCQ*1 ps;			  
                     ocb_dq2(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq3(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq4(dqs_i) <= '1' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
                  else
		     dm_ce_0(dqs_i) <= (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;

		     -- Shift bitslip logic by 1 or 2 clk_mem cycles
		     case (xhdl5) is
			when "000" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			when "010" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			when "100" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			when "110" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
                        -- DQS inverted during write leveling
			when "001" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			when "011" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			when "101" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			when "111" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			when others =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
		     end case;
                  end if;
	       end if;
	    end process;
	 end generate;
      end generate;

      gen_ncwl_noWC: if (((nCWL = 6) or (nCWL = 8)) and (CLKPERF_DLY_USED = "OFF")) generate
         -- Extending tri-state signal at the end when CLKPERF_DELAYED is not used
         -- In this use case the data path goes through the ODELAY whereas the 
         -- tri-state path does not. Hence tri-state must be extended to
         -- compensate for the ODELAY insertion delay and number of taps.
         -- Tri-state signal is asserted for eight and a half clk_mem cycles.
         ncwl_odd_loop: for dqs_i in 0 to (DQS_WIDTH-1) generate
               signal xhdl6: std_logic_vector(2 downto 0);
         begin
	          xhdl6 <= wr_calib_dly(2*dqs_i + 1 downto 2*dqs_i) & inv_dqs(dqs_i);
            process (clk)		 
            begin

	       if (clk'event and clk = '1') then
	          if ((rst_delayed(RST_DLY_NUM-1) = '1') or (wrlvl_active_r1 = '1')) then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;			  
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_dq1(dqs_i) <= '1' after TCQ*1 ps;			  
                     ocb_dq2(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq3(dqs_i) <= '1' after TCQ*1 ps;
                     ocb_dq4(dqs_i) <= '1' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
                  else
		     dm_ce_0(dqs_i) <= (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;

		     -- Shift bitslip logic by 1 or 2 clk_mem cycles
		     case (xhdl6) is
			when "000" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			when "010" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			when "100" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			when "110" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
                        -- DQS inverted during write leveling
			when "001" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (mux_wrdata_en or wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
			when "011" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			when "101" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			when "111" =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5 or wrdata_en_r6) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4 or wrdata_en_r5) after TCQ*1 ps;
			when others =>     
			   ocb_d1(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq1(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
			   ocb_dq4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3 or wrdata_en_r4) after TCQ*1 ps;
		     end case;
                  end if;
	       end if;
	    end process;
	 end generate;
      end generate;
   end generate;


   gen_ddr2_dqs_wc: if (DRAM_TYPE(1 to 4) /= "DDR3") generate
   begin
      gen_ncwl_even: if (nCWL = 2) generate
      begin
         ncwl_2: for dqs_i in 0 to (DQS_WIDTH-1) generate
         begin
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  if (rst_delayed(RST_DLY_NUM-1) = '1') then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
	          else   
		     ocb_d1(dqs_i) <= NOT (wrdata_en_r1) after TCQ*1 ps;
		     ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or mux_wrdata_en) after TCQ*1 ps;
		     ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or mux_wrdata_en) after TCQ*1 ps;
		     ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or mux_wrdata_en) after TCQ*1 ps;
		     dm_ce_0(dqs_i) <= (wrdata_en_r1 or wrdata_en_r2 or mux_wrdata_en) after TCQ*1 ps;
		  end if;
	       end if;
	    end process;
	 end generate;
      end generate;
            
      gen_ncwl_3: if (nCWL = 3) generate
      begin
         -- write command sent by MC on channel 1
         -- D3,D4 inputs of the OCB used to send write command to DDR3	      
         ncwl_3: for dqs_i in 0 to (DQS_WIDTH-1) generate
         begin
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  if (rst_delayed(RST_DLY_NUM-1) = '1') then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
	          else   
		     ocb_d1(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d3(dqs_i) <= NOT (wrdata_en_r1) after TCQ*1 ps;
		     ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or mux_wrdata_en) after TCQ*1 ps;
		     dm_ce_0(dqs_i) <= (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
		  end if;
	       end if;
	    end process;
	 end generate;
      end generate; --block: ncwl_odd_loop

      gen_ncwl_4: if (nCWL = 4) generate
      begin
         ncwl_4: for dqs_i in 0 to (DQS_WIDTH-1) generate
         begin
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  if (rst_delayed(RST_DLY_NUM-1) = '1') then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
	          else   
		     ocb_d1(dqs_i) <= NOT (wrdata_en_r2) after TCQ*1 ps;
		     ocb_d2(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
		     dm_ce_0(dqs_i) <= (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
		  end if;
	       end if;
	    end process;
	 end generate;
      end generate;

      gen_ncwl_5: if (nCWL = 5) generate
      begin
         -- write command sent by MC on channel 1
         -- D3,D4 inputs of the OCB used to send write command to DDR3
         ncwl_5: for dqs_i in 0 to (DQS_WIDTH-1) generate
         begin
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  if (rst_delayed(RST_DLY_NUM-1) = '1') then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
	          else   
		     ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d3(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d4(dqs_i) <= NOT (wrdata_en_r1 or wrdata_en_r2) after TCQ*1 ps;
		     dm_ce_0(dqs_i) <= (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
		  end if;
	       end if;
	    end process;
	 end generate;
      end generate;

      gen_ncwl_6: if (nCWL = 6) generate
      begin
         ncwl_6: for dqs_i in 0 to (DQS_WIDTH-1) generate
         begin
            process (clk)
            begin
               if (clk'event and clk = '1') then
                  if (rst_delayed(RST_DLY_NUM-1) = '1') then
                     ocb_d1(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d2(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d3(dqs_i) <= '0' after TCQ*1 ps;
                     ocb_d4(dqs_i) <= '0' after TCQ*1 ps;
                     dm_ce_0(dqs_i) <= '0' after TCQ*1 ps;
	          else   
		     ocb_d1(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d2(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d3(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r2) after TCQ*1 ps;
		     ocb_d4(dqs_i) <= NOT (wrdata_en_r3 or wrdata_en_r2) after TCQ*1 ps;
		     dm_ce_0(dqs_i) <= (wrdata_en_r1 or wrdata_en_r2 or wrdata_en_r3) after TCQ*1 ps;
		  end if;
	       end if;
	    end process;
	 end generate;
      end generate;
   end generate; --block: gen_ddr2_dqs_wc

   process (clk)
   begin
      if (clk'event and clk = '1') then 	   
         wrlvl_active_r1 <= wrlvl_active after TCQ*1 ps;
         wrlvl_active_r2 <= wrlvl_active_r1 after TCQ*1 ps;
         wrlvl_done_r1   <= wrlvl_done after TCQ*1 ps;
         wrlvl_done_r2   <= wrlvl_done_r1 after TCQ*1 ps;
         wrlvl_done_r3   <= wrlvl_done_r2 after TCQ*1 ps;
      end if;
   end process;

   -- Staging dm_ce based on CWL.
   -- For lower CWL in DDR2 FF stages are removed to
   -- send the DM out on correct time.
   DDR3_DM: if (DRAM_TYPE(1 to 4) = "DDR3") generate
   begin
      process (dm_ce_0)
      begin
         dm_ce <= dm_ce_0;
      end process;
   end generate;

   DDR2_DM: if (DRAM_TYPE(1 to 4) = "DDR2") generate
   begin
      nCWL_5up: if (nCWL >= 5) generate
      begin	      
         process (clk)
         begin
            if (clk'event and clk = '1') then		 
               dm_ce_r <= dm_ce_0 after TCQ*1 ps;
               dm_ce <= dm_ce_r after TCQ*1 ps;
       end if;   
         end process;
      end generate;	 
      nCWL_3n4: if ((nCWL = 3) or (nCWL = 4)) generate
      begin	      
         process (clk)
         begin
            if (clk'event and clk = '1') then		 
               dm_ce <= dm_ce_0 after TCQ*1 ps;
	    end if;
         end process;
      end generate;
      nCWL_2: if (nCWL = 2) generate
      begin
         process (dm_ce_0)
         begin
            dm_ce <= dm_ce_0;
         end process;
      end generate;
   end generate;   

   -- NOTE: Restructure/retime later to improve timing
   DDR3_TRISTATE: if (DRAM_TYPE = "DDR3") generate
      gen_oe: for dqs_cnt_i in 0 to (DQS_WIDTH-1) generate
      begin
         dqs_oe_n((dqs_cnt_i*4) + 0) <= ocb_d1(dqs_cnt_i);
         dqs_oe_n((dqs_cnt_i*4) + 1) <= ocb_d2(dqs_cnt_i);
         dqs_oe_n((dqs_cnt_i*4) + 2) <= ocb_d3(dqs_cnt_i);
         dqs_oe_n((dqs_cnt_i*4) + 3) <= ocb_d4(dqs_cnt_i);
         dq_oe_n((dqs_cnt_i*4) + 0)  <= ocb_dq1(dqs_cnt_i); 
         dq_oe_n((dqs_cnt_i*4) + 1)  <= ocb_dq2(dqs_cnt_i);
         dq_oe_n((dqs_cnt_i*4) + 2)  <= ocb_dq3(dqs_cnt_i);
         dq_oe_n((dqs_cnt_i*4) + 3)  <= ocb_dq4(dqs_cnt_i);
      end generate;
   end generate;

   DDR2_TRISTATE: if (DRAM_TYPE = "DDR2") generate
      gen_oe: for dqs_cnt_i in 0 to (DQS_WIDTH-1) generate
      begin
         dqs_oe_n((dqs_cnt_i*4) + 0) <= ocb_d1(dqs_cnt_i);
         dqs_oe_n((dqs_cnt_i*4) + 1) <= ocb_d2(dqs_cnt_i);
         dqs_oe_n((dqs_cnt_i*4) + 2) <= ocb_d3(dqs_cnt_i);
         dqs_oe_n((dqs_cnt_i*4) + 3) <= ocb_d4(dqs_cnt_i);
         dq_oe_n((dqs_cnt_i*4) + 0)  <= ocb_d1(dqs_cnt_i); 
         dq_oe_n((dqs_cnt_i*4) + 1)  <= ocb_d2(dqs_cnt_i);
         dq_oe_n((dqs_cnt_i*4) + 2)  <= ocb_d3(dqs_cnt_i);
         dq_oe_n((dqs_cnt_i*4) + 3)  <= ocb_d4(dqs_cnt_i);
      end generate;
   end generate;

   -- signal used to assert DQS for write leveling.
   -- the DQS will be asserted once every 16 clock cycles.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then	      
            wr_level_dqs_asrt_r <= '0' after TCQ*1 ps;
            dqs_wc_asrt         <= '0' after TCQ*1 ps;
            dqs_wc_deasrt       <= '0' after TCQ*1 ps;
	 else
	    wr_level_dqs_asrt_r <= (wr_level_dqs_stg_r(19) and wrlvl_active_r1) after TCQ*1 ps; 
            dqs_wc_asrt         <= (wr_level_dqs_stg_r(15) and wrlvl_active_r1) after TCQ*1 ps; 
            dqs_wc_deasrt       <= (wr_level_dqs_stg_r(16) and wrlvl_active_r1) after TCQ*1 ps; 
	 end if;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then	      
            dqs_asrt_cnt <= "00" after TCQ*1 ps;
         elsif ((wr_level_dqs_asrt_r = '1') and (dqs_asrt_cnt /= "11")) then
	    dqs_asrt_cnt <= dqs_asrt_cnt + '1' after TCQ*1 ps;
	 end if;
      end if;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if ((rst = '1') or (wrlvl_active = '0'))then	      
            wr_lvl_start <= '0' after TCQ*1 ps;
         elsif (dqs_asrt_cnt = "11") then
	    wr_lvl_start <= '1' after TCQ*1 ps;
	 end if;
      end if;
   end process;

   -- shift register that is used to assert the DQS once every
   -- 16 clock cycles during write leveling.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then	      
            wr_level_dqs_stg_r <= "10000000000000000000" after TCQ*1 ps;
         else
	    wr_level_dqs_stg_r <= (wr_level_dqs_stg_r(18 downto 0) & wr_level_dqs_stg_r(19)) after TCQ*1 ps;
	 end if;
      end if;
   end process;

   gen_dqs_r_i: for dqs_r_i in 0 to (DQS_WIDTH-1) generate
   begin
      gen_ddr3_dqs: if (DRAM_TYPE(1 to 4) = "DDR3") generate	   
      begin
         process (clk)
         begin
            if (clk'event and clk = '1') then
               if (rst = '1') then		 
                  dqs_rst((dqs_r_i*4) + 0) <= '0' after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 1) <= '0' after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 2) <= '0' after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 3) <= '0' after TCQ*1 ps;
               elsif (inv_dqs(dqs_r_i) = '1') then
                  dqs_rst((dqs_r_i*4) + 0) <= ((wr_level_dqs_stg_r(19) and wrlvl_active_r1) or (not(wrlvl_active_r1))) after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 1) <= '0' after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 2) <= ((wr_level_dqs_stg_r(19) and wrlvl_active_r1) or (not(wrlvl_active_r1))) after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 3) <= '0' after TCQ*1 ps;
               elsif (inv_dqs(dqs_r_i) = '0') then
                  dqs_rst((dqs_r_i*4) + 0) <= '0' after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 1) <= ((wr_level_dqs_stg_r(19) and wrlvl_active_r1) or (not(wrlvl_active_r1))) after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 2) <= '0' after TCQ*1 ps;
                  dqs_rst((dqs_r_i*4) + 3) <= ((wr_level_dqs_stg_r(19) and wrlvl_active_r1) or (not(wrlvl_active_r1))) after TCQ*1 ps;
               end if;
            end if;
         end process;
      end generate;
      gen_ddr2_dqs: if (DRAM_TYPE(1 to 4) /= "DDR3") generate
      begin
         dqs_rst((dqs_r_i*4) +0) <= '0';
         dqs_rst((dqs_r_i*4) +1) <= '1' when ((wr_level_dqs_asrt_r='1') or (wrlvl_active_r2='0')) else '0';
         dqs_rst((dqs_r_i*4) +2) <= '0';         
         dqs_rst((dqs_r_i*4) +3) <= '1' when (wrlvl_active_r2='0') else '0';
      end generate;
   end generate;

   --***************************************************************************
   -- Format write data/mask: Data is in format: {fall, rise}
   --***************************************************************************
   gen_wrdata_mask_rdimm: if ((DRAM_TYPE = "DDR3") and (REG_CTRL = "ON")) generate

      process (mc_data_sel,phy_wrdata_r,phy_wrdata,dfi_wrdata_r,dfi_wrdata)
      begin
         if ((mc_data_sel = '0') and (nCWL = 9)) then
            wr_data_rise0 <= phy_wrdata_r((DQ_WIDTH-1) downto 0);
            wr_data_fall0 <= phy_wrdata_r((2*DQ_WIDTH)-1 downto DQ_WIDTH);
            wr_data_rise1 <= phy_wrdata_r((3*DQ_WIDTH)-1 downto 2*DQ_WIDTH);
            wr_data_fall1 <= phy_wrdata_r((4*DQ_WIDTH)-1 downto 3*DQ_WIDTH);
         else
            if (mc_data_sel = '0') then
               wr_data_rise0 <= phy_wrdata((DQ_WIDTH-1) downto 0);
               wr_data_fall0 <= phy_wrdata((2*DQ_WIDTH)-1 downto DQ_WIDTH);
               wr_data_rise1 <= phy_wrdata((3*DQ_WIDTH)-1 downto 2*DQ_WIDTH);
               wr_data_fall1 <= phy_wrdata((4*DQ_WIDTH)-1 downto 3*DQ_WIDTH);
            else
	       if ((nCWL = 7) or (nCWL = 9)) then
                  wr_data_rise0 <= dfi_wrdata_r((DQ_WIDTH-1) downto 0);
                  wr_data_fall0 <= dfi_wrdata_r((2*DQ_WIDTH)-1 downto DQ_WIDTH);
                  wr_data_rise1 <= dfi_wrdata_r((3*DQ_WIDTH)-1 downto 2*DQ_WIDTH);
                  wr_data_fall1 <= dfi_wrdata_r((4*DQ_WIDTH)-1 downto 3*DQ_WIDTH);
	       else
                  wr_data_rise0 <= dfi_wrdata((DQ_WIDTH-1) downto 0);
                  wr_data_fall0 <= dfi_wrdata((2*DQ_WIDTH)-1 downto DQ_WIDTH);
                  wr_data_rise1 <= dfi_wrdata((3*DQ_WIDTH)-1 downto 2*DQ_WIDTH);
                  wr_data_fall1 <= dfi_wrdata((4*DQ_WIDTH)-1 downto 3*DQ_WIDTH);
	       end if;
	    end if;
	 end if;
      end process;

      mask_data_rise0 <= (others => '0')                            when (mc_data_sel = '0') else
                         dfi_wrdata_mask_r((DQ_WIDTH/8)-1 downto 0) when ((mc_data_sel = '1') and ((REG_CTRL = "ON") and ((nCWL = 7) or (nCWL = 9)))) else 
                         dfi_wrdata_mask((DQ_WIDTH/8)-1 downto 0);  
      mask_data_fall0 <= (others => '0')                                         when (mc_data_sel = '0') else
                         dfi_wrdata_mask_r(2*(DQ_WIDTH/8)-1 downto (DQ_WIDTH/8)) when ((mc_data_sel = '1') and 
			 							       ((REG_CTRL = "ON") and ((nCWL = 7) or (nCWL = 9)))) else 
                         dfi_wrdata_mask(2*(DQ_WIDTH/8)-1 downto (DQ_WIDTH/8));  
      mask_data_rise1 <= (others => '0')                                           when (mc_data_sel = '0') else
                         dfi_wrdata_mask_r(3*(DQ_WIDTH/8)-1 downto 2*(DQ_WIDTH/8)) when ((mc_data_sel = '1') and 
			 							         ((REG_CTRL = "ON") and ((nCWL = 7) or (nCWL = 9)))) else 
                         dfi_wrdata_mask(3*(DQ_WIDTH/8)-1 downto 2*(DQ_WIDTH/8));  
      mask_data_fall1 <= (others => '0')                                           when (mc_data_sel = '0') else
                         dfi_wrdata_mask_r(4*(DQ_WIDTH/8)-1 downto 3*(DQ_WIDTH/8)) when ((mc_data_sel = '1') and 
			 							         ((REG_CTRL = "ON") and ((nCWL = 7) or (nCWL = 9)))) else 
                         dfi_wrdata_mask (4*(DQ_WIDTH/8)-1 downto 3*(DQ_WIDTH/8));  
   end generate;

   gen_wrdata_mask_udimm: if (not(DRAM_TYPE = "DDR3") or not(REG_CTRL = "ON")) generate      
      wr_data_rise0 <= dfi_wrdata(DQ_WIDTH-1 downto 0) when (mc_data_sel = '1') else
                       phy_wrdata(DQ_WIDTH-1 downto 0);
      wr_data_fall0 <= dfi_wrdata((2*DQ_WIDTH)-1 downto DQ_WIDTH) when (mc_data_sel = '1') else
                       phy_wrdata((2*DQ_WIDTH)-1 downto DQ_WIDTH);
      wr_data_rise1 <= dfi_wrdata((3*DQ_WIDTH)-1 downto 2*DQ_WIDTH) when (mc_data_sel = '1') else
                       phy_wrdata((3*DQ_WIDTH)-1 downto 2*DQ_WIDTH);
      wr_data_fall1 <= dfi_wrdata((4*DQ_WIDTH)-1 downto 3*DQ_WIDTH) when (mc_data_sel = '1') else
                       phy_wrdata((4*DQ_WIDTH)-1 downto 3*DQ_WIDTH);

      mask_data_rise0 <= dfi_wrdata_mask((DQ_WIDTH/8)-1 downto 0) when (mc_data_sel = '1') else
           	      (others => '0');
      mask_data_fall0 <= dfi_wrdata_mask(2*(DQ_WIDTH/8)-1 downto (DQ_WIDTH/8)) when (mc_data_sel = '1') else
           	      (others => '0');
      mask_data_rise1 <= dfi_wrdata_mask(3*(DQ_WIDTH/8)-1 downto 2*(DQ_WIDTH/8)) when (mc_data_sel = '1') else
           	      (others => '0');
      mask_data_fall1 <= dfi_wrdata_mask(4*(DQ_WIDTH/8)-1 downto 3*(DQ_WIDTH/8)) when (mc_data_sel = '1') else
		      (others => '0');
   end generate; 

end trans;

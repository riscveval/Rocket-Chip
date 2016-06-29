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
--  /   /         Filename: phy_pd.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   This module is replicated in phy_pd_top for each DQS signal.  This module
--   contains the logic that calibrates PD (moves DQS such that clk_cpt rising
--   edge is aligned with DQS rising edge) and maintains this phase relationship
--   by moving clk_cpt as necessary.
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_pd.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_pd.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_pd is
   generic (
      TCQ             : integer := 100;
      SIM_CAL_OPTION  : string  := "NONE";  -- "NONE", "FAST_CAL", "SKIP_CAL" (same as "NONE")
      PD_LHC_WIDTH    : integer := 16       -- synth low & high cntr physical width
   );
   port (
      dbg_pd		  : out std_logic_vector(99 downto 0);	-- debug signals
      dqs_dly_val_in	  : in  std_logic_vector(4 downto 0);
      dqs_dly_val	  : out std_logic_vector(4 downto 0);
      pd_en_maintain	  : out std_logic;			-- maintenance enable
      pd_incdec_maintain  : out std_logic;  			-- maintenance inc/dec
      pd_cal_done	  : out std_logic;         		-- calibration done (level)
      pd_cal_start	  : in  std_logic;        		-- calibration start (pulse or level)
      dfi_init_complete	  : in  std_logic;
      pd_read_valid	  : in  std_logic;       		-- advance cntrs only when true
      trip_points	  : in  std_logic_vector(1 downto 0);   -- the 2 rising clock samples of the nibble

      -- Debug 
      dbg_pd_off	  : in  std_logic;
      dbg_pd_maintain_off : in  std_logic;
      dbg_pd_inc_cpt	  : in  std_logic;      		-- one clk period pulse
      dbg_pd_dec_cpt	  : in  std_logic;      		-- one clk period pulse
      dbg_pd_inc_dqs	  : in  std_logic;      		-- one clk period pulse
      dbg_pd_dec_dqs	  : in  std_logic;      		-- one clk period pulse
      dbg_pd_disab_hyst   : in  std_logic;
      dbg_pd_msb_sel      : in  std_logic_vector(3 downto 0);	-- selects effective msb of high & 
                                      				-- low cntrs
      clk		  : in  std_logic;                 	-- clkmem/2
      rst                 : in  std_logic
   ); 
end phy_pd; 

architecture trans of phy_pd is

   -- merge two SIM_CAL_OPTION values into new localparam
   function CALC_FAST_SIM return string is
   begin
      if ((SIM_CAL_OPTION = "FAST_CAL") or (SIM_CAL_OPTION = "FAST_WIN_DETECT")) then
	 return "YES";
      else
	 return "NO";
      end if;
   end function CALC_FAST_SIM;

   constant FAST_SIM 	 : string := CALC_FAST_SIM;

   -- width of low and high counters
   function CALC_LHC_WIDTH return integer is
   begin
      if (FAST_SIM = "YES") then
	 return (6);
      else
	 return PD_LHC_WIDTH;
      end if;
   end function CALC_LHC_WIDTH;

   -- width of calibration done counter (6 for synthesis, less for simulation)
   function CALC_CDC_WIDTH return integer is
   begin
      if (FAST_SIM = "YES") then
         return (3);
      else
         return (6);
      end if;
   end function CALC_CDC_WIDTH;

   --***************************************************************************
   -- Local parameters (other than state assignments)
   --***************************************************************************   
   constant LHC_WIDTH    : integer := CALC_LHC_WIDTH;
   constant CDC_WIDTH    : integer := CALC_CDC_WIDTH;
   constant RVPLS_WIDTH  : integer := 1;	-- this controls the pipeline delay of pd_read_valid
                              			-- set to 1 for normal operation

  --***************************************************************************
   -- pd state assignments
   --***************************************************************************
   constant PD_IDLE      : std_logic_vector(2 downto 0) := "000";
   constant PD_CLR_CNTRS : std_logic_vector(2 downto 0) := "001";
   constant PD_INC_CNTRS : std_logic_vector(2 downto 0) := "010";
   constant PD_UPDATE    : std_logic_vector(2 downto 0) := "011";
   constant PD_WAIT      : std_logic_vector(2 downto 0) := "100";   

   --***************************************************************************
   -- constants for pd_done logic
   --***************************************************************************
   constant PD_DONE_IDLE : std_logic_vector(3 downto 0) := "0000";
   constant PD_DONE_MAX  : std_logic_vector(3 downto 0) := "1010";

   --***************************************************************************
   -- Internal signals
   --***************************************************************************   
   signal pd_en_maintain_d	: std_logic;
   signal pd_incdec_maintain_d  : std_logic;
   signal low_d			: std_logic_vector(LHC_WIDTH-1 downto 0);
   signal high_d		: std_logic_vector(LHC_WIDTH-1 downto 0);
   signal ld_dqs_dly_val_r	: std_logic;				-- combinatorial
   signal dqs_dly_val_r		: std_logic_vector(4 downto 0);
   signal pd_cal_done_i		: std_logic;       			-- pd_cal_done internal
   signal first_calib_sample	: std_logic;
   signal rev_direction		: std_logic;
   signal rev_direction_ce	: std_logic;
   signal pd_en_calib		: std_logic;         			-- calibration enable
   signal pd_incdec_calib	: std_logic;     			-- calibration inc/dec
   signal pd_en			: std_logic;
   signal pd_incdec		: std_logic;
   signal reset			: std_logic;               		-- rst is synchronized to clk
   signal pd_state_r		: std_logic_vector(2 downto 0);
   signal pd_next_state		: std_logic_vector(2 downto 0);       	-- combinatorial
   signal low			: std_logic_vector(LHC_WIDTH-1 downto 0);-- low counter
   signal high			: std_logic_vector(LHC_WIDTH-1 downto 0);-- high counter
   signal samples_done		: std_logic;
   signal samples_done_pl	: std_logic_vector(2 downto 0);
   signal inc_cntrs		: std_logic;
   signal clr_low_high		: std_logic;
   signal low_high_ce		: std_logic;
   signal update_phase		: std_logic;
   signal calib_done_cntr	: std_logic_vector(CDC_WIDTH-1 downto 0);
   signal calib_done_cntr_inc	: std_logic;
   signal calib_done_cntr_ce	: std_logic;
   signal high_ge_low		: std_logic;
   signal l_addend		: std_logic_vector(1 downto 0);
   signal h_addend		: std_logic_vector(1 downto 0);
   signal read_valid_pl		: std_logic;
   signal enab_maintenance	: std_logic;

   signal pd_done_state_r	: std_logic_vector(3 downto 0);
   signal pd_done_next_state	: std_logic_vector(3 downto 0);
   signal pd_incdec_done	: std_logic;       			-- combinatorial
   signal pd_incdec_done_next	: std_logic;  				-- combinatorial
   signal block_change		: std_logic;
   signal low_nearly_done	: std_logic;
   signal high_nearly_done	: std_logic;
   signal pd_incdec_tp		: std_logic;

   signal low_done		: std_logic;				-- PD_DEBUG not defined
   signal high_done		: std_logic;
   signal hyst_mux_sel          : std_logic_vector(3 downto 0);
   signal mux_sel               : std_logic_vector(3 downto 0);
   signal low_mux               : std_logic;                            -- combinatorial
   signal high_mux              : std_logic;                            -- combinatorial
   signal low_nearly_done_r     : std_logic;
   signal high_nearly_done_r    : std_logic;

begin

   --***************************************************************************
   -- low_done and high_done
   --***************************************************************************

   -- select MSB during calibration - during maintanence,
   -- determined by dbg_pd_msb_sel. Add case to handle
   -- fast simulation to prevent overflow of counter
   -- since LHC_WIDTH is set to small value for fast sim
   mux_sel <= dbg_pd_msb_sel when ((pd_cal_done_i = '1') and not(FAST_SIM = "YES")) else 
	      std_logic_vector(to_unsigned((LHC_WIDTH-1),4));
  
   process (mux_sel,low)
   begin
         low_mux <= low(to_integer(unsigned(mux_sel)));
   end process;      

   process (mux_sel,high)
   begin
         high_mux <= high(to_integer(unsigned(mux_sel)));
   end process;      

   process(clk)
   begin
      if (clk'event and clk = '1') then	   
         if (clr_low_high = '1') then
	    low_done  <= '0' after TCQ*1 ps;
	    high_done <= '0' after TCQ*1 ps;
         else
	    low_done  <= low_mux after TCQ*1 ps;
            high_done <= high_mux after TCQ*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- block_change (hysteresis) logic
   --***************************************************************************
   -- select MSB used to determine hysteresis level. Add case to handle
   -- fast simulation to prevent out-of-bounds index since LHC_WIDTH is set 
   -- to small value for fast sim. If DEBUG PORT is disabled, dbg_pd_msb_sel
   -- must be hardcoded to appropriate value in upper-level module. 
   hyst_mux_sel <= std_logic_vector(to_unsigned((LHC_WIDTH-2), 4)) when (FAST_SIM = "YES") else
		   (dbg_pd_msb_sel-'1');
   process (hyst_mux_sel,low)
   begin
         low_nearly_done <= low(to_integer(unsigned(hyst_mux_sel)));
   end process;      

   process (hyst_mux_sel,high)
   begin
         high_nearly_done <= high(to_integer(unsigned(hyst_mux_sel)));
   end process;      

   -- pipeline low_nearly_done and high_nearly_done
   process(clk)
   begin
      if (clk'event and clk = '1') then	   
         if ((reset = '1') or (dbg_pd_disab_hyst = '1')) then
	    low_nearly_done_r  <= '0' after TCQ*1 ps;
	    high_nearly_done_r <= '0' after TCQ*1 ps;
         else
	    low_nearly_done_r  <= low_nearly_done after TCQ*1 ps;
            high_nearly_done_r <= high_nearly_done after TCQ*1 ps;
         end if;
      end if;
   end process;   

   block_change <= ((high_done and low_done) or low_nearly_done_r) when (high_done='1') else 
		   ((high_done and low_done) or high_nearly_done_r);

   --***************************************************************************
   -- samples_done and high_ge_low
   --***************************************************************************
   samples_done <= (low_done or high_done) and not(clr_low_high); -- ~clr_low_high makes samples_done de-assert one cycle sooner
   high_ge_low  <= high_done;

   --***************************************************************************
   -- Debug
   --***************************************************************************

   -- Temporary debug assignments and logic - remove for release code.

   -- Disabling of PD is allowed either before or after calibration
   -- Usage: dbg_pd_off = 1 to disable PD. If disabled prior to initialization
   --  it should remain off - turning it on later will result in bad behavior
   --  since the DQS early/late tap delays will not have been properly initialized.
   --  If disabled after initial calibration, it can later be re-enabled
   --  without reseting the system.
  
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            pd_incdec_tp <= '0' after TCQ*1 ps;
	 elsif (pd_en = '1') then
            pd_incdec_tp <= pd_incdec after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   dbg_pd(0)     <= pd_en;
   dbg_pd(1)     <= pd_incdec;
   dbg_pd(2)     <= pd_cal_done_i;
   dbg_pd(3)     <= pd_cal_start;
   dbg_pd(4)     <= samples_done;
   dbg_pd(5)     <= inc_cntrs;
   dbg_pd(6)     <= clr_low_high;
   dbg_pd(7)     <= low_high_ce;
   dbg_pd(8)     <= update_phase;
   dbg_pd(9)     <= calib_done_cntr_inc;
   dbg_pd(10)    <= calib_done_cntr_ce;
   dbg_pd(11)    <= first_calib_sample;
   dbg_pd(12)    <= rev_direction;
   dbg_pd(13)    <= rev_direction_ce;
   dbg_pd(14)    <= pd_en_calib;
   dbg_pd(15)    <= pd_incdec_calib;
   dbg_pd(16)    <= read_valid_pl;
   dbg_pd(17)    <= pd_read_valid;
   dbg_pd(18)    <= pd_incdec_tp;
   dbg_pd(19)    <= block_change;

   dbg_pd(20)    	<= low_nearly_done_r;
   dbg_pd(21)    	<= high_nearly_done_r;
   dbg_pd(23 downto 22) <= (others => '0');                        -- spare scalor bits
   dbg_pd(29 downto 24) <= ('0' & dqs_dly_val_r);                  -- 1 spare bit
   dbg_pd(33 downto 30) <= ('0' & pd_state_r);                     -- 1 spare bit
   dbg_pd(37 downto 34) <= ('0' & pd_next_state);                  -- 1 spare bit
   gen_LHC_WIDTH_6: if (LHC_WIDTH = 6) generate   
      dbg_pd(53 downto 44) <= (others => '0');         
      dbg_pd(69 downto 60) <= (others => '0');         
      dbg_pd(43 downto 38) <= high; 
      dbg_pd(59 downto 54) <= low; 
   end generate;
   gen_LHC_WIDTH_16: if (LHC_WIDTH = 16) generate   
      dbg_pd(53 downto 38) <= high;                                -- 16 bits max
      dbg_pd(69 downto 54) <= low;                                 -- 16 bits max
   end generate;
   dbg_pd(73 downto 70) <= pd_done_state_r;
   dbg_pd(74+CDC_WIDTH-1 downto 74) <= calib_done_cntr;
   dbg_pd(81 downto 74+CDC_WIDTH)     <= (others => '0');          --  8 bits max
   dbg_pd(83 downto 82) <= l_addend;
   dbg_pd(85 downto 84) <= h_addend;
   dbg_pd(87 downto 86) <= trip_points;
   dbg_pd(99 downto 88) <= (others => '0');                        -- spare

   --***************************************************************************
   -- pd_read_valid pipeline shifter
   --***************************************************************************
   gen_rvpls: if (RVPLS_WIDTH = 0) generate
      read_valid_pl <= pd_read_valid;
   end generate;

   gen_rvpls_1: if (RVPLS_WIDTH = 1) generate
      signal read_valid_shftr : std_logic_vector(RVPLS_WIDTH-1 downto 0);
   begin

      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (reset = '1') then
               read_valid_shftr(0) <= '0' after TCQ*1 ps;
            else
               read_valid_shftr(0) <= pd_read_valid after TCQ*1 ps;
	    end if;
	 end if;
      end process;

      read_valid_pl <= read_valid_shftr(RVPLS_WIDTH-1);
   end generate;

   gen_rvpls_gt1: if (not(RVPLS_WIDTH = 0) and not(RVPLS_WIDTH = 1)) generate
      signal read_valid_shftr : std_logic_vector(RVPLS_WIDTH-1 downto 0);
   begin

      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (reset = '1') then
               read_valid_shftr <= (others => '0') after TCQ*1 ps;
            else
               read_valid_shftr <= (read_valid_shftr(RVPLS_WIDTH-2 downto 0) & pd_read_valid) after TCQ*1 ps;
	    end if;
	 end if;
      end process;

      read_valid_pl <= read_valid_shftr(RVPLS_WIDTH-1);
   end generate;

   --***************************************************************************
   -- phase shift interface
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            pd_en <= '0' after TCQ*1 ps;
         else
            pd_en <= update_phase after TCQ*1 ps;
         end if;
      end if;
   end process;
   pd_incdec <= high_ge_low;

   --***************************************************************************
   -- inc/dec control
   --***************************************************************************
   rev_direction_ce <= first_calib_sample and pd_en and (pd_incdec xnor dqs_dly_val_r(4));

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            first_calib_sample <= '1' after TCQ*1 ps;
            rev_direction      <= '0' after TCQ*1 ps;
         else
            if (pd_en = '1') then		 
               first_calib_sample <= '0' after TCQ*1 ps;
            end if;
	    if (rev_direction_ce = '1') then
	       rev_direction <= '1' after TCQ*1 ps;
            end if;	       
         end if;
      end if;
   end process;   

   pd_en_calib          <= (pd_en and not(pd_cal_done_i) and not(first_calib_sample)) or dbg_pd_inc_dqs or dbg_pd_dec_dqs;
   pd_incdec_calib      <= (pd_incdec xor rev_direction) or dbg_pd_inc_dqs;

   enab_maintenance     <= dfi_init_complete and not(dbg_pd_maintain_off);
   pd_en_maintain_d     <= (pd_en and pd_cal_done_i and enab_maintenance and not(block_change)) or dbg_pd_inc_cpt or dbg_pd_dec_cpt;
   pd_incdec_maintain_d <= (not(pd_incdec_calib) or dbg_pd_inc_cpt) and not(dbg_pd_dec_cpt);

   process (clk)	-- pipeline maintenance control signals
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            pd_en_maintain     <= '0' after TCQ*1 ps;
            pd_incdec_maintain <= '0' after TCQ*1 ps;
         else
            pd_en_maintain     <= pd_en_maintain_d after TCQ*1 ps;
            pd_incdec_maintain <= pd_incdec_maintain_d after TCQ*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- dqs delay value counter
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            dqs_dly_val_r <= (others => '0') after TCQ*1 ps;
         elsif (ld_dqs_dly_val_r = '1') then
            dqs_dly_val_r <= dqs_dly_val_in after TCQ*1 ps;
         else
            if (pd_en_calib = '1') then
	       if (pd_incdec_calib = '1') then
                  dqs_dly_val_r <= dqs_dly_val_r + '1' after TCQ*1 ps;
	       else
                  dqs_dly_val_r <= dqs_dly_val_r - '1' after TCQ*1 ps;
	       end if;  
            end if;	       
         end if;
      end if;
   end process;

   dqs_dly_val <= dqs_dly_val_r;
   
   --***************************************************************************
   -- reset synchronization
   --***************************************************************************
   process (clk, rst)
   begin
      if (rst = '1') then
         reset <= '1' after TCQ*1 ps;
      elsif (clk'event and clk = '1') then
         reset <= '0' after TCQ*1 ps;
      end if;
   end process;

   --***************************************************************************
   -- State register
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            pd_state_r <= (others => '0') after TCQ*1 ps;
         else
            pd_state_r <= pd_next_state after TCQ*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- Next pd state
   --***************************************************************************
   process (pd_state_r, pd_cal_start, dbg_pd_off, samples_done_pl(2), pd_incdec_done)
   begin
      pd_next_state <= PD_IDLE;		-- default state is idle
      ld_dqs_dly_val_r <= '0';

      case (pd_state_r) is

	 -- (0) wait for pd_cal_start     
         when PD_IDLE =>
            if (pd_cal_start = '1') then
	       pd_next_state <= PD_CLR_CNTRS;
               ld_dqs_dly_val_r <= '1';	       
            end if;

	 -- (1) clr low and high counters
         when PD_CLR_CNTRS =>
            if (dbg_pd_off = '0') then
               pd_next_state <= PD_INC_CNTRS;
	    else
               pd_next_state <= PD_CLR_CNTRS;
            end if;

	 -- (2) conditionally inc low and high counters
         when PD_INC_CNTRS =>
            if (samples_done_pl(2) = '1') then
               pd_next_state <= PD_UPDATE;
	    else
               pd_next_state <= PD_INC_CNTRS;
            end if;

	 -- (3) pulse pd_en
         when PD_UPDATE =>
            pd_next_state <= PD_WAIT;

	 -- (4) wait for pd_incdec_done
         when PD_WAIT =>
            if (pd_incdec_done = '1') then
               pd_next_state <= PD_CLR_CNTRS;
	    else
               pd_next_state <= PD_WAIT;
            end if;

         when others =>
            null;

      end case;
   end process;

   --***************************************************************************
   -- pd state translations
   --***************************************************************************
   inc_cntrs    <= (read_valid_pl and not(samples_done)) when (pd_state_r = PD_INC_CNTRS) else '0';
   clr_low_high <= '1' when (pd_state_r = PD_CLR_CNTRS) else reset;
   low_high_ce  <= inc_cntrs;
   update_phase <= '1' when (pd_state_r = PD_UPDATE) else '0';

   --***************************************************************************
   -- pd_cal_done generator
   --***************************************************************************
   
   calib_done_cntr_inc <= high_ge_low xnor calib_done_cntr(0);
   calib_done_cntr_ce  <= update_phase and not(calib_done_cntr(CDC_WIDTH-1)) and not(first_calib_sample);

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            calib_done_cntr <= (others => '0') after TCQ*1 ps;
         elsif (calib_done_cntr_ce = '1') then
            calib_done_cntr <= (calib_done_cntr + calib_done_cntr_inc) after TCQ*1 ps;
         end if;
      end if;
   end process;

   pd_cal_done_i  <= calib_done_cntr(CDC_WIDTH-1) or dbg_pd_off;
   pd_cal_done    <= pd_cal_done_i;

   --***************************************************************************
   -- addemd gemerators (pipelined)
   --***************************************************************************

   -- trip_points  h_addend  l_addend
   -- -----------  --------  --------
   --     00          00        10
   --     01          01        01
   --     10          01        01
   --     11          10        00

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            l_addend <= (others => '0') after TCQ*1 ps;
            h_addend <= (others => '0') after TCQ*1 ps;
         else
            l_addend <= ( (not(trip_points(1)) and not(trip_points(0))) & (trip_points(1) xor trip_points(0)) ) after TCQ*1 ps;
            h_addend <= ( (trip_points(1) and trip_points(0)) & (trip_points(1) xor trip_points(0)) ) after TCQ*1 ps;
         end if;
      end if;
   end process;   

   --***************************************************************************
   -- low counter
   --***************************************************************************
   process (l_addend, low)
      variable low_d1 : std_logic_vector(LHC_WIDTH-1 downto 0);
   begin
      low_d1(LHC_WIDTH-1 downto 2) := (others => '0');
      low_d1(1 downto 0) 	   := l_addend;
      low_d <= low + low_d1;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (clr_low_high = '1') then
            low <= (others => '0') after TCQ*1 ps;
         elsif (low_high_ce = '1') then
            low <= low_d after TCQ*1 ps;
         end if;
      end if;
   end process;

  --***************************************************************************
  -- high counter
  --***************************************************************************
   process (h_addend, high)
      variable high_d1 : std_logic_vector(LHC_WIDTH-1 downto 0);
   begin
      high_d1(LHC_WIDTH-1 downto 2) := (others => '0');
      high_d1(1 downto 0) 	    := h_addend;
      high_d <= high + high_d1;
   end process;

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (clr_low_high = '1') then
            high <= (others => '0') after TCQ*1 ps;
         elsif (low_high_ce = '1') then
            high <= high_d after TCQ*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- samples_done pipeline shifter
   --***************************************************************************

   -- This shifter delays samples_done rising edge until the nearly_done logic has completed
   -- the pass through its pipeline.
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            samples_done_pl <= (others => '0') after TCQ*1 ps;
         else
            samples_done_pl <= ( (samples_done_pl(1) and samples_done) &
                                 (samples_done_pl(0) and samples_done) & samples_done ) after TCQ*1 ps;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- pd_done logic
   --***************************************************************************

   -- This logic adds a delay after pd_en is pulsed.  This delay is necessary
   -- to allow the effect of the delay tap change to cycle through to the addends,
   -- where it can then be sampled in the low and high counters. 
   
   -- the following represents pd_done registers
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (reset = '1') then
            pd_done_state_r <= (others => '0') after TCQ*1 ps;
            pd_incdec_done  <= '0' after TCQ*1 ps;
         else
            pd_done_state_r <= pd_done_next_state after TCQ*1 ps;
            pd_incdec_done  <= pd_incdec_done_next after TCQ*1 ps;
         end if;
      end if;
   end process;
   
   -- pd_done next generator
   process (pd_done_state_r, pd_en)
   begin
      pd_done_next_state  <= pd_done_state_r + '1'; 	-- dflt pd_done_next_state is + 1
      pd_incdec_done_next <= '0';                	-- dflt pd_incdec_done is false

      case (pd_done_state_r) is
      
         -- (0) wait for pd_en
         when PD_DONE_IDLE =>
            if (pd_en = '0') then
               pd_done_next_state <= PD_DONE_IDLE;
	    end if;

         -- (10)
         when PD_DONE_MAX =>
            pd_done_next_state  <= PD_DONE_IDLE;
            pd_incdec_done_next <= '1';

         when others =>
            null;		 

      end case;
   end process;   
            
end trans;

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
--  /   /         Filename: phy_pd_top.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--  Top-level for all Phase Detector logic
--
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_pd_top.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_pd_top.vhd,v $
--*****************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_pd_top is
   generic (
      TCQ                     : integer := 100;		-- clk->out delay (sim only)
      DQS_CNT_WIDTH           : integer := 3;		-- = ceil(log2(DQS_WIDTH))
      DQS_WIDTH               : integer := 8;		-- # of DQS (strobe),
      PD_LHC_WIDTH            : integer := 16;		-- synth low & high cntr physical width
      PD_CALIB_MODE           : string  := "PARALLEL";	-- "PARALLEL" or "SEQUENTIAL"
      PD_MSB_SEL              : integer := 8;           -- # of bits in PD response cntr
      PD_DQS0_ONLY            : string  := "ON";        -- Enable use of DQS[0] only for
   							-- phase detector ("ON","OFF")
      SIM_CAL_OPTION          : string  := "NONE";	-- "NONE" = full initial cal
 						      	-- "FAST_CAL" = cal w/ 1 DQS only
      DEBUG_PORT              : string  := "OFF"        -- Enable debug port
   );
   port (
      clk                     : in std_logic;
      rst                     : in std_logic;
      -- Control/status
      pd_cal_start            : in std_logic;					-- start PD initial cal
      pd_cal_done             : out std_logic;					-- PD initial cal done
      dfi_init_complete       : in std_logic;					-- Core init sequence done
      read_valid              : in std_logic;					-- Read data (DQS) valid
      -- MMCM fine phase shift control
      pd_PSEN                 : out std_logic;                                  -- FPS port enable
      pd_PSINCDEC             : out std_logic;                                  -- FPS increment/decrement
      -- IODELAY control
      dlyval_rdlvl_dqs        : in  std_logic_vector(5*DQS_WIDTH - 1 downto 0);	-- dqs values before PD begins
      dlyce_pd_cpt            : out std_logic_vector(DQS_WIDTH - 1 downto 0);	-- capture clock select
      dlyinc_pd_cpt           : out std_logic_vector(DQS_WIDTH - 1 downto 0);	-- capture clock inc/dec
      dlyval_pd_dqs           : out std_logic_vector(5*DQS_WIDTH - 1 downto 0); -- DQS PD parallel load
      -- Input DQS
      rd_dqs_rise0            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      rd_dqs_fall0            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      rd_dqs_rise1            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      rd_dqs_fall1            : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      -- Refresh control
      pd_prech_req            : out std_logic;					-- one clk period wide
      prech_done              : in std_logic;					-- one clk period wide
      
      -- Debug
      dbg_pd_off              : in std_logic;
      dbg_pd_maintain_off     : in std_logic;
      dbg_pd_maintain_0_only  : in std_logic;
      dbg_pd_inc_cpt          : in std_logic;
      dbg_pd_dec_cpt          : in std_logic;
      dbg_pd_inc_dqs          : in std_logic;
      dbg_pd_dec_dqs          : in std_logic;
      dbg_pd_disab_hyst       : in std_logic;
      dbg_pd_disab_hyst_0     : in std_logic;
      dbg_pd_msb_sel          : in std_logic_vector(3 downto 0);
      dbg_pd_byte_sel         : in std_logic_vector(DQS_CNT_WIDTH - 1 downto 0);
      dbg_inc_rd_fps          : in std_logic;
      dbg_dec_rd_fps          : in std_logic;
      dbg_phy_pd              : out std_logic_vector(255 downto 0)
   );
end entity phy_pd_top;

architecture arch of phy_pd_top is

   type type_5 is array (DQS_WIDTH - 1 downto 0) of std_logic_vector(1 downto 0);
   type type_4 is array (DQS_WIDTH - 1 downto 0) of std_logic_vector(3 downto 0);
   type type_6 is array (DQS_WIDTH - 1 downto 0) of std_logic_vector(99 downto 0);

   -- Function to 'and' all the bits of a signal
   function AND_BR(inp_sig: std_logic_vector)
            return std_logic is
      variable return_var : std_logic := '1';		    
   begin
      for index in inp_sig'range loop
	 return_var := return_var and inp_sig(index);
      end loop;
      
      return return_var;
   end function;

   -- Function to 'OR' all the bits of a signal
   function OR_BR(inp_sig: std_logic_vector)
            return std_logic is
      variable return_var : std_logic := '0';		    
   begin
      for index in inp_sig'range loop
	 return_var := return_var or inp_sig(index);
      end loop;
      
      return return_var;
   end function;

   --***************************************************************************
   -- Internal signals
   --***************************************************************************
   signal dbg_pd             : type_6;
   signal dec_cpt            : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dec_dqs            : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyce_pd_cpt_w     : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal inc_cpt            : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal inc_dqs            : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal disable_hysteresis : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal early_dqs_data     : type_4;
   signal maintain_off       : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal msb_sel            : type_4;
   signal pd_cal_done_byte   : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal pd_cal_start_byte  : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal pd_cal_start_pulse : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal pd_cal_start_r     : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal pd_maintain_0_only : std_logic;
   signal pd_off             : std_logic;
   signal pd_prec_req_r      : std_logic;
   signal pd_start_raw       : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal prech_done_pl      : std_logic;
   signal reset              : std_logic;
   signal trip_points        : type_5;
   
   -- Declare intermediate signals for referenced outputs
   signal pd_cal_done_3      : std_logic;
   signal dlyce_pd_cpt_0     : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyinc_pd_cpt_1    : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal pd_PSINCDEC_0      : std_logic;        
   signal pd_PSEN_0          : std_logic;

   component phy_pd
      generic (
         TCQ                 : integer := 100;
         SIM_CAL_OPTION      : string  := "NONE";  			-- "NONE", "FAST_CAL", "SKIP_CAL" (same as "NONE")
         PD_LHC_WIDTH        : integer := 16       			-- synth low & high cntr physical width
      );
      port (
         dbg_pd		     : out std_logic_vector(99 downto 0);	-- debug signals
         dqs_dly_val_in	     : in  std_logic_vector(4 downto 0);
         dqs_dly_val	     : out std_logic_vector(4 downto 0);
         pd_en_maintain	     : out std_logic;				-- maintenance enable
         pd_incdec_maintain  : out std_logic;  				-- maintenance inc/dec
         pd_cal_done	     : out std_logic;         			-- calibration done (level)
         pd_cal_start	     : in  std_logic;        			-- calibration start (pulse or level)
         dfi_init_complete   : in  std_logic;
         pd_read_valid	     : in  std_logic;       			-- advance cntrs only when true
         trip_points	     : in  std_logic_vector(1 downto 0);   	-- the 2 rising clock samples of the nibble

         -- Debug 
         dbg_pd_off	     : in  std_logic;
         dbg_pd_maintain_off : in  std_logic;
         dbg_pd_inc_cpt	     : in  std_logic;      			-- one clk period pulse
         dbg_pd_dec_cpt	     : in  std_logic;      			-- one clk period pulse
         dbg_pd_inc_dqs	     : in  std_logic;      			-- one clk period pulse
         dbg_pd_dec_dqs	     : in  std_logic;      			-- one clk period pulse
         dbg_pd_disab_hyst   : in  std_logic;
         dbg_pd_msb_sel      : in  std_logic_vector(3 downto 0);	-- selects effective msb of high & 
                                         				-- low cntrs
         clk		     : in  std_logic;                 		-- clkmem/2
         rst                 : in  std_logic
      ); 
   end component; 

begin
   -- Drive referenced outputs
   pd_cal_done 	   <= pd_cal_done_3;
   dlyce_pd_cpt    <= dlyce_pd_cpt_0;
   dlyinc_pd_cpt   <= dlyinc_pd_cpt_1;
   pd_PSINCDEC     <= pd_PSINCDEC_0;
   pd_PSEN         <= pd_PSEN_0; 

   --***************************************************************************
   -- reset synchronization
   --***************************************************************************
   process (clk, rst)
   begin
      if (rst = '1') then
         reset <= '1' after (TCQ)*1 ps;
      elsif (clk'event and clk = '1') then
	 reset <= '0' after (TCQ)*1 ps;
      end if;
   end process;
         
    --***************************************************************************
    -- Debug
    --***************************************************************************
         
    -- for now, route out only DQS 0 PD debug signals
   dbg_phy_pd(99 downto 0)    <= dbg_pd(0);
   dbg_phy_pd(103 downto 100) <= early_dqs_data(0);
   dbg_phy_pd(104) <= pd_cal_start;
   dbg_phy_pd(105) <= pd_cal_done_3;
   dbg_phy_pd(106) <= read_valid;
   -- signals to drive read MMCM phase shift cntr for debug
   dbg_phy_pd(107) <= pd_PSEN_0;		
   dbg_phy_pd(108) <= pd_PSINCDEC_0;
   -- spare
   dbg_phy_pd(255 downto 109) <= (others => '0');
   
   --***************************************************************************
   -- Periodic capture clock calibration and maintenance. One instance for each
   -- DQS group.
   --***************************************************************************
   process (dbg_pd_disab_hyst_0,dbg_pd_disab_hyst)
   begin
      if (DEBUG_PORT = "ON") then
         disable_hysteresis(DQS_WIDTH-1 downto 1) <= (others => dbg_pd_disab_hyst);
         disable_hysteresis(0)                    <= dbg_pd_disab_hyst_0;
      else
          disable_hysteresis <= (others => '0');
      end if;
   end process;

   pd_off <= dbg_pd_off when (DEBUG_PORT = "ON") else 
	     '0';

   -- Note:  Calibration of the DQS groups can occur in parallel or
   -- sequentially.
   
   gen_cal_mode_prl: if (PD_CALIB_MODE = "PARALLEL") generate
      -- parallel calibration
      pd_cal_done_3     <= AND_BR(pd_cal_done_byte);
      pd_cal_start_byte <= (others => pd_cal_start);
      
      pd_prech_req      <= '0';				-- not used for parallel calibration
      pd_start_raw      <= (others => '0');		-- not used for parallel calibration
      pd_cal_start_pulse<= (others => '0');		-- not used for parallel calibration
   end generate;

   -- sequential calibration
   gen_cal_mode_sql: if (not(PD_CALIB_MODE = "PARALLEL")) generate
      
      pd_cal_done_3 <= pd_cal_done_byte(DQS_WIDTH - 1);
      
      gen_DQSWD_1: if (DQS_WIDTH = 1) generate
         pd_cal_start_byte(0) <= pd_cal_start;
         pd_prech_req <= '0';			-- no refresh if only one DQS
      end generate;

      gen_DQSWD_gt_1 : if (DQS_WIDTH /= 1) generate 	-- DQS_WIDTH > 1
         pd_start_raw <= (pd_cal_done_byte(DQS_WIDTH-2 downto 0) & pd_cal_start);
         pd_prech_req <= pd_prec_req_r;
         pd_cal_start_pulse <= pd_start_raw and not(pd_cal_start_r);

         process (pd_start_raw, prech_done_pl)
         begin
            for i in pd_start_raw'range loop 
   	          pd_cal_start_byte(i) <= pd_start_raw(i) and prech_done_pl;
            end loop;
         end process;
         
         process (clk)
         begin
            if (clk'event and clk = '1') then
               if (reset = '1') then
                  prech_done_pl <= '0' after (TCQ)*1 ps;
                  pd_prec_req_r <= '0' after (TCQ)*1 ps;
                  pd_cal_start_r <= (others => '0') after (TCQ)*1 ps;
               else
                  prech_done_pl <= prech_done after (TCQ)*1 ps;
                  pd_prec_req_r <= OR_BR(pd_cal_start_pulse) after (TCQ)*0 ps;
                  pd_cal_start_r <= pd_start_raw after (TCQ)*1 ps;
               end if;
            end if;
         end process;
      end generate;
   end generate;

   dqs0_on: if (PD_DQS0_ONLY = "ON") generate
      pd_maintain_0_only <= '1';
   end generate;

   dqs0_off: if (not(PD_DQS0_ONLY = "ON")) generate
      pd_maintain_0_only <= dbg_pd_maintain_0_only when (DEBUG_PORT = "ON") else
		       	    '0';
   end generate;   

   gen_pd : for dqs_i in 0 to (DQS_WIDTH-1) generate
      early_dqs_data(dqs_i) <= (rd_dqs_fall1(dqs_i) & rd_dqs_rise1(dqs_i) & 
			        rd_dqs_fall0(dqs_i) & rd_dqs_rise0(dqs_i));
      trip_points(dqs_i)    <= (rd_dqs_rise1(dqs_i) & rd_dqs_rise0(dqs_i));
      
      inc_cpt(dqs_i) <= dbg_pd_inc_cpt when ((TO_INTEGER(unsigned(dbg_pd_byte_sel)) = dqs_i) and (DEBUG_PORT = "ON")) else '0';
      dec_cpt(dqs_i) <= dbg_pd_dec_cpt when ((TO_INTEGER(unsigned(dbg_pd_byte_sel)) = dqs_i) and (DEBUG_PORT = "ON")) else '0';
      inc_dqs(dqs_i) <= dbg_pd_inc_dqs when ((TO_INTEGER(unsigned(dbg_pd_byte_sel)) = dqs_i) and (DEBUG_PORT = "ON")) else '0';
      dec_dqs(dqs_i) <= dbg_pd_dec_dqs when ((TO_INTEGER(unsigned(dbg_pd_byte_sel)) = dqs_i) and (DEBUG_PORT = "ON")) else '0';
      
      -- set MSB for counter: make byte 0 respond faster
      msb_sel(dqs_i)     <= (dbg_pd_msb_sel - '1')                           when ((dqs_i = 0) and (DEBUG_PORT = "ON"))    else
			    std_logic_vector(to_unsigned((PD_MSB_SEL-1), 4)) when ((dqs_i = 0) and not(DEBUG_PORT = "ON")) else
		     	    dbg_pd_msb_sel                                   when (not(dqs_i = 0) and (DEBUG_PORT = "ON")) else
			    std_logic_vector(to_unsigned(PD_MSB_SEL, 4));

      maintain_off(dqs_i)<= dbg_pd_maintain_off                         when ((dqs_i = 0) and (DEBUG_PORT = "ON"))    else
			    '0'                                         when ((dqs_i = 0) and not(DEBUG_PORT = "ON")) else
		     	    (dbg_pd_maintain_off or pd_maintain_0_only) when (not(dqs_i = 0) and (DEBUG_PORT = "ON")) else
			    pd_maintain_0_only; 
      
      gen_pd_inst: if ((PD_DQS0_ONLY = "OFF") or (dqs_i = 0)) generate
         u_phy_pd : phy_pd
            generic map (
               tcq              => TCQ,
               sim_cal_option   => SIM_CAL_OPTION,
               pd_lhc_width     => PD_LHC_WIDTH			              		-- synth low & high cntr physical width	
            )
            port map (
               dbg_pd               => dbg_pd(dqs_i),		             		-- output [99:0] debug signals
               dqs_dly_val_in       => dlyval_rdlvl_dqs(5*(dqs_i+1)-1 downto 5*dqs_i),  -- input
               dqs_dly_val          => dlyval_pd_dqs(5*(dqs_i+1)-1 downto 5*dqs_i), 	-- output reg [4:0]
               pd_en_maintain       => dlyce_pd_cpt_w(dqs_i),				-- output maintenance enable
               pd_incdec_maintain   => dlyinc_pd_cpt_1(dqs_i),				-- output maintenance inc/dec
               pd_cal_done          => pd_cal_done_byte(dqs_i),				-- output calibration done (level)
               pd_cal_start         => pd_cal_start_byte(dqs_i),			-- input calibration start (level)
               dfi_init_complete    => dfi_init_complete,				-- input
               pd_read_valid        => read_valid,					-- input advance cntrs only when true
               trip_points          => trip_points(dqs_i),				-- input
               dbg_pd_off           => pd_off,						-- input
               dbg_pd_maintain_off  => maintain_off(dqs_i),				-- input
               dbg_pd_inc_cpt       => inc_cpt(dqs_i),					-- input one clk period pulse
               dbg_pd_dec_cpt       => dec_cpt(dqs_i),					-- input one clk period pulse
               dbg_pd_inc_dqs       => inc_dqs(dqs_i),					-- input one clk period pulse
               dbg_pd_dec_dqs       => dec_dqs(dqs_i),					-- input one clk period pulse
	       dbg_pd_disab_hyst    => disable_hysteresis(dqs_i),			-- input
	       dbg_pd_msb_sel	    => msb_sel(dqs_i),					-- input (3:0)
               clk                  => clk,						-- input  clkmem/2
               rst                  => rst						-- input
            );
         end generate;

      gen_pd_tie: if (not(PD_DQS0_ONLY = "OFF") and not(dqs_i = 0)) generate
	 dbg_pd(dqs_i)                        <= (others => '0');     
         dlyce_pd_cpt_w(dqs_i)                <= '0';   
         dlyinc_pd_cpt_1(dqs_i)                 <= '0';
         pd_cal_done_byte(dqs_i)              <= '1';
         dlyval_pd_dqs(5*(dqs_i+1)-1 downto 5*dqs_i) <= (others => '0');
      end generate;
   end generate;

   --***************************************************************************
   -- Separate ce controls for Calibration and the Phase Detector are needed for
   -- byte 0, because the byte 0 Phase Detector controls the MMCM, rather than
   -- the byte 0 cpt IODELAYE1.
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            pd_PSEN_0 <= '0' after TCQ*1 ps;
	 else
   	    if ((dlyce_pd_cpt_w(0) = '1') or ((DEBUG_PORT = "ON") and ((dbg_inc_rd_fps or dbg_dec_rd_fps) = '1'))) then
               pd_PSEN_0 <= '1' after TCQ*1 ps;
            else
               pd_PSEN_0 <= '0' after TCQ*1 ps;
            end if;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- Signals dbg_inc_rd_fps and dbg_dec_rd_fps directly control the read
   -- MMCM Fine Phase Shift during debug. They should only be used when
   -- read phase detector is disabled
   --***************************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            pd_PSINCDEC_0 <= '0' after TCQ*1 ps;
	 else
   	    if ((DEBUG_PORT = "ON") and ((dbg_inc_rd_fps or dbg_dec_rd_fps) = '1')) then
               pd_PSINCDEC_0 <= dbg_inc_rd_fps after TCQ*1 ps;
            else
               pd_PSINCDEC_0 <= dlyinc_pd_cpt_1(0) after TCQ*1 ps;
            end if;
         end if;
      end if;
   end process;

   --***************************************************************************
   -- IODELAY for DQS[0] is not controlled via dlyce_cpt port (IODELAY value
   -- is fixed). Rather the phase of capture clock for DQS[0] is controlled
   -- via fine-phase shift port of MMCM that generates the performance clock
   -- used as the "base" read clock (signal clk_rd_base)
   --***************************************************************************
   dlyce_pd_cpt_0(0) <= '0';

   gen_dlyce_pd_cpt_gt0: if (DQS_WIDTH > 1) generate
      dlyce_pd_cpt_0(DQS_WIDTH-1 downto 1) <= dlyce_pd_cpt_w(DQS_WIDTH-1 downto 1);
   end generate;

end architecture arch;



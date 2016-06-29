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
--  /   /         Filename: phy_dly_ctrl.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Mon Jun 30 2008 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--  Multiplexing for all DQ/DQS/Capture and resynchronization clock
--  IODELAY elements
--  Scope of this module:
--    IODELAYs controlled:
--      1. DQ (rdlvl/writes)
--      2. DQS (wrlvl/phase detector)
--      3. Capture clock (rdlvl/phase detector)
--      4. Resync clock (rdlvl/phase detector)
--    Functions performed:
--      1. Synchronization (from GCLK to BUFR domain)
--      2. Multi-rank IODELAY lookup (NOT YET SUPPORTED)
--    NOTES:
--      1. Per-bit DQ control not yet supported
--      2. Multi-rank control not yet supported
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_dly_ctrl.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_dly_ctrl.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_dly_ctrl is
   generic (
      TCQ             	: integer := 100;	-- clk->out delay (sim only)
      DQ_WIDTH       	: integer := 64;	-- # of DQ (data)
      DQS_CNT_WIDTH   	: integer := 3;		-- = ceil(log2(DQ_WIDTH))
      DQS_WIDTH     	: integer := 8; 	-- # of DQS (strobe)
      RANK_WIDTH     	: integer := 1; 	-- # of ranks of DRAM
      nCWL     		: integer := 5; 	-- Write CAS latency (in clk cyc)
      REG_CTRL          : string  := "OFF";     -- "ON" for registered DIMM
      WRLVL    		: string  := "ON"; 	-- Enable write leveling
      PHASE_DETECT	: string  := "ON"; 	-- Enable read phase detector
      DRAM_TYPE		: string  := "DDR3";   	-- Memory I/F type: "DDR3", "DDR2"
      nDQS_COL0		: integer := 4;		-- # DQS groups in I/O column #1
      nDQS_COL1		: integer := 4;		-- # DQS groups in I/O column #2
      nDQS_COL2		: integer := 0;		-- # DQS groups in I/O column #3
      nDQS_COL3		: integer := 0;		-- # DQS groups in I/O column #4
      DQS_LOC_COL0      : std_logic_vector(143 downto 0) := X"000000000000000000000000000003020100";
      			       			-- DQS grps in col #1
      DQS_LOC_COL1      : std_logic_vector(143 downto 0) := X"000000000000000000000000000007060504";
			       		        -- DQS grps in col #2
      DQS_LOC_COL2      : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
			       		        -- DQS grps in col #3
      DQS_LOC_COL3      : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
      DEBUG_PORT        : string := "OFF"       -- Enable debug port
   );
   port (
      clk    	        	: in std_logic;  
      rst       		: in std_logic; 
      clk_rsync	        	: in std_logic_vector(3 downto 0);  
      rst_rsync       		: in std_logic_vector(3 downto 0); 
      -- Operation status, control signals
      wrlvl_done      		: in std_logic; 
      rdlvl_done          	: in std_logic_vector(1 downto 0);
      pd_cal_done   		: in std_logic; 
      mc_data_sel   		: in std_logic; 
      mc_ioconfig   		: in std_logic_vector(RANK_WIDTH downto 0);
      mc_ioconfig_en   		: in std_logic; 
      phy_ioconfig   		: in std_logic_vector(0 downto 0); 
      phy_ioconfig_en 		: in std_logic; 
      dqs_oe	   		: in std_logic; 
      -- DQ, DQS IODELAY controls for write leveling
      dlyval_wrlvl_dqs		: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
      dlyval_wrlvl_dq		: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
      --  Capture Clock / Resync Clock IODELAY controls for read leveling
      dlyce_rdlvl_cpt		: in std_logic_vector((DQS_WIDTH-1) downto 0);
      dlyinc_rdlvl_cpt		: in std_logic;
      dlyce_rdlvl_rsync		: in std_logic_vector(3 downto 0);
      dlyinc_rdlvl_rsync	: in std_logic;
      dlyval_rdlvl_dq		: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
      dlyval_rdlvl_dqs		: in std_logic_vector((5*DQS_WIDTH-1) downto 0);
      -- Phase detector IODELAY control for DQS, Capture Clock
      dlyce_pd_cpt		: in std_logic_vector((DQS_WIDTH-1) downto 0);
      dlyinc_pd_cpt		: in std_logic_vector((DQS_WIDTH-1) downto 0);
      dlyval_pd_dqs	        : in std_logic_vector((5*DQS_WIDTH-1) downto 0);
      -- IODELAY controls
      dlyval_dqs		: out std_logic_vector((5*DQS_WIDTH-1) downto 0);
      dlyval_dq			: out std_logic_vector((5*DQS_WIDTH-1) downto 0);
      dlyrst_cpt		: out std_logic;
      dlyce_cpt			: out std_logic_vector((DQS_WIDTH-1) downto 0);
      dlyinc_cpt		: out std_logic_vector((DQS_WIDTH-1) downto 0);
      dlyrst_rsync		: out std_logic;
      dlyce_rsync		: out std_logic_vector(3 downto 0);
      dlyinc_rsync		: out std_logic_vector(3 downto 0);
      -- Debug Port
      dbg_pd_off		: in std_logic
   );
end phy_dly_ctrl;

architecture trans of phy_dly_ctrl is

   -- Type definitions
   type dbg_ports1 is array (0 to (DQS_WIDTH-1)) of std_logic_vector(4 downto 0);
   type dbg_ports2 is array (0 to (DQ_WIDTH-1)) of std_logic_vector(4 downto 0);
   type dbg_ports3 is array (0 to 3) of std_logic_vector(4 downto 0);

   signal dlyce_cpt_mux     		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dlyce_rsync_mux	  	: std_logic_vector(3 downto 0);
   signal dlyinc_cpt_mux  		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dlyinc_rsync_mux	  	: std_logic_vector(3 downto 0);
   signal dqs_oe_r	  		: std_logic;
   signal dqs_wr	  		: std_logic;
   signal mux_ioconfig	  		: std_logic_vector(0 downto 0);
   signal mux_ioconfig_en	  	: std_logic;
   signal mux_rd_wr		  	: std_logic;
   signal mux_rd_wr_last_r	  	: std_logic;
   signal rd_wr_r		  	: std_logic;
   signal rd_wr_rsync_r	  		: std_logic_vector(3 downto 0);
   signal rd_wr_rsync_tmp_r	  	: std_logic_vector(3 downto 0);
   signal rd_wr_rsync_tmp_r1	  	: std_logic_vector(3 downto 0);
   signal dlyce_rdlvl_cpt_0_r	  	: std_logic;
   signal dlyce_cpt_iodelay    		: std_logic_vector((DQS_WIDTH-1) downto 0);
   -- Declare intermediate signals for referenced outputs
   signal dlyce_cpt_xhdl1		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dlyinc_cpt_xhdl3		: std_logic_vector((DQS_WIDTH-1) downto 0);
   signal dlyrst_cpt_xhdl5	  	: std_logic;
   signal dlyrst_rsync_xhdl6	  	: std_logic;
   signal dlyce_rsync_xhdl2		: std_logic_vector(3 downto 0);
   signal dlyinc_rsync_xhdl4		: std_logic_vector(3 downto 0);
   signal dlyval_dqs_xhdl8		: std_logic_vector((5*DQS_WIDTH-1) downto 0);
   signal dlyval_dq_xhdl9		: std_logic_vector((5*DQS_WIDTH-1) downto 0);
  
begin
   -- Drive the outputs with intermediate signals
   dlyce_cpt    <= dlyce_cpt_xhdl1;	
   dlyrst_cpt   <= dlyrst_cpt_xhdl5;	
   dlyrst_rsync <= dlyrst_rsync_xhdl6;
   dlyce_rsync  <= dlyce_rsync_xhdl2;
   dlyinc_rsync <= dlyinc_rsync_xhdl4;
   dlyinc_cpt   <= dlyinc_cpt_xhdl3;
   dlyval_dqs   <= dlyval_dqs_xhdl8;
   dlyval_dq    <= dlyval_dq_xhdl9;

   --***************************************************************************
   -- IODELAY RESET CONTROL:
   -- RST for IODELAY is used to control parallel loading of IODELAY (dlyval)
   -- For all IODELAYs where glitching of outputs is permitted, always assert
   -- RST (i.e. control logic can change outputs without worrying about
   -- synchronization of control bits causing output glitching). For all other
   -- IODELAYs (CPT, RSYNC), only assert RST when DLYVAL is stable
   --***************************************************************************
   dlyrst_cpt_xhdl5   <= rst;
   dlyrst_rsync_xhdl6 <= rst;

   --***************************************************************************
   -- IODELAY MUX CONTROL LOGIC AND CLOCK SYNCHRONIZATION
   -- This logic determines the main MUX control logic for selecting what gets
   -- fed to the IODELAY taps. Output signal is MUX_IOCFG = [0 for write, 1 for
   -- read]. This logic is in the CLK domain, and needs to be synchronized to
   -- each of the individual CLK_RSYNC[x] domains
   --***************************************************************************

   -- Select between either MC or PHY control
   mux_ioconfig(0) <= mc_ioconfig(RANK_WIDTH) when (mc_data_sel = '1') else
		      phy_ioconfig(0);
   mux_ioconfig_en <= mc_ioconfig_en  when (mc_data_sel = '1') else
		      phy_ioconfig_en;   
   mux_rd_wr      <= mux_ioconfig(0);

   process (clk)
   begin
      if (clk'event and clk = '1') then
         dqs_oe_r <= dqs_oe after TCQ*1 ps;
      end if;
   end process;

   -- Generate indication when write is occurring - necessary to prevent
   -- situation where a read request comes in on DFI before the current
   -- write has been completed on the DDR bus - in that case, the IODELAY
   -- value should remain at the write value until the write is completed
   -- on the DDR bus. 
  
   process (dqs_oe, mux_rd_wr_last_r)
   begin
      dqs_wr <= mux_rd_wr_last_r or dqs_oe;
   end process;
	
   -- Store value of MUX_IOCONFIG when enable(latch) signal asserted
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (mux_ioconfig_en = '1') then
            mux_rd_wr_last_r <= mux_rd_wr after TCQ*1 ps;
         end if;
      end if;
   end process;

   -- New value of MUX_IOCONFIG gets reflected right away as soon as
   -- enable/latch signal is asserted. This signal indicates whether a
   -- write or read is occurring (1 = write, 0 = read). Add dependence on
   -- DQS_WR to account for pipelining - prevent read value from being
   -- loaded until previous write is finished   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (mux_ioconfig_en = '1') then
            if ((dqs_wr = '1') and (DRAM_TYPE = "DDR3")) then
               rd_wr_r <= '1' after TCQ*1 ps;
	    else
               rd_wr_r <= mux_rd_wr after TCQ*1 ps;
	    end if;
	 else
	    if ((dqs_wr = '1') and (DRAM_TYPE = "DDR3")) then
	       rd_wr_r <= '1' after TCQ*1 ps;
	    else
	       rd_wr_r <= mux_rd_wr after TCQ*1 ps;
	    end if;
	 end if;
      end if;
   end process;

   -- Synchronize MUX control to each of the individual clock domains
   gen_sync_rd_wr: for r_i in 0 to 3 generate
      gen_cwl_ddr2: if (DRAM_TYPE = "DDR2") generate
	 gen_cwl_ddr2_ls_4: if (nCWL <= 3) generate
	    -- one less pipeline stage for cwl<= 3
	    process (clk_rsync(r_i))
	    begin
	       if (clk_rsync(r_i)'event and clk_rsync(r_i) = '1') then
                  rd_wr_rsync_tmp_r(r_i) <= rd_wr_r after TCQ*1 ps;
                  rd_wr_rsync_r(r_i)     <= rd_wr_rsync_tmp_r(r_i) after TCQ*1 ps;
	       end if;  
	    end process;
         end generate;		 
         gen_cwl_ddr2_gt_3:  if (nCWL > 3) generate
	    process (clk_rsync(r_i))
	    begin
	       if (clk_rsync(r_i)'event and clk_rsync(r_i) = '1') then
                  rd_wr_rsync_tmp_r(r_i) <= rd_wr_r after TCQ*1 ps;
                  rd_wr_rsync_tmp_r1(r_i)<= rd_wr_rsync_tmp_r(r_i) after TCQ*1 ps;
                  rd_wr_rsync_r(r_i)     <= rd_wr_rsync_tmp_r1(r_i) after TCQ*1 ps;
	       end if;
	    end process;	       
         end generate;
      end generate;

      gen_cwl_5_ddr3: if (((nCWL = 5) or
                           ((nCWL = 6) and (REG_CTRL = "ON"))) and
                          (DRAM_TYPE /= "DDR2")) generate 
         -- For CWL = 5, bypass one of the pipeline registers for speed
         -- purposes (need to load IODELAY value as soon as possible on write,
         -- time between IOCONFIG_EN and OSERDES.WC assertion is shorter than
         -- for all other CWL values. Rely on built in registers in IODELAY to
         -- reduce metastability?
         -- NOTE: 2nd case added where we consider the case of registered
         --   DIMM and an nCWL value (as passed to this module) of 6 to be
         --   the same case, because the actual CWL value = 5 (as programmed
         --   in the DRAM - see module phy_top for CWL_M adjustment) and more
         --   importantly, the controller (MC) treats the CWL as 5 for bus
         --   turnaround purposes, and on a WRITE->READ, it the extra clock
         --   cycle is needed to program the new value of the IODELAY before
         --   the read data is captured. Note that we may want to apply this
         --   case as well for DDR2 registered DIMMs as well        
         process (clk_rsync(r_i))
         begin
	    if (clk_rsync(r_i)'event and clk_rsync(r_i) = '1') then
               rd_wr_rsync_r(r_i) <= rd_wr_r after TCQ*1 ps;
	    end if;
	 end process;
      end generate;
      gen_cwl_gt_5_ddr3: if ((not((nCWL = 5) or
                                  ((nCWL = 6) and (REG_CTRL = "ON")))) and
                             (DRAM_TYPE /= "DDR2")) generate
	 -- Otherwise, use two pipeline stages in CLK_RSYNC domain to
         -- reduce metastability
         process (clk_rsync(r_i))
         begin
	    if (clk_rsync(r_i)'event and clk_rsync(r_i) = '1') then
               rd_wr_rsync_tmp_r(r_i) <= rd_wr_r after TCQ*1 ps;
               rd_wr_rsync_r(r_i)     <= rd_wr_rsync_tmp_r(r_i) after TCQ*1 ps;
	    end if;
	 end process;
      end generate;
   end generate;
	
   --***************************************************************************
   -- IODELAY CE/INC MUX LOGIC
   -- Increment/Enable MUX logic for Capture and Resynchronization clocks.
   -- No synchronization of these signals to another clock domain is
   -- required - the capture and resync clock IODELAY control ports are
   -- clocked by CLK
   --***************************************************************************
   process (clk)    
   begin
      if (clk'event and clk = '1') then
         if (rdlvl_done(1) = '0') then 
            -- If read leveling not completed, rdlvl logic has control of capture
            -- and resync clock adjustment IODELAYs
            dlyce_cpt_mux    <= dlyce_rdlvl_cpt after TCQ*1 ps;
            dlyinc_cpt_mux   <= (others => dlyinc_rdlvl_cpt) after TCQ*1 ps;
            dlyce_rsync_mux  <= dlyce_rdlvl_rsync after TCQ*1 ps;
            dlyinc_rsync_mux <= (others => dlyinc_rdlvl_rsync) after TCQ*1 ps;
         else
	    if ((PHASE_DETECT = "OFF") or ((DEBUG_PORT = "ON") and (dbg_pd_off = '1'))) then
               -- If read phase detector is off, give control of CPT/RSYNC IODELAY
               -- taps to the read leveling logic. Normally the read leveling logic
               -- will not be changing the IODELAY values after initial calibration.
               -- However, the debug port interface for changing the CPT/RSYNC
               -- tap values does go through the PHY_RDLVL module - if the user
               -- has this capability enabled, then that module will change the
               -- IODELAY tap values. Note that use of the debug interface to change
               -- the CPT/RSYNC tap values is limiting to changing the tap values
               -- only when the read phase detector is turned off - otherwise, if
               -- the read phase detector is on, it will simply "undo" any changes
               -- to the tap count made via the debug port interface
               dlyce_cpt_mux    <= dlyce_rdlvl_cpt after TCQ*1 ps;
               dlyinc_cpt_mux   <= (others => dlyinc_rdlvl_cpt) after TCQ*1 ps;
               dlyce_rsync_mux  <= dlyce_rdlvl_rsync after TCQ*1 ps;
               dlyinc_rsync_mux <= (others => dlyinc_rdlvl_rsync) after TCQ*1 ps;
            else
	       -- Else read phase detector has control of capture/rsync phases
               dlyce_cpt_mux    <= dlyce_pd_cpt after TCQ*1 ps;
               dlyinc_cpt_mux   <= dlyinc_pd_cpt after TCQ*1 ps;
               -- Phase detector does not control RSYNC - rely on RSYNC positioning
               -- to be able to handle entire possible range that phase detector can
               -- vary the capture clock IODELAY taps. In the future, we may want to
               -- change to allow phase detector to vary RSYNC taps, if there is
               -- insufficient margin to allow for a "static" scheme
               dlyce_rsync_mux   <= "0000" after TCQ*1 ps;
               dlyinc_rsync_mux  <= "0000" after TCQ*1 ps;
            end if;
	 end if;
      end if;
   end process;

   dlyce_cpt_xhdl1     <= dlyce_cpt_mux;
   dlyinc_cpt_xhdl3    <= dlyinc_cpt_mux;
   dlyce_rsync_xhdl2   <= dlyce_rsync_mux;
   dlyinc_rsync_xhdl4  <= dlyinc_rsync_mux;   

   --***************************************************************************
   -- SYNCHRONIZATION FOR CLK <-> CLK_RSYNC[X] DOMAINS
   --***************************************************************************

   --***************************************************************************
   -- BIT STEERING EQUATIONS:
   -- What follows are 4 generate loops - each of which handles "bit
   -- steering" for each of the I/O columns. The first loop is always
   -- instantited. The other 3 will only be instantiated depending on the
   -- number of I/O columns used
   --***************************************************************************
   
   gen_c0: if (nDQS_COL0 > 0) generate
     gen_loop_c0: for c0_i in 0 to (nDQS_COL0-1) generate
     
        --*****************************************************************
        -- DQ/DQS DLYVAL MUX LOGIC
        -- This is the MUX logic to control the parallel load delay values for
        -- DQ and DQS IODELAYs. There are up to 4 MUX's, one for each
        -- CLK_RSYNC[x] clock domain. Each MUX can handle a variable amount
        -- of DQ/DQS IODELAYs depending on the particular user pin assignment
        -- (e.g. how many I/O columns are used, and the particular DQS groups
        -- assigned to each I/O column). The MUX select (S), and input lines
        -- (A,B) are configured:
        --   S: MUX_IO_CFG_RSYNC[x]
        --   A: value of DQ/DQS IODELAY from write leveling logic
        --   B: value of DQ/DQS IODELAY from read phase detector logic (DQS) or
        --      from read leveling logic (DQ). NOTE: The value of DQS may also
        --      depend on the read leveling logic with per-bit deskew support.
        --      This may require another level of MUX prior to this MUX
        -- The parallel signals from the 3 possible sources (wrlvl, rdlvl, read
        -- phase detector) are not synchronized to CLK_RSYNC< but also are not
        -- timing critical - i.e. the IODELAY output can glitch briefly.
        -- Therefore, there is no need to synchronize any of these sources
        -- prior to the MUX (although a MAXDELAY constraint to ensure these
        -- async paths aren't too long - they should be less than ~2 clock
        -- cycles) should be added
        --*****************************************************************
        process (clk_rsync(0))
        begin
           if (clk_rsync(0)'event and clk_rsync(0) = '1') then 	      
  	      if (rd_wr_rsync_r(0) = '1') then
	         -- Load write IODELAY values	    
  	         dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
                                  (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) )
	  		<= dlyval_wrlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                                       (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) ) after TCQ*1 ps;
	         -- Write DQ IODELAY values are byte-wide only
	         dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                    (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) )
	  		<= dlyval_wrlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                                       (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) ) after TCQ*1 ps;
              else
	         -- Load read IODELAY values
	         if ((PHASE_DETECT = "ON") and (rdlvl_done(1) = '1')) then	-- pd has control
	            dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                             (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) )
	             	<= dlyval_pd_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                                         (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) ) after TCQ*1 ps;
	         else
                    -- Read Leveling logic has control of DQS (used only if IODELAY
                    -- taps are required for either per-bit or low freq calibration)		       
	            dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                             (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) )
	             	<= dlyval_rdlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                                       (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) ) after TCQ*1 ps;
	         end if;
	         dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4 downto  
	                    (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) )
	  		<= dlyval_rdlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) + 4  downto 
	                                      (5*TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) ) after TCQ*1 ps;
              end if;
	   end if;
        end process;
     end generate;
   end generate;

   --*****************************************************************
   -- The next 3 cases are for the other 3 banks. Conditionally include
   -- only if multiple banks are supported. There's probably a better
   -- way of instantiating these 3 other cases without taking up so much
   -- space....
   --*****************************************************************
 	
   -- I/O COLUMN #2
   gen_c1: if (nDQS_COL1 > 0) generate
      gen_loop_c1: for c1_i in 0 to (nDQS_COL1-1) generate
         process (clk_rsync(1))
         begin
            if (clk_rsync(1)'event and clk_rsync(1) = '1') then 	      
               if (rd_wr_rsync_r(1) = '1') then
                  dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                   (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) )
           		<= dlyval_wrlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                             (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) ) after TCQ*1 ps;
                  dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                             (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) )
           		<= dlyval_wrlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                            (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) ) after TCQ*1 ps;
               else
	       if ((PHASE_DETECT = "ON") and (rdlvl_done(1) = '1')) then	-- pd has control
                     dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                      (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) )
                      	<= dlyval_pd_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                               (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) ) after TCQ*1 ps;
                  else	
                  -- Read Leveling logic has control of DQS (used only if IODELAY
                  -- taps are required for either per-bit or low freq calibration)		       
                     dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                      (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) )
                      	<= dlyval_rdlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                             (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) ) after TCQ*1 ps;
                  end if;
                  dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                             (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) )
           		<= dlyval_rdlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) + 4 downto  
                                            (5*TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) ) after TCQ*1 ps;
               end if;
            end if;
         end process;
      end generate;
   end generate;

   -- I/O COLUMN #3
   gen_c2: if (nDQS_COL2 > 0) generate
      gen_loop_c2: for c2_i in 0 to (nDQS_COL2-1) generate
         process (clk_rsync(2))
         begin
            if (clk_rsync(2)'event and clk_rsync(2) = '1') then 	      
               if (rd_wr_rsync_r(2) = '1') then
                  dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                   (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) )
           		<= dlyval_wrlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                             (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) ) after TCQ*1 ps;
                  dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                             (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) )
           		<= dlyval_wrlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                            (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) ) after TCQ*1 ps;
               else
	       if ((PHASE_DETECT = "ON") and (rdlvl_done(1) = '1')) then	-- pd has control
                     dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                      (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) )
                      	<= dlyval_pd_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                               (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) ) after TCQ*1 ps;
                  else	
                  -- Read Leveling logic has control of DQS (used only if IODELAY
                  -- taps are required for either per-bit or low freq calibration)		       
                     dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                      (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) )
                      	<= dlyval_rdlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                             (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) ) after TCQ*1 ps;
                  end if;
                  dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                             (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) )
           		<= dlyval_rdlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) + 4 downto  
                                            (5*TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) ) after TCQ*1 ps;
               end if;
            end if;
         end process;
      end generate;
   end generate;

   -- I/O COLUMN #4
   gen_c3: if (nDQS_COL3 > 0) generate
      gen_loop_c3: for c3_i in 0 to (nDQS_COL3-1) generate
         process (clk_rsync(3))
         begin
            if (clk_rsync(3)'event and clk_rsync(3) = '1') then 	      
               if (rd_wr_rsync_r(3) = '1') then
                  dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                   (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) )
           		<= dlyval_wrlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                             (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) ) after TCQ*1 ps;
                  dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                             (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) )
           		<= dlyval_wrlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                            (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) ) after TCQ*1 ps;
               else
	       if ((PHASE_DETECT = "ON") and (rdlvl_done(1) = '1')) then	-- pd has control
                     dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                      (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) )
                      	<= dlyval_pd_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                               (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) ) after TCQ*1 ps;
                  else	
                  -- Read Leveling logic has control of DQS (used only if IODELAY
                  -- taps are required for either per-bit or low freq calibration)		       
                     dlyval_dqs_xhdl8( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                      (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) )
                      	<= dlyval_rdlvl_dqs( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                             (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) ) after TCQ*1 ps;
                  end if;
                  dlyval_dq_xhdl9( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                             (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) )
           		<= dlyval_rdlvl_dq( (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) + 4 downto  
                                            (5*TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) ) after TCQ*1 ps;
               end if;
            end if;
         end process;
      end generate;
   end generate;

end trans;   


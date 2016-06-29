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
--  /   /         Filename: phy_rdclk_gen.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Generation and distribution of capture clock. One of the forwarded
--   CK/CK# clocks to memory is fed back into the FPGA. From there it is
--   forwarded to a PLL, where it drives a BUFO, then drives multiple
--   IODELAY + BUFIO sites, one for each DQS group (capture clocks). An
--   additional IODELAY and BUFIO is driven to create the resynchronization
--   clock for capture read data into the FPGA fabric.
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_rdclk_gen.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_rdclk_gen.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_rdclk_gen is
   generic (
      TCQ                   : integer := 100;		-- clk->out delay (sim only)
      nCK_PER_CLK           : integer := 2;		-- # of memory clocks per CLK
      CLK_PERIOD            : integer := 3333;		-- Internal clock period (in ps)
      REFCLK_FREQ           : real    := 300.0;		-- IODELAY Reference Clock freq (MHz)
      DQS_WIDTH             : integer := 1;		-- # of DQS (strobe),
      nDQS_COL0   	    : integer := 4;     	-- # DQS groups in I/O column #1
      nDQS_COL1   	    : integer := 4;     	-- # DQS groups in I/O column #2
      nDQS_COL2      	    : integer := 0;     	-- # DQS groups in I/O column #3
      nDQS_COL3   	    : integer := 0;     	-- # DQS groups in I/O column #4
      IODELAY_GRP           : string := "IODELAY_MIG"	-- May be assigned unique name
                                                        -- when mult IP cores in design
      );
      port (
      clk_mem               : in std_logic;      			   -- Memory clock
      clk                   : in std_logic;       			   -- Internal (logic) half-rate clock
      clk_rd_base           : in std_logic;      			   -- Base capture clock
      rst                   : in std_logic;        			   -- Logic reset
      dlyrst_cpt            : in std_logic;       			   -- Capture clock IDELAY shared reset
      dlyce_cpt             : in std_logic_vector(DQS_WIDTH - 1 downto 0); -- Capture clock IDELAY enable
      dlyinc_cpt            : in std_logic_vector(DQS_WIDTH - 1 downto 0); -- Capture clock IDELAY inc/dec
      dlyrst_rsync          : in std_logic;                                -- Resync clock IDELAY reset
      dlyce_rsync           : in std_logic_vector(3 downto 0); 		   -- Resync clock IDELAY enable
      dlyinc_rsync          : in std_logic_vector(3 downto 0); 		   -- Resync clock IDELAY inc/dec
      clk_cpt               : out std_logic_vector(DQS_WIDTH - 1 downto 0);-- Data capture clock
      clk_rsync             : out std_logic_vector(3 downto 0);		   -- Resynchronization clock
      rst_rsync             : out std_logic_vector(3 downto 0); 	   -- Resync clock domain reset
      -- debug control signals
      dbg_cpt_tap_cnt       : out std_logic_vector(5*DQS_WIDTH-1 downto 0);-- CPT IODELAY tap count 
      dbg_rsync_tap_cnt	    : out std_logic_vector(19 downto 0)		   -- RSYNC IODELAY tap count
   );
end phy_rdclk_gen;  

architecture trans of phy_rdclk_gen is    

   -- # cycles after deassertion of master reset when OSERDES used to
   -- forward CPT and RSYNC clocks are taken out of reset	
   constant RST_OSERDES_SYNC_NUM  : integer := 9;

   -- NOTE: All these parameters must be <= 8, otherwise, you'll need to
   --  individually change the width of the respective counter
   constant EN_CLK_ON_CNT         : integer := 8;
   constant EN_CLK_OFF_CNT        : integer := 8;
   constant RST_OFF_CNT           : integer := 8;
   constant WC_OSERDES_RST_CNT    : integer := 8;

   -- Calculate appropriate MMCM multiplication factor to keep VCO frequency
   -- in allowable range, and at the same time as high as possible in order 
   -- to keep output jitter as low as possible
   --   VCO frequency = CLKIN frequency * CLKFBOUT_MULT_F / DIVCLK_DIVIDE
   --   NOTES:
   --    1. DIVCLK_DIVIDE can be 1 or 2 depending on the input frequency
   --       and assumed speedgrade (change starting with MIG 3.3 - before
   --       DIVCLK_DIVIDE was always set to 1 - this exceeded the allowable
   --       PFD clock period when using a -2 part at higher than 533MHz freq.
   --    2. Period of the input clock provided by the user is assumed to
   --       be = CLK_PERIOD / nCK_PER_CLK
   constant CLKIN_PERIOD	: integer := (CLK_PERIOD/nCK_PER_CLK);

   -- Maximum skew between BUFR and BUFIO networks across 3 banks in ps.
   -- Includes all skew starting from when the base clock exits read MMCM
   constant CLK_CPT_SKEW_PS 	: integer := 200;

   -- Amount to shift BUFR (in ps) by in order to accomodate all possibilites
   -- of BUFIO-BUFR skew after read calibration
   -- = T/2 + CLK_CPT_SKEW, where T = memory clock period
   constant RSYNC_SHIFT_PS 	: real := real((CLK_PERIOD/nCK_PER_CLK/2) + CLK_CPT_SKEW_PS);

   -- Amount to shift in RSYNC_SHIFT_PS in # of IODELAY taps. Cap at 31.
   function CALC_RSYNC_SHIFT_TAPS return real is
          variable return_value : real;
   begin
         	if (((RSYNC_SHIFT_PS+(1000000.0/(REFCLK_FREQ*64.0))-1.0) /
         				   (1000000.0/(REFCLK_FREQ*64.0))) > 31.0) then
            return_value := 31.0;
         else
            return_value := ((RSYNC_SHIFT_PS + (1000000.0/(REFCLK_FREQ*64.0)) - 1.0)/
         				(1000000.0/(REFCLK_FREQ*64.0)));
         end if;
         return return_value;
   end function;
   constant RSYNC_SHIFT_TAPS	: integer := integer(CALC_RSYNC_SHIFT_TAPS);

   -- States for reset deassertion and clock generation state machine 
   type RESET_STATE_TYPE_R_STATE is (	RESET_IDLE,         
         				RESET_PULSE_WC,     
         				RESET_ENABLE_CLK,   
         				RESET_DISABLE_CLK,  
         				RESET_DEASSERT_RST, 
         				RESET_PULSE_CLK,
         				RESET_DONE
         			    );

   signal clk_cpt_tmp            : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal cpt_odelay             : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal cpt_oserdes            : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal en_clk_off_cnt_r       : std_logic_vector(3 downto 0);
   signal en_clk_on_cnt_r        : std_logic_vector(3 downto 0);
   signal en_clk_cpt_even_r      : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal en_clk_cpt_odd_r       : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal en_clk_rsync_even_r    : std_logic_vector(3 downto 0);
   signal en_clk_rsync_odd_r     : std_logic_vector(3 downto 0);
   signal ocbextend_cpt          : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal ocbextend_cpt_r        : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal ocbextend_rsync        : std_logic_vector(3 downto 0);
   signal ocbextend_rsync_r      : std_logic_vector(3 downto 0);
   signal reset_state_r          : RESET_STATE_TYPE_R_STATE;
   signal rsync_bufr             : std_logic_vector(3 downto 0);
   signal rsync_odelay           : std_logic_vector(3 downto 0);
   signal rsync_oserdes          : std_logic_vector(3 downto 0);
   signal rst_off_cnt_r          : std_logic_vector(3 downto 0);
   signal rst_oserdes            : std_logic;
   signal rst_oserdes_sync_r     : std_logic_vector(RST_OSERDES_SYNC_NUM - 1 downto 0);
   signal rst_rsync_pre_r        : std_logic;
   signal wc_oserdes_r           : std_logic;
   signal wc_oserdes_cnt_r       : std_logic_vector(3 downto 0);

   signal dlyrst_cpt_r           : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dlyrst_rsync_r         : std_logic_vector(3 downto 0);
   signal rst_oserdes_cpt_r      : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal rst_oserdes_rsync_r    : std_logic_vector(3 downto 0);

   -- Declare intermediate signals for referenced outputs
   signal pll_lock_xhdl1	 : std_logic;
   signal rst_rsync_xhdl2	 : std_logic_vector(3 downto 0);

   attribute IODELAY_GROUP : string;

begin
   -- Drive the outputs with intermediate signals
   rst_rsync <= rst_rsync_xhdl2;

   -- XST attributes for local reset trees - prohibit equivalent register 
   -- removal to prevent "sharing" w/ other local reset trees
   -- synthesis attribute shreg_extract of dlyrst_cpt_r is "no";  
   -- synthesis attribute equivalent_register_removal of dlyrst_cpt_r is "no"
   -- synthesis attribute shreg_extract of dlyrst_rsync_r is "no";  
   -- synthesis attribute equivalent_register_removal of dlyrst_rsync_r is "no"
   -- synthesis attribute shreg_extract of rst_oserdes_cpt_r is "no";  
   -- synthesis attribute equivalent_register_removal of rst_oserdes_cpt_r is "no"
   -- synthesis attribute shreg_extract of rst_oserdes_rsync_r is "no";  
   -- synthesis attribute equivalent_register_removal of rst_oserdes_rsync_r is "no"
    
   --***************************************************************************
   -- RESET GENERATION AND SYNCHRONIZATION:
   -- Reset and clock assertion must be carefully done in order to ensure that
   -- the ISERDES internal CLK-divide-by-2 element of all DQ/DQS bits are phase
   -- aligned prior to adjustment of individual CPT clocks. This allows us to
   -- synchronize data capture to the BUFR domain using a single BUFR -
   -- otherwise, if some CLK-div-by-2 clocks are 180 degrees phase shifted
   -- from others, then it becomes impossible to provide meeting timing for
   -- the BUFIO-BUFR capture across all bits. 
   --  1. The various stages required to generate the forwarded capture and
   --     resynchronization clocks (both PERF and BUFG clocks are involved)
   --  2. The need to ensure that the divide-by-2 elements in all ISERDES and
   --     BUFR blocks power up in the "same state" (e.g. on the first clock
   --     edge that they receive, they should drive out logic high). Otherwise
   --     these clocks can be either 0 or 180 degrees out of phase, which makes
   --     it hard to synchronize data going from the ISERDES CLK-div-2 domain
   --     to the BUFR domain.
   --  3. On a related note, the OSERDES blocks are used to generate clocks
   --     for the ISERDES and BUFR elements. Because the OSERDES OCB feature
   --     is used to synchronize from the BUFG to PERF domain (and provide the
   --     ability to gate these clocks), we have to account for the possibility
   --     that the latency across different OCB blocks can vary (by 1 clock
   --     cycle). This means that if the same control is provided to all 
   --     clock-forwaring OSERDES, there can be an extra clock pulse produced
   --     by some OSERDES blocks compared to others - this in turn will also
   --     cause the ISERDES and BUFR divide-by-2 outputs to go out of phase.
   --     Therefore, the OSERDES.OCBEXTEND pins of all these clock-forwarding
   --     OSERDES must be monitored. If there is a difference in the OCBEXTEND
   --     values across all the OSERDES, some OSERDES must have a clock pulse
   --     removed in order to ensure phase matching across all the ISERDES and
   --     BUFR divide-by-2 elements
   -- Reset sequence:
   --  1. Initially all resets are asserted
   --  2. Once both MMCMs lock, deassert reset for OSERDESs responsible for
   --     clock forwarding for CPT and RSYNC clocks. Deassertion is
   --     synchronous to clk. 
   --  3. Pulse WC for the CPT and RSYNC clock OSERDESs. WC must be
   --     synchronous to clk, and is initially deasserted, then pulsed
   --     8 clock cycles after OSERDES reset deassertion. Keep en_clk = 1
   --     to enable the OSERDES outputs.
   --    - At this point the CPT/RSYNC clocks are active
   --  4. Disable CPT and RSYNC clocks (en_clk=0). Keep rst_rsync asserted
   --    - At this point the CPT/RSYNC clocks are flatlined
   --  5. Deassert rst_rsync. This is done to ensure that the divide-by-2
   --     circuits in all the ISERDES and BURFs will be in the same "state" 
   --     when the clock is once again restored. Otherwise, if rst_rsync were
   --     deasserted while the CPT clocks were active, it's not possible to 
   --     guarantee that the reset will be deasserted synchronously with 
   --     respect to the capture clock for all ISERDES. 
   --  6. Observe the OCBEXTEND for each of the CPT and RSYNC OSERDES. For
   --     those that have an OCBEXTEND value of 1, drive a single clock
   --     pulse out prior to the next step where the clocks are permanently
   --     reenabled. This will "equalize" the phases of all the ISERDES and
   --     BUFR divide-by-2 elements. 
   --  7. Permanently re-enable CPT and RSYNC clocks.
   -- NOTES:
   --  1. May need to revisit reenabling of CPT and RSYNC clocks - may be
   --     fair amount of ISI on the first few edges of the clock. Could
   --     instead drive out a slower rate clock initially after re-enabling
   --     the clocks. 
   --  2. May need to revisit formula for positioning of RSYNC clock so that
   --     a single RSYNC clock can resynchronize data for all CPT blocks. This
   --     can either be a "static" calculation, or a dynamic calibration step. 
   --***************************************************************************
   
   --*****************************************************************  
   -- Keep all logic driven by PLL performance path in reset until master
   -- logic reset deasserted
   --*****************************************************************  
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rst_oserdes_sync_r <= (others => '1') after (TCQ)*1 ps;
         else            
            rst_oserdes_sync_r <= std_logic_vector(unsigned(rst_oserdes_sync_r) sll 1) after (TCQ)*1 ps;
         end if;
      end if;
   end process;
   
   rst_oserdes <= rst_oserdes_sync_r(RST_OSERDES_SYNC_NUM - 1); 
   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst_oserdes = '1') then
            en_clk_off_cnt_r    <= (others => '0') after (TCQ)*1 ps;
            en_clk_on_cnt_r     <= (others => '0') after (TCQ)*1 ps;
            en_clk_cpt_even_r   <= (others => '0') after (TCQ)*1 ps;
            en_clk_cpt_odd_r    <= (others => '0') after (TCQ)*1 ps;
            en_clk_rsync_even_r <= (others => '0') after (TCQ)*1 ps;
            en_clk_rsync_odd_r  <= (others => '0') after (TCQ)*1 ps;
            rst_off_cnt_r       <= (others => '0') after (TCQ)*1 ps;
            rst_rsync_pre_r     <= '1'             after (TCQ)*1 ps;
            reset_state_r       <= RESET_IDLE      after (TCQ)*1 ps;
            wc_oserdes_cnt_r    <= (others => '0') after (TCQ)*1 ps;
            wc_oserdes_r        <= '0'             after (TCQ)*1 ps;
         else
            -- Default assignments
            en_clk_cpt_even_r   <= (others => '0') after (TCQ)*1 ps;
            en_clk_cpt_odd_r    <= (others => '0') after (TCQ)*1 ps;
            en_clk_rsync_even_r <= (others => '0') after (TCQ)*1 ps;
            en_clk_rsync_odd_r  <= (others => '0') after (TCQ)*1 ps;
            rst_rsync_pre_r     <= '1' after (TCQ)*1 ps;
            wc_oserdes_r 	<= '0' after (TCQ)*1 ps;
            
	    
            case reset_state_r is
               -- Wait for both MMCM's to lock 
               when RESET_IDLE =>
                  wc_oserdes_cnt_r <= "0000" after (TCQ)*1 ps;
                  reset_state_r <= RESET_PULSE_WC after (TCQ)*1 ps;
               
               when RESET_PULSE_WC =>
               -- Pulse WC some time after reset to OSERDES is deasserted
                  wc_oserdes_cnt_r <= (wc_oserdes_cnt_r + '1') after (TCQ)*1 ps;
                  if (TO_INTEGER(unsigned(wc_oserdes_cnt_r)) = (WC_OSERDES_RST_CNT-1)) then
                     wc_oserdes_r <= '1' after (TCQ)*1 ps;
                     reset_state_r <= RESET_ENABLE_CLK after (TCQ)*1 ps;
                  end if;

	       -- Drive out a few clocks to make sure reset is recognized for
               -- those circuits that require a synchronous reset               
               when RESET_ENABLE_CLK =>
                  en_clk_cpt_even_r   <= (others => '1') after (TCQ)*1 ps;
                  en_clk_cpt_odd_r    <= (others => '1') after (TCQ)*1 ps;
                  en_clk_rsync_even_r <= (others => '1') after (TCQ)*1 ps;
                  en_clk_rsync_odd_r  <= (others => '1') after (TCQ)*1 ps;
                  en_clk_on_cnt_r     <= (en_clk_on_cnt_r + '1') after (TCQ)*1 ps;
                  if (TO_INTEGER(unsigned(en_clk_on_cnt_r)) = (EN_CLK_ON_CNT - 1)) then
                     reset_state_r    <= RESET_DISABLE_CLK after (TCQ)*1 ps;
                  end if;

               -- Disable clocks in preparation for disabling reset
               when RESET_DISABLE_CLK =>
                  en_clk_off_cnt_r <= (en_clk_off_cnt_r + '1') after (TCQ)*1 ps;
                  if (TO_INTEGER(unsigned(en_clk_off_cnt_r)) = (EN_CLK_OFF_CNT - 1)) then
                     reset_state_r <= RESET_DEASSERT_RST after (TCQ)*1 ps;
                  end if;
               
               -- Deassert reset while clocks are inactive
               when RESET_DEASSERT_RST =>
                  rst_rsync_pre_r    <= '0' after (TCQ)*1 ps;
                  rst_off_cnt_r      <= (rst_off_cnt_r + '1') after (TCQ)*1 ps;
                  if (TO_INTEGER(unsigned(rst_off_cnt_r)) = (RST_OFF_CNT - 1)) then
                     reset_state_r   <= RESET_PULSE_CLK after (TCQ)*1 ps;
                  end if;
               
               -- Pulse extra clock to those CPT/RSYNC OSERDES that need it 
               when RESET_PULSE_CLK =>
                  en_clk_cpt_even_r    <= ocbextend_cpt_r   after (TCQ)*1 ps;
                  en_clk_cpt_odd_r     <= (others => '0')   after (TCQ)*1 ps;
                  en_clk_rsync_even_r  <= ocbextend_rsync_r after (TCQ)*1 ps;
                  en_clk_rsync_odd_r   <= (others => '0')   after (TCQ)*1 ps;
                  rst_rsync_pre_r      <= '0'               after (TCQ)*1 ps;
                  reset_state_r        <= RESET_DONE        after (TCQ)*1 ps;
                  
               -- Permanently enable clocks                                   
               when RESET_DONE =>
                  en_clk_cpt_even_r   <= (others => '1') after (TCQ)*1 ps;
                  en_clk_cpt_odd_r    <= (others => '1') after (TCQ)*1 ps;
                  en_clk_rsync_even_r <= (others => '1') after (TCQ)*1 ps;
                  en_clk_rsync_odd_r  <= (others => '1') after (TCQ)*1 ps;
                  rst_rsync_pre_r     <= '0'             after (TCQ)*1 ps;
	       
	       when others =>
            end case;
         end if;
      end if;
   end process;
   

   --*****************************************************************
   -- Reset pipelining - register reset signals to prevent large (and long)
   -- fanouts during physical compilation of the design - in particular when
   -- the design spans multiple I/O columns. Create one for every CPT and 
   -- RSYNC clock OSERDES - might be overkill (one per I/O column may be 
   -- enough). Note this adds a one cycle delay between when the FSM below
   -- is taken out of reset, and when the OSERDES are taken out of reset -
   -- this should be accounted for by the FSM logic
   --*****************************************************************
   process (clk)
   begin
      if (clk'event and clk = '1') then
         dlyrst_cpt_r        <= (others => dlyrst_cpt) after TCQ*1 ps;	      
         dlyrst_rsync_r      <= (others => dlyrst_rsync) after TCQ*1 ps;
         rst_oserdes_cpt_r   <= (others => rst_oserdes) after TCQ*1 ps;
         rst_oserdes_rsync_r <= (others => rst_oserdes) after TCQ*1 ps;
      end if;
   end process;

   --*****************************************************************
   -- Miscellaneous signals
   --*****************************************************************
   
   -- NOTE: Deassertion of RST_RSYNC does not have to be synchronous
   --  w/r/t CLK_RSYNC[x] - because CLK_RSYNC[x] is inactive when
   --  reset is deasserted
   process (clk)
   begin
      if (clk'event and clk = '1') then         
         rst_rsync_xhdl2(0) <= rst_rsync_pre_r after (TCQ)*1 ps;
         rst_rsync_xhdl2(1) <= rst_rsync_pre_r after (TCQ)*1 ps;
         rst_rsync_xhdl2(2) <= rst_rsync_pre_r after (TCQ)*1 ps;
         rst_rsync_xhdl2(3) <= rst_rsync_pre_r after (TCQ)*1 ps;
      end if;
   end process;

   -- Register OCBEXTEND from CPT and RSYNC OSERDES - although these will
   -- be static signals by the time they're used by the state machine
   process (clk)
   begin
      if (clk'event and clk = '1') then
         ocbextend_cpt_r   <= ocbextend_cpt   after (TCQ)*1 ps;
         ocbextend_rsync_r <= ocbextend_rsync after (TCQ)*1 ps;
      end if;
   end process;
   
   
   --***************************************************************************
   -- Generation for each of the individual DQS group clocks. Also generate
   -- resynchronization clock.
   -- NOTES:
   --   1. BUFO drives OSERDES which in turn drives corresponding IODELAY
   --   2. Another mechanism may exist where BUFO drives the IODELAY input 
   --      combinationally (bypassing the last stage flip-flop in OSERDES)
   --***************************************************************************

   --*****************************************************************  
   -- Clock forwarding:
   -- Use OSERDES to forward clock even though only basic ODDR
   -- functionality is needed - use case for ODDR connected to
   -- performance path may not be supported, and may later want 
   -- to add clock-gating capability to CPT clock to decrease
   -- IODELAY loading time when switching ranks  
   --*****************************************************************

   --*******************************************************
   -- Capture clocks
   --*******************************************************

   gen_ck_cpt : for ck_i in 0 to  DQS_WIDTH - 1 generate
      attribute IODELAY_GROUP of u_odelay_cpt : label is IODELAY_GRP;
   begin   
   u_oserdes_cpt : OSERDESE1
         generic map (
            DATA_RATE_OQ   => "DDR",
            DATA_RATE_TQ   => "DDR",
            DATA_WIDTH     => 4,
            DDR3_DATA      => 0,
            INIT_OQ        => '0',
            INIT_TQ        => '0',
            INTERFACE_TYPE => "MEMORY_DDR3",
            ODELAY_USED    => 0,
            SERDES_MODE    => "MASTER",
            SRVAL_OQ       => '0',
            SRVAL_TQ       => '0',
            TRISTATE_WIDTH => 4
         )
         port map (
            OCBEXTEND     => ocbextend_cpt(ck_i),
            OFB           => cpt_oserdes(ck_i),
            OQ            => open,
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TFB           => open,
            TQ            => open,
            CLK           => clk_mem,            
            CLKDIV        => clk,
            CLKPERF       => clk_rd_base,
            CLKPERFDELAY  => 'Z',
            D1            => en_clk_cpt_odd_r(ck_i),		-- Gating of fwd'ed clock
            D2            => '0',
            D3            => en_clk_cpt_even_r(ck_i),		-- Gating of fwd'ed clock
            D4            => '0',
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',            
            RST           => rst_oserdes_cpt_r(ck_i),
	    T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TCE           => '1',            
            WC            => wc_oserdes_r
         );
      
      u_odelay_cpt : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => TRUE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "VARIABLE",
            ODELAY_VALUE           => 0,
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "CLOCK"
         )
         port map (
            DATAOUT      => cpt_odelay(ck_i),
            C            => clk,
            CE           => dlyce_cpt(ck_i),
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => dlyinc_cpt(ck_i),
            ODATAIN      => cpt_oserdes(ck_i),
            RST          => dlyrst_cpt_r(ck_i),
            T            => 'Z',
            CNTVALUEIN   => (others => 'Z'),
            CNTVALUEOUT  => dbg_cpt_tap_cnt(5*ck_i+4 downto 5*ck_i),
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );     
      
      u_bufio_cpt : BUFIO
         port map (
            i  => cpt_odelay(ck_i),
            o  => clk_cpt_tmp(ck_i)
         );
      
      -- Use for simulation purposes only
      clk_cpt(ck_i) <= clk_cpt_tmp(ck_i) after 0.1 ps;
      
   end generate;

   --*******************************************************
   -- Resynchronization clock 
   --*******************************************************
   
   -- I/O column #1
   gen_loop_col0 : if (nDQS_COL0 > 0) generate      
      attribute IODELAY_GROUP of u_odelay_rsync : label is IODELAY_GRP;
   begin   
   u_oserdes_rsync : OSERDESE1
         generic map (
            DATA_RATE_OQ   => "DDR",
            DATA_RATE_TQ   => "DDR",
            DATA_WIDTH     => 4,
            DDR3_DATA      => 0,
            INIT_OQ        => '0',
            INIT_TQ        => '0',
            INTERFACE_TYPE => "MEMORY_DDR3",
            ODELAY_USED    => 0,
            SERDES_MODE    => "MASTER",
            SRVAL_OQ       => '0',
            SRVAL_TQ       => '0',
            TRISTATE_WIDTH => 4
         )
         port map (
            OCBEXTEND     => ocbextend_rsync(0),
            OFB           => rsync_oserdes(0),
            OQ            => open,
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,            
            CLKDIV        => clk,
            CLKPERF       => clk_rd_base,
            CLKPERFDELAY  => 'Z',
            D1            => en_clk_rsync_odd_r(0),		-- Gating of fwd'ed clock
            D2            => '0',
            D3            => en_clk_rsync_even_r(0),		-- Gating of fwd'ed clock
            D4            => '0',
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',            
            RST           => rst_oserdes_rsync_r(0),
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',            
            WC            => wc_oserdes_r
         );
            
      u_odelay_rsync : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => TRUE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "VARIABLE",
            ODELAY_VALUE           => 16,  -- Set at midpt for CLKDIVINV cal
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "CLOCK"
         )
         port map (
            DATAOUT      => rsync_odelay(0),
            C            => clk,
            CE           => dlyce_rsync(0),
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => dlyinc_rsync(0),
            ODATAIN      => rsync_oserdes(0),
            RST          => dlyrst_rsync_r(0),
            T            => 'Z',
            CNTVALUEIN   => (others => 'Z'),
            CNTVALUEOUT  => dbg_rsync_tap_cnt(4 downto 0),
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );
            
      u_bufr_rsync : BUFR
         generic map (
            bufr_divide  => "2",
            sim_device   => "VIRTEX6"
         )
         port map (
            i    => rsync_odelay(0),
            o    => rsync_bufr(0),
            ce   => '1',
            clr  => rst_rsync_xhdl2(0)
         );
   end generate;

   -- I/O column #2
   gen_loop_col1 : if (nDQS_COL1 > 0) generate      
      
   attribute IODELAY_GROUP of u_odelay_rsync : label is IODELAY_GRP;
   begin
   u_oserdes_rsync : OSERDESE1
         generic map (
            DATA_RATE_OQ   => "DDR",
            DATA_RATE_TQ   => "DDR",
            DATA_WIDTH     => 4,
            DDR3_DATA      => 0,
            INIT_OQ        => '0',
            INIT_TQ        => '0',
            INTERFACE_TYPE => "MEMORY_DDR3",
            ODELAY_USED    => 0,
            SERDES_MODE    => "MASTER",
            SRVAL_OQ       => '0',
            SRVAL_TQ       => '0',
            TRISTATE_WIDTH => 4
         )
         port map (
            OCBEXTEND     => ocbextend_rsync(1),
            OFB           => rsync_oserdes(1),
            OQ            => open,
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,            
            CLKDIV        => clk,
            CLKPERF       => clk_rd_base,
            CLKPERFDELAY  => 'Z',
            D1            => en_clk_rsync_odd_r(1),		-- Gating of fwd'ed clock
            D2            => '0',
            D3            => en_clk_rsync_even_r(1),		-- Gating of fwd'ed clock
            D4            => '0',
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',            
            RST           => rst_oserdes_rsync_r(1),
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',            
            WC            => wc_oserdes_r
         );
      
      
      u_odelay_rsync : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => TRUE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "VARIABLE",
            ODELAY_VALUE           => 16,  -- Set at midpt for CLKDIVINV cal
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "CLOCK"
         )
         port map (
            DATAOUT      => rsync_odelay(1),
            C            => clk,
            CE           => dlyce_rsync(1),
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => dlyinc_rsync(1),
            ODATAIN      => rsync_oserdes(1),
            RST          => dlyrst_rsync_r(1),
            T            => 'Z',
            CNTVALUEIN   => (others => 'Z'),
            CNTVALUEOUT  => dbg_rsync_tap_cnt(9 downto 5),
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );
            
      u_bufr_rsync : BUFR
         generic map (
            bufr_divide  => "2",
            sim_device   => "VIRTEX6"
         )
         port map (
            i    => rsync_odelay(1),
            o    => rsync_bufr(1),
            ce   => '1',
            clr  => rst_rsync_xhdl2(1)
         );
   end generate;   

   -- I/O column #3
   gen_loop_col2 : if (nDQS_COL2 > 0) generate      
      
   attribute IODELAY_GROUP of u_odelay_rsync : label is IODELAY_GRP;
   begin
   u_oserdes_rsync : OSERDESE1
         generic map (
            DATA_RATE_OQ   => "DDR",
            DATA_RATE_TQ   => "DDR",
            DATA_WIDTH     => 4,
            DDR3_DATA      => 0,
            INIT_OQ        => '0',
            INIT_TQ        => '0',
            INTERFACE_TYPE => "MEMORY_DDR3",
            ODELAY_USED    => 0,
            SERDES_MODE    => "MASTER",
            SRVAL_OQ       => '0',
            SRVAL_TQ       => '0',
            TRISTATE_WIDTH => 4
         )
         port map (
            OCBEXTEND     => ocbextend_rsync(2),
            OFB           => rsync_oserdes(2),
            OQ            => open,
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,            
            CLKDIV        => clk,
            CLKPERF       => clk_rd_base,
            CLKPERFDELAY  => 'Z',
            D1            => en_clk_rsync_odd_r(2),		-- Gating of fwd'ed clock
            D2            => '0',
            D3            => en_clk_rsync_even_r(2),		-- Gating of fwd'ed clock
            D4            => '0',
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',            
            RST           => rst_oserdes_rsync_r(2),
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',            
            WC            => wc_oserdes_r
         );
      
      
      u_odelay_rsync : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => TRUE,
            IDELAY_TYPE            => "FIXED",
            IDELAY_VALUE           => 0,
            ODELAY_TYPE            => "VARIABLE",
            ODELAY_VALUE           => 16,  -- Set at midpt for CLKDIVINV cal
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "CLOCK"
         )
         port map (
            DATAOUT      => rsync_odelay(2),
            C            => clk,
            CE           => dlyce_rsync(2),
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => dlyinc_rsync(2),
            ODATAIN      => rsync_oserdes(2),
            RST          => dlyrst_rsync_r(2),
            T            => 'Z',
            CNTVALUEIN   => (others => 'Z'),
            CNTVALUEOUT  => dbg_rsync_tap_cnt(14 downto 10),
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );
      
      
      
      u_bufr_rsync : BUFR
         generic map (
            bufr_divide  => "2",
            sim_device   => "VIRTEX6"
         )
         port map (
            i    => rsync_odelay(2),
            o    => rsync_bufr(2),
            ce   => '1',
            clr  => rst_rsync_xhdl2(2)
         );
   end generate;

   -- I/O column #4
   gen_loop_col3 : if (nDQS_COL3 > 0) generate      
      
   attribute IODELAY_GROUP of u_odelay_rsync : label is IODELAY_GRP;
   begin
   u_oserdes_rsync : OSERDESE1
         generic map (
            DATA_RATE_OQ   => "DDR",
            DATA_RATE_TQ   => "DDR",
            DATA_WIDTH     => 4,
            DDR3_DATA      => 0,
            INIT_OQ        => '0',
            INIT_TQ        => '0',
            INTERFACE_TYPE => "MEMORY_DDR3",
            ODELAY_USED    => 0,
            SERDES_MODE    => "MASTER",
            SRVAL_OQ       => '0',
            SRVAL_TQ       => '0',
            TRISTATE_WIDTH => 4
         )
         port map (
            OCBEXTEND     => ocbextend_rsync(3),
            OFB           => rsync_oserdes(3),
            OQ            => open,
            SHIFTOUT1     => open,
            SHIFTOUT2     => open,
            TQ            => open,
            CLK           => clk_mem,            
            CLKDIV        => clk,
            CLKPERF       => clk_rd_base,
            CLKPERFDELAY  => 'Z',
            D1            => en_clk_rsync_odd_r(3),		-- Gating of fwd'ed clock
            D2            => '0',
            D3            => en_clk_rsync_even_r(3),		-- Gating of fwd'ed clock
            D4            => '0',
            D5            => 'Z',
            D6            => 'Z',
            ODV           => '0',
            OCE           => '1',
            SHIFTIN1      => 'Z',
            SHIFTIN2      => 'Z',            
            RST           => rst_oserdes_rsync_r(3),
            T1            => '0',
            T2            => '0',
            T3            => '0',
            T4            => '0',
            TFB           => open,
            TCE           => '1',            
            WC            => wc_oserdes_r
         );
      
      
      u_odelay_rsync : IODELAYE1
         generic map (
            CINVCTRL_SEL           => FALSE,
            DELAY_SRC              => "O",
            HIGH_PERFORMANCE_MODE  => TRUE,
            IDELAY_TYPE            => "FIXED",	-- See CR 511257
            IDELAY_VALUE           => 0,	-- See CR 511257
            ODELAY_TYPE            => "VARIABLE",
            ODELAY_VALUE           => 16,  -- Set at midpt for CLKDIVINV cal
            REFCLK_FREQUENCY       => REFCLK_FREQ,
            SIGNAL_PATTERN         => "CLOCK"
         )
         port map (
            DATAOUT      => rsync_odelay(3),
            C            => clk,
            CE           => dlyce_rsync(3),
            DATAIN       => 'Z',
            IDATAIN      => 'Z',
            INC          => dlyinc_rsync(3),
            ODATAIN      => rsync_oserdes(3),
            RST          => dlyrst_rsync_r(3),
            T            => 'Z',
            CNTVALUEIN   => (others => 'Z'),
            CNTVALUEOUT  => dbg_rsync_tap_cnt(19 downto 15),
            CLKIN        => 'Z',
            CINVCTRL     => '0'
         );
      
      
      
      u_bufr_rsync : BUFR
         generic map (
            bufr_divide  => "2",
            sim_device   => "VIRTEX6"
         )
         port map (
            i    => rsync_odelay(3),
            o    => rsync_bufr(3),
            ce   => '1',
            clr  => rst_rsync_xhdl2(3)
         );
   end generate;

   clk_rsync <= rsync_bufr;
   

end trans;



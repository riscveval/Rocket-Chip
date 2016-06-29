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
--  /   /         Filename: phy_data_io.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Top-level for all data (DQ, DQS, DM) related IOB logic.
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_data_io.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_data_io.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_data_io is
   generic (
      TCQ                 : integer := 100;		-- clk->out delay (sim only)
      nCK_PER_CLK         : integer := 2;		-- # of memory clocks per CLK
      CLK_PERIOD          : integer := 3000;		-- Internal clock period (in ps)
      DRAM_WIDTH          : integer := 8;		-- # of DQ per DQS
      DM_WIDTH            : integer := 9;		-- # of DM (data mask)
      DQ_WIDTH            : integer := 72;		-- # of DQ (data)
      DQS_WIDTH           : integer := 9;		-- # of DQS (strobe)
      DRAM_TYPE           : string  := "DDR3";
      nCWL                : integer := 5;		-- Write CAS latency (in clk cyc)
      WRLVL               : string  := "OFF";		-- Enable write leveling
      REFCLK_FREQ         : real    := 300.0;		-- IODELAY Reference Clock freq (MHz)
      IBUF_LPWR_MODE      : string  := "OFF";		-- Input buffer low power mode
      IODELAY_HP_MODE     : string  := "ON";		-- IODELAY High Performance Mode
      IODELAY_GRP         : string  := "IODELAY_MIG";	-- May be assigned unique name
						        -- when mult IP cores in design
      nDQS_COL0           : integer := 4;		-- # DQS groups in I/O column #1
      nDQS_COL1           : integer := 4;		-- # DQS groups in I/O column #2
      nDQS_COL2           : integer := 0;		-- # DQS groups in I/O column #3
      nDQS_COL3           : integer := 0;		-- # DQS groups in I/O column #4
      DQS_LOC_COL0        : std_logic_vector(143 downto 0) := X"000000000000000000000000000003020100";-- DQS grps in col #1
      DQS_LOC_COL1        : std_logic_vector(143 downto 0) := X"000000000000000000000000000007060504";-- DQS grps in col #2
      DQS_LOC_COL2        : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";-- DQS grps in col #3
      DQS_LOC_COL3        : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";-- DQS grps in col #4
      USE_DM_PORT         : integer := 1		-- DM instantation enable
   );
   port (
      clk_mem             : in std_logic;
      clk                 : in std_logic;
      clk_cpt             : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      clk_rsync           : in std_logic_vector(3 downto 0);
      rst                 : in std_logic;
      rst_rsync           : in std_logic_vector(3 downto 0);
       -- IODELAY I/F
      dlyval_dq           : in std_logic_vector(5*DQS_WIDTH - 1 downto 0);
      dlyval_dqs          : in std_logic_vector(5*DQS_WIDTH - 1 downto 0);
      -- Write datapath I/F
      inv_dqs             : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      wr_calib_dly        : in std_logic_vector(2*DQS_WIDTH - 1 downto 0);
      dqs_oe_n            : in std_logic_vector(4*DQS_WIDTH - 1 downto 0);
      dq_oe_n             : in std_logic_vector(4*DQS_WIDTH - 1 downto 0);
      dqs_rst             : in std_logic_vector((DQS_WIDTH * 4) - 1 downto 0);
      dm_ce               : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      mask_data_rise0     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
      mask_data_fall0     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
      mask_data_rise1     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
      mask_data_fall1     : in std_logic_vector((DQ_WIDTH / 8) - 1 downto 0);
      wr_data_rise0       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      wr_data_rise1       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      wr_data_fall0       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      wr_data_fall1       : in std_logic_vector(DQ_WIDTH - 1 downto 0);
      -- Read datapath I/F
      rd_bitslip_cnt      : in std_logic_vector(2*DQS_WIDTH - 1 downto 0);
      rd_clkdly_cnt       : in std_logic_vector(2*DQS_WIDTH - 1 downto 0);
      rd_clkdiv_inv       : in std_logic_vector(DQS_WIDTH - 1 downto 0);
      rd_data_rise0       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
      rd_data_fall0       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
      rd_data_rise1       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
      rd_data_fall1       : out std_logic_vector(DQ_WIDTH - 1 downto 0);
      rd_dqs_rise0        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      rd_dqs_fall0        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      rd_dqs_rise1        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      rd_dqs_fall1        : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      -- DDR3 bus signals
      ddr_dm              : out std_logic_vector(DM_WIDTH - 1 downto 0);
      ddr_dqs_p           : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
      ddr_dqs_n           : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
      ddr_dq              : inout std_logic_vector(DQ_WIDTH - 1 downto 0);
      -- Debug Port
      dbg_dqs_tap_cnt     : out std_logic_vector(5*DQS_WIDTH - 1 downto 0); 
      dbg_dq_tap_cnt      : out std_logic_vector(5*DQS_WIDTH - 1 downto 0)   
   );
end phy_data_io;

architecture trans of phy_data_io is

   -- ratio of # of physical DM outputs to bytes in data bus
   -- may be different - e.g. if using x4 components
   constant DM_TO_BYTE_RATIO : integer := DM_WIDTH / (DQ_WIDTH / 8);
   
   signal clk_rsync_dqs      : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal dq_tap_cnt         : std_logic_vector(5*DQ_WIDTH - 1 downto 0);
   signal rst_r              : std_logic_vector(DQS_WIDTH - 1 downto 0);
   signal rst_rsync_dqs      : std_logic_vector(DQS_WIDTH - 1 downto 0);

   signal rst_dqs_r           : std_logic_vector(DQS_WIDTH-1 downto 0);
   signal rst_dm_r            : std_logic_vector(DM_WIDTH-1 downto 0);
   signal rst_dq_r            : std_logic_vector(DQ_WIDTH-1 downto 0);
------- phy_dqs_iob component --------
   component phy_dqs_iob
      generic (
         TCQ                    : integer := 100;			-- clk->out delay (sim only)
         DRAM_TYPE              : string  := "DDR3";			-- Memory I/F type: "DDR3", "DDR2"
         REFCLK_FREQ            : real    := 300.0;			-- IODELAY Reference Clock freq (MHz)
         IBUF_LPWR_MODE   	     : string  := "OFF";  		-- Input buffer low power mode
         IODELAY_HP_MODE        : string  := "ON";			-- IODELAY High Performance Mode
         IODELAY_GRP            : string  := "IODELAY_MIG" 		-- May be assigned unique name
                                                           		-- when mult IP cores in design
      );
      port (
         clk_mem                : in std_logic;				-- memory-rate clock
         clk                    : in std_logic;				-- internal (logic) clock
         clk_cpt                : in std_logic;				-- read capture clock
         clk_rsync              : in std_logic;				-- resynchronization (read) clock
         rst                    : in std_logic;				-- reset sync'ed to CLK
         rst_rsync              : in std_logic;				-- reset sync'ed to RSYNC
         -- IODELAY I/F
         dlyval                 : in std_logic_vector(4 downto 0);	-- IODELAY (DQS) parallel load value
         -- Write datapath I/F
         dqs_oe_n	             : in std_logic_vector(3 downto 0);	-- DQS output enable
         dqs_rst                : in std_logic_vector(3 downto 0);	-- D4 input of OSERDES: 1- for normal, 0- for WL
         -- Read datapath I/F
         rd_bitslip_cnt         : in std_logic_vector(1 downto 0);
         rd_clkdly_cnt          : in std_logic_vector(1 downto 0);
         rd_clkdiv_inv          : in std_logic;
         rd_dqs_rise0           : out std_logic;			-- DQS captured in clk_cpt domain
         rd_dqs_fall0           : out std_logic;			-- used by Phase Detector. Monitor DQS
         rd_dqs_rise1           : out std_logic;
         rd_dqs_fall1           : out std_logic;
         -- DDR3 bus signals
         ddr_dqs_p              : inout std_logic;
         ddr_dqs_n              : inout std_logic;
         -- Debug Port   
         dqs_tap_cnt            : out std_logic_vector(4 downto 0)
      );
   end component;   

------- phy_dq_iob component --------
   component phy_dq_iob
      generic (
         TCQ                    : integer := 100;			-- clk->out delay (sim only)
         nCWL                   : integer := 5;				-- Write CAS latency (in clk cyc)
         DRAM_TYPE              : string  := "DDR3";			-- Memory I/F type: "DDR3", "DDR2"
         WRLVL                  : string  := "ON";			-- "OFF" for "DDR3" component interface
         REFCLK_FREQ            : real    := 300.0;			-- IODELAY Reference Clock freq (MHz)
         IBUF_LPWR_MODE   	     : string  := "OFF";  		-- Input buffer low power mode
         IODELAY_HP_MODE        : string  := "ON";			-- IODELAY High Performance Mode
         IODELAY_GRP            : string  := "IODELAY_MIG" 		-- May be assigned unique name
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
         rd_clkdly_cnt          : in std_logic_vector(1 downto 0);
         rd_clkdiv_inv          : in std_logic;
         rd_data_rise0          : out std_logic;
         rd_data_fall0          : out std_logic;
         rd_data_rise1          : out std_logic;
         rd_data_fall1          : out std_logic;
         -- DDR3 bus signals
         ddr_dq                 : inout std_logic;
         dq_tap_cnt             : out std_logic_vector(4 downto 0)
      );
   end component;

------- phy_dm_iob component --------
   component phy_dm_iob
      generic (
         TCQ                    : integer := 100;			-- clk->out delay (sim only)
         nCWL                   : integer := 5;				-- CAS Write Latency
         DRAM_TYPE              : string  := "DDR3";			-- Memory I/F type: "DDR3", "DDR2"
         WRLVL                  : string  := "ON";			-- "OFF" for "DDR3" component interface
         REFCLK_FREQ            : real    := 300.0;			-- IODELAY Reference Clock freq (MHz)
         IODELAY_HP_MODE        : string  := "ON";			-- IODELAY High Performance Mode
         IODELAY_GRP            : string  := "IODELAY_MIG" 		-- May be assigned unique name
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
   end component;

   attribute max_fanout: string;
   attribute max_fanout of rst_dqs_r : signal is "1";
   attribute max_fanout of rst_dm_r : signal is "1";
   attribute max_fanout of rst_dq_r : signal is "1";
   attribute shreg_extract: string;
   attribute shreg_extract of rst_dqs_r : signal is "no";  
   attribute shreg_extract of rst_dm_r : signal is "no";  
   attribute shreg_extract of rst_dq_r : signal is "no";  
   attribute equivalent_register_removal: string;
   attribute equivalent_register_removal of rst_dqs_r : signal is "no";
   attribute equivalent_register_removal of rst_dm_r : signal is "no";
   attribute equivalent_register_removal of rst_dq_r : signal is "no";

   attribute syn_maxfan : integer;
   attribute syn_maxfan of rst_dqs_r  : signal is 1;
   attribute syn_maxfan of rst_dm_r   : signal is 1;
   attribute syn_maxfan of rst_dq_r   : signal is 1;
   attribute syn_srlstyle : string;
   attribute syn_srlstyle of rst_dqs_r : signal is "noextractff_srl";
   attribute syn_srlstyle of rst_dm_r  : signal is "noextractff_srl";
   attribute syn_srlstyle of rst_dq_r  : signal is "noextractff_srl";
   attribute syn_preserve : boolean;
   attribute syn_preserve of rst_dqs_r  : signal is true;
   attribute syn_preserve of rst_dm_r   : signal is true;
   attribute syn_preserve of rst_dq_r   : signal is true;

begin

   -- XST attributes for local reset tree RST_R - prohibit equivalent 
   -- register removal on RST_R to prevent "sharing" w/ other local reset trees
   -- synthesis attribute shreg_extract of rst_r is "no";  
   -- synthesis attribute equivalent_register_removal of rst_r is "no"
   --
   --***************************************************************************
   -- Steer correct CLK_RSYNC to each DQS/DQ/DM group - different DQS groups
   -- can reside on different I/O columns - each I/O column will have its
   -- own CLK_RSYNC
   -- Also steer correct performance path clock to each DQS/DQ/DM group - 
   -- different DQS groups can reside on different I/O columns - inner I/O
   -- column I/Os will use clk_wr_i, other column I/O's will use clk_wr_o
   -- By convention, inner columns use DQS_COL0 and DQS_COL1, and outer
   -- columns use DQS_COL2 and DQS_COL3. 
   --***************************************************************************
   
   gen_c0 :  if (nDQS_COL0 > 0) generate
     gen_loop_c0 : for c0_i in 0 to  nDQS_COL0 - 1 generate
        clk_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) <= clk_rsync(0);
        rst_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL0(8*c0_i+7 downto 8*c0_i)))) <= rst_rsync(0);
     end generate;
   end generate;
   
   gen_c1 : if (nDQS_COL1 > 0) generate
      gen_loop_c1 : for c1_i in 0 to  (nDQS_COL1 - 1) generate
         clk_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) <= clk_rsync(1);
         rst_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL1(8*c1_i+7 downto 8*c1_i)))) <= rst_rsync(1);
      end generate;
   end generate;
   
   gen_c2 : if (nDQS_COL2 > 0) generate
      gen_loop_c2 : for c2_i in 0 to  (nDQS_COL2 - 1) generate
         clk_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) <= clk_rsync(2);
         rst_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL2(8*c2_i+7 downto 8*c2_i)))) <= rst_rsync(2);
      end generate;
   end generate;
   
   gen_c3 : if (nDQS_COL3 > 0) generate
      gen_loop_c3 : for c3_i in 0 to  nDQS_COL3 - 1 generate
         clk_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) <= clk_rsync(3);
         rst_rsync_dqs(TO_INTEGER(unsigned(DQS_LOC_COL3(8*c3_i+7 downto 8*c3_i)))) <= rst_rsync(3);
      end generate;
   end generate;

   --***************************************************************************
   -- Reset pipelining - register reset signals to prevent large (and long)
   -- fanouts during physical compilation of the design. Create one local reset
   -- for every byte's worth of DQ/DM/DQS (this should be local since DQ/DM/DQS
   -- are placed close together)
   --***************************************************************************

   process (clk)
   begin
      if (clk'event and clk = '1') then
         if (rst = '1') then
            rst_r <= (others => '1') after (TCQ)*1 ps;
         else
            rst_r <= (others => '0') after (TCQ)*1 ps;
	 end if;
      end if;
   end process;

   --***************************************************************************
   -- DQS instances
   --***************************************************************************
   
   gen_dqs : for dqs_i in 0 to  DQS_WIDTH - 1 generate
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
                 rst_dqs_r(dqs_i) <= '1'  after (TCQ)*1 ps;
             else
                 rst_dqs_r(dqs_i) <= '0' after (TCQ)*1 ps;
	     end if;
         end if; 
      end process;

      u_phy_dqs_iob : phy_dqs_iob
         generic map (
            DRAM_TYPE         => (DRAM_TYPE),
            REFCLK_FREQ       => (REFCLK_FREQ),
            IBUF_LPWR_MODE    => (IBUF_LPWR_MODE),
            IODELAY_HP_MODE   => (IODELAY_HP_MODE),
            IODELAY_GRP       => (IODELAY_GRP)
         )
         port map (
            clk_mem             => clk_mem,
            clk                 => clk,
            clk_cpt             => clk_cpt(dqs_i),
            clk_rsync           => clk_rsync_dqs(dqs_i),
            rst                 => rst_dqs_r(dqs_i),
            rst_rsync           => rst_rsync_dqs(dqs_i),
            dlyval              => dlyval_dqs(5*dqs_i+4 downto 5*dqs_i),
            dqs_oe_n            => dqs_oe_n(4*dqs_i+3 downto 4*dqs_i),
            dqs_rst             => dqs_rst(4*dqs_i+3 downto 4*dqs_i),
            rd_bitslip_cnt      => rd_bitslip_cnt(2*dqs_i+1 downto 2*dqs_i),
            rd_clkdly_cnt       => rd_clkdly_cnt(2*dqs_i+1 downto 2*dqs_i),
            rd_clkdiv_inv       => rd_clkdiv_inv(dqs_i),
            rd_dqs_rise0        => rd_dqs_rise0(dqs_i),
            rd_dqs_fall0        => rd_dqs_fall0(dqs_i),
            rd_dqs_rise1        => rd_dqs_rise1(dqs_i),
            rd_dqs_fall1        => rd_dqs_fall1(dqs_i),
            ddr_dqs_p           => ddr_dqs_p(dqs_i),
            ddr_dqs_n           => ddr_dqs_n(dqs_i),
	    dqs_tap_cnt         => dbg_dqs_tap_cnt(5*dqs_i+4 downto 5*dqs_i)
         );
   end generate;
   
   --***************************************************************************
   -- DM instances
   --***************************************************************************
   gen_dm_inst: if (USE_DM_PORT /= 0) generate
   gen_dm : for dm_i in 0 to  DM_WIDTH - 1 generate 
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
                 rst_dm_r(dm_i) <= '1'  after (TCQ)*1 ps;
             else
                 rst_dm_r(dm_i) <= '0' after (TCQ)*1 ps;
	     end if;
         end if; 
      end process;

      
      u_phy_dm_iob : phy_dm_iob
         generic map (
            TCQ               => (TCQ),
            nCWL              => (nCWL),
            DRAM_TYPE         => (DRAM_TYPE),
            WRLVL             => (WRLVL),
            REFCLK_FREQ       => (REFCLK_FREQ),
            IODELAY_HP_MODE   => (IODELAY_HP_MODE),
            IODELAY_GRP       => (IODELAY_GRP)
         )
         port map (
            clk_mem          => clk_mem,
            clk              => clk,
            clk_rsync        => clk_rsync_dqs(dm_i),
            rst              => rst_dm_r(dm_i),
            dlyval           => dlyval_dq(5*dm_i+4 downto 5*dm_i),
            dm_ce            => dm_ce(dm_i),
            inv_dqs          => inv_dqs(dm_i),
            wr_calib_dly     => wr_calib_dly(2*dm_i+1 downto 2*dm_i),
            mask_data_rise0  => mask_data_rise0(dm_i / DM_TO_BYTE_RATIO),
            mask_data_fall0  => mask_data_fall0(dm_i / DM_TO_BYTE_RATIO),
            mask_data_rise1  => mask_data_rise1(dm_i / DM_TO_BYTE_RATIO),
            mask_data_fall1  => mask_data_fall1(dm_i / DM_TO_BYTE_RATIO),
            ddr_dm           => ddr_dm(dm_i)
         );
   end generate;
   end generate;
   --***************************************************************************
   -- DQ IOB instances
   --***************************************************************************
   
   gen_dq : for dq_i in 0 to  DQ_WIDTH - 1 generate   
      process (clk)
      begin
         if (clk'event and clk = '1') then
            if (rst = '1') then
                 rst_dq_r(dq_i) <= '1'  after (TCQ)*1 ps;
             else
                 rst_dq_r(dq_i) <= '0' after (TCQ)*1 ps;
	     end if;
         end if; 
      end process;

      
      u_iob_dq : phy_dq_iob
         generic map (
            tcq               => (TCQ),
            ncwl              => (nCWL),
            dram_type         => (DRAM_TYPE),
            wrlvl             => (WRLVL),
            refclk_freq       => (REFCLK_FREQ),
            ibuf_lpwr_mode    => (IBUF_LPWR_MODE),
            iodelay_hp_mode   => (IODELAY_HP_MODE),
            iodelay_grp       => (IODELAY_GRP)
         )
         port map (
            clk_mem         => clk_mem,
            clk             => clk,
            rst             => rst_dq_r(dq_i),
            clk_cpt         => clk_cpt(dq_i / DRAM_WIDTH),
            clk_rsync       => clk_rsync_dqs(dq_i / DRAM_WIDTH),
            rst_rsync       => rst_rsync_dqs(dq_i / DRAM_WIDTH),
            dlyval          => dlyval_dq(5 * (dq_i / DRAM_WIDTH) + 4 downto 5 * (dq_i / DRAM_WIDTH)),
            inv_dqs         => inv_dqs(dq_i / DRAM_WIDTH),
            wr_calib_dly    => wr_calib_dly(2 * (dq_i / DRAM_WIDTH) + 1 downto 2 * (dq_i / DRAM_WIDTH)),
            dq_oe_n         => dq_oe_n(4 * (dq_i / DRAM_WIDTH) + 3 downto 4 * (dq_i / DRAM_WIDTH)),
            wr_data_rise0   => wr_data_rise0(dq_i),
            wr_data_fall0   => wr_data_fall0(dq_i),
            wr_data_rise1   => wr_data_rise1(dq_i),
            wr_data_fall1   => wr_data_fall1(dq_i),
            rd_bitslip_cnt  => rd_bitslip_cnt(2 * (dq_i / DRAM_WIDTH) + 1 downto 2 * (dq_i / DRAM_WIDTH)),
            rd_clkdly_cnt   => rd_clkdly_cnt(2 * (dq_i / DRAM_WIDTH) + 1 downto 2 * (dq_i / DRAM_WIDTH)),
            rd_clkdiv_inv   => rd_clkdiv_inv(dq_i / DRAM_WIDTH),
            rd_data_rise0   => rd_data_rise0(dq_i),
            rd_data_fall0   => rd_data_fall0(dq_i),
            rd_data_rise1   => rd_data_rise1(dq_i),
            rd_data_fall1   => rd_data_fall1(dq_i),
            ddr_dq          => ddr_dq(dq_i),
	    dq_tap_cnt      => dq_tap_cnt(5*dq_i+4 downto 5*dq_i)	    
         );
   end generate;

   -- Only use one DQ IODELAY tap per DQS group, since all DQs in the same
   -- DQS group have the same delay value (because calibration for both write
   -- and read timing is done on a per-DQS group basis, not a per-bit basis)
   gen_dbg: for dbg_i in 0 to (DQS_WIDTH - 1) generate
      dbg_dq_tap_cnt(5*dbg_i+4 downto 5*dbg_i) <= dq_tap_cnt (5*DRAM_WIDTH*dbg_i + 4 downto 5*DRAM_WIDTH*dbg_i);
   end generate;   
      
end trans;



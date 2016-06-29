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
--  /   /         Filename: phy_read.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:13 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Top-level module for PHY-layer read logic
--     1. Read clock (capture, resync) generation
--     2. Synchronization of control from MC into resync clock domain
--     3. Synchronization of data/valid into MC clock domain
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_read.vhd,v 1.1 2011/06/02 07:18:13 mishra Exp $
--**$Date: 2011/06/02 07:18:13 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_read.vhd,v $
--******************************************************************************
library unisim;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;

entity phy_read is
   generic (
      TCQ 		: integer := 100;
      nCK_PER_CLK     	: integer := 2;       		 -- # of memory clocks per CLK
      CLK_PERIOD        : integer := 3333;    		 -- Internal clock period (in ps)
      REFCLK_FREQ       : real := 300.0;   		 	 -- IODELAY Reference Clock freq (MHz)
      DQS_WIDTH         : integer := 8;       		 -- # of DQS (strobe)
      DQ_WIDTH          : integer := 64;      		 -- # of DQ (data)
      DRAM_WIDTH        : integer := 8;       		 -- # of DQ per DQS
      IODELAY_GRP       : string := "IODELAY_MIG"; 		 -- May be assigned unique name
                                              		 -- when mult IP cores in design
      nDQS_COL0         : integer := 4;       		 -- # DQS groups in I/O column #1
      nDQS_COL1         : integer := 4;       		 -- # DQS groups in I/O column #2
      nDQS_COL2         : integer := 0;       		 -- # DQS groups in I/O column #3
      nDQS_COL3         : integer := 0;       		 -- # DQS groups in I/O column #4
      DQS_LOC_COL0      : std_logic_vector(143 downto 0) := X"11100F0E0D0C0B0A09080706050403020100";
      			       			-- DQS grps in col #1
      DQS_LOC_COL1      : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
			       		        -- DQS grps in col #2
      DQS_LOC_COL2      : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
			       		        -- DQS grps in col #3
      DQS_LOC_COL3      : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000"
   );      
   port (
      clk_mem			: in std_logic;		     
      clk			: in std_logic;		     
      rst   		        : in std_logic;		     
      clk_rd_base		: in std_logic;		     
      -- Read clock generation/distribution signals
      dlyrst_cpt		: in std_logic;		     
      dlyce_cpt			: in std_logic_vector(DQS_WIDTH-1 downto 0);		     
      dlyinc_cpt		: in std_logic_vector(DQS_WIDTH-1 downto 0);		     
      dlyrst_rsync		: in std_logic;		     
      dlyce_rsync		: in std_logic_vector(3 downto 0);		     
      dlyinc_rsync		: in std_logic_vector(3 downto 0);		     
      clk_cpt			: out std_logic_vector(DQS_WIDTH-1 downto 0);		     
      clk_rsync			: out std_logic_vector(3 downto 0);		     
      rst_rsync			: out std_logic_vector(3 downto 0);		     
      rdpath_rdy		: out std_logic;	
      -- Control for command sync logic
      mc_data_sel		: in std_logic;		     
      rd_active_dly		: in std_logic_vector(4 downto 0);		     
      -- Captured data in resync clock domain
      rd_data_rise0		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
      rd_data_fall0		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
      rd_data_rise1		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
      rd_data_fall1		: in std_logic_vector((DQ_WIDTH-1) downto 0);		     
      rd_dqs_rise0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
      rd_dqs_fall0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
      rd_dqs_rise1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
      rd_dqs_fall1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);		     
      -- DFI signals from MC/PHY rdlvl logic
      dfi_rddata_en		: in std_logic;		     
      phy_rddata_en		: in std_logic;		     
      -- Synchronized data/valid back to MC/PHY rdlvl logic
      dfi_rddata_valid		: out std_logic;		     
      dfi_rddata_valid_phy	: out std_logic;		     
      dfi_rddata		: out std_logic_vector((4*DQ_WIDTH-1) downto 0);		     
      dfi_rd_dqs		: out std_logic_vector((4*DQS_WIDTH-1) downto 0);		     
      -- Debug bus
      dbg_cpt_tap_cnt		: out std_logic_vector(5*DQS_WIDTH-1 downto 0);	-- CPT IODELAY tap count
      dbg_rsync_tap_cnt		: out std_logic_vector(19 downto 0);		-- RSYNC IODELAY tap count
      dbg_phy_read		: out std_logic_vector(255 downto 0)		-- general purpose debug
	);
end phy_read;	

architecture trans of phy_read is 

   -- Declare intermediate signals for referenced outputs
   signal rst_rsync_xhdl0	: std_logic_vector(3 downto 0);
   signal clk_rsync_xhdl1	: std_logic_vector(3 downto 0);

------- component phy_rdclk_gen ------
component phy_rdclk_gen
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
end component;  

-------- component phy_rdctrl_sync --------
   component phy_rdctrl_sync
      generic (
         TCQ                   : integer := 100
      );
      port (
         clk                   : in std_logic;
         rst_rsync             : in std_logic;	-- Use only CLK_RSYNC[0] reset
         -- Control for control sync logic
         mc_data_sel           : in std_logic;
         rd_active_dly         : in std_logic_vector(4 downto 0);
         -- DFI signals from MC/PHY rdlvl logic
         dfi_rddata_en         : in std_logic;
         phy_rddata_en         : in std_logic;
         -- Control for read logic, initialization logic
         dfi_rddata_valid      : out std_logic;
         dfi_rddata_valid_phy  : out std_logic;
         rdpath_rdy            : out std_logic   -- asserted when read path
                                                 -- ready for use
      );
   end component;

------- component phy_rddata_sync ------
   component phy_rddata_sync
      generic (
         TCQ             	: integer := 100;	-- clk->out delay (sim only)
         DQ_WIDTH       	: integer := 64;	-- # of DQ (data)
         DQS_WIDTH     	: integer := 8; 	-- # of DQS (strobe)
         DRAM_WIDTH     	: integer := 8; 	-- # # of DQ per DQS
         nDQS_COL0		: integer := 4;		-- # DQS groups in I/O column #1
         nDQS_COL1		: integer := 4;		-- # DQS groups in I/O column #2
         nDQS_COL2		: integer := 4;		-- # DQS groups in I/O column #3
         nDQS_COL3		: integer := 4;		-- # DQS groups in I/O column #4
         DQS_LOC_COL0               : std_logic_vector(143 downto 0) := X"11100F0E0D0C0B0A09080706050403020100";
         								-- DQS grps in col #1
         DQS_LOC_COL1               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
           						        -- DQS grps in col #2
         DQS_LOC_COL2               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000";
           						        -- DQS grps in col #3
         DQS_LOC_COL3               : std_logic_vector(143 downto 0) := X"000000000000000000000000000000000000"
      );
      port (
         clk    	        	: in std_logic;  
         clk_rsync	        	: in std_logic_vector(3 downto 0);  
         rst_rsync       		: in std_logic_vector(3 downto 0); 
         -- Captured data in resync clock domain
         rd_data_rise0		: in std_logic_vector((DQ_WIDTH-1) downto 0);
         rd_data_fall0		: in std_logic_vector((DQ_WIDTH-1) downto 0);
         rd_data_rise1		: in std_logic_vector((DQ_WIDTH-1) downto 0);
         rd_data_fall1		: in std_logic_vector((DQ_WIDTH-1) downto 0);
         rd_dqs_rise0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
         rd_dqs_fall0	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
         rd_dqs_rise1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
         rd_dqs_fall1	        : in std_logic_vector((DQS_WIDTH-1) downto 0);
         --  Synchronized data/valid back to MC/PHY rdlvl logic
         dfi_rddata		: out std_logic_vector((4*DQ_WIDTH-1) downto 0);
         dfi_rd_dqs		: out std_logic_vector((4*DQS_WIDTH-1) downto 0)
      );
   end component;

begin
   -- Drive the outputs with intermediate signals
   rst_rsync <= rst_rsync_xhdl0;
   clk_rsync <= clk_rsync_xhdl1;
   --***************************************************************************
   -- Assign signals for Debug Port
   --***************************************************************************
	
   -- Currently no assignments - add as needed
   dbg_phy_read <= (others => '0');	

   --***************************************************************************
   -- Read clocks (capture, resynchronization) generation
   --***************************************************************************

   u_phy_rdclk_gen: phy_rdclk_gen
      generic map (
         TCQ            => TCQ,
         nCK_PER_CLK    => nCK_PER_CLK,
         CLK_PERIOD     => CLK_PERIOD,
         DQS_WIDTH      => DQS_WIDTH,
         REFCLK_FREQ    => REFCLK_FREQ,
         IODELAY_GRP    => IODELAY_GRP,
         nDQS_COL0      => nDQS_COL0,
         nDQS_COL1      => nDQS_COL1,
         nDQS_COL2      => nDQS_COL2,
         nDQS_COL3      => nDQS_COL3    
	 )
      port map (       
         clk_mem           => clk_mem,
         clk               => clk,
         clk_rd_base       => clk_rd_base,
         rst		   => rst,
         dlyrst_cpt        => dlyrst_cpt,
         dlyce_cpt         => dlyce_cpt,
         dlyinc_cpt        => dlyinc_cpt,
         dlyrst_rsync      => dlyrst_rsync,
         dlyce_rsync       => dlyce_rsync,
         dlyinc_rsync      => dlyinc_rsync,
         clk_cpt           => clk_cpt,
         clk_rsync         => clk_rsync_xhdl1,
         rst_rsync         => rst_rsync_xhdl0,
         dbg_cpt_tap_cnt   => dbg_cpt_tap_cnt,
         dbg_rsync_tap_cnt => dbg_rsync_tap_cnt
         );

   --***************************************************************************
   -- Synchronization of read enable signal from MC/PHY rdlvl logic
   --***************************************************************************
   u_phy_rdctrl_sync: phy_rdctrl_sync
   generic map (
      TCQ	=> TCQ
      )
   port map (
      clk                  => clk,
      rst_rsync            => rst_rsync_xhdl0(0),
      mc_data_sel          => mc_data_sel,
      rd_active_dly        => rd_active_dly,
      dfi_rddata_en        => dfi_rddata_en,
      phy_rddata_en        => phy_rddata_en,
      dfi_rddata_valid     => dfi_rddata_valid,
      dfi_rddata_valid_phy => dfi_rddata_valid_phy,
      rdpath_rdy           => rdpath_rdy
      );

   --***************************************************************************
   -- Synchronization of read data and accompanying valid signal back to MC/
   -- PHY rdlvl logic
   --***************************************************************************
   u_phy_rddata_sync: phy_rddata_sync
   generic map (
      TCQ            => TCQ,
      DQ_WIDTH       => DQ_WIDTH,
      DQS_WIDTH      => DQS_WIDTH,
      DRAM_WIDTH     => DRAM_WIDTH,
      nDQS_COL0      => nDQS_COL0,
      nDQS_COL1      => nDQS_COL1,
      nDQS_COL2      => nDQS_COL2,
      nDQS_COL3      => nDQS_COL3,
      DQS_LOC_COL0   => DQS_LOC_COL0,
      DQS_LOC_COL1   => DQS_LOC_COL1,
      DQS_LOC_COL2   => DQS_LOC_COL2,
      DQS_LOC_COL3   => DQS_LOC_COL3
      )
   port map (
      clk                => clk,
      clk_rsync          => clk_rsync_xhdl1,
      rst_rsync          => rst_rsync_xhdl0,
      rd_data_rise0      => rd_data_rise0,
      rd_data_fall0      => rd_data_fall0,
      rd_data_rise1      => rd_data_rise1,
      rd_data_fall1      => rd_data_fall1,
      rd_dqs_rise0       => rd_dqs_rise0,
      rd_dqs_fall0       => rd_dqs_fall0,
      rd_dqs_rise1       => rd_dqs_rise1,
      rd_dqs_fall1       => rd_dqs_fall1,
      dfi_rddata         => dfi_rddata,
      dfi_rd_dqs	 => dfi_rd_dqs
      );

end architecture trans;





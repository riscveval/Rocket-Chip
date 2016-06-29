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
--  /   /         Filename: phy_dqs_iob.vhd
-- /___/   /\     Date Last Modified: $Date: 2011/06/02 07:18:12 $
-- \   \  /  \    Date Created: Aug 03 2009 
--  \___\/\___\
--
--Device: Virtex-6
--Design Name: DDR3 SDRAM
--Purpose:
--   Instantiates I/O-related logic for DQS. Contains logic for both write
--   and read (phase detection) paths.
--Reference:
--Revision History:
--*****************************************************************************

--******************************************************************************
--**$Id: phy_dqs_iob.vhd,v 1.1 2011/06/02 07:18:12 mishra Exp $
--**$Date: 2011/06/02 07:18:12 $
--**$Author: mishra $
--**$Revision: 1.1 $
--**$Source: /devl/xcs/repo/env/Databases/ip/src2/O/mig_v3_9/data/dlib/virtex6/ddr3_sdram/vhdl/rtl/phy/phy_dqs_iob.vhd,v $
--******************************************************************************
library unisim;
   use unisim.vcomponents.all;
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   use ieee.numeric_std.all;


entity phy_dqs_iob is
   generic (
      TCQ                    : integer := 100;		 	-- clk->out delay (sim only)
      DRAM_TYPE              : string  := "DDR3";	 	-- Memory I/F type: "DDR3", "DDR2"
      REFCLK_FREQ            : real    := 300.0;	 	-- IODELAY Reference Clock freq (MHz)
      IBUF_LPWR_MODE   	     : string  := "OFF";  	 	-- Input buffer low power mode
      IODELAY_HP_MODE        : string  := "ON";		 	-- IODELAY High Performance Mode
      IODELAY_GRP            : string  := "IODELAY_MIG"  	-- May be assigned unique name
                                                         	-- when mult IP cores in design
   );
   port (
      clk_mem                : in std_logic;			-- memory-rate clock
      clk                    : in std_logic;			-- internal (logic) clock
      clk_cpt                : in std_logic;			-- read capture clock
      clk_rsync              : in std_logic;			-- resynchronization (read) clock
      rst                    : in std_logic;			-- reset sync'ed to CLK
      rst_rsync              : in std_logic;			-- reset sync'ed to RSYNC
      -- IODELAY I/F
      dlyval                 : in std_logic_vector(4 downto 0);	-- IODELAY (DQS) parallel load value
      -- Write datapath I/F
      dqs_oe_n	             : in std_logic_vector(3 downto 0);	-- DQS output enable
      dqs_rst                : in std_logic_vector(3 downto 0);	-- D4 input of OSERDES: 1- for normal, 0- for WL
      -- Read datapath I/F
      rd_bitslip_cnt         : in std_logic_vector(1 downto 0);
      rd_clkdly_cnt	     : in std_logic_vector(1 downto 0);
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
end phy_dqs_iob;

architecture trans_phy_dqs_iob of phy_dqs_iob is

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
   signal dqs_ibuf_n               : std_logic;
   signal dqs_ibuf_p               : std_logic;
   signal dqs_n_iodelay            : std_logic;
   signal dqs_n_tfb                : std_logic;
   signal dqs_n_tq                 : std_logic;
   signal dqs_p_iodelay            : std_logic;
   signal dqs_p_tfb                : std_logic;
   signal dqs_p_oq                 : std_logic;
   signal dqs_p_tq                 : std_logic;
   signal iserdes_clk              : std_logic;
   signal iserdes_clkb             : std_logic;
   signal iserdes_q                : std_logic_vector(5 downto 0);
   signal iserdes_q_mux            : std_logic_vector(5 downto 0);  
   signal iserdes_q_neg_r          : std_logic_vector(5 downto 0);
   signal iserdes_q_r              : std_logic_vector(5 downto 0);
   signal rddata                   : std_logic_vector(3 downto 0);

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
   attribute IODELAY_GROUP of u_iodelay_dqs_p_early : label is IODELAY_GRP;

begin

   --***************************************************************************
   -- Strobe Bidirectional I/O
   --***************************************************************************

   u_iobuf_dqs: IOBUFDS_DIFF_OUT
      generic map (
         IBUF_LOW_PWR => IBUF_LOW_PWR
      )
      port map (
         o    => dqs_ibuf_p,
         ob   => dqs_ibuf_n,
         io   => ddr_dqs_p,
         iob  => ddr_dqs_n,
         i    => dqs_p_iodelay,
         tm   => dqs_p_tq,
         ts   => dqs_n_tq
      );	 
   --***************************************************************************
   -- Programmable Delay element - the "P"-side is used for both input and
   -- output paths. The N-side is used for tri-state control of N-side I/O
   -- buffer and can possibly be used as as an input (complement of P-side)
   -- for the read phase detector
   --***************************************************************************      	 
	 
   u_iodelay_dqs_p_early : IODELAYE1
      generic map (
         CINVCTRL_SEL           => FALSE,
         DELAY_SRC              => "IO",
         HIGH_PERFORMANCE_MODE  => HIGH_PERFORMANCE_MODE,
         IDELAY_TYPE            => "VAR_LOADABLE",                           
         IDELAY_VALUE           => 0,     	
         ODELAY_TYPE            => "VAR_LOADABLE",
         ODELAY_VALUE           => 0,
         REFCLK_FREQUENCY       => REFCLK_FREQ
      )
      port map (
         DATAOUT      => dqs_p_iodelay,
         C            => clk_rsync,
         CE           => '0',
         DATAIN       => '0',
         IDATAIN      => dqs_ibuf_p,
         INC          => '0',
         ODATAIN      => dqs_p_oq,		
         RST          => '1',
         T            => dqs_p_tfb,
         CNTVALUEIN   => dlyval,
         CNTVALUEOUT  => dqs_tap_cnt,
         CLKIN        => 'Z',
         CINVCTRL     => '0'
      ); 

   --***************************************************************************
   -- Write Path
   --***************************************************************************

   u_oserdes_dqs_p : OSERDESE1
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
         OQ            => dqs_p_oq,
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         TQ            => dqs_p_tq,
         CLK           => clk_mem,                
         CLKDIV        => clk,                 
         CLKPERF       => 'Z',
         CLKPERFDELAY  => 'Z',
         D1            => dqs_rst(0),
         D2            => dqs_rst(1),
         D3            => dqs_rst(2),
         D4            => dqs_rst(3),
         D5            => 'Z',
         D6            => 'Z',
         OCE           => '1',
         ODV           => '0',
         SHIFTIN1      => 'Z',
         SHIFTIN2      => 'Z',               
         RST           => rst,
         T1            => dqs_oe_n(0),
         T2            => dqs_oe_n(1),
         T3            => dqs_oe_n(2),
         T4            => dqs_oe_n(3),
         TFB           => dqs_p_tfb,
         TCE           => '1',               
         WC            => '0'
      );

   u_oserdes_dqs_n : OSERDESE1
      generic map (
         DATA_RATE_OQ   => "DDR",
         DATA_RATE_TQ   => "DDR",
         DATA_WIDTH     => 4,
         DDR3_DATA      => 0,
         INIT_OQ        => '1',
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
         OQ            => open,
         SHIFTOUT1     => open,
         SHIFTOUT2     => open,
         TQ            => dqs_n_tq,
         CLK           => clk_mem,                
         CLKDIV        => clk,                 
         CLKPERF       => 'Z',
         CLKPERFDELAY  => 'Z',
         D1            => '0',
         D2            => '0',
         D3            => '0',
         D4            => '0',
         D5            => 'Z',
         D6            => 'Z',
         OCE           => '1',
         ODV           => '0',
         SHIFTIN1      => 'Z',
         SHIFTIN2      => 'Z',               
         RST           => rst,
         T1            => dqs_oe_n(0),
         T2            => dqs_oe_n(1),
         T3            => dqs_oe_n(2),
         T4            => dqs_oe_n(3),
         TFB           => dqs_n_tfb,
         TCE           => '1',               
         WC            => '0'
      );	 
   
   --***************************************************************************
   -- Read Path
   --***************************************************************************   

   -- Assign equally to avoid delta-delay issues in simulation
   iserdes_clk  <=  clk_cpt;
   iserdes_clkb <=  not(clk_cpt);

   u_iserdes_dqs_p : ISERDESE1
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
         DDLY          => dqs_p_iodelay,
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

   u_rd_bitslip_early: rd_bitslip
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

   rd_dqs_rise0 <= rddata(3);
   rd_dqs_fall0 <= rddata(2);
   rd_dqs_rise1 <= rddata(1);
   rd_dqs_fall1 <= rddata(0);

end trans_phy_dqs_iob;






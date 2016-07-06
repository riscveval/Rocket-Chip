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
-- /___/  \  /    Vendor             : Xilinx
-- \   \   \/     Version            : 3.92
--  \   \         Application        : MIG
--  /   /         Filename           : mig_vhdl.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:11 $
-- \   \  /  \    Date Created       : Mon Jun 23 2008
--  \___\/\___\
--
-- Device           : Virtex-6
-- Design Name      : DDR3 SDRAM
-- Purpose          :
--                   Top-level  module. This module serves both as an example,
--                   and allows the user to synthesize a self-contained design,
--                   which they can use to test their hardware. In addition to
--                   the memory controller.
--                   instantiates:
--                     1. Clock generation/distribution, reset logic
--                     2. IDELAY control block
--                     3. Synthesizable testbench - used to model user's backend
--                        logic
-- Reference        :
-- Revision History :
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;

entity mig_ml605 is
  generic(
     REFCLK_FREQ           : real := 200.0;
                                     -- # = 200 for all design frequencies of
                                     --         -1 speed grade devices
                                     --   = 200 when design frequency < 480 MHz
                                     --         for -2 and -3 speed grade devices.
                                     --   = 300 when design frequency >= 480 MHz
                                     --         for -2 and -3 speed grade devices.
     IODELAY_GRP           : string := "IODELAY_MIG";
                                     -- It is associated to a set of IODELAYs with
                                     -- an IDELAYCTRL that have same IODELAY CONTROLLER
                                     -- clock frequency.
     MMCM_ADV_BANDWIDTH    : string  := "OPTIMIZED";
                                     -- MMCM programming algorithm
     CLKFBOUT_MULT_F       : integer := 6;
                                     -- write PLL VCO multiplier.
     DIVCLK_DIVIDE         : integer := 2;
                                     -- write PLL VCO divisor.
     CLKOUT_DIVIDE         : integer := 3;
                                     -- VCO output divisor for fast (memory) clocks.
     nCK_PER_CLK           : integer := 2;
                                     -- # of memory CKs per fabric clock.
                                     -- # = 2, 1.
     tCK                   : integer := 2500;
                                     -- memory tCK paramter.
                                     -- # = Clock Period.
     DEBUG_PORT            : string := "OFF";
                                     -- # = "ON" Enable debug signals/controls.
                                     --   = "OFF" Disable debug signals/controls.
     SIM_BYPASS_INIT_CAL   : string := "OFF";
                                     -- # = "OFF" -  Complete memory init &
                                     --              calibration sequence
                                     -- # = "SKIP" - Skip memory init &
                                     --              calibration sequence
                                     -- # = "FAST" - Skip memory init & use
                                     --              abbreviated calib sequence
     nCS_PER_RANK          : integer := 1;
                                     -- # of unique CS outputs per Rank for
                                     -- phy.
     DQS_CNT_WIDTH         : integer := 3;
                                     -- # = ceil(log2(DQS_WIDTH)).
     RANK_WIDTH            : integer := 1;
                                     -- # = ceil(log2(RANKS)).
     BANK_WIDTH            : integer := 3;
                                     -- # of memory Bank Address bits.
     CK_WIDTH              : integer := 1;
                                     -- # of CK/CK# outputs to memory.
     CKE_WIDTH             : integer := 1;
                                     -- # of CKE outputs to memory.
     COL_WIDTH             : integer := 10;
                                     -- # of memory Column Address bits.
     CS_WIDTH              : integer := 1;
                                     -- # of unique CS outputs to memory.
     DM_WIDTH              : integer := 8;
                                     -- # of Data Mask bits.
     DQ_WIDTH              : integer := 64;
                                     -- # of Data (DQ) bits.
     DQS_WIDTH             : integer := 8;
                                     -- # of DQS/DQS# bits.
     ROW_WIDTH             : integer := 13;
                                     -- # of memory Row Address bits.
     BURST_MODE            : string := "8";
                                     -- Burst Length (Mode Register 0).
                                     -- # = "8", "4", "OTF".
     BM_CNT_WIDTH          : integer := 2;
                                     -- # = ceil(log2(nBANK_MACHS)).
     ADDR_CMD_MODE         : string := "1T" ;
                                     -- # = "2T", "1T".
     ORDERING              : string := "STRICT";
                                     -- # = "NORM", "STRICT".
     WRLVL                 : string := "ON";
                                     -- # = "ON" - DDR3 SDRAM
                                     --   = "OFF" - DDR2 SDRAM.
     PHASE_DETECT          : string := "ON";
                                     -- # = "ON", "OFF".
     RTT_NOM               : string := "60";
                                     -- RTT_NOM (ODT) (Mode Register 1).
                                     -- # = "DISABLED" - RTT_NOM disabled,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
                                     --   = "40"  - RZQ/6.
     RTT_WR                : string := "OFF";
                                     -- RTT_WR (ODT) (Mode Register 2).
                                     -- # = "OFF" - Dynamic ODT off,
                                     --   = "120" - RZQ/2,
                                     --   = "60"  - RZQ/4,
     OUTPUT_DRV            : string := "HIGH";
                                     -- Output Driver Impedance Control (Mode Register 1).
                                     -- # = "HIGH" - RZQ/7,
                                     --   = "LOW" - RZQ/6.
     REG_CTRL              : string := "OFF";
                                     -- # = "ON" - RDIMMs,
                                     --   = "OFF" - Components, SODIMMs, UDIMMs.
     nDQS_COL0             : integer := 6;
                                     -- Number of DQS groups in I/O column #1.
     nDQS_COL1             : integer := 2;
                                     -- Number of DQS groups in I/O column #2.
     nDQS_COL2             : integer := 0;
                                     -- Number of DQS groups in I/O column #3.
     nDQS_COL3             : integer := 0;
                                     -- Number of DQS groups in I/O column #4.
     DQS_LOC_COL0          : std_logic_vector(47 downto 0) := X"050403020100";
                                     -- DQS groups in column #1.
     DQS_LOC_COL1          : std_logic_vector(15 downto 0) := X"0706";
                                     -- DQS groups in column #2.
     DQS_LOC_COL2          : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #3.
     DQS_LOC_COL3          : std_logic_vector(0 downto 0) := "0";
                                     -- DQS groups in column #4.
     tPRDI                 : integer := 1000000;
                                     -- memory tPRDI paramter.
     tREFI                 : integer := 7800000;
                                     -- memory tREFI paramter.
     tZQI                  : integer := 128000000;
                                     -- memory tZQI paramter.
     ADDR_WIDTH            : integer := 27;
                                     -- # = RANK_WIDTH + BANK_WIDTH
                                     --     + ROW_WIDTH + COL_WIDTH;
     ECC                   : string := "OFF";
     ECC_TEST              : string := "OFF";
     TCQ                   : integer := 100;
     DATA_WIDTH            : integer := 64;
     -- If parameters overrinding is used for simulation, PAYLOAD_WIDTH
     -- parameter should to be overidden along with the vsim command
     PAYLOAD_WIDTH         : integer := 64;
		C_S_AXI_ID_WIDTH  : integer := 5;
														-- Width of all master and slave ID signals.
														-- # = >= 1.
		C_S_AXI_ADDR_WIDTH : integer := 32;
														-- Width of S_AXI_AWADDR, S_AXI_ARADDR, M_AXI_AWADDR and
														-- M_AXI_ARADDR for all SI/MI slots.
														-- # = 32.
		C_S_AXI_DATA_WIDTH : integer := 128;
														-- Width of WDATA and RDATA on SI slot.
														-- Must be <= APP_DATA_WIDTH.
														-- # = 32, 64, 128, 256.
		C_S_AXI_SUPPORTS_NARROW_BURST : integer := 1;
														-- Indicates whether to instatiate upsizer
														-- Range: 0, 1
		C_S_AXI_REG_EN0 : std_logic_vector(19 downto 0) := X"00000";
														-- Instatiates register slices before upsizer.
														-- The type of register is specified for each channel
														-- in a vector. 4 bits per channel are used.
														-- C_S_AXI_REG_EN0[03:00] = AW CHANNEL REGISTER SLICE
														-- C_S_AXI_REG_EN0[07:04] =  W CHANNEL REGISTER SLICE
														-- C_S_AXI_REG_EN0[11:08] =  B CHANNEL REGISTER SLICE
														-- C_S_AXI_REG_EN0[15:12] = AR CHANNEL REGISTER SLICE
														-- C_S_AXI_REG_EN0[20:16] =  R CHANNEL REGISTER SLICE
														-- Possible values for each channel are:
														--
														--   0 => BYPASS    = The channel is just wired through the
														--                    module.
														--   1 => FWD       = The master VALID and payload signals
														--                    are registrated.
														--   2 => REV       = The slave ready signal is registrated
														--   3 => FWD_REV   = Both FWD and REV
														--   4 => SLAVE_FWD = All slave side signals and master
														--                    VALID and payload are registrated.
														--   5 => SLAVE_RDY = All slave side signals and master
														--                    READY are registrated.
														--   6 => INPUTS    = Slave and Master side inputs are
														--                    registrated.
														--
														--                                     A  A
														--                                    RRBWW
	  C_S_AXI_REG_EN1 : std_logic_vector(19 downto 0) := X"00000";
														-- Same as C_S_AXI_REG_EN0, but this register is after
														-- the upsizer
	  C_RD_WR_ARB_ALGORITHM : string := "RD_PRI_REG";
														-- Indicates the Arbitration
														-- Allowed values - "TDM", "ROUND_ROBIN",
														-- "RD_PRI_REG", "RD_PRI_REG_STARVE_LIMIT"
	  C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
														-- Width of AXI-4-Lite address bus
	  C_S_AXI_CTRL_DATA_WIDTH : integer := 32;
														-- Width of AXI-4-Lite data buses
	  C_S_AXI_BASEADDR : std_logic_vector(31 downto 0) := X"40000000";
														-- Base address of AXI4 Memory Mapped bus.
	  C_ECC_ONOFF_RESET_VALUE : integer := 1;
														-- Controls ECC on/off value at startup/reset
	  C_ECC_CE_COUNTER_WIDTH : integer := 8
														-- The external memory to controller clock ratio.

    );
  port(

      clk200        : in    std_logic;
      clk           : in    std_logic;
      clk2x         : in    std_logic;
      clk2x_unbuf   : in    std_logic;
      ddr3_dq       : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr3_dm       : out   std_logic_vector(DM_WIDTH-1 downto 0);
      ddr3_addr     : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr3_ba       : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr3_ras_n    : out   std_logic;
      ddr3_cas_n    : out   std_logic;
      ddr3_we_n     : out   std_logic;
      ddr3_reset_n  : out   std_logic;
      ddr3_cs_n     : out   std_logic_vector((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
      ddr3_odt      : out   std_logic_vector((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
      ddr3_cke      : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr3_dqs_p    : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr3_dqs_n    : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr3_ck_p     : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr3_ck_n     : out   std_logic_vector(CK_WIDTH-1 downto 0);
      s_axi_awid : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_awaddr : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awlen : in std_logic_vector(7 downto 0);
      s_axi_awsize : in std_logic_vector(2 downto 0);
      s_axi_awburst : in std_logic_vector(1 downto 0);
      s_axi_awlock : in std_logic;
      s_axi_awcache : in std_logic_vector(3 downto 0);
      s_axi_awprot : in std_logic_vector(2 downto 0);
      s_axi_awqos : in std_logic_vector(3 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      -- Slave Interface Write Data Ports
      s_axi_wdata : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb : in std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
      s_axi_wlast : in std_logic;
      s_axi_wvalid : in std_logic;
      s_axi_wready : out std_logic;
      -- Slave Interface Write Response Ports
      s_axi_bid : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_bresp : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bready : in std_logic;
      -- Slave Interface Read Address Ports
      s_axi_arid : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_araddr : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arlen : in std_logic_vector(7 downto 0);
      s_axi_arsize : in std_logic_vector(2 downto 0);
      s_axi_arburst : in std_logic_vector(1 downto 0);
      s_axi_arlock : in std_logic;
      s_axi_arcache : in std_logic_vector(3 downto 0);
      s_axi_arprot : in std_logic_vector(2 downto 0);
      s_axi_arqos : in std_logic_vector(3 downto 0);
      s_axi_arvalid : in std_logic;
      s_axi_arready : out std_logic;
      -- Slave Interface Read Data Ports
      s_axi_rid : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_rdata : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp : out std_logic_vector(1 downto 0);
      s_axi_rlast : out std_logic;
      s_axi_rvalid : out std_logic;
      s_axi_rready : in std_logic;
      interrupt : out   std_logic;
      phy_init_done : out   std_logic;
      rstn        : in std_logic
    );
end entity mig_ml605;

architecture arch_mig_ml605 of mig_ml605 is

  constant SYSCLK_PERIOD : integer := tCK * nCK_PER_CLK;

  -- The following parameters used to drive Data and Address modes
  -- in debug ports
  constant SIMULATION : string := "FALSE";
  constant DATA_MODE  : std_logic_vector(3 downto 0) := "0010";
  constant ADDR_MODE  : std_logic_vector(2 downto 0) := "011";
  constant APP_DATA_WIDTH : integer := PAYLOAD_WIDTH * 4;
  constant APP_MASK_WIDTH : integer := APP_DATA_WIDTH / 8;

  component iodelay_ctrl
    generic (
      TCQ            : integer;
      IODELAY_GRP    : string
      );
    port (
      clk200           : in  std_logic;
      rstn             : in  std_logic;
      iodelay_ctrl_rdy : out std_logic
      );
  end component iodelay_ctrl;

  component memc_ui_top
    generic(
      REFCLK_FREQ           : real;
      SIM_BYPASS_INIT_CAL   : string;
      IODELAY_GRP           : string;
      nCK_PER_CLK           : integer;
      nCS_PER_RANK          : integer;
      DQS_CNT_WIDTH         : integer;
      RANK_WIDTH            : integer;
      BANK_WIDTH            : integer;
      CK_WIDTH              : integer;
      CKE_WIDTH             : integer;
      COL_WIDTH             : integer;
      CS_WIDTH              : integer;
      DQ_WIDTH              : integer;
      DM_WIDTH              : integer;
      DQS_WIDTH             : integer;
      ROW_WIDTH             : integer;
      BURST_MODE            : string;
      BM_CNT_WIDTH          : integer;
      ADDR_CMD_MODE         : string;
      ORDERING              : string;
      WRLVL                 : string;
      PHASE_DETECT          : string;
      RTT_NOM               : string;
      RTT_WR                : string;
      OUTPUT_DRV            : string;
      REG_CTRL              : string;
      nDQS_COL0             : integer;
      nDQS_COL1             : integer;
      nDQS_COL2             : integer;
      nDQS_COL3             : integer;
      DQS_LOC_COL0          : std_logic_vector(47 downto 0);
      DQS_LOC_COL1          : std_logic_vector(15 downto 0);
      DQS_LOC_COL2          : std_logic_vector(0 downto 0);
      DQS_LOC_COL3          : std_logic_vector(0 downto 0);
      tCK                   : integer;
      DEBUG_PORT            : string;
      tPRDI                 : integer;
      tREFI                 : integer;
      tZQI                  : integer;
      ADDR_WIDTH            : integer;
      TCQ                   : integer;
      ECC                   : string;
      ECC_TEST              : string;
      PAYLOAD_WIDTH         : integer;
      APP_DATA_WIDTH        : integer;
      APP_MASK_WIDTH        : integer;
      INTERFACE  : string;
      C_S_AXI_ID_WIDTH  : integer;
      C_S_AXI_ADDR_WIDTH : integer;
      C_S_AXI_DATA_WIDTH : integer;
      C_S_AXI_SUPPORTS_NARROW_BURST : integer;
      C_S_AXI_REG_EN0 : std_logic_vector(19 downto 0);
      C_S_AXI_REG_EN1 : std_logic_vector(19 downto 0);
      C_RD_WR_ARB_ALGORITHM : string;
      C_S_AXI_CTRL_ADDR_WIDTH : integer;
      C_S_AXI_CTRL_DATA_WIDTH : integer;
      C_S_AXI_BASEADDR : std_logic_vector(31 downto 0);
      C_ECC_ONOFF_RESET_VALUE : integer;
      C_ECC_CE_COUNTER_WIDTH : integer
      );
    port(
      clk                       : in    std_logic;
      clk_mem                   : in    std_logic;
      clk_rd_base               : in    std_logic;
      rst                       : in    std_logic;
      ddr_addr                  : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr_ba                    : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr_cas_n                 : out   std_logic;
      ddr_ck_n                  : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_ck                    : out   std_logic_vector(CK_WIDTH-1 downto 0);
      ddr_cke                   : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr_cs_n                  : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_dm                    : out   std_logic_vector(DM_WIDTH-1 downto 0);
      ddr_odt                   : out   std_logic_vector(CS_WIDTH*nCS_PER_RANK-1 downto 0);
      ddr_ras_n                 : out   std_logic;
      ddr_reset_n               : out   std_logic;
      ddr_parity                : out   std_logic;
      ddr_we_n                  : out   std_logic;
      ddr_dq                    : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr_dqs_n                 : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      ddr_dqs                   : inout std_logic_vector(DQS_WIDTH-1 downto 0);
      pd_PSEN                   : out   std_logic;
      pd_PSINCDEC               : out   std_logic;
      pd_PSDONE                 : in    std_logic;
      phy_init_done             : out   std_logic;
      bank_mach_next            : out   std_logic_vector(BM_CNT_WIDTH-1 downto 0);
      app_ecc_multiple_err      : out   std_logic_vector(3 downto 0);
      dbg_wr_dq_tap_set         : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wr_dqs_tap_set        : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wr_tap_set_en         : in    std_logic;
      dbg_wrlvl_start           : out   std_logic;
      dbg_wrlvl_done            : out   std_logic;
      dbg_wrlvl_err             : out   std_logic;
      dbg_wl_dqs_inverted       : out   std_logic_vector(DQS_WIDTH-1 downto 0);
      dbg_wr_calib_clk_delay    : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dqs_tap_cnt : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_wl_odelay_dq_tap_cnt  : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rdlvl_start           : out   std_logic_vector(1 downto 0);
      dbg_rdlvl_done            : out   std_logic_vector(1 downto 0);
      dbg_rdlvl_err             : out   std_logic_vector(1 downto 0);
      dbg_cpt_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_first_edge_cnt    : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_cpt_second_edge_cnt   : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rd_bitslip_cnt        : out   std_logic_vector(3*DQS_WIDTH-1 downto 0);
      dbg_rd_clkdly_cnt         : out   std_logic_vector(2*DQS_WIDTH-1 downto 0);
      dbg_rd_active_dly         : out   std_logic_vector(4 downto 0);
      dbg_pd_off                : in    std_logic;
      dbg_pd_maintain_off       : in    std_logic;
      dbg_pd_maintain_0_only    : in    std_logic;
      dbg_inc_cpt               : in    std_logic;
      dbg_dec_cpt               : in    std_logic;
      dbg_inc_rd_dqs            : in    std_logic;
      dbg_dec_rd_dqs            : in    std_logic;
      dbg_inc_dec_sel           : in    std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_inc_rd_fps            : in    std_logic;
      dbg_dec_rd_fps            : in    std_logic;
      dbg_dqs_tap_cnt           : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_dq_tap_cnt            : out   std_logic_vector(5*DQS_WIDTH-1 downto 0);
      dbg_rddata                : out   std_logic_vector(4*DQ_WIDTH-1 downto 0);

      aresetn  : in std_logic;
  
      -- Slave Interface Write Address Ports
      s_axi_awid   : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_awaddr : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_awlen  : in std_logic_vector(7 downto 0);
      s_axi_awsize : in std_logic_vector(2 downto 0);
      s_axi_awburst : in std_logic_vector(1 downto 0);
      s_axi_awlock  : in std_logic_vector(0 downto 0);
      s_axi_awcache : in std_logic_vector(3 downto 0);
      s_axi_awprot  : in std_logic_vector(2 downto 0);
      s_axi_awqos   : in std_logic_vector(3 downto 0);
      s_axi_awvalid : in std_logic;
      s_axi_awready : out std_logic;
      -- Slave Interface Write Data Ports
      s_axi_wdata  : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_wstrb  : in std_logic_vector(C_S_AXI_DATA_WIDTH/8-1 downto 0);
      s_axi_wlast  : in std_logic;
      s_axi_wvalid : in std_logic;
      s_axi_wready : out std_logic;
      -- Slave Interface Write Response Ports
      s_axi_bid    : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_bresp  : out std_logic_vector(1 downto 0);
      s_axi_bvalid : out std_logic;
      s_axi_bready : in std_logic;
      -- Slave Interface Read Address Ports
      s_axi_arid   : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_araddr : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
      s_axi_arlen  : in std_logic_vector(7 downto 0);
      s_axi_arsize : in std_logic_vector(2 downto 0);
      s_axi_arburst  : in std_logic_vector(1 downto 0);
      s_axi_arlock   : in std_logic_vector(0 downto 0);
      s_axi_arcache  : in std_logic_vector(3 downto 0);
      s_axi_arprot   : in std_logic_vector(2 downto 0);
      s_axi_arqos    : in std_logic_vector(3 downto 0);
      s_axi_arvalid  : in std_logic;
      s_axi_arready  : out std_logic;
      -- Slave Interface Read Data Ports
      s_axi_rid    : out std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
      s_axi_rdata  : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
      s_axi_rresp  : out std_logic_vector(1 downto 0);
      s_axi_rlast  : out std_logic;
      s_axi_rvalid : out std_logic;
      s_axi_rready : in std_logic;
      interrupt                 : out   std_logic
     );
  end component memc_ui_top;


  signal mmcm_clk                       : std_logic;
  signal iodelay_ctrl_rdy               : std_logic;
      
  signal rst                            : std_logic;
  signal pd_PSDONE                      : std_logic;
  signal pd_PSEN                        : std_logic;
  signal pd_PSINCDEC                    : std_logic;
  signal bank_mach_next                 : std_logic_vector((BM_CNT_WIDTH)-1 downto 0);
  signal ddr3_parity                    : std_logic;
  signal app_hi_pri                     : std_logic;

  signal phy_init_done_i                : std_logic;
  signal app_ecc_multiple_err_i         : std_logic_vector(3 downto 0);
  signal traffic_wr_data_counts         : std_logic_vector(47 downto 0);
  signal traffic_rd_data_counts         : std_logic_vector(47 downto 0);


  signal dbg_cpt_first_edge_cnt         : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_cpt_second_edge_cnt        : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_cpt_tap_cnt                : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_dec_cpt                    : std_logic;
  signal dbg_dec_rd_dqs                 : std_logic;
  signal dbg_dec_rd_fps                 : std_logic;
  signal dbg_dq_tap_cnt                 : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_dqs_tap_cnt                : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_inc_cpt                    : std_logic;
  signal dbg_inc_dec_sel                : std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
  signal dbg_inc_rd_dqs                 : std_logic;
  signal dbg_inc_rd_fps                 : std_logic;
  signal dbg_ocb_mon_off                : std_logic;
  signal dbg_pd_off                     : std_logic;
  signal dbg_pd_maintain_off            : std_logic;
  signal dbg_pd_maintain_0_only         : std_logic;
  signal dbg_rd_active_dly              : std_logic_vector(4 downto 0);
  signal dbg_rd_bitslip_cnt             : std_logic_vector(3*DQS_WIDTH-1 downto 0);
  signal dbg_rd_clkdly_cnt              : std_logic_vector(2*DQS_WIDTH-1 downto 0);
  signal dbg_rddata                     : std_logic_vector(4*DQ_WIDTH-1 downto 0);
  signal dbg_rdlvl_done                 : std_logic_vector(1 downto 0);
  signal dbg_rdlvl_err                  : std_logic_vector(1 downto 0);
  signal dbg_rdlvl_start                : std_logic_vector(1 downto 0);
  signal dbg_wl_dqs_inverted            : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal dbg_wl_odelay_dq_tap_cnt       : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_wl_odelay_dqs_tap_cnt      : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_wr_calib_clk_delay         : std_logic_vector(2*DQS_WIDTH-1 downto 0);
  signal dbg_wr_dq_tap_set              : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_wr_dqs_tap_set             : std_logic_vector(5*DQS_WIDTH-1 downto 0);
  signal dbg_wr_tap_set_en              : std_logic;
  signal dbg_idel_up_all                : std_logic;
  signal dbg_idel_down_all              : std_logic;
  signal dbg_idel_up_cpt                : std_logic;
  signal dbg_idel_down_cpt              : std_logic;
  signal dbg_idel_up_rsync              : std_logic;
  signal dbg_idel_down_rsync            : std_logic;
  signal dbg_sel_all_idel_cpt           : std_logic;
  signal dbg_sel_all_idel_rsync         : std_logic;
  signal dbg_pd_inc_cpt                 : std_logic;
  signal dbg_pd_dec_cpt                 : std_logic;
  signal dbg_pd_inc_dqs                 : std_logic;
  signal dbg_pd_dec_dqs                 : std_logic;
  signal dbg_pd_disab_hyst              : std_logic;
  signal dbg_pd_disab_hyst_0            : std_logic;
  signal dbg_wrlvl_done                 : std_logic;
  signal dbg_wrlvl_err                  : std_logic;
  signal dbg_wrlvl_start                : std_logic;
  signal dbg_tap_cnt_during_wrlvl       : std_logic_vector(4 downto 0);
  signal dbg_rsync_tap_cnt              : std_logic_vector(19 downto 0);
  signal dbg_phy_pd                     : std_logic_vector(255 downto 0);
  signal dbg_phy_read                   : std_logic_vector(255 downto 0);
  signal dbg_phy_rdlvl                  : std_logic_vector(255 downto 0);
  signal dbg_phy_top                    : std_logic_vector(255 downto 0);
  signal dbg_pd_msb_sel                 : std_logic_vector(3 downto 0);
  signal dbg_rd_data_edge_detect        : std_logic_vector(DQS_WIDTH-1 downto 0);
  signal dbg_sel_idel_cpt               : std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
  signal dbg_sel_idel_rsync             : std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
  signal dbg_pd_byte_sel                : std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
  signal modify_enable_sel              : std_logic;
  signal vio_data_mode                  : std_logic_vector(2 downto 0);
  signal vio_addr_mode                  : std_logic_vector(2 downto 0);

  signal ddr3_cs0_clk          : std_logic;
  signal ddr3_cs0_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs0_data         : std_logic_vector(383 downto 0);
  signal ddr3_cs0_trig         : std_logic_vector(7 downto 0);
  signal ddr3_cs1_async_in     : std_logic_vector(255 downto 0);
  signal ddr3_cs1_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs2_async_in     : std_logic_vector(255 downto 0);
  signal ddr3_cs2_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs3_async_in     : std_logic_vector(255 downto 0);
  signal ddr3_cs3_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs4_clk          : std_logic;
  signal ddr3_cs4_control      : std_logic_vector(35 downto 0);
  signal ddr3_cs4_sync_out     : std_logic_vector(31 downto 0);

  signal s_axi_awlock_vec : std_logic_vector(0 downto 0);
  signal s_axi_arlock_vec : std_logic_vector(0 downto 0);

begin

  --***************************************************************************
  phy_init_done               <= phy_init_done_i;


  u_iodelay_ctrl : iodelay_ctrl
    generic map(
      TCQ            => TCQ,
      IODELAY_GRP    => IODELAY_GRP
      )
    port map(
      clk200        => clk200,
      rstn          => rstn,
      iodelay_ctrl_rdy => iodelay_ctrl_rdy
      );
  rst <= not rstn or not iodelay_ctrl_rdy;

  s_axi_awlock_vec(0) <= s_axi_awlock;
  s_axi_arlock_vec(0) <= s_axi_arlock;
  
  u_memc_ui_top : memc_ui_top
    generic map(
      ADDR_CMD_MODE       => ADDR_CMD_MODE,
      BANK_WIDTH          => BANK_WIDTH,
      CK_WIDTH            => CK_WIDTH,
      CKE_WIDTH           => CKE_WIDTH,
      nCK_PER_CLK         => nCK_PER_CLK,
      COL_WIDTH           => COL_WIDTH,
      CS_WIDTH            => CS_WIDTH,
      DM_WIDTH        => DM_WIDTH,
      nCS_PER_RANK        => nCS_PER_RANK,
      DEBUG_PORT          => DEBUG_PORT,
      IODELAY_GRP         => IODELAY_GRP,
      DQ_WIDTH            => DQ_WIDTH,
      DQS_WIDTH           => DQS_WIDTH,
      DQS_CNT_WIDTH       => DQS_CNT_WIDTH,
      ORDERING            => ORDERING,
      OUTPUT_DRV          => OUTPUT_DRV,
      PHASE_DETECT        => PHASE_DETECT,
      RANK_WIDTH          => RANK_WIDTH,
      REFCLK_FREQ         => REFCLK_FREQ,
      REG_CTRL            => REG_CTRL,
      ROW_WIDTH           => ROW_WIDTH,
      RTT_NOM             => RTT_NOM,
      RTT_WR              => RTT_WR,
      SIM_BYPASS_INIT_CAL => SIM_BYPASS_INIT_CAL,
      WRLVL               => WRLVL,
      nDQS_COL0           => nDQS_COL0,
      nDQS_COL1           => nDQS_COL1,
      nDQS_COL2           => nDQS_COL2,
      nDQS_COL3           => nDQS_COL3,
      DQS_LOC_COL0        => DQS_LOC_COL0,
      DQS_LOC_COL1        => DQS_LOC_COL1,
      DQS_LOC_COL2        => DQS_LOC_COL2,
      DQS_LOC_COL3        => DQS_LOC_COL3,
      BURST_MODE          => BURST_MODE,
      BM_CNT_WIDTH        => BM_CNT_WIDTH,
      tCK                 => tCK,
      tPRDI               => tPRDI,
      tREFI               => tREFI,
      tZQI                => tZQI,
      ADDR_WIDTH          => ADDR_WIDTH,
      TCQ                 => TCQ,
      ECC                 => ECC,
      ECC_TEST            => ECC_TEST,
      PAYLOAD_WIDTH       => PAYLOAD_WIDTH,
      APP_DATA_WIDTH      => APP_DATA_WIDTH,
      APP_MASK_WIDTH      => APP_MASK_WIDTH,
		INTERFACE  => "AXI4",
		C_S_AXI_ID_WIDTH  => C_S_AXI_ID_WIDTH,
		C_S_AXI_ADDR_WIDTH => C_S_AXI_ADDR_WIDTH,
		C_S_AXI_DATA_WIDTH => C_S_AXI_DATA_WIDTH,
		C_S_AXI_SUPPORTS_NARROW_BURST => C_S_AXI_SUPPORTS_NARROW_BURST,
		C_S_AXI_REG_EN0 => C_S_AXI_REG_EN0 ,
		C_S_AXI_REG_EN1 => C_S_AXI_REG_EN1,
		C_RD_WR_ARB_ALGORITHM => C_RD_WR_ARB_ALGORITHM ,
		C_S_AXI_CTRL_ADDR_WIDTH => C_S_AXI_CTRL_ADDR_WIDTH,
		C_S_AXI_CTRL_DATA_WIDTH => C_S_AXI_CTRL_DATA_WIDTH,
		C_S_AXI_BASEADDR => C_S_AXI_BASEADDR,
		C_ECC_ONOFF_RESET_VALUE => C_ECC_ONOFF_RESET_VALUE,
		C_ECC_CE_COUNTER_WIDTH => C_ECC_CE_COUNTER_WIDTH
      )
    port map(
      clk                       => clk,
      clk_mem                   => clk2x,
      clk_rd_base               => clk2x_unbuf,
      rst                       => rst,
      ddr_addr                  => ddr3_addr,
      ddr_ba                    => ddr3_ba,
      ddr_cas_n                 => ddr3_cas_n,
      ddr_ck_n                  => ddr3_ck_n,
      ddr_ck                    => ddr3_ck_p,
      ddr_cke                   => ddr3_cke,
      ddr_cs_n                  => ddr3_cs_n,
      ddr_dm                    => ddr3_dm,
      ddr_odt                   => ddr3_odt,
      ddr_ras_n                 => ddr3_ras_n,
      ddr_reset_n               => ddr3_reset_n,
      ddr_parity                => ddr3_parity,
      ddr_we_n                  => ddr3_we_n,
      ddr_dq                    => ddr3_dq,
      ddr_dqs_n                 => ddr3_dqs_n,
      ddr_dqs                   => ddr3_dqs_p,
      pd_PSEN                   => pd_PSEN,
      pd_PSINCDEC               => pd_PSINCDEC,
      pd_PSDONE                 => pd_PSDONE,
      phy_init_done             => phy_init_done_i,
      bank_mach_next            => bank_mach_next,
      app_ecc_multiple_err      => app_ecc_multiple_err_i,
      dbg_wr_dqs_tap_set        => dbg_wr_dqs_tap_set,
      dbg_wr_dq_tap_set         => dbg_wr_dq_tap_set,
      dbg_wr_tap_set_en         => dbg_wr_tap_set_en,
      dbg_wrlvl_start           => dbg_wrlvl_start,
      dbg_wrlvl_done            => dbg_wrlvl_done,
      dbg_wrlvl_err             => dbg_wrlvl_err,
      dbg_wl_dqs_inverted       => dbg_wl_dqs_inverted,
      dbg_wr_calib_clk_delay    => dbg_wr_calib_clk_delay,
      dbg_wl_odelay_dqs_tap_cnt => dbg_wl_odelay_dqs_tap_cnt,
      dbg_wl_odelay_dq_tap_cnt  => dbg_wl_odelay_dq_tap_cnt,
      dbg_rdlvl_start           => dbg_rdlvl_start,
      dbg_rdlvl_done            => dbg_rdlvl_done,
      dbg_rdlvl_err             => dbg_rdlvl_err,
      dbg_cpt_tap_cnt           => dbg_cpt_tap_cnt,
      dbg_cpt_first_edge_cnt    => dbg_cpt_first_edge_cnt,
      dbg_cpt_second_edge_cnt   => dbg_cpt_second_edge_cnt,
      dbg_rd_bitslip_cnt        => dbg_rd_bitslip_cnt,
      dbg_rd_clkdly_cnt         => dbg_rd_clkdly_cnt,
      dbg_rd_active_dly         => dbg_rd_active_dly,
      dbg_pd_off                => dbg_pd_off,
      dbg_pd_maintain_off       => dbg_pd_maintain_off,
      dbg_pd_maintain_0_only    => dbg_pd_maintain_0_only,
      dbg_inc_cpt               => dbg_inc_cpt,
      dbg_dec_cpt               => dbg_dec_cpt,
      dbg_inc_rd_dqs            => dbg_inc_rd_dqs,
      dbg_dec_rd_dqs            => dbg_dec_rd_dqs,
      dbg_inc_dec_sel           => dbg_inc_dec_sel,
      dbg_inc_rd_fps            => dbg_inc_rd_fps,
      dbg_dec_rd_fps            => dbg_dec_rd_fps,
      dbg_dqs_tap_cnt           => dbg_dqs_tap_cnt,
      dbg_dq_tap_cnt            => dbg_dq_tap_cnt,
      dbg_rddata                => dbg_rddata,

      aresetn => '1',

      -- Slave Interface Write Address Ports
      s_axi_awid   => s_axi_awid,
      s_axi_awaddr => s_axi_awaddr,
      s_axi_awlen  => s_axi_awlen,
      s_axi_awsize => s_axi_awsize,
      s_axi_awburst => s_axi_awburst,
      s_axi_awlock  => s_axi_awlock_vec,
      s_axi_awcache => s_axi_awcache,
      s_axi_awprot  => s_axi_awprot,
      s_axi_awqos   => s_axi_awqos,
      s_axi_awvalid => s_axi_awvalid,
      s_axi_awready => s_axi_awready,
      -- Slave Interface Write Data Ports
      s_axi_wdata  => s_axi_wdata,
      s_axi_wstrb  => s_axi_wstrb,
      s_axi_wlast  => s_axi_wlast,
      s_axi_wvalid => s_axi_wvalid,
      s_axi_wready => s_axi_wready,
      -- Slave Interface Write Response Ports
      s_axi_bid    => s_axi_bid,
      s_axi_bresp  => s_axi_bresp,
      s_axi_bvalid => s_axi_bvalid,
      s_axi_bready => s_axi_bready,
      -- Slave Interface Read Address Ports
      s_axi_arid   => s_axi_arid,
      s_axi_araddr => s_axi_araddr,
      s_axi_arlen  => s_axi_arlen,
      s_axi_arsize => s_axi_arsize,
      s_axi_arburst  => s_axi_arburst,
      s_axi_arlock   => s_axi_arlock_vec,
      s_axi_arcache  => s_axi_arcache,
      s_axi_arprot   => s_axi_arprot,
      s_axi_arqos    => s_axi_arqos,
      s_axi_arvalid  => s_axi_arvalid,
      s_axi_arready  => s_axi_arready,
      -- Slave Interface Read Data Ports
      s_axi_rid    => s_axi_rid,
      s_axi_rdata  => s_axi_rdata,
      s_axi_rresp  => s_axi_rresp,
      s_axi_rlast  => s_axi_rlast,
      s_axi_rvalid => s_axi_rvalid,
      s_axi_rready => s_axi_rready,

      interrupt => interrupt
    );




  -- If debug port is not enabled, then make certain control input
  -- to Debug Port are disabled
  gen_dbg_tie_off : if (DEBUG_PORT = "OFF") generate
    dbg_wr_dqs_tap_set     <= (others => '0');
    dbg_wr_dq_tap_set      <= (others => '0');
    dbg_wr_tap_set_en      <= '0';
    dbg_pd_off             <= '0';
    dbg_pd_maintain_off    <= '0';
    dbg_pd_maintain_0_only <= '0';
    dbg_ocb_mon_off        <= '0';
    dbg_inc_cpt            <= '0';
    dbg_dec_cpt            <= '0';
    dbg_inc_rd_dqs         <= '0';
    dbg_dec_rd_dqs         <= '0';
    dbg_inc_dec_sel        <= (others => '0');
    dbg_inc_rd_fps         <= '0';
    dbg_pd_msb_sel         <= (others => '0');
    dbg_sel_idel_cpt       <= (others => '0');
    dbg_sel_idel_rsync     <= (others => '0');
    dbg_pd_byte_sel        <= (others => '0');
    dbg_dec_rd_fps         <= '0';
    modify_enable_sel      <= '0';
  end generate gen_dbg_tie_off;


end architecture arch_mig_ml605;

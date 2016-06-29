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
--  /   /         Filename           : memc_ui_top.vhd
-- /___/   /\     Date Last Modified : $Date: 2011/06/02 07:18:11 $
-- \   \  /  \    Date Created       : Mon Jun 23 2008
--  \___\/\___\
--
-- Device           : Virtex-6
-- Design Name      : DDR2 SDRAM & DDR3 SDRAM
-- Purpose          :
--                   Top level memory interface block. Instantiates a clock and
--                   reset generator, the memory controller, the phy and the
--                   user interface blocks.
-- Reference        :
-- Revision History :
--*****************************************************************************

library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;

entity memc_ui_top is
  generic(
    REFCLK_FREQ             : real := 200.0;
                                    -- DDR2 SDRAM:
				    -- # = 200 for all design frequencies
                                    -- DDR3 SDRAM:
				    -- # = 200 for all design frequencies of
                                    --         -1 speed grade devices
                                    --   = 200 when design frequency < 480 MHz
                                    --         for -2 and -3 speed grade devices
                                    --   = 300 when design frequency >= 480 MHz
                                    --         for -2 and -3 speed grade devices
    SIM_BYPASS_INIT_CAL     : string := "OFF";
                                        -- # = "OFF" -  Complete memory init &
                                        --              calibration sequence
                                        -- # = "SKIP" - Skip memory init &
                                        --              calibration sequence
                                        -- # = "FAST" - Skip memory init & use
                                        --              abbreviated calib sequence
    IODELAY_GRP             : string := "IODELAY_MIG";
                                        --to phy_top
    nCK_PER_CLK             : integer := 2;
                                        -- # of memory CKs per fabric clock.
                                        -- # = 2, 1.
    DRAM_TYPE               : string := "DDR3";
                                        -- SDRAM type. # = "DDR3", "DDR2".
    nCS_PER_RANK            : integer := 1;
                                        -- # of unique CS outputs per Rank for
                                        -- phy.
    DQ_CNT_WIDTH            : integer := 6;
                                        -- # = ceil(log2(DQ_WIDTH)).
    DQS_CNT_WIDTH           : integer := 3;
                                        -- # = ceil(log2(DQS_WIDTH)).
    RANK_WIDTH              : integer := 1;
                                        -- # = ceil(log2(RANKS)).
    BANK_WIDTH              : integer := 3;
                                        -- # of memory Bank Address bits.
    CK_WIDTH                : integer := 1;
                                        -- # of CK/CK# outputs to memory.
    CKE_WIDTH               : integer := 1;
                                        -- # of CKE outputs to memory.
    COL_WIDTH               : integer := 10;
                                        -- # of memory Column Address bits.
    CS_WIDTH                : integer := 1;
                                        -- # of unique CS outputs to memory.
    DM_WIDTH                : integer := 8;
                                        -- # of Data Mask bits.
    USE_DM_PORT             : integer := 1;
                                        -- # = 1, When Data Mask option is enabled
                                        --   = 0, When Data Mask option is disbaled
                                        -- When Data Mask option is disbaled in
                                        -- MIG Controller Options page, the logic
                                        -- related to Data Mask should not get
                                        -- synthesized
    DQ_WIDTH                : integer := 64;
                                        -- # of Data (DQ) bits.
    DRAM_WIDTH              : integer := 8;
                                        -- # of DQ bits per DQS.
    DQS_WIDTH               : integer := 8;
                                        -- # of DQS/DQS# bits.
    ROW_WIDTH               : integer := 13;
                                        -- # of memory Row Address bits.
    AL                      : string := "0";
                                        -- DDR3 SDRAM:
                                        -- Additive Latency (Mode Register 1).
                                        -- # = "0", "CL-1", "CL-2".
                                        -- DDR2 SDRAM:
                                        -- Additive Latency (Extended Mode Register).
    BURST_MODE              : string := "8";
                                        -- DDR3 SDRAM:
                                        -- Burst Length (Mode Register 0).
                                        -- # = "8", "4", "OTF".
                                        -- DDR2 SDRAM:
                                        -- Burst Length (Mode Register).
                                        -- # = "8", "4".
    BURST_TYPE              : string := "SEQ";
                                        -- DDR3 SDRAM: Burst Type (Mode Register 0).
                                        -- DDR2 SDRAM: Burst Type (Mode Register).
                                        -- # = "SEQ" - (Sequential),
                                        --   = "INT" - (Interleaved).
    IBUF_LPWR_MODE          : string := "OFF";
                                        -- to phy_top
    IODELAY_HP_MODE         : string := "ON";
                                        -- to phy_top
    nAL                     : integer := 0;
                                        -- # Additive Latency in number of clock
                                        -- cycles.
    CL                      : integer := 6;
                                        -- DDR3 SDRAM: CAS Latency (Mode Register 0).
                                        -- DDR2 SDRAM: CAS Latency (Mode Register).
    CWL                     : integer := 5;
                                        -- DDR3 SDRAM: CAS Write Latency (Mode Register 2).
                                        -- DDR2 SDRAM: Can be ignored
    DATA_BUF_ADDR_WIDTH     : integer := 4;
    DATA_BUF_OFFSET_WIDTH   : integer := 1;
                                        -- # = 0,1.
    --DELAY_WR_DATA_CNTRL     : integer := 0; --This parameter is made as MC's constant
                                        -- # = 0,1.
    BM_CNT_WIDTH            : integer := 2;
                                        -- # = ceil(log2(nBANK_MACHS)).
    ADDR_CMD_MODE           : string := "1T" ;
                                        -- # = "2T", "1T".
    nBANK_MACHS             : integer := 4;
                                        -- # = 2,3,4,5,6,7,8.
    ORDERING                : string := "STRICT";
                                        -- # = "NORM", "STRICT".
    RANKS                   : integer := 1;
                                        -- # of Ranks.
    WRLVL                   : string := "ON";
                                        -- # = "ON" - DDR3 SDRAM
                                        --   = "OFF" - DDR2 SDRAM.
    PHASE_DETECT            : string := "ON";
                                        -- # = "ON", "OFF".
    CAL_WIDTH               : string := "HALF";
                                        -- # = "HALF", "FULL".
   --parameter CALIB_ROW_ADD           = 16'h0000,// Calibration row address
   --parameter CALIB_COL_ADD           = 12'h000, // Calibration column address
   --parameter CALIB_BA_ADD            = 3'h0,    // Calibration bank address
    RTT_NOM                 : string := "60";
                                        -- DDR3 SDRAM:
                                        -- RTT_NOM (ODT) (Mode Register 1).
                                        -- # = "DISABLED" - RTT_NOM disabled,
                                        --   = "120" - RZQ/2,
                                        --   = "60"  - RZQ/4,
                                        --   = "40"  - RZQ/6.
                                        -- DDR2 SDRAM:
                                        -- RTT (Nominal) (Extended Mode Register).
                                        -- # = "DISABLED" - RTT disabled,
                                        --   = "150" - 150 Ohms,
                                        --   = "75" - 75 Ohms,
                                        --   = "50" - 50 Ohms.
    RTT_WR                  : string := "OFF";
                                        -- DDR3 SDRAM:
                                        -- RTT_WR (ODT) (Mode Register 2).
                                        -- # = "OFF" - Dynamic ODT off,
                                        --   = "120" - RZQ/2,
                                        --   = "60"  - RZQ/4,
                                        -- DDR2 SDRAM:
                                        -- Can be ignored. Always set to "OFF".
    OUTPUT_DRV              : string := "HIGH";
                                        -- DDR3 SDRAM:
                                        -- Output Drive Strength (Mode Register 1).
                                        -- # = "HIGH" - RZQ/7,
                                        --   = "LOW" - RZQ/6.
                                        -- DDR2 SDRAM:
                                        -- Output Drive Strength (Extended Mode Register).
                                        -- # = "HIGH" - FULL,
                                        --   = "LOW" - REDUCED.
    REG_CTRL                : string := "OFF";
                                        -- # = "ON" - RDIMMs,
                                        --   = "OFF" - Components, SODIMMs, UDIMMs.
    nDQS_COL0               : integer :=6;
                                        -- Number of DQS groups in I/O column #1.
    nDQS_COL1               : integer := 2;
                                        -- Number of DQS groups in I/O column #2.
    nDQS_COL2               : integer := 0;
                                        -- Number of DQS groups in I/O column #3.
    nDQS_COL3               : integer := 0;
                                        -- Number of DQS groups in I/O column #4.
    DQS_LOC_COL0            : std_logic_vector(47 downto 0) := X"050403020100";
                                        -- DQS groups in column #1.
    DQS_LOC_COL1            : std_logic_vector(15 downto 0) := X"0706";
                                        -- DQS groups in column #2.
    DQS_LOC_COL2            : std_logic_vector(0 downto 0) := "0";
                                        -- DQS groups in column #3.
    DQS_LOC_COL3            : std_logic_vector(0 downto 0) := "0";
                                        -- DQS groups in column #4.
    tCK                     : integer := 2500;
                                        -- memory tCK paramter.
                                        -- # = Clock Period.
    tFAW                    : integer := 37500;
                                        -- memory tRAW paramter.
    tPRDI                   : integer := 1000000;
                                        -- memory tPRDI paramter.
    tRRD                    : integer := 10000;
                                        -- memory tRRD paramter.
    tRAS                    : integer := 37500;
                                        -- memory tRAS paramter.
    tRCD                    : integer := 13130;
                                        -- memory tRCD paramter.
    tREFI                   : integer := 7800000;
                                        -- memory tREFI paramter.
    tRFC                    : integer := 110000;
                                        -- memory tRFC paramter.
    tRP                     : integer := 13130;
                                        -- memory tRP paramter.
    tRTP                    : integer := 7500;
                                        -- memory tRTP paramter.
    tWTR                    : integer := 7500;
                                        -- memory tWTR paramter.
    tZQI                    : integer := 128000000;
                                        -- memory tZQI paramter.
    tZQCS                   : integer := 64;
                                        -- memory tZQCS paramter.
    SLOT_0_CONFIG           : std_logic_vector(7 downto 0) := X"01";
                                        -- Mapping of Ranks.
    SLOT_1_CONFIG           : std_logic_vector(7 downto 0) := X"00";
                                        -- Mapping of Ranks.
    DEBUG_PORT              : string := "OFF";
                                        -- # = "ON" Enable debug signals/controls.
                                        --   = "OFF" Disable debug signals/controls.
    ADDR_WIDTH              : integer := 27;
                                        -- # = RANK_WIDTH + BANK_WIDTH
                                        --     + ROW_WIDTH + COL_WIDTH;
    MEM_ADDR_ORDER          : string  := "ROW_BANK_COLUMN";
    STARVE_LIMIT            : integer := 2;
                                        -- # = 2,3,4.
    TCQ                     : integer := 100;
    ECC                     : string := "OFF";
    DATA_WIDTH              : integer := 64;
                                        -- # = DQ_WIDTH + ECC_WIDTH, if ECC="ON";
                                        --   = DQ_WIDTH, if ECC="OFF".
    ECC_TEST                : string := "OFF";
    PAYLOAD_WIDTH           : integer := 64;
    -- UI_INTFC Parameters
    APP_DATA_WIDTH          : integer := 64*4;
                                        -- (PAYLOAD_WIDTH * 4)
    APP_MASK_WIDTH          : integer := 64/2;
                                        -- (APP_DATA_WIDTH / 8)
   INTERFACE  : string := "AXI4";
                                       -- Port Interface.
                                       -- # = UI - User Interface,
                                       --   = AXI4 - AXI4 Interface.
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
    pd_PSDONE                 : in   std_logic;
    phy_init_done             : out   std_logic;
    bank_mach_next            : out   std_logic_vector(BM_CNT_WIDTH-1 downto 0);
    app_ecc_multiple_err      : out   std_logic_vector(3 downto 0);
    dbg_wr_dqs_tap_set        : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
    dbg_wr_dq_tap_set         : in    std_logic_vector(5*DQS_WIDTH-1 downto 0);
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
end entity memc_ui_top;
architecture arch_memc_ui_top of memc_ui_top is
  attribute X_CORE_INFO : string;
  attribute X_CORE_INFO of arch_memc_ui_top : ARCHITECTURE IS
    "mig_v3_92_ddr3_V6, Coregen 14.7";

  attribute CORE_GENERATION_INFO : string;
  attribute CORE_GENERATION_INFO of arch_memc_ui_top : ARCHITECTURE IS "ddr3_V6,mig_v3_92,{LANGUAGE=VHDL, SYNTHESIS_TOOL=ISE, LEVEL=CONTROLLER, AXI_ENABLE=0, NO_OF_CONTROLLERS=1, INTERFACE_TYPE=DDR3, CLK_PERIOD=2500, MEMORY_TYPE=SODIMM, MEMORY_PART=mt4jsf6464hy-1g1, DQ_WIDTH=64, ECC=OFF, DATA_MASK=1, BURST_MODE=8, BURST_TYPE=SEQ, OUTPUT_DRV=HIGH, RTT_NOM=60, REFCLK_FREQ=200, MMCM_ADV_BANDWIDTH=OPTIMIZED, CLKFBOUT_MULT_F=6, CLKOUT_DIVIDE=3, DEBUG_PORT=OFF, IODELAY_HP_MODE=ON, INTERNAL_VREF=0, DCI_INOUTS=1, CLASS_ADDR=II, INPUT_CLK_TYPE=DIFFERENTIAL}";
  function XWIDTH return integer is
  begin
    if(CS_WIDTH = 1) then
      return 0;
    else
      return RANK_WIDTH;
    end if;
  end function;

  function ECCWIDTH return integer is
  begin
    if(ECC = "OFF") then
      return 0;
    else
      if(DATA_WIDTH <= 4) then
        return 4;
      elsif(DATA_WIDTH <= 10) then
        return 5;
      elsif(DATA_WIDTH <= 26) then
        return 6;
      elsif(DATA_WIDTH <= 57) then
        return 7;
      elsif(DATA_WIDTH <= 120) then
        return 8;
      elsif(DATA_WIDTH <= 247) then
        return 9;
      else
        return 10;
      end if;
    end if;
  end function;

  constant nPHY_WRLAT : integer := 0;
  constant MC_ERR_ADDR_WIDTH : integer := XWIDTH + BANK_WIDTH + ROW_WIDTH
                                          + COL_WIDTH + DATA_BUF_OFFSET_WIDTH;
  constant ECC_WIDTH : integer := ECCWIDTH;

--  constant PAYLOAD_WIDTH = (ECC_TEST == "OFF") ? DATA_WIDTH : DQ_WIDTH;

  constant DLC0_zeros : std_logic_vector(143 downto 47+1) := (others => '0');
  constant DLC1_zeros : std_logic_vector(143 downto 15+1) := (others => '0');
  constant DLC2_zeros : std_logic_vector(143 downto 0+1) := (others => '0');
  constant DLC3_zeros : std_logic_vector(143 downto 0+1) := (others => '0');

  constant DQS_LOC_COL0_i : std_logic_vector(143 downto 0) := (DLC0_zeros & DQS_LOC_COL0);
  constant DQS_LOC_COL1_i : std_logic_vector(143 downto 0) := (DLC1_zeros & DQS_LOC_COL1);
  constant DQS_LOC_COL2_i : std_logic_vector(143 downto 0) := (DLC2_zeros & DQS_LOC_COL2);
  constant DQS_LOC_COL3_i : std_logic_vector(143 downto 0) := (DLC3_zeros & DQS_LOC_COL3);

component axi_mc generic  (
  C_FAMILY : string := "virtex6";
  C_S_AXI_ID_WIDTH : integer := 4;
  C_S_AXI_ADDR_WIDTH : integer := 30; 
  C_S_AXI_DATA_WIDTH : integer := 32; 
  C_MC_ADDR_WIDTH    : integer := 30;
  C_MC_DATA_WIDTH    : integer := 32;
  C_MC_BURST_MODE    : string := "8";
  C_MC_nCK_PER_CLK     : integer := 2;
  C_S_AXI_SUPPORTS_NARROW_BURST : integer := 1;
  C_S_AXI_REG_EN0  : std_logic_vector(19 downto 0) := X"00000";
  C_S_AXI_REG_EN1  : std_logic_vector(19 downto 0) := X"00000";
  C_RD_WR_ARB_ALGORITHM : string := "RD_PRI_REG";
  C_ECC                 : string := "OFF"
); port 
(
  -- AXI Slave Interface
  -- Slave Interface System Signals           
  aclk     : in std_logic;
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
  -- MC Master Interface
  --CMD PORT
  mc_app_en   : out std_logic;
  mc_app_cmd  : out std_logic_vector(2 downto 0);
  mc_app_sz   : out std_logic;
  mc_app_addr : out std_logic_vector(C_MC_ADDR_WIDTH-1 downto 0);
  mc_app_hi_pri   : out std_logic;
  mc_app_rdy       : in std_logic;
  mc_init_complete : in std_logic;
  --DATA PORT
  mc_app_wdf_wren  : out std_logic;
  mc_app_wdf_mask  : out std_logic_vector(C_MC_DATA_WIDTH/8-1 downto 0);
  mc_app_wdf_data  : out std_logic_vector(C_MC_DATA_WIDTH-1 downto 0);
  mc_app_wdf_end   : out std_logic;
  mc_app_wdf_rdy : in std_logic;
                                              
  mc_app_rd_valid : in std_logic;
  mc_app_rd_data  : in std_logic_vector(C_MC_DATA_WIDTH-1 downto 0);
  mc_app_rd_end   : in std_logic;
  mc_app_ecc_multiple_err : in std_logic_vector(2*C_MC_nCK_PER_CLK-1 downto 0)
);
end component;

  component mem_intfc
    generic (
      TCQ                    : integer;
      PAYLOAD_WIDTH          : integer;
      ADDR_CMD_MODE          : string;
      AL                     : string;
      BANK_WIDTH             : integer;
      BM_CNT_WIDTH           : integer;
      BURST_MODE             : string;
      BURST_TYPE             : string;
      CK_WIDTH               : integer;
      CKE_WIDTH              : integer;
      CL                     : integer;
      COL_WIDTH              : integer;
      CS_WIDTH               : integer;
      CWL                    : integer;
      DATA_WIDTH             : integer;
      DATA_BUF_ADDR_WIDTH    : integer;
      DATA_BUF_OFFSET_WIDTH  : integer;
      DM_WIDTH               : integer;
      DQ_CNT_WIDTH           : integer;
      DQ_WIDTH               : integer;
      DQS_CNT_WIDTH          : integer;
      DQS_WIDTH              : integer;
      DRAM_TYPE              : string;
      DRAM_WIDTH             : integer;
      ECC                    : string;
      ECC_WIDTH              : integer;
      MC_ERR_ADDR_WIDTH      : integer;
      nAL                    : integer;
      nBANK_MACHS            : integer;
      nCK_PER_CLK            : integer;
      nCS_PER_RANK           : integer;
      ORDERING               : string;
      PHASE_DETECT           : string;
      IBUF_LPWR_MODE         : string;
      IODELAY_HP_MODE        : string;
      IODELAY_GRP            : string;
      OUTPUT_DRV             : string;
      REG_CTRL               : string;
      RTT_NOM                : string;
      RTT_WR                 : string;
      STARVE_LIMIT           : integer;
      tCK                    : integer;
      tFAW                   : integer;
      tPRDI                  : integer;
      tRAS                   : integer;
      tRCD                   : integer;
      tREFI                  : integer;
      tRFC                   : integer;
      tRP                    : integer;
      tRRD                   : integer;
      tRTP                   : integer;
      tWTR                   : integer;
      tZQI                   : integer;
      tZQCS                  : integer;
      WRLVL                  : string;
      DEBUG_PORT             : string;
      CAL_WIDTH              : string;
      RANK_WIDTH             : integer;
      RANKS                  : integer;
      ROW_WIDTH              : integer;
      SLOT_0_CONFIG          : std_logic_vector(7 downto 0);
      SLOT_1_CONFIG          : std_logic_vector(7 downto 0);
      SIM_BYPASS_INIT_CAL    : string;
      REFCLK_FREQ            : real;
      nDQS_COL0              : integer;
      nDQS_COL1              : integer;
      nDQS_COL2              : integer;
      nDQS_COL3              : integer;
      DQS_LOC_COL0           : std_logic_vector (143 downto 0);
      DQS_LOC_COL1           : std_logic_vector (143 downto 0);
      DQS_LOC_COL2           : std_logic_vector (143 downto 0);
      DQS_LOC_COL3           : std_logic_vector (143 downto 0);
      USE_DM_PORT            : integer
      );
    port (
      wr_data_offset              : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
      wr_data_en                  : out std_logic;
      wr_data_addr                : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      rd_data_offset              : out std_logic_vector(DATA_BUF_OFFSET_WIDTH - 1 downto 0);
      rd_data_en                  : out std_logic;
      rd_data_addr                : out std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      ddr_we_n                    : out std_logic;
      ddr_parity                  : out std_logic;
      ddr_reset_n                 : out std_logic;
      ddr_ras_n                   : out std_logic;
      ddr_odt                     : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      ddr_dm                      : out std_logic_vector(DM_WIDTH - 1 downto 0);
      ddr_cs_n                    : out std_logic_vector(CS_WIDTH * nCS_PER_RANK - 1 downto 0);
      ddr_cke                     : out std_logic_vector(CKE_WIDTH - 1 downto 0);
      ddr_ck                      : out std_logic_vector(CK_WIDTH - 1 downto 0);
      ddr_ck_n                    : out std_logic_vector(CK_WIDTH - 1 downto 0);
      ddr_cas_n                   : out std_logic;
      ddr_ba                      : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      ddr_addr                    : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      dbg_wr_dqs_tap_set          : in std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_wr_dq_tap_set           : in std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_wr_tap_set_en           : in std_logic;
      dbg_wrlvl_start             : out std_logic;
      dbg_wrlvl_done              : out std_logic;
      dbg_wrlvl_err               : out std_logic;
      bank_mach_next              : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      dbg_rd_active_dly           : out std_logic_vector( 4 downto 0);
      dbg_wl_dqs_inverted         : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      dbg_wr_calib_clk_delay      : out std_logic_vector(2 * DQS_WIDTH - 1 downto 0);
      dbg_wl_odelay_dqs_tap_cnt   : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_wl_odelay_dq_tap_cnt    : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_tap_cnt_during_wrlvl    : out std_logic_vector(4 downto 0);
      dbg_wl_edge_detect_valid    : out std_logic;
      dbg_rd_data_edge_detect     : out std_logic_vector(DQS_WIDTH - 1 downto 0);
      dbg_rdlvl_start             : out std_logic_vector(1 downto 0);
      dbg_rdlvl_done              : out std_logic_vector(1 downto 0);
      dbg_rdlvl_err               : out std_logic_vector(1 downto 0);
      dbg_cpt_first_edge_cnt      : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_cpt_second_edge_cnt     : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_rd_bitslip_cnt          : out std_logic_vector(3 * DQS_WIDTH - 1 downto 0);
      dbg_rd_clkdly_cnt           : out std_logic_vector(2 * DQS_WIDTH - 1 downto 0);
      dbg_rddata                  : out std_logic_vector(4 * DQ_WIDTH - 1 downto 0);
      dbg_idel_up_all             : in std_logic;
      dbg_idel_down_all           : in std_logic;
      dbg_idel_up_cpt             : in std_logic;
      dbg_idel_down_cpt           : in std_logic;
      dbg_idel_up_rsync           : in std_logic;
      dbg_idel_down_rsync         : in std_logic;
      dbg_sel_all_idel_cpt        : in std_logic;
      dbg_sel_all_idel_rsync      : in std_logic;
      dbg_sel_idel_cpt            : in std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_sel_idel_rsync          : in std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_cpt_tap_cnt             : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_rsync_tap_cnt           : out std_logic_vector(19 downto 0);
      dbg_dqs_tap_cnt             : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_dq_tap_cnt              : out std_logic_vector(5 * DQS_WIDTH - 1 downto 0);
      dbg_pd_off                  : in std_logic;
      dbg_pd_maintain_off         : in std_logic;
      dbg_pd_maintain_0_only      : in std_logic;
      dbg_pd_inc_cpt              : in std_logic;
      dbg_pd_dec_cpt              : in std_logic;
      dbg_pd_inc_dqs              : in std_logic;
      dbg_pd_dec_dqs              : in std_logic;
      dbg_pd_disab_hyst           : in std_logic;
      dbg_pd_disab_hyst_0         : in std_logic;
      dbg_pd_msb_sel              : in std_logic_vector(3 downto 0);
      dbg_pd_byte_sel             : in std_logic_vector(DQS_CNT_WIDTH-1 downto 0);
      dbg_inc_rd_fps              : in std_logic;
      dbg_dec_rd_fps              : in std_logic;
      dbg_phy_pd                  : out std_logic_vector(255 downto 0);
      dbg_phy_read                : out std_logic_vector(255 downto 0);
      dbg_phy_rdlvl               : out std_logic_vector(255 downto 0);
      dbg_phy_top                 : out std_logic_vector(255 downto 0);
      accept                      : out std_logic;
      accept_ns                   : out std_logic;
      rd_data                     : out std_logic_vector((4 * PAYLOAD_WIDTH) - 1 downto 0);
      pd_PSEN                     : out std_logic;
      pd_PSINCDEC                 : out std_logic;
      rd_data_end                 : out std_logic;
      dfi_init_complete           : out std_logic;
      ecc_single                  : out std_logic_vector(3 downto 0);
      ecc_multiple                : out std_logic_vector(3 downto 0);
      ecc_err_addr                : out std_logic_vector(MC_ERR_ADDR_WIDTH - 1 downto 0);
      ddr_dqs                     : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
      ddr_dqs_n                   : inout std_logic_vector(DQS_WIDTH - 1 downto 0);
      ddr_dq                      : inout std_logic_vector(DQ_WIDTH - 1 downto 0);
      use_addr                    : in std_logic;
      size                        : in std_logic;
      rst                         : in std_logic;
      row                         : in std_logic_vector(ROW_WIDTH - 1 downto 0);
      rank                        : in std_logic_vector(RANK_WIDTH - 1 downto 0);
      hi_priority                 : in std_logic;
      data_buf_addr               : in std_logic_vector(DATA_BUF_ADDR_WIDTH - 1 downto 0);
      col                         : in std_logic_vector(COL_WIDTH - 1 downto 0);
      cmd                         : in std_logic_vector(2 downto 0);
      clk_mem                     : in std_logic;
      clk                         : in std_logic;
      clk_rd_base                 : in std_logic;
      bank                        : in std_logic_vector(BANK_WIDTH - 1 downto 0);
      wr_data                     : in std_logic_vector((4 * PAYLOAD_WIDTH) - 1 downto 0);
      wr_data_mask                : in std_logic_vector((4 * (DATA_WIDTH / 8)) - 1 downto   0);
      pd_PSDONE                   : in std_logic;
      slot_0_present              : in std_logic_vector(7 downto 0);
      slot_1_present              : in std_logic_vector(7 downto 0);
      correct_en                  : in std_logic;
      raw_not_ecc                 : in std_logic_vector(3 downto 0)
      );
  end component mem_intfc;

  component ui_top
    generic (
      TCQ                   : integer;
      APP_DATA_WIDTH        : integer;
      APP_MASK_WIDTH        : integer;
      BANK_WIDTH            : integer;
      COL_WIDTH             : integer;
      CWL                   : integer;
      ECC                   : string;
      ECC_TEST              : string;
      ORDERING              : string;
      RANKS                 : integer;
      RANK_WIDTH            : integer;
      ROW_WIDTH             : integer;
      MEM_ADDR_ORDER        : string
      );
    port (
      wr_data_mask          : out std_logic_vector(APP_MASK_WIDTH - 1 downto 0);
      wr_data               : out std_logic_vector(APP_DATA_WIDTH - 1 downto 0);
      use_addr              : out std_logic;
      size                  : out std_logic;
      row                   : out std_logic_vector(ROW_WIDTH - 1 downto 0);
      raw_not_ecc           : out std_logic_vector(3 downto 0);
      rank                  : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      hi_priority           : out std_logic;
      data_buf_addr         : out std_logic_vector(3 downto 0);
      col                   : out std_logic_vector(COL_WIDTH - 1 downto 0);
      cmd                   : out std_logic_vector(2 downto 0);
      bank                  : out std_logic_vector(BANK_WIDTH - 1 downto 0);
      app_wdf_rdy           : out std_logic;
      app_rdy               : out std_logic;
      app_rd_data_valid     : out std_logic;
      app_rd_data_end       : out std_logic;
      app_rd_data           : out std_logic_vector(APP_DATA_WIDTH - 1 downto 0);
      app_ecc_multiple_err  : out std_logic_vector(3 downto 0);
      correct_en            : out std_logic;
      wr_data_offset        : in std_logic;
      wr_data_en            : in std_logic;
      wr_data_addr          : in std_logic_vector(3 downto 0);
      rst                   : in std_logic;
      rd_data_offset        : in std_logic;
      rd_data_end           : in std_logic;
      rd_data_en            : in std_logic;
      rd_data_addr          : in std_logic_vector(3 downto 0);
      rd_data               : in std_logic_vector(APP_DATA_WIDTH - 1 downto 0);
      ecc_multiple          : in std_logic_vector(3 downto 0);
      clk                   : in std_logic;
      app_wdf_wren          : in std_logic;
      app_wdf_mask          : in std_logic_vector(APP_MASK_WIDTH - 1 downto 0);
      app_wdf_end           : in std_logic;
      app_wdf_data          : in std_logic_vector(APP_DATA_WIDTH - 1 downto 0);
      app_sz                : in std_logic;
      app_raw_not_ecc       : in std_logic_vector(3 downto 0);
      app_hi_pri            : in std_logic;
      app_en                : in std_logic;
      app_cmd               : in std_logic_vector(2 downto 0);
      app_addr              : in std_logic_vector(RANK_WIDTH + BANK_WIDTH + ROW_WIDTH + COL_WIDTH - 1 downto 0);
      accept_ns             : in std_logic;
      accept                : in std_logic;
      app_correct_en        : in std_logic
      );
  end component ui_top;

  signal correct_en      : std_logic;
  signal raw_not_ecc     : std_logic_vector(3 downto 0);
  signal ecc_single      : std_logic_vector(3 downto 0);
  signal ecc_multiple    : std_logic_vector(3 downto 0);
  signal ecc_err_addr    : std_logic_vector(MC_ERR_ADDR_WIDTH-1 downto 0);
  signal app_raw_not_ecc : std_logic_vector(3 downto 0);

  signal wr_data_offset  : std_logic_vector(DATA_BUF_OFFSET_WIDTH-1 downto 0);
  signal wr_data_en      : std_logic;
  signal wr_data_addr    : std_logic_vector(DATA_BUF_ADDR_WIDTH-1 downto 0);
  signal rd_data_offset  : std_logic_vector(DATA_BUF_OFFSET_WIDTH-1 downto 0);
  signal rd_data_en      : std_logic;
  signal rd_data_addr    : std_logic_vector(DATA_BUF_ADDR_WIDTH-1 downto 0);
  signal accept          : std_logic;
  signal accept_ns       : std_logic;
  signal rd_data         : std_logic_vector((4*PAYLOAD_WIDTH)-1 downto 0);
  signal rd_data_end     : std_logic;
  signal use_addr        : std_logic;
  signal size            : std_logic;
  signal row             : std_logic_vector(ROW_WIDTH-1 downto 0);
  signal rank            : std_logic_vector(RANK_WIDTH-1 downto 0);
  signal hi_priority     : std_logic;
  signal data_buf_addr   : std_logic_vector(DATA_BUF_ADDR_WIDTH-1 downto 0);
  signal col             : std_logic_vector(COL_WIDTH-1 downto 0);
  signal cmd             : std_logic_vector(2 downto 0);
  signal bank            : std_logic_vector(BANK_WIDTH-1 downto 0);
  signal wr_data         : std_logic_vector((4*PAYLOAD_WIDTH)-1 downto 0);
  signal wr_data_mask    : std_logic_vector((4*(PAYLOAD_WIDTH/8))-1 downto 0);

  signal app_rd_data               : std_logic_vector(APP_DATA_WIDTH-1 downto 0);
  signal app_rd_data_end           : std_logic;
  signal app_rd_data_valid         : std_logic;
  signal app_rdy                   : std_logic;
  signal app_wdf_rdy               : std_logic;
  signal app_addr                  : std_logic_vector(ADDR_WIDTH-1 downto 0);
  signal app_cmd                   : std_logic_vector(2 downto 0);
  signal app_en                    : std_logic;
  signal app_hi_pri                : std_logic;
  signal app_sz                    : std_logic;
  signal app_wdf_data              : std_logic_vector(APP_DATA_WIDTH-1 downto 0);
  signal app_wdf_end               : std_logic;
  signal app_wdf_mask              : std_logic_vector(APP_MASK_WIDTH-1 downto 0);
  signal app_wdf_wren              : std_logic;
  signal app_correct_en            : std_logic;
  
  signal w_phy_init_done : std_logic;
  signal w_app_ecc_multiple_err : std_logic_vector(3 downto 0);

begin

  u_mem_intfc : mem_intfc
    generic map(
      TCQ                   => TCQ,
      ADDR_CMD_MODE         => ADDR_CMD_MODE,
      AL                    => AL,
      BANK_WIDTH            => BANK_WIDTH,
      BM_CNT_WIDTH          => BM_CNT_WIDTH,
      BURST_MODE            => BURST_MODE,
      BURST_TYPE            => BURST_TYPE,
      CK_WIDTH              => CK_WIDTH,
      CKE_WIDTH             => CKE_WIDTH,
      CL                    => CL,
      COL_WIDTH             => COL_WIDTH,
      CS_WIDTH              => CS_WIDTH,
      CWL                   => CWL,
      DATA_WIDTH            => DATA_WIDTH,
      DATA_BUF_ADDR_WIDTH   => DATA_BUF_ADDR_WIDTH,
      DATA_BUF_OFFSET_WIDTH => DATA_BUF_OFFSET_WIDTH,
      --DELAY_WR_DATA_CNTRL   => DELAY_WR_DATA_CNTRL,
      DM_WIDTH              => DM_WIDTH,
      DQ_CNT_WIDTH          => DQ_CNT_WIDTH,
      DQ_WIDTH              => DQ_WIDTH,
      DQS_CNT_WIDTH         => DQS_CNT_WIDTH,
      DQS_WIDTH             => DQS_WIDTH,
      DRAM_TYPE             => DRAM_TYPE,
      DRAM_WIDTH            => DRAM_WIDTH,
      ECC                   => ECC,
      PAYLOAD_WIDTH         => PAYLOAD_WIDTH,
      ECC_WIDTH             => ECC_WIDTH,
      MC_ERR_ADDR_WIDTH     => MC_ERR_ADDR_WIDTH,
      nAL                   => nAL,
      nBANK_MACHS           => nBANK_MACHS,
      nCK_PER_CLK           => nCK_PER_CLK,
      nCS_PER_RANK          => nCS_PER_RANK,
      ORDERING              => ORDERING,
      PHASE_DETECT          => PHASE_DETECT,
      IBUF_LPWR_MODE        => IBUF_LPWR_MODE,
      IODELAY_HP_MODE       => IODELAY_HP_MODE,
      IODELAY_GRP           => IODELAY_GRP,
      OUTPUT_DRV            => OUTPUT_DRV,
      REG_CTRL              => REG_CTRL,
      RTT_NOM               => RTT_NOM,
      RTT_WR                => RTT_WR,
      STARVE_LIMIT          => STARVE_LIMIT,
      tCK                   => tCK,
      tFAW                  => tFAW,
      tPRDI                 => tPRDI,
      tRAS                  => tRAS,
      tRCD                  => tRCD,
      tREFI                 => tREFI,
      tRFC                  => tRFC,
      tRP                   => tRP,
      tRRD                  => tRRD,
      tRTP                  => tRTP,
      tWTR                  => tWTR,
      tZQI                  => tZQI,
      tZQCS                 => tZQCS,
      WRLVL                 => WRLVL,
      DEBUG_PORT            => DEBUG_PORT,
      CAL_WIDTH             => CAL_WIDTH,
      RANK_WIDTH            => RANK_WIDTH,
      RANKS                 => RANKS,
      ROW_WIDTH             => ROW_WIDTH,
      SLOT_0_CONFIG         => SLOT_0_CONFIG,
      SLOT_1_CONFIG         => SLOT_1_CONFIG,
      SIM_BYPASS_INIT_CAL   => SIM_BYPASS_INIT_CAL,
      REFCLK_FREQ           => REFCLK_FREQ,
      nDQS_COL0             => nDQS_COL0,
      nDQS_COL1             => nDQS_COL1,
      nDQS_COL2             => nDQS_COL2,
      nDQS_COL3             => nDQS_COL3,
      DQS_LOC_COL0          => DQS_LOC_COL0_i,
      DQS_LOC_COL1          => DQS_LOC_COL1_i,
      DQS_LOC_COL2          => DQS_LOC_COL2_i,
      DQS_LOC_COL3          => DQS_LOC_COL3_i,
      USE_DM_PORT           => USE_DM_PORT
      )
    port map(
      wr_data_offset            => wr_data_offset,
      wr_data_en                => wr_data_en,
      wr_data_addr              => wr_data_addr,
      rd_data_offset            => rd_data_offset,
      rd_data_en                => rd_data_en,
      rd_data_addr              => rd_data_addr,
      ddr_we_n                  => ddr_we_n,
      ddr_parity                => ddr_parity,
      ddr_reset_n               => ddr_reset_n,
      ddr_ras_n                 => ddr_ras_n,
      ddr_odt                   => ddr_odt,
      ddr_dm                    => ddr_dm,
      ddr_cs_n                  => ddr_cs_n,
      ddr_cke                   => ddr_cke,
      ddr_ck                    => ddr_ck,
      ddr_ck_n                  => ddr_ck_n,
      ddr_cas_n                 => ddr_cas_n,
      ddr_ba                    => ddr_ba,
      ddr_addr                  => ddr_addr,
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
      dbg_tap_cnt_during_wrlvl  => open,
      dbg_wl_edge_detect_valid  => open,
      dbg_rd_data_edge_detect   => open,
      dbg_rdlvl_start           => dbg_rdlvl_start,
      dbg_rdlvl_done            => dbg_rdlvl_done,
      dbg_rdlvl_err             => dbg_rdlvl_err,
      dbg_cpt_first_edge_cnt    => dbg_cpt_first_edge_cnt,
      dbg_cpt_second_edge_cnt   => dbg_cpt_second_edge_cnt,
      dbg_rd_bitslip_cnt        => dbg_rd_bitslip_cnt,
      dbg_rd_clkdly_cnt         => dbg_rd_clkdly_cnt,
      dbg_rd_active_dly         => dbg_rd_active_dly,
      dbg_rddata                => dbg_rddata,
      -- Currently CPT clock IODELAY taps must be moved on per-DQS group
      -- basis-only - i.e. all CPT clocks cannot be moved simultaneously
      -- If desired to change this, rewire dbg_idel_*_all, and
      -- dbg_sel_idel_*_* accordingly. Also no support for changing DQS
      -- and CPT taps via phase detector. Note: can change CPT taps via
      -- dbg_idel_*_cpt, but PD must off when this happens
      dbg_idel_up_all           => '0',
      dbg_idel_down_all         => '0',
      dbg_idel_up_cpt           => dbg_inc_cpt,
      dbg_idel_down_cpt         => dbg_dec_cpt,
      dbg_idel_up_rsync         => '0',
      dbg_idel_down_rsync       => '0',
      dbg_sel_idel_cpt          => dbg_inc_dec_sel,
      dbg_sel_all_idel_cpt      => '0',
      dbg_sel_idel_rsync        => (others => '0'),
      dbg_sel_all_idel_rsync    => '0',
      dbg_cpt_tap_cnt           => dbg_cpt_tap_cnt,
      dbg_rsync_tap_cnt         => open,
      dbg_dqs_tap_cnt           => dbg_dqs_tap_cnt,
      dbg_dq_tap_cnt            => dbg_dq_tap_cnt,
      dbg_pd_off                => dbg_pd_off,
      dbg_pd_maintain_off       => dbg_pd_maintain_off,
      dbg_pd_maintain_0_only    => dbg_pd_maintain_0_only,
      dbg_pd_inc_cpt            => '0',
      dbg_pd_dec_cpt            => '0',
      dbg_pd_inc_dqs            => dbg_inc_rd_dqs,
      dbg_pd_dec_dqs            => dbg_dec_rd_dqs,
      dbg_pd_disab_hyst         => '0',
      dbg_pd_disab_hyst_0       => '0',
      dbg_pd_msb_sel            => (others => '0'),
      dbg_pd_byte_sel           => dbg_inc_dec_sel,
      dbg_inc_rd_fps            => dbg_inc_rd_fps,
      dbg_dec_rd_fps            => dbg_dec_rd_fps,
      dbg_phy_pd                => open,
      dbg_phy_read              => open,
      dbg_phy_rdlvl             => open,
      dbg_phy_top               => open,
      bank_mach_next            => bank_mach_next,
      accept                    => accept,
      accept_ns                 => accept_ns,
      rd_data                   => rd_data((PAYLOAD_WIDTH*4)-1 downto 0),
      rd_data_end               => rd_data_end,
      pd_PSEN                   => pd_PSEN,
      dfi_init_complete         => w_phy_init_done,
      pd_PSINCDEC               => pd_PSINCDEC,
      ecc_single                => ecc_single,
      ecc_multiple              => ecc_multiple,
      ecc_err_addr              => ecc_err_addr,
      ddr_dqs                   => ddr_dqs,
      ddr_dqs_n                 => ddr_dqs_n,
      ddr_dq                    => ddr_dq,
      use_addr                  => use_addr,
      size                      => size,
      rst                       => rst,
      row                       => row,
      rank                      => rank,
      hi_priority               => '0',
      data_buf_addr             => data_buf_addr,
      col                       => col,
      cmd                       => cmd,
      clk_mem                   => clk_mem,
      clk                       => clk,
      clk_rd_base               => clk_rd_base,
      bank                      => bank,
      wr_data                   => wr_data,
      wr_data_mask              => wr_data_mask(4 * DATA_WIDTH / 8 - 1 downto 0),
      pd_PSDONE                 => pd_PSDONE,
      slot_0_present            => SLOT_0_CONFIG,
      slot_1_present            => SLOT_1_CONFIG,
      correct_en                => correct_en,
      raw_not_ecc               => raw_not_ecc
      );
		
  phy_init_done <= w_phy_init_done;

  u_ui_top : ui_top
    generic map(
      TCQ            => TCQ,
      APP_DATA_WIDTH => APP_DATA_WIDTH,
      APP_MASK_WIDTH => APP_MASK_WIDTH,
      BANK_WIDTH     => BANK_WIDTH,
      COL_WIDTH      => COL_WIDTH,
      CWL            => CWL,
      ECC            => ECC,
      ECC_TEST       => ECC_TEST,
      ORDERING       => ORDERING,
      RANKS          => RANKS,
      RANK_WIDTH     => RANK_WIDTH,
      ROW_WIDTH      => ROW_WIDTH,
      MEM_ADDR_ORDER => MEM_ADDR_ORDER
      )
    port map(
      wr_data_mask         => wr_data_mask,
      wr_data              => wr_data(APP_DATA_WIDTH-1 downto 0),
      use_addr             => use_addr,
      size                 => size,
      row                  => row(ROW_WIDTH-1 downto 0),
      rank                 => rank(RANK_WIDTH-1 downto 0),
      hi_priority          => hi_priority,
      data_buf_addr        => data_buf_addr(3 downto 0),
      col                  => col,
      cmd                  => cmd,
      bank                 => bank,
      app_wdf_rdy          => app_wdf_rdy,
      app_rdy              => app_rdy,
      app_rd_data_valid    => app_rd_data_valid,
      app_rd_data_end      => app_rd_data_end,
      app_rd_data          => app_rd_data,
      wr_data_offset       => std_logic(wr_data_offset(DATA_BUF_OFFSET_WIDTH-1)),
      wr_data_en           => wr_data_en,
      wr_data_addr         => wr_data_addr(3 downto 0),
      rst                  => rst,
      rd_data_offset       => std_logic(rd_data_offset(DATA_BUF_OFFSET_WIDTH-1)),
      rd_data_end          => rd_data_end,
      rd_data_en           => rd_data_en,
      rd_data_addr         => rd_data_addr(3 downto 0),
      rd_data              => rd_data(APP_DATA_WIDTH-1 downto 0),
      clk                  => clk,
      raw_not_ecc          => raw_not_ecc,
      app_ecc_multiple_err => w_app_ecc_multiple_err,
      correct_en           => correct_en,
      ecc_multiple         => ecc_multiple,
      app_raw_not_ecc      => app_raw_not_ecc,
      app_correct_en       => app_correct_en,
      app_wdf_wren         => app_wdf_wren,
      app_wdf_mask         => app_wdf_mask,
      app_wdf_end          => app_wdf_end,
      app_wdf_data         => app_wdf_data,
      app_sz               => app_sz,
      app_hi_pri           => app_hi_pri,
      app_en               => app_en,
      app_cmd              => app_cmd,
      app_addr             => app_addr,
      accept_ns            => accept_ns,
      accept               => accept
      );
		
	app_ecc_multiple_err <= w_app_ecc_multiple_err;


  u_axi_mc : axi_mc 
    generic map (
     C_FAMILY                => "virtex6"                ,
     C_S_AXI_ID_WIDTH        => C_S_AXI_ID_WIDTH        ,
     C_S_AXI_ADDR_WIDTH      => C_S_AXI_ADDR_WIDTH      ,
     C_S_AXI_DATA_WIDTH      => C_S_AXI_DATA_WIDTH      ,
     C_MC_ADDR_WIDTH         => ADDR_WIDTH              ,
     C_MC_DATA_WIDTH         => APP_DATA_WIDTH          ,
     C_MC_BURST_MODE         => BURST_MODE              ,
     C_MC_nCK_PER_CLK        => nCK_PER_CLK             ,
     C_S_AXI_SUPPORTS_NARROW_BURST => C_S_AXI_SUPPORTS_NARROW_BURST,
     C_S_AXI_REG_EN0         => C_S_AXI_REG_EN0         ,
     C_S_AXI_REG_EN1         => C_S_AXI_REG_EN1         ,
     C_RD_WR_ARB_ALGORITHM   => C_RD_WR_ARB_ALGORITHM  ,
     C_ECC                   => ECC                     
    ) port map (
       aclk                                   => clk             ,
       aresetn                                => aresetn         ,
       -- Slave Interface Write Address Ports
       s_axi_awid                             => s_axi_awid      ,
       s_axi_awaddr                           => s_axi_awaddr    ,
       s_axi_awlen                            => s_axi_awlen     ,
       s_axi_awsize                           => s_axi_awsize    ,
       s_axi_awburst                          => s_axi_awburst   ,
       s_axi_awlock                           => s_axi_awlock    ,
       s_axi_awcache                          => s_axi_awcache   ,
       s_axi_awprot                           => s_axi_awprot    ,
       s_axi_awqos                            => s_axi_awqos     ,
       s_axi_awvalid                          => s_axi_awvalid   ,
       s_axi_awready                          => s_axi_awready   ,
       -- Slave Interface Write Data Ports
       s_axi_wdata                            => s_axi_wdata     ,
       s_axi_wstrb                            => s_axi_wstrb     ,
       s_axi_wlast                            => s_axi_wlast     ,
       s_axi_wvalid                           => s_axi_wvalid    ,
       s_axi_wready                           => s_axi_wready    ,
       -- Slave Interface Write Response Ports
       s_axi_bid                              => s_axi_bid       ,
       s_axi_bresp                            => s_axi_bresp     ,
       s_axi_bvalid                           => s_axi_bvalid    ,
       s_axi_bready                           => s_axi_bready    ,
       -- Slave Interface Read Address Ports
       s_axi_arid                             => s_axi_arid      ,
       s_axi_araddr                           => s_axi_araddr    ,
       s_axi_arlen                            => s_axi_arlen     ,
       s_axi_arsize                           => s_axi_arsize    ,
       s_axi_arburst                          => s_axi_arburst   ,
       s_axi_arlock                           => s_axi_arlock    ,
       s_axi_arcache                          => s_axi_arcache   ,
       s_axi_arprot                           => s_axi_arprot    ,
       s_axi_arqos                            => s_axi_arqos     ,
       s_axi_arvalid                          => s_axi_arvalid   ,
       s_axi_arready                          => s_axi_arready   ,
       -- Slave Interface Read Data Ports
       s_axi_rid                              => s_axi_rid       ,
       s_axi_rdata                            => s_axi_rdata     ,
       s_axi_rresp                            => s_axi_rresp     ,
       s_axi_rlast                            => s_axi_rlast     ,
       s_axi_rvalid                           => s_axi_rvalid    ,
       s_axi_rready                           => s_axi_rready    ,
       -- MC Master Interface
       --CMD PORT
       mc_app_en                              => app_en          ,
       mc_app_cmd                             => app_cmd         ,
       mc_app_sz                              => app_sz          ,
       mc_app_addr                            => app_addr        ,
       mc_app_hi_pri                          => app_hi_pri      ,
       mc_app_rdy                             => app_rdy         ,
       mc_init_complete                       => w_phy_init_done,
       --DATA PORT
       mc_app_wdf_wren                        => app_wdf_wren    ,
       mc_app_wdf_mask                        => app_wdf_mask    ,
       mc_app_wdf_data                        => app_wdf_data    ,
       mc_app_wdf_end                         => app_wdf_end     ,
       mc_app_wdf_rdy                         => app_wdf_rdy     ,

       mc_app_rd_valid                        => app_rd_data_valid ,
       mc_app_rd_data                         => app_rd_data     ,
       mc_app_rd_end                          => app_rd_data_end ,
       mc_app_ecc_multiple_err                => w_app_ecc_multiple_err
       );

  gen_no_axi_ctrl_top : if ECC = "OFF" generate
     --s_axi_ctrl_awready <= '0';
     --s_axi_ctrl_wready  <= '0';
     --s_axi_ctrl_bvalid  <= '0';
     --s_axi_ctrl_bresp   <= "00";
     --s_axi_ctrl_arready <= '0';
     --s_axi_ctrl_rvalid  <= '0';
     --s_axi_ctrl_rdata   <= (others => '0');
     --s_axi_ctrl_rresp   <= "00";
     interrupt          <= '0';
     app_correct_en     <= '1';
     app_raw_not_ecc    <= (others => '0');
     --fi_xor_we          <= (others => '0');
     --fi_xor_wrdata      <= (others => '0');
  end generate;


end arch_memc_ui_top;

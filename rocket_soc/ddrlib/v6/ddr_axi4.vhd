-----------------------------------------------------------------------------
--! @file
--! @copyright Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author    Sergey Khabarov - sergeykhbr@gmail.com
--! @brief     Implementation of nasti_dsu (Debug Support Unit).
--! @details   DDR controller (MIG) for ML605 board.
-----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library commonlib;
use commonlib.types_common.all;
--! AMBA system bus specific library.
library ambalib;
--! AXI4 configuration constants.
use ambalib.types_amba4.all;
library rocketlib;
use rocketlib.types_ddr.all;

entity ddr_axi4 is
  generic (
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#
  );
  port 
  (
    rstn        : in std_logic;
    clk200      : in std_logic; -- 200 MHz
    clk         : in std_logic; -- 60 MHz
    clk2x       : in std_logic; -- 120 MHz
    clk2x_unbuf : in std_logic; -- 120 MHz
    o_cfg  : out nasti_slave_config_type;
    i_axi  : in nasti_slave_in_type;
    o_axi  : out nasti_slave_out_type;
    io_ddr3 : inout ddr3_io_type;
    o_ddr3  : out ddr3_out_type
  );
end;

architecture arch_ddr_axi4 of ddr_axi4 is

  constant xconfig : nasti_slave_config_type := (
     xindex => xindex,
     xaddr => conv_std_logic_vector(xaddr, CFG_NASTI_CFG_ADDR_BITS),
     xmask => conv_std_logic_vector(xmask, CFG_NASTI_CFG_ADDR_BITS),
     vid => VENDOR_XILINX,
     did => XILINX_DDR,
     descrtype => PNP_CFG_TYPE_SLAVE,
     descrsize => PNP_CFG_SLAVE_DESCR_BYTES
  );


  component mig_ml605 is
  generic(
     REFCLK_FREQ           : real := 200.0;
     IODELAY_GRP           : string := "IODELAY_MIG";
     MMCM_ADV_BANDWIDTH    : string  := "OPTIMIZED";
     CLKFBOUT_MULT_F       : integer := 6;
     DIVCLK_DIVIDE         : integer := 2;
     CLKOUT_DIVIDE         : integer := 3;
     nCK_PER_CLK           : integer := 2;
     tCK                   : integer := 2500;
     DEBUG_PORT            : string := "OFF";
     SIM_BYPASS_INIT_CAL   : string := "OFF"; --"FAST"
     nCS_PER_RANK          : integer := 1;
     DQS_CNT_WIDTH         : integer := 3;
     RANK_WIDTH            : integer := 1;
     BANK_WIDTH            : integer := 3;
     CK_WIDTH              : integer := 1;
     CKE_WIDTH             : integer := 1;
     COL_WIDTH             : integer := 10;
     CS_WIDTH              : integer := 1;
     DM_WIDTH              : integer := 8;
     DQ_WIDTH              : integer := 64;
     DQS_WIDTH             : integer := 8;
     ROW_WIDTH             : integer := 13;
     BURST_MODE            : string := "8";
     BM_CNT_WIDTH          : integer := 2;
     ADDR_CMD_MODE         : string := "1T" ;
     ORDERING              : string := "STRICT";
     WRLVL                 : string := "ON";
     PHASE_DETECT          : string := "ON";
     RTT_NOM               : string := "60";
     RTT_WR                : string := "OFF";
     OUTPUT_DRV            : string := "HIGH";
     REG_CTRL              : string := "OFF";
     nDQS_COL0             : integer := 6;
     nDQS_COL1             : integer := 2;
     nDQS_COL2             : integer := 0;
     nDQS_COL3             : integer := 0;
     DQS_LOC_COL0          : std_logic_vector(47 downto 0) := X"050403020100";
     DQS_LOC_COL1          : std_logic_vector(15 downto 0) := X"0706";
     DQS_LOC_COL2          : std_logic_vector(0 downto 0) := "0";
     DQS_LOC_COL3          : std_logic_vector(0 downto 0) := "0";
     tPRDI                 : integer := 1000000;
     tREFI                 : integer := 7800000;
     tZQI                  : integer := 128000000;
     ADDR_WIDTH            : integer := 27;
     ECC                   : string := "OFF";
     ECC_TEST              : string := "OFF";
     TCQ                   : integer := 100;
     DATA_WIDTH            : integer := 64;
     PAYLOAD_WIDTH         : integer := 64;
     C_S_AXI_ID_WIDTH          : integer := 5;
     C_S_AXI_ADDR_WIDTH        : integer := 32;
     C_S_AXI_DATA_WIDTH        : integer := 128;
     C_S_AXI_SUPPORTS_NARROW_BURST  : integer := 1;
     C_RD_WR_ARB_ALGORITHM    : string := "RD_PRI_REG";
     C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
     C_S_AXI_CTRL_DATA_WIDTH : integer := 32;
     C_S_AXI_BASEADDR        : std_logic_vector(31 downto 0) := X"40000000";
     C_ECC_ONOFF_RESET_VALUE : integer := 1;
     C_ECC_CE_COUNTER_WIDTH  : integer := 8
    );
  port(
      clk200     : in    std_logic;
      clk     : in    std_logic;
      clk2x     : in    std_logic;
      clk2x_unbuf     : in    std_logic;
      ddr3_dq       : inout std_logic_vector(DQ_WIDTH-1 downto 0);
      ddr3_addr     : out   std_logic_vector(ROW_WIDTH-1 downto 0);
      ddr3_ba       : out   std_logic_vector(BANK_WIDTH-1 downto 0);
      ddr3_ras_n    : out   std_logic;
      ddr3_cas_n    : out   std_logic;
      ddr3_we_n     : out   std_logic;
      ddr3_reset_n  : out   std_logic;
      ddr3_cs_n     : out   std_logic_vector((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
      ddr3_odt      : out   std_logic_vector((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
      ddr3_cke      : out   std_logic_vector(CKE_WIDTH-1 downto 0);
      ddr3_dm       : out   std_logic_vector(DM_WIDTH-1 downto 0);
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
  end component;


begin

  o_cfg  <= xconfig;


  mig0 : mig_ml605 port map (
    clk200 => clk200,
    clk => clk,
    clk2x => clk2x,
    clk2x_unbuf => clk2x_unbuf,
    ddr3_dq => io_ddr3.dq,
    ddr3_addr => o_ddr3.addr,
    ddr3_ba => o_ddr3.ba,
    ddr3_ras_n => o_ddr3.ras_n,
    ddr3_cas_n => o_ddr3.cas_n,
    ddr3_we_n => o_ddr3.we_n,
    ddr3_reset_n => o_ddr3.reset_n,
    ddr3_cs_n => o_ddr3.cs_n,
    ddr3_odt => o_ddr3.odt,
    ddr3_cke => o_ddr3.cke,
    ddr3_dm => o_ddr3.dm,
    ddr3_dqs_p => io_ddr3.dqs_p,
    ddr3_dqs_n => io_ddr3.dqs_n,
    ddr3_ck_p => o_ddr3.ck_p,
    ddr3_ck_n => o_ddr3.ck_n,
    s_axi_awid => i_axi.aw_id,
    s_axi_awaddr => i_axi.aw_bits.addr,
    s_axi_awlen => i_axi.aw_bits.len,
    s_axi_awsize => i_axi.aw_bits.size,
    s_axi_awburst => i_axi.aw_bits.burst,
    s_axi_awlock => i_axi.aw_bits.lock,
    s_axi_awcache => i_axi.aw_bits.cache,
    s_axi_awprot => i_axi.aw_bits.prot,
    s_axi_awqos => i_axi.aw_bits.qos,
    s_axi_awvalid => i_axi.aw_valid,
    s_axi_awready => o_axi.aw_ready,
    -- Slave Interface Write Data Ports
    s_axi_wdata => i_axi.w_data,
    s_axi_wstrb => i_axi.w_strb,
    s_axi_wlast => i_axi.w_last,
    s_axi_wvalid => i_axi.w_valid,
    s_axi_wready => o_axi.w_ready,
    -- Slave Interface Write Response Ports
    s_axi_bid => o_axi.b_id,
    s_axi_bresp => o_axi.b_resp,
    s_axi_bvalid => o_axi.b_valid,
    s_axi_bready => i_axi.b_ready,
    -- Slave Interface Read Address Ports
    s_axi_arid => i_axi.ar_id,
    s_axi_araddr => i_axi.ar_bits.addr,
    s_axi_arlen => i_axi.ar_bits.len,
    s_axi_arsize => i_axi.ar_bits.size,
    s_axi_arburst => i_axi.ar_bits.burst,
    s_axi_arlock => i_axi.ar_bits.lock,
    s_axi_arcache => i_axi.ar_bits.cache,
    s_axi_arprot => i_axi.ar_bits.prot,
    s_axi_arqos => i_axi.ar_bits.qos,
    s_axi_arvalid => i_axi.ar_valid,
    s_axi_arready => o_axi.ar_ready,
    -- Slave Interface Read Data Ports
    s_axi_rid => o_axi.r_id,
    s_axi_rdata => o_axi.r_data,
    s_axi_rresp => o_axi.r_resp,
    s_axi_rlast => o_axi.r_last,
    s_axi_rvalid => o_axi.r_valid,
    s_axi_rready => i_axi.r_ready,
    -- Interrupt output
    interrupt => open,
    phy_init_done => o_ddr3.phy_init_done,
    rstn => rstn
   );

end;

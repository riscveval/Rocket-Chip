-----------------------------------------------------------------------------
--! @file
--! @copyright Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author    Sergey Khabarov - sergeykhbr@gmail.com
--! @brief     DDR (MIG) interface types.
-----------------------------------------------------------------------------

--! Standard library.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library commonlib;
use commonlib.types_common.all;
--! Technology definition library.
library techmap;
use techmap.gencomp.all;
--! CPU, System Bus and common peripheries library.
library ambalib;
use ambalib.types_amba4.all;

--! @brief   Declaration of components visible on SoC top level.
package types_ddr is

  constant CFG_DDR_CS_WIDTH : integer := 1;
  constant CFG_DDR_nCS_PER_RANK : integer := 1;
  constant CFG_DDR_CKE_WIDTH : integer := 1;
  constant CFG_DDR_DM_WIDTH : integer := 8;
  constant CFG_DDR_CK_WIDTH : integer := 1;

  -- DDR model configuraiton parameters:
  constant CFG_DDR_DQ_WIDTH : integer := 64;
  constant CFG_DDR_ROW_WIDTH : integer := 13;
  constant CFG_DDR_BANK_WIDTH : integer := 3;
  constant CFG_DDR_DQS_WIDTH : integer := 8;
  constant CFG_DDR_DM_BITS : integer := 2;


  component mig_ml605 
  generic (
   REFCLK_FREQ             : real := 200.0;
                                       -- # = 200 for all design frequencies of
                                       --         -1 speed grade devices
                                       --   = 200 when design frequency < 480 MHz
                                       --         for -2 and -3 speed grade devices.
                                       --   = 300 when design frequency >= 480 MHz
                                       --         for -2 and -3 speed grade devices.
   IODELAY_GRP             : string := "IODELAY_MIG";
                                       -- It is associated to a set of IODELAYs with
                                       -- an IDELAYCTRL that have same IODELAY CONTROLLER
                                       -- clock frequency.
   MMCM_ADV_BANDWIDTH      : string := "OPTIMIZED";
                                       -- MMCM programming algorithm
   CLKFBOUT_MULT_F         : integer := 6;
                                       -- write PLL VCO multiplier.
   DIVCLK_DIVIDE           : integer := 1;--2; 
                                       -- write PLL VCO divisor.
   CLKOUT_DIVIDE           : integer := 3;
                                       -- VCO output divisor for fast (memory) clocks.
   nCK_PER_CLK             : integer := 2;
                                       -- # of memory CKs per fabric clock.
                                       -- # = 2, 1.
   tCK                     : integer := 2500;
                                       -- memory tCK paramter.
                                       -- # = Clock Period.
   DEBUG_PORT              : string := "OFF";
                                       -- # = "ON" Enable debug signals/controls.
                                       --   = "OFF" Disable debug signals/controls.
   SIM_BYPASS_INIT_CAL     : string := "OFF";
                                       -- # = "OFF" -  Complete memory init &
                                       --              calibration sequence
                                       -- # = "SKIP" - Skip memory init &
                                       --              calibration sequence
                                       -- # = "FAST" - Skip memory init & use
                                       --              abbreviated calib sequence
   nCS_PER_RANK            : integer := 1;
                                       -- # of unique CS outputs per Rank for
                                       -- phy.
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
   DQ_WIDTH                : integer := 64;
                                       -- # of Data (DQ) bits.
   DQS_WIDTH               : integer := 8;
                                       -- # of DQS/DQS# bits.
   ROW_WIDTH               : integer := 13;
                                       -- # of memory Row Address bits.
   BURST_MODE              : string := "8";
                                       -- Burst Length (Mode Register 0).
                                       -- # = "8", "4", "OTF".
   BM_CNT_WIDTH            : integer := 2;
                                       -- # = ceil(log2(nBANK_MACHS)).
   ADDR_CMD_MODE           : string := "1T" ;
                                       -- # = "2T", "1T".
   ORDERING                : string := "STRICT";
                                       -- # = "NORM", "STRICT".
   WRLVL                   : string := "ON";
                                       -- # = "ON" - DDR3 SDRAM
                                       --   = "OFF" - DDR2 SDRAM.
   PHASE_DETECT            : string := "ON";
                                       -- # = "ON", "OFF".
   RTT_NOM                 : string := "60";
                                       -- RTT_NOM (ODT) (Mode Register 1).
                                       -- # = "DISABLED" - RTT_NOM disabled,
                                       --   = "120" - RZQ/2,
                                       --   = "60"  - RZQ/4,
                                       --   = "40"  - RZQ/6.
   RTT_WR                  : string := "OFF";
                                       -- RTT_WR (ODT) (Mode Register 2).
                                       -- # = "OFF" - Dynamic ODT off,
                                       --   = "120" - RZQ/2,
                                       --   = "60"  - RZQ/4,
   OUTPUT_DRV              : string := "HIGH";
                                       -- Output Driver Impedance Control (Mode Register 1).
                                       -- # = "HIGH" - RZQ/7,
                                       --   = "LOW" - RZQ/6.
   REG_CTRL                : string := "OFF";
                                       -- # = "ON" - RDIMMs,
                                       --   = "OFF" - Components, SODIMMs, UDIMMs.
   nDQS_COL0               : integer := 3;--6;!!!!!!!!!!!! mig_38
                                       -- Number of DQS groups in I/O column #1.
   nDQS_COL1               : integer := 5;--2;!!!!!!!!!!!! mig_38
                                       -- Number of DQS groups in I/O column #2.
   nDQS_COL2               : integer := 0;
                                       -- Number of DQS groups in I/O column #3.
   nDQS_COL3               : integer := 0;
                                       -- Number of DQS groups in I/O column #4.
   --DQS_LOC_COL0            : std_logic_vector(47 downto 0) := X"050403020100";--!!!!!!!!!!!! mig_38
   DQS_LOC_COL0            : std_logic_vector(23 downto 0) := X"020100";--!!!!!!!!!!!! mig_38
                                       -- DQS groups in column #1.
   --DQS_LOC_COL1            : std_logic_vector(15 downto 0) := X"0706";--!!!!!!!!!!!! mig_38
   DQS_LOC_COL1            : std_logic_vector(39 downto 0) := X"0706050403";--!!!!!!!!!!!! mig_38
                                       -- DQS groups in column #2.
   DQS_LOC_COL2            : integer := 0;
                                       -- DQS groups in column #3.
   DQS_LOC_COL3            : integer := 0;
                                       -- DQS groups in column #4.
   tPRDI                   : integer := 1000000;
                                       -- memory tPRDI paramter.
   tREFI                   : integer := 7800000;
                                       -- memory tREFI paramter.
   tZQI                    : integer := 128000000;
                                       -- memory tZQI paramter.
   ADDR_WIDTH              : integer := 27;
                                       -- # = RANK_WIDTH + BANK_WIDTH
                                       --     + ROW_WIDTH + COL_WIDTH;
   ECC                     : string := "OFF";
   ECC_TEST                : string := "OFF";
   TCQ                     : integer := 100;
   DATA_WIDTH              : integer := 64;
   -- If parameters overrinding is used for simulation, PAYLOAD_WIDTH parameter
   -- should to be overidden along with the vsim command
   PAYLOAD_WIDTH           : integer := 64;
   INTERFACE               : string := "AXI4";
                                       -- Port Interface.
                                       -- # = UI - User Interface,
                                       --   = AXI4 - AXI4 Interface.
   C_S_AXI_ID_WIDTH          : integer := 5;
                                       -- Width of all master and slave ID signals.
                                       -- # = >= 1.
   C_S_AXI_ADDR_WIDTH        : integer := 32;
                                       -- Width of S_AXI_AWADDR, S_AXI_ARADDR, M_AXI_AWADDR and
                                       -- M_AXI_ARADDR for all SI/MI slots.
                                       -- # = 32.
   C_S_AXI_DATA_WIDTH        : integer := 128;
                                       -- Width of WDATA and RDATA on SI slot.
                                       -- Must be less or equal to APP_DATA_WIDTH.
                                       -- # = 32, 64, 128, 256.
   C_S_AXI_SUPPORTS_NARROW_BURST  : integer := 1;
                                       -- Indicates whether to instatiate upsizer
                                       -- Range: 0, 1
   C_RD_WR_ARB_ALGORITHM    : string := "RD_PRI_REG";
                                       -- Indicates the Arbitration
                                       -- Allowed values - "TDM", "ROUND_ROBIN",
                                       -- "RD_PRI_REG", "RD_PRI_REG_STARVE_LIMIT"
   C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
                                         -- Width of AXI-4-Lite address bus
   C_S_AXI_CTRL_DATA_WIDTH : integer := 32;
                                         -- Width of AXI-4-Lite data buses
   C_S_AXI_BASEADDR   : std_logic_vector(31 downto 0) := X"00000000";
                                         -- Base address of AXI4 Memory Mapped bus.
   C_ECC_ONOFF_RESET_VALUE : integer := 1;
                                         -- Controls ECC on/off value at startup/reset
   C_ECC_CE_COUNTER_WIDTH  : integer := 8;
                                       -- The external memory to controller clock ratio.
   -- calibration Address. The address given below will be used for calibration
   -- read and write operations.
   CALIB_ROW_ADD           : std_logic_vector(15 downto 0) := X"0000";-- Calibration row address
   CALIB_COL_ADD           : std_logic_vector(11 downto 0) := X"000"; -- Calibration column address
   CALIB_BA_ADD            : std_logic_vector(2 downto 0) := "000";    -- Calibration bank address
   RST_ACT_LOW             : integer := 1;
                                       -- =1 for active low reset,
                                       -- =0 for active high.
   INPUT_CLK_TYPE          : string := "SINGLE_ENDED";
                                       -- input clock type DIFFERENTIAL or SINGLE_ENDED
   STARVE_LIMIT            : integer := 2
                                       -- # = 2,3,4.
   );
   port (
     --sys_clk : in std_logic;    --single ended system clocks
     clk_200 : in std_logic;     --single ended iodelayctrl clk
     ddr3_dq : inout std_logic_vector(DQ_WIDTH-1 downto 0);
     ddr3_addr : out std_logic_vector(ROW_WIDTH-1 downto 0);
     ddr3_ba : out std_logic_vector(BANK_WIDTH-1 downto 0);
     ddr3_ras_n : out std_logic;
     ddr3_cas_n : out std_logic;
     ddr3_we_n : out std_logic;
     ddr3_reset_n : out std_logic;
     ddr3_cs_n : out std_logic_vector((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
     ddr3_odt : out std_logic_vector((CS_WIDTH*nCS_PER_RANK)-1 downto 0);
     ddr3_cke : out std_logic_vector(CKE_WIDTH-1 downto 0);
     ddr3_dm : out std_logic_vector(DM_WIDTH-1 downto 0);
     ddr3_dqs_p : inout std_logic_vector(DQS_WIDTH-1 downto 0);
     ddr3_dqs_n : inout std_logic_vector(DQS_WIDTH-1 downto 0);
     ddr3_ck_p : out std_logic_vector(CK_WIDTH-1 downto 0);
     ddr3_ck_n : out std_logic_vector(CK_WIDTH-1 downto 0);
     aresetn : in std_logic;
     s_axi_awid : in std_logic_vector(C_S_AXI_ID_WIDTH-1 downto 0);
     s_axi_awaddr : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
     s_axi_awlen : in std_logic_vector(7 downto 0);
     s_axi_awsize : in std_logic_vector(2 downto 0);
     s_axi_awburst : in std_logic_vector(1 downto 0);
     s_axi_awlock : in std_logic_vector(0 downto 0);
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
     s_axi_arlock : in std_logic_vector(0 downto 0);
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
     ui_clk_sync_rst : out std_logic;
     ui_clk : out std_logic;
     -- AXI CTRL port
     s_axi_ctrl_awvalid : in std_logic;
     s_axi_ctrl_awready : out std_logic;
     s_axi_ctrl_awaddr : in std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
     -- Slave Interface Write Data Ports
     s_axi_ctrl_wvalid : in std_logic;
     s_axi_ctrl_wready : out std_logic;
     s_axi_ctrl_wdata : in std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
     -- Slave Interface Write Response Ports
     s_axi_ctrl_bvalid : out std_logic;
     s_axi_ctrl_bready : in std_logic;
     s_axi_ctrl_bresp : out std_logic_vector(1 downto 0);
     -- Slave Interface Read Address Ports
     s_axi_ctrl_arvalid : in std_logic;
     s_axi_ctrl_arready : out std_logic;
     s_axi_ctrl_araddr : in std_logic_vector(C_S_AXI_CTRL_ADDR_WIDTH-1 downto 0);
     -- Slave Interface Read Data Ports
     s_axi_ctrl_rvalid : out std_logic;
     s_axi_ctrl_rready : in std_logic;
     s_axi_ctrl_rdata : out std_logic_vector(C_S_AXI_CTRL_DATA_WIDTH-1 downto 0);
     s_axi_ctrl_rresp : out std_logic_vector(1 downto 0);
     -- Interrupt output
     interrupt : out std_logic;
     phy_init_done : out std_logic;
     sys_rst : in std_logic   -- System reset
   );
   end component mig_ml605;


  component WireDelay
    generic (
       Delay_g    : time;
       Delay_rd   : time;
       ERR_INSERT : string);
    port
      (A             : inout Std_Logic;
       B             : inout Std_Logic;
       reset         : in    Std_Logic;
       phy_init_done : in    Std_Logic
       );
  end component WireDelay;

  component axi4_tg 
    generic (
     C_AXI_ID_WIDTH           : integer := 4; -- The AXI id width used for read and write
                                             -- This is an integer between 1-16
     C_AXI_ADDR_WIDTH         : integer := 32; -- This is AXI address width for all 
                                              -- SI and MI slots
     C_AXI_DATA_WIDTH         : integer := 32; -- Width of the AXI write and read data
     C_AXI_NBURST_SUPPORT     : integer := 0; -- Support for narrow burst transfers
                                             -- 1-supported, 0-not supported 
     C_EN_WRAP_TRANS          : integer := 0; -- Set 1 to enable wrap transactions
     C_BEGIN_ADDRESS          : std_logic_vector(31 downto 0) := X"00000000"; -- Start address of the address map
     C_END_ADDRESS            : std_logic_vector(31 downto 0) := X"FFFFFFFF"; -- End address of the address map
     DBG_WR_STS_WIDTH         : integer := 32;
     DBG_RD_STS_WIDTH         : integer := 32;
     ENFORCE_RD_WR            : integer := 0;
     ENFORCE_RD_WR_CMD        : std_logic_vector(7 downto 0) := X"11";
     EN_UPSIZER               : integer := 0;
     ENFORCE_RD_WR_PATTERN    : std_logic_vector(2 downto 0) := "000");
  port (
   aclk : in std_logic;    -- AXI input clock
   aresetn : in std_logic; -- Active low AXI reset signal
-- Input control signals
   init_cmptd : in std_logic; -- Initialization completed
   init_test : in std_logic;  -- Initialize the test
   wdog_mask : in std_logic;  -- Mask the watchdog timeouts
   wrap_en : in std_logic;    -- Enable wrap transactions
-- AXI write address channel signals
   axi_wready : in std_logic; -- Indicates slave is ready to accept a 
   axi_wid : out std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);    -- Write ID
   axi_waddr : out std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);  -- Write address
   axi_wlen : out std_logic_vector(7 downto 0);   -- Write Burst Length
   axi_wsize : out std_logic_vector(2 downto 0);  -- Write Burst size
   axi_wburst : out std_logic_vector(1 downto 0); -- Write Burst type
   axi_wlock : out std_logic_vector(1 downto 0);  -- Write lock type
   axi_wcache : out std_logic_vector(3 downto 0); -- Write Cache type
   axi_wprot : out std_logic_vector(2 downto 0);  -- Write Protection type
   axi_wvalid : out std_logic; -- Write address valid
-- AXI write data channel signals
   axi_wd_wready : in std_logic;  -- Write data ready
   axi_wd_wid : out std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);     -- Write ID tag
   axi_wd_data : out std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);    -- Write data
   axi_wd_strb : out std_logic_vector(C_AXI_DATA_WIDTH/8-1 downto 0);    -- Write strobes
   axi_wd_last : out std_logic;    -- Last write transaction   
   axi_wd_valid : out std_logic;   -- Write valid
-- AXI write response channel signals
   axi_wd_bid : in std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);     -- Response ID
   axi_wd_bresp : in std_logic_vector(1 downto 0);   -- Write response
   axi_wd_bvalid : in std_logic;  -- Write reponse valid
   axi_wd_bready : out std_logic;  -- Response ready
-- AXI read address channel signals
   axi_rready : in std_logic;     -- Read address ready
   axi_rid : out std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);        -- Read ID
   axi_raddr : out std_logic_vector(C_AXI_ADDR_WIDTH-1 downto 0);      -- Read address
   axi_rlen : out std_logic_vector(7 downto 0);       -- Read Burst Length
   axi_rsize : out std_logic_vector(2 downto 0);      -- Read Burst size
   axi_rburst : out std_logic_vector(1 downto 0);     -- Read Burst type
   axi_rlock : out std_logic_vector(1 downto 0);      -- Read lock type
   axi_rcache : out std_logic_vector(3 downto 0);     -- Read Cache type
   axi_rprot : out std_logic_vector(2 downto 0);      -- Read Protection type
   axi_rvalid : out std_logic;     -- Read address valid
-- AXI read data channel signals   
   axi_rd_bid : in std_logic_vector(C_AXI_ID_WIDTH-1 downto 0);     -- Response ID
   axi_rd_rresp : in std_logic_vector(1 downto 0);   -- Read response
   axi_rd_rvalid : in std_logic;  -- Read reponse valid
   axi_rd_data : in std_logic_vector(C_AXI_DATA_WIDTH-1 downto 0);    -- Read data
   axi_rd_last : in std_logic;    -- Read last
   axi_rd_rready : out std_logic;  -- Read Response ready
-- Error status signals
   cmd_err : out std_logic;      -- Error during command phase
   data_msmatch_err : out std_logic; -- Data mismatch
   write_err : out std_logic;    -- Write error occured
   read_err : out std_logic;     -- Read error occured
   test_cmptd : out std_logic;   -- Data pattern test completed
   write_cmptd : out std_logic;  -- Write test completed
   read_cmptd : out std_logic;   -- Read test completed
   cmptd_cycle : out std_logic;  -- Indicates eight transactions completed
   cmptd_one_wr_rd : out std_logic; -- Completed atleast one write and read
-- Debug status signals
   dbg_wr_sts_vld : out std_logic; -- Write debug status valid,
   dbg_wr_sts : out std_logic_vector(DBG_WR_STS_WIDTH-1 downto 0);     -- Write status
   dbg_rd_sts_vld : out std_logic; -- Read debug status valid
   dbg_rd_sts : out std_logic_vector(DBG_RD_STS_WIDTH-1 downto 0)    -- Read status
  );
  end component axi4_tg;

  component ff_aw is
  port (
     rstn : in std_logic;
     clk_fast : in std_logic;  
     clk_slow : in std_logic;  
     -- 60 MHz
     slow_aw_valid : in std_logic;
     slow_aw_bits : in nasti_metadata_type;
     slow_aw_id   : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     slow_aw_user : in std_logic;
     slow_aw_ready : out std_logic;

     -- 200 MHz
     fast_aw_valid : out std_logic;
     fast_aw_bits : out nasti_metadata_type;
     fast_aw_id   : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     fast_aw_user : out std_logic;
     fast_aw_ready : in std_logic
  );
  end component;

  component ff_w is
  port (
     rstn : in std_logic;
     clk_fast : in std_logic;  
     clk_slow : in std_logic;  
     -- 60 MHz
     slow_w_valid : in std_logic;
     slow_w_data : in std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
     slow_w_last : in std_logic;
     slow_w_strb : in std_logic_vector(CFG_NASTI_DATA_BYTES-1 downto 0);
     slow_w_user : in std_logic;
     slow_w_ready : out std_logic;
     -- 200 MHz
     fast_w_valid : out std_logic;
     fast_w_data : out std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
     fast_w_last : out std_logic;
     fast_w_strb : out std_logic_vector(CFG_NASTI_DATA_BYTES-1 downto 0);
     fast_w_user : out std_logic;
     fast_w_ready : in std_logic
  );
  end component;
  
  component ff_b is
  port (
     rstn : in std_logic;
     clk_fast : in std_logic;  
     clk_slow : in std_logic;  
     -- 60 MHz
     slow_b_ready : in std_logic;
     slow_b_valid : out std_logic;
     slow_b_resp : out std_logic_vector(1 downto 0);
     slow_b_id   : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     slow_b_user : out std_logic;
     -- 200 MHz
     fast_b_ready : out std_logic;
     fast_b_valid : in std_logic;
     fast_b_resp : in std_logic_vector(1 downto 0);
     fast_b_id   : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     fast_b_user : in std_logic
  );
  end component;

  component ff_ar is
  port (
     rstn : in std_logic;
     clk_fast : in std_logic;  
     clk_slow : in std_logic;  
     -- 60 MHz
     slow_ar_valid : in std_logic;
     slow_ar_bits : in nasti_metadata_type;
     slow_ar_id   : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     slow_ar_user : in std_logic;
     slow_ar_ready : out std_logic;
     -- 200 MHz
     fast_ar_valid : out std_logic;
     fast_ar_bits : out nasti_metadata_type;
     fast_ar_id   : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     fast_ar_user : out std_logic;
     fast_ar_ready : in std_logic
  );
  end component;

  component ff_r is
  port (
     rstn : in std_logic;
     clk_slow : in std_logic;
     clk_fast : in std_logic;  
     -- 60 MHz
     slow_r_ready : in std_logic;
     slow_r_valid : out std_logic;
     slow_r_resp : out std_logic_vector(1 downto 0);
     slow_r_data : out std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
     slow_r_last : out std_logic;
     slow_r_id   : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     slow_r_user : out std_logic;
     -- 200 MHz
     fast_r_ready : out std_logic;
     fast_r_valid : in std_logic;
     fast_r_resp : in std_logic_vector(1 downto 0);
     fast_r_data : in std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
     fast_r_last : in std_logic;
     fast_r_id   : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     fast_r_user : in std_logic
  );
  end component;

 component ddr3_model port (
    rst_n   : in std_logic;
    ck      : in std_logic;
    ck_n    : in std_logic;
    cke     : in std_logic;
    cs_n    : in std_logic;
    ras_n   : in std_logic;
    cas_n   : in std_logic;
    we_n    : in std_logic;
    dm_tdqs : inout std_logic_vector(CFG_DDR_DM_BITS-1 downto 0); -- inout   [DM_BITS-1:0]   
    ba      : in std_logic_vector(CFG_DDR_BANK_WIDTH-1 downto 0); -- input   [BA_BITS-1:0]   
    addr    : in std_logic_vector(CFG_DDR_ROW_WIDTH-1 downto 0); -- input   [ADDR_BITS-1:0] 
    dq      : inout std_logic_vector(15 downto 0);
    dqs     : inout std_logic_vector(CFG_DDR_DQS_WIDTH-1 downto 0);
    dqs_n   : inout std_logic_vector(CFG_DDR_DQS_WIDTH-1 downto 0);
    tdqs_n  : out std_logic_vector(CFG_DDR_DQS_WIDTH-1 downto 0);
    odt     : in std_logic
);
end component ddr3_model;

  component axi_ddr3_v6 is 
  generic (
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#
  );
  port (
   i_rstn : in std_logic;
   i_clk_200 : in std_logic;
   i_pll_bus : in std_logic;

   io_ddr3_dq : inout std_logic_vector(CFG_DDR_DQ_WIDTH-1 downto 0);
   o_ddr3_addr : out std_logic_vector(CFG_DDR_ROW_WIDTH-1 downto 0);
   o_ddr3_ba : out std_logic_vector(CFG_DDR_BANK_WIDTH-1 downto 0);
   o_ddr3_ras_n : out std_logic;
   o_ddr3_cas_n : out std_logic;
   o_ddr3_we_n : out std_logic;
   o_ddr3_reset_n : out std_logic;
   o_ddr3_cs_n : out std_logic_vector((CFG_DDR_CS_WIDTH*CFG_DDR_nCS_PER_RANK)-1 downto 0);
   o_ddr3_odt : out std_logic_vector((CFG_DDR_CS_WIDTH*CFG_DDR_nCS_PER_RANK)-1 downto 0);
   o_ddr3_cke : out std_logic_vector(CFG_DDR_CKE_WIDTH-1 downto 0);
   o_ddr3_dm : out std_logic_vector(CFG_DDR_DM_WIDTH-1 downto 0);
   io_ddr3_dqs_p : inout std_logic_vector(CFG_DDR_DQS_WIDTH-1 downto 0);
   io_ddr3_dqs_n : inout std_logic_vector(CFG_DDR_DQS_WIDTH-1 downto 0);
   o_ddr3_ck_p : out std_logic_vector(CFG_DDR_CK_WIDTH-1 downto 0);
   o_ddr3_ck_n : out std_logic_vector(CFG_DDR_CK_WIDTH-1 downto 0);

   o_phy_init_done : out std_logic;

   i_slv : in nasti_slave_in_type;
   o_slv : out nasti_slave_out_type;
   o_cfg  : out nasti_slave_config_type
  );
  end component;

end; -- package body

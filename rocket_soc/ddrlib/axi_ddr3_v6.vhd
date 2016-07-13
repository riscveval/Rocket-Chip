library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
library commonlib;
use commonlib.types_common.all;
library techmap;
use techmap.gencomp.all;
use techmap.types_pll.all;
library ambalib;
use ambalib.types_amba4.all;
library ddrlib;
use ddrlib.types_ddr.all;

entity axi_ddr3_v6 is
generic (
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#
);
port (
   i_rstn : in std_logic;
   i_clk_200 : in std_logic;
   i_pll_bus : in std_logic;
   i_pll_clk_mem : in std_logic;  --400 MHz
   i_pll_clk : in std_logic;      --200 MHz
   i_pll_rd_base : in std_logic;  -- 400 MHz
   i_pll_locked : in std_logic;
   o_PSEN : out std_logic;           -- For enabling fine-phase shift
   o_PSINCDEC : out std_logic;        -- = 1 increment phase shift, = 0
   i_PSDONE : in std_logic;

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
end entity axi_ddr3_v6;

architecture arch_axi_ddr3_v6 of axi_ddr3_v6 is
  constant REFCLK_FREQ           : real := 200.0;
                                    -- # = 200 for all design frequencies of
                                    --         -1 speed grade devices
                                    --   = 200 when design frequency < 480 MHz
                                    --         for -2 and -3 speed grade devices.
                                    --   = 300 when design frequency >= 480 MHz
                                    --         for -2 and -3 speed grade devices.
  constant SIM_BYPASS_INIT_CAL   : string := "FAST";
                                    -- # = "OFF" -  Complete memory init &
                                    --              calibration sequence
                                    -- # = "SKIP" - Skip memory init &
                                    --              calibration sequence
                                    -- # = "FAST" - Skip memory init & use
                                    --              abbreviated calib sequence
  constant RST_ACT_LOW           : integer := 1;
                                    -- =1 for active low reset,
                                    -- =0 for active high.
  constant IODELAY_GRP           : string := "IODELAY_MIG";
                                    --to phy_top
  constant nCK_PER_CLK           : integer := 2;
                                    -- # of memory CKs per fabric clock.
                                    -- # = 2, 1.
  constant nCS_PER_RANK          : integer := 1;
                                    -- # of unique CS outputs per Rank for
                                    -- phy.
  constant DQS_CNT_WIDTH         : integer := 3;
                                    -- # = ceil(log2(DQS_WIDTH)).
  constant RANK_WIDTH            : integer := 1;
                                    -- # = ceil(log2(RANKS)).
  constant BANK_WIDTH            : integer := 3;
                                    -- # of memory Bank Address bits.
  constant CK_WIDTH              : integer := 1;
                                    -- # of CK/CK# outputs to memory.
  constant CKE_WIDTH             : integer := 1;
                                    -- # of CKE outputs to memory.
  constant COL_WIDTH             : integer := 10;
                                    -- # of memory Column Address bits.
  constant CS_WIDTH              : integer := 1;
                                    -- # of unique CS outputs to memory.
  constant DM_WIDTH              : integer := 8;
                                    -- # of Data Mask bits.
  constant DQ_WIDTH              : integer := 64;
                                    -- # of Data (DQ) bits.
  constant DQS_WIDTH             : integer := 8;
                                    -- # of DQS/DQS# bits.
  constant ROW_WIDTH             : integer := 13;
                                    -- # of memory Row Address bits.
  constant BURST_MODE            : string := "8";
                                    -- Burst Length (Mode Register 0).
                                    -- # = "8", "4", "OTF".
  constant INPUT_CLK_TYPE        : string := "SINGLE_ENDED";
                                    -- input clock type DIFFERENTIAL or SINGLE_ENDED
  constant BM_CNT_WIDTH          : integer := 2;
                                    -- # = ceil(log2(nBANK_MACHS)).
  constant ADDR_CMD_MODE         : string  := "1T" ;
                                    -- # = "2T", "1T".
  constant ORDERING              : string := "STRICT";
                                    -- # = "NORM", "STRICT".
  constant RTT_NOM               : string := "60";
                                    -- RTT_NOM (ODT) (Mode Register 1).
                                    -- # = "DISABLED" - RTT_NOM disabled,
                                    --   = "120" - RZQ/2,
                                    --   = "60" - RZQ/4,
                                    --   = "40" - RZQ/6.
  constant RTT_WR                : string := "OFF";
                                       -- RTT_WR (ODT) (Mode Register 2).
                                       -- # = "OFF" - Dynamic ODT off,
                                       --   = "120" - RZQ/2,
                                       --   = "60" - RZQ/4,
  constant OUTPUT_DRV            : string := "HIGH";
                                    -- Output Driver Impedance Control (Mode Register 1).
                                    -- # = "HIGH" - RZQ/7,
                                    --   = "LOW" - RZQ/6.
  constant REG_CTRL              : string := "OFF";
                                    -- # = "ON" - RDIMMs,
                                    --   = "OFF" - Components, SODIMMs, UDIMMs.
  constant CLKFBOUT_MULT_F       : integer := 6; -- (200 / 1) * 6 = 1200 MHz
                                    -- write PLL VCO multiplier.
  constant DIVCLK_DIVIDE         : integer := 1; -- 1 for Fin=200 MHz; 2 when Fin = 400 MHz from SMA
                                    -- write PLL VCO divisor.
  constant CLKOUT_DIVIDE         : integer := 3; -- 1200 MHz / 3 = 400 MHz
                                    -- VCO output divisor for fast (memory) clocks.
  constant tCK                   : integer := 2500;
                                    -- memory tCK paramter.
                                    -- # = Clock Period.
  constant DEBUG_PORT            : string := "OFF";
                                    -- # = "ON" Enable debug signals/controls.
                                    --   = "OFF" Disable debug signals/controls.
  constant tPRDI                 : integer := 1000000;
                                    -- memory tPRDI paramter.
  constant tREFI                 : integer := 7800000;
                                    -- memory tREFI paramter.
  constant tZQI                  : integer := 128000000;
                                    -- memory tZQI paramter.
  constant ADDR_WIDTH            : integer := 27;
                                    -- # = RANK_WIDTH + BANK_WIDTH
                                    --     + ROW_WIDTH + COL_WIDTH;
  constant STARVE_LIMIT          : integer := 2;
                                    -- # = 2,3,4.
  constant TCQ                   : integer := 100;
  constant ECC                   : string := "OFF";
  constant ECC_TEST              : string := "OFF";
  constant DATA_WIDTH : integer := 64;
  constant PAYLOAD_WIDTH : integer := 64;

  constant INTERFACE : string := "AXI4";
                                      -- Port Interface.
                                      -- # = UI - User Interface,
                                      --   = AXI4 - AXI4 Interface.
  --***********************************************************************//
  -- AXI related parameters
  --***********************************************************************//
  constant C_S_AXI_ID_WIDTH        : integer := 5;
                                      -- Width of all master and slave ID signals.
                                      -- # = >= 1.
  constant C_S_AXI_ADDR_WIDTH      : integer := 32;
                                      -- Width of S_AXI_AWADDR, S_AXI_ARADDR, M_AXI_AWADDR and
                                      -- M_AXI_ARADDR for all SI/MI slots.
                                      -- # = 32.
  constant C_S_AXI_DATA_WIDTH      : integer := 128;
                                      -- Width of WDATA and RDATA on SI slot.
                                      -- Must be less or equal to APP_DATA_WIDTH.
                                      -- # = 32, 64, 128, 256.
  constant C_S_AXI_SUPPORTS_NARROW_BURST : integer := 1;
                                       -- Indicates whether to instatiate upsizer
                                       -- Range: 0, 1
  constant C_RD_WR_ARB_ALGORITHM : string := "RD_PRI_REG";
                                       -- Indicates the Arbitration
                                       -- Allowed values - "TDM", "ROUND_ROBIN",
                                       -- "RD_PRI_REG", "RD_PRI_REG_STARVE_LIMIT"
  constant C_S_AXI_CTRL_ADDR_WIDTH : integer := 32;
                                        -- Width of AXI-4-Lite address bus
  constant C_S_AXI_CTRL_DATA_WIDTH : integer := 32;
                                        -- Width of AXI-4-Lite data buses
  constant C_S_AXI_BASEADDR        : std_logic_vector(31 downto 0) := X"00000000";
                                        -- Base address of AXI4 Memory Mapped bus.
  constant C_ECC_ONOFF_RESET_VALUE : integer := 1;
                                        -- Controls ECC on/off value at startup/reset
  constant C_ECC_CE_COUNTER_WIDTH  : integer := 8;
                                        -- The external memory to controller clock ratio.
  -- calibration Address. The address given below will be used for calibration
  -- read and write operations.
  constant CALIB_ROW_ADD  : std_logic_vector(15 downto 0) := X"0000";-- Calibration row address
  constant CALIB_COL_ADD  : std_logic_vector(11 downto 0) := X"000"; -- Calibration column address
  constant CALIB_BA_ADD   : std_logic_vector(2 downto 0) := "000";    -- Calibration bank address

  constant xconfig : nasti_slave_config_type := (
     xindex => xindex,
     xaddr => conv_std_logic_vector(xaddr, CFG_NASTI_CFG_ADDR_BITS),
     xmask => conv_std_logic_vector(xmask, CFG_NASTI_CFG_ADDR_BITS),
     vid => VENDOR_GNSSSENSOR,
     did => XILINX_DDR,
     descrtype => PNP_CFG_TYPE_SLAVE,
     descrsize => PNP_CFG_SLAVE_DESCR_BYTES
  );

  --**************************************************************************--
  -- Wire Declarations
  --**************************************************************************--
  signal sys_rst_p : std_logic;


  signal clk : std_logic;
  signal rst : std_logic;

  signal aresetn : std_logic; -- reg

  -- Slave Interface Write Address Ports
  signal s_axi_awlock1 : std_logic_vector(0 downto 0);
  signal s_axi_arlock1 : std_logic_vector(0 downto 0);

  signal si_slv : nasti_slave_in_type;
  signal so_slv : nasti_slave_out_type;
  signal iaxi : nasti_slave_in_type;
  signal oaxi : nasti_slave_out_type;
  
  type state_type is (state_idle, state_rd, state_wr, state_handshake);
  type registers is record 
      state : state_type;
      burst_len : std_logic_vector(7 downto 0);
  end record;
  signal r, rin : registers;

begin

  o_cfg <= xconfig;
  sys_rst_p <= not i_rstn;
  
  o_slv <= so_slv;
  aresetn <= i_rstn;

  comblogic : process(i_rstn, i_slv, r, so_slv)
    variable v_slv : nasti_slave_in_type;
    variable v : registers;
  begin
    v := r;

    v_slv := i_slv;
    v_slv.w_valid := '0';
    v_slv.w_last := '0';
    v_slv.w_strb := (others => '0');
    v_slv.w_data := (others => '0');
    
    if i_slv.ar_valid = '1' and 
      ((i_slv.ar_bits.addr(CFG_NASTI_ADDR_BITS-1 downto 12) and xconfig.xmask) = xconfig.xaddr) then
      v_slv.ar_valid := '1';
      v_slv.ar_bits.addr := (i_slv.ar_bits.addr(CFG_NASTI_ADDR_BITS-1 downto 12) and (not xconfig.xmask))
                   & i_slv.ar_bits.addr(11 downto 0);
    else
      v_slv.ar_valid := '0';
    end if;

    if i_slv.aw_valid = '1' and 
      ((i_slv.aw_bits.addr(CFG_NASTI_ADDR_BITS-1 downto 12) and xconfig.xmask) = xconfig.xaddr) then
      v_slv.aw_valid := '1';
      v_slv.aw_bits.addr := (i_slv.aw_bits.addr(CFG_NASTI_ADDR_BITS-1 downto 12) and (not xconfig.xmask))
                   & i_slv.aw_bits.addr(11 downto 0);

    else
      v_slv.aw_valid := '0';
    end if;
    
    if i_rstn = '0' then 
      v.state := state_idle;
    end if;
    
    case r.state is
    when state_idle =>
      if v_slv.ar_valid = '1' then
        v.state := state_rd;
        v.burst_len := i_slv.ar_bits.len;
      elsif v_slv.aw_valid = '1' then
        v.state := state_wr;
        v.burst_len := i_slv.aw_bits.len;
      end if;

    when state_rd =>
      if i_slv.r_ready = '1' and so_slv.r_valid = '1' then
        if r.burst_len = X"00" then
            v.state := state_idle;
        else
            v.burst_len := r.burst_len - 1;
       end if;
      end if;
      
    when state_wr =>
      v_slv.w_valid := i_slv.w_valid;
      v_slv.w_strb := i_slv.w_strb;
      v_slv.w_data := i_slv.w_data;
      if r.burst_len = X"00" then
          v_slv.w_last := '1';
      end if;
      if i_slv.w_valid = '1' and so_slv.w_ready = '1' then
        if r.burst_len = X"00" then
            v.state := state_handshake;
        else
            v.burst_len := r.burst_len - 1;
       end if;
      end if;
      
    when state_handshake =>
      if i_slv.b_ready = '1' and so_slv.b_valid = '1' then
        v.state := state_idle;
      end if;
    when others =>
    end case;

    si_slv <= v_slv;
    rin <= v;
  end process;
  
  
  process (i_pll_bus, rin)
  begin
    if rising_edge(i_pll_bus) then
        r <= rin;
    end if;
  end process;

  

  u_ip_top : mig_ml605 
    generic map (
     nCK_PER_CLK               => nCK_PER_CLK,
     tCK                       => tCK,
     RST_ACT_LOW               => RST_ACT_LOW,
     REFCLK_FREQ               => REFCLK_FREQ,
     IODELAY_GRP               => IODELAY_GRP,
     INPUT_CLK_TYPE            => INPUT_CLK_TYPE,
     BANK_WIDTH                => BANK_WIDTH,
     CK_WIDTH                  => CK_WIDTH,
     CKE_WIDTH                 => CKE_WIDTH,
     COL_WIDTH                 => COL_WIDTH,
     nCS_PER_RANK              => nCS_PER_RANK,
     DQ_WIDTH                  => DQ_WIDTH,
     DM_WIDTH                  => DM_WIDTH,
     DQS_CNT_WIDTH             => DQS_CNT_WIDTH,
     DQS_WIDTH                 => DQS_WIDTH,
     ROW_WIDTH                 => ROW_WIDTH,
     RANK_WIDTH                => RANK_WIDTH,
     CS_WIDTH                  => CS_WIDTH,
     BURST_MODE                => BURST_MODE,
     BM_CNT_WIDTH              => BM_CNT_WIDTH,
     CLKFBOUT_MULT_F           => CLKFBOUT_MULT_F,
     DIVCLK_DIVIDE             => DIVCLK_DIVIDE,
     CLKOUT_DIVIDE             => CLKOUT_DIVIDE,
     OUTPUT_DRV                => OUTPUT_DRV,
     REG_CTRL                  => REG_CTRL,
     RTT_NOM                   => RTT_NOM,
     RTT_WR                    => RTT_WR,
     SIM_BYPASS_INIT_CAL       => SIM_BYPASS_INIT_CAL,
     DEBUG_PORT                => DEBUG_PORT,
     tPRDI                     => tPRDI,
     tREFI                     => tREFI,
     tZQI                      => tZQI,
     ADDR_CMD_MODE             => ADDR_CMD_MODE,
     ORDERING                  => ORDERING,
     STARVE_LIMIT              => STARVE_LIMIT,
     ADDR_WIDTH                => ADDR_WIDTH,
     ECC                       => ECC,
     ECC_TEST                  => ECC_TEST,
     INTERFACE                 => INTERFACE,
     TCQ                       => TCQ,
     DATA_WIDTH                => DATA_WIDTH,
     PAYLOAD_WIDTH             => PAYLOAD_WIDTH,
     C_S_AXI_ID_WIDTH          => C_S_AXI_ID_WIDTH,
     C_S_AXI_ADDR_WIDTH        => C_S_AXI_ADDR_WIDTH,
     C_S_AXI_DATA_WIDTH        => C_S_AXI_DATA_WIDTH,
     C_S_AXI_SUPPORTS_NARROW_BURST => C_S_AXI_SUPPORTS_NARROW_BURST,
     C_RD_WR_ARB_ALGORITHM      => C_RD_WR_ARB_ALGORITHM,
     C_S_AXI_CTRL_ADDR_WIDTH   => C_S_AXI_CTRL_ADDR_WIDTH,
     C_S_AXI_CTRL_DATA_WIDTH   => C_S_AXI_CTRL_DATA_WIDTH,
     C_S_AXI_BASEADDR          => C_S_AXI_BASEADDR,
     C_ECC_ONOFF_RESET_VALUE   => C_ECC_ONOFF_RESET_VALUE,
     C_ECC_CE_COUNTER_WIDTH    => C_ECC_CE_COUNTER_WIDTH,
     CALIB_ROW_ADD             => CALIB_ROW_ADD,
     CALIB_COL_ADD             => CALIB_COL_ADD,
     CALIB_BA_ADD              => CALIB_BA_ADD
     )
     port map (
       clk_200              => i_clk_200,
       clk_mem              => i_pll_clk_mem,
       clk                  => i_pll_clk,
       clk_rd_base          => i_pll_rd_base,
       pll_locked           => i_pll_locked,
       -- Phase Shift Interface
       o_PSEN               => o_PSEN,
       o_PSINCDEC           => o_PSINCDEC,
       i_PSDONE             => i_PSDONE,
       sys_rst              => i_rstn,
       ddr3_ck_p            => o_ddr3_ck_p,
       ddr3_ck_n            => o_ddr3_ck_n,
       ddr3_addr            => o_ddr3_addr,
       ddr3_ba              => o_ddr3_ba,
       ddr3_ras_n           => o_ddr3_ras_n,
       ddr3_cas_n           => o_ddr3_cas_n,
       ddr3_we_n            => o_ddr3_we_n,
       ddr3_cs_n            => o_ddr3_cs_n,
       ddr3_cke             => o_ddr3_cke,
       ddr3_odt             => o_ddr3_odt,
       ddr3_reset_n         => o_ddr3_reset_n,
       ddr3_dm              => o_ddr3_dm,
       ddr3_dq              => io_ddr3_dq,
       ddr3_dqs_p           => io_ddr3_dqs_p,
       ddr3_dqs_n           => io_ddr3_dqs_n,
       ui_clk               => clk,
       ui_clk_sync_rst      => rst,
       aresetn              => aresetn,

       s_axi_awid              => iaxi.aw_id,
       s_axi_awaddr            => iaxi.aw_bits.addr,
       s_axi_awlen             => iaxi.aw_bits.len,
       s_axi_awsize            => iaxi.aw_bits.size,
       s_axi_awburst           => iaxi.aw_bits.burst,
       s_axi_awlock            => s_axi_awlock1,
       s_axi_awcache           => iaxi.aw_bits.cache,
       s_axi_awprot            => iaxi.aw_bits.prot ,
       s_axi_awqos             => iaxi.aw_bits.qos,--X"0",
       s_axi_awvalid           => iaxi.aw_valid,
       s_axi_awready           => oaxi.aw_ready,

       s_axi_wdata             => iaxi.w_data,
       s_axi_wstrb             => iaxi.w_strb,
       s_axi_wlast             => iaxi.w_last,
       s_axi_wvalid            => iaxi.w_valid,
       s_axi_wready            => oaxi.w_ready,

       s_axi_bid               => oaxi.b_id,
       s_axi_bresp             => oaxi.b_resp,
       s_axi_bvalid            => oaxi.b_valid,
       s_axi_bready            => iaxi.b_ready,

       s_axi_arid              => iaxi.ar_id,
       s_axi_araddr            => iaxi.ar_bits.addr,
       s_axi_arlen             => iaxi.ar_bits.len,
       s_axi_arsize            => iaxi.ar_bits.size,
       s_axi_arburst           => iaxi.ar_bits.burst,
       s_axi_arlock            => s_axi_arlock1,
       s_axi_arcache           => iaxi.ar_bits.cache,
       s_axi_arprot            => iaxi.ar_bits.prot,
       s_axi_arqos             => iaxi.ar_bits.qos,
       s_axi_arvalid           => iaxi.ar_valid,
       s_axi_arready           => oaxi.ar_ready,

       s_axi_rid               => oaxi.r_id,
       s_axi_rdata             => oaxi.r_data,
       s_axi_rresp             => oaxi.r_resp,
       s_axi_rlast             => oaxi.r_last,
       s_axi_rvalid            => oaxi.r_valid,
       s_axi_rready            => iaxi.r_ready,
       s_axi_ctrl_awvalid      => '0',
       s_axi_ctrl_awready      => open,
       s_axi_ctrl_awaddr       => (others => '0'),
       s_axi_ctrl_wvalid       => '0',
       s_axi_ctrl_wready       => open,
       s_axi_ctrl_wdata        => (others => '0'),
       s_axi_ctrl_bvalid       => open,
       s_axi_ctrl_bready       => '1',
       s_axi_ctrl_bresp        => open,
       s_axi_ctrl_arvalid      => '0',
       s_axi_ctrl_arready      => open,
       s_axi_ctrl_araddr       => (others => '0'),
       s_axi_ctrl_rvalid       => open,
       s_axi_ctrl_rready       => '1',
       s_axi_ctrl_rdata        => open,
       s_axi_ctrl_rresp        => open,
       interrupt               => open,
       phy_init_done        => o_phy_init_done
       );




 aw0 : ff_aw port map (
     rstn => aresetn,
     clk_fast => clk,
     clk_slow => i_pll_bus,
     -- 60 MHz
     slow_aw_valid => si_slv.aw_valid,
     slow_aw_bits  => si_slv.aw_bits,
     slow_aw_id    => si_slv.aw_id,
     slow_aw_user  => si_slv.aw_user,
     slow_aw_ready => so_slv.aw_ready,
     -- 200 MHz
     fast_aw_valid => iaxi.aw_valid,
     fast_aw_bits  => iaxi.aw_bits,
     fast_aw_id    => iaxi.aw_id,
     fast_aw_user  => iaxi.aw_user,
     fast_aw_ready => oaxi.aw_ready
  );
  s_axi_awlock1(0) <= iaxi.aw_bits.lock;

  w0 : ff_w port map (
     rstn => aresetn,
     clk_fast => clk,
     clk_slow => i_pll_bus,
     -- 60 MHz
     slow_w_valid => si_slv.w_valid,
     slow_w_data  => si_slv.w_data,
     slow_w_last  => si_slv.w_last,
     slow_w_strb  => si_slv.w_strb,
     slow_w_user  => si_slv.w_user,
     slow_w_ready => so_slv.w_ready,
     -- 200 MHz
     fast_w_valid => iaxi.w_valid,
     fast_w_data  => iaxi.w_data,
     fast_w_last  => iaxi.w_last,
     fast_w_strb  => iaxi.w_strb,
     fast_w_user  => iaxi.w_user,
     fast_w_ready => oaxi.w_ready
  );
  
  b0 : ff_b port map (
     rstn => aresetn,
     clk_fast     => clk,
     clk_slow     => i_pll_bus,
     -- 60 MHz
     slow_b_ready => si_slv.b_ready,
     slow_b_valid => so_slv.b_valid,
     slow_b_resp  => so_slv.b_resp,
     slow_b_id    => so_slv.b_id,
     slow_b_user  => so_slv.b_user,
     -- 200 MHz
     fast_b_ready => iaxi.b_ready,
     fast_b_valid => oaxi.b_valid,
     fast_b_resp  => oaxi.b_resp,
     fast_b_id    => oaxi.b_id,
     fast_b_user  => oaxi.b_user
  );
  
 
 ar0 : ff_ar port map (
     rstn => aresetn,
     clk_fast => clk,
     clk_slow => i_pll_bus,
     -- 60 MHz
     slow_ar_valid => si_slv.ar_valid,
     slow_ar_bits  => si_slv.ar_bits,
     slow_ar_id    => si_slv.ar_id,
     slow_ar_user  => si_slv.ar_user,
     slow_ar_ready => so_slv.ar_ready,
     -- 200 MHz
     fast_ar_valid => iaxi.ar_valid,
     fast_ar_bits  => iaxi.ar_bits,
     fast_ar_id    => iaxi.ar_id,
     fast_ar_user  => iaxi.ar_user,
     fast_ar_ready => oaxi.ar_ready
  );
  s_axi_arlock1(0) <= iaxi.ar_bits.lock;


  r0 : ff_r port map (
     rstn => aresetn,
     clk_fast => clk,
     clk_slow => i_pll_bus,
     -- 60 MHz
     slow_r_ready => si_slv.r_ready,
     slow_r_valid => so_slv.r_valid,
     slow_r_resp => so_slv.r_resp,
     slow_r_data => so_slv.r_data,
     slow_r_last => so_slv.r_last,
     slow_r_id   => so_slv.r_id,
     slow_r_user => so_slv.r_user,
     -- 200 MHz
     fast_r_ready => iaxi.r_ready,
     fast_r_valid => oaxi.r_valid,
     fast_r_resp => oaxi.r_resp,
     fast_r_data => oaxi.r_data,
     fast_r_last => oaxi.r_last,
     fast_r_id   => oaxi.r_id,
     fast_r_user => oaxi.r_user
  );

end architecture arch_axi_ddr3_v6;


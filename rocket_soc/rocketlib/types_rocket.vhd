-----------------------------------------------------------------------------
--! @file
--! @copyright Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author    Sergey Khabarov - sergeykhbr@gmail.com
--! @brief     System Top level modules and interconnect declarations.
-----------------------------------------------------------------------------

--! Standard library.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
--! Technology definition library.
library techmap;
use techmap.gencomp.all;
--! CPU, System Bus and common peripheries library.
library rocketlib;
use rocketlib.types_nasti.all; --! AXI4 bus configuration.
use rocketlib.types_tile.all;  --! TileLink configuration.

--! @brief   Declaration of components visible on SoC top level.
package types_rocket is

--! @brief   Bits allocated for the memory tag value.
--! @details This value is defined \i Config.scala and depends of others
--!          configuration paramters, like number of master, clients, channels
--!          and so on. It is not used in VHDL implemenation.
constant MEM_TAG_BITS  : integer := 6;
--! @brief   Memory data bitwise.
--! @details We intentionally select this value equals to AXI4 bus data width.
--!          Default SCALA configurator value uses 64/128 SerDes module to
--!          access from Tile to AXI4 bus.
constant MEM_DATA_BITS : integer := CFG_NASTI_DATA_BITS;
--! @brief   SCALA generated value. Not used in VHDL.
constant MEM_ADDR_BITS : integer := 26;
--! @brief   Multiplexing HTIF bus data width.
--! @details Not used in a case of disabled L2 cache.
--!          If L2 cached is enabled this value defines bitwise of the bus
--!          between \i Uncore module and external transievers.
--!          Standard message size for the HTID request is 128 bits, so this
--!          value defines number of beats required to transmit/recieve such
--!          message.
constant HTIF_WIDTH    : integer := 16;

--! @brief Rocket NoC Verilog implementation generated by SCALA.
component Top
port (
    clk : in std_logic;
    reset : in std_logic;
    io_host_clk : out std_logic;
    io_host_clk_edge : out std_logic;
    io_host_in_ready : out std_logic;
    io_host_in_valid : in std_logic;
    io_host_in_bits : in std_logic_vector(15 downto 0);
    io_host_out_ready : in std_logic;
    io_host_out_valid : out std_logic;
    io_host_out_bits : out std_logic_vector(15 downto 0);
    io_host_debug_stats_csr : out std_logic;
    io_mem_backup_ctrl_en : in std_logic;
    io_mem_backup_ctrl_in_valid : in std_logic;
    io_mem_backup_ctrl_out_ready : in std_logic;
    io_mem_backup_ctrl_out_valid : out std_logic;
    io_mem_0_aw_ready : in std_logic;
    io_mem_0_aw_valid : out std_logic;
    io_mem_0_aw_bits_addr : out std_logic_vector(31 downto 0);
    io_mem_0_aw_bits_len : out std_logic_vector(7 downto 0);
    io_mem_0_aw_bits_size : out std_logic_vector(2 downto 0);
    io_mem_0_aw_bits_burst : out std_logic_vector(1 downto 0);
    io_mem_0_aw_bits_lock : out std_logic;
    io_mem_0_aw_bits_cache : out std_logic_vector(3 downto 0);
    io_mem_0_aw_bits_prot : out std_logic_vector(2 downto 0);
    io_mem_0_aw_bits_qos : out std_logic_vector(3 downto 0);
    io_mem_0_aw_bits_region : out std_logic_vector(3 downto 0);
    io_mem_0_aw_bits_id : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mem_0_aw_bits_user : out std_logic;
    io_mem_0_w_ready : in std_logic;
    io_mem_0_w_valid : out std_logic;
    io_mem_0_w_bits_data : out std_logic_vector(127 downto 0);
    io_mem_0_w_bits_last : out std_logic;
    io_mem_0_w_bits_strb : out std_logic_vector(15 downto 0);
    io_mem_0_w_bits_user : out std_logic;
    io_mem_0_b_ready : out std_logic;
    io_mem_0_b_valid : in std_logic;
    io_mem_0_b_bits_resp : in std_logic_vector(1 downto 0);
    io_mem_0_b_bits_id : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mem_0_b_bits_user : in std_logic;
    io_mem_0_ar_ready : in std_logic;
    io_mem_0_ar_valid : out std_logic;
    io_mem_0_ar_bits_addr : out std_logic_vector(31 downto 0);
    io_mem_0_ar_bits_len : out std_logic_vector(7 downto 0);
    io_mem_0_ar_bits_size : out std_logic_vector(2 downto 0);
    io_mem_0_ar_bits_burst : out std_logic_vector(1 downto 0);
    io_mem_0_ar_bits_lock : out std_logic;
    io_mem_0_ar_bits_cache : out std_logic_vector(3 downto 0);
    io_mem_0_ar_bits_prot : out std_logic_vector(2 downto 0);
    io_mem_0_ar_bits_qos : out std_logic_vector(3 downto 0);
    io_mem_0_ar_bits_region : out std_logic_vector(3 downto 0);
    io_mem_0_ar_bits_id : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mem_0_ar_bits_user : out std_logic;
    io_mem_0_r_ready : out std_logic;
    io_mem_0_r_valid : in std_logic;
    io_mem_0_r_bits_resp : in std_logic_vector(1 downto 0);
    io_mem_0_r_bits_data : in std_logic_vector(127 downto 0);
    io_mem_0_r_bits_last : in std_logic;
    io_mem_0_r_bits_id : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mem_0_r_bits_user : in std_logic;
    --! mmio 
    io_mmio_aw_ready : in std_logic;
    io_mmio_aw_valid : out std_logic;
    io_mmio_aw_bits_addr : out std_logic_vector(31 downto 0);
    io_mmio_aw_bits_len : out std_logic_vector(7 downto 0);
    io_mmio_aw_bits_size : out std_logic_vector(2 downto 0);
    io_mmio_aw_bits_burst : out std_logic_vector(1 downto 0);
    io_mmio_aw_bits_lock : out std_logic;
    io_mmio_aw_bits_cache : out std_logic_vector(3 downto 0);
    io_mmio_aw_bits_prot : out std_logic_vector(2 downto 0);
    io_mmio_aw_bits_qos : out std_logic_vector(3 downto 0);
    io_mmio_aw_bits_region : out std_logic_vector(3 downto 0);
    io_mmio_aw_bits_id : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mmio_aw_bits_user : out std_logic;
    io_mmio_w_ready : in std_logic;
    io_mmio_w_valid : out std_logic;
    io_mmio_w_bits_data : out std_logic_vector(MEM_DATA_BITS-1 downto 0);
    io_mmio_w_bits_last : out std_logic;
    io_mmio_w_bits_strb : out std_logic_vector(15 downto 0);
    io_mmio_w_bits_user : out std_logic;
    io_mmio_b_ready : out std_logic;
    io_mmio_b_valid : in std_logic;
    io_mmio_b_bits_resp : in std_logic_vector(1 downto 0);
    io_mmio_b_bits_id : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mmio_b_bits_user : in std_logic;
    io_mmio_ar_ready : in std_logic;
    io_mmio_ar_valid : out std_logic;
    io_mmio_ar_bits_addr : out std_logic_vector(31 downto 0);
    io_mmio_ar_bits_len : out std_logic_vector(7 downto 0);
    io_mmio_ar_bits_size : out std_logic_vector(2 downto 0);
    io_mmio_ar_bits_burst : out std_logic_vector(1 downto 0);
    io_mmio_ar_bits_lock : out std_logic;
    io_mmio_ar_bits_cache : out std_logic_vector(3 downto 0);
    io_mmio_ar_bits_prot : out std_logic_vector(2 downto 0);
    io_mmio_ar_bits_qos : out std_logic_vector(3 downto 0);
    io_mmio_ar_bits_region : out std_logic_vector(3 downto 0);
    io_mmio_ar_bits_id : out std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mmio_ar_bits_user : out std_logic;
    io_mmio_r_ready : out std_logic;
    io_mmio_r_valid : in std_logic;
    io_mmio_r_bits_resp : in std_logic_vector(1 downto 0);
    io_mmio_r_bits_data : in std_logic_vector(MEM_DATA_BITS-1 downto 0);
    io_mmio_r_bits_last : in std_logic;
    io_mmio_r_bits_id : in std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
    io_mmio_r_bits_user : in std_logic
    --init : in std_logic
);
end component;

component RocketTile
port (
    clk : in std_logic;
    reset : in std_logic;
    io_cached_0_acquire_ready : in std_logic;
    io_cached_0_acquire_valid : out std_logic;
    io_cached_0_acquire_bits_addr_block : out std_logic_vector(25 downto 0);
    io_cached_0_acquire_bits_client_xact_id : out std_logic_vector(1 downto 0);
    io_cached_0_acquire_bits_addr_beat : out std_logic_vector(1 downto 0);
    io_cached_0_acquire_bits_is_builtin_type : out std_logic;
    io_cached_0_acquire_bits_a_type : out std_logic_vector(2 downto 0);
    io_cached_0_acquire_bits_union : out std_logic_vector(16 downto 0);
    io_cached_0_acquire_bits_data : out std_logic_vector(127 downto 0);
    io_cached_0_grant_ready : out std_logic;
    io_cached_0_grant_valid : in std_logic;
    io_cached_0_grant_bits_addr_beat : in std_logic_vector(1 downto 0);
    io_cached_0_grant_bits_client_xact_id : in std_logic_vector(1 downto 0);
    io_cached_0_grant_bits_manager_xact_id : in std_logic_vector(3 downto 0);
    io_cached_0_grant_bits_is_builtin_type : in std_logic;
    io_cached_0_grant_bits_g_type : in std_logic_vector(3 downto 0);
    io_cached_0_grant_bits_data : in std_logic_vector(127 downto 0);
    io_cached_0_probe_ready : out std_logic;
    io_cached_0_probe_valid : in std_logic;
    io_cached_0_probe_bits_addr_block : in std_logic_vector(25 downto 0);
    io_cached_0_probe_bits_p_type : in std_logic_vector(1 downto 0);
    io_cached_0_release_ready : in std_logic;
    io_cached_0_release_valid : out std_logic;
    io_cached_0_release_bits_addr_beat : out std_logic_vector(1 downto 0);
    io_cached_0_release_bits_addr_block : out std_logic_vector(25 downto 0);
    io_cached_0_release_bits_client_xact_id : out std_logic_vector(1 downto 0);
    io_cached_0_release_bits_r_type : out std_logic_vector(2 downto 0);
    io_cached_0_release_bits_voluntary : out std_logic;
    io_cached_0_release_bits_data : out std_logic_vector(127 downto 0);
    io_uncached_0_acquire_ready : in std_logic;
    io_uncached_0_acquire_valid : out std_logic;
    io_uncached_0_acquire_bits_addr_block : out std_logic_vector(25 downto 0);
    io_uncached_0_acquire_bits_client_xact_id : out std_logic_vector(1 downto 0);
    io_uncached_0_acquire_bits_addr_beat : out std_logic_vector(1 downto 0);
    io_uncached_0_acquire_bits_is_builtin_type : out std_logic;
    io_uncached_0_acquire_bits_a_type : out std_logic_vector(2 downto 0);
    io_uncached_0_acquire_bits_union : out std_logic_vector(16 downto 0);
    io_uncached_0_acquire_bits_data : out std_logic_vector(127 downto 0);
    io_uncached_0_grant_ready : out std_logic;
    io_uncached_0_grant_valid : in std_logic;
    io_uncached_0_grant_bits_addr_beat : in std_logic_vector(1 downto 0);
    io_uncached_0_grant_bits_client_xact_id : in std_logic_vector(1 downto 0);
    io_uncached_0_grant_bits_manager_xact_id : in std_logic_vector(3 downto 0);
    io_uncached_0_grant_bits_is_builtin_type : in std_logic;
    io_uncached_0_grant_bits_g_type : in std_logic_vector(3 downto 0);
    io_uncached_0_grant_bits_data : in std_logic_vector(127 downto 0);
    io_host_reset : in std_logic;
    io_host_id : in std_logic;
    io_host_csr_req_ready : out std_logic;
    io_host_csr_req_valid : in std_logic;
    io_host_csr_req_bits_rw : in std_logic;
    io_host_csr_req_bits_addr : in std_logic_vector(11 downto 0);
    io_host_csr_req_bits_data : in std_logic_vector(63 downto 0);
    io_host_csr_resp_ready : in std_logic;
    io_host_csr_resp_valid : out std_logic;
    io_host_csr_resp_bits : out std_logic_vector(63 downto 0);
    io_host_debug_stats_csr : out std_logic
);
end component;

--! HostIO tile input signals
type host_in_type is  record
    reset : std_logic;
    id : std_logic;
    csr_req_valid : std_logic;
    csr_req_bits_rw : std_logic;
    csr_req_bits_addr : std_logic_vector(11 downto 0);
    csr_req_bits_data : std_logic_vector(63 downto 0);
    csr_resp_ready : std_logic;
end record;

--! HostIO tile output signals
type host_out_type is record
    csr_req_ready : std_logic;
    csr_resp_valid : std_logic;
    csr_resp_bits : std_logic_vector(63 downto 0);
    debug_stats_csr : std_logic;
end record;


--! @brief NoC global reset former.
--! @details This module produces output reset signal in a case if
--!          button 'Reset' was pushed or PLL isn't a 'lock' state.
--! param[in]  inSysReset Button generated signal
--! param[in]  inSysClk Clock from the PLL. Bus clock.
--! param[in]  inPllLock PLL status.
--! param[out] outReset Output reset signal with active 'High' (1 = reset).
component reset_global
port (
  inSysReset  : in std_ulogic;
  inSysClk    : in std_ulogic;
  inPllLock   : in std_ulogic;
  outReset    : out std_ulogic );
end component;


--! @brief Input signals of the Starter component.
type starter_in_type is record
   in_ready  : std_logic;
   out_valid : std_logic;
   out_bits  : std_logic_vector(HTIF_WIDTH-1 downto 0);
end record;

--! @brief Output signals of the Starter component.
type starter_out_type is record
   in_valid  : std_logic;
   in_bits   : std_logic_vector(HTIF_WIDTH-1 downto 0);
   out_ready : std_logic;
   exit_t    : std_logic_vector(31 downto 0);
end record;

--! @brief   Rocket Cores hard-reset initialization module
--! @details Everytime after hard reset Rocket core is in resetting
--!          state. Module Uncore::HTIF implements writting into 
--!          MRESET CSR-register (0x784) and not allowed to CPU start
--!          execution. This reseting cycle is continuing upto external
--!          write 0-value into this MRESET register.
--! param[in] clk  Clock sinal for the HTIFIO bus.
--! param[in] nrst Module reset signal with the active Low level.
--! param[in] i    Input interconnect signals.
--! param[out] o   Output interconnect signals.
component Starter
port (
    clk   : in std_logic;
    nrst  : in std_logic;
    i     : in starter_in_type;
    o     : out starter_out_type
);
end component;

component NastiArbiter is
  port (
    clk  : in  std_logic;
    i    : in  nasti_slaves_out_vector;
    o    : out nasti_slave_out_type
  );
end component;

component TileBridgeArbiter is
  port (
    i_cached    : in  nasti_slave_in_type;
    i_uncached  : in  nasti_slave_in_type;
    o           : out nasti_slave_in_type
  );
end component;  



--! Boot ROM with AXI4 interface declaration.
component nasti_bootrom is
  generic (
    memtech  : integer := inferred;
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#;
    sim_hexfile : string
  );
  port (
    clk  : in std_logic;
    nrst : in std_logic;
    cfg  : out nasti_slave_config_type;
    i    : in  nasti_slave_in_type;
    o    : out nasti_slave_out_type
  );
end component;

  component nasti_romimage is
  generic (
    memtech  : integer := inferred;
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#;
    sim_hexfile : string
  );
  port (
    clk  : in std_logic;
    nrst : in std_logic;
    cfg  : out nasti_slave_config_type;
    i    : in  nasti_slave_in_type;
    o    : out nasti_slave_out_type
  );
  end component; 

--! Internal RAM with AXI4 interface declaration.
component nasti_sram is
  generic (
    memtech  : integer := inferred;
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#;
    abits    : integer := 17;
    init_file : string := "" -- only for 'inferred'
  );
  port (
    clk  : in std_logic;
    nrst : in std_logic;
    cfg  : out nasti_slave_config_type;
    i    : in  nasti_slave_in_type;
    o    : out nasti_slave_out_type
  );
end component; 


--! @brief NASTI (AXI4) GPIO controller
component nasti_gpio is
  generic (
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#
  );
  port (
    clk  : in std_logic;
    nrst : in std_logic;
    cfg  : out nasti_slave_config_type;
    i    : in  nasti_slave_in_type;
    o    : out nasti_slave_out_type;
    i_dip : in std_logic_vector(3 downto 0);
    o_led : out std_logic_vector(7 downto 0)
  );
end component; 

type uart_in_type is record
  rd   	: std_ulogic;
  cts   : std_ulogic;
end record;

type uart_out_type is record
  td   	: std_ulogic;
  rts   : std_ulogic;
end record;

component nasti_uart is
  generic (
    xindex  : integer := 0;
    xaddr   : integer := 0;
    xmask   : integer := 16#fffff#;
    fifosz  : integer := 16;
    parity_bit : integer := 1
  );
  port (
    clk    : in  std_logic;
    nrst   : in  std_logic;
    cfg    : out  nasti_slave_config_type;
    i_uart : in  uart_in_type;
    o_uart : out uart_out_type;
    i_axi  : in  nasti_slave_in_type;
    o_axi  : out nasti_slave_out_type);
end component;

component nasti_irqctrl is
  generic (
    xindex   : integer := 0;
    xaddr    : integer := 0;
    xmask    : integer := 16#fffff#;
    L2_ena   : boolean := false
  );
  port 
 (
    clk    : in std_logic;
    nrst   : in std_logic;
    i_irqs : in std_logic_vector(CFG_IRQ_TOTAL-1 downto 0);
    o_cfg  : out nasti_slave_config_type;
    i_axi  : in nasti_slave_in_type;
    o_axi  : out nasti_slave_out_type;
    i_host : in host_out_type;
    o_host : out host_in_type
  );
end component;

component nasti_gnssstub is
  generic (
    xindex  : integer := 0;
    xaddr   : integer := 0;
    xmask   : integer := 16#fffff#
  );
  port (
    clk  : in  std_logic;
    nrst : in  std_logic;
    cfg  : out nasti_slave_config_type;
    i    : in  nasti_slave_in_type;
    o    : out nasti_slave_out_type;
    irq  : out std_logic
  );
end component; 

component nasti_pnp is
  generic (
    xindex  : integer := 0;
    xaddr   : integer := 0;
    xmask   : integer := 16#fffff#;
    tech    : integer := 0
  );
  port (
    clk    : in  std_logic;
    nrst   : in  std_logic;
    cfgvec : in  nasti_slave_cfg_vector;
    cfg    : out  nasti_slave_config_type;
    i      : in  nasti_slave_in_type;
    o      : out nasti_slave_out_type
  );
end component; 

end; -- package declaration

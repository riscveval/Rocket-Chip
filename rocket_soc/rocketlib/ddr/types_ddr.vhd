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

  constant CFG_DDR_DQ_WIDTH : integer := 64;
  constant CFG_DDR_ROW_WIDTH : integer := 13;
  constant CFG_DDR_BANK_WIDTH : integer := 3;
  constant CFG_DDR_DQS_WIDTH : integer := 8;
  constant CFG_DDR_CS_WIDTH : integer := 1;
  constant CFG_DDR_nCS_PER_RANK : integer := 1;
  constant CFG_DDR_CKE_WIDTH : integer := 1;
  constant CFG_DDR_DM_WIDTH : integer := 8;
  constant CFG_DDR_CK_WIDTH : integer := 1;

  type ddr3_io_type is record
    dq  : std_logic_vector(CFG_DDR_DQ_WIDTH-1 downto 0);
    dqs_p : std_logic_vector(CFG_DDR_DQS_WIDTH-1 downto 0);
    dqs_n : std_logic_vector(CFG_DDR_DQS_WIDTH-1 downto 0);
  end record;

  type ddr3_out_type is record
    addr    : std_logic_vector(CFG_DDR_ROW_WIDTH-1 downto 0);
    ba      : std_logic_vector(CFG_DDR_BANK_WIDTH-1 downto 0);
    ras_n   : std_logic;
    cas_n   : std_logic;
    we_n    : std_logic;
    reset_n : std_logic;
    cs_n    : std_logic_vector((CFG_DDR_CS_WIDTH*CFG_DDR_nCS_PER_RANK)-1 downto 0);
    odt     : std_logic_vector((CFG_DDR_CS_WIDTH*CFG_DDR_nCS_PER_RANK)-1 downto 0);
    cke     : std_logic_vector(CFG_DDR_CKE_WIDTH-1 downto 0);
    dm      : std_logic_vector(CFG_DDR_DM_WIDTH-1 downto 0);
    ck_p    : std_logic_vector(CFG_DDR_CK_WIDTH-1 downto 0);
    ck_n    : std_logic_vector(CFG_DDR_CK_WIDTH-1 downto 0);

    phy_init_done : std_logic;
  end record;


  component ddr_axi4 is
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
  end component;


end; -- package body

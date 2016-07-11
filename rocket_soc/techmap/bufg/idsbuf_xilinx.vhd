----------------------------------------------------------------------------
--! @file
--! @copyright  Copyright 2015 GNSS Sensor Ltd. All right reserved.
--! @author     Sergey Khabarov
--! @brief      Input buffer with the differential signals.
----------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library unisim;
use unisim.vcomponents.all;

entity idsbuf_xilinx is
  port (
    clk_p : in std_logic;
    clk_n : in std_logic;
    o_clk  : out std_logic
  );
end; 
 
architecture rtl of idsbuf_xilinx is
  signal ibufg : std_logic;
begin

  x1 : IBUFGDS  port map (
     I     => clk_p,
     IB    => clk_n,
     O     => ibufg
  );

  -- IBUFGDS intends to drive global clockdirectly but 
  --          DDR example uses such cascade chaining.
  x2 : BUFG port map (
     O => o_clk,
     I => ibufg
  );

end;

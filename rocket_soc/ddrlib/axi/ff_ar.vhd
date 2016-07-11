library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
library ambalib;
use ambalib.types_amba4.all;

entity ff_ar is
  port (
     rstn : in std_logic;
     clk_slow : in std_logic;
     clk_fast : in std_logic;  
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
end entity ff_ar;

architecture arch_ff_ar of ff_ar is
  type registers_fast is record
     clk_slow : std_logic;
     valid : std_logic;
     bits  : nasti_metadata_type;
     id    : std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     user  : std_logic;
     ready : std_logic;
     wait_ready : std_logic;
     skip_next : std_logic;
  end record;

  signal rin, r : registers_fast;
begin

  comb0 : process (rstn, r, clk_slow, slow_ar_valid, fast_ar_ready,
                   slow_ar_bits, slow_ar_id, slow_ar_user)
    variable slow_negedge : std_logic;
    variable v : registers_fast;
  begin
      v := r;

      v.clk_slow := clk_slow;
      slow_negedge := not clk_slow and r.clk_slow;

      if slow_negedge = '1' then
          v.ready := fast_ar_ready or r.wait_ready;
          v.wait_ready := '0';
    
          v.valid := slow_ar_valid and not r.skip_next;
          v.bits := slow_ar_bits;
          v.id   := slow_ar_id;
          v.user := slow_ar_user;
      end if;
     
      if fast_ar_ready = '1' and r.valid = '1' then
          v.valid := '0';
          v.wait_ready := not slow_negedge;
          v.skip_next := not r.ready;
      end if;

      if rstn = '0' then
         v.clk_slow := '0';
         v.valid := '0';
         v.bits := META_NONE;
         v.ready := '0';
         v.wait_ready := '0';
         v.skip_next := '0';
      end if;

      rin <= v;

      slow_ar_ready <= r.ready;
      fast_ar_valid <= r.valid;
      fast_ar_bits  <= r.bits;
      fast_ar_id    <= r.id;
      fast_ar_user  <= r.user;
  end process;

  cklf : process (clk_fast)
  begin
    if rising_edge(clk_fast) then
        r <= rin;
    end if;
  end process;

end architecture arch_ff_ar;

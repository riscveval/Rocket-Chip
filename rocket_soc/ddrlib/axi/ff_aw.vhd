library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
library ambalib;
use ambalib.types_amba4.all;

entity ff_aw is
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
end entity ff_aw;

architecture arch_ff_aw of ff_aw is
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

  comb0 : process (rstn, r, clk_slow, slow_aw_valid, fast_aw_ready,
                   slow_aw_bits, slow_aw_id, slow_aw_user)
    variable slow_negedge : std_logic;
    variable v : registers_fast;
  begin
      v := r;

      v.clk_slow := clk_slow;
      slow_negedge := not clk_slow and r.clk_slow;

      if slow_negedge = '1' then
          v.ready := fast_aw_ready or r.wait_ready;
          v.wait_ready := '0';
    
          v.valid := slow_aw_valid and not r.skip_next;
          v.bits := slow_aw_bits;
          v.id   := slow_aw_id;
          v.user := slow_aw_user;
      end if;
      if fast_aw_ready = '1' and r.valid = '1' then
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

      slow_aw_ready <= r.ready;
      fast_aw_valid <= r.valid;
      fast_aw_bits  <= r.bits;
      fast_aw_id    <= r.id;
      fast_aw_user  <= r.user;
  end process;

  cklf : process (clk_fast)
  begin
    if rising_edge(clk_fast) then
        r <= rin;
    end if;
  end process;

end architecture arch_ff_aw;

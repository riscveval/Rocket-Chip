library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
library ambalib;
use ambalib.types_amba4.all;

entity ff_b is
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
end entity ff_b;

architecture arch_ff_b of ff_b is
  type registers_fast is record
     clk_slow : std_logic;
     valid : std_logic;
     wait_valid : std_logic;
     resp : std_logic_vector(1 downto 0);
     id   : std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     user : std_logic;
  end record;

  signal rin, r : registers_fast;
begin

  comb0 : process (rstn, clk_slow, r, fast_b_valid, slow_b_ready,
                   fast_b_resp, fast_b_id, fast_b_user)
    variable slow_negedge : std_logic;
    variable v : registers_fast;
  begin
      v := r;

      v.clk_slow := clk_slow;
      slow_negedge := not clk_slow and r.clk_slow;

      if slow_negedge = '1' then
          v.valid := fast_b_valid or r.wait_valid;
          v.wait_valid := '0';
      end if;

      if fast_b_valid = '1' then 
         v.wait_valid := not slow_negedge;
         v.resp  := fast_b_resp;
         v.id    := fast_b_id;
         v.user  := '0';
      end if;

      if rstn = '0' then
         v.clk_slow := '0';
         v.valid := '0';
         v.wait_valid := '0';
         v.resp := (others => '0');
         v.id := (others => '0');
         v.user := '0';
      end if;

      rin <= v;

      fast_b_ready <= '1';
      slow_b_valid <= r.valid;
      slow_b_resp  <= r.resp;
      slow_b_id    <= r.id;
      slow_b_user  <= r.user;
  end process;

  cklf : process (clk_fast)
  begin
    if rising_edge(clk_fast) then
        r <= rin;
    end if;
  end process;

end architecture arch_ff_b;

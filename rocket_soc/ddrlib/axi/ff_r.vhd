library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
library ambalib;
use ambalib.types_amba4.all;

entity ff_r is
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
end entity ff_r;

architecture arch_ff_r of ff_r is
  type registers_fast is record
     clk_slow : std_logic;
     valid : std_logic;
     wait_valid : std_logic;
     resp : std_logic_vector(1 downto 0);
     data : std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
     last : std_logic;
     id   : std_logic_vector(CFG_ROCKET_ID_BITS-1 downto 0);
     user : std_logic;
  end record;

  signal rin, r : registers_fast;
begin

  comb0 : process (rstn, r, clk_slow, slow_r_ready, fast_r_valid, fast_r_resp,
                   fast_r_data, fast_r_last, fast_r_id, fast_r_user)
    variable v : registers_fast;
    variable slow_negedge : std_logic;
  begin
      v := r;

      v.clk_slow := clk_slow;
      slow_negedge := not clk_slow and r.clk_slow;

      if slow_negedge = '1' then
         v.valid := fast_r_valid or r.wait_valid;
         v.wait_valid := '0';
      end if;
      
      if fast_r_valid = '1' then 
         v.wait_valid := not slow_negedge;
         v.resp  := fast_r_resp;
         v.data  := fast_r_data;
         v.last  := fast_r_last;
         v.id    := fast_r_id;
         v.user  := fast_r_user;
      end if;

      if rstn = '0' then
         v.clk_slow := '0';
         v.resp  := (others => '0');
         v.data  := (others => '0');
         v.last  := '0';
         v.id    := (others => '0');
         v.user  := '0';
         v.valid := '0';
         v.wait_valid := '0';
      end if;

      rin <= v;

      slow_r_valid <= r.valid;
      slow_r_resp  <= r.resp;
      slow_r_data  <= r.data;
      slow_r_last  <= r.last;
      slow_r_id    <= r.id;
      slow_r_user  <= r.user;
      fast_r_ready <= '1';

  end process;

  cklf : process (clk_fast)
  begin
    if rising_edge(clk_fast) then
        r <= rin;
    end if;
  end process;

end architecture arch_ff_r;

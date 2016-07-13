library ieee;
library unisim;
use ieee.std_logic_1164.all;
use unisim.vcomponents.all;
use ieee.numeric_std.all;
library ambalib;
use ambalib.types_amba4.all;

entity ff_w is
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
end entity ff_w;

architecture arch_ff_w of ff_w is
  type registers_fast is record
     clk_slow : std_logic;
     valid : std_logic;
     data : std_logic_vector(CFG_NASTI_DATA_BITS-1 downto 0);
     last : std_logic;
     strb : std_logic_vector(CFG_NASTI_DATA_BYTES-1 downto 0);
     user : std_logic;
     ready : std_logic;
     wait_ready : std_logic;
     was_accepted : std_logic;
  end record;

  signal rin, r : registers_fast;
begin

  comb0 : process (rstn, clk_slow, r, slow_w_valid, fast_w_ready,
                   slow_w_data, slow_w_last, slow_w_strb, slow_w_user)
    variable slow_negedge : std_logic;
    variable v : registers_fast;
  begin
      v := r;

      v.clk_slow := clk_slow;
      slow_negedge := not clk_slow and r.clk_slow;

      if slow_negedge = '1' then
          v.ready := fast_w_ready or r.wait_ready;
          v.wait_ready := '0';
    
          v.was_accepted := slow_w_last and slow_w_valid;
          v.valid := slow_w_valid and not r.was_accepted;
          v.data := slow_w_data;
          v.last := slow_w_last;
          v.strb := slow_w_strb;
          v.user := slow_w_user;
      end if;
      
      if fast_w_ready = '1' and r.valid = '1' then
          v.valid := '0';
          v.wait_ready := not slow_negedge;
      end if;


   

      if rstn = '0' then
         v.clk_slow := '0';
         v.valid := '0';
         v.data := (others => '0');
         v.last := '0';
         v.strb := (others => '0');
         v.user := '0';
         v.ready := '0';
         v.wait_ready := '0';
         v.was_accepted := '0';
      end if;

      rin <= v;

      slow_w_ready <= r.ready;
      fast_w_valid <= r.valid;
      fast_w_data  <= r.data;
      fast_w_last  <= r.last;
      fast_w_strb  <= r.strb;
      fast_w_user  <= r.user;
  end process;

  cklf : process (clk_fast)
  begin
    if rising_edge(clk_fast) then
        r <= rin;
    end if;
  end process;

end architecture arch_ff_w;

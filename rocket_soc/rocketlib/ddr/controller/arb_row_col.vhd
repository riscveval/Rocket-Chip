
library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
--   use ieee.numeric_std.all;
   use ieee.std_logic_arith.all;


-- This block receives request to send row and column commands and
-- requests to change the IO configuration.  These requests come
-- the individual bank machines.  The arbitration winner is selected
-- and driven back to the bank machines.
--
-- The CS enables are generated.  For 2:1 mode, row commands are sent
-- in the "0" phase, and column commands are sent in the "1" phase.
--
-- In 2T mode, a further arbitration is performed between the row
-- and column commands.  The winner of this arbitration inhibits
-- arbitration by the loser.  The winner is allowed to arbitrate, the loser is
-- blocked until the next state.  The winning address command
-- is repeated on both the "0" and the "1" phases and the CS
-- is asserted for just the "1" phase.

entity arb_row_col is
   generic (
      TCQ                      : integer := 100;
      ADDR_CMD_MODE            : string := "1T";
      EARLY_WR_DATA_ADDR       : string := "OFF";
      nBANK_MACHS              : integer := 4;
      nCK_PER_CLK              : integer := 2;
      nCNFG2WR                 : integer := 2
   );
   port (
      -- Give column command priority whenever previous state has no row request.
      
      -- Row address/command arbitration.
      grant_row_r              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      sent_row                 : out std_logic;
      
      sending_row              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      
      -- IO config arbitration.
      grant_config_r           : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      
      io_config_strobe_ns      : out std_logic;
      
      io_config_strobe         : out std_logic;

	  force_io_config_rd_r1    : out std_logic;
      
      -- Generate io_config_valid.
      io_config_valid_r        : out std_logic;
      
      -- Column address/command arbitration.
      grant_col_r              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      
      sending_col              : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      sent_col                 : out std_logic;
      
      -- If we need early wr_data_addr because ECC is on, arbitrate
      -- to see which bank machine might sent the next wr_data_addr;
      grant_col_wr             : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      -- block: early_wr_addr_arb_on
      
      send_cmd0_col            : out std_logic;         --= 1'b0;
      send_cmd1_row            : out std_logic;         -- = 1'b0;
      
      cs_en0                   : out std_logic;         --= 1'b0;
      cs_en1                   : out std_logic;         -- = 1'b0;
      
      insert_maint_r1          : out std_logic;
      clk                      : in std_logic;
      rst                      : in std_logic;
      rts_row                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      insert_maint_r           : in std_logic;
      rts_col                  : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      rtc                      : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      force_io_config_rd_r     : in std_logic;
      col_rdy_wr               : in std_logic_vector(nBANK_MACHS - 1 downto 0)
   );
end entity arb_row_col;

architecture trans of arb_row_col is


function REDUCTION_OR( A: in std_logic_vector) return std_logic is
  variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp or A(i);
  end loop;
  return tmp;
end function REDUCTION_OR;


component round_robin_arb 
   generic (
      TCQ              : integer := 100;
      WIDTH            : integer := 3
   );
   port (
      
      grant_ns         : out std_logic_vector(WIDTH - 1 downto 0);
      
      grant_r          : out std_logic_vector(WIDTH - 1 downto 0);
      clk              : in std_logic;
      rst              : in std_logic;
      req              : in std_logic_vector(WIDTH - 1 downto 0);
      disable_grant    : in std_logic;
      
      current_master   : in std_logic_vector(WIDTH - 1 downto 0);
      upd_last_master  : in std_logic
   );
end component;







   signal io_config_strobe_r        : std_logic;
   signal block_grant_row           : std_logic;
   signal block_grant_col           : std_logic;
   signal io_config_kill_rts_col    : std_logic;
   signal col_request               : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal granted_col_ns            : std_logic;
   signal row_request               : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal granted_row_ns            : std_logic;
   signal grant_row_r_lcl           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal granted_row_r             : std_logic;
   signal sent_row_lcl              : std_logic;
   signal grant_config_r_lcl        : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal upd_io_config_last_master : std_logic;
   signal io_config_strobe_ns_lcl   : std_logic;
   signal force_io_config_rd_r1_lcl : std_logic;
   signal io_config_valid_r_lcl     : std_logic;
   signal io_config_valid_ns        : std_logic;
   signal grant_col_r_lcl           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal granted_col_r             : std_logic;
   signal sent_col_lcl              : std_logic;
   signal insert_maint_r1_lcl       : std_logic;
   
   signal sent_row_or_maint         : std_logic;
   -- X-HDL generated signals

   signal i2 : std_logic_vector(1 downto 0);
   signal nBANK_MACHS_insert_maint : std_logic_vector(nBANK_MACHS - 1 downto 0); -- intermediate value
   signal col_req_tmp           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal col_req_tmp2           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal sending_row_tmp        : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal sending_col_tmp        : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal row_col_grant          : std_logic_vector(1 downto 0); 
   signal current_master         : std_logic_vector(1 downto 0);
   signal upd_last_master        : std_logic;
   -- Declare intermediate signals for referenced outputs
   signal grant_col_wr_raw           : std_logic_vector(nBANK_MACHS - 1 downto 0);
begin
   -- Drive referenced outputs
   grant_col_wr <= grant_col_wr_raw;
   io_config_kill_rts_col <= '0' when (nCNFG2WR = 1) else
                             io_config_strobe_r;
   granted_col_ns <= REDUCTION_OR(col_request);

   
    process(insert_maint_r)
      begin
      for i in 0 to nBANK_MACHS - 1  loop
        nBANK_MACHS_insert_maint(i) <= not(insert_maint_r);
      end loop;
      
      end process;

   row_request <= rts_row and nBANK_MACHS_insert_maint;
   
   granted_row_ns <= REDUCTION_OR(row_request);
   
   
    process(insert_maint_r,io_config_kill_rts_col)
      begin
      for i in 0 to nBANK_MACHS - 1  loop
        col_req_tmp(i) <= not(io_config_kill_rts_col or insert_maint_r);
      end loop;
      
      end process;
   
   row_col_2T_arb : if (ADDR_CMD_MODE = "2T") generate
      col_request <= rts_col and col_req_tmp;
      
      
      
      current_master <= "10" when ((not(granted_row_ns)) = '1') else
                        row_col_grant;
      upd_last_master <= not(granted_row_ns) or REDUCTION_OR(row_col_grant);
      
      
      i2 <= (granted_row_ns & granted_col_ns);
      
      row_col_arb0 : round_robin_arb
         generic map (
            width  => 2
         )
         port map (
           grant_ns         => open,
            grant_r          => row_col_grant,
            upd_last_master  => upd_last_master,
            current_master   => current_master,
            clk              => clk,
            rst              => rst,
            req              => i2,
            disable_grant    => '0'
         );
      (block_grant_col, block_grant_row) <= row_col_grant;
   end generate;
   
   
    process(io_config_kill_rts_col)
    begin
    for i in 0 to nBANK_MACHS - 1  loop
      col_req_tmp2(i) <= not(io_config_kill_rts_col);
    end loop;
    
    end process;
 
   row_col_1T_arb : if (not (ADDR_CMD_MODE = "2T")) generate
      col_request <= rts_col and col_req_tmp2;
      block_grant_row <= '0';
      block_grant_col <= '0';
   end generate;
   grant_row_r <= grant_row_r_lcl;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         granted_row_r <= granted_row_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   sent_row_lcl <= granted_row_r and not(block_grant_row);
   sent_row <= sent_row_lcl;
   
   
   row_arb0 :round_robin_arb
      generic map (
         width  => nBANK_MACHS
      )
      port map (
         grant_ns         => open,
         grant_r          => grant_row_r_lcl(nBANK_MACHS - 1 downto 0),
         upd_last_master  => sent_row_lcl,
         current_master   => grant_row_r_lcl(nBANK_MACHS - 1 downto 0),
         clk              => clk,
         rst              => rst,
         req              => row_request,
         disable_grant    => '0'
      );
      
    process(block_grant_row)
      begin
      for i in 0 to nBANK_MACHS - 1  loop
        sending_row_tmp(i) <= not(block_grant_row);
      end loop;
      
      end process;
   
      
   sending_row <= grant_row_r_lcl and sending_row_tmp;
   grant_config_r <= grant_config_r_lcl;
   
   
   config_arb0 : round_robin_arb
      generic map (
         width  => nBANK_MACHS
      )
      port map (
         grant_ns         => open,
         grant_r          => grant_config_r_lcl(nBANK_MACHS - 1 downto 0),
         upd_last_master  => upd_io_config_last_master,
         current_master   => grant_config_r_lcl(nBANK_MACHS - 1 downto 0),
         clk              => clk,
         rst              => rst,
         req              => rtc(nBANK_MACHS - 1 downto 0),
         disable_grant    => '0'
      );
   io_config_strobe_ns_lcl <= not(io_config_strobe_r) and (REDUCTION_OR(rtc) or force_io_config_rd_r) and not(granted_col_ns);
   io_config_strobe_ns <= io_config_strobe_ns_lcl;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         io_config_strobe_r <= io_config_strobe_ns_lcl after (TCQ)*1 ps;
      end if;
   end process;
   
   io_config_strobe <= io_config_strobe_r;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         force_io_config_rd_r1_lcl <= force_io_config_rd_r after (TCQ)*1 ps;
      end if;
   end process;

   force_io_config_rd_r1 <= force_io_config_rd_r1_lcl;
   
   upd_io_config_last_master <= io_config_strobe_r and not(force_io_config_rd_r1_lcl);
   io_config_valid_ns <= not(rst) and (io_config_valid_r_lcl or io_config_strobe_ns_lcl);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         io_config_valid_r_lcl <= io_config_valid_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   io_config_valid_r <= io_config_valid_r_lcl;
   grant_col_r <= grant_col_r_lcl;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         granted_col_r <= granted_col_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   
   
   col_arb0 : round_robin_arb
      generic map (
         width  => nBANK_MACHS
      )
      port map (
         grant_ns         => open,
         grant_r          => grant_col_r_lcl(nBANK_MACHS - 1 downto 0),
         upd_last_master  => sent_col_lcl,
         current_master   => grant_col_r_lcl(nBANK_MACHS - 1 downto 0),
         clk              => clk,
         rst              => rst,
         req              => col_request,
         disable_grant    => '0'
      );
      
   
    process(block_grant_col)
      begin
      for i in 0 to nBANK_MACHS - 1  loop
        sending_col_tmp(i) <= not(block_grant_col);
      end loop;
      
      end process;
      
   sending_col <= grant_col_r_lcl and sending_col_tmp;
   sent_col_lcl <= granted_col_r and not(block_grant_col);
   sent_col <= sent_col_lcl;
   early_wr_addr_arb_off : if (EARLY_WR_DATA_ADDR = "OFF") generate
      grant_col_wr_raw <= (others => '0' );
   end generate;
   early_wr_addr_arb_on : if (not (EARLY_WR_DATA_ADDR = "OFF")) generate
      
	signal grant_col_wr_r : std_logic_vector (nBANK_MACHS - 1 downto 0);
	signal grant_col_wr_ns : std_logic_vector (nBANK_MACHS - 1 downto 0);
	signal grant_col_wr_raw_temp : std_logic_vector (nBANK_MACHS - 1 downto 0);
     begin 
      col_arb1 : round_robin_arb
         generic map (
            width  => nBANK_MACHS
         )
         port map (
            grant_ns         => grant_col_wr_raw_temp,
            grant_r          => open,
            upd_last_master  => sent_col_lcl,
            current_master   => grant_col_r_lcl(nBANK_MACHS - 1 downto 0),
            clk              => clk,
            rst              => rst,
            req              => col_rdy_wr,
            disable_grant    => '0'
         );

	grant_col_wr_ns <= grant_col_wr_raw_temp when ( granted_col_ns = '1') else grant_col_wr_r;
	process (clk)
	begin
		if ( clk'event and clk = '1') then
			grant_col_wr_r <= grant_col_wr_ns after (TCQ)*1 ps;
		end if;
	end process;
	grant_col_wr_raw <= grant_col_wr_ns;
   end generate;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         insert_maint_r1_lcl <= insert_maint_r after (TCQ)*1 ps;
      end if;
   end process;
   
   insert_maint_r1 <= insert_maint_r1_lcl;
   sent_row_or_maint <= sent_row_lcl or insert_maint_r1_lcl;
   
   two_one_not2T: if (nCK_PER_CLK = 2 and (not(ADDR_CMD_MODE = "2T"))) generate
                  
                    cs_en0 <= sent_row_or_maint; 
                    cs_en1 <= sent_col_lcl;
                    send_cmd0_col <= '0';
                    send_cmd1_row <= '0';
   end generate; 
   two_one_2T: if (nCK_PER_CLK = 2 and ADDR_CMD_MODE = "2T")  generate
                    cs_en1 <= sent_row_or_maint or sent_col_lcl;
                    send_cmd0_col <= sent_col_lcl;
                    send_cmd1_row <= sent_row_or_maint;
                    cs_en0 <= '0'; 
   end generate;

   other_cases: if ( not( (nCK_PER_CLK = 2 and ADDR_CMD_MODE = "2T") or (nCK_PER_CLK = 2 and (not(ADDR_CMD_MODE = "2T"))) ) ) generate
                    cs_en0 <= '0'; 
                    cs_en1 <= '0';
                    send_cmd0_col <= '0';
                    send_cmd1_row <= '0';
   end generate;
   
                   
end architecture trans;







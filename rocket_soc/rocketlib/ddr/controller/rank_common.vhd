--*****************************************************************************
-- (c) Copyright 2009 - 2010 Xilinx, Inc. All rights reserved.
--
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
--
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
--
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
--
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--
--*****************************************************************************
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor                : Xilinx
-- \   \   \/     Version               : 3.92
--  \   \         Application           : MIG
--  /   /         Filename              : rank_common.vhd
-- /___/   /\     Date Last Modified    : $date$
-- \   \  /  \    Date Created          : Wed Jun 17 2009
--  \___\/\___\
--
--Device            : Virtex-6
--Design Name       : DDR3 SDRAM
--Purpose           :
--Reference         :
--Revision History  :
--*****************************************************************************

library ieee;
   use ieee.std_logic_1164.all;
   use ieee.std_logic_unsigned.all;
   --use ieee.std_logic_arith.all;
   use ieee.numeric_std.all;


-- Block for logic common to all rank machines. Contains
-- a clock prescaler, and arbiters for refresh and periodic
-- read functions.

entity rank_common is
   generic (
      TCQ                        : integer := 100;
      DRAM_TYPE                  : string := "DDR3";
      MAINT_PRESCALER_DIV        : integer := 40;
      nBANK_MACHS                : integer := 4;
      RANK_WIDTH                 : integer := 2;
      RANKS                      : integer := 4;
      REFRESH_TIMER_DIV          : integer := 39;                                                                                                                                                                                                                                                                                                                                                                                                                       
      ZQ_TIMER_DIV               : integer := 640000
   );
   port (
      -- Outputs
      -- Inputs
      
      -- ceiling logb2
      
      -- Maintenance and periodic read prescaler.  Nominally 200 nS.
      --clogb2(MAINT_PRESCALER_DIV + 1);
      
      maint_prescaler_tick_r     : out std_logic;
      
      -- Refresh timebase.  Nominically 7800 nS.
      refresh_tick               : out std_logic;
      
     
      -- block: maintenance_request
      maint_zq_r                 : out std_logic;
      maint_req_r                : out std_logic;
      maint_rank_r               : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      
      -- Periodic reads to maintain PHY alignment.
      -- Demand insertion of periodic read as soon as
      -- possible.  Since the is a single rank, bank compare mechanism
      -- must be used, periodic reads must be forced in at the
      -- expense of not accepting a normal request.
      
      clear_periodic_rd_request  : out std_logic_vector(RANKS - 1 downto 0);
      
      -- Maintenance request pipeline.
      
      -- Arbitrate periodic read requests.
      -- Inputs
      
      -- Encode and set periodic read rank into periodic_rd_rank_r.
      
      -- Once the request is dropped in the queue, it might be a while before it
      -- emerges.  Can't clear the request based on seeing the read issued.
      -- Need to clear the request as soon as its made it into the queue.
      
      -- block: maintenance_request
      periodic_rd_r              : out std_logic;
      periodic_rd_rank_r         : out std_logic_vector(RANK_WIDTH - 1 downto 0);
      clk                        : in std_logic;
      rst                        : in std_logic;
      dfi_init_complete          : in std_logic;
      app_zq_req                 : in std_logic;
      insert_maint_r1            : in std_logic;
      refresh_request            : in std_logic_vector(RANKS - 1 downto 0);
      maint_wip_r                : in std_logic;
      slot_0_present             : in std_logic_vector(7 downto 0);
      slot_1_present             : in std_logic_vector(7 downto 0);
      periodic_rd_request        : in std_logic_vector(RANKS - 1 downto 0);
      periodic_rd_ack_r          : in std_logic
   );
end entity rank_common;

architecture trans of rank_common is

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



function nCOPY (A : in std_logic; B : in integer) return std_logic_vector is
variable tmp : std_logic_vector(B - 1 downto 0);
begin
    for i in 0 to B - 1  loop
      tmp(i) := A;
    end loop;
    return tmp;
end function nCOPY;





function clogb2(size: integer) return integer is
   variable tmp : integer := 1;
   variable tmp_size : std_logic_vector (31 downto 0);
begin
  tmp_size := std_logic_vector(TO_UNSIGNED((size - 1),32));
  while ( to_integer(UNSIGNED(tmp_size)) > 1 ) loop
    tmp_size := std_logic_vector(UNSIGNED(tmp_size) srl 1);
    tmp := tmp + 1;
  end loop;
  return tmp;
  --for i in 23 downto 0 loop  
  --  if( size <= 2** i) then 
  --  tmp := i; 
  --  end if;
  --end loop;
  --return tmp;
end function clogb2;


function BOOLEAN_TO_STD_LOGIC(A : in BOOLEAN) return std_logic is
begin
   if A = true then
       return '1';
   else
       return '0';
   end if;
end function BOOLEAN_TO_STD_LOGIC;

function REDUCTION_OR( A: in std_logic_vector) return std_logic is
  variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp or A(i);
  end loop;
  return tmp;
end function REDUCTION_OR;


   constant ONE                      : integer := 1;
   constant MAINT_PRESCALER_WIDTH    : integer := clogb2(MAINT_PRESCALER_DIV + 1);
   constant REFRESH_TIMER_WIDTH      : integer := clogb2(REFRESH_TIMER_DIV + 1);
   constant ZQ_TIMER_WIDTH           : integer := clogb2(ZQ_TIMER_DIV + 1);

   signal maint_prescaler_tick_r_lcl : std_logic;
   signal refresh_tick_lcl           : std_logic;
   signal maint_zq_r_lcl             : std_logic;
   signal zq_request                 : std_logic := '0';
   signal maint_req_r_lcl            : std_logic;
   signal maint_rank_r_lcl           : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal periodic_rd_r_lcl          : std_logic;
   signal periodic_rd_rank_r_lcl     : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal periodic_rd_rank_ns        : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal periodic_rd_grant_r        : std_logic_vector(RANKS - 1 downto 0);
   signal periodic_rd_grant_ns        : std_logic_vector(RANKS - 1 downto 0);
   signal maint_grant_ns        : std_logic_vector(RANKS  downto 0);
   signal maint_grant_r        : std_logic_vector(RANKS  downto 0);
   signal maint_rank_ns        : std_logic_vector(RANK_WIDTH - 1 downto 0);
   signal periodic_rd_busy             : std_logic;
   signal maint_zq_ns             : std_logic;
   signal upd_last_master_ns             : std_logic;
   signal upd_last_master_r             : std_logic;
   signal new_maint_rank_r             : std_logic;
   signal zq_timer_r        : std_logic_vector(ZQ_TIMER_WIDTH - 1 downto 0);
   signal zq_timer_ns        : std_logic_vector(ZQ_TIMER_WIDTH - 1 downto 0);
   signal refresh_timer_r               : std_logic_vector(REFRESH_TIMER_WIDTH - 1 downto 0);
   signal refresh_timer_ns               : std_logic_vector(REFRESH_TIMER_WIDTH - 1 downto 0);
   signal periodic_upd_last_master_ns : std_logic;  -- local signal in verilog code within periodic request
   signal periodic_upd_last_master_r : std_logic;

   signal maint_request               : std_logic_vector(RANKS downto 0);
   signal maint_busy             : std_logic;
   
   signal maint_prescaler_r             : std_logic_vector(MAINT_PRESCALER_WIDTH-1 downto 0);
   signal maint_prescaler_ns             : std_logic_vector(MAINT_PRESCALER_WIDTH-1 downto 0);
   signal maint_prescaler_tick_ns         : std_logic;
   signal zq_request_r             : std_logic;
   signal zq_request_ns             : std_logic;
   signal zq_tick             : std_logic := '0';
   signal zq_clears_zq_request : std_logic;
   signal present : std_logic_vector(7 downto 0);
   signal periodic_rd_ns : std_logic;
   signal int2 : std_logic;
   signal int3 : std_logic_vector(RANKS - 1 downto 0);
   
   
   signal tst_rdor_rd_request : std_logic;
   
begin
   maint_prescaler_tick_ns <= BOOLEAN_TO_STD_LOGIC(maint_prescaler_r = std_logic_vector(TO_UNSIGNED(1,MAINT_PRESCALER_WIDTH)));
   process (dfi_init_complete, maint_prescaler_r, maint_prescaler_tick_ns)
   begin
      maint_prescaler_ns <= maint_prescaler_r;
      if ((not(dfi_init_complete) or maint_prescaler_tick_ns) = '1') then
         maint_prescaler_ns <= std_logic_vector(TO_UNSIGNED(MAINT_PRESCALER_DIV,MAINT_PRESCALER_WIDTH));
      elsif ((REDUCTION_OR(maint_prescaler_r)) = '1') then
         maint_prescaler_ns <= maint_prescaler_r - std_logic_vector(TO_UNSIGNED(1,MAINT_PRESCALER_WIDTH));
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_prescaler_r <= maint_prescaler_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_prescaler_tick_r_lcl <= maint_prescaler_tick_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   maint_prescaler_tick_r <= maint_prescaler_tick_r_lcl;
   process (dfi_init_complete, maint_prescaler_tick_r_lcl, refresh_tick_lcl, refresh_timer_r)
   begin
      refresh_timer_ns <= refresh_timer_r;
      if ((not(dfi_init_complete) or refresh_tick_lcl) = '1') then
         refresh_timer_ns <= std_logic_vector(TO_UNSIGNED(REFRESH_TIMER_DIV,REFRESH_TIMER_WIDTH ));
      elsif ((REDUCTION_OR(refresh_timer_r) and maint_prescaler_tick_r_lcl) = '1') then
         refresh_timer_ns <= refresh_timer_r - std_logic_vector(TO_UNSIGNED(1,REFRESH_TIMER_WIDTH));
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         refresh_timer_r <= refresh_timer_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   refresh_tick_lcl <= BOOLEAN_TO_STD_LOGIC(refresh_timer_r = std_logic_vector(TO_UNSIGNED(1,REFRESH_TIMER_WIDTH ))) and maint_prescaler_tick_r_lcl;
   refresh_tick <= refresh_tick_lcl;
   int0 : if (DRAM_TYPE = "DDR3") generate
      int1 : if (ZQ_TIMER_DIV /= 0) generate
         process (dfi_init_complete, maint_prescaler_tick_r_lcl, zq_tick, zq_timer_r)
         variable zq_timer_ns_tmp : std_logic_vector(ZQ_TIMER_WIDTH - 1 downto 0);
         begin
            zq_timer_ns_tmp := zq_timer_r;
            if ((not(dfi_init_complete) or zq_tick) = '1') then
               zq_timer_ns_tmp := std_logic_vector(TO_UNSIGNED(ZQ_TIMER_DIV,ZQ_TIMER_WIDTH ));
            elsif ((REDUCTION_OR(zq_timer_r) and maint_prescaler_tick_r_lcl) = '1') then
               zq_timer_ns_tmp := zq_timer_r - std_logic_vector(TO_UNSIGNED(1,ZQ_TIMER_WIDTH ));
            end if;
            
            zq_timer_ns  <= zq_timer_ns_tmp ;
         end process;
         
         process (clk)
         begin
            if (clk'event and clk = '1') then
               zq_timer_r <= zq_timer_ns after (TCQ)*1 ps;
            end if;
         end process;
         
         process (maint_prescaler_tick_r_lcl, zq_timer_r)
         begin
            zq_tick <= (BOOLEAN_TO_STD_LOGIC(zq_timer_r = std_logic_vector(TO_UNSIGNED(1,ZQ_TIMER_WIDTH ))) and maint_prescaler_tick_r_lcl);
         end process;
         
      end generate;
      zq_clears_zq_request <= insert_maint_r1 and maint_zq_r_lcl;
      zq_request_ns <= not(rst) and BOOLEAN_TO_STD_LOGIC(DRAM_TYPE = "DDR3") and 
                      ((not(dfi_init_complete) and BOOLEAN_TO_STD_LOGIC(ZQ_TIMER_DIV /= 0)) or
                       (zq_request_r and not(zq_clears_zq_request)) or
                       zq_tick or 
                       (app_zq_req and dfi_init_complete));
      process (clk)
      begin
         if (clk'event and clk = '1') then
            zq_request_r <= zq_request_ns after (TCQ)*1 ps;
         end if;
      end process;
      
      process (dfi_init_complete, zq_request_r)
      begin
         zq_request <= dfi_init_complete and zq_request_r;
      end process;
      
   end generate;
   
   
   -- Maintenance_request
   
   
   maint_busy <= upd_last_master_r or new_maint_rank_r or maint_req_r_lcl or maint_wip_r;
   maint_request <= (zq_request & refresh_request(RANKS - 1 downto 0));
   upd_last_master_ns <= REDUCTION_OR(maint_request) and not(maint_busy);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         upd_last_master_r <= upd_last_master_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         new_maint_rank_r <= upd_last_master_r after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_req_r_lcl <= new_maint_rank_r after (TCQ)*1 ps;
      end if;
   end process;
   
   
   
   maint_arb0 : round_robin_arb
      generic map (
         WIDTH  => (RANKS + 1)
      )
      port map (
         grant_ns         => maint_grant_ns,
         grant_r          => maint_grant_r,
         upd_last_master  => upd_last_master_r,
         current_master   => maint_grant_r,
         req              => maint_request,
         disable_grant    => '0',
         clk              => clk,
         rst              => rst
      );
   present <= slot_0_present or slot_1_present;
   maint_zq_ns <= not(rst) and maint_grant_r(RANKS) when (upd_last_master_r = '1') else
                  not(rst) and maint_zq_r_lcl;
   process (maint_grant_r, maint_rank_r_lcl, maint_zq_ns, present, rst, upd_last_master_r)
   variable maint_rank_ns_tmp : std_logic_vector(RANK_WIDTH-1 downto 0);
   begin
      if (rst = '1') then
         maint_rank_ns_tmp := (others => '0' );
      else
         maint_rank_ns_tmp := maint_rank_r_lcl;
         if (maint_zq_ns = '1') then
            maint_rank_ns_tmp := maint_rank_r_lcl + std_logic_vector(TO_UNSIGNED(1,RANK_WIDTH ));
            for i in 0 to 7 loop
               if ((not(present(to_integer(UNSIGNED(maint_rank_ns_tmp))))) = '1') then
                  maint_rank_ns_tmp :=  maint_rank_ns_tmp + std_logic_vector(TO_UNSIGNED(1,RANK_WIDTH));
               end if;
            end loop;
         elsif (upd_last_master_r = '1') then
            for i in 0 to  RANKS - 1 loop
               if ((maint_grant_r(i)) = '1') then
                  maint_rank_ns_tmp := std_logic_vector(TO_UNSIGNED(i,RANK_WIDTH ));
               end if;
            end loop;
         end if;
      end if;
      maint_rank_ns <= maint_rank_ns_tmp;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_rank_r_lcl <= maint_rank_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_zq_r_lcl <= maint_zq_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   maint_zq_r <= maint_zq_r_lcl;
   maint_req_r <= maint_req_r_lcl;
   maint_rank_r <= maint_rank_r_lcl;
   
   
   -- generate : periodic_read_request
   
   periodic_rd_busy <= periodic_upd_last_master_r or periodic_rd_r_lcl;
 
   --upd_last_master_ns <= dfi_init_complete and (REDUCTION_OR(periodic_rd_request) and not(periodic_rd_busy));
   periodic_upd_last_master_ns <= dfi_init_complete and (REDUCTION_OR(periodic_rd_request) and not(periodic_rd_busy));

 process (clk)
   begin
      if (clk'event and clk = '1') then
         periodic_upd_last_master_r <= periodic_upd_last_master_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   periodic_rd_ns <= dfi_init_complete and (periodic_upd_last_master_r or (periodic_rd_r_lcl and not(periodic_rd_ack_r)));
   process (clk)
   begin
      if (clk'event and clk = '1') then
         periodic_rd_r_lcl <= periodic_rd_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   
   
   periodic_rd_arb0 : round_robin_arb
      generic map (
         WIDTH  => RANKS
      )
      port map (
         grant_ns         => periodic_rd_grant_ns(RANKS - 1 downto 0),
         grant_r          => open,
         upd_last_master  => periodic_upd_last_master_r,--upd_last_master_r,
         current_master   => periodic_rd_grant_r(RANKS - 1 downto 0),
         req              => periodic_rd_request(RANKS - 1 downto 0),
         disable_grant    => '0',
         clk              => clk,
         rst              => rst
      );
   int3 <= periodic_rd_grant_ns when (periodic_upd_last_master_ns = '1') else
                        periodic_rd_grant_r;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         periodic_rd_grant_r <= int3;
      end if;
   end process;
   
   process (periodic_rd_grant_r, periodic_rd_rank_r_lcl, periodic_upd_last_master_r)
   begin
      periodic_rd_rank_ns <= periodic_rd_rank_r_lcl;
      if (periodic_upd_last_master_r = '1') then
         for i in 0 to  RANKS - 1 loop
            if ((periodic_rd_grant_r(i)) = '1') then
               periodic_rd_rank_ns <= std_logic_vector(TO_UNSIGNED(i,RANK_WIDTH ));
            end if;
         end loop;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         periodic_rd_rank_r_lcl <= periodic_rd_rank_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   clear_periodic_rd_request <= periodic_rd_grant_r and nCOPY(periodic_rd_ack_r,RANKS);
   periodic_rd_r <= periodic_rd_r_lcl;
   periodic_rd_rank_r <= periodic_rd_rank_r_lcl;
   
end architecture trans;



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
--  /   /         Filename              : bank_common.vhd
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
 --  use ieee.numeric_std.all;
   use ieee.std_logic_arith.all;


-- Common block for the bank machines.  Bank_common computes various
-- items that cross all of the bank machines.  These values are then
-- fed back to all of the bank machines.  Most of these values have
-- to do with a row machine figuring out where it belongs in a queue.

entity bank_common is
   generic (
      TCQ                   : integer := 100;
      BM_CNT_WIDTH          : integer := 2;
      LOW_IDLE_CNT          : integer := 1;
      nBANK_MACHS           : integer := 4;
      nCK_PER_CLK           : integer := 2;
      nOP_WAIT              : integer := 0;
      nRFC                  : integer := 44;
      RANK_WIDTH            : integer := 2;
      RANKS                 : integer := 4;
      CWL                   : integer := 5;
      tZQCS                 : integer := 64
   );
   port (
      
      accept_internal_r     : out std_logic;
      accept_ns             : out std_logic;
      
      -- Wire to user interface informing user that the request has been accepted.
      accept                : out std_logic;
      
      -- periodic_rd_insert tells everyone to mux in the periodic read.
      
      periodic_rd_insert    : out std_logic;
      
      -- periodic_rd_ack_r acknowledges that the read has been accepted
      -- into the queue.
      periodic_rd_ack_r     : out std_logic;
      
      -- accept_req tells all q entries that a request has been accepted.
      accept_req            : out std_logic;
      
      -- Count how many non idle bank machines hit on the rank and bank.
      rb_hit_busy_cnt       : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      
      -- Count the number of idle bank machines.
      idle_cnt              : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      
      -- Count the number of bank machines in the ordering queue.
      order_cnt             : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      
      adv_order_q           : out std_logic;
      
      -- Figure out which bank machine is going to accept the next request.
      bank_mach_next        : out std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
      
      op_exit_grant         : out std_logic_vector(nBANK_MACHS - 1 downto 0);
      low_idle_cnt_r        : out std_logic;            -- = 1'b0;
      
      -- In support of open page mode, the following logic
      -- keeps track of how many "idle" bank machines there
      -- are.  In this case, idle means a bank machine is on
      -- the idle list, or is in the process of precharging and
      -- will soon be idle.
      
      -- This arbiter determines which bank machine should transition
      -- from open page wait to precharge.  Ideally, this process
      -- would take the oldest waiter, but don't have any reasonable
      -- way to implement that.  Instead, just use simple round robin
      -- arb with the small enhancement that the most recent bank machine
      -- to enter open page wait is given lowest priority in the arbiter.
      
      -- should be one bit set at most
      
      -- Register some command information.  This information will be used
      -- by the bank machines to figure out if there is something behind it
      -- in the queue that require hi priority.
      
      was_wr                : out std_logic;
      
      was_priority          : out std_logic;
      
      -- DRAM maintenance (refresh and ZQ) controller
      
      maint_wip_r           : out std_logic;
      maint_idle            : out std_logic;
      force_io_config_rd_r  : out std_logic;
      
      -- Idle when not (maintenance work in progress (wip), OR maintenance
      -- starting tick).
      
      -- Maintenance work in progress starts with maint_reg_r tick, terminated
      -- with maint_end tick.  maint_end tick is generated by the RFC ZQ timer below.
      
      -- Keep track of which bank machines hit on the maintenance request
      -- when the request is made.  As bank machines complete, an assertion
      -- of the bm_end signal clears the correspoding bit in the
      -- maint_hit_busies_r vector.   Eventually, all bits should clear and
      -- the maintenance operation will proceed.  ZQ hits on all
      -- non idle banks.  Refresh hits only on non idle banks with the same rank as
      -- the refresh request.
      
      -- Look to see if io_config is in read mode.
      
      -- Queue is clear of requests conflicting with maintenance.
      
      -- Force io_config to read mode for ZQ.  This insures the DQ
      -- bus is hi Z.
      
      -- Ready to start sending maintenance commands.
      
      -- block: maint_controller
      
      -- Figure out how many maintenance commands to send, and send them.
      insert_maint_r        : out std_logic;
      clk                   : in std_logic;
      rst                   : in std_logic;
      idle_ns               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      dfi_init_complete     : in std_logic;
      periodic_rd_r         : in std_logic;
      use_addr              : in std_logic;
      rb_hit_busy_r         : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      idle_r                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      ordered_r             : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      ordered_issued        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      head_r                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      end_rtp               : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      passing_open_bank     : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      op_exit_req           : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      start_pre_wait        : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      cmd                   : in std_logic_vector(2 downto 0);
      hi_priority           : in std_logic;
      maint_req_r           : in std_logic;
      maint_zq_r            : in std_logic;
      maint_hit             : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      bm_end                : in std_logic_vector(nBANK_MACHS - 1 downto 0);
      io_config_valid_r     : in std_logic;
      io_config             : in std_logic_vector(RANK_WIDTH downto 0);
      slot_0_present        : in std_logic_vector(7 downto 0);
      slot_1_present        : in std_logic_vector(7 downto 0)
   );
end entity bank_common;

architecture trans of bank_common is

function nCOPY (A : in std_logic; B : in integer) return std_logic_vector is
variable tmp : std_logic_vector(B - 1 downto 0);
begin
    for i in 0 to B - 1  loop
      tmp(i) := A;
    end loop;
    return tmp;
end function nCOPY;

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



function REDUCTION_NOR( A: in std_logic_vector) return std_logic is
  variable tmp : std_logic := '0';
begin
  for i in A'range loop
       tmp := tmp or A(i);
  end loop;
  return  (not tmp);
end function REDUCTION_NOR;

function fRFC_CLKS (nCK_PER_CLK: integer; nRFC : integer )
return integer is
begin

if (nCK_PER_CLK = 1) then
    return (nRFC);
else 
    return ( nRFC/2 + (nRFC mod 2));
    
end if ;
end function fRFC_CLKS;


function fZQCS_CLKS  (nCK_PER_CLK: integer; tZQCS : integer )
return integer is
begin

if (nCK_PER_CLK = 1) then
    return (tZQCS);
else 
    return ( tZQCS/2 + (tZQCS mod 2));
    
end if ;
end function fZQCS_CLKS ;


function clogb2(size: integer) return integer is
   variable tmp : integer range 0 to 24;

begin
  tmp := 0;

  for i in 23 downto 0 loop  
    if( size <= 2** i) then 
    tmp := i; 
    end if;
  end loop;
  return tmp;
end function clogb2;

function fRFC_ZQ_TIMER_WIDTH (nZQCS_CLKS: integer; nRFC_CLKS : integer)
return integer is
begin

if (nZQCS_CLKS > nRFC_CLKS) then
    return (clogb2(nZQCS_CLKS + 1));
else 
    return ( clogb2(nRFC_CLKS + 1));
    
end if ;
end function fRFC_ZQ_TIMER_WIDTH;

function COND_ADD ( A: std_logic_vector; B : std_logic_vector; C : std_logic; D : std_logic)
return std_logic_vector is
variable  tmp : std_logic_vector (BM_CNT_WIDTH  downto 0);
begin
   tmp :=conv_std_logic_vector( (conv_integer (A) - conv_integer (C)),BM_CNT_WIDTH+1);
   for i in 0 to  nBANK_MACHS - 1 loop
      tmp := conv_std_logic_vector((conv_integer(tmp) + conv_integer( B(i))),BM_CNT_WIDTH+1);
   end loop;
   tmp := conv_std_logic_vector((conv_integer(tmp) + conv_integer(D)),BM_CNT_WIDTH+1);
   return tmp;
end function COND_ADD;


      
constant      ZERO                  : integer := 0;
constant      ONE                   : integer := 1;
constant      BM_CNT_ZERO           : std_logic_vector(BM_CNT_WIDTH - 1 downto 0) := (others => '0');
constant      BM_CNT_ONE            : std_logic_vector(BM_CNT_WIDTH - 1 downto 0) := (others => '1');

constant nRFC_CLKS            : integer := fRFC_CLKS(nCK_PER_CLK ,nRFC);
constant nZQCS_CLKS           : integer := fRFC_CLKS(nCK_PER_CLK ,tZQCS);
constant RFC_ZQ_TIMER_WIDTH   : integer := fRFC_ZQ_TIMER_WIDTH(nZQCS_CLKS ,nRFC_CLKS );
constant THREE                : integer := 3;

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



   signal accept_internal_ns     : std_logic;
   signal periodic_rd_ack_ns     : std_logic;
   signal accept_ns_lcl          : std_logic;
   signal accept_r               : std_logic;
   signal periodic_rd_ack_r_lcl  : std_logic;
   signal periodic_rd_insert_lcl : std_logic;
   signal accept_req_lcl         : std_logic;
   signal i                      : integer;
   signal next_int1              : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal maint_wip_r_lcl        : std_logic;
   signal maint_idle_lcl         : std_logic;
   signal start_maint            : std_logic;
   signal maint_end              : std_logic;
   signal insert_maint_r_lcl     : std_logic;
   signal rfc_zq_timer_r         :std_logic_vector(RFC_ZQ_TIMER_WIDTH - 1 downto 0);
   signal rfc_zq_timer_ns        :std_logic_vector(RFC_ZQ_TIMER_WIDTH - 1 downto 0);
   signal maint_wip_ns           : std_logic;
   signal clear_vector           : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal maint_zq_hits          : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal maint_hit_busies_ns    : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal maint_hit_busies_r     : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal io_config_rd           : std_logic;
   signal io_config_rd_r         : std_logic;
   signal io_config_rd_r1        : std_logic;
   signal io_config_rd_delayed   : std_logic;
   signal maint_clear           : std_logic;
   signal maint_rdy           : std_logic;
   signal maint_rdy_r1           : std_logic;
   
   signal force_io_config_rd_ns           : std_logic;
   signal force_io_config_rd_r_lcl           : std_logic;
   signal send_cnt_ns            : std_logic_vector(RANK_WIDTH downto 0);
   signal send_cnt_r             : std_logic_vector(RANK_WIDTH downto 0);
   signal present_count             : std_logic_vector(RANK_WIDTH downto 0);
   
   signal present           : std_logic_vector(7 downto 0);
   signal insert_maint_ns        : std_logic;
   
   -- Count up how many slots are occupied.  This tells
   -- us how many ZQ commands to send out.
   
   -- For refresh, there is only a single command sent.  For
   -- ZQ, each rank present will receive a ZQ command.  The counter
   -- below counts down the number of ranks present.
   
   -- Insert a maintenance command for start_maint, or when the sent count
   -- is not zero.
   
   -- block: generate_maint_cmds
   
   -- RFC ZQ timer.  Generates delay from refresh or ZQ command until
   -- the end of the maintenance operation.
   
   -- Compute values for RFC and ZQ periods.
   signal rfc_zq_timer_ns_int7 : std_logic_vector(RFC_ZQ_TIMER_WIDTH - 1 downto 0);
   
   -- Declare intermediate signals for referenced outputs
   signal rb_hit_busy_cnt_int4   : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal idle_cnt_int0          : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal order_cnt_int3         : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   signal op_exit_grant_i     : std_logic_vector(nBANK_MACHS - 1 downto 0);
   signal tstA                   : std_logic;
begin
   -- Drive referenced outputs
   rb_hit_busy_cnt <= rb_hit_busy_cnt_int4;
   idle_cnt <= idle_cnt_int0;
   order_cnt <= order_cnt_int3;
   op_exit_grant <= op_exit_grant_i;
   accept_internal_ns <= dfi_init_complete and REDUCTION_OR(idle_ns);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         accept_internal_r <= accept_internal_ns;
      end if;
   end process;
   
   accept_ns_lcl <= accept_internal_ns and not(periodic_rd_ack_ns);
   accept_ns <= accept_ns_lcl;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         accept_r <= accept_ns_lcl after (TCQ)*1 ps;
      end if;
   end process;
   
   accept <= accept_r;
   periodic_rd_insert_lcl <= periodic_rd_r and not(periodic_rd_ack_r_lcl);
   periodic_rd_insert <= periodic_rd_insert_lcl;
   periodic_rd_ack_ns <= periodic_rd_insert_lcl and accept_internal_ns;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         periodic_rd_ack_r_lcl <= periodic_rd_ack_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   periodic_rd_ack_r <= periodic_rd_ack_r_lcl;
   accept_req_lcl <= periodic_rd_ack_r_lcl or (accept_r and use_addr);
   accept_req <= accept_req_lcl;
   process (rb_hit_busy_r)
   variable rb_hit_busy_r_tmp : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   begin
      rb_hit_busy_r_tmp := (others => '0');
      for i in 0 to  nBANK_MACHS - 1 loop
         if ((rb_hit_busy_r(i)) = '1') then
            rb_hit_busy_r_tmp := rb_hit_busy_r_tmp + '1';
         end if;
      end loop;
      rb_hit_busy_cnt_int4 <= rb_hit_busy_r_tmp;
   end process;
   
   process (idle_r)
   variable idle_cnt_int0_tmp : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   begin
      idle_cnt_int0_tmp := (others => '0');
      for i in 0 to  nBANK_MACHS - 1 loop
         if ((idle_r(i)) = '1') then
            idle_cnt_int0_tmp := idle_cnt_int0_tmp + '1';
         end if;
      end loop;
      
      idle_cnt_int0 <= idle_cnt_int0_tmp;
      
   end process;
   
   process (ordered_r)
   variable order_cnt_int3_tmp : std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   
   begin
      order_cnt_int3_tmp := (others => '0');
      for i in 0 to  nBANK_MACHS - 1 loop
         if ((ordered_r(i)) = '1') then
            order_cnt_int3_tmp := order_cnt_int3_tmp + '1';
         end if;
      end loop;
    order_cnt_int3 <= order_cnt_int3_tmp;  
   end process;
   
   adv_order_q <= REDUCTION_OR(ordered_issued);
   next_int1 <= idle_r and head_r;
   process (next_int1)
   variable   bank_mach_next_tmp        :  std_logic_vector(BM_CNT_WIDTH - 1 downto 0);
   
   begin
      bank_mach_next_tmp := BM_CNT_ZERO;
      for i in 0 to  nBANK_MACHS - 1 loop
         if ((next_int1(i)) = '1') then
            bank_mach_next_tmp := conv_std_logic_vector(i, BM_CNT_WIDTH);
         end if;
      end loop;
      
      
      bank_mach_next <= bank_mach_next_tmp;
      
      
   end process;
   
   op_mode_disabled : if (nOP_WAIT = 0) generate
      op_exit_grant_i <= (others => '0');
      low_idle_cnt_r <= '0';
      
   end generate;
   
   
   op_mode_enabled : if (not(nOP_WAIT = 0)) generate  
      signal idle_cnt_r : std_logic_vector(BM_CNT_WIDTH  downto 0);
      signal idle_cnt_ns : std_logic_vector(BM_CNT_WIDTH  downto 0);
      signal low_idle_cnt_ns : std_logic;
      signal upd_last_master : std_logic;
      begin
      process (accept_req_lcl, idle_cnt_r, passing_open_bank, rst, start_pre_wait)
      begin
         if (rst = '1') then
            idle_cnt_ns <= conv_std_logic_vector(nBANK_MACHS, BM_CNT_WIDTH+1);
         else
            idle_cnt_ns <= COND_ADD (idle_cnt_r,passing_open_bank,accept_req_lcl,(REDUCTION_OR(start_pre_wait)));
            --idle_cnt_ns <= idle_cnt_r - ( accept_req_lcl);
            --for i in 0 to  nBANK_MACHS - 1 loop
            --   idle_cnt_ns <= idle_cnt_ns + ( passing_open_bank(i));
            --end loop;
            --idle_cnt_ns <= idle_cnt_ns + ( REDUCTION_OR(start_pre_wait));
         end if;
      end process;
      
      process (clk)
      begin
         if (clk'event and clk = '1') then
            idle_cnt_r <= idle_cnt_ns after (TCQ)*1 ps;
         end if;
      end process;
      
      
      
      process(idle_cnt_ns)
      begin
      if ( conv_integer(idle_cnt_ns) <= LOW_IDLE_CNT) then
           low_idle_cnt_ns <= '1';
      else   
           low_idle_cnt_ns <= '0';
      end if;
      end process;
      
      
      process (clk)
      begin
         if (clk'event and clk = '1') then
            low_idle_cnt_r <= low_idle_cnt_ns after (TCQ)*1 ps;
         end if;
      end process;
      
      upd_last_master <= REDUCTION_OR(end_rtp);
      
      
      op_arb0 : round_robin_arb
         generic map (
            TCQ    => TCQ,
            WIDTH  => nBANK_MACHS
         )
         port map (
            grant_ns         => op_exit_grant_i(nBANK_MACHS - 1 downto 0),
            grant_r          => open,
            upd_last_master  => upd_last_master,
            current_master   => end_rtp(nBANK_MACHS - 1 downto 0),
            clk              => clk,
            rst              => rst,
            req              => op_exit_req(nBANK_MACHS - 1 downto 0),
            disable_grant    => '0'
         );
   end generate;
   process (clk)
   begin
      if (clk'event and clk = '1') then
         was_wr <= cmd(0) and not((periodic_rd_r and not(periodic_rd_ack_r_lcl))) after (TCQ)*1 ps;
      end if;
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         was_priority <= hi_priority after (TCQ)*1 ps;
      end if;
   end process;
   
   maint_wip_r <= maint_wip_r_lcl;
   maint_idle <= maint_idle_lcl;
                          -- ok                bad
   maint_idle_lcl <= not(maint_req_r or maint_wip_r_lcl);
                                    -- ok             bad                   ok
   maint_wip_ns <= not(rst) and not(maint_end) and (maint_wip_r_lcl or maint_req_r);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_wip_r_lcl <= maint_wip_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   
   
   clear_vector <= nCOPY(rst,nBANK_MACHS) or bm_end;
                              --
   maint_zq_hits <= nCOPY(maint_idle_lcl,nBANK_MACHS) and (maint_hit or nCOPY(maint_zq_r,nBANK_MACHS)) and not(idle_ns);
   maint_hit_busies_ns <= not(clear_vector) and (maint_hit_busies_r or maint_zq_hits);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_hit_busies_r <= maint_hit_busies_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   io_config_rd <= io_config_valid_r and not(io_config(RANK_WIDTH));
	  --Added to fix CR #528228
	  --Adding extra register stages to delay the maintainence
	  --commands from beign applied on the dfi interface bus.
	  --This is done to compensate the delays added to ODT logic
	  --in the mem_infc module.
   process (clk)
   begin
    if (clk'event and clk = '1') then
        io_config_rd_r  <= io_config_rd;
		io_config_rd_r1 <= io_config_rd_r;
    end if;
   end process;

   io_config_rd_delayed <= io_config_rd_r1 when (CWL >= 7) else io_config_rd_r;

   tstA <= REDUCTION_NOR(maint_hit_busies_ns);
   maint_clear <= not(maint_idle_lcl) and REDUCTION_NOR(maint_hit_busies_ns);--
   
   
   
   force_io_config_rd_ns <= maint_clear and maint_zq_r and not(io_config_rd) and not(force_io_config_rd_r_lcl);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         force_io_config_rd_r_lcl <= force_io_config_rd_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   force_io_config_rd_r <= force_io_config_rd_r_lcl;
   -- bac
   maint_rdy <= maint_clear and (not(maint_zq_r) or io_config_rd_delayed);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         maint_rdy_r1 <= maint_rdy after (TCQ)*1 ps;
      end if;
   end process;
   
   start_maint <= maint_rdy and not(maint_rdy_r1);
   insert_maint_r <= insert_maint_r_lcl;
   present <= slot_0_present or slot_1_present;
   process (present)
   variable present_count_tmp : std_logic_vector(RANK_WIDTH downto 0);
   begin
      present_count_tmp := (others => '0');
      for i in 0 to 7 loop
         present_count_tmp := present_count_tmp + (nCOPY('0',RANK_WIDTH) & present(i));
      end loop;
      
      present_count <= present_count_tmp;
   end process;

  
   process (maint_zq_r, present_count, rst, send_cnt_r, start_maint)
   variable send_cnt_ns_tmp : std_logic_vector(RANK_WIDTH downto 0);
   variable tstAA : std_logic_vector(2 downto 0);
   begin
      if (rst = '1') then
         send_cnt_ns_tmp := (others => '0');
      else
         send_cnt_ns_tmp := send_cnt_r;
         if (start_maint = '1' and maint_zq_r = '1') then
            send_cnt_ns_tmp := present_count;
            tstAA := "001";
         end if;
         if ((REDUCTION_OR(send_cnt_ns_tmp)) = '1') then
            send_cnt_ns_tmp := send_cnt_ns_tmp - '1';
            tstAA := "010";
            
         end if;
      end if;
      
      send_cnt_ns <= send_cnt_ns_tmp;
      
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         send_cnt_r <= send_cnt_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   insert_maint_ns <= start_maint or REDUCTION_OR(send_cnt_r);
   process (clk)
   begin
      if (clk'event and clk = '1') then
         insert_maint_r_lcl <= insert_maint_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   
   
   
   rfc_zq_timer_ns_int7 <= conv_std_logic_vector(nZQCS_CLKS, RFC_ZQ_TIMER_WIDTH) when (maint_zq_r = '1') else
                         conv_std_logic_vector(nRFC_CLKS, RFC_ZQ_TIMER_WIDTH);
                         
   
   rfc_zq_timer:process (insert_maint_r_lcl,rfc_zq_timer_ns_int7, maint_zq_r, rfc_zq_timer_r, rst)
   variable rfc_zq_timer_ns_tmp : std_logic_vector(RFC_ZQ_TIMER_WIDTH - 1 downto 0);
   begin
      rfc_zq_timer_ns_tmp := rfc_zq_timer_r;
      if (rst = '1') then
         rfc_zq_timer_ns_tmp := (others => '0');
      elsif (insert_maint_r_lcl = '1') then
         rfc_zq_timer_ns_tmp := rfc_zq_timer_ns_int7;
      elsif ((REDUCTION_OR(rfc_zq_timer_r)) = '1') then
         rfc_zq_timer_ns_tmp := rfc_zq_timer_r - '1';
      end if;
      
      rfc_zq_timer_ns <= rfc_zq_timer_ns_tmp;
      
      
   end process;
   
   process (clk)
   begin
      if (clk'event and clk = '1') then
         
         -- Based on rfc_zq_timer_r, figure out when to release any bank
         -- machines waiting to send an activate.  Need to add two to the end count.
         -- One because the counter starts a state after the insert_refresh_r, and
         -- one more because bm_end to insert_refresh_r is one state shorter
         -- than bm_end to rts_row.
         rfc_zq_timer_r <= rfc_zq_timer_ns after (TCQ)*1 ps;
      end if;
   end process;
   
   maint_end <= BOOLEAN_TO_STD_LOGIC((conv_integer(rfc_zq_timer_r) = 3));
   -- block: rfc_zq_timer
   
                -- bank_common
end architecture trans;


